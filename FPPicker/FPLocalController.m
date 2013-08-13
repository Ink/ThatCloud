//
//  FPLocalController.m
//  FPPicker
//
//  Created by Liyan David Chang on 6/20/12.
//  Copyright (c) 2012 Ink (Cloudtop Inc), All rights reserved.
//

#import "FPLocalController.h"

@interface FPLocalController ()

@property int padding;
@property int numPerRow;
@property int thumbSize;
@property UILabel *emptyLabel;

@end

@implementation FPLocalController

@synthesize photos = _photos;
@synthesize fpdelegate;
@synthesize assetGroup = _assetGroup;
@synthesize padding, numPerRow, thumbSize;
@synthesize emptyLabel = _emptyLabel;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    NSInteger gCount = [self.assetGroup numberOfAssets];

    self.title = [NSString stringWithFormat:@"%@ (%d)",[self.assetGroup valueForProperty:ALAssetsGroupPropertyName], gCount];
    
    //Register for the app switch focus event. Reload the data so things show up immeadiately.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadPhotoData) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void) viewWillAppear:(BOOL)animated  {
   
    [self loadPhotoData];
    [super viewWillAppear:animated];

}

- (void) loadPhotoData {
    
    self.contentSizeForViewInPopover = fpWindowSize;
    
    CGRect bounds = [self getViewBounds];
    self.thumbSize = fpLocalThumbSize;
    self.numPerRow = (int) bounds.size.width/self.thumbSize;
    self.padding = (int)((bounds.size.width - numPerRow*self.thumbSize)/ ((float)numPerRow + 1));
    if (padding < 4){
        self.numPerRow -= 1;
        self.padding = (int)((bounds.size.width - numPerRow*self.thumbSize)/ ((float)numPerRow + 1));
    }
    NSLog(@"numperro; %d", self.numPerRow);

    //Just make one instance empty label
    _emptyLabel  = [[UILabel alloc] initWithFrame:CGRectMake(0, (bounds.size.height)/2-60, bounds.size.width, 30)];
    [_emptyLabel setTextColor:[UIColor grayColor]];
    [_emptyLabel setTextAlignment:NSTextAlignmentCenter];
    [_emptyLabel setText:@"Nothing Available"];
    
    // collect the things
    NSMutableArray *collector = [[NSMutableArray alloc] initWithCapacity:0];
    
    [self.assetGroup enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop) {
      if (asset) {
          [collector addObject:asset];
      }
    }];
    NSLog(@"%d things presented", [collector count]);
    NSArray* reversed = [[collector reverseObjectEnumerator] allObjects];

    [self setPhotos:reversed];
    [self.tableView reloadData];
}


-(void)setPhotos:(NSArray *)photos {

    if (_photos != photos) {
        _photos = photos;
    }

    // In theory, you should be able to do this only if you update.
    // However, this seems safer to make sure that the empty label gets removed.
    if ([_photos count] == 0) {
        [self.view addSubview:_emptyLabel];
    } else {
        [_emptyLabel removeFromSuperview];
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (int)ceil([self.photos count]/(self.numPerRow*1.0));
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTappedWithGesture:)];
    [cell.contentView addGestureRecognizer:tap];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    CGRect rect = CGRectMake(self.padding, self.padding, self.thumbSize, self.thumbSize);
    
    for (int i=0; i<self.numPerRow; i++) {
        int index = self.numPerRow*indexPath.row + i;
        NSLog(@"Index %d", index);
        if (index >= [self.photos count]){
            break;
        }
        
        ALAsset *asset = [self.photos objectAtIndex:index];
        
        UIImageView *image = [[UIImageView alloc] initWithFrame:rect];
        image.tag = index;
        image.image = [UIImage imageWithCGImage:[asset thumbnail]];
        image.contentMode = UIViewContentModeScaleAspectFill;
        image.clipsToBounds = YES;
        
        NSString *uti = [[asset defaultRepresentation] UTI];
        if ([uti isEqualToString:@"com.apple.quicktime-movie"]){
            //ALAssetRepresentation *rep = [asset defaultRepresentation];
                NSLog(@"data: %@", [asset valueForProperty:ALAssetPropertyDuration]);
            UIImage *videoOverlay = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]  pathForResource:@"glyphicons_180_facetime_video" ofType:@"png"]];
            
            UIImage *backgroundImage = image.image;
            UIImage *watermarkImage = videoOverlay;
            
            UILabel *headingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, backgroundImage.size.height - 10, backgroundImage.size.width, 10)];
            [headingLabel setTextColor:[UIColor whiteColor]];
            [headingLabel setBackgroundColor:[UIColor blackColor]];
            [headingLabel setAlpha:0.7];
            [headingLabel setFont:[UIFont systemFontOfSize:14]];
            [headingLabel setTextAlignment:NSTextAlignmentRight];
            headingLabel.text = [FPLibrary formatTimeInSeconds: ceil([[asset valueForProperty:ALAssetPropertyDuration] doubleValue])];

            
            UIGraphicsBeginImageContext(backgroundImage.size);
            [backgroundImage drawInRect:CGRectMake(0, 0, backgroundImage.size.width, backgroundImage.size.height)];
            [watermarkImage drawInRect:CGRectMake(5, backgroundImage.size.height - watermarkImage.size.height - 5, watermarkImage.size.width, watermarkImage.size.height)];
            [headingLabel drawTextInRect:CGRectMake(0, backgroundImage.size.height - watermarkImage.size.height -3 , backgroundImage.size.width-5, 10)];
            
            UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            image.image = result;
            
        }

        
        [cell.contentView addSubview:image];
        rect = CGRectMake((rect.origin.x+self.thumbSize+self.padding), rect.origin.y, rect.size.width, rect.size.height);
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.thumbSize + self.padding;
}

