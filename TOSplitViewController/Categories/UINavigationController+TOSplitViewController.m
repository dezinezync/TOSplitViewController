//
//  UINavigationController+TOSplitViewController.m
//  TOSplitViewControllerExample
//
//  Created by Tim Oliver on 4/4/17.
//  Copyright © 2017 Tim Oliver. All rights reserved.
//

#import "UINavigationController+TOSplitViewController.h"
#import <objc/runtime.h>
#import "TOSplitViewController.h"

static void *TOSplitViewControllerRootControllerKey;
static void *TOSplitViewControllerViewControllersKey;

const NSString *TOSplitViewControllerMapTableKey = @"viewControllers";

@implementation UINavigationController (TOSplitViewController)

#pragma mark - Public Interface -

- (BOOL)toSplitViewController_moveViewControllersToNavigationController:(UINavigationController *)navigationController animated:(BOOL)animated
{
    if (self.viewControllers.count == 0) {
        return YES;
    }

    // Save a strong reference to the root controller, so even if it is completely dismissed, it
    // won't be released from memory (and we can restore to it later)
    [self toSplitViewController_setRootViewController:self.viewControllers.firstObject];

    // Save an weak copy of all of the view controllers. If they get popped by the user,
    // they'll be released from here too.
    [self toSplitViewController_setViewControllerStack:self.viewControllers];

    // Pull out the view controllers, and nil them out from this controller
    NSArray *controllers = [self.viewControllers copy];
    self.viewControllers = [NSArray array];

    // Push them onto the target controller
    for (UIViewController *controller in controllers) {
        [navigationController pushViewController:controller animated:animated];
    }

    return YES;
}

- (void)toSplitViewController_restoreViewControllersAnimated:(BOOL)animated
{
    // Loop through all the controllers we had saved and restore them.
    NSMutableArray *viewControllers = [self toSplitViewController_viewControllerStack];

    // Check to see if any of our controllers are still in that navigation controller (or if the user popped all of them)
    // If there were still unpopped controllers, and then additional controllers were added, we'll 'inherit' those ones
    // as children of this view controller
    UIViewController *lastViewController = viewControllers.lastObject;
    UINavigationController *navigationController = lastViewController.navigationController;
    if (navigationController != nil) {
        NSUInteger index = [navigationController.viewControllers indexOfObject:lastViewController];
        NSRange range = NSMakeRange(index + 1, navigationController.viewControllers.count - (index+1));
        NSArray *trailingViewControllers = [navigationController.viewControllers subarrayWithRange:range];
        [viewControllers addObjectsFromArray:trailingViewControllers];
    }

    for (UIViewController *controller in viewControllers) {
        if (controller.navigationController) {
            NSMutableArray *viewControllers = [controller.navigationController.viewControllers mutableCopy];
            [viewControllers removeObject:controller];
            [controller.navigationController setViewControllers:viewControllers animated:NO];
        }

        // Push it back to us
        [self pushViewController:controller animated:animated];
    }

    // Flush out the internal properties so there are no leaked references
    [self toSplitViewController_setViewControllerStack:nil];
    [self toSplitViewController_setRootViewController:nil];
}

#pragma mark - Property Management -

- (void)toSplitViewController_setRootViewController:(UIViewController *)rootViewController
{
    objc_setAssociatedObject(self, &TOSplitViewControllerRootControllerKey, rootViewController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (nullable UIViewController *)toSplitViewController_rootViewController
{
    return objc_getAssociatedObject(self, &TOSplitViewControllerRootControllerKey);
}

- (void)toSplitViewController_setViewControllerStack:(NSArray<UIViewController *> *)viewControllers
{
    if (viewControllers == nil) {
        objc_setAssociatedObject(self, &TOSplitViewControllerViewControllersKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return;
    }

    NSPointerArray *pointerArray = [NSPointerArray pointerArrayWithOptions:NSPointerFunctionsWeakMemory];
    for (UIViewController *controller in viewControllers) {
        [pointerArray addPointer:(__bridge void * _Nullable)(controller)];
    }

    objc_setAssociatedObject(self, &TOSplitViewControllerViewControllersKey, pointerArray, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (nullable NSMutableArray *)toSplitViewController_viewControllerStack
{
    NSPointerArray *pointerArray = objc_getAssociatedObject(self, &TOSplitViewControllerViewControllersKey);
    NSMutableArray *viewControllers = [NSMutableArray array];
    for (id object in pointerArray) {
        if ([object isKindOfClass:[UIViewController class]] == NO) { continue; }
        [viewControllers addObject:object];
    }

    return viewControllers;
}

#pragma mark - Expand/Collapse Integration -
- (void)collapseAuxiliaryViewController:(UIViewController *)auxiliaryViewController
                                 ofType:(TOSplitViewControllerType)type
                 forSplitViewController:(TOSplitViewController *)splitViewController
{
    // We can only work with 2 navigation view controllers
    if (![auxiliaryViewController isKindOfClass:[UINavigationController class]]) {
        return;
    }

    [(UINavigationController *)auxiliaryViewController toSplitViewController_moveViewControllersToNavigationController:self animated:YES];
}

- (nullable UIViewController *)separateAuxiliaryViewController:(UIViewController *)auxiliaryViewController
                                                        ofType:(TOSplitViewControllerType)type
                                        forSplitViewController:(TOSplitViewController *)splitViewController
{
    if (![auxiliaryViewController isKindOfClass:[UINavigationController class]]) {
        return nil;
    }

    [(UINavigationController *)auxiliaryViewController toSplitViewController_restoreViewControllersAnimated:NO];
    return auxiliaryViewController;
}

#pragma mark - Presentation Integration -
- (void)to_showViewController:(nullable UIViewController *)viewController sender:(nullable id)sender
{
    if (viewController == nil) { return; }
    [self showViewController:viewController sender:sender];
}

@end
