/* IncallViewController.h
 *
 * Copyright (C) 2009  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or   
 *  (at your option) any later version.                                 
 *                                                                      
 *  This program is distributed in the hope that it will be useful,     
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of      
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the       
 *  GNU General Public License for more details.                
 *                                                                      
 *  You should have received a copy of the GNU General Public License   
 *  along with this program; if not, write to the Free Software         
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */              
#import "IncallViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import "linphonecore.h"
#include "LinphoneManager.h"
#include "private.h"

@implementation IncallViewController


@synthesize controlSubView;
@synthesize callControlSubView;
@synthesize padSubView;
@synthesize hangUpView;

@synthesize addToConf;
@synthesize endCtrl;
@synthesize close;
@synthesize mute;
@synthesize pause;
@synthesize dialer;
@synthesize speaker;
@synthesize contacts;
@synthesize callTableView;
@synthesize addCall;
@synthesize mergeCalls;

@synthesize one;
@synthesize two;
@synthesize three;
@synthesize four;
@synthesize five;
@synthesize six;
@synthesize seven;
@synthesize eight;
@synthesize nine;
@synthesize star;
@synthesize zero;
@synthesize hash;
@synthesize videoViewController;

/*
// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization

    }
    return self;
}
*/


bool isInConference(LinphoneCall* call) {
    if (!call)
        return false;
    return linphone_call_get_current_params(call)->in_conference;
}

int callCount(LinphoneCore* lc) {
    int count = 0;
    const MSList* calls = linphone_core_get_calls(lc);
    
    while (calls != 0) {
        if (!isInConference((LinphoneCall*)calls->data)) {
            count++;
        }
        calls = calls->next;
    }
    return count;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	//Controls
	[mute initWithOnImage:[UIImage imageNamed:@"micro_inverse.png"]  offImage:[UIImage imageNamed:@"micro.png"] ];
    [speaker initWithOnImage:[UIImage imageNamed:@"HP_inverse.png"]  offImage:[UIImage imageNamed:@"HP.png"] ];
	

	//Dialer init
	[zero initWithNumber:'0'];
	[one initWithNumber:'1'];
	[two initWithNumber:'2'];
	[three initWithNumber:'3'];
	[four initWithNumber:'4'];
	[five initWithNumber:'5'];
	[six initWithNumber:'6'];
	[seven initWithNumber:'7'];
	[eight initWithNumber:'8'];
	[nine initWithNumber:'9'];
	[star initWithNumber:'*'];
	[hash initWithNumber:'#'];
    
    [addCall addTarget:self action:@selector(addCallPressed) forControlEvents:UIControlEventTouchDown];
    [mergeCalls addTarget:self action:@selector(mergeCallsPressed) forControlEvents:UIControlEventTouchDown];
    //[endCtrl addTarget:self action:@selector(endCallPressed) forControlEvents:UIControlEventTouchUpInside];
    [addToConf addTarget:self action:@selector(addToConfCallPressed) forControlEvents:UIControlEventTouchUpInside];
    [pause addTarget:self action:@selector(pauseCallPressed) forControlEvents:UIControlEventTouchUpInside];
    [mergeCalls setHidden:YES];
	mVideoViewController =  [[VideoViewController alloc]  initWithNibName:@"VideoViewController" 
																							 bundle:[NSBundle mainBundle]];
	mVideoShown=FALSE;
	mIncallViewIsReady=FALSE;
	mVideoIsPending=FALSE;
    //selectedCall = nil;
}

-(void) addCallPressed {
    [self dismissModalViewControllerAnimated:true];
}

-(void) mergeCallsPressed {
    LinphoneCore* lc = [LinphoneManager getLc];
    
    linphone_core_add_all_to_conference(lc);
}

-(void) addToConfCallPressed {
    LinphoneCall* selectedCall = linphone_core_get_current_call([LinphoneManager getLc]);
	if (!selectedCall)
        return;
    linphone_core_add_to_conference([LinphoneManager getLc], selectedCall);
}

-(void) pauseCallPressed {
    LinphoneCall* selectedCall = linphone_core_get_current_call([LinphoneManager getLc]);
	if (!selectedCall)
        return;
    if (linphone_call_get_state(selectedCall) == LinphoneCallPaused) {
        [pause setSelected:NO];
        linphone_core_resume_call([LinphoneManager getLc], selectedCall);
    }else{
        linphone_core_pause_call([LinphoneManager getLc], selectedCall);
        [pause setSelected:YES];
    }
}


