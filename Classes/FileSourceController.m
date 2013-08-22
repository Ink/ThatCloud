//
//  ServiceController.m
//  FPPicker
//
//  Created by Liyan David Chang on 6/20/12.
//  Copyright (c) 2013 Ink (Cloudtop Inc), All rights reserved.
//

#import "FileSourceController.h"
#import "SourceListSaveController.h"
#import "FPAuthController.h"
#import "FPInternalHeaders.h"
#import "FPThumbCell.h"
#import "FPMimetype.h"

#import "FlatUIKit.h"
#import "ThatCloudConstants.h"

#import <QuartzCore/QuartzCore.h>

@interface FileSourceController ()

@property int padding;
@property int numPerRow;
@property int thumbSize;
@property FPAFHTTPRequestOperation *downloadAndUpdatePreviewOperation;

@end

@implementation FileSourceController

@synthesize contents, sourceType, viewType, nextPage, nextPageSpinner, fpdelegate, precacheOperations;
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

- (void)addUIElements
{
    [self setTitle:sourceType.name];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorColor = [UIColor clearColor];
    self.precacheOperations = [[NSMutableDictionary alloc] init];
    
    
    
    [UIBarButtonItem configureFlatButtonsWithColor:[UIColor peterRiverColor]
                                  highlightedColor:[UIColor belizeHoleColor]
                                      cornerRadius:3];
    
    
    self.navigationItem.leftBarButtonItem =[[UIBarButtonItem alloc]initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonAction)];
    
    self.previewViewController = (FilePreviewViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    [self.tableView addSubview:refreshControl];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //Make sure that we have a service
    if (self.sourceType == nil){ return; }

    if (_path == nil){
        _path = [[NSString alloc] initWithFormat:@"%@/", self.sourceType.rootUrl];
    }

    [self fpLoadContents:_path];
    [FPMBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [self addUIElements];
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
    if (self.nextPage != nil){
        return 2;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0){
        if ([viewType isEqualToString:@"thumbnails"]){
            return (int) ceil([self.contents count]/(self.numPerRow*1.0));
        } else {
            return [self.contents count];
        }
    } else if (section == 1){
        return 1;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([viewType isEqualToString:@"thumbnails"]){
        return self.thumbSize+self.padding;
    }
    return 44;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 1){ //If it is the load more section
        [self fpLoadNextPage]; //Load More Stuff from Internet
    }
}

- (void)populateNewCell:(FPThumbCell *)cell
{
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

- (void)populateLoadingMoreCell:(FPThumbCell *)cell
{
    nextPageSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    nextPageSpinner.hidesWhenStopped = YES;
    
    int height = 44;
    if ([viewType isEqualToString:@"thumbnails"]){
        height = self.thumbSize+self.padding;
    }        
    nextPageSpinner.frame = CGRectMake(floorf(floorf(height - 20) / 2), floorf((height - 20) / 2), 20, 20);
    
    [cell addSubview:nextPageSpinner];
    [nextPageSpinner startAnimating];
    
    
    cell.textLabel.text = @"Loading more";
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.userInteractionEnabled = NO;
    cell.textLabel.font = [UIFont fontWithName:LIGHTFONT size:18];
}

- (void)populateThumbnailCell:(FPThumbCell *)cell indexPath:(NSIndexPath *)indexPath
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTappedWithGesture:)];
    [cell.contentView addGestureRecognizer:tap];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    CGRect rect = CGRectMake(self.padding, self.padding, self.thumbSize, self.thumbSize);
    for (int i=0; i<self.numPerRow; i++) {
        int index = self.numPerRow*indexPath.row + i;
        NSLog(@"index: %d", index);
        if (index >= [self.contents count]){
            break;
        }
        
        if (index >= [self.contents count]){
            // The data ends at this row, so we're done filling it
            return;
        }
        NSMutableDictionary *obj = [self.contents objectAtIndex:index];
        NSString *urlString = [obj valueForKey:@"thumbnail"];
        
        NSMutableURLRequest *mrequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
        
        if (![urlString hasPrefix:fpBASE_URL]){
            NSDictionary *headers = [NSHTTPCookie requestHeaderFieldsWithCookies:[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:fpBASE_URL]]];
            [mrequest setAllHTTPHeaderFields:headers];
        }
        
        UIImageView *image = [[UIImageView alloc] initWithFrame:rect];
        image.tag = index;
        image.contentMode = UIViewContentModeScaleAspectFill;
        image.clipsToBounds = YES;
        if ([[NSNumber numberWithInt:1] isEqual:[obj valueForKey:@"disabled"]]){
            image.alpha = 0.5;
        } else {
            image.alpha = 1.0;
        }
        
        //NSLog(@"Request: %@", mrequest);
        [image FPsetImageWithURLRequest:mrequest placeholderImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"placeholder" ofType:@"png"]] success:nil failure:nil];
        
        BOOL thumbExists = [[NSNumber numberWithInt:1] isEqualToNumber:[obj valueForKey:@"thumb_exists"]];
        
        if (!thumbExists){
            UILabel *subLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.thumbSize-30, self.thumbSize, 30)];
            [subLabel setTextColor:[UIColor blackColor]];
            [subLabel setFont:[UIFont systemFontOfSize:16]];
            [subLabel setBackgroundColor:[UIColor clearColor]];
            [subLabel setText: [obj valueForKey:@"filename"]];
            [subLabel setTextAlignment:NSTextAlignmentCenter];
            [image addSubview:subLabel];
            image.contentMode = UIViewContentModeCenter;
            image.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.1];
            
        } else {
            image.contentMode = UIViewContentModeScaleAspectFill;
        }
        
        [cell.contentView addSubview:image];
        rect = CGRectMake((rect.origin.x+self.thumbSize+self.padding), rect.origin.y, rect.size.width, rect.size.height);
    }
}

