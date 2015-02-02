//
//  LYRUIMessageBubbleView.m
//  LayerUIKit
//
//  Created by Kevin Coleman on 9/8/14.
//
//

#import "LYRUIMessageBubbleView.h"
#import "LYRUIMessagingUtilities.h"
#import "LYRUIProgressView.h"

CGFloat const LYRUIMessageBubbleLabelHorizontalPadding = 12;
CGFloat const LYRUIMessageBubbleLabelVerticalPadding = 8;
CGFloat const LYRUIMessageBubbleMapWidth = 200;
CGFloat const LYRUIMessageBubbleMapHeight = 200;

NSString *const LYRUIUserDidTapLinkNotification = @"LYRUIUserDidTapLinkNotification";

@interface LYRUIMessageBubbleView () <UIGestureRecognizerDelegate>

@property (nonatomic) LYRUIProgressView *progressView;
@property (nonatomic) UIView *longPressMask;
@property (nonatomic) MKMapSnapshotter *snapshotter;
@property (nonatomic) CLLocationCoordinate2D locationShown;
@property (nonatomic) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic) NSURL *tappedURL;
@property (nonatomic) NSLayoutConstraint *imageWidthConstraint;

@end

@implementation LYRUIMessageBubbleView 

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _locationShown = kCLLocationCoordinate2DInvalid;
        self.clipsToBounds = YES;
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.bubbleViewLabel = [[UILabel alloc] init];
        self.bubbleViewLabel.numberOfLines = 0;
        self.bubbleViewLabel.userInteractionEnabled = YES;
        self.bubbleViewLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.bubbleViewLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh + 1 forAxis:UILayoutConstraintAxisHorizontal];
        [self addSubview:self.bubbleViewLabel];
        
        self.bubbleImageView = [[UIImageView alloc] init];
        self.bubbleImageView.translatesAutoresizingMaskIntoConstraints = NO;
        self.bubbleImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:self.bubbleImageView];
        
        self.progressView = [[LYRUIProgressView alloc] initWithFrame:CGRectMake(0, 0, 128.0f, 128.0f)];
        self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
        self.progressView.alpha = 1.0f;
        [self addSubview:self.progressView];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.bubbleViewLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:LYRUIMessageBubbleLabelVerticalPadding]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.bubbleViewLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:LYRUIMessageBubbleLabelHorizontalPadding]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.bubbleViewLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:-LYRUIMessageBubbleLabelHorizontalPadding]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.bubbleViewLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-LYRUIMessageBubbleLabelVerticalPadding]];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.bubbleImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.bubbleImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.bubbleImageView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.bubbleImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
        self.imageWidthConstraint = [NSLayoutConstraint constraintWithItem:self.bubbleImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:0];
        [self addConstraint:self.imageWidthConstraint];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.progressView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.progressView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.progressView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:64.0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.progressView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:64.0]];
        
        self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleLabelTap:)];
        self.tapGestureRecognizer.delegate = self;
        [self.bubbleViewLabel addGestureRecognizer:self.tapGestureRecognizer];
        
        UILongPressGestureRecognizer *gestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [self addGestureRecognizer:gestureRecognizer];
    }
    return self;
}

