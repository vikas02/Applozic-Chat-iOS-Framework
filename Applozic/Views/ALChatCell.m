//
//  ALChatCell.m
//  ChatApp
//
//  Copyright (c) 2015 AppLozic. All rights reserved.
//

#define DATE_LABEL_SIZE 12

#import "ALChatCell.h"
#import "ALUtilityClass.h"
#import "ALConstant.h"
#import "UIImageView+WebCache.h"
#import "ALContactDBService.h"
#import "ALApplozicSettings.h"
#import "ALMessageService.h"
#import "ALMessageDBService.h"
#import "UIImage+Utility.h"
#import "ALColorUtility.h"
#import "ALMessageInfoViewController.h"
#import "ALChatViewController.h"
#import "ALMessageClientService.h"
#import <Applozic/Applozic-Swift.h>

// Constants
#define MT_INBOX_CONSTANT "4"
#define MT_OUTBOX_CONSTANT "5"

#define USER_PROFILE_PADDING_X 5
#define USER_PROFILE_WIDTH 45
#define USER_PROFILE_HEIGHT 45

#define BUBBLE_PADDING_X 13
#define BUBBLE_PADDING_WIDTH 20
#define BUBBLE_PADDING_X_OUTBOX 27
#define BUBBLE_PADDING_HEIGHT 20
#define BUBBLE_PADDING_HEIGHT_GRP 35

#define MESSAGE_PADDING_X 10
#define MESSAGE_PADDING_Y 10
#define MESSAGE_PADDING_Y_GRP 5
#define MESSAGE_PADDING_WIDTH 20
#define MESSAGE_PADDING_HEIGHT 20

#define CHANNEL_PADDING_X 10
#define CHANNEL_PADDING_Y 2
#define CHANNEL_PADDING_WIDTH 100
#define CHANNEL_PADDING_HEIGHT 20

#define DATE_PADDING_X 20
#define DATE_PADDING_WIDTH 20
#define DATE_HEIGHT 20

#define MSG_STATUS_WIDTH 20
#define MSG_STATUS_HEIGHT 20



@implementation ALChatCell
{
    CGFloat msgFrameHeight;
    UITapGestureRecognizer * tapForCustomView, *tapGestureRecognizerForCell;
    
    
    //Modified by chetu
    NSMutableAttributedString *answerAttributed;
    
    NSString *trimmedMessage;
    
    BOOL readStatus;
    
    BOOL isTrimmed;;
    
    ALMessage *alMessageRecieved;
    
    CGSize viewSizeReceived;
    NSIndexPath *indexReceived;
    
    UITableView *chatTblView;
    
    NSRange linkRangeString;
    
    NSUInteger count;
    ALChatViewController * chatController;
    //
}

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        
        //
        readStatus = FALSE;
        
        isTrimmed = FALSE;
        
        self.backgroundColor = [UIColor clearColor];
        
        self.mUserProfileImageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 5, 45, 45)];
        self.mUserProfileImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.mUserProfileImageView.layer.cornerRadius=self.mUserProfileImageView.frame.size.width/2;
        self.mUserProfileImageView.clipsToBounds = YES;
        [self.contentView addSubview:self.mUserProfileImageView];
        
        self.mBubleImageView = [[UIImageView alloc] init];
        self.mBubleImageView.contentMode = UIViewContentModeScaleToFill;
        self.mBubleImageView.backgroundColor = [UIColor whiteColor];
        self.mBubleImageView.layer.cornerRadius = 5;
        [self.contentView addSubview:self.mBubleImageView];
        
        
        self.replyParentView = [[UIImageView alloc] init];
        self.replyParentView.contentMode = UIViewContentModeScaleToFill;
        self.replyParentView.backgroundColor = [UIColor whiteColor];
        self.replyParentView.layer.cornerRadius = 5;
        [self.replyParentView setUserInteractionEnabled:YES];
        
        UITapGestureRecognizer * replyViewTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureForReplyView:)];
        replyViewTapGesture.numberOfTapsRequired=1;
        [self.replyParentView addGestureRecognizer:replyViewTapGesture];
        
        [self.contentView addSubview:self.replyParentView];
        
        self.mNameLabel = [[UILabel alloc] init];
        [self.mNameLabel setTextColor:[UIColor whiteColor]];
        [self.mNameLabel setBackgroundColor:[UIColor clearColor]];
        [self.mNameLabel setFont:[UIFont fontWithName:@"Helvetica" size:18]];
        self.mNameLabel.textAlignment = NSTextAlignmentCenter;
        self.mNameLabel.layer.cornerRadius = self.mNameLabel.frame.size.width/2;
        self.mNameLabel.layer.masksToBounds = YES;
        [self.contentView addSubview:self.mNameLabel];
        
        self.mMessageLabel = [[ALHyperLabel alloc] init];
        self.mMessageLabel.numberOfLines = 0;
        
        NSString *fontName = [ALUtilityClass parsedALChatCostomizationPlistForKey:APPLOZIC_CHAT_FONTNAME];
        
        if (!fontName) {
            fontName = DEFAULT_FONT_NAME;
        }
        
        self.mMessageLabel.font = [UIFont fontWithName:[ALApplozicSettings getFontFace] size:MESSAGE_TEXT_SIZE];
        self.mMessageLabel.textColor = [UIColor grayColor];
        [self.contentView addSubview:self.mMessageLabel];
        
        self.mChannelMemberName = [[UILabel alloc] init];
        self.mChannelMemberName.font = [UIFont fontWithName:@"Helvetica-Bold" size:15];
        self.mChannelMemberName.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.mChannelMemberName];
        
        self.mDateLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, 100, 25)];
        self.mDateLabel.font = [UIFont fontWithName:[ALApplozicSettings getFontFace] size:DATE_LABEL_SIZE];
        self.mDateLabel.textColor = [ALApplozicSettings getDateColor];
        self.mDateLabel.numberOfLines = 1;
        [self.contentView addSubview:self.mDateLabel];
        
        self.mMessageStatusImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.mDateLabel.frame.origin.x+
                                                                                     self.mDateLabel.frame.size.width,
                                                                                     self.mDateLabel.frame.origin.y, 20, 20)];
        self.mMessageStatusImageView.contentMode = UIViewContentModeScaleToFill;
        self.mMessageStatusImageView.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.mMessageStatusImageView];
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.contentView.userInteractionEnabled = YES;
        
        tapForCustomView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(processTapGesture)];
        tapForCustomView.numberOfTapsRequired = 1;
        
        UITapGestureRecognizer *tapForOpenChat = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(processOpenChat)];
        tapForOpenChat.numberOfTapsRequired = 1;
        [self.mUserProfileImageView setUserInteractionEnabled:YES];
        [self.mUserProfileImageView addGestureRecognizer:tapForOpenChat];
        
        self.hyperLinkArray = [NSMutableArray new];
        
        if ([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft) {
            
            self.transform = CGAffineTransformMakeScale(-1.0, 1.0);
            self.replyParentView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
            self.mNameLabel.transform = CGAffineTransformMakeScale(-1.0, 1.0);
            self.mChannelMemberName.transform = CGAffineTransformMakeScale(-1.0, 1.0);
            self.mMessageLabel.transform = CGAffineTransformMakeScale(-1.0, 1.0);
            self.mDateLabel.transform = CGAffineTransformMakeScale(-1.0, 1.0);
            self.mMessageStatusImageView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
        }
    }
    
    
    
    UITapGestureRecognizer * menuTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(proccessTapForMenu:)];
    menuTapGesture.cancelsTouchesInView = NO;
    [self.contentView setUserInteractionEnabled:YES];
    [self.contentView addGestureRecognizer:menuTapGesture];
    return self;
    
}