- (void)populateFileOrFolderCell:(FPThumbCell *)cell indexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row >= [self.contents count]){
        // No data for this row
        return;
    }
    NSMutableDictionary *obj = [self.contents objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [obj valueForKey:@"filename"];
    
    if ([[NSNumber numberWithInt:1] isEqualToNumber:[obj valueForKey:@"is_dir"]]){
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.textColor = [UIColor blackColor];
        cell.imageView.image = [UIImage imageNamed:@"folder.png"];
        [self fpPreloadContents:[obj valueForKey:@"link_path"] forCell:cell.tag];
    } else {
        NSLog(@"Thumb exists%@", [obj valueForKey:@"thumb_exists"]);
        
        
        NSString *cell_mimetype = [obj valueForKey:@"mimetype"];
        if (cell_mimetype == (id)[NSNull null]) {
            cell_mimetype = @"unknown/whatever";
        }
        
        NSString *iconPath = [FPMimetype iconPathForMimetype:cell_mimetype];
        cell.imageView.image = [UIImage imageNamed:iconPath];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier = fpCellIdentifier;
    FPThumbCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil){
        cell = [[FPThumbCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    } else {
        // You need to cancel the old precache request.
        if ([precacheOperations objectForKey:[NSString stringWithFormat:@"precache_%d", indexPath.row]]){
            [(FPAFURLConnectionOperation*)[precacheOperations objectForKey:[NSString stringWithFormat:@"precache_%d", indexPath.row]] cancel];
        }
        [self populateNewCell:cell];
    }
    cell.tag = indexPath.row;
    cell.textLabel.font = [UIFont fontWithName:LIGHTFONT size:18];
    
    if (self.nextPage != nil && indexPath.section == 1){
        [self populateLoadingMoreCell:cell];
    } else if ([viewType isEqualToString:@"thumbnails"]){
        [self populateThumbnailCell:cell indexPath:indexPath];
    } else {
        [self populateFileOrFolderCell:cell indexPath:indexPath];
    }
    
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
    
    UIImage *thumbnail = [tableView cellForRowAtIndexPath:indexPath].imageView.image;
    NSMutableDictionary *obj = [self.contents objectAtIndex:indexPath.row];

    BOOL thumbExists = (BOOL) [obj valueForKey:@"thumb_exists"];
    if (thumbExists){
        [self objectSelectedAtIndex:indexPath.row withThumbnail:thumbnail];
    } else {
        [self objectSelectedAtIndex:indexPath.row];
    }
}

- (void) fpAuthResponse {
    self.path = [NSString stringWithFormat:@"%@/", self.sourceType.rootUrl];
    [self fpLoadContents:_path cachePolicy:NSURLRequestReloadIgnoringCacheData];
}

- (void) fpAuthResponseCancel {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

/*  
 *  The default wrapper for fpLoadContents.
 *  I presume that cached data is fine unless you specify specifically.
 */
- (void) fpLoadContents:(NSString *)loadpath {
    [self fpLoadContents:loadpath cachePolicy:NSURLRequestReturnCacheDataElseLoad];
}


- (void)showAuthView {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fpAuthResponse) name:@"auth" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fpAuthResponseCancel) name:@"authCancel" object:nil];
    
    UINavigationController *navController = [[UINavigationController alloc] init];
    
    FPAuthController *authView = [[FPAuthController alloc] init];
    [navController addChildViewController:authView];
    authView.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    authView.service = sourceType.identifier;
    authView.title = sourceType.name;
    
    //NOTE: You must delay on save because of transition collisions
    if ([fpdelegate class] == [SourceListSaveController class]){
        //NOTE: Must use current context to make sure parent doesnt resize to full screen
        navController.modalPresentationStyle = UIModalPresentationCurrentContext;
        authView.modalPresentationStyle = UIModalPresentationCurrentContext;
        
        double delayInSeconds = 0.5f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            //code to be executed on the main queue after delay
            [self presentViewController:navController animated:NO completion:nil];
        });
    } else {
        [self presentViewController:navController animated:NO completion:nil];
    }
}

