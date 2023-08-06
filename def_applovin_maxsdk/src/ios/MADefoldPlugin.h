#import <Foundation/Foundation.h>
#import <AppLovinSDK/AppLovinSDK.h>
#import <DTBiOSSDK/DTBiOSSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface MADefoldPlugin : NSObject

typedef void(*DefoldEventCallback)(int messageId, NSString *body);

#pragma mark - Initialization

- (instancetype)init:(DefoldEventCallback)eventCallback amazonAppId:(NSString *)amazonAppId;


#pragma mark - Interstitials

- (void)loadInterstitialWithAdUnitIdentifier:(NSString *)adUnitIdentifier;
- (BOOL)isInterstitialReadyWithAdUnitIdentifier:(NSString *)adUnitIdentifier;
- (void)showInterstitialWithAdUnitIdentifier:(NSString *)adUnitIdentifier placement:(NSString *)placement;
- (void)setInterstitialExtraParameterForAdUnitIdentifier:(NSString *)adUnitIdentifier key:(NSString *)key value:(NSString *)value;

#pragma mark - Rewarded

- (void)loadRewardedAdWithAdUnitIdentifier:(NSString *)adUnitIdentifier;
- (BOOL)isRewardedAdReadyWithAdUnitIdentifier:(NSString *)adUnitIdentifier;
- (void)showRewardedAdWithAdUnitIdentifier:(NSString *)adUnitIdentifier placement:(NSString *)placement;
- (void)setRewardedAdExtraParameterForAdUnitIdentifier:(NSString *)adUnitIdentifier key:(NSString *)key value:(nullable NSString *)value;

#pragma mark - Banners

- (void)createBannerWithAdUnitIdentifier:(NSString *)adUnitIdentifier atPosition:(NSString *)bannerPosition;
- (void)setBannerBackgroundColorForAdUnitIdentifier:(NSString *)adUnitIdentifier hexColorCode:(NSString *)hexColorCode;
- (void)setBannerPlacement:(nullable NSString *)placement forAdUnitIdentifier:(NSString *)adUnitIdentifier;
- (void)updateBannerPosition:(NSString *)bannerPosition forAdUnitIdentifier:(NSString *)adUnitIdentifier;
- (void)showBannerWithAdUnitIdentifier:(NSString *)adUnitIdentifier;
- (void)hideBannerWithAdUnitIdentifier:(NSString *)adUnitIdentifier;
- (void)destroyBannerWithAdUnitIdentifier:(NSString *)adUnitIdentifier;
- (void)showAnyBannerAd;
- (void)hideAllBannerAds;
- (void)destroyAllBannerAds;
- (BOOL)isAnyBannerAdLoaded;
- (BOOL)isAnyBannerAdShown;

@end

NS_ASSUME_NONNULL_END
