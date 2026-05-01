package com.example.frontend

import android.content.Intent
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            AUDIO_BACKGROUND_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startAudioBackgroundService" -> {
                    startAudioForegroundService(
                        notificationText = call.argument<String>("notificationText"),
                    )
                    result.success(null)
                }
                "stopAudioBackgroundService" -> {
                    stopAudioForegroundService()
                    result.success(null)
                }
                "updateAudioBackgroundNotification" -> {
                    updateAudioForegroundNotification(
                        notificationText = call.argument<String>("notificationText"),
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startAudioForegroundService(notificationText: String?) {
        val intent = Intent(this, NavigationAudioForegroundService::class.java).apply {
            action = NavigationAudioForegroundService.ACTION_START
            putExtra(NavigationAudioForegroundService.EXTRA_NOTIFICATION_TEXT, notificationText)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            ContextCompat.startForegroundService(this, intent)
        } else {
            startService(intent)
        }
    }

    private fun stopAudioForegroundService() {
        val intent = Intent(this, NavigationAudioForegroundService::class.java).apply {
            action = NavigationAudioForegroundService.ACTION_STOP
        }
        startService(intent)
    }

    private fun updateAudioForegroundNotification(notificationText: String?) {
        val intent = Intent(this, NavigationAudioForegroundService::class.java).apply {
            action = NavigationAudioForegroundService.ACTION_UPDATE
            putExtra(NavigationAudioForegroundService.EXTRA_NOTIFICATION_TEXT, notificationText)
        }
        startService(intent)
    }

    companion object {
        private const val AUDIO_BACKGROUND_CHANNEL =
            "com.a4mpets/audio_background_service"
    }
}
