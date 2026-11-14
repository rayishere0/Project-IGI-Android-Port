#include <jni.h>
#include <android/native_window.h>
#include <android/native_window_jni.h>
#include <android/log.h>
#include <dlfcn.h>
#include <dirent.h>
#include <string>
#include <vector>
#include <thread>
#include <atomic>
#include <mutex>

#define LOG_TAG "ProjectIGI-NDK"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)



// CoreCLR hosting function signatures
typedef int (*coreclr_initialize_fn)(
    const char* exePath,
    const char* appDomainFriendlyName,
    int propertyCount,
    const char** propertyKeys,
    const char** propertyValues,
    void** hostHandle,
    unsigned int* domainId);

typedef int (*coreclr_shutdown_fn)(
    void* hostHandle,
    unsigned int domainId);

typedef int (*coreclr_create_delegate_fn)(
    void* hostHandle,
    unsigned int domainId,
    const char* entryPointAssemblyName,
    const char* entryPointTypeName,
    const char* entryPointMethodName,
    void** delegate);

// Managed delegates
typedef int (*RunFn)(intptr_t nativeWindow, int width, int height, intptr_t dataDirPtr, intptr_t optionsPtr);
typedef void (*TouchFn)(int action, int pointerId, float x, float y);
typedef void (*KeyFn)(int keyCode, int down);
typedef void (*ResizeFn)(int width, int height);
typedef void (*StopFn)();
typedef void (*GyroFn)(float yawRadians, float pitchRadians);
typedef void (*GamepadAxisFn)(float leftX, float leftY, float rightX, float rightY, float leftTrigger, float rightTrigger);
typedef void (*GamepadConnectedFn)(int connected);
typedef void (*TextFn)(const char* text);
typedef int (*MicrophoneRequestedFn)();
typedef void (*SurfaceLostFn)();
typedef void (*SurfaceRecreatedFn)(intptr_t nativeWindow, int width, int height);

static void* g_coreclr_lib = nullptr;
static void* g_host_handle = nullptr;
static unsigned int g_domain_id = 0;

static RunFn g_run_fn = nullptr;
static TouchFn g_touch_fn = nullptr;
static KeyFn g_key_fn = nullptr;
static ResizeFn g_resize_fn = nullptr;
static StopFn g_stop_fn = nullptr;
static GyroFn g_gyro_fn = nullptr;
static GamepadAxisFn g_gamepad_axis_fn = nullptr;
static GamepadConnectedFn g_gamepad_connected_fn = nullptr;
static TextFn g_text_fn = nullptr;
static MicrophoneRequestedFn g_microphone_requested_fn = nullptr;
static SurfaceLostFn g_surface_lost_fn = nullptr;
static SurfaceRecreatedFn g_surface_recreated_fn = nullptr;

static std::thread g_game_thread;
static std::atomic<bool> g_game_running{false};
static ANativeWindow* g_native_window = nullptr;

static JavaVM* g_jvm = nullptr;
static std::mutex g_surface_mutex;
static std::condition_variable g_surface_cv;
static bool g_surface_updated = false;

static std::string build_tpa_list(const std::string& directory) {
    std::string tpa;
    DIR* dir = opendir(directory.c_str());
    if (!dir) {
        LOGE("Failed to open managed directory: %s", directory.c_str());
        return tpa;
    }
    struct dirent* entry;
    while ((entry = readdir(dir)) != nullptr) {
        std::string name = entry->d_name;
        if (name.length() > 4 && name.substr(name.length() - 4) == ".dll") {
            if (!tpa.empty()) {
                tpa += ":";
            }
            tpa += directory + "/" + name;
        }
    }
    closedir(dir);
    return tpa;
}

// The .NET Android crypto PAL's init lives behind JNI_OnLoad: the PAL's
// pal_jni_onload.c exports a (weak, JNIEXPORT) JNI_OnLoad that tail-calls
// AndroidCryptoNative_InitLibraryOnLoad(vm, reserved) (dotnet/runtime,
// src/native/libs/System.Security.Cryptography.Native.Android/). The init
// stores the JavaVM the PAL's GetJNIEnv() dereferences on every call, and
// caches the Java classes the PAL needs (SecureRandom, MessageDigest, Cipher,
// SSLContext, ...). The init itself is NOT exported: it is a plain hidden
// function, so dlsym("AndroidCryptoNative_InitLibraryOnLoad") returns NULL —
// proved on-device (Ray's logcat, 2026-11-11 15:00:59 IST: "has no
// InitLibraryOnLoad export") and on the shipped .NET 10 runtime packs
// (nm -D on 10.0.0 and 10.0.15: JNI_OnLoad present, InitLibraryOnLoad
// absent from .dynsym). That is why PR #92's first attempt failed on the
// symbol lookup. Call JNI_OnLoad instead — the documented entry point,
// exactly what the JVM calls on System.loadLibrary.
typedef jint (*CryptoPalInitFn)(JavaVM*, void*);