- (void)updateActivityIndicatorWithProgress:(float)progress options:(LYRUIProgressViewOptions)options
{
    BOOL shouldBeVisible = (options & LYRUIProgressViewOptionShowProgress);
    NSLog(@"visible:%d progress:%.2f: %@", shouldBeVisible, progress, [NSThread callStackSymbols]);
    if (options & LYRUIProgressViewOptionAnimated) {
        [UIView animateWithDuration:0.50f animations:^{
            self.progressView.alpha = shouldBeVisible ? 1.0f : 0.0f;
        } completion:^(BOOL finished) {
        }];
    } else {
        self.progressView.alpha = shouldBeVisible ? 1.0f : 0.0f;
    }
    if (options & LYRUIProgressViewOptionButtonStyleNone) {
        self.progressView.iconStyle = LYRUIProgressViewIconStyleNone;
    } else if (options & LYRUIProgressViewOptionButtonStyleDownload) {
        self.progressView.iconStyle = LYRUIProgressViewIconStyleDownload;
    } else if (options & LYRUIProgressViewOptionButtonStylePlay) {
        self.progressView.iconStyle = LYRUIProgressViewIconStylePlay;
    } else if (options & LYRUIProgressViewOptionButtonStylePause) {
        self.progressView.iconStyle = LYRUIProgressViewIconStylePause;
    } else if (options & LYRUIProgressViewOptionButtonStyleStop) {
        self.progressView.iconStyle = LYRUIProgressViewIconStyleStop;
    }
    
    [self.progressView setProgress:progress animated:(options & LYRUIProgressViewOptionAnimated)];
}

- (void)updateWithAttributedText:(NSAttributedString *)text
{
    self.bubbleViewLabel.attributedText = text;
    if (self.imageWidthConstraint) [self removeConstraint:self.imageWidthConstraint];
    [self setContentType:LYRUIBubbleViewContentTypeText];
}

- (void)updateWithImage:(UIImage *)image width:(CGFloat)width
{
    self.bubbleImageView.image = image;
    self.imageWidthConstraint.constant = width;
    [self setContentType:LYRUIBubbleViewContentTypeImage];
}

- (void)updateWithLocation:(CLLocationCoordinate2D)location
{

    self.imageWidthConstraint.constant = LYRUIMaxCellWidth();
    [self setNeedsUpdateConstraints];
    
    BOOL alreadyShowingLocation = self.locationShown.latitude == location.latitude && self.locationShown.longitude == location.longitude;
    if (alreadyShowingLocation) {
        self.bubbleImageView.hidden = NO;
        return;
    }
    
    self.bubbleImageView.hidden = YES;
    self.bubbleImageView.image = nil;
    self.locationShown = kCLLocationCoordinate2DInvalid;
    
    MKMapSnapshotOptions *options = [[MKMapSnapshotOptions alloc] init];
    MKCoordinateSpan span = MKCoordinateSpanMake(0.005, 0.005);
    options.region = MKCoordinateRegionMake(location, span);
    options.scale = [UIScreen mainScreen].scale;
    options.size = CGSizeMake(200, 200);
    self.snapshotter = [[MKMapSnapshotter alloc] initWithOptions:options];
    
    __weak typeof(self) weakSelf = self;
    [self.snapshotter startWithCompletionHandler:^(MKMapSnapshot *snapshot, NSError *error) {
        typeof(self) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        if (error) {
            NSLog(@"Error generating map snapshot: %@", error);
            self.bubbleImageView.image = [UIImage imageNamed:@"LayerUIKitResource.bundle/warning-black"];
            self.bubbleImageView.contentMode = UIViewContentModeCenter;
        } else {
            self.bubbleImageView.contentMode = UIViewContentModeScaleAspectFill;
            // Create a pin image.
            MKAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:nil reuseIdentifier:@""];
            UIImage *pinImage = pin.image;
            
            // Draw the image.
            UIImage *image = snapshot.image;
            UIGraphicsBeginImageContextWithOptions(image.size, YES, image.scale);
            [image drawAtPoint:CGPointMake(0, 0)];
            
            // Draw the pin.
            CGPoint point = [snapshot pointForCoordinate:location];
            [pinImage drawAtPoint:CGPointMake(point.x, point.y - pinImage.size.height)];
            UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            // Set image.
            strongSelf.bubbleImageView.image = finalImage;
            strongSelf.locationShown = location;
        }
        strongSelf.bubbleImageView.hidden = NO;
        strongSelf.bubbleImageView.alpha = 0.0;
        
        // Animate into view.
        [UIView animateWithDuration:0.2 animations:^{
            strongSelf.bubbleImageView.alpha = 1.0;
        }];
    }];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer
{
    if ([recognizer state] == UIGestureRecognizerStateBegan) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(menuControllerDisappeared)
                                                     name:UIMenuControllerDidHideMenuNotification
                                                   object:nil];
        
        [self becomeFirstResponder];
        
        self.longPressMask = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        self.longPressMask.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.longPressMask.backgroundColor = [UIColor blackColor];
        self.longPressMask.alpha = 0.1;
        [self addSubview:self.longPressMask];
        
        UIMenuController *menuController = [UIMenuController sharedMenuController];
        UIMenuItem *resetMenuItem = [[UIMenuItem alloc] initWithTitle:@"Copy" action:@selector(copyItem)];
        [menuController setMenuItems:@[resetMenuItem]];
        [menuController setTargetRect:CGRectMake(self.frame.size.width / 2, 0.0f, 0.0f, 0.0f) inView:self];
        [menuController setMenuVisible:YES animated:YES];
    }
}

