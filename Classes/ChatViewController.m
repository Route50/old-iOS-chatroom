    //
//  ChatViewController.m
//  Route 50 iPad
//
//  Created by Navarr Barnier on 6/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ChatViewController.h"
#import <AudioToolbox/AudioToolbox.h>

@implementation ChatViewController

@synthesize entries;
@synthesize newestMessage;
@synthesize chatTable;
@synthesize chatMessageCell;
@synthesize username,password;
@synthesize chatMessage;
@synthesize sendButton;
@synthesize lastKbSize;

-(void)viewDidLoad
{
	// Main Setup
	self.entries = [NSMutableArray arrayWithCapacity:50];
	self.newestMessage = 0;
	waitingForAuth = NO;
	
	self.chatMessage.delegate = self;
	
	// Instantiate Chat
	timerSet = NO;
	[self checkForMessages];
	
	// Super
	[super viewDidLoad];
	
	// Orientation Notifications
	UIDevice *device = [UIDevice currentDevice];
	[device beginGeneratingDeviceOrientationNotifications];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(deviceOrientationDidChange:)
												 name:UIDeviceOrientationDidChangeNotification
											   object:nil];
	
	// Notification Subscriptions
	UIApplication *app = [UIApplication sharedApplication];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(applicationWillEnterForeground:)
												 name:UIApplicationWillEnterForegroundNotification
											   object:app];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWasShown:)
												 name:UIKeyboardDidShowNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillBeHidden:) 
												 name:UIKeyboardWillHideNotification 
											   object:nil];
	
	// User Login Check Functions
	self.chatMessage.enabled = NO;
	self.chatMessage.text = @"Can Not Post as Guest (Set Username and Password in Settings App)";
	self.chatMessage.alpha = 0.5;
	self.sendButton.enabled = NO;
	self.sendButton.alpha = 0.5;
	[self attemptSignin];
}

#pragma mark -
#pragma mark UITextFieldDelegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[self sendMessage];
	return YES;
}

#pragma mark -
#pragma mark Login

-(void)applicationWillEnterForeground:(NSNotification *)notification
{
	[self attemptSignin];
}

-(void)attemptSignin
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults synchronize];
	NSString *oldUsername = self.username;
	NSString *oldPassword = self.password;
	self.username = [defaults objectForKey:@"username"];
	self.password = [defaults objectForKey:@"password"];
	// then authenticate
	if([self.username isEqual:@""] || [self.password isEqual:@""] || self.username == NULL || self.password == NULL)
	{
		self.chatMessage.enabled = NO;
		self.chatMessage.text = @"Can Not Post as Guest (Set Username and Password in Settings App)";
		self.chatMessage.alpha = 0.5;
		self.sendButton.enabled = NO;
		self.sendButton.alpha = 0.5;		
	}
	else if(![oldUsername isEqual:self.username] && ![oldPassword isEqual:self.password])
	{
		// Disable Stuff
		self.chatMessage.enabled = NO;
		self.chatMessage.alpha = 0.5;
		self.sendButton.enabled = NO;
		self.chatMessage.alpha = 0.5;
		self.chatMessage.text = [NSString stringWithFormat:@"Attempting to Login as %@...",self.username];
		
		NSHTTPCookieStorage *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
		for(int i = 0;i < [[cookies cookies] count];i++)
		{
			[cookies deleteCookie:[[cookies cookies] objectAtIndex:i]];
		}
		waitingForAuth = YES;
		NSMutableURLRequest *req = [[[NSMutableURLRequest alloc] init] autorelease];
		[req setURL:[NSURL URLWithString:@"http://route50.net/login"]];
		[req setHTTPMethod:@"POST"];
		NSData *body = [[NSString stringWithFormat:@"username=%@&password=%@",self.username,self.password] dataUsingEncoding:NSUTF8StringEncoding];
		[req setHTTPBody:body];
		
		NSURLConnection *con = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:YES];
		[con release];
	}
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	NSLog(@"Did Receive Data");
	if(waitingForAuth)
	{
		NSLog(@"Is Waiting for Auth");
		SBJsonParser *parser = [[SBJsonParser alloc] init];
		NSString *urlString = [NSString stringWithString:@"http://route50.net/ajax/newstuff"];
		NSURL *url = [NSURL URLWithString:urlString];
		NSString *json = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
		NSDictionary *nData = [parser objectWithString:json];
		NSLog(@"Data: %@",nData);
		if([[nData objectForKey:@"loggedin"] isEqual:[NSNumber numberWithInt:1]])
		{
			[self loginSuccess];
		}
		[parser release];
	}
}

