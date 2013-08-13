//
//  FPSource.m
//  FPPicker
//
//  Created by Liyan David Chang on 7/7/12.
//  Copyright (c) 2012 Filepicker.io (Couldtop Inc.). All rights reserved.
//

#import "FPSource.h"

@implementation FPSource

@synthesize name, identifier, icon, rootUrl, open_mimetypes, save_mimetypes, mimetypes, overwritePossible, externalDomains;

- (NSString *) mimetypeString {
    if ([self.mimetypes count] == 0){
        return @"[]";
    }
    return [NSString stringWithFormat:@"[\"%@\"]", [self.mimetypes componentsJoinedByString:@"\",\""]];
}

@end
