#import "YSIFLYNativeViewController.h"

#import "YSIFLYADUtil.h"
#import <YSIFLYADLib/YSIFLYADLib.h>

@interface YSIFLYNativeViewController () <YSIFLYNativeFeedAdDelegate>

@property (nonatomic, strong) YSIFLYNativeFeedAd *nativeAd;
@property (nonatomic, strong) UISegmentedControl *slotControl;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIView *adContainer;
@property (nonatomic, strong) UIView *mediaContainer;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) UILabel *sourceLabel;
@property (nonatomic, strong) UIButton *ctaButton;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UITextView *logView;

@end

@implementation YSIFLYNativeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"自渲染信息流";
    self.view.backgroundColor = UIColor.whiteColor;
    [self setupUI];
    [self log:@"信息流示例：Load -> 媒体渲染素材 -> bindAdWithViewBinder"];
}

- (void)dealloc {
    [self.nativeAd ysifly_destroy];
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

    self.slotControl = [[UISegmentedControl alloc] initWithItems:@[@"图文", @"视频"]];
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
    y += 290;

    UILabel *logTitle = [YSIFLYADUtil createSectionTitleWithText:@"回调日志"
                                                         frame:CGRectMake(margin, y, contentWidth, 18)];
    [self.view addSubview:logTitle];
    y += 22;

    CGFloat logHeight = MAX(170, self.view.bounds.size.height - y - 24);
    self.logView = [YSIFLYADUtil createLogTextViewWithFrame:CGRectMake(margin, y, contentWidth, logHeight)];
    [self.view addSubview:self.logView];
    [self resetAdCard];
}

- (void)buildNativeAdCardAtY:(CGFloat)y contentWidth:(CGFloat)contentWidth margin:(CGFloat)margin {
    self.adContainer = [[UIView alloc] initWithFrame:CGRectMake(margin, y, contentWidth, 274)];
    self.adContainer.backgroundColor = UIColor.whiteColor;
    self.adContainer.layer.cornerRadius = 8;
    self.adContainer.layer.borderColor = [UIColor colorWithWhite:0.86 alpha:1.0].CGColor;
    self.adContainer.layer.borderWidth = 1;
    self.adContainer.clipsToBounds = YES;
    [self.view addSubview:self.adContainer];

    self.mediaContainer = [[UIView alloc] initWithFrame:CGRectMake(12, 12, contentWidth - 24, 150)];
    self.mediaContainer.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.mediaContainer.layer.cornerRadius = 6;
    self.mediaContainer.clipsToBounds = YES;
    [self.adContainer addSubview:self.mediaContainer];

    self.imageView = [[UIImageView alloc] initWithFrame:self.mediaContainer.bounds];
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = YES;
    [self.mediaContainer addSubview:self.imageView];

    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 174, contentWidth - 64, 22)];
    self.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.titleLabel.textColor = UIColor.labelColor;
    [self.adContainer addSubview:self.titleLabel];

    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.closeButton.frame = CGRectMake(contentWidth - 44, 170, 32, 32);
    [self.closeButton setTitle:@"×" forState:UIControlStateNormal];
    self.closeButton.titleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightRegular];
    [self.adContainer addSubview:self.closeButton];

    self.descLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 202, contentWidth - 24, 36)];
    self.descLabel.font = [UIFont systemFontOfSize:13];
    self.descLabel.textColor = UIColor.secondaryLabelColor;
    self.descLabel.numberOfLines = 2;
    [self.adContainer addSubview:self.descLabel];

    self.sourceLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 242, 120, 22)];
    self.sourceLabel.font = [UIFont systemFontOfSize:12];
    self.sourceLabel.textColor = UIColor.secondaryLabelColor;
    [self.adContainer addSubview:self.sourceLabel];

    self.ctaButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.ctaButton.frame = CGRectMake(contentWidth - 110, 238, 98, 30);
    self.ctaButton.backgroundColor = UIColor.blackColor;
    self.ctaButton.layer.cornerRadius = 6;
    self.ctaButton.clipsToBounds = YES;
    self.ctaButton.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    [self.ctaButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self.adContainer addSubview:self.ctaButton];
}

- (void)ysifly_loadAd {
    [self destroyAdSilently];
    [self resetAdCard];

    NSString *adUnitId = self.slotControl.selectedSegmentIndex == 1 ? __FEED_VIDEO_AD_UNIT_ID__ : __TYPED_ONE_NATIVE_AD_UNIT_ID__;
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
    [self updateStatus:@"已销毁" color:UIColor.systemTealColor];
    [self log:@"Destroy"];
}

- (void)destroyAdSilently {
    if (!self.nativeAd) {
        return;
    }
    self.nativeAd.delegate = nil;
    [self.nativeAd ysifly_destroy];
    self.nativeAd = nil;
}

- (void)resetAdCard {
    for (UIView *subview in [self.mediaContainer.subviews copy]) {
        if (subview != self.imageView) {
            [subview removeFromSuperview];
        }
    }
    self.imageView.hidden = NO;
    self.imageView.image = nil;
    self.titleLabel.text = @"广告标题";
    self.descLabel.text = @"广告描述";
    self.sourceLabel.text = @"广告";
    [self.ctaButton setTitle:@"查看详情" forState:UIControlStateNormal];
}

- (void)renderAndBindAd:(YSIFLYNativeFeedAd *)ad {
    YSIFLYNativeFeedAdData *data = ad.adData;
    self.titleLabel.text = data.title.length > 0 ? data.title : @"广告标题";
    self.descLabel.text = data.desc.length > 0 ? data.desc : (data.content.length > 0 ? data.content : @"广告描述");
    self.sourceLabel.text = data.sponsored.length > 0 ? data.sponsored : (data.appName.length > 0 ? data.appName : @"广告");
    [self.ctaButton setTitle:data.actionText.length > 0 ? data.actionText : @"查看详情" forState:UIControlStateNormal];

    [self log:[NSString stringWithFormat:@"素材 materialType=%ld title=%@", (long)data.materialType, data.title ?: @"无"]];
    if (ad.hasVideoTemplate) {
        self.imageView.hidden = YES;
        UILabel *placeholder = [[UILabel alloc] initWithFrame:self.mediaContainer.bounds];
        placeholder.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        placeholder.text = @"视频广告区域";
        placeholder.textAlignment = NSTextAlignmentCenter;
        placeholder.textColor = UIColor.secondaryLabelColor;
        [self.mediaContainer addSubview:placeholder];
        [self bindNativeAd:ad video:YES];
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
                                    self.imageView.image = image;
                                    [self log:@"图片素材已渲染，开始绑定"];
                                    [self bindNativeAd:ad video:NO];
                                } else {
                                    [self log:[NSString stringWithFormat:@"图片加载失败：%@", error.localizedDescription ?: @"未知"]];
                                    [self updateStatus:@"图片加载失败，未绑定广告" color:UIColor.systemRedColor];
                                }
                            }];
}

