package com.meteoritestudio.prom1;

import com.meteoritestudio.applauncher.CameraPhoto;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.os.Debug;
import android.util.Log;
import android.app.PendingIntent;
import android.app.AlarmManager;
import android.content.ComponentCallbacks2;

import com.meteoritestudio.applauncher.EmulatorDetector;
import com.meteoritestudio.applauncher.JavaLog;
import com.meteoritestudio.applauncher.PermissionUtils;
import com.meteoritestudio.applauncher.MacUtils;

import android.support.v4.app.ActivityCompat;
import android.support.annotation.NonNull;
import android.app.ActivityManager;
import android.os.Environment;


public class MainActivity extends com.onevcat.uniwebview.AndroidPlugin implements ActivityCompat.OnRequestPermissionsResultCallback, ComponentCallbacks2 {
//public class MainActivity extends UnityPlayerActivity {
	private static MainActivity _Instance = null;
	private static final int TIME_OUT = 10 * 1000; // 超时时间
	private static final String CHARSET = "utf-8"; // 设置编码
	private static final String TAG = "com.meteoritestudio.prom1.MainActivity";

	public static MainActivity getInstance() {
		return _Instance;
	}

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		int ret = 0; //GCloudVoiceEngine.getInstance().init(getApplicationContext(), this);
		
		_Instance = this;

		// http://blog.csdn.net/c15522627353/article/details/52452490
		// AndroidBug54971Workaround.assistActivity(findViewById(android.R.id.content));


     /*
		String sdcardDir = Environment.getExternalStorageDirectory().toString();
		String path = sdcardDir
				+ "/M1JavaLog.txt";

		JavaLog.Instance().Init(path);

		WriteLog(String.format("MainActivity OnCreate !!"));
     */

