package com.example.frontend

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class NavigationAudioForegroundService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_START -> {
                val customText = intent.getStringExtra(EXTRA_NOTIFICATION_TEXT)
                val notification = buildNotification(customText)
                startForeground(NOTIFICATION_ID, notification)
                return START_STICKY
            }
            ACTION_UPDATE -> {
                val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                manager.notify(
                    NOTIFICATION_ID,
                    buildNotification(intent.getStringExtra(EXTRA_NOTIFICATION_TEXT)),
                )
                return START_STICKY
            }
            else -> {
                val notification = buildNotification(null)
                startForeground(NOTIFICATION_ID, notification)
                return START_STICKY
            }
        }
    }

    private fun buildNotification(customText: String?): Notification {
        ensureNotificationChannel()
        val text = customText?.trim()?.takeIf { it.isNotEmpty() }
            ?: getString(R.string.nav_audio_notification_text)
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_nav_audio)
            .setContentTitle(getString(R.string.nav_audio_notification_title))
            .setContentText(text)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun ensureNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val existing = manager.getNotificationChannel(CHANNEL_ID)
        if (existing != null) {
            return
        }
        val channel = NotificationChannel(
            CHANNEL_ID,
            getString(R.string.nav_audio_channel_name),
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = getString(R.string.nav_audio_channel_description)
            setSound(null, null)
            enableVibration(false)
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }

    companion object {
        const val ACTION_START = "com.example.frontend.action.START_AUDIO_BACKGROUND"
        const val ACTION_STOP = "com.example.frontend.action.STOP_AUDIO_BACKGROUND"
        const val ACTION_UPDATE = "com.example.frontend.action.UPDATE_AUDIO_NOTIFICATION"
        const val EXTRA_NOTIFICATION_TEXT = "notification_text"
        const val CHANNEL_ID = "a4mpets_audio_background"
        const val NOTIFICATION_ID = 7441
    }
}
