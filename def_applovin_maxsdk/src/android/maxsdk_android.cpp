#if defined(DM_PLATFORM_ANDROID)

#include <jni.h>
#include <dmsdk/dlib/android.h>

#include "../maxsdk_private.h"
#include "../maxsdk_callback_private.h"
#include "maxsdk_jni.h"
#include "com_defold_maxsdk_AppLovinMaxJNI.h"

JNIEXPORT void JNICALL Java_com_defold_maxsdk_AppLovinMaxJNI_maxsdkAddToQueue(JNIEnv * env, jclass cls, jint jmsg, jstring jjson)
{
    const char* json = env->GetStringUTFChars(jjson, 0);
    dmAppLovinMax::AddToQueueCallback((dmAppLovinMax::MessageId)jmsg, json);
    env->ReleaseStringUTFChars(jjson, json);
}

namespace dmAppLovinMax {

struct AppLovin
{
    jobject        m_AppLovinMaxJNI;

    jmethodID      m_Initialize;
    jmethodID      m_ShowConsentFlow;
    jmethodID      m_OnActivateApp;
    jmethodID      m_OnDeactivateApp;
    jmethodID      m_SetMuted;
    jmethodID      m_SetVerboseLogging;
    jmethodID      m_SetHasUserConsent;
    jmethodID      m_SetIsAgeRestrictedUser;
    jmethodID      m_SetDoNotSell;
    jmethodID      m_OpenMediationDebugger;

    jmethodID      m_LoadInterstitial;
    jmethodID      m_ShowInterstitial;
    jmethodID      m_IsInterstitialLoaded;

    jmethodID      m_LoadRewarded;
    jmethodID      m_ShowRewarded;
    jmethodID      m_IsRewardedLoaded;

