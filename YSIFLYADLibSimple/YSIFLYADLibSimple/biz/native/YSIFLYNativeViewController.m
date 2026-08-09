#import "YSIFLYNativeViewController.h"

#import "YSIFLYADUtil.h"
#import <YSIFLYADLib/YSIFLYADLib.h>

static NSInteger const YSNativeFeedDemoAdRow = 4;
static NSInteger const YSNativeFeedDemoRowCount = 16;
static NSString *const YSNativeFeedDemoContentCellIdentifier = @"ys-native-feed-content";
static NSString *const YSNativeFeedDemoAdCellIdentifier = @"ys-native-feed-ad";
static NSString *const YSNativeFeedDemoAdItemIdentifier = @"ys-native-feed-stable-ad-item";

typedef void (^YSNativeFeedDemoRenderCompletion)(BOOL ready, NSString *_Nullable failureReason);

/// 列表数据层中的逻辑广告条目。stableIdentifier 不随 Cell 复用变化；媒体只持有 Ad，
/// SDK 在 Ad 内部托管展示会话、绑定句柄和复用代次。
@interface YSNativeFeedDemoItem : NSObject

@property (nonatomic, copy) NSString *stableIdentifier;
@property (nonatomic, strong, nullable) YSIFLYNativeFeedAd *ad;
@property (nonatomic, assign) NSUInteger generation;

- (instancetype)initWithStableIdentifier:(NSString *)stableIdentifier;

@end

@implementation YSNativeFeedDemoItem

- (instancetype)initWithStableIdentifier:(NSString *)stableIdentifier {
    self = [super init];
    if (self) {
        _stableIdentifier = [stableIdentifier copy];
    }
    return self;
}

@end

/// 可复用的广告 Cell。Cell 只负责渲染 UI、生成 Binder，并在离屏/复用时按容器反注册；
/// 不保存 Session、Binding 或首次/复用状态。
@interface YSNativeFeedDemoTableViewCell : UITableViewCell

- (void)renderAd:(YSIFLYNativeFeedAd *)ad completion:(YSNativeFeedDemoRenderCompletion)completion;
- (YSIFLYNativeFeedAdViewBinder *)viewBinderForAd:(YSIFLYNativeFeedAd *)ad;
- (void)detachAdFromContainer;
- (void)updateVideoMessage:(NSString *)message visible:(BOOL)visible;

@end

@interface YSNativeFeedDemoTableViewCell ()

@property (nonatomic, assign) NSUInteger renderGeneration;
@property (nonatomic, strong) UIView *adContainer;
@property (nonatomic, strong) UIView *videoView;
@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, strong) UIImageView *singleImageView;
@property (nonatomic, copy) NSArray<UIImageView *> *multipleImageViews;
@property (nonatomic, strong) UILabel *adBadgeLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) UIButton *ctaButton;
@property (nonatomic, strong) UIButton *closeButton;

@end


@implementation YSNativeFeedDemoTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self ys_demoConfigureCell];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self ys_demoConfigureCell];
    }
    return self;
}

