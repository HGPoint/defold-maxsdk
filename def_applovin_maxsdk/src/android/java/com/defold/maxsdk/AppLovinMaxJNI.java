package com.defold.maxsdk;

import android.app.Activity;
import android.graphics.Color;
import android.view.Gravity;
import android.view.View;
import android.view.WindowManager;
import android.widget.RelativeLayout;

import androidx.annotation.NonNull;

import com.applovin.mediation.MaxAd;
import com.applovin.mediation.MaxAdFormat;
import com.applovin.mediation.MaxAdListener;
import com.applovin.mediation.MaxAdViewAdListener;
import com.applovin.mediation.MaxAdWaterfallInfo;
import com.applovin.mediation.MaxError;
import com.applovin.mediation.MaxMediatedNetworkInfo;
import com.applovin.mediation.MaxNetworkResponseInfo;
import com.applovin.mediation.MaxReward;
import com.applovin.mediation.MaxRewardedAdListener;
import com.applovin.mediation.ads.MaxAdView;
import com.applovin.mediation.ads.MaxInterstitialAd;
import com.applovin.mediation.ads.MaxRewardedAd;
import com.applovin.sdk.AppLovinMediationProvider;
import com.applovin.sdk.AppLovinPrivacySettings;
import com.applovin.sdk.AppLovinSdk;
import com.applovin.sdk.AppLovinSdkUtils;

import com.amazon.device.ads.AdError;
import com.amazon.device.ads.AdRegistration;
import com.amazon.device.ads.DTBAdCallback;
import com.amazon.device.ads.DTBAdNetwork;
import com.amazon.device.ads.DTBAdNetworkInfo;
import com.amazon.device.ads.DTBAdRequest;
import com.amazon.device.ads.DTBAdResponse;
import com.amazon.device.ads.DTBAdSize;
import com.amazon.device.ads.MRAIDPolicy;

import java.util.HashMap;
import java.util.Map;

import org.json.JSONObject;
import org.json.JSONException;

public class AppLovinMaxJNI {

//    private static final String TAG = "AppLovinMaxJNI";

    public static native void maxsdkAddToQueue(int msg, String json);

    // CONSTANTS:
    // duplicate of enums from maxsdk_callback_private.h:
    private static final int MSG_INTERSTITIAL = 1;
    private static final int MSG_REWARDED = 2;
    private static final int MSG_BANNER = 3;
    private static final int MSG_INITIALIZATION = 4;

    private static final int EVENT_CLOSED = 1;
    private static final int EVENT_FAILED_TO_SHOW = 2;
    private static final int EVENT_OPENING = 3;
    private static final int EVENT_FAILED_TO_LOAD = 4;
    private static final int EVENT_LOADED = 5;
    private static final int EVENT_NOT_LOADED = 6;
    private static final int EVENT_EARNED_REWARD = 7;
    private static final int EVENT_COMPLETE = 8;
    private static final int EVENT_CLICKED = 9;
    private static final int EVENT_DESTROYED = 10;
    private static final int EVENT_EXPANDED = 11;
    private static final int EVENT_COLLAPSED = 12;
    private static final int EVENT_REVENUE_PAID = 13;
    private static final int EVENT_SIZE_UPDATE = 14;
    private static final int EVENT_FAILED_TO_LOAD_WATERFALL = 15;

    // duplicate of enums from maxsdk_private.h:
    private static final int SIZE_BANNER = 0;
    private static final int SIZE_LEADER = 1;
    private static final int SIZE_MREC = 2;

    private static final int POS_NONE = 0;
    private static final int POS_TOP_LEFT = 1;
    private static final int POS_TOP_CENTER = 2;
    private static final int POS_TOP_RIGHT = 3;
    private static final int POS_BOTTOM_LEFT = 4;
    private static final int POS_BOTTOM_CENTER = 5;
    private static final int POS_BOTTOM_RIGHT = 6;
    private static final int POS_CENTER = 7;
    
    
    private static final String MSG_KEY_EVENT = "event";
    private static final String MSG_KEY_AD_NETWORK = "ad_network";
    private static final String MSG_KEY_REVENUE = "revenue";
    private static final String MSG_KEY_AD_UNIT_ID = "ad_unit_id";
    private static final String MSG_KEY_CODE = "code";
    private static final String MSG_KEY_ERROR = "error";
    private static final String MSG_KEY_X_POS = "x";
    private static final String MSG_KEY_Y_POS = "y";
    
