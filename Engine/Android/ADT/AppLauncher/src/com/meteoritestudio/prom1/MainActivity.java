package com.meteoritestudio.prom1;

import com.unity3d.player.UnityPlayer;
import java.io.*;
import java.net.*;
import java.util.*;

import android.app.Activity;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffXfermode;
import android.graphics.Rect;
import android.graphics.RectF;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.provider.MediaStore;
import android.provider.MediaStore.Images.Media;
import android.util.Log;
import android.widget.Toast;
import android.app.PendingIntent;
import android.app.AlarmManager;

import com.meteoritestudio.applauncher.JavaLog;
import com.onevcat.*;

public class MainActivity extends com.onevcat.uniwebview.AndroidPlugin {
//public class MainActivity extends UnityPlayerActivity {
	private static MainActivity _Instance = null;
	private static final int TIME_OUT = 10 * 1000; // 超时时间
	private static final String CHARSET = "utf-8"; // 设置编码
	private static final String TAG = "com.meteoritestudio.prom1.MainActivity";

	public static String srcPath;
	private static String requestUrl;
	private static String loginKey;
	public static String SAVED_IMAGE_DIR_PATH = Environment
			.getExternalStorageDirectory().getPath() + "/";

	public static String cameraPath;
	public static Uri photoUri;

	public static MainActivity getInstance() {
		return _Instance;
	}

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		//int ret = GCloudVoiceEngine.getInstance().init(getApplicationContext(), this);
		int ret = 0;
		
		_Instance = this;

		// http://blog.csdn.net/c15522627353/article/details/52452490
		// AndroidBug54971Workaround.assistActivity(findViewById(android.R.id.content));

		String sdcardDir = Environment.getExternalStorageDirectory().toString();
		String path = sdcardDir
				+ "/M1JavaLog.txt";
		JavaLog.Instance().Init(path);

