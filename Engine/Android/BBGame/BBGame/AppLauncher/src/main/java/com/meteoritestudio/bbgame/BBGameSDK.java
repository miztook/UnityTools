package com.meteoritestudio.bbgame;

import org.json.JSONException;
import org.json.JSONObject;

import com.bbgame.sdk.api.model.ResultModel;
import com.bbgame.sdk.event.SDKEventKey;
import com.bbgame.sdk.event.SDKEventReceiver;
import com.bbgame.sdk.event.Subscribe;
import com.bbgame.sdk.BBGameSdk;
import com.bbgame.sdk.exception.ActivityNullPointerException;
import com.appsflyer.AppsFlyerLib;
import com.appsflyer.AppsFlyerConversionListener;

import com.sensorsdata.analytics.android.sdk.SensorsDataAPI;
import com.sensorsdata.analytics.android.sdk.SAConfigOptions;
import com.sensorsdata.analytics.android.sdk.SensorsAnalyticsAutoTrackEventType;

import com.bbgame.sdk.param.SDKParamKey;
import com.bbgame.sdk.param.SDKParams;
import com.bbgame.sdk.pay.PayWay;
import com.meteoritestudio.applauncher.JavaLog;
import com.meteoritestudio.prom1.MainActivity;
import com.unity3d.player.UnityPlayer;

import android.os.Bundle;
import android.util.Log;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.Map;

public class BBGameSDK {

    private static final String AF_DEV_KEY = "P64pjYJjzv355sCjgHxZrW";
    private static SDKEventReceiver _SdkEventReceiver = null;
    // 数据接收的 URL
    private static final String SA_SERVER_URL = "http://tera-bi.bbgame.com.tw:8106/sa?project=production";

    private static final String _LogTag = "BBG_SDK";

    public static void PlatformInit(){
        Log.w(_LogTag, "PlatformInit Start");
        AppsFlyerConversionListener conversionDataListener = new AppsFlyerConversionListener() {
            @Override
            public void onInstallConversionDataLoaded(Map<String,String> map){}
            @Override
            public void onInstallConversionFailure(String s){}
            @Override
            public void onAppOpenAttribution(Map<String, String> map){}
            @Override
            public void onAttributionFailure(String s){}
        };
        AppsFlyerLib.getInstance().init(AF_DEV_KEY,conversionDataListener, MainActivity.getInstance().getApplicationContext());
        AppsFlyerLib.getInstance().startTracking(MainActivity.getInstance().getApplication());

        //通过 SAConfigOptions 设置神策 SDK，每个条件都非必须，开发者可根据自己实际情况设置，更多设置可参考 SAConfigOptions 类中方法注释
        SAConfigOptions saConfigOptions = new SAConfigOptions(SA_SERVER_URL);
        saConfigOptions.setAutoTrackEventType(SensorsAnalyticsAutoTrackEventType.APP_START);      //开启全埋点启动事件
                //.enableLog(true);        //开启神策调试日志，默认关闭(调试时，可开启日志)。
        //需要在主线程初始化神策 SDK
        SensorsDataAPI.startWithConfigOptions(MainActivity.getInstance(), saConfigOptions);

        _SdkEventReceiver = new SDKEventReceiver() {
            @Subscribe(event = SDKEventKey.ON_INIT_SUCCESS)
            void onSdkInitSuccess() {
                Log.w(_LogTag, "onSdkInitSuccess");
            }

            @Subscribe(event = SDKEventKey.ON_INIT_FAILED)
            void onSdkInitFailed(String msg) {
                Log.e(_LogTag, "onSdkInitFailed msg:" + msg);
            }

            @Subscribe(event = SDKEventKey.ON_LOGIN_SUCCESS_USERID)
            void onSdkLoginSuccess(String token, String userId) {
                Log.w(_LogTag, "onSdkLoginSuccess userId:"+userId+" token:"+token);
                try
                {
                    JSONObject entityJsonObject = new JSONObject();
                    entityJsonObject.put("uid", userId);
                    entityJsonObject.put("token", token);
                    JSONObject resultJsonObject = new JSONObject();
                    resultJsonObject.put("code", BBGameResultCode.LoginSucceed);
                    resultJsonObject.put("message", "");
                    resultJsonObject.put("loginInfo", entityJsonObject);
                    SendUnity("PlatformSDKLoginCallBack", resultJsonObject.toString());
                }
                catch (Exception e){ }
            }

            @Subscribe(event = SDKEventKey.ON_LOGIN_FAILED)
            void onSdkLoginFailed(String message) {
                Log.w(_LogTag, "onSdkLoginFailed");
                try
                {
                    JSONObject resultJsonObject = new JSONObject();
                    resultJsonObject.put("code", BBGameResultCode.LoginFailed);
                    resultJsonObject.put("message", message);
                    SendUnity("PlatformSDKLoginCallBack", resultJsonObject.toString());
                }
                catch (Exception e){ }
            }

            @Subscribe(event = SDKEventKey.ON_LOGOUT_SUCCESS)
            void onSdkLogoutSuccess() {
                Log.w(_LogTag, "onSdkLogoutSuccess");
                try
                {
                    JSONObject resultJsonObject = new JSONObject();
                    resultJsonObject.put("code", BBGameResultCode.LogoutSucceed);
                    resultJsonObject.put("message", "");
                    SendUnity("PlatformSDKLogoutCallBack", resultJsonObject.toString());
                }
                catch (Exception e){ }
            }

            @Subscribe(event = SDKEventKey.ON_LOGOUT_FAILED)
            void onSdkLogoutFailed(String message) {
                Log.w(_LogTag, "onSdkLogoutFailed");
                try
                {
                    JSONObject resultJsonObject = new JSONObject();
                    resultJsonObject.put("code", BBGameResultCode.LogoutFailed);
                    resultJsonObject.put("message", message);
                    SendUnity("PlatformSDKLogoutCallBack", resultJsonObject.toString());
                }
                catch (Exception e){ }
            }

            @Subscribe(event = SDKEventKey.ON_ORDER_PAY_SUCC)
            void onSdkPaySuccess(ResultModel resultModel) {
                Log.w(_LogTag, "onSdkPaySuccess code:" + resultModel.getStatusCode()+" msg:"+resultModel.getMsg());
                try
                {
                    JSONObject resultJsonObject = new JSONObject();
                    resultJsonObject.put("code", BBGameResultCode.PaySuccess);
                    resultJsonObject.put("message", resultModel.getMsg());
                    SendUnity("PlatformSDKPayCallBack", resultJsonObject.toString());
                }
                catch (Exception e){ }
            }

            @Subscribe(event = SDKEventKey.ON_PAY_USER_EXIT)
            void onSdkPayUserExit(ResultModel resultModel) {
                Log.w(_LogTag, "onSdkPayUserExit code:" + resultModel.getStatusCode()+" msg:"+resultModel.getMsg());
                try
                {
                    JSONObject resultJsonObject = new JSONObject();
                    resultJsonObject.put("code", BBGameResultCode.PayUserExit);
                    resultJsonObject.put("message", resultModel.getMsg());
                    SendUnity("PlatformSDKPayCallBack", resultJsonObject.toString());
                }
                catch (Exception e){ }
            }

            @Subscribe(event = SDKEventKey.ON_FACEBOOK_SHARE_SUCCESS)
            void onFacebookShareSuccess() {
                Log.w(_LogTag, "onFacebookShareSuccess");
            }

            @Subscribe(event = SDKEventKey.ON_FACEBOOK_SHARE_FAILED)
            void onFacebookShareFailed(String message) {
                Log.w(_LogTag, "onFacebookShareFailed");
            }
        };
        try {
            BBGameSdk.defaultSdk().registerSDKEventReceiver(_SdkEventReceiver);
            BBGameSdk.defaultSdk().initSdk(MainActivity.getInstance(), null);
        } catch (ActivityNullPointerException e) {
            e.printStackTrace();
        }
    }