-(void)loginSuccess
{
	NSLog(@"Login was a Success!");
	waitingForAuth = NO;
	self.sendButton.enabled = YES;
	self.sendButton.alpha = 1.0;
	self.chatMessage.enabled = YES;
	self.chatMessage.alpha = 1.0;
	self.chatMessage.text = @"";
	self.chatMessage.placeholder = [NSString stringWithFormat:@"Send a Message as %@ (Go To Settings to Change User)",self.username];
}

#pragma mark -
#pragma mark Chat Methods

-(void)checkForMessages
{
	NSLog(@"Check For Messages");
	NSLog(@"Newest Message: %d",self.newestMessage);
	NSString *urlString = [NSString stringWithFormat:@"http://route50.net/chat/new/%d?room=lobby&textonly=1",self.newestMessage];
	NSURL *url = [NSURL URLWithString:urlString];
	
	NSLog(@"Checking %@",urlString);
	
	dispatch_queue_t queue = dispatch_queue_create("net.route50.fetcher", NULL); //Create a new dispatch queue
	dispatch_async(queue, ^{ //Asynchronously run this block
		currentlyCheckingForMessages = YES;
		SBJsonParser *parser = [[SBJsonParser alloc] init];
		NSString *json = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
		NSArray *messages = [parser objectWithString:json];
		dispatch_sync(dispatch_get_main_queue(), ^{ //When the above statements are done, perform the following on the main thread (UI can only be changed on the main thread)
			NSLog(@"Result: %@",json);
			
			NSLog(@"Messages Count: %d",[messages count]);
			
			for(int i = [messages count]-1;i >= 0;i--)
			{
				// if((NSUInteger)[[messages objectAtIndex:i] objectAtIndex:0] < self.newestMessage) continue; // Skip
				
				[self.entries addObject:[messages objectAtIndex:i]];
				self.newestMessage = [[[messages objectAtIndex:i] objectAtIndex:4] intValue];
				if([[[messages objectAtIndex:i] objectAtIndex:5] isEqual:[NSNumber numberWithInt:1]])
				{
					// Play the Sound
					SystemSoundID ping;
					NSString *path = [[NSBundle mainBundle] pathForResource:@"notify" ofType:@"mp3"];
					AudioServicesCreateSystemSoundID((CFURLRef)[NSURL fileURLWithPath:path], &ping);
					AudioServicesPlaySystemSound(ping);
				}
				
				NSLog(@"Added: %@",[[messages objectAtIndex:i] objectAtIndex:2]);
			}
			[chatTable reloadData];
			
			NSHTTPCookieStorage *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
			NSLog(@"Cookies: %@",cookies);
			
			// Scroll to bottom
			NSUInteger scrollTo = [self.entries count] - 1;
			NSIndexPath *indexPath = [NSIndexPath indexPathForRow:MAX(0,scrollTo) inSection:0];
			[self.chatTable scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
			
			NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(timerCallback)]];
			[invocation setTarget:self];
			[invocation setSelector:@selector(timerCallback)];
			if (!timerSet) {
				urlPoll = [NSTimer scheduledTimerWithTimeInterval:2.5 invocation:invocation repeats:NO];
				timerSet = YES;
			}
			[parser release];
			currentlyCheckingForMessages = NO;
		});
	});
	dispatch_release(queue);
}

-(void)timerCallback
{
	timerSet = NO;
	[self checkForMessages];
}

