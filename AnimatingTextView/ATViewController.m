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
        self.fadeTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f];
        self.fadeTextLabel.textColor = [UIColor blackColor];
    }
    return self;
}

-(void)prepareForReuse {
    [super prepareForReuse];
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
    
    NSString *textToDisplay = @"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.";
    cell.fadeTextLabel.text = textToDisplay;
    [cell.fadeTextLabel animateTextFade:YES];
    return cell;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
