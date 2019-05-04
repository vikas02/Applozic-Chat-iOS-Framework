//
//  ViewController.m
//  ChatApp
//
//  Copyright (c) 2015 AppLozic. All rights reserved.
//

#define NAVIGATION_TEXT_SIZE 20
#define USER_NAME_LABEL_SIZE 18
#define MESSAGE_LABEL_SIZE 14
#define TIME_LABEL_SIZE 12
#define IMAGE_NAME_LABEL_SIZE 14

#import "UIView+Toast.h"
#import "TSMessageView.h"
#import "ALMessagesViewController.h"
#import "ALConstant.h"
#import "ALMessageService.h"
#import "ALMessage.h"
#import "ALUtilityClass.h"
#import "ALContact.h"
#import "ALMessageDBService.h"
#import "ALRegisterUserClientService.h"
#import "ALDBHandler.h"
#import "ALContact.h"
#import "ALUserDefaultsHandler.h"
#import "ALContactDBService.h"
#import "UIImageView+WebCache.h"
#import "ALColorUtility.h"
#import "ALMQTTConversationService.h"
#import "ALApplozicSettings.h"
#import "ALDataNetworkConnection.h"
#import "ALUserService.h"
#import "ALChannelDBService.h"
#import "ALChannel.h"
#import "ALChatLauncher.h"
#import "ALChannelService.h"
#import "ALNotificationView.h"
#import "ALPushAssist.h"
#import "ALUserDetail.h"
#import "ALContactService.h"
#import "ALConversationClientService.h"
#import "ALPushNotificationService.h"
#import "ALPushAssist.h"
#import "ALGroupCreationViewController.h"
#import "ALMessageClientService.h"
#import "ALGroupDetailViewController.h"


// Constants
#define DEFAULT_TOP_LANDSCAPE_CONSTANT -34
#define DEFAULT_TOP_PORTRAIT_CONSTANT -64
#define MQTT_MAX_RETRY 3

//==============================================================================================================================================
// Private interface
//==============================================================================================================================================

@interface ALMessagesViewController ()<UITableViewDataSource, UITableViewDelegate, ALMessagesDelegate, ALMQTTConversationDelegate>

@property (strong, nonatomic) IBOutlet UIBarButtonItem *navigationRightButton;

-(IBAction)navigationRightButtonAction:(id)sender;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *backButton;
- (IBAction)backButtonAction:(id)sender;
-(void)emptyConversationAlertLabel;
// Constants

// IBOutlet
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mTableViewTopConstraint;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *mActivityIndicator;

// Private Variables
@property (nonatomic) NSInteger mqttRetryCount;
@property (nonatomic, strong) NSMutableArray * mContactsMessageListArray;
@property (nonatomic, strong) UIColor *navColor;
@property (nonatomic, strong) NSNumber *unreadCount;
@property (strong, nonatomic) UILabel *emptyConversationText;
@property (strong, nonatomic) ALMQTTConversationService *alMqttConversationService;

@property (strong, nonatomic) UIBarButtonItem *barButtonItem;
@property (strong, nonatomic) UIBarButtonItem *refreshButton;

//@property (nonatomic, strong) ALMessageDBService *dBService;

@end

// $$$$$$$$$$$$$$$$$$ Class Extension for solving Constraints Issues.$$$$$$$$$$$$$$$$$$$$
@interface NSLayoutConstraint (Description)

@end

@implementation NSLayoutConstraint (Description)

-(NSString *)description {
    return [NSString stringWithFormat:@"id: %@, constant: %f", self.identifier, self.constant];
}

@end
//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

@implementation ALMessagesViewController

//==============================================================================================================================================
#pragma mark - VIEW LIFE CYCLE
//==============================================================================================================================================

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.mqttRetryCount = 0;
    
    [self setUpTableView];
    self.mTableView.allowsMultipleSelectionDuringEditing = NO;
    [self.mActivityIndicator startAnimating];
    
    self.dBService = [[ALMessageDBService alloc] init];
    self.dBService.delegate = self;
    [self.dBService getMessages:self.childGroupList];
    
    self.alMqttConversationService = [ALMQTTConversationService sharedInstance];
    self.alMqttConversationService.mqttConversationDelegate = self;
    
    [self.alMqttConversationService subscribeToConversation];
    
    CGFloat navigationHeight = self.navigationController.navigationBar.frame.size.height +
    [UIApplication sharedApplication].statusBarFrame.size.height;
    
    self.emptyConversationText = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.origin.x,
                                                                           self.view.frame.size.height/2 - navigationHeight,
                                                                           self.view.frame.size.width, 30)];
    
    [self.emptyConversationText setText:[ALApplozicSettings getEmptyConversationText]];
    [self.emptyConversationText setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:self.emptyConversationText];
    self.emptyConversationText.hidden = YES;
    
    self.barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[self setCustomBackButton: NSLocalizedStringWithDefaultValue(@"back", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], [ALApplozicSettings getTitleForBackButtonMsgVC], @"")]];
    
    if((self.channelKey || self.userIdToLaunch)){
        [self createAndLaunchChatView ];
    }
    
    //amolchat
    self.aplozicStoryboard = [UIStoryboard storyboardWithName:@"Applozic" bundle:[NSBundle bundleForClass:ALChatViewController.class]];
    
    
    [self addCustomBack];
}

#pragma mark - back button code
-(void)addCustomBack
{
    
    
    UIButton *backButton = [[UIButton alloc] initWithFrame: CGRectMake(0, 0, 44.0f, 30.0f)];
    [backButton setImage:[ALUtilityClass getImageFromFramworkBundle:@"ic_back1"]  forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backClicked) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    
}
-(void)backClicked
{
    [self.navigationController popViewControllerAnimated:YES];
}

//amolchat
-(void)createCustomLeftItems
{
    UIButton *btnMenu = [UIButton buttonWithType:UIButtonTypeCustom];
    btnMenu.frame = CGRectMake(0, 0, 44, 44);
    [btnMenu setImage:[UIImage imageNamed:@"menu"] forState:UIControlStateNormal];
    UIBarButtonItem *menu =   [[UIBarButtonItem alloc] initWithCustomView:btnMenu];
    
    
    UIButton *btnGuo = [UIButton buttonWithType:UIButtonTypeCustom];
    btnGuo.frame = CGRectMake(0, 0, 44, 44);
    [btnGuo setImage:[UIImage imageNamed:@"img_photo"] forState:UIControlStateNormal];
    UIBarButtonItem *menuGuo =   [[UIBarButtonItem alloc] initWithCustomView:btnGuo];
    
    self.navigationItem.leftBarButtonItems = @[menu];
}

-(void)loadMessages:(NSNotification *)notification
{
    [self.dBService getMessages:self.childGroupList];
}

-(void)viewDidDisappear:(BOOL)animated
{
    BOOL profileFlag = NO;
    UIViewController *VC = self.tabBarController.selectedViewController;
    UINavigationController *navVC = (UINavigationController *)VC;
    
    for(UIViewController *VC in navVC.viewControllers)
    {
        if([NSStringFromClass([VC class]) isEqualToString:@"ALUserProfileVC"])
        {
            profileFlag = YES;
        }
    }
    
    if (self.navigationController.viewControllers.count == 1 && !profileFlag)
    {
        NSLog(@"MSG VC : CLOSING_MQTT_CONNECTIONS");
        [self.alMqttConversationService unsubscribeToConversation];
    }
}