- (void)handleNoData {
    
    CGRect bounds = [self getViewBounds];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    UILabel *headingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, (bounds.size.height)/2-60, bounds.size.width, 30)];
    headingLabel.tag = -1;
    [headingLabel setTextColor:[UIColor grayColor]];
    [headingLabel setFont:[UIFont systemFontOfSize:25]];
    [headingLabel setTextAlignment:NSTextAlignmentCenter];
    headingLabel.text = @"No files here";
    [self.view addSubview:headingLabel];
    
    UILabel *subLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, (bounds.size.height)/2-30, bounds.size.width, 30)];
    subLabel.tag = -2;
    [subLabel setTextColor:[UIColor grayColor]];
    [subLabel setTextAlignment:NSTextAlignmentCenter];
    subLabel.text = @"Pull down to refresh";
    [self.view addSubview:subLabel];
}

- (void)handleSuccesfulFPRequest:(id)JSON loadpath:(NSString *)loadpath {
    NSLog(@"Loading Contents: %@", JSON);
    
    self.contents = [ JSON valueForKeyPath:@"contents"];
    self.viewType = [ JSON valueForKeyPath:@"view"];
    
    NSString *next = [ JSON valueForKeyPath:@"next"];
    if (next && next != (NSString*)[NSNull null]){
        self.nextPage = next ;
    } else {
        self.nextPage = nil;
    }
    
    if (![viewType isEqualToString:@"thumbnails"]){
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    } else {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    
    [self setTitle:[JSON valueForKey:@"filename"]];
    
    if ([JSON valueForKey:@"auth"] ){
        [self showAuthView];
        
    } else {
        if ([loadpath isEqualToString:[NSString stringWithFormat:@"%@/", self.sourceType.rootUrl]]){
            //logout only on root level
            UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithTitle:@"Logout" style:UIBarButtonItemStylePlain target:self action:@selector(logout:)];
            [anotherButton configureFlatButtonWithColor:[UIColor concreteColor] highlightedColor:[UIColor asbestosColor] cornerRadius:3];
            self.navigationItem.rightBarButtonItem = anotherButton;
        }
        
        if ([[JSON valueForKeyPath:@"contents"] count] == 0){
            [self handleNoData];
        }
    }
    
    [self.tableView reloadData];
    [self afterReload:YES];
}

