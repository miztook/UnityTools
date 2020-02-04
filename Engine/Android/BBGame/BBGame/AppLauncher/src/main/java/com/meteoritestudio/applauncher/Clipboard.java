package com.meteoritestudio.applauncher;

import android.app.Activity;
import android.content.Context;
import android.content.ClipData;
import android.content.ClipboardManager;

public class Clipboard {

    public static void CopyTextToClipboard(final Activity targetActivity, final String text) {
        targetActivity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                ClipboardManager clipboardManager = (ClipboardManager) targetActivity.getSystemService(Context.CLIPBOARD_SERVICE);
                ClipData clipData = ClipData.newPlainText("text", text);
                clipboardManager.setPrimaryClip(clipData);
            }
        });

    }
}
