#ifdef __ANDROID__

#include "texture.h"
#include <jni.h>
#include <android/log.h>
#include <android/native_window_jni.h>
#include <cstring>
#include <algorithm>
#include <mutex>
#include <stdexcept>
#include <dlfcn.h>          // ★ dlopen / dlsym

#define LOG_TAG "NativeBridge"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO,  LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

namespace flutter_video_player {

// ==================== JNI 缓存 ====================
static JavaVM*   g_vm           = nullptr;
static jclass    g_plugin_class = nullptr;
static jclass    g_result_class = nullptr;
static jmethodID g_create_mid   = nullptr;
static jmethodID g_destroy_mid  = nullptr;
static jfieldID  g_surface_fid  = nullptr;
static jfieldID  g_texid_fid    = nullptr;

static std::once_flag g_init_flag;
static bool           g_init_ok = false;

struct SurfaceInfo {
    jobject surface;
    int64_t textureId;
};

// ★ 从 libart.so 拿 JNI_GetCreatedJavaVMs，替代 JNI_OnLoad 的 vm 入参
static JavaVM* findJavaVM() {
    void* handle = dlopen("libart.so", RTLD_NOW);
    if (!handle) {
        // 兼容旧版 Android（Android 4.x 用 libnativehelper）
        handle = dlopen("libnativehelper.so", RTLD_NOW);
    }
    if (!handle) {
        LOGE("dlopen libart.so failed: %s", dlerror());
        return nullptr;
    }
    using Fn = jint (*)(JavaVM**, jsize, jsize*);
    auto fn = reinterpret_cast<Fn>(dlsym(handle, "JNI_GetCreatedJavaVMs"));
    if (!fn) {
        LOGE("dlsym JNI_GetCreatedJavaVMs failed");
        dlclose(handle);
        return nullptr;
    }
    JavaVM* vm = nullptr;
    jsize count = 0;
    jint ret = fn(&vm, 1, &count);
    dlclose(handle);
    if (ret != JNI_OK || count == 0) {
        LOGE("JNI_GetCreatedJavaVMs ret=%d count=%d", ret, count);
        return nullptr;
    }
    return vm;
}

// ★ 懒初始化：第一次调用 getEnv() 时执行一次
static bool initJNI() {
    if (!g_vm) g_vm = findJavaVM();
    if (!g_vm) { LOGE("JavaVM not found"); return false; }

    JNIEnv* env = nullptr;
    bool attached = false;
    if (g_vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) == JNI_EDETACHED) {
        if (g_vm->AttachCurrentThread(&env, nullptr) != JNI_OK) {
            LOGE("AttachCurrentThread failed");
            return false;
        }
        attached = true;
    }
    if (!env) { LOGE("getEnv failed in init"); return false; }

    jclass pc = env->FindClass("com/example/flutter_video_player/FlutterVideoPlayerPlugin");
    if (!pc) {
        LOGE("FindClass plugin failed (called from non-Java thread?)");
        env->ExceptionDescribe();
        env->ExceptionClear();
        if (attached) g_vm->DetachCurrentThread();
        return false;
    }
    g_plugin_class = reinterpret_cast<jclass>(env->NewGlobalRef(pc));
    env->DeleteLocalRef(pc);

    jclass rc = env->FindClass("com/example/flutter_video_player/SurfaceResult");
    if (!rc) {
        LOGE("FindClass SurfaceResult failed");
        env->ExceptionDescribe();
        env->ExceptionClear();
        if (attached) g_vm->DetachCurrentThread();
        return false;
    }
    g_result_class = reinterpret_cast<jclass>(env->NewGlobalRef(rc));
    env->DeleteLocalRef(rc);

    g_create_mid  = env->GetStaticMethodID(g_plugin_class, "createSurfaceForNative",
            "()Lcom/example/flutter_video_player/SurfaceResult;");
    g_destroy_mid = env->GetStaticMethodID(g_plugin_class, "destroySurfaceForNative", "(J)Z");
    g_surface_fid = env->GetFieldID(g_result_class, "surface",   "Landroid/view/Surface;");
    g_texid_fid   = env->GetFieldID(g_result_class, "textureId", "J");

    if (!g_create_mid || !g_destroy_mid || !g_surface_fid || !g_texid_fid) {
        LOGE("cache method/field failed");
        env->ExceptionDescribe();
        env->ExceptionClear();
        if (attached) g_vm->DetachCurrentThread();
        return false;
    }

