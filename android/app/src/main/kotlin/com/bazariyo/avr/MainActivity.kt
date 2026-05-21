package com.bazariyo.avr

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.IntegrityTokenRequest

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.bazariyo.freshveggie/integrity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getIntegrityToken") {
                val nonce = call.argument<String>("nonce")
                val cloudProjectNumber = call.argument<String>("cloudProjectNumber")?.toLongOrNull()

                if (nonce == null || cloudProjectNumber == null) {
                    result.error("INVALID_ARGUMENTS", "Nonce and Cloud Project Number are required", null)
                    return@setMethodCallHandler
                }

                val integrityManager = IntegrityManagerFactory.create(applicationContext)
                val integrityTokenRequest = IntegrityTokenRequest.builder()
                    .setNonce(nonce)
                    .setCloudProjectNumber(cloudProjectNumber)
                    .build()

                integrityManager.requestIntegrityToken(integrityTokenRequest)
                    .addOnSuccessListener { response ->
                        result.success(response.token())
                    }
                    .addOnFailureListener { e ->
                        result.error("INTEGRITY_ERROR", e.message, null)
                    }
            } else {
                result.notImplemented()
            }
        }
    }
}