//Modified by chetu
-(instancetype)populateCell:(ALMessage*) alMessage viewSize:(CGSize)viewSize index:(NSIndexPath*)index tableview:(UITableView*)tblView withController:(UIViewController*)controller
{
    chatController = (ALChatViewController*)controller;
    //textContainer.size = self.mMessageLabel.bounds.size;
    indexReceived = index;
    
    chatTblView = tblView;

    NSString *trimmedText;
    
    if(alMessage.message.length > 300){
        
        if ( alMessageRecieved.isTrimmedFinish == YES) {
            
            alMessage = alMessageRecieved;
            trimmedText = alMessage.message;
            readStatus = FALSE;
            
        }else{
            
            if (alMessage.trimmedMessage == nil) {
                isTrimmed = true;
                trimmedText = [self trimRecievedMessage:alMessage];
                
            }else{
                isTrimmed = false;
                trimmedText = [self trimRecievedMessage:alMessage];
            }
       
        }
    }
    
    [self.hyperLinkArray removeAllObjects];
    self.mUserProfileImageView.alpha = 1;
    
    BOOL today = [[NSCalendar currentCalendar] isDateInToday:[NSDate dateWithTimeIntervalSince1970:[alMessage.createdAtTime doubleValue]/1000]];
    NSString * theDate = [NSString stringWithFormat:@"%@",[alMessage getCreatedAtTimeChatOnlyTime:today]];
    
    alMessage = [[chatController.alMessageWrapper getUpdatedMessageArray] objectAtIndex:index.row];
    self.mMessage = alMessage;
    [self processHyperLink];
    
    
    //self.mMessage.message = @"😊";
    
    
    CGFloat fontSize = self.mMessageLabel.font.pointSize;
    
    BOOL isEmojiPresent = NO;
    if (self.mMessage.message && [self stringContainsSingleEmoji:self.mMessage.message]) {
        
        //fontSize = 40;
        isEmojiPresent = YES;
    }
    
    ALContactDBService *theContactDBService = [[ALContactDBService alloc] init];
    ALContact *alContact = [theContactDBService loadContactByKey:@"userId" value: alMessage.to];
    
    NSString * receiverName = [alContact getDisplayName];
    
    CGSize theTextSize;
    
    if(alMessage.message.length > 300){
        
        theTextSize = [ALUtilityClass getSizeForText:trimmedText maxWidth:viewSize.width-115
                                                font:self.mMessageLabel.font.fontName
                                            fontSize:fontSize];
    }else{
        
        theTextSize = [ALUtilityClass getSizeForText:alMessage.message maxWidth:viewSize.width-115
                                                font:self.mMessageLabel.font.fontName
                                            fontSize:fontSize];
    }
    
    
    CGSize theDateSize = [ALUtilityClass getSizeForText:theDate maxWidth:150
                                                   font:self.mDateLabel.font.fontName
                                               fontSize:self.mDateLabel.font.pointSize];
    
    CGSize receiverNameSize = [ALUtilityClass getSizeForText:receiverName
                                                    maxWidth:viewSize.width - 115
                                                        font:self.mChannelMemberName.font.fontName
                                                    fontSize:self.mChannelMemberName.font.pointSize];
    
    [self.mBubleImageView setHidden:NO];
    [self.mDateLabel setHidden:NO];
    [self.mMessageLabel setTextAlignment:NSTextAlignmentLeft];
    [self.mChannelMemberName setHidden:YES];
    [self.mNameLabel setHidden:YES];
    [self.replyParentView setHidden:YES];
    self.mMessageStatusImageView.hidden = YES;
    [self.contentView bringSubviewToFront:self.mMessageStatusImageView];
    self.mUserProfileImageView.backgroundColor = [UIColor whiteColor];
    self.mMessageLabel.backgroundColor = [UIColor clearColor];
    
    
    if([alMessage.type isEqualToString:@"100"])
    {
        [self dateTextSetupForALMessage:alMessage withViewSize:viewSize andTheTextSize:theTextSize];
    }
    else if ([alMessage.type isEqualToString:@MT_INBOX_CONSTANT])
    {
        [self.contentView bringSubviewToFront:self.mChannelMemberName];
        
        if([ALApplozicSettings isUserProfileHidden])
        {
            self.mUserProfileImageView.frame = CGRectMake(USER_PROFILE_PADDING_X, 0, 0, USER_PROFILE_HEIGHT);
        }
        else
        {
            self.mUserProfileImageView.frame = CGRectMake(USER_PROFILE_PADDING_X,
                                                          0, USER_PROFILE_WIDTH, USER_PROFILE_HEIGHT);
        }
        
        if([ALApplozicSettings getReceiveMsgColor])
        {
            self.mBubleImageView.backgroundColor = [ALApplozicSettings getReceiveMsgColor];
        }
        else
        {
            self.mBubleImageView.backgroundColor = [UIColor whiteColor];
        }
        
        self.mNameLabel.frame = self.mUserProfileImageView.frame;
        [self.mNameLabel setText:[ALColorUtility getAlphabetForProfileImage:receiverName]];
        
        //  ===== Intial bubble View image =========//
        
        CGFloat requiredBubbleWidth = theTextSize.width + BUBBLE_PADDING_WIDTH;
        CGFloat requiredBubbleHeight;
        
        
        requiredBubbleHeight =  theTextSize.height + BUBBLE_PADDING_HEIGHT;
        
        
        self.mBubleImageView.frame = CGRectMake(self.mUserProfileImageView.frame.size.width + 13,
                                                0, requiredBubbleWidth,
                                                requiredBubbleHeight);
        
        self.mBubleImageView.layer.shadowOpacity = 0.3;
        self.mBubleImageView.layer.shadowOffset = CGSizeMake(0, 2);
        self.mBubleImageView.layer.shadowRadius = 1;
        self.mBubleImageView.layer.masksToBounds = NO;
        
        CGFloat mMessageLabelY = self.mBubleImageView.frame.origin.y + MESSAGE_PADDING_Y;
        
        if([alMessage getGroupId])
        {
            [self.mChannelMemberName setHidden:NO];
            
            [self.mChannelMemberName setTextColor: [ALColorUtility getColorForAlphabet:receiverName]];
            
            if(theTextSize.width < receiverNameSize.width)
            {
                theTextSize.width = receiverNameSize.width+5;
                requiredBubbleWidth = theTextSize.width + CHANNEL_PADDING_X;
            }
            
            
            self.mChannelMemberName.frame = CGRectMake(self.mBubleImageView.frame.origin.x + CHANNEL_PADDING_X,
                                                       self.mBubleImageView.frame.origin.y + CHANNEL_PADDING_Y,
                                                       self.mBubleImageView.frame.size.width + CHANNEL_PADDING_WIDTH, CHANNEL_PADDING_HEIGHT);
            
            [self.mChannelMemberName setText:receiverName];
            
            mMessageLabelY = mMessageLabelY +  self.mChannelMemberName.frame.size.height;
            requiredBubbleHeight = requiredBubbleHeight + self.mChannelMemberName.frame.size.height;
        }
        
        if( alMessage.isAReplyMessage )
        {
            [self processReplyOfChat:alMessage andViewSize:viewSize];
            mMessageLabelY = mMessageLabelY + self.replyParentView.frame.size.height;
            requiredBubbleHeight = requiredBubbleHeight + self.replyParentView.frame.size.height;
            requiredBubbleWidth = self.replyParentView.frame.size.width + 10;
        }
        //resize bubble
        
        if(self.replyParentView.frame.size.width>theTextSize.width){
            theTextSize.width = self.replyParentView.frame.size.width;
        }
        
        self.mBubleImageView.frame = CGRectMake(self.mUserProfileImageView.frame.size.width + 13,
                                                0, requiredBubbleWidth,
                                                requiredBubbleHeight);
        
        
        self.mMessageLabel.frame = CGRectMake(self.mChannelMemberName.frame.origin.x,
                                              self.mChannelMemberName.frame.origin.y + self.mChannelMemberName.frame.size.height + MESSAGE_PADDING_Y_GRP,
                                              theTextSize.width, theTextSize.height);
        
        
        self.mMessageLabel.frame = CGRectMake(self.mBubleImageView.frame.origin.x + MESSAGE_PADDING_X ,
                                              mMessageLabelY,
                                              theTextSize.width, theTextSize.height);
        
        
        
        self.mMessageLabel.textColor = [ALApplozicSettings getReceiveMsgTextColor];
        
        self.mDateLabel.frame = CGRectMake(self.mBubleImageView.frame.origin.x,
                                           self.mBubleImageView.frame.origin.y + self.mBubleImageView.frame.size.height,
                                           theDateSize.width + DATE_PADDING_WIDTH, DATE_HEIGHT);
        
        self.mDateLabel.textAlignment = NSTextAlignmentLeft;
        
        if(alContact.contactImageUrl)
        {
            ALMessageClientService * messageClientService = [[ALMessageClientService alloc]init];
            [messageClientService downloadImageUrlAndSet:alContact.contactImageUrl imageView:self.mUserProfileImageView defaultImage:@"ic_contact_picture_holo_light.png"];
        }
        else
        {
            [self.mUserProfileImageView sd_setImageWithURL:[NSURL URLWithString:@""] placeholderImage:nil options:SDWebImageRefreshCached];
            [self.mNameLabel setHidden:NO];
            self.mUserProfileImageView.backgroundColor = [ALColorUtility getColorForAlphabet:receiverName];
        }
    }
    else    //Sent Message
    {
        if([ALApplozicSettings getSendMsgColor])
        {
            self.mBubleImageView.backgroundColor = [ALApplozicSettings getSendMsgColor];
        }
        else
        {
            self.mBubleImageView.backgroundColor = [UIColor whiteColor];
        }
        self.mUserProfileImageView.alpha = 0;
        self.mUserProfileImageView.frame = CGRectMake(viewSize.width - 53, 0, 0, 45);
        
        self.mMessageStatusImageView.hidden = NO;
        
        
        CGFloat requiredBubbleWidth = theTextSize.width + BUBBLE_PADDING_X_OUTBOX;
        CGFloat requiredBubbleHeight;
        
        requiredBubbleHeight =  theTextSize.height + BUBBLE_PADDING_HEIGHT;
        
        
        
        self.mBubleImageView.frame = CGRectMake((viewSize.width - theTextSize.width - BUBBLE_PADDING_X_OUTBOX) , 0,
                                                requiredBubbleWidth+10,
                                                requiredBubbleHeight);
        
        self.mBubleImageView.layer.shadowOpacity = 0.3;
        self.mBubleImageView.layer.shadowOffset = CGSizeMake(0, 2);
        self.mBubleImageView.layer.shadowRadius = 1;
        self.mBubleImageView.layer.masksToBounds = NO;
        CGFloat mMessageLabelY = self.mBubleImageView.frame.origin.y + MESSAGE_PADDING_Y;
        
        if(alMessage.isAReplyMessage)
        {
            [self processReplyOfChat:alMessage andViewSize:viewSize];
            mMessageLabelY = mMessageLabelY + self.replyParentView.frame.size.height ;
            requiredBubbleHeight = requiredBubbleHeight + self.replyParentView.frame.size.height;
            requiredBubbleWidth = self.replyParentView.frame.size.width + 10;
            
        }
        
        //resize bubble
        self.mBubleImageView.frame = CGRectMake((viewSize.width - requiredBubbleWidth - BUBBLE_PADDING_X_OUTBOX),
                                                0, requiredBubbleWidth,
                                                requiredBubbleHeight);
        
        if(self.replyParentView.frame.size.width>theTextSize.width){
            theTextSize.width = self.replyParentView.frame.size.width;
        }
        
        msgFrameHeight = self.mBubleImageView.frame.size.height;
        
        
        self.mMessageLabel.frame = CGRectMake(self.mBubleImageView.frame.origin.x + MESSAGE_PADDING_X,
                                              mMessageLabelY, theTextSize.width, theTextSize.height);
        
        
        
        
        self.mDateLabel.frame = CGRectMake((self.mBubleImageView.frame.origin.x + self.mBubleImageView.frame.size.width)
                                           - theDateSize.width - DATE_PADDING_X,
                                           self.mBubleImageView.frame.origin.y + self.mBubleImageView.frame.size.height,
                                           theDateSize.width, DATE_HEIGHT);
        
        
        self.mDateLabel.textAlignment = NSTextAlignmentLeft;
        
        self.mMessageStatusImageView.frame = CGRectMake(self.mDateLabel.frame.origin.x + self.mDateLabel.frame.size.width,
                                                        self.mDateLabel.frame.origin.y,
                                                        MSG_STATUS_WIDTH, MSG_STATUS_HEIGHT);
        
        
        
        
        
    }
    
    if ([alMessage.type isEqualToString:@MT_OUTBOX_CONSTANT] && (alMessage.contentType != ALMESSAGE_CHANNEL_NOTIFICATION)) {
        
        self.mMessageStatusImageView.hidden = NO;
        NSString * imageName;
        
        switch (alMessage.status.intValue) {
            case DELIVERED_AND_READ :{
                imageName = @"ic_action_read.png";
            }break;
            case DELIVERED:{
                imageName = @"ic_action_message_delivered.png";
            }break;
            case SENT:{
                imageName = @"ic_action_message_sent.png";
            }break;
            default:{
                imageName = @"ic_action_about.png";
            }break;
        }
        self.mMessageStatusImageView.image = [ALUtilityClass getImageFromFramworkBundle:imageName];
    }
    
    self.mDateLabel.text = theDate;
    
    
    //    self.mDateLabel.text = @"";
    
    /*    =========================== FOR PUSH VC ON TAP =============================  */
    
    //   CHECKING IF MESSAGE META-DATA DICTIONARY HAVE SOME DATA
    
    if(self.mMessage.metadata.count && (alMessage.contentType != 102) && (alMessage.contentType != 103))
    {
        [self.mBubleImageView setUserInteractionEnabled:YES];
        [self.mBubleImageView addGestureRecognizer:tapForCustomView];
    }
    
    /*    ====================================== END =================================  */
    
    self.mMessageLabel.font = [UIFont fontWithName:[ALApplozicSettings getFontFace] size:MESSAGE_TEXT_SIZE];
    
    
    
    
    if(alMessage.contentType == ALMESSAGE_CONTENT_TEXT_HTML)
    {
        
        NSAttributedString * attributedString = [[NSAttributedString alloc] initWithData:[self.mMessage.message dataUsingEncoding:NSUnicodeStringEncoding]
                                                                                 options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType } documentAttributes:nil error:nil];
        
        self.mMessageLabel.attributedText = attributedString;
    }
    else
    {
        NSDictionary *attrs = @{
                                NSFontAttributeName : self.mMessageLabel.font,
                                NSForegroundColorAttributeName : self.mMessageLabel.textColor
                                };
        
        self.mMessageLabel.linkAttributeDefault = @{
                                                    NSFontAttributeName : self.mMessageLabel.font,
                                                    NSForegroundColorAttributeName :[UIColor blueColor],
                                                    NSUnderlineStyleAttributeName : [NSNumber numberWithInt:NSUnderlineStyleThick]
                                                    };
        
        if (self.mMessage.message){
            
            //Modified by chetu
            
            /*Implement a  check to identify long message*/
            if (alMessage.isTrimmedFinish == NO && alMessage.message.length > 300)
            {
                
                self.mMessageLabel.attributedText = answerAttributed;
                
                
            }else{
                
                self.mMessageLabel.attributedText = [[NSAttributedString alloc] initWithString:self.mMessage.message attributes:attrs];
            }
            //
            
            
        }
        [self setHyperLinkAttribute];
    }
    
    
    if(isEmojiPresent){
        NSDictionary *attrs = @{
                                NSFontAttributeName : [UIFont systemFontOfSize:fontSize],
                                NSForegroundColorAttributeName : self.mMessageLabel.textColor
                                };
        
        self.mMessageLabel.attributedText = [[NSAttributedString alloc] initWithString:self.mMessage.message attributes:attrs];
    }
    
    
    
    //    if (self.mMessage.message && ([self.mMessage.type isEqualToString:@"4"] || [self.mMessage.type isEqualToString:@"5"])){
    
    //    }
    //    else
    //    {
    //        //self.mMessageLabel.text = self.mMessage.message;
    //
    //    }
    
    
    return self;
    
}