    public static void PlatformLogin() {
        try {
            BBGameSdk.defaultSdk().login(MainActivity.getInstance(), null);
        } catch (ActivityNullPointerException e) {
            e.printStackTrace();
        }
    }

    public static void PlatformLogout() {
        try {
            BBGameSdk.defaultSdk().logout(MainActivity.getInstance(), null);
        } catch (ActivityNullPointerException e) {
            e.printStackTrace();
        }
    }

    public static void UploadRoleInfo(final String rolejson) {
        try {
            SDKParams sdkParams = new SDKParams();
            JSONObject roleJsonObject = new JSONObject(rolejson);
            sdkParams.put(SDKParamKey.STRING_ROLE_ID, roleJsonObject.getString("playerId"));
            sdkParams.put(SDKParamKey.STRING_ROLE_NAME, roleJsonObject.getString("roleName"));
            sdkParams.put(SDKParamKey.STRING_ROLE_LEVEL, roleJsonObject.getString("roleLevel"));
            sdkParams.put(SDKParamKey.STRING_ZONE_ID, roleJsonObject.getString("serverId"));
            sdkParams.put(SDKParamKey.STRING_ZONE_NAME, roleJsonObject.getString("serverName"));
            BBGameSdk.defaultSdk().submitRoleData(MainActivity.getInstance(), sdkParams);
        } catch (Exception e) {
            String msg = "UploadRoleInfo failed rolejson:" + rolejson + ", got exception:" + e.toString();
            Log.w(_LogTag, msg);
            JavaLog.Instance().WriteLog(msg);
        }
    }

