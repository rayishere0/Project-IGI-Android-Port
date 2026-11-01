#pragma once

#include <vector>
#include <mutex>
#include <unordered_map>
#include <cstdint>

namespace projectigi {

enum class TouchAction : int {
    Down = 0,
    Up = 1,
    Move = 2,
    Cancel = 3,
    PointerDown = 5,
    PointerUp = 6
};

struct TouchEvent {
    int pointerId{0};
    TouchAction action{TouchAction::Down};
    float x{0.0f};
    float y{0.0f};
    uint64_t timestampNs{0};
};

struct TouchPointer {
    int id{0};
    float startX{0.0f};
    float startY{0.0f};
    float currentX{0.0f};
    float currentY{0.0f};
    float deltaX{0.0f};
    float deltaY{0.0f};
    uint64_t startTimeNs{0};
    bool isDown{false};
    bool isDragging{false};
};

struct GestureState {
    bool tapDetected{false};
    float tapX{0.0f};
    float tapY{0.0f};

    bool dragDetected{false};
    float dragDeltaX{0.0f};
    float dragDeltaY{0.0f};

    bool pinchDetected{false};
    float pinchScaleDelta{0.0f}; // > 0 zoom in, < 0 zoom out

    // Virtual Dual-Stick controls for mobile FPS gameplay
    float moveStickX{0.0f}; // -1.0f (left) to 1.0f (right)
    float moveStickY{0.0f}; // -1.0f (back) to 1.0f (forward)
    float lookDeltaX{0.0f}; // camera yaw change
    float lookDeltaY{0.0f}; // camera pitch change
    bool fireButtonPressed{false};
};

class InputManager {
public:
    static InputManager& instance();

    // Called from JNI thread (Thread-safe)
    void postTouchEvent(int pointerId, int action, float x, float y);

    // Called from Engine / Render Thread
    void update(float deltaTime, int viewportWidth, int viewportHeight);

    const GestureState& getGestures() const { return currentGestures_; }

    void setTouchSensitivity(float sensitivity) { touchSensitivity_ = sensitivity; }
    float getTouchSensitivity() const { return touchSensitivity_; }

    void reset();

private:
    InputManager() = default;
    ~InputManager() = default;
    InputManager(const InputManager&) = delete;
    InputManager& operator=(const InputManager&) = delete;

    std::mutex queueMutex_;
    std::vector<TouchEvent> pendingQueue_;
    std::vector<TouchEvent> processingQueue_;

    std::unordered_map<int, TouchPointer> activePointers_;
    GestureState currentGestures_;

    float touchSensitivity_{1.0f};
    float initialPinchDistance_{0.0f};
    bool isPinching_{false};
};

} // namespace projectigi

