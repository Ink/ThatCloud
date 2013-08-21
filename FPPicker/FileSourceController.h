//
//  ServiceController.h
//  FPPicker
//
//  Created by Liyan David Chang on 6/20/12.
//  Copyright (c) 2013 Ink (Cloudtop Inc), All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "FPPicker.h"
#import "FPInternalHeaders.h"
#import "FilePreviewViewController.h"

@interface FileSourceController : UITableViewController
@property (nonatomic, strong, retain) NSString *path;
@property (nonatomic, strong) NSMutableArray *contents;

@property (nonatomic, strong) FPSource *sourceType;
@property (nonatomic, strong) NSString *viewType;
@property (nonatomic, strong) NSString *nextPage;
@property (nonatomic, strong) UIActivityIndicatorView *nextPageSpinner;

@property (nonatomic, strong) id <FPSourcePickerDelegate> fpdelegate;
@property (nonatomic, strong) NSMutableDictionary *precacheOperations;


@property (strong, nonatomic) FilePreviewViewController *previewViewController;

- (void) fpLoadContents:(NSString *)loadpath;
- (void) objectSelectedAtIndex:(NSInteger) index;
- (void) afterReload:(BOOL)success;

@end
