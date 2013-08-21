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

@interface FPSampleSourceController : UITableViewController
@property (nonatomic, strong) NSMutableArray *contents;

@property (strong, nonatomic) FilePreviewViewController *previewViewController;

- (void) objectSelectedAtIndex:(NSInteger) index;

@end
