package com.berna.corp_syncmdm

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.StatFs
import android.provider.Settings
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.*
import java.util.concurrent.TimeUnit

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.berna.corp_syncmdm/native_stats"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDiskSpace" -> {
                    val diskInfo = getDiskSpaceInfo()
                    result.success(diskInfo)
                }
                "hasUsageStatsPermission" -> {
                    val hasPermission = hasUsageStatsPermission()
                    result.success(hasPermission)
                }
                "requestUsageStatsPermission" -> {
                    requestUsageStatsPermission()
                    result.success(null)
                }
                "getAppUsageStats" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        val stats = getAppUsageStats()
                        result.success(stats)
                    } else {
                        result.error("UNAVAILABLE", "Usage stats not available on this device", null)
                    }
                }
                "getInstalledAppsCount" -> {
                    val appsInfo = getInstalledAppsInfo()
                    result.success(appsInfo)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getDiskSpaceInfo(): Map<String, Any> {
        val result = HashMap<String, Any>()

        try {
            val stat = StatFs(android.os.Environment.getDataDirectory().path)

            val blockSize = stat.blockSizeLong
            val totalBlocks = stat.blockCountLong
            val availableBlocks = stat.availableBlocksLong

            val totalSize = totalBlocks * blockSize
            val freeSize = availableBlocks * blockSize
            val usedSize = totalSize - freeSize

            // Converter para GB
            val totalGB = totalSize / (1024.0 * 1024.0 * 1024.0)
            val freeGB = freeSize / (1024.0 * 1024.0 * 1024.0)
            val usedGB = usedSize / (1024.0 * 1024.0 * 1024.0)
            val usedPercentage = (usedGB / totalGB) * 100

            result["total_disk_space"] = String.format("%.2fGB", totalGB)
            result["free_disk_space"] = String.format("%.2fGB", freeGB)
            result["used_disk_space"] = String.format("%.2fGB", usedGB)
            result["disk_used_percentage"] = String.format("%.1f", usedPercentage)
            result["total_disk_space_bytes"] = totalSize
            result["free_disk_space_bytes"] = freeSize

        } catch (e: Exception) {
            result["error"] = e.message ?: "Unknown error"
        }

        return result
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as android.app.AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        } else {
            appOps.checkOpNoThrow(
                android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        }
        return mode == android.app.AppOpsManager.MODE_ALLOWED
    }

    private fun requestUsageStatsPermission() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        startActivity(intent)
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun getAppUsageStats(): Map<String, Any> {
        val result = HashMap<String, Any>()

        if (!hasUsageStatsPermission()) {
            result["error"] = "Permission not granted"
            return result
        }

        try {
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

            val endTime = System.currentTimeMillis()
            val startTime = endTime - 24 * 60 * 60 * 1000

            val usageEvents = usageStatsManager.queryEvents(startTime, endTime)

            var totalScreenTimeMillis = 0L
            val appScreenTimes = HashMap<String, Long>()
            val appNames = HashMap<String, String>()

            var lastEventTime = 0L
            var lastEventType = 0
            var lastEventPackage = ""

            while (usageEvents.hasNextEvent()) {
                val event = UsageEvents.Event()
                usageEvents.getNextEvent(event)

                when (event.eventType) {
                    UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                        lastEventTime = event.timeStamp
                        lastEventType = event.eventType
                        lastEventPackage = event.packageName
                    }
                    UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                        if (lastEventPackage == event.packageName &&
                            lastEventType == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                            val usageTime = event.timeStamp - lastEventTime
                            totalScreenTimeMillis += usageTime

                            // Tempo por app
                            val currentTime = appScreenTimes[event.packageName] ?: 0L
                            appScreenTimes[event.packageName] = currentTime + usageTime

                            try {
                                val packageManager = packageManager
                                val appInfo = packageManager.getApplicationInfo(event.packageName, 0)
                                val appName = packageManager.getApplicationLabel(appInfo).toString()
                                appNames[event.packageName] = appName
                            } catch (e: Exception) {
                                appNames[event.packageName] = event.packageName
                            }
                        }
                    }
                }
            }

            val totalScreenTimeMinutes = TimeUnit.MILLISECONDS.toMinutes(totalScreenTimeMillis)

            val sortedApps = appScreenTimes.entries.sortedByDescending { it.value }.take(5)
            val topApps = HashMap<String, Long>()

            for (entry in sortedApps) {
                val appName = appNames[entry.key] ?: entry.key
                val minutes = TimeUnit.MILLISECONDS.toMinutes(entry.value)
                if (minutes > 0) {
                    topApps[appName] = minutes
                }
            }

            result["total_screen_time_minutes"] = totalScreenTimeMinutes
            result["screen_time_hours"] = String.format("%.1f", totalScreenTimeMinutes / 60.0)
            result["top_apps"] = topApps

        } catch (e: Exception) {
            result["error"] = e.message ?: "Unknown error"
        }

        return result
    }

    private fun getInstalledAppsInfo(): Map<String, Any> {
        val result = HashMap<String, Any>()

        try {
            val packageManager = packageManager
            val packages = packageManager.getInstalledApplications(0)

            var systemAppsCount = 0
            var userAppsCount = 0

            for (appInfo in packages) {
                if ((appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0) {
                    systemAppsCount++
                } else {
                    userAppsCount++
                }
            }

            result["total_apps_count"] = packages.size
            result["system_apps_count"] = systemAppsCount
            result["user_apps_count"] = userAppsCount

        } catch (e: Exception) {
            result["error"] = e.message ?: "Unknown error"
        }

        return result
    }
}