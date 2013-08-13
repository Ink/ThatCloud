//
//  TableViewController.m
//  FPPicker
//
//  Created by Liyan David Chang on 6/20/12.
//  Copyright (c) 2012 Filepicker.io (Cloudtop Inc), All rights reserved.
//

#import "FPSourceListController.h"

#import "FPLocalAlbumController.h"
#import "FPSourceController.h"
#import "FPSaveSourceController.h"
#import "FPSaveController.h"
#import "FPSearchController.h"
#import "FPInfoViewController.h"
#import "ATConnect.h"
#import <INK/InkCore.h>
#import "FPSampleSourceController.h"

#import "FlatUIKit.h"


@interface FPSourceListController ()

@end

@implementation FPSourceListController

@synthesize sources, fpdelegate, imgdelagate, sourceNames, dataTypes;

- (id)initWithStyle:(UITableViewStyle)style 
{
    self = [super initWithStyle:style];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.previewViewController = (FilePreviewViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    self.previewViewController.master = (id)self;
    [UIBarButtonItem configureFlatButtonsWithColor:[UIColor peterRiverColor]
                                  highlightedColor:[UIColor belizeHoleColor]
                                      cornerRadius:3];
    // Set the text of back button to be "back", regardless of title.
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    
    /*
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [btn addTarget:self action:@selector(infoButtonRequest) forControlEvents:UIControlEventTouchUpInside];
    btn.contentEdgeInsets = UIEdgeInsetsMake(0, -10, 0, 10);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
    */
    
    [self.navigationController.navigationBar configureFlatNavigationBarWithColor:[UIColor whiteColor]];
    
    [self loadContents];
    
    if ([self.sources count] == 0){
        //No services
        UILabel *emptyLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 200, 200, 20)];
        [emptyLabel setTextColor:[UIColor grayColor]];
        emptyLabel.text = @"No Services Available";
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        [self.view addSubview:emptyLabel];
        
    }
    
    self.tableView.separatorColor = [UIColor clearColor];
    if ([self isInSaveMode]) {
        [self.navigationController.toolbar setBackgroundImage:[UIImage imageWithColor:[UIColor whiteColor] cornerRadius:0] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault & UIBarMetricsLandscapePhone];
        self.title = @"Chose where to save your file";
        
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)];
        [cancelButton configureFlatButtonWithColor:[UIColor peterRiverColor] highlightedColor:[UIColor belizeHoleColor] cornerRadius:3];

        [self.navigationController setToolbarHidden:NO];
        [self setToolbarItems:[NSArray arrayWithObjects:cancelButton, nil]];
    }
}

- (void) cancelAction:(id) sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (bool) readyForSave {
    return [self.navigationController topViewController] == (id) self;
}

