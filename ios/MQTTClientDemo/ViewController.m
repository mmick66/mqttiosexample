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

#define SYSTEM_IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] == NSOrderedDescending)

@interface ViewController () <CLLocationManagerDelegate>
{
    MQTTClient *mqttClient;
    CLLocationManager *locationManager;
}

@property (strong, nonatomic) IBOutlet UIButton *connectButton;
@property (strong, nonatomic) IBOutlet UIButton *sendButton;
@property (strong, nonatomic) IBOutlet UIButton *disconnectButton;

@property (strong, nonatomic) IBOutlet UITextView *outputTextView;
@property (strong, nonatomic) IBOutlet UITextField *clientIDTextField;
@property (strong, nonatomic) IBOutlet UILabel *latitudeLabel;
@property (strong, nonatomic) IBOutlet UILabel *longitudeLabel;


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

- (void) showLocationServiceUnavailableMessage {
    
    [[[UIAlertView alloc] initWithTitle:@"Location Services Disabled"
                                message:@"Please enable the location services to run this experiment. If on the simulator add GPX"
                               delegate:nil
                      cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    
}

- (IBAction)switchValueChanged:(UISwitch *)sender {
    
    if(sender.on) {
        
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        
//        if(SYSTEM_IS_OS_8_OR_LATER) {
//            
//            [locationManager requestWhenInUseAuthorization];
//            [locationManager requestAlwaysAuthorization];
//            
//        } else {
//            
//            [locationManager startUpdatingLocation];
//        }
        
        
        
    } else {
        
        [locationManager stopUpdatingLocation];
    }
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    switch (status) {
            
        case kCLAuthorizationStatusNotDetermined:
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied:
            [self showLocationServiceUnavailableMessage];
            break;
            
        default:
            NSLog(@"Switched Location on");
            [locationManager startUpdatingLocation];
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError: %@", error);
    [[[UIAlertView alloc] initWithTitle:@"Error"
                                message:@"Failed to Get Your Location"
                               delegate:nil
                      cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    NSLog(@"didUpdateToLocation: %@", newLocation);
    
    CLLocation *currentLocation = newLocation;
    
    if (currentLocation != nil) {
        self.longitudeLabel.text = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude];
        self.latitudeLabel.text = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude];
    }
}

- (void)sendLocation {
    [self publishMessage:@"" toTopic:[NSString stringWithFormat:@"%@/location", mqttClient.clientID]];
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
                
                }
            
            }];
}

// append to the output
- (void) wirteOutput:(NSString*)output {
    
    if([self.outputTextView.text isEqualToString:@""]) {
        self.outputTextView.text = output;
        return;
    }
    self.outputTextView.text = [NSString stringWithFormat:@"%@\n%@", self.outputTextView.text, output];
    
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
    
    for(UIControl* control in @[self.clientIDTextField,
                                self.connectButton,
                                self.disconnectButton])
    {
        
        control.alpha = control.enabled ? 1.0 : 0.5;
    }
    
    
}



- (IBAction)trashPressed:(id)sender {
    
    self.outputTextView.text = @"";
}


@end
