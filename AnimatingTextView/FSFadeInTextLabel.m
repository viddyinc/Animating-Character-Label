//
//  FSFadeInTextView.m
//  AnimatingTextView
//
//  Created by Sean Lee on 2/12/14.
//  Copyright (c) 2014 seanlee. All rights reserved.
//

#import "FSFadeInTextLabel.h"

static NSCache *characterImageCache;

@interface FSFadeInTextLabel ()
@property (strong, nonatomic) UIView *textContainer;
@property (assign, atomic) BOOL cancelOperation;
@end

@implementation FSFadeInTextLabel

+(void)initialize {
    characterImageCache = [[NSCache alloc] init];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        self.textContainer = [[UIView alloc] initWithFrame:self.bounds];
        [self addSubview:self.textContainer];
        
        self.numberOfFadeInBuckets = 7;
        self.totalAnimationDuration = 2.0f;
    }
    return self;
}

-(void)prepareForReuse {
    [self.textContainer removeFromSuperview];
    self.textContainer = nil;
    
    self.textContainer = [[UIView alloc] initWithFrame:self.bounds];
    [self addSubview:self.textContainer];
    
    self.text = @"";
}

-(void)setFont:(UIFont *)font {
    _font = font;
    [characterImageCache removeAllObjects];
}

-(void)setTextColor:(UIColor *)textColor {
    _textColor = textColor;
    [characterImageCache removeAllObjects];
}

-(void)setTextAlignment:(NSTextAlignment)textAlignment {
    _textAlignment = textAlignment;
}

-(void)setText:(NSString *)text {
    _text = text;
}

-(void)setNumberOfFadeInBuckets:(int)numberOfFadeInBuckets {
    _numberOfFadeInBuckets = numberOfFadeInBuckets;
}

-(void)setTotalAnimationDuration:(float)totalAnimationDuration {
    _totalAnimationDuration = totalAnimationDuration;
}

-(NSDictionary *)createCharacterRectsForText:(UITextView *)tv {
    NSMutableArray *rectOfCharacters = [NSMutableArray arrayWithCapacity:tv.text.length];
    
    UIGraphicsBeginImageContextWithOptions(tv.bounds.size, NO, 0.0);
    [tv.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *renderedTextImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    for (int x = 0; x < tv.text.length; x++) {
        UITextPosition *firstPos = [tv positionFromPosition:tv.beginningOfDocument offset:x];
        UITextPosition *nextPos = [tv positionFromPosition:tv.beginningOfDocument offset:x+1];
        
        UITextRange *range = [tv textRangeFromPosition:firstPos toPosition:nextPos];
        CGRect result = [tv firstRectForRange:range];
        
        [rectOfCharacters addObject:[NSValue valueWithCGRect:result]];
    }
    
    return @{@"rects": rectOfCharacters,
             @"image": renderedTextImage};
}

-(NSArray *)createAnimationBuckets:(NSArray *)rectOfCharacters {
    int bucketSize = ceil(rectOfCharacters.count*1.0 / self.numberOfFadeInBuckets);
    
    NSMutableArray *buckets = [NSMutableArray arrayWithCapacity:self.numberOfFadeInBuckets];
    for (int x = 0; x < self.numberOfFadeInBuckets; x++) {
        NSMutableArray *bucket = [NSMutableArray arrayWithCapacity:bucketSize];
        [buckets addObject:bucket];
    }
    
    [rectOfCharacters enumerateObjectsUsingBlock:^(NSValue *rectValue, NSUInteger idx, BOOL *stop) {
        NSUInteger r = arc4random_uniform((int)buckets.count);
        [buckets[r] addObject:rectValue];
    }];

    return buckets;
}

-(void)showText:(BOOL)fade {
    [self.textContainer.subviews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
        [view removeFromSuperview];
    }];

    NSString *text = self.text;
    UITextView *tv = [[UITextView alloc] initWithFrame:self.bounds];
    tv.font = self.font;
    tv.textColor = self.textColor;
    tv.textAlignment = self.textAlignment;
    tv.backgroundColor = [UIColor clearColor];
    tv.text = text;
    tv.userInteractionEnabled = NO;

    if (fade) {
        __weak UIView *weakTextContainer = self.textContainer;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            if (weakTextContainer == nil) {
                return ;
            }
            
            NSDictionary *rv = [self createCharacterRectsForText:tv];
            NSArray *rectForCharacters = rv[@"rects"];
            UIImage *textimage = rv[@"image"];

            if (weakTextContainer == nil) {
                return ;
            }
            
            NSArray *animationBuckets = [self createAnimationBuckets:rectForCharacters];
            
            if (weakTextContainer == nil) {
                return ;
            }

            // using total animation time, calculate each animation time.
            CGFloat animationDuration = self.totalAnimationDuration/4;
            CGFloat startWindow = self.totalAnimationDuration / (self.numberOfFadeInBuckets*2);
            
            __weak FSFadeInTextLabel *weakSelf = self;
            
            for (int x = 0; x < animationBuckets.count; x++) {
                double delayInSeconds = x*startWindow; // x*0.1
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                    __strong __typeof(&*weakTextContainer)strongTextContainer = weakTextContainer;
                    __strong __typeof(&*weakSelf)strongSelf = weakSelf;
                    
                    if (strongTextContainer == nil || strongSelf == nil) {
                        return ;
                    }
                    
                    for (NSValue *rectValue in animationBuckets[x]) {
                        CGRect rect = [rectValue CGRectValue];
                        UIView *view = [[UIView alloc] initWithFrame:rect];
                        view.clipsToBounds = YES;
                        view.alpha = 0.0f;
                        
                        UIImageView *imageview = [[UIImageView alloc] initWithImage:textimage];
                        imageview.frame = CGRectMake(-CGRectGetMinX(rect), -CGRectGetMinY(rect), textimage.size.width, textimage.size.height);
                        [view addSubview:imageview];
                        [strongTextContainer addSubview:view];
                        
                        [UIView animateWithDuration:animationDuration animations:^{ // 0.35
                            view.alpha = 1.0f;
                        }];
                    }
                });
            }
        });
    } else {
        [self.textContainer addSubview:tv];
    }
}

@end
