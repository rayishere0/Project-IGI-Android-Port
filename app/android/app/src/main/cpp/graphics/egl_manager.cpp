#include "egl_manager.h"
#include <android/log.h>

#define LOG_TAG "ProjectIGI-EGL"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

namespace projectigi {

EglManager& EglManager::instance() {
    static EglManager instance;
    return instance;
}

bool EglManager::createEGL(ANativeWindow* window) {
    std::lock_guard<std::mutex> lock(eglMutex_);
    if (!window) {
        LOGE("createEGL called with null ANativeWindow");
        return false;
    }

    window_ = window;

    // 1. Get default display
    display_ = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    if (display_ == EGL_NO_DISPLAY) {
        LOGE("eglGetDisplay failed: 0x%x", eglGetError());
        return false;
    }

    // 2. Initialize display
    EGLint major, minor;
    if (!eglInitialize(display_, &major, &minor)) {
        LOGE("eglInitialize failed: 0x%x", eglGetError());
        return false;
    }
    LOGI("EGL initialized: major %d, minor %d", major, minor);

    // 3. Choose configuration for OpenGL ES 3.0
    const EGLint attribs[] = {
        EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
        EGL_BLUE_SIZE, 8,
        EGL_GREEN_SIZE, 8,
        EGL_RED_SIZE, 8,
        EGL_DEPTH_SIZE, 16,
        EGL_RENDERABLE_TYPE, EGL_OPENGL_ES3_BIT,
        EGL_NONE
    };

    EGLint numConfigs = 0;
    if (!eglChooseConfig(display_, attribs, &config_, 1, &numConfigs) || numConfigs <= 0) {
        LOGE("eglChooseConfig failed: 0x%x", eglGetError());
        return false;
    }

    // Match Android native window format to EGL config
    EGLint visualId = 0;
    eglGetConfigAttrib(display_, config_, EGL_NATIVE_VISUAL_ID, &visualId);
    ANativeWindow_setBuffersGeometry(window_, 0, 0, visualId);

    // 4. Create OpenGL ES 3.0 context
    const EGLint contextAttribs[] = {
        EGL_CONTEXT_CLIENT_VERSION, 3,
        EGL_NONE
    };
    context_ = eglCreateContext(display_, config_, EGL_NO_CONTEXT, contextAttribs);
    if (context_ == EGL_NO_CONTEXT) {
        LOGE("eglCreateContext failed: 0x%x", eglGetError());
        return false;
    }

    // 5. Create Window Surface
    surface_ = eglCreateWindowSurface(display_, config_, window_, nullptr);
    if (surface_ == EGL_NO_SURFACE) {
        LOGE("eglCreateWindowSurface failed: 0x%x", eglGetError());
        return false;
    }

    // 6. Bind context to the calling render thread
    if (!eglMakeCurrent(display_, surface_, surface_, context_)) {
        LOGE("eglMakeCurrent failed: 0x%x", eglGetError());
        return false;
    }

    eglQuerySurface(display_, surface_, EGL_WIDTH, &width_);
    eglQuerySurface(display_, surface_, EGL_HEIGHT, &height_);
    LOGI("EGL Surface successfully created and made current: %dx%d", width_, height_);

    return true;
}

void EglManager::destroyEGL() {
    std::lock_guard<std::mutex> lock(eglMutex_);
    if (display_ != EGL_NO_DISPLAY) {
        eglMakeCurrent(display_, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        if (surface_ != EGL_NO_SURFACE) {
            eglDestroySurface(display_, surface_);
            surface_ = EGL_NO_SURFACE;
        }
        if (context_ != EGL_NO_CONTEXT) {
            eglDestroyContext(display_, context_);
            context_ = EGL_NO_CONTEXT;
        }
        eglTerminate(display_);
        display_ = EGL_NO_DISPLAY;
    }
    window_ = nullptr;
    width_ = 0;
    height_ = 0;
    LOGI("EGL successfully destroyed.");
}

bool EglManager::makeCurrent() {
    std::lock_guard<std::mutex> lock(eglMutex_);
    if (display_ == EGL_NO_DISPLAY || surface_ == EGL_NO_SURFACE || context_ == EGL_NO_CONTEXT) {
        return false;
    }
    if (eglMakeCurrent(display_, surface_, surface_, context_) != EGL_TRUE) {
        LOGE("eglMakeCurrent failed in makeCurrent(): 0x%x", eglGetError());
        return false;
    }
    return true;
}

void EglManager::swapBuffers() {
    std::lock_guard<std::mutex> lock(eglMutex_);
    if (display_ != EGL_NO_DISPLAY && surface_ != EGL_NO_SURFACE) {
        if (!eglSwapBuffers(display_, surface_)) {
            LOGE("eglSwapBuffers failed: 0x%x", eglGetError());
        }
    }
}

void EglManager::onPause() {
    std::lock_guard<std::mutex> lock(eglMutex_);
    if (display_ != EGL_NO_DISPLAY) {
        eglMakeCurrent(display_, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        if (surface_ != EGL_NO_SURFACE) {
            eglDestroySurface(display_, surface_);
            surface_ = EGL_NO_SURFACE;
            LOGI("EGL Surface destroyed for pause.");
        }
    }
}

void EglManager::onResume(ANativeWindow* window) {
    std::lock_guard<std::mutex> lock(eglMutex_);
    if (!window || display_ == EGL_NO_DISPLAY || context_ == EGL_NO_CONTEXT) {
        return;
    }
    window_ = window;
    EGLint visualId = 0;
    eglGetConfigAttrib(display_, config_, EGL_NATIVE_VISUAL_ID, &visualId);
    ANativeWindow_setBuffersGeometry(window_, 0, 0, visualId);

    surface_ = eglCreateWindowSurface(display_, config_, window_, nullptr);
    if (surface_ != EGL_NO_SURFACE) {
        eglMakeCurrent(display_, surface_, surface_, context_);
        eglQuerySurface(display_, surface_, EGL_WIDTH, &width_);
        eglQuerySurface(display_, surface_, EGL_HEIGHT, &height_);
        LOGI("EGL Surface restored for resume: %dx%d", width_, height_);
    } else {
        LOGE("Failed to recreate EGL surface on resume: 0x%x", eglGetError());
    }
}

} // namespace projectigi
