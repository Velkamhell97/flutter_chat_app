package com.example.chat_app;

import androidx.annotation.NonNull;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import android.content.Context;
import android.media.MediaMetadataRetriever;
import android.os.Environment;
import android.util.Log;
import android.view.View;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

import android.os.Build.VERSION;
import android.view.WindowInsets;
import android.view.inputmethod.InputMethodManager;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import linc.com.amplituda.Amplituda;
import linc.com.amplituda.AmplitudaProgressListener;
import linc.com.amplituda.AmplitudaResult;
import linc.com.amplituda.Compress;
import linc.com.amplituda.InputAudio;
import linc.com.amplituda.ProgressOperation;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example.chat_app/channel";


    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("getAndroidVersion")) {
                                int androidVersion = getAndroidVersion();
                                result.success(androidVersion);
                            }   else if(call.method.equals("getKeyboardHeight")) {
                                WindowInsetsCompat insets = ViewCompat.getRootWindowInsets(getWindow().getDecorView());
                                int keyboardHeight = insets.getInsets(WindowInsetsCompat.Type.ime()).bottom;
                                result.success(keyboardHeight);
                            }   else if(call.method.equals("hideKeyboard")) {
                                View view = this.getCurrentFocus();
                                if(view != null) {
                                    InputMethodManager imm = (InputMethodManager) getSystemService(Context.INPUT_METHOD_SERVICE);
                                    imm.hideSoftInputFromWindow(view.getWindowToken(), 0);
                                }
                            }   else if (call.method.equals("processAudio")) {
                                String path = call.argument("path");

                                Amplituda amplituda = new Amplituda(this);

                                amplituda.processAudio(
                                        path,
                                        Compress.withParams(Compress.AVERAGE, 1),
                                        new AmplitudaProgressListener() {
                                            @Override
                                            public void onStartProgress() {
                                                super.onStartProgress();
                                            }

                                            @Override
                                            public void onStopProgress() {
                                                super.onStopProgress();
                                            }

                                            @Override
                                            public void onProgress(ProgressOperation operation, int progress) {
                                            }
                                        }
                                ).get(
                                    (data) -> result.success(data.amplitudesAsList()),
                                    exception -> {
                                        exception.printStackTrace();
                                        result.success(null);
                                    }
                                );
                            }  else if (call.method.equals("getDuration")) {
                                String path = call.argument("path");

                                MediaMetadataRetriever retriever = new MediaMetadataRetriever();
                                retriever.setDataSource(path);

                                try {
                                    String metadata = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION);
                                    Integer duration = Integer.parseInt(metadata);
                                    result.success(duration);
                                } catch (Exception e){
                                    result.success(null);
                                }
                            } else {
                                result.notImplemented();
                            }
                        }
                );
    }

    private int getAndroidVersion() {
        return VERSION.SDK_INT;
    }
}