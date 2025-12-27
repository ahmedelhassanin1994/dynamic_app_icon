package com.example.dynamic_app_icon

import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** DynamicAppIconPlugin */
class DynamicAppIconPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var activity: Activity? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "dynamic_app_icon")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "changeIcon" -> {
                val iconName = call.argument<String>("iconName")
                val packageName = call.argument<String>("packageName") ?: context?.packageName
                val aliases = call.argument<List<String>>("aliases")

                if (iconName != null && packageName != null) {
                    try {
                        changeAppIcon(packageName, iconName, aliases)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ICON_CHANGE_ERROR", e.message, null)
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "Icon name is required", null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun changeAppIcon(packageName: String, iconName: String, aliases: List<String>?) {
        val packageManager = context?.packageManager ?: return

        // If aliases are provided from Dart, use them. Otherwise, we can't disable others safely
        // without knowing them, but we can at least enable the one requested.
        val componentsToDisable = aliases ?: listOf()

        // Disable all provided aliases except the one we're enabling
        for (alias in componentsToDisable) {
            if (alias != iconName) {
                packageManager.setComponentEnabledSetting(
                    ComponentName(packageName, alias),
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                    PackageManager.DONT_KILL_APP
                )
            }
        }

        // Enable the selected alias
        packageManager.setComponentEnabledSetting(
            ComponentName(packageName, iconName),
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP
        )

        // Optional: Graceful restart after a short delay
        Handler(Looper.getMainLooper()).postDelayed({
            restartApp(packageName)
        }, 500)
    }

    private fun restartApp(packageName: String) {
        val intent = context?.packageManager?.getLaunchIntentForPackage(packageName)
        intent?.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        intent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context?.startActivity(intent)
        activity?.finish()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
    }

    // ActivityAware methods
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
