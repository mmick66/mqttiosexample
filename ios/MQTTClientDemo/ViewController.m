//
//  ViewController.m
//  MQTTClientDemo
//
//  Created by Michael Michailidis on 03/08/2015.
//  Copyright (c) 2015 karmadust. All rights reserved.
//

#import "ViewController.h"
#import <MQTTKit.h>

#define STD_CLIENT_ID @"D1102"

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
@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    
    self.messageLabel.text = @"";
    self.clientIDTextField.text = STD_CLIENT_ID;
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
    
    
    client = [[MQTTClient alloc] initWithClientId:self.clientIDTextField.text];
    
    
}


- (IBAction)connectButtonPressed:(UIButton*)sender {
    
    // 46.101.21.238 - haproxy
    // iot.eclipse.org
    // 46.101.22.78 - mosca
    
    self.messageLabel.text = @"Connecting";
    
    [client connectToHost:@"46.101.21.238"
        completionHandler:^(NSUInteger code) {
            
            
            if (code == ConnectionAccepted) {
                
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    
                    self.messageLabel.text = @"Connection Accepted";
                    
                    
                    
                });
                
                
            }
            
        }];
}

- (IBAction)sendButtonPressed:(UIButton *)sender {
    
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
    
    [client disconnectWithCompletionHandler:^(NSUInteger code) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.messageLabel.text = @"Client Disconnected";
            
        });
        
    }];
    
}





@end
