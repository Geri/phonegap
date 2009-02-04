#import "GlassAppDelegate.h"
#import "GlassViewController.h"
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>


@implementation GlassAppDelegate

@synthesize window;
@synthesize viewController;

@synthesize lastKnownLocation;
@synthesize picker; //urbian

void alert(NSString *message) {
    UIAlertView *openURLAlert = [[UIAlertView alloc] initWithTitle:@"Alert" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [openURLAlert show];
    [openURLAlert release];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {


	locationManager = [[CLLocationManager alloc] init];
	locationManager.delegate = self;
	[locationManager startUpdatingLocation];
	
	webView.delegate = self;
  	
	[[UIAccelerometer sharedAccelerometer] setUpdateInterval:1.0/40.0];
	[[UIAccelerometer sharedAccelerometer] setDelegate:self];

	[window addSubview:viewController.view]; 
	
	NSString *errorDesc = nil;
	
	NSPropertyListFormat format;
	NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"plist"];
	NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
	dictonary = (NSDictionary *)[NSPropertyListSerialization
										  propertyListFromData:plistXML
										  mutabilityOption:NSPropertyListMutableContainersAndLeaves			  
										  format:&format errorDescription:&errorDesc];
	[dictonary retain];
	
	NSString *mode;
	NSString *url;
	int detectNumber;

	mode			= [dictonary objectForKey:@"Offline"];
	url				= [dictonary objectForKey:@"Callback"];
	detectNumber	= (int)[dictonary objectForKey:@"DetectPhoneNumber"]; 
		
	if ([mode isEqualToString:@"0"]) {
		// Online Mode
		appURL = [[NSURL URLWithString:url] retain];
		NSURLRequest * aRequest = [NSURLRequest requestWithURL:appURL];
		[webView loadRequest:aRequest];
	} else {		
		// Offline Mode
		NSString * urlPathString;
		NSBundle * thisBundle = [NSBundle bundleForClass:[self class]];
		if (urlPathString = [thisBundle pathForResource:@"index" ofType:@"html" inDirectory:@"www"]){
			[webView  loadRequest:[NSURLRequest
								   requestWithURL:[NSURL fileURLWithPath:urlPathString]
								   cachePolicy:NSURLRequestUseProtocolCachePolicy
								   timeoutInterval:20.0
								   ]];
			
		}   
	}
	
	webView.detectsPhoneNumbers=detectNumber;
	
	//This keeps the Default.png up
	imageView = [[UIImageView alloc] initWithImage:[[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Default" ofType:@"png"]]];
	[window addSubview:imageView];
  
	//for the activityView (urbian.org)
	activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	activityView.frame = CGRectMake(139.0f-18.0f, 80.0f, 37.0f, 37.0f);
	//Center to view
	activityView.center = webView.center;
	activityView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
	activityView.hidesWhenStopped = YES;
	[webView addSubview:activityView];
	
	[window makeKeyAndVisible];

	
	//NSBundle * mainBundle = [NSBundle mainBundle];


}

//when web application loads pass it device information
- (void)webViewDidStartLoad:(UIWebView *)theWebView {
  [theWebView stringByEvaluatingJavaScriptFromString:[[Device alloc] init]];
}

- (void)webViewDidFinishLoad:(UIWebView *)theWebView {
	imageView.hidden = YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	if ([error code] != NSURLErrorCancelled)
		alert(error.localizedDescription);
}

- (BOOL)webView:(UIWebView *)theWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	NSURL* url = [request URL];
	NSString * urlString = [url absoluteString];
	
	NSBundle * mainBundle = [NSBundle mainBundle];
	
	// Check to see if the URL request is for the App URL.
	// If it is not, then launch using Safari
	NSString* urlHost = [url host];
	NSString* appHost = [appURL host];
	NSRange range = [urlHost rangeOfString:appHost options:NSCaseInsensitiveSearch];
	if (range.location == NSNotFound)
		[[UIApplication sharedApplication] openURL:url];
    
	NSString * jsCallBack = nil;
	NSArray * parts = [urlString componentsSeparatedByString:@":"];

	double lat = lastKnownLocation.coordinate.latitude;
	double lon = lastKnownLocation.coordinate.longitude;

	if ([parts count] > 1 && [(NSString *)[parts objectAtIndex:0] isEqualToString:@"gap"]) {
		
		if ([(NSString *)[parts objectAtIndex:0] isEqualToString:@"gap"]){
			
			if([(NSString *)[parts objectAtIndex:1] isEqualToString:@"getloc"]){
				NSLog(@"location request!");

				jsCallBack = [[NSString alloc] initWithFormat:@"gotLocation('%f','%f');", lat, lon];
				NSLog(jsCallBack);
				[theWebView stringByEvaluatingJavaScriptFromString:jsCallBack];
				
				[jsCallBack release];
			} else if([(NSString *)[parts objectAtIndex:1] isEqualToString:@"getphoto"]){
				
				// added/modified by urbian.org - g.mueller @urbian.org
					
				NSUInteger imageSource;
				
				//set upload url
				photoUploadUrl = [parts objectAtIndex:3];
				[photoUploadUrl retain];
				
				NSLog([@"photo-url: " stringByAppendingString:photoUploadUrl]);
				
				//which image source
				if([(NSString *)[parts objectAtIndex:2] isEqualToString:@"fromCamera"]){
					imageSource = UIImagePickerControllerSourceTypeCamera;
				} else if([(NSString *)[parts objectAtIndex:2] isEqualToString:@"fromLibrary"]){
					imageSource = UIImagePickerControllerSourceTypePhotoLibrary;	
				} else {
					NSLog(@"photo: no Source type set");
					return NO;
				}
				
				//check if source is available
				if([UIImagePickerController isSourceTypeAvailable:imageSource])
				{
					picker = [[UIImagePickerController alloc]init];
					picker.sourceType = imageSource;
					picker.allowsImageEditing = YES;
					picker.delegate = self;
					
					[viewController presentModalViewController:picker animated:YES];
					
				} else {
					NSLog(@"photo: source not available!");
					return NO;
				}
				
				webView.hidden = YES;
				
				NSLog(@"photo: dialog open now!");
				
				/* old code
				NSLog(@"Photo request!");
				NSLog([parts objectAtIndex:2]);
			
				imagePickerController.view.hidden = NO;
				webView.hidden = YES;
				[window bringSubviewToFront:imagePickerController.view];
				NSLog(@"photo dialog open now!");
				 */
				 
			} else if([(NSString *)[parts objectAtIndex:1] isEqualToString:@"vibrate"]){
				Vibrate *vibration = [[Vibrate alloc] init];
				[vibration vibrate];
				[vibration release];

				//contacts = [[Contacts alloc] init];
				//[contacts getContacts];
			
			} else if([(NSString *)[parts objectAtIndex:1] isEqualToString:@"openmap"]) {
				
				NSString *mapurl = [@"maps:" stringByAppendingString:[parts objectAtIndex:2]];
				
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:mapurl]];
			} else if ([(NSString *)[parts objectAtIndex:1] isEqualToString:@"sound"]) {

				// Split the Sound file 
				NSString *ef = (NSString *)[parts objectAtIndex:2];
				NSArray *soundFile = [ef componentsSeparatedByString:@"."];
				
				NSString *file = (NSString *)[soundFile objectAtIndex:0];
				NSString *ext = (NSString *)[soundFile objectAtIndex:1];
				// Some TODO's here
				// Test to see if the file/ext is IN the bundle
				// Cleanup any memory that may not be caught
				sound = [[Sound alloc] initWithContentsOfFile:[mainBundle pathForResource:file ofType:ext]];
				[sound play];
				
				
			} else if([(NSString *)[parts objectAtIndex:1] isEqualToString:@"urbianmenu"]) {
				
				//show/hide the menu
				
				NSLog(@"Show Menu ...");
				
				if([(NSString *)[parts objectAtIndex:2] isEqualToString:@"true"])
					urbianToolbar.hidden = NO;
				else 
					urbianToolbar.hidden = YES;
				
			} else if([(NSString *)[parts objectAtIndex:1] isEqualToString:@"waiting"]) {
			//added by urbian
				// start/stop activityView animation
				//-  show a Activity Indicator View, eg while loading a new page
				//-  use "gap:waiting:start" and "gap:waiting:stop" 
				
				NSLog(@"Waiting ..");
				if([(NSString *)[parts objectAtIndex:2] isEqualToString:@"start"]) {
					[activityView startAnimating];
				} else {
					if ([activityView isAnimating]) {
						[activityView stopAnimating];
					}
				}
				
				
			} else if([(NSString *)[parts objectAtIndex:1] isEqualToString:@"datepicker"]) {
				
				//open a datepicker
				NSLog(@"Get date ...");
				
				//reset datePicker to current date
				[datePicker setDate:[NSDate date]];
				
				//set position
				if (urbianToolbar.hidden == YES) { 
					[datePicker setFrame:(CGRectMake(0.0, 250, datePicker.frame.size.width, datePicker.frame.size.height))];
					[datePickerDone setFrame:(CGRectMake(0.0, 210,datePickerDone.frame.size.width, datePickerDone.frame.size.height))];
				} else {
					[datePicker setFrame:(CGRectMake(0.0, 206, datePicker.frame.size.width, datePicker.frame.size.height))];
					[datePickerDone setFrame:(CGRectMake(0.0, 166,datePickerDone.frame.size.width, datePickerDone.frame.size.height))];
				}
				
				//set datePicker mode
				if([(NSString *)[parts objectAtIndex:2] isEqualToString:@"date"]) {
					
					datePicker.datePickerMode = UIDatePickerModeDate;
					datePicker.hidden = NO;
					datePickerDone.hidden = NO;
					
				} else if([(NSString *)[parts objectAtIndex:2] isEqualToString:@"time"]) {
					
					datePicker.datePickerMode = UIDatePickerModeTime;
					datePicker.hidden = NO;
					datePickerDone.hidden = NO;
					
				} else if([(NSString *)[parts objectAtIndex:2] isEqualToString:@"datetime"]) {
					
					datePicker.datePickerMode = UIDatePickerModeDateAndTime;
					datePicker.hidden = NO;
					datePickerDone.hidden = NO;
					
				} else if([(NSString *)[parts objectAtIndex:2] isEqualToString:@"cancel"]) {
					
					//hides the datepicker
					datePicker.hidden = YES;
					datePickerDone.hidden = YES;
				}
			}
			
			return NO;
		}
	}

	return YES;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
	[lastKnownLocation release];
	lastKnownLocation = newLocation;
	[lastKnownLocation retain];	
}


- (void) accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
	NSString * jsCallBack = nil;
	
	jsCallBack = [[NSString alloc] initWithFormat:@"gotAcceleration('%f','%f','%f');", acceleration.x, acceleration.y, acceleration.z];
	[webView stringByEvaluatingJavaScriptFromString:jsCallBack];
}

