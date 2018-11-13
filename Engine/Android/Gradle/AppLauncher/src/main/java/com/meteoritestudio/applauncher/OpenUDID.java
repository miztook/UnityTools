package com.meteoritestudio.applauncher;

import android.app.Activity;


public class OpenUDID {
	
    public static String GetOpenUDID(Activity targetActivity)
    {
    	String retStr = "";
    	
    	OpenUDID_manager.sync(targetActivity);
    	if (OpenUDID_manager.isInitialized())
    	{
    		retStr = OpenUDID_manager.getOpenUDID();
    	}
    	
    	return retStr;
    }
}