#import "YSIFLYRewardVideoViewController.h"

#if __has_include(<YSIFLYADLib/IFLYRewardVideoAd.h>)
#import "YSIFLYADUtil.h"
#import <YSIFLYADLib/YSIFLYADLib.h>

@interface YSIFLYRewardVideoViewController () <YSIFLYRewardVideoAdDelegate>
@property (nonatomic, strong) YSIFLYRewardVideoAd *rewardAd;
@property (nonatomic, strong) UIButton *showButton;
@property (nonatomic, strong) UITextView *logView;
@property (nonatomic, assign) BOOL rewardGranted;
@end

@implementation YSIFLYRewardVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"激励广告";
    self.view.backgroundColor = UIColor.whiteColor;
    CGFloat margin = 16;
    CGFloat width = self.view.bounds.size.width - margin * 2;
    UILabel *description = [YSIFLYADUtil createSectionTitleWithText:@"Load → Ready → Show。仅奖励生效回调确认奖励，关闭和播放完成不代表获奖。请先配置自己的激励广告位。"
                                                          frame:CGRectMake(margin, 110, width, 60)];
    [self.view addSubview:description];
    CGFloat buttonWidth = (width - 8) / 2;
    UIButton *load = [YSIFLYADUtil createADTypeButtonWithFrame:CGRectMake(margin, 184, buttonWidth, 44)
                                                      title:@"Load" target:self action:@selector(loadAd)];
    [self.view addSubview:load];
    self.showButton = [YSIFLYADUtil createADTypeButtonWithFrame:CGRectMake(margin + buttonWidth + 8, 184, buttonWidth, 44)
                                                       title:@"Show" target:self action:@selector(showAd)];
    [self setShowEnabled:NO];
    [self.view addSubview:self.showButton];
    UIButton *destroy = [YSIFLYADUtil createSmallButtonWithTitle:@"Destroy" color:UIColor.systemRedColor
                                                       target:self action:@selector(destroyAd)];
    destroy.frame = CGRectMake(margin, 240, width, 34);
    [self.view addSubview:destroy];
    self.logView = [YSIFLYADUtil createLogTextViewWithFrame:CGRectMake(margin, 288, width, MAX(180, self.view.bounds.size.height - 312))];
    self.logView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.logView];
    [self log:@"本页仅演示回调，不发放真实业务奖励。观看前由宿主说明奖励条件。"];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.isMovingFromParentViewController || self.isBeingDismissed || self.navigationController.isBeingDismissed) {
        [self destroyAd];
    }
}

- (void)dealloc {
    _rewardAd.delegate = nil;
    [_rewardAd ysifly_destroy];
}

- (void)loadAd {
    [self destroyAd];
    if (__REWARD_AD_UNIT_ID__.length == 0) {
        [self log:@"请先在 YSIFLYAdPrefixHeader.pch 配置 __REWARD_AD_UNIT_ID__。"];
        return;
    }
    self.rewardGranted = NO;
    YSIFLYRewardVideoAd *ad = [[YSIFLYRewardVideoAd alloc] initWithAdUnitId:__REWARD_AD_UNIT_ID__];
    self.rewardAd = ad;
    ad.delegate = self;
    ad.currentViewController = self;
    [ad ysifly_loadAdWithRequestConfig:[YSIFLYADUtil mediaSampleRequestConfig]];
    [self log:@"Load：等待 Ready 后展示。"];
}

- (void)showAd {
    YSIFLYRewardVideoAd *ad = self.rewardAd;
    if (!ad || ![ad ysifly_isAdValid]) {
        [self setShowEnabled:NO];
        [self log:@"广告未就绪或已失效，请重新加载。"];
        return;
    }
    if (!self.view.window || self.presentedViewController || self.isBeingDismissed || self.isMovingFromParentViewController) {
        [self log:@"来源页面当前不可展示，请在页面可见后重试。"];
        return;
    }
    if (@available(iOS 13.0, *)) {
        if (self.view.window.windowScene.activationState != UISceneActivationStateForegroundActive) return;
    }
    [self setShowEnabled:NO];
    YSIFLYRewardVideoAdConfig *config = [[YSIFLYRewardVideoAdConfig alloc] init];
    config.muteOnStart = YES;
    config.muteButtonHidden = NO;
    [ad ysifly_showAdFromRootViewController:self config:config];
}

- (void)destroyAd {
    YSIFLYRewardVideoAd *ad = self.rewardAd;
    self.rewardAd = nil;
    ad.delegate = nil;
    [ad ysifly_destroy];
    [self setShowEnabled:NO];
}

- (void)setShowEnabled:(BOOL)enabled {
    self.showButton.enabled = enabled;
    self.showButton.alpha = enabled ? 1.0 : 0.45;
}

- (void)log:(NSString *)message {
    [YSIFLYADUtil appendLog:message toTextView:self.logView];
    YSIFLYSampleLogInfo(@"Reward", @"%@", message);
}

- (void)ysifly_rewardVideoAdDidLoad:(YSIFLYRewardVideoAd *)ad {
    if (ad != self.rewardAd) return;
    [self log:@"DidLoad：响应已解析，继续等待 Ready。"];
}

- (void)ysifly_rewardVideoAdDidReady:(YSIFLYRewardVideoAd *)ad {
    if (ad != self.rewardAd) return;
    [self setShowEnabled:[ad ysifly_isAdValid]];
    [self log:@"DidReady：可点击 Show。"];
}

- (void)ysifly_rewardVideoAdDidShow:(YSIFLYRewardVideoAd *)ad {
    if (ad == self.rewardAd) [self log:@"DidShow"];
}

- (void)ysifly_rewardVideoAdDidExpose:(YSIFLYRewardVideoAd *)ad {
    if (ad == self.rewardAd) [self log:@"DidExpose"];
}

- (void)ysifly_rewardVideoAdDidClick:(YSIFLYRewardVideoAd *)ad {
    if (ad == self.rewardAd) [self log:@"DidClick"];
}

- (void)ysifly_rewardVideoAd:(YSIFLYRewardVideoAd *)ad didRewardEffective:(NSDictionary *)info {
    if (ad != self.rewardAd || self.rewardGranted) return;
    self.rewardGranted = YES;
    [self log:@"DidRewardEffective：本次广告奖励生效（示例仅记录一次）。业务发奖还需按业务订单做幂等处理。"];
}

- (void)ysifly_rewardVideoAdDidPlayFinish:(YSIFLYRewardVideoAd *)ad {
    if (ad == self.rewardAd) [self log:@"DidPlayFinish：仅表示播放完成，不作为发奖依据。"];
}

- (void)ysifly_rewardVideoAdDidClose:(YSIFLYRewardVideoAd *)ad {
    if (ad != self.rewardAd) return;
    [self log:self.rewardGranted ? @"DidClose：已收到奖励生效回调。" : @"DidClose：未收到奖励生效回调，不发奖。"];
    [self destroyAd];
}

- (void)ysifly_rewardVideoAd:(YSIFLYRewardVideoAd *)ad didFailWithError:(YSIFLYAdError *)error {
    if (ad != self.rewardAd) return;
    [self setShowEnabled:NO];
    [self log:[NSString stringWithFormat:@"DidFail：%@；失败不补发奖励。", [YSIFLYADUtil summaryForError:error]]];
}

@end
#endif