- (void)handleFailedFPRequest:(NSError *)error loadpath:(NSString *)loadpath {
    [self afterReload:NO];    
    
    if (error.code == -1009 || error.code == -1001){
        [self.navigationController popViewControllerAnimated:YES];
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Internet Connection"
                                                          message:@"You aren't connected to the internet so we can't get your files."
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        
        [message show];
    }
    
    if (error.code == -1011){
        [self fpLoadContents:loadpath cachePolicy:NSURLRequestReloadIgnoringCacheData];
    }
}

- (void) fpLoadContents:(NSString *)loadpath cachePolicy:(NSURLRequestCachePolicy) policy {
    
    NSURLRequest *request = [self requestForLoadPath:loadpath withFormat:@"info" cachePolicy:policy];
    
    FPAFJSONRequestOperation *operation = [FPAFJSONRequestOperation JSONRequestOperationWithRequest: request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        [self handleSuccesfulFPRequest:JSON loadpath:loadpath];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"Error: %@", error);
        
        [self handleFailedFPRequest:error loadpath:loadpath];
        
    }];
    
    [operation start];
}


- (void) fpPreloadContents:(NSString *)loadpath {
    [self fpPreloadContents:loadpath forCell:-1];
}

- (void) fpPreloadContents:(NSString *)loadpath cachePolicy:(NSURLRequestCachePolicy)policy {
    NSLog(@"trying to refresh a path");
    [self fpPreloadContents:loadpath forCell:-1 cachePolicy:policy ];
}

- (void) fpPreloadContents:(NSString *)loadpath forCell:(NSInteger)cellIndex {
    [self fpPreloadContents:loadpath forCell:cellIndex cachePolicy:NSURLRequestReturnCacheDataElseLoad ];
}


- (void) fpPreloadContents:(NSString *)loadpath forCell:(NSInteger)cellIndex cachePolicy:(NSURLRequestCachePolicy)policy {
    NSInteger nilInteger = -1;
    
    NSURLRequest *request = [self requestForLoadPath:loadpath withFormat:@"info" cachePolicy:policy];
    
    FPAFJSONRequestOperation *operation = [FPAFJSONRequestOperation JSONRequestOperationWithRequest: request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        //NSLog(@"JSON: %@", JSON);
        if (cellIndex != nilInteger){
            [precacheOperations removeObjectForKey:[NSString stringWithFormat:@"precache_%d", cellIndex]];
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (cellIndex != nilInteger){
            [precacheOperations removeObjectForKey:[NSString stringWithFormat:@"precache_%d", cellIndex]];
        }
    }];
    [operation start];
    
    if (cellIndex != nilInteger){
        [precacheOperations setObject:operation forKey:[NSString stringWithFormat:@"precache_%d", cellIndex]];
    }
    
}