        Log.i(TAG, "MainActivity OnCreate !!");
	}

	@Override
	protected void onDestroy() {
		//JavaLog.Instance().Destory();
		super.onDestroy();
	}

	@Override
	protected void onNewIntent(Intent intent) {
		super.onNewIntent(intent);
		// New intent update to the current activity
		this.setIntent(intent);
	}

	protected void WriteLog(String strLog) {
		Log.i(TAG, strLog);
		JavaLog.Instance().WriteLog(strLog);
	}

	public static int GetLargeMemoryLimit()
	{
		int limit = 0;
		try {
			ActivityManager activityManager = (ActivityManager) _Instance.getApplication().getSystemService(ACTIVITY_SERVICE);
			limit = activityManager.getLargeMemoryClass();
		}
		catch (Exception e) {
			limit = 0;
		}
		return limit;
	}

	public static int GetMemoryLimit()
	{
		int limit = 0;
		try {
			ActivityManager activityManager = (ActivityManager) _Instance.getApplication().getSystemService(ACTIVITY_SERVICE);
			limit = activityManager.getMemoryClass();
		}
		catch (Exception e){
			limit = 0;
		}
		return limit;
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
		return CameraPhoto.TakeCamera(_Instance);
	}

	public static boolean TakePhoto() {
		return CameraPhoto.TakePhoto(_Instance);
	}

	public static boolean SavePhoto(String path)
	{
		return CameraPhoto.SavePhoto(_Instance, path);
	}

	public void onActivityResult(int requestCode, int resultCode, Intent data) {
		super.onActivityResult(requestCode, resultCode, data);

		CameraPhoto.OnActivityResult(this, requestCode, resultCode, data);
	}


	private PermissionUtils.PermissionGrant mPermissionGrant = new PermissionUtils.PermissionGrant() {
		@Override
		public void onPermissionGranted(int requestCode) {
			switch (requestCode) {
				case PermissionUtils.CODE_RECORD_AUDIO:
					//Toast.makeText(MainActivity.this, "Result Permission Grant CODE_RECORD_AUDIO", Toast.LENGTH_SHORT).show();
					break;
				case PermissionUtils.CODE_GET_ACCOUNTS:
					//Toast.makeText(MainActivity.this, "Result Permission Grant CODE_GET_ACCOUNTS", Toast.LENGTH_SHORT).show();
					break;
				case PermissionUtils.CODE_READ_PHONE_STATE:
					//Toast.makeText(MainActivity.this, "Result Permission Grant CODE_READ_PHONE_STATE", Toast.LENGTH_SHORT).show();
					break;
				case PermissionUtils.CODE_CALL_PHONE:
					//Toast.makeText(MainActivity.this, "Result Permission Grant CODE_CALL_PHONE", Toast.LENGTH_SHORT).show();
					break;
				case PermissionUtils.CODE_CAMERA:
					//Toast.makeText(MainActivity.this, "Result Permission Grant CODE_CAMERA", Toast.LENGTH_SHORT).show();
					break;
				case PermissionUtils.CODE_ACCESS_FINE_LOCATION:
					//Toast.makeText(MainActivity.this, "Result Permission Grant CODE_ACCESS_FINE_LOCATION", Toast.LENGTH_SHORT).show();
					break;
				case PermissionUtils.CODE_ACCESS_COARSE_LOCATION:
					//Toast.makeText(MainActivity.this, "Result Permission Grant CODE_ACCESS_COARSE_LOCATION", Toast.LENGTH_SHORT).show();
					break;
				case PermissionUtils.CODE_READ_EXTERNAL_STORAGE:
					//Toast.makeText(MainActivity.this, "Result Permission Grant CODE_READ_EXTERNAL_STORAGE", Toast.LENGTH_SHORT).show();
					break;
				case PermissionUtils.CODE_WRITE_EXTERNAL_STORAGE:
					//Toast.makeText(MainActivity.this, "Result Permission Grant CODE_WRITE_EXTERNAL_STORAGE", Toast.LENGTH_SHORT).show();
					break;
				default:
					break;
			}
		}
	};

	@Override
	public void onRequestPermissionsResult(final int requestCode, @NonNull String[] permissions,
										   @NonNull int[] grantResults) {

		PermissionUtils.requestPermissionsResult(this, requestCode, permissions, grantResults, mPermissionGrant);
	}


	public static boolean hasPermission(final int requestCode)
	{
		if (_Instance == null)
			return false;
		return PermissionUtils.hasPermission( _Instance, requestCode);
	}

	public static void requestPermission(final int requestCode)
	{
		if (_Instance == null)
			return;
		PermissionUtils.requestPermission(_Instance, requestCode, _Instance.mPermissionGrant);
	}

	private static final String[] videoPermissions =
			{
					PermissionUtils.PERMISSION_RECORD_AUDIO,
					PermissionUtils.PERMISSION_CAMERA,
					PermissionUtils.PERMISSION_WRITE_EXTERNAL_STORAGE
			};

	public static void requestVideoPermission()
	{
		if (_Instance == null)
			return;
		PermissionUtils.requestMultiPermissions(_Instance, videoPermissions, _Instance.mPermissionGrant);
	}

	public static String getMAC()
	{
		if (_Instance == null)
			return "";
		return MacUtils.getMAC(_Instance
				.getBaseContext());
	}

	public static int getTotalPss()
	{
		Debug.MemoryInfo memInfo = new Debug.MemoryInfo();
		Debug.getMemoryInfo(memInfo);
		return memInfo.getTotalPss();
	}

	public static String getMemotryStats()
	{
		Debug.MemoryInfo memInfo = new Debug.MemoryInfo();
		Debug.getMemoryInfo(memInfo);

		long available = Runtime.getRuntime().maxMemory();
		long used = Runtime.getRuntime().totalMemory();
        float percentAvailable = 100f * (1f - ((float) used / available ));

		String stats = String.format("total PSS: %d \n available MEM: %d \n used MEM: %d \n percentAvail: %f",
				memInfo.getTotalPss(), (int)available, (int)used, percentAvailable);
		return stats;
	}

	public static boolean isAppLowMemory(final float lowMemoryPercent)
	{
		long available = Runtime.getRuntime().maxMemory();
		long used = Runtime.getRuntime().totalMemory();

		float percentAvailable = 100f * (1f - ((float) used / available ));
		return percentAvailable <= lowMemoryPercent;
	}

    public void onTrimMemory(int level) {

        Log.i(TAG, String.format("MainActivity onTrimMemory level %d", level));

        // Determine which lifecycle or system event was raised.
        switch (level) {

            case ComponentCallbacks2.TRIM_MEMORY_UI_HIDDEN:

                /*
                   Release any UI objects that currently hold memory.

                   "release your UI resources" is actually about things like caches.
                   You usually don't have to worry about managing views or UI components because the OS
                   already does that, and that's why there are all those callbacks for creating, starting,
                   pausing, stopping and destroying an activity.
                   The user interface has moved to the background.
                */

                break;

            case ComponentCallbacks2.TRIM_MEMORY_RUNNING_MODERATE:
            case ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW:
            case ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL:

                /*
                   Release any memory that your app doesn't need to run.

                   The device is running low on memory while the app is running.
                   The event raised indicates the severity of the memory-related event.
                   If the event is TRIM_MEMORY_RUNNING_CRITICAL, then the system will
                   begin killing background processes.
                */

                break;

            case ComponentCallbacks2.TRIM_MEMORY_BACKGROUND:
            case ComponentCallbacks2.TRIM_MEMORY_MODERATE:
            case ComponentCallbacks2.TRIM_MEMORY_COMPLETE:

                /*
                   Release as much memory as the process can.
                   The app is on the LRU list and the system is running low on memory.
                   The event raised indicates where the app sits within the LRU list.
                   If the event is TRIM_MEMORY_COMPLETE, the process will be one of
                   the first to be terminated.
                */

                break;

            default:
                /*
                  Release any non-critical data structures.
                  The app received an unrecognized memory level value
                  from the system. Treat this as a generic low-memory message.
                */
                break;
        }
    }

	public static String getSDCardDir()
	{
		String sdcardDir = Environment.getExternalStorageDirectory().toString();
		return sdcardDir;
	}

	public static String getEmulatorName()
	{
		if (_Instance == null)
			return "";
		return EmulatorDetector.with(_Instance).getEmulatorString();
	}

	public static String getOBBDir()
	{
		String obbDir = "";
		try {
			Context context = _Instance.getApplicationContext();
			obbDir = context.getObbDir().toString();
		}
		catch (Exception e)
		{
			obbDir = "";
		}
		return obbDir;
	}

	@Override
	protected void onStop() {
		try {
			super.onStop();
		} catch (Exception e) {
			Log.w(TAG, "onStop()", e);
			super.onStop();
		}
	}

	/*
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
				//当文件不为空，把文件包装并且上传

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

				// 这里重点注意： name里面的值为服务器端需要key 只有这个key 才可以得到对应的文件
				// filename是文件的名字，包含后缀名的 比如:abc.png

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
				 // 获取响应码 200=成功 当响应成功，获取响应的流

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

	public static boolean CheckPermissionGranted(String requiredPermission)
	{
		try {
			Context context = _Instance.getApplicationContext();
			int checkVal = context.checkCallingOrSelfPermission(requiredPermission);
			return checkVal == PackageManager.PERMISSION_GRANTED;
		}
		catch (Exception e)
		{
			return false;
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
		// 去锯齿
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
	*/
}