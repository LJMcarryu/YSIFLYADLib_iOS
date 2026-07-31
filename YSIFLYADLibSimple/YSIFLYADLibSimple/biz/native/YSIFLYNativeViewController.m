#import "YSIFLYNativeViewController.h"

#import "YSIFLYADUtil.h"
#import <YSIFLYADLib/YSIFLYADLib.h>

@interface YSIFLYNativeViewController () <YSIFLYNativeFeedAdDelegate>

@property (nonatomic, strong) YSIFLYNativeFeedAd *nativeAd;
@property (nonatomic, strong) UISegmentedControl *slotControl;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIView *adContainer;
@property (nonatomic, strong) UIView *videoView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, copy) NSArray<UIImageView *> *multiImageViews;
@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, strong) UILabel *adBadgeLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) UIButton *ctaButton;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UITextView *logView;

- (void)loadMultipleImagesAndBindAd:(YSIFLYNativeFeedAd *)ad;
- (void)bindNativeAd:(YSIFLYNativeFeedAd *)ad;

@end

@implementation YSIFLYNativeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"自渲染信息流示例";
    self.view.backgroundColor = UIColor.whiteColor;
    [self setupUI];
    [self log:@"自渲染信息流示例：Load -> 读取 adData -> 媒体渲染 -> Binder 绑定"];
}

- (void)dealloc {
    [self.nativeAd ysifly_unbindAd];
    self.nativeAd.delegate = nil;
    [self.nativeAd ysifly_destroy];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.nativeAd.hasVideoTemplate) {
        [self.nativeAd ysifly_pausePlay];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.nativeAd.hasVideoTemplate) {
        [self.nativeAd ysifly_resumePlay];
    }
}

- (void)setupUI {
    CGFloat margin = 16;
    CGFloat width = self.view.bounds.size.width;
    CGFloat contentWidth = width - margin * 2;
    CGFloat y = 100;

    UILabel *desc = [YSIFLYADUtil createSectionTitleWithText:@"媒体侧根据 adData 自行渲染 UI，然后通过 Binder 把容器、点击视图、关闭按钮和视频容器交给 SDK。"
                                                     frame:CGRectMake(margin, y, contentWidth, 42)];
    [self.view addSubview:desc];
    y += 54;

    self.slotControl = [[UISegmentedControl alloc] initWithItems:@[@"单图", @"多图", @"视频"]];
    self.slotControl.frame = CGRectMake(margin, y, contentWidth, 32);
    self.slotControl.selectedSegmentIndex = 0;
    [self.view addSubview:self.slotControl];
    y += 48;

    CGFloat buttonWidth = (contentWidth - 8) / 2.0;
    UIButton *loadButton = [YSIFLYADUtil createADTypeButtonWithFrame:CGRectMake(margin, y, buttonWidth, 44)
                                                            title:@"Load"
                                                           target:self
                                                           action:@selector(ysifly_loadAd)];
    [self.view addSubview:loadButton];

    UIButton *destroyButton = [YSIFLYADUtil createADTypeButtonWithFrame:CGRectMake(margin + buttonWidth + 8, y, buttonWidth, 44)
                                                                title:@"Destroy"
                                                               target:self
                                                               action:@selector(destroyAd)];
    destroyButton.backgroundColor = UIColor.systemRedColor;
    [self.view addSubview:destroyButton];
    y += 54;

    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin, y, contentWidth, 22)];
    self.statusLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    self.statusLabel.textColor = UIColor.systemBlueColor;
    self.statusLabel.text = @"等待加载";
    [self.view addSubview:self.statusLabel];
    y += 32;

    [self buildNativeAdCardAtY:y contentWidth:contentWidth margin:margin];
    y += 246;

    UILabel *logTitle = [YSIFLYADUtil createSectionTitleWithText:@"回调日志"
                                                         frame:CGRectMake(margin, y, contentWidth, 18)];
    [self.view addSubview:logTitle];
    y += 22;

    CGFloat logHeight = MAX(170, self.view.bounds.size.height - y - 24);
    self.logView = [YSIFLYADUtil createLogTextViewWithFrame:CGRectMake(margin, y, contentWidth, logHeight)];
    [self.view addSubview:self.logView];
    [self resetAdCard];
}

