package com.example.flutter_video_player

import android.view.Surface
import androidx.annotation.Keep
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.view.TextureRegistry

/** 返回给 C++ 的结果包 */
@Keep
class SurfaceResult(val surface: Surface, val textureId: Long)

/** FlutterVideoPlayerPlugin */
class FlutterVideoPlayerPlugin :
    FlutterPlugin,
    MethodCallHandler {

    // The MethodChannel that will the communication between Flutter and native Android
    private lateinit var channel: MethodChannel

    companion object {
        // -------- 供 C++ JNI 使用的引用 --------
        private var engineRef: FlutterEngine? = null
        private val producers = mutableListOf<TextureRegistry.SurfaceProducer>()

        init {
            System.loadLibrary("flutter_video_player")
        }

        /** 供 C++ JNI 调用：创建 Surface 与 textureId */
        @Keep
        @JvmStatic
        fun createSurfaceForNative(): SurfaceResult {
            val engine = engineRef
                ?: throw IllegalStateException("FlutterEngine not attached")
            val producer = engine.renderer.createSurfaceProducer()
            producers.add(producer)
            return SurfaceResult(producer.surface, producer.id())
        }

        /** 供 C++ JNI 调用：按 textureId 销毁并释放全部底层资源 */
        @Keep
        @JvmStatic
        fun destroySurfaceForNative(textureId: Long): Boolean {
            val it = producers.iterator()
            while (it.hasNext()) {
                val p = it.next()
                if (p.id() == textureId) {
                    it.remove()
                    p.release()   // 释放 SurfaceProducer 及其底层资源
                    return true
                }
            }
            return false
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        // -------- 默认模板 --------
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_video_player")
        channel.setMethodCallHandler(this)

        // -------- 保存 engine 供 C++ 使用 --------
        engineRef = flutterPluginBinding.flutterEngine
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        // -------- 默认模板 --------
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // -------- 默认模板 --------
        channel.setMethodCallHandler(null)

        // -------- 兜底清理 --------
        producers.forEach { it.release() }
        producers.clear()
        engineRef = null
    }
}