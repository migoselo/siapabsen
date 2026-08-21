package com.example.upsend_karyawan

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.location.Location
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingEvent

class RadiusGeofenceReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val event = GeofencingEvent.fromIntent(intent) ?: return
        if (event.hasError() || event.geofenceTransition != Geofence.GEOFENCE_TRANSITION_EXIT) {
            return
        }

        val channelId = "attendance_radius"
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(
            NotificationChannel(
                channelId,
                "Pengingat Absensi",
                NotificationManager.IMPORTANCE_HIGH
            )
        )

        val openAppIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val openAppPendingIntent = openAppIntent?.let {
            PendingIntent.getActivity(
                context,
                1001,
                it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentTitle("Pengingat checkout")
            .setContentText("Anda berada di luar radius absensi. Jangan lupa checkout.")
            .setStyle(
                NotificationCompat.BigTextStyle().bigText(
                    "Anda berada di luar radius absensi. Jangan lupa checkout."
                )
            )
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .apply {
                if (openAppPendingIntent != null) setContentIntent(openAppPendingIntent)
            }
            .build()

        manager.notify(1001, notification)
    }
}
