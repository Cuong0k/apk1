package com.follow.clash.core

/**
 * JNI bridge to libcore.so → libclash.so (Clash Meta engine).
 * Package + class name MUST match the exported JNI symbols in libcore.so:
 *   Java_com_follow_clash_core_Core_*
 */
object Core {
    init {
        System.loadLibrary("clash") // must load Go dependency before the JNI bridge
        System.loadLibrary("core")
    }

    /** Initialize Clash with [homeDir] where config.yaml resides. Returns "" on success or error string. */
    external fun quickSetup(homeDir: String): String

    /**
     * Invoke an action on the Clash engine.
     * [action] — action type (int constant defined by libcore)
     * [data]   — JSON string payload
     * [extra]  — auxiliary string (callback ID or empty)
     * [timeout]— timeout in milliseconds
     * Returns JSON result or error string.
     */
    external fun invokeAction(action: Int, data: String, extra: String, timeout: Int): String

    /** Attach an Android TUN fd to Clash. [listener] is called back to protect outbound sockets. */
    external fun startTun(fd: Int, listener: TunInterface): Unit

    /** Detach TUN and stop packet processing. */
    external fun stopTun(): Unit

    /** Current upload/download speed: LongArray[0]=up B/s, [1]=down B/s. */
    external fun getTraffic(): LongArray

    /** Cumulative traffic: LongArray[0]=totalUp, [1]=totalDown in bytes. */
    external fun getTotalTraffic(): LongArray

    /** Suspend or resume Clash processing (e.g. when app goes background). */
    external fun suspended(value: Boolean): Unit

    /** Hot-update DNS servers without restarting Clash. */
    external fun updateDNS(dns: String): Unit

    /** Set a listener for async Clash events (logs, proxy changes, etc.). */
    external fun setEventListener(listener: InvokeInterface?): Unit

    /** Force Go GC — call periodically to free memory. */
    external fun forceGC(): Unit
}

/** Callback interface for async invokeAction results and event log lines. */
interface InvokeInterface {
    fun onResult(result: String)
}

/** Callback interface that lets Clash protect outbound sockets from the VPN routing table. */
interface TunInterface {
    /** Protect [fd] so Clash's outbound connection bypasses the TUN interface. */
    fun protect(fd: Int): Boolean
    /** Resolve a process by [name] / [uid] for per-app routing. Return false to skip. */
    fun resolverProcess(name: String, uid: Int, remote: String): Boolean
}
