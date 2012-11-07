//
//  ScreenShotViewController.m
//  PhotoShare
//
//  Created by Charlie Lin on 05/09/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ScreenShotViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <QuartzCore/QuartzCore.h>
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>
//#import "ScreenshotPreview.h"
//import "CustomLabelTitle.h"
#import "MBProgressHUD.h"


#define FRAME_SIZE 320
#define HEADER_OFFSET 30     //<!Size of the header to contain the back button and the ARoverlaybar
#define BUTTON_OFFSET_H 3    //<!Margins of the close button
#define BUTTON_OFFSET_W 50    //<!Margins of the close button
#define PRELOADED_OVERLAYS 7
#define PRELOADED_FRAMES 1
#define SCROLLVIEW_THUMBS 5
//#define ADJUST_RATIO 30
#define ADJUST_RATIO 0

static float sfPreviousScale;

// View Controller Class Extension
@interface ScreenShotViewController()

- (void)renderView:(UIView*)view inContext:(CGContextRef)context;
- (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections;
- (void)setupCaptureSession;
- (void)captureStillImage;
- (void)autofocusNotSupported;
- (void)captureStillImageFailedWithError:(NSError *)error;
- (void)cannotWriteToAssetLibrary;
- (void)cameraOn;
- (void)cameraOff;

@end

@implementation ScreenShotViewController

@synthesize mainView;
@synthesize overlayView;
@synthesize overlayImageView;
@synthesize backgroundImageView;
@synthesize findTaylorImageView;

@synthesize capturedSession;
@synthesize previewLayer;
@synthesize capturedStillImageOutput;

@synthesize photoShotButton;
@synthesize tutorialImage;
@synthesize screenshotImage;
//@synthesize scrVw;
//Allow to use Gyroscope data
@synthesize motionManager = _motionManager;

//Store the position of the Taylor overlay
@synthesize overlayPositionY;
@synthesize overlayPositionX;
@synthesize overlayScale;
@synthesize overlayAngle;
//@synthesize parentcntrl;
@synthesize UserSelImage;
@synthesize imgUserPhoto;
@synthesize overlayScrollView;
@synthesize framesScrollView;
@synthesize frameView;
@synthesize frameImageView;
@synthesize overlayimageUrl;
@synthesize blnScreenLoaded;
@synthesize overlayButton;
@synthesize frameButton;
@synthesize overlaysArray;
@synthesize framesArray;
@synthesize previewImageView;
@synthesize doneBtn;
@synthesize retakeBtn;
@synthesize takePhotoBtn;
@synthesize scrollViewContainer;
@synthesize positionLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
    {
        //Initialization Stuff here
    }
    return self;
}


- (void)dealloc
{
    //NSLog(@"SCreenshot Dealloc");
    
    
    imgUserPhoto=nil;
    [mainView release];
	[overlayView release];
    [overlayImageView release];
    [backgroundImageView release];
	
	screenshotImage=nil;
    
    [capturedSession release];
    [previewLayer release];
    //NSLog(@"retain count of overlay image at dealloc: %d", [UserSelImage.image retainCount]);
    [UserSelImage release];
    
    [capturedStillImageOutput release];
    [photoShotButton release];
    _motionManager=nil;
    
    [overlayimageUrl release];
    overlayimageUrl=nil;
    //parentcntrl=nil;
    //if(scrVw)
    //    [scrVw release];
    //scrVw = nil;
    
    [findTaylorImageView release]; findTaylorImageView=nil;
    
    //[macysOverlayImageView release]; macysOverlayImageView=nil;
    
    [overlayScrollView release];
    [framesScrollView release];
    [frameView release];
    [frameImageView release];
    [overlayButton release];
    [frameButton release];
    
    [normalBorderColor release];
    [selectedBorderColor release];
    
    //[framesAndOverlays release];
    
    //[frame release];
    //[overlay release];
    [framesArray release];
    [overlaysArray release];
    
    [previewImageView release];
    [doneBtn release];
    [retakeBtn release];
    [takePhotoBtn release];
    [scrollViewContainer release];
    [positionLabel release];
    [tutorialImage release];
    [super dealloc];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
    //set initially to overlays
    overlayButton.selected = YES;
    
    photoShotButton.enabled=YES;
    
    //Save the last known orientation
    currentOrientation = UIInterfaceOrientationPortrait;
    
    //This method is now called from the superview
	//[self performSelectorInBackground:@selector(loadOverLayImage) withObject:nil];//TODO
    
    //Adding the HEADER to show the BACK button
    //headerView = [[[UIView alloc] initWithFrame: CGRectMake(0,0,self.view.frame.size.width,HEADER_OFFSET)] autorelease];
    //[self.view addSubview: headerView];
    
    //Register a notification to detect when a rotation has ocurred
    [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(receivedRotate:) name: UIDeviceOrientationDidChangeNotification object: nil];
    
    
    //[self setupScrollViews];

    [self receivedRotate:nil];
    
    
    //create the shadow on scrollviews
    //[overlayScrollView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"backgroundLeftBar.png"]]];
    //[framesScrollView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"backgroundRightBar.png"]]];
    //RGB: 38 34 43
    //[overlayScrollView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"scrollBGH.jpg"]]];
    //[framesScrollView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"scrollBGH.jpg"]]];
    [overlayScrollView setBackgroundColor:[UIColor colorWithRed:38.0/255.0 green:34.0/255.0 blue:43.0/255.0 alpha:1.0]];
    [framesScrollView setBackgroundColor:[UIColor colorWithRed:38.0/255.0 green:34.0/255.0 blue:43.0/255.0 alpha:1.0]];
    CALayer * l1 = [overlayScrollView layer];
    l1.borderWidth = 1.0;
    l1.borderColor = [UIColor colorWithRed:85.0/255.0 green:85.0/255.0 blue:85.0/255.0 alpha:1.0].CGColor;
    [l1 setShadowOffset:CGSizeMake(2.0, 2.0)];
    [l1 setShadowRadius:2.0];
    [l1 setShadowOpacity:1.0];
    l1.shouldRasterize = YES;
    
    CALayer * l2 = [framesScrollView layer];
    l2.borderWidth = 1.0;
    l2.borderColor = [UIColor colorWithRed:85.0/255.0 green:85.0/255.0 blue:85.0/255.0 alpha:1.0].CGColor;
    [l2 setShadowOffset:CGSizeMake(2.0, 2.0)];
    [l2 setShadowRadius:2.0];
    [l2 setShadowOpacity:1.0];
    l2.shouldRasterize = YES;
    
    //[framesScrollView setHidden:YES];
    
    normalBorderColor = [UIColor colorWithRed:85.0/255.0 green:85.0/255.0 blue:85.0/255.0 alpha:0.6];
    [normalBorderColor retain];
    selectedBorderColor = [UIColor colorWithRed:106.0/255.0 green:103.0/255.0 blue:111.0/255.0 alpha:1.0];
    [selectedBorderColor retain];
    
    /*
    //frame = [[HJManagedImageV alloc] initWithFrame:CGRectMake(0,0,FRAME_SIZE,FRAME_SIZE)];
    frame = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,FRAME_SIZE,FRAME_SIZE)];
    frame.contentMode = UIViewContentModeScaleAspectFill;
    frame.image = nil;
    [self.frameView addSubview:frame];
    
    //overlay = [[HJManagedImageV alloc] initWithFrame:CGRectMake(83,-18,118,433)];
    overlay = [[UIImageView alloc] initWithFrame:CGRectMake(83,-18,118,433)];
    overlay.contentMode = UIViewContentModeScaleAspectFit;
    overlay.image = nil;
    [self.overlayView addSubview:overlay];
    
    //AEGAppDelegate *appDelegate = (AEGAppDelegate *)[[UIApplication sharedApplication] delegate];
    //[appDelegate.hjObjManager manage:frame];
    //[appDelegate.hjObjManager manage:overlay];
    */
    framesArray = [[NSMutableArray alloc] init];
    overlaysArray = [[NSMutableArray alloc] init];
    cx_overlay = 0;
    cx_frame = 0;
    
    [self setupPreloadedScrollViews];
    
    //set up some settings for the preview image
    doneBtn.hidden = YES;
    CALayer *previewImageLayer = [previewImageView layer];
    //previewImageLayer.masksToBounds = YES;
    self.mainView.layer.masksToBounds = YES;
    positionLabel.alpha = 0;

    [super viewDidLoad];
}


