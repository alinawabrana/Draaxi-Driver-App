package com.example.draaxi_driver

import android.content.Intent
import android.net.Uri
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.draaxi_driver/open_url"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val mapsKey = try {
            getString(R.string.google_maps_key)
        } catch (e: Exception) {
            ""
        }
        if (mapsKey.isBlank()) {
            Log.e("MapsKey", "google_maps_key is empty")
        } else {
            Log.i("MapsKey", "google_maps_key is set (length=${mapsKey.length})")
        }
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openUrl") {
                val url = call.arguments as String
                try {
                    // Open URL in external browser (Chrome)
                    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("UNAVAILABLE", "Could not open URL: ${e.message}", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