// 卡片布局参考私有库 Demo：深色媒体区（视频承载/图片叠加）+ 下方一行「广告角标 | 描述 | 圆形关闭」。
- (void)buildNativeAdCardAtY:(CGFloat)y contentWidth:(CGFloat)contentWidth margin:(CGFloat)margin {
    self.adContainer = [[UIView alloc] initWithFrame:CGRectMake(margin, y, contentWidth, 230)];
    self.adContainer.backgroundColor = UIColor.whiteColor;
    self.adContainer.layer.cornerRadius = 8;
    self.adContainer.layer.borderColor = [UIColor colorWithWhite:0.86 alpha:1.0].CGColor;
    self.adContainer.layer.borderWidth = 1;
    self.adContainer.clipsToBounds = YES;
    [self.view addSubview:self.adContainer];

    CGFloat padding = 12;
    CGFloat innerW = contentWidth - padding * 2;

    // 媒体区：视频素材承载视图（深色底），图片素材叠加同区域的 imageView
    self.videoView = [[UIView alloc] initWithFrame:CGRectMake(padding, padding, innerW, 170)];
    self.videoView.backgroundColor = [UIColor colorWithRed:0.11 green:0.12 blue:0.14 alpha:1.0];
    self.videoView.layer.cornerRadius = 6;
    self.videoView.clipsToBounds = YES;
    [self.adContainer addSubview:self.videoView];

    self.placeholderLabel = [[UILabel alloc] initWithFrame:self.videoView.bounds];
    self.placeholderLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.placeholderLabel.text = @"广告素材展示区域";
    self.placeholderLabel.textAlignment = NSTextAlignmentCenter;
    self.placeholderLabel.textColor = [UIColor colorWithWhite:0.55 alpha:1.0];
    self.placeholderLabel.font = [UIFont systemFontOfSize:14];
    [self.videoView addSubview:self.placeholderLabel];

    self.imageView = [[UIImageView alloc] initWithFrame:self.videoView.frame];
    self.imageView.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.96 alpha:1.0];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = YES;
    self.imageView.layer.cornerRadius = 6;
    self.imageView.hidden = YES;
    [self.adContainer addSubview:self.imageView];

    NSMutableArray<UIImageView *> *multiImageViews = [NSMutableArray arrayWithCapacity:3];
    CGFloat multiGap = 4;
    CGFloat multiWidth = floor((innerW - multiGap * 2) / 3.0);
    for (NSInteger index = 0; index < 3; index++) {
        CGFloat x = padding + (multiWidth + multiGap) * index;
        CGFloat itemWidth = index == 2 ? CGRectGetMaxX(self.videoView.frame) - x : multiWidth;
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(x, padding, itemWidth, 170)];
        imageView.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.96 alpha:1.0];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        imageView.layer.cornerRadius = 6;
        imageView.hidden = YES;
        [self.adContainer addSubview:imageView];
        [multiImageViews addObject:imageView];
    }
    self.multiImageViews = multiImageViews;

    CGFloat rowY = CGRectGetMaxY(self.videoView.frame) + 10;
    CGFloat rowH = 28;
    CGFloat badgeW = 40;
    CGFloat badgeH = 20;
    CGFloat closeSide = 28;
    CGFloat gap = 8;

    self.adBadgeLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding, rowY + (rowH - badgeH) * 0.5, badgeW, badgeH)];
    self.adBadgeLabel.text = @"广告";
    self.adBadgeLabel.textAlignment = NSTextAlignmentCenter;
    self.adBadgeLabel.textColor = UIColor.whiteColor;
    self.adBadgeLabel.font = [UIFont systemFontOfSize:10];
    self.adBadgeLabel.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.4];
    self.adBadgeLabel.layer.cornerRadius = 4;
    self.adBadgeLabel.clipsToBounds = YES;
    self.adBadgeLabel.hidden = YES;
    [self.adContainer addSubview:self.adBadgeLabel];

    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.closeButton.frame = CGRectMake(contentWidth - padding - closeSide, rowY, closeSide, closeSide);
    self.closeButton.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.4];
    self.closeButton.layer.cornerRadius = closeSide * 0.5;
    self.closeButton.clipsToBounds = YES;
    self.closeButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    [self.closeButton setTitle:@"×" forState:UIControlStateNormal];
    [self.closeButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self.adContainer addSubview:self.closeButton];

    CGFloat ctaWidth = 72;
    self.ctaButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.ctaButton.frame = CGRectMake(CGRectGetMinX(self.closeButton.frame) - gap - ctaWidth,
                                      rowY + 2,
                                      ctaWidth,
                                      rowH - 4);
    self.ctaButton.backgroundColor = UIColor.systemBlueColor;
    self.ctaButton.layer.cornerRadius = 5;
    self.ctaButton.clipsToBounds = YES;
    self.ctaButton.titleLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    [self.ctaButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.ctaButton.hidden = YES;
    [self.adContainer addSubview:self.ctaButton];

    CGFloat descX = CGRectGetMaxX(self.adBadgeLabel.frame) + gap;
    CGFloat descW = CGRectGetMinX(self.ctaButton.frame) - gap - descX;
    self.descLabel = [[UILabel alloc] initWithFrame:CGRectMake(descX, rowY, descW, rowH)];
    self.descLabel.font = [UIFont systemFontOfSize:13];
    self.descLabel.textColor = UIColor.darkGrayColor;
    self.descLabel.numberOfLines = 1;
    self.descLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.adContainer addSubview:self.descLabel];
}