    LOGI("JNI lazy init ok (attached=%d)", (int)attached);
    return true;
}

static JNIEnv* getEnv() {
    std::call_once(g_init_flag, []() { g_init_ok = initJNI(); });
    if (!g_init_ok || !g_vm) return nullptr;

    JNIEnv* env = nullptr;
    if (g_vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) == JNI_EDETACHED) {
        if (g_vm->AttachCurrentThread(&env, nullptr) != JNI_OK) return nullptr;
    }
    return env;
}

// ==================== createSurface / destroySurface ====================

static SurfaceInfo createSurface() {
    SurfaceInfo info{nullptr, -1};
    JNIEnv* env = getEnv();
    if (!env) return info;

    jobject res = env->CallStaticObjectMethod(g_plugin_class, g_create_mid);
    if (env->ExceptionCheck() || !res) {
        env->ExceptionDescribe();
        env->ExceptionClear();
        return info;
    }

    jobject surfaceLocal = env->GetObjectField(res, g_surface_fid);
    info.textureId = env->GetLongField(res, g_texid_fid);
    info.surface   = env->NewGlobalRef(surfaceLocal);

    env->DeleteLocalRef(surfaceLocal);
    env->DeleteLocalRef(res);
    return info;
}

static bool destroySurface(SurfaceInfo& info) {
    JNIEnv* env = getEnv();
    if (!env) return false;

    if (info.surface) {
        env->DeleteGlobalRef(info.surface);
        info.surface = nullptr;
    }

    jboolean ok = env->CallStaticBooleanMethod(g_plugin_class, g_destroy_mid, info.textureId);
    if (env->ExceptionCheck()) {
        env->ExceptionDescribe();
        env->ExceptionClear();
        ok = JNI_FALSE;
    }
    info.textureId = -1;
    return ok == JNI_TRUE;
}

// ==================== Android 版 _Texture ====================

class _Texture : public Texture {
public:
    _Texture() {
        SurfaceInfo info = createSurface();
        if (info.textureId <= 0 || !info.surface) {
            throw std::runtime_error("createSurface failed");
        }
        textureId_ = info.textureId;
        surface_   = info.surface;

        JNIEnv* env = getEnv();
        window_ = ANativeWindow_fromSurface(env, surface_);
        if (!window_) LOGE("ANativeWindow_fromSurface failed");
        LOGI("_Texture created id=%lld window=%p", (long long)textureId_, window_);
    }

    ~_Texture() override {
        if (window_) {
            ANativeWindow_release(window_);
            window_ = nullptr;
        }
        if (surface_ || textureId_ > 0) {
            SurfaceInfo info{surface_, textureId_};
            destroySurface(info);
            surface_   = nullptr;
            textureId_ = -1;
        }
        LOGI("_Texture destroyed");
    }

    int64_t getId() override { return textureId_; }

    void write(uint8_t* data, int width, int height,
               const std::function<void()>& releaseCallback) override {
        if (!window_ || !data || width <= 0 || height <= 0) {
            if (releaseCallback) releaseCallback();
            return;
        }

        ANativeWindow_setBuffersGeometry(window_, width, height, WINDOW_FORMAT_RGBA_8888);

        ANativeWindow_Buffer buffer;
        if (ANativeWindow_lock(window_, &buffer, nullptr) != 0) {
            if (releaseCallback) releaseCallback();
            return;
        }

        uint8_t* dst = static_cast<uint8_t*>(buffer.bits);
        const int dstStride = buffer.stride * 4;
        const int srcStride = width * 4;
        const int copyBytes = std::min(dstStride, srcStride);
        const int rows      = std::min(buffer.height, height);

        for (int i = 0; i < rows; ++i) {
            std::memcpy(dst + i * dstStride, data + i * srcStride, copyBytes);
        }

        ANativeWindow_unlockAndPost(window_);
        if (releaseCallback) releaseCallback();
    }

private:
    int64_t        textureId_ = -1;
    jobject        surface_   = nullptr;
    ANativeWindow* window_    = nullptr;
};

// ==================== 静态接口 ====================

void Texture::setTextureRegistrar(void* /*texture_registrar*/) {}

Texture* Texture::create() {
    return new _Texture();
}

} // namespace flutter_video_player

#endif // __ANDROID__