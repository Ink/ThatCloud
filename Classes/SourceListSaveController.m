//
//  NavigationController.m
//  FPPicker
//
//  Created by Liyan David Chang on 6/20/12.
//  Copyright (c) 2013 Ink (Cloudtop Inc), All rights reserved.
//

#import "FPInternalHeaders.h"
#import "SourceListSaveController.h"
#import "FileSourceListController.h"

@interface SourceListSaveController ()

@end

@implementation SourceListSaveController

@synthesize fpdelegate, sourceNames, data, dataurl, dataType, proposedFilename, dataExtension;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.delegate = self;
    
    if (fpAPIKEY == NULL || [fpAPIKEY isEqualToString:@""] || [fpAPIKEY isEqualToString:@"SET_FILEPICKER.IO_APIKEY_HERE"]){
        NSException* apikeyException = [NSException
                                        exceptionWithName:@"Filepicker Configuration Error"
                                        reason:@"APIKEY not set. You can get one at https://www.Ink and insert it into your project's info.plist as 'Filepicker API Key'"
                                        userInfo:nil];
        [apikeyException raise];
    }
    
    if (data == nil && dataurl == nil) {
        NSLog(@"WARNING: No data specified. Continuing but saving blank file.");
        data = [@"" dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    if (dataType == nil && dataExtension == nil){
        NSLog(@"WARNING: No data type or data extension specified");
    }

    FileSourceListController *fileSourceListController = [FileSourceListController alloc];
    fileSourceListController.fpdelegate = self;
    fileSourceListController.sourceNames = sourceNames;
    fileSourceListController.dataTypes = [NSArray arrayWithObjects:dataType, nil];
    
    fileSourceListController = [fileSourceListController init];
    
    
    [self pushViewController:fileSourceListController animated:YES];
    if (_startingSource != nil) {
        [fileSourceListController switchToSource:_startingSource];
    }
}

- (void) saveFileName:(NSString *)filename To:(NSString *)path {
    [FPMBProgressHUD showHUDAddedTo:self.view animated:YES];
    NSLog(@"saving %@ %@ to %@", filename, [self getExtensionString], path);
    filename = [filename stringByAppendingString:[self getExtensionString]];
    if (self.dataurl){
        [FPLibrary uploadDataURL:self.dataurl named:filename toPath:path ofMimetype:self.dataType withOptions:[[NSDictionary alloc] init] success:^(id JSON) {
            NSLog(@"Success %@", JSON);
            [FPMBProgressHUD hideAllHUDsForView:self.view animated:YES];
            NSDictionary *info = [[NSDictionary alloc] init ];
            [fpdelegate FPSaveController:self didFinishPickingMediaWithInfo:info];

        } failure:^(NSError *error, id JSON) {
            NSLog(@"FAIL.... %@ %@", error, JSON);
            [FPMBProgressHUD hideAllHUDsForView:self.view animated:YES];
            if ([fpdelegate respondsToSelector:@selector(FPSaveController:didError:)]) {
                [fpdelegate FPSaveController:self didError:JSON];
            } else {
                [fpdelegate FPSaveControllerDidCancel:self];
            }
        }];
    } else {
        [FPLibrary uploadData:self.data named:filename toPath:path ofMimetype:self.dataType withOptions:[[NSDictionary alloc] init] success:^(id JSON) {
            NSLog(@"Success %@", JSON);
            [FPMBProgressHUD hideAllHUDsForView:self.view animated:YES];
            NSDictionary *info = [[NSDictionary alloc] init ];
            [fpdelegate FPSaveController:self didFinishPickingMediaWithInfo:info];
            
        } failure:^(NSError *error, id JSON) {
            NSLog(@"FAIL.... %@ %@", error, JSON);
            [FPMBProgressHUD hideAllHUDsForView:self.view animated:YES];
            if ([fpdelegate respondsToSelector:@selector(FPSaveController:didError:)]) {
                [fpdelegate FPSaveController:self didError:JSON];
            } else {
                [fpdelegate FPSaveControllerDidCancel:self];
            }
        }];
    }
    
}

- (void) saveFileLocally {
    if ([fpdelegate respondsToSelector:@selector(FPSaveControllerDidSave:)]) {
        [fpdelegate FPSaveControllerDidSave:self];
    }
    
    [FPMBProgressHUD showHUDAddedTo:self.view animated:YES];
    if (self.dataurl){
        UIImageWriteToSavedPhotosAlbum([UIImage imageWithContentsOfFile:[self.dataurl absoluteString]], nil, nil, nil);
    } else {
        UIImageWriteToSavedPhotosAlbum([UIImage imageWithData: self.data], nil, nil, nil);
    }
    NSDictionary *info = [[NSDictionary alloc] init ];
    [fpdelegate FPSaveController:self didFinishPickingMediaWithInfo:info];

}



#pragma mark FPSourcePickerDelegate Methods

- (void)FPSourceController:(FileSourceController *)picker didPickMediaWithInfo:(NSDictionary *)info {
    if ([fpdelegate respondsToSelector:@selector(FPSaveControllerDidSave:)]) {
        [fpdelegate FPSaveControllerDidSave:self];
    }
}


- (void)FPSourceController:(FileSourceController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    
    //The user saved a file to the cloud or camera roll.
    NSLog(@"Saved something to a source: %@", info);
    
    [fpdelegate FPSaveController:self didFinishPickingMediaWithInfo:info];
    fpdelegate = nil;
    
}

- (void)FPSourceControllerDidCancel:(FileSourceController *)picker
{
    //The user chose to cancel when saving to the cloud or camera roll.
    NSLog(@"FP Save Canceled.");
    
    [fpdelegate FPSaveControllerDidCancel:self];
    fpdelegate = nil;

}

#pragma mark UIPopoverControllerDelegate Methods

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    [fpdelegate FPSaveControllerDidCancel:self];
    fpdelegate = nil;

}


#pragma mark UINavigationControllerDelegate Methods

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    return;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    return;
}

- (NSString *) getExtensionString {
    if (dataExtension){
        return [NSString stringWithFormat:@".%@", dataExtension];        
    } else if (dataType) {
        CFStringRef mimeType = (__bridge CFStringRef) self.dataType;
        CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType, NULL);
        CFStringRef extension = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassFilenameExtension);
        CFRelease(uti);
        if (extension){
            return [NSString stringWithFormat:@".%@", (__bridge_transfer NSString*) extension];
        } else {
            return @"";
        }
    } else {
        return @"";
    }
}

@end