- (IBAction)toggleToOverlays:(id)sender  {
    if(frameButton.isSelected)  {
        frameButton.selected = NO;
        overlayButton.selected = YES;
        
        [UIView transitionFromView:framesScrollView
                            toView:overlayScrollView
                          duration:0.75
                           options:UIViewAnimationOptionTransitionFlipFromLeft
                        completion:^(BOOL finished){
                            /* do something on animation completion */
                        }];

    }
}

- (IBAction)toggleToFrames:(id)sender  {
    if(overlayButton.isSelected)  {
        overlayButton.selected = NO;
        frameButton.selected = YES;
        
        [UIView transitionFromView:overlayScrollView
                            toView:framesScrollView
                          duration:0.75
                           options:UIViewAnimationOptionTransitionFlipFromLeft
                        completion:^(BOOL finished){
                            /* do something on animation completion */
                        }];
        
    }
}

- (IBAction)toggleScrollViews  {
    //left: 0, 44, 50, 430
    //right: 270, 44, 50, 430
    
    if(overlaysOn)  {
        //shift scroll views out
        [UIView transitionFromView:overlayScrollView
                            toView:framesScrollView
                          duration:0.75
                           options:UIViewAnimationOptionTransitionFlipFromLeft
                        completion:^(BOOL finished){
                            /* do something on animation completion */
                        }];
        
        /*
        [UIView transitionWithView:framesScrollView    // use the forView: argument
                          duration:1          // use the setAnimationDuration: argument
                           options:UIViewAnimationOptionTransitionFlipFromLeft
                        // check UIViewAnimationOptions for what options you can use
                        animations:^{         // put the animation block here
                            [overlayScrollView setHidden:YES];
                            [framesScrollView setHidden:NO];
                        }
        completion:NULL];
         */
         
        overlaysOn = NO;
    }
    else  {
        //shift scroll views in
        [UIView transitionFromView:framesScrollView
                            toView:overlayScrollView
                          duration:0.75
                           options:UIViewAnimationOptionTransitionFlipFromLeft
                        completion:^(BOOL finished){
                            /* do something on animation completion */
                        }];

        overlaysOn = YES;
    }
    
}

