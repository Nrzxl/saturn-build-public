package com.example.saturn_app

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** SATURN's OS notification bridge for activity synchronized while open.
 * Background push requires a separate, configured Firebase FCM service.
 * No notification is posted before the user opts in explicitly.
 */
class MainActivity : FlutterActivity() {
    private val channelId = "saturn_orbit_activity"
    private val permissionRequest = 43061
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "saturn/native_notices").setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> requestNativePermission(result)
                "notify" -> {
                    val title = call.argument<String>("title") ?: "Nossa Órbita"
                    val body = call.argument<String>("body") ?: ""
                    val id = call.argument<Int>("id") ?: 1
                    try {
                        postNativeNotification(id, title, body)
                        result.success(null)
                    } catch (error: SecurityException) {
                        result.error("NOT_ALLOWED", "Notificações bloqueadas no Android.", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun notificationManager(): NotificationManager =
        getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    private fun requestNativePermission(result: MethodChannel.Result) {
        val notifications = notificationManager()
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(notifications.areNotificationsEnabled())
            return
        }
        if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                PackageManager.PERMISSION_GRANTED) {
            result.success(notifications.areNotificationsEnabled())
            return
        }
        if (pendingPermissionResult != null) {
            result.error("BUSY", "Outra permissão está em andamento.", null)
            return
        }
        pendingPermissionResult = result
        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            permissionRequest)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>, grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == permissionRequest) {
            val allowed = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED &&
                notificationManager().areNotificationsEnabled()
            pendingPermissionResult?.success(allowed)
            pendingPermissionResult = null
        }
    }

    private fun postNativeNotification(id: Int, headline: String, detail: String) {
        val manager = notificationManager()
        if (!manager.areNotificationsEnabled()) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
                PackageManager.PERMISSION_GRANTED) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(NotificationChannel(
                channelId, "Nossa Órbita", NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Novas resenhas, séries, livros e sugestões do casal"
                enableVibration(true)
            })
        }
        val openIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pending = openIntent?.let {
            PendingIntent.getActivity(this, 0, it, PendingIntent.FLAG_UPDATE_CURRENT or
                (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                    PendingIntent.FLAG_IMMUTABLE else 0))
        }
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            Notification.Builder(this, channelId) else Notification.Builder(this)
        val notification = builder
            .setSmallIcon(R.drawable.ic_stat_saturn)
            .setContentTitle(headline.take(90))
            .setContentText(detail.take(200))
            .setAutoCancel(true)
            .setColor(android.graphics.Color.rgb(198, 164, 119))
            .setCategory(Notification.CATEGORY_SOCIAL)
            .apply { if (pending != null) setContentIntent(pending) }
            .build()
        manager.notify(id, notification)
    }
}
