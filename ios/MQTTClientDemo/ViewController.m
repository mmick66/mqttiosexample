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
    CLLocationManager *locationManager;
}

@property (strong, nonatomic) IBOutlet UIButton *connectButton;
@property (strong, nonatomic) IBOutlet UIButton *sendButton;
@property (strong, nonatomic) IBOutlet UIButton *disconnectButton;

@property (strong, nonatomic) IBOutlet UILabel *messageLabel;
@property (strong, nonatomic) IBOutlet UITextField *clientIDTextField;
@property (strong, nonatomic) IBOutlet UILabel *latitudeLabel;
@property (strong, nonatomic) IBOutlet UILabel *longitudeLabel;


@property (nonatomic) BOOL isConnected;

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    
    self.messageLabel.text = @"";
    self.clientIDTextField.text = STD_CLIENT_ID;
    
    self.isConnected = NO;
    
    locationManager = [[CLLocationManager alloc] init];
    
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
}



- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError: %@", error);
    [[[UIAlertView alloc] initWithTitle:@"Error"
                                message:@"Failed to Get Your Location"
                               delegate:nil
                      cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    NSLog(@"didUpdateToLocation: %@", newLocation);
    
    CLLocation *currentLocation = newLocation;
    
    if (currentLocation != nil) {
        self.longitudeLabel.text = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude];
        self.latitudeLabel.text = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude];
    }
}


- (IBAction)connectButtonPressed:(UIButton*)sender {
    
    mqttClient = [[MQTTClient alloc] initWithClientId:self.clientIDTextField.text];
    
    self.messageLabel.text = [NSString stringWithFormat:@"Connecting... to %@", STD_MQTT_SERVER_URI];
    
    [mqttClient connectToHost:STD_MQTT_SERVER_URI
            completionHandler:^(NSUInteger code) {
            
                if (code == ConnectionAccepted) {
                
                    dispatch_async(dispatch_get_main_queue(), ^{
                    
                        self.messageLabel.text = @"Connection Accepted!";
                        self.isConnected = YES;
                        
                        [self publishStatusMessage:@"Online"];
                    
                    });
                
                }
            
            }];
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
                    
                    self.messageLabel.text = [NSString stringWithFormat:@"message: \"%@\" has been published to topic: \"%@\"", message, topic];
                    
                });
                
            }];
}



- (IBAction)disconnectButtonPressed:(id)sender {
    
    if(!mqttClient)
        return;
    
    [mqttClient disconnectWithCompletionHandler:^(NSUInteger code) {
        
            dispatch_async(dispatch_get_main_queue(), ^{
            
                self.messageLabel.text = @"Client Disconnected";
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



@end
