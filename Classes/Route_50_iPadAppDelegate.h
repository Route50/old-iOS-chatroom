//
//  Route_50_iPadAppDelegate.h
//  Route 50 iPad
//
//  Created by Navarr Barnier on 6/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SplitController.h"

@interface Route_50_iPadAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
	SplitController *splitView;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet SplitController *splitView;

@end