- (void) reset {
    self.dataTypes = [NSArray arrayWithObjects:@"*/*", nil];

    [self loadContents];
    [[self tableView] reloadData];
    [[self navigationController] popToRootViewControllerAnimated:YES];
    
    InkFile *selectedFile = [InkFile alloc];
    selectedFile.fileName = @"empty";
    [selectedFile writeData:[NSData alloc]];
    selectedFile.mode = @"Regular";
    [[self previewViewController] previewFile:selectedFile];
}
- (void) loadContents {
    //NSLog(@"sources: %@", sourceNames);
    
    if (sourceNames == nil){
        sourceNames = [[NSArray alloc] initWithObjects: FPSourceDropbox, FPSourceFacebook, FPSourceGmail, FPSourceBox, FPSourceGithub, FPSourceGoogleDrive, FPSourceInstagram, FPSourceFlickr, FPSourcePicasa, FPSourceSkydrive, FPSourceImagesearch, nil];
    }
    if (self.dataTypes == nil){
        self.dataTypes = [NSArray arrayWithObjects:@"*/*", nil];
    }
    
    NSMutableArray *local = [[NSMutableArray alloc ] init];
    NSMutableArray *cloud = [[NSMutableArray alloc ] init];
    
    for (NSString *source in sourceNames){
        FPSource *sourceObj = [[FPSource alloc] init];
        sourceObj.identifier = source;
        
        if (source == FPSourceCamera) {
            sourceObj.name = @"Camera";
            sourceObj.icon = @"glyphicons_011_camera";
            sourceObj.rootUrl = @"/Camera";
            sourceObj.open_mimetypes = [NSArray arrayWithObjects:@"video/quicktime", @"image/jpeg", @"image/png", nil];
            sourceObj.save_mimetypes = [NSArray arrayWithObjects: nil];
            sourceObj.overwritePossible = NO;
            sourceObj.externalDomains = [NSArray arrayWithObjects: nil];
        } else if (source == FPSourceCameraRoll){
            sourceObj.name = @"Albums";
            sourceObj.icon = @"glyphicons_008_film";
            sourceObj.rootUrl = @"/Albums";
            sourceObj.open_mimetypes = [NSArray arrayWithObjects:@"image/jpeg", @"image/png", @"video/quicktime", nil];
            sourceObj.save_mimetypes = [NSArray arrayWithObjects: @"image/jpeg", @"image/png", nil];
            sourceObj.overwritePossible = NO;
            sourceObj.externalDomains = [NSArray arrayWithObjects: nil];
        } else if (source == FPSourceBox) {
            sourceObj.name = @"Box";
            sourceObj.icon = @"glyphicons_sb2_box";
            sourceObj.rootUrl = @"/Box";
            sourceObj.open_mimetypes = [NSArray arrayWithObjects:@"*/*", nil];
            sourceObj.save_mimetypes = [NSArray arrayWithObjects:@"*/*", nil];
            sourceObj.overwritePossible = YES;
            sourceObj.externalDomains = [NSArray arrayWithObjects:@"https://www.box.com", nil];
        } else if (source == FPSourceDropbox) {
            sourceObj.name = @"Dropbox";
            sourceObj.icon = @"glyphicons_361_dropbox";
            sourceObj.rootUrl = @"/Dropbox";
            sourceObj.open_mimetypes = [NSArray arrayWithObjects:@"*/*", nil];
            sourceObj.save_mimetypes = [NSArray arrayWithObjects:@"*/*", nil];
            sourceObj.overwritePossible = YES;
            sourceObj.externalDomains = [NSArray arrayWithObjects:@"https://www.dropbox.com", nil];
        } else if (source == FPSourceFacebook) {
            sourceObj.name = @"Facebook";
            sourceObj.icon = @"glyphicons_390_facebook";
            sourceObj.rootUrl = @"/Facebook";
            sourceObj.open_mimetypes = [NSArray arrayWithObjects:@"image/jpeg", nil];
            sourceObj.save_mimetypes = [NSArray arrayWithObjects:@"image/*", nil];
            sourceObj.overwritePossible = NO;
            sourceObj.externalDomains = [NSArray arrayWithObjects:@"https://www.facebook.com", nil];
        } else if (source == FPSourceGithub) {
            sourceObj.name = @"Github";
            sourceObj.icon = @"glyphicons_381_github";
            sourceObj.rootUrl = @"/Github";
            sourceObj.open_mimetypes = [NSArray arrayWithObjects:@"*/*", nil];
            sourceObj.save_mimetypes = [NSArray arrayWithObjects: nil];
            sourceObj.overwritePossible = NO;
            sourceObj.externalDomains = [NSArray arrayWithObjects:@"https://www.github.com", nil];
        } else if (source == FPSourceGmail) {
            sourceObj.name = @"Gmail";
            sourceObj.icon = @"glyphicons_sb1_gmail";
            sourceObj.rootUrl = @"/Gmail";
            sourceObj.open_mimetypes = [NSArray arrayWithObjects:@"*/*", nil];
            sourceObj.save_mimetypes = [NSArray arrayWithObjects: nil];
            sourceObj.overwritePossible = NO;
            sourceObj.externalDomains = [NSArray arrayWithObjects:@"https://www.google.com", @"https://accounts.google.com", @"https://google.com", nil];
        } else if (source == FPSourceImagesearch) {
            sourceObj.name = @"Web Images";
            sourceObj.icon = @"glyphicons_027_search";
            sourceObj.rootUrl = @"/Imagesearch";
            sourceObj.open_mimetypes = [NSArray arrayWithObjects:@"image/jpeg", nil];
            sourceObj.save_mimetypes = [NSArray arrayWithObjects: nil];
            sourceObj.overwritePossible = NO;
            sourceObj.externalDomains = [NSArray arrayWithObjects: nil];
        } else if (source == FPSourceGoogleDrive) {
            sourceObj.name = @"Google Drive";
            sourceObj.icon = @"GoogleDrive";
            sourceObj.rootUrl = @"/GDrive";
            sourceObj.open_mimetypes = [NSArray arrayWithObjects:@"*/*", nil];
            sourceObj.save_mimetypes = [NSArray arrayWithObjects:@"*/*", nil];
            sourceObj.overwritePossible = NO;
            sourceObj.externalDomains = [NSArray arrayWithObjects:@"https://www.google.com", @"https://accounts.google.com", @"https://google.com", nil];
        } else if (source == FPSourceFlickr) {
            sourceObj.name = @"Flickr";
            sourceObj.icon = @"glyphicons_395_flickr";
            sourceObj.rootUrl = @"/Flickr";
            sourceObj.open_mimetypes = [NSArray arrayWithObjects:@"image/*", nil];
            sourceObj.save_mimetypes = [NSArray arrayWithObjects:@"image/*", nil];
            sourceObj.overwritePossible = NO;
            sourceObj.externalDomains = [NSArray arrayWithObjects:@"https://*.flickr.com", @"http://*.flickr.com", nil];
        } else if (source == FPSourcePicasa) {
            sourceObj.name = @"Picasa";
            sourceObj.icon = @"glyphicons_366_picasa";
            sourceObj.rootUrl = @"/Picasa";
            sourceObj.open_mimetypes = [NSArray arrayWithObjects:@"image/*", nil];
            sourceObj.save_mimetypes = [NSArray arrayWithObjects:@"image/*", nil];
            sourceObj.overwritePossible = YES;
            sourceObj.externalDomains = [NSArray arrayWithObjects:@"https://www.google.com", @"https://accounts.google.com", @"https://google.com", nil];
        } else if (source == FPSourceInstagram) {
            sourceObj.name = @"Instagram";
            sourceObj.icon = @"Instagram";
            sourceObj.rootUrl = @"/Instagram";
            sourceObj.open_mimetypes = [NSArray arrayWithObjects:@"image/jpeg", nil];
            sourceObj.save_mimetypes = [NSArray arrayWithObjects: nil];
            sourceObj.overwritePossible = YES;
            sourceObj.externalDomains = [NSArray arrayWithObjects:@"https://www.instagram.com",  @"https://instagram.com", nil];
        } else if (source == FPSourceSkydrive) {
            sourceObj.name = @"SkyDrive";
            sourceObj.icon = @"glyphicons_sb3_skydrive";
            sourceObj.rootUrl = @"/SkyDrive";
            sourceObj.open_mimetypes = [NSArray arrayWithObjects:@"*/*", nil];
            sourceObj.save_mimetypes = [NSArray arrayWithObjects:@"*/*", nil];
            sourceObj.overwritePossible = YES;
            sourceObj.externalDomains = [NSArray arrayWithObjects:@"https://login.live.com",  @"https://skydrive.live.com", nil];
        }
        
        NSArray *source_mimetypes;
        if ([self isInSaveMode]) {
            source_mimetypes = sourceObj.save_mimetypes;
        } else {
            source_mimetypes = sourceObj.open_mimetypes;
        }
        
        if ([self mimetypeCheck:source_mimetypes against:self.dataTypes]){
            sourceObj.mimetypes = self.dataTypes;
            if (source == FPSourceCamera || source == FPSourceCameraRoll){
                [local addObject:sourceObj];
            } else {
                [cloud addObject:sourceObj];
            }
        }
        
    }
    
    [self setTitle:@"That Cloud"];
    NSString *cloudTitle = @"Cloud";
    
    
    self.sources = [[NSMutableDictionary alloc ] init];
    if ([local count] > 0){
        [ self.sources setObject:local forKey:@"Local"];
    }
    if ([cloud count] > 0){
        [ self.sources setObject:cloud forKey:cloudTitle];
    }
}

