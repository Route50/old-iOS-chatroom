    //
//  UserbarViewController.m
//  Route 50 iPad
//
//  Created by Navarr Barnier on 6/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UserbarViewController.h"


@implementation UserbarViewController

@synthesize users, userbarPollingTimer, userListTable;

-(void)viewDidLoad
{
	[self grabUsers];
	[super viewDidLoad];
}

#pragma mark -
#pragma mark Userbar Methods

-(void)grabUsers
{	
	NSLog(@"Check for Users");
	SBJsonParser *parser = [[SBJsonParser alloc] init];
	NSString *urlString = @"http://route50.net/ajax/chatbar?room=lobby";
	NSURL *url = [NSURL URLWithString:urlString];
	
	NSLog(@"Checking %@",urlString);
	
	NSString *json = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
	NSDictionary *userData = [parser objectWithString:json];
	
	NSLog(@"Result: %@",json);
	
	NSMutableArray *userHolder = [NSMutableArray arrayWithCapacity:2];
	[userHolder addObject:[NSArray arrayWithArray:[userData objectForKey:@"staff_json"]]];
	[userHolder addObject:[NSArray arrayWithArray:[userData objectForKey:@"chatters_json"]]];
	
	for(int i = 0; i < 1;i++)
		if([[userHolder objectAtIndex:i] count] == 0) [userHolder replaceObjectAtIndex:i withObject:[NSArray arrayWithObject:@"Nobody"]];
	
	NSLog(@"UserHolder: %@",userHolder);
	
	self.users = userHolder;
	[userListTable reloadData];
	
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(timerCallback)]];
	[invocation setTarget:self];
	[invocation setSelector:@selector(timerCallback)];
	self.userbarPollingTimer = [NSTimer scheduledTimerWithTimeInterval:15 invocation:invocation repeats:NO];
	[parser release];
}

-(void)timerCallback
{
	[self grabUsers];
}

#pragma mark -
#pragma mark Methods for Table View

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [[self.users objectAtIndex:section] count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSUInteger row = [indexPath row];
	NSUInteger section = [indexPath section];
	NSLog(@"Searching for Cell to grab from dequeue...");
	UITableViewCell *cell;
//	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"userCell"];
//	if(cell == nil)
//	{
//		NSLog(@"Cell not found.  Creating from scratch.");
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"userCell"] autorelease];
//	}
	
	NSLog(@"Request for data at %d:%d",section,row);
	NSLog(@"Data at %d:%d - %@",section,row,[[self.users objectAtIndex:section] objectAtIndex:row]);
	cell.textLabel.text = [[self.users objectAtIndex:section] objectAtIndex:row];
	NSLog(@"Text Set.");
	
	return cell;
}

-(NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 5;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if(section == 0) return @"Staff";
	if(section == 1) return @"Chatters";
	return @"";
}

#pragma mark -
#pragma mark Normal Stuff

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
	self.users = nil;
	self.userbarPollingTimer = nil;
	self.userListTable = nil;
}


- (void)dealloc {
	[users release];
	[userbarPollingTimer release];
	[userListTable release];
    [super dealloc];
}


@end
