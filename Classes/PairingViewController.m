//
//  PairingViewController.m
//  thatcloud
//
//  Created by Liyan David Chang on 8/6/13.
//  Copyright (c) 2013 Ink (Cloudtop Inc). All rights reserved.
//

#import "PairingViewController.h"
#import "FlatUIKit.h"
#import "ThatCloudConstants.h"

@interface PairingViewController ()
@property NSString *fphandle;

@end

@implementation PairingViewController

- (id)initWithHandle:(NSString*)fphandle {
    
    self = [super init];
    if (self) {
        self.fphandle = fphandle;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#define imageVFrame (DEVICE_IS_IPAD ? (CGRectMake((540-imageV.frame.size.width)/2, 50, imageV.frame.size.width, imageV.frame.size.height)) : (CGRectMake(10, 5, imageV.frame.size.width, imageV.frame.size.height)))
#define subheaderFrame (DEVICE_IS_IPAD ? CGRectMake(0, 200, 540, 90) : CGRectMake(0, 170, 320, 90))
#define labelFrame (DEVICE_IS_IPAD ? CGRectMake(0, 350, 540, 30) : CGRectMake(0, 280, 320, 30))
#define pairingTextfieldFrame (DEVICE_IS_IPAD ? CGRectMake((540-250)/2, 385, 250, 30) : CGRectMake(40, 335, 250, 30))
#define copylabelFrame (DEVICE_IS_IPAD ? CGRectMake(0, 410, 540, 30) : CGRectMake(0, 350, 320, 30))
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Share this file with another device";
    [self.navigationController.navigationBar configureFlatNavigationBarWithColor:[UIColor whiteColor]];

    [self.view setBackgroundColor:[UIColor whiteColor]];

    UIImageView *imageV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pair.png"]];
    imageV.frame = imageVFrame;
    [self.view addSubview:imageV];
    
    UILabel *subheader = [[UILabel alloc] initWithFrame:subheaderFrame];
    subheader.textAlignment = NSTextAlignmentCenter;
    subheader.text = @"You can easily share files with other ThatCloud users.\n A secure pairing code has been generated below \nand can be retrieved on another device with ThatCloud.";
    subheader.lineBreakMode = NSLineBreakByWordWrapping;
    subheader.numberOfLines = 0;
    subheader.font = [UIFont fontWithName:LIGHTFONT size:18];
    [self.view addSubview:subheader];

    
    UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"Pairing Code";
    label.font = [UIFont fontWithName:FONT size:22];
    [self.view addSubview:label];

    
    UITextField *pairing = [[UITextField alloc] initWithFrame:pairingTextfieldFrame];
    [pairing setText:self.fphandle];
    pairing.delegate = self;
    pairing.textAlignment = NSTextAlignmentCenter;
    pairing.enabled = NO;
    pairing.font = [UIFont fontWithName:@"Courier" size:18];
    [self.view addSubview:pairing];
    
    UILabel *copylabel = [[UILabel alloc] initWithFrame:copylabelFrame];
    copylabel.textAlignment = NSTextAlignmentCenter;
    copylabel.text = @"(Copied to your clipboard)";
    copylabel.font = [UIFont fontWithName:FONT size:14];
    copylabel.textColor = [UIColor grayColor];
    [self.view addSubview:copylabel];

    
    UIPasteboard *pb = [UIPasteboard generalPasteboard];
    [pb setString:self.fphandle];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wenum-conversion"
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)];
#pragma clang diagnostic pop
    
    [cancelButton configureFlatButtonWithColor:[UIColor peterRiverColor] highlightedColor:[UIColor belizeHoleColor] cornerRadius:3];

    self.navigationItem.rightBarButtonItem = cancelButton;
    
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) cancelAction:(id) sender {
    [self.navigationController dismissViewControllerAnimated:NO completion:nil];

}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    return NO;
}

@end