- (void)ys_demoConfigureCell {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = UIColor.whiteColor;

    self.adContainer = [[UIView alloc] initWithFrame:CGRectZero];
    self.adContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.adContainer.backgroundColor = UIColor.whiteColor;
    self.adContainer.layer.cornerRadius = 8;
    self.adContainer.layer.borderColor = [UIColor colorWithWhite:0.86 alpha:1.0].CGColor;
    self.adContainer.layer.borderWidth = 1;
    self.adContainer.clipsToBounds = YES;
    [self.contentView addSubview:self.adContainer];

    UILayoutGuide *margins = self.contentView.layoutMarginsGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.adContainer.leadingAnchor constraintEqualToAnchor:margins.leadingAnchor],
        [self.adContainer.trailingAnchor constraintEqualToAnchor:margins.trailingAnchor],
        [self.adContainer.topAnchor constraintEqualToAnchor:margins.topAnchor],
        [self.adContainer.bottomAnchor constraintEqualToAnchor:margins.bottomAnchor],
    ]];

    self.videoView = [[UIView alloc] initWithFrame:CGRectZero];
    self.videoView.backgroundColor = [UIColor colorWithRed:0.11 green:0.12 blue:0.14 alpha:1.0];
    self.videoView.layer.cornerRadius = 6;
    self.videoView.clipsToBounds = YES;
    [self.adContainer addSubview:self.videoView];

    self.placeholderLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.placeholderLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.placeholderLabel.textAlignment = NSTextAlignmentCenter;
    self.placeholderLabel.textColor = [UIColor colorWithWhite:0.65 alpha:1.0];
    self.placeholderLabel.font = [UIFont systemFontOfSize:14];
    [self.videoView addSubview:self.placeholderLabel];

    self.singleImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.singleImageView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.singleImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.singleImageView.clipsToBounds = YES;
    self.singleImageView.layer.cornerRadius = 6;
    [self.adContainer addSubview:self.singleImageView];

    NSMutableArray<UIImageView *> *multipleImageViews = [NSMutableArray arrayWithCapacity:3];
    for (NSUInteger index = 0; index < 3; index++) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        imageView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        imageView.layer.cornerRadius = 6;
        [self.adContainer addSubview:imageView];
        [multipleImageViews addObject:imageView];
    }
    self.multipleImageViews = multipleImageViews;

    self.adBadgeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.adBadgeLabel.textAlignment = NSTextAlignmentCenter;
    self.adBadgeLabel.textColor = UIColor.whiteColor;
    self.adBadgeLabel.font = [UIFont systemFontOfSize:10];
    self.adBadgeLabel.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.45];
    self.adBadgeLabel.layer.cornerRadius = 4;
    self.adBadgeLabel.clipsToBounds = YES;
    [self.adContainer addSubview:self.adBadgeLabel];

    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.closeButton.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.45];
    self.closeButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    [self.closeButton setTitle:@"×" forState:UIControlStateNormal];
    [self.closeButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self.adContainer addSubview:self.closeButton];

    self.ctaButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.ctaButton.backgroundColor = UIColor.systemBlueColor;
    self.ctaButton.layer.cornerRadius = 5;
    self.ctaButton.clipsToBounds = YES;
    self.ctaButton.titleLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    [self.ctaButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self.adContainer addSubview:self.ctaButton];

    self.descLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.descLabel.font = [UIFont systemFontOfSize:13];
    self.descLabel.textColor = UIColor.darkGrayColor;
    self.descLabel.numberOfLines = 1;
    self.descLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.adContainer addSubview:self.descLabel];

    [self ys_demoResetCard];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat width = CGRectGetWidth(self.adContainer.bounds);
    if (width <= 0) {
        return;
    }
    CGFloat padding = 12;
    CGFloat mediaWidth = width - padding * 2;
    CGFloat mediaHeight = 170;
    CGRect mediaFrame = CGRectMake(padding, padding, mediaWidth, mediaHeight);
    self.videoView.frame = mediaFrame;
    self.placeholderLabel.frame = self.videoView.bounds;
    self.singleImageView.frame = mediaFrame;

    CGFloat imageGap = 4;
    CGFloat imageWidth = floor((mediaWidth - imageGap * 2) / 3.0);
    for (NSUInteger index = 0; index < self.multipleImageViews.count; index++) {
        CGFloat x = padding + (imageWidth + imageGap) * index;
        CGFloat itemWidth = index == self.multipleImageViews.count - 1
                                ? CGRectGetMaxX(mediaFrame) - x
                                : imageWidth;
        self.multipleImageViews[index].frame = CGRectMake(x, padding, itemWidth, mediaHeight);
    }

    CGFloat rowY = CGRectGetMaxY(mediaFrame) + 10;
    CGFloat rowHeight = 28;
    CGFloat badgeWidth = 42;
    CGFloat badgeHeight = 20;
    CGFloat closeSide = 28;
    CGFloat gap = 8;
    self.adBadgeLabel.frame = CGRectMake(padding,
                                         rowY + (rowHeight - badgeHeight) * 0.5,
                                         badgeWidth,
                                         badgeHeight);
    self.closeButton.frame = CGRectMake(width - padding - closeSide, rowY, closeSide, closeSide);
    self.closeButton.layer.cornerRadius = closeSide * 0.5;

    CGFloat ctaWidth = 72;
    self.ctaButton.frame = CGRectMake(CGRectGetMinX(self.closeButton.frame) - gap - ctaWidth,
                                      rowY + 2,
                                      ctaWidth,
                                      rowHeight - 4);
    CGFloat descX = CGRectGetMaxX(self.adBadgeLabel.frame) + gap;
    CGFloat descRight = self.ctaButton.hidden ? CGRectGetMinX(self.closeButton.frame)
                                              : CGRectGetMinX(self.ctaButton.frame);
    self.descLabel.frame = CGRectMake(descX, rowY, MAX(0, descRight - gap - descX), rowHeight);
}

