//
//  TOSplitViewController.m
//  TOSplitViewControllerExample
//
//  Created by Tim Oliver on 3/14/17.
//  Copyright © 2017 Tim Oliver. All rights reserved.
//

#import "TOSplitViewController.h"

@interface TOSplitViewController () {
    struct {
        BOOL showSecondController;
        BOOL collapseSecondaryToPrimary;
        BOOL collapseDetailToPrimary;
        BOOL expandPrimaryToDetail;
        BOOL expandPrimaryToSecondary;
    } _delegateFlags;
}

// The separator lines between view controllers
@property (nonatomic, strong) NSArray<UIView *> *separatorViews;

// The three view controllers, returning nil if not presently visible
@property (nonatomic, readonly) UIViewController *primaryViewController;
@property (nonatomic, readonly) UIViewController *secondaryViewController;
@property (nonatomic, readonly) UIViewController *detailViewController;

@end

@implementation TOSplitViewController

- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers
{
    if (self = [super init]) {
        _viewControllers = [viewControllers copy];
        [self setUp];
    }

    return self;
}

- (void)setUp
{
    // Primary Column
    _primaryColumnMinimumWidth = 254.0f;
    _primaryColumnMaximumWidth = 400.0f;
    _preferredPrimaryColumnWidthFraction = 0.38f;

    // Secondary Column
    _secondaryColumnMinimumWidth = 320.0f;
    _secondaryColumnMaximumWidth = 400.0f;

    // Detail Column
    _detailColumnMinimumWidth = 450.0f;

    // State data
    _maximumNumberOfColumns = 3;

    _separatorStrokeColor = [UIColor colorWithWhite:0.75f alpha:1.0f];
}

#pragma mark - View Lifecylce -

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithWhite:0.95f alpha:1.0f];

    //Add all of the view controllers
    for (UIViewController *controller in self.viewControllers) {
        [self addSplitViewControllerChildViewController:controller];
    }

    // Create separators
    NSMutableArray *separators = [NSMutableArray array];
    for (NSInteger i = 0; i < 2; i++) {
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = self.separatorStrokeColor;
        [separators addObject:view];
    }
    self.separatorViews = [NSArray arrayWithArray:separators];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    CGSize size = self.view.bounds.size;
    BOOL compact = (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact);
    [self updateViewControllersForBoundsSize:size compactSizeClass:compact];
    [self layoutViewControllersForBoundsSize:size];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    NSInteger newNumberOfColumns = [self possibleNumberOfColumnsForWidth:size.width];

    // If we can't simply resize the columns, perform a 'collapse' or 'expand' animation
    if (newNumberOfColumns != self.viewControllers.count) {
        if (newNumberOfColumns < self.viewControllers.count) {
            [self transitionToCollapsedViewControllerCount:newNumberOfColumns withSize:size withTransitionCoordinator:coordinator];
        }
        else {
            [self transitionToExpandedViewControllerCount:newNumberOfColumns withSize:size withTransitionCoordinator:coordinator];
        }

        return;
    }

    // Animate the view controllers resizing
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self layoutViewControllersForBoundsSize:size];
    } completion:nil];
}

