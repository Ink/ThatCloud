//
//  ServiceController.m
//  FPPicker
//
//  Created by Liyan David Chang on 6/20/12.
//  Copyright (c) 2013 Ink (Cloudtop Inc), All rights reserved.
//

#import "FPSampleSourceController.h"
#import "SourceListSaveController.h"
#import "FPAuthController.h"
#import "FPInternalHeaders.h"
#import "FPThumbCell.h"
#import "FPMimetype.h"

#import "FlatUIKit.h"
#import "ThatCloudConstants.h"

#import <QuartzCore/QuartzCore.h>

@interface FPSampleSourceController ()

@property int padding;
@property int numPerRow;
@property int thumbSize;
@property FPAFHTTPRequestOperation *downloadAndUpdatePreviewOperation;

@end

@implementation FPSampleSourceController

@synthesize contents;
@synthesize padding, numPerRow, thumbSize;
@synthesize downloadAndUpdatePreviewOperation;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    return self;
}

- (void)backButtonAction {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.contents = [NSMutableArray array];
    [self setTitle:@"Sample Files"];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorColor = [UIColor clearColor];
    
    [UIBarButtonItem configureFlatButtonsWithColor:[UIColor peterRiverColor]
                                  highlightedColor:[UIColor belizeHoleColor]
                                      cornerRadius:3];

    
    self.navigationItem.leftBarButtonItem =[[UIBarButtonItem alloc]initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonAction)];
    
    self.previewViewController = (FilePreviewViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    //get the documents directory:
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *bundleDocPath = [[NSBundle mainBundle] pathForResource:@"SampleDoc" ofType:@"pdf"];
    
    NSString *docPath = [documentsDirectory stringByAppendingPathComponent:@"SampleDoc.pdf"];
    [[NSFileManager defaultManager] copyItemAtPath:bundleDocPath toPath:docPath error:nil];
    InkFile *sampleDoc = [[InkFile alloc] init];
    sampleDoc.fileName = @"SampleDoc.pdf";
    sampleDoc.uti = @"com.adobe.pdf";
    sampleDoc.mimetype = @"application/pdf";
    sampleDoc.filePath = docPath;
    sampleDoc.storageLocation = storedOnDisk;
    [self.contents addObject:sampleDoc];
    
    NSString *bundleImagePath = [[NSBundle mainBundle] pathForResource:@"SampleImage" ofType:@"jpg"];
    NSString *imagePath = [documentsDirectory stringByAppendingPathComponent:@"SampleImage.jpg"];
    NSError *__autoreleasing *error = NULL;
    [[NSFileManager defaultManager] copyItemAtPath:bundleImagePath toPath:imagePath error:error];
    if (error) {
        NSLog(@"Error!");
    }
    
    InkFile *sampleImage = [[InkFile alloc] init];
    sampleImage.fileName = @"SampleImage.jpg";
    sampleImage.uti = @"public.jpeg";
    sampleImage.mimetype = @"image/jpeg";
    sampleImage.filePath = imagePath;
    sampleImage.storageLocation = storedOnDisk;
    [self.contents addObject:sampleImage];
}

- (void)viewWillAppear:(BOOL)animated {
    self.contentSizeForViewInPopover = fpWindowSize;
    
    CGRect bounds = [self getViewBounds];
    self.thumbSize = fpRemoteThumbSize;
    self.numPerRow = (int) bounds.size.width/self.thumbSize;
    self.padding = (int)((bounds.size.width - numPerRow*self.thumbSize)/ ((float)numPerRow + 1));
    if (padding < 4){
        self.numPerRow -= 1;
        self.padding = (int)((bounds.size.width - numPerRow*self.thumbSize)/ ((float)numPerRow + 1));
    }
        
    [super viewWillAppear:animated];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //remove the pull down login label if applicable.
    UIView *v = [self.view viewWithTag:[@"-1" integerValue]];
    if (v != nil){
        [v removeFromSuperview];
    }
    v = [self.view viewWithTag:[@"-2" integerValue]];
    if (v != nil) {
        [v removeFromSuperview];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.contents count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier = fpCellIdentifier;
    FPThumbCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil){
        cell = [[FPThumbCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.textColor = [UIColor blackColor];
        cell.imageView.alpha = 1.0;
        cell.imageView.image = nil;
        cell.textLabel.text = @"";
        cell.userInteractionEnabled = YES;
        
        for (UIView *view in cell.contentView.subviews){
            [view removeFromSuperview];
        }
    }
    cell.tag = indexPath.row;
    cell.textLabel.font = [UIFont fontWithName:LIGHTFONT size:18];
    
    
    if (indexPath.row >= [self.contents count]){ return cell; }
    InkFile *file = [self.contents objectAtIndex:indexPath.row];
    
    cell.textLabel.text = file.fileName;
    
    
    NSString *cell_mimetype = file.mimetype;
    if (cell_mimetype == (id)[NSNull null]) {
        cell_mimetype = @"unknown/whatever";
    }
    
    NSString *iconPath = [FPMimetype iconPathForMimetype:cell_mimetype];
    cell.imageView.image = [UIImage imageNamed:iconPath];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self objectSelectedAtIndex:indexPath.row];
}

- (IBAction)singleTappedWithGesture:(UIGestureRecognizer *)sender
{
    CGPoint tapPoint = [sender locationOfTouch:sender.view.tag inView:sender.view];
   
    int rowIndex = (int) fmin(floor(tapPoint.x/105), self.numPerRow - 1);
    
    //Do nothing if there isn't a corresponding image view.
    if (rowIndex >= [sender.view.subviews count]){
        return;
    }
    
    UIImageView *selectedView = [sender.view.subviews objectAtIndex:rowIndex];
    
    [self objectSelectedAtIndex:selectedView.tag];
}

- (void) objectSelectedAtIndex:(NSInteger) index {
    InkFile *selectedFile = [self.contents objectAtIndex:index];
    [[self previewViewController] previewFile:selectedFile];
}

- (CGRect)getViewBounds {
    CGRect bounds = self.view.bounds;

    UIView *parent = self.view.superview;
	if (parent) {
		bounds = parent.bounds;
	}
    return bounds;
}

@end
