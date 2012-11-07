//
//  ARLaunchViewController.h
//  PhotoShareTest
//
//  Created by Charlie Lin on 9/26/12.
//  Copyright (c) 2012 Hidden Creative Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ScreenShotViewController.h"

//#import <TTLogger/TTUIViewController.h>

@interface ARLaunchViewController : UIViewController
{
    ScreenShotViewController * scrVw;
    CAEmitterLayer* emitter;

}

@property (retain, nonatomic) IBOutlet UIButton *startGeo;


-(IBAction)startPhotoCard:(id)sender;
-(void) setOverlay:(UIImage *) overlay;

@end
