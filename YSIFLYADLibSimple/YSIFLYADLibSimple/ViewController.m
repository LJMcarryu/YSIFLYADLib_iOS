//
//  ViewController.m
//  YSIFLYADLibSimple
//
//  Created by admin on 3.3.25.
//

#import "YSIFLYBannerViewController.h"
#import "YSIFLYInterstitialViewController.h"
#import "YSIFLYNativeViewController.h"
#import "YSIFLYSplashViewController.h"
#import "ViewController.h"

#import "YSIFLYADUtil.h"
#import <YSIFLYADLib/YSIFLYADLib.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"YSIFLYADLib 示例";
    self.view.backgroundColor = UIColor.whiteColor;
    [self initADTypeListView];
}

- (void)initADTypeListView {
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:scrollView];

    CGFloat width = self.view.bounds.size.width;
    CGFloat margin = 24;
    CGFloat contentWidth = width - margin * 2;
    CGFloat y = 24;

    UILabel *versionLabel =
        [YSIFLYADUtil createSectionTitleWithText:[NSString stringWithFormat:@"SDK Version: %@", [YSIFLYAdTool ysifly_sdkVersion]]
                                         frame:CGRectMake(margin, y, contentWidth, 20)];
    versionLabel.textAlignment = NSTextAlignmentCenter;
    [scrollView addSubview:versionLabel];
    y += 36;

    UILabel *descLabel = [YSIFLYADUtil
        createSectionTitleWithText:@"本工程演示媒体侧常用接入流程：初始化、加载、展示、回调、销毁。示例代码只使用 SDK 公开 API。"
                             frame:CGRectMake(margin, y, contentWidth, 52)];
    descLabel.textAlignment = NSTextAlignmentCenter;
    [scrollView addSubview:descLabel];
    y += 72;

    NSArray<NSDictionary<NSString *, NSString *> *> *items = @[
        @{@"title" : @"开屏广告", @"selector" : @"splashADTypeClick:"},
        @{@"title" : @"Banner 广告", @"selector" : @"bannerADTypeClick:"},
        @{@"title" : @"插屏广告", @"selector" : @"interstitialADTypeClick:"},
        @{@"title" : @"自渲染信息流", @"selector" : @"nativeADTypeClick:"},
    ];

    for (NSDictionary<NSString *, NSString *> *item in items) {
        SEL selector = NSSelectorFromString(item[@"selector"]);
        UIButton *button = [YSIFLYADUtil createADTypeButtonWithFrame:CGRectMake(margin, y, contentWidth, 48)
                                                             title:item[@"title"]
                                                            target:self
                                                            action:selector];
        [scrollView addSubview:button];
        y += 62;
    }

    scrollView.contentSize = CGSizeMake(width, y + 24);
}

- (void)splashADTypeClick:(UIButton *)sender {
    [self.navigationController pushViewController:YSIFLYSplashViewController.alloc.init animated:YES];
}

- (void)nativeADTypeClick:(UIButton *)sender {
    [self.navigationController pushViewController:YSIFLYNativeViewController.alloc.init animated:YES];
}

- (void)bannerADTypeClick:(UIButton *)sender {
    [self.navigationController pushViewController:YSIFLYBannerViewController.alloc.init animated:YES];
}

- (void)interstitialADTypeClick:(UIButton *)sender {
    [self.navigationController pushViewController:YSIFLYInterstitialViewController.alloc.init animated:YES];
}

@end
