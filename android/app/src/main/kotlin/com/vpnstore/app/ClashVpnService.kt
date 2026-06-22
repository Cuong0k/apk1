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
import java.net.HttpURLConnection
import java.net.URL

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

        // In-process fallback (used only when not running as a separate process)
        @Volatile var isRunning = false
            private set

        // Prevent concurrent startClash calls (e.g. if connect() fires rapidly)
        @Volatile private var isStarting = false
    }

    private var trafficHandler: Handler? = null
    private val trafficRunnable = object : Runnable {
        override fun run() {
            try {
                val t  = Core.getTraffic()
                val tt = Core.getTotalTraffic()
                val up   = if (t.size  >= 2) t[0]  else 0L
                val down = if (t.size  >= 2) t[1]  else 0L
                val tUp  = if (tt.size >= 2) tt[0] else 0L
                val tDn  = if (tt.size >= 2) tt[1] else 0L
                // Write state to file so MainActivity (possibly in another process) can read it
                writeStateFile(running = true, up = up, down = down, totalUp = tUp, totalDown = tDn)
            } catch (_: Throwable) {}
            trafficHandler?.postDelayed(this, 1000)
        }
    }

    override fun onCreate() {
        super.onCreate()
        trafficHandler = Handler(Looper.getMainLooper())
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Android may restart a foreground service after a crash with a null intent.
        // In that case, do nothing — let the Flutter app detect the disconnected state
        // and reconnect explicitly rather than auto-restarting potentially broken state.
        if (intent == null) {
            writeStateFile(running = false)
            stopSelf()
            return START_NOT_STICKY
        }
        when (intent.action) {
            ACTION_START -> {
                val config  = intent.getStringExtra(EXTRA_CONFIG)  ?: return START_NOT_STICKY
                val homeDir = intent.getStringExtra(EXTRA_HOME_DIR) ?: filesDir.absolutePath

                // Prevent overlapping start calls (e.g. rapid connect() invocations)
                if (isStarting) {
                    android.util.Log.w("ClashVPN", "Already starting, ignoring duplicate start")
                    return START_NOT_STICKY
                }
                isStarting = true

                try {
                    startForegroundCompat()
                } catch (e: Throwable) {
                    android.util.Log.e("ClashVPN", "startForeground failed: ${e.message}")
                    isStarting = false
                    stopSelf()
                    return START_NOT_STICKY
                }

                Thread {
                    try {
                        if (!startClash(homeDir, config)) {
                            Handler(Looper.getMainLooper()).post {
                                stopForegroundCompat()
                                stopSelf()
                            }
                        }
                    } finally {
                        isStarting = false
                    }
                }.start()
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
        // Clear log at start of each attempt so log always reflects latest attempt
        try { logFile().delete() } catch (_: Throwable) {}
        writeLog("startClash: begin")

        isRunning = false
        trafficHandler?.removeCallbacks(trafficRunnable)

        writeLog("stopTun: about to call (loads native libs)")
        try { Core.stopTun() } catch (_: Throwable) {}
        writeLog("stopTun: done (libs loaded OK)")

        tunFd?.close()
        tunFd = null

        val dir = File(homeDir).also { it.mkdirs() }
        try {
            File(dir, "config.yaml").writeText(yamlConfig)
        } catch (e: Throwable) {
            writeLog("write config failed: ${e.message}")
            return false
        }

        writeLog("TUN: about to establish")
        val tun = try {
            Builder().apply {
                setMtu(1500)
                addAddress("198.18.0.1", 30)
                addDnsServer("1.1.1.1")
                addDnsServer("8.8.8.8")
                addRoute("0.0.0.0", 0)
                try { addRoute("::", 0) } catch (_: Throwable) {}
                setSession("VPN Store")
                try { addDisallowedApplication(packageName) } catch (_: Throwable) {}
            }.establish()
        } catch (e: Throwable) {
            writeLog("TUN: establish failed: ${e.message}")
            null
        } ?: run { writeLog("TUN: establish returned null"); return false }

        writeLog("TUN: established fd=${tun.fd}")
        tunFd = tun

        writeLog("quickSetup: calling homeDir=$homeDir")
        try {
            val result = Core.quickSetup(homeDir)
            if (result.isNotEmpty() && result != "success") {
                writeLog("quickSetup returned error: $result")
                tun.close()
                tunFd = null
                return false
            }
            writeLog("quickSetup OK result='$result'")
        } catch (e: Throwable) {
            writeLog("quickSetup threw: ${e.javaClass.simpleName}: ${e.message}")
            tun.close()
            tunFd = null
            return false
        }

        // Wait for the Clash external controller to be ready — this ensures quickSetup
        // has fully initialized all internal state before we hand over the TUN fd.
        // Without this wait, startTUN can race with goroutines started by quickSetup
        // and cause nil-pointer panics inside the Go runtime.
        val ready = waitForClashReady(maxMs = 5000)
        writeLog("waitForClashReady=$ready")

        protect(tun.fd)

        writeLog("calling startTun fd=${tun.fd}")
        try {
            Core.startTun(tun.fd, tunBridge)
            writeLog("startTun OK")
        } catch (e: Throwable) {
            writeLog("startTun threw: ${e.javaClass.simpleName}: ${e.message}")
            tun.close()
            tunFd = null
            try { Core.stopTun() } catch (_: Throwable) {}
            return false
        }

        isRunning = true
        writeStateFile(running = true)
        trafficHandler?.post(trafficRunnable)
        return true
    }

    /** Poll 127.0.0.1:9091/version until Clash's REST API responds (= fully started). */
    private fun waitForClashReady(maxMs: Long): Boolean {
        val deadline = System.currentTimeMillis() + maxMs
        while (System.currentTimeMillis() < deadline) {
            try {
                val conn = URL("http://127.0.0.1:9091/version").openConnection() as HttpURLConnection
                conn.connectTimeout = 400
                conn.readTimeout    = 400
                val code = conn.responseCode
                conn.disconnect()
                if (code in 200..299) return true  // Clash is ready
            } catch (_: Throwable) {}
            try { Thread.sleep(200) } catch (_: InterruptedException) { return false }
        }
        return false
    }

    // ── Diagnostic log file — survives process death, readable by MainActivity ──

    private fun logFile() = File(filesDir, "vpn_log.txt")

    internal fun writeLog(msg: String) {
        android.util.Log.d("ClashVPN", msg)
        try {
            val line = "${System.currentTimeMillis()} $msg\n"
            val f = logFile()
            // Keep last 4 KB to avoid unbounded growth
            val existing = if (f.exists()) f.readText() else ""
            val trimmed = if (existing.length > 3800) existing.takeLast(3800) else existing
            f.writeText(trimmed + line)
        } catch (_: Throwable) {}
    }

    private fun stopClash() {
        isRunning = false
        trafficHandler?.removeCallbacks(trafficRunnable)
        try { Core.stopTun() } catch (_: Throwable) {}
        tunFd?.close()
        tunFd = null
        writeStateFile(running = false)
        stopForegroundCompat()
    }

    // ── File-based IPC so MainActivity can read state even across process boundary ──

    private fun stateFile() = File(filesDir, "vpn_state.json")

    private fun writeStateFile(
        running: Boolean,
        up: Long = 0, down: Long = 0,
        totalUp: Long = 0, totalDown: Long = 0,
    ) {
        try {
            val ts = System.currentTimeMillis()
            stateFile().writeText(
                """{"running":$running,"up":$up,"down":$down,"totalUp":$totalUp,"totalDown":$totalDown,"ts":$ts}"""
            )
        } catch (_: Throwable) {}
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
