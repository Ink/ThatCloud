//
//  TestViewController.h
//  FPPicker
//
//  Created by Liyan David Chang on 6/20/12.
//  Copyright (c) 2012 Filepicker.io (Cloudtop Inc), All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FPInternalHeaders.h"
#import "FPConstants.h"
#import "FPConfig.h"

@interface FPAuthController : UIViewController <UIWebViewDelegate>

@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, strong) NSString *service;

@property (nonatomic) BOOL alreadyReload;
@end