// Initialises the .NET Android crypto PAL, once, before any managed code runs. The
// runtime loads that library by dlopen for P/Invoke, so its (weak) JNI_OnLoad never
// runs and its stored JavaVM stays null: the first crypto/TLS call then faults at 0x0
// in GetJNIEnv — RandomNumberGenerator on the game thread (the #80 Start crash) and
// SslStream creation on a .NET TP Worker (the rooms HTTPS/WSS crash, 2026-11-11
// 14:27:42 IST). Calling JNI_OnLoad here is exactly what .NET for Android does at
// startup (via System.loadLibrary); it fixes every PAL site at once (RNG, SslStream,
// hashing) because they all start at the same GetJNIEnv() on the same JavaVM. A
// failure only warns: the game starts as it does today, with crypto still broken,
// and no new failure mode.
static bool init_android_crypto_pal(const std::string& nativeLibDir, const std::string& managedDir, const std::string& filesDir) {
    static bool attempted = false;
    static bool ok = false;
    if (attempted) {
        return ok;
    }
    attempted = true;

    if (!g_jvm) {
        LOGE("Android crypto PAL: no JavaVM yet; crypto/TLS calls will crash if used.");
        return false;
    }

    void* cryptoLib = dlopen((nativeLibDir + "/libSystem.Security.Cryptography.Native.Android.so").c_str(), RTLD_NOW | RTLD_GLOBAL);
    if (!cryptoLib) {
        cryptoLib = dlopen((managedDir + "/libSystem.Security.Cryptography.Native.Android.so").c_str(), RTLD_NOW | RTLD_GLOBAL);
    }
    if (!cryptoLib) {
        cryptoLib = dlopen((filesDir + "/libSystem.Security.Cryptography.Native.Android.so").c_str(), RTLD_NOW | RTLD_GLOBAL);
    }
    if (!cryptoLib) {
        cryptoLib = dlopen("libSystem.Security.Cryptography.Native.Android.so", RTLD_NOW | RTLD_GLOBAL);
    }
    if (!cryptoLib) {
        LOGW("Android crypto PAL not found (%s); HTTPS/SSL and crypto RNG will crash if used.", dlerror());
        return false;
    }

    // Pre-flight: the PAL's init ABORTS the process (LOG_FATAL + abort())
    // if any class it caches is missing from the dex. The init caches 83
    // classes; 79 are JDK (java/*, javax/*) and always present, one is a
    // framework class (com/android/org/conscrypt/SSLParametersImpl), and
    // three are .NET Android runtime classes (net/dot/android/crypto/*)
    // that this host does NOT ship in its dex. Before this PR they were
    // absent, so calling the init killed the game at Play (Ray's logcat
    // 2026-11-11 15:10 IST: "GetClassGRef: class
    // net/dot/android/crypto/DotnetProxyTrustManager was not found"). The
    // three classes are now vendored into the app's Java tree under the
    // same package, so the check below should pass. But never trust that:
    // check every non-JDK class the init caches with the bridge's own
    // FindClass (which returns NULL instead of aborting) plus the exact
    // ctor/method the 10.0 PAL looks up, via raw GetMethodID (NULL on
    // failure, no abort). If anything is missing, SKIP the init and let
    // the game start as it did before #93 (crypto calls will still crash
    // when used, but the game LAUNCHES). A rooms-only crash must never
    // again become a can't-launch crash. This runs on the UI thread
    // inside nativeStartGame's JNI call, so FindClass resolves against
    // the app's classloader - exactly the context the PAL's own
    // FindClass will use a moment later.
    {
        JNIEnv* env = nullptr;
        if (g_jvm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) != JNI_OK) {
            if (g_jvm->AttachCurrentThread(&env, nullptr) != JNI_OK || !env) {
                LOGW("Android crypto PAL pre-flight: no JNIEnv; skipping PAL init, game starts without crypto.");
                return false;
            }
        }
        auto clearPending = [&]() {
            if (env->ExceptionCheck()) env->ExceptionClear();
        };
        // Each entry: class, then the ctor/method the 10.0 PAL looks up
        // (nullptr method = class only). Signatures are the 10.0 shapes;
        // main's DotnetProxyTrustManager has a different (3-arg) ctor,
        // but the device PAL is .NET 10 - proven on its own binary.
        struct PalClassCheck { const char* klass; const char* method; const char* sig; bool isStatic; };
        static const PalClassCheck kPalClasses[] = {
            {"net/dot/android/crypto/DotnetProxyTrustManager", "<init>", "(J)V", false},
            {"net/dot/android/crypto/DotnetX509KeyManager", "<init>", "(Ljava/security/KeyStore$PrivateKeyEntry;)V", false},
            {"net/dot/android/crypto/PalPbkdf2", "pbkdf2OneShot", "(Ljava/lang/String;[BLjava/nio/ByteBuffer;ILjava/nio/ByteBuffer;)I", true},
            {"com/android/org/conscrypt/SSLParametersImpl", "setUseSni", "(Z)V", false},
        };
        for (const PalClassCheck& c : kPalClasses) {
            jclass cls = env->FindClass(c.klass);
            if (!cls) {
                clearPending();
                LOGW("Android crypto PAL pre-flight: class %s missing from dex; skipping PAL init, game starts without crypto.", c.klass);
                return false;
            }
            if (c.method) {
                jmethodID mid = c.isStatic
                    ? env->GetStaticMethodID(cls, c.method, c.sig)
                    : env->GetMethodID(cls, c.method, c.sig);
                if (!mid) {
                    clearPending();
                    LOGW("Android crypto PAL pre-flight: %s.%s %s missing; skipping PAL init, game starts without crypto.", c.klass, c.method, c.sig);
                    env->DeleteLocalRef(cls);
                    return false;
                }
            }
            env->DeleteLocalRef(cls);
        }
        LOGI("Android crypto PAL pre-flight: all required classes present; calling init.");
    }

    // The PAL's init is NOT exported under its own name: AndroidCryptoNative_
    // InitLibraryOnLoad is a plain hidden function in the .so — dlsym() finds
    // no such dynamic symbol, on the device build (Ray's logcat 2026-11-11
    // 15:00:59 IST) and on the shipped .NET 10 runtime packs (nm -D on 10.0.0
    // and 10.0.15). The exported entry point is JNI_OnLoad (JNIEXPORT, weak;
    // dotnet/runtime pal_jni_onload.c), which simply tail-calls
    // InitLibraryOnLoad(vm, reserved) and returns its result
    // (JNI_VERSION_1_6). So call JNI_OnLoad — the documented entry point,
    // exactly what the JVM would call on System.loadLibrary. Keep the direct
    // init as a fallback for any build that does export it. Each outcome has
    // its own log line so the next logcat says exactly what happened.
    auto jniOnLoad = (CryptoPalInitFn)dlsym(cryptoLib, "JNI_OnLoad");
    if (jniOnLoad) {
        jint res = jniOnLoad(g_jvm, nullptr);
        if (res != JNI_VERSION_1_6) {
            LOGW("Android crypto PAL JNI_OnLoad returned %d, expected %d; HTTPS/SSL may crash.", (int)res, (int)JNI_VERSION_1_6);
            return false;
        }
        LOGI("Android crypto PAL initialised via JNI_OnLoad (returned 0x%06x); TLS/RNG now safe on any thread.", (unsigned)res);
        ok = true;
        return true;
    }

    auto init = (CryptoPalInitFn)dlsym(cryptoLib, "AndroidCryptoNative_InitLibraryOnLoad");
    if (init) {
        jint res = init(g_jvm, nullptr);
        if (res != JNI_VERSION_1_6) {
            LOGW("Android crypto PAL InitLibraryOnLoad returned %d, expected %d; HTTPS/SSL may crash.", (int)res, (int)JNI_VERSION_1_6);
            return false;
        }
        LOGI("Android crypto PAL initialised via InitLibraryOnLoad (returned 0x%06x); TLS/RNG now safe on any thread.", (unsigned)res);
        ok = true;
        return true;
    }

    LOGW("Android crypto PAL has neither JNI_OnLoad nor InitLibraryOnLoad export; HTTPS/SSL and crypto RNG will crash if used.");
    return false;
}

