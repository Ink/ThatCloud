//
//  FPConfig.h
//  FPPicker
//
//  Created by Liyan David Chang on 6/20/12.
//  Copyright (c) 2013 Ink (Cloudtop Inc), All rights reserved.
//

//To turn off logging for prod versions
#ifdef DEBUG
#   define NSForceLog(...) NSLog(__VA_ARGS__);
#   define NSLog(...) NSLog(__VA_ARGS__);
#else 
#   define NSForceLog(FORMAT, ...) fprintf(stderr,"[Ink Mobile Framework] %s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#   define NSLog(...)
#endif


/// Stick this in code you want to assert if run on the main UI thread.
#define DONT_BLOCK_UI() \
NSAssert(![NSThread isMainThread], @"Don't block the UI thread please!")

/// Stick this in code you want to assert if run on a background thread.
#define BLOCK_UI() \
NSAssert([NSThread isMainThread], @"You aren't running in the UI thread!")

#ifdef DEBUG
#define fpBASE_URL                  @"https://www.filepicker.io"
//#define fpBASE_URL                  @"https://www.fabric-io.net"
//#define fpBASE_URL                  @"https://www.fabricio.co"
//#define fpBASE_URL                  @"http://www.local-fp.com"
#else 
//Make sure release builds are always on prod.
#define fpBASE_URL                  @"https://www.filepicker.io"
#endif  


#define fpDEVICE_NAME               [[UIDevice currentDevice] name]
#define fpDEVICE_OS                 [[UIDevice currentDevice] systemName]
#define fpDEVICE_VERSION            [[UIDevice currentDevice] systemVersion]

#define fpDEVICE_TYPE               UI_USER_INTERFACE_IDIOM()
#define fpDEVICE_TYPE_IPAD          UIUserInterfaceIdiomPad
#define fpDEVICE_TYPE_IPHONE        UIUserInterfaceIdiomPhone

#define fpCOOKIES                   [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:fpBASE_URL]]
#define fpBASE_NSURL                [NSURL URLWithString:fpBASE_URL]

#define fpAPIKEY                    @"AEs7v6p1cQOOFrcZgDrGcz"

#define fpWindowSize                CGSizeMake(320, 480)


#define fpCellIdentifier            @"Filepicker_Cell"


#define fpLocalThumbSize            75
#define fpRemoteThumbSize           100


#define fpMaxChunkSize              262144 //.25mb
#define fpNumRetries                10