- (void)ysifly_loadAd {
    [self destroyAdSilently];
    [self resetAdCard];

    NSString *adUnitId = __TYPED_ONE_NATIVE_AD_UNIT_ID__;
    if (self.slotControl.selectedSegmentIndex == 1) {
        adUnitId = __TYPED_MORE_NATIVE_AD_UNIT_ID__;
    } else if (self.slotControl.selectedSegmentIndex == 2) {
        adUnitId = __FEED_VIDEO_AD_UNIT_ID__;
    }
    [self updateStatus:@"正在加载信息流" color:UIColor.systemBlueColor];
    [self log:[NSString stringWithFormat:@"Load adUnitId=%@", adUnitId]];

    YSIFLYNativeFeedAd *ad = [[YSIFLYNativeFeedAd alloc] initWithAdUnitId:adUnitId];
    ad.delegate = self;
    ad.currentViewController = self;
    ad.muteOnStart = YES;
    self.nativeAd = ad;
    [ad ysifly_loadAdWithRequestConfig:[YSIFLYADUtil mediaSampleRequestConfig]];
}

- (void)destroyAd {
    [self destroyAdSilently];
    [self resetAdCard];
    [self updateStatus:@"已销毁" color:[YSIFLYADUtil demoTealColor]];
    [self log:@"Destroy"];
}

- (void)destroyAdSilently {
    YSIFLYNativeFeedAd *ad = self.nativeAd;
    if (!ad) {
        return;
    }
    self.nativeAd = nil;
    [ad ysifly_unbindAd];
    ad.delegate = nil;
    [ad ysifly_destroy];
}

- (void)resetAdCard {
    // 复位媒体区：移除视频承载视图里临时添加的子视图，保留占位标签
    for (UIView *subview in [self.videoView.subviews copy]) {
        if (subview != self.placeholderLabel) {
            [subview removeFromSuperview];
        }
    }
    self.videoView.hidden = NO;
    self.placeholderLabel.hidden = NO;
    self.placeholderLabel.text = @"广告素材展示区域";
    self.imageView.hidden = YES;
    self.imageView.image = nil;
    for (UIImageView *imageView in self.multiImageViews) {
        imageView.hidden = YES;
        imageView.image = nil;
    }
    self.adBadgeLabel.hidden = YES;
    self.descLabel.text = @"";
    self.ctaButton.hidden = YES;
    [self.ctaButton setTitle:nil forState:UIControlStateNormal];
    self.closeButton.hidden = YES;
}