- (void)imagePickerController:(UIImagePickerController *)thePicker didFinishPickingImage:(UIImage *)theImage editingInfo:(NSDictionary *)editingInfo
{
	
	//modified by urbian.org - g.mueller @urbian.org
	
    NSLog(@"photo: picked image");
	
	NSData * imageData = UIImageJPEGRepresentation(theImage, 0.75);
	
	NSString *urlString = [@"http://" stringByAppendingString:photoUploadUrl]; // upload the photo to this url
	
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
	[request setURL:[NSURL URLWithString:urlString]];
	[request setHTTPMethod:@"POST"];
	
	// ---------
	//Add the header info
	NSString *stringBoundary = [NSString stringWithString:@"0xKhTmLbOuNdArY"];
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",stringBoundary];
	[request addValue:contentType forHTTPHeaderField: @"Content-Type"];
	
	//create the body
	NSMutableData *postBody = [NSMutableData data];
	[postBody appendData:[[NSString stringWithFormat:@"--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];

	//add data field and file data
	[postBody appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"photo_0\"; filename=\"photo\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:@"Content-Type: application/octet-stream\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[postBody appendData:[NSData dataWithData:imageData]];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	// ---------
	[request setHTTPBody:postBody];
	
	//NSURLConnection *
	conn=[[NSURLConnection alloc] initWithRequest:request delegate:self];
	
	if(conn) {		
		receivedData=[[NSMutableData data] retain];
		NSString *sourceSt = [[NSString alloc] initWithBytes:[receivedData bytes] length:[receivedData length] encoding:NSUTF8StringEncoding];
		NSLog([@"photo: connection sucess" stringByAppendingString:sourceSt]);
		
	} else {
		NSLog(@"photo: upload failed!");
	}
	
	[[thePicker parentViewController] dismissModalViewControllerAnimated:YES];
	
	webView.hidden = NO;
	[window bringSubviewToFront:webView];

}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)thePicker
{
	// Dismiss the image selection and close the program
	[[thePicker parentViewController] dismissModalViewControllerAnimated:YES];
	
	//added by urbian - the webapp should know when the user canceled
	NSString * jsCallBack = nil;
	
	jsCallBack = [[NSString alloc] initWithFormat:@"gotPhoto('CANCEL');", lastUploadedPhoto];
	[webView stringByEvaluatingJavaScriptFromString:jsCallBack];	
	[jsCallBack release];
	
	// Hide the imagePicker and bring the web page back into focus
	NSLog(@"Photo Cancel Request");
	webView.hidden = NO;
	[window bringSubviewToFront:webView];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  
	NSLog(@"photo: upload finished!");
	
	//added by urbian.org - g.mueller
	NSString *aStr = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
	
	//upload.php should return "filename=<filename>"
	NSArray * parts = [aStr componentsSeparatedByString:@"="];
	//set filename
	lastUploadedPhoto = (NSString *)[parts objectAtIndex:1];
	
	//now the callback: return lastUploadedPhoto
	
	NSString * jsCallBack = nil;
	
	if(lastUploadedPhoto == nil) lastUploadedPhoto = @"ERROR";
	
	jsCallBack = [[NSString alloc] initWithFormat:@"gotPhoto('%@');", lastUploadedPhoto];
	
	[webView stringByEvaluatingJavaScriptFromString:jsCallBack];
	
	NSLog(@"Succeeded! Received %d bytes of data",[receivedData length]);
	NSLog(jsCallBack);
	
    // release the connection, and the data object
    [conn release];
    [receivedData release];
	
	#if TARGET_IPHONE_SIMULATOR
		alert(@"Did finish loading image!");
	#endif
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *) response {
	
	//added by urbian.org
	NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
	NSLog(@"HTTP Status Code: %i", [httpResponse statusCode]);
	
	[receivedData setLength:0];
	
	NSLog(@"HERE RESPONSE");
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // append the new data to the receivedData
    // receivedData is declared as a method instance elsewhere
    [receivedData appendData:data];
    NSLog(@"photo: progress");
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog([@"photo: upload failed! " stringByAppendingString:[error description]]);
    
#if TARGET_IPHONE_SIMULATOR
    alert(@"Error while uploading image!");
#endif    
}

// for the urbian toolbar

- (IBAction)goToLink: (id)sender {
	
	NSString * jsCallBack = nil;
	NSString * mLink = nil;
	
	if (sender == linkButton_1) mLink = [dictonary objectForKey:@"Link_1"];
	else if (sender == linkButton_2) mLink = [dictonary objectForKey:@"Link_2"];
	else if (sender == linkButton_3) mLink = [dictonary objectForKey:@"Link_3"];
	else if (sender == linkButton_4) mLink = [dictonary objectForKey:@"Link_4"];
	else if (sender == linkButton_5) mLink = [dictonary objectForKey:@"Link_5"];
	
	jsCallBack = [[NSString alloc] initWithFormat:@"change_module('%@', 'module_divShift_%@.php', 'isApp=1');", mLink, mLink];
	
	NSLog(jsCallBack);
	
	[webView stringByEvaluatingJavaScriptFromString:jsCallBack];
	[jsCallBack release];
	
}

// if user changed Date of Datepicker

- (IBAction) datePickerDoneAction {
	
	datePicker.hidden = YES;
	datePickerDone.hidden = YES;
	
	NSString * jsCallBack = nil;
	NSString * selDate = nil; 
	
	selDate = [datePicker.date descriptionWithCalendarFormat:@"'%Y', '%m', '%d', '%X'" timeZone:nil locale:nil];
	
	jsCallBack = [[NSString alloc] initWithFormat:@"gotDate(%@);", selDate];
	[webView stringByEvaluatingJavaScriptFromString:jsCallBack];
	[jsCallBack release];
	
	NSLog(jsCallBack);

} 


- (void)dealloc {
	[appURL release];
	[activityView release];
	[imageView release];
	[viewController release];
	[window release];
	[lastKnownLocation release];
	[picker release]; //urbian
	[appURL release];
	[datePicker release]; //urbian
	[datePickerDone release]; //urbian
	
	[photoUploadUrl release]; //added by urbian
	[dictonary release];
	
	[super dealloc];
}


@end
