//
//  ThatCloudAppDelegate.m
//
//  Created by Ink on 8/1/13.
//  Copyright (c) 2013 Ink (Cloudtop Inc), All rights reserved.
//

#import "ThatCloudAppDelegate.h"
#import <Ink/Ink.h>
#import <Ink/INKCoreManager.h>
#import "FPPicker.h"
#import "INKWelcomeViewController.h"
#import "ATConnect.h"
#import "StandaloneStatsEmitter.h"

#define kApptentiveAPIKey @"2f565a4292b7381c91028235e59b70dc20616c503690982e1adb25d68637d89c"


@implementation ThatCloudAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    ATConnect *connection = [ATConnect sharedConnection];
    connection.apiKey = kApptentiveAPIKey;
    
    // Initialize Ink
    [Ink setupWithAppKey:@"AneRowxpcloudAGkdngz"];
    
    [[StandaloneStatsEmitter sharedEmitter] setAppKey:@"AneRowxpcloudAGkdngz"];
    [[StandaloneStatsEmitter sharedEmitter] sendStat:@"app_launched" withAdditionalStatistics:nil];
    [[INKCoreManager sharedManager] registerAdditionalURLScheme:@"thatcloud"];
    
    // Register our incoming actions
    INKAction *store = [INKAction action:@"Store in ThatCloud" type:INKActionType_Store];
    [Ink registerAction:store withTarget:self selector:@selector(storeBlob:action:error:)];
    
    INKAction *storeFacebook = [INKAction action:@"Post to Facebook" type:INKActionType_Share];
    [Ink registerAction:storeFacebook withTarget:self selector:@selector(storeToFacebook:action:error:)];
    
    INKAction *storeDropbox = [INKAction action:@"Store in Dropbox" type:INKActionType_Insert];
    [Ink registerAction:storeDropbox withTarget:self selector:@selector(storeToDropbox:action:error:)];
    
    INKAction *storeGoogleDrive = [INKAction action:@"Store in Google Drive" type:INKActionType_Edit];
    [Ink registerAction:storeGoogleDrive withTarget:self selector:@selector(storeToGoogleDrive:action:error:)];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
        UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
        splitViewController.delegate = (id)navigationController.topViewController;
    }
    
    if ([INKWelcomeViewController shouldRunWelcomeFlow]) {
        INKWelcomeViewController * welcomeViewController;
        welcomeViewController = [[INKWelcomeViewController alloc] initWithNibName:@"INKWelcomeViewController" bundle:nil];
        
        welcomeViewController.nextViewController = self.window.rootViewController;
        [self.window setRootViewController:welcomeViewController];
    }

    
    //Override point for customization after application launch.
    return YES;

}

//TODO: Use FPSourceFacebook, but you can't because I was stupid when I wrote the library and sourceObjects aren't named the same as the constants
- (void) storeToFacebook: (INKBlob *)blob action:(INKAction*)action error:(NSError*)error{
    [self performSelector:@selector(storeBlobWithStartingSourceAsArray:) withObject:@[blob, @"Facebook"] afterDelay:0.5f];
}

- (void) storeToDropbox: (INKBlob *)blob action:(INKAction*)action error:(NSError*)error{
    [self performSelector:@selector(storeBlobWithStartingSourceAsArray:) withObject:@[blob, @"Dropbox"] afterDelay:0.5f];
}

- (void) storeToGoogleDrive: (INKBlob *)blob action:(INKAction*)action error:(NSError*)error{
    [self performSelector:@selector(storeBlobWithStartingSourceAsArray:) withObject:@[blob, @"Google Drive"] afterDelay:0.5f];
}

- (void) storeToBox: (INKBlob *)blob action:(INKAction*)action error:(NSError*)error{
    [self performSelector:@selector(storeBlobWithStartingSourceAsArray:) withObject:@[blob, @"Box"] afterDelay:0.5f];
}

- (void) storeToFlickr: (INKBlob *)blob action:(INKAction*)action error:(NSError*)error{
    [self performSelector:@selector(storeBlobWithStartingSourceAsArray:) withObject:@[blob, @"Flickr"] afterDelay:0.5f];
}

- (void) storeToPicasa: (INKBlob *)blob action:(INKAction*)action error:(NSError*)error{
    [self performSelector:@selector(storeBlobWithStartingSourceAsArray:) withObject:@[blob, @"Picasa"] afterDelay:0.5f];
}

- (void) storeToSkyDrive: (INKBlob *) blob action:(INKAction*)action error:(NSError*)error{
    [self performSelector:@selector(storeBlobWithStartingSourceAsArray:) withObject:@[blob, @"SkyDrive"] afterDelay:0.5f];
}

- (void)storeBlob:(INKBlob *)blob action:(INKAction*)action error:(NSError*)error{
    [self storeBlob:blob withStartingSource:nil];
}

- (void)storeBlobWithStartingSourceAsArray:(NSArray*)args {
    INKBlob* blob = [args objectAtIndex:0];
    NSString *startingSource = [args objectAtIndex:1];
    [self storeBlob:blob withStartingSource:startingSource];
}

- (void)storeBlob:(INKBlob *)blob withStartingSource:(NSString *)startingSource {
    
    NSLog(@"Store received: %@", blob);
    
    NSString *mimeType = ( NSString *)CFBridgingRelease(UTTypeCopyPreferredTagWithClass(( CFStringRef)CFBridgingRetain((blob .uti)), kUTTagClassMIMEType));
    
    //remove any existing views
    if ([[self.window.rootViewController presentedViewController] class] == [SourceListSaveController class] ){
        [self.window.rootViewController dismissViewControllerAnimated:NO completion:^{
            //nothing;
        }];        
    }
    
    SourceListSaveController *sc = [[SourceListSaveController alloc] init];
    sc.fpdelegate = self;
    sc.dataType = mimeType;
    sc.data = blob.data;
    sc.proposedFilename = [blob.filename stringByDeletingPathExtension];
    sc.startingSource = startingSource;
    
    sc.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.window.rootViewController presentViewController:sc animated:YES completion:nil];
}

/*
 * This makese the login screens look much nicer on iPad
 */
+ (void)initialize {
    // Set user agent (the only problem is that we can't modify the User-Agent later in the program)
    NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:@"Mozilla/5.0 (iPhone; CPU iPhone OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3", @"UserAgent", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
}

//This method is used instead of the handleOpenURL method because it is depreciated in iOS 6 and only one of the methods can be used
-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([Ink openURL:url sourceApplication:sourceApplication annotation:annotation]) {
        
        // Don't run the welcome flow if coming in on an action
        [INKWelcomeViewController setShouldRunWelcomeFlow:NO];
        return YES;
    }
    
    // Add whatever other url handling code your app requires here
    return NO;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark FPSaveDelegate

- (void)FPSaveControllerDidSave:(SourceListSaveController *)picker {
    //user selected save. save not complete yet.
}

- (void)FPSaveControllerDidCancel:(SourceListSaveController *)picker {
    [self.window.rootViewController dismissViewControllerAnimated:NO completion:^{
        [Ink return];
    }];
}

- (void)FPSaveController:(SourceListSaveController *)picker didError:(NSDictionary *)info {
    [self.window.rootViewController dismissViewControllerAnimated:NO completion:^{
        [Ink return];
    }];
}

- (void)FPSaveController:(SourceListSaveController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self.window.rootViewController dismissViewControllerAnimated:NO completion:^{
        [Ink return];
    }];
}

@end
