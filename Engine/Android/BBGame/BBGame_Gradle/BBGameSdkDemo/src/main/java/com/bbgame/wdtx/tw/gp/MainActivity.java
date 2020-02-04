package com.bbgame.wdtx.tw.gp;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.support.v4.app.FragmentActivity;
import android.util.Log;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Toast;

import com.bbgame.sdk.BBGameSdk;
import com.bbgame.sdk.api.model.ResultModel;
import com.bbgame.sdk.event.SDKEventKey;
import com.bbgame.sdk.event.SDKEventReceiver;
import com.bbgame.sdk.event.Subscribe;
import com.bbgame.sdk.exception.ActivityNullPointerException;
import com.bbgame.sdk.open.SocialAction;
import com.bbgame.sdk.param.SDKParamKey;
import com.bbgame.sdk.param.SDKParams;
import com.bbgame.sdk.pay.PayWay;

import java.io.File;

public class MainActivity extends FragmentActivity implements OnClickListener {
    SDKEventReceiver sdkEventReceiver = new SDKEventReceiver() {

        @Subscribe(event = SDKEventKey.ON_INIT_SUCCESS)
        void onSdkInitSuccess() {
            showToastInfo("开始游戏");
        }

        @Subscribe(event = SDKEventKey.ON_INIT_FAILED)
        void onSdkInitFailed(String msg) {
            showToastInfo(msg);
        }

        @Subscribe(event = SDKEventKey.ON_PAY_USER_EXIT)
        void onSdkPayUserExit(ResultModel resultModel) {
            showToastInfo(resultModel.getMsg());
        }

        @Subscribe(event = SDKEventKey.ON_ORDER_PAY_SUCC)
        void onSdkPaySuccess(ResultModel resultModel) {
            showToastInfo(resultModel.getMsg());
        }

        @Subscribe(event = SDKEventKey.ON_LOGIN_SUCCESS)
        void onSdkLoginSuccess(String token) {
            showToastInfo("token=" + token);
        }

        @Subscribe(event = SDKEventKey.ON_LOGIN_FAILED)
        void onSdkLoginFailed(String message) {
            showToastInfo("登录失败：" + message);
        }

        @Subscribe(event = SDKEventKey.ON_LOGOUT_SUCCESS)
        void onSdkLogoutSuccess() {
            showToastInfo("登出成功！");
        }

        @Subscribe(event = SDKEventKey.ON_LOGOUT_FAILED)
        void onSdkLogoutFailed(String message) {
            showToastInfo("登出失败: " + message);
        }

        @Subscribe(event = SDKEventKey.ON_FACEBOOK_SHARE_SUCCESS)
        void onFacebookShareSuccess() {
            showToastInfo("Facebook 分享成功");
        }

        @Subscribe(event = SDKEventKey.ON_FACEBOOK_SHARE_FAILED)
        void onFacebookShareFailed(String message) {
            showToastInfo("Facebook 分享失败" + message);
        }

    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        /*StrictMode.setThreadPolicy(new StrictMode.ThreadPolicy.Builder()
                .detectDiskReads()
                .detectDiskWrites()
                .detectNetwork()   // or .detectAll() for all detectable problems
                .penaltyLog()
                .build());
        StrictMode.setVmPolicy(new StrictMode.VmPolicy.Builder()
                .detectLeakedSqlLiteObjects()
                .detectLeakedClosableObjects()
                .penaltyLog()
                .penaltyDropBox()
                .build());*/

        if ((getIntent().getFlags() & Intent.FLAG_ACTIVITY_BROUGHT_TO_FRONT) != 0) {
            Log.i("MainActivity", "onCreate with flag FLAG_ACTIVITY_BROUGHT_TO_FRONT");
            finish();
            return;
        }

        try {
            BBGameSdk.defaultSdk().initSdk(this, null);
        } catch (ActivityNullPointerException e) {
            e.printStackTrace();
        }
        BBGameSdk.defaultSdk().registerSDKEventReceiver(sdkEventReceiver);
    }