- (void)transitionToCollapsedViewControllerCount:(NSInteger)newCount withSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    NSInteger viewControllerCount = self.viewControllers.count;
    BOOL collapsingSecondary = (newCount == 2); //Collapsing 3 to 2
    BOOL collapsingDetail = (newCount == 1);    //Collapsing 2 to 1

    UIView *detailSnapshot = nil;
    UIView *secondarySnapshot = nil;
    UIView *primarySnapshot = nil;

    UIViewController *primaryViewController = self.primaryViewController;
    primarySnapshot = [primaryViewController.view snapshotViewAfterScreenUpdates:NO];
    [self.view addSubview:primarySnapshot];

    if (collapsingSecondary) {
        UIViewController *secondaryViewController = self.secondaryViewController;
        secondarySnapshot = [secondaryViewController.view snapshotViewAfterScreenUpdates:NO];
        secondarySnapshot.frame = secondaryViewController.view.frame;
        [self.view insertSubview:secondarySnapshot atIndex:0];
    }
    else if (collapsingDetail) {
        UIViewController *detailViewController = self.detailViewController;
        detailSnapshot = [detailViewController.view snapshotViewAfterScreenUpdates:NO];
        detailSnapshot.frame = detailViewController.view.frame;
        [self.view addSubview:detailSnapshot];
    }

    [self updateViewControllersForBoundsSize:size compactSizeClass:(self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact)];
    [self layoutViewControllersForBoundsSize:size];

    // Offset the new primary controller back to where the detail controller was
    if (detailSnapshot) {
        self.primaryViewController.view.frame = detailSnapshot.frame;

        // Add a separator back in
        UIView *separatorView = self.separatorViews.firstObject;
        CGRect frame = separatorView.frame;
        frame.origin.x = self.primaryViewController.view.frame.origin.x;
        separatorView.frame = frame;
        [self.view addSubview:separatorView];
    }

    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if (collapsingSecondary) {
            primarySnapshot.frame = self.primaryViewController.view.frame;
            primarySnapshot.alpha = 0.0f;
        }
        else if (collapsingDetail) {
            // Animate the detail view crossfading to the new one
            detailSnapshot.frame = (CGRect){CGPointZero, size};
            detailSnapshot.alpha = 0.0f;

            self.primaryViewController.view.frame = detailSnapshot.frame;

            // Slide the primary view out to the side
            CGRect frame = primarySnapshot.frame;
            frame.origin.x = -(frame.size.width);
            primarySnapshot.frame = frame;;

            // Animate the separator with it
            UIView *separatorView = self.separatorViews.firstObject;
            CGRect separatorFrame = separatorView.frame;
            separatorFrame.origin.x = -(separatorFrame.size.width);
            separatorView.frame = separatorFrame;
        }

    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [detailSnapshot removeFromSuperview];
        [secondarySnapshot removeFromSuperview];
        [primarySnapshot removeFromSuperview];
    }];
}

- (void)transitionToExpandedViewControllerCount:(NSInteger)newCount withSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{

}

#pragma mark - Column Setup & Management -

- (void)addSplitViewControllerChildViewController:(UIViewController *)controller
{
    [controller willMoveToParentViewController:self];
    [self addChildViewController:controller];
    [self.view addSubview:controller.view];
    [controller didMoveToParentViewController:self];
}

- (UIViewController *)removeSplitViewControllerChildViewController:(UIViewController *)controller
{
    [controller willMoveToParentViewController:nil];
    [controller removeFromParentViewController];
    [controller.view removeFromSuperview];
    [controller didMoveToParentViewController:nil];
    return controller;
}

- (void)layoutViewControllersForBoundsSize:(CGSize)size
{
    NSInteger numberOfColumns = self.viewControllers.count;
    if (numberOfColumns == 0) {
        return;
    }

    CGRect frame = CGRectZero;

    // The columns to layout
    UIViewController *primaryController = self.viewControllers.firstObject;
    UIViewController *secondaryController = numberOfColumns == 3 ? self.viewControllers[1] : nil;
    UIViewController *detailController = nil;
    if (numberOfColumns > 1) {
        detailController = numberOfColumns == 3 ? self.viewControllers[2] : self.viewControllers[1];
    }

    if (numberOfColumns == 3) {
        CGFloat idealPrimaryWidth = self.primaryColumnMinimumWidth;
        CGFloat idealSecondaryWidth = self.secondaryColumnMinimumWidth;
        CGFloat idealDetailWidth = self.detailColumnMinimumWidth;

        CGFloat padding = 0.0f;
        CGFloat delta = size.width - (idealPrimaryWidth + idealSecondaryWidth + idealDetailWidth);
        if (delta > FLT_EPSILON) {
            padding = floorf(delta / 3.0f);
        }

        frame.size = size;
        frame.size.width = idealPrimaryWidth + padding;
        primaryController.view.frame = frame;

        frame.origin.x = CGRectGetMaxX(frame);
        frame.size.width = idealSecondaryWidth + padding;
        secondaryController.view.frame = frame;

        frame.origin.x = CGRectGetMaxX(frame);
        frame.size.width = size.width - frame.origin.x;
        detailController.view.frame = frame;
    }
    else if (numberOfColumns == 2) {
        CGFloat idealPrimaryWidth = (size.width * self.preferredPrimaryColumnWidthFraction);
        idealPrimaryWidth = MAX(self.primaryColumnMinimumWidth, idealPrimaryWidth);
        idealPrimaryWidth = MIN(self.primaryColumnMaximumWidth, idealPrimaryWidth);

        frame.size = size;
        frame.size.width = floorf(idealPrimaryWidth);
        primaryController.view.frame = frame;

        frame.origin.x = CGRectGetMaxX(frame);
        frame.size.width = size.width - frame.origin.x;
        detailController.view.frame = frame;
    }
    else {
        frame.size = size;
        primaryController.view.frame = frame;
    }

    [self layoutSeparatorViewsForHeight:size.height];
}