- (IBAction)cancelPhoto  {
    //[self dismissModalViewControllerAnimated:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

/*
- (void) buttonClicked: (id)sender
{
    //The superview will change this view with the tableview
    [self dismissModalViewControllerAnimated:YES];
}
*/

-(void) chooseOverlay: (id) sender  {
    
    UserSelImage.image = nil;
    //NSLog(@"retain count of overlay image: %d", [UserSelImage.image retainCount]);
    
    //remove higlighted color
    if(highlightedOverlay)  {
        CALayer * l = [highlightedOverlay layer];
        l.shadowOpacity = 0.0;
    }
    
    //if this overlay is already on the screen, remove it if user taps again
    if(highlightedOverlay == sender)  {
        highlightedOverlay = nil;
        //overlay.image = nil;
        
        return;
    }
    
    //add highlighted color to new selection
    highlightedOverlay = (UIButton *)sender;
    
    CALayer * l = [highlightedOverlay layer];
    l.shadowColor = [UIColor whiteColor].CGColor;
    l.shadowRadius = 1.0;
    l.shadowOpacity = 1.0;
    l.shadowOffset = CGSizeZero;
    //l.shouldRasterize = YES;

    
    UIButton *theButton = (UIButton *)sender;
    //NSLog(@"The count of the array: %d", overlayArray.count);
    if(theButton.tag < PRELOADED_OVERLAYS)  {
        //overlay.image = [UIImage imageNamed:[NSString stringWithFormat:@"overlay%d.png", theButton.tag+1]];
        UserSelImage.image = [UIImage imageNamed:[NSString stringWithFormat:@"overlay%d.png", theButton.tag+1]];
        NSLog(@"File name: %@", [NSString stringWithFormat:@"overlay%d.png", theButton.tag+1]);
    }

    
    [self receivedRotate:nil];
    //[self.view setNeedsDisplay];
    //AEGAppDelegate *appDelegate = (AEGAppDelegate *)[[UIApplication sharedApplication] delegate];
    //[appDelegate.hjObjManager manage:overlay];
    //self.UserSelImage.url = [NSURL URLWithString:imageUrl];
    /*
    PFObject *newOverlay = [overlayArray objectAtIndex:theButton.tag];
    PFFile *overlayPhoto = [newOverlay objectForKey:(@"image")];
    [overlayPhoto getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if(!error)  {
            UIImage *newOverlayImage = [UIImage imageWithData:data];
            //[self loadoverlayImageonCamera:newOverlayImage];
            //self.overlayImageView.image = newOverlayImage;
            [self.UserSelImage setImage:newOverlayImage];
            
            self.overlayImageView.frame = CGRectMake(overlayImageView.frame.origin.x, overlayImageView.frame.origin.y, newOverlayImage.size.width, newOverlayImage.size.height);
        }
    }];*/
}

-(void) chooseFrame: (id) sender  {
    frameImageView.image = nil;
    
    //remove higlighted color
    if(highlightedFrame)  {
        CALayer * l = [highlightedFrame layer];
         l.shadowOpacity = 0.0;
    }
    
    //if this overlay is already on the screen, remove it if user taps again
    if(highlightedFrame == sender)  {
        
        highlightedFrame = nil;
        //frame.image = nil;

        return;
    }
    
    //add highlighted color to new selection
    highlightedFrame = (UIButton *)sender;
    
    CALayer * l = [highlightedFrame layer];
    l.shadowColor = [UIColor whiteColor].CGColor;
    l.shadowRadius = 1.0;
    l.shadowOpacity = 1.0;
    l.shadowOffset = CGSizeZero;
    //l.shouldRasterize = YES;

    highlightedFrame = (UIButton *)sender;
    UIButton *theButton = (UIButton *)sender;
    
    if(theButton.tag < PRELOADED_FRAMES)  {
        //frame.image = [UIImage imageNamed:[NSString stringWithFormat:@"frame%d.png", theButton.tag+1]];
        frameImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"frame%d.png", theButton.tag+1]];
    }

    
    [self receivedRotate:nil];
    /*
    PFObject *newFrame = [framesArray objectAtIndex:theButton.tag];
    PFFile *frame = [newFrame objectForKey:(@"image")];
    [frame getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if(!error)  {
            UIImage *newFrameImage = [UIImage imageWithData:data];
            //[self loadoverlayImageonCamera:newOverlayImage];
            frameImageView.image = newFrameImage;
        }
    }];*/
}

-(void) setupPreloadedScrollViews  {
    [framesScrollView setCanCancelContentTouches:NO];
    
    framesScrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    framesScrollView.clipsToBounds = NO;
    framesScrollView.scrollEnabled = YES;
    framesScrollView.pagingEnabled = NO;
    
    [overlayScrollView setCanCancelContentTouches:NO];
    
    overlayScrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    overlayScrollView.clipsToBounds = NO;
    overlayScrollView.scrollEnabled = YES;
    overlayScrollView.pagingEnabled = NO;
    
    
    NSInteger tot= 0;
    nimages_overlays = 0;
    for (;tot<PRELOADED_OVERLAYS; nimages_overlays++) {
        
        if (SCROLLVIEW_THUMBS==nimages_overlays) {
            nimages_overlays=0;
        }
        
        UIImageView *imageView = [[UIImageView alloc] init];
        UIButton *thumbnailButton = [[UIButton alloc] init];
            
        imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"overlay%d_thumb.png", tot+1]];
        CGRect rect = imageView.frame;
        rect.size.height = 50;
        rect.size.width = 50;
        rect.origin.x = cx_overlay;
        rect.origin.y = 0;
        
        imageView.frame = rect;
        imageView.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.3];
        thumbnailButton.frame = rect;
            
        [overlayScrollView addSubview:imageView];
        [imageView release];
            
        [thumbnailButton setTag:tot];
        [thumbnailButton addTarget:self action:@selector(chooseOverlay:) forControlEvents:UIControlEventTouchUpInside];
        [overlayScrollView addSubview:thumbnailButton];
        [thumbnailButton release];
            
        CALayer * l = [thumbnailButton layer];
        //[l setCornerRadius:10.0];
            
        l.borderWidth = 2.0;
        l.borderColor = normalBorderColor.CGColor;
        
        cx_overlay += imageView.frame.size.width+5;
            
        tot++;
    }
    
    
    tot = 0;
    nimages_frames = 0;
    for (;tot<PRELOADED_FRAMES; nimages_frames++) {
        
        if (SCROLLVIEW_THUMBS==nimages_frames) {
            nimages_frames=0;
        }
        
        UIImageView *imageView = [[UIImageView alloc] init];
        UIButton *thumbnailButton = [[UIButton alloc] init];
        
        imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"frame%d_thumb.png", tot+1]];
        CGRect rect = imageView.frame;
        rect.size.height = 50;
        rect.size.width = 50;
        rect.origin.x = cx_frame;
        rect.origin.y = 0;
        
        imageView.frame = rect;
        imageView.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.3];
        thumbnailButton.frame = rect;
        
        [framesScrollView addSubview:imageView];
        [imageView release];
        
        [thumbnailButton setTag:tot];
        [thumbnailButton addTarget:self action:@selector(chooseFrame:) forControlEvents:UIControlEventTouchUpInside];
        [framesScrollView addSubview:thumbnailButton];
        [thumbnailButton release];
        
        CALayer * l = [thumbnailButton layer];
        //[l setCornerRadius:10.0];
        
        l.borderWidth = 2.0;
        l.borderColor = normalBorderColor.CGColor;
        
        cx_frame += imageView.frame.size.width+5;
        
        tot++;
    }
    
    [overlayScrollView setContentSize:CGSizeMake(cx_overlay, [overlayScrollView bounds].size.height)];
    [framesScrollView setContentSize:CGSizeMake(cx_frame, [overlayScrollView bounds].size.height)];

}


-(void) loadOverLayImage
{
    
    UIImage *temp = [UIImage imageNamed:@"logoHidden"];
    [self performSelectorOnMainThread:@selector(loadoverlayImageonCamera:) withObject:temp waitUntilDone:NO ];
    
}