//

- (BOOL)stringContainsSingleEmoji:(NSString *)string {
    // __block BOOL returnValue = NO;
    __block int count = 0;
    [string enumerateSubstringsInRange:NSMakeRange(0, [string length]) options:NSStringEnumerationByComposedCharacterSequences usingBlock:
     ^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
         BOOL returnValue = NO;
         const unichar hs = [substring characterAtIndex:0];
         // surrogate pair
         if (0xd800 <= hs && hs <= 0xdbff) {
             if (substring.length > 1) {
                 const unichar ls = [substring characterAtIndex:1];
                 const int uc = ((hs - 0xd800) * 0x400) + (ls - 0xdc00) + 0x10000;
                 if (0x1d000 <= uc && uc <= 0x1f77f) {
                     returnValue = YES;
                 }
             }
         } else if (substring.length > 1) {
             const unichar ls = [substring characterAtIndex:1];
             if (ls == 0x20e3) {
                 returnValue = YES;
             }
             
         } else {
             // non surrogate
             if (0x2100 <= hs && hs <= 0x27ff) {
                 returnValue = YES;
             } else if (0x2B05 <= hs && hs <= 0x2b07) {
                 returnValue = YES;
             } else if (0x2934 <= hs && hs <= 0x2935) {
                 returnValue = YES;
             } else if (0x3297 <= hs && hs <= 0x3299) {
                 returnValue = YES;
             } else if (hs == 0xa9 || hs == 0xae || hs == 0x303d || hs == 0x3030 || hs == 0x2b55 || hs == 0x2b1c || hs == 0x2b1b || hs == 0x2b50) {
                 returnValue = YES;
             }
         }
         
         if (returnValue) {
             count++;
         }
     }];
    
    return count == 1? YES : NO ;
}