    // END CONSTANTS

    // Fullscreen Ad Fields
    private final Map<String, MaxInterstitialAd> mInterstitials = new HashMap<>(2);
    private final Map<String, MaxRewardedAd> mRewardedAds = new HashMap<>(2);
    private final HashMap<String, Boolean> mInterstitialAdsAmazon = new HashMap<>();
    private String amazonBannerSlotId = null;

    private final Activity mActivity;

    public AppLovinMaxJNI(final Activity activity) {
        mActivity = activity;
    }

    public void initialize(String AmazonAppId) {
        AdRegistration.getInstance(AmazonAppId, mActivity);
        AdRegistration.setAdNetworkInfo(new DTBAdNetworkInfo(DTBAdNetwork.MAX));
        AdRegistration.setMRAIDSupportedVersions(new String[]{"1.0", "2.0", "3.0"});
        AdRegistration.setMRAIDPolicy(MRAIDPolicy.CUSTOM);


        AppLovinSdk.getInstance(mActivity).setMediationProvider(AppLovinMediationProvider.MAX);
        AppLovinSdk.getInstance(mActivity).initializeSdk(config -> sendSimpleMessage(MSG_INITIALIZATION, EVENT_COMPLETE));
    }

    private MaxInterstitialAd retrieveInterstitial(String adUnitId) {
        MaxInterstitialAd result = mInterstitials.get(adUnitId);
        if (result == null) {
            result = new MaxInterstitialAd(adUnitId, mActivity);
            result.setListener(new MaxAdListener() {
                @Override
                public void onAdLoaded(MaxAd ad) {
                    sendSimpleMessage(MSG_INTERSTITIAL, EVENT_LOADED, ad);
                }

                @Override
                public void onAdLoadFailed(String adUnitId, final MaxError maxError) {
                    sendFailedToLoadMessage(MSG_INTERSTITIAL, adUnitId, maxError);
                }

                @Override
                public void onAdDisplayed(MaxAd ad) {
                    sendSimpleMessage(MSG_INTERSTITIAL, EVENT_OPENING, ad);
                }

                @Override
                public void onAdDisplayFailed(MaxAd ad, final MaxError maxError) {
                    sendFailedToShowMessage(MSG_INTERSTITIAL, ad, maxError);
                }

                @Override
                public void onAdHidden(MaxAd ad) {
                    sendSimpleMessage(MSG_INTERSTITIAL, EVENT_CLOSED, ad);
                }

                @Override
                public void onAdClicked(MaxAd ad) {
                    sendSimpleMessage(MSG_INTERSTITIAL, EVENT_CLICKED, ad);
                }
            });

            result.setRevenueListener(ad -> sendSimpleMessage(MSG_INTERSTITIAL, EVENT_REVENUE_PAID, ad));

            mInterstitials.put(adUnitId, result);
        }

        return result;
    }

    private MaxRewardedAd retrieveRewardedAd(String adUnitId) {
        MaxRewardedAd result = mRewardedAds.get(adUnitId);
        if (result == null) {
            result = MaxRewardedAd.getInstance(adUnitId, mActivity);
            result.setListener(new MaxRewardedAdListener() {
                @Override
                public void onAdLoaded(MaxAd ad) {
                    sendSimpleMessage(MSG_REWARDED, EVENT_LOADED, ad);
                }

                @Override
                public void onAdLoadFailed(String adUnitId, final MaxError maxError) {
                    sendFailedToLoadMessage(MSG_REWARDED, adUnitId, maxError);
                }

                @Override
                public void onAdDisplayed(MaxAd ad) {
                    sendSimpleMessage(MSG_REWARDED, EVENT_OPENING, ad);
                }

                @Override
                public void onAdDisplayFailed(MaxAd ad, final MaxError maxError) {
                    sendFailedToShowMessage(MSG_REWARDED, ad, maxError);
                }

                @Override
                public void onAdHidden(MaxAd ad) {
                    sendSimpleMessage(MSG_REWARDED, EVENT_CLOSED, ad);
                }

                @Override
                public void onAdClicked(MaxAd ad) {
                    sendSimpleMessage(MSG_REWARDED, EVENT_CLICKED, ad);
                }

                @Override
                public void onRewardedVideoStarted(MaxAd ad) {
                }

                @Override
                public void onRewardedVideoCompleted(MaxAd ad) {
                }

                @Override
                public void onUserRewarded(MaxAd ad, MaxReward reward) {
                    sendSimpleMessage(MSG_REWARDED, EVENT_EARNED_REWARD, ad);
                }
            });

            result.setRevenueListener(ad -> sendSimpleMessage(MSG_REWARDED, EVENT_REVENUE_PAID, ad));

            mRewardedAds.put(adUnitId, result);
        }

        return result;
    }

