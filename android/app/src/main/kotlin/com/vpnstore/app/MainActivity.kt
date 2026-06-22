package com.vpnstore.app

import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.Uri
import android.os.Build
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val UPDATE_CHANNEL = "com.vpnstore.app/update"
    private val VPN_CHANNEL = "com.vpnstore.app/vpn"
    private var vpnChannel: MethodChannel? = null
    private var networkCallback: ConnectivityManager.NetworkCallback? = null

    companion object {
        const val ACTION_TOGGLE_VPN = "com.vpnstore.app.TOGGLE_VPN"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // APK update channel (Flutter → Android)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPDATE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getCacheDir" -> result.success(cacheDir.absolutePath)
                    "installApk" -> {
                        val path = call.argument<String>("path")!!
                        installApk(path)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // VPN control channel — Android → Flutter (network events, tile toggle)
        vpnChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VPN_CHANNEL)
        setupNetworkCallback()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Nhận lệnh toggle từ Quick Settings tile
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

    // Theo dõi thay đổi mạng (4G↔WiFi) → báo Flutter để reconnect nếu cần
    private fun setupNetworkCallback() {
        val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val request = NetworkRequest.Builder()
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
        cm.registerNetworkCallback(request, networkCallback!!)
    }

    private fun installApk(filePath: String) {
        val file = File(filePath)
        val uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            FileProvider.getUriForFile(this, "$packageName.provider", file)
        } else {
            @Suppress("DEPRECATION")
            Uri.fromFile(file)
        }
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }
}
