package com.meteoritestudio.applauncher;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.util.Vector;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.ProgressDialog;
import android.content.DialogInterface;
import android.content.res.AssetManager;
import android.graphics.drawable.ColorDrawable;
import android.os.StatFs;
import android.util.Log;
import android.view.Gravity;
import android.view.Window;
import android.view.WindowManager;

public class CopyAssetDirectory implements Runnable {
    private Activity m_targetActivity;
    private String m_sourceDir;
    private String m_destDir;
    private String m_title;
    private String m_NoSpaceTitle;
    private String m_NoSpaceMessage;
    private String m_NoSpaceOK;
    private ProgressDialog m_progressDlg;
    private volatile Boolean m_finished = false;
    private volatile int currentProgress = 0;
    private long m_nTotalSize = 0;
    private int m_nCopyBlock = 1024;
    private static Vector<FileInfo> m_FileList = new Vector<FileInfo>();

    private CopyAssetDirectory() {
    }

    public static String execute(final Activity targetActivity,
	    final String sourceDir, final String destDir,
	    final String copyTitle, final String titleNoSpace,
	    final String messageNoSpace, final String okNoSpace,
	    final long totalSize, final int copyBlock) {
	final CopyAssetDirectory self = new CopyAssetDirectory();

	Runnable initRunner = new Runnable() {
	    @Override
	    public void run() {
		self.init(targetActivity, sourceDir, destDir, copyTitle,
			titleNoSpace, messageNoSpace, okNoSpace, totalSize,
			copyBlock);

		synchronized (this) {
		    this.notify();
		}
	    }
	};

	targetActivity.runOnUiThread(initRunner);
	synchronized (initRunner) {
	    try {
		initRunner.wait();
	    } catch (InterruptedException e) {
		Log.d("CopyAssetDirectory1", "InterruptedException");
		return null;
	    }
	}

	if (self.shouldCopyFile())
	    self.run();

	if (self.m_progressDlg.isShowing()) {
	    self.m_targetActivity.runOnUiThread(new Runnable() {

		@Override
		public void run() {
		    // TODO Auto-generated method stub
		    self.m_progressDlg.cancel();
		}
	    });
	}

	return self.m_destDir;
    }

    private void init(Activity targetActivity, String sourceDir,
	    String destDir, String copyTitle, String titleNoSpace,
	    String messageNoSpace, String okNoSpace, long totalSize,
	    int copyBlock) {
	Log.d("CopyAssetDirectory1", "init, source dir = " + sourceDir
		+ ", destDir=" + destDir);

	m_targetActivity = targetActivity;
	m_sourceDir = sourceDir;
	m_title = copyTitle;
	m_NoSpaceTitle = titleNoSpace;
	m_NoSpaceMessage = messageNoSpace;
	m_NoSpaceOK = okNoSpace;
	m_nTotalSize = totalSize;
	m_nCopyBlock = copyBlock;

	// if (AndroidWrapper.isHaveSDCard())
	// m_destDir = AndroidWrapper.getSDCardPath() + "/" + destDir;
	// else
	m_destDir = destDir;

	m_progressDlg = new ProgressDialog(m_targetActivity);
	m_progressDlg.setMax(100);
	m_progressDlg.setProgressStyle(ProgressDialog.STYLE_HORIZONTAL);
	m_progressDlg.setTitle(m_title);
	m_progressDlg.setCancelable(false);
	m_progressDlg.setCanceledOnTouchOutside(false);

	m_progressDlg.show();

	Window window = m_progressDlg.getWindow();
	WindowManager.LayoutParams params = window.getAttributes();
	params.dimAmount = 0f;
	params.gravity = Gravity.CENTER_HORIZONTAL;
	window.setAttributes(params);
	window.setBackgroundDrawable(new ColorDrawable(
		android.graphics.Color.TRANSPARENT));
    }