    public void onActivateApp() {
        resumeBanner();
    }

    public void onDeactivateApp() {
        pauseBanner();
    }

    public void setMuted(boolean muted) {
        AppLovinSdk.getInstance(mActivity).getSettings().setMuted(muted);
    }

    public void setVerboseLogging(boolean isVerboseLoggingEnabled) {
        AppLovinSdk.getInstance(mActivity).getSettings().setVerboseLogging(isVerboseLoggingEnabled);
    }

    public void setHasUserConsent(boolean hasUserConsent) {
        AppLovinPrivacySettings.setHasUserConsent(hasUserConsent, mActivity);
    }

    public void setIsAgeRestrictedUser(boolean isAgeRestrictedUser) {
        AppLovinPrivacySettings.setIsAgeRestrictedUser(isAgeRestrictedUser, mActivity);
    }

    public void setDoNotSell(boolean doNotSell) {
        AppLovinPrivacySettings.setDoNotSell(doNotSell, mActivity);
    }

    public void openMediationDebugger() {
        AppLovinSdk.getInstance(mActivity).showMediationDebugger();
    }

    // https://www.baeldung.com/java-json-escaping
    private String getJsonConversionErrorMessage(String messageText) {
        String message;
        try {
            JSONObject obj = new JSONObject();
            obj.put(MSG_KEY_ERROR, messageText);
            message = obj.toString();
        } catch (JSONException e) {
            message = "{ \"error\": \"Error while converting simple message to JSON.\" }";
        }
        return message;
    }

    private String getErrorMessage(final String adUnitId, final MaxError maxError) {
        return String.format("%s\n%s\nAdUnitId:%s", maxError.getMessage(), maxError.getMediatedNetworkErrorMessage(), adUnitId);
    }

    private String getErrorMessage(final MaxAd ad, MaxError maxError) {
        return String.format("%s\nFormat:%s AdUnitId:%s Network:%s",
                maxError.getMessage(), ad.getFormat(), ad.getAdUnitId(), ad.getNetworkName());
    }

    private void sendSimpleMessage(int msg, int eventId, MaxAd ad) {
        String message;
        try {
            JSONObject obj = new JSONObject();
            obj.put(MSG_KEY_EVENT, eventId);
            obj.put(MSG_KEY_AD_NETWORK, ad.getNetworkName());
            obj.put(MSG_KEY_REVENUE, ad.getRevenue());
            obj.put(MSG_KEY_AD_UNIT_ID, ad.getAdUnitId());
            message = obj.toString();
        } catch (JSONException e) {
            message = getJsonConversionErrorMessage(e.getMessage());
        }
        maxsdkAddToQueue(msg, message);
    }

    private void sendFailedToShowMessage(int msg, final MaxAd ad, MaxError maxError) {
        String message;
        try {
            JSONObject obj = new JSONObject();
            obj.put(MSG_KEY_EVENT, EVENT_FAILED_TO_SHOW);
            obj.put(MSG_KEY_AD_NETWORK, ad.getNetworkName());
            obj.put(MSG_KEY_REVENUE, ad.getRevenue());
            obj.put(MSG_KEY_AD_UNIT_ID, ad.getAdUnitId());
            obj.put(MSG_KEY_CODE, maxError.getCode());
            obj.put(MSG_KEY_ERROR, getErrorMessage(ad, maxError));
            message = obj.toString();
        } catch (JSONException e) {
            message = getJsonConversionErrorMessage(e.getMessage());
        }
        maxsdkAddToQueue(msg, message);
    }