-(void)updateLocalization{
    
    [self.mTableView reloadData];
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if([ALApplozicSettings isDropShadowInNavigationBarEnabled])
    {
        [self dropShadowInNavigationBar];
    }
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLocalization) name:@"Update_messages_screen_control" object:nil];
    
    //amolchat
    self.tabBarController.navigationController.navigationBarHidden = YES;
    self.navigationController.navigationBarHidden = YES;
    //self.navigationItem.hidesBackButton = YES;
    
    [self.navigationController.navigationBar addSubview:[ALUtilityClass setStatusBarStyle]];
    
    //amolchat
    // [self.navigationItem setLeftBarButtonItem:self.barButtonItem];
    [self.navigationItem setLeftBarButtonItems:nil];
    // [self createCustomLeftItems];
    
    
    
    [self.tabBarController.tabBar setHidden:[ALUserDefaultsHandler isBottomTabBarHidden]];
    
    if ([self.detailChatViewController refreshMainView])
    {
        if(self.parentGroupKey && [ALApplozicSettings getSubGroupLaunchFlag])
        {
            [self intializeSubgroupMessages];
        }
        
        [self.dBService getMessages:self.childGroupList];
        [self.detailChatViewController setRefreshMainView:FALSE];
        [self.mTableView reloadData];
    }
    
    if([ALUserDefaultsHandler isNavigationRightButtonHidden])
    {
        [self.navigationItem setRightBarButtonItems:nil];
    }
    
    if([ALApplozicSettings getCustomNavRightButtonMsgVC])
    {
        self.refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                           target:self
                                                                           action:@selector(refreshMessageList)];
        [self.navigationItem setRightBarButtonItem:self.refreshButton];
    }
    
    if([ALUserDefaultsHandler isBackButtonHidden])
    {
        [self.navigationItem setLeftBarButtonItems:nil];
    }
    
    //register for notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushNotificationhandler:) name:@"pushNotification" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callLastSeenStatusUpdate)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:[UIApplication sharedApplication]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newMessageHandler:) name:NEW_MESSAGE_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTable:) name:@"reloadTable" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLastSeenAtStatusPUSH:) name:@"update_USER_STATUS" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEntersForegroundIntoListView:) name:@"appCameInForeground" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadMessages:) name:@"CONVERSATION_DELETION" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCallForUser:) name:@"USER_DETAILS_UPDATE_CALL" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateBroadCastMessages) name:@"BROADCAST_MSG_UPDATE" object:nil];
    
    [self.navigationController.navigationBar setTitleTextAttributes: @{
                                                                       NSForegroundColorAttributeName:[UIColor whiteColor],
                                                                       NSFontAttributeName:[UIFont fontWithName:[ALApplozicSettings getFontFace]
                                                                                                           size:NAVIGATION_TEXT_SIZE]
                                                                       }];
    
    self.navigationItem.title = NSLocalizedStringWithDefaultValue(@"chatTitle", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], [ALApplozicSettings getTitleForConversationScreen], @"");
    
    
    if([ALApplozicSettings getColorForNavigation] && [ALApplozicSettings getColorForNavigationItem])
    {
        [self.navigationController.navigationBar setTitleTextAttributes: @{
                                                                           NSForegroundColorAttributeName:[ALApplozicSettings getColorForNavigationItem],
                                                                           NSFontAttributeName:[UIFont fontWithName:[ALApplozicSettings getFontFace]
                                                                                                               size:NAVIGATION_TEXT_SIZE]
                                                                           }];
        
        self.navigationController.navigationBar.translucent = NO;
        [self.navigationController.navigationBar setBarTintColor: [ALApplozicSettings getColorForNavigation]];
        [self.navigationController.navigationBar setTintColor: [ALApplozicSettings getColorForNavigationItem]];
    }
    
    [self callLastSeenStatusUpdate];
}

-(void)intializeSubgroupMessages
{
    ALChannelService * channelService = [ALChannelService new];
    self.childGroupList = [[NSMutableArray alloc] initWithArray:[channelService fetchChildChannelsWithParentKey:self.parentGroupKey]];
    //    ALChannel * parentChannel = [channelService getChannelByKey:self.parentGroupKey];
    //    [self.childGroupList addObject:parentChannel];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.detailChatViewController.contactIds = nil;
    self.detailChatViewController.channelKey = nil;
    self.detailChatViewController.conversationId = nil;
    
    if([self.mActivityIndicator isAnimating])
    {
        [self.emptyConversationText setHidden:YES];
    }
    else
    {
        [self emptyConversationAlertLabel];
    }
    
    if (![ALDataNetworkConnection checkDataNetworkAvailable])
    {
        [self noDataNotificationView];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.tabBarController.tabBar setHidden: [ALUserDefaultsHandler isBottomTabBarHidden]];
    //unregister for notification
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"pushNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NEW_MESSAGE_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"BROADCAST_MSG_UPDATE" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"Update_messages_screen_control" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    
    
}

//==============================================================================================================================================
#pragma mark - NAVIGATION SHADOW EFFECTS
//==============================================================================================================================================

-(void)dropShadowInNavigationBar
{
    self.navigationController.navigationBar.layer.shadowOpacity = 0.5;
    self.navigationController.navigationBar.layer.shadowOffset = CGSizeMake(0, 0);
    self.navigationController.navigationBar.layer.shadowRadius = 10;
    self.navigationController.navigationBar.layer.masksToBounds = NO;
}

//==============================================================================================================================================
#pragma mark - END
//==============================================================================================================================================

-(void)appEntersForegroundIntoListView:(id)sender
{
    [self callLastSeenStatusUpdate];
}

-(void)emptyConversationAlertLabel
{
    if(self.mContactsMessageListArray.count == 0)
    {
        [self.emptyConversationText setHidden:NO];
    }
    else
    {
        [self.emptyConversationText setHidden:YES];
    }
}

//==============================================================================================================================================
#pragma mark - NAVIGATION RIGHT BUTTON ACTION + CONTACT LAUNCH FOR USER/SUB GROUP
//==============================================================================================================================================

-(IBAction)navigationRightButtonAction:(id)sender
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Applozic" bundle:[NSBundle bundleForClass:ALChatViewController.class]];
    ALNewContactsViewController *contactVC = (ALNewContactsViewController *)[storyboard instantiateViewControllerWithIdentifier:@"ALNewContactsViewController"];
    contactVC.forGroup = [NSNumber numberWithInt:REGULAR_CONTACTS];
    if([ALApplozicSettings isContactsGroupEnabled ] && _contactsGroupId)
    {
        [ALApplozicSettings setContactsGroupId:_contactsGroupId];
    }
    
    if(self.parentGroupKey && [ALApplozicSettings getSubGroupLaunchFlag])
    {
        contactVC.forGroup = [NSNumber numberWithInt:LAUNCH_GROUP_OF_TWO];
        ALChannelService * channelService = [ALChannelService new];
        contactVC.parentChannel = [channelService getChannelByKey:self.parentGroupKey];
        contactVC.childChannels = [[NSMutableArray alloc] initWithArray:[channelService fetchChildChannelsWithParentKey:self.parentGroupKey]];
    }
    
    [self.navigationController pushViewController:contactVC animated:YES];
}

/************************************  REFRESH CONVERSATION IF RIGHT BUTTON IS REFRESH BUTTON **************************************************/

-(void)refreshMessageList
{
    NSString * toastMsg = NSLocalizedString(@"Syncing messages with the server, It might take fews mins!", nil)
    ;
    [self.view makeToast:toastMsg duration:1.0 position:CSToastPositionBottom title:nil];
    
    [ALMessageService getLatestMessageForUser:[ALUserDefaultsHandler getDeviceKeyString] withCompletion:^(NSMutableArray  * messageList, NSError *error) {
        
        if(error)
        {
            NSLog(@"ERROR: IN REFRESH MSG VC :: %@",error);
            return;
        }
        NSLog(@"REFRESH MSG VC");
    }];
}

-(void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)setUpTableView
{
    self.mContactsMessageListArray = [NSMutableArray new];
    self.mTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateConversationTableNotification:)
                                                 name:@"updateConversationTableNotification"
                                               object:nil];
}

//==============================================================================================================================================
#pragma mark - ALMessagesDelegate
//==============================================================================================================================================

-(void)reloadTable:(NSNotification*)notification
{
    [self updateMessageList:notification.object];
    [[NSNotificationCenter defaultCenter] removeObserver:@"reloadTable"];
}