-(IBAction)sendMessage
{
	self.sendButton.enabled = NO;
	NSString *postData = [NSString stringWithFormat:@"room=lobby&_ajax=1&text=%@",[self.chatMessage.text stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
	NSMutableURLRequest *req = [[[NSMutableURLRequest alloc] init] autorelease];
	[req setURL:[NSURL URLWithString:@"http://route50.net/chat/post"]];
	[req setHTTPMethod:@"POST"];
	NSData *body = [postData dataUsingEncoding:NSUTF8StringEncoding];
	[req setHTTPBody:body];
	
	NSURLConnection *con = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:YES];
	[con release];
	self.chatMessage.text = @"";
	self.sendButton.enabled = YES;
	if (!currentlyCheckingForMessages)
		[self checkForMessages];
}

#pragma mark -
#pragma mark Methods for Table View

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger row = [indexPath row];
	NSString *cellText = [[self.entries objectAtIndex:row] objectAtIndex:2];
	UIFont *cellFont = [UIFont systemFontOfSize:14];
	CGSize constraintSize = CGSizeMake(680.0f, MAXFLOAT);
	CGSize labelSize = [cellText sizeWithFont:cellFont constrainedToSize:constraintSize lineBreakMode:UILineBreakModeWordWrap];
	
	NSString *nameText = [[self.entries objectAtIndex:row] objectAtIndex:1];
	CGSize titleSize = [nameText sizeWithFont:[UIFont systemFontOfSize:12] constrainedToSize:constraintSize lineBreakMode:UILineBreakModeWordWrap];
	
	return labelSize.height + titleSize.height + 15;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	//NSLog(@"Count: %@",[self.entries count]);
	return [self.entries count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{	
	static NSString *simpleIdent = @"SimpleCell";
	/*
	static NSString *chatMessageIdentifier = @"ChatMessage";
	static NSString *actionMessageIdentifier = @"ActionMessage";
	static NSString *announcementIdentifier = @"Announcement";
	*/
	NSUInteger entry = [indexPath row];
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleIdent];
	if(cell == nil)
	{
		/*
		 NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"chatMessage" owner:self options:nil];
		 if([nib count] > 0)
		 cell = self.chatMessageCell;
		 */
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:simpleIdent] autorelease];
	}
	
	NSString *user = [[self.entries objectAtIndex:entry] objectAtIndex:1];
	NSString *message = [[self.entries objectAtIndex:entry] objectAtIndex:2];
	cell.textLabel.numberOfLines = 0;
	cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
	cell.textLabel.textColor = [UIColor blackColor];
	
	cell.detailTextLabel.text = user;
	cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
	
	// NSLog(@"Object at Index 6: %@",[[self.entries objectAtIndex:entry] objectAtIndex:6]);
	if([[[self.entries objectAtIndex:entry] objectAtIndex:5] intValue] == 1)
	{
		cell.textLabel.textColor = [UIColor redColor];
	}
	
	if([[[self.entries objectAtIndex:entry] objectAtIndex:6] intValue] == 1)
	{
		cell.textLabel.font = [UIFont boldSystemFontOfSize:14];
		cell.textLabel.text = [NSString stringWithFormat:@"* %@*",[message substringFromIndex:4]];
	}
	else 
	{
		cell.textLabel.font = [UIFont systemFontOfSize:14];
		cell.textLabel.text = message;
	}
	// cell.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:
	/*
	 ((UILabel *)[cell viewWithTag:1]).text = user;
	 ((UILabel *)[cell viewWithTag:2]).text = message;
	 */
	
	return cell;
}

#pragma mark -
#pragma mark View Scroll Up with Keyboard

// Code Taken from http://stackoverflow.com/questions/1126726/how-to-make-a-uitextfield-move-up-when-keyboard-is-present
// And edited slightly.  But this is the sauce.
// Also data from http://developer.apple.com/library/ios/#documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/KeyboardManagement/KeyboardManagement.html


-(void)keyboardWasShown:(NSNotification*)aNotification
{
	self.lastKbSize = [[[aNotification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
	NSLog(@"Keyboard Was Be Shown");
	[self setViewMovedUp:YES];
}

-(void)keyboardWillBeHidden:(NSNotification*)aNotification
{
	NSLog(@"Keyboard Will Be Hidden");
	[self setViewMovedUp:NO];
	self.lastKbSize = CGSizeMake(0,0);
}

-(void)setViewMovedUp:(BOOL)movedUp
{
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.5];
	
	CGRect rect = self.view.frame;
	CGFloat pixelAmount;
	
	if(rect.size.width == 768)
		pixelAmount = self.lastKbSize.height;
	else
		pixelAmount = self.lastKbSize.width;
	
	if(movedUp)
	{
		rect.origin.y -= pixelAmount;
//		self.chatTable.bounds.origin.y += pixelAmount;
//		rect.size.height -= pixelAmount;
	}
	else
	{
		rect.origin.y += pixelAmount;
//		self.chatTable.bounds.origin.y -= pixelAmount;
//		rect.size.height += pixelAmount;
	}
	self.view.frame = rect;
	
	// TEMPORARY FOR DEBUG PURPOSES
	//[chatMessage resignFirstResponder];
	
	[UIView commitAnimations];
}

-(void)deviceOrientationDidChange:(NSNotification *)notification
{
	[self.chatMessage resignFirstResponder];
}

#pragma mark -
#pragma mark Default Stuff

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	self.entries = nil;
	self.chatTable = nil;
	self.chatMessageCell = nil;
}


- (void)dealloc {
	[entries release];
	[chatTable release];
	[chatMessageCell release];
    [super dealloc];
}


@end
