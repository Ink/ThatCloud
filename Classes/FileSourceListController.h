//
//  TableViewController.h
//  FPPicker
//
//  Created by Liyan David Chang on 6/20/12.
//  Copyright (c) 2013 Ink (Cloudtop Inc), All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FPPicker.h"
#import "FPInternalHeaders.h"
#import "FilePreviewViewController.h"


@interface FileSourceListController : UITableViewController <UIImagePickerControllerDelegate, UINavigationBarDelegate, Resetable>

@property (nonatomic, strong) NSArray *sourceNames;

@property (nonatomic, strong) NSMutableDictionary *sources;
@property (nonatomic, strong) id <FPSourcePickerDelegate> fpdelegate;
@property (nonatomic, assign) id <UINavigationControllerDelegate, UIImagePickerControllerDelegate> imgdelagate;
@property (strong, nonatomic) FilePreviewViewController *previewViewController;

@property (nonatomic, strong) NSArray *dataTypes;


- (void) switchToSource: (NSString *)sourceString;

@end