    private void sendFailedToLoadMessage(int msg, String adUnitId, MaxError maxError) {
        String message;
        try {
            JSONObject obj = new JSONObject();
            obj.put(MSG_KEY_EVENT, EVENT_FAILED_TO_LOAD);
            obj.put(MSG_KEY_CODE, maxError.getCode());
            obj.put(MSG_KEY_ERROR, getErrorMessage(adUnitId, maxError));
            message = obj.toString();
        } catch (JSONException e) {
            message = getJsonConversionErrorMessage(e.getMessage());
        }
        maxsdkAddToQueue(msg, message);

        MaxAdWaterfallInfo waterfall = maxError.getWaterfall();
        if (waterfall != null) {
            for (MaxNetworkResponseInfo networkResponse : waterfall.getNetworkResponses()) {
                MaxMediatedNetworkInfo network = networkResponse.getMediatedNetwork();
                if (network != null) {
                    String waterfall_message;
                    try {
                        JSONObject obj = new JSONObject();
                        obj.put(MSG_KEY_EVENT, EVENT_FAILED_TO_LOAD_WATERFALL);
                        obj.put(MSG_KEY_CODE, networkResponse.getError().getCode());
                        obj.put(MSG_KEY_ERROR, getErrorMessage(adUnitId, maxError));
                        obj.put(MSG_KEY_AD_NETWORK, network.getName());
                        waterfall_message = obj.toString();
                    } catch (JSONException e) {
                        waterfall_message = getJsonConversionErrorMessage(e.getMessage());
                    }
                    maxsdkAddToQueue(msg, waterfall_message);
                }
            }
        }
    }

    private void sendSimpleMessage(int msg, int eventId) {
        String message;
        try {
            JSONObject obj = new JSONObject();
            obj.put(MSG_KEY_EVENT, eventId);
            message = obj.toString();
        } catch (JSONException e) {
            message = getJsonConversionErrorMessage(e.getMessage());
        }
        maxsdkAddToQueue(msg, message);
    }

    private void sendNotLoadedMessage(int msg, String messageStr) {
        String message;
        try {
            JSONObject obj = new JSONObject();
            obj.put(MSG_KEY_EVENT, EVENT_NOT_LOADED);
            obj.put(MSG_KEY_ERROR, messageStr);
            message = obj.toString();
        } catch (JSONException e) {
            message = getJsonConversionErrorMessage(e.getMessage());
        }
        maxsdkAddToQueue(msg, message);
    }

    private void sendBannerSizeChangedMessage(int sizeX, int sizeY) {
        String message;
        try {
            JSONObject obj = new JSONObject();
            obj.put(MSG_KEY_EVENT, EVENT_SIZE_UPDATE);
            obj.put(MSG_KEY_X_POS, sizeX);
            obj.put(MSG_KEY_Y_POS, sizeY);
            message = obj.toString();
        } catch (JSONException e) {
            message = getJsonConversionErrorMessage(e.getMessage());
        }
        maxsdkAddToQueue(MSG_BANNER, message);
    }

//--------------------------------------------------
// Interstitial ADS

    public void loadInterstitial(final String unitId, final String amazonSlotID) {
        mActivity.runOnUiThread(() -> {
            final MaxInterstitialAd adInstance = retrieveInterstitial(unitId);
            if (mInterstitialAdsAmazon.get(unitId) == null) {
                DTBAdRequest adLoader = new DTBAdRequest();
                adLoader.setSizes(new DTBAdSize.DTBInterstitialAdSize(amazonSlotID));
                adLoader.loadAd(new DTBAdCallback() {
                    @Override
                    public void onSuccess(@NonNull final DTBAdResponse dtbAdResponse) {
                        mInterstitialAdsAmazon.put(unitId, true);
                        adInstance.setLocalExtraParameter("amazon_ad_response", dtbAdResponse);
                        adInstance.loadAd();
                    }

                    @Override
                    public void onFailure(@NonNull final AdError adError) {
                        mInterstitialAdsAmazon.put(unitId, false);
                        adInstance.setLocalExtraParameter("amazon_ad_error", adError);
                        adInstance.loadAd();
                    }
                });
            } else {
                adInstance.loadAd();
            }
        });
    }