-(void) proccessTapForMenu:(id)tap{
    
    [self processKeyBoardHideTap];
    
    UIMenuItem * messageForward = [[UIMenuItem alloc] initWithTitle:NSLocalizedStringWithDefaultValue(@"forwardOptionTitle", [ALApplozicSettings getLocalizableName],[NSBundle mainBundle], NSLocalizedString(@"Forward", nil), @"") action:@selector(messageForward:)];
    UIMenuItem * messageReply = [[UIMenuItem alloc] initWithTitle:NSLocalizedStringWithDefaultValue(@"replyOptionTitle", [ALApplozicSettings getLocalizableName],[NSBundle mainBundle], NSLocalizedString(@"Reply", nil), @"") action:@selector(messageReply:)];
    
    if ([self.mMessage.type isEqualToString:@MT_INBOX_CONSTANT]){
        
        [[UIMenuController sharedMenuController] setMenuItems: @[messageForward,messageReply]];
        
    }else if ([self.mMessage.type isEqualToString:@MT_OUTBOX_CONSTANT]){
        
        UIMenuItem * msgInfo = [[UIMenuItem alloc] initWithTitle:NSLocalizedStringWithDefaultValue(@"infoOptionTitle", [ALApplozicSettings getLocalizableName],[NSBundle mainBundle], NSLocalizedString(@"Info", nil), @"") action:@selector(msgInfo:)];
        
        [[UIMenuController sharedMenuController] setMenuItems: @[msgInfo,messageReply,messageForward]];
    }
    [[UIMenuController sharedMenuController] update];
    
}

