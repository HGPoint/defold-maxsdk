#include <dmsdk/sdk.h>
#import "MADefoldPlugin.h"

#define KEY_WINDOW [UIApplication sharedApplication].keyWindow
#define DEVICE_SPECIFIC_ADVIEW_AD_FORMAT ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) ? MAAdFormat.leader : MAAdFormat.banner


@interface MADefoldPlugin()<MAAdRevenueDelegate, MAAdDelegate, MAAdViewAdDelegate, MARewardedAdDelegate>

// Parent Fields
@property (nonatomic, weak) ALSdk *sdk;
@property (nonatomic, strong) UIWindow *window;

// Fullscreen Ad Fields
@property (nonatomic, strong) NSMutableDictionary<NSString *, MAInterstitialAd *> *interstitials;
@property (nonatomic, strong) NSMutableDictionary<NSString *, MARewardedAd *> *rewardedAds;

// Banner Fields
@property (nonatomic, strong) NSMutableDictionary<NSString *, MAAdView *> *adViews;
@property (nonatomic, strong) NSMutableDictionary<NSString *, MAAdFormat *> *adViewAdFormats;
@property (nonatomic, strong) NSMutableDictionary<NSString *, MAAdFormat *> *verticalAdViewFormats;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *adViewPositions;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSArray<NSLayoutConstraint *> *> *adViewConstraints;
@property (nonatomic, strong) NSMutableArray<NSString *> *adUnitIdentifiersToShowAfterCreate;
@property (nonatomic, strong) UIView *safeAreaBackground;
@property (nonatomic, strong, nullable) UIColor *publisherBannerBackgroundColor;

@property (nonatomic, weak) UIWindow *mainView;
@property (nonatomic, weak) UIWindow *mainSubView;

@property (nonatomic, assign) DefoldEventCallback eventCallback;

@end

@implementation MADefoldPlugin
static NSString *const SDK_TAG = @"AppLovinSdk";
static NSString *const TAG = @"MADefoldPlugin";

    // duplicate of enums from maxsdk_callback_private.h:
static const int MSG_INTERSTITIAL = 1;
static const int MSG_REWARDED = 2;
static const int MSG_BANNER = 3;
static const int MSG_INITIALIZATION = 4;

static const int EVENT_CLOSED = 1;
static const int EVENT_FAILED_TO_SHOW = 2;
static const int EVENT_OPENING = 3;
static const int EVENT_FAILED_TO_LOAD = 4;
static const int EVENT_LOADED = 5;
static const int EVENT_NOT_LOADED = 6;
static const int EVENT_EARNED_REWARD = 7;
static const int EVENT_COMPLETE = 8;
static const int EVENT_CLICKED = 9;
static const int EVENT_DESTROYED = 10;
static const int EVENT_EXPANDED = 11;
static const int EVENT_COLLAPSED = 12;
static const int EVENT_REVENUE_PAID = 13;
static const int EVENT_SIZE_UPDATE = 14;
static const int EVENT_FAILED_TO_LOAD_WATERFALL = 15;;
static bool IS_USER_GDPR_REGION = false;

#pragma mark - Initialization

- (instancetype)init:(DefoldEventCallback)eventCallback amazonAppId:(NSString *)amazonAppId privacyPolicyUrl:(nullable NSString *)privacyPolicyUrl userId:(nullable NSString *)userId;
{
    self = [super init];
    if ( self )
    {
        self.interstitials = [NSMutableDictionary dictionaryWithCapacity: 2];
        self.rewardedAds = [NSMutableDictionary dictionaryWithCapacity: 2];self.adViews = [NSMutableDictionary dictionaryWithCapacity: 2];
        self.adViewAdFormats = [NSMutableDictionary dictionaryWithCapacity: 2];
        self.verticalAdViewFormats = [NSMutableDictionary dictionaryWithCapacity: 2];
        self.adViewPositions = [NSMutableDictionary dictionaryWithCapacity: 2];
        self.adViewConstraints = [NSMutableDictionary dictionaryWithCapacity: 2];
        self.adUnitIdentifiersToShowAfterCreate = [NSMutableArray arrayWithCapacity: 2];
        self.eventCallback = eventCallback;
        self.sdk = [ALSdk shared];
        self.sdk.settings.termsAndPrivacyPolicyFlowSettings.enabled = YES;
        self.sdk.settings.termsAndPrivacyPolicyFlowSettings.privacyPolicyURL = [NSURL URLWithString: privacyPolicyUrl];
        self.sdk.mediationProvider = ALMediationProviderMAX;
        self.sdk.userIdentifier = userId;
        self.mainView = dmGraphics::GetNativeiOSUIView();
        self.mainSubView = dmGraphics::GetNativeiOSUIWindow();
        self.window = self.mainSubView;

        self.safeAreaBackground = [[UIView alloc] init];
        self.safeAreaBackground.hidden = YES;
        self.safeAreaBackground.backgroundColor = UIColor.clearColor;
        self.safeAreaBackground.translatesAutoresizingMaskIntoConstraints = NO;
        self.safeAreaBackground.userInteractionEnabled = NO;
        [self.mainSubView addSubview: self.safeAreaBackground];


        [self.sdk setPluginVersion: @"defold-maxsdk"];
        [self.sdk initializeSdkWithCompletionHandler:^(ALSdkConfiguration *configuration) {
            // Start loading ads
            if (configuration.consentFlowUserGeography == ALConsentFlowUserGeographyGDPR) {
                IS_USER_GDPR_REGION = true;
            }
            [self sendDefoldEvent: MSG_INITIALIZATION event_id: EVENT_COMPLETE parameters: @{@"plugin":@"defold-maxsdk"}];
        }];
        [[DTBAds sharedInstance] setAppKey: amazonAppId];
        DTBAdNetworkInfo *adNetworkInfo = [[DTBAdNetworkInfo alloc] initWithNetworkName: DTBADNETWORK_MAX];
        [DTBAds sharedInstance].mraidCustomVersions = @[@"1.0", @"2.0", @"3.0"];
        [[DTBAds sharedInstance] setAdNetworkInfo: adNetworkInfo];
        [DTBAds sharedInstance].mraidPolicy = CUSTOM_MRAID;
    }
    return self;
}

