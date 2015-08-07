//
//  ViewController.m
//  MQTTClientDemo
//
//  Created by Michael Michailidis on 03/08/2015.
//  Copyright (c) 2015 karmadust. All rights reserved.
//

#import "ViewController.h"
#import <MQTTKit.h>

#define STD_CLIENT_ID @"D101"
#define STD_MQTT_SERVER_URI @"127.0.0.1"

@interface ViewController ()
{
    MQTTClient *client;
}
@property (strong, nonatomic) IBOutlet UIButton *connectButton;
@property (strong, nonatomic) IBOutlet UIButton *sendButton;
@property (strong, nonatomic) IBOutlet UIButton *disconnectButton;

@property (strong, nonatomic) IBOutlet UILabel *messageLabel;
@property (strong, nonatomic) IBOutlet UISegmentedControl *statusControl;
@property (strong, nonatomic) IBOutlet UIStepper *stepper;
@property (strong, nonatomic) IBOutlet UITextField *clientIDTextField;

@property (nonatomic) BOOL isConnected;

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    
    self.messageLabel.text = @"";
    self.clientIDTextField.text = STD_CLIENT_ID;
    
    self.isConnected = NO;
}



- (IBAction)stepperValueChanged:(UIStepper *)sender {
    
    NSString* numericPart = [self.clientIDTextField.text substringFromIndex:1];
    
    int value = [numericPart intValue];
    
    if(value > 0) {
        
        value += (int)sender.value;
        self.clientIDTextField.text = [NSString stringWithFormat:@"D%i", value];
        
    }
    
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}


- (IBAction)connectButtonPressed:(UIButton*)sender {
    
    client = [[MQTTClient alloc] initWithClientId:self.clientIDTextField.text];
    
    self.messageLabel.text = [NSString stringWithFormat:@"Connecting... to %@", STD_MQTT_SERVER_URI];
    
    [client connectToHost:STD_MQTT_SERVER_URI
        completionHandler:^(NSUInteger code) {
            
            if (code == ConnectionAccepted) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    self.messageLabel.text = @"Connection Accepted!";
                    self.isConnected = YES;
                    
                });
                
                
            }
            
        }];
}

- (IBAction)sendButtonPressed:(UIButton *)sender {
    
    if(!client)
        return;
    
    NSString* topic = [NSString stringWithFormat:@"%@/status", client.clientID];
    
    NSString* statusString = self.statusControl.selectedSegmentIndex == 0 ? @"Online" : @"Offline";
    
    [client publishString:statusString
                  toTopic:topic
                  withQos:AtMostOnce // 0
                   retain:NO
        completionHandler:^(int mid) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                self.messageLabel.text = [NSString stringWithFormat:@"Message: \"%@\" has been delivered", statusString];
                
            });
            
            
            
        }];
}

- (IBAction)disconnectButtonPressed:(id)sender {
    
    if(!client)
        return;
    
    [client disconnectWithCompletionHandler:^(NSUInteger code) {
        
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
    
    self.stepper.enabled = !_isConnected;
    self.clientIDTextField.enabled = !_isConnected;
    
    
    self.connectButton.enabled = !_isConnected;
    self.disconnectButton.enabled = _isConnected;
    self.sendButton.enabled = _isConnected;
    
    for(UIControl* control in @[self.clientIDTextField, self.stepper, self.connectButton, self.disconnectButton, self.sendButton])
        control.alpha = control.enabled ? 1.0 : 0.5;
    
}



@end