    jmethodID      m_LoadBanner;
    jmethodID      m_DestroyBanner;
    jmethodID      m_ShowBanner;
    jmethodID      m_HideBanner;
    jmethodID      m_IsBannerLoaded;
    jmethodID      m_IsBannerShown;
};

static AppLovin       g_maxsdk;

static void CallVoidMethod(jobject instance, jmethodID method)
{
    dmAndroid::ThreadAttacher threadAttacher;
    JNIEnv* env = threadAttacher.GetEnv();

    env->CallVoidMethod(instance, method);
}

static bool CallBoolMethod(jobject instance, jmethodID method)
{
    dmAndroid::ThreadAttacher threadAttacher;
    JNIEnv* env = threadAttacher.GetEnv();

    jboolean return_value = (jboolean)env->CallBooleanMethod(instance, method);
    return JNI_TRUE == return_value;
}

static bool CallBoolMethodChar(jobject instance, jmethodID method, const char* cstr)
{
    dmAndroid::ThreadAttacher threadAttacher;
    JNIEnv* env = threadAttacher.GetEnv();
    
    jstring jstr = NULL;
    if (cstr)
    {
        jstr = env->NewStringUTF(cstr);
    }

    jboolean return_value = (jboolean)env->CallBooleanMethod(instance, method, jstr);
    
    if (cstr)
    {
        jstr = env->NewStringUTF(cstr);
    }
    return JNI_TRUE == return_value;
}

static void CallVoidMethodBool(jobject instance, jmethodID method, bool cbool)
{
    dmAndroid::ThreadAttacher threadAttacher;
    JNIEnv* env = threadAttacher.GetEnv();

    env->CallVoidMethod(instance, method, cbool);
}

static void CallVoidMethodChar(jobject instance, jmethodID method, const char* cstr)
{
    dmAndroid::ThreadAttacher threadAttacher;
    JNIEnv* env = threadAttacher.GetEnv();

    jstring jstr = NULL;
    if (cstr)
    {
        jstr = env->NewStringUTF(cstr);
    }

    env->CallVoidMethod(instance, method, jstr);

    if (cstr)
    {
        env->DeleteLocalRef(jstr);
    }
}

static void CallVoidMethodCharChar(jobject instance, jmethodID method, const char* cstr1, const char* cstr2)
{
    dmAndroid::ThreadAttacher threadAttacher;
    JNIEnv* env = threadAttacher.GetEnv();

    jstring jstr1 = NULL;
    if (cstr1)
    {
        jstr1 = env->NewStringUTF(cstr1);
    }

    jstring jstr2 = NULL;
    if (cstr2)
    {
        jstr2 = env->NewStringUTF(cstr2);
    }

    env->CallVoidMethod(instance, method, jstr1, jstr2);

    if (cstr1)
    {
        env->DeleteLocalRef(jstr1);
    }

    if (cstr2)
    {
        env->DeleteLocalRef(jstr2);
    }
}


static void CallVoidMethodCharCharChar(jobject instance, jmethodID method, const char* cstr1, const char* cstr2, const char* cstr3)
{
    dmAndroid::ThreadAttacher threadAttacher;
    JNIEnv* env = threadAttacher.GetEnv();

    jstring jstr1 = NULL;
    if (cstr1)
    {
        jstr1 = env->NewStringUTF(cstr1);
    }

    jstring jstr2 = NULL;
    if (cstr2)
    {
        jstr2 = env->NewStringUTF(cstr2);
    }
    
    jstring jstr3 = NULL;
    if (cstr3)
    {
        jstr3 = env->NewStringUTF(cstr3);
    }

    env->CallVoidMethod(instance, method, jstr1, jstr2, jstr3);

    if (cstr1)
    {
        env->DeleteLocalRef(jstr1);
    }

    if (cstr2)
    {
        env->DeleteLocalRef(jstr2);
    }
    
    if (cstr3)
    {
        env->DeleteLocalRef(jstr3);
    }
}

static void CallVoidMethodCharInt(jobject instance, jmethodID method, const char* cstr, int cint)
{
    dmAndroid::ThreadAttacher threadAttacher;
    JNIEnv* env = threadAttacher.GetEnv();

    jstring jstr = env->NewStringUTF(cstr);
    env->CallVoidMethod(instance, method, jstr, cint);
    env->DeleteLocalRef(jstr);
}

static void CallVoidMethodCharCharInt(jobject instance, jmethodID method, const char* cstr, const char* cstr1, int cint)
{
    dmAndroid::ThreadAttacher threadAttacher;
    JNIEnv* env = threadAttacher.GetEnv();

    jstring jstr = env->NewStringUTF(cstr);
    jstring jstr1 = env->NewStringUTF(cstr1);
    env->CallVoidMethod(instance, method, jstr, jstr1, cint);
    env->DeleteLocalRef(jstr);
    env->DeleteLocalRef(jstr1);
}

static void CallVoidMethodIntChar(jobject instance, jmethodID method, int cint, const char* cstr)
{
    dmAndroid::ThreadAttacher threadAttacher;
    JNIEnv* env = threadAttacher.GetEnv();

    jstring jstr = NULL;
    if (cstr)
    {
        jstr = env->NewStringUTF(cstr);
    }

    env->CallVoidMethod(instance, method, cint, jstr);

    if (cstr)
    {
        env->DeleteLocalRef(jstr);
    }
}

static void CallVoidMethodInt(jobject instance, jmethodID method, int cint)
{
    dmAndroid::ThreadAttacher threadAttacher;
    JNIEnv* env = threadAttacher.GetEnv();

    env->CallVoidMethod(instance, method, cint);
}

static void InitJNIMethods(JNIEnv* env, jclass cls)
{
    g_maxsdk.m_Initialize             = env->GetMethodID(cls, "initialize", "(Ljava/lang/String;)V");
    g_maxsdk.m_ShowConsentFlow        = env->GetMethodID(cls, "showConsentFlow", "()V");
    g_maxsdk.m_OnActivateApp          = env->GetMethodID(cls, "onActivateApp", "()V");
    g_maxsdk.m_OnDeactivateApp        = env->GetMethodID(cls, "onDeactivateApp", "()V");
    g_maxsdk.m_SetMuted               = env->GetMethodID(cls, "setMuted", "(Z)V");
    g_maxsdk.m_SetVerboseLogging      = env->GetMethodID(cls, "setVerboseLogging", "(Z)V");
    g_maxsdk.m_SetHasUserConsent      = env->GetMethodID(cls, "setHasUserConsent", "(Z)V");
    g_maxsdk.m_SetIsAgeRestrictedUser = env->GetMethodID(cls, "setIsAgeRestrictedUser", "(Z)V");
    g_maxsdk.m_SetDoNotSell           = env->GetMethodID(cls, "setDoNotSell", "(Z)V");
    g_maxsdk.m_OpenMediationDebugger  = env->GetMethodID(cls, "openMediationDebugger", "()V");

    g_maxsdk.m_LoadInterstitial       = env->GetMethodID(cls, "loadInterstitial", "(Ljava/lang/String;Ljava/lang/String;)V");
    g_maxsdk.m_ShowInterstitial       = env->GetMethodID(cls, "showInterstitial", "(Ljava/lang/String;Ljava/lang/String;)V");
    g_maxsdk.m_IsInterstitialLoaded   = env->GetMethodID(cls, "isInterstitialLoaded", "(Ljava/lang/String;)Z");

    g_maxsdk.m_LoadRewarded     = env->GetMethodID(cls, "loadRewarded", "(Ljava/lang/String;Ljava/lang/String;)V");
    g_maxsdk.m_ShowRewarded     = env->GetMethodID(cls, "showRewarded", "(Ljava/lang/String;Ljava/lang/String;)V");
    g_maxsdk.m_IsRewardedLoaded = env->GetMethodID(cls, "isRewardedLoaded", "(Ljava/lang/String;)Z");

    g_maxsdk.m_LoadBanner     = env->GetMethodID(cls, "loadBanner", "(Ljava/lang/String;Ljava/lang/String;I)V");
    g_maxsdk.m_DestroyBanner  = env->GetMethodID(cls, "destroyBanner", "()V");
    g_maxsdk.m_ShowBanner     = env->GetMethodID(cls, "showBanner", "(ILjava/lang/String;)V");
    g_maxsdk.m_HideBanner     = env->GetMethodID(cls, "hideBanner", "()V");
    g_maxsdk.m_IsBannerLoaded = env->GetMethodID(cls, "isBannerLoaded", "()Z");
    g_maxsdk.m_IsBannerShown  = env->GetMethodID(cls, "isBannerShown", "()Z");
}

void Initialize_Ext()
{
    dmAndroid::ThreadAttacher threadAttacher;
    JNIEnv* env = threadAttacher.GetEnv();
    jclass cls = dmAndroid::LoadClass(env, "com/defold/maxsdk/AppLovinMaxJNI");

    InitJNIMethods(env, cls);

    jmethodID jni_constructor = env->GetMethodID(cls, "<init>", "(Landroid/app/Activity;)V");

    g_maxsdk.m_AppLovinMaxJNI = env->NewGlobalRef(env->NewObject(cls, jni_constructor, threadAttacher.GetActivity()->clazz));
}

void OnActivateApp()
{
    CallVoidMethod(g_maxsdk.m_AppLovinMaxJNI, g_maxsdk.m_OnActivateApp);
}

void OnDeactivateApp()
{
    CallVoidMethod(g_maxsdk.m_AppLovinMaxJNI, g_maxsdk.m_OnDeactivateApp);
}

void Initialize(const char* amazonAppId)
{
    CallVoidMethodChar(g_maxsdk.m_AppLovinMaxJNI, g_maxsdk.m_Initialize, amazonAppId);
}

void ShowConsentFlow()
{
    CallVoidMethod(g_maxsdk.m_AppLovinMaxJNI, g_maxsdk.m_ShowConsentFlow);
}

void SetMuted(bool muted)
{
    CallVoidMethodBool(g_maxsdk.m_AppLovinMaxJNI, g_maxsdk.m_SetMuted, muted);
}

void SetVerboseLogging(bool verbose)
{
    CallVoidMethodBool(g_maxsdk.m_AppLovinMaxJNI, g_maxsdk.m_SetVerboseLogging, verbose);
}

void SetHasUserConsent(bool hasConsent)
{
    CallVoidMethodBool(g_maxsdk.m_AppLovinMaxJNI, g_maxsdk.m_SetHasUserConsent, hasConsent);
}

void SetIsAgeRestrictedUser(bool ageRestricted)
{
    CallVoidMethodBool(g_maxsdk.m_AppLovinMaxJNI, g_maxsdk.m_SetIsAgeRestrictedUser, ageRestricted);
}

void SetDoNotSell(bool doNotSell)
{
    CallVoidMethodBool(g_maxsdk.m_AppLovinMaxJNI, g_maxsdk.m_SetDoNotSell, doNotSell);
}

void OpenMediationDebugger()
{
    CallVoidMethod(g_maxsdk.m_AppLovinMaxJNI, g_maxsdk.m_OpenMediationDebugger);
}

void LoadInterstitial(const char* unitId, const char* amazonSlotID)
{
    CallVoidMethodCharChar(g_maxsdk.m_AppLovinMaxJNI, g_maxsdk.m_LoadInterstitial, unitId, amazonSlotID);
}

void ShowInterstitial(const char* unitId, const char* placement)
{
    CallVoidMethodCharChar(g_maxsdk.m_AppLovinMaxJNI, g_maxsdk.m_ShowInterstitial, unitId, placement);
}

bool IsInterstitialLoaded(const char* unitId)
{
    return CallBoolMethodChar(g_maxsdk.m_AppLovinMaxJNI, g_maxsdk.m_IsInterstitialLoaded, unitId);
}

void LoadRewarded(const char* unitId, const char* amazonSlotID)
{
    CallVoidMethodCharChar(g_maxsdk.m_AppLovinMaxJNI, g_maxsdk.m_LoadRewarded, unitId, amazonSlotID);
}

void ShowRewarded(const char* unitId, const char* placement)
{
    CallVoidMethodCharChar(g_maxsdk.m_AppLovinMaxJNI, g_maxsdk.m_ShowRewarded, unitId, placement);
}

bool IsRewardedLoaded(const char* unitId)
{
    return CallBoolMethodChar(g_maxsdk.m_AppLovinMaxJNI, g_maxsdk.m_IsRewardedLoaded, unitId);
}

void LoadBanner(const char* unitId, const char* amazonSlotId, BannerSize bannerSize)
{
    CallVoidMethodCharCharInt(g_maxsdk.m_AppLovinMaxJNI, g_maxsdk.m_LoadBanner, unitId, amazonSlotId, (int)bannerSize);
}

void DestroyBanner()
{
    CallVoidMethod(g_maxsdk.m_AppLovinMaxJNI, g_maxsdk.m_DestroyBanner);
}

void ShowBanner(BannerPosition bannerPos, const char* placement)
{
    CallVoidMethodIntChar(g_maxsdk.m_AppLovinMaxJNI, g_maxsdk.m_ShowBanner, (int)bannerPos, placement);
}

void HideBanner()
{
    CallVoidMethod(g_maxsdk.m_AppLovinMaxJNI, g_maxsdk.m_HideBanner);
}

bool IsBannerLoaded()
{
    return CallBoolMethod(g_maxsdk.m_AppLovinMaxJNI, g_maxsdk.m_IsBannerLoaded);
}

bool IsBannerShown()
{
    return CallBoolMethod(g_maxsdk.m_AppLovinMaxJNI, g_maxsdk.m_IsBannerShown);
}

}//namespace dmAppLovinMax

#endif
