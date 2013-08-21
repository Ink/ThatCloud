//
//  FilePreviewViewController.h
//
//  Created by Liyan David Chang on 7/11/13.
//  Copyright (c) 2013 Ink (Cloudtop Inc). All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InkFile.h"
#import "FPPicker.h"

@protocol Resetable<NSObject>
@optional
// The picker does not dismiss itself; the client dismisses it in these callbacks.
// The delegate will receive one or the other, but not both, depending whether the user
// confirms or cancels.
- (void) reset;
- (bool) readyForSave;

@end

@interface FilePreviewViewController : UIViewController <UISplitViewControllerDelegate, UIWebViewDelegate, FPSaveDelegate>

@property (nonatomic) IBOutlet UIWebView *webView;
@property InkFile *myFile;
@property id <Resetable> master;

- (void) previewFile:(InkFile*)myFile;
- (void) showSpinner;
- (void) updateSpinner:(float)progress;
- (void) reset;
- (void) showNoPreviewScreen;

@end