    public void showInterstitial(final String unitId, final String placement) {
        mActivity.runOnUiThread(() -> {
            if (isInterstitialLoaded(unitId)) {
                retrieveInterstitial(unitId).showAd(placement);
            } else {
                sendNotLoadedMessage(MSG_INTERSTITIAL,
                        "Can't show Interstitial AD that wasn't loaded.");
            }
        });
    }

    public boolean isInterstitialLoaded(final String unitId) {
        return retrieveInterstitial(unitId).isReady();
    }

    //--------------------------------------------------
// Rewarded ADS
    public void loadRewarded(final String unitId, final String amazonSlotID) {
        mActivity.runOnUiThread(() -> {
            final MaxRewardedAd adInstance = retrieveRewardedAd(unitId);
            adInstance.loadAd();
        });
    }

    public void showRewarded(final String unitId, final String placement) {
        mActivity.runOnUiThread(() -> {
            if (isRewardedLoaded(unitId)) {
                retrieveRewardedAd(unitId).showAd(placement);
            } else {
                sendNotLoadedMessage(MSG_REWARDED,
                        "Can't show Rewarded AD that wasn't loaded.");
            }
        });
    }

    public boolean isRewardedLoaded(final String unitId) {
        return retrieveRewardedAd(unitId).isReady();
    }

//--------------------------------------------------
// Banner ADS

    private enum BannerState {
        /**
         * No loaded banner
         */
        NONE,

        /**
         * Banner is loaded but not visible
         */
        HIDDEN,

        /**
         * Banner is loaded and visible, auto-refresh enabled
         */
        SHOWN,

        /**
         * Needs to relayout banner and resume auto-refresh after app activated (focused)
         */
        PAUSED,
    }


    private BannerState mBannerState = BannerState.NONE;
    private int mBannerSize = SIZE_BANNER;
    private String mBannerUnit = null;
    private String mBannerPlacement = null;
    private RelativeLayout mBannerLayout;
    private MaxAd mLoadedBanner;
    private MaxAdView mBannerAdView;
    private int mBannerGravity = Gravity.NO_GRAVITY;

    public void loadBanner(final String unitId, final String amazonSlotId, final int bannerSize) {
        if (amazonSlotId != null) {
            amazonBannerSlotId = amazonSlotId;
        }
        mActivity.runOnUiThread(() -> {
            destroyBannerUiThread();
            MaxAdFormat adFormat = getMaxAdFormat(bannerSize);
            mBannerAdView = new MaxAdView(unitId, adFormat, mActivity);
            final MaxAdView view = mBannerAdView;
            view.setBackgroundColor(Color.TRANSPARENT);
            view.setListener(new MaxAdViewAdListener() {
                @Override
                public void onAdExpanded(MaxAd ad) {
                    sendSimpleMessage(MSG_BANNER, EVENT_EXPANDED, ad);
                }

                @Override
                public void onAdCollapsed(MaxAd ad) {
                    sendSimpleMessage(MSG_BANNER, EVENT_COLLAPSED, ad);
                }

                @Override
                public void onAdLoaded(final MaxAd ad) {
                    mActivity.runOnUiThread(() -> {
                        if (view != mBannerAdView) {
                            view.destroy();
                            return;
                        }

                        mBannerUnit = unitId;
                        mBannerSize = bannerSize;
                        mLoadedBanner = ad;

                        // if banner was reloaded after destroying on focus lost - force show it
                        if (mBannerState == BannerState.PAUSED) {
                            mBannerAdView.setPlacement(mBannerPlacement);
                            showBannerUiThread();
                        }

                        sendSimpleMessage(MSG_BANNER, EVENT_LOADED, ad);
                    });
                }

                @Override
                public void onAdLoadFailed(String adUnitId, final MaxError maxError) {
                    sendFailedToLoadMessage(MSG_BANNER, adUnitId, maxError);
                }

                @Override
                public void onAdDisplayed(MaxAd ad) {
                    // DO NOT USE - THIS IS RESERVED FOR FULLSCREEN ADS ONLY AND WILL BE REMOVED IN A FUTURE SDK RELEASE
                }

                @Override
                public void onAdHidden(MaxAd ad) {
                    // DO NOT USE - THIS IS RESERVED FOR FULLSCREEN ADS ONLY AND WILL BE REMOVED IN A FUTURE SDK RELEASE
                }

                @Override
                public void onAdClicked(MaxAd ad) {
                    sendSimpleMessage(MSG_BANNER, EVENT_CLICKED, ad);
                }

                @Override
                public void onAdDisplayFailed(MaxAd ad, final MaxError maxError) {
                    sendFailedToShowMessage(MSG_BANNER, ad, maxError);
                }
            });

            view.setRevenueListener(ad -> sendSimpleMessage(MSG_BANNER, EVENT_REVENUE_PAID, ad));

            // Raw size will be 320x50 for BANNERs on phones, and 728x90 for LEADERs on tablets
            AppLovinSdkUtils.Size rawSize = adFormat.getSize();
            DTBAdSize size = new DTBAdSize(rawSize.getWidth(), rawSize.getHeight(), amazonSlotId);

            DTBAdRequest adLoader = new DTBAdRequest();
            adLoader.setSizes(size);
            adLoader.loadAd(new DTBAdCallback() {
                @Override
                public void onSuccess(@NonNull final DTBAdResponse dtbAdResponse) {
                    view.setLocalExtraParameter("amazon_ad_response", dtbAdResponse);
                    view.loadAd();
                    view.setExtraParameter("allow_pause_auto_refresh_immediately", "true");
                    view.stopAutoRefresh();
                }

                @Override
                public void onFailure(@NonNull final AdError adError) {

                    view.setLocalExtraParameter("amazon_ad_error", adError);
                    view.loadAd();
                    view.setExtraParameter("allow_pause_auto_refresh_immediately", "true");
                    view.stopAutoRefresh();
                }
            });
        });
    }

