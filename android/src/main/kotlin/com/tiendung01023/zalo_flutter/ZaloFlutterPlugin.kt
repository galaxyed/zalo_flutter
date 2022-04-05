package com.tiendung01023.zalo_flutter

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.util.Base64
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import java.lang.Exception
import java.security.MessageDigest
import java.security.NoSuchAlgorithmException

import com.zing.zalo.zalosdk.oauth.*


/** ZaloFlutterPlugin */
class ZaloFlutterPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private val channelName = "zalo_flutter"

    private lateinit var context: Context
    private lateinit var activity: Activity

    private val zaloInstance = ZaloSDK.Instance

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, channelName)
        channel.setMethodCallHandler(this)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onDetachedFromActivityForConfigChanges() {}

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}

    override fun onDetachedFromActivity() {}

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        try {
            when (call.method) {
                "getHashKey" -> getHashKey(result)
                "logout" -> logout(result)
                "isAuthenticated" -> isAuthenticated(result)
                "getStatusLoginZalo" -> getStatusLoginZalo(result)
                "login" -> login(result)
                else -> {
                    result.notImplemented()
                }
            }
        } catch (e: Exception) {
            result.success(null)
        }
    }

    @Throws(Exception::class)
    private fun getHashKey(result: Result) {
        val key = AppHelper.getHashKey(context)
        Log.v(
            channelName,
            "------------------------------------------------------------------------------------------------"
        )
        Log.v(
            channelName,
            "HashKey ANDROID. Copy it to Dashboard [https://developers.zalo.me/app/{your_app_id}/login]"
        )
        Log.v(channelName, key)
        Log.v(
            channelName,
            "------------------------------------------------------------------------------------------------"
        )
        result.success(key)
    }

    @Throws(Exception::class)
    private fun login(result: Result) {
        val listener: OAuthCompleteListener = object : OAuthCompleteListener() {
            override fun onGetOAuthComplete(response: OauthResponse) {
                val error: MutableMap<String, Any?> = HashMap()
                error["errorCode"] = response.errorCode
                error["errorMessage"] = response.errorMessage
                val data: MutableMap<String, Any?> = HashMap()
                data["oauthCode"] = response.oauthCode
                data["userId"] = response.getuId().toString()
                val map: MutableMap<String, Any?> = HashMap()
                map["isSuccess"] = true
                map["error"] = error
                map["data"] = data
                result.success(map)
            }

            override fun onAuthenError(errorCode: Int, message: String) {
                val error: MutableMap<String, Any?> = HashMap()
                error["errorCode"] = errorCode
                error["errorMessage"] = message
                val map: MutableMap<String, Any?> = HashMap()
                map["isSuccess"] = false
                map["error"] = error
                map["data"] = null
                result.success(map)
            }
        }
        zaloInstance.authenticate(activity, LoginVia.APP_OR_WEB, listener)
    }

    @Throws(Exception::class)
    private fun isAuthenticated(result: Result) {
        zaloInstance.isAuthenticate { validated, _, _, _ -> result.success(validated) }
    }

    @Throws(Exception::class)
    private fun logout(result: Result) {
        zaloInstance.unauthenticate()
        result.success(null)
    }

    @Throws(Exception::class)
    private fun getStatusLoginZalo(result: Result) {
        zaloInstance.getZaloLoginStatus { status -> result.success(status) }
    }
}

private object AppHelper {
    @Suppress("DEPRECATION")
    @SuppressLint("PackageManagerGetSignatures")
    fun getHashKey(@NonNull context: Context): String {
        try {
            val packageManager = context.packageManager
            val info = packageManager.getPackageInfo(
                context.packageName,
                PackageManager.GET_SIGNATURES
            )
            for (signature in info.signatures) {
                val md = MessageDigest.getInstance("SHA")
                md.update(signature.toByteArray())
                return Base64.encodeToString(md.digest(), Base64.DEFAULT)
            }
            return ""
        } catch (e: PackageManager.NameNotFoundException) {
            e.printStackTrace()
            return ""
        } catch (e: NoSuchAlgorithmException) {
            e.printStackTrace()
            return ""
        }
    }

    @Throws(JSONException::class)
    private fun fromMap(jsonObj: JSONObject): Map<String, Any?> {
        val map: MutableMap<String, Any?> = HashMap()
        val keys = jsonObj.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            var value = jsonObj[key]
            if (value is JSONArray) {
                value = fromList(value)
            } else if (value is JSONObject) {
                value = fromMap(value)
            }
            map[key] = value
        }
        return map
    }

    @Throws(JSONException::class)
    private fun fromList(array: JSONArray): List<Any> {
        val list: MutableList<Any> = ArrayList()
        for (i in 0 until array.length()) {
            var value = array[i]
            if (value is JSONArray) {
                value = fromList(value)
            } else if (value is JSONObject) {
                value = fromMap(value)
            }
            list.add(value)
        }
        return list
    }
}