- (bool) isInSaveMode {
    return ([fpdelegate class] == [FPSaveController class]);
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.sources count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([self.sources count] <= 1){
        return nil;
    } else {
        return [[self.sources allKeys] objectAtIndex:section];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *sourceCategory = [[self.sources allKeys] objectAtIndex:section];
    return [[self.sources valueForKey:sourceCategory] count] + 3; //samples, spacer, feedback
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = fpCellIdentifier;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    int count = [[self.sources valueForKey:@"Cloud"] count];
    int index = indexPath.row;
    if (index == 0) {
        cell.textLabel.text = @"Sample Files";
        cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];

        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"glyphicons_144_folder_open" ofType:@"png"]];
        return cell;
    } else if (index == count + 1) {
        //Blank spacer
        cell.userInteractionEnabled = NO;
        return cell;
    } else if (index == count + 2) {
        //feedback
        cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
        cell.textLabel.text = @"Feedback";
        return cell;
    }
    index--;
    NSString *sourceCategory = [[self.sources allKeys] objectAtIndex:indexPath.section];
    FPSource *source = [[self.sources valueForKey:sourceCategory] objectAtIndex:index];
    
    cell.textLabel.text = source.name;
    cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    if ([fpdelegate class] == [FPSaveController class] && source.identifier == FPSourceCameraRoll){
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    if (source.identifier == FPFeedback) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    cell.imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:source.icon ofType:@"png"]];
    
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

