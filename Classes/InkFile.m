//
//  InkFile.m
//
//  Created by Darko Vukovic on 7/11/13.
//  Copyright (c) 2013 Ink (Cloudtop Inc). All rights reserved.
//

#import "InkFile.h"
#import "FPInternalHeaders.h"


@implementation InkFile

@synthesize storageLocation, fileName, uti, mimetype, fphandle;

- (NSData *)getData {
    if (storageLocation == storedOnDisk) {
        return [NSData dataWithContentsOfFile:_filePath];
    } else if (storageLocation == storedInRAM) {
        return _data;
    } else {
        return nil;
    }
}

- (void)writeData:(NSData *)inputData {
    if (storageLocation == unset) {
        storageLocation = storedInRAM;
    }
    if (storageLocation == storedOnDisk) {
        [inputData writeToFile:_filePath atomically:NO];
    } else if (storageLocation == storedInRAM) {
        _data = inputData;
    }
}

- (void)loadFromInkBlob:(INKBlob *)blob {
    fileName = blob.filename;
    [self writeData:blob.data];
    uti = blob.uti;
    mimetype = (__bridge  NSString *)UTTypeCopyPreferredTagWithClass((__bridge  CFStringRef)(uti), kUTTagClassMIMEType);
}

@end
