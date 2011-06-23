//
//  UserbarViewController.h
//  Route 50 iPad
//
//  Created by Navarr Barnier on 6/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JSON.h"

@interface UserbarViewController : UIViewController <UITableViewDelegate,UITableViewDataSource> {
	NSArray *users;
	NSTimer *userbarPollingTimer;
	UITableView *userListTable;
}

@property (nonatomic,retain) NSArray *users;
@property (nonatomic,retain) NSTimer *userbarPollingTimer;
@property (nonatomic,retain) IBOutlet UITableView *userListTable;

-(void)grabUsers;
-(void)timerCallback;

@end
