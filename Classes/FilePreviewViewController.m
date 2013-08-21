//
//  FilePreviewViewController.m
//
//  Created by Liyan David Chang on 7/11/13.
//  Copyright (c) 2013 Ink (Cloudtop Inc). All rights reserved.
//

#import "FilePreviewViewController.h"
#import <Ink/Ink.h>
#import "FPInternalHeaders.h"
#import "PairingViewController.h"
#import "PairingReceiveViewController.h"

#import "FlatUIKit.h"

@interface FilePreviewViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@end

@implementation FilePreviewViewController {
    UIButton* inkButton;
}

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
    self.myFile = [InkFile new];
    self.webView.delegate = self;
    self.webView.scalesPageToFit = YES;
    [self.navigationController.navigationBar configureFlatNavigationBarWithColor:[UIColor whiteColor]];
    [self reset];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    // Error code -999 is a indicates a request was cancelled (which it was, since we started loading a different file).
    if (error.code != -999) {
        NSLog(@"ERROR loading file, %@", error);
        [self showNoPreviewScreen];
    }
}

- (void)showNoPreviewScreen {
    NSString *htmlString = @"<html><head><style type='text/css'>"
    "body{font-family:'HelveticaNeue-Light', 'Helvetica Neue Light', 'Helvetica Neue', Helvetica, Arial; color:#d0d0d0;}"
    ".center{width:200px;height:200px;position:absolute;left:50%;top:50%;margin:-150px 0 0 -100px;}"
    ".pcenter{width:100%;text-align:center;margin:0;padding:0;font-size:2em;}"
    "</style></head><body><div class='center'><img src='no_preview.png' />";
    htmlString = [htmlString stringByAppendingFormat:@"<p class='pcenter'>%@</p>", self.myFile.fileName];
    htmlString = [htmlString stringByAppendingString:@"</div></body></html>"];
    [_webView loadHTMLString:htmlString baseURL:[[NSBundle mainBundle] bundleURL]];
    NSLog(@"LDCDL: %@ %@", self.myFile.fileName, self.myFile.mimetype);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) showSpinner {
    
    FPMBProgressHUD* hud = [FPMBProgressHUD HUDForView:[self view]];
    if (hud){
        hud.mode = FPMBProgressHUDModeIndeterminate;
    } else {
        hud = [FPMBProgressHUD showHUDAddedTo:[self view] animated:YES];
    }
    hud.labelText = @"Connecting";
}

- (void) hideSpinner {
    [FPMBProgressHUD hideAllHUDsForView:[self view] animated:NO];
}


- (void) updateSpinner:(float)progress {
    FPMBProgressHUD* hud = [FPMBProgressHUD HUDForView:[self view]];
    hud.mode = FPMBProgressHUDModeAnnularDeterminate;
    hud.progress = progress;
    hud.labelText = @"Loading";
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    // Remove the loading spinner with the view finishing loading
    [self hideSpinner];
}

- (void) reset {
    UIImage* image = [UIImage imageNamed:@"base.png"];
    InkFile *f = [[InkFile alloc] init];
    f.uti = @"public.png";
    f.mimetype = @"image/png";
    f.fileName = @"Example-Ink-Logo.png";
    [f writeData:UIImagePNGRepresentation(image)];
    [self previewFile:f withHide:NO];
}

- (void) previewFile:(InkFile*)myFile {
    [self previewFile:myFile withHide:YES];
}