#pragma mark - Banners

- (void)createBannerWithAdUnitIdentifier:(NSString *)adUnitIdentifier atPosition:(NSString *)bannerPosition
{
    [self createAdViewWithAdUnitIdentifier: adUnitIdentifier adFormat: DEVICE_SPECIFIC_ADVIEW_AD_FORMAT atPosition: bannerPosition];
}

- (void)setBannerBackgroundColorForAdUnitIdentifier:(NSString *)adUnitIdentifier hexColorCode:(NSString *)hexColorCode
{
    [self setAdViewBackgroundColorForAdUnitIdentifier: adUnitIdentifier adFormat: DEVICE_SPECIFIC_ADVIEW_AD_FORMAT hexColorCode: hexColorCode];
}

- (void)setBannerPlacement:(nullable NSString *)placement forAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    [self setAdViewPlacement: placement forAdUnitIdentifier: adUnitIdentifier adFormat: DEVICE_SPECIFIC_ADVIEW_AD_FORMAT];
}

- (void)updateBannerPosition:(NSString *)bannerPosition forAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    [self updateAdViewPosition: bannerPosition forAdUnitIdentifier: adUnitIdentifier adFormat: DEVICE_SPECIFIC_ADVIEW_AD_FORMAT];
}

- (void)showBannerWithAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    [self showAdViewWithAdUnitIdentifier: adUnitIdentifier adFormat: DEVICE_SPECIFIC_ADVIEW_AD_FORMAT];
}

- (void)showAnyBannerAd
{
    for (NSString* key in self.adViews) {
        [self showAdViewWithAdUnitIdentifier: key adFormat: DEVICE_SPECIFIC_ADVIEW_AD_FORMAT];
        return;
    }  
}

- (void)hideBannerWithAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    [self hideAdViewWithAdUnitIdentifier: adUnitIdentifier adFormat: DEVICE_SPECIFIC_ADVIEW_AD_FORMAT];
}

- (void)hideAllBannerAds
{
    for (NSString* key in self.adViews) {
        [self hideAdViewWithAdUnitIdentifier: key adFormat: DEVICE_SPECIFIC_ADVIEW_AD_FORMAT];
    }  
}

- (void)destroyBannerWithAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    [self destroyAdViewWithAdUnitIdentifier: adUnitIdentifier adFormat: DEVICE_SPECIFIC_ADVIEW_AD_FORMAT];
}

- (void)destroyAllBannerAds
{
    for (NSString* key in self.adViews) {
        [self destroyAdViewWithAdUnitIdentifier: key adFormat: DEVICE_SPECIFIC_ADVIEW_AD_FORMAT];
    }
}

- (BOOL)isAnyBannerAdShown
{

    for (NSString* key in self.adViews) {
        MAAdView *view = self.adViews[key];
        if(![view isHidden])
            return true;
    }  
    return false;
}

- (BOOL)isAnyBannerAdLoaded
{
    for (NSString* key in self.adViews) {
        return true;
    }  
    return false;
}

#pragma mark - Interstitials

- (void)loadInterstitialWithAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    MAInterstitialAd *interstitial = [self retrieveInterstitialForAdUnitIdentifier: adUnitIdentifier];
    [interstitial loadAd];
}

- (BOOL)isInterstitialReadyWithAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    MAInterstitialAd *interstitial = [self retrieveInterstitialForAdUnitIdentifier: adUnitIdentifier];
    return [interstitial isReady];
}

- (void)showInterstitialWithAdUnitIdentifier:(NSString *)adUnitIdentifier placement:(NSString *)placement
{
    MAInterstitialAd *interstitial = [self retrieveInterstitialForAdUnitIdentifier: adUnitIdentifier];
    [interstitial showAdForPlacement: placement];
}

- (void)setInterstitialExtraParameterForAdUnitIdentifier:(NSString *)adUnitIdentifier key:(NSString *)key value:(NSString *)value
{
    MAInterstitialAd *interstitial = [self retrieveInterstitialForAdUnitIdentifier: adUnitIdentifier];
    [interstitial setExtraParameterForKey: key value: value];
}

