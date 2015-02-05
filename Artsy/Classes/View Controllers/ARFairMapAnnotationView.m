#import "ARFairMapAnnotationView.h"

@interface ARFairMapAnnotationView ()
@property (nonatomic, weak) UIImageView *mapFeatureView;
@property (nonatomic, strong) UILabel *primaryTitleLabel;
@property (nonatomic, strong) UIView *borderView;
@property (nonatomic, assign) BOOL reducedToPoint;
@property (nonatomic, assign) CGPoint mapPositioningPoint;
@property (nonatomic, copy) NSArray *positionConstraints;
@end

@implementation ARFairMapAnnotationView

static CGFloat ARHorizontalOffsetFromIcon = 4;

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _reducedToPoint = NO;
    }
    return self;
}

- (id)initWithMapView:(NAMapView *)mapView forAnnotation:(ARFairMapAnnotation *)annotation
{
    self = [super init];
    if (self) {
        _mapView = mapView;
        _annotation = annotation;
    }
    return self;
}


- (void)setDisplayTitle:(NSString *)title
{
    if(! self.primaryTitleLabel){
        UILabel *primaryTitleLabel = [[UILabel alloc] init];
        primaryTitleLabel.font = [UIFont sansSerifFontWithSize:8];
        primaryTitleLabel.preferredMaxLayoutWidth = 90;
        self.primaryTitleLabel = primaryTitleLabel;
        [self addSubview:primaryTitleLabel];
        [primaryTitleLabel alignTopEdgeWithView:self predicate:nil];
        [primaryTitleLabel alignAttribute:NSLayoutAttributeLeading toAttribute:NSLayoutAttributeTrailing ofView:self.mapFeatureView predicate:NSStringWithFormat(@"%f", ARHorizontalOffsetFromIcon)];
        [primaryTitleLabel constrainHeightToView:self.mapFeatureView predicate:nil];
    }

    self.primaryTitleLabel.text = self.hasLabel ? [title uppercaseString] : @"";
    _displayTitle = title;
}

// draw a red border around the current view
- (void)addBorder
{
    if (!self.borderView) {
        CGRect primaryRect = CGRectUnion(self.bounds, self.primaryTitleLabel.frame);
        UIView *borderView = [[UIView alloc] initWithFrame:primaryRect];
        borderView.layer.borderColor = [UIColor redColor].CGColor;
        borderView.layer.borderWidth = 1.0f;
        [self addSubview:borderView];
        _borderView = borderView;
    }
}

- (void)setMapFeatureType:(enum ARMapFeatureType)mapFeatureType
{
    _mapFeatureType = mapFeatureType;

    if(! self.mapFeatureView) {
        UIImageView *mapFeatureView = [[UIImageView alloc] init];
        mapFeatureView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:mapFeatureView];
        [mapFeatureView alignTopEdgeWithView:self predicate:nil];
        [mapFeatureView alignLeadingEdgeWithView:self predicate:nil];
        self.mapFeatureView = mapFeatureView;
        self.clipsToBounds = NO;
    }

    NSString *mapFeatureTypeString = NSStringFromARMapFeatureType(mapFeatureType) ?: @"GenericEvent";
    self.mapFeatureView.image = [UIImage imageNamed:NSStringWithFormat(@"MapAnnotation_%@", mapFeatureTypeString)];

    CGFloat dimension = self.mapFeatureView.image.size.height / 2;
    self.mapPositioningPoint = CGPointMake(dimension, dimension);
}

// TODO This is called a lot when zooming. Use relative positioning so that position is maintained as zoom level changes?
//
- (void)updatePosition
{
    CGPoint point = [self.mapView zoomRelativePoint:self.annotation.point];
    point.x -= self.mapPositioningPoint.x;
    point.y -= self.mapPositioningPoint.x;

    // TODO These constraints are added to the superview, it feels bad to modify these here. What’s the suggested approach?
    if (self.positionConstraints) {
      [self.superview removeConstraints:self.positionConstraints];
    }
    NSMutableArray *constraints = [NSMutableArray new];
    // TODO Is leading guaranteed to be appropriate for locale-independent code? (Frame code.)
    [constraints addObjectsFromArray:[self alignLeadingEdgeWithView:self.superview predicate:[NSString stringWithFormat:@"%f", point.x]]];
    [constraints addObjectsFromArray:[self alignTopEdgeWithView:self.superview predicate:[NSString stringWithFormat:@"%f", point.y]]];
    self.positionConstraints = constraints;
}

- (CGRect)boundingFrame
{
    CGRect primaryRect = CGRectNull;
    if ([self hasLabel]) {
        primaryRect = CGRectUnion(self.bounds, self.primaryTitleLabel.frame);
    } else {
        primaryRect = self.bounds;
    }
    return (CGRect){
        .origin = self.frame.origin,
        .size = CGSizeMake(primaryRect.size.width, primaryRect.size.height)
    };
}

- (void)reduceToPoint
{
    if (self.mapFeatureType == ARMapFeatureTypeHighlighted) {
        return;
    }

    if (self.mapFeatureType != ARMapFeatureTypeDefault) {
        self.primaryTitleLabel.hidden = YES;
    } else {
        self.hidden = YES;
    }

    _reducedToPoint = YES;
}

- (void)expandToFull
{
    self.frame = self.boundingFrame;
    if (self.mapFeatureType && self.mapFeatureType != ARMapFeatureTypeDefault) {
        self.primaryTitleLabel.hidden = NO;
    } else {
        self.hidden = NO;
    }

    _reducedToPoint = NO;
}

- (BOOL)hasLabel
{
    return self.mapFeatureType != ARMapFeatureTypeEntrance
        && self.mapFeatureType != ARMapFeatureTypeCoatCheck
        && self.mapFeatureType != ARMapFeatureTypeExit
        && self.mapFeatureType != ARMapFeatureTypeTicket;
}

- (BOOL)isUserInteractionAlwaysEnabled
{
    return self.mapFeatureType == ARMapFeatureTypeHighlighted
        || self.mapFeatureType == ARMapFeatureTypeSaved
        || self.mapFeatureType == ARMapFeatureTypeArtsy;
}

@end
