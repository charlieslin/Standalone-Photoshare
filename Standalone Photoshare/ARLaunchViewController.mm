//
//  ARLaunchViewController.m
//  PhotoShareTest
//
//  Created by Charlie Lin on 9/26/12.
//  Copyright (c) 2012 Hidden Creative Ltd. All rights reserved.
//

#import "ARLaunchViewController.h"

#define MAX_DISTANCE_IN_METERS 1600
#define TIMEOUT 20
#define MAX_ATTEMPTS 30
#define MINIMUM_ACCURACY 65.0
#define MEDIUM_ACCURACY 30.0
#define BEST_ACCURACY 10.0

@interface ARLaunchViewController ()

@end

@implementation ARLaunchViewController


@synthesize startGeo;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self animateSpark];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    

}

- (void)viewDidUnload
{


    [self setStartGeo:nil];
    [super viewDidUnload];
}




-(IBAction)startPhotoCard:(id)sender  {
    NSLog(@"start photo button pressed");
    
    scrVw = [[ScreenShotViewController alloc] init];

    scrVw.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    [scrVw performSelectorOnMainThread:@selector(loadoverlayImageonCamera:) withObject:nil waitUntilDone:NO ];
    
    [self.navigationController pushViewController:scrVw animated:YES];
    [scrVw release];
    
    
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    //The rotation is not PERMITED, its done in the code of each view.
    //It's done this way to prevent the camera to work irregularly when a rotation ocurrs (the video ayer cannot be resized easily and the capture method works in portrait)
    return NO;//(toInterfaceOrientation == UIInterfaceOrientationPortrait);
}



-(void)animateSpark  {
    
    CAAnimationGroup *theGroup = [CAAnimationGroup animation];
    theGroup.duration = 3.0;
    theGroup.repeatCount = 1;
    theGroup.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    theGroup.fillMode = kCAFillModeForwards;
    theGroup.removedOnCompletion = NO;
    
    
    UIImage *spark = [UIImage imageNamed:@"sparkle.png"];
    UIImageView *sparkView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,50,50)];
    sparkView.image = spark;
    [self.view addSubview:sparkView];
    [sparkView release];
    
    // animation code
    CAKeyframeAnimation* circularAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    //CGMutablePathRef path = CGPathCreateMutable();
    //CGRect pathRect = CGRectMake(0, 0, 200, 200); // define circle bounds with rectangle
    
    //CGPathAddEllipseInRect(path, NULL, pathRect);
    
    circularAnimation.path = CGPathCreateWithRect(startGeo.frame, nil);
    //CGPathRelease(path);
    circularAnimation.duration = 1.5;
    circularAnimation.repeatDuration = 0;
    circularAnimation.repeatCount = 1;
    circularAnimation.calculationMode = kCAAnimationPaced;
    circularAnimation.removedOnCompletion = NO;
    circularAnimation.fillMode = kCAFillModeForwards;
    //[emitter addAnimation:circularAnimation forKey:@"circularAnimation"];
    //[sparkView.layer addAnimation:circularAnimation forKey:@"circularAnimation"];
    
    CABasicAnimation * fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
    //CGMutablePathRef path = CGPathCreateMutable();
    //CGRect pathRect = CGRectMake(0, 0, 200, 200); // define circle bounds with rectangle
    
    //CGPathAddEllipseInRect(path, NULL, pathRect);
    fadeOut.fromValue=[NSNumber numberWithFloat:1.0];
    fadeOut.toValue=[NSNumber numberWithFloat:0.0];
    fadeOut.beginTime = 1.5;
    fadeOut.duration = 0.25;
    fadeOut.fillMode = kCAFillModeForwards;
    fadeOut.removedOnCompletion = NO;
    
    theGroup.animations = [NSArray arrayWithObjects:circularAnimation, fadeOut, nil];
    [sparkView.layer addAnimation:theGroup forKey:@"circleAndFade"];
    
    //[sparkView.layer addAnimation:fadeOut forKey:@"fadeOut"];
}

@end