#pragma mark - Rewarded

- (void)loadRewardedAdWithAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    MARewardedAd *rewardedAd = [self retrieveRewardedAdForAdUnitIdentifier: adUnitIdentifier];
    [rewardedAd loadAd];
}

- (BOOL)isRewardedAdReadyWithAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    MARewardedAd *rewardedAd = [self retrieveRewardedAdForAdUnitIdentifier: adUnitIdentifier];
    return [rewardedAd isReady];
}

- (void)showRewardedAdWithAdUnitIdentifier:(NSString *)adUnitIdentifier placement:(NSString *)placement
{
    MARewardedAd *rewardedAd = [self retrieveRewardedAdForAdUnitIdentifier: adUnitIdentifier];
    [rewardedAd showAdForPlacement: placement];
}

- (void)setRewardedAdExtraParameterForAdUnitIdentifier:(NSString *)adUnitIdentifier key:(NSString *)key value:(nullable NSString *)value
{
    MARewardedAd *rewardedAd = [self retrieveRewardedAdForAdUnitIdentifier: adUnitIdentifier];
    [rewardedAd setExtraParameterForKey: key value: value];
}

#pragma mark - Ad Callbacks

- (void)didLoadAd:(MAAd *)ad
{
    int type;
    MAAdFormat *adFormat = ad.format;
    if ( MAAdFormat.banner == adFormat || MAAdFormat.leader == adFormat || MAAdFormat.mrec == adFormat )
    {
        MAAdView *adView = [self retrieveAdViewForAdUnitIdentifier: ad.adUnitIdentifier adFormat: adFormat];
        // An ad is now being shown, enable user interaction.
        adView.userInteractionEnabled = YES;
        
        type = MSG_BANNER;
        [self positionAdViewForAd: ad];
        
        // Do not auto-refresh by default if the ad view is not showing yet (e.g. first load during app launch and publisher does not automatically show banner upon load success)
        // We will resume auto-refresh in -[MAUnrealPlugin showBannerWithAdUnitIdentifier:].
        if ( adView && [adView isHidden] )
        {
            [adView stopAutoRefresh];
        }
    }
    else if ( MAAdFormat.interstitial == adFormat )
    {
        type = MSG_INTERSTITIAL;
    }
    else if ( MAAdFormat.rewarded == adFormat )
    {
        type = MSG_REWARDED;
    }
    else
    {
        [self logInvalidAdFormat: adFormat];
        return;
    }
    
    [self sendDefoldEvent: type event_id: EVENT_LOADED parameters: [self adInfoForAd: ad]];
}

- (void)didFailToLoadAdForAdUnitIdentifier:(NSString *)adUnitIdentifier withError:(MAError *)error
{
    if ( !adUnitIdentifier )
    {
        [self log: @"adUnitIdentifier cannot be nil from %@", [NSThread callStackSymbols]];
        return;
    }
    
    int type;
    if ( self.adViews[adUnitIdentifier] )
    {
        type = MSG_BANNER;
    }
    else if ( self.interstitials[adUnitIdentifier] )
    {
        type = MSG_INTERSTITIAL;
    }
    else if ( self.rewardedAds[adUnitIdentifier] )
    {
        type = MSG_REWARDED;
    }
    else
    {
        [self log: @"invalid adUnitId from %@", [NSThread callStackSymbols]];
        return;
    }
    
    NSMutableDictionary *parameters = [[self errorInfoForError: error] mutableCopy];
    parameters[@"adUnitIdentifier"] = adUnitIdentifier;
    
    [self sendDefoldEvent: type event_id: EVENT_FAILED_TO_LOAD parameters: parameters];


    if (!error.waterfall) {
        return;
    }

    MAAdWaterfallInfo *waterfall = error.waterfall;
    for (MANetworkResponseInfo *networkResponse in waterfall.networkResponses)
    {
        if (networkResponse.error) {

            NSMutableDictionary *waterfall_parameters = [[self errorInfoForResponse: networkResponse] mutableCopy];
            waterfall_parameters[@"adUnitIdentifier"] = adUnitIdentifier;       
            [self sendDefoldEvent: type event_id: EVENT_FAILED_TO_LOAD_WATERFALL parameters: waterfall_parameters];
        }
    }
}

- (void)didClickAd:(MAAd *)ad
{
    int type;
    MAAdFormat *adFormat = ad.format;
    if ( MAAdFormat.banner == adFormat || MAAdFormat.leader == adFormat )
    {
        type = MSG_BANNER;
    }
    else if ( MAAdFormat.mrec == adFormat )
    {
        type = MSG_BANNER;
    }
    else if ( MAAdFormat.interstitial == adFormat )
    {
        type = MSG_INTERSTITIAL;
    }
    else if ( MAAdFormat.rewarded == adFormat )
    {
        type = MSG_REWARDED;
    }
    else
    {
        [self logInvalidAdFormat: adFormat];
        return;
    }
    
    [self sendDefoldEvent: type event_id: EVENT_CLICKED parameters: [self adInfoForAd: ad]];
}