-(void)getMessagesArray:(NSMutableArray *)messagesArray
{
    [self.mActivityIndicator stopAnimating];
    
    if(messagesArray.count == 0)
    {
        [[self emptyConversationText] setHidden:NO];
    }
    else
    {
        [[self emptyConversationText] setHidden:YES];
    }
    
    self.mContactsMessageListArray = messagesArray;
    for (int i=0; i<messagesArray.count; i++) {
        ALMessage * message = messagesArray[i];
        if(message.groupId != nil) {
            // It's a group message
        } else if (message.contactIds != nil)  {
            // It's a normal one to one message
        }
    }
    [self.mTableView reloadData];
    NSLog(@"GETTING MESSAGE ARRAY");
}

-(void)didUpdateBroadCastMessages {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.dBService getMessages:nil];
        [self.detailChatViewController setRefreshMainView:NO];
        [self.mTableView reloadData];
    });
}

//==============================================================================================================================================
#pragma mark - UPDATE MESSAGE LIST
//==============================================================================================================================================

-(void)updateMessageList:(NSMutableArray *)messagesArray
{
    NSUInteger index = 0;
    
    if(messagesArray.count)
    {
        [self.emptyConversationText setHidden:YES];
    }
    
    BOOL isreloadRequire = NO;
    for(ALMessage *msg in messagesArray)
    {
        
        
        ALContactCell *contactCell;
        ALContactDBService * contactDBService = [[ALContactDBService alloc] init];
        ALChannelService * channelService = [[ALChannelService alloc] init];
        if(msg.groupId)
        {
            msg.contactIds = NULL;
            contactCell = [self getCellForGroup:msg.groupId];
        }
        else
        {
            contactCell = [self getCell:msg.contactIds];
        }
        
        if (msg.contentType == AV_CALL_CONTENT_TWO)
        {
            //            ALVOIPNotificationHandler *voipHandler = [ALVOIPNotificationHandler sharedManager];
            //            [voipHandler handleAVMsg:msg andViewController:self];
        }
        else if(contactCell)
        {
            contactCell.mMessageLabel.text = msg.message;
            
            ALContact *alContact = [contactDBService loadContactByKey:@"userId" value:msg.contactIds];
            
            ALChannel * channel = [channelService getChannelByKey:msg.groupId];
            [self updateProfileImageAndUnreadCount:contactCell WithChannel:channel orChannelId:alContact];
            //if ([msg.type integerValue] == [FORWARD_STATUS integerValue])
            //  contactCell.mLastMessageStatusImageView.image = [ALUtilityClass getImageFromFramworkBundle:@"mobicom_social_forward.png"];
            //else if ([msg.type integerValue] == [REPLIED_STATUS integerValue])
            //  contactCell.mLastMessageStatusImageView.image = [ALUtilityClass getImageFromFramworkBundle:@"mobicom_social_reply.png"];
            
            BOOL isToday = [ALUtilityClass isToday:[NSDate dateWithTimeIntervalSince1970:[msg.createdAtTime doubleValue]/1000]];
            contactCell.mTimeLabel.text = [msg getCreatedAtTime:isToday];
            [self displayAttachmentMediaType:msg andContactCell: contactCell];
            
            
        }
        else
        {
            index = [self.mContactsMessageListArray indexOfObjectPassingTest:^BOOL(ALMessage *almessage, NSUInteger idx, BOOL *stop) {
                
                if (msg.groupId)
                {
                    return [almessage.groupId isEqualToNumber:msg.groupId];
                }
                else
                {
                    if([ALApplozicSettings getSubGroupLaunchFlag])
                    {
                        return NO;
                    }
                    return [almessage.to isEqualToString:msg.to];
                }
            }];
            
            isreloadRequire = YES;
            if (index != NSNotFound)
            {
                [self.mContactsMessageListArray replaceObjectAtIndex:index withObject:msg];
            }
            else
            {
                //No cell founds
                
                //if([ALApplozicSettings getSubGroupLaunchFlag])
                //{
                if (msg.groupId)
                {
                    isreloadRequire = NO;
                    [channelService getChannelInformation:msg.groupId orClientChannelKey:nil withCompletion:^(ALChannel *alChannel) {
                        
                        BOOL channelFlag = ([ALApplozicSettings getSubGroupLaunchFlag] && [alChannel.parentKey isEqualToNumber:self.parentGroupKey]);
                        BOOL categoryFlag =  [ALApplozicSettings getCategoryName] && [alChannel isPartOfCategory:[ALApplozicSettings getCategoryName]];
                        
                        if ((channelFlag || categoryFlag) ||
                            !([ALApplozicSettings getSubGroupLaunchFlag] || [ALApplozicSettings getCategoryName]))
                        {
                            [self.mContactsMessageListArray insertObject:msg atIndex:0];
                            [self.mTableView reloadData];
                        }
                    }];
                }
                //}
                else
                {
                    [self.mContactsMessageListArray insertObject:msg atIndex:0];
                }
            }
            
            NSLog(@"contact cell not found ....");
        }
    }
    if(isreloadRequire)
    {
        [self.mTableView reloadData];
    }
}

-(ALContactCell *)getCell:(NSString *)key
{
    int index = (int)[self.mContactsMessageListArray indexOfObjectPassingTest:^BOOL(id element, NSUInteger idx, BOOL *stop) {
        
        ALMessage *message = (ALMessage*)element;
        if([message.contactIds isEqualToString:key] && (message.groupId.intValue == 0 || message.groupId == nil))
        {
            *stop = YES;
            return YES;
        }
        return NO;
    }];
    
    NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:1];
    ALContactCell *contactCell = (ALContactCell *)[self.mTableView cellForRowAtIndexPath:path];
    
    return contactCell;
}

-(ALContactCell *)getCellForGroup:(NSNumber *)groupKey
{
    int index = (int)[self.mContactsMessageListArray indexOfObjectPassingTest:^BOOL(id element,NSUInteger idx,BOOL *stop) {
        
        ALMessage *message = (ALMessage*)element;
        if([message.groupId isEqualToNumber:groupKey])
        {
            *stop = YES;
            return YES;
        }
        return NO;
    }];
    
    NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:1];
    ALContactCell *contactCell  = (ALContactCell *)[self.mTableView cellForRowAtIndexPath:path];
    
    return contactCell;
}

