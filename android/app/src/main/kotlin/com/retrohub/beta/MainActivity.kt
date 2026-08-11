package com.retrohub.beta

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothServerSocket
import android.bluetooth.BluetoothSocket
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.util.UUID
import java.util.concurrent.atomic.AtomicBoolean

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "RetroHubBT"
        private const val METHOD_CHANNEL = "com.retrohub.beta/bluetooth_link"
        private const val EVENT_CHANNEL = "com.retrohub.beta/bluetooth_link/events"
        private const val DEFAULT_SERVICE_NAME = "RetroHub Link"
        private const val DEFAULT_UUID = "b2554007-ebb3-4359-9483-4d49f79d8246"
    }

    private val bluetoothAdapter: BluetoothAdapter?
        get() = BluetoothAdapter.getDefaultAdapter()

    @Volatile
    private var eventSink: EventChannel.EventSink? = null

    @Volatile
    private var serverSocket: BluetoothServerSocket? = null

    @Volatile
    private var socket: BluetoothSocket? = null

    @Volatile
    private var input: InputStream? = null

    @Volatile
    private var output: OutputStream? = null

    @Volatile
    private var hostThread: Thread? = null

    @Volatile
    private var connectThread: Thread? = null

    @Volatile
    private var readThread: Thread? = null

    private val intentionalDisconnect = AtomicBoolean(false)
    private val writeLock = Any()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                Log.d(TAG, "[RetroHub BT] EventChannel onListen")
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                Log.d(TAG, "[RetroHub BT] EventChannel onCancel")
                eventSink = null
            }
        })

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL
        ).setMethodCallHandler { call, result ->
            Log.d(TAG, "[RetroHub BT] MethodChannel: ${call.method}")

            when (call.method) {
                "startHosting" -> {
                    val name = call.argument<String>("name")
                        ?.takeIf { it.isNotBlank() }
                        ?: DEFAULT_SERVICE_NAME
                    val uuid = parseUuid(call.argument<String>("uuid"), result)
                        ?: return@setMethodCallHandler

                    if (!hasConnectPermission()) {
                        result.error(
                            "bluetooth_permission",
                            "BLUETOOTH_CONNECT no está concedido",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    startHosting(name, uuid)
                    result.success(null)
                }

                "connect" -> {
                    val address = call.argument<String>("address")
                    if (address.isNullOrBlank()) {
                        result.error(
                            "invalid_address",
                            "No se recibió una dirección Bluetooth",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    val uuid = parseUuid(call.argument<String>("uuid"), result)
                        ?: return@setMethodCallHandler

                    if (!hasConnectPermission()) {
                        result.error(
                            "bluetooth_permission",
                            "BLUETOOTH_CONNECT no está concedido",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    connect(address, uuid)
                    result.success(null)
                }

                "send" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    if (bytes == null) {
                        result.error(
                            "invalid_data",
                            "No se recibieron bytes para enviar",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    result.success(send(bytes))
                }

                "disconnect" -> {
                    stopBluetooth(notifyFlutter = true)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun parseUuid(
        raw: String?,
        result: MethodChannel.Result
    ): UUID? {
        return try {
            UUID.fromString(raw ?: DEFAULT_UUID)
        } catch (_: IllegalArgumentException) {
            result.error("invalid_uuid", "UUID Bluetooth inválido: $raw", null)
            null
        }
    }

    private fun hasConnectPermission(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.BLUETOOTH_CONNECT
            ) == PackageManager.PERMISSION_GRANTED
    }

    private fun startHosting(serviceName: String, uuid: UUID) {
        Log.d(
            TAG,
            "[RetroHub BT] HOST solicitado name=$serviceName uuid=$uuid"
        )

        prepareForNewConnection()

        val adapter = bluetoothAdapter
        if (adapter == null) {
            emitError("Bluetooth no está disponible en este dispositivo")
            return
        }

        if (!adapter.isEnabled) {
            emitError("Bluetooth está desactivado")
            return
        }

        intentionalDisconnect.set(false)

        hostThread = Thread({
            var localServer: BluetoothServerSocket? = null

            try {
                Log.d(TAG, "[RetroHub BT] HOST creando server socket RFCOMM")

                localServer = adapter.listenUsingInsecureRfcommWithServiceRecord(
                    serviceName,
                    uuid
                )
                serverSocket = localServer

                Log.d(TAG, "[RetroHub BT] HOST LISTENING - esperando accept()")

                val accepted = localServer.accept()

                if (intentionalDisconnect.get()) {
                    closeQuietly(accepted)
                    return@Thread
                }

                Log.d(
                    TAG,
                    "[RetroHub BT] HOST ACCEPT OK address=${safeAddress(accepted.remoteDevice)}"
                )

                // Ya tenemos una conexión; el servidor deja de ser necesario.
                closeQuietly(localServer)
                if (serverSocket === localServer) {
                    serverSocket = null
                }

                attachConnectedSocket(accepted, "HOST")
            } catch (e: IOException) {
                if (!intentionalDisconnect.get()) {
                    Log.e(TAG, "[RetroHub BT] HOST error", e)
                    emitError("host_error: ${e.message ?: e.javaClass.simpleName}")
                } else {
                    Log.d(TAG, "[RetroHub BT] HOST accept cerrado voluntariamente")
                }
            } catch (e: SecurityException) {
                Log.e(TAG, "[RetroHub BT] HOST permiso Bluetooth", e)
                emitError("bluetooth_permission: ${e.message ?: "permiso denegado"}")
            } finally {
                closeQuietly(localServer)
                if (serverSocket === localServer) {
                    serverSocket = null
                }
            }
        }, "RetroHub-BT-Host").also { it.start() }
    }

    private fun connect(address: String, uuid: UUID) {
        Log.d(
            TAG,
            "[RetroHub BT] CLIENTE connect solicitado address=$address uuid=$uuid"
        )

        prepareForNewConnection()

        val adapter = bluetoothAdapter
        if (adapter == null) {
            emitError("Bluetooth no está disponible en este dispositivo")
            return
        }

        if (!adapter.isEnabled) {
            emitError("Bluetooth está desactivado")
            return
        }

        intentionalDisconnect.set(false)

        connectThread = Thread({
            var candidate: BluetoothSocket? = null

            try {
                Log.d(TAG, "[RetroHub BT] CLIENTE cancelando discovery")
                try {
                    adapter.cancelDiscovery()
                } catch (e: SecurityException) {
                    Log.w(TAG, "[RetroHub BT] No se pudo cancelar discovery", e)
                }

                Log.d(TAG, "[RetroHub BT] CLIENTE obteniendo remoteDevice $address")
                val device = adapter.getRemoteDevice(address)

                Log.d(TAG, "[RetroHub BT] CLIENTE creando insecure RFCOMM socket")
                candidate = device.createInsecureRfcommSocketToServiceRecord(uuid)

                Log.d(TAG, "[RetroHub BT] CLIENTE llamando socket.connect()")
                candidate.connect()

                if (intentionalDisconnect.get()) {
                    closeQuietly(candidate)
                    return@Thread
                }

                Log.d(TAG, "[RetroHub BT] CLIENTE CONNECT OK")
                attachConnectedSocket(candidate, "CLIENTE")
                candidate = null
            } catch (e: IllegalArgumentException) {
                Log.e(TAG, "[RetroHub BT] Dirección Bluetooth inválida", e)
                emitError("invalid_address: $address")
            } catch (e: IOException) {
                if (!intentionalDisconnect.get()) {
                    Log.e(TAG, "[RetroHub BT] CLIENTE error", e)
                    emitError("connect_error: ${e.message ?: e.javaClass.simpleName}")
                }
            } catch (e: SecurityException) {
                Log.e(TAG, "[RetroHub BT] CLIENTE permiso Bluetooth", e)
                emitError("bluetooth_permission: ${e.message ?: "permiso denegado"}")
            } finally {
                closeQuietly(candidate)
            }
        }, "RetroHub-BT-Connect").also { it.start() }
    }

    @Synchronized
    private fun attachConnectedSocket(connectedSocket: BluetoothSocket, role: String) {
        if (intentionalDisconnect.get()) {
            closeQuietly(connectedSocket)
            return
        }

        // Si por alguna carrera quedó otro socket, se cierra antes de adoptar éste.
        closeActiveSocketOnly()

        try {
            socket = connectedSocket
            input = connectedSocket.inputStream
            output = connectedSocket.outputStream

            val remote = connectedSocket.remoteDevice
            val address = safeAddress(remote)
            val name = safeName(remote)

            Log.d(
                TAG,
                "[RetroHub BT] $role CONECTADO name=$name address=$address"
            )

            emitEvent(
                mapOf(
                    "type" to "connected",
                    "address" to address,
                    "name" to name
                )
            )

            startReader(connectedSocket)
        } catch (e: IOException) {
            Log.e(TAG, "[RetroHub BT] $role no pudo abrir streams", e)
            closeActiveSocketOnly()
            emitError("stream_error: ${e.message ?: e.javaClass.simpleName}")
        } catch (e: SecurityException) {
            Log.e(TAG, "[RetroHub BT] $role permiso al leer remoteDevice", e)
            closeActiveSocketOnly()
            emitError("bluetooth_permission: ${e.message ?: "permiso denegado"}")
        }
    }

    private fun startReader(connectedSocket: BluetoothSocket) {
        readThread = Thread({
            val buffer = ByteArray(4096)

            try {
                while (!intentionalDisconnect.get() && socket === connectedSocket) {
                    val currentInput = input ?: break
                    val count = currentInput.read(buffer)

                    if (count < 0) {
                        throw IOException("BluetoothSocket EOF")
                    }

                    if (count == 0) {
                        continue
                    }

                    val data = buffer.copyOf(count)
                    Log.v(TAG, "[RetroHub BT] RX $count bytes")

                    emitEvent(
                        mapOf(
                            "type" to "data",
                            "bytes" to data
                        )
                    )
                }
            } catch (e: IOException) {
                if (!intentionalDisconnect.get() && socket === connectedSocket) {
                    Log.e(TAG, "[RetroHub BT] RX error", e)
                    closeActiveSocketOnly()
                    emitError("read_error: ${e.message ?: e.javaClass.simpleName}")
                    emitDisconnected()
                }
            } catch (e: SecurityException) {
                if (!intentionalDisconnect.get() && socket === connectedSocket) {
                    Log.e(TAG, "[RetroHub BT] RX permiso Bluetooth", e)
                    closeActiveSocketOnly()
                    emitError("bluetooth_permission: ${e.message ?: "permiso denegado"}")
                    emitDisconnected()
                }
            }
        }, "RetroHub-BT-Reader").also { it.start() }
    }

    private fun send(bytes: ByteArray): Boolean {
        if (bytes.isEmpty()) {
            return true
        }

        val currentOutput = output ?: run {
            Log.w(TAG, "[RetroHub BT] SEND ignorado: no hay conexión")
            return false
        }

        return try {
            synchronized(writeLock) {
                currentOutput.write(bytes)
                currentOutput.flush()
            }
            Log.v(TAG, "[RetroHub BT] SEND ${bytes.size} bytes")
            true
        } catch (e: IOException) {
            Log.e(TAG, "[RetroHub BT] SEND error", e)
            emitError("send_error: ${e.message ?: e.javaClass.simpleName}")
            false
        }
    }

    /**
     * Cierra una sesión anterior antes de host/connect sin mandar un
     * "disconnected" espurio a Flutter. La nueva operación emitirá su
     * propio estado.
     */
    private fun prepareForNewConnection() {
        intentionalDisconnect.set(true)

        closeQuietly(serverSocket)
        serverSocket = null

        closeActiveSocketOnly()

        hostThread?.interrupt()
        connectThread?.interrupt()
        readThread?.interrupt()

        hostThread = null
        connectThread = null
        readThread = null
    }

    @Synchronized
    private fun closeActiveSocketOnly() {
        closeQuietly(input)
        closeQuietly(output)
        closeQuietly(socket)

        input = null
        output = null
        socket = null
    }

    private fun stopBluetooth(notifyFlutter: Boolean) {
        Log.d(
            TAG,
            "[RetroHub BT] stopBluetooth server=${serverSocket != null} socket=${socket != null}"
        )

        intentionalDisconnect.set(true)

        closeQuietly(serverSocket)
        serverSocket = null

        closeActiveSocketOnly()

        hostThread?.interrupt()
        connectThread?.interrupt()
        readThread?.interrupt()

        hostThread = null
        connectThread = null
        readThread = null

        if (notifyFlutter) {
            emitDisconnected()
        }
    }

    private fun emitDisconnected() {
        emitEvent(mapOf("type" to "disconnected"))
    }

    private fun emitError(reason: String) {
        Log.e(TAG, "[RetroHub BT] ERROR $reason")
        emitEvent(
            mapOf(
                "type" to "error",
                "reason" to reason
            )
        )
    }

    private fun emitEvent(event: Map<String, Any>) {
        runOnUiThread {
            try {
                Log.d(
                    TAG,
                    "[RetroHub BT] EVENT type=${event["type"]} reason=${event["reason"] ?: ""}"
                )
                eventSink?.success(event)
            } catch (e: Exception) {
                Log.e(TAG, "[RetroHub BT] Error enviando evento a Flutter", e)
            }
        }
    }

    private fun safeName(device: BluetoothDevice?): String {
        if (device == null) return ""
        return try {
            device.name ?: ""
        } catch (_: SecurityException) {
            ""
        }
    }

    private fun safeAddress(device: BluetoothDevice?): String {
        if (device == null) return ""
        return try {
            device.address ?: ""
        } catch (_: SecurityException) {
            ""
        }
    }

    private fun closeQuietly(closeable: Any?) {
        try {
            when (closeable) {
                is BluetoothServerSocket -> closeable.close()
                is BluetoothSocket -> closeable.close()
                is InputStream -> closeable.close()
                is OutputStream -> closeable.close()
            }
        } catch (_: IOException) {
            // Cierre best-effort.
        }
    }

    override fun onDestroy() {
        stopBluetooth(notifyFlutter = false)
        eventSink = null
        super.onDestroy()
    }
}