- (void)renderAd:(YSIFLYNativeFeedAd *)ad completion:(YSNativeFeedDemoRenderCompletion)completion {
    // 可见行 reload 可能不会先触发 prepareForReuse。必须在改写媒体子视图前按容器反注册，
    // 避免上一条广告的手势、曝光或播放器继续作用于新 UI。
    [self detachAdFromContainer];
    NSUInteger generation = self.renderGeneration;

    YSIFLYNativeFeedAdData *data = ad.adData;
    if (!data || ![data ysifly_isMaterialComplete] ||
        data.materialType == YSIFLYNativeFeedAdMaterialTypeUnknown) {
        if (completion) {
            completion(NO, @"素材不完整或类型未知");
        }
        return;
    }

    BOOL clickable = [self ys_demoIsClickableData:data];
    self.adBadgeLabel.hidden = NO;
    self.adBadgeLabel.text = data.adSourceMark.length > 0 ? data.adSourceMark : @"广告";
    self.closeButton.hidden = NO;
    NSString *primaryText = data.appName.length > 0 ? data.appName
                                                    : (data.title.length > 0 ? data.title : data.brand);
    NSString *secondaryText = data.desc.length > 0 ? data.desc : data.content;
    self.descLabel.text = primaryText.length > 0 && secondaryText.length > 0
                              ? [NSString stringWithFormat:@"%@ · %@", primaryText, secondaryText]
                              : (primaryText.length > 0
                                     ? primaryText
                                     : (secondaryText.length > 0 ? secondaryText : @"广告"));
    self.ctaButton.hidden = !clickable;
    [self.ctaButton setTitle:(clickable ? (data.ctaText.length > 0 ? data.ctaText : @"查看详情") : nil)
                    forState:UIControlStateNormal];
    [self setNeedsLayout];

    if (data.materialType == YSIFLYNativeFeedAdMaterialTypeVideo) {
        self.videoView.hidden = NO;
        self.placeholderLabel.hidden = NO;
        self.placeholderLabel.text = @"视频等待曝光后自动播放";
        if (completion) {
            completion(YES, nil);
        }
        return;
    }

    NSArray<NSString *> *imageURLs = data.imageURLs;
    if (data.materialType == YSIFLYNativeFeedAdMaterialTypeSingleImage) {
        NSString *imageURL = imageURLs.firstObject;
        self.videoView.hidden = NO;
        self.placeholderLabel.hidden = NO;
        self.placeholderLabel.text = @"图片加载中…";
        __weak typeof(self) weakSelf = self;
        [YSIFLYADUtil loadImageWithURLString:imageURL
                                  completion:^(UIImage *image, NSError *error) {
                                      __strong typeof(weakSelf) self = weakSelf;
                                      if (!self || self.renderGeneration != generation) {
                                          return;
                                      }
                                      if (!image) {
                                          if (completion) {
                                              completion(NO, error.localizedDescription ?: @"图片加载失败");
                                          }
                                          return;
                                      }
                                      self.videoView.hidden = YES;
                                      self.placeholderLabel.hidden = YES;
                                      self.singleImageView.image = image;
                                      self.singleImageView.hidden = NO;
                                      if (completion) {
                                          completion(YES, nil);
                                      }
                                  }];
        return;
    }

    NSUInteger imageCount = MIN(imageURLs.count, self.multipleImageViews.count);
    if (imageCount < 2) {
        if (completion) {
            completion(NO, @"多图素材不足两张");
        }
        return;
    }

    self.videoView.hidden = NO;
    self.placeholderLabel.hidden = NO;
    self.placeholderLabel.text = @"多图加载中…";
    dispatch_group_t group = dispatch_group_create();
    __block NSUInteger loadedCount = 0;
    __weak typeof(self) weakSelf = self;
    for (NSUInteger index = 0; index < imageCount; index++) {
        dispatch_group_enter(group);
        [YSIFLYADUtil loadImageWithURLString:imageURLs[index]
                                  completion:^(UIImage *image, NSError *error) {
                                      (void)error;
                                      __strong typeof(weakSelf) self = weakSelf;
                                      if (self && self.renderGeneration == generation && image) {
                                          UIImageView *imageView = self.multipleImageViews[index];
                                          imageView.image = image;
                                          imageView.hidden = NO;
                                          loadedCount += 1;
                                      }
                                      dispatch_group_leave(group);
                                  }];
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.renderGeneration != generation) {
            return;
        }
        if (loadedCount < 2) {
            if (completion) {
                completion(NO, @"多图成功图片不足两张");
            }
            return;
        }
        self.videoView.hidden = YES;
        self.placeholderLabel.hidden = YES;
        if (completion) {
            completion(YES, nil);
        }
    });
}