//==============================================================================================================================================
#pragma mark - TABLE VIEW DELEGATES METHODS
//==============================================================================================================================================

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return (self.mTableView == nil) ? 0 : 2;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
        {
            if([ALApplozicSettings getGroupOption])
            {
                return 1;
            }
            else
            {
                return 0;
            }
        }break;
            
        case 1:
        {
            return self.mContactsMessageListArray.count>0?[self.mContactsMessageListArray count]:0;
        }break;
            
        default:
            return 0;
            break;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ALContactCell *contactCell;
    
    switch (indexPath.section)
    {
        case 0:
        {
            //Cell for group button....
            contactCell = (ALContactCell *)[tableView dequeueReusableCellWithIdentifier:@"groupCell"];
            
            //Add group button.....
            UIButton *newBtn = (UIButton*)[contactCell viewWithTag:101];
            [newBtn addTarget:self action:@selector(createGroup:) forControlEvents:UIControlEventTouchUpInside];
            newBtn.userInteractionEnabled = YES;
            
            
            //            [newBtn setTitle:NSLocalizedStringWithDefaultValue(@"createGroupOptionTitle", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], @"Create Group", @"")
            //                    forState:UIControlStateNormal];
            [newBtn setContentMode:UIViewContentModeScaleAspectFit];
            
            [newBtn setImage:[UIImage imageNamed:@"create_group"] forState:UIControlStateNormal];
            [newBtn sizeToFit];
            
            
            
            // Add group button.....
            UIButton *newBroadCast = (UIButton*)[contactCell viewWithTag:102];
            [newBroadCast addTarget:self action:@selector(createBroadcastGroup:) forControlEvents:UIControlEventTouchUpInside];
            
            [newBroadCast sizeToFit];
            
            [newBroadCast setTitle:NSLocalizedStringWithDefaultValue(@"broadcastGroupOptionTitle", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], NSLocalizedString(@"New Broadcast", nil), @"")
                          forState:UIControlStateNormal];
            
            newBroadCast.userInteractionEnabled = [ALApplozicSettings isBroadcastGroupEnable];
            [newBroadCast setHidden:![ALApplozicSettings isBroadcastGroupEnable]];
            
        }break;
            
        case 1:
        {
            //Add rest of messageList
            contactCell = (ALContactCell *)[tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
            
            [contactCell.mUserNameLabel setFont:[UIFont fontWithName:[ALApplozicSettings getFontFace] size:USER_NAME_LABEL_SIZE]];
            [contactCell.mMessageLabel setFont:[UIFont fontWithName:[ALApplozicSettings getFontFace] size:MESSAGE_LABEL_SIZE]];
            [contactCell.mTimeLabel setFont:[UIFont fontWithName:[ALApplozicSettings getFontFace] size:TIME_LABEL_SIZE]];
            [contactCell.imageNameLabel setFont:[UIFont fontWithName:[ALApplozicSettings getFontFace] size:IMAGE_NAME_LABEL_SIZE]];
            
            contactCell.unreadCountLabel.backgroundColor = [ALApplozicSettings getUnreadCountLabelBGColor];
            
            
            
            //add gesture for tap
            if (contactCell.mUserImageView.gestureRecognizers.count == 0) {
                UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(profileIconClicked:)];
                tap.numberOfTapsRequired = 1;
                [contactCell.mUserImageView addGestureRecognizer:tap];
            }
            contactCell.mUserImageView.userInteractionEnabled = YES;
            contactCell.mUserImageView.tag = indexPath.row;
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                contactCell.unreadCountLabel.layer.cornerRadius = contactCell.unreadCountLabel.frame.size.width/2;
                contactCell.unreadCountLabel.layer.masksToBounds = YES;
                
                contactCell.mUserImageView.layer.cornerRadius = contactCell.mUserImageView.frame.size.width/2;
                contactCell.mUserImageView.layer.masksToBounds = YES;
                contactCell.mUserImageView.contentMode = UIViewContentModeScaleAspectFill;
                
                //amol: add borders
                //contactCell.mUserImageView.layer.borderWidth = 1;
                // contactCell.mUserImageView.layer.borderColor = [ALApplozicSettings getColorForNavigation].CGColor;
                
            });
            
            [contactCell.onlineImageMarker setBackgroundColor:[UIColor clearColor]];
            
            UILabel* nameIcon = (UILabel*)[contactCell viewWithTag:102];
            if ([[contactCell viewWithTag:102] isKindOfClass:[UILabel class]]){
                NSLog(@"This is a label");
                nameIcon.textColor = [UIColor whiteColor];
            }else{
                NSLog(@"Not a label");
            }
            
            
            ALMessage *message = (ALMessage *)self.mContactsMessageListArray[indexPath.row];
            
            ALContactDBService *contactDBService = [[ALContactDBService alloc] init];
            ALContact *alContact = [contactDBService loadContactByKey:@"userId" value: message.to];
            
            if([message.groupId intValue])
            {
                ALChannelService *channelService = [[ALChannelService alloc] init];
                [channelService getChannelInformation:message.groupId orClientChannelKey:nil withCompletion:^(ALChannel *alChannel)
                 {
                     [self updateProfileImageAndUnreadCount:contactCell WithChannel:alChannel orChannelId:nil];
                 }];
            }
            else
            {
                contactCell.mUserNameLabel.text = [alContact getDisplayName];
                [self updateProfileImageAndUnreadCount:contactCell WithChannel:nil orChannelId:alContact];
                
            }
            
            
            contactCell.mMessageLabel.text = message.message;
            contactCell.mMessageLabel.hidden = NO;
            //
            //            if ([message.type integerValue] == [FORWARD_STATUS integerValue])
            //                contactCell.mLastMessageStatusImageView.image = [ALUtilityClass getImageFromFramworkBundle:@"mobicom_social_forward.png"];
            //            else if ([message.type integerValue] == [REPLIED_STATUS integerValue])
            //                contactCell.mLastMessageStatusImageView.image = [ALUtilityClass getImageFromFramworkBundle:@"mobicom_social_reply.png"];
            //
            BOOL isToday = [ALUtilityClass isToday:[NSDate dateWithTimeIntervalSince1970:[message.createdAtTime doubleValue]/1000]];
            contactCell.mTimeLabel.text = [message getCreatedAtTime:isToday];
            
            [self displayAttachmentMediaType:message andContactCell:contactCell];
            
        }break;
            
        default:
            break;
    }
    
    return contactCell;
}


-(void)profileIconClicked:(UIGestureRecognizer*)gesture
{
    UIView *tappedView  = gesture.view;
    
    if (tappedView.tag < self.mContactsMessageListArray.count) {
        ALMessage * message = self.mContactsMessageListArray[tappedView.tag];
        
        if (!message.groupId) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"chat_open_profile" object:message.contactIds];
        }
        else
        {
            /* ALChannelService *channelService = [[ALChannelService alloc] init];
             
             ALChannel * channel = [channelService getChannelByKey:message.groupId];
             
             if (![ALApplozicSettings isGroupInfoDisabled] && (channel.type != GROUP_OF_TWO) && ![ALChannelService isChannelDeleted:channel.key] && ![ALChannelService isConversationClosed:channel.key])
             {
             UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Applozic" bundle:[NSBundle bundleForClass:[self class]]];
             ALGroupDetailViewController * groupDetailViewController = (ALGroupDetailViewController*)[storyboard instantiateViewControllerWithIdentifier:@"ALGroupDetailViewController"];
             groupDetailViewController.channelKeyID = channel.key;
             // groupDetailViewController.alChatViewController = self;
             
             if([ALApplozicSettings isContactsGroupEnabled] && _contactsGroupId){
             [ALApplozicSettings setContactsGroupId:_contactsGroupId];
             }
             
             [[ALUtilityClass topMostControllerNormal].navigationController pushViewController:groupDetailViewController animated:YES];
             }
             */
        }
        
    }
    
}

//==============================================================================================================================================
#pragma mark - update profile user image
//==============================================================================================================================================

