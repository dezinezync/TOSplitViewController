//
//  AppDelegate.m
//  TOSplitViewControllerExample
//
//  Created by Tim Oliver on 3/14/17.
//  Copyright © 2017 Tim Oliver. All rights reserved.
//

#import "AppDelegate.h"
#import "TOSplitViewController.h"
#import "PrimaryViewController.h"
#import "SecondaryViewController.h"
#import "DetailViewController.h"

@interface AppDelegate () <TOSplitViewControllerDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    PrimaryViewController *mainController = [[PrimaryViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *primaryNavController = [[UINavigationController alloc] initWithRootViewController:mainController];

    SecondaryViewController *secondaryController = [[SecondaryViewController alloc] init];
    UINavigationController *secondaryNavController = [[UINavigationController alloc] initWithRootViewController:secondaryController];

    DetailViewController *detailController = [[DetailViewController alloc] init];
    UINavigationController *detailNavController = [[UINavigationController alloc] initWithRootViewController:detailController];

    NSArray *controllers = @[primaryNavController, secondaryNavController, detailNavController];
    TOSplitViewController *splitViewController = [[TOSplitViewController alloc] initWithViewControllers:controllers];
    splitViewController.delegate = self;
    
    splitViewController.primaryColumnMaximumWidth = 298.f;
    splitViewController.secondaryColumnMaximumWidth = 375.f;

    self.window.rootViewController = splitViewController;
    [self.window makeKeyAndVisible];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(splitControllerShowTargetDidChange:) name:TOSplitViewControllerShowTargetDidChangeNotification object:nil];

    return YES;
}

- (void)splitControllerShowTargetDidChange:(NSNotification *)notification
{
    NSLog(@"Show Target Changed!");
}

#pragma mark - Delegate -

- (BOOL)splitViewController:(TOSplitViewController *)splitViewController
     collapseViewController:(UIViewController *)auxiliaryViewController
                     ofType:(TOSplitViewControllerType)controllerType
  ontoPrimaryViewController:(UIViewController *)primaryViewController
              shouldAnimate:(BOOL)animate
{
    // Return YES when you've manually handled the collapse logic   
    return NO;
}

- (nullable UIViewController *)splitViewController:(TOSplitViewController *)splitViewController
                      separateViewControllerOfType:(TOSplitViewControllerType)type
                         fromPrimaryViewController:(UIViewController *)primaryViewController
{
    return nil;
}

- (nullable UIViewController *)splitViewController:(TOSplitViewController *)splitViewController
        primaryViewControllerForCollapsingFromType:(TOSplitViewControllerType)type
{
    return nil;
}

- (nullable UIViewController *)splitViewController:(TOSplitViewController *)splitViewController
           primaryViewControllerForExpandingToType:(TOSplitViewControllerType)type
{
    return nil;
}

@end