-(void)updateCallsDurations {
    [self updateUIFromLinphoneState: nil]; 
}

-(void) viewWillAppear:(BOOL)animated {

	
}
-(void)viewDidAppear:(BOOL)animated {
    if (dismissed) {
        [self dismissModalViewControllerAnimated:true];
    } else {
        [self updateCallsDurations];
        durationRefreasher = [NSTimer	scheduledTimerWithTimeInterval:1 
                                                              target:self 
                                                            selector:@selector(updateCallsDurations) 
                                                            userInfo:nil 
                                                             repeats:YES];
        glowingTimer = [NSTimer	scheduledTimerWithTimeInterval:0.1 
                                                              target:self 
                                                            selector:@selector(updateGlow) 
                                                            userInfo:nil 
                                                             repeats:YES];
        glow = 0;
		mIncallViewIsReady=TRUE; 
		if (mVideoIsPending) {
			mVideoIsPending=FALSE;
			[self displayVideoCall:nil FromUI:self 
						   forUser:nil 
				   withDisplayName:nil];
			
		}

		
		UIDevice* device = [UIDevice currentDevice];
		if ([device respondsToSelector:@selector(isMultitaskingSupported)]
			&& [device isMultitaskingSupported]) {
			bool enableVideo = [[NSUserDefaults standardUserDefaults] boolForKey:@"enable_video_preference"];
			bool startVideo = [[NSUserDefaults standardUserDefaults] boolForKey:@"start_video_preference"];
				if (enableVideo && !startVideo) {
					[addVideo setHidden:FALSE];
					[contacts setHidden:TRUE];
				} else {
					[addVideo setHidden:TRUE];
					[contacts setHidden:FALSE];				
				}
				
		
		}
		
    }
}

- (void) viewDidDisappear:(BOOL)animated {
    if (durationRefreasher != nil) {
        [durationRefreasher invalidate];
        durationRefreasher=nil;
        [glowingTimer invalidate];
        glowingTimer = nil;
    }
	if (!mVideoShown) [[UIApplication sharedApplication] setIdleTimerDisabled:false];
}

- (void)viewDidUnload {

	
}



-(void) displayStatus:(NSString*) message; {

}

-(void) displayPad:(bool) enable {
    [callTableView setHidden:enable];
    [hangUpView setHidden:enable];
	[controlSubView setHidden:enable];
	[padSubView setHidden:!enable];
}
-(void) displayCall:(LinphoneCall*) call InProgressFromUI:(UIViewController*) viewCtrl forUser:(NSString*) username withDisplayName:(NSString*) displayName {
	//restaure view
	[self displayPad:false];
	dismissed = false;
	UIDevice *device = [UIDevice currentDevice];
    device.proximityMonitoringEnabled = YES;
	if ([speaker isOn]) 
		[speaker toggle];
    [self updateUIFromLinphoneState: nil]; 
}

-(void) displayIncomingCall:(LinphoneCall *)call NotificationFromUI:(UIViewController *)viewCtrl forUser:(NSString *)username withDisplayName:(NSString *)displayName {
    
}