- (void)didDisplayAd:(MAAd *)ad
{
    // BMLs do not support [DISPLAY] events
    MAAdFormat *adFormat = ad.format;
    if ( adFormat != MAAdFormat.interstitial && adFormat != MAAdFormat.rewarded ) return;
    
    int type;
    if ( MAAdFormat.interstitial == adFormat )
    {
        type = MSG_INTERSTITIAL;
    }
    else // REWARDED
    {
        type = MSG_REWARDED;
    }
    
    [self sendDefoldEvent: type event_id: EVENT_OPENING parameters: [self adInfoForAd: ad]];
}

- (void)didFailToDisplayAd:(MAAd *)ad withError:(MAError *)error
{
    // BMLs do not support [DISPLAY] events
    MAAdFormat *adFormat = ad.format;
    if ( adFormat != MAAdFormat.interstitial && adFormat != MAAdFormat.rewarded ) return;
    
    int type;
    if ( MAAdFormat.interstitial == adFormat )
    {
        type = MSG_INTERSTITIAL;
    }
    else // REWARDED
    {
        type = MSG_REWARDED;
    }
    
    NSMutableDictionary *parameters = [[self adInfoForAd: ad] mutableCopy];
    [parameters addEntriesFromDictionary: [self errorInfoForError: error]];
    
    [self sendDefoldEvent: type event_id: EVENT_FAILED_TO_SHOW parameters: parameters];
}

- (void)didHideAd:(MAAd *)ad
{
    // BMLs do not support [HIDDEN] events
    MAAdFormat *adFormat = ad.format;
    if ( adFormat != MAAdFormat.interstitial && adFormat != MAAdFormat.rewarded ) return;
    
    int type;
    if ( MAAdFormat.interstitial == adFormat )
    {
        type = MSG_INTERSTITIAL;
    }
    else // REWARDED
    {
        type = MSG_REWARDED;
    }
    
    [self sendDefoldEvent: type event_id: EVENT_CLOSED parameters: [self adInfoForAd: ad]];
}

- (void)didRewardUserForAd:(MAAd *)ad withReward:(MAReward *)reward
{
    MAAdFormat *adFormat = ad.format;
    if ( adFormat != MAAdFormat.rewarded )
    {
        [self logInvalidAdFormat: adFormat];
        return;
    }
    
    NSMutableDictionary *parameters = [[self adInfoForAd: ad] mutableCopy];
    parameters[@"label"] = reward ? reward.label : @"";
    parameters[@"amount"] = reward ? @(reward.amount) : @(0);
    
    [self sendDefoldEvent: MSG_REWARDED event_id: EVENT_EARNED_REWARD parameters: parameters];
}

- (void)didExpandAd:(MAAd *)ad
{
    [self sendDefoldEvent: MSG_BANNER event_id: EVENT_EXPANDED parameters: [self adInfoForAd: ad]];
}

- (void)didCollapseAd:(MAAd *)ad
{
    [self sendDefoldEvent: MSG_BANNER event_id: EVENT_COLLAPSED parameters: [self adInfoForAd: ad]];
}

- (void)didPayRevenueForAd:(MAAd *)ad
{
    int type;
    MAAdFormat *adFormat = ad.format;
    if ( MAAdFormat.banner == adFormat || MAAdFormat.leader == adFormat )
    {
        type = MSG_BANNER;
    }
    else if ( MAAdFormat.interstitial == adFormat )
    {
        type = MSG_INTERSTITIAL;
    }
    else if ( MAAdFormat.rewarded == adFormat )
    {
        type = MSG_REWARDED;
    }
    else
    {
        [self logInvalidAdFormat: adFormat];
        return;
    }
    
    [self sendDefoldEvent: type event_id: EVENT_REVENUE_PAID parameters: [self adInfoForAd: ad]];
}

#pragma mark - Internal Methods

- (void)logInvalidAdFormat:(MAAdFormat *)adFormat
{
    [self log: @"invalid ad format: %@, from %@", adFormat, [NSThread callStackSymbols]];
}

- (void)log:(NSString *)format, ...
{
    va_list valist;
    va_start(valist, format);
    NSString *message = [[NSString alloc] initWithFormat: format arguments: valist];
    va_end(valist);
    
    NSLog(@"[%@] [%@] %@", SDK_TAG, TAG, message);
}

- (MAInterstitialAd *)retrieveInterstitialForAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    MAInterstitialAd *result = self.interstitials[adUnitIdentifier];
    if ( !result )
    {
        result = [[MAInterstitialAd alloc] initWithAdUnitIdentifier: adUnitIdentifier sdk: self.sdk];
        result.delegate = self;
        
        self.interstitials[adUnitIdentifier] = result;
    }
    
    return result;
}

- (MARewardedAd *)retrieveRewardedAdForAdUnitIdentifier:(NSString *)adUnitIdentifier
{
    MARewardedAd *result = self.rewardedAds[adUnitIdentifier];
    if ( !result )
    {
        result = [MARewardedAd sharedWithAdUnitIdentifier: adUnitIdentifier sdk: self.sdk];
        result.delegate = self;
        
        self.rewardedAds[adUnitIdentifier] = result;
    }
    
    return result;
}

