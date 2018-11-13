package com.meteoritestudio.applauncher;

import java.io.File;
import java.io.FileWriter;
import java.io.PrintWriter;
import java.text.SimpleDateFormat;
import java.util.Date;

import android.util.Log;

public class JavaLog {
    private String TAG = "JavaLog";
    private static PrintWriter m_printWriter = null;

    private static JavaLog m_Instance = null;

    public static JavaLog Instance() {
	if (m_Instance == null) {
	    m_Instance = new JavaLog();
	}

	return m_Instance;
    }

    public boolean Init(String path) {
	return CreateLogFile(path);
    }

    private boolean CreateLogFile(String path) {
	boolean bRet = true;

	String destPath = path.substring(0, path.lastIndexOf("/"));
	File mWorkingPath = new File(destPath);

	if (!mWorkingPath.exists()) {
	    if (!mWorkingPath.mkdirs()) {
		Log.e(TAG, "mkdirs failed!!");
	    }
	}

	File pFile = new File(path);
	if (pFile.exists()) {
	    pFile.delete();
	}

	try {
	    FileWriter pFileWriter = new FileWriter(pFile, true);

	    m_printWriter = new PrintWriter(pFileWriter);

	    Date date = new Date();
	    SimpleDateFormat sdf = new SimpleDateFormat(
		    "yyyy-MM-dd HH:mm:ss\r\n");
	    String str = TAG + " Create: " + sdf.format(date);

	    m_printWriter.println(str);
	    m_printWriter.flush();
	} catch (Exception e) {
	    bRet = false;
	    e.printStackTrace();
	}

	return bRet;
    }

    public void WriteLog(String strLog) {

	if (m_printWriter == null)
	    return;

	try {
	    m_printWriter.println(TAG + " " + strLog + "\r\n");
	    m_printWriter.flush();

	} catch (Exception e) {
	    e.printStackTrace();
	}
    }

    public void Destory() {
	// TODO Auto-generated method stub
	if (m_printWriter == null)
	    return;

	try {

	    m_printWriter.println("\r\n\r\n" + TAG + "Destory!!!");
	    m_printWriter.flush();
	    m_printWriter.close();
	    m_printWriter = null;

	} catch (Exception e) {
	    e.printStackTrace();
	}
    }

}