    public void destroyBanner() {
        mActivity.runOnUiThread(this::destroyBannerUiThread);
    }

    public void showBanner(final int pos, final String placement) {
        mActivity.runOnUiThread(() -> {
            if (isBannerLoaded()) {
                mBannerPlacement = placement;
                mBannerGravity = getGravity(pos);
                mBannerAdView.setPlacement(placement);
                showBannerUiThread();
            } else {
                sendNotLoadedMessage(MSG_BANNER,
                        "Can't show Banner AD that wasn't loaded.");
            }
        });
    }

    public void hideBanner() {
        mActivity.runOnUiThread(() -> {
            if (isBannerLoaded()) {
                if (mBannerAdView != null) {
                    mBannerAdView.setExtraParameter("allow_pause_auto_refresh_immediately", "true");
                    mBannerAdView.stopAutoRefresh();
                }
                if (mBannerLayout != null) {
                    removeBannerLayout();
                }
                mBannerState = BannerState.HIDDEN;
            }
        });
    }

    public boolean isBannerLoaded() {
        return mBannerAdView != null && mLoadedBanner != null;
    }

    public boolean isBannerShown() {
        return isBannerLoaded() && mBannerState == BannerState.SHOWN;
    }

    private void destroyBannerUiThread() {
        if (!isBannerLoaded()) {
            return;
        }

        mBannerAdView.setExtraParameter("allow_pause_auto_refresh_immediately", "true");
        mBannerAdView.stopAutoRefresh();
        mBannerAdView.destroy();
        removeBannerLayout();
        mBannerAdView = null;
        mLoadedBanner = null;
        mBannerState = BannerState.NONE;
        sendSimpleMessage(MSG_BANNER, EVENT_DESTROYED);
    }

    private void showBannerUiThread() {
        recreateBannerLayout(mBannerAdView, mLoadedBanner.getFormat());
        mBannerAdView.setBackgroundColor(Color.TRANSPARENT);
        mBannerAdView.startAutoRefresh();
        mBannerState = BannerState.SHOWN;
    }

    private void pauseBanner() {
        mActivity.runOnUiThread(() -> {
            if (isBannerShown()) {
                destroyBannerUiThread();
                mBannerState = BannerState.PAUSED;
            }
        });
    }

    private void resumeBanner() {
        if (mBannerState == BannerState.PAUSED) {
            loadBanner(mBannerUnit, amazonBannerSlotId, mBannerSize);
        }
    }

