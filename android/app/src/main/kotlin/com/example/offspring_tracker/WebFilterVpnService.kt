package com.example.offspring_tracker

import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.VpnService
import android.os.ParcelFileDescriptor
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.Inet4Address
import java.net.InetAddress
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Blocks websites by filtering DNS on the phone itself.
 *
 * The VPN only captures DNS traffic sent to a private address. Lookups for
 * blocked domains get a "not found" answer; all other lookups are forwarded
 * to the phone's normal DNS servers. No other traffic passes through it and
 * nothing leaves the phone except the normal DNS lookups.
 */
class WebFilterVpnService : VpnService() {
    private var tunnel: ParcelFileDescriptor? = null
    private var reader: Thread? = null
    private var forwarders: ExecutorService? = null
    private var upstreamDns: List<InetAddress> = emptyList()

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopFilter()
            stopSelf()
            return START_NOT_STICKY
        }
        startFilter()
        return START_STICKY
    }

    override fun onRevoke() {
        // The user turned the VPN off in Settings, or another VPN took over.
        stopFilter()
        stopSelf()
    }

    override fun onDestroy() {
        stopFilter()
        super.onDestroy()
    }

    private fun startFilter() {
        if (tunnel != null) return
        upstreamDns = currentDnsServers()
        val established = Builder()
            .setSession("Offspring Tracker website filter")
            .addAddress(VPN_ADDRESS, 32)
            .addDnsServer(VPN_DNS)
            .addRoute(VPN_DNS, 32)
            .setBlocking(true)
            .establish() ?: return
        tunnel = established
        isRunning = true
        forwarders = Executors.newFixedThreadPool(4)
        reader = Thread({ readLoop(established) }, "web-filter").also { it.start() }
    }

    private fun stopFilter() {
        isRunning = false
        reader?.interrupt()
        reader = null
        forwarders?.shutdownNow()
        forwarders = null
        try {
            tunnel?.close()
        } catch (_: Exception) {
        }
        tunnel = null
    }

    private fun readLoop(fd: ParcelFileDescriptor) {
        val input = FileInputStream(fd.fileDescriptor)
        val output = FileOutputStream(fd.fileDescriptor)
        val buffer = ByteArray(32767)
        try {
            while (!Thread.currentThread().isInterrupted) {
                val length = input.read(buffer)
                if (length <= 0) continue
                val packet = buffer.copyOf(length)
                forwarders?.execute { handlePacket(packet, output) }
            }
        } catch (_: Exception) {
            // Tunnel closed.
        }
    }

    private fun handlePacket(packet: ByteArray, output: FileOutputStream) {
        val query = DnsPacket.parse(packet) ?: return
        val answer = if (BlockingRules.load(this).isSiteBlocked(query.host)) {
            query.notFoundAnswer()
        } else {
            forward(query.dnsPayload) ?: return
        }
        val response = query.wrapResponse(answer)
        synchronized(output) {
            try {
                output.write(response)
            } catch (_: Exception) {
            }
        }
    }

    private fun forward(payload: ByteArray): ByteArray? {
        for (server in upstreamDns) {
            try {
                DatagramSocket().use { socket ->
                    protect(socket) // keep this lookup outside the VPN
                    socket.soTimeout = 5000
                    socket.send(DatagramPacket(payload, payload.size, server, 53))
                    val reply = DatagramPacket(ByteArray(4096), 4096)
                    socket.receive(reply)
                    return reply.data.copyOf(reply.length)
                }
            } catch (_: Exception) {
                // Try the next server.
            }
        }
        return null
    }

    /** DNS servers of the current network, with public fallbacks. */
    private fun currentDnsServers(): List<InetAddress> {
        val servers = mutableListOf<InetAddress>()
        try {
            val connectivity = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            connectivity.activeNetwork?.let { network ->
                connectivity.getLinkProperties(network)?.dnsServers
                    ?.filterIsInstance<Inet4Address>()
                    ?.filter { it.hostAddress != VPN_DNS }
                    ?.let { servers.addAll(it) }
            }
        } catch (_: Exception) {
        }
        servers.add(InetAddress.getByName("8.8.8.8"))
        servers.add(InetAddress.getByName("1.1.1.1"))
        return servers.distinct()
    }

    companion object {
        const val ACTION_START = "com.example.offspring_tracker.WEB_FILTER_START"
        const val ACTION_STOP = "com.example.offspring_tracker.WEB_FILTER_STOP"
        private const val VPN_ADDRESS = "10.111.222.1"
        private const val VPN_DNS = "10.111.222.53"

        @Volatile var isRunning = false
            private set
    }
}