static bool initialize_coreclr(const std::string& filesDir, const std::string& nativeLibDir) {
    if (g_host_handle != nullptr) {
        return true;
    }

    std::string managedDir = filesDir + "/managed";
    LOGI("Scanning managed assemblies in: %s", managedDir.c_str());
    std::string tpaList = build_tpa_list(managedDir);
    if (tpaList.empty()) {
        LOGE("No assemblies found in %s! Did asset extraction fail?", managedDir.c_str());
        return false;
    }

    std::string coreclrPath = nativeLibDir + "/libcoreclr.so";
    LOGI("Loading CoreCLR from %s...", coreclrPath.c_str());
    g_coreclr_lib = dlopen(coreclrPath.c_str(), RTLD_NOW | RTLD_GLOBAL);
    if (!g_coreclr_lib) {
        LOGW("Failed to load %s (%s), trying bare dlopen...", coreclrPath.c_str(), dlerror());
        g_coreclr_lib = dlopen("libcoreclr.so", RTLD_NOW | RTLD_GLOBAL);
    }
    if (!g_coreclr_lib) {
        LOGE("Fatal: could not dlopen libcoreclr.so: %s", dlerror());
        return false;
    }

    std::string openalPath = nativeLibDir + "/libopenal.so";
    void* openalLib = dlopen(openalPath.c_str(), RTLD_NOW | RTLD_GLOBAL);
    if (!openalLib) {
        openalPath = managedDir + "/libopenal.so";
        openalLib = dlopen(openalPath.c_str(), RTLD_NOW | RTLD_GLOBAL);
    }
    if (!openalLib) {
        openalPath = filesDir + "/libopenal.so";
        openalLib = dlopen(openalPath.c_str(), RTLD_NOW | RTLD_GLOBAL);
    }
    if (!openalLib) {
        openalLib = dlopen("libopenal.so", RTLD_NOW | RTLD_GLOBAL);
    }
    if (openalLib) {
        LOGI("Preloaded OpenAL native library successfully: %s", openalPath.c_str());
    } else {
        LOGW("Failed to preload OpenAL: %s", dlerror());
    }

    // Before any managed code runs: without this, the first crypto/TLS call faults
    // at 0x0 (see init_android_crypto_pal above). Runs on the UI thread, as in .NET
    // for Android's startup path.
    init_android_crypto_pal(nativeLibDir, managedDir, filesDir);

    setenv("PROJECTIGI_NATIVE_LIB_DIR", nativeLibDir.c_str(), 1);

    auto coreclr_init = (coreclr_initialize_fn)dlsym(g_coreclr_lib, "coreclr_initialize");
    auto coreclr_delegate = (coreclr_create_delegate_fn)dlsym(g_coreclr_lib, "coreclr_create_delegate");

    if (!coreclr_init || !coreclr_delegate) {
        LOGE("Fatal: missing coreclr_initialize or coreclr_create_delegate symbols in libcoreclr.so");
        return false;
    }

    const char* propertyKeys[] = {
        "TRUSTED_PLATFORM_ASSEMBLIES",
        "APP_PATHS",
        "NATIVE_DLL_SEARCH_DIRECTORIES"
    };

    std::string nativeDirs = nativeLibDir + ":" + filesDir + ":" + managedDir;
    const char* propertyValues[] = {
        tpaList.c_str(),
        managedDir.c_str(),
        nativeDirs.c_str()
    };

    LOGI("Initializing CoreCLR runtime...");
    int hr = coreclr_init(
        managedDir.c_str(),
        "ProjectIGIDomain",
        3,
        propertyKeys,
        propertyValues,
        &g_host_handle,
        &g_domain_id
    );

    if (hr < 0 || !g_host_handle) {
        LOGE("coreclr_initialize failed with HRESULT 0x%08X", hr);
        return false;
    }

    LOGI("CoreCLR initialized successfully (domain %u). Binding delegates...", g_domain_id);

    int res1 = coreclr_delegate(g_host_handle, g_domain_id, "OpenIGI.Android", "OpenIGI.Android.AndroidHost", "Run", (void**)&g_run_fn);
    int res2 = coreclr_delegate(g_host_handle, g_domain_id, "OpenIGI.Android", "OpenIGI.Android.AndroidHost", "OnTouch", (void**)&g_touch_fn);
    int res3 = coreclr_delegate(g_host_handle, g_domain_id, "OpenIGI.Android", "OpenIGI.Android.AndroidHost", "OnKey", (void**)&g_key_fn);
    int res4 = coreclr_delegate(g_host_handle, g_domain_id, "OpenIGI.Android", "OpenIGI.Android.AndroidHost", "OnResize", (void**)&g_resize_fn);
    int res5 = coreclr_delegate(g_host_handle, g_domain_id, "OpenIGI.Android", "OpenIGI.Android.AndroidHost", "Stop", (void**)&g_stop_fn);
    int res6 = coreclr_delegate(g_host_handle, g_domain_id, "OpenIGI.Android", "OpenIGI.Android.AndroidHost", "OnGyro", (void**)&g_gyro_fn);
    int res7 = coreclr_delegate(g_host_handle, g_domain_id, "OpenIGI.Android", "OpenIGI.Android.AndroidHost", "OnText", (void**)&g_text_fn);
    int res8 = coreclr_delegate(g_host_handle, g_domain_id, "OpenIGI.Android", "OpenIGI.Android.AndroidHost", "OnSurfaceLost", (void**)&g_surface_lost_fn);
    int res9 = coreclr_delegate(g_host_handle, g_domain_id, "OpenIGI.Android", "OpenIGI.Android.AndroidHost", "OnSurfaceRecreated", (void**)&g_surface_recreated_fn);
    int res10 = coreclr_delegate(g_host_handle, g_domain_id, "OpenIGI.Android", "OpenIGI.Android.AndroidHost", "OnGamepadAxis", (void**)&g_gamepad_axis_fn);
    int res11 = coreclr_delegate(g_host_handle, g_domain_id, "OpenIGI.Android", "OpenIGI.Android.AndroidHost", "OnGamepadConnected", (void**)&g_gamepad_connected_fn);
    int res12 = coreclr_delegate(g_host_handle, g_domain_id, "OpenIGI.Android", "OpenIGI.Android.AndroidHost", "IsMicrophoneRequested", (void**)&g_microphone_requested_fn);

    LOGI("Delegate binding results: Run=0x%08X, OnTouch=0x%08X, OnKey=0x%08X, OnResize=0x%08X, Stop=0x%08X, OnGyro=0x%08X, OnText=0x%08X, OnSurfaceLost=0x%08X, OnSurfaceRecreated=0x%08X, OnGamepadAxis=0x%08X, OnGamepadConnected=0x%08X, IsMicrophoneRequested=0x%08X", res1, res2, res3, res4, res5, res6, res7, res8, res9, res10, res11, res12);

    if (res1 < 0 || !g_run_fn) {
        LOGE("Failed to bind AndroidHost.Run: 0x%08X", res1);
        return false;
    }

    LOGI("Successfully bound all AndroidHost managed callbacks!");
    return true;
}