-(void)dateTextSetupForALMessage:(ALMessage *)alMessage withViewSize:(CGSize)viewSize andTheTextSize:(CGSize)theTextSize
{
    [self.mDateLabel setHidden:YES];
    [self.mBubleImageView setHidden:YES];
    CGFloat dateY = 0;
    [self.mMessageLabel setFrame:CGRectMake(0, dateY, viewSize.width, theTextSize.height+10)];
    [self.mMessageLabel setTextAlignment:NSTextAlignmentCenter];
    [self.mMessageLabel setText:alMessage.message];
    [self.mMessageLabel setBackgroundColor:[UIColor clearColor]];
    [self.mMessageLabel setTextColor:[ALApplozicSettings getMsgDateColor]];
    self.mUserProfileImageView.frame = CGRectMake(USER_PROFILE_PADDING_X, 0, 0, USER_PROFILE_HEIGHT);
    
}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

-(BOOL)canBecomeFirstResponder
{
    return YES;
}

-(BOOL) canPerformAction:(SEL)action withSender:(id)sender
{
    
    if(self.mMessage.groupId){
        ALChannelService *channelService = [[ALChannelService alloc] init];
        ALChannel *channel =  [channelService getChannelByKey:self.mMessage.groupId];
        if(channel && channel.type == OPEN){
            return (self.mMessage.isDownloadRequired? NO:(action == @selector(copy:)));
        }
    }
    
    if([self.mMessage.type isEqualToString:@MT_OUTBOX_CONSTANT] && self.mMessage.groupId)
    {
        return (self.mMessage.isDownloadRequired? (action == @selector(delete:) || action == @selector(msgInfo:) || action == @selector(copy:)) : (action == @selector(delete:)|| action == @selector(msgInfo:)|| [self isForwardMenuEnabled:action]  || [self isMessageReplyMenuEnabled:action] || action == @selector(copy:)));
    }
    
    return (self.mMessage.isDownloadRequired? (action == @selector(delete:)):(action == @selector(delete:) ||[self isForwardMenuEnabled:action]|| [self isMessageReplyMenuEnabled:action] )|| (action == @selector(copy:)));
    
    
}


