//
//  ALContactCell.m
//  ChatApp
//
//  Copyright (c) 2015 AppLozic. All rights reserved.
//

#import "ALContactCell.h"

@implementation ALContactCell

- (void)awakeFromNib {
    [[self mUserNameLabel] setTextAlignment:NSTextAlignmentNatural];
    [[self mMessageLabel] setTextAlignment:NSTextAlignmentNatural];
    [[self imageNameLabel] setTextAlignment:NSTextAlignmentNatural];
    
    self.mUserNameLabel.textColor = [UIColor blackColor];
    self.mMessageLabel.textColor = [UIColor blackColor];
    self.mTimeLabel.textColor = [UIColor blackColor];
  
    
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
  
    [super setSelected:selected animated:animated];

}

@end
