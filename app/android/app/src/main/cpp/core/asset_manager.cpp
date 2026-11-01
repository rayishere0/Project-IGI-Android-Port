#include "asset_manager.h"
#include <android/log.h>
#include <fstream>

#define LOG_TAG "ProjectIGI-AssetManager"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

namespace projectigi {

AssetManager& AssetManager::instance() {
    static AssetManager instance;
    return instance;
}

bool AssetManager::initialize(AAssetManager* mgr, const std::string& internalPath) {
    std::lock_guard<std::mutex> lock(mutex_);
    assetManager_ = mgr;
    internalDataPath_ = internalPath;
    LOGI("Native AssetManager initialized. Internal path: %s", internalPath.c_str());
    return assetManager_ != nullptr;
}

void AssetManager::shutdown() {
    std::lock_guard<std::mutex> lock(mutex_);
    assetManager_ = nullptr;
    internalDataPath_.clear();
    LOGI("Native AssetManager shut down.");
}

std::string AssetManager::resolvePath(const std::string& rawPath) {
    // Strip leading slashes
    std::string path = rawPath;
    while (!path.empty() && (path.front() == '/' || path.front() == '\\')) {
        path.erase(0, 1);
    }
    return path;
}

bool AssetManager::fileExists(const std::string& path) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!assetManager_) {
        return false;
    }

    std::string clean = resolvePath(path);
    
    // Candidates to search within assets
    std::vector<std::string> candidates = {
        clean,
        "public/" + clean,
        "Project IGI/" + clean,
        "public/Project IGI/" + clean
    };

    for (const auto& candidate : candidates) {
        AAsset* asset = AAssetManager_open(assetManager_, candidate.c_str(), AASSET_MODE_UNKNOWN);
        if (asset) {
            AAsset_close(asset);
            return true;
        }
    }

    return false;
}

std::vector<uint8_t> AssetManager::readBytes(const std::string& path) {
    std::lock_guard<std::mutex> lock(mutex_);
    std::vector<uint8_t> buffer;
    if (!assetManager_) {
        LOGE("AAssetManager is null, cannot read: %s", path.c_str());
        return buffer;
    }

    std::string clean = resolvePath(path);
    std::vector<std::string> candidates = {
        clean,
        "public/" + clean,
        "Project IGI/" + clean,
        "public/Project IGI/" + clean
    };

    AAsset* asset = nullptr;
    for (const auto& candidate : candidates) {
        asset = AAssetManager_open(assetManager_, candidate.c_str(), AASSET_MODE_BUFFER);
        if (asset) {
            break;
        }
    }

    if (!asset) {
        LOGW("Failed to locate asset: %s", path.c_str());
        return buffer;
    }

    off_t size = AAsset_getLength(asset);
    if (size > 0) {
        buffer.resize(static_cast<size_t>(size));
        int readBytes = AAsset_read(asset, buffer.data(), buffer.size());
        if (readBytes < 0) {
            LOGE("Error reading asset bytes for %s", path.c_str());
            buffer.clear();
        }
    }

    AAsset_close(asset);
    return buffer;
}

std::string AssetManager::readText(const std::string& path) {
    auto bytes = readBytes(path);
    if (bytes.empty()) {
        return "";
    }
    return std::string(bytes.begin(), bytes.end());
}

AAsset* AssetManager::openAsset(const std::string& path, int mode) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!assetManager_) {
        return nullptr;
    }

    std::string clean = resolvePath(path);
    std::vector<std::string> candidates = {
        clean,
        "public/" + clean,
        "Project IGI/" + clean,
        "public/Project IGI/" + clean
    };

    for (const auto& candidate : candidates) {
        AAsset* asset = AAssetManager_open(assetManager_, candidate.c_str(), mode);
        if (asset) {
            return asset;
        }
    }
    return nullptr;
}

void AssetManager::closeAsset(AAsset* asset) {
    if (asset) {
        AAsset_close(asset);
    }
}

} // namespace projectigi