-(void) messageForward:(id)sender
{
    NSLog(@"Message forward option is pressed");
    [self.delegate processForwardMessage:self.mMessage];
}


// Default copy method
- (void)copy:(id)sender
{
    NSLog(@"Copy in ALChatCell, messageId: %@", self.mMessage.message);
    UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
    
    if(self.mMessage.message != NULL)
    {
        //    [pasteBoard setString:cell.textLabel.text];
        [pasteBoard setString:self.mMessage.message];
    }
    else
    {
        [pasteBoard setString:@""];
    }
    
}

-(void) delete:(id)sender
{
    NSLog(@"Delete in ALChatCell pressed");
    
    //UI
    NSLog(@"message to deleteUI %@",self.mMessage.message);
    [self.delegate deleteMessageFromView:self.mMessage];
    
    //serverCall
    [ALMessageService deleteMessage:self.mMessage.key andContactId:self.mMessage.contactIds withCompletion:^(NSString *string, NSError *error) {
        
        NSLog(@"DELETE MESSAGE ERROR :: %@", error.description);
    }];
}

-(void)msgInfo:(id)sender
{
    [self.delegate showAnimation:YES];
    UIStoryboard *storyboardM = [UIStoryboard storyboardWithName:@"Applozic" bundle:[NSBundle bundleForClass:ALChatViewController.class]];
    ALMessageInfoViewController *msgInfoVC = (ALMessageInfoViewController *)[storyboardM instantiateViewControllerWithIdentifier:@"ALMessageInfoView"];
    
    __weak typeof(ALMessageInfoViewController *) weakObj = msgInfoVC;
    
    [msgInfoVC setMessage:self.mMessage andHeaderHeight:msgFrameHeight withCompletionHandler:^(NSError *error) {
        
        if(!error)
        {
            [self.delegate loadView:weakObj];
        }
        else
        {
            [self.delegate showAnimation:NO];
        }
    }];
}


-(void) messageReply:(id)sender
{
    NSLog(@"Message forward option is pressed");
    [self.delegate processMessageReply:self.mMessage];
    
}

-(void) processKeyBoardHideTap
{
    [self.delegate handleTapGestureForKeyBoard];
    
}

-(void)processTapGesture
{
    [self.delegate processALMessage:self.mMessage];
}

-(void)processOpenChat
{
    [self processKeyBoardHideTap];
    [self.delegate openUserChat:self.mMessage];
}

