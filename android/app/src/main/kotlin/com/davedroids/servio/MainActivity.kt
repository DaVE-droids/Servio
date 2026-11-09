package com.davedroids.servio

import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Hands a downloaded build to Android's package installer.
 *
 * Written here rather than taken from a plugin: the published Flutter
 * packages for this pin their own (older) Android Gradle Plugin and use DSL
 * that AGP 9 removed, and this is the one operation in Servio that installs
 * software on someone's phone — worth owning outright. It is about thirty
 * lines. See docs/APP_UPDATES.md.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "servio/installer",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "install" -> install(call.argument<String>("path"), result)
                else -> result.notImplemented()
            }
        }
    }

    private fun install(path: String?, result: MethodChannel.Result) {
        if (path == null) {
            result.error("no-path", "No file path was given.", null)
            return
        }
        try {
            val file = File(path)
            if (!file.exists()) {
                result.error("missing", "The downloaded file is gone.", null)
                return
            }
            // Since Android 7 another app cannot be handed a raw file path,
            // so the file is shared as a content URI the installer is
            // granted temporary read access to.
            val uri = FileProvider.getUriForFile(
                this,
                "$packageName.fileprovider",
                file,
            )
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            result.success(null)
        } catch (error: Exception) {
            result.error("install-failed", error.message, null)
        }
    }
}