- (void)createAdViewWithAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat atPosition:(NSString *)adViewPosition
{
    dispatchOnMainQueue(^{
        [self log: @"Creating %@ with ad unit identifier \"%@\" and position: \"%@\"", adFormat, adUnitIdentifier, adViewPosition];
        
        // Retrieve ad view from the map
        MAAdView *adView = [self retrieveAdViewForAdUnitIdentifier: adUnitIdentifier adFormat: adFormat atPosition: adViewPosition];
        adView.hidden = YES;
        self.safeAreaBackground.hidden = YES;
        
        // Position ad view immediately so if publisher sets color before ad loads, it will not be the size of the screen
        self.adViewAdFormats[adUnitIdentifier] = adFormat;
        [self positionAdViewForAdUnitIdentifier: adUnitIdentifier adFormat: adFormat];
        
        [adView loadAd];
        
        // The publisher may have requested to show the banner before it was created. Now that the banner is created, show it.
        if ( [self.adUnitIdentifiersToShowAfterCreate containsObject: adUnitIdentifier] )
        {
            [self showAdViewWithAdUnitIdentifier: adUnitIdentifier adFormat: adFormat];
            [self.adUnitIdentifiersToShowAfterCreate removeObject: adUnitIdentifier];
        }
    });
}

- (void)setAdViewBackgroundColorForAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat hexColorCode:(NSString *)hexColorCode
{
    dispatchOnMainQueue(^{
        [self log: @"Setting %@ with ad unit identifier \"%@\" to color: \"%@\"", adFormat, adUnitIdentifier, hexColorCode];
        
        UIColor *convertedColor = [[UIColor alloc] initWithRed:1 green:1  blue:1 alpha:0];
        
        MAAdView *view = [self retrieveAdViewForAdUnitIdentifier: adUnitIdentifier adFormat: adFormat];
        self.publisherBannerBackgroundColor = convertedColor;
        self.safeAreaBackground.backgroundColor = view.backgroundColor = convertedColor;
    });
}

- (void)setAdViewPlacement:(nullable NSString *)placement forAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat
{
    dispatchOnMainQueue(^{
        [self log: @"Setting placement \"%@\" for \"%@\" with ad unit identifier \"%@\"", placement, adFormat, adUnitIdentifier];
        
        MAAdView *adView = [self retrieveAdViewForAdUnitIdentifier: adUnitIdentifier adFormat: adFormat];
        adView.placement = placement;
    });
}

- (void)updateAdViewPosition:(NSString *)adViewPosition forAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat
{
    dispatchOnMainQueue(^{
        // Check if the previous position is same as the new position. If so, no need to update the position again.
        NSString *previousPosition = self.adViewPositions[adUnitIdentifier];
        if ( !adViewPosition || [adViewPosition isEqualToString: previousPosition] ) return;
        
        self.adViewPositions[adUnitIdentifier] = adViewPosition;
        [self positionAdViewForAdUnitIdentifier: adUnitIdentifier adFormat: adFormat];
    });
}

- (void)showAdViewWithAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat
{
    dispatchOnMainQueue(^{
        [self log: @"Showing %@ with ad unit identifier \"%@\"", adFormat, adUnitIdentifier];
        
        MAAdView *view = [self retrieveAdViewForAdUnitIdentifier: adUnitIdentifier adFormat: adFormat];
        if ( !view )
        {
            [self log: @"%@ does not exist for ad unit identifier %@.", adFormat, adUnitIdentifier];
            
            // The adView has not yet been created. Store the ad unit ID, so that it can be displayed once the banner has been created.
            [self.adUnitIdentifiersToShowAfterCreate addObject: adUnitIdentifier];
        }
        
        self.safeAreaBackground.hidden = NO;
        view.hidden = NO;
        
        CGSize adViewSize = [[self class] adViewSizeForAdFormat: adFormat];
        [self sendDefoldEvent: MSG_BANNER event_id: EVENT_SIZE_UPDATE parameters: @{@"x": @(adViewSize.width * self.mainView.contentScaleFactor * view.contentScaleFactor), @"y": @(adViewSize.height * self.mainView.contentScaleFactor * view.contentScaleFactor)}];
    
        [view startAutoRefresh];
    });
}

- (void)hideAdViewWithAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat
{
    dispatchOnMainQueue(^{
        [self log: @"Hiding %@ with ad unit identifier \"%@\"", adFormat, adUnitIdentifier];
        [self.adUnitIdentifiersToShowAfterCreate removeObject: adUnitIdentifier];
        
        MAAdView *view = [self retrieveAdViewForAdUnitIdentifier: adUnitIdentifier adFormat: adFormat];
        view.hidden = YES;
        self.safeAreaBackground.hidden = YES;
        
        [view stopAutoRefresh];

    });
}

