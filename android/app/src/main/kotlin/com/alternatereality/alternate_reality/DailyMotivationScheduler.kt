package com.alternatereality.alternate_reality

import android.Manifest
import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import org.json.JSONArray
import java.time.LocalDate
import java.util.Calendar

/** One alarm, one visible notification ID. Never modifies current reality (4107). */
object DailyMotivationScheduler {
    const val NOTIFICATION_ID = 4108
    private const val CHANNEL = "daily_motivation"
    private fun prefs(context: Context) = context.getSharedPreferences("daily_motivation", Context.MODE_PRIVATE)
    private fun alarmIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context, NOTIFICATION_ID, Intent(context, DailyMotivationReceiver::class.java),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )

    fun configure(context: Context, enabled: Boolean, hour: Int, minute: Int, messages: List<String>, showToday: Boolean) {
        require(hour in 0..23 && minute in 0..59 && messages.isNotEmpty())
        val p = prefs(context)
        check(p.edit().putBoolean("enabled", enabled).putInt("hour", hour).putInt("minute", minute)
            .putString("messages", JSONArray(messages).toString()).commit())
        if (!enabled) { cancel(context); return }
        try {
            scheduleNext(context)
            if (showToday || p.getString("shownDate", "") != LocalDate.now().toString()) show(context, showToday)
        } catch (e: Exception) {
            p.edit().putBoolean("enabled", false).commit()
            cancel(context)
            throw e
        }
    }

    fun scheduleNext(context: Context) {
        val p = prefs(context)
        if (!p.getBoolean("enabled", false)) return
        val now = System.currentTimeMillis()
        val next = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, p.getInt("hour", 8)); set(Calendar.MINUTE, p.getInt("minute", 0))
            set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
            if (timeInMillis <= now) add(Calendar.DAY_OF_MONTH, 1)
        }
        val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next.timeInMillis, alarmIntent(context))
    }

    fun show(context: Context, alert: Boolean) {
        val p = prefs(context)
        if (!p.getBoolean("enabled", false)) return
        if (Build.VERSION.SDK_INT >= 33 && context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) return
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= 24 && !manager.areNotificationsEnabled()) return
        val messages = JSONArray(p.getString("messages", "[]"))
        if (messages.length() == 0) return
        val today = LocalDate.now()
        val index = Math.floorMod(today.toEpochDay(), messages.length().toLong()).toInt()
        val text = messages.getString(index)
        if (Build.VERSION.SDK_INT >= 26) manager.createNotificationChannel(NotificationChannel(CHANNEL, "Daily motivation", NotificationManager.IMPORTANCE_DEFAULT).apply {
            description = "A different motivational message each day"
        })
        val openApp = PendingIntent.getActivity(context, NOTIFICATION_ID,
            Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, CHANNEL) else Notification.Builder(context)
        val notification = builder.setSmallIcon(R.drawable.ic_motivation)
            .setContentTitle("DAILY MOTIVATION").setContentText(text)
            .setStyle(Notification.BigTextStyle().bigText(text)).setContentIntent(openApp)
            .setOngoing(true).setAutoCancel(false).setOnlyAlertOnce(!alert)
            .setCategory(Notification.CATEGORY_REMINDER).build()
        manager.notify(NOTIFICATION_ID, notification)
        p.edit().putString("shownDate", today.toString()).apply()
    }

    private fun cancel(context: Context) {
        (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(alarmIntent(context))
        (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).cancel(NOTIFICATION_ID)
    }
}

class DailyMotivationReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        try { DailyMotivationScheduler.show(context, true) }
        finally { DailyMotivationScheduler.scheduleNext(context) }
    }
}

class DailyMotivationRescheduleReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action !in listOf(Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED, Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED)) return
        DailyMotivationScheduler.scheduleNext(context)
        DailyMotivationScheduler.show(context, false)
    }
}
