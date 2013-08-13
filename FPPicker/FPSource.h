//
//  FPSource.h
//  FPPicker
//
//  Created by Liyan David Chang on 7/7/12.
//  Copyright (c) 2012 Filepicker.io (Couldtop Inc.). All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FPSource : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *icon;
@property (nonatomic, strong) NSString *rootUrl;
@property (nonatomic, strong) NSArray *open_mimetypes;
@property (nonatomic, strong) NSArray *save_mimetypes;
@property (nonatomic, strong) NSArray *mimetypes;
@property (nonatomic, strong) NSArray *externalDomains;
@property (nonatomic) BOOL overwritePossible;


- (NSString *) mimetypeString;

@end