- (void)destroyAdViewWithAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat
{
    dispatchOnMainQueue(^{
        [self log: @"Destroying %@ with ad unit identifier \"%@\"", adFormat, adUnitIdentifier];
        
        MAAdView *view = [self retrieveAdViewForAdUnitIdentifier: adUnitIdentifier adFormat: adFormat];
        view.delegate = nil;
        
        [view removeFromSuperview];
        
        [self.adViews removeObjectForKey: adUnitIdentifier];
        [self.adViewPositions removeObjectForKey: adUnitIdentifier];
        [self.adViewAdFormats removeObjectForKey: adUnitIdentifier];
        [self.verticalAdViewFormats removeObjectForKey: adUnitIdentifier];
        [self sendDefoldEvent: MSG_BANNER event_id: EVENT_DESTROYED parameters: @{@"ad_unit_id": adUnitIdentifier}];
    });
}

- (MAAdView *)retrieveAdViewForAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat
{
    return [self retrieveAdViewForAdUnitIdentifier: adUnitIdentifier adFormat: adFormat atPosition: nil];
}

- (MAAdView *)retrieveAdViewForAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat atPosition:(NSString *)adViewPosition
{
    MAAdView *result = self.adViews[adUnitIdentifier];
    if ( !result && adViewPosition )
    {
        result = [[MAAdView alloc] initWithAdUnitIdentifier: adUnitIdentifier adFormat: adFormat sdk: self.sdk];
        result.delegate = self;
        result.userInteractionEnabled = NO;
        result.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.adViews[adUnitIdentifier] = result;
        
        self.adViewPositions[adUnitIdentifier] = adViewPosition;
        [self.mainSubView addSubview: result];
    }
    
    return result;
}

- (void)positionAdViewForAd:(MAAd *)ad
{
    [self positionAdViewForAdUnitIdentifier: ad.adUnitIdentifier adFormat: ad.format];
}

