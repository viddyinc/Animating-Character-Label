//
//  FSFadeInTextView.h
//  AnimatingTextView
//
//  Created by Sean Lee on 2/12/14.
//  Copyright (c) 2014 seanlee. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FSFadeInTextLabel : UIView

@property (strong, nonatomic) NSString *text;
@property (strong, nonatomic) UIFont *font;
@property (strong, nonatomic) UIColor *textColor;
@property (assign, nonatomic) NSTextAlignment textAlignment;

@property (assign, nonatomic) int numberOfFadeInBuckets;
@property (assign, nonatomic) float totalAnimationDuration;

-(void)showText:(BOOL)fade;

// To use inside a reusable cell (collectionview/tableview), call the following method
-(void)prepareForReuse;

@end
