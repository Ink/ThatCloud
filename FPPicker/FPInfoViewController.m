//
//  FPInfoViewController.m
//  FPPicker
//
//  Created by Liyan David Chang on 1/7/13.
//  Copyright (c) 2013 Ink (Cloudtop Inc.). All rights reserved.
//

#import "FPInfoViewController.h"
#import "FPConfig.h"
#import "FPLibrary.h"

@interface FPInfoViewController ()

@end

@implementation FPInfoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.title = @"About ThatStorage";
    


}

- (void)viewWillAppear:(BOOL)animated{
    self.contentSizeForViewInPopover = fpWindowSize;
    
    [super viewWillAppear:animated];
    
    CGRect bounds = [self.view bounds];
    NSLog(@"Bounds %f %f", bounds.size.height, bounds.size.width);
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    //logo
    
    UIImage *logo = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"logo_small" ofType:@"png"]];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage: logo];
    CGPoint center = imageView.center;
    center.y = 80;
    center.x = self.view.center.x;
    imageView.center = center;
    [self.view addSubview:imageView];

    //Description
    
    UILabel *headingLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, logo.size.height + 30, bounds.size.width-30, 200)];
    headingLabel.tag = -1;
    [headingLabel setTextColor:[UIColor grayColor]];
    [headingLabel setFont:[UIFont systemFontOfSize:15]];
    [headingLabel setTextAlignment:NSTextAlignmentCenter];
    headingLabel.text = @"ThatStorage is a sample app created by Ink to demonstrate the Ink Mobile Framework. It's backed by the Ink Web Framework. Ink is a trusted provider that helps\n applications connect with your content,\n no matter where you store it. \n\nYour information and files are secure and\n your username and password\n are never stored.\n\nMore information at https://www.inkfilepicker.com";
    headingLabel.numberOfLines = 0;
    headingLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    [self.view addSubview:headingLabel];

    //Footer
    
    UILabel *legalLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, bounds.size.height - 30, bounds.size.width, 30)];
    [legalLabel setTextColor:[UIColor grayColor]];
    [legalLabel setFont:[UIFont systemFontOfSize:12]];
    [legalLabel setTextAlignment:NSTextAlignmentCenter];
    legalLabel.text = @"Ink 2012, 2013";

    [self.view addSubview:legalLabel];

    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
