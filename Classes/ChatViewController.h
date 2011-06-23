//
//  ChatViewController.h
//  Route 50 iPad
//
//  Created by Navarr Barnier on 6/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JSON.h"

@interface ChatViewController : UIViewController <UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate>
{
	NSMutableArray *entries;
	NSUInteger newestMessage;
	NSTimer *urlPoll;
	BOOL timerSet;
	BOOL currentlyCheckingForMessages;
	UITableView *chatTable;
	UITableViewCell *chatMessageCell;
	CGSize lastKbSize;
	NSString *username;
	NSString *password;
	UITextField *chatMessage;
	UIButton *sendButton;
	BOOL waitingForAuth;
}

@property (nonatomic,retain) NSMutableArray *entries;
@property NSUInteger newestMessage;
@property (nonatomic,retain) IBOutlet UITableView *chatTable;
@property (nonatomic,retain) IBOutlet UITableViewCell *chatMessageCell;
@property (nonatomic,retain) IBOutlet NSString *username, *password;
@property (nonatomic,retain) IBOutlet UITextField *chatMessage;
@property (nonatomic,retain) IBOutlet UIButton *sendButton;
@property CGSize lastKbSize;

-(void)checkForMessages;
-(void)timerCallback;
-(void)setViewMovedUp:(BOOL)movedUp;

-(void)attemptSignin;
-(void)loginSuccess;

-(IBAction)sendMessage;

@end