- (void)layoutSeparatorViewsForHeight:(CGFloat)height
{
    //Add the separators
    for (UIView *view in self.separatorViews) {
        [view removeFromSuperview];
    }

    if (self.viewControllers.count < 2) { return; }

    NSInteger i = 0;
    CGFloat width = 1.0f / [[UIScreen mainScreen] scale];
    for (UIViewController *controller in self.viewControllers) {
        if (i >= self.separatorViews.count) { break; }

        CGRect frame = CGRectMake(0.0f, 0.0f, width, height);
        UIView *separator = self.separatorViews[i++];
        frame.origin.x = CGRectGetMaxX(controller.view.frame);
        separator.frame = frame;

        [self.view addSubview:separator];
    }
}

- (void)updateViewControllersForBoundsSize:(CGSize)size compactSizeClass:(BOOL)compact
{
    NSInteger numberOfColumns    = self.viewControllers.count;
    NSInteger newNumberOfColumns = [self possibleNumberOfColumnsForWidth:size.width];

    if (numberOfColumns == newNumberOfColumns) { return; }

    NSMutableArray *controllers = [NSMutableArray arrayWithArray:self.viewControllers];

    // Collapse columns down to the necessary number
    while (numberOfColumns > newNumberOfColumns && controllers.count > 1) {
        UIViewController *primaryViewController = controllers.firstObject;
        UIViewController *auxiliaryViewController = controllers[1]; // Either the secondary or detail controller

        // We're collapsing the secondary controller into the primary
        UIViewController *newPrimaryController = nil;
        if (numberOfColumns == 3) {
            if (_delegateFlags.collapseSecondaryToPrimary) {
                newPrimaryController = [self.delegate primaryViewControllerForCollapsingSplitViewController:self
                                                                                fromSecondaryViewController:auxiliaryViewController];
            }
        }
        else if (numberOfColumns == 2) { // We're collapsing the detail controller into the primary
            if (_delegateFlags.collapseDetailToPrimary) {
                newPrimaryController = [self.delegate primaryViewControllerForCollapsingSplitViewController:self
                                                                                fromDetailViewController:auxiliaryViewController];
            }
        }

        // If there was a delegate that provided a user-specified view controller, override and replace
        // the current primary controller
        if (newPrimaryController) {
            [self removeSplitViewControllerChildViewController:auxiliaryViewController];
            if ([self replacePrimaryControllerWithController:newPrimaryController]) {
                [controllers replaceObjectAtIndex:0 withObject:newPrimaryController];
            }
        }
        else { // otherwise default to a merge behaviour where the auxiliary controller will add its children to the primary nav controller
            [self removeSplitViewControllerChildViewController:auxiliaryViewController];
            [self mergeViewController:auxiliaryViewController intoViewController:primaryViewController];
        }

        // Remove the controller we just merged / replaced
        [controllers removeObjectAtIndex:1];
        _viewControllers = [NSArray arrayWithArray:controllers];

        numberOfColumns--;
    }

    // Expand columns to the necessary number
    while (numberOfColumns < newNumberOfColumns && controllers.count < 3) {
        UIViewController *sourceViewController = controllers.firstObject;
        UIViewController *expandedViewController = nil;

        // If we're expanding the primary out into a detail
        if (numberOfColumns == 1) {
            if (_delegateFlags.expandPrimaryToDetail) {
                expandedViewController = [_delegate splitViewController:self expandDetailViewControllerFromPrimaryViewController:sourceViewController];
            }
        }
        else if (numberOfColumns == 2) {
            if (_delegateFlags.expandPrimaryToSecondary) {
                expandedViewController = [_delegate splitViewController:self expandSecondaryViewControllerFromPrimaryViewController:sourceViewController];
            }

        }

        // If the delegates failed, try to manually expand the controller if it's a navigation controller
        if (expandedViewController == nil) {
            expandedViewController = [self expandedViewControllerFromSourceViewController:sourceViewController];
        }

        if (expandedViewController) {
            [controllers insertObject:expandedViewController atIndex:1];
            [self addSplitViewControllerChildViewController:expandedViewController];
        }

        numberOfColumns++;
        _viewControllers = [NSArray arrayWithArray:controllers];
    }
}