extern "C" {

JNIEXPORT jboolean JNICALL Java_com_projectigi_app_NativeEngine_nativeStartGame
  (JNIEnv *env, jclass clazz, jobject surface, jint width, jint height, jstring javaFilesDir, jstring javaNativeLibDir, jstring javaOptions) {
    LOGI("Java_com_projectigi_app_NativeEngine_nativeStartGame: %dx%d", width, height);

    if (g_game_running.load()) {
        LOGW("Game is already running.");
        return JNI_TRUE;
    }

    const char* filesDirC = env->GetStringUTFChars(javaFilesDir, nullptr);
    const char* nativeLibDirC = env->GetStringUTFChars(javaNativeLibDir, nullptr);
    const char* optionsC = env->GetStringUTFChars(javaOptions, nullptr);

    std::string filesDir(filesDirC ? filesDirC : "");
    std::string nativeLibDir(nativeLibDirC ? nativeLibDirC : "");
    std::string options(optionsC ? optionsC : "");

    if (filesDirC) env->ReleaseStringUTFChars(javaFilesDir, filesDirC);
    if (nativeLibDirC) env->ReleaseStringUTFChars(javaNativeLibDir, nativeLibDirC);
    if (optionsC) env->ReleaseStringUTFChars(javaOptions, optionsC);

    if (!initialize_coreclr(filesDir, nativeLibDir)) {
        LOGE("Failed to initialize CoreCLR.");
        return JNI_FALSE;
    }

    int landscapeWidth = width > height ? width : height;
    int landscapeHeight = width > height ? height : width;

    if (g_native_window) {
        ANativeWindow_release(g_native_window);
        g_native_window = nullptr;
    }


    g_native_window = ANativeWindow_fromSurface(env, surface);
    if (!g_native_window) {
        LOGE("ANativeWindow_fromSurface failed.");
        return JNI_FALSE;
    }

    int32_t setGeoRes = ANativeWindow_setBuffersGeometry(g_native_window, landscapeWidth, landscapeHeight, 0);
    LOGI("ANativeWindow_setBuffersGeometry(%dx%d) returned %d", landscapeWidth, landscapeHeight, setGeoRes);

    std::string dataDir = filesDir + "/Project IGI";


    g_game_running.store(true);
    g_game_thread = std::thread([landscapeWidth, landscapeHeight, dataDir, options]() {
        LOGI("Game thread started. Attaching thread to Java VM...");
        JNIEnv* env = nullptr;
        if (g_jvm) {
            jint attachResult = g_jvm->AttachCurrentThread(&env, nullptr);
            LOGI("JVM AttachCurrentThread returned %d, JNIEnv=%p", attachResult, env);
        }

        LOGI("Vulkan backend selected: vkCreateAndroidSurfaceKHR has exclusive access (%dx%d)...", landscapeWidth, landscapeHeight);

        int exitCode = g_run_fn((intptr_t)g_native_window, landscapeWidth, landscapeHeight, (intptr_t)dataDir.c_str(), (intptr_t)options.c_str());
        LOGI("ProjectIGI managed game loop ended with exit code: %d", exitCode);


        if (g_jvm) {
            g_jvm->DetachCurrentThread();
        }
        g_game_running.store(false);
    });

    return JNI_TRUE;
}

JNIEXPORT void JNICALL Java_com_projectigi_app_NativeEngine_nativeOnSurfaceChanged
  (JNIEnv *env, jclass clazz, jint width, jint height) {
    int landscapeWidth = width > height ? width : height;
    int landscapeHeight = width > height ? height : width;
    if (g_native_window) {
        ANativeWindow_setBuffersGeometry(g_native_window, landscapeWidth, landscapeHeight, 0);
    }
    if (g_resize_fn) {
        g_resize_fn(landscapeWidth, landscapeHeight);
    }
}

JNIEXPORT void JNICALL Java_com_projectigi_app_NativeEngine_nativeOnSurfaceDestroyed
  (JNIEnv *env, jclass clazz) {
    LOGI("nativeOnSurfaceDestroyed");
    // The surface is gone (app backgrounded) but the engine is NOT stopped: it idles with
    // no surface until a new one arrives, so the player returns to the pause menu in the
    // mission instead of the main menu. Genuine shutdown still goes through nativeShutdown.
    if (g_surface_lost_fn) {
        g_surface_lost_fn();
    }
    if (g_native_window) {
        ANativeWindow_release(g_native_window);
        g_native_window = nullptr;
    }
}

JNIEXPORT jboolean JNICALL Java_com_projectigi_app_NativeEngine_nativeIsGameRunning
  (JNIEnv *env, jclass clazz) {
    return g_game_running.load() ? JNI_TRUE : JNI_FALSE;
}

JNIEXPORT void JNICALL Java_com_projectigi_app_NativeEngine_nativeOnSurfaceRecreated
  (JNIEnv *env, jclass clazz, jobject surface, jint width, jint height) {
    LOGI("Java_com_projectigi_app_NativeEngine_nativeOnSurfaceRecreated: %dx%d", width, height);

    if (g_native_window) {
        ANativeWindow_release(g_native_window);
        g_native_window = nullptr;
    }


    if (surface) {
        g_native_window = ANativeWindow_fromSurface(env, surface);
        if (g_native_window) {
            int landscapeWidth = width > height ? width : height;
            int landscapeHeight = width > height ? height : width;
            ANativeWindow_setBuffersGeometry(g_native_window, landscapeWidth, landscapeHeight, 0);

            // Hand the new window to managed code so it can rebind the presentation surface
            // to it and resume in place (instead of restarting the engine to the main menu).
            if (g_surface_recreated_fn) {
                g_surface_recreated_fn(
                    reinterpret_cast<intptr_t>(g_native_window),
                    landscapeWidth,
                    landscapeHeight);
            }
        }
    }

    {
        std::lock_guard<std::mutex> lock(g_surface_mutex);
        g_surface_updated = true;
    }
    g_surface_cv.notify_all();
}

extern "C" JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM* vm, void* reserved) {
    g_jvm = vm;
    return JNI_VERSION_1_6;
}