- (YSIFLYNativeFeedAdViewBinder *)viewBinderForAd:(YSIFLYNativeFeedAd *)ad {
    YSIFLYNativeFeedAdData *data = ad.adData;
    BOOL video = data.materialType == YSIFLYNativeFeedAdMaterialTypeVideo;
    BOOL multipleImages = data.materialType == YSIFLYNativeFeedAdMaterialTypeMultipleImages;
    BOOL clickable = [self ys_demoIsClickableData:data];

    NSMutableArray<UIView *> *mediaViews = [NSMutableArray array];
    if (video) {
        [mediaViews addObject:self.videoView];
    } else if (multipleImages) {
        for (UIImageView *imageView in self.multipleImageViews) {
            if (!imageView.hidden && imageView.image) {
                [mediaViews addObject:imageView];
            }
        }
    } else {
        [mediaViews addObject:self.singleImageView];
    }

    YSIFLYNativeFeedAdViewBinder *binder = [[YSIFLYNativeFeedAdViewBinder alloc] init];
    binder.containerView = self.adContainer;
    NSMutableArray<UIView *> *renderViews = [mediaViews mutableCopy];
    [renderViews addObjectsFromArray:@[self.adBadgeLabel, self.descLabel, self.closeButton]];
    if (clickable) {
        [renderViews addObject:self.ctaButton];
    }
    binder.renderViews = renderViews;
    // nil 会回退为整容器可点击；Exposure / Unknown 必须显式传空数组。
    if (clickable) {
        NSMutableArray<UIView *> *clickViews = [mediaViews mutableCopy];
        [clickViews addObject:self.ctaButton];
        binder.clickViews = clickViews;
    } else {
        binder.clickViews = @[];
    }
    binder.closeView = self.closeButton;
    binder.videoView = video ? self.videoView : nil;
    binder.imageView = video ? nil : (UIImageView *)mediaViews.firstObject;
    binder.descView = self.descLabel;
    binder.adSourceView = self.adBadgeLabel;
    binder.ctaView = clickable ? self.ctaButton : nil;
    return binder;
}

- (void)detachAdFromContainer {
    self.renderGeneration += 1;
    [YSIFLYNativeFeedAd ysifly_detachAdFromContainerView:self.adContainer];
    [self ys_demoResetVisuals];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self detachAdFromContainer];
}

- (void)updateVideoMessage:(NSString *)message visible:(BOOL)visible {
    self.placeholderLabel.text = message;
    self.placeholderLabel.hidden = !visible;
}

- (BOOL)ys_demoIsClickableData:(YSIFLYNativeFeedAdData *)data {
    return data.interactionType == YSIFLYNativeFeedAdInteractionTypeRedirect ||
           data.interactionType == YSIFLYNativeFeedAdInteractionTypeDownload;
}

- (void)ys_demoResetCard {
    self.renderGeneration += 1;
    [self ys_demoResetVisuals];
}

- (void)ys_demoResetVisuals {
    // SDK 的透明播放器宿主由容器级 detach 清理；媒体只清自己的图片和文案。
    self.videoView.hidden = NO;
    self.placeholderLabel.hidden = NO;
    self.placeholderLabel.text = @"等待加载广告";
    self.singleImageView.hidden = YES;
    self.singleImageView.image = nil;
    for (UIImageView *imageView in self.multipleImageViews) {
        imageView.hidden = YES;
        imageView.image = nil;
    }
    self.adBadgeLabel.hidden = YES;
    self.adBadgeLabel.text = @"广告";
    self.descLabel.text = @"";
    self.ctaButton.hidden = YES;
    [self.ctaButton setTitle:nil forState:UIControlStateNormal];
    self.closeButton.hidden = YES;
    [self setNeedsLayout];
}

@end


@interface YSIFLYNativeViewController ()
    <UITableViewDataSource, UITableViewDelegate, YSIFLYNativeFeedAdDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISegmentedControl *slotControl;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UITextView *logView;
@property (nonatomic, strong) YSNativeFeedDemoItem *adItem;
@property (nonatomic, assign) NSUInteger loadGeneration;
@property (nonatomic, weak, nullable) YSNativeFeedDemoTableViewCell *visibleAdCell;
@property (nonatomic, weak, nullable) YSNativeFeedDemoTableViewCell *attachedAdCell;
@property (nonatomic, copy, nullable) NSString *visibleAdItemIdentifier;

