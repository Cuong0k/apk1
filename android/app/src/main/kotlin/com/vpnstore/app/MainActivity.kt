package com.vpnstore.app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.*
import android.os.Build
import android.os.Bundle
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val UPDATE_CHANNEL = "com.vpnstore.app/update"
    private val VPN_CHANNEL    = "com.vpnstore.app/vpn"
    private val CLASH_CHANNEL  = "com.vpnstore.app/clash"

    private var vpnChannel: MethodChannel? = null
    private var networkCallback: ConnectivityManager.NetworkCallback? = null

    // Pending VPN permission request
    private var vpnPermResult: MethodChannel.Result? = null
    private val VPN_PERM_REQ = 1001

    companion object {
        const val ACTION_TOGGLE_VPN = "com.vpnstore.app.TOGGLE_VPN"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── APK update channel ────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPDATE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getCacheDir" -> result.success(cacheDir.absolutePath)
                    "installApk" -> {
                        installApk(call.argument<String>("path")!!)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // ── VPN platform events (tile toggle, network change) ─────────────
        vpnChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VPN_CHANNEL)
        setupNetworkCallback()

        // ── Clash engine channel ──────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CLASH_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestPermission" -> {
                        val intent = VpnService.prepare(this)
                        if (intent == null) {
                            result.success(true)
                        } else {
                            vpnPermResult = result
                            startActivityForResult(intent, VPN_PERM_REQ)
                        }
                    }

                    "start" -> {
                        val config  = call.argument<String>("config")  ?: return@setMethodCallHandler result.error("NO_CONFIG", "config required", null)
                        val homeDir = call.argument<String>("homeDir") ?: filesDir.absolutePath

                        // Permission check before starting
                        if (VpnService.prepare(this) != null) {
                            result.error("NO_PERM", "VPN permission not granted", null)
                            return@setMethodCallHandler
                        }

                        val svc = Intent(this, ClashVpnService::class.java).apply {
                            action = ClashVpnService.ACTION_START
                            putExtra(ClashVpnService.EXTRA_CONFIG, config)
                            putExtra(ClashVpnService.EXTRA_HOME_DIR, homeDir)
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(svc)
                        } else {
                            startService(svc)
                        }
                        result.success(null)
                    }

                    "stop" -> {
                        val svc = Intent(this, ClashVpnService::class.java).apply {
                            action = ClashVpnService.ACTION_STOP
                        }
                        startService(svc)
                        result.success(null)
                    }

                    "isRunning" -> result.success(ClashVpnService.isRunning)

                    "getTraffic" -> result.success(mapOf(
                        "up"         to ClashVpnService.uploadSpeed,
                        "down"       to ClashVpnService.downloadSpeed,
                        "totalUp"    to ClashVpnService.totalUpload,
                        "totalDown"  to ClashVpnService.totalDownload,
                    ))

                    "getFilesDir" -> result.success(filesDir.absolutePath)

                    else -> result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == VPN_PERM_REQ) {
            vpnPermResult?.success(resultCode == Activity.RESULT_OK)
            vpnPermResult = null
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.action == ACTION_TOGGLE_VPN) {
            vpnChannel?.invokeMethod("toggleVpn", null)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        networkCallback?.let {
            (getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager)
                .unregisterNetworkCallback(it)
        }
    }

    private fun setupNetworkCallback() {
        try {
            val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val req = NetworkRequest.Builder()
                .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
                .build()
            networkCallback = object : ConnectivityManager.NetworkCallback() {
                override fun onAvailable(network: Network) {
                    runOnUiThread { vpnChannel?.invokeMethod("networkAvailable", null) }
                }
                override fun onLost(network: Network) {
                    runOnUiThread { vpnChannel?.invokeMethod("networkLost", null) }
                }
            }
            cm.registerNetworkCallback(req, networkCallback!!)
        } catch (_: Exception) {
            // Network callback not critical — VPN status polling handles state changes
        }
    }

    private fun installApk(filePath: String) {
        val file = File(filePath)
        val uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            FileProvider.getUriForFile(this, "$packageName.provider", file)
        } else {
            @Suppress("DEPRECATION")
            android.net.Uri.fromFile(file)
        }
        startActivity(Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        })
    }
}
