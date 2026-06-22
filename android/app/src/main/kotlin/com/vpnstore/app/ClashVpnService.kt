package com.vpnstore.app

import android.app.*
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.VpnService
import android.os.*
import androidx.core.app.NotificationCompat
import com.follow.clash.core.Core
import com.follow.clash.core.TunInterface
import java.io.File

class ClashVpnService : VpnService() {

    private var tunFd: ParcelFileDescriptor? = null

    private val tunBridge = object : TunInterface {
        override fun protect(fd: Int): Boolean = this@ClashVpnService.protect(fd)
        override fun resolverProcess(name: String, uid: Int, remote: String): Boolean = false
    }

    companion object {
        private const val NOTIF_CHANNEL = "clash_vpn"
        private const val NOTIF_ID = 101
        const val ACTION_START = "com.vpnstore.app.CLASH_START"
        const val ACTION_STOP  = "com.vpnstore.app.CLASH_STOP"
        const val EXTRA_CONFIG   = "config"
        const val EXTRA_HOME_DIR = "homeDir"

        @Volatile var isRunning = false
            private set
        @Volatile var uploadSpeed:   Long = 0
        @Volatile var downloadSpeed: Long = 0
        @Volatile var totalUpload:   Long = 0
        @Volatile var totalDownload: Long = 0
    }

    private var trafficHandler: Handler? = null
    private val trafficRunnable = object : Runnable {
        override fun run() {
            try {
                val t  = Core.getTraffic()
                val tt = Core.getTotalTraffic()
                if (t.size >= 2)  { uploadSpeed = t[0];   downloadSpeed = t[1] }
                if (tt.size >= 2) { totalUpload = tt[0];  totalDownload = tt[1] }
            } catch (_: Throwable) {}
            trafficHandler?.postDelayed(this, 1000)
        }
    }

    override fun onCreate() {
        super.onCreate()
        trafficHandler = Handler(Looper.getMainLooper())
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val config  = intent.getStringExtra(EXTRA_CONFIG)  ?: return START_NOT_STICKY
                val homeDir = intent.getStringExtra(EXTRA_HOME_DIR) ?: filesDir.absolutePath
                // Must call startForeground() BEFORE heavy work — Android kills the service
                // if startForeground() isn't called within 5 seconds of startForegroundService()
                try {
                    startForegroundCompat()
                } catch (e: Throwable) {
                    android.util.Log.e("ClashVPN", "startForeground failed: ${e.message}")
                    stopSelf()
                    return START_NOT_STICKY
                }
                if (!startClash(homeDir, config)) {
                    stopForegroundCompat()
                    stopSelf()
                }
            }
            ACTION_STOP -> {
                stopClash()
                stopSelf()
            }
        }
        return START_STICKY
    }

    private fun startForegroundCompat() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(
                NotificationChannel(NOTIF_CHANNEL, "VPN Store", NotificationManager.IMPORTANCE_LOW)
            )
        }
        val notification = buildNotification()
        // API 34+ requires the 3-argument form with a declared foreground service type
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(NOTIF_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIF_ID, notification)
        }
    }

    private fun stopForegroundCompat() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
    }

    private fun startClash(homeDir: String, yamlConfig: String): Boolean {
        // Tear down any previous session — but do NOT touch foreground state here,
        // since we just called startForeground() above.
        isRunning = false
        trafficHandler?.removeCallbacks(trafficRunnable)
        // catch Throwable, not Exception — UnsatisfiedLinkError (from System.loadLibrary)
        // is an Error subclass and would NOT be caught by catch(Exception)
        try { Core.stopTun() } catch (_: Throwable) {}
        tunFd?.close()
        tunFd = null
        uploadSpeed = 0; downloadSpeed = 0

        // Write YAML config to homeDir/config.yaml
        val dir = File(homeDir).also { it.mkdirs() }
        try {
            File(dir, "config.yaml").writeText(yamlConfig)
        } catch (e: Throwable) {
            android.util.Log.e("ClashVPN", "write config failed: ${e.message}")
            return false
        }

        // Create TUN interface — the whole block needs try-catch because:
        // - addRoute("::", 0) throws on devices that don't support IPv6 VPN routing
        // - setMtu() / establish() can throw on certain OEM implementations
        val tun = try {
            Builder().apply {
                setMtu(1500)  // 9000 (jumbo) is rejected by many Xiaomi/MIUI builds
                addAddress("198.18.0.1", 30)
                addDnsServer("1.1.1.1")
                addDnsServer("8.8.8.8")
                addRoute("0.0.0.0", 0)
                try { addRoute("::", 0) } catch (_: Throwable) {}  // IPv6 is optional
                setSession("VPN Store")
                try { addDisallowedApplication(packageName) } catch (_: Throwable) {}
            }.establish()
        } catch (e: Throwable) {
            android.util.Log.e("ClashVPN", "TUN establish failed: ${e.message}")
            null
        } ?: return false

        tunFd = tun

        // Initialize Clash engine — reads config.yaml from homeDir.
        // System.loadLibrary throws UnsatisfiedLinkError (an Error, not Exception)
        // if the .so can't be loaded, so we must catch Throwable here.
        try {
            val result = Core.quickSetup(homeDir)
            if (result.isNotEmpty() && result != "success") {
                android.util.Log.w("ClashVPN", "quickSetup: $result")
            }
        } catch (e: Throwable) {
            android.util.Log.e("ClashVPN", "quickSetup failed: ${e.message}")
            tun.close()
            tunFd = null
            return false
        }

        // Protect the TUN fd itself so traffic from Clash doesn't loop back through the VPN
        protect(tun.fd)

        // Hand the TUN fd to Clash
        try {
            Core.startTun(tun.fd, tunBridge)
        } catch (e: Throwable) {
            android.util.Log.e("ClashVPN", "startTun failed: ${e.message}")
            tun.close()
            tunFd = null
            try { Core.stopTun() } catch (_: Throwable) {}
            return false
        }

        isRunning = true
        trafficHandler?.post(trafficRunnable)
        return true
    }

    private fun stopClash() {
        isRunning = false
        trafficHandler?.removeCallbacks(trafficRunnable)
        try { Core.stopTun() } catch (_: Throwable) {}
        tunFd?.close()
        tunFd = null
        uploadSpeed = 0; downloadSpeed = 0
        stopForegroundCompat()
    }

    private fun buildNotification(): Notification {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        val pi = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        return NotificationCompat.Builder(this, NOTIF_CHANNEL)
            .setContentTitle("VPN Store")
            .setContentText("Đang bảo vệ kết nối")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentIntent(pi)
            .setOngoing(true)
            .build()
    }

    override fun onDestroy() {
        stopClash()
        super.onDestroy()
    }

    override fun onRevoke() {
        stopClash()
        super.onRevoke()
    }
}
