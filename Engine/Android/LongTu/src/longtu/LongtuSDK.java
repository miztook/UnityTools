package com.meteoritestudio.longtu;

import org.json.JSONException;
import org.json.JSONObject;

import com.bh.sdk.LTEntity;
import com.bh.sdk.LTProduct;
import com.bh.sdk.RoleInfo;
import com.bh.sdk.UnionCallbackCode;
import com.bh.sdk.UnionSDKInterface;
import com.bh.sdk.UnionSDKListener;
import com.bh.sdk.Interface.LTUnionSDK;
import com.bh.sdk.ltlistener.IBindAccountListener;
import com.bh.sdk.ltlistener.IGiftListener;
import com.bh.sdk.ltlistener.IGuestListener;
import com.tools.libproject.data.FileData;

import com.longtugame.notice.ShowNoticeView;
import com.meteoritestudio.applauncher.JavaLog;
import com.meteoritestudio.prom1.MainActivity;
import com.unity3d.player.UnityPlayer;
import com.unity3d.player.UnityPlayerActivity;

import android.R.string;
import android.content.Context;
import android.util.Log;

public class LongtuSDK {
    public static void PlatformInit() {
        LTUnionSDK.getInstance().LTUnionSDKListener(new UnionSDKListener() {
            @Override
            public void LTUnionSDKInitCallBack(int code, String msg) {
                Log.w("UnionSDKInitCallBack", String.format("LTUnionSDKInitCallBack code: %d, msg: %s", code, msg));
                switch (code) {
                    case UnionCallbackCode.CODE_INIT_SUCCESS:
                        //初始化成功。初始化成功后才可调用登陆接口
                        Log.w("UnionSDKInitCallBack", "CODE_INIT_SUCCESS");
                        break;
                    default:
                        break;
                }
            }

            @Override
            public void LTUnionSDKLoginCallBack(int code, String msg, LTEntity entity) {
            	JSONObject entityJsonObject = null;
                switch (code) {
                    case UnionCallbackCode.CODE_LOGIN_SUCCESS:
                        Log.w("UnionSDKLoginCallBack",
                                "登陆成功 :" + msg + " userID=" + entity.getUid()+ " gameid=" + entity.getGameid()+ " Channelid=" + entity.getChannelid() /*+ " lttoken=" + entity.getLtToken()*/);
                        try {
                            entityJsonObject = new JSONObject();
                            entityJsonObject.put("uid", entity.getUid());
                            entityJsonObject.put("token", entity.getToken());
                            entityJsonObject.put("gameid", entity.getGameid());
                            entityJsonObject.put("channelid", entity.getChannelid());
						} catch (JSONException e) { }
                        break;
                    case UnionCallbackCode.CODE_LOGIN_FAIL:
                        Log.w("UnionSDKLoginCallBack", "登陆失败:" + msg);
                        break;
                    case UnionCallbackCode.CODE_LOGIN_CANCEL:
                        Log.w("UnionSDKLoginCallBack", "登陆取消:" + msg);
                        break;
                    case UnionCallbackCode.CODE_LOGIN_TIMEOUT:
                        Log.w("UnionSDKLoginCallBack", "登陆超时:" + msg);
                        break;
                    default:
                        break;
                }
                try {
					JSONObject resultJsonObject = new JSONObject();
					resultJsonObject.put("code", code);
					resultJsonObject.put("message", msg);
					if (entityJsonObject != null) {
						resultJsonObject.put("loginInfo", entityJsonObject);
					}
					SendUnity("PlatformSDKLoginCallBack", resultJsonObject.toString());
				} catch (Exception e) { }
            }

            @Override
            public void LTUnionSDKPayCallBack(int code, String msg) {
                switch (code) {
                    case UnionCallbackCode.CODE_PAY_SUCCESS:
                        Log.w("UnionSDKPayCallBack", "支付成功:" + msg);
                        break;
                    case UnionCallbackCode.CODE_PAY_FAIL:
                        Log.w("UnionSDKPayCallBack", "支付失败:" + msg);
                        break;
                    case UnionCallbackCode.CODE_PAY_CANCEL:
                        Log.w("UnionSDKPayCallBack", "支付取消:" + msg);
                        break;
                    default:
                        break;
                }
            }

            @Override
            public void LTUnionSDKLogoutCallBack(int code, String msg) {
                switch (code) {
                    case UnionCallbackCode.CODE_LOGOUT_SUCCESS:
                        Log.w("UnionSDKLogoutCallBack", "退出账户成功:" + msg);
                        break;
                    case UnionCallbackCode.CODE_LOGOUT_FAIL:
                        Log.w("UnionSDKLogoutCallBack", "退出账户失败:" + msg);
                        break;
                    default:
                        break;
                }
                SendCallbackResult("PlatformSDKLogoutCallBack", code, msg);
            }

            @Override
            public void LTUnionSDKExitgameCallBack(int code, String msg) {
                switch (code) {
                    case UnionCallbackCode.CODE_EXIT_SUCCESS:
                        Log.w("UnionSDKExitCallBack", "退出游戏成功:" + msg);
                        MainActivity.getInstance().finish();
                        System.exit(0);
                        break;
                    case UnionCallbackCode.CODE_EXIT_FAIL:
                        Log.w("UnionSDKExitCallBack", "退出游戏失败:" + msg);
                        break;
                    default:
                        break;
                }
                SendCallbackResult("PlatformSDKExitCallBack", code, msg);
            }

        });
        Log.w("LTUnionSDK", "PlatformInit Start");
        LTUnionSDK.getInstance().LTUnionSDKInit(MainActivity.getInstance());
    }
    