- (void)renderAndBindAd:(YSIFLYNativeFeedAd *)ad {
    YSIFLYNativeFeedAdData *data = ad.adData;
    if (!data || ![data ysifly_isMaterialComplete] ||
        data.materialType == YSIFLYNativeFeedAdMaterialTypeUnknown) {
        [self log:@"素材不完整或类型未知，不渲染、不绑定"];
        [self updateStatus:@"素材不可用" color:UIColor.systemRedColor];
        [self destroyAdSilently];
        [self resetAdCard];
        return;
    }
    BOOL clickable =
        data.interactionType == YSIFLYNativeFeedAdInteractionTypeRedirect ||
        data.interactionType == YSIFLYNativeFeedAdInteractionTypeDownload;
    self.adBadgeLabel.hidden = NO;
    self.adBadgeLabel.text = data.adSourceMark.length > 0 ? data.adSourceMark : @"广告";
    self.closeButton.hidden = NO;
    NSString *primaryText = data.appName.length > 0 ? data.appName : (data.title.length > 0 ? data.title : data.brand);
    NSString *secondaryText = data.desc.length > 0 ? data.desc : data.content;
    self.descLabel.text = primaryText.length > 0 && secondaryText.length > 0
                              ? [NSString stringWithFormat:@"%@ · %@", primaryText, secondaryText]
                              : (primaryText.length > 0 ? primaryText : (secondaryText.length > 0 ? secondaryText : @"广告"));
    self.ctaButton.hidden = !clickable;
    [self.ctaButton setTitle:(clickable ? (data.ctaText.length > 0 ? data.ctaText : @"查看详情") : nil)
                    forState:UIControlStateNormal];

    [self log:[NSString stringWithFormat:
                        @"素材 creativeId=%@ templateId=%ld materialType=%ld interactionType=%ld interactType=%ld appName=%@ ctaText=%@",
                        data.creativeId ?: @"无",
                        (long)data.templateId,
                        (long)data.materialType,
                        (long)data.interactionType,
                        (long)data.interactType,
                        data.appName ?: @"无",
                        data.ctaText ?: @"无"]];
    switch (data.materialType) {
        case YSIFLYNativeFeedAdMaterialTypeVideo:
            self.imageView.hidden = YES;
            self.videoView.hidden = NO;
            self.placeholderLabel.hidden = NO;
            self.placeholderLabel.text = @"视频等待曝光后自动播放";
            [self bindNativeAd:ad];
            return;
        case YSIFLYNativeFeedAdMaterialTypeMultipleImages:
            [self loadMultipleImagesAndBindAd:ad];
            return;
        case YSIFLYNativeFeedAdMaterialTypeSingleImage:
            break;
        case YSIFLYNativeFeedAdMaterialTypeUnknown:
        default:
            return;
    }

    NSString *imageURL = data.imageURLs.firstObject;
    __weak typeof(self) weakSelf = self;
    [YSIFLYADUtil loadImageWithURLString:imageURL
                            completion:^(UIImage *image, NSError *error) {
                                __strong typeof(weakSelf) self = weakSelf;
                                if (!self || self.nativeAd != ad) {
                                    return;
                                }
                                if (image) {
                                    // 图文：图片素材覆盖媒体区，隐藏深色占位
                                    self.placeholderLabel.hidden = YES;
                                    self.videoView.hidden = YES;
                                    self.imageView.hidden = NO;
                                    self.imageView.image = image;
                                    [self log:@"单图素材已渲染，开始绑定"];
                                    [self bindNativeAd:ad];
                                } else {
                                    [self log:[NSString stringWithFormat:@"图片加载失败：%@", error.localizedDescription ?: @"未知"]];
                                    [self updateStatus:@"图片加载失败，未绑定广告" color:UIColor.systemRedColor];
                                    [self destroyAdSilently];
                                    [self resetAdCard];
                                }
                            }];
}

- (void)loadMultipleImagesAndBindAd:(YSIFLYNativeFeedAd *)ad {
    NSArray<NSString *> *allURLs = ad.adData.imageURLs;
    NSUInteger count = MIN(allURLs.count, self.multiImageViews.count);
    if (count < 2) {
        [self log:@"多图素材不足两张，不绑定"];
        [self destroyAdSilently];
        [self resetAdCard];
        return;
    }

    self.videoView.hidden = NO;
    self.placeholderLabel.hidden = NO;
    self.placeholderLabel.text = @"多图加载中...";
    dispatch_group_t group = dispatch_group_create();
    __block NSUInteger loadedCount = 0;
    __weak typeof(self) weakSelf = self;
    for (NSUInteger index = 0; index < count; index++) {
        dispatch_group_enter(group);
        [YSIFLYADUtil loadImageWithURLString:allURLs[index]
                                 completion:^(UIImage *image, NSError *error) {
                                     __strong typeof(weakSelf) self = weakSelf;
                                     if (self && self.nativeAd == ad && image) {
                                         UIImageView *imageView = self.multiImageViews[index];
                                         imageView.image = image;
                                         imageView.hidden = NO;
                                         loadedCount += 1;
                                     } else if (self && self.nativeAd == ad) {
                                         [self log:[NSString stringWithFormat:@"多图第 %lu 张加载失败：%@",
                                                                              (unsigned long)(index + 1),
                                                                              error.localizedDescription ?: @"未知"]];
                                     }
                                     dispatch_group_leave(group);
                                 }];
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.nativeAd != ad) {
            return;
        }
        if (loadedCount < 2) {
            [self log:@"多图成功图片不足两张，不绑定"];
            [self updateStatus:@"多图加载失败，未绑定广告" color:UIColor.systemRedColor];
            [self destroyAdSilently];
            [self resetAdCard];
            return;
        }
        self.placeholderLabel.hidden = YES;
        self.videoView.hidden = YES;
        [self log:[NSString stringWithFormat:@"多图素材已渲染 %lu 张，开始绑定", (unsigned long)loadedCount]];
        [self bindNativeAd:ad];
    });
}

