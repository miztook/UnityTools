package com.meteoritestudio.applauncher;

import java.lang.reflect.Method;
import android.app.Activity;
import android.content.Context;
import android.util.DisplayMetrics;
import android.util.Log;


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
	
	
	private final float DEFAULT_NOTCH_RATIO = 48;
	public static float GetNotchSize(Activity targetActivity) {
		float fRet = 0.0f;
		float dpi = GetDpi(targetActivity);
		float density = GetDensity(targetActivity);
				
		return fRet;
	}
	
	public static boolean IgnoreNotchScreen(Activity targetActivity) {
		boolean bRet = false;
		// Huawei
    	if(hasNotchInScreenAtHuawei(targetActivity))
    		return true;
    	
    	return bRet;
	}
	
    public static boolean HasNotchInScreen(Activity targetActivity)
    {
    	boolean bRet = false;
    	
    	// Oppo
    	if(hasNotchInScreenAtOppo(targetActivity))
    		return true;
    	
    	// Huawei
    	if(hasNotchInScreenAtHuawei(targetActivity))
    		return true;
    	
    	// Voio
    	if(hasNotchInScreenAtVivo(targetActivity))
    		return true;
    	
    	return bRet;
    }
    
    // Oppo
    private static boolean hasNotchInScreenAtOppo(Context context){
        return context.getPackageManager().hasSystemFeature("com.oppo.feature.screen.heteromorphism");
    }
    
    // Huawei
    private static boolean hasNotchInScreenAtHuawei(Context context)
    {
        boolean ret = false;
        try 
        {
            ClassLoader cl = context.getClassLoader();
            Class HwNotchSizeUtil = cl.loadClass("com.huawei.android.util.HwNotchSizeUtil");
            Method get = HwNotchSizeUtil.getMethod("hasNotchInScreen");
            ret = (Boolean) get.invoke(HwNotchSizeUtil);
        } 
        catch (ClassNotFoundException e){}
        catch (NoSuchMethodException e){}
        catch (Exception e){}

        return ret; 
    }
    
    // Vivo
    private static boolean hasNotchInScreenAtVivo(Context context)
    {
    	final int NOTCH_IN_SCREEN_VIVO=0x00000020;
    	final int ROUNDED_IN_SCREEN_VIVO=0x00000008;
    	
        boolean ret = false;
        try 
        {
            ClassLoader cl = context.getClassLoader();
            Class FtFeature = cl.loadClass("com.util.FtFeature");
            Method get = FtFeature.getMethod("isFeatureSupport",int.class);
            ret = (Boolean) get.invoke(FtFeature,NOTCH_IN_SCREEN_VIVO);
        } 
        catch (ClassNotFoundException e){}
        catch (NoSuchMethodException e){}
        catch (Exception e){}
        
        return ret;
    }
}