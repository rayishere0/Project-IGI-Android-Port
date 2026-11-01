#include "engine.h"
#include "egl_manager.h"
#include "gles3_renderer.h"
#include "input_manager.h"
#include "asset_manager.h"
#include <android/log.h>
#include <algorithm>

#define LOG_TAG "ProjectIGI-Engine"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

namespace projectigi {

Engine& Engine::instance() {
    static Engine instance;
    return instance;
}

Engine::Engine() {
    lastFrameTime_ = std::chrono::steady_clock::now();
}

Engine::~Engine() {
    shutdown();
}

bool Engine::initialize(ANativeWindow* window) {
    LOGI("Initializing native ProjectIGI Engine...");

    if (!EglManager::instance().createEGL(window)) {
        LOGE("Failed to create EGL context");
        return false;
    }

    viewportWidth_ = EglManager::instance().getWidth();
    viewportHeight_ = EglManager::instance().getHeight();

    if (!Gles3Renderer::instance().initialize(viewportWidth_, viewportHeight_)) {
        LOGE("Failed to initialize OpenGL ES 3.0 Renderer");
        return false;
    }

    lastFrameTime_ = std::chrono::steady_clock::now();
    simulationAccumulator_ = 0.0f;
    loadingProgress_ = 0.0f;
    state_ = EngineState::Loading;

    LOGI("ProjectIGI Native Engine successfully initialized (%dx%d)", viewportWidth_, viewportHeight_);
    return true;
}

void Engine::shutdown() {
    if (state_ == EngineState::Terminated) return;

    LOGI("Shutting down native ProjectIGI Engine...");
    state_ = EngineState::Terminated;

    Gles3Renderer::instance().shutdown();
    EglManager::instance().destroyEGL();
    InputManager::instance().reset();
    AssetManager::instance().shutdown();

    LOGI("ProjectIGI Native Engine shut down.");
}

void Engine::onSurfaceCreated(ANativeWindow* window) {
    LOGI("onSurfaceCreated called");
    if (state_ == EngineState::Uninitialized || state_ == EngineState::Terminated) {
        initialize(window);
    } else {
        EglManager::instance().onResume(window);
        Gles3Renderer::instance().initialize(EglManager::instance().getWidth(), EglManager::instance().getHeight());
    }
}

void Engine::onSurfaceChanged(int width, int height) {
    LOGI("onSurfaceChanged: %dx%d", width, height);
    if (width > 0 && height > 0) {
        viewportWidth_ = width;
        viewportHeight_ = height;
        Gles3Renderer::instance().resize(width, height);
    }
}

void Engine::onSurfaceDestroyed() {
    LOGI("onSurfaceDestroyed called");
    EglManager::instance().onPause();
}

void Engine::onPause() {
    LOGI("Engine paused");
    if (state_ == EngineState::Running) {
        state_ = EngineState::Paused;
    }
    EglManager::instance().onPause();
}

void Engine::onResume() {
    LOGI("Engine resumed");
    lastFrameTime_ = std::chrono::steady_clock::now();
    if (state_ == EngineState::Paused) {
        state_ = EngineState::Running;
    }
}

void Engine::updateSimulation(float fixedDelta) {
    const auto& gestures = InputManager::instance().getGestures();

    if (gestures.tapDetected) {
        if (!infiniteAmmo_) {
            playerAmmo_ = std::max(0.0f, playerAmmo_ - 1.0f);
        }
    }

    if (godMode_) {
        playerHealth_ = 100.0f;
    }

    if (state_ == EngineState::Loading) {
        loadingProgress_ += fixedDelta * 0.35f; // Smooth progression
        if (loadingProgress_ >= 1.0f) {
            loadingProgress_ = 1.0f;
            state_ = EngineState::Running;
            LOGI("Loading complete! Entering Running state.");
        }
    }
}

void Engine::render() {
    Gles3Renderer& renderer = Gles3Renderer::instance();
    renderer.beginFrame();

    const auto& gestures = InputManager::instance().getGestures();

    if (state_ == EngineState::Loading) {
        // Draw Authentic Project IGI Loading Screen with progress bar and optional backdrop texture
        renderer.drawLoadingScreen(loadingProgress_, backdropTexture_);
    } else {
        // In-Game Tactical World / HUD
        // 1. Tactical dark green backdrop
        renderer.drawColorRect(0.0f, 0.0f, (float)viewportWidth_, (float)viewportHeight_, 
                              0.03f, 0.08f, 0.05f, 1.0f);

        // 2. Tactical Corner Brackets
        float bLen = 36.0f;
        float bThick = 3.0f;
        float greenR = 0.24f, greenG = 0.95f, greenB = 0.42f;
        float w = (float)viewportWidth_;
        float h = (float)viewportHeight_;
        renderer.drawColorRect(16.0f, 16.0f, bLen, bThick, greenR, greenG, greenB, 1.0f);
        renderer.drawColorRect(16.0f, 16.0f, bThick, bLen, greenR, greenG, greenB, 1.0f);
        renderer.drawColorRect(w - 16.0f - bLen, 16.0f, bLen, bThick, greenR, greenG, greenB, 1.0f);
        renderer.drawColorRect(w - 16.0f - bThick, 16.0f, bThick, bLen, greenR, greenG, greenB, 1.0f);

        // 3. Central Sniper / Tactical Crosshair
        float cx = viewportWidth_ * 0.5f;
        float cy = viewportHeight_ * 0.5f;
        float crossArm = 20.0f;
        renderer.drawColorRect(cx - crossArm, cy - 1.5f, crossArm * 2.0f, 3.0f, 0.24f, 0.95f, 0.42f, 0.9f);
        renderer.drawColorRect(cx - 1.5f, cy - crossArm, 3.0f, crossArm * 2.0f, 0.24f, 0.95f, 0.42f, 0.9f);

        // 4. Tactical HUD: Health and Ammo
        renderer.drawTacticalHud(playerHealth_, playerAmmo_, currentWeapon_, infiniteAmmo_, godMode_);

        // 5. Virtual Touch Controls Overlay
        renderer.drawVirtualTouchControls(gestures.moveStickX, gestures.moveStickY, 
                                          std::abs(gestures.moveStickX) > 0.05f || std::abs(gestures.moveStickY) > 0.05f,
                                          0.0f, 0.0f, gestures.lookDeltaX != 0.0f || gestures.lookDeltaY != 0.0f);
    }

    renderer.endFrame();
    EglManager::instance().swapBuffers();
}

void Engine::step() {
    if (state_ == EngineState::Uninitialized || state_ == EngineState::Terminated || state_ == EngineState::Paused) {
        return;
    }

    if (!EglManager::instance().isReady()) {
        return;
    }

    auto now = std::chrono::steady_clock::now();
    float dt = std::chrono::duration<float>(now - lastFrameTime_).count();
    lastFrameTime_ = now;
    dt = std::min(dt, 0.1f);

    // 1. Update Input Subsystem
    InputManager::instance().update(dt, viewportWidth_, viewportHeight_);

    // 2. Fixed-timestep 30 Hz simulation accumulation
    simulationAccumulator_ += dt;
    while (simulationAccumulator_ >= kFixedSimulationDt) {
        updateSimulation(kFixedSimulationDt);
        simulationAccumulator_ -= kFixedSimulationDt;
    }

    // 3. Render frame
    render();
}

} // namespace projectigi
