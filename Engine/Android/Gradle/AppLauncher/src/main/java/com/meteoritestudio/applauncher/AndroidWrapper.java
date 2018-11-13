package com.meteoritestudio.applauncher;

import java.io.*;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.AlertDialog.Builder;
import android.content.*;
import android.content.pm.*;
import android.net.*;
import android.net.wifi.*;
import android.os.*;
import android.telephony.TelephonyManager;
import android.util.DisplayMetrics;

public class AndroidWrapper {
    public static AndroidWrapper mThis;

    public AndroidWrapper() {
	mThis = this;
    }

    public static long getSDCardAvailSize() {
	String state = Environment.getExternalStorageState();
	if (Environment.MEDIA_MOUNTED.equals(state)) {
	    // File sdcardDir = Environment.getExternalStorageDirectory();
	    String sdcardDir = Environment.getExternalStorageDirectory()
		    .toString();
	    StatFs sf = new StatFs(sdcardDir);
	    long blockSize = sf.getBlockSize();
	    long availCount = sf.getAvailableBlocks();

	    return blockSize * availCount;
	}
	return 0;
    }

    public static boolean isHaveSDCard() {
	return Environment.getExternalStorageState().equals(
		Environment.MEDIA_MOUNTED); // 判断sd卡是否存在
    }

    public static String getSDCardPath() {
	File sdDir = null;
	boolean sdCardExist = Environment.getExternalStorageState().equals(
		Environment.MEDIA_MOUNTED); // 判断sd卡是否存在
	if (sdCardExist) {
	    sdDir = Environment.getExternalStorageDirectory();// 获取跟目录
	    return sdDir.toString();
	}
	return "";
    }

    public static long getMemSize() {
	String str1 = "/proc/meminfo";
	String str2;
	String[] arrayOfString;
	long initial_memory = 0;

	try {
	    FileReader localFileReader = new FileReader(str1);
	    BufferedReader localBufferedReader = new BufferedReader(
		    localFileReader, 8192);
	    str2 = localBufferedReader.readLine();
	    arrayOfString = str2.split("\\s+");
	    initial_memory = Integer.valueOf(arrayOfString[1]).intValue() * 1024;
	    localBufferedReader.close();

	} catch (IOException e) {
	}

	return initial_memory;
    }

    public static int isHave3G2G(Context context) {
	if (context == null)
	    return 0;

	TelephonyManager telephonyManager = (TelephonyManager) context
		.getSystemService(Context.TELEPHONY_SERVICE);
	int networkType = telephonyManager.getNetworkType();
	if (networkType != TelephonyManager.NETWORK_TYPE_UNKNOWN)
	    return 1;

	return 0;
    }

    public static String getMetaData(Context context, String key) {
	try {
	    ApplicationInfo ai = context.getPackageManager()
		    .getApplicationInfo(context.getPackageName(),
			    PackageManager.GET_META_DATA);
	    Object value = ai.metaData.get(key);
	    if (null != value) {
		return value.toString();
	    }
	} catch (Exception e) {
	}

	return null;
    }

    public static void showExitDialog(Context context, String strTitle,
	    String strMessage, String strOK, String strCancel) {

	AlertDialog.Builder builder = new Builder(context);
	builder.setTitle(strTitle);
	builder.setMessage(strMessage);

	builder.setPositiveButton(strOK, new AlertDialog.OnClickListener() {

	    @Override
	    public void onClick(DialogInterface dialog, int which) {
		dialog.dismiss();
		android.os.Process.killProcess(android.os.Process.myPid());
		System.exit(0);
	    }
	});

	builder.setNegativeButton(strCancel, new AlertDialog.OnClickListener() {

	    @Override
	    public void onClick(DialogInterface dialog, int whick) {
		dialog.dismiss();
	    }
	});

	builder.create().show();
    }

    public static void showExitDialog(Context context, String iMessage,
	    String iOK) {

	AlertDialog.Builder builder = new Builder(context);
	builder.setMessage(iMessage);

	builder.setPositiveButton(iOK, new AlertDialog.OnClickListener() {

	    @Override
	    public void onClick(DialogInterface dialog, int which) {
		dialog.dismiss();
		android.os.Process.killProcess(android.os.Process.myPid());
		System.exit(0);
	    }
	});

	builder.create().show();
    }

    // used for native code.
    public static String getVersionName(Context context) {

	String versionName = "";
	try {
	    PackageManager packageManager = context.getPackageManager();
	    PackageInfo packInfo = packageManager.getPackageInfo(
		    context.getPackageName(), 0);
	    versionName = packInfo.versionName;
	} catch (Exception e) {

	}
	return versionName;
    }

    // used for java code.
    public static String getCurVersion(Context context) throws Exception {
	PackageManager packageManager = context.getPackageManager();
	PackageInfo packInfo = packageManager.getPackageInfo(
		context.getPackageName(), 0);
	String version = packInfo.versionName;
	return version;
    }

    public static int getCurVersionCode(Context context) throws Exception {
	PackageManager packageManager = context.getPackageManager();
	PackageInfo packInfo = packageManager.getPackageInfo(
		context.getPackageName(), 0);
	int versionCode = packInfo.versionCode;
	return versionCode;
    }

    public static int isHaveWifi(Context context) {
	ConnectivityManager mConnMgr = (ConnectivityManager) context
		.getSystemService(Context.CONNECTIVITY_SERVICE);
	NetworkInfo mWifi = mConnMgr
		.getNetworkInfo(ConnectivityManager.TYPE_WIFI);
	if (mWifi != null && mWifi.isConnected())
	    return 1;

	return 0;
    }

    public static String getMacAddress(Context context) {

	String macAddress = "";
	WifiManager wifiManager = (WifiManager) context
		.getSystemService(Context.WIFI_SERVICE);

	if (wifiManager.isWifiEnabled()) {
	    WifiInfo info = wifiManager.getConnectionInfo();
	    macAddress = info.getMacAddress();
	} else {
	    wifiManager.setWifiEnabled(true);
	    WifiInfo info = wifiManager.getConnectionInfo();
	    macAddress = info.getMacAddress();
	    wifiManager.setWifiEnabled(false);
	}

	return macAddress;
    }

    public static float getDeviceDPI(Context context) {
	float dpi = 1.0f;
	try {
	    DisplayMetrics dm = context.getResources().getDisplayMetrics();
	    dpi = (float) dm.densityDpi;
	} catch (Exception e) {
	}

	return dpi;
    }

    //
    public static boolean isUsingVirtualDevice() {

	return (Build.MODEL == null) || (Build.MODEL == "")
		|| (Build.MODEL.toLowerCase().contains("sdk"));
    }

    public static void exit() {
	System.exit(0);
    }

    public static void OpenUrl(final Activity targetActivity, final String url)
    {
        try{
            Uri uri = Uri.parse(url);
            Intent intent = new Intent(Intent.ACTION_VIEW, uri);
            targetActivity.startActivity(intent);
            intent = null;
        }
        catch (Exception e) {}
    }

}