-(void) loadoverlayImageonCamera:(UIImage*) temp
{

    [self ShowCamera];
   
    //self.overlayImageView.image = imgUserPhoto;
    
    //[self.UserSelImage setImage:imgUserPhoto];
    
	self.overlayImageView.frame = CGRectMake(overlayImageView.frame.origin.x, overlayImageView.frame.origin.y, imgUserPhoto.size.width, imgUserPhoto.size.height);
	
    self.backgroundImageView.image = [UIImage imageNamed:@"CameraBackground"];
   
    _motionManager=nil;
    
    /*
    CMMotionManager *manager = [[CMMotionManager alloc] init];
    self.motionManager = manager;
    [manager release]; manager = nil;
    */
    
    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    pinchRecognizer.delegate = self;
    //[self.view addGestureRecognizer:pinchRecognizer];
    [self.mainView addGestureRecognizer:pinchRecognizer];
	
    [pinchRecognizer release]; pinchRecognizer = nil;
    
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    panRecognizer.delegate = self;
    [panRecognizer setMaximumNumberOfTouches:1];
    //[self.view addGestureRecognizer:panRecognizer];
    [self.mainView addGestureRecognizer:panRecognizer];
	
    [panRecognizer release]; panRecognizer = nil;
    
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapRecognizer.delegate = self;
    [tapRecognizer setCancelsTouchesInView:NO];
    //[self.view addGestureRecognizer:tapRecognizer];
    [self.mainView addGestureRecognizer:tapRecognizer];
	
    [tapRecognizer release]; tapRecognizer = nil;
    
    
    UIRotationGestureRecognizer *rotationRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotation:)];
    rotationRecognizer.delegate = self;
    //[self.view addGestureRecognizer:rotationRecognizer];
    [self.mainView addGestureRecognizer:rotationRecognizer];
     
    [rotationRecognizer release]; rotationRecognizer = nil;

}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer  {
    
    return YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    
    [super viewWillAppear:animated];
    /*
    if (blnmovetoCommentScreen) {
        return;
    }*/
    //self.navigationItem.hidesBackButton = YES;
   
    if (blnScreenLoaded) {
        photoShotButton.enabled=YES;
        
        [self ShowCamera];
    }
        
}
-(void) ShowCamera
{
    [self cameraOn];
    //Start a timer to fetch motion data periodically
    //[NSTimer scheduledTimerWithTimeInterval:1/30.0
    //                                target:self selector:@selector(timerFired:)
    //                               userInfo:nil repeats:YES];
    
    
    overlayPositionX = 0;
    overlayPositionY = 0;
    
    
    overlayScale = 1.0f;
    overlayAngle = 0.0f;
    
    //Disable mutitouch support
    self.view.multipleTouchEnabled = NO;	
    
    //Set the views visible
	self.findTaylorImageView.text = @"";
    self.findTaylorImageView.editable = NO;
}
- (void)viewDidAppear:(BOOL)animated
{
    /*
    if (blnmovetoCommentScreen) {
        [self.navigationController popViewControllerAnimated:YES];
        [super viewDidAppear:animated];
        self.viewControllerCountAtDissappear = [[self.navigationController viewControllers] count];    
        if (self.backButtonTargetAdded) {
            [self.backButton removeTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
            self.backButtonTargetAdded = NO;
            //NSLog(@"Removed d %@",self.delegate);
        }
        
        return;
    }  
    
    [self unHideBackButton];*/
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelay:3.5];
    [UIView setAnimationDuration:0.5];
    [tutorialImage setAlpha:0.0];
    [UIView commitAnimations];


    [super viewDidAppear:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self cameraOff];
    //[self hideBackButton];
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated  {
    [super viewDidDisappear:animated];
}

- (void)viewDidUnload
{
    
    
    //for (UIView* child in self.view.subviews) {
    //    [child removeFromSuperview];
    //}
    
    UserSelImage = nil;
    self.mainView = nil;
    self.overlayView = nil;
    self.overlayImageView = nil;
    self.backgroundImageView = nil;
    self.findTaylorImageView = nil;
    self.overlayimageUrl=nil;
    
    [self setOverlayScrollView:nil];
    [self setFramesScrollView:nil];
    [self setFrameView:nil];
    [self setFrameImageView:nil];
    [self setOverlayButton:nil];
    [self setFrameButton:nil];

    selectedBorderColor = nil;
    normalBorderColor = nil;
    frameImageView = nil;
    framesAndOverlays = nil;
    
    //[frame removeFromSuperview];
    //[overlay removeFromSuperview];
    //frame = nil;
    //overlay = nil;
    
    [self setPreviewImageView:nil];
    [self setDoneBtn:nil];
    [self setDoneBtn:nil];
    [self setRetakeBtn:nil];
    [self setTakePhotoBtn:nil];
    [self setScrollViewContainer:nil];
    [self setPositionLabel:nil];
    [self setTutorialImage:nil];
    [super viewDidUnload];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark -
#pragma mark Methods for OpenGL & UIKView Screenshots based on Q&A 1702, Q&A 1703, Q&A 1704, & Q&A 1714

- (void)renderView:(UIView*)view inContext:(CGContextRef)context
{	
    
    CGContextSaveGState(context);

	
	// Center the context around the window's anchor point and adjust based on the ratio difference applied.
    //CGContextTranslateCTM(context, [view center].x+ADJUST_RATIO/2, [view center].y);
    CGContextTranslateCTM(context, [view center].x, [view center].y);
    
	
	// Apply the window's transform about the anchor point.
    CGContextConcatCTM(context, [view transform]);
	
	
    // Offset by the portion of the bounds left of and above the anchor point.
    CGContextTranslateCTM(context,
                          -[view bounds].size.width * [[view layer] anchorPoint].x,
                          -[view bounds].size.height * [[view layer] anchorPoint].y);
    
	
	// Render the layer hierarchy to the current context.
    [[view layer] renderInContext:context];
	
    
	// Restore the context
    CGContextRestoreGState(context);
}




#pragma mark -
#pragma mark IBAction Methods for Camera

- (void)cameraOn
{
    self.UserSelImage.hidden=NO;
	[self setupCaptureSession];    
    
    self.backgroundImageView.image = nil;
	
	
	// This creates the camera feed view
	self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.capturedSession];
    self.previewLayer.frame = self.backgroundImageView.bounds;
    //self.previewLayer.frame = self.mainView.bounds;
    // Set the previewLayer to portrait.(allow to keep previous app orientation without calling the delegate)
    
    if (self.previewLayer.orientationSupported)
    {
        self.previewLayer.orientation = AVCaptureVideoOrientationPortrait;
    }
    
    //self.previewLayer.videoGravity = AVLayerVideoGravityResize;
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	[self.backgroundImageView.layer addSublayer:self.previewLayer];				
}