-(void)updateProfileImageAndUnreadCount:(ALContactCell *)contactCell WithChannel:(ALChannel*) alChannel orChannelId:(ALContact*)contact{
    
    UILabel* nameIcon = (UILabel*)[contactCell viewWithTag:102];
    
    if ([[contactCell viewWithTag:102] isKindOfClass:[UILabel class]]){
        NSLog(@"This is a label");
        nameIcon.textColor = [UIColor whiteColor];
    }else{
        NSLog(@"Not a label");
    }
    
    
    ALContactService * contactService = [ALContactService new];
    contactCell.mUserImageView.backgroundColor = [UIColor whiteColor];
    if(alChannel)
    {
        
        if(alChannel.type == GROUP_OF_TWO)
        {
            NSString * receiverId =  [alChannel getReceiverIdInGroupOfTwo];
            ALContact* grpContact = [contactService loadContactByKey:@"userId" value:receiverId];
            contactCell.mUserNameLabel.text = [grpContact getDisplayName];
            contactCell.onlineImageMarker.hidden = (!grpContact.connected);
            if(grpContact.contactImageUrl.length)
            {
                ALMessageClientService * messageClientService = [[ALMessageClientService alloc]init];
                [messageClientService downloadImageUrlAndSet:grpContact.contactImageUrl imageView:contactCell.mUserImageView defaultImage:nil];
                contactCell.imageNameLabel.hidden = YES;
                nameIcon.hidden=YES;
            }
            else
            {
                nameIcon.hidden = NO;
                [contactCell.mUserImageView sd_setImageWithURL:[NSURL URLWithString:@""] placeholderImage:nil options:SDWebImageRefreshCached];
                contactCell.mUserImageView.backgroundColor = [ALColorUtility getColorForAlphabet:[grpContact getDisplayName]];
                if ([nameIcon isKindOfClass:[UILabel class]]){
                    NSLog(@"This is a label");
                    [nameIcon setText:[ALColorUtility getAlphabetForProfileImage:[grpContact getDisplayName]]];
                }else{
                    NSLog(@"Not a label");
                }
                
              
            }
            
        }
        else
        {
            
            NSString  *placeHolderImage ;
            if (alChannel.type == BROADCAST)
            {
                placeHolderImage = @"broadcast_group.png";
                [contactCell.mUserImageView setImage:[ALUtilityClass getImageFromFramworkBundle:@"broadcast_group.png"]];
            }else{
                placeHolderImage = @"applozic_group_icon.png";
                [contactCell.mUserImageView setImage:[ALUtilityClass getImageFromFramworkBundle:@"applozic_group_icon.png"]];
            }
            
            ALMessageClientService * messageClientService = [[ALMessageClientService alloc]init];
            [messageClientService downloadImageUrlAndSet:alChannel.channelImageURL imageView:contactCell.mUserImageView defaultImage:placeHolderImage];
            
            nameIcon.hidden = YES;
            contactCell.mUserNameLabel.text = [alChannel name];
            contactCell.onlineImageMarker.hidden = YES;
            
        }
    }
    else
    {
        contactCell.mUserNameLabel.text = [contact getDisplayName];
        contactCell.onlineImageMarker.hidden = (!contact.connected);
        if(contact.contactImageUrl.length)
        {
            ALMessageClientService * messageClientService = [[ALMessageClientService alloc]init];
            [messageClientService downloadImageUrlAndSet:contact.contactImageUrl imageView:contactCell.mUserImageView defaultImage:@"ic_contact_picture_holo_light.png"];
            contactCell.imageNameLabel.hidden = YES;
            nameIcon.hidden= YES;
        }
        else
        {
            nameIcon.hidden = NO;
            [contactCell.mUserImageView sd_setImageWithURL:[NSURL URLWithString:@""] placeholderImage:nil options:SDWebImageRefreshCached];
            contactCell.mUserImageView.backgroundColor = [ALColorUtility getColorForAlphabet:[contact getDisplayName]];
            
            if ([nameIcon isKindOfClass:[UILabel class]]){
                NSLog(@"This is a label");
                [nameIcon setText:[ALColorUtility getAlphabetForProfileImage:[contact getDisplayName]]];
            }else{
                NSLog(@"Not a label");
            }
            //[nameIcon setText:[ALColorUtility getAlphabetForProfileImage:[contact getDisplayName]]];
        }
    }
    
    //for contact Id:
    
    //update unread count value
    int count = (alChannel) ? alChannel.unreadCount.intValue :contact.unreadCount.intValue;
    if(count==0)
    {
        contactCell.unreadCountLabel.text = @"";
        [contactCell.unreadCountLabel setHidden:YES];
    }
    else
    {
        [contactCell.unreadCountLabel setHidden:NO];
        contactCell.unreadCountLabel.text=[NSString stringWithFormat:@"%i",count];
        
    }
    
    //online status
    ALContactDBService *contactDBService = [[ALContactDBService alloc] init];
    BOOL isUserDeleted = [contactDBService isUserDeleted:contact.userId];
    
    if( contact && ( contact.block || contact.blockBy || isUserDeleted  || ![ALApplozicSettings getVisibilityForOnlineIndicator]) )
    {
        [contactCell.onlineImageMarker setHidden:YES];
    }
    
}

/*********************************************  ATTACHMENT ICON & TITLE IN TABLE CELL ******************************************************/

-(void)displayAttachmentMediaType:(ALMessage *)message andContactCell:(ALContactCell *)contactCell
{
    
    
    if( message.fileMeta || message.contentType == ALMESSAGE_CONTENT_LOCATION ){
        contactCell.mMessageLabel.hidden = YES;
        contactCell.imageMarker.hidden = NO;
        contactCell.imageNameLabel.hidden = NO;
        
        if([message.fileMeta.contentType hasPrefix:@"image"])
        {
            //        contactCell.imageNameLabel.text = NSLocalizedString(@"MEDIA_TYPE_IMAGE", nil);
            contactCell.imageNameLabel.text = NSLocalizedStringWithDefaultValue(@"image", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], NSLocalizedString(@"Image", nil), @"");
            
            contactCell.imageMarker.image = [ALUtilityClass getImageFromFramworkBundle:@"ic_action_camera.png"];
        }
        else if([message.fileMeta.contentType hasPrefix:@"video"])
        {
            //            contactCell.imageNameLabel.text = NSLocalizedString(@"MEDIA_TYPE_VIDEO", nil);
            contactCell.imageNameLabel.text = NSLocalizedStringWithDefaultValue(@"video", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], NSLocalizedString(@"Video", nil), @"");
            contactCell.imageMarker.image = [ALUtilityClass getImageFromFramworkBundle:@"ic_action_video.png"];
        }
        else if (message.contentType == ALMESSAGE_CONTENT_LOCATION)   // location..
        {
            contactCell.mMessageLabel.hidden = YES;
            contactCell.imageNameLabel.text = NSLocalizedStringWithDefaultValue(@"location", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle],  NSLocalizedString(@"Location", nil), @"");
            contactCell.imageMarker.image = [ALUtilityClass getImageFromFramworkBundle:@"location_filled.png"];
        }
        else if (message.fileMeta.contentType)           //other than video and image
        {
            //        contactCell.imageNameLabel.text = NSLocalizedString(@"MEDIA_TYPE_ATTACHMENT", nil);
            contactCell.imageNameLabel.text =  NSLocalizedStringWithDefaultValue(@"attachment", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle],  NSLocalizedString(@"Attachment", nil), @"");
            contactCell.imageMarker.image = [ALUtilityClass getImageFromFramworkBundle:@"ic_action_attachment.png"];
        }
        else
        {
            contactCell.imageNameLabel.hidden = YES;
            contactCell.imageMarker.hidden = YES;
            contactCell.mMessageLabel.hidden = NO;
        }
        
    }
    else if (message.contentType == AV_CALL_CONTENT_THREE)
    {
        contactCell.mMessageLabel.hidden = YES;
        contactCell.imageNameLabel.hidden = NO;
        contactCell.imageMarker.hidden = NO;
        contactCell.imageNameLabel.text = [message getVOIPMessageText];
        contactCell.imageMarker.image = [ALUtilityClass getVOIPMessageImage:message];
    }
    else
    {
        contactCell.imageNameLabel.hidden = YES;
        contactCell.imageMarker.hidden = YES;
        contactCell.mMessageLabel.hidden = NO;
    }
}

//==============================================================================================================================================
#pragma mark - TABLE VIEW DATASOURCE METHODS
//==============================================================================================================================================

/*********************************************  ACTION ON TAP OF TABLE CELL ******************************************************/

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{    
    if(indexPath.section != 0)
    {
        ALMessage * message = self.mContactsMessageListArray[indexPath.row];
        
        //Modified by Chetu
        /*
         Implementation of delegate method to call api to check blocked contact in chat view controller
        */
        
        if (message.groupId == nil) {
         [self.messagesViewDelegate handleTableCelldataByIndex:indexPath andWithMessage:message];
        }
        
        //
        
        [self createDetailChatViewControllerWithMessage:message];
        ALContactCell * contactCell = (ALContactCell *)[tableView cellForRowAtIndexPath:indexPath];
        int count = [contactCell.unreadCountLabel.text intValue];
        if(count)
        {
            self.detailChatViewController.refresh = YES;
        }
        
    }
}


-(void)createDetailChatViewController:(NSString *)contactIds
{
    if (!(self.detailChatViewController))
    {
        //amolchat
        //self.detailChatViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ALChatViewController"];
        self.detailChatViewController = [self.aplozicStoryboard instantiateViewControllerWithIdentifier:@"ALChatViewController"];
        self.detailChatViewController.navigationController.navigationBarHidden = NO;
        
        
    }
    if([ALApplozicSettings isContactsGroupEnabled ] && _contactsGroupId)
    {
        [ALApplozicSettings setContactsGroupId:_contactsGroupId];
    }
    self.detailChatViewController.contactIds = contactIds;
    self.detailChatViewController.chatViewDelegate = self;
    self.detailChatViewController.channelKey = self.channelKey;
    
    //amol added if block
    
    
    if (![self containController:[ALChatViewController class]])
    {
        [self.navigationController pushViewController:self.detailChatViewController animated:YES];
        
    }
}