		WriteLog(String.format("GCloudVoiceEngine init %d", ret));
	}

	@Override
	protected void onDestroy() {
		JavaLog.Instance().Destory();
		super.onDestroy();
	}

	protected void WriteLog(String strLog) {
		Log.i(TAG, strLog);
		JavaLog.Instance().WriteLog(strLog);
	}

	public static void DoRestartImmediate() {
		if (_Instance == null)
			return;

		Intent intent = _Instance
				.getBaseContext()
				.getPackageManager()
				.getLaunchIntentForPackage(
						_Instance.getBaseContext().getPackageName());
		intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
		_Instance.startActivity(intent);
	}

	public static void DoRestart(int Ntime) {
		if (Ntime < 200)
			Ntime = 200;

		Intent restartIntent = _Instance.getPackageManager()
				.getLaunchIntentForPackage(_Instance.getPackageName());
		PendingIntent intent = PendingIntent.getActivity(_Instance, 0,
				restartIntent, Intent.FLAG_ACTIVITY_CLEAR_TOP);
		AlarmManager manager = (AlarmManager) _Instance
				.getSystemService(Context.ALARM_SERVICE);
		manager.set(AlarmManager.RTC, System.currentTimeMillis() + Ntime,
				intent);
		_Instance.finish();
		android.os.Process.killProcess(android.os.Process.myPid());
	}

	public static boolean TakeCamera() {
		if (_Instance == null)
			return false;

		String state = Environment.getExternalStorageState();
		if (state.equals(Environment.MEDIA_MOUNTED)) {
			cameraPath = SAVED_IMAGE_DIR_PATH + "capture.jpg";
			Intent intent = new Intent();
			// 指定开启系统相机的Action
			intent.setAction(MediaStore.ACTION_IMAGE_CAPTURE);
			String out_file_path = SAVED_IMAGE_DIR_PATH;
			File dir = new File(out_file_path);
			if (!dir.exists()) {
				dir.mkdirs();
			} // 把文件地址转换成Uri格式
			Uri uri = Uri.fromFile(new File(cameraPath));
			// 设置系统相机拍摄照片完成后图片文件的存放地址
			intent.putExtra(MediaStore.EXTRA_OUTPUT, uri);

			_Instance.startActivityForResult(intent, 10);

			return true;
		} else {
			Toast.makeText(_Instance.getApplicationContext(),
					"Make sure SDCard is avaiable", Toast.LENGTH_LONG).show();

			return true;
		}
	}

	public static boolean TakePhoto() {
		if (_Instance == null)
			return false;

		_Instance.srcPath = "";

		String filename = "photo.jpg";
		ContentValues values = new ContentValues();
		values.put(Media.TITLE, filename);
		photoUri = _Instance.getContentResolver().insert(
				MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values);

		// 参考: http://www.cnblogs.com/loonggg/p/4981782.html

		Intent intent;
		if (Build.VERSION.SDK_INT < 19) {

			intent = new Intent(Intent.ACTION_GET_CONTENT);
			intent.setType("image/*");
			intent.addCategory(Intent.CATEGORY_OPENABLE);

		} else {

			intent = new Intent(
					Intent.ACTION_PICK,
					android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
		}

		intent.putExtra(MediaStore.EXTRA_OUTPUT, photoUri);

		/*
		 * intent.putExtra("crop", "true"); intent.putExtra("aspectX", 1);
		 * intent.putExtra("aspectY", 1); intent.putExtra("outputX", 128);
		 * intent.putExtra("outputY", 128); intent.putExtra("scale", true);
		 * intent.putExtra("return-data", true);
		 */

		_Instance.startActivityForResult(intent, 11);

		return true;
	}

	public void onActivityResult(int requestCode, int resultCode, Intent data) {
		super.onActivityResult(requestCode, resultCode, data);

		// WriteLog(String.format("begin onActivityResult!!! requestCode %d, resultCode %d",
		// requestCode, resultCode));

		if (requestCode == 10 && resultCode == Activity.RESULT_OK) // Camera
		{
			// WriteLog("data1-->Camera");

			srcPath = cameraPath;
			// WriteLog(String.format("data1 save--> %s", srcPath));

			// UnityPlayer.UnitySendMessage("EntryPoint",
			// "OnPhotoCameraFileResult", srcPath);

			File picture = new File(SAVED_IMAGE_DIR_PATH + "capture.jpg");

			cropImageUri(Uri.fromFile(picture), 128, 128, 12);

		} else if (requestCode == 11 && resultCode == Activity.RESULT_OK
				&& data != null) // Photo
		{
			WriteLog("data2-->Photo");

			try {
				Uri uri = data.getData();
				if (uri == null)
					uri = photoUri;

				Bitmap bitmap = decodeUriAsBitmap(uri);

				if (bitmap != null) {

					final String absPath = getAbsolutePath(_Instance, uri);
					if (absPath != null)
						srcPath = absPath;

					if (bitmap.getWidth() == bitmap.getHeight()
							&& bitmap.getWidth() <= 128
							&& bitmap.getHeight() <= 128) {
						// bitmap = getRoundedCornerBitmap(bitmap);
						UnityPlayer.UnitySendMessage("EntryPoint",
								"OnPhotoCameraFileResult", srcPath);
						srcPath = "";
					} else {
						cropImageUri(uri, 128, 128, 12);
					}
				}
			} catch (Exception e) {
				WriteLog(e.getMessage());
			}

			WriteLog(String.format("data2 save--> %s", srcPath));
		} else if (requestCode == 12 && resultCode == Activity.RESULT_OK
				&& data != null) // Photo
		{
			if (srcPath != "") {
				File outFile = new File(srcPath);
				if (outFile.exists())
					UnityPlayer.UnitySendMessage("EntryPoint",
							"OnPhotoCameraFileResult", srcPath);

				srcPath = "";
			}
		}

		// WriteLog(String.format("end onActivityResult!!! requestCode %d, resultCode %d",
		// requestCode, resultCode));
	}

	private Bitmap decodeUriAsBitmap(Uri uri) {
		Bitmap bitmap = null;
		try {
			bitmap = BitmapFactory.decodeStream(getContentResolver()
					.openInputStream(uri));
		} catch (FileNotFoundException e) {
			e.printStackTrace();
			return null;
		}
		return bitmap;
	}

	private void cropImageUri(Uri uri, int outputX, int outputY, int requestCode) {

		Intent intent = new Intent("com.android.camera.action.CROP");

		intent.setDataAndType(uri, "image/*");

		intent.putExtra("crop", "true");

		intent.putExtra("aspectX", 1);

		intent.putExtra("aspectY", 1);

		intent.putExtra("outputX", outputX);

		intent.putExtra("outputY", outputY);

		intent.putExtra("scale", true);

		intent.putExtra(MediaStore.EXTRA_OUTPUT, uri);

		intent.putExtra("return-data", true);

		intent.putExtra("outputFormat", Bitmap.CompressFormat.JPEG.toString());

		intent.putExtra("noFaceDetection", true); // no face detection

		startActivityForResult(intent, requestCode);

	}

	public static String startCamera(Activity activity, int requestCode) {

		// 指定相机拍摄照片保存地址
		String state = Environment.getExternalStorageState();
		if (state.equals(Environment.MEDIA_MOUNTED)) {
			Intent intent = new Intent();
			// 指定开启系统相机的Action
			intent.setAction(MediaStore.ACTION_IMAGE_CAPTURE);
			File outDir = Environment
					.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES);
			if (!outDir.exists()) {
				outDir.mkdirs();
			}
			File outFile = new File(outDir, "capture.jpg");
			// 把文件地址转换成Uri格式
			Uri uri = Uri.fromFile(outFile);
			// LogUtil.d("getAbsolutePath=" + outFile.getAbsolutePath());
			// 设置系统相机拍摄照片完成后图片文件的存放地址
			intent.putExtra(MediaStore.EXTRA_OUTPUT, uri);
			// 此值在最低质量最小文件尺寸时是0，在最高质量最大文件尺寸时是１
			intent.putExtra(MediaStore.EXTRA_VIDEO_QUALITY, 0);
			activity.startActivityForResult(intent, requestCode);
			return outFile.getAbsolutePath();
		} else {
			Toast.makeText(activity, "请确认已经插入SD卡", Toast.LENGTH_LONG).show();
			return null;
		}
	}

	public String getAbsolutePath(final Context context, final Uri uri) {
		if (null == uri)
			return null;

		final String scheme = uri.getScheme();
		String data = null;
		if (scheme == null) {
			data = uri.getPath();
		} else if (ContentResolver.SCHEME_FILE.equals(scheme)) {
			data = uri.getPath();
		} else if (ContentResolver.SCHEME_CONTENT.equals(scheme)) {
			String[] filePathColumns = { MediaStore.Images.Media.DATA };
			Cursor cursor = context.getContentResolver().query(uri,
					filePathColumns, null, null, null);

			if (null != cursor) {
				if (cursor.moveToFirst()) {
					int index = cursor.getColumnIndex(filePathColumns[0]);
					if (index > -1) {
						data = cursor.getString(index);
					}
				}
				cursor.close();
			}

		}
		return data;
	}

	private void submitUploadFile() {
		final File file = new File(srcPath);
		final String RequestURL = requestUrl;
		if (file == null || (!file.exists())) {
			return;
		}

		// Log.i(TAG, "请求的URL=" + RequestURL);
		// Log.i(TAG, "请求的fileName=" + file.getName());
		final Map<String, String> params = new HashMap<String, String>();
		params.put("user_id", loginKey);
		params.put("file_type", "1");
		// params.put("content", img_content.getText().toString());
		// showProgressDialog();
		new Thread(new Runnable() { // 开启线程上传文件
					@Override
					public void run() {
						uploadFile(file, RequestURL, params);
					}
				}).start();
	}

	private String uploadFile(File file, String RequestURL,
			Map<String, String> param) {
		String result = null;
		String BOUNDARY = UUID.randomUUID().toString(); // 边界标识 随机生成
		String PREFIX = "--", LINE_END = "\r\n";
		String CONTENT_TYPE = "multipart/form-data"; // 内容类型
		// 显示进度框
		// showProgressDialog();
		try {
			URL url = new URL(RequestURL);
			HttpURLConnection conn = (HttpURLConnection) url.openConnection();
			conn.setReadTimeout(TIME_OUT);
			conn.setConnectTimeout(TIME_OUT);
			conn.setDoInput(true); // 允许输入流
			conn.setDoOutput(true); // 允许输出流
			conn.setUseCaches(false); // 不允许使用缓存
			conn.setRequestMethod("POST"); // 请求方式
			conn.setRequestProperty("Charset", CHARSET); // 设置编码
			conn.setRequestProperty("connection", "keep-alive");
			conn.setRequestProperty("Content-Type", CONTENT_TYPE + ";boundary="
					+ BOUNDARY);
			if (file != null) {
				/**
				 * 当文件不为空，把文件包装并且上传
				 */
				DataOutputStream dos = new DataOutputStream(
						conn.getOutputStream());
				StringBuffer sb = new StringBuffer();

				String params = "";
				if (param != null && param.size() > 0) {
					Iterator<String> it = param.keySet().iterator();
					while (it.hasNext()) {
						sb = null;
						sb = new StringBuffer();
						String key = it.next();
						String value = param.get(key);
						sb.append(PREFIX).append(BOUNDARY).append(LINE_END);
						sb.append("Content-Disposition: form-data; name=\"")
								.append(key).append("\"").append(LINE_END)
								.append(LINE_END);
						sb.append(value).append(LINE_END);
						params = sb.toString();
						Log.i(TAG, key + "=" + params + "##");
						dos.write(params.getBytes());
						// dos.flush();
					}
				}
				sb = new StringBuffer();
				sb.append(PREFIX);
				sb.append(BOUNDARY);
				sb.append(LINE_END);
				/**
				 * 这里重点注意： name里面的值为服务器端需要key 只有这个key 才可以得到对应的文件
				 * filename是文件的名字，包含后缀名的 比如:abc.png
				 */
				sb.append("Content-Disposition: form-data; name=\"upfile\";filename=\""
						+ file.getName() + "\"" + LINE_END);
				sb.append("Content-Type: image/pjpeg; charset=" + CHARSET
						+ LINE_END);
				sb.append(LINE_END);
				dos.write(sb.toString().getBytes());
				InputStream is = new FileInputStream(file);
				byte[] bytes = new byte[1024];
				int len = 0;
				while ((len = is.read(bytes)) != -1) {
					dos.write(bytes, 0, len);
				}
				is.close();
				dos.write(LINE_END.getBytes());
				byte[] end_data = (PREFIX + BOUNDARY + PREFIX + LINE_END)
						.getBytes();
				dos.write(end_data);

				dos.flush();
				/**
				 * 获取响应码 200=成功 当响应成功，获取响应的流
				 */

				int res = conn.getResponseCode();
				System.out.println("res=========" + res);
				if (res == 200) {
					InputStream input = conn.getInputStream();
					StringBuffer sb1 = new StringBuffer();
					int ss;
					while ((ss = input.read()) != -1) {
						sb1.append((char) ss);
					}
					result = sb1.toString();
					// // 移除进度框
					// removeProgressDialog();
					finish();
				} else {
				}
			}
		} catch (MalformedURLException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
		return result;
	}

	public static void SavePhoto(String path) {
		try {
			Context context = _Instance.getApplicationContext();
			String photo_uri = MediaStore.Images.Media.insertImage(
					context.getContentResolver(), path, "TeraPhoto", "");
			context.sendBroadcast(new Intent(
			// Intent.ACTION_MEDIA_MOUNTED,
					Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, Uri.parse("file://"
							+ photo_uri)));
		} catch (FileNotFoundException e) {

		}
	}

	public Bitmap getRoundedCornerBitmap(Bitmap bitmap) {
		if (bitmap == null) {
			return null;
		}

		Bitmap output = Bitmap.createBitmap(bitmap.getWidth(),
				bitmap.getHeight(), Bitmap.Config.ARGB_8888);
		Canvas canvas = new Canvas(output);
		final Paint paint = new Paint();
		/* 去锯齿 */
		paint.setAntiAlias(true);
		paint.setFilterBitmap(true);
		paint.setDither(true);
		// 保证是方形，并且从中心画
		int width = bitmap.getWidth();
		int height = bitmap.getHeight();
		int w;
		int deltaX = 0;
		int deltaY = 0;
		if (width <= height) {
			w = width;
			deltaY = height - w;
		} else {
			w = height;
			deltaX = width - w;
		}
		final Rect rect = new Rect(deltaX, deltaY, w, w);
		final RectF rectF = new RectF(rect);

		paint.setAntiAlias(true);
		canvas.drawARGB(0, 0, 0, 0);
		// 圆形，所有只用一个
		int radius = (int) (Math.sqrt(w * w * 2.0d) / 2);
		canvas.drawRoundRect(rectF, radius, radius, paint);
		paint.setXfermode(new PorterDuffXfermode(PorterDuff.Mode.SRC_IN));
		canvas.drawBitmap(bitmap, rect, rect, paint);
		return output;
	}
}