- (void) fpLoadNextPage {
    // Encode a string to embed in an URL.
    NSLog(@"Next page: %@", self.nextPage);
    NSString *encoded = (__bridge_transfer NSString*)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                (__bridge CFStringRef) self.nextPage,
                                                NULL,
                                                (CFStringRef) @"!*'();:@&=+$,/?%#[]",
                                                kCFStringEncodingUTF8);

    NSString *nextPageParam = [NSString stringWithFormat:@"&start=%@", encoded];
    NSLog(@"nextpageparm: %@", nextPageParam);
    NSURLRequest *request = [self requestForLoadPath:self.path withFormat:@"info" byAppending:nextPageParam cachePolicy:NSURLRequestReloadIgnoringCacheData];
    FPAFJSONRequestOperation *operation = [FPAFJSONRequestOperation JSONRequestOperationWithRequest: request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSLog(@"JSON: %@", JSON);
        
        NSMutableArray *tempArray = [[NSMutableArray alloc] initWithArray:self.contents];
        [tempArray addObjectsFromArray:[ JSON valueForKeyPath:@"contents"]];
        self.contents = tempArray;
        
        NSString *next = [ JSON valueForKeyPath:@"next"];
        if (next && next != (NSString*)[NSNull null]){
            self.nextPage = next ;
        } else {
            self.nextPage = nil;
        }
        [self.tableView reloadData];
        [nextPageSpinner stopAnimating];

    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"JSON: %@", JSON);
        self.nextPage = nil;
        [self.tableView reloadData];
        [nextPageSpinner stopAnimating];
        
    }];
    [operation start];
    
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
    
    NSMutableDictionary *obj = [self.contents objectAtIndex:selectedView.tag];
    UIImage *thumbnail;
    BOOL thumbExists = [[NSNumber numberWithInt:1] isEqualToNumber:[obj valueForKey:@"thumb_exists"]];
    if (thumbExists){
        thumbnail = selectedView.image;
        [self objectSelectedAtIndex:selectedView.tag withThumbnail:thumbnail];
    } else {
        [self objectSelectedAtIndex:selectedView.tag];        
    }
}

- (void) objectSelectedAtIndex:(NSInteger) index {
    [self objectSelectedAtIndex:index withThumbnail:nil];
}

- (void) objectSelectedAtIndex:(NSInteger) index withThumbnail:(UIImage *) thumbnail {
        
    NSMutableDictionary *obj = [self.contents objectAtIndex:index];
    
    if ([[NSNumber numberWithInt:1] isEqual:[obj valueForKey:@"disabled"]]){
        return;
    } else if ([[NSNumber numberWithInt:1] isEqualToNumber:[obj valueForKey:@"is_dir"]]){
        FileSourceController *subController = [[FileSourceController alloc] init];
        subController.path = [obj valueForKey:@"link_path"];
        subController.sourceType = sourceType;
        subController.fpdelegate = fpdelegate;
        [self.navigationController pushViewController:subController animated:YES];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(),^{
        [fpdelegate FPSourceController:self didPickMediaWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                              thumbnail, @"FPPickerControllerThumbnailImage"
                                                              , nil]];
    });
    
    [[self previewViewController] showSpinner];
    [self downloadAndUpdatePreview:obj];

}

- (void) downloadAndUpdatePreview: (NSDictionary*) obj {
    if (downloadAndUpdatePreviewOperation){
        [downloadAndUpdatePreviewOperation cancel];
    }
    
    NSString *totalInkPath = [obj valueForKey:@"link_path"];
    NSString *mimetype = [obj valueForKey:@"mimetype"];
    if (mimetype == (id)[NSNull null]) {
        [[self previewViewController] showNoPreviewScreen];
        return;
    }
    
    NSURLRequest *request = [self requestForLoadPath:totalInkPath withFormat:@"data" cachePolicy:NSURLRequestReturnCacheDataElseLoad];
    
    FPAFHTTPRequestOperation *operation = [[FPAFHTTPRequestOperation alloc]initWithRequest:request];
    [operation  setCompletionBlockWithSuccess:^(FPAFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *headers = [operation.response allHeaderFields];
        NSString *fpurl = [headers valueForKey:@"X-Data-Url"];        
        NSString *fphandle = [[fpurl componentsSeparatedByString:@"/"] lastObject];
        
        NSData *data = operation.responseData;
        InkFile *selectedFile = [InkFile alloc];
        selectedFile.fileName = [totalInkPath lastPathComponent];
        selectedFile.mimetype = [operation.response MIMEType];
        // For some providers, the inkpath isn't very meaningful.
        CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (CFStringRef)CFBridgingRetain(mimetype), (__bridge CFStringRef)@"public.data");
        selectedFile.uti = ( NSString *)CFBridgingRelease(UTI);
        selectedFile.inkPath = [totalInkPath stringByDeletingLastPathComponent];
        selectedFile.fphandle = fphandle;
        
        [selectedFile writeData:data];
        
        [[self previewViewController] previewFile:selectedFile];
    }
    failure:^(FPAFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error: %@",  operation.responseString);
    }
    ];
    [operation setDownloadProgressBlock:^(NSInteger bytesRead, NSInteger totalBytesRead, NSInteger totalBytesExpectedToRead) {
        [[self previewViewController] updateSpinner: 1.0f * totalBytesRead/totalBytesExpectedToRead];
    }];
    downloadAndUpdatePreviewOperation = operation;
    [operation start];
}