- (BOOL ) containController:(Class)controllerClass
{
    BOOL isFound = NO;
    NSArray * controllers = [self.navigationController viewControllers];
    
    for (int i = 0; i < [controllers count]; i++){
        
        UIViewController * controllerTest = [controllers objectAtIndex:i];
        
        if([controllerTest isKindOfClass:controllerClass]){
            NSLog(@"Class is available");
            isFound = YES; break;
        }
        
    }
    return isFound;
}

-(void)createDetailChatViewControllerWithMessage:(ALMessage *)message
{   
    if(!(self.detailChatViewController))
    {
        //amolchat
        // self.detailChatViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ALChatViewController"];
        self.detailChatViewController = [self.aplozicStoryboard instantiateViewControllerWithIdentifier:@"ALChatViewController"];
//        self.detailChatViewController.IS_USER_BLOCKED = YES;
        self.detailChatViewController.navigationController.navigationBarHidden = NO;
        
    }
    
    if(message.conversationId)
    {
        self.detailChatViewController.conversationId = message.conversationId;
    }
    
    if([ALApplozicSettings isContactsGroupEnabled ] && _contactsGroupId)
    {
        [ALApplozicSettings setContactsGroupId:_contactsGroupId];
    }
    
    if(message.groupId)
    {
        self.detailChatViewController.channelKey = message.groupId;
        self.detailChatViewController.contactIds = nil;
        
        ALChannelService *channelService = [[ALChannelService alloc] init];
        ALChannel *alChannel = [channelService getChannelByKey:message.groupId];
        
        if(alChannel.type == GROUP_OF_TWO)
        {
            NSString* contactId = [alChannel getReceiverIdInGroupOfTwo];
            ALContactService * contactService = [ALContactService new];
            ALContact * alContact = [contactService loadContactByKey:@"userId" value:contactId];
            self.detailChatViewController.contactIds = alContact.userId;
        }
    }
    else
    {
        self.detailChatViewController.contactIds = message.contactIds;
    }
    
    self.detailChatViewController.chatViewDelegate = self;
    
    //amolchat
    //[self.navigationController pushViewController: self.detailChatViewController animated:YES];
    
    [self.tabBarController.navigationController pushViewController: self.detailChatViewController animated:YES];
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0)
    {
        tableView.rowHeight = 40.0;
    }
    else
    {
        tableView.rowHeight = 81.5;
    }
    
    return tableView.rowHeight;
}

//==============================================================================================================================================
#pragma mark - TABLE VIEW EDITING METHODS
//==============================================================================================================================================

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0)
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

/************************************************  DELETE CONVERSATION ON SWIPE ********************************************************/

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        
        NSLog(@"DELETE_PRESSED");
        if(![ALDataNetworkConnection checkDataNetworkAvailable])
        {
            [self noDataNotificationView];
            return;
        }
        ALMessage * alMessageobj = self.mContactsMessageListArray[indexPath.row];
        
        ALChannelService *channelService = [ALChannelService new];
        
        if([channelService isChannelLeft:[alMessageobj getGroupId]])
        {
            NSArray * filteredArray = [self.mContactsMessageListArray filteredArrayUsingPredicate:
                                       [NSPredicate predicateWithFormat:@"groupId = %@",[alMessageobj getGroupId]]];
            
            [self.dBService deleteAllMessagesByContact:nil orChannelKey:[alMessageobj getGroupId]];
            [ALChannelService setUnreadCountZeroForGroupID:[alMessageobj getGroupId]];
            [self subProcessDeleteMessageThread:filteredArray];
            return;
        }
        
        [ALMessageService deleteMessageThread:alMessageobj.contactIds orChannelKey:[alMessageobj getGroupId]
                               withCompletion:^(NSString *string, NSError *error) {
                                   
                                   if(error)
                                   {
                                       NSLog(@"DELETE_FAILED_CONVERSATION_ERROR_DESCRIPTION :: %@", error.description);
                                       [ALUtilityClass displayToastWithMessage:@"Delete failed"];
                                       return;
                                   }
                                   NSArray * theFilteredArray;
                                   if([alMessageobj getGroupId])
                                   {
                                       
                                       theFilteredArray = [self.mContactsMessageListArray filteredArrayUsingPredicate:
                                                           [NSPredicate predicateWithFormat:@"groupId = %@",[alMessageobj getGroupId]]];
                                   }
                                   else
                                   {
                                       theFilteredArray = [self.mContactsMessageListArray filteredArrayUsingPredicate:
                                                           [NSPredicate predicateWithFormat:@"contactIds = %@ AND groupId = %@",alMessageobj.contactIds,nil]];
                                   }
                                   
                                   [self subProcessDeleteMessageThread:theFilteredArray];
                                   
                                   if([ALChannelService isChannelDeleted:[alMessageobj getGroupId]])
                                   {
                                       ALChannelDBService *channelDBService = [[ALChannelDBService alloc] init];
                                       [channelDBService deleteChannel:[alMessageobj getGroupId]];
                                   }
                               }];
    }
}

-(void)subProcessDeleteMessageThread:(NSArray *)theFilteredArray
{
    NSLog(@"GETTING_FILTERED_ARRAY_COUNT :: %lu", (unsigned long)theFilteredArray.count);
    [self.mContactsMessageListArray removeObjectsInArray:theFilteredArray];
    [self emptyConversationAlertLabel];
    [self.mTableView reloadData];
}

//==============================================================================================================================================
#pragma mark - NOTIFICATION OBSERVERS
//==============================================================================================================================================

-(void)updateConversationTableNotification:(NSNotification *)notification
{
    ALMessage * theMessage = notification.object;
    NSLog(@"NOTIFICATION_FOR_TABLE_UPDATE :: %@", theMessage.message);
    NSArray * theFilteredArray = [self.mContactsMessageListArray
                                  filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"contactIds = %@", theMessage.contactIds]];
    //check for group id also
    ALMessage * theLatestMessage = theFilteredArray.firstObject;
    if (theLatestMessage != nil && ![theMessage.createdAtTime isEqualToNumber: theLatestMessage.createdAtTime])
    {
        [self.mContactsMessageListArray removeObject:theLatestMessage];
        [self.mContactsMessageListArray insertObject:theMessage atIndex:0];
        [self.mTableView reloadData];
    }
}

//==============================================================================================================================================
#pragma mark - VIEW ORIENTATION METHODS
//==============================================================================================================================================

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    UIInterfaceOrientation toOrientation = (UIInterfaceOrientation)[[UIDevice currentDevice] orientation];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone &&
        (toOrientation == UIInterfaceOrientationLandscapeLeft || toOrientation == UIInterfaceOrientationLandscapeRight))
    {
        self.mTableViewTopConstraint.constant = DEFAULT_TOP_LANDSCAPE_CONSTANT;
    }
    else
    {
        self.mTableViewTopConstraint.constant = DEFAULT_TOP_PORTRAIT_CONSTANT;
    }
    [self.view layoutIfNeeded];
}

//==============================================================================================================================================
#pragma mark - MQTT SERVICE DELEGATE METHODS
//==============================================================================================================================================

-(void)mqttDidConnected
{
    if (self.detailChatViewController)
    {
        [self.detailChatViewController subscrbingChannel];
    }
}

-(void)updateCallForUser:(NSNotification *)notifyObj
{
    NSString *userID = (NSString *)notifyObj.object;
    [self updateUserDetail:userID];
}

-(void)updateUserDetail:(NSString *)userId
{
    NSLog(@"ALMSGVC : USER_DETAIL_CHANGED_CALL_UPDATE");
    [ALUserService updateUserDetail:userId withCompletion:^(ALUserDetail *userDetail) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"USER_DETAIL_OTHER_VC" object:userDetail];
        ALContactCell * contactCell = [self getCell:userId];
        UILabel* nameIcon = (UILabel *)[contactCell viewWithTag:102];
        
        if ([[contactCell viewWithTag:102] isKindOfClass:[UILabel class]]){
            NSLog(@"This is a label");
            [nameIcon setText:[ALColorUtility getAlphabetForProfileImage:[userDetail getDisplayName]]];
        }else{
            NSLog(@"Not a label");
        }
        
      
        
        if(contactCell)
        {
            NSURL * URL = [NSURL URLWithString:userDetail.imageLink];
            if(URL)
            {
                [contactCell.mUserImageView sd_setImageWithURL:URL placeholderImage:nil options:SDWebImageRefreshCached];
                nameIcon.hidden = YES;
            }
            else
            {
                nameIcon.hidden = NO;
                [contactCell.mUserImageView sd_setImageWithURL:[NSURL URLWithString:@""] placeholderImage:nil options:SDWebImageRefreshCached];
                contactCell.mUserImageView.backgroundColor = [ALColorUtility getColorForAlphabet:[userDetail getDisplayName]];
            }
            [self.detailChatViewController setRefresh:YES];
        }
        [self.detailChatViewController subProcessDetailUpdate:userDetail];
    }];
}