- (void)bindNativeAd:(YSIFLYNativeFeedAd *)ad {
    YSIFLYNativeFeedAdData *data = ad.adData;
    BOOL isVideo = data.materialType == YSIFLYNativeFeedAdMaterialTypeVideo;
    BOOL isMultiple = data.materialType == YSIFLYNativeFeedAdMaterialTypeMultipleImages;
    NSMutableArray<UIView *> *multipleViews = [NSMutableArray array];
    if (isMultiple) {
        for (UIImageView *imageView in self.multiImageViews) {
            if (!imageView.hidden && imageView.image) {
                [multipleViews addObject:imageView];
            }
        }
    }
    NSArray<UIView *> *mediaViews = isVideo ? @[self.videoView] : (isMultiple ? multipleViews : @[self.imageView]);
    YSIFLYNativeFeedAdViewBinder *binder = [[YSIFLYNativeFeedAdViewBinder alloc] init];
    binder.containerView = self.adContainer;
    NSMutableArray<UIView *> *renderViews = [mediaViews mutableCopy];
    [renderViews addObjectsFromArray:@[self.adBadgeLabel, self.descLabel, self.closeButton]];
    BOOL clickable =
        data.interactionType == YSIFLYNativeFeedAdInteractionTypeRedirect ||
        data.interactionType == YSIFLYNativeFeedAdInteractionTypeDownload;
    if (clickable) {
        [renderViews addObject:self.ctaButton];
    }
    binder.renderViews = renderViews;
    // nil 会默认整容器可点击；纯曝光与未知行为必须显式传空数组。
    if (clickable) {
        NSMutableArray<UIView *> *clickViews = [mediaViews mutableCopy];
        [clickViews addObject:self.ctaButton];
        binder.clickViews = clickViews;
    } else {
        binder.clickViews = @[];
    }
    binder.closeView = self.closeButton;
    binder.videoView = isVideo ? self.videoView : nil;
    binder.imageView = isVideo ? nil : (UIImageView *)mediaViews.firstObject;
    binder.descView = self.descLabel;
    binder.adSourceView = self.adBadgeLabel;
    binder.ctaView = clickable ? self.ctaButton : nil;

    YSIFLYAdError *error = nil;
    BOOL success = [ad ysifly_bindAdWithViewBinder:binder error:&error];
    [self log:[NSString stringWithFormat:@"bindAdWithViewBinder success=%@ %@", success ? @"YES" : @"NO",
                                      error ? [YSIFLYADUtil summaryForError:error] : @""]];
    if (!success) {
        [self updateStatus:@"信息流绑定失败" color:UIColor.systemRedColor];
        [self destroyAdSilently];
        [self resetAdCard];
    }
}

- (void)updateStatus:(NSString *)text color:(UIColor *)color {
    self.statusLabel.text = text;
    self.statusLabel.textColor = color;
}

- (void)log:(NSString *)text {
    [YSIFLYADUtil appendLog:text toTextView:self.logView];
    YSIFLYSampleLogInfo(@"NativeFeed", @"%@", text);
}

#pragma mark - YSIFLYNativeFeedAdDelegate

- (void)ysifly_nativeFeedAdDidLoad:(YSIFLYNativeFeedAd *)ad {
    if (ad != self.nativeAd) {
        return;
    }
    [self log:[NSString stringWithFormat:@"nativeFeedAdDidLoad templateId=%ld materialType=%ld appName=%@ %@",
                                      (long)ad.adData.templateId,
                                      (long)ad.materialType,
                                      ad.adData.appName ?: @"无",
                                      [YSIFLYADUtil bidInfoSummaryForAd:ad]]];
    [self updateStatus:@"加载成功，媒体侧开始渲染" color:[YSIFLYADUtil demoIndigoColor]];
    [self renderAndBindAd:ad];
}