    private static void SendCallbackResult(final String method, int code, final String msg) {
        try {
            JSONObject result = new JSONObject();
			result.put("code", code);
	        result.put("message", msg);
	        SendUnity(method, result.toString());
		} catch (JSONException e) {
			Log.w("LTUnionSDK", "SendCallbackResult failed, got exception:" + e.toString());
			JavaLog.Instance().WriteLog("SendCallbackResult failed, got exception:" + e.toString());
		}
    }

    private static void SendUnity(final String method, final String param) {
    	try {
        	UnityPlayer.UnitySendMessage("AndroidBridge", method, param);
		} catch (Exception e) {
			String msg = "SendUnity failed method:" + method + "param:" + param + ", got exception:" + e.toString();
			Log.w("LTUnionSDK", msg);
			JavaLog.Instance().WriteLog(msg);
		}
    }

    public static void PlatformLogin() {
        Log.w("LTUnionSDK", "PlatformLogin Start");
        LTUnionSDK.getInstance().LTUnionSDKShowLoginView();
    }

    public static void PlatformLogout() {
        Log.w("LTUnionSDK", "PlatformLogout Start");
        LTUnionSDK.getInstance().LTUnionSDKLogout();
    }
    
    public static void UploadRoleInfo(final String rolejson) {
    	try {
    		JSONObject roleJsonObject = new JSONObject(rolejson);
    		RoleInfo roleinfo = new RoleInfo();
    		roleinfo.setSendtype(roleJsonObject.getString("sendType"));
    		roleinfo.setPlayerid(roleJsonObject.getString("playerId"));
    		roleinfo.setRolename(roleJsonObject.getString("roleName"));
    		roleinfo.setRolelevel(roleJsonObject.getString("roleLevel"));
    		roleinfo.setViplevel(roleJsonObject.getString("vipLevel"));
    		roleinfo.setServerid(roleJsonObject.getString("serverId"));
    		roleinfo.setServername(roleJsonObject.getString("serverName"));
    		roleinfo.setLaborunion(roleJsonObject.getString("laborUnion"));
    		roleinfo.setRoleCreateTime(roleJsonObject.getString("roleCreateTime"));
    		roleinfo.setRoleLevelMTime(roleJsonObject.getString("roleLevelMTime"));
            Log.w("LTUnionSDK", "UploadRoleInfo Start");
    		LTUnionSDK.getInstance().LTUnionSDKRoleInfo(roleinfo);
		} catch (Exception e) {
			String msg = "UploadRoleInfo failed rolejson:" + rolejson + ", got exception:" + e.toString();
			Log.w("LTUnionSDK", msg);
			JavaLog.Instance().WriteLog(msg);
		}
    }

	public static boolean IsPlatformExitGame() {
		return LTUnionSDK.getInstance().LTUnionSDKIsLTExitGame();
	}

	public static void PlatformExitGame() {
		if (IsPlatformExitGame()) {
            Log.w("LTUnionSDK", "PlatformExitGame Start");
			LTUnionSDK.getInstance().LTUnionSDKShowExitgame();
		}
	}
	
	public static String GetGameID(){
		return UnionSDKInterface.getInstance().getGameID();
	}
	
	public static String GetChannelID(){
		return UnionSDKInterface.getInstance().getCurrChannel();
	}
	
	public static void ShowAnnouncement (final Context context) {
		Log.d("Notice", "Call ShowAnnouncement");
		ShowNoticeView.showNoticeView(context, "520078", "0");
	}
	
	public static void SetDataBreakPoint(final String point) {
		LTUnionSDK.getInstance().LTUnionSDKDataBreakpoint(point, "");
	}
}