-(void) dismissVideoView {
	[[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO]; 
	[self dismissModalViewControllerAnimated:FALSE];//just in case
	 mVideoShown=FALSE;
}
-(void) displayInCall:(LinphoneCall*) call FromUI:(UIViewController*) viewCtrl forUser:(NSString*) username withDisplayName:(NSString*) displayName {
    dismissed = false;
	UIDevice *device = [UIDevice currentDevice];
    device.proximityMonitoringEnabled = YES;
	if (call !=nil  && linphone_call_get_dir(call)==LinphoneCallIncoming) {
		if ([speaker isOn]) [speaker toggle];
	}
    [self updateUIFromLinphoneState: nil];
	if (self.presentedViewController == (UIViewController*)mVideoViewController) {
		[self dismissVideoView];
	}
}
-(void) displayDialerFromUI:(UIViewController*) viewCtrl forUser:(NSString*) username withDisplayName:(NSString*) displayName {
	UIViewController* modalVC = self.modalViewController;
	UIDevice *device = [UIDevice currentDevice];
    device.proximityMonitoringEnabled = NO;
    if (modalVC != nil) {
        // clear previous native window ids
        if (modalVC == mVideoViewController) {
            mVideoShown=FALSE;
            linphone_core_set_native_video_window_id([LinphoneManager getLc],0);	
            linphone_core_set_native_preview_window_id([LinphoneManager getLc],0);
        }
		[[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO]; 
		[self dismissModalViewControllerAnimated:FALSE];//just in case
    }

	[self dismissModalViewControllerAnimated:FALSE]; //disable animation to avoid blanc bar just below status bar*/
    dismissed = true;
    [self updateUIFromLinphoneState: nil]; 
}
-(void) displayVideoCall:(LinphoneCall*) call FromUI:(UIViewController*) viewCtrl forUser:(NSString*) username withDisplayName:(NSString*) displayName { 
	if (mIncallViewIsReady) {
	[[UIApplication sharedApplication] setStatusBarHidden:YES animated:NO];
	mVideoShown=TRUE;
	[self presentModalViewController:mVideoViewController animated:true];
	} else {
		//postepone presentation
		mVideoIsPending=TRUE;
	}
}
-(void) updateUIFromLinphoneState:(UIViewController *)viewCtrl {
    [mute reset];
    // if (
    // [pause reset];

    
    LinphoneCore* lc;
    
    @try {
        lc = [LinphoneManager getLc];
        
        if (callCount([LinphoneManager getLc]) > 1) {
            [pause setHidden:YES];
            [mergeCalls setHidden:NO];
        } else {
            [pause setHidden:NO];
            [mergeCalls setHidden:YES];        
        }
        
        [callTableView reloadData];       
    } @catch (NSException* exc) {
        return;
    }
    LinphoneCall* selectedCall = linphone_core_get_current_call([LinphoneManager getLc]);
    // hide call control subview if no call selected
    [callControlSubView setHidden:(selectedCall == NULL)];
    // hide add to conf if no conf exist
    if (!callControlSubView.hidden) {
        [addToConf setHidden:(linphone_core_get_conference_size(lc) == 0 ||
                            isInConference(selectedCall))];
    }
    int callsCount = linphone_core_get_calls_nb(lc);
    // hide pause/resume if in conference    
    if (selectedCall) {
        if (linphone_core_is_in_conference(lc))
            [pause setHidden:YES];
        else if (linphone_call_get_state(selectedCall)==LinphoneCallPaused) {
            [pause setHidden:NO];
            //[pause setTitle:@"Resume" forState:UIControlStateNormal];
            pause.selected = YES;
        } else if (callCount(lc) == callsCount && callsCount == 1) {
            [pause setHidden:NO];
            //[pause setTitle:@"Pause" forState:UIControlStateNormal];
            pause.selected = NO;
        } else {
            [pause setHidden:YES];
        }
    } else {
        [pause setHidden:callsCount > 0];
    }
    [mergeCalls setHidden:!pause.hidden];
}

- (IBAction)doAction:(id)sender {
	
	if (sender == dialer) {
		[self displayPad:true];
		
	} else if (sender == contacts) {
		// start people picker
		myPeoplePickerController = [[[ABPeoplePickerNavigationController alloc] init] autorelease];
		[myPeoplePickerController setPeoplePickerDelegate:self];
		
		[self presentModalViewController: myPeoplePickerController animated:true]; 
	} else if (sender == close) {
		[self displayPad:false];
	} 	
}

// handle people picker behavior

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker 
	  shouldContinueAfterSelectingPerson:(ABRecordRef)person {
	return true;
	
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker 
	  shouldContinueAfterSelectingPerson:(ABRecordRef)person 
								property:(ABPropertyID)property 
							  identifier:(ABMultiValueIdentifier)identifier {
	
	return false;
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker {
	[self dismissModalViewControllerAnimated:true];
}




- (void)dealloc {
    [super dealloc]; 
}

-(LinphoneCall*) retrieveCallAtIndex: (NSInteger) index inConference:(bool) conf{
    const MSList* calls = linphone_core_get_calls([LinphoneManager getLc]);
    
    if (!conf && linphone_core_get_conference_size([LinphoneManager getLc]))
        index--;
    
    while (calls != 0) {
        if (isInConference((LinphoneCall*)calls->data) == conf) {
            if (index == 0)
                break;
            index--;
        }
        calls = calls->next;
    }
    
    if (calls == 0) {
        ms_error("Cannot find call with index %d (in conf: %d)", index, conf);
        return nil;
    } else {
        return (LinphoneCall*)calls->data;
    }
}

-(void) updateActive:(bool_t)active cell:(UITableViewCell*) cell {
    if (!active) {
        
        cell.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.2];
        
        UIColor* c = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        [cell.textLabel setTextColor:c];
        [cell.detailTextLabel setTextColor:c];
    } else {
        cell.backgroundColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:(0.7+sin(2*glow)*0.3)];
        [cell.textLabel setTextColor:[UIColor whiteColor]];  
        [cell.detailTextLabel setTextColor:[UIColor whiteColor]];
    } 
    [cell.textLabel setBackgroundColor:[UIColor clearColor]];
    [cell.detailTextLabel setBackgroundColor:[UIColor clearColor]];
    [cell.accessoryView setHidden:YES];
    //[cell.backgroundView setBackgroundColor:cell.backgroundColor];
}

-(void) updateGlow {
    glow += 0.1;
    
    NSIndexPath* path = [callTableView indexPathForSelectedRow];
    if (path) {
        UITableViewCell* cell = [callTableView cellForRowAtIndexPath:path];
        [self updateActive:YES cell:cell];
        [cell.backgroundView setNeedsDisplay];
        [cell setNeedsDisplay];
        [callTableView setNeedsDisplay];
    }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [self updateActive:(cell.accessoryType == UITableViewCellAccessoryCheckmark) cell:cell];
    //cell.accessoryType = UITableViewCellAccessoryNone;
}

- (void) updateCell:(UITableViewCell*)cell at:(NSIndexPath*) path withCall:(LinphoneCall*) call conferenceActive:(bool)confActive{
    if (call == NULL) {
        ms_warning("UpdateCell called with null call");
        [cell.textLabel setText:@""];
        return;
    }
    const LinphoneAddress* addr = linphone_call_get_remote_address(call);
    if (addr) {
        NSMutableString* mss = [[NSMutableString alloc] init];
        
        const char* n = linphone_address_get_display_name(addr);
        if (n) 
            [mss appendFormat:@"%s", n, nil];
        else
            [mss appendFormat:@"%s", linphone_address_get_username(addr), nil];
        [cell.textLabel setText:mss];
    } else
        [cell.textLabel setText:@"plop"];
    
    NSMutableString* ms = [[NSMutableString alloc] init ];
    if (linphone_call_get_state(call) == LinphoneCallStreamsRunning) {
        int duration = linphone_call_get_duration(call);
        if (duration >= 60)
            [ms appendFormat:@"%02i:%02i", (duration/60), duration - 60*(duration/60), nil];
        else
            [ms appendFormat:@"%02i sec", duration, nil];
    } else {
        [ms appendFormat:@"%s", linphone_call_state_to_string(linphone_call_get_state(call)), nil];
    }
    [cell.detailTextLabel setText:ms];
        
    /*
    if (linphone_core_get_current_call([LinphoneManager getLc]) == call) {
        cell.backgroundColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:1];
    } else if (confActive && isInConference(call)) {
        cell.backgroundColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:1];
    } else{
        cell.backgroundColor = [UIColor colorWithRed:1 green:0.5 blue:0 alpha:1];
    }*/
    
    
    LinphoneCall* selectedCall = linphone_core_get_current_call([LinphoneManager getLc]);
    if (call == selectedCall) {
        [cell setSelected:YES animated:NO];
        [callTableView selectRowAtIndexPath:path animated:NO scrollPosition:UITableViewScrollPositionNone];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }else{
        [cell setSelected:NO animated:NO];
        [callTableView deselectRowAtIndexPath:path animated:NO];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}


-(void) updateConferenceCell:(UITableViewCell*) cell at:(NSIndexPath*)indexPath {
    [cell.textLabel setText:@"Conference"];
    
    LinphoneCore* lc = [LinphoneManager getLc];
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    [self updateActive:NO cell:cell];
    cell.selected = NO;
    [callTableView deselectRowAtIndexPath:indexPath animated:NO];
    
    NSMutableString* ms = [[NSMutableString alloc] init ];
    const MSList* calls = linphone_core_get_calls(lc);
    while (calls) {
        LinphoneCall* call = (LinphoneCall*)calls->data;
        if (isInConference(call)) {
             const LinphoneAddress* addr = linphone_call_get_remote_address(call);
            
            const char* n = linphone_address_get_display_name(addr);
            if (n) 
                [ms appendFormat:@"%s ", n, nil];
            else
                [ms appendFormat:@"%s ", linphone_address_get_username(addr), nil];
            
            //if (call == selectedCall)
            //    [self updateActive:YES cell:cell];
			LinphoneCall* selectedCall = linphone_core_get_current_call([LinphoneManager getLc]);
            if (call == selectedCall) {
                [callTableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                cell.selected = YES;
                 cell.accessoryType = UITableViewCellAccessoryCheckmark;
                
            }
        }
        calls = calls->next;
    }
    [cell.detailTextLabel setText:ms];
    
    /*if (linphone_core_is_in_conference(lc))
        cell.backgroundColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:1];
    else
        cell.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:1];*/
}


// UITableViewDataSource (required)
- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [callTableView dequeueReusableCellWithIdentifier:@"MyIdentifier"];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"MyIdentifier"] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    LinphoneCore* lc = [LinphoneManager getLc];
    if (indexPath.row == 0 && linphone_core_get_conference_size(lc) > 0)
        [self updateConferenceCell:cell at:indexPath];
    else
        [self updateCell:cell at:indexPath withCall: [self retrieveCallAtIndex:indexPath.row inConference:NO]
            conferenceActive:linphone_core_is_in_conference(lc)];

    cell.userInteractionEnabled = YES; 
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    //cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    
    
    
    /*NSString *path = [[NSBundle mainBundle] pathForResource:[item objectForKey:@"imageKey"] ofType:@"png"];
    UIImage *theImage = [UIImage imageWithContentsOfFile:path];
    cell.imageView.image = theImage;*/
    return cell;
} 


// UITableViewDataSource (required)
- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    LinphoneCore* lc = [LinphoneManager getLc];
    
    return callCount(lc) + (int)(linphone_core_get_conference_size(lc) > 0);
    
    if (section == 0 && linphone_core_get_conference_size(lc) > 0)
        return linphone_core_get_conference_size(lc) - linphone_core_is_in_conference(lc);
    
    return callCount(lc);
}

// UITableViewDataSource
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
    LinphoneCore* lc = [LinphoneManager getLc];
    int count = 0;
    
    if (callCount(lc) > 0)
        count++;
    
    if (linphone_core_get_conference_size([LinphoneManager getLc]) > 0)
        count ++;
    
    return count;
}

