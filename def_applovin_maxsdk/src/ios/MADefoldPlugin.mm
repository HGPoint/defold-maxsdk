#import "MADefoldPlugin.h"

#define KEY_WINDOW [UIApplication sharedApplication].keyWindow
#define DEVICE_SPECIFIC_ADVIEW_AD_FORMAT ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) ? MAAdFormat.leader : MAAdFormat.banner


@interface MADefoldPlugin()<MAAdRevenueDelegate, MAAdDelegate, MAAdViewAdDelegate, MARewardedAdDelegate>

// Parent Fields
@property (nonatomic, weak) ALSdk *sdk;


// Fullscreen Ad Fields
@property (nonatomic, strong) NSMutableDictionary<NSString *, MAInterstitialAd *> *interstitials;
@property (nonatomic, strong) NSMutableDictionary<NSString *, MARewardedAd *> *rewardedAds;

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

#pragma mark - Initialization

- (instancetype)init:(DefoldEventCallback)eventCallback
{
    self = [super init];
    if ( self )
    {
        self.interstitials = [NSMutableDictionary dictionaryWithCapacity: 2];
        self.rewardedAds = [NSMutableDictionary dictionaryWithCapacity: 2];
        self.eventCallback = eventCallback;
        self.sdk = [ALSdk shared];
        self.sdk.mediationProvider = ALMediationProviderMAX;
        [self.sdk setPluginVersion: @"defold-maxsdk"];
        [self.sdk initializeSdkWithCompletionHandler:^(ALSdkConfiguration *configuration) {
            // Start loading ads
            [self sendDefoldEvent: MSG_INITIALIZATION event_id: EVENT_COMPLETE parameters: @{@"plugin":@"defold-maxsdk"}];
        }];
    }
    return self;
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
    if ( MAAdFormat.interstitial == adFormat )
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
    if ( self.interstitials[adUnitIdentifier] )
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
}

- (void)didClickAd:(MAAd *)ad
{
    int type;
    MAAdFormat *adFormat = ad.format;
    if ( MAAdFormat.interstitial == adFormat )
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

- (void)didPayRevenueForAd:(MAAd *)ad
{
    int type;
    MAAdFormat *adFormat = ad.format;
    if ( MAAdFormat.interstitial == adFormat )
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

#pragma mark - Utility Methods

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
