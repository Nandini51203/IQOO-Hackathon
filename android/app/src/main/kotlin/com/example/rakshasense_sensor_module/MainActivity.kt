package com.example.rakshasense_sensor_module

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.telephony.SmsManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channelName = "rakshasense/native"
    private val smsPermissionRequestCode = 1001

    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "requestSmsPermission" -> {
                    requestSmsPermission(result)
                }

                "sendSms" -> {
                    val phoneNumber = call.argument<String>("to")
                    val message = call.argument<String>("message")

                    if (phoneNumber.isNullOrBlank() || message.isNullOrBlank()) {
                        result.error(
                            "INVALID_ARGUMENTS",
                            "Phone number and message are required.",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    sendSms(
                        phoneNumber = phoneNumber,
                        message = message,
                        result = result
                    )
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun requestSmsPermission(
        result: MethodChannel.Result
    ) {
        if (
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.SEND_SMS
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }

        pendingPermissionResult = result

        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.SEND_SMS),
            smsPermissionRequestCode
        )
    }

    private fun sendSms(
        phoneNumber: String,
        message: String,
        result: MethodChannel.Result
    ) {
        val permissionGranted =
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.SEND_SMS
            ) == PackageManager.PERMISSION_GRANTED

        if (!permissionGranted) {
            result.error(
                "SMS_PERMISSION_REQUIRED",
                "SEND_SMS permission has not been granted.",
                null
            )
            return
        }

        try {
            val smsManager = SmsManager.getDefault()

            val parts = smsManager.divideMessage(message)

            smsManager.sendMultipartTextMessage(
                phoneNumber,
                null,
                parts,
                null,
                null
            )

            result.success(true)

        } catch (e: Exception) {

            result.error(
                "SMS_SEND_FAILED",
                e.message ?: "Unable to send SMS.",
                null
            )
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(
            requestCode,
            permissions,
            grantResults
        )

        if (requestCode == smsPermissionRequestCode) {

            val granted =
                grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED

            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
        }
    }
}