- (void) previewFile:(InkFile*)myFile withHide:(BOOL)shouldHideMaster{

    self.myFile = myFile;
    NSString *mimeType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)(myFile.uti), kUTTagClassMIMEType);
    [_webView loadData:[myFile getData] MIMEType:mimeType textEncodingName:nil baseURL:[NSURL URLWithString:@"http://www.example.com"]];
    self.view.userInteractionEnabled = YES;
    
    // Enable our view for Ink
    // Uses dynamic blob so that if the file is big or slow to load it won't block the Ink dialog
    [self.view INKEnableWithUTI:myFile.uti dynamicBlob:^INKBlob *{
        INKBlob *blob = [INKBlob blobFromData:[myFile getData]];
        blob.uti = myFile.uti;
        blob.filename = myFile.fileName;
        return blob;
    } returnBlock:^(INKBlob *blob, INKAction *action, NSError *error) {
        if ([action.type isEqualToString: INKActionType_Return]) {
            [self saveBlob: blob withFilename:myFile.fileName];
        } else {
            // Return_Cancel
            NSLog(@"Return cancel.");
        }
    }];
    
    // Adds the Ink button to the top right corner
    UIButton * button = [self.view INKAddLaunchButton];
    if (button) {
        inkButton = button;
    }
    
    if (shouldHideMaster){
        if (self.masterPopoverController != nil) {
            [self.masterPopoverController dismissPopoverAnimated:YES];
        }
    }
    
    UIBarButtonItem *pairing = [[UIBarButtonItem alloc] initWithTitle:@"Share" style:UIBarButtonItemStylePlain target:self action:@selector(showPairingCode:)];
    
    UIBarButtonItem *receive = [[UIBarButtonItem alloc] initWithTitle:@"Receive File" style:UIBarButtonItemStylePlain target:self action:@selector(redeemPairingCode:)];

    UIBarButtonItem *move = [[UIBarButtonItem alloc] initWithTitle:@"Copy to" style:UIBarButtonItemStylePlain target:self action:@selector(moveFile:)];
    
    self.navigationItem.rightBarButtonItems = @[receive, pairing, move];
    if (!myFile.fphandle){
        self.navigationItem.rightBarButtonItems = @[receive];
    }

    self.navigationItem.prompt = nil;
}

- (void) viewWillLayoutSubviews {
    //Make sure we're aligned properly
    if (inkButton) {
        inkButton.frame = CGRectMake(self.view.frame.size.width - inkButton.frame.size.width - 20.0, inkButton.frame.origin.y,
            inkButton.frame.size.width, inkButton.frame.size.height);
    }
}

- (void) saveBlob:(INKBlob *)blob withFilename:(NSString *) filename {
    NSLog(@"Saving the blob");
    [self.myFile loadFromInkBlob:blob];
    blob.filename = filename;
    
    // There has to be some base url, but it's never actually shown.
    [_webView loadData:[self.myFile getData] MIMEType:self.myFile.mimetype textEncodingName:nil baseURL:[NSURL URLWithString:@"http://www.example.com"]];
    [self filepickerPost:blob];
}

- (void) filepickerPost:(INKBlob *)blob {
    NSString *mimeType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)(blob.uti), kUTTagClassMIMEType);
    
    [FPLibrary uploadData:blob.data named:blob.filename toPath:self.myFile.inkPath ofMimetype:mimeType withOptions:nil success:^(id JSON) {
        // ok
        NSLog(@"File stored successful");
    }failure:^(NSError *error, id JSON) {
        NSLog(@"Fail to save the fail: %@, %@", error, JSON);
        // TODO: retry or something
    }];
}

- (void)showPairingCode:(id)sender {

    PairingViewController *vc = [[PairingViewController alloc] initWithHandle:self.myFile.fphandle];
    
    UINavigationController *nv = [[UINavigationController alloc] init];
    [nv pushViewController:vc animated:YES];
    nv.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:nv animated:YES completion:nil];
    
}

- (void)redeemPairingCode:(id)sender {
    PairingReceiveViewController *vc = [[PairingReceiveViewController alloc] init];
    
    UINavigationController *nv = [[UINavigationController alloc] init];
    [nv pushViewController:vc animated:YES];
    nv.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:nv animated:YES completion:nil];

}

- (void)moveFile:(id)sender {
    
    SourceListSaveController *sc = [[SourceListSaveController alloc] init];
    sc.fpdelegate = self;
    sc.dataType = self.myFile.mimetype;
    sc.data = [self.myFile getData];
    sc.proposedFilename = [self.myFile.fileName stringByDeletingPathExtension];
    
    sc.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self presentViewController:sc animated:YES completion:nil];
}



- (void)FPSaveControllerDidSave:(SourceListSaveController *)picker {
    //user selected save. save not complete yet.
}

- (void)FPSaveControllerDidCancel:(SourceListSaveController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)FPSaveController:(SourceListSaveController *)picker didError:(NSDictionary *)info {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)FPSaveController:(SourceListSaveController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated:NO completion:nil];
}



#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Menu", @"Menu");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

@end
