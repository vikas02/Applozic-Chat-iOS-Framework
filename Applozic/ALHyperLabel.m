//
//  ALHyperLabel.m
//  ALHyperLabelDemo


#import "ALHyperLabel.h"

#define kCharacterSkipLength    5

@interface ALHyperLabel ()

@property (nonatomic) NSMutableDictionary *handlerDictionary;
@property (nonatomic) NSLayoutManager *layoutManager;
@property (nonatomic) NSTextContainer *textContainer;
@property (nonatomic) NSAttributedString *backupAttributedText;

@end

@implementation ALHyperLabel

static CGFloat highLightAnimationTime = 0.15;
static UIColor *ALHyperLabelLinkColorDefault;
static UIColor *ALHyperLabelLinkColorHighlight;

+ (void)initialize {
	if (self == [ALHyperLabel class]) {
		ALHyperLabelLinkColorDefault = [UIColor colorWithRed:28/255.0 green:135/255.0 blue:199/255.0 alpha:1];
		ALHyperLabelLinkColorHighlight = [UIColor colorWithRed:242/255.0 green:183/255.0 blue:73/255.0 alpha:1];
	}
}

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
    
	if (self) {
		[self checkInitialization];
        
        // _truncationString = @" ...More";
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	if (self) {
		[self checkInitialization];
        
//        _truncationString = @" ...More";
//        [self setText:self.text];
	}
	return self;
}

- (void)checkInitialization {
	if (!self.handlerDictionary) {
		self.handlerDictionary = [NSMutableDictionary new];
	}
	
	if (!self.userInteractionEnabled) {
		self.userInteractionEnabled = YES;
	}
	
	if (!self.linkAttributeDefault) {
		self.linkAttributeDefault = @{NSForegroundColorAttributeName: ALHyperLabelLinkColorDefault,
									  NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)};
	}
	
	if (!self.linkAttributeHighlight) {
		self.linkAttributeHighlight = @{NSForegroundColorAttributeName: ALHyperLabelLinkColorHighlight,
										NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)};
	}
}

//========================================================================================================================================
#pragma mark - APIs
//========================================================================================================================================

- (void)clearActionDictionary {
    [self.handlerDictionary removeAllObjects];
}

//designated setter
- (void)setLinkForRange:(NSRange)range withAttributes:(NSDictionary *)attributes andLinkHandler:(void (^)(ALHyperLabel *label, NSRange selectedRange))handler {
	NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc]initWithAttributedString:self.attributedText];
	
	if (attributes) {
		[mutableAttributedString addAttributes:attributes range:range];
	}
	
	if (handler) {
		[self.handlerDictionary setObject:handler forKey:[NSValue valueWithRange:range]];
	}
	
	self.attributedText = mutableAttributedString;
}

- (void)setLinkForRange:(NSRange)range withLinkHandler:(void(^)(ALHyperLabel *label, NSRange selectedRange))handler {
	[self setLinkForRange:range withAttributes:self.linkAttributeDefault andLinkHandler:handler];
}

- (void)setLinkForSubstring:(NSString *)substring withAttribute:(NSDictionary *)attribute andLinkHandler:(void(^)(ALHyperLabel *label, NSString *substring))handler {
	NSRange range = [self.attributedText.string rangeOfString:substring];
	if (range.length){
        [self setLinkForRange:range withAttributes:attribute andLinkHandler:^(ALHyperLabel *label, NSRange range){
			handler(label, [label.attributedText.string substringWithRange:range]);
		}];
	}
}

- (void)setLinkForSubstring:(NSString *)substring withLinkHandler:(void(^)(ALHyperLabel *label, NSString *substring))handler {
	[self setLinkForSubstring:substring withAttribute:self.linkAttributeDefault andLinkHandler:handler];
}

- (void)setLinksForSubstrings:(NSArray *)linkStrings withLinkHandler:(void(^)(ALHyperLabel *label, NSString *substring))handler {
	for (NSString *linkString in linkStrings) {
		[self setLinkForSubstring:linkString withLinkHandler:handler];
	}
}

//========================================================================================================================================
#pragma mark - Event Handler
//========================================================================================================================================

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	self.backupAttributedText = self.attributedText;
	for (UITouch *touch in touches) {
		CGPoint touchPoint = [touch locationInView:self];
		NSValue *rangeValue = [self attributedTextRangeForPoint:touchPoint];
        if (rangeValue)
        {
			NSRange range = [rangeValue rangeValue];
			NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc]initWithAttributedString:self.attributedText];
			[attributedString addAttributes:self.linkAttributeHighlight range:range];
			
			[UIView transitionWithView:self duration:highLightAnimationTime options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
				self.attributedText = attributedString;
			} completion:nil];
		}
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[UIView transitionWithView:self duration:highLightAnimationTime options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
		self.attributedText = self.backupAttributedText;
	} completion:nil];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[UIView transitionWithView:self duration:highLightAnimationTime options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
		self.attributedText = self.backupAttributedText;
	} completion:nil];
	
	for (UITouch *touch in touches) {
		NSValue *rangeValue = [self attributedTextRangeForPoint:[touch locationInView:self]];
		if (rangeValue) {
			void(^handler)(ALHyperLabel *label, NSRange selectedRange) = self.handlerDictionary[rangeValue];
			handler(self, [rangeValue rangeValue]);
		}
	}
}

