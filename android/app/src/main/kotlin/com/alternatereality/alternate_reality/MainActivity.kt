package com.alternatereality.alternate_reality

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "alternate_reality/daily_motivation").setMethodCallHandler { call, result ->
            if (call.method != "configure") { result.notImplemented(); return@setMethodCallHandler }
            try {
                DailyMotivationScheduler.configure(this,
                    call.argument<Boolean>("enabled") ?: false,
                    call.argument<Int>("hour") ?: 8, call.argument<Int>("minute") ?: 0,
                    call.argument<List<String>>("messages") ?: emptyList(),
                    call.argument<Boolean>("showToday") ?: false)
                result.success(null)
            } catch (e: Exception) { result.error("schedule_failed", "Daily notification could not be scheduled.", null) }
        }
    }
}
