//
//  FPSearchController.m
//  FPPicker
//
//  Created by Liyan David Chang on 6/20/12.
//  Copyright (c) 2012 Ink (Cloudtop Inc), All rights reserved.
//

#import "FPSearchController.h"
#import "FlatUIKit.h"

@interface FPSearchController ()

@end

@implementation FPSearchController

@synthesize searchDisplayController, searchBar;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0,70,320,44)];
    [self.searchBar setBackgroundImage:[UIImage imageWithColor:[UIColor whiteColor] cornerRadius:0]];
    searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
    searchDisplayController.delegate = self;
    searchDisplayController.searchResultsDataSource = self;
    searchDisplayController.searchResultsDelegate = self;
    self.tableView.tableHeaderView = searchBar;

    //Flat search button
    UIBarButtonItem *searchBarButton = [UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil];
    [searchBarButton setBackgroundImage:[UIImage imageWithColor:[UIColor grayColor] cornerRadius:3] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [searchBarButton setBackgroundImage:[UIImage imageWithColor:[UIColor lightGrayColor] cornerRadius:3] forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];

}

- (void)viewWillAppear:(BOOL)animated {
    self.contentSizeForViewInPopover = fpWindowSize;
    [super viewWillAppear:animated];
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    //NSLog(@"Search String %@", searchString);
    NSString *path = [NSString stringWithFormat:@"%@/%@", self.sourceType.rootUrl, [searchString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    self.path = path;
    [self fpLoadContents:path];
    [FPMBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self.searchDisplayController.searchResultsTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];

    //will reload when I have the results
    return NO;
}
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    //will reload when I have the results
    return NO;
}

@end
