package com.example.chat_app

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Build.VERSION

class MainActivity: FlutterActivity() {
  private val CHANNEL = "samples.flutter.dev/sdk"

  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
        call, result ->
      if (call.method == "getAndroidVersion") {
        val androidVersion = getAndroidVersion()
        result.success(androidVersion)
      } else {
        result.notImplemented()
      }
    }
  }

  private fun getAndroidVersion(): Int {
    return VERSION.SDK_INT
  }
}