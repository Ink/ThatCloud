//
//  InkFile.h
//  DropboxBrowser
//
//  Created by Darko Vukovic on 7/11/13.
//  Copyright (c) 2013 iRare Media. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <INK/InkCore.h>

typedef enum {
    unset,
    storedOnDisk,
    storedInRAM,
} StorageLocation;

@interface InkFile : NSObject

@property (strong, atomic) NSString *fileName;
@property (strong, atomic) NSString *filePath;
@property (strong, atomic) NSString *inkPath;
@property (strong, atomic) NSURL *fileURL;
@property (strong, atomic) NSString *destinationDirectory;
@property (strong, atomic) NSString *mode;
@property (strong, atomic) NSString *uti;
@property (strong, atomic) NSString *mimetype;
@property (strong, atomic) NSURL *inkurl;
@property (strong, atomic) NSData *data;
@property (strong, atomic) NSString *fphandle;
//@property (strong, atomic) DBMetadata *dbMetadata;
@property (atomic) StorageLocation storageLocation;

- (void)writeData:(NSData *)inputData;
- (NSData *)getData;
- (void)loadFromInkBlob:(INKBlob *)blob;
@end