- (void)ysifly_nativeFeedAdDidRender:(YSIFLYNativeFeedAd *)ad {
    if (ad != self.nativeAd) {
        return;
    }
    [self log:@"nativeFeedAdDidRender"];
    [self updateStatus:@"绑定成功，等待曝光" color:UIColor.systemGreenColor];
    if (ad.hasVideoTemplate) {
        [self log:@"视频由 SDK 在达到曝光条件后自动播放"];
    }
}

- (void)ysifly_nativeFeedAdDidExpose:(YSIFLYNativeFeedAd *)ad {
    if (ad != self.nativeAd) {
        return;
    }
    [self log:@"nativeFeedAdDidExpose"];
    [self updateStatus:@"信息流已曝光" color:UIColor.systemGreenColor];
}

- (void)ysifly_nativeFeedAdDidClick:(YSIFLYNativeFeedAd *)ad {
    if (ad != self.nativeAd) {
        return;
    }
    [self log:@"nativeFeedAdDidClick"];
}

- (void)ysifly_nativeFeedAdDidClose:(YSIFLYNativeFeedAd *)ad {
    [self log:@"nativeFeedAdDidClose"];
    [self updateStatus:@"信息流已关闭" color:[YSIFLYADUtil demoTealColor]];
    if (ad == self.nativeAd) {
        [self destroyAdSilently];
        [self resetAdCard];
    }
}

- (void)ysifly_nativeFeedAd:(YSIFLYNativeFeedAd *)ad didFailWithError:(YSIFLYAdError *)error {
    if (ad != self.nativeAd) {
        return;
    }
    [self log:[NSString stringWithFormat:@"nativeFeedAd didFailWithError %@", [YSIFLYADUtil summaryForError:error]]];
    [self updateStatus:@"信息流加载失败" color:UIColor.systemRedColor];
    [self destroyAdSilently];
    [self resetAdCard];
}

- (void)ysifly_nativeFeedAd:(YSIFLYNativeFeedAd *)ad didFailToRenderWithError:(YSIFLYAdError *)error {
    if (ad != self.nativeAd) {
        return;
    }
    [self log:[NSString stringWithFormat:@"nativeFeedAd didFailToRender %@", [YSIFLYADUtil summaryForError:error]]];
    [self updateStatus:@"信息流渲染失败" color:UIColor.systemRedColor];
    [self destroyAdSilently];
    [self resetAdCard];
}

- (void)ysifly_nativeFeedAdDidStartPlay:(YSIFLYNativeFeedAd *)ad {
    if (ad != self.nativeAd) {
        return;
    }
    [self log:@"nativeFeedAdDidStartPlay"];
    self.placeholderLabel.hidden = YES;
}

- (void)ysifly_nativeFeedAdDidPausePlay:(YSIFLYNativeFeedAd *)ad {
    if (ad != self.nativeAd) {
        return;
    }
    [self log:@"nativeFeedAdDidPausePlay"];
    self.placeholderLabel.hidden = NO;
    self.placeholderLabel.text = @"视频已暂停";
}

- (void)ysifly_nativeFeedAdDidResumePlay:(YSIFLYNativeFeedAd *)ad {
    if (ad != self.nativeAd) {
        return;
    }
    [self log:@"nativeFeedAdDidResumePlay"];
    self.placeholderLabel.hidden = YES;
}

- (void)ysifly_nativeFeedAdDidPlayFinish:(YSIFLYNativeFeedAd *)ad {
    if (ad != self.nativeAd) {
        return;
    }
    [self log:@"nativeFeedAdDidPlayFinish"];
    self.placeholderLabel.hidden = NO;
    self.placeholderLabel.text = @"视频播放完成";
}

- (void)ysifly_nativeFeedAd:(YSIFLYNativeFeedAd *)ad didFailToPlayWithError:(YSIFLYAdError *)error {
    if (ad != self.nativeAd) {
        return;
    }
    [self log:[NSString stringWithFormat:@"nativeFeedAd didFailToPlay %@", [YSIFLYADUtil summaryForError:error]]];
    self.placeholderLabel.hidden = NO;
    self.placeholderLabel.text = @"视频播放失败";
}

- (void)ysifly_nativeFeedAd:(YSIFLYNativeFeedAd *)ad didJumpWithSuccess:(BOOL)success {
    if (ad != self.nativeAd) {
        return;
    }
    [self log:[NSString stringWithFormat:@"nativeFeedAd didJumpWithSuccess=%@", success ? @"YES" : @"NO"]];
}

@end
