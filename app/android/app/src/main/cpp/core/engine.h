#pragma once

#include <android/native_window.h>
#include <chrono>
#include <atomic>
#include <memory>
#include <GLES3/gl3.h>

namespace openigi {

enum class EngineState {
    Uninitialized,
    Loading,
    Running,
    Paused,
    Terminated
};

class Engine {
public:
    static Engine& instance();

    bool initialize(ANativeWindow* window);
    void shutdown();

    void onSurfaceCreated(ANativeWindow* window);
    void onSurfaceChanged(int width, int height);
    void onSurfaceDestroyed();

    void onPause();
    void onResume();

    // Advances one simulation tick and renders frame
    void step();

    EngineState getState() const { return state_; }
    void setBackdropTexture(GLuint texId) { backdropTexture_ = texId; }

    void setCheatGodMode(bool enable) { godMode_ = enable; }
    void setCheatInfiniteAmmo(bool enable) { infiniteAmmo_ = enable; }
    void setCheatAllWeapons(bool enable) { allWeapons_ = enable; }

private:
    Engine();
    ~Engine();
    Engine(const Engine&) = delete;
    Engine& operator=(const Engine&) = delete;

    void updateSimulation(float fixedDelta);
    void render();

    std::atomic<EngineState> state_{EngineState::Uninitialized};

    int viewportWidth_{1280};
    int viewportHeight_{720};

    // Deterministic 30 Hz Simulation Clock
    static constexpr float kFixedSimulationDt = 1.0f / 30.0f;
    float simulationAccumulator_{0.0f};
    std::chrono::steady_clock::time_point lastFrameTime_;

    float playerHealth_{100.0f};
    float playerAmmo_{30.0f};
    int currentWeapon_{1};
    float loadingProgress_{0.0f};
    GLuint backdropTexture_{0};

    // Cheats
    bool godMode_{false};
    bool infiniteAmmo_{false};
    bool allWeapons_{false};
};

} // namespace openigi
