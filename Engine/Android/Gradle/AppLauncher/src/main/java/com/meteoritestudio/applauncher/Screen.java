package com.meteoritestudio.applauncher;

import java.lang.reflect.Method;
import android.app.Activity;
import android.content.Context;
import android.os.Build;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.DisplayCutout;
import android.view.View;
import android.view.WindowInsets;

import com.meteoritestudio.utils.HwNotchUtils;
import com.meteoritestudio.utils.MeizuNotchUtils;
import com.meteoritestudio.utils.OppoNotchUtils;
import com.meteoritestudio.utils.VivoNotchUtils;
import com.meteoritestudio.utils.XiaomiNotchUtils;

public class Screen {
	
	public static float GetDensity(Activity targetActivity) {
		DisplayMetrics dm = new DisplayMetrics();
		targetActivity.getWindowManager().getDefaultDisplay().getMetrics(dm);

		return dm.density;
	}
	
	public static float GetDpi(Activity targetActivity) {
		float fRet = 0.0f;
		
		DisplayMetrics dm = new DisplayMetrics();
		targetActivity.getWindowManager().getDefaultDisplay().getMetrics(dm);
		fRet = dm.densityDpi;		
		
		return fRet;
	}
	
	public static float GetDpiX(Activity targetActivity) {
		float fRet = 0.0f;
		
		DisplayMetrics dm = new DisplayMetrics();
		targetActivity.getWindowManager().getDefaultDisplay().getMetrics(dm);
		fRet = dm.xdpi;		
		
		return fRet;
	}
	
	public static float GetDpiY(Activity targetActivity) {
		float fRet = 0.0f;
		
		DisplayMetrics dm = new DisplayMetrics();
		targetActivity.getWindowManager().getDefaultDisplay().getMetrics(dm);
		fRet = dm.ydpi;		
		
		return fRet;
	}
	
	public static float GetWidth(Activity targetActivity) {
		float fRet = 0.0f;
		
		DisplayMetrics dm = new DisplayMetrics();
		targetActivity.getWindowManager().getDefaultDisplay().getMetrics(dm);
		fRet = dm.widthPixels;		
		
		return fRet;
	}
	
	public static float GetHeight(Activity targetActivity) {
		float fRet = 0.0f;
		
		DisplayMetrics dm = new DisplayMetrics();
		targetActivity.getWindowManager().getDefaultDisplay().getMetrics(dm);
		fRet = dm.heightPixels;		
		
		return fRet;
	}
	
	public static boolean IgnoreNotchScreen(Activity targetActivity) {
		boolean bRet = false;
    	return bRet;
	}

    public static boolean HasNotchInScreen(Activity targetActivity)
	{
		boolean bIsNotchScreen = false;
		// Android P Api
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P)
		{
			final View decorView = targetActivity.getWindow().getDecorView();
			if (decorView != null) {
				WindowInsets windowInsets = decorView.getRootWindowInsets();
				if (windowInsets != null) {
					DisplayCutout displayCutout = windowInsets.getDisplayCutout();
					if (displayCutout != null) {
						float left = displayCutout.getSafeInsetLeft();
						float right = displayCutout.getSafeInsetRight();
						float top = displayCutout.getSafeInsetTop();
						float bottom = displayCutout.getSafeInsetBottom();

//						Log.d("HasNotchInScreen", "安全区域距离屏幕左边的距离 SafeInsetLeft:" + left);
//						Log.d("HasNotchInScreen", "安全区域距离屏幕右部的距离 SafeInsetRight:" + right);
//						Log.d("HasNotchInScreen", "安全区域距离屏幕顶部的距离 SafeInsetTop:" + top);
//						Log.d("HasNotchInScreen", "安全区域距离屏幕底部的距离 SafeInsetBottom:" + bottom);

						bIsNotchScreen = left + right + top + bottom > 0;
					}
				}
			}
		}
		else if (HwNotchUtils.hasNotch(targetActivity))
		{
			// 华为
			int[] rect = HwNotchUtils.getNotchSize(targetActivity);
			int width = rect[1];
			int height = rect[2];
			bIsNotchScreen = height > 0;
		}
		else if (MeizuNotchUtils.hasNotch(targetActivity))
		{
			// 魅族
			int width = MeizuNotchUtils.getNotWidth(targetActivity);
			int height = MeizuNotchUtils.getNotHeight(targetActivity);
			bIsNotchScreen = height > 0;
		}
		else if (OppoNotchUtils.hasNotch(targetActivity))
		{
			// Oppo
			bIsNotchScreen = true;
		}
		else if (VivoNotchUtils.hasNotch(targetActivity))
		{
			// Vivo
			bIsNotchScreen = true;
		}
		else if (XiaomiNotchUtils.hasNotch(targetActivity))
		{
			// 小米
			int width = XiaomiNotchUtils.getNotWidth(targetActivity);
			int height = XiaomiNotchUtils.getNotHeight(targetActivity);
			bIsNotchScreen = height > 0;
		}