- (void)cameraOff
{
	self.backgroundImageView.image = [UIImage imageNamed:@"CameraBackground"];
	[self.capturedSession stopRunning];	
    [self.previewLayer removeFromSuperlayer];
    
}


- (IBAction)takePhoto
{    
  
    takePhotoBtn.enabled = NO;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.mainView animated:YES];
    hud.labelText = @"Creating Photo Card!";
    [self captureStillImage];
    blnScreenLoaded=YES;
    //In this module the camera is just stoped when removing the view, so is faster to come back to it if the photo has to be retaken
    //Add the code for the app behaviour once the photo is taken.
}

- (IBAction)pressDone:(id)sender  {
    [self composeImage];
}


//Adapted from apple Technical Q&A QA1702
// Create and configure a capture session and start it running
- (void)setupCaptureSession 
{	
    NSError *error = nil;
	
    // Create the session
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
	
    session.sessionPreset = AVCaptureSessionPresetPhoto;
	
	// Find a suitable AVCaptureDevice
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	
	
	// Support auto-focus locked mode
	if ([device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) 
	{
		NSError *error = nil;
		if ([device lockForConfiguration:&error]) 
        {
			device.focusMode = AVCaptureFocusModeAutoFocus;
			[device unlockForConfiguration];
		}
		else 
		{
            NSLog(@"No autofocus");
            //Display an alert message
            //Un-comment to enable
            if ([self respondsToSelector:@selector(autofocusNotSupported)]) 
            {
                [self autofocusNotSupported];
            }
		}
	}
    else
        NSLog(@"No Autofocus");
	
	
    // Create a device input with the device and add it to the session.
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device 
                                                                        error:&error];
    if (!input) 
	{
        // Handling the error appropriately.
    }
    else  {
        [session addInput:input];
    }
	
	
    // Create a AVCaputreStillImageOutput instance and add it to the session
	AVCaptureStillImageOutput *imageOutput = [[AVCaptureStillImageOutput alloc] init];
	NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
	[imageOutput setOutputSettings:outputSettings];
	
	
	[session addOutput:imageOutput];
	
	
	// Start the session running to start the flow of data
    [session startRunning];
	
	
    // Assign session we've created here to our AVCaptureSession ivar.
	self.capturedStillImageOutput  = imageOutput;
	self.capturedSession  = session;
    
    
    ///ADDED AD
    [imageOutput release];
    [session release];
    [outputSettings release];
}



#pragma mark -
#pragma mark Screenshot Methods Using AVFoundation and UIKit as shown in Technical Q&A 1714

