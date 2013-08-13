//
//  UINavigationBar+FlatUI.m
//  FlatUI
//
//  Created by Jack Flintermann on 5/3/13.
//  Copyright (c) 2013 Jack Flintermann. All rights reserved.
//

#import "UINavigationBar+FlatUI.h"
#import "UIImage+FlatUI.h"

@implementation UINavigationBar (FlatUI)

- (void) configureFlatNavigationBarWithColor:(UIColor *)color {
    [self setBackgroundImage:[UIImage imageWithColor:color cornerRadius:0]
               forBarMetrics:UIBarMetricsDefault & UIBarMetricsLandscapePhone];
    NSMutableDictionary *titleTextAttributes = [[self titleTextAttributes] mutableCopy];
    if (!titleTextAttributes) {
        titleTextAttributes = [NSMutableDictionary dictionary];
    }
    [titleTextAttributes setValue:[UIColor clearColor] forKey:UITextAttributeTextShadowColor];
    [titleTextAttributes setValue:[NSValue valueWithUIOffset:UIOffsetMake(0, 0)] forKey:UITextAttributeTextShadowOffset];
    [self setTitleTextAttributes:titleTextAttributes];
    if([self respondsToSelector:@selector(setShadowImage:)])
    {
        [self setShadowImage:[UIImage imageWithColor:[UIColor clearColor] cornerRadius:0]];
    }
    
    //LDCDL: adding border
    //TODO: Hack. Width *2 to prevent having to refresh the line when it rotates
    UIView *navBorder = [[UIView alloc] initWithFrame:CGRectMake(0,self.frame.size.height-1,self.frame.size.width*2, 1)];
    [navBorder setBackgroundColor:[UIColor colorWithWhite:200.0f/255.f alpha:0.8f]];
    [navBorder setOpaque:YES];
    [self addSubview:navBorder];    
}

@end