/** A DNS query read from an IPv4/UDP packet captured by the VPN. */
private class DnsPacket(
    private val ip: ByteArray,
    private val ipHeaderLength: Int,
    val dnsPayload: ByteArray,
    val host: String,
    private val questionEnd: Int,
) {
    /** A "domain not found" reply that keeps the original question. */
    fun notFoundAnswer(): ByteArray {
        val reply = dnsPayload.copyOf(questionEnd)
        reply[2] = (0x80 or (dnsPayload[2].toInt() and 0x01)).toByte() // response, keep RD
        reply[3] = (0x80 or 0x03).toByte() // RA, NXDOMAIN
        for (i in 6..11) reply[i] = 0 // no answer/authority/additional records
        return reply
    }

    /** Wraps a DNS reply in IPv4 + UDP headers addressed back to the asker. */
    fun wrapResponse(dns: ByteArray): ByteArray {
        val total = 20 + 8 + dns.size
        val out = ByteArray(total)
        out[0] = 0x45
        writeShort(out, 2, total)
        out[6] = 0x40 // don't fragment
        out[8] = 64 // TTL
        out[9] = 17 // UDP
        System.arraycopy(ip, 16, out, 12, 4) // from: the DNS address
        System.arraycopy(ip, 12, out, 16, 4) // to: the original sender
        writeShort(out, 10, checksum(out, 0, 20))
        val udpIn = ipHeaderLength
        out[20] = ip[udpIn + 2]
        out[21] = ip[udpIn + 3] // source port 53
        out[22] = ip[udpIn]
        out[23] = ip[udpIn + 1] // back to the sender's port
        writeShort(out, 24, 8 + dns.size)
        // UDP checksum 0 = not used (allowed for IPv4).
        System.arraycopy(dns, 0, out, 28, dns.size)
        return out
    }

    companion object {
        fun parse(ip: ByteArray): DnsPacket? {
            if (ip.size < 28 || (ip[0].toInt() shr 4) != 4) return null
            val headerLength = (ip[0].toInt() and 0x0F) * 4
            if (ip[9].toInt() != 17 || ip.size < headerLength + 8 + 12) return null
            val destinationPort = readShort(ip, headerLength + 2)
            if (destinationPort != 53) return null
            val dns = ip.copyOfRange(headerLength + 8, ip.size)
            if (readShort(dns, 4) < 1) return null // no question

            val labels = mutableListOf<String>()
            var pos = 12
            while (pos < dns.size) {
                val length = dns[pos].toInt() and 0xFF
                if (length == 0) {
                    pos++
                    break
                }
                if (length and 0xC0 != 0 || pos + 1 + length > dns.size) return null
                labels.add(String(dns, pos + 1, length, Charsets.US_ASCII))
                pos += 1 + length
            }
            val questionEnd = pos + 4 // QTYPE + QCLASS
            if (labels.isEmpty() || questionEnd > dns.size) return null
            return DnsPacket(ip, headerLength, dns, labels.joinToString(".").lowercase(), questionEnd)
        }

        private fun readShort(data: ByteArray, offset: Int): Int =
            ((data[offset].toInt() and 0xFF) shl 8) or (data[offset + 1].toInt() and 0xFF)

        private fun writeShort(data: ByteArray, offset: Int, value: Int) {
            data[offset] = (value shr 8).toByte()
            data[offset + 1] = value.toByte()
        }

        private fun checksum(data: ByteArray, offset: Int, length: Int): Int {
            var sum = 0
            var i = offset
            while (i < offset + length - 1) {
                sum += readShort(data, i)
                i += 2
            }
            while (sum shr 16 != 0) sum = (sum and 0xFFFF) + (sum shr 16)
            return sum.inv() and 0xFFFF
        }
    }
}