    // 暂时在没有 pck的情况下，读取FileList文件列表，减少遍历列表时间消耗
    private void GetListFile(String path, Vector<FileInfo> fileList) {
	InputStreamReader inputReader = null;
	try {
	    inputReader = new InputStreamReader(assetManager().open(path));
	} catch (IOException e) {
	}

	JavaLog.Instance().WriteLog("filelist path = " + path);

	BufferedReader in;
	boolean bIsFirstLine = true;
	try {
	    in = new BufferedReader(inputReader);
	    if (in != null) {
		String line = null;
		while ((line = in.readLine()) != null) {
		    if (bIsFirstLine) {
			bIsFirstLine = false;
			continue;
		    }

		    fileList.add(new FileInfo(line, 0));
		}
	    }
	} catch (FileNotFoundException e) {
	} catch (IOException e) {
	}

	JavaLog.Instance()
		.WriteLog("filelist End!  Count = " + fileList.size());
    }

    public static long CopyAssetFileToPath(final Activity targetActivity,
	    final String fileName, final String sourceFolder,
	    final String destFolder) {
	long writeLen = -1;
	InputStream in = null;
	OutputStream out = null;

	try {
	    AssetManager assetManager = targetActivity.getResources()
		    .getAssets();

	    byte[] buffer = new byte[1024];

	    String fullPath = combinePath(sourceFolder, fileName);
	    in = assetManager.open(fullPath);

	    String newFileName = combinePath(destFolder, fileName);
	    new File(newFileName).getParentFile().mkdirs();

	    out = new FileOutputStream(newFileName);

	    long finishedSize = 0;
	    int read;
	    while ((read = in.read(buffer)) != -1) {
		out.write(buffer, 0, read);
		out.flush();

		finishedSize += read;
	    }

	    writeLen = finishedSize;
	} catch (IOException ioException) {

	} catch (Exception e) {

	} finally {
	    if (in != null) {
		try {
		    in.close();
		} catch (IOException e) {
		    // NOOP
		}
	    }
	    if (out != null) {
		try {
		    out.close();
		} catch (IOException e) {
		    // NOOP
		}
	    }
	}

	return writeLen;
    }

    @Override
    public void run() {
	Vector<FileInfo> fileList = new Vector<FileInfo>();

	// 获取文件列表
	GetListFile(m_sourceDir + "/listfile.txt", fileList);
	// BuildFileList(m_sourceDir, fileList);

	if (m_nTotalSize == 0)
	    m_nTotalSize = 1;

	new File(m_destDir).mkdirs();
	long freeSpace = CalcFreeSpace(m_destDir);

	if (m_nTotalSize > freeSpace) {
	    ShowNoSpaceDialog(m_NoSpaceTitle, m_NoSpaceMessage, m_NoSpaceOK,
		    m_nTotalSize);
	    return;
	}

	long finishedSize = 0;
	int lastProgress = 0;
	byte[] buffer = new byte[this.m_nCopyBlock];

	for (int iFile = 0; iFile < fileList.size(); ++iFile) {
	    String relativePath = fileList.get(iFile).relativePath;
	    String fullPath = combinePath(m_sourceDir, relativePath);

	    // JavaLog.Instance().WriteLog("File : " + relativePath);
	    try {
		InputStream in = assetManager().open(fullPath);
		String newFileName = combinePath(m_destDir, relativePath);

		new File(newFileName).getParentFile().mkdirs();

		OutputStream out = new FileOutputStream(newFileName);

		int read;
		while ((read = in.read(buffer)) != -1) {
		    out.write(buffer, 0, read);
		    out.flush();

		    finishedSize += read;

		    currentProgress = (int) (finishedSize * 100 / m_nTotalSize);
		    if (currentProgress != lastProgress) {
			lastProgress = currentProgress;
			m_targetActivity.runOnUiThread(new Runnable() {

			    @Override
			    public void run() {
				// TODO Auto-generated method stub
				m_progressDlg.setProgress(currentProgress);
			    }
			});

		    }
		}
		in.close();
		out.close();
	    } catch (IOException e) {
	    }
	}

	writeFlagFile();
	m_progressDlg.cancel();
	m_finished = true;
    }

    private static String combinePath(String path1, String path2) {
	if (path1.isEmpty() || path2.isEmpty())
	    return path1 + path2;
	else
	    return path1 + File.separator + path2;
    }

    public Boolean IsFinished() {
	return m_finished;
    }

    private AssetManager assetManager() {
	return m_targetActivity.getResources().getAssets();
    }