- (void)positionAdViewForAdUnitIdentifier:(NSString *)adUnitIdentifier adFormat:(MAAdFormat *)adFormat
{
    MAAdView *adView = [self retrieveAdViewForAdUnitIdentifier: adUnitIdentifier adFormat: adFormat];
    NSString *adViewPosition = self.adViewPositions[adUnitIdentifier];
    
    UIView *superview = self.mainView;
    if ( !superview ) return;
    
    // Deactivate any previous constraints so that the banner can be positioned again.
    NSArray<NSLayoutConstraint *> *activeConstraints = self.adViewConstraints[adUnitIdentifier];
    [NSLayoutConstraint deactivateConstraints: activeConstraints];
    adView.transform = CGAffineTransformIdentity;
    [self.verticalAdViewFormats removeObjectForKey: adUnitIdentifier];
    
    // Ensure superview contains the safe area background.
    if ( ![superview.subviews containsObject: self.safeAreaBackground] )
    {
        [self.safeAreaBackground removeFromSuperview];
        [superview insertSubview: self.safeAreaBackground belowSubview: adView];
    }
    
    // Deactivate any previous constraints and reset visibility state so that the safe area background can be positioned again.
    [NSLayoutConstraint deactivateConstraints: self.safeAreaBackground.constraints];
    self.safeAreaBackground.hidden = adView.hidden;
    
    CGSize adViewSize = [[self class] adViewSizeForAdFormat: adFormat];
    
    // All positions have constant height
    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray arrayWithObject: [adView.heightAnchor constraintEqualToConstant: adViewSize.height]];
    
    UIEdgeInsets safeAreaInsets = superview.safeAreaInsets;
    CGFloat bottomInset = safeAreaInsets.bottom;
    
    if (UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom > 0) {
        bottomInset -= UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom;
    }

    UILayoutGuide *layoutGuide;
    if ( @available(iOS 11.0, *) )
    {
        layoutGuide = superview.safeAreaLayoutGuide;
    }
    else
    {
        layoutGuide = superview.layoutMarginsGuide;
    }
    
    // If top of bottom center, stretch width of screen
    if ( [adViewPosition isEqual: @"top_center"] || [adViewPosition isEqual: @"bottom_center"] )
    {
        // If publisher actually provided a banner background color, span the banner across the realm
        if ( self.publisherBannerBackgroundColor && adFormat != MAAdFormat.mrec )
        {
            [constraints addObjectsFromArray: @[[self.safeAreaBackground.leftAnchor constraintEqualToAnchor: superview.leftAnchor],
                                                [self.safeAreaBackground.rightAnchor constraintEqualToAnchor: superview.rightAnchor]]];
            
            if ( [adViewPosition isEqual: @"top_center"] )
            {
                [constraints addObjectsFromArray: @[[adView.topAnchor constraintEqualToAnchor: layoutGuide.topAnchor],
                                                    [adView.leftAnchor constraintEqualToAnchor: superview.leftAnchor],
                                                    [adView.rightAnchor constraintEqualToAnchor: superview.rightAnchor]]];
                [constraints addObjectsFromArray: @[[self.safeAreaBackground.topAnchor constraintEqualToAnchor: superview.topAnchor],
                                                    [self.safeAreaBackground.bottomAnchor constraintEqualToAnchor: adView.topAnchor]]];
            }
            else // BottomCenter
            {
                [constraints addObjectsFromArray: @[[adView.bottomAnchor constraintEqualToAnchor: layoutGuide.bottomAnchor constant:-bottomInset],
                                                    [adView.leftAnchor constraintEqualToAnchor: superview.leftAnchor],
                                                    [adView.rightAnchor constraintEqualToAnchor: superview.rightAnchor]]];
                [constraints addObjectsFromArray: @[[self.safeAreaBackground.topAnchor constraintEqualToAnchor: adView.bottomAnchor],
                                                    [self.safeAreaBackground.bottomAnchor constraintEqualToAnchor: superview.bottomAnchor]]];
            }
        }
        // If pub does not have a background color set - we shouldn't span the banner the width of the realm (there might be user-interactable UI on the sides)
        else
        {
            self.safeAreaBackground.hidden = YES;
            
            // Assign constant width of 320 or 728
            [constraints addObject: [adView.widthAnchor constraintEqualToConstant: adViewSize.width]];
            [constraints addObject: [adView.centerXAnchor constraintEqualToAnchor: layoutGuide.centerXAnchor]];
            
            if ( [adViewPosition isEqual: @"top_center"] )
            {
                [constraints addObject: [adView.topAnchor constraintEqualToAnchor: layoutGuide.topAnchor]];
            }
            else // BottomCenter
            {
                [constraints addObject: [adView.bottomAnchor constraintEqualToAnchor: layoutGuide.bottomAnchor]];
            }
        }
    }
    // Check if the publisher wants vertical banners.
    else if ( [adViewPosition isEqual: @"center_left"] || [adViewPosition isEqual: @"center_right"] )
    {
        if ( MAAdFormat.mrec == adFormat )
        {
            [constraints addObject: [adView.widthAnchor constraintEqualToConstant: adViewSize.width]];
            
            if ( [adViewPosition isEqual: @"center_left"] )
            {
                [constraints addObjectsFromArray: @[[adView.centerYAnchor constraintEqualToAnchor: layoutGuide.centerYAnchor],
                                                    [adView.leftAnchor constraintEqualToAnchor: superview.leftAnchor]]];
                
                [constraints addObjectsFromArray: @[[self.safeAreaBackground.rightAnchor constraintEqualToAnchor: layoutGuide.leftAnchor],
                                                    [self.safeAreaBackground.leftAnchor constraintEqualToAnchor: superview.leftAnchor]]];
            }
            else // center_right
            {
                [constraints addObjectsFromArray: @[[adView.centerYAnchor constraintEqualToAnchor: layoutGuide.centerYAnchor],
                                                    [adView.rightAnchor constraintEqualToAnchor: superview.rightAnchor]]];
                
                [constraints addObjectsFromArray: @[[self.safeAreaBackground.leftAnchor constraintEqualToAnchor: layoutGuide.rightAnchor],
                                                    [self.safeAreaBackground.rightAnchor constraintEqualToAnchor: superview.rightAnchor]]];
            }
        }
        else
        {
            /* Align the center of the view such that when rotated it snaps into place.
             *
             *                  +---+---+-------+
             *                  |   |           |
             *                  |   |           |
             *                  |   |           |
             *                  |   |           |
             *                  |   |           |
             *                  |   |           |
             *    +-------------+---+-----------+--+
             *    |             | + |   +       |  |
             *    +-------------+---+-----------+--+
             *                  <+> |           |
             *                  |+  |           |
             *                  ||  |           |
             *                  ||  |           |
             *                  ||  |           |
             *                  ||  |           |
             *                  +|--+-----------+
             *                   v
             *            Banner Half Height
             */
            self.safeAreaBackground.hidden = YES;
            
            adView.transform = CGAffineTransformRotate(CGAffineTransformIdentity, M_PI_2);
            
            CGFloat width;
            // If the publisher has a background color set - set the width to the height of the screen, to span the ad across the screen after it is rotated.
            if ( self.publisherBannerBackgroundColor )
            {
                width = CGRectGetHeight(KEY_WINDOW.bounds);
            }
            // Otherwise - we shouldn't span the banner the width of the realm (there might be user-interactable UI on the sides)
            else
            {
                width = adViewSize.width;
            }
            [constraints addObject: [adView.widthAnchor constraintEqualToConstant: width]];
            
            // Set constraints such that the center of the banner aligns with the center left or right as needed. That way, once rotated, the banner snaps into place.
            [constraints addObject: [adView.centerYAnchor constraintEqualToAnchor: superview.centerYAnchor]];
            
            // Place the center of the banner half the height of the banner away from the side. If we align the center exactly with the left/right anchor, only half the banner will be visible.
            CGFloat bannerHalfHeight = adViewSize.height / 2.0;
            UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
            if ( [adViewPosition isEqual: @"center_left"] )
            {
                NSLayoutAnchor *anchor = ( orientation == UIInterfaceOrientationLandscapeRight ) ? layoutGuide.leftAnchor : superview.leftAnchor;
                [constraints addObject: [adView.centerXAnchor constraintEqualToAnchor: anchor constant: bannerHalfHeight]];
            }
            else // CenterRight
            {
                NSLayoutAnchor *anchor = ( orientation == UIInterfaceOrientationLandscapeLeft ) ? layoutGuide.rightAnchor : superview.rightAnchor;
                [constraints addObject: [adView.centerXAnchor constraintEqualToAnchor: anchor constant: -bannerHalfHeight]];
            }
            
            // Store the ad view with format, so that it can be updated when the orientation changes.
            self.verticalAdViewFormats[adUnitIdentifier] = adFormat;
        }
    }
    // Otherwise, publisher will likely construct their own views around the adview
    else
    {
        self.safeAreaBackground.hidden = YES;
        
        // Assign constant width of 320 or 728
        [constraints addObject: [adView.widthAnchor constraintEqualToConstant: adViewSize.width]];
        
        if ( [adViewPosition isEqual: @"top_left"] )
        {
            [constraints addObjectsFromArray: @[[adView.topAnchor constraintEqualToAnchor: layoutGuide.topAnchor],
                                                [adView.leftAnchor constraintEqualToAnchor: superview.leftAnchor]]];
        }
        else if ( [adViewPosition isEqual: @"top_right"] )
        {
            [constraints addObjectsFromArray: @[[adView.topAnchor constraintEqualToAnchor: layoutGuide.topAnchor],
                                                [adView.rightAnchor constraintEqualToAnchor: superview.rightAnchor]]];
        }
        else if ( [adViewPosition isEqual: @"centered"] )
        {
            [constraints addObjectsFromArray: @[[adView.centerXAnchor constraintEqualToAnchor: layoutGuide.centerXAnchor],
                                                [adView.centerYAnchor constraintEqualToAnchor: layoutGuide.centerYAnchor]]];
        }
        else if ( [adViewPosition isEqual: @"bottom_left"] )
        {
            [constraints addObjectsFromArray: @[[adView.bottomAnchor constraintEqualToAnchor: layoutGuide.bottomAnchor],
                                                [adView.leftAnchor constraintEqualToAnchor: superview.leftAnchor]]];
        }
        else if ( [adViewPosition isEqual: @"bottom_right"] )
        {
            [constraints addObjectsFromArray: @[[adView.bottomAnchor constraintEqualToAnchor: layoutGuide.bottomAnchor],
                                                [adView.rightAnchor constraintEqualToAnchor: superview.rightAnchor]]];
        }
    }
    
    self.adViewConstraints[adUnitIdentifier] = constraints;
    
    [NSLayoutConstraint activateConstraints: constraints];
}

