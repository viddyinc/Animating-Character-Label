//
//  FSFadeInTextView.m
//  AnimatingTextView
//
//  Created by Sean Lee on 2/12/14.
//  Copyright (c) 2014 seanlee. All rights reserved.
//

#import "FSFadeInTextLabel.h"

@interface FSFadeInTextLabel ()
@property (strong, nonatomic) UITextView *textview;
@property (strong, nonatomic) UIImage *renderedTextImage;
@property (strong, nonatomic) NSArray *buckets;
@property (strong, nonatomic) NSArray *rectOfCharacters;

@property (assign, nonatomic) BOOL needsRelayout;
@property (assign, nonatomic) BOOL needsToUpdateAnimationBuckets;

@property (strong, nonatomic) UIImageView *imageview;
@end

@implementation FSFadeInTextLabel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        self.textview = [[UITextView alloc] initWithFrame:self.bounds];
        self.textview.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f];
        self.textview.textColor = [UIColor blackColor];
        self.textview.textAlignment = NSTextAlignmentCenter;
        self.textview.backgroundColor = [UIColor clearColor];
        self.textview.userInteractionEnabled = NO;
        
        self.numberOfFadeInBuckets = 10;
        self.totalAnimationDuration = 2.0f;
        self.needsRelayout = YES;
    }
    return self;
}

-(void)setFont:(UIFont *)font {
    self.textview.font = font;
    self.needsRelayout = YES;
}

-(void)setTextColor:(UIColor *)textColor {
    self.textview.textColor = textColor;
    self.needsRelayout = YES;
}

-(void)setTextAlignment:(NSTextAlignment)textAlignment {
    self.textview.textAlignment = textAlignment;
    self.needsRelayout = YES;
}

-(void)setText:(NSString *)text {
    _text = text;
    self.textview.text = text;
    self.needsRelayout = YES;
}

-(void)setNumberOfFadeInBuckets:(int)numberOfFadeInBuckets {
    _numberOfFadeInBuckets = numberOfFadeInBuckets;
    self.needsToUpdateAnimationBuckets = YES;
}

-(void)setTotalAnimationDuration:(float)totalAnimationDuration {
    _totalAnimationDuration = totalAnimationDuration;
}

-(void)setupCharacterViews {
    if (!self.needsRelayout) {
        return;
    }
    
    self.needsRelayout = NO;
    self.needsToUpdateAnimationBuckets = YES;
    
    NSMutableArray *rectOfCharacters = [NSMutableArray arrayWithCapacity:self.text.length];
    
    for (int x = 0; x < self.text.length; x++) {
        UITextPosition *firstPos = [self.textview positionFromPosition:self.textview.beginningOfDocument offset:x];
        UITextPosition *nextPos = [self.textview positionFromPosition:self.textview.beginningOfDocument offset:x+1];
        
        UITextRange *range = [self.textview textRangeFromPosition:firstPos toPosition:nextPos];
        CGRect result = [self.textview firstRectForRange:range];
        
        [rectOfCharacters addObject:[NSValue valueWithCGRect:result]];
    }
    
    self.rectOfCharacters = rectOfCharacters;
    
    UIGraphicsBeginImageContextWithOptions(self.textview.bounds.size, NO, 0.0);
    [self.textview.layer renderInContext:UIGraphicsGetCurrentContext()];
    self.renderedTextImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
 
    [self setupAnimationBuckets];
}

-(void)setupAnimationBuckets {
    if (!self.needsToUpdateAnimationBuckets) {
        return;
    }
    
    [self.subviews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
        [view removeFromSuperview];
    }];
    
    self.needsToUpdateAnimationBuckets = NO;
    
    int bucketSize = ceil(self.rectOfCharacters.count*1.0 / self.numberOfFadeInBuckets);
    
    NSMutableArray *buckets = [NSMutableArray arrayWithCapacity:self.numberOfFadeInBuckets];
    for (int x = 0; x < self.numberOfFadeInBuckets; x++) {
        NSMutableArray *bucket = [NSMutableArray arrayWithCapacity:bucketSize];
        [buckets addObject:bucket];
    }
    
    [self.rectOfCharacters enumerateObjectsUsingBlock:^(NSValue *rectValue, NSUInteger idx, BOOL *stop) {
        CGRect rect = [rectValue CGRectValue];
        UIView *view = [[UIView alloc] initWithFrame:rect];
        view.clipsToBounds = YES;
        view.alpha = 0.0f;

        dispatch_sync(dispatch_get_main_queue(), ^{
            UIImageView *imageview = [[UIImageView alloc] initWithImage:self.renderedTextImage];
            [view addSubview:imageview];
            imageview.frame = CGRectMake(-CGRectGetMinX(rect), -CGRectGetMinY(rect), self.renderedTextImage.size.width, self.renderedTextImage.size.height);
        });

        NSUInteger r = arc4random_uniform((int)buckets.count);
        [buckets[r] addObject:view];
    }];

    self.buckets = buckets;
}

-(void)animateTextFade:(BOOL)fadeIn {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (self.needsRelayout) {
            [self setupCharacterViews];
        } else if (self.needsToUpdateAnimationBuckets) {
            [self setupAnimationBuckets];
        }
        
        // using total animation time, calculate each animation time.
        CGFloat animationDuration = self.totalAnimationDuration/4;
        CGFloat startWindow = self.totalAnimationDuration / (self.numberOfFadeInBuckets*2);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            for (int x = 0; x < self.buckets.count; x++) {
                for (UIView *view in self.buckets[x]) {
                    [self addSubview:view];
                }
            }
            
            for (int x = 0; x < self.buckets.count; x++) {
                double delayInSeconds = x*startWindow; // x*0.1
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [UIView animateWithDuration:animationDuration animations:^{ // 0.35
                        for (UIView *view in self.buckets[x]) {
                            view.alpha = fadeIn ? 1.0f : 0.0f;
                        }
                    }];
                });
            }
        });
        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if (!self.imageview) {
//                self.imageview = [[UIImageView alloc] initWithFrame:self.bounds];
//            }
//            [self addSubview:self.imageview];
//            self.imageview.image = self.renderedTextImage;
//        });
    });
}

@end