-(void)processHyperLink
{
    if(self.mMessage.contentType == ALMESSAGE_CHANNEL_NOTIFICATION || !self.mMessage.message.length) // AVOID HYPERLINK FOR GROUP OPERATION MESSAGE OBJECT
    {
        return;
    }
    
    NSString * source = self.mMessage.message;
    NSDataDetector * detector = [NSDataDetector dataDetectorWithTypes:(NSTextCheckingTypePhoneNumber | NSTextCheckingTypeLink)
                                                                error:nil];
    
    NSArray * matches = [detector matchesInString:source options:0 range:NSMakeRange(0, [source length])];
    
    for(NSTextCheckingResult * link in matches)
    {
        if(link.URL)
        {
            NSString * actualLinkString = [source substringWithRange:link.range];
            [self.hyperLinkArray addObject:actualLinkString];
        }
        else if (link.phoneNumber)
        {
            [self.hyperLinkArray addObject:link.phoneNumber.description];
        }
    }
}

-(void)setHyperLinkAttribute
{
    if(self.mMessage.contentType == ALMESSAGE_CHANNEL_NOTIFICATION || !self.mMessage.message.length)
    {
        return;
    }
    
    void(^handler)(ALHyperLabel *label, NSString *substring) = ^(ALHyperLabel *label, NSString *substring){
        
        if(substring.integerValue)
        {
            NSNumber * contact = [NSNumber numberWithInteger:substring.integerValue];
            NSURL * phoneNumber = [NSURL URLWithString:[NSString stringWithFormat:@"telprompt://%@",contact]];
            [[UIApplication sharedApplication] openURL:phoneNumber];
        }
        else
        {
            if([substring hasPrefix:@"http"])
            {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:substring]];
            }
            else
            {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@",substring]]];
            }
        }
    };
    
    NSArray * nsArrayLink = [NSArray arrayWithArray:[self.hyperLinkArray mutableCopy]];
    [self.mMessageLabel setLinksForSubstrings:nsArrayLink withLinkHandler: handler];
}

-(void)processReplyOfChat:(ALMessage*)almessage andViewSize:(CGSize)viewSize
{
    
    if(!almessage.isAReplyMessage)
    {
        return;
    }
    
    NSString * messageReplyId = [almessage.metadata valueForKey:AL_MESSAGE_REPLY_KEY];
    ALMessage * replyMessage = [[ALMessageService new] getALMessageByKey:messageReplyId];
    
    if(replyMessage == nil){
        return;
        
    }
    
    self.replyParentView.hidden=NO;
    
    self.replyUIView = [[MessageReplyView alloc] init];
    
    [self.replyUIView setBackgroundColor:[UIColor clearColor]];
    
    
    CGFloat replyWidthRequired = [self.replyUIView getWidthRequired:replyMessage andViewSize:viewSize];
    
    if(self.mBubleImageView.frame.size.width> replyWidthRequired )
    {
        replyWidthRequired = (self.mBubleImageView.frame.size.width);
        NSLog(@" replyWidthRequired is less from parent one : %d", replyWidthRequired);
    }
    else
    {
        NSLog(@" replyWidthRequired is grater from parent one : %d", replyWidthRequired);
        
    }
    
    CGFloat bubbleXposition = self.mBubleImageView.frame.origin.x +5;
    
    if(almessage.isSentMessage)
    {
        bubbleXposition  = (viewSize.width - replyWidthRequired - BUBBLE_PADDING_X_OUTBOX -5);
        
    }
    
    if(almessage.groupId && almessage.isReceivedMessage)
    {
        
        self.replyParentView.frame =
        CGRectMake( bubbleXposition+2,
                   self.mChannelMemberName.frame.origin.y + self.mChannelMemberName.frame.size.height,
                   replyWidthRequired+5,
                   60);
        
    }
    else if(!almessage.groupId & !almessage.isSentMessage  ){
        self.replyParentView.frame =
        CGRectMake( bubbleXposition -1 ,
                   self.mBubleImageView.frame.origin.y+3 ,
                   replyWidthRequired+5,
                   60);
        
    }else{
        self.replyParentView.frame =
        CGRectMake( bubbleXposition -5 ,
                   self.mBubleImageView.frame.origin.y+3 ,
                   replyWidthRequired+5,
                   60);
        
    }
    
    //clear views if any addeded already
    NSArray *viewsToRemove = [self.replyParentView subviews];
    for (UIView *v in viewsToRemove) {
        [v removeFromSuperview];
    }
    
    if ([almessage.type isEqualToString:@MT_INBOX_CONSTANT]) {
        [self.replyParentView setBackgroundColor:[ALApplozicSettings getSendMsgColor]];
    }
    else
    {
        [self.replyParentView setBackgroundColor:[UIColor whiteColor]];
        
    }
    
    [self.replyUIView populateUI:almessage withSuperView:self.replyParentView];
    [self.replyParentView addSubview:self.replyUIView];
    
}

-(void)tapGestureForReplyView:(id)sender{
    
    [self.delegate scrollToReplyMessage:self.mMessage];
    
}

-(BOOL)isMessageReplyMenuEnabled:(SEL) action
{
    
    return ([ALApplozicSettings isReplyOptionEnabled] && action == @selector(messageReply:));
    
}

-(BOOL)isForwardMenuEnabled:(SEL) action;
{
    return ([ALApplozicSettings isForwardOptionEnabled] && action == @selector(messageForward:));
}