+ (CGSize)adViewSizeForAdFormat:(MAAdFormat *)adFormat
{
    if ( MAAdFormat.leader == adFormat )
    {
        return CGSizeMake(728.0f, 90.0f);
    }
    else if ( MAAdFormat.banner == adFormat )
    {
        return CGSizeMake(320.0f, 50.0f);
    }
    else if ( MAAdFormat.mrec == adFormat )
    {
        return CGSizeMake(300.0f, 250.0f);
    }
    else
    {
        [NSException raise: NSInvalidArgumentException format: @"Invalid ad format"];
        return CGSizeZero;
    }
}

#pragma mark - Utility Methods

- (BOOL)isUserGdprRegion
{
    return IS_USER_GDPR_REGION;
}

- (void)showConsentFlow
{
     ALCMPService *cmpService = [ALSdk shared].cmpService;

    [cmpService showCMPForExistingUserWithCompletion:^(ALCMPError * _Nullable error) {
        
        if ( !error )
        {
            // The CMP alert was shown successfully.
        }
    }];
}

- (NSDictionary<NSString *, id> *)adInfoForAd:(MAAd *)ad
{
    return @{@"ad_unit_id" : ad.adUnitIdentifier,
             @"creativeIdentifier" : ad.creativeIdentifier ?: @"",
             @"ad_network" : ad.networkName,
             @"placement" : ad.placement ?: @"",
             @"revenue" : @(ad.revenue)};
}

- (NSDictionary<NSString *, id> *)errorInfoForError:(MAError *)error
{
    return @{@"code" : @(error.code),
             @"error" : error.message ?: @"",
             @"waterfall" : error.waterfall.description ?: @""};
}

- (NSDictionary<NSString *, id> *)errorInfoForResponse:(MANetworkResponseInfo *)networkResponse {
    NSMutableDictionary<NSString *, id> *dict = [NSMutableDictionary dictionary];
    dict[@"ad_network"] = networkResponse.mediatedNetwork;
    
    if (networkResponse.error) {
        dict[@"code"] = @(networkResponse.error.code);
    }

    return dict;
}

#pragma mark - Defold Bridge

// NOTE: Defold deserializes to the relevant USTRUCT based on the JSON keys, so the keys must match with the corresponding UPROPERTY
- (void)sendDefoldEvent:(int)msg_type event_id:(int)event_id parameters:(NSDictionary<NSString *, NSString *> *)parameters
{
    if ( self.eventCallback )
    {
        NSMutableDictionary *mutparameters = [parameters mutableCopy];
        mutparameters[@"event"] = @(event_id);
        NSData *data = [NSJSONSerialization dataWithJSONObject: mutparameters options: 0 error: nil];
        NSString *serializedParameters = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
        
        self.eventCallback(msg_type, serializedParameters);
    }
}

@end