- (void)viewDidAppear:(BOOL)animated {
    [self.previewViewController reset];
}

- (IBAction)temp:(id)sender {
    [self storeBlob:nil];
}

- (void)storeBlob:(INKBlob *)blob {
    
    NSLog(@"Store received: %@", blob);
    NSString *mimeType = ( NSString *)CFBridgingRelease(UTTypeCopyPreferredTagWithClass(( CFStringRef)CFBridgingRetain((blob .uti)), kUTTagClassMIMEType));

    
    FPSaveController *sc = [[FPSaveController alloc] init];
    sc.dataType = mimeType;
    sc.data = blob.data;
    sc.proposedFilename = blob.filename;
    
    sc.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:sc animated:YES completion:nil];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int count = [[self.sources valueForKey:@"Cloud"] count];
    int index = indexPath.row;
    if (index == 0) {
        //Sample files
        FPSampleSourceController *sView = [[FPSampleSourceController alloc] init];
        [self.navigationController pushViewController:sView animated:NO];
        return;
    } else if (index == count + 1) {
        //Spacer
        return;
    } else if (index == count + 2) {
        //Feedback
        ATConnect *connection = [ATConnect sharedConnection];
        [connection presentMessageCenterFromViewController:self];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    index--;
    NSString *sourceCategory = [[self.sources allKeys] objectAtIndex:indexPath.section];
    FPSource *source = [[self.sources valueForKey:sourceCategory] objectAtIndex:index];

    //NSLog(@"Source %@", source);

    if (source.identifier == FPSourceCamera)
    {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
            UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
            imgPicker.delegate = self.imgdelagate;
            imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            
            if ([fpdelegate isKindOfClass:[FPPickerController class]]){
                FPPickerController *picker = ((FPPickerController *)fpdelegate);
                
                //UIImagePickerController Properties

                NSArray *allMediaTypes =
                    [UIImagePickerController availableMediaTypesForSourceType:imgPicker.sourceType];
                NSMutableArray *wantedMediaTypes = [[NSMutableArray alloc] init];
                
                NSLog(@"ALL TYPES: %@", allMediaTypes);
                if ([allMediaTypes containsObject:(NSString*)kUTTypeImage]){
                    NSLog(@"CAN DO IMAGES");
                    NSArray *images = [NSArray arrayWithObjects:@"image/jpeg", @"image/png", nil];
                    NSLog(@"SHOULD DO IMAGES");
                    if ([self mimetypeCheck:images against:self.dataTypes]){
                        [wantedMediaTypes addObject:(NSString*)kUTTypeImage];
                    }
                }

                if ([allMediaTypes containsObject:(NSString*)kUTTypeMovie]){
                    NSLog(@"CAN DO VIDEO");
                    if ([self.dataTypes containsObject:(NSString*)@"video/quicktime"]){
                        NSLog(@"SHOULD DO VIDEO");
                        [wantedMediaTypes addObject:(NSString*)kUTTypeMovie];
                    }
                }

                imgPicker.mediaTypes = wantedMediaTypes;

                
                imgPicker.allowsEditing = picker.allowsEditing;
                imgPicker.videoQuality = picker.videoQuality;
                imgPicker.videoMaximumDuration = picker.videoMaximumDuration;
                imgPicker.showsCameraControls = picker.showsCameraControls;
                imgPicker.cameraOverlayView = picker.cameraOverlayView;
                imgPicker.cameraViewTransform = picker.cameraViewTransform;
                imgPicker.cameraDevice = picker.cameraDevice;
                imgPicker.cameraFlashMode = picker.cameraFlashMode;
            }
            [[UIApplication sharedApplication] setStatusBarHidden:YES];

            [self presentViewController:imgPicker animated:YES completion:nil];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"No Camera Available"
                                       message:@"This device doesn't seem to have a camera available."
                                      delegate:nil
                             cancelButtonTitle:@"OK"
                             otherButtonTitles:nil] show];
        }
    }
    else if (source.identifier == FPSourceCameraRoll)
    {
        if ([fpdelegate class] == [FPSaveController class]){
            FPSaveController *saveC = (FPSaveController *)fpdelegate;
            [saveC saveFileLocally];
        } else {
            FPLocalAlbumController *sView = [[FPLocalAlbumController alloc] init];
            sView.sourceType = source;
            sView.fpdelegate = fpdelegate;
            [self.navigationController pushViewController:sView animated:YES];
        }
    } 
    else if (source.identifier == FPSourceImagesearch)
    {
        FPSearchController *sView = [[FPSearchController alloc] init];
        sView.sourceType = source;
        sView.fpdelegate = fpdelegate;
        [self.navigationController pushViewController:sView animated:YES];
    }
    else 
    {
        FPSourceController *sView;
        if ([fpdelegate class] == [FPSaveController class]){
            sView = [[FPSaveSourceController alloc] init];
        } else {
            sView = [[FPSourceController alloc] init];
        }
        sView.sourceType = source;
        sView.fpdelegate = fpdelegate;
        [self.navigationController pushViewController:sView animated:NO];
    }
}

