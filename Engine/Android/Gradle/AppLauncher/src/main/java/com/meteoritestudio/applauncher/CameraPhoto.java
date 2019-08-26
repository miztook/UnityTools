package com.meteoritestudio.applauncher;

import android.app.Activity;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;
import android.util.Log;
import android.widget.Toast;

import com.unity3d.player.UnityPlayer;

import java.io.File;
import java.io.FileNotFoundException;

public class CameraPhoto {

    private static final int RC_CAMERA = 10;
    private static final int RC_PHOTO = 11;
    private static final int RC_PHOTO_CAMERA_RESULT = 12;
    private static final String TAG = "com.meteoritestudio.prom1.MainActivity";

    public static String srcPath;
    public static String cameraPath;
    public static Uri photoUri;
    public static String SAVED_IMAGE_DIR_PATH = Environment
            .getExternalStorageDirectory().getPath() + "/";

    protected static void WriteLog(String strLog) {
        Log.i(TAG, strLog);
        JavaLog.Instance().WriteLog(strLog);
    }

    public static void OnActivityResult(Activity activity, int requestCode,  int resultCode, Intent data)
    {
        if (resultCode != Activity.RESULT_OK)
            return;

        if (requestCode == RC_CAMERA) // Camera
        {
            // WriteLog("data1-->Camera");

            srcPath = cameraPath;
            // WriteLog(String.format("data1 save--> %s", srcPath));

            // UnityPlayer.UnitySendMessage("EntryPoint",
            // "OnPhotoCameraFileResult", srcPath);

            File picture = new File(SAVED_IMAGE_DIR_PATH + "capture.jpg");

            cropImageUri(activity, Uri.fromFile(picture), 128, 128, RC_PHOTO_CAMERA_RESULT);
        }
        else if (requestCode == RC_PHOTO && data != null)
        {
            WriteLog("data2-->Photo");

            try {
                Uri uri = data.getData();
                if (uri == null)
                    uri = photoUri;

                Bitmap bitmap = decodeUriAsBitmap(activity, uri);

                if (bitmap != null) {

                    final String absPath = getAbsolutePath(activity, uri);
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
                        cropImageUri(activity, uri, 128, 128, RC_PHOTO_CAMERA_RESULT);
                    }
                }
            } catch (Exception e) {
                WriteLog(e.getMessage());
            }

            WriteLog(String.format("data2 save--> %s", srcPath));
        }
        else if (requestCode == RC_PHOTO_CAMERA_RESULT && data != null)
        {
            if (srcPath != "") {
                File outFile = new File(srcPath);
                if (outFile.exists())
                    UnityPlayer.UnitySendMessage("EntryPoint",
                            "OnPhotoCameraFileResult", srcPath);

                srcPath = "";
            }
        }
    }

    public static boolean TakeCamera(Activity activity)
    {
        if (activity == null)
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

            activity.startActivityForResult(intent, RC_CAMERA);

            return true;
        } else {
            Toast.makeText(activity,
                    "Make sure SDCard is avaiable", Toast.LENGTH_LONG).show();

            return true;
        }
    }

    public static boolean TakePhoto(Activity activity) {
        if (activity == null)
            return false;

        srcPath = "";

        String filename = "photo.jpg";
        ContentValues values = new ContentValues();
        values.put(MediaStore.Images.Media.TITLE, filename);
        photoUri = activity.getContentResolver().insert(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values);

        // 参考: http://www.cnblogs.com/loonggg/p/4981782.html

        Intent intent;
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.KITKAT) {

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

        activity.startActivityForResult(intent, RC_PHOTO);

        return true;
    }

    public static boolean SavePhoto(Activity activity, String path)
    {
        if (activity == null)
            return false;

        try {
            Context context = activity.getApplicationContext();
            String photo_uri = MediaStore.Images.Media.insertImage(
                    context.getContentResolver(), path, "TeraPhoto", "");
            context.sendBroadcast(new Intent(
                    // Intent.ACTION_MEDIA_MOUNTED,
                    Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, Uri.parse("file://"
                    + photo_uri)));
        } catch (FileNotFoundException e) {
            return false;
        } catch (Exception e) {
            return false;
        }

        return true;
    }

    private static Bitmap decodeUriAsBitmap(Activity activity, Uri uri) {
        Bitmap bitmap = null;
        try {
            bitmap = BitmapFactory.decodeStream(activity.getContentResolver()
                    .openInputStream(uri));
        } catch (FileNotFoundException e) {
            e.printStackTrace();
            return null;
        }
        return bitmap;
    }

    private static void cropImageUri(Activity activity, Uri uri, int outputX, int outputY, int requestCode) {

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

        activity.startActivityForResult(intent, requestCode);

    }

    public static String getAbsolutePath(final Context context, final Uri uri) {
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
}