    public static void PlatformPay(final String rolejson,
                                   final String cpOrderId,
                                   final String productId,
                                   final String callbackInfo,
                                   final String notifyUrl) {
        try {
            SDKParams sdkParams = new SDKParams();
            JSONObject roleJsonObject = new JSONObject(rolejson);
            sdkParams.put(SDKParamKey.STRING_ROLE_ID, roleJsonObject.getString("playerId"));
            sdkParams.put(SDKParamKey.STRING_ROLE_NAME, roleJsonObject.getString("roleName"));
            sdkParams.put(SDKParamKey.STRING_ZONE_ID, roleJsonObject.getString("serverId"));
            sdkParams.put(SDKParamKey.STRING_ZONE_NAME, roleJsonObject.getString("serverName"));
            sdkParams.put(SDKParamKey.PAY_WAY, PayWay.PAY_WAY_GOOGLE);
            sdkParams.put(SDKParamKey.CP_ORDER_ID, cpOrderId);
            sdkParams.put(SDKParamKey.PRODUCT_ID, productId);
              sdkParams.put(SDKParamKey.NOTIFY_URL, notifyUrl);
            BBGameSdk.defaultSdk().pay(MainActivity.getInstance(), sdkParams);
        } catch (Exception e) {
            String msg = String.format("PlatformPay failed, rolejson:%s, cpOrderId:%s, productId:%s, callbackInfo:%s, notifyUrl:%s\ngot exception:%s",
                    rolejson, cpOrderId, productId, callbackInfo, notifyUrl, e.toString());
            Log.w(_LogTag, msg);
            JavaLog.Instance().WriteLog(msg);
        }
    }

    public static void OpenAccountCenter(){
        try {
            BBGameSdk.defaultSdk().openAccountCenter(MainActivity.getInstance(), null);
        } catch (ActivityNullPointerException e) {
            e.printStackTrace();
        }
    }

    public static void OpenCustomerService(final String rolejson){
        try {
            SDKParams sdkParams = new SDKParams();
            JSONObject roleJsonObject = new JSONObject(rolejson);
            sdkParams.put(SDKParamKey.STRING_ROLE_ID, roleJsonObject.getString("playerId"));
            sdkParams.put(SDKParamKey.STRING_ROLE_NAME, roleJsonObject.getString("roleName"));
            sdkParams.put(SDKParamKey.STRING_ZONE_ID, roleJsonObject.getString("serverId"));
            sdkParams.put(SDKParamKey.STRING_ZONE_NAME, roleJsonObject.getString("serverName"));
            BBGameSdk.defaultSdk().openCustomerService(MainActivity.getInstance(), sdkParams);
        } catch (Exception e) {
            String msg = String.format("OpenCustomerService failed, rolejson:%s\ngot exception:%s", rolejson, e.toString());
            Log.w(_LogTag, msg);
            JavaLog.Instance().WriteLog(msg);
        }
    }

    public static void AddLogEvent(final String title, final String rolejson, final String arg0, final String arg1) {
        try {
            Bundle bundle = new Bundle();
            if (!rolejson.isEmpty())
            {
                JSONObject roleJsonObject = new JSONObject(rolejson);
                bundle.putString(SDKParamKey.STRING_ROLE_ID, roleJsonObject.getString("playerId"));
                bundle.putString(SDKParamKey.STRING_ROLE_NAME, roleJsonObject.getString("roleName"));
                bundle.putString(SDKParamKey.STRING_ZONE_ID, roleJsonObject.getString("serverId"));
                bundle.putString(SDKParamKey.STRING_ZONE_NAME, roleJsonObject.getString("serverName"));
            }
            bundle.putString(arg0, arg1);
            BBGameSdk.defaultSdk().addLogEvent(MainActivity.getInstance(), title, bundle);
        } catch (Exception e) {
            String msg = String.format("AddLogEvent failed, rolejson:%s, arg0:%s, arg1:%s\ngot exception:%s", rolejson, arg0, arg1, e.toString());
            Log.w(_LogTag, msg);
            JavaLog.Instance().WriteLog(msg);
        }
    }

    public static void PlatformDestroy() {
        if (_SdkEventReceiver != null){
            BBGameSdk.defaultSdk().unregisterSDKEventReceiver(_SdkEventReceiver);
            _SdkEventReceiver = null;
        }
    }

    public static void RegisterSuperProperties(final String json) {
        if (json == null || json.isEmpty()) return;
        try {
            JSONObject properties = new JSONObject(json);
            SensorsDataAPI.sharedInstance().registerSuperProperties(properties);
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public static void EventLogin(final String loginId) {
        SensorsDataAPI.sharedInstance().login(loginId);
    }

    public static void Track(final String eventName, final String json) {
        if (json == null || json.isEmpty()) return;
        try {
            JSONObject properties = new JSONObject(json);
            SensorsDataAPI.sharedInstance().track(eventName, properties);
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    private static void SendUnity(final String method, final String param) {
        try {
            UnityPlayer.UnitySendMessage("AndroidBridge", method, param);
        } catch (Exception e) {
            String msg = "SendUnity failed method:" + method + "param:" + param + ", got exception:" + e.toString();
            Log.w(_LogTag, msg);
            JavaLog.Instance().WriteLog(msg);
        }
    }
}