    @Override
    public void onClick(View v) {
        SDKParams sdkParams = new SDKParams();
        switch (v.getId()) {
            case R.id.login_mode_select_btn:
                //账户登录
                try {
                    BBGameSdk.defaultSdk().login(this, null);
                } catch (ActivityNullPointerException e) {
                    e.printStackTrace();
                }
                break;
            case R.id.submit_data_btn:
                //上传角色信息
                sdkParams.put(SDKParamKey.STRING_ROLE_ID, "roleId_123");
                sdkParams.put(SDKParamKey.STRING_ROLE_NAME, "roleName");
                sdkParams.put(SDKParamKey.STRING_ROLE_LEVEL, "6");
                sdkParams.put(SDKParamKey.STRING_ZONE_ID, "1");
                sdkParams.put(SDKParamKey.STRING_ZONE_NAME, "韩国1服");

                try {
                    BBGameSdk.defaultSdk().submitRoleData(this, sdkParams);
                } catch (ActivityNullPointerException e) {
                    e.printStackTrace();
                }
                break;
            case R.id.clear_user_btn:
                // 账户登出，清除用户状态,对应回调ON_LOGOUT_SUCCESS和ON_LOGOUT_FAILED
                try {
                    BBGameSdk.defaultSdk().logout(this, null);
                } catch (ActivityNullPointerException e) {
                    e.printStackTrace();
                }
                break;
            case R.id.pay_btn:
                //角色信息
                sdkParams.put(SDKParamKey.STRING_ROLE_ID, "roleId_123");
                sdkParams.put(SDKParamKey.STRING_ROLE_NAME, "roleName");
                sdkParams.put(SDKParamKey.STRING_ZONE_ID, "1");
                sdkParams.put(SDKParamKey.STRING_ZONE_NAME, "server1");

                //Google支付
                sdkParams.put(SDKParamKey.PAY_WAY, PayWay.PAY_WAY_GOOGLE);

                //产品ID，见BBGAME运营提供的产品表
                sdkParams.put(SDKParamKey.PRODUCT_ID, "Google的产品ID");//Google的产品ID
                sdkParams.put(SDKParamKey.CP_ORDER_ID, "cp_order_id_" + System.currentTimeMillis());//cp订单id
                sdkParams.put(SDKParamKey.CALLBACK_INFO, "callback");//透传参数
                //推荐服务器后台配置支付回调地址（如果客户端传入,则取客户端的地址,不取服务器配置的地址）
                sdkParams.put(SDKParamKey.NOTIFY_URL, "https://api.uat.bbgame.com.tw/v1/mock/orders/notify/a8c93804-e633-11e7-a183-883fd3280b78");

                try {
                    BBGameSdk.defaultSdk().pay(this, sdkParams);
                } catch (ActivityNullPointerException e) {
                    e.printStackTrace();
                }
                break;
            case R.id.pay_one_btn:
                //角色信息
                sdkParams.put(SDKParamKey.STRING_ROLE_ID, "roleId_123");
                sdkParams.put(SDKParamKey.STRING_ROLE_NAME, "roleName");
                sdkParams.put(SDKParamKey.STRING_ZONE_ID, "1");
                sdkParams.put(SDKParamKey.STRING_ZONE_NAME, "server1");


                //OneStore V5支付
                sdkParams.put(SDKParamKey.PAY_WAY, PayWay.PAY_WAY_ONESTORE_V5);
                //OneStore特有参数(OneStore的publicKey)
                sdkParams.put(SDKParamKey.ONESTORE_PUBLIC_KEY, "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCVX4i2XViA8h5CBKhFrayfQIq7IlzLcMIOZiwUVXfhCwTgSY6O36GXC1f9g5sdbGKaFU2KzKqn6O1K0YpCgNzurl4nvspy/WqI9+ASGwOYx59KzNxErydZXflv4/xlm7mCsRsGmsWyNJYjKp6oGCHCcmtRTKJaWWypv9VtpwMBJQIDAQAB");

                //产品ID，见BBGAME运营提供的产品表
                sdkParams.put(SDKParamKey.PRODUCT_ID, "oneStore的产品ID");//oneStore的产品ID
                sdkParams.put(SDKParamKey.CP_ORDER_ID, "cp_order_id_" + System.currentTimeMillis());//cp订单id
                sdkParams.put(SDKParamKey.CALLBACK_INFO, "callback");//透传参数
                //推荐服务器后台配置支付回调地址（如果客户端传入,则取客户端的地址,不取服务器配置的地址）
                sdkParams.put(SDKParamKey.NOTIFY_URL, "https://api.uat.bbgame.com.tw/v1/mock/orders/notify/a8c93804-e633-11e7-a183-883fd3280b78");

                try {
                    BBGameSdk.defaultSdk().pay(this, sdkParams);
                } catch (ActivityNullPointerException e) {
                    e.printStackTrace();
                }
                break;
            case R.id.customer_services:
                //角色信息
                sdkParams.put(SDKParamKey.STRING_ROLE_ID, "roleId_123");
                sdkParams.put(SDKParamKey.STRING_ROLE_NAME, "roleName");
                sdkParams.put(SDKParamKey.STRING_ZONE_ID, "1");
                sdkParams.put(SDKParamKey.STRING_ZONE_NAME, "server1");
                try {
                    BBGameSdk.defaultSdk().openCustomerService(this, null);//打开客诉
                } catch (ActivityNullPointerException e) {
                    e.printStackTrace();
                }
                break;
            case R.id.account_center:
                try {
                    BBGameSdk.defaultSdk().openAccountCenter(this, null);//打开用户中心
                } catch (ActivityNullPointerException e) {
                    e.printStackTrace();
                }
                break;
            case R.id.open_cafe:
//                CafeUtil.openCafe(this);//打开Cafe,需自行添加CafeUtil
                break;
            case R.id.facebook_share_btn:
                //Facebook分享

                //sdkParams.put(SDKParamKey.SOCIAL_ACTION, SocialAction.ACTION_FACEBOOK_REMOTE_SHARE);
                sdkParams.put(SDKParamKey.SOCIAL_ACTION, SocialAction.ACTION_FACEBOOK_SHARE);
                sdkParams.put(SDKParamKey.FACEBOOK_SHARE_CONTENT_URL, "https://www.facebook.com");
                sdkParams.put(SDKParamKey.FACEBOOK_SHARE_QUOTE, "this is text");//SHARE_QUOTE可选参数
                sdkParams.put(SDKParamKey.FACEBOOK_SHARE_TAG, "demo");//SHARE_TAG可选参数

                //facebook分享支持[链接+tag+文字]或者[图片+tag+文字]
                //有传FACEBOOK_SHARE_IMAGE_URI参数则使用[图片+tag+文字],会忽略传入的FACEBOOK_SHARE_CONTENT_URL参数
                //使用[图片+tag+文字]的分享方式,必须设备安装有facebook客户端(FB-SDK要求的),分享图片需自行申请存储权限
                String imageUri = Uri.fromFile(new File(Environment.getExternalStorageDirectory() + "/Download/ic_launcher.png")).toString();
//                sdkParams.put(SDKParamKey.FACEBOOK_SHARE_IMAGE_URI, imageUri);
                try {
                    BBGameSdk.defaultSdk().startSocialActivity(this, sdkParams);
                } catch (ActivityNullPointerException e) {
                    e.printStackTrace();
                }
                break;
            case R.id.test:
//                addEventLog();

//                String url = getSharedPreferences("sp_current_facebook_user", Context.MODE_PRIVATE).getString("profile_pic","");
//                showToastInfo(url);
                break;
            default:
                break;
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        BBGameSdk.defaultSdk().unregisterSDKEventReceiver(sdkEventReceiver);
        sdkEventReceiver = null;
    }
//打开用户协议
//startActivity(new Intent(this, ProtocolActivity.class).setData(Uri.parse(getString(R.string.bbg_kr_protocol_url))));
//打开隐私协议
//startActivity(new Intent(this, ProtocolActivity.class).setData(Uri.parse(getString(R.string.bbg_kr_privacy_url))));
//打开运营政策
//startActivity(new Intent(this, ProtocolActivity.class).setData(Uri.parse(getString(R.string.bbg_kr_policy_url))));


    //BBG-SDK的打点功能
    private void addEventLog() {
        Bundle bundle = new Bundle();
        bundle.putString("roleId", "角色ID");
        bundle.putString("roleName", "角色名");
        bundle.putString("serverId", "服务器ID");
        bundle.putString("serverName", "服务器名");

        //完成新手教程事件
//        BBGameSdk.defaultSdk().addLogEvent(this, SDKParamKey.EVENT_COMPLETED_TUTORIAL, bundle);
//
//        bundle.putString("level", "关卡名称");
//        BBGameSdk.defaultSdk().addLogEvent(this, SDKParamKey.EVENT_ACHIEVED_LEVEL, bundle);
//
//        bundle.putString("achievement", "解锁成就名称");
//        BBGameSdk.defaultSdk().addLogEvent(this, SDKParamKey.EVENT_UNLOCKED_ACHIEVEMENT, bundle);
//
//        bundle.putString("rate", "评分名称");
//        BBGameSdk.defaultSdk().addLogEvent(this, SDKParamKey.EVENT_RATED, bundle);

        //除了以上四种特殊命名外(这四种事件的角色参数为必需参数),其他的可以传入自定义事件
        //传入需要记录的参数,自定义事件的角色参数为非必要参数
        bundle.putString("example", "自定义参数");
        //自定义事件bbg_example
        BBGameSdk.defaultSdk().addLogEvent(this, "bbg_example", bundle);
    }


    private void showToastInfo(final String info) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Toast.makeText(MainActivity.this, info, Toast.LENGTH_SHORT).show();
            }
        });
    }

//    //(BBG-SDK内部已实现动态申请)厂商自行添加unity需要的权限,以下示例,仅为示例(存储权限为必需权限,录音为非必需权限)
//    private void requestUnityPermission() {
//        String[] mustPermission = {android.Manifest.permission.WRITE_EXTERNAL_STORAGE};
//        HashMap<String, String> permissionMap = new HashMap<>();
//        permissionMap.put(android.Manifest.permission.WRITE_EXTERNAL_STORAGE, "需要xx1权限用来做xxx,是必需权限");
//        permissionMap.put(android.Manifest.permission.RECORD_AUDIO, "需要xx2权限用来做xxxxx");
//        //传入的Activity务必为FragmentActivity或者AppCompatActivity
//        PermissionRequestUtil.requestPermission(MainActivity.this, permissionMap, mustPermission, new PermissionRequestCallBack() {
//            @Override
//            public void PermissionRequestFinish(HashMap<String, String> refuseList) {
//                //refuseList回调是被拒绝的权限列表
////                showToastInfo(refuseList.toString());
//            }
//        });
//    }
}