// UITableViewDataSource
//- (NSArray*) sectionIndexTitlesForTableView:(UITableView *)tableView {
//   return [NSArray arrayWithObjects:@"Conf", @"Calls", nil ];
//}

// UITableViewDataSource
- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
    return @"Calls";
    if (section == 0 && linphone_core_get_conference_size([LinphoneManager getLc]) > 0)
        return @"Conference";
    else
        return @"Calls";
}

// UITableViewDataSource
- (NSString*) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    LinphoneCore* lc = [LinphoneManager getLc];
    
    [[callTableView cellForRowAtIndexPath:indexPath] setSelected:YES animated:NO];
        
    bool inConf = (indexPath.row == 0 && linphone_core_get_conference_size(lc) > 0);
    
    LinphoneCall* selectedCall = [self retrieveCallAtIndex:indexPath.row inConference:inConf];
    
    if (inConf) {
        if (linphone_core_is_in_conference(lc))
            return;
        LinphoneCall* current = linphone_core_get_current_call(lc);
        if (current)
            linphone_core_pause_call(lc, current);
        linphone_core_enter_conference([LinphoneManager getLc]);
    } else if (selectedCall) {
        if (linphone_core_is_in_conference(lc)) {
            linphone_core_leave_conference(lc);
        }
        linphone_core_resume_call([LinphoneManager getLc], selectedCall);
    }
    
    [self updateUIFromLinphoneState: nil];    
}


@end