- (NSURLRequest *) requestForLoadPath: (NSString *)loadpath withFormat:(NSString*)type cachePolicy:(NSURLRequestCachePolicy)policy {
    
    return [self requestForLoadPath:loadpath withFormat:type byAppending:@"" cachePolicy:policy];
}

- (NSURLRequest *) requestForLoadPath: (NSString *)loadpath withFormat:(NSString*)type byAppending:(NSString*)additionalString cachePolicy:(NSURLRequestCachePolicy)policy {
    
    NSString *appString = [NSString stringWithFormat:@"{\"apikey\": \"%@\"}", fpAPIKEY];
    NSString *js_sessionString = [[NSString stringWithFormat:@"{\"app\": %@, \"mimetypes\": %@, \"version\": \"v1\"}", appString, [sourceType mimetypeString]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] ;
    
    NSMutableString *urlString = [NSMutableString stringWithString:[fpBASE_URL stringByAppendingString:[@"/api/path" stringByAppendingString:loadpath ]]]; 

    if ([urlString rangeOfString:@"?"].location == NSNotFound) {
        [urlString appendFormat:@"?format=%@&%@=%@", type, @"js_session", js_sessionString];
    } else {
        [urlString appendFormat:@"&format=%@&%@=%@", type, @"js_session", js_sessionString];
    }
    
    [urlString appendString:additionalString];
    
    NSURL *url = [NSURL URLWithString:urlString];
   
    
    NSMutableURLRequest *mrequest = [NSMutableURLRequest requestWithURL:url cachePolicy:policy timeoutInterval:240];
    [mrequest setAllHTTPHeaderFields:[NSHTTPCookie requestHeaderFieldsWithCookies:fpCOOKIES]];
    
    return mrequest;
    
}


- (void)handleRefresh:(id)sender {
    [self fpLoadContents:_path cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
}

- (void)logout:(NSObject *)button {
    
    NSString *urlString = [NSString stringWithFormat:@"%@/api/client/%@/unauth", fpBASE_URL, self.sourceType.identifier];

    NSLog(@"Logout: %@", urlString);

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:240];
    [FPMBProgressHUD showHUDAddedTo:self.view animated:YES];
    FPAFJSONRequestOperation *operation = [FPAFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSLog(@"Logout result: %@", JSON);
        
        [self fpPreloadContents:_path cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
        
        
        NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];

        for (NSHTTPCookie* cookie in [cookies cookies]) {
            NSLog(@"%@",[cookie domain]);
        }

        
        for (NSString *urlString in sourceType.externalDomains){
            NSArray* siteCookies;        
            siteCookies = [cookies cookiesForURL: [NSURL URLWithString:urlString]];
            for (NSHTTPCookie* cookie in siteCookies) {
                [cookies deleteCookie:cookie];
            }
        }
        
        for (NSHTTPCookie* cookie in [cookies cookies]) {
            NSLog(@"- %@",[cookie domain]);
        }
        
        
        [self.navigationController popViewControllerAnimated:YES];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"error: %@ %@", error, JSON);
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Logout Failure"
                                                          message:@"Hmm. We weren't able to logout."
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        
        [message show];
    }];
    [operation start];    
}

- (CGRect)getViewBounds {
    CGRect bounds = self.view.bounds;

    UIView *parent = self.view.superview;
	if (parent) {
		bounds = parent.bounds;
	}
    return bounds;
}

- (void) afterReload:(BOOL)success {
    [self.refreshControl endRefreshing];
    
    //If anyone puts one there, like web search controller
    [FPMBProgressHUD hideAllHUDsForView:self.view animated:YES];
    return;
}

@end
