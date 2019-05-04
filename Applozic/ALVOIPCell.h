//
//  ALVOIPCell.h
//  Applozic
//
//  Created by Abhishek Thapliyal on 2/14/17.
//  Copyright © 2017 applozic Inc. All rights reserved.
//

#import <Applozic/Applozic.h>

@interface ALVOIPCell : ALChatCell

-(instancetype)populateCell:(ALMessage*) alMessage viewSize:(CGSize)viewSize index:(NSIndexPath *)index tableview:(UITableView *)tblView withController:(UIViewController*)controller;

@end