-(void)reloadDataForUserBlockNotification:(NSString *)userId andBlockFlag:(BOOL)flag
{
    [self.detailChatViewController checkUserBlockStatus];
    
    if([[ALPushAssist new] isMessageViewOnTop])
    {
        [self.detailChatViewController.label setHidden:YES];
        
        ALContactCell * contactCell = [self getCell:userId];
        if(contactCell && [ALApplozicSettings getVisibilityForOnlineIndicator])
        {
            [contactCell.onlineImageMarker setHidden:flag];
        }
    }
}

-(void)syncCall:(ALMessage *)alMessage andMessageList:(NSMutableArray *)messageArray
{
    ALPushAssist* top = [[ALPushAssist alloc] init];
    [self.detailChatViewController setRefresh: YES];
    
    if ([self.detailChatViewController contactIds] != nil || [self.detailChatViewController channelKey] != nil)
    {
        [self.detailChatViewController syncCall:alMessage updateUI:[NSNumber numberWithInt:APP_STATE_ACTIVE] alertValue:alMessage.message];
    }
    else if (top.isMessageViewOnTop && (![alMessage.type isEqualToString:@"5"]))
    {
        [self updateMessageList:messageArray];
        
        if ((alMessage.groupId && [ALChannelService isChannelMuted:alMessage.groupId]) || [alMessage isMsgHidden])
        {
            return;
        }
        
        ALNotificationView * alnotification = [[ALNotificationView alloc] initWithAlMessage:alMessage
                                                                           withAlertMessage:alMessage.message];
        
        [alnotification nativeNotification:self];
    }
}

-(void)delivered:(NSString *)messageKey contactId:(NSString *)contactId withStatus:(int)status
{
    if (messageKey != nil)
    {
        [self.detailChatViewController updateDeliveryReport:messageKey withStatus:status];
    }
}

-(void)updateStatusForContact:(NSString *) contactId withStatus:(int)status
{
    if([[self.detailChatViewController contactIds] isEqualToString: contactId])
    {
        [self.detailChatViewController updateStatusReportForConversation:status];
    }
}

-(void)updateTypingStatus:(NSString *)applicationKey userId:(NSString *)userId status:(BOOL)status
{
    NSLog(@"==== (MSG_VC) Received typing status %d for: %@ ====", status, userId);
    ALContactDBService *contactDBService = [[ALContactDBService alloc] init];
    ALContact *alContact = [contactDBService loadContactByKey:@"userId" value: userId];
    if((alContact.block || alContact.blockBy) && !self.detailChatViewController.channelKey)
    {
        return;
    }
    
    if ([self.detailChatViewController.contactIds isEqualToString:userId] || self.detailChatViewController.channelKey)
    {
        [self.detailChatViewController showTypingLabel:status userId:userId];
    }
}

-(void)updateLastSeenAtStatus:(ALUserDetail *) alUserDetail
{
    [self.detailChatViewController setRefreshMainView:YES];
    
    if ([self.detailChatViewController.contactIds isEqualToString:alUserDetail.userId])
    {
        [self.detailChatViewController updateLastSeenAtStatus:alUserDetail];
    }
    else if ([ALApplozicSettings getSubGroupLaunchFlag] || [ALApplozicSettings getGroupOfTwoFlag])
    {
        [self.mTableView reloadData];
    }
    else
    {
        ALContactCell *contactCell = [self getCell:alUserDetail.userId];
        [contactCell.onlineImageMarker setHidden:YES];
        if(alUserDetail.connected && [ALApplozicSettings getVisibilityForOnlineIndicator])
        {
            [contactCell.onlineImageMarker setHidden:NO];
        }
        
        ALContactDBService * contactDBService = [[ALContactDBService alloc] init];
        ALContact *alContact = [contactDBService loadContactByKey:@"userId" value:alUserDetail.userId];
        BOOL isUserDeleted = [contactDBService isUserDeleted:alUserDetail.userId];
        if(alContact.block || alContact.blockBy || isUserDeleted)
        {
            [contactCell.onlineImageMarker setHidden:YES];
        }
    }
}

-(void)updateLastSeenAtStatusPUSH:(NSNotification*)notification
{
    [self updateLastSeenAtStatus:notification.object];
}

-(void)mqttConnectionClosed
{
    if (self.mqttRetryCount > MQTT_MAX_RETRY || !self.getVisibleState)
    {
        return;
    }
    
    UIApplication *app = [UIApplication sharedApplication];
    BOOL isBackgroundState = (app.applicationState == UIApplicationStateBackground);
    
    if([ALDataNetworkConnection checkDataNetworkAvailable] && !isBackgroundState)
    {
        NSLog(@"MQTT connection closed, subscribing again: %lu", (long)_mqttRetryCount);
        NSLog(@"ALMessageVC subscribing channel again....");
        [self.alMqttConversationService subscribeToConversation];
        self.mqttRetryCount++;
    }
}

-(void)callLastSeenStatusUpdate
{
    [ALUserService getLastSeenUpdateForUsers:[ALUserDefaultsHandler getLastSeenSyncTime] withCompletion:^(NSMutableArray * userDetailArray)
     {
         for(ALUserDetail * userDetail in userDetailArray)
         {
             [self updateLastSeenAtStatus:userDetail];
         }
     }];
}

-(void)pushNotificationhandler:(NSNotification *) notification
{
    NSString * contactId = notification.object;
    
    NSArray * myArray = [contactId componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@":"]];
    
    if(myArray.count > 2)
    {
        self.channelKey = @([ myArray[1] intValue]);
    }
    else
    {
        self.channelKey = nil;
    }
    
    NSDictionary *dict = notification.userInfo;
    NSNumber * updateUI = [dict valueForKey:@"updateUI"];
    NSString * alertValue = [dict valueForKey:@"alertValue"];
    
    if (self.isViewLoaded && self.view.window && [updateUI isEqualToNumber:[NSNumber numberWithInt:APP_STATE_ACTIVE]])
    {
        ALMessage *msg = [[ALMessage alloc] init];
        msg.message = alertValue;
        NSArray *myArray = [msg.message componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@":"]];
        
        if(myArray.count > 1)
        {
            alertValue = [NSString stringWithFormat:@"%@", myArray[1]];
        }
        else
        {
            alertValue = myArray[0];
        }
        msg.message = alertValue;
        msg.contactIds = contactId;
        msg.groupId = self.channelKey;
        
        [self syncCall:msg andMessageList:nil];
    }
    else if([updateUI isEqualToNumber:[NSNumber numberWithInt:APP_STATE_INACTIVE]])
    {
        NSLog(@"######## IT SHOULD NEVER COME HERE #########");
        //  [self createDetailChatViewController: contactId]; amol ommented this line..crashing on push click
        //      [self.detailChatViewController fetchAndRefresh];
        self.detailChatViewController.contactIds = contactId;
        [self.detailChatViewController setRefresh: YES];
    }
    else if([NSNumber numberWithInt:APP_STATE_BACKGROUND])
    {
        /*
         # Synced before already!
         # NSLog(@"APP_STATE_BACKGROUND HANDLER");
         */
    }
}

-(void)dealloc
{
    //    NSLog(@"dealloc called. Unsubscribing with mqtt.");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"USER_DETAILS_UPDATE_CALL" object:nil];
}