- (BOOL)replacePrimaryControllerWithController:(UIViewController *)viewController
{
    UIViewController *primaryViewController = self.viewControllers.firstObject;

    // Skip if the new primary controller is actually the original (ie a navigation controller)
    if (viewController == primaryViewController) { return NO; }

    // Remove the original view controller and add the new one
    [self removeSplitViewControllerChildViewController:primaryViewController];
    [self addSplitViewControllerChildViewController:viewController];

    return YES;
}

- (BOOL)mergeViewController:(UIViewController *)sourceViewController intoViewController:(UIViewController *)destViewController
{
    // If the dest is a navigation controller, we can push to it, else just let the source get destroyed
    if (![destViewController isKindOfClass:[UINavigationController class]]) { return NO; }

    UINavigationController *destNavigationController = (UINavigationController *)destViewController;

    //Copy all view controllers to the primary navigation controller
    if ([sourceViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *sourceNavigationController = (UINavigationController *)sourceViewController;

        NSArray *sourceViewControllers = sourceNavigationController.viewControllers;
        sourceNavigationController.viewControllers = [NSArray array]; //Remove all view controllers from old navigation controller

        for (UIViewController *controller in sourceViewControllers) {
            [destNavigationController pushViewController:controller animated:NO];
        }
    }
    else {
        [destNavigationController pushViewController:sourceViewController animated:NO];
    }

    return YES;
}

- (UIViewController *)expandedViewControllerFromSourceViewController:(UIViewController *)sourceViewController
{
    // If a navigation controller, extract the last view controller from it and return it in a new navigation controller
    if ([sourceViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)sourceViewController;
        if (navigationController.viewControllers.count < 2) {
            return nil;
        }

        UIViewController *lastViewController = [(UINavigationController *)sourceViewController popViewControllerAnimated:NO];
        return [[UINavigationController alloc] initWithRootViewController:lastViewController];
    }

    return nil;
}

#pragma mark - Column State Checking -

- (NSInteger)possibleNumberOfColumnsForWidth:(CGFloat)width
{
    // Not a regular side class (eg, iPhone / iPad Split View)
    if (self.view.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassRegular) {
        return 1;
    }

    CGFloat totalDualWidth = self.primaryColumnMinimumWidth;
    totalDualWidth += self.detailColumnMinimumWidth;

    //Default to 1 column
    NSInteger numberOfColumns = 1;

    // Check if there's enough horizontal space for all 3 columns
    if (totalDualWidth + self.secondaryColumnMinimumWidth <= width + FLT_EPSILON) {
        numberOfColumns = 3;
    }
    else if (totalDualWidth < width) { // Check if there's enough space for 2 columns
        return numberOfColumns = 2;
    }

    // Default to 1 column
    return MIN(self.maximumNumberOfColumns, numberOfColumns);
}

#pragma mark - Accessors -
- (void)setDelegate:(id<TOSplitViewControllerDelegate>)delegate
{
    if (delegate == _delegate) { return; }
    _delegate = delegate;

    _delegateFlags.showSecondController = [_delegate respondsToSelector:@selector(splitViewControllerShouldShowSecondaryColumn:)];
    _delegateFlags.collapseSecondaryToPrimary = [_delegate respondsToSelector:@selector(primaryViewControllerForCollapsingSplitViewController:
                                                                                        fromSecondaryViewController:)];
    _delegateFlags.collapseDetailToPrimary = [_delegate respondsToSelector:@selector(primaryViewControllerForCollapsingSplitViewController:
                                                                                     fromDetailViewController:)];
    _delegateFlags.expandPrimaryToDetail = [_delegate respondsToSelector:@selector(splitViewController:expandDetailViewControllerFromPrimaryViewController:)];
    _delegateFlags.expandPrimaryToSecondary = [_delegate respondsToSelector:@selector(splitViewController:expandSecondaryViewControllerFromPrimaryViewController:)];
}

#pragma mark - Internal Accessors -
- (UIViewController *)primaryViewController
{
    return self.viewControllers.firstObject;
}

- (UIViewController *)secondaryViewController
{
    if (self.viewControllers.count <= 2) { return nil; }
    return self.viewControllers[1];
}

- (UIViewController *)detailViewController
{
    if (self.viewControllers.count == 3) {
        return self.viewControllers[2];
    }
    else if (self.viewControllers.count == 2) {
        return self.viewControllers[1];
    }

    return nil;
}

@end