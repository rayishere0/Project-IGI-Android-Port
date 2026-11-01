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

static void* g_coreclr_lib = nullptr;
static void* g_host_handle = nullptr;
static unsigned int g_domain_id = 0;

static RunFn g_run_fn = nullptr;
static TouchFn g_touch_fn = nullptr;
static KeyFn g_key_fn = nullptr;
static ResizeFn g_resize_fn = nullptr;
static StopFn g_stop_fn = nullptr;

static std::thread g_game_thread;
static std::atomic<bool> g_game_running{false};
static ANativeWindow* g_native_window = nullptr;

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
        LOGI("Game thread started. Entering ProjectIGI managed game host via Vulkan (%dx%d)...", landscapeWidth, landscapeHeight);
        int exitCode = g_run_fn((intptr_t)g_native_window, landscapeWidth, landscapeHeight, (intptr_t)dataDir.c_str(), (intptr_t)options.c_str());
        LOGI("ProjectIGI managed game loop ended with exit code: %d", exitCode);
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
