//
//  FPLocalAlbumController.h
//  FPPicker
//
//  Created by Liyan David Chang on 4/17/13.
//  Copyright (c) 2013 Ink (Cloudtop Inc.). All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "FPPicker.h"
#import "FPInternalHeaders.h"

@interface FPLocalAlbumController : UITableViewController

@property (nonatomic, strong) NSArray *albums;
@property (nonatomic, strong) id <FPSourcePickerDelegate> fpdelegate;
@property (nonatomic, strong) FPSource *sourceType;

@end
