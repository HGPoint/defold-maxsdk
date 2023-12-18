#pragma once

namespace dmAppLovinMax {

enum BannerSize
{
    SIZE_BANNER =           0,
    SIZE_LEADER =           1,
    SIZE_MREC =             2,
};

enum BannerPosition
{
    POS_NONE =              0,
    POS_TOP_LEFT =          1,
    POS_TOP_CENTER =        2,
    POS_TOP_RIGHT =         3,
    POS_BOTTOM_LEFT =       4,
    POS_BOTTOM_CENTER =     5,
    POS_BOTTOM_RIGHT =      6,
    POS_CENTER =            7
};

void Initialize_Ext();
void OnActivateApp();
void OnDeactivateApp();

void Initialize(const char* amazonAppId);
void ShowConsentFlow();
void SetMuted(bool muted);
void SetVerboseLogging(bool verbose);
void SetHasUserConsent(bool hasConsent);
void SetIsAgeRestrictedUser(bool ageRestricted);
void SetDoNotSell(bool doNotSell);
//void SetFbDataProcessingOptions(const char* cstr, int cint1, int cint2);
void OpenMediationDebugger();

void LoadInterstitial(const char* unitId, const char* amazonSlotID);
void ShowInterstitial(const char* unitId, const char* placement);
bool IsInterstitialLoaded(const char* unitId);

void LoadRewarded(const char* unitId, const char* amazonSlotID);
void ShowRewarded(const char* unitId, const char* placement);
bool IsRewardedLoaded(const char* unitId);

void LoadBanner(const char* unitId, const char* amazonSlotID, BannerSize bannerSize);
void DestroyBanner();
void ShowBanner(BannerPosition bannerPos, const char* placement);
void HideBanner();
bool IsBannerLoaded();
bool IsBannerShown();

} //namespace dmAppLovinMax
