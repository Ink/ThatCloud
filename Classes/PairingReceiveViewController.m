//
//  PairingRecieveViewController.m
//  thatcloud
//
//  Created by Liyan David Chang on 8/6/13.
//  Copyright (c) 2013 Ink (Cloudtop Inc). All rights reserved.
//

#import "PairingReceiveViewController.h"
#import "FlatUIKit.h"
#import <Ink/Ink.h>
#import "SourceListSaveController.h"
#import "InkFile.h"
#import "FPAFNetworking.h"
#import "ThatCloudConstants.h"

@interface PairingReceiveViewController ()

@property UILabel *filename;
@property UILabel *mimetype;
@property InkFile *myfile;

@end

@implementation PairingReceiveViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self.view sizeToFit];
    
    self.title = @"Accept a File Transfer";
    [self.navigationController.navigationBar configureFlatNavigationBarWithColor:[UIColor whiteColor]];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 30, 540, 30)];
    label.text = [NSString stringWithFormat:@"Enter the Pairing Code:"];
    label.font = [UIFont fontWithName:LIGHTFONT size:16];
    
    label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:label];
    
    UILabel *filename = [[UILabel alloc] initWithFrame:CGRectMake((540-400)/2, 130, 400, 30)];
    filename.text = @"";
    filename.textAlignment = NSTextAlignmentCenter;
    filename.lineBreakMode = NSLineBreakByTruncatingMiddle;
    filename.font = [UIFont fontWithName:FONT size:16];
    [self.view addSubview:filename];
    self.filename = filename;
    
    UILabel *mimetype = [[UILabel alloc] initWithFrame:CGRectMake((540-400)/2, 150, 400, 30)];
    mimetype.textAlignment = NSTextAlignmentCenter;
    mimetype.text = @"";
    mimetype.font = [UIFont fontWithName:LIGHTFONT size:14];
    mimetype.backgroundColor = [UIColor clearColor];
    mimetype.textColor = [UIColor grayColor];
    [self.view addSubview:mimetype];
    self.mimetype = mimetype;
    

    
    label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:label];
    
    UITextField *tx = [[UITextField alloc] initWithFrame:CGRectMake((540-350)/2, 80, 350, 30)];
    [tx setBorderStyle:UITextBorderStyleRoundedRect];
    [tx setFont:[UIFont fontWithName:@"Courier" size:16]];
    tx.autocapitalizationType = UITextAutocapitalizationTypeNone;
    tx.autocorrectionType =  UITextAutocorrectionTypeNo;
    tx.textAlignment = NSTextAlignmentCenter;
    tx.delegate = self;
    [self.view addSubview:tx];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(textChanged:)
     name:UITextFieldTextDidChangeNotification
     object:tx];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wenum-conversion"
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)];
    [cancelButton configureFlatButtonWithColor:[UIColor peterRiverColor] highlightedColor:[UIColor belizeHoleColor] cornerRadius:3];
#pragma clang diagnostic pop
    self.navigationItem.rightBarButtonItem = cancelButton;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) cancelAction:(id) sender {
    [self.navigationController dismissViewControllerAnimated:NO completion:nil];
    
}

- (void) textChanged:(NSNotification*) sender {
    NSString *text = [(UITextField*)sender.object text];
    if ([text length] == 20){
        
        
        NSLog(@"Looking up filepicker url");
        self.filename.text = @"Retrieving File";

        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.filepicker.io/api/file/%@", text]];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        
        FPAFHTTPRequestOperation *operation = [[FPAFHTTPRequestOperation alloc] initWithRequest:request];
        [operation setCompletionBlockWithSuccess:^(FPAFHTTPRequestOperation *operation, id responseObject) {
            
            self.myfile = [[InkFile alloc] init];
            self.myfile.fileName = [[[operation response] allHeaderFields] valueForKey:@"X-File-Name"];
            self.myfile.mimetype = [[operation response] MIMEType];
            [self.myfile writeData:[operation responseData]];
            
            self.filename.text = self.myfile.fileName;
            self.mimetype.text = self.myfile.mimetype;
            
            
            FUIButton *save = [FUIButton buttonWithType:UIButtonTypeCustom];
            save.buttonColor = [UIColor peterRiverColor];
            save.shadowColor = [UIColor belizeHoleColor];
            save.shadowHeight = 3.0f;
            save.cornerRadius = 6.0f;
            save.frame = CGRectMake(440/2, 190, 100, 40);
            [save addTarget:self action:@selector(saveFile:) forControlEvents:UIControlEventTouchUpInside];
            [save setTitle:@"Accept" forState:UIControlStateNormal];
            [self.view addSubview:save];
            
        } failure:^(FPAFHTTPRequestOperation *operation, NSError *error) {
            self.filename.text = @"Not a valid pairing code";

        }];
        
        [operation start];


        
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    
    if ([string length] == 0){
        return YES;
    }
    if ([textField.text length] >= 20) {
        textField.text = [textField.text substringToIndex:20];
        return NO;
    }
    return YES;
}

- (void)saveFile:(id)sender {
        
        SourceListSaveController *sc = [[SourceListSaveController alloc] init];
        sc.fpdelegate = self;
        sc.dataType = self.myfile.mimetype;
        sc.data = self.myfile.data;
        sc.proposedFilename = [self.myfile.fileName stringByDeletingPathExtension];
        
        sc.modalPresentationStyle = UIModalPresentationFormSheet;
    
        [self presentViewController:sc animated:YES completion:nil];
}

- (void)FPSaveControllerDidSave:(SourceListSaveController *)picker {
    //user selected save. save not complete yet.
}

- (void)FPSaveControllerDidCancel:(SourceListSaveController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
    [Ink return];
}

- (void)FPSaveController:(SourceListSaveController *)picker didError:(NSDictionary *)info {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)FPSaveController:(SourceListSaveController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated:NO completion:nil];
    [self.navigationController dismissViewControllerAnimated:NO completion:nil];

}


@end
