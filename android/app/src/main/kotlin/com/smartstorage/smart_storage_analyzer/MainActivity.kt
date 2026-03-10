package com.smartstorage.smart_storage_analyzer

import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.StatFs
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.smartstorage/storage"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    try {
                        val pm = packageManager
                        val apps = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            pm.getInstalledApplications(PackageManager.ApplicationInfoFlags.of(0))
                        } else {
                            @Suppress("DEPRECATION")
                            pm.getInstalledApplications(0)
                        }

                        // Try to get usage stats for last-used info
                        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
                        val endTime = System.currentTimeMillis()
                        val startTime = endTime - 365L * 24 * 60 * 60 * 1000 // 1 year
                        val usageStats = try {
                            usageStatsManager?.queryUsageStats(
                                UsageStatsManager.INTERVAL_YEARLY, startTime, endTime
                            )?.associateBy { it.packageName }
                        } catch (e: Exception) {
                            null
                        }

                        val appList = mutableListOf<HashMap<String, Any?>>()

                        for (appInfo in apps) {
                            // Skip our own app
                            if (appInfo.packageName == packageName) continue

                            val isSystemApp = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                            // Skip system apps that can't be uninstalled
                            if (isSystemApp && (appInfo.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) == 0) continue

                            val appName = pm.getApplicationLabel(appInfo).toString()

                            // Get app size from sourceDir
                            val appSize = try {
                                val sourceDir = File(appInfo.sourceDir)
                                var size = sourceDir.length()
                                // Also add data dir size if accessible
                                appInfo.dataDir?.let { dataDir ->
                                    val dataDirFile = File(dataDir)
                                    if (dataDirFile.exists() && dataDirFile.canRead()) {
                                        size += dataDirFile.walkTopDown()
                                            .filter { it.isFile }
                                            .sumOf { it.length() }
                                    }
                                }
                                size
                            } catch (e: Exception) {
                                0L
                            }

                            // Get last used time from usage stats
                            val lastUsed = usageStats?.get(appInfo.packageName)?.lastTimeUsed ?: 0L

                            val map = hashMapOf<String, Any?>(
                                "name" to appName,
                                "packageName" to appInfo.packageName,
                                "size" to appSize,
                                "lastUsed" to lastUsed,
                                "isSystemApp" to isSystemApp
                            )
                            appList.add(map)
                        }

                        // Sort by size descending
                        appList.sortByDescending { (it["size"] as? Long) ?: 0L }

                        result.success(appList)
                    } catch (e: Exception) {
                        result.error("APP_LIST_ERROR", "Failed to get installed apps: ${e.message}", null)
                    }
                }
                "uninstallApp" -> {
                    try {
                        val packageNameArg = call.argument<String>("packageName")
                        if (packageNameArg == null) {
                            result.error("INVALID_ARG", "Package name is required", null)
                            return@setMethodCallHandler
                        }
                        val intent = Intent(Intent.ACTION_UNINSTALL_PACKAGE).apply {
                            data = Uri.parse("package:$packageNameArg")
                            putExtra(Intent.EXTRA_RETURN_RESULT, true)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UNINSTALL_ERROR", "Failed to uninstall: ${e.message}", null)
                    }
                }
                "getStorageInfo" -> {
                    try {
                        val stat = StatFs(Environment.getExternalStorageDirectory().path)
                        val totalSpace = stat.totalBytes
                        val freeSpace = stat.availableBytes
                        val usedSpace = totalSpace - freeSpace

                        val info = hashMapOf<String, Long>(
                            "totalSpace" to totalSpace,
                            "usedSpace" to usedSpace,
                            "freeSpace" to freeSpace
                        )
                        result.success(info)
                    } catch (e: Exception) {
                        result.error("STORAGE_ERROR", "Failed to get storage info", e.message)
                    }
                }
                "getFreeDiskSpace" -> {
                    try {
                        val path = call.argument<String>("path") ?: Environment.getExternalStorageDirectory().path
                        val stat = StatFs(path)
                        result.success(stat.availableBytes)
                    } catch (e: Exception) {
                        result.error("STORAGE_ERROR", "Failed to get free disk space", e.message)
                    }
                }
                "openFile" -> {
                    try {
                        val filePath = call.argument<String>("path")
                        if (filePath == null) {
                            result.error("INVALID_ARG", "Path is required", null)
                            return@setMethodCallHandler
                        }
                        val file = File(filePath)
                        if (!file.exists()) {
                            result.error("FILE_NOT_FOUND", "File does not exist", null)
                            return@setMethodCallHandler
                        }
                        val uri = FileProvider.getUriForFile(
                            this,
                            "${applicationContext.packageName}.fileprovider",
                            file
                        )
                        val mimeType = getMimeType(filePath)
                        val intent = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(uri, mimeType)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("OPEN_ERROR", "Failed to open file: ${e.message}", null)
                    }
                }
                "deletePath" -> {
                    try {
                        val filePath = call.argument<String>("path")
                        if (filePath == null) {
                            result.error("INVALID_ARG", "Path is required", null)
                            return@setMethodCallHandler
                        }
                        val file = File(filePath)
                        val deleted = if (file.isDirectory) {
                            file.deleteRecursively()
                        } else {
                            file.delete()
                        }
                        result.success(deleted)
                    } catch (e: Exception) {
                        result.error("DELETE_ERROR", "Failed to delete: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getMimeType(path: String): String {
        val ext = path.substringAfterLast('.', "").lowercase()
        return when (ext) {
            "jpg", "jpeg" -> "image/jpeg"
            "png" -> "image/png"
            "gif" -> "image/gif"
            "webp" -> "image/webp"
            "bmp" -> "image/bmp"
            "heic", "heif" -> "image/heif"
            "svg" -> "image/svg+xml"
            "mp4" -> "video/mp4"
            "mkv" -> "video/x-matroska"
            "avi" -> "video/x-msvideo"
            "mov" -> "video/quicktime"
            "wmv" -> "video/x-ms-wmv"
            "flv" -> "video/x-flv"
            "webm" -> "video/webm"
            "3gp" -> "video/3gpp"
            "mp3" -> "audio/mpeg"
            "wav" -> "audio/wav"
            "flac" -> "audio/flac"
            "aac" -> "audio/aac"
            "ogg" -> "audio/ogg"
            "m4a" -> "audio/mp4"
            "pdf" -> "application/pdf"
            "doc" -> "application/msword"
            "docx" -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            "xls" -> "application/vnd.ms-excel"
            "xlsx" -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            "ppt" -> "application/vnd.ms-powerpoint"
            "pptx" -> "application/vnd.openxmlformats-officedocument.presentationml.presentation"
            "txt" -> "text/plain"
            "csv" -> "text/csv"
            "apk" -> "application/vnd.android.package-archive"
            "zip" -> "application/zip"
            "rar" -> "application/x-rar-compressed"
            else -> "*/*"
        }
    }
}