    private int getGravity(final int bannerPosConst) {
        int bannerPos = Gravity.NO_GRAVITY; //POS_NONE
        switch (bannerPosConst) {
            case POS_TOP_LEFT:
                bannerPos = Gravity.TOP | Gravity.LEFT;
                break;
            case POS_TOP_CENTER:
                bannerPos = Gravity.TOP | Gravity.CENTER_HORIZONTAL;
                break;
            case POS_TOP_RIGHT:
                bannerPos = Gravity.TOP | Gravity.RIGHT;
                break;
            case POS_BOTTOM_LEFT:
                bannerPos = Gravity.BOTTOM | Gravity.LEFT;
                break;
            case POS_BOTTOM_CENTER:
                bannerPos = Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL;
                break;
            case POS_BOTTOM_RIGHT:
                bannerPos = Gravity.BOTTOM | Gravity.RIGHT;
                break;
            case POS_CENTER:
                bannerPos = Gravity.CENTER;
                break;
        }
        return bannerPos;
    }

    private MaxAdFormat getMaxAdFormat(final int bannerSizeConst) {
        switch (bannerSizeConst) {
            case SIZE_MREC:
                return MaxAdFormat.MREC;
            case SIZE_LEADER:
                return MaxAdFormat.LEADER;
            case SIZE_BANNER:
            default:
                return MaxAdFormat.BANNER;
        }
    }

    private void removeBannerLayout() {
        if (mBannerLayout != null) {
            mBannerLayout.setVisibility(View.GONE);
            mBannerLayout.removeAllViews();
            mActivity.getWindowManager().removeView(mBannerLayout);
            mBannerLayout = null;
        }
    }

    private void update_banner_size(MaxAdFormat adFormat) {
        AppLovinSdkUtils.Size adSize = adFormat.getSize();
        int widthDp = adSize.getWidth();
        int heightDp = adSize.getHeight();
        int widthPx = AppLovinSdkUtils.dpToPx(mActivity, widthDp);
        int heightPx = AppLovinSdkUtils.dpToPx(mActivity, heightDp);

        sendBannerSizeChangedMessage(widthPx, heightPx);
    }

    private void recreateBannerLayout(MaxAdView adView, MaxAdFormat adFormat) {
        removeBannerLayout();
        mBannerLayout = new RelativeLayout(mActivity);
        mBannerLayout.setSystemUiVisibility(
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                        | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                        | View.SYSTEM_UI_FLAG_FULLSCREEN
                        | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
        mBannerLayout.addView(adView, getAdLayoutParams(adFormat));
        mActivity.getWindowManager().addView(mBannerLayout, getWindowLayoutParams());
        update_banner_size(adFormat);
    }

    private WindowManager.LayoutParams getWindowLayoutParams() {
        WindowManager.LayoutParams windowParams = new WindowManager.LayoutParams();
        windowParams.x = WindowManager.LayoutParams.WRAP_CONTENT;
        windowParams.y = WindowManager.LayoutParams.WRAP_CONTENT;
        windowParams.width = WindowManager.LayoutParams.WRAP_CONTENT;
        windowParams.height = WindowManager.LayoutParams.WRAP_CONTENT;
        windowParams.flags = WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL | WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE;
        windowParams.gravity = mBannerGravity;
        return windowParams;
    }

    private RelativeLayout.LayoutParams getAdLayoutParams(MaxAdFormat adFormat) {
        // TODO how to determine is adaptive banner? see MaxAdFormat.getAdaptiveSize()
        // NOTE: Only AdMob / Google Ad Manager currently has support for adaptive banners and the maximum height is 15% the height of the screen.
        AppLovinSdkUtils.Size adSize = adFormat.getSize();
        int widthDp = adSize.getWidth();
        int heightDp = adSize.getHeight();
        int widthPx = AppLovinSdkUtils.dpToPx(mActivity, widthDp);
        int heightPx = AppLovinSdkUtils.dpToPx(mActivity, heightDp);
        int width = (adFormat == MaxAdFormat.MREC) ? widthPx : RelativeLayout.LayoutParams.MATCH_PARENT;
        RelativeLayout.LayoutParams adParams = new RelativeLayout.LayoutParams(width, heightPx);
        adParams.setMargins(0, 0, 0, 0);
        return adParams;
    }
}