extern "C" JNIEXPORT intptr_t JNICALL get_current_jni_env() {
    if (!g_jvm) {
        LOGE("get_current_jni_env: g_jvm is null!");
        return 0;
    }
    JNIEnv* env = nullptr;
    jint res = g_jvm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6);
    if (res == JNI_EDETACHED) {
        if (g_jvm->AttachCurrentThread(&env, nullptr) != JNI_OK) {
            LOGE("get_current_jni_env: AttachCurrentThread failed!");
            return 0;
        }
        LOGI("get_current_jni_env: Attached thread to JVM, env=%p", env);
    } else if (res != JNI_OK) {
        LOGE("get_current_jni_env: GetEnv failed with status %d", res);
        return 0;
    }
    return reinterpret_cast<intptr_t>(env);
}

JNIEXPORT void JNICALL Java_com_projectigi_app_NativeEngine_nativeOnTouch
  (JNIEnv *env, jclass clazz, jint action, jint pointerId, jfloat x, jfloat y) {
    if (g_touch_fn) {
        g_touch_fn(action, pointerId, x, y);
    }
}

JNIEXPORT void JNICALL Java_com_projectigi_app_NativeEngine_nativeOnKey
  (JNIEnv *env, jclass clazz, jint keyCode, jboolean down) {
    if (g_key_fn) {
        g_key_fn(keyCode, down ? 1 : 0);
    }
}

