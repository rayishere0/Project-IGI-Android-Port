#include "input_manager.h"
#include <chrono>
#include <cmath>
#include <android/log.h>

#define LOG_TAG "OpenIGI-Input"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

namespace openigi {

InputManager& InputManager::instance() {
    static InputManager instance;
    return instance;
}

void InputManager::postTouchEvent(int pointerId, int action, float x, float y) {
    auto now = std::chrono::steady_clock::now();
    uint64_t timestamp = std::chrono::duration_cast<std::chrono::nanoseconds>(now.time_since_epoch()).count();

    TouchEvent evt;
    evt.pointerId = pointerId;
    evt.action = static_cast<TouchAction>(action);
    evt.x = x;
    evt.y = y;
    evt.timestampNs = timestamp;

    std::lock_guard<std::mutex> lock(queueMutex_);
    pendingQueue_.push_back(evt);
}

void InputManager::reset() {
    std::lock_guard<std::mutex> lock(queueMutex_);
    pendingQueue_.clear();
    processingQueue_.clear();
    activePointers_.clear();
    currentGestures_ = GestureState();
    isPinching_ = false;
}

void InputManager::update(float deltaTime, int viewportWidth, int viewportHeight) {
    // 1. Drain pending queue from JNI thread into processing queue
    {
        std::lock_guard<std::mutex> lock(queueMutex_);
        if (!pendingQueue_.empty()) {
            processingQueue_.insert(processingQueue_.end(), pendingQueue_.begin(), pendingQueue_.end());
            pendingQueue_.clear();
        }
    }

    // Reset per-frame impulse gestures
    currentGestures_.tapDetected = false;
    currentGestures_.dragDetected = false;
    currentGestures_.pinchDetected = false;
    currentGestures_.lookDeltaX = 0.0f;
    currentGestures_.lookDeltaY = 0.0f;
    currentGestures_.dragDeltaX = 0.0f;
    currentGestures_.dragDeltaY = 0.0f;
    currentGestures_.pinchScaleDelta = 0.0f;

    const float tapMaxDistance = 20.0f;
    const uint64_t tapMaxDurationNs = 350000000ULL; // 350ms
    const float halfWidth = viewportWidth > 0 ? viewportWidth * 0.5f : 640.0f;

    // 2. Process all events sequentially
    for (const auto& evt : processingQueue_) {
        switch (evt.action) {
            case TouchAction::Down:
            case TouchAction::PointerDown: {
                TouchPointer ptr;
                ptr.id = evt.pointerId;
                ptr.startX = evt.x;
                ptr.startY = evt.y;
                ptr.currentX = evt.x;
                ptr.currentY = evt.y;
                ptr.deltaX = 0.0f;
                ptr.deltaY = 0.0f;
                ptr.startTimeNs = evt.timestampNs;
                ptr.isDown = true;
                ptr.isDragging = false;
                activePointers_[evt.pointerId] = ptr;
                break;
            }

            case TouchAction::Move: {
                auto it = activePointers_.find(evt.pointerId);
                if (it != activePointers_.end()) {
                    float dx = evt.x - it->second.currentX;
                    float dy = evt.y - it->second.currentY;
                    it->second.deltaX = dx;
                    it->second.deltaY = dy;
                    it->second.currentX = evt.x;
                    it->second.currentY = evt.y;

                    float distFromStart = std::hypot(evt.x - it->second.startX, evt.y - it->second.startY);
                    if (distFromStart > tapMaxDistance) {
                        it->second.isDragging = true;
                    }

                    // Feed drag gestures
                    currentGestures_.dragDetected = true;
                    currentGestures_.dragDeltaX += dx;
                    currentGestures_.dragDeltaY += dy;

                    // Camera Look on Right Half of Screen
                    if (it->second.startX >= halfWidth) {
                        currentGestures_.lookDeltaX += dx * touchSensitivity_;
                        currentGestures_.lookDeltaY += dy * touchSensitivity_;
                    } 
                    // Movement Stick on Left Half of Screen
                    else {
                        float stickRange = 100.0f;
                        float stickDx = it->second.currentX - it->second.startX;
                        float stickDy = it->second.currentY - it->second.startY;
                        currentGestures_.moveStickX = std::clamp(stickDx / stickRange, -1.0f, 1.0f);
                        currentGestures_.moveStickY = std::clamp(-stickDy / stickRange, -1.0f, 1.0f); // Up is positive
                    }
                }
                break;
            }

            case TouchAction::Up:
            case TouchAction::PointerUp: {
                auto it = activePointers_.find(evt.pointerId);
                if (it != activePointers_.end()) {
                    uint64_t duration = evt.timestampNs - it->second.startTimeNs;
                    float dist = std::hypot(evt.x - it->second.startX, evt.y - it->second.startY);

                    // Check for clean Tap
                    if (!it->second.isDragging && dist < tapMaxDistance && duration < tapMaxDurationNs) {
                        currentGestures_.tapDetected = true;
                        currentGestures_.tapX = evt.x;
                        currentGestures_.tapY = evt.y;
                    }

                    // Reset movement stick if this pointer was the left-side stick
                    if (it->second.startX < halfWidth) {
                        currentGestures_.moveStickX = 0.0f;
                        currentGestures_.moveStickY = 0.0f;
                    }

                    activePointers_.erase(it);
                }
                break;
            }

            case TouchAction::Cancel: {
                activePointers_.clear();
                currentGestures_.moveStickX = 0.0f;
                currentGestures_.moveStickY = 0.0f;
                isPinching_ = false;
                break;
            }
        }
    }
    processingQueue_.clear();

    // 3. Pinch detection if 2 active pointers exist
    if (activePointers_.size() >= 2) {
        auto it1 = activePointers_.begin();
        auto it2 = std::next(it1);
        float currentDist = std::hypot(it1->second.currentX - it2->second.currentX,
                                       it1->second.currentY - it2->second.currentY);
        if (!isPinching_) {
            isPinching_ = true;
            initialPinchDistance_ = currentDist;
        } else {
            float deltaDist = currentDist - initialPinchDistance_;
            if (std::abs(deltaDist) > 10.0f) {
                currentGestures_.pinchDetected = true;
                currentGestures_.pinchScaleDelta = deltaDist / 200.0f;
                initialPinchDistance_ = currentDist;
            }
        }
    } else {
        isPinching_ = false;
    }
}

} // namespace openigi

