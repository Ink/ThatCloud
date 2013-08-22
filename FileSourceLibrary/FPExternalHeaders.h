//
//  FPExternalHeaders.h
//  FPPicker
//
//  Created by Liyan David Chang on 7/8/12.
//  Copyright (c) 2013 Ink (Cloudtop Inc.). All rights reserved.
//

#import <Foundation/Foundation.h>

@class FPPickerController;
@class SourceListSaveController;

@protocol FPPickerDelegate <NSObject>

- (void)FPPickerController:(FPPickerController *)picker didPickMediaWithInfo:(NSDictionary *) info;
- (void)FPPickerController:(FPPickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
- (void)FPPickerControllerDidCancel:(FPPickerController *)picker;

@end

@protocol FPSaveDelegate <NSObject>

- (void)FPSaveControllerDidSave:(SourceListSaveController *)picker;
- (void)FPSaveController:(SourceListSaveController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
- (void)FPSaveControllerDidCancel:(SourceListSaveController *)picker;
- (void)FPSaveController:(SourceListSaveController *)picker didError:(NSDictionary *)info;

@end

@class FileSourceController;

@protocol FPSourcePickerDelegate <NSObject>

- (void)FPSourceController:(FileSourceController *)picker didPickMediaWithInfo:(NSDictionary *) info;
- (void)FPSourceController:(FileSourceController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
- (void)FPSourceControllerDidCancel:(FileSourceController *)picker;

@end

@protocol FPSourceSaveDelegate <NSObject>

@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSURL *dataurl;
@property (nonatomic, strong) NSString *dataType;

- (void)FPSourceController:(FileSourceController *)picker didPickMediaWithInfo:(NSDictionary *) info;
- (void)FPSourceController:(FileSourceController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
- (void)FPSourceControllerDidCancel:(FileSourceController *)picker;

@end

