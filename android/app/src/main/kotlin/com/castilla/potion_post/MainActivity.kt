package com.castilla.potion_post

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin
import io.flutter.plugins.sharedpreferences.SharedPreferencesPigeonOptions
import kotlin.coroutines.Continuation
import kotlin.coroutines.EmptyCoroutineContext
import kotlin.coroutines.startCoroutine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "potion_post/progress")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "supportDirectory" -> result.success(File(filesDir, "potion-post").absolutePath)
                    "legacyProgress" -> {
                        val plugin = flutterEngine.plugins.get(SharedPreferencesPlugin::class.java) as? SharedPreferencesPlugin
                        if (plugin == null) {
                            val old = legacyXml()
                            if (old != null) result.success(old)
                            else result.error("save-read", "Saved progress reader is unavailable.", null)
                        } else {
                            // Read existing DataStore directly on Android, independently of
                            // the Dart/JNI preferences transport used by older game builds.
                            suspend {
                                plugin.getString("potion_post_progress_v1", SharedPreferencesPigeonOptions(null, true))
                            }.startCoroutine(object : Continuation<String?> {
                                override val context = EmptyCoroutineContext
                                override fun resumeWith(outcome: Result<String?>) {
                                    runOnUiThread {
                                        outcome.fold(
                                            onSuccess = { result.success(it ?: legacyXml()) },
                                            onFailure = {
                                                val old = legacyXml()
                                                if (old != null) result.success(old)
                                                else result.error("save-read", "Saved progress could not be opened.", null)
                                            }
                                        )
                                    }
                                }
                            })
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun legacyXml(): String? = try {
        getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
            .getString("flutter.potion_post_progress_v1", null)
    } catch (_: Exception) { null }
}