- (void)startLoadingAdItem;
- (BOOL)attachCurrentAdToCell:(YSNativeFeedDemoTableViewCell *)cell;
- (void)continueDisplayingAdItemAfterCellDetached;
- (void)retireCurrentAdItem;

@end


@implementation YSIFLYNativeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"信息流列表复用";
    self.view.backgroundColor = UIColor.whiteColor;
    self.adItem = [[YSNativeFeedDemoItem alloc] initWithStableIdentifier:YSNativeFeedDemoAdItemIdentifier];
    [self setupUI];
    [self log:@"稳定广告条目：数据层只持有 Ad，SDK 托管 Session / Binding 与复用代次"];
}

- (void)dealloc {
    [self retireCurrentAdItem];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.adItem.ad.hasVideoTemplate) {
        [self.adItem.ad ysifly_pausePlay];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.adItem.ad.hasVideoTemplate && self.visibleAdCell) {
        [self.adItem.ad ysifly_resumePlay];
    }
}

- (void)setupUI {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 64;
    [self.tableView registerClass:UITableViewCell.class
           forCellReuseIdentifier:YSNativeFeedDemoContentCellIdentifier];
    [self.tableView registerClass:YSNativeFeedDemoTableViewCell.class
           forCellReuseIdentifier:YSNativeFeedDemoAdCellIdentifier];
    [self.view addSubview:self.tableView];

    CGFloat margin = 16;
    CGFloat width = CGRectGetWidth(self.view.bounds);
    CGFloat contentWidth = width - margin * 2;
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 256)];

    UILabel *desc = [YSIFLYADUtil
        createSectionTitleWithText:@"向下滚动让广告 Cell 离屏，再滚回：同一稳定条目会恢复原广告，曝光前后均可复用。"
                             frame:CGRectMake(margin, 12, contentWidth, 38)];
    [header addSubview:desc];

    self.slotControl = [[UISegmentedControl alloc] initWithItems:@[@"单图", @"多图", @"视频"]];
    self.slotControl.frame = CGRectMake(margin, 58, contentWidth, 32);
    self.slotControl.selectedSegmentIndex = 0;
    [header addSubview:self.slotControl];

    CGFloat buttonWidth = (contentWidth - 8) / 2.0;
    UIButton *loadButton = [YSIFLYADUtil createADTypeButtonWithFrame:CGRectMake(margin, 100, buttonWidth, 42)
                                                              title:@"加载 / 换一条"
                                                             target:self
                                                             action:@selector(reloadAdItem)];
    [header addSubview:loadButton];

    UIButton *destroyButton = [YSIFLYADUtil
        createADTypeButtonWithFrame:CGRectMake(margin + buttonWidth + 8, 100, buttonWidth, 42)
                              title:@"永久淘汰"
                             target:self
                             action:@selector(destroyAdItem)];
    destroyButton.backgroundColor = UIColor.systemRedColor;
    [header addSubview:destroyButton];

    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin, 150, contentWidth, 22)];
    self.statusLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    self.statusLabel.textColor = UIColor.systemBlueColor;
    self.statusLabel.text = @"广告行进入屏幕时自动加载";
    [header addSubview:self.statusLabel];

    self.logView = [YSIFLYADUtil createLogTextViewWithFrame:CGRectMake(margin, 180, contentWidth, 64)];
    [header addSubview:self.logView];
    self.tableView.tableHeaderView = header;
}

- (void)reloadAdItem {
    [self retireCurrentAdItem];
    [self startLoadingAdItem];
}

- (void)destroyAdItem {
    [self retireCurrentAdItem];
    [self updateStatus:@"逻辑广告条目已永久淘汰" color:[YSIFLYADUtil demoTealColor]];
    [self log:@"容器 ysifly_detachAdFromContainerView: → 释放最后一个 Ad 强引用（ysifly_destroy 可选）"];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return YSNativeFeedDemoRowCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == YSNativeFeedDemoAdRow) {
        return [tableView dequeueReusableCellWithIdentifier:YSNativeFeedDemoAdCellIdentifier
                                               forIndexPath:indexPath];
    }

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:YSNativeFeedDemoContentCellIdentifier
                                                            forIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"内容行 %ld", (long)indexPath.row + 1];
    cell.textLabel.textColor = [YSIFLYADUtil demoSecondaryLabelColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row == YSNativeFeedDemoAdRow ? 250 : 64;
}