- (void) captureStillImage
{
    //NSLog(@"The overlay origins before doing anything: %f %f", self.overlayView.frame.origin.x, self.overlayView.frame.origin.y);
    
    AVCaptureConnection *videoConnection = [self connectionWithMediaType:AVMediaTypeVideo fromConnections:[self.capturedStillImageOutput connections]];
	
    
    //Currently, since the VIEW is not rotating for REAL it just uses portrait
    if(UIInterfaceOrientationPortrait == [[UIApplication sharedApplication] statusBarOrientation])
        [videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    if(UIInterfaceOrientationPortraitUpsideDown == [[UIApplication sharedApplication] statusBarOrientation])
        [videoConnection setVideoOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
    if(UIInterfaceOrientationLandscapeLeft == [[UIApplication sharedApplication] statusBarOrientation])
        [videoConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
    if(UIInterfaceOrientationLandscapeRight == [[UIApplication sharedApplication] statusBarOrientation])
        [videoConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
 

    [self.capturedStillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection
															   completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) 
     {
         if (imageDataSampleBuffer != NULL) 
         {
             
             [self.capturedSession stopRunning];
             
             // Grab the image data as a JPEG still image from the AVCaptureStillImageOutput and create a UIImage image with it.
             NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
             UIImage *image = [[UIImage alloc] initWithData:imageData];
             
             // Create a graphics context with the target size
             CGSize imageSize = [[UIScreen mainScreen] bounds].size;
             //CGSize imageSize = CGSizeMake(320,320);

             //manually adjust the ratio of the video and crop the right side
             
             //imageSize.width+=ADJUST_RATIO;
             
             //imageSize.height-= (20+self.mainView.frame.origin.y);
             imageSize.height = roundf((imageSize.width/image.size.width)*image.size.height);
             
             //NSLog(@"cg width and cg height %f %f", imageSize.width, imageSize.height);
             //NSLog(@"width and height %f %f", image.size.width, image.size.height);
             /*
             imageSize = CGSizeMake(320, 320);
             CGSize newSize = CGSizeMake(640, 640);
             
             CGSize inputSize = image.size;
             CGFloat scaleFactor = newSize.height / inputSize.height;
             CGFloat width = roundf(inputSize.width *scaleFactor);
             
             if ( width > newSize.width ) {
                 scaleFactor = newSize.width / inputSize.width;
                 newSize.height = roundf( inputSize.height * scaleFactor );
             } else {
                 newSize.width = width;
             }
             
             UIGraphicsBeginImageContext( newSize );
             CGContextRef context = UIGraphicsGetCurrentContext();
             
             CGContextDrawImage( context, CGRectMake( 0, 0, newSize.width, newSize.height ), [image CGImage] );
             UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
             
             UIGraphicsEndImageContext();
             
             CGRect cropRect = CGRectMake(0,0,640,640);
             CGImageRef imageRef = CGImageCreateWithImageInRect( outputImage.CGImage, cropRect );
             outputImage = [[[UIImage alloc] initWithCGImage: imageRef] autorelease];
             CGImageRelease( imageRef );
             previewImageView.image = outputImage;
             */
             
             
             UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
             
             CGContextRef context = UIGraphicsGetCurrentContext();
             
             UIGraphicsPushContext(context);
             
             [image drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
             
             UIGraphicsPopContext();
             

            UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();

             //114 comes from 47*2 + 40, which is the y origin of the camera view for retina + height of status bar
             CGImageRef imageRef = CGImageCreateWithImageInRect([screenshot CGImage], CGRectMake(0,108,640,640));
             //CGImageRef imageRef = CGImageCreateWithImageInRect([screenshot CGImage], CGRectMake(0,0,640,640));
             // or use the UIImage wherever you like
             //self.screenshotImage = [UIImage imageWithCGImage:imageRef];
             previewImageView.image =[UIImage imageWithCGImage:imageRef];
             CGImageRelease(imageRef);
             //self.screenshotImage = screenshot;
             
             
             //[self openPreview];
             // Close image context
             UIGraphicsEndImageContext();
             
             
             [image release];
             
             [MBProgressHUD hideHUDForView:self.mainView animated:YES];
             [self goIntoPreviewMode];
         }
         else if (error) 
         {
             NSLog(@"Save image fail.");
             if ([self respondsToSelector:@selector(captureStillImageFailedWithError:)]) 
             {
                 [self captureStillImageFailedWithError:error];
             }
         }
     }];
	
}

-(void)composeImage  {

    CGSize imageSize = [[UIScreen mainScreen] bounds].size;
    //CGSize imageSize = CGSizeMake(320,320);
    
    //manually adjust the ratio of the video and crop the right side
    
   // imageSize.width+=ADJUST_RATIO;
    //imageSize.height-=ADJUST_RATIO/2;
    
    
    //UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    UIGraphicsBeginImageContextWithOptions(previewImageView.bounds.size, NO, 0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIGraphicsPushContext(context);
    
    //[previewImageView.image drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
    [previewImageView.image drawInRect:CGRectMake(0, 0, previewImageView.bounds.size.width, previewImageView.bounds.size.height)];
    UIGraphicsPopContext();
    
    
    // Render the camera overlay view into the graphic context.
     
    [self renderView:self.overlayView inContext:context];
    [self renderView:frameView inContext:context];
     
     
    // Retrieve the screenshot image containing both the camera content and the overlay view
    
    UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
    
    
    //CGImageRef imageRef = CGImageCreateWithImageInRect([screenshot CGImage], CGRectMake(ADJUST_RATIO,94,640,640));
    // or use the UIImage wherever you like
    //self.screenshotImage = [UIImage imageWithCGImage:imageRef];
    
    //CGImageRelease(imageRef);
    self.screenshotImage = screenshot;
    
    
    //[self openPreview];
    // Close image context
    UIGraphicsEndImageContext();

}

-(void) goIntoPreviewMode  {
    // move the preview from 47 to 70 y coord
    
    // Setup the animation
    CGAffineTransform bottomBtnMove = CGAffineTransformMakeTranslation(-320, 0);
    CGAffineTransform scrollViewMove = CGAffineTransformMakeTranslation(0, 200);
    CGAffineTransform screenshotMove = CGAffineTransformMakeTranslation(0, 23);
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    takePhotoBtn.transform = bottomBtnMove;
    retakeBtn.transform = bottomBtnMove;
    overlayButton.transform = bottomBtnMove;
    frameButton.transform = bottomBtnMove;
    scrollViewContainer.transform = scrollViewMove;
    doneBtn.hidden = NO;
    positionLabel.alpha = 1.0;

    //previewImageView.transform = screenshotMove;
    mainView.transform = screenshotMove;
    [UIView commitAnimations];
    backgroundImageView.hidden = YES;
}

-(IBAction)returnToCamera:(id)sender  {
    // Setup the animation


    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    takePhotoBtn.transform = CGAffineTransformIdentity;
    retakeBtn.transform = CGAffineTransformIdentity;
    overlayButton.transform = CGAffineTransformIdentity;
    frameButton.transform = CGAffineTransformIdentity;
    scrollViewContainer.transform = CGAffineTransformIdentity;
    doneBtn.hidden = YES;
    previewImageView.transform = CGAffineTransformIdentity;
    mainView.transform = CGAffineTransformIdentity;
    previewImageView.image = nil;
    positionLabel.alpha = 0.0;
    [UIView commitAnimations];
    backgroundImageView.hidden = NO;
    [self.capturedSession startRunning];
    takePhotoBtn.enabled = YES;

}

- (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections
{
	for ( AVCaptureConnection *connection in connections ) 
	{
		for ( AVCaptureInputPort *port in [connection inputPorts] ) 
		{
			if ( [[port mediaType] isEqual:mediaType] ) 
			{
				return [[connection retain] autorelease];
			}
		}
	}
	return nil;
}




#pragma mark -
#pragma mark Error Handling Methods

- (void) autofocusNotSupported
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Autofocus Not Supported."
                                                        message:@"Camera will run without autofocus."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];        
}



- (void) captureStillImageFailedWithError:(NSError *)error
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"ERROR: Screenshot Capture."
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
}



- (void) cannotWriteToAssetLibrary
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"ERROR: Photo Copy."
                                                        message:@"Cannot copy to the image library."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];        
}




#pragma mark Touch handling

- (void)handlePinch: (UIPinchGestureRecognizer *)gesture {
	
    if([gesture state] == UIGestureRecognizerStateBegan)
        sfPreviousScale = 1.0f;
    

    overlayScale += ((float) gesture.scale - sfPreviousScale);
    sfPreviousScale =(float) gesture.scale;
    if (overlayScale < 0.5f)
        overlayScale = 0.5f;
    else if (overlayScale > 2.0f)
        overlayScale = 2.0f;
        
        
    CGAffineTransform transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(overlayPositionX, overlayPositionY), overlayAngle);

    self.overlayView.transform = CGAffineTransformScale(transform, overlayScale, overlayScale);
    //NSLog(@"taylorScale:%f ", taylorScale);
    
}

