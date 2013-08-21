//
//  FPSearchController.h
//  FPPicker
//
//  Created by Liyan David Chang on 6/20/12.
//  Copyright (c) 2012 Ink (Cloudtop Inc), All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FPInternalHeaders.h"
#import "FileSourceController.h"

@interface FPSearchController : FileSourceController <UISearchDisplayDelegate>

@property (nonatomic, strong) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) IBOutlet UISearchDisplayController *searchDisplayController;

@end
