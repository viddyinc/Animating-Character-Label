//
//  FSFadeInTextView.m
//  AnimatingTextView
//
//  Created by Sean Lee on 2/12/14.
//  Copyright (c) 2014 seanlee. All rights reserved.
//

#import "FSFadeInTextLabel.h"

// can't cache once per character :( ligature and kerning causes same char to look different each time.
#define USE_CHARACTER_CACHE 0

#if USE_CHARACTER_CACHE
static NSCache *characterCache;
#endif

@interface FSFadeInTextLabel ()
@property (strong, nonatomic) UIView *textContainer;
@end

@implementation FSFadeInTextLabel

+(void)initialize {
#if USE_CHARACTER_CACHE
    characterCache = [[NSCache alloc] init];
#endif
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        self.textContainer = [[UIView alloc] initWithFrame:self.bounds];
        [self addSubview:self.textContainer];
        
        self.numberOfFadeInBuckets = 6;
        self.totalAnimationDuration = 1.5f;
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
#if USE_CHARACTER_CACHE
    [characterCache removeAllObjects];
#endif
}

-(void)setTextColor:(UIColor *)textColor {
    _textColor = textColor;
#if USE_CHARACTER_CACHE
    [characterCache removeAllObjects];
#endif
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

-(NSArray *)createCharacterRectsForText:(UITextView *)tv {
#if USE_CHARACTER_CACHE
    UIImage *renderedTextImage = nil;
#endif

    int bucketSize = ceil(tv.text.length*1.0 / self.numberOfFadeInBuckets);
    
    NSMutableArray *buckets = [NSMutableArray arrayWithCapacity:self.numberOfFadeInBuckets];
    for (int x = 0; x < self.numberOfFadeInBuckets; x++) {
        NSMutableArray *bucket = [NSMutableArray arrayWithCapacity:bucketSize];
        [buckets addObject:bucket];
    }
    
    unichar charbuffer[tv.text.length];
    [tv.text getCharacters:charbuffer range:NSMakeRange(0, tv.text.length)];
//    const char *chars = [tv.text UTF8String];

    for (int x = 0; x < tv.text.length; x++) {
        unichar charAtIndex = charbuffer[x];
        if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:charAtIndex]) {
            continue;
        }
        
        UITextPosition *firstPos = [tv positionFromPosition:tv.beginningOfDocument offset:x];
        UITextPosition *nextPos = [tv positionFromPosition:tv.beginningOfDocument offset:x+1];
        
        UITextRange *range = [tv textRangeFromPosition:firstPos toPosition:nextPos];
        CGRect result = [tv firstRectForRange:range];
        
        // for every character, check cache. render character image and cache image/size, and use that next time.
        
#if USE_CHARACTER_CACHE
        NSDictionary *cachedd = [characterCache objectForKey:@(charAtIndex)];
        if (!cachedd) {
            
            if (renderedTextImage == nil) {
                UIGraphicsBeginImageContextWithOptions(tv.bounds.size, NO, 0.0);
                [tv.layer renderInContext:UIGraphicsGetCurrentContext()];
                renderedTextImage = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
            }
            
            CGRect rect = CGRectMake(result.origin.x * renderedTextImage.scale, result.origin.y * renderedTextImage.scale, result.size.width * renderedTextImage.scale, result.size.height * renderedTextImage.scale);
            CGImageRef imageRef = CGImageCreateWithImageInRect([renderedTextImage CGImage], rect);
            UIImage *characterImage = [UIImage imageWithCGImage:imageRef scale:renderedTextImage.scale orientation:renderedTextImage.imageOrientation];
            [characterCache setObject:characterImage forKey:@(charAtIndex)];
        }
        
        NSUInteger r = arc4random_uniform((int)buckets.count);
        [buckets[r] addObject:@[@(charAtIndex),[NSValue valueWithCGRect:result]]];
#else
        NSUInteger r = arc4random_uniform((int)buckets.count);
        [buckets[r] addObject:[NSValue valueWithCGRect:result]];
#endif
    }
    
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
            
            NSArray *animationBuckets = [self createCharacterRectsForText:tv];

            if (weakTextContainer == nil) {
                return ;
            }
            
            // using total animation time, calculate animation duration for animation buckets.
            CGFloat animationDuration = self.totalAnimationDuration/4;
            CGFloat startWindow = self.totalAnimationDuration / (self.numberOfFadeInBuckets*2);
            
#if !USE_CHARACTER_CACHE
            UIGraphicsBeginImageContextWithOptions(tv.bounds.size, NO, 0.0);
            [tv.layer renderInContext:UIGraphicsGetCurrentContext()];
            UIImage *renderedTextImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
#endif
            
            for (int x = 0; x < animationBuckets.count; x++) {
                double delayInSeconds = x*startWindow; // x*0.1
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                    __strong __typeof(&*weakTextContainer)strongTextContainer = weakTextContainer;
                    
                    if (strongTextContainer == nil) {
                        return;
                    }
                    
#if USE_CHARACTER_CACHE
                    for (NSArray *charAndRectValue in animationBuckets[x]) {
                        NSNumber *unicharNumber = charAndRectValue[0];
                        CGRect rect = [charAndRectValue[1] CGRectValue];
                        
                        UIImageView *imageview = [[UIImageView alloc] initWithFrame:rect];
                        imageview.alpha = 0.0f;
                        imageview.image = [characterCache objectForKey:unicharNumber];
                        
                        [strongTextContainer addSubview:imageview];
                        
                        [UIView animateWithDuration:animationDuration animations:^{ // 0.35
                            imageview.alpha = 1.0f;
                        }];
                    }
#else
                    for (NSValue *rectValue in animationBuckets[x]) {
                        CGRect rect = [rectValue CGRectValue];
                        UIView *view = [[UIView alloc] initWithFrame:rect];
                        view.clipsToBounds = YES;
                        view.alpha = 0.0f;
                        
                        UIImageView *imageview = [[UIImageView alloc] initWithImage:renderedTextImage];
                        imageview.frame = CGRectMake(-CGRectGetMinX(rect), -CGRectGetMinY(rect), renderedTextImage.size.width, renderedTextImage.size.height);
                        [view addSubview:imageview];
                        [strongTextContainer addSubview:view];
                        
                        [UIView animateWithDuration:animationDuration animations:^{ // 0.35
                            view.alpha = 1.0f;
                        }];
                    }
#endif
                });
            }
        });
    } else {
        [self.textContainer addSubview:tv];
    }
}

@end