- (void)tableView:(UITableView *)tableView
 willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row != YSNativeFeedDemoAdRow ||
        ![cell isKindOfClass:YSNativeFeedDemoTableViewCell.class]) {
        return;
    }

    YSNativeFeedDemoTableViewCell *adCell = (YSNativeFeedDemoTableViewCell *)cell;
    self.visibleAdCell = adCell;
    self.visibleAdItemIdentifier = self.adItem.stableIdentifier;

    YSIFLYNativeFeedAd *ad = self.adItem.ad;
    if (ad.adData) {
        // SDK 处理同 Ad 迁移、同容器幂等和 UIKit 新旧 Cell 回调乱序；媒体无需判断首次/复用。
        [self attachCurrentAdToCell:adCell];
        return;
    }

    if (!ad) {
        [self startLoadingAdItem];
    }
}

- (void)tableView:(UITableView *)tableView
didEndDisplayingCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![cell isKindOfClass:YSNativeFeedDemoTableViewCell.class]) {
        return;
    }

    YSNativeFeedDemoTableViewCell *adCell = (YSNativeFeedDemoTableViewCell *)cell;
    [adCell detachAdFromContainer];
    if (self.attachedAdCell == adCell) {
        self.attachedAdCell = nil;
    }
    if (self.visibleAdCell == adCell) {
        self.visibleAdCell = nil;
        self.visibleAdItemIdentifier = nil;
    }

    // UIKit 可能先回调新 Cell 的 willDisplay，再回调旧 Cell 的 didEndDisplaying。
    // 旧容器真正反注册后，再对仍可见的新 Cell 重试；媒体不保存 Binding 或首次/复用状态。
    [self continueDisplayingAdItemAfterCellDetached];
}

#pragma mark - Logical ad item lifecycle

- (void)startLoadingAdItem {
    if (self.adItem.ad) {
        return;
    }

    NSString *adUnitId = __TYPED_ONE_NATIVE_AD_UNIT_ID__;
    if (self.slotControl.selectedSegmentIndex == 1) {
        adUnitId = __TYPED_MORE_NATIVE_AD_UNIT_ID__;
    } else if (self.slotControl.selectedSegmentIndex == 2) {
        adUnitId = __FEED_VIDEO_AD_UNIT_ID__;
    }

    self.loadGeneration += 1;
    self.adItem.generation = self.loadGeneration;
    YSIFLYNativeFeedAd *ad = [[YSIFLYNativeFeedAd alloc] initWithAdUnitId:adUnitId];
    self.adItem.ad = ad;
    ad.delegate = self;
    ad.currentViewController = self;
    ad.muteOnStart = YES;

    [self updateStatus:@"正在加载稳定广告条目" color:UIColor.systemBlueColor];
    [self log:[NSString stringWithFormat:@"Load generation=%lu adUnitId=%@",
                                         (unsigned long)self.adItem.generation,
                                         adUnitId]];
    [ad ysifly_loadAdWithRequestConfig:[YSIFLYADUtil mediaSampleRequestConfig]];
}