//========================================================================================================================================
#pragma mark - Substring Locator
//========================================================================================================================================

- (NSValue *)attributedTextRangeForPoint:(CGPoint)point
{
	NSLayoutManager *layoutManager = [NSLayoutManager new];
	NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeZero];
	
	textContainer.lineFragmentPadding = 0.0;
	textContainer.lineBreakMode = self.lineBreakMode;
	textContainer.maximumNumberOfLines = self.numberOfLines;
	textContainer.size = self.bounds.size;
	[layoutManager addTextContainer:textContainer];
	
	//textStorage to calculate the position
	NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:self.attributedText];
	[textStorage addLayoutManager:layoutManager];
	
	// find the tapped character location and compare it to the specified range
	CGPoint locationOfTouchInLabel = point;
	CGRect textBoundingBox = [layoutManager usedRectForTextContainer:textContainer];
	CGPoint textContainerOffset = CGPointMake((CGRectGetWidth(self.bounds) - CGRectGetWidth(textBoundingBox)) * 0.5 - CGRectGetMinX(textBoundingBox),
											  (CGRectGetHeight(self.bounds) - CGRectGetHeight(textBoundingBox)) * 0.5 - CGRectGetMinY(textBoundingBox));
	CGPoint locationOfTouchInTextContainer = CGPointMake(locationOfTouchInLabel.x - textContainerOffset.x, locationOfTouchInLabel.y - textContainerOffset.y);
	NSInteger indexOfCharacter = [layoutManager characterIndexForPoint:locationOfTouchInTextContainer inTextContainer:textContainer fractionOfDistanceBetweenInsertionPoints:nil];
	
	for (NSValue *rangeValue in self.handlerDictionary) {
		NSRange range = [rangeValue rangeValue];
		if (NSLocationInRange(indexOfCharacter, range)) {
			return rangeValue;
		}
	}
	
	return nil;
}


//-(void)setText:(NSString *)text
//{
//    [super setText:text];
//    
//    if (text == nil) {
//        return;
//    }
//    
//    _isTruncated = [self checkTruncation];
//    @try
//    {
//        if (_isTruncated) {
//            NSMutableAttributedString* attributedString = [[NSMutableAttributedString alloc] initWithString:self.text];
//            [attributedString setAttributes:@{NSFontAttributeName:self.font}
//                                      range:NSMakeRange(0, self.attributedText.length-_truncationString.length)];
//            [attributedString setAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue-CondensedBold" size:self.font.pointSize],
//                                              NSForegroundColorAttributeName:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.3]}
//                                      range:NSMakeRange(self.attributedText.length-_truncationString.length, _truncationString.length)];
//            [self setAttributedText:attributedString];
//        }
//    }
//    @catch (NSException *exception) //NSRangeException
//    {
//        return;
//    }
//}
//
//-(BOOL)checkTruncation
//{
//    BOOL isTruncated = NO;
//    BOOL wasAdjustsFontSizeToFitWidth = self.adjustsFontSizeToFitWidth;
//    
//    CGFloat fontSize = self.font.pointSize;
//    
//    float height = self.frame.size.height;
//    
//    if (self.adjustsFontSizeToFitWidth) {
//        [self setFont:[UIFont fontWithName:self.font.fontName size:fontSize * self.minimumScaleFactor]]; //set to smallest font
//        [self setAdjustsFontSizeToFitWidth:NO];
//    }
//    
//    float fitHeight = [self sizeThatFits:self.frame.size].height;
//    
//    if ([self sizeThatFits:self.frame.size].height >= height && _truncationString.length > 0) {
//        NSString* fullText = self.text;
//        [super setText:@""];
//        int i = 0;
//        
//        NSString* lastGoodText;
//        
//        while ((fitHeight = [self sizeThatFits:self.frame.size].height) <= height && i < fullText.length) {
//            isTruncated = YES;
//            NSString* shorterText = self.text;
//            
//            shorterText = [fullText substringToIndex:i];
//            shorterText = [NSString stringWithFormat:@"%@%@", shorterText, _truncationString];
//            lastGoodText = self.text;
//            [super setText:shorterText];
//            
//            i += kCharacterSkipLength;
//        }
//        [super setText:lastGoodText];
//        
//    }
//    
//    if ((fitHeight / (self.minimumScaleFactor*fontSize)) > 3.0) {// if more that ~3 lines align left
//        [self setTextAlignment:NSTextAlignmentNatural];
//    }else{
//        [self setTextAlignment:NSTextAlignmentCenter];
//    }
//    
//    [self setAdjustsFontSizeToFitWidth:wasAdjustsFontSizeToFitWidth];
//    if (isTruncated == NO) {
//        [self setFont:[UIFont fontWithName:self.font.fontName size:fontSize]];
//    }
//    
//    return isTruncated;
//}

@end
