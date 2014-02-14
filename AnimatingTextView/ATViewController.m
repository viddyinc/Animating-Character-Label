//
//  ATViewController.m
//  AnimatingTextView
//
//  Created by Sean Lee on 2/12/14.
//  Copyright (c) 2014 seanlee. All rights reserved.
//

#import "ATViewController.h"
#import "FSFadeInTextLabel.h"

@interface FadeLabelTableViewCell : UITableViewCell
@property (strong, nonatomic) FSFadeInTextLabel *fadeTextLabel;
@end

@implementation FadeLabelTableViewCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.fadeTextLabel = [[FSFadeInTextLabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetWidth(self.bounds))];
        [self.contentView addSubview:self.fadeTextLabel];
        self.fadeTextLabel.font = [UIFont fontWithName:@"GillSans-Light" size:20.0f];
        self.fadeTextLabel.textColor = [UIColor blackColor];
    }
    return self;
}

-(void)prepareForReuse {
    [super prepareForReuse];
    [self.fadeTextLabel prepareForReuse];
}

@end

@interface ATViewController ()

@property (strong, nonatomic) FSFadeInTextLabel *fadeTextLabel;

@end

@implementation ATViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.rowHeight = 320;
    [self.tableView registerClass:[FadeLabelTableViewCell class] forCellReuseIdentifier:@"cell"];
    self.view.backgroundColor = [UIColor blackColor];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1000;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    FadeLabelTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    NSString *textToDisplay = @"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor.";
    cell.fadeTextLabel.text = textToDisplay;
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(FadeLabelTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {

    // uncomment lines below to display none-fade in version of the text, for better scroll performance.
//    static double prevCallTime = 0;
//    static double prevCallOffset = 0;
//    
//    //Simple velocity calculation
//    double curCallTime = CACurrentMediaTime();
//    double timeDelta = curCallTime - prevCallTime;
//    double curCallOffset = self.tableView.contentOffset.y;
//    double offsetDelta = curCallOffset - prevCallOffset;
//    double velocity = fabs(offsetDelta / timeDelta);
//    prevCallTime = curCallTime;
//    prevCallOffset = curCallOffset;

//    if (ABS(velocity) > 1000 || velocity == 0) {
//        [cell.fadeTextLabel showText:NO];
//    } else {
        [cell.fadeTextLabel showText:YES];
//    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