- (void)handlePan: (UIPanGestureRecognizer *)gesture {
    

    CGPoint newLocation = [gesture translationInView:self.mainView];
    float moveX = (float) newLocation.x;
    float moveY = (float) newLocation.y;
    //NSLog(@"Before overlayPosition X, Y: %f, %f", overlayPositionX, overlayPositionY);
    //NSLog(@"Frame of overlay: %f, %f", overlayView.frame.origin.x, overlayView.frame.origin.y);
    if([gesture state] == UIGestureRecognizerStateBegan || [gesture state] == UIGestureRecognizerStateChanged)
    {
        
        moveX = (float) newLocation.x + overlayPositionX;
        moveY = (float) newLocation.y + overlayPositionY;
        
        if(moveX > 140)  {
            moveX = 140;
        }
        
        if(moveX < -140)  {
            moveX = -140;
        }
        
        if(moveY > 260)  {
            moveY = 260;
        }
        if(moveY < -190)  {
            moveY = -190;
        }
        //CGAffineTransform transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation((float) newLocation.x + overlayPositionX,
        //                                                                                           (float) newLocation.y + overlayPositionY), overlayAngle);
        CGAffineTransform transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(moveX, moveY), overlayAngle);
        self.overlayView.transform = CGAffineTransformScale(transform, overlayScale, overlayScale);
    }
    else if([gesture state] == UIGestureRecognizerStateEnded)
    {
        //overlayPositionY += (float) newLocation.y;
        //overlayPositionX += (float) newLocation.x;       
        overlayPositionX += moveX;       
        overlayPositionY += moveY;
    }
    //NSLog(@"overlayPosition X, Y: %f, %f", overlayPositionX, overlayPositionY);
}

- (void)handleTap:(UITapGestureRecognizer *)sender { 
    if (sender.state == UIGestureRecognizerStateEnded)
    {     
        // Find a suitable AVCaptureDevice
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        
        // Support auto-focus locked mode
        if ([device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) 
        {
            NSError *error = nil;
            if ([device lockForConfiguration:&error]) 
            {
                device.focusMode = AVCaptureFocusModeAutoFocus;
                [device unlockForConfiguration];
            }
        }
    }
}

- (void)handleRotation: (UIRotationGestureRecognizer *)gesture
{
    static float previousAngle = 0;
    if([gesture state] == UIGestureRecognizerStateBegan)
        previousAngle = overlayAngle;
    
    overlayAngle = gesture.rotation+previousAngle;
    CGAffineTransform transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(overlayPositionX, overlayPositionY), overlayScale, overlayScale);
    self.overlayView.transform = CGAffineTransformRotate(transform, overlayAngle);
    
}




-(NSString *) formatDateString:(NSString *)dateString
{
    NSString *tempDateString = [NSString stringWithString:dateString];
    
    if(tempDateString)
    {
        tempDateString = [tempDateString stringByReplacingOccurrencesOfString:@"T" withString:@" "];
        tempDateString = [tempDateString stringByReplacingOccurrencesOfString:@"+" withString:@" +"];
        
        NSRange range = [tempDateString rangeOfString:@":" options:NSBackwardsSearch];
        if (range.length > 0)
        {
            tempDateString = [tempDateString stringByReplacingCharactersInRange:range withString:@""];
            //tempDateString = [tempDateString stringByReplacingOccurrencesOfString:@":" withString:@"" options:0 range:range];
        }
    }
    return tempDateString;
}


#pragma mark - Manage popUpWindow

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    //No rotation is supported
    //It's done this way so the camera can work easily (but the interface must rotate using hardcode)
    return NO;
}

//iOS 6 specific code:
- (NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL) shouldAutorotate  {
    return NO;
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    //Since rotation is not supported, this is never called for real.
    //I leave the code so there is a starting point in case of enabling the autorotation
    //Adjust the Close button position depending on the orientation, to be always on the top right corner
    if(UIInterfaceOrientationIsLandscape(interfaceOrientation)){ //Landscape mode
        
        CGRect  bounds = CGRectMake(self.backgroundImageView.bounds.origin.x,
                                     self.backgroundImageView.bounds.origin.y,
                                     self.backgroundImageView.bounds.size.height+10,
                                     self.backgroundImageView.bounds.size.width);
        
        self.previewLayer.bounds = bounds;
        
        self.previewLayer.position=CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));

        
        
    }else{                                                      //Portrait mode
        CGRect  bounds = CGRectMake(self.backgroundImageView.bounds.origin.x,
                                    self.backgroundImageView.bounds.origin.y,
                                    self.backgroundImageView.bounds.size.height+10,
                                    self.backgroundImageView.bounds.size.width);
        
        self.previewLayer.bounds = bounds;
        
        self.previewLayer.position=CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
        
    }
    
    //Rotate the camera
    if(UIInterfaceOrientationLandscapeLeft == interfaceOrientation){
        self.previewLayer.orientation = AVCaptureVideoOrientationLandscapeLeft;
    }else if(UIInterfaceOrientationLandscapeRight== interfaceOrientation){
        self.previewLayer.orientation = AVCaptureVideoOrientationLandscapeRight;
    }else if(UIInterfaceOrientationPortrait == interfaceOrientation){
        self.previewLayer.orientation = AVCaptureVideoOrientationPortrait;
    }else if(UIInterfaceOrientationPortraitUpsideDown == interfaceOrientation){
        self.previewLayer.orientation = AVCaptureVideoOrientationPortraitUpsideDown;
    }
 
    [super willRotateToInterfaceOrientation:interfaceOrientation duration:duration];
    
}