- (BOOL)attachCurrentAdToCell:(YSNativeFeedDemoTableViewCell *)cell {
    YSNativeFeedDemoItem *item = self.adItem;
    YSIFLYNativeFeedAd *ad = item.ad;
    if (!cell || !ad || !ad.adData) {
        return NO;
    }
    if (self.attachedAdCell == cell) {
        return YES;
    }

    NSUInteger generation = item.generation;
    __weak typeof(self) weakSelf = self;
    __weak typeof(cell) weakCell = cell;
    __weak YSIFLYNativeFeedAd *weakAd = ad;
    [cell renderAd:ad
        completion:^(BOOL ready, NSString *failureReason) {
            __strong typeof(weakSelf) self = weakSelf;
            __strong typeof(weakCell) cell = weakCell;
            YSIFLYNativeFeedAd *ad = weakAd;
            if (!self || !cell || self.adItem != item || self.adItem.ad != ad ||
                self.adItem.generation != generation ||
                self.visibleAdCell != cell ||
                ![self.visibleAdItemIdentifier isEqualToString:item.stableIdentifier]) {
                return;
            }

            if (!ready) {
                [self log:[NSString stringWithFormat:@"媒体渲染失败：%@", failureReason ?: @"未知"]];
                [cell detachAdFromContainer];
                if (self.attachedAdCell && self.attachedAdCell != cell) {
                    [self updateStatus:@"等待旧广告容器离屏" color:[YSIFLYADUtil demoIndigoColor]];
                    return;
                }
                [self updateStatus:@"素材渲染失败" color:UIColor.systemRedColor];
                [self retireCurrentAdItem];
                return;
            }

            YSIFLYAdError *error = nil;
            BOOL attached = [ad ysifly_attachWithViewBinder:[cell viewBinderForAd:ad]
                                                      error:&error];
            if (!attached) {
                // attach 可能同步触发 delegate；先确认失败仍属于当前代次，再处理。
                if (self.adItem != item || self.adItem.ad != ad || self.adItem.generation != generation) {
                    return;
                }
                [self log:[NSString stringWithFormat:@"attach 失败 %@",
                                                   [YSIFLYADUtil summaryForError:error]]];
                [cell detachAdFromContainer];
                if (self.attachedAdCell && self.attachedAdCell != cell) {
                    [self updateStatus:@"等待旧广告容器离屏" color:[YSIFLYADUtil demoIndigoColor]];
                    return;
                }
                BOOL expired = error.errorCode == YSIFLYAdErrorCodeNativeFeedAdExpired;
                BOOL invalidAd = ![ad ysifly_isAdValid];
                [self retireCurrentAdItem];
                if ((expired || invalidAd) && self.visibleAdCell == cell) {
                    [self log:@"旧容器已反注册；过期广告释放后请求替换广告"];
                    [self startLoadingAdItem];
                } else {
                    [self updateStatus:@"信息流挂载失败" color:UIColor.systemRedColor];
                }
                return;
            }

            if (self.visibleAdCell != cell || self.adItem != item || self.adItem.ad != ad ||
                self.adItem.generation != generation) {
                [cell detachAdFromContainer];
                return;
            }
            self.attachedAdCell = cell;
            [self updateStatus:@"SDK 托管挂载成功" color:UIColor.systemGreenColor];
            [self log:[NSString stringWithFormat:@"attach success generation=%lu（首次/复用无需媒体判断）",
                                               (unsigned long)generation]];
        }];
    return YES;
}

- (void)continueDisplayingAdItemAfterCellDetached {
    YSNativeFeedDemoTableViewCell *visibleCell = self.visibleAdCell;
    YSNativeFeedDemoItem *item = self.adItem;
    if (!visibleCell || !item.ad || !item.ad.adData ||
        ![self.visibleAdItemIdentifier isEqualToString:item.stableIdentifier]) {
        return;
    }
    [self attachCurrentAdToCell:visibleCell];
}

- (void)retireCurrentAdItem {
    YSIFLYNativeFeedAd *ad = self.adItem.ad;
    if (!ad) {
        return;
    }

    self.loadGeneration += 1;
    self.adItem.generation = self.loadGeneration;
    self.adItem.ad = nil;

    YSNativeFeedDemoTableViewCell *attachedCell = self.attachedAdCell;
    YSNativeFeedDemoTableViewCell *visibleCell = self.visibleAdCell;
    self.attachedAdCell = nil;
    if (attachedCell) {
        [attachedCell detachAdFromContainer];
    }
    if (visibleCell && visibleCell != attachedCell) {
        [visibleCell detachAdFromContainer];
    }
    ad.delegate = nil;
    // 正常永久淘汰只需释放最后一个 Ad 强引用；仍要暂存 Ad 却需提前终止时才调用 ysifly_destroy。
}

#pragma mark - Status and logs

- (void)updateStatus:(NSString *)text color:(UIColor *)color {
    self.statusLabel.text = text;
    self.statusLabel.textColor = color;
}

- (void)log:(NSString *)text {
    [YSIFLYADUtil appendLog:text toTextView:self.logView];
    YSIFLYSampleLogInfo(@"NativeFeedList", @"%@", text);
}

#pragma mark - YSIFLYNativeFeedAdDelegate

- (void)ysifly_nativeFeedAdDidLoad:(YSIFLYNativeFeedAd *)ad {
    if (ad != self.adItem.ad) {
        return;
    }

    [self log:[NSString stringWithFormat:@"didLoad generation=%lu materialType=%ld %@",
                                         (unsigned long)self.adItem.generation,
                                         (long)ad.materialType,
                                         [YSIFLYADUtil bidInfoSummaryForAd:ad]]];
    [self updateStatus:@"广告已加载，等待广告 Cell" color:[YSIFLYADUtil demoIndigoColor]];
    YSNativeFeedDemoTableViewCell *visibleCell = self.visibleAdCell;
    if (visibleCell) {
        [self attachCurrentAdToCell:visibleCell];
    }
}