- (void) switchToSource: (NSString *)sourceString {
    [self loadContents];
    FPSourceController *sView;
    if ([fpdelegate class] == [FPSaveController class]){
        sView = [[FPSaveSourceController alloc] init];
    } else {
        sView = [[FPSourceController alloc] init];
    }
    FPSource *source = [self getSourceForName: sourceString];
    sView.sourceType = source;
    sView.fpdelegate = fpdelegate;
    //NOTE: Animating this means that save as into unauthed service will crash.
    [self.navigationController pushViewController:sView animated:NO];
}

- (FPSource *) getSourceForName: (NSString *)name {
    for (FPSource *source in [sources valueForKey:@"Cloud"]) {
        if ([source.name isEqualToString:name]) {
            return source;
        }
    }
    return nil;
}
- (void)viewWillAppear:(BOOL)animated {
    /*
    self.navigationController.toolbarHidden = NO;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0 , 0.0, 300, 21.0)];
    [titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:12]];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    [titleLabel setTextColor:[UIColor whiteColor]];
    [titleLabel setText:@"Powered by Filepicker.io"];
    [titleLabel setTextAlignment:NSTextAlignmentCenter];
    
    UIBarButtonItem *title = [[UIBarButtonItem alloc] initWithCustomView:titleLabel];
    [self setToolbarItems:[NSArray arrayWithObjects: title, nil]];
    */
    self.contentSizeForViewInPopover = fpWindowSize;
    [super viewWillAppear:animated];
}

- (BOOL) mimetypeCheck:(NSArray *)mimes1 against:(NSArray *)mimes2 {
    if ([mimes1 count] == 0 || [mimes2 count] == 0){
        return NO;
    }
    
    for (NSString *mimetype1 in mimes1){
        for (NSString *mimetype2 in mimes2){
            if ([mimetype1 isEqualToString:@"*/*"] || [mimetype2 isEqualToString:@"*/*"]){
                return YES;
            }
            if ([mimetype1 isEqualToString: mimetype2]){
                return YES;
            }
            NSArray *splitType1 = [mimetype1 componentsSeparatedByString:@"/"];
            NSArray *splitType2 = [mimetype2 componentsSeparatedByString:@"/"];
            if ([[splitType1 objectAtIndex:0] isEqualToString:[splitType2 objectAtIndex:0]]){
                return YES;
            }
        }
    }
    return NO;
}

- (void) cancelButtonRequest:(id)sender {
    NSLog(@"Cancel Button Pressed on Source List");
    [fpdelegate FPSourceControllerDidCancel:nil];
}

- (void) infoButtonRequest {
    NSLog(@"Info Button Pressed on Source List");
    
    FPInfoViewController *info = [FPInfoViewController alloc];
    [self.navigationController pushViewController:info animated:YES];
}

@end