- (void)setBubbleViewContentType:(LYRUIBubbleViewContentType)contentType
{
    switch (contentType) {
        case LYRUIBubbleViewContentTypeText:
            self.bubbleImageView.hidden = YES;
            self.bubbleViewLabel.hidden = NO;
            self.bubbleImageView.image = nil;
            self.locationShown = kCLLocationCoordinate2DInvalid;
            [self.snapshotter cancel];
            
            break;
        case LYRUIBubbleViewContentTypeImage:
            self.bubbleViewLabel.hidden = YES;
            self.bubbleImageView.hidden = NO;
            self.locationShown = kCLLocationCoordinate2DInvalid;
            self.bubbleViewLabel.text = nil;
            [self.snapshotter cancel];
            break;
        case LYRUIBubbleViewContentTypeLocation:
            self.bubbleViewLabel.hidden = YES;
            self.bubbleViewLabel.text = nil;
            [self.snapshotter cancel];
            break;
        default:
            break;
    }
    [self setNeedsUpdateConstraints];
}

- (void)copyItem
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    if (!self.bubbleViewLabel.isHidden) {
        pasteboard.string = self.bubbleViewLabel.text;
    } else {
        pasteboard.image = self.bubbleImageView.image;
    }
}

- (void)menuControllerDisappeared
{
    [self.longPressMask removeFromSuperview];
    self.longPressMask = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer != self.tapGestureRecognizer) return YES;
    
    //http://stackoverflow.com/questions/21349725/character-index-at-touch-point-for-uilabel/26806991#26806991
    UILabel *textLabel = self.bubbleViewLabel;
    CGPoint tapLocation = [gestureRecognizer locationInView:textLabel];
    
    // init text storage
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:textLabel.attributedText];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    [textStorage addLayoutManager:layoutManager];
    
    // init text container
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:textLabel.frame.size];
    textContainer.lineFragmentPadding = 0;
    textContainer.maximumNumberOfLines = textLabel.numberOfLines;
    textContainer.lineBreakMode = textLabel.lineBreakMode;
    [layoutManager addTextContainer:textContainer];
    
    NSUInteger characterIndex = [layoutManager characterIndexForPoint:tapLocation
                                                      inTextContainer:textContainer
                             fractionOfDistanceBetweenInsertionPoints:NULL];
    NSArray *results = LYRUILinkResultsForText(self.bubbleViewLabel.attributedText.string);
    for (NSTextCheckingResult *result in results) {
        if (NSLocationInRange(characterIndex, result.range)) {
            self.tappedURL = result.URL;
            return YES;
        }
    }
    return NO;
}

#pragma mark - Actions

- (void)handleLabelTap:(UITapGestureRecognizer *)tapGestureRecognizer
{
    [[NSNotificationCenter defaultCenter] postNotificationName:LYRUIUserDidTapLinkNotification object:self.tappedURL];
    self.tappedURL = nil;
}

@end