- (void)ysifly_nativeFeedAdDidRender:(YSIFLYNativeFeedAd *)ad {
    if (ad == self.adItem.ad) {
        [self log:@"nativeFeedAdDidRender"];
    }
}

- (void)ysifly_nativeFeedAdDidExpose:(YSIFLYNativeFeedAd *)ad {
    if (ad == self.adItem.ad) {
        [self log:@"nativeFeedAdDidExpose（同一逻辑广告仅一次）"];
        [self updateStatus:@"信息流已曝光" color:UIColor.systemGreenColor];
    }
}

- (void)ysifly_nativeFeedAdDidClick:(YSIFLYNativeFeedAd *)ad {
    if (ad == self.adItem.ad) {
        [self log:@"nativeFeedAdDidClick"];
    }
}

- (void)ysifly_nativeFeedAdDidClose:(YSIFLYNativeFeedAd *)ad {
    if (ad != self.adItem.ad) {
        return;
    }
    [self log:@"nativeFeedAdDidClose"];
    [self retireCurrentAdItem];
    [self updateStatus:@"信息流已关闭" color:[YSIFLYADUtil demoTealColor]];
}

- (void)ysifly_nativeFeedAd:(YSIFLYNativeFeedAd *)ad didFailWithError:(YSIFLYAdError *)error {
    if (ad != self.adItem.ad) {
        return;
    }
    [self log:[NSString stringWithFormat:@"nativeFeedAd didFailWithError %@",
                                           [YSIFLYADUtil summaryForError:error]]];
    [self updateStatus:@"信息流加载失败" color:UIColor.systemRedColor];
    [self retireCurrentAdItem];
}

- (void)ysifly_nativeFeedAd:(YSIFLYNativeFeedAd *)ad
 didFailToRenderWithError:(YSIFLYAdError *)error {
    if (ad == self.adItem.ad) {
        [self log:[NSString stringWithFormat:@"nativeFeedAd didFailToRender %@",
                                               [YSIFLYADUtil summaryForError:error]]];
    }
}

- (void)ysifly_nativeFeedAdDidStartPlay:(YSIFLYNativeFeedAd *)ad {
    if (ad == self.adItem.ad && self.visibleAdCell) {
        [self.visibleAdCell updateVideoMessage:@"视频播放中" visible:NO];
        [self log:@"nativeFeedAdDidStartPlay"];
    }
}

- (void)ysifly_nativeFeedAdDidPausePlay:(YSIFLYNativeFeedAd *)ad {
    if (ad == self.adItem.ad && self.visibleAdCell) {
        [self.visibleAdCell updateVideoMessage:@"视频已暂停" visible:YES];
        [self log:@"nativeFeedAdDidPausePlay"];
    }
}

- (void)ysifly_nativeFeedAdDidResumePlay:(YSIFLYNativeFeedAd *)ad {
    if (ad == self.adItem.ad && self.visibleAdCell) {
        [self.visibleAdCell updateVideoMessage:@"视频播放中" visible:NO];
        [self log:@"nativeFeedAdDidResumePlay"];
    }
}

- (void)ysifly_nativeFeedAdDidPlayFinish:(YSIFLYNativeFeedAd *)ad {
    if (ad == self.adItem.ad && self.visibleAdCell) {
        [self.visibleAdCell updateVideoMessage:@"视频播放完成" visible:YES];
        [self log:@"nativeFeedAdDidPlayFinish"];
    }
}

- (void)ysifly_nativeFeedAd:(YSIFLYNativeFeedAd *)ad
 didFailToPlayWithError:(YSIFLYAdError *)error {
    if (ad == self.adItem.ad && self.visibleAdCell) {
        [self.visibleAdCell updateVideoMessage:@"视频播放失败" visible:YES];
        [self log:[NSString stringWithFormat:@"nativeFeedAd didFailToPlay %@",
                                               [YSIFLYADUtil summaryForError:error]]];
    }
}

- (void)ysifly_nativeFeedAd:(YSIFLYNativeFeedAd *)ad didJumpWithSuccess:(BOOL)success {
    if (ad == self.adItem.ad) {
        [self log:[NSString stringWithFormat:@"nativeFeedAd didJumpWithSuccess=%@",
                                               success ? @"YES" : @"NO"]];
    }
}

@end