#pragma mark - Table view delegate

- (IBAction)singleTappedWithGesture:(UIGestureRecognizer *)sender
{
    CGPoint tapPoint = [sender locationOfTouch:sender.view.tag inView:sender.view];
    
    int colIndex = (int) fmin(floor(tapPoint.x/(self.thumbSize+self.padding)), self.numPerRow-1);
    
    //Do nothing if there isn't a corresponding image view.
    if (colIndex >= [sender.view.subviews count]){
        return;
    }
    
    [FPMBProgressHUD showHUDAddedTo:self.view animated:NO];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void){
        UIImageView *selectedView = [sender.view.subviews objectAtIndex:colIndex];
        [self objectSelectedAtIndex:selectedView.tag];    
    });
}

- (void) objectSelectedAtIndex:(NSInteger) index {

    
    ALAsset *asset = [self.photos objectAtIndex:index];
    ALAssetRepresentation *representation = [asset defaultRepresentation];

    dispatch_async(dispatch_get_main_queue(),^{
        [fpdelegate FPSourceController:nil didPickMediaWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                             [UIImage imageWithCGImage:[asset thumbnail]], @"FPPickerControllerThumbnailImage" , nil]];
    });
    
    //NSLog(@"Selected Contents: %@", asset);
    //NSLog(@"Type: %@", [asset valueForProperty:@"ALAssetPropertyType"]);
    
    NSLog(@"Asset: %@", asset);

    NSString *filename;
    if ([representation respondsToSelector:@selector(filename)]){
        filename = [representation filename];
    } else {
        NSString *extension = (__bridge_transfer NSString*)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)[representation UTI], kUTTagClassFilenameExtension); 
        filename = [NSString stringWithFormat:@"file.%@", extension];
    }
    
    BOOL shouldUpload = YES;
    if ([fpdelegate isKindOfClass:[FPPickerController class]]){
        NSLog(@"Should I upload?");
        FPPickerController *pickerC = (FPPickerController *)fpdelegate;
        shouldUpload = [pickerC shouldUpload];
    }

    NSLog(@"should upload: %@", shouldUpload?@"YES":@"NO");
    
    if ([[asset valueForProperty:@"ALAssetPropertyType"] isEqual:(NSString*) ALAssetTypePhoto]){
        
        ALAssetRepresentation *representation = [asset defaultRepresentation];
        //NSLog(@"Repre: %@", representation);
        //NSDictionary *imageMetadata = [representation metadata];
        //NSLog(@"meta: %@", imageMetadata);
        
        
        //BOOL isIOS5 = [[[UIDevice currentDevice] systemVersion] floatValue] >= 5.0;
        
        UIImage* image = [UIImage imageWithCGImage:[representation fullResolutionImage] 
                                        scale:[representation scale] orientation:(UIImageOrientation)[representation orientation]];
        
        NSLog(@"uti: %@", [representation UTI]);

        
        [FPLibrary uploadAsset:asset withOptions:[[NSDictionary alloc] init] shouldUpload:shouldUpload success:^(id JSON, NSURL *localurl) {
            NSLog(@"JSON %@", JSON);
            NSLog(@"JSON %@", [[[[JSON objectForKey:@"data"] objectAtIndex:0] objectForKey:@"data"] objectForKey:@"filename"]);
            NSDictionary *output = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    (NSString*) kUTTypeImage, @"FPPickerControllerMediaType",
                                    image, @"FPPickerControllerOriginalImage",
                                    localurl, @"FPPickerControllerMediaURL",
                                    [[[JSON objectForKey:@"data"]  objectAtIndex:0] objectForKey:@"url"], @"FPPickerControllerRemoteURL",
                                    [[[[JSON objectForKey:@"data"] objectAtIndex:0] objectForKey:@"data"] objectForKey:@"filename"], @"FPPickerControllerFilename",
                                    [[[[JSON objectForKey:@"data"] objectAtIndex:0] objectForKey:@"data"] objectForKey:@"key"], @"FPPickerControllerKey",
                                    nil];
            dispatch_async(dispatch_get_main_queue(),^{
                [FPMBProgressHUD hideAllHUDsForView:self.view animated:YES];
                //NSLog(@"INFO %@:", output);
                [fpdelegate FPSourceController:nil didFinishPickingMediaWithInfo:output];
            });
            
        } failure:^(NSError *error, id JSON, NSURL *localurl) {
            NSDictionary *output = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    (NSString*) kUTTypeImage, @"FPPickerControllerMediaType",
                                    image, @"FPPickerControllerOriginalImage",
                                    localurl, @"FPPickerControllerMediaURL",
                                    @"", @"FPPickerControllerRemoteURL",
                                    filename, @"FPPickerControllerFilename",
                                    nil];
            //NSLog(@"INFO %@:", output);
            dispatch_async(dispatch_get_main_queue(),^{
                NSLog(@"Error %@:", error);
            
                [FPMBProgressHUD hideAllHUDsForView:self.view animated:YES];
                [fpdelegate FPSourceController:nil didFinishPickingMediaWithInfo:output];
            });

        }];
        return;
    } else if ([[asset valueForProperty:@"ALAssetPropertyType"] isEqual:(NSString*) ALAssetTypeVideo]){
                        
        [FPLibrary uploadAsset:asset withOptions:[[NSDictionary alloc] init] shouldUpload:shouldUpload success:^(id JSON, NSURL *localurl) {
            NSDictionary *output = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    (NSString *) kUTTypeVideo , @"FPPickerControllerMediaType",
                                    localurl, @"FPPickerControllerMediaURL",
                                    [[[JSON objectForKey:@"data"]  objectAtIndex:0] objectForKey:@"url"], @"FPPickerControllerRemoteURL",
                                    [[[[JSON objectForKey:@"data"] objectAtIndex:0] objectForKey:@"data"] objectForKey:@"filename"], @"FPPickerControllerFilename",
                                    [[[[JSON objectForKey:@"data"] objectAtIndex:0] objectForKey:@"data"] objectForKey:@"key"], @"FPPickerControllerKey",
                                    nil];
            dispatch_async(dispatch_get_main_queue(),^{
            [FPMBProgressHUD hideAllHUDsForView:self.view animated:YES];
            //NSLog(@"INFO %@:", output);
            [fpdelegate FPSourceController:nil didFinishPickingMediaWithInfo:output];
            });
            
        } failure:^(NSError *error, id JSON, NSURL *localurl) {
            NSDictionary *output = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    (NSString *) kUTTypeVideo , @"FPPickerControllerMediaType",
                                    localurl, @"FPPickerControllerMediaURL",
                                    @"", @"FPPickerControllerRemoteURL",
                                    filename, @"FPPickerControllerFilename",
                                    nil];
            //NSLog(@"INFO %@:", output);
            //NSLog(@"Error %@:", error);
            dispatch_async(dispatch_get_main_queue(),^{
            [FPMBProgressHUD hideAllHUDsForView:self.view animated:YES];
            [fpdelegate FPSourceController:nil didFinishPickingMediaWithInfo:output];
            });

        }];
        return;
        
        
    } else {
        dispatch_async(dispatch_get_main_queue(),^{
        NSLog(@"Type: %@", [asset valueForProperty:@"ALAssetPropertyType"]);
        NSLog(@"Didnt handle");
        [FPMBProgressHUD hideAllHUDsForView:self.view animated:YES];
        [fpdelegate FPSourceControllerDidCancel:nil];
        });

    }
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
