//
//  ViewController.m
//  MQTTClientDemo
//
//  Created by Michael Michailidis on 03/08/2015.
//  Copyright (c) 2015 karmadust. All rights reserved.
//

#import "ViewController.h"
#import <MQTTKit.h>
#import <CoreLocation/CoreLocation.h>

#define STD_CLIENT_ID @"D101"
#define STD_MQTT_SERVER_URI @"127.0.0.1"

@interface ViewController () <CLLocationManagerDelegate>
{
    MQTTClient *mqttClient;
}

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) IBOutlet UIButton *connectButton;
@property (strong, nonatomic) IBOutlet UIButton *disconnectButton;

@property (strong, nonatomic) IBOutlet UITextView *outputTextView;
@property (strong, nonatomic) IBOutlet UITextField *clientIDTextField;
@property (strong, nonatomic) IBOutlet UILabel *latitudeLabel;
@property (strong, nonatomic) IBOutlet UILabel *longitudeLabel;
@property (strong, nonatomic) IBOutlet UISwitch *locationSwitch;


@property (nonatomic) BOOL isConnected;

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    
    self.outputTextView.text = @"";
    self.clientIDTextField.text = STD_CLIENT_ID;
    
    self.isConnected = NO;
    
    
}

-(void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
}

# pragma mark - Location Service



- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    [[[UIAlertView alloc] initWithTitle:@"Failed to Get Your Location"
                                message:@"If on a simulator make sure you do debug > simulate location and set it to something "
                               delegate:nil
                      cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    
    self.locationSwitch.on = NO;
    self.locationManager = nil;
    
    
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    NSLog(@"didUpdateToLocation: %@", newLocation);
    
    CLLocation *currentLocation = newLocation;
    
    if (currentLocation != nil) {
        
        NSString* latString = [NSString stringWithFormat:@"Lat: %.8f", currentLocation.coordinate.longitude];
        NSString* longString = [NSString stringWithFormat:@"Long: %.8f", currentLocation.coordinate.latitude];
        
        self.longitudeLabel.text = latString;
        self.latitudeLabel.text = longString;
        
        NSString* message = [NSString stringWithFormat:@"{%@, %@}", latString, longString];
        [self publishMessage:message toTopic:[NSString stringWithFormat:@"%@/location", mqttClient.clientID]];
        
    }
}



# pragma mark - Callbacks


- (IBAction)connectButtonPressed:(UIButton*)sender {
    
    mqttClient = [[MQTTClient alloc] initWithClientId:self.clientIDTextField.text];
    
    [self wirteOutput:[NSString stringWithFormat:@"Connecting to %@...", STD_MQTT_SERVER_URI]];
    
    [mqttClient connectToHost:STD_MQTT_SERVER_URI
            completionHandler:^(NSUInteger code) {
            
                if (code == ConnectionAccepted) {
                
                    dispatch_async(dispatch_get_main_queue(), ^{
                    
                        [self wirteOutput:@"Connection Accepted!"];
                        self.isConnected = YES;
                        
                        [self publishStatusMessage:@"Online"];
                    
                    });
                } else {
                    [self wirteOutput:@"Could not connect to host!"];
                }
            
            }];
}

// append to the output
- (void) wirteOutput:(NSString*)output {
    
    NSString* currentText = self.outputTextView.text;
    
    if([currentText isEqualToString:@""]) {
        self.outputTextView.text = output;
        return;
    }
    self.outputTextView.text = [NSString stringWithFormat:@"%@\n%@", currentText, output];
    
    // scroll to bottom
    NSRange range = NSMakeRange(currentText.length - 1, 1);
    [self.outputTextView scrollRangeToVisible:range];
    
}


     

#pragma mark - API

-(void)publishStatusMessage:(NSString*)message
{
    NSString* compositeTopicString = [NSString stringWithFormat:@"%@/status", mqttClient.clientID];
    [self publishMessage:message toTopic:compositeTopicString];
}

-(void)publishMessage:(NSString*)message toTopic:(NSString*)topic
{
    [self publishMessage:message toTopic:topic retained:NO];
    
}
-(void)publishMessage:(NSString*)message toTopic:(NSString*)topic retained:(BOOL)retained
{
    if(!mqttClient) {
        NSLog(@"ERROR: No MQTTKit Client has been initialized!");
        return;
    }
    
    
    [mqttClient publishString:message
                      toTopic:topic
                      withQos:AtMostOnce // 0
                       retain:retained
            completionHandler:^(int mid) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    NSString* ackString = [NSString stringWithFormat:@"PUB >> \"%@\" to \"%@\"", message, topic];
                    [self wirteOutput:ackString];
                    
                });
                
            }];
}



- (IBAction)disconnectButtonPressed:(id)sender {
    
    if(!mqttClient)
        return;
    
    [mqttClient disconnectWithCompletionHandler:^(NSUInteger code) {
        
            dispatch_async(dispatch_get_main_queue(), ^{
            
                [self wirteOutput: @"Client Disconnected"];
                self.isConnected = NO;
            
            });
        
        }];
    
}

#pragma mark - Setters/Getters

-(void)setIsConnected:(BOOL)isConnected
{
    _isConnected = isConnected;
    
    self.clientIDTextField.enabled = !_isConnected;
    
    self.connectButton.enabled = !_isConnected;
    self.disconnectButton.enabled = _isConnected;
    self.sendButton.enabled = _isConnected;
    self.locationSwitch.enabled = _isConnected;
    
    for(UIControl* control in @[self.clientIDTextField,
                                self.connectButton,
                                self.disconnectButton,
                                self.locationSwitch])
    {
        
        control.alpha = control.enabled ? 1.0 : 0.5;
    }
    
    
}



- (IBAction)trashPressed:(id)sender {
    
    self.outputTextView.text = @"";
}


@end
