#pragma once

#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES3/gl3.h>
#include <android/native_window.h>
#include <mutex>

namespace openigi {

class EglManager {
public:
    static EglManager& instance();

    bool createEGL(ANativeWindow* window);
    void destroyEGL();

    bool makeCurrent();
    void swapBuffers();

    void onPause();
    void onResume(ANativeWindow* window);

    bool isReady() const { return display_ != EGL_NO_DISPLAY && surface_ != EGL_NO_SURFACE && context_ != EGL_NO_CONTEXT; }

    int getWidth() const { return width_; }
    int getHeight() const { return height_; }

private:
    EglManager() = default;
    ~EglManager() { destroyEGL(); }
    EglManager(const EglManager&) = delete;
    EglManager& operator=(const EglManager&) = delete;

    EGLDisplay display_{EGL_NO_DISPLAY};
    EGLConfig config_{nullptr};
    EGLSurface surface_{EGL_NO_SURFACE};
    EGLContext context_{EGL_NO_CONTEXT};
    ANativeWindow* window_{nullptr};

    int width_{0};
    int height_{0};
    std::mutex eglMutex_;
};

} // namespace openigi