// This method is called by NSNotificationCenter when the device is rotated.
-(void) receivedRotate: (NSNotification*) notification
{
    //NSLog(@"receivedRotate");
    UIDeviceOrientation interfaceOrientation = [[UIDevice currentDevice] orientation];
    
    if(interfaceOrientation != UIDeviceOrientationUnknown) {
        
            //This prevent a double rotation (from portrait to upsidedown for example)
            if((UIInterfaceOrientationIsLandscape(interfaceOrientation) && UIInterfaceOrientationIsLandscape(currentOrientation)) 
               || (UIInterfaceOrientationIsPortrait(interfaceOrientation) && UIInterfaceOrientationIsPortrait(currentOrientation))) {
            //if(interfaceOrientation == currentOrientation) {
                NSLog(@"Do not rotate to current orientation: %i", interfaceOrientation);
            } else
            {
                //for every step of the rotation, the overlay must be rotated 90degrees in one or the other direction
                if(interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
                
                
                if(currentOrientation == UIInterfaceOrientationPortrait)
                    overlayAngle += 3.1415; //note that this 180degrees rotation will never happen with the if statement. I leave it just in case of future updates
                if(currentOrientation == UIInterfaceOrientationLandscapeLeft)
                    overlayAngle -= 3.1415/2;
                if(currentOrientation == UIInterfaceOrientationLandscapeRight)
                    overlayAngle += 3.1415/2;
                
                
            } else if(interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
                
                
                if(currentOrientation == UIInterfaceOrientationPortrait)
                    overlayAngle -= 3.1415/2;
                if(currentOrientation == UIInterfaceOrientationPortraitUpsideDown)
                    overlayAngle += 3.1415/2;
                if(currentOrientation == UIInterfaceOrientationLandscapeRight)
                    overlayAngle += 3.1415;
            } else if(interfaceOrientation == UIInterfaceOrientationLandscapeRight){
                
                
                if(currentOrientation == UIInterfaceOrientationPortrait)
                    overlayAngle += 3.1415/2;
                if(currentOrientation == UIInterfaceOrientationPortraitUpsideDown)
                    overlayAngle -= 3.1415/2;
                if(currentOrientation == UIInterfaceOrientationLandscapeLeft)
                    overlayAngle += 3.1415;
            } else if(interfaceOrientation == UIInterfaceOrientationPortrait) {
                
                
                if(currentOrientation == UIInterfaceOrientationPortrait)
                    overlayAngle += 3.1415;
                if(currentOrientation == UIInterfaceOrientationLandscapeLeft)
                    overlayAngle += 3.1415/2;
                if(currentOrientation == UIInterfaceOrientationLandscapeRight)
                    overlayAngle -= 3.1415/2;
                
                
            }
            
            //Transform the overlay, it's important to keep also the position and scale, so eerything is applied
            CGAffineTransform transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(overlayPositionX, overlayPositionY), overlayScale, overlayScale);
            // Setup the animation
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:0.2];
            [UIView setAnimationCurve:overlayAngle*180/M_PI];
            [UIView setAnimationBeginsFromCurrentState:YES];
            self.overlayView.transform = CGAffineTransformRotate(transform, overlayAngle);
            [UIView commitAnimations];
            //save the last known orientation
            currentOrientation = interfaceOrientation;
            //rotate the interface
            [self RotateInterfaceTo:currentOrientation];
        }
            
            
            
    } else {
        NSLog(@"Unknown device orientation");
    }
}

- (void) rotateThumbswithAngle: (CGFloat)angle  {
    NSArray *subviews = [overlayScrollView subviews];
    NSArray *subviews2 = [framesScrollView subviews];
    
    CGAffineTransform transform1 = CGAffineTransformMakeScale(0.5, 0.5);
    CGAffineTransform transform2 = CGAffineTransformMakeRotation(angle);
    CGAffineTransform transform3 = CGAffineTransformMakeScale(2, 2);
    CGAffineTransform allTransforms = transform2;
    //CGAffineTransform allTransforms = CGAffineTransformConcat(transform1, CGAffineTransformConcat(transform2, transform3));
    

    
    
    // Setup the animation
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.2];
    [UIView setAnimationCurve:angle*180/M_PI];
    [UIView setAnimationBeginsFromCurrentState:YES];

    
    for (UIView *subview in subviews)  {
        if([subview isKindOfClass:[UIImageView class]]) {
            //NSLog(@"an iamge!");
            subview.transform = allTransforms;
            
        }
    }
    

    for (UIView *subview in subviews2)  {
        if([subview isKindOfClass:[UIImageView class]]) {
            //NSLog(@"an image!");
            
            subview.transform = allTransforms;
            
        }
    }
    [UIView commitAnimations];

}

-(void) RotateInterfaceTo:(UIInterfaceOrientation) rotation
{
    //This method is for MANUALLY rotate the interface.
    //The code can be triky since the rotations are done from the center of each element. Please look carefully to the values for the translation
    
    //for every possible orientation
    if(rotation == UIInterfaceOrientationLandscapeLeft)
    {
        /*
        //adjust the position and rotation of the button
        photoShotButton.frame = CGRectMake(230, 240, 101, 47);
        //photoShotButton.transform = CGAffineTransformMakeRotation( ( 270 * M_PI ) / 180 );
        
        
        //and the header
        headerView.frame = CGRectMake(-(self.view.frame.size.height-HEADER_OFFSET)/2,(self.view.frame.size.height-HEADER_OFFSET)/2,self.view.frame.size.height,HEADER_OFFSET);
        headerView.transform = CGAffineTransformMakeRotation( ( 270 * M_PI ) / 180 );
        */
        
        [self rotateThumbswithAngle:( 270 * M_PI) / 180];
        
    }
    if(rotation == UIInterfaceOrientationLandscapeRight)
    {
        /*
        //Note that here the angle of rotation changes (different orientations = different angles)
        photoShotButton.frame = CGRectMake(0, 240, 101, 47);
        //photoShotButton.transform = CGAffineTransformMakeRotation( ( 90 * M_PI ) / 180 );
        
        headerView.frame = CGRectMake(70,(self.view.frame.size.height-HEADER_OFFSET)/2,self.view.frame.size.height,HEADER_OFFSET);
        headerView.transform = CGAffineTransformMakeRotation( ( 90 * M_PI ) / 180 );
         */
        
        [self rotateThumbswithAngle:( 90 * M_PI ) / 180];
    }
    if(rotation == UIInterfaceOrientationPortrait)
    {
        /*
        photoShotButton.frame = CGRectMake(110, 429, 101, 47);
        //photoShotButton.transform = CGAffineTransformMakeRotation( ( 0 * M_PI ) / 180 );
        
        headerView.frame = CGRectMake((self.view.frame.size.width-HEADER_OFFSET)/2,-(self.view.frame.size.width-HEADER_OFFSET)/2,HEADER_OFFSET,self.view.frame.size.width);
        headerView.transform = CGAffineTransformMakeRotation( ( 0 * M_PI ) / 180 );
         */
        [self rotateThumbswithAngle:( 0 * M_PI) / 180];
        
    }
    if(rotation == UIInterfaceOrientationPortraitUpsideDown)
    {
        /*
        photoShotButton.frame = CGRectMake(110, 51, 101, 47);
        //photoShotButton.transform = CGAffineTransformMakeRotation( ( 180 * M_PI ) / 180 );
        
        headerView.frame = CGRectMake((self.view.frame.size.width-HEADER_OFFSET)/2,self.view.frame.size.width-HEADER_OFFSET/2,HEADER_OFFSET,self.view.frame.size.width);
        headerView.transform = CGAffineTransformMakeRotation( ( 180 * M_PI ) / 180 );
        */
        
        [self rotateThumbswithAngle:( 180 * M_PI) / 180];
    }
}




@end