    public static int BuildFileList(final Activity targetActivity,
	    final String assetDir) {
	m_FileList.clear();
	BuildFileListInner(targetActivity, assetDir, "", m_FileList);
	return m_FileList.size();
    }

    public static long GetFileListTotalFileSize() {
	long total = 0;
	for (int iFile = 0; iFile < m_FileList.size(); ++iFile) {
	    total += m_FileList.get(iFile).size;
	}
	return total;
    }

    public static String GetRelativeFileName(int index) {
	if (index < 0 || index >= m_FileList.size())
	    return "";
	return m_FileList.get(index).relativePath;
    }

    private static void BuildFileListInner(final Activity targetActivity,
	    String assetBaseDir, String currentPath, Vector<FileInfo> fileList) {
	if (currentPath.startsWith("AssetBundles"))
	    return;

	try {
	    String fullPath = combinePath(assetBaseDir, currentPath);

	    AssetManager mgr = targetActivity.getResources().getAssets();
	    String[] files = mgr.list(fullPath);
	    if (files.length == 0) // is a file
	    {
		InputStream file = mgr.open(fullPath);
		long fileLength = file.available();
		file.close();

		fileList.add(new FileInfo(currentPath, fileLength));
	    } else // is a directory
	    {
		for (int iFile = 0; iFile < files.length; ++iFile) {
		    String relativePath = combinePath(currentPath, files[iFile]);

		    BuildFileListInner(targetActivity, assetBaseDir,
			    relativePath, fileList);
		}
	    }
	} catch (IOException e) {
	    JavaLog.Instance().WriteLog(e.getMessage());
	}
    }

    private long CalcFreeSpace(String path) {
	StatFs statFs = new StatFs(path);
	long Free = (long) statFs.getAvailableBlocks()
		* (long) statFs.getBlockSize();
	return Free;
    }

    private void ShowNoSpaceDialog(final String strTitle,
	    final String strMessage, final String strOk, final long totalSize) {
	m_targetActivity.runOnUiThread(new Runnable() {
	    public void run() {
		AlertDialog.Builder dlgBuilder = new AlertDialog.Builder(
			m_targetActivity);
		// dlgBuilder.setTitle("SD卡空间不足");
		// String spaceStr = Integer.toString((int)Math.ceil(totalSize *
		// 1.1f / (1024*1024)));
		// dlgBuilder.setMessage("请保证SD卡有足够的空间" + spaceStr + " MB");

		dlgBuilder.setTitle(strTitle);
		dlgBuilder.setMessage(strMessage);
		dlgBuilder.setCancelable(false);

		dlgBuilder.setPositiveButton(strOk,
			new AlertDialog.OnClickListener() {
			    public void onClick(DialogInterface dialog,
				    int which) {
				dialog.dismiss();
				System.exit(0);
			    }
			});

		dlgBuilder.create().show();
	    }
	});
    }

    public boolean shouldCopyFile() {
	try {
	    File file = new File(m_destDir + "/" + ".lock");
	    if (file.exists()) {
		FileReader fReader = new FileReader(file);
		BufferedReader bReader = new BufferedReader(fReader);
		String str = bReader.readLine(); // only one line.
		fReader.close();

		int versionCodeInFile = Integer.valueOf(str).intValue();
		int curVersionCode = AndroidWrapper
			.getCurVersionCode(m_targetActivity);

		if (versionCodeInFile == curVersionCode) {
		    return false;
		}
	    }
	} catch (IOException e) {
	} catch (Exception e) {
	}

	return true;
    }

    private void writeFlagFile() {
	File file = new File(m_destDir + "/" + ".lock");

	File workingPath = new File(m_destDir);
	if (!workingPath.exists()) {

	    if (!workingPath.mkdirs()) {
		// make file failed
	    }
	}

	if (file.exists()) {
	    file.delete();
	}

	try {
	    int curVersionCode = AndroidWrapper
		    .getCurVersionCode(m_targetActivity);
	    String strVersionCode = Integer.toString(curVersionCode);
	    OutputStream out = new FileOutputStream(file);
	    out.write(strVersionCode.getBytes());
	    out.close();
	} catch (IOException el) {
	    return;
	} catch (Exception e) {
	    return;
	}
    }
}