-(IBAction)backButtonAction:(id)sender
{
    UIViewController *  uiController = [self.navigationController popViewControllerAnimated:YES];
    if(!uiController)
    {
        [self  dismissViewControllerAnimated:YES completion:nil];
    }
}

-(BOOL)getVisibleState
{
    if((self.isViewLoaded && self.view.window) ||
       (self.detailChatViewController && self.detailChatViewController.isViewLoaded && self.detailChatViewController.view.window))
    {
        NSLog(@"VIEW_CONTROLLER IS VISIBLE");
        return YES;
    }
    else
    {
        NSLog(@"VIEW_CONTROLLER IS NOT VISIBLE");
        return NO;
    }
}

//==============================================================================================================================================
#pragma mark - CUSTOM NAVIGATION BACK BUTTON
//==============================================================================================================================================

-(UIView *)setCustomBackButton:(NSString *)text
{
    UIImage * backImage = [ALUtilityClass getImageFromFramworkBundle:@"bbb.png"];
    backImage = [backImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:backImage];
    [imageView setFrame:CGRectMake(-10, 0, 30, 30)];
    [imageView setTintColor:[ALApplozicSettings getColorForNavigationItem]];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(imageView.frame.origin.x + imageView.frame.size.width - 5,
                                                               imageView.frame.origin.y + 5 , 20, 15)];
    
    [label setTextColor:[ALApplozicSettings getColorForNavigationItem]];
    [label setText:text];
    [label sizeToFit];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0,
                                                            imageView.frame.size.width + label.frame.size.width, imageView.frame.size.height)];
    
    view.bounds = CGRectMake(view.bounds.origin.x + 8, view.bounds.origin.y - 1, view.bounds.size.width, view.bounds.size.height);
    if ([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft) {
        view.transform = CGAffineTransformMakeScale(-1.0, 1.0);
        label.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    }
    [view addSubview:imageView];
    [view addSubview:label];
    
    //    UIButton * button = [[UIButton alloc] initWithFrame:view.frame];
    //    [button addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
    
    UITapGestureRecognizer * backTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(back:)];
    backTap.numberOfTapsRequired = 1;
    [view addGestureRecognizer:backTap];
    
    //    [button addSubview:view];
    //    [view addSubview:button];
    return view;
}

-(void)back:(id)sender
{
    UIViewController *  uiController = [self.navigationController popViewControllerAnimated:YES];
    if(!uiController)
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

-(void)appWillEnterForeground:(NSNotification *)notification
{
    NSLog(@"will enter foreground notification");
    // [self syncCall:nil];
    //[self callLastSeenStatusUpdate];
}

-(void)newMessageHandler:(NSNotification *)notification
{
    NSMutableArray * messageArray = notification.object;
    NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAtTime" ascending:YES];
    NSArray *descriptors = [NSArray arrayWithObject:valueDescriptor];
    [messageArray sortUsingDescriptors:descriptors];
    [self updateMessageList:messageArray];
}

//==============================================================================================================================================
#pragma mark - CREATE GROUP METHOD
//==============================================================================================================================================

-(IBAction)createGroup:(id)sender
{
    if(![ALDataNetworkConnection checkDataNetworkAvailable])
    {
        [self noDataNotificationView];
        return;
    }
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Applozic" bundle:[NSBundle bundleForClass:[ALMessagesViewController class]]];
    
    ALGroupCreationViewController * groupCreation = (ALGroupCreationViewController *)[storyboard instantiateViewControllerWithIdentifier:@"ALGroupCreationViewController"];
    
    groupCreation.isViewForUpdatingGroup = NO;
    
    if([ALApplozicSettings isContactsGroupEnabled ] && _contactsGroupId)
    {
        [ALApplozicSettings setContactsGroupId:_contactsGroupId];
    }
    
    if(self.parentGroupKey && [ALApplozicSettings getSubGroupLaunchFlag])
    {
        groupCreation.parentChannelKey = self.parentGroupKey;
    }
    
    [self.navigationController pushViewController:groupCreation animated:YES];
}

-(void)noDataNotificationView
{
    ALNotificationView * notification = [ALNotificationView new];
    [notification noDataConnectionNotificationView];
}

-(void)createAndLaunchChatView
{
    if (!(self.detailChatViewController))
    {
        //amolchat
        //self.detailChatViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ALChatViewController"];
        self.detailChatViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ALChatViewController"];
        
    }
    
    self.detailChatViewController.contactIds = self.userIdToLaunch;
    self.detailChatViewController.channelKey = self.channelKey;
    self.detailChatViewController.chatViewDelegate = self;
    [self.detailChatViewController serverCallForLastSeen];
    
    [self.navigationController pushViewController:self.detailChatViewController animated:YES];
}

-(void)insertChannelMessage:(NSNumber *)channelKey
{
    ALMessage * channelMessage = [ALMessage new];
    channelMessage.groupId = channelKey;
    NSMutableArray * grpMesgArray = [[NSMutableArray alloc] initWithObjects:channelMessage, nil];
    [self updateMessageList:grpMesgArray];
}

- (IBAction)createBroadcastGroup:(id)sender {
    
    if(![ALDataNetworkConnection checkDataNetworkAvailable])
    {
        [self noDataNotificationView];
        return;
    }
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Applozic" bundle:[NSBundle bundleForClass:[self class]]];
    
    if([ALApplozicSettings isContactsGroupEnabled ] && _contactsGroupId)
    {
        [ALApplozicSettings setContactsGroupId:_contactsGroupId];
    }
    ALNewContactsViewController *contactVC = (ALNewContactsViewController *)[storyboard
                                                                             instantiateViewControllerWithIdentifier:@"ALNewContactsViewController"];
    contactVC.forGroup = [NSNumber numberWithInt:BROADCAST_GROUP_CREATION];
    [self.navigationController pushViewController:contactVC animated:YES];
}

//==============================================================================================================================================
#pragma mark - CHAT VIEW DELEGATE FOR PUSH Custom VC
//==============================================================================================================================================

-(void)handleCustomActionFromChatVC:(UIViewController *)chatViewController andWithMessage:(ALMessage *)alMessage
{
    [self.messagesViewDelegate handleCustomActionFromMsgVC:chatViewController andWithMessage:alMessage];
}

//==============================================================================================================================================
#pragma mark - TABLE SCROLL DELEGATE METHOD
//==============================================================================================================================================

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if(self.parentGroupKey && [ALApplozicSettings getSubGroupLaunchFlag])
    {
        NSLog(@"NOT REQUIRE FOR PARENT GROUP");
        return;
    }
    
    NSLog(@"END_SCROCLLING_TRY");
    CGPoint offset = scrollView.contentOffset;
    CGRect bounds = scrollView.bounds;
    CGSize size = scrollView.contentSize;
    UIEdgeInsets inset = scrollView.contentInset;
    float y = offset.y + bounds.size.height - inset.bottom;
    float h = size.height;
    float reload_distance = 10;
    
    if(y > (h - reload_distance))
    {
        [self fetchMoreMessages:scrollView];
    }
}

-(void)fetchMoreMessages:(UIScrollView*)aScrollView
{
    [self.mActivityIndicator startAnimating];
    [self.mTableView setUserInteractionEnabled:NO];
    
    if(![ALUserDefaultsHandler getFlagForAllConversationFetched])
    {
        [self.dBService fetchConversationfromServerWithCompletion:^(BOOL flag) {
            
            [self.mActivityIndicator stopAnimating];
            [self.mTableView setUserInteractionEnabled:YES];
        }];
    }
    else
    {
        if([ALApplozicSettings getVisibilityForNoMoreConversationMsgVC])
        {
            [[TSMessageView appearance] setTitleTextColor:[UIColor whiteColor]];
            [TSMessage showNotificationWithTitle:NSLocalizedStringWithDefaultValue(@"noMoreConversations", [ALApplozicSettings getLocalizableName], [NSBundle mainBundle], NSLocalizedString(@"No more conversations", nil), @"")
                                            type:TSMessageNotificationTypeWarning];
        }
        [self.mActivityIndicator stopAnimating];
        [self.mTableView setUserInteractionEnabled:YES];
    }
}

@end