		Log.d("HasNotchInScreen", "全面屏：" + bIsNotchScreen);

		return bIsNotchScreen;
	}

	//获取状态栏高度
	public static int GetStatusBarHeight(Activity targetActivity)
	{
		int statusBarHeight = 0;
		int resourceId = targetActivity.getResources().getIdentifier("status_bar_height", "dimen", "android");
		if (resourceId > 0)
			statusBarHeight = targetActivity.getResources().getDimensionPixelSize(resourceId);

		return statusBarHeight;
	}

	private static float DEFAULT_NOTCH_HEIGHT = 90;
	public static float GetNotchHeight(Activity targetActivity)
	{
		String strModel = android.os.Build.MODEL;
		String strBrand = android.os.Build.BRAND;
		Log.d("HasNotchInScreen", "机型信息:" + strModel + "厂商:" + strBrand);

		float fRet = 0.0f;
		// Android P Api
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P)
		{
			final View decorView = targetActivity.getWindow().getDecorView();
			if (decorView != null) {
				WindowInsets windowInsets = decorView.getRootWindowInsets();
				if (windowInsets != null) {
					DisplayCutout displayCutout = windowInsets.getDisplayCutout();
					if (displayCutout != null) {
						float left = displayCutout.getSafeInsetLeft();
						float right = displayCutout.getSafeInsetRight();
						float top = displayCutout.getSafeInsetTop();
						float bottom = displayCutout.getSafeInsetBottom();

//						Log.d("HasNotchInScreen", "安全区域距离屏幕左边的距离 SafeInsetLeft:" + left);
//						Log.d("HasNotchInScreen", "安全区域距离屏幕右部的距离 SafeInsetRight:" + right);
//						Log.d("HasNotchInScreen", "安全区域距离屏幕顶部的距离 SafeInsetTop:" + top);
//						Log.d("HasNotchInScreen", "安全区域距离屏幕底部的距离 SafeInsetBottom:" + bottom);

						float a1 = Math.max(left, right);
						float a2 = Math.max(top, bottom);
						fRet = Math.max(a1, a2);
						Log.d("HasNotchInScreen", "Android.P GetNotchHeight:" + fRet);
					}
				}
			}
		}
		else if (HwNotchUtils.hasNotch(targetActivity) && HwNotchUtils.getIsNotchSwitchOpen(targetActivity) == false)
		{
			// 华为
			int[] rect = HwNotchUtils.getNotchSize(targetActivity);
			int width = rect[0];
			int height = rect[1];
			fRet = height;
			Log.d("HasNotchInScreen", "华为 Open Notch:" + HwNotchUtils.getIsNotchSwitchOpen(targetActivity));
			Log.d("HasNotchInScreen", "华为 GetNotchHeight:" + fRet + "width" + width + "height" + height);
		}
		else if (MeizuNotchUtils.hasNotch(targetActivity))
		{
			// 魅族
			int width = MeizuNotchUtils.getNotWidth(targetActivity);
			int height = MeizuNotchUtils.getNotHeight(targetActivity);
			fRet = DEFAULT_NOTCH_HEIGHT;
			Log.d("HasNotchInScreen", "魅族 GetNotchHeight:" + fRet + "width" + width + "height" + height);
		}
		else if (OppoNotchUtils.hasNotch(targetActivity))
		{
			// Oppo
			fRet = DEFAULT_NOTCH_HEIGHT;
			Log.d("HasNotchInScreen", "Oppo GetNotchHeight:" + fRet);
		}
		else if (VivoNotchUtils.hasNotch(targetActivity))
		{
			// Vivo
			fRet = DEFAULT_NOTCH_HEIGHT;
			Log.d("HasNotchInScreen", "Vivo GetNotchHeight:" + fRet);
		}
		else if (XiaomiNotchUtils.hasNotch(targetActivity))
		{
			// 小米
			int width = XiaomiNotchUtils.getNotWidth(targetActivity);
			int height = XiaomiNotchUtils.getNotHeight(targetActivity);
			fRet = DEFAULT_NOTCH_HEIGHT;
			Log.d("HasNotchInScreen", "小米 GetNotchHeight:" + fRet + "width" + width + "height" + height);
		}

		return fRet;
	}
}