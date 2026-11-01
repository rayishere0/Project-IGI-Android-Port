#pragma once

#include <android/asset_manager.h>
#include <android/asset_manager_jni.h>
#include <string>
#include <vector>
#include <memory>
#include <mutex>

namespace projectigi {

class AssetManager {
public:
    static AssetManager& instance();

    bool initialize(AAssetManager* mgr, const std::string& internalPath);
    void shutdown();

    bool fileExists(const std::string& path);
    std::vector<uint8_t> readBytes(const std::string& path);
    std::string readText(const std::string& path);
    
    // Direct stream access for streaming larger game files (e.g., .data, .wav)
    AAsset* openAsset(const std::string& path, int mode = AASSET_MODE_BUFFER);
    void closeAsset(AAsset* asset);

    const std::string& getInternalPath() const { return internalDataPath_; }

private:
    AssetManager() = default;
    ~AssetManager() = default;
    AssetManager(const AssetManager&) = delete;
    AssetManager& operator=(const AssetManager&) = delete;

    std::string resolvePath(const std::string& rawPath);

    AAssetManager* assetManager_{nullptr};
    std::string internalDataPath_;
    std::mutex mutex_;
};

} // namespace projectigi

