
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UINavigationController.h>

#import "Vibrate.h"
#import "Location.h"
#import "Device.h"
#import "Sound.h"
//#import "Contacts.h"


@class GlassViewController;
@class Sound;
//@class Contacts;

@interface GlassAppDelegate : NSObject <
    UIApplicationDelegate, 
    UIWebViewDelegate, 
    CLLocationManagerDelegate, 
    UIAccelerometerDelegate,
    UIImagePickerControllerDelegate, 
    UIPickerViewDelegate, 
    UINavigationControllerDelegate
  >
{

	
	IBOutlet UIWindow *window;
	IBOutlet GlassViewController *viewController;
	IBOutlet UIWebView *webView;
	IBOutlet UIImageView *imageView;
	IBOutlet UIActivityIndicatorView *activityView;
  
	IBOutlet UIToolbar *urbianToolbar; //added by urbian
	IBOutlet UIDatePicker *datePicker; //added by urbian
	IBOutlet UIToolbar *datePickerDone; //added by urbian
	
	IBOutlet UIBarButtonItem *linkButton_1; //added by urbian
	IBOutlet UIBarButtonItem *linkButton_2; //added by urbian
	IBOutlet UIBarButtonItem *linkButton_3; //added by urbian
	IBOutlet UIBarButtonItem *linkButton_4; //added by urbian
	IBOutlet UIBarButtonItem *linkButton_5; //added by urbian

	CLLocationManager *locationManager;
	CLLocation		  *lastKnownLocation;

	UIImagePickerController *picker; //urbian
	NSString *photoUploadUrl; // added by urbian
	NSString *lastUploadedPhoto; //added by urbian
	NSURLConnection *conn; //added by urbian
	NSMutableData   *receivedData; //added by urbian
	
	NSDictionary *dictonary;
	
	NSURLConnection *callBackConnection;
	Sound *sound;
	//Contacts *contacts;
	NSURL* appURL;
}

@property (nonatomic, retain) CLLocation *lastKnownLocation;
@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) GlassViewController *viewController;
@property (nonatomic, retain) UIImagePickerController *picker;

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image2 editingInfo:(NSDictionary *)editingInfo;
- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker;

// added by urbian (g.mueller@urbian.org)
- (IBAction)goToLink: (id)sender;
- (IBAction)datePickerDoneAction;

@end