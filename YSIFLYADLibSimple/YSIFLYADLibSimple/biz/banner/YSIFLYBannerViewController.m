#import "YSIFLYBannerViewController.h"

#import "YSIFLYADUtil.h"
#import <YSIFLYADLib/YSIFLYADLib.h>

@interface YSIFLYBannerViewController () <YSIFLYBannerAdDelegate>

@property (nonatomic, strong) YSIFLYBannerAd *bannerAd;
@property (nonatomic, strong) UIView *bannerContainer;
@property (nonatomic, strong) UIButton *showButton;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UITextView *logView;

@end

@implementation YSIFLYBannerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Banner 广告";
    self.view.backgroundColor = UIColor.whiteColor;
    [self setupUI];
    [self log:@"Banner 示例：Load -> Ready -> ShowInView -> Destroy"];
}

- (void)dealloc {
    [self.bannerAd ysifly_destroy];
}

- (void)setupUI {
    CGFloat margin = 16;
    CGFloat width = self.view.bounds.size.width;
    CGFloat contentWidth = width - margin * 2;
    CGFloat y = 110;

    UILabel *desc = [YSIFLYADUtil createSectionTitleWithText:@"Banner 由 SDK 内置渲染，媒体侧提供容器视图并在 ready 后调用 ysifly_showInView:。"
                                                     frame:CGRectMake(margin, y, contentWidth, 38)];
    [self.view addSubview:desc];
    y += 48;

    CGFloat buttonWidth = (contentWidth - 8) / 2.0;
    UIButton *loadButton = [YSIFLYADUtil createADTypeButtonWithFrame:CGRectMake(margin, y, buttonWidth, 44)
                                                            title:@"Load"
                                                           target:self
                                                           action:@selector(loadBannerAd)];
    [self.view addSubview:loadButton];

    self.showButton = [YSIFLYADUtil createADTypeButtonWithFrame:CGRectMake(margin + buttonWidth + 8, y, buttonWidth, 44)
                                                        title:@"Show"
                                                       target:self
                                                       action:@selector(showBannerAd)];
    [self setShowButtonEnabled:NO];
    [self.view addSubview:self.showButton];
    y += 54;

    UIButton *destroyButton = [YSIFLYADUtil createSmallButtonWithTitle:@"Destroy"
                                                               color:UIColor.systemRedColor
                                                              target:self
                                                              action:@selector(destroyBannerAd)];
    destroyButton.frame = CGRectMake(margin, y, buttonWidth, 34);
    [self.view addSubview:destroyButton];

    UIButton *statusButton = [YSIFLYADUtil createSmallButtonWithTitle:@"检查状态"
                                                              color:UIColor.systemBlueColor
                                                             target:self
                                                             action:@selector(checkStatus)];
    statusButton.frame = CGRectMake(margin + buttonWidth + 8, y, buttonWidth, 34);
    [self.view addSubview:statusButton];
    y += 48;

    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin, y, contentWidth, 22)];
    self.statusLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    self.statusLabel.textColor = UIColor.systemBlueColor;
    self.statusLabel.text = @"等待加载";
    [self.view addSubview:self.statusLabel];
    y += 32;

    UILabel *containerTitle = [YSIFLYADUtil createSectionTitleWithText:@"Banner 容器"
                                                               frame:CGRectMake(margin, y, contentWidth, 18)];
    [self.view addSubview:containerTitle];
    y += 22;

    self.bannerContainer = [[UIView alloc] initWithFrame:CGRectMake(margin, y, contentWidth, 90)];
    self.bannerContainer.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0];
    self.bannerContainer.layer.cornerRadius = 8;
    self.bannerContainer.layer.borderColor = [UIColor colorWithWhite:0.86 alpha:1.0].CGColor;
    self.bannerContainer.layer.borderWidth = 1;
    [self.view addSubview:self.bannerContainer];
    [self resetBannerPlaceholder];
    y += 108;

    UILabel *logTitle = [YSIFLYADUtil createSectionTitleWithText:@"回调日志"
                                                         frame:CGRectMake(margin, y, contentWidth, 18)];
    [self.view addSubview:logTitle];
    y += 22;

    CGFloat logHeight = MAX(180, self.view.bounds.size.height - y - 24);
    self.logView = [YSIFLYADUtil createLogTextViewWithFrame:CGRectMake(margin, y, contentWidth, logHeight)];
    [self.view addSubview:self.logView];
}

- (void)loadBannerAd {
    [self destroyBannerAdSilently];
    [self resetBannerPlaceholder];
    [self setShowButtonEnabled:NO];
    [self updateStatus:@"正在加载 Banner" color:UIColor.systemBlueColor];
    [self log:[NSString stringWithFormat:@"Load adUnitId=%@", __BANNER_AD_UNIT_ID__]];

    YSIFLYBannerAd *ad = [[YSIFLYBannerAd alloc] initWithAdUnitId:__BANNER_AD_UNIT_ID__];
    ad.delegate = self;
    ad.currentViewController = self;
    ad.closeButtonVisible = YES;
    self.bannerAd = ad;
    [ad ysifly_loadAdWithRequestConfig:[YSIFLYADUtil mediaSampleRequestConfig]];
}

- (void)showBannerAd {
    if (!self.bannerAd || ![self.bannerAd ysifly_isAdValid]) {
        [self log:@"Show ignored: Banner 尚未 ready 或已失效"];
        [self updateStatus:@"请先等待 ready 回调" color:UIColor.systemRedColor];
        [self setShowButtonEnabled:NO];
        return;
    }

    [self log:@"调用 ysifly_showInView:"];
    [self setShowButtonEnabled:NO];
    [self.bannerAd ysifly_showInView:self.bannerContainer];
}

- (void)destroyBannerAd {
    [self destroyBannerAdSilently];
    [self resetBannerPlaceholder];
    [self updateStatus:@"已销毁" color:[YSIFLYADUtil demoTealColor]];
    [self log:@"Destroy"];
}

- (void)checkStatus {
    [self log:[NSString stringWithFormat:@"状态 ysifly_isAdValid=%@ ecpm=%.2f",
                                      (self.bannerAd && [self.bannerAd ysifly_isAdValid]) ? @"YES" : @"NO",
                                      self.bannerAd ? [self.bannerAd ecpm] : -1.0]];
}

- (void)destroyBannerAdSilently {
    if (!self.bannerAd) {
        return;
    }
    self.bannerAd.delegate = nil;
    [self.bannerAd ysifly_destroy];
    self.bannerAd = nil;
    [self setShowButtonEnabled:NO];
}

- (void)resetBannerPlaceholder {
    for (UIView *subview in [self.bannerContainer.subviews copy]) {
        [subview removeFromSuperview];
    }
    UILabel *label = [[UILabel alloc] initWithFrame:self.bannerContainer.bounds];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    label.text = @"Banner 展示区域";
    label.textColor = [YSIFLYADUtil demoSecondaryLabelColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:14];
    [self.bannerContainer addSubview:label];
}

- (void)setShowButtonEnabled:(BOOL)enabled {
    self.showButton.enabled = enabled;
    self.showButton.alpha = enabled ? 1.0 : 0.45;
}

- (void)updateStatus:(NSString *)text color:(UIColor *)color {
    self.statusLabel.text = text;
    self.statusLabel.textColor = color;
}

- (void)log:(NSString *)text {
    [YSIFLYADUtil appendLog:text toTextView:self.logView];
    YSIFLYSampleLogInfo(@"Banner", @"%@", text);
}

#pragma mark - YSIFLYBannerAdDelegate

- (void)ysifly_bannerAdDidLoad:(YSIFLYBannerAd *)ad {
    [self log:[NSString stringWithFormat:@"bannerAdDidLoad ecpm=%.2f", [ad ecpm]]];
    [self updateStatus:@"已加载，等待素材 ready" color:[YSIFLYADUtil demoIndigoColor]];
}

- (void)ysifly_bannerAdDidReady:(YSIFLYBannerAd *)ad {
    [self log:@"bannerAdDidReady"];
    [self updateStatus:@"Banner 已 ready，可展示" color:UIColor.systemGreenColor];
    [self setShowButtonEnabled:ad == self.bannerAd && [ad ysifly_isAdValid]];
}

- (void)ysifly_bannerAdDidExpose:(YSIFLYBannerAd *)ad {
    [self log:@"bannerAdDidExpose"];
    [self updateStatus:@"Banner 已曝光" color:UIColor.systemGreenColor];
}

- (void)ysifly_bannerAdDidClick:(YSIFLYBannerAd *)ad {
    [self log:@"bannerAdDidClick"];
}

- (void)ysifly_bannerAd:(YSIFLYBannerAd *)ad didJumpWithSuccess:(BOOL)success {
    [self log:[NSString stringWithFormat:@"bannerAd didJumpWithSuccess=%@", success ? @"YES" : @"NO"]];
}

- (void)ysifly_bannerAdDidClose:(YSIFLYBannerAd *)ad {
    [self log:@"bannerAdDidClose"];
    [self updateStatus:@"Banner 已关闭" color:[YSIFLYADUtil demoTealColor]];
}

- (void)ysifly_bannerAd:(YSIFLYBannerAd *)ad didFailWithError:(YSIFLYAdError *)error {
    [self log:[NSString stringWithFormat:@"bannerAd didFailWithError %@", [YSIFLYADUtil summaryForError:error]]];
    [self updateStatus:@"Banner 加载或展示失败" color:UIColor.systemRedColor];
    [self setShowButtonEnabled:NO];
}

@end
