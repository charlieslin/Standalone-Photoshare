//
//  ScreenShotViewController.h
//  PhotoShare
//
//  Created by Charlie Lin on 05/09/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#include <CoreMotion/CoreMotion.h>


@interface ScreenShotViewController:UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate, UIGestureRecognizerDelegate>
{
    AVCaptureSession *capturedSession;
    AVCaptureVideoPreviewLayer *previewLayer;
    AVCaptureStillImageOutput *capturedStillImageOutput;
    
	UIView *mainView;
	UIView *overlayView;
    UIImageView *overlayImageView;
    UIImageView *backgroundImageView;
    
    CMMotionManager *_motionManager;
    
    //ScreenshotPreview * scrVw;
    UIInterfaceOrientation currentOrientation;

    UITextView *findTaylorImageView;
    
    //Store the position of the image overlay
    float overlayPositionY;
    float overlayPositionX;
    float overlayScale;
    float overlayAngle;
    
    UIButton * closeBtn;                                    //<! button for closing at the header
    UIView * headerView;                                    //<! Header of the AR layout
    
    
    //////AD
    //UIViewController *parentcntrl;
    UIImageView *UserSelImage;
    
    UIImage *imgUserPhoto;
    NSURL *overlayimageUrl;
    
    BOOL blnmovetoCommentScreen;
    BOOL blnScreenLoaded;
    
    NSMutableArray *overlaysArray;
    NSMutableArray *framesArray;
    BOOL overlaysOn;
    
    UIButton *highlightedOverlay;
    UIButton *highlightedFrame;
    
    UIColor *normalBorderColor;
    UIColor *selectedBorderColor;
    
    NSArray *framesAndOverlays;
    
    //HJManagedImageV *frame;
    //HJManagedImageV *overlay;
    //UIImageView *frame;
    //UIImageView *overlay;
    
    CGFloat cx_overlay;
    CGFloat cx_frame;
    NSUInteger nimages_overlays;
    NSUInteger nimages_frames;

}

@property (retain, nonatomic) IBOutlet UIImageView *tutorialImage;
@property (retain, nonatomic) IBOutlet UIView *scrollViewContainer;
@property (retain, nonatomic) IBOutlet UIButton *takePhotoBtn;
@property (retain, nonatomic) IBOutlet UIButton *retakeBtn;
@property (retain, nonatomic) IBOutlet UIButton *doneBtn;
@property (retain, nonatomic) IBOutlet UIImageView *previewImageView;
@property (nonatomic, retain) NSMutableArray *overlaysArray;
@property (nonatomic, retain) NSMutableArray *framesArray;
@property (retain, nonatomic) IBOutlet UIScrollView *overlayScrollView;
@property (retain, nonatomic) IBOutlet UIScrollView *framesScrollView;
@property (retain, nonatomic) IBOutlet UIView *frameView;
@property (retain, nonatomic) IBOutlet UIImageView *frameImageView;
@property (nonatomic, retain) NSURL *overlayimageUrl;
//@property (nonatomic, retain)IBOutlet  HJManagedImageV *UserSelImage;
@property (nonatomic, retain)IBOutlet  UIImageView *UserSelImage;
@property (nonatomic, retain) UIImage *imgUserPhoto;

@property (retain, nonatomic) IBOutlet UILabel *positionLabel;

// Properties for UIKit Screenshot
@property (nonatomic, retain) IBOutlet UIView *mainView;
@property (nonatomic, retain) IBOutlet UIView *overlayView;
@property (nonatomic, retain) IBOutlet UIImageView *overlayImageView;
@property (nonatomic, retain) IBOutlet UIImageView *backgroundImageView;
@property (nonatomic, retain) IBOutlet UITextView *findTaylorImageView;

//@property (nonatomic, assign) UIViewController *parentcntrl;
//@property (nonatomic, assign) ScreenshotPreview * scrVw;
// Properties for Preview Image and Views
@property (nonatomic, retain) UIImage *screenshotImage;

// Properties for AVFoundation (camera) Screenshot
@property (nonatomic, retain) AVCaptureSession *capturedSession;
@property (nonatomic, retain) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, retain) AVCaptureStillImageOutput	*capturedStillImageOutput;

@property (nonatomic, retain) IBOutlet UIButton *photoShotButton;

@property (nonatomic, retain) CMMotionManager *motionManager;

@property float overlayPositionY;
@property float overlayPositionX;
@property float overlayScale;
@property float overlayAngle;

@property BOOL blnScreenLoaded;

@property (retain, nonatomic) IBOutlet UIButton *overlayButton;
@property (retain, nonatomic) IBOutlet UIButton *frameButton;

- (IBAction)toggleToOverlays:(id)sender;

- (IBAction)toggleToFrames:(id)sender;

// Screenshot Camera Methods
- (IBAction)pressDone:(id)sender;
- (IBAction)returnToCamera:(id)sender;
- (IBAction)takePhoto;
- (IBAction)cancelPhoto;
-(void) openPreview;
-(void) ShowCamera;

-(NSString *) formatDateString:(NSString *)dateString;

/**
 Action performed when the back button is pressed.
 If the events are open does nothing, otherwise it dismiss the current view
 @param sender Id of the element that called the method
 */
- (void) buttonClicked: (id)sender;

-(void) RotateInterfaceTo:(UIInterfaceOrientation) rotation;
@end