JNIEXPORT void JNICALL Java_com_projectigi_app_NativeEngine_nativeOnGyro
  (JNIEnv *env, jclass clazz, jfloat yawRadians, jfloat pitchRadians) {
    if (g_gyro_fn) {
        g_gyro_fn(yawRadians, pitchRadians);
    }
}

JNIEXPORT void JNICALL Java_com_projectigi_app_NativeEngine_nativeOnGamepadAxis
  (JNIEnv *env, jclass clazz, jfloat leftX, jfloat leftY, jfloat rightX, jfloat rightY, jfloat leftTrigger, jfloat rightTrigger) {
    if (g_gamepad_axis_fn) {
        g_gamepad_axis_fn(leftX, leftY, rightX, rightY, leftTrigger, rightTrigger);
    }
}

JNIEXPORT void JNICALL Java_com_projectigi_app_NativeEngine_nativeOnGamepadConnected
  (JNIEnv *env, jclass clazz, jboolean connected) {
    if (g_gamepad_connected_fn) {
        g_gamepad_connected_fn(connected ? 1 : 0);
    }
}

JNIEXPORT void JNICALL Java_com_projectigi_app_NativeEngine_nativeOnText
  (JNIEnv *env, jclass clazz, jstring text) {
    if (g_text_fn && text != nullptr) {
        const char* utf8 = env->GetStringUTFChars(text, nullptr);
        if (utf8 != nullptr) {
            g_text_fn(utf8);
            env->ReleaseStringUTFChars(text, utf8);
        }
    }
}

JNIEXPORT jboolean JNICALL Java_com_projectigi_app_NativeEngine_nativeIsMicrophoneRequested
  (JNIEnv *env, jclass clazz) {
    if (g_microphone_requested_fn) {
        return g_microphone_requested_fn() != 0 ? JNI_TRUE : JNI_FALSE;
    }
    return JNI_FALSE;
}

JNIEXPORT void JNICALL Java_com_projectigi_app_NativeEngine_nativeShutdown
  (JNIEnv *env, jclass clazz) {
    LOGI("nativeShutdown");
    if (g_stop_fn) {
        g_stop_fn();
    }
    if (g_game_thread.joinable()) {
        g_game_thread.join();
    }
    if (g_native_window) {
        ANativeWindow_release(g_native_window);
        g_native_window = nullptr;
    }
}



} // extern "C"