//Modified by chetu

/**
 This is method used to add attributed text in label
 - Parameters:
 - msgLbl: UILabel
 - range: NSRange
 - tapGesture: UITapGestureRecognizer
 - Returns: NSRange
 */
-(BOOL)didTapAttributedTextInLabel:(UILabel*)msgLbl inRange:(NSRange)range withGesture:(UITapGestureRecognizer *)tapGesture {
    
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    NSTextContainer  *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeZero];
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithString:msgLbl.attributedText.string];
    
    // Configure layoutManager and textStorage
    
    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];

    
    // Configure textContainer
    textContainer.lineFragmentPadding = 0.0;
    textContainer.lineBreakMode = msgLbl.lineBreakMode;
    textContainer.maximumNumberOfLines = msgLbl.numberOfLines;
    CGSize labelSize = msgLbl.bounds.size;
    textContainer.size = labelSize;
    
    
    CGPoint locationOfTouchInLabel = [tapGesture locationInView:msgLbl];
   // CGSize labelSize = tapGesture.view.bounds.size;
    CGRect textBoundingBox = [layoutManager usedRectForTextContainer:textContainer];
    CGPoint textContainerOffset = CGPointMake((labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
                                              (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y);
    CGPoint locationOfTouchInTextContainer = CGPointMake(locationOfTouchInLabel.x - textContainerOffset.x,
                                                         locationOfTouchInLabel.y - textContainerOffset.y);
    NSInteger indexOfCharacter = [layoutManager characterIndexForPoint:locationOfTouchInTextContainer
                                                       inTextContainer:textContainer
                              fractionOfDistanceBetweenInsertionPoints:nil];

    
    return NSLocationInRange(indexOfCharacter, range);
}



/**
 This is method used to handle tap gesture on read more button
 - Parameters:
 - tapGesture: UITapGestureRecognizer
 - Returns: nil
 */
- (void)readMoreDidClickedGesture:(UITapGestureRecognizer *)tapGesture {
    
    UILabel * msgLbl = (UILabel*)tapGesture.view;
    NSString * messageLblString = msgLbl.text;
    NSRange  readMoreRange = [messageLblString rangeOfString:@"....Read More"];
    
    
    
    if ([self didTapAttributedTextInLabel:msgLbl inRange:readMoreRange withGesture:tapGesture]) {
        ALMessage * msg = [[chatController.alMessageWrapper getUpdatedMessageArray] objectAtIndex:tapGesture.view.tag];
        isTrimmed = true;
        [self trimRecievedMessage:msg];
        isTrimmed = false;
        chatTblView.reloadData;
    }
    
    NSLog(@"read more button action'...");
}


/**
 This is method used to trimm long message
 - Parameters:
 - trimRecievedMessage: NSString
 - Returns: NSString
 */
-(NSString*)trimRecievedMessage:(ALMessage*)msg{
    
    //textContainer.size = self.mMessageLabel.bounds.size;
    NSString *trimmedMsg;
    
    if (isTrimmed == true) {
        
        if (msg.trimmedMessage.length == 0) {
            trimmedMsg = [msg.message substringToIndex:300];
        }else{
            if (msg.message.length >= msg.trimmedMessage.length+300) {
                trimmedMsg = [msg.message substringToIndex:msg.trimmedMessage.length+300];
            }else{
                NSString * remainingString = [msg.message substringFromIndex:msg.trimmedMessage.length];
                trimmedMsg = [NSString stringWithFormat:@"%@%@",msg.trimmedMessage,remainingString];
            }
            
        }
        
    }else{
        trimmedMsg = msg.trimmedMessage;
    }
    
   
    msg.trimmedMessage = trimmedMsg;
    
    NSString *finalString = @"";
    if (trimmedMsg.length != msg.message.length) {
        
        NSString *readMoreText = @"....Read More";
        
        finalString = [NSString stringWithFormat: @"%@ %@", trimmedMsg,readMoreText];
        
        UITapGestureRecognizer *readMoreGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(readMoreDidClickedGesture:)];
        
        readMoreGesture.numberOfTapsRequired = 1;
        
        [self.mMessageLabel addGestureRecognizer:readMoreGesture];
       
        self.mMessageLabel.tag = indexReceived.row;
        
        self.mMessageLabel.userInteractionEnabled = YES;
        
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:finalString attributes:nil];
        NSRange linkRange = NSMakeRange((finalString.length-readMoreText.length), readMoreText.length); // for the word "link" in the string above
        
       // linkRangeString = linkRange;
        
        NSDictionary *linkAttributes = @{ NSForegroundColorAttributeName : [UIColor colorWithRed:0.05 green:0.4 blue:0.65 alpha:1.0],
                                          NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle) };
        [attributedString setAttributes:linkAttributes range:linkRange];
        
        
        answerAttributed = attributedString;
        // Assign attributedText to UILabel
        self.mMessageLabel.attributedText = attributedString;
        
        msg.isTrimmedFinish = false;
        
    }else{
        msg.isTrimmedFinish = YES;
        finalString = trimmedMsg;
        
    }
    
    [[chatController.alMessageWrapper getUpdatedMessageArray] replaceObjectAtIndex:indexReceived.row withObject:msg];
    NSLog(@"%@", [[[chatController.alMessageWrapper getUpdatedMessageArray] objectAtIndex:indexReceived.row] trimmedMessage]);
    
    return finalString;
}

//
@end
