//
//  TableViewController.m
//  FPPicker
//
//  Created by Liyan David Chang on 6/20/12.
//  Copyright (c) 2013 Ink (Cloudtop Inc), All rights reserved.
//

#import "FileSourceListController.h"

#import "FileSourceController.h"
#import "SaveController.h"
#import "SourceListSaveController.h"
#import "FPMimetype.h"
#import "ATConnect.h"
#import <INK/Ink.h>
#import "FPSampleSourceController.h"
#import "ThatCloudConstants.h"
#import "StandaloneStatsEmitter.h"

#import "FlatUIKit.h"


@interface FileSourceListController ()

@end

@implementation FileSourceListController

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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wenum-conversion"
        // Button style is for use with FlatUI
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)];
#pragma clang diagnostic pop
        [cancelButton configureFlatButtonWithColor:[UIColor peterRiverColor] highlightedColor:[UIColor belizeHoleColor] cornerRadius:3];

        [self.navigationController setToolbarHidden:NO];
        [self setToolbarItems:[NSArray arrayWithObjects:cancelButton, nil]];
    }
}

- (void) cancelAction:(id) sender {
    // TODO: this is a bit of hack. We should refactor the source list controller to stop checking it's root class
    [self dismissViewControllerAnimated:YES completion:^{
        [Ink return];
    }];
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
    [[self previewViewController] previewFile:selectedFile];
}

- (FPSource *)createSourceObjFrom:(NSString *)source {
    FPSource *sourceObj = [[FPSource alloc] init];
    sourceObj.identifier = source;
    
    if (source == FPSourceCameraRoll){
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
    return sourceObj;
}

- (void) loadContents {
    
    if (sourceNames == nil){
        sourceNames = [[NSArray alloc] initWithObjects: FPSourceDropbox, FPSourceFacebook, FPSourceGmail, FPSourceBox, FPSourceGithub, FPSourceGoogleDrive, FPSourceInstagram, FPSourceFlickr, FPSourcePicasa, FPSourceSkydrive, nil];
    }
    if (self.dataTypes == nil){
        self.dataTypes = [NSArray arrayWithObjects:@"*/*", nil];
    }
    
    NSMutableArray *local = [[NSMutableArray alloc ] init];
    NSMutableArray *cloud = [[NSMutableArray alloc ] init];
    
    for (NSString *source in sourceNames){
        FPSource *sourceObj;
        sourceObj = [self createSourceObjFrom:source];
        
        NSArray *source_mimetypes;
        if ([self isInSaveMode]) {
            source_mimetypes = sourceObj.save_mimetypes;
        } else {
            source_mimetypes = sourceObj.open_mimetypes;
        }
        
        if ([FPMimetype mimetypeCheck:source_mimetypes against:self.dataTypes]){
            sourceObj.mimetypes = self.dataTypes;
            if (source == FPSourceCameraRoll){
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
    return ([fpdelegate class] == [SourceListSaveController class]);
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
    return [(NSArray *)[self.sources valueForKey:sourceCategory] count] + 3; //samples, spacer, feedback
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = fpCellIdentifier;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    int count = [(NSArray *)[self.sources valueForKey:@"Cloud"] count];
    int index = indexPath.row;
    if (index == 0) {
        cell.textLabel.text = @"Sample Files";
        cell.textLabel.font = [UIFont fontWithName:LIGHTFONT size:18];

        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"glyphicons_144_folder_open" ofType:@"png"]];
        return cell;
    } else if (index == count + 1) {
        //Blank spacer
        cell.userInteractionEnabled = NO;
        return cell;
    } else if (index == count + 2) {
        //feedback
        cell.textLabel.font = [UIFont fontWithName:LIGHTFONT size:18];
        cell.textLabel.text = @"Feedback";
        return cell;
    }
    index--;
    NSString *sourceCategory = [[self.sources allKeys] objectAtIndex:indexPath.section];
    FPSource *source = [[self.sources valueForKey:sourceCategory] objectAtIndex:index];
    
    cell.textLabel.text = source.name;
    cell.textLabel.font = [UIFont fontWithName:LIGHTFONT size:18];
    if ([fpdelegate class] == [SourceListSaveController class] && source.identifier == FPSourceCameraRoll){
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

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
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
    NSString *mimeType = ( NSString *)CFBridgingRelease(UTTypeCopyPreferredTagWithClass(( CFStringRef)CFBridgingRetain((blob.uti)), kUTTagClassMIMEType));

    
    SourceListSaveController *sc = [[SourceListSaveController alloc] init];
    sc.dataType = mimeType;
    sc.data = blob.data;
    sc.proposedFilename = blob.filename;
    
    sc.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:sc animated:YES completion:nil];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int count = [(NSArray *)[self.sources valueForKey:@"Cloud"] count];
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
    
    [[StandaloneStatsEmitter sharedEmitter] sendStat:@"source_selected" withAdditionalStatistics:@{@"source": source.name}];

    FileSourceController *sView;
    if ([fpdelegate class] == [SourceListSaveController class]){
        sView = [[SaveController alloc] init];
    } else {
        sView = [[FileSourceController alloc] init];
    }
    sView.sourceType = source;
    sView.fpdelegate = fpdelegate;
    [self.navigationController pushViewController:sView animated:NO];

}

- (void) switchToSource: (NSString *)sourceString {
    [self loadContents];
    FileSourceController *sView;
    if ([fpdelegate class] == [SourceListSaveController class]){
        sView = [[SaveController alloc] init];
    } else {
        sView = [[FileSourceController alloc] init];
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
    self.contentSizeForViewInPopover = fpWindowSize;
    [super viewWillAppear:animated];
}

- (void) cancelButtonRequest:(id)sender {
    NSLog(@"Cancel Button Pressed on Source List");
    [fpdelegate FPSourceControllerDidCancel:nil];
}


@end