- (void)bindNativeAd:(YSIFLYNativeFeedAd *)ad video:(BOOL)isVideo {
    YSIFLYNativeFeedAdViewBinder *binder = [[YSIFLYNativeFeedAdViewBinder alloc] init];
    binder.containerView = self.adContainer;
    binder.renderViews = @[self.mediaContainer, self.titleLabel, self.descLabel, self.ctaButton];
    binder.clickViews = @[self.mediaContainer, self.ctaButton];
    binder.closeView = self.closeButton;
    binder.videoView = isVideo ? self.mediaContainer : nil;
    binder.titleView = self.titleLabel;
    binder.descView = self.descLabel;
    binder.imageView = self.imageView;
    binder.ctaView = self.ctaButton;

    YSIFLYAdError *error = nil;
    BOOL success = [ad ysifly_bindAdWithViewBinder:binder error:&error];
    [self log:[NSString stringWithFormat:@"bindAdWithViewBinder success=%@ %@", success ? @"YES" : @"NO",
                                      error ? [YSIFLYADUtil summaryForError:error] : @""]];
    if (!success) {
        [self updateStatus:@"信息流绑定失败" color:UIColor.systemRedColor];
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
    [self log:[NSString stringWithFormat:@"nativeFeedAdDidLoad materialType=%ld ecpm=%.2f",
                                      (long)ad.materialType,
                                      [ad ecpm]]];
    if (ad != self.nativeAd) {
        return;
    }
    [self updateStatus:@"加载成功，媒体侧开始渲染" color:UIColor.systemIndigoColor];
    [self renderAndBindAd:ad];
}

- (void)ysifly_nativeFeedAdDidRender:(YSIFLYNativeFeedAd *)ad {
    [self log:@"nativeFeedAdDidRender"];
    [self updateStatus:@"绑定成功，等待曝光" color:UIColor.systemGreenColor];
    if (ad == self.nativeAd && ad.hasVideoTemplate) {
        [ad ysifly_startPlay];
        [self log:@"视频信息流调用 ysifly_startPlay"];
    }
}

- (void)ysifly_nativeFeedAdDidExpose:(YSIFLYNativeFeedAd *)ad {
    [self log:@"nativeFeedAdDidExpose"];
    [self updateStatus:@"信息流已曝光" color:UIColor.systemGreenColor];
}

- (void)ysifly_nativeFeedAdDidClick:(YSIFLYNativeFeedAd *)ad {
    [self log:@"nativeFeedAdDidClick"];
}

- (void)ysifly_nativeFeedAdDidClose:(YSIFLYNativeFeedAd *)ad {
    [self log:@"nativeFeedAdDidClose"];
    [self updateStatus:@"信息流已关闭" color:UIColor.systemTealColor];
    if (ad == self.nativeAd) {
        [self destroyAdSilently];
        [self resetAdCard];
    }
}

- (void)ysifly_nativeFeedAd:(YSIFLYNativeFeedAd *)ad didFailWithError:(YSIFLYAdError *)error {
    [self log:[NSString stringWithFormat:@"nativeFeedAd didFailWithError %@", [YSIFLYADUtil summaryForError:error]]];
    [self updateStatus:@"信息流加载失败" color:UIColor.systemRedColor];
}

- (void)ysifly_nativeFeedAd:(YSIFLYNativeFeedAd *)ad didFailToRenderWithError:(YSIFLYAdError *)error {
    [self log:[NSString stringWithFormat:@"nativeFeedAd didFailToRender %@", [YSIFLYADUtil summaryForError:error]]];
    [self updateStatus:@"信息流渲染失败" color:UIColor.systemRedColor];
}

- (void)ysifly_nativeFeedAdDidStartPlay:(YSIFLYNativeFeedAd *)ad {
    [self log:@"nativeFeedAdDidStartPlay"];
}

- (void)ysifly_nativeFeedAdDidPlayFinish:(YSIFLYNativeFeedAd *)ad {
    [self log:@"nativeFeedAdDidPlayFinish"];
}

- (void)ysifly_nativeFeedAd:(YSIFLYNativeFeedAd *)ad didFailToPlayWithError:(YSIFLYAdError *)error {
    [self log:[NSString stringWithFormat:@"nativeFeedAd didFailToPlay %@", [YSIFLYADUtil summaryForError:error]]];
}

- (void)ysifly_nativeFeedAd:(YSIFLYNativeFeedAd *)ad didJumpWithSuccess:(BOOL)success {
    [self log:[NSString stringWithFormat:@"nativeFeedAd didJumpWithSuccess=%@", success ? @"YES" : @"NO"]];
}

@end
