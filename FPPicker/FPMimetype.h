//
//  FPMimetype.h
//  Bin
//
//  Created by Liyan David Chang on 7/28/13.
//  Copyright (c) 2013 Ink (Cloudtop Inc). All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FPMimetype : NSObject

+ (NSString*) iconPathForMimetype: (NSString *)mimetype;
+ (BOOL) mimetypeCheck:(NSArray *)mimes1 against:(NSArray *)mimes2;

@end
