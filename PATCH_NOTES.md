# Project I.G.I. Android Port - Patch Notes

## Version 1.0.0 (Release Build)

### 🛡️ Copyright Compliance & External Game Loader
- **Decoupled Game Files**: Completely removed all copyrighted retail game assets from the repository and APK bundle.
- **Storage Access Framework (SAF) Launcher**:
  - Built a custom launcher screen in `MainActivity.java` utilizing the `src/img.png` splash artwork.
  - Added **"SELECT GAME FOLDER"** button allowing users to locate their authentic PC installation directory of *Project I.G.I.* (2000).
  - Automatically verifies folder signatures (`common/`, `missions/`, `weapons/`, `menusystem/`, `sounds/`, `humanplayer/`, `config.qvm`, `IGI.exe`) before enabling the **"PLAY"** button.

### 🎮 Gameplay & Control Enhancements
- **Touch Pause System**: Tapping the `||` touch button on the HUD instantly pauses game simulation, AI updates, and audio playback.
- **Subtle Cheats Gear Icon**: Replaced the bulky main-menu cheats box with a compact top-right gear icon. Tapping opens an on-demand modal for:
  - **Infinite Health**
  - **Infinite Ammunition**
  - **All Weapons**
- **30 FPS Target Frame Pacer**: Default frame rate capped at 30 FPS for smooth, thermal-stable, battery-friendly mobile performance.

### 🎬 Cutscene & Audio Polish
- **Dialogue Audio Clarity**: Background mission music automatically mutes during cutscenes for clear dialogue playback.
- **Cutscene Skip Rules**: Mid-mission cutscenes feature an interactive hold-to-skip prompt, while post-mission clearance cutscenes play cleanly without prompts.

### ⚙️ Graphics & Rendering Compatibility
- **Universal GPU Support**: Relaxed EGL context attributes to ensure 100% compatibility across ARM Mali, MediaTek, and Qualcomm Adreno GPUs.
- **Vulkan 1.1 / GLES 3.0 RHI**: Native C++ JNI bridge compiled with symbol obfuscation (`-fvisibility=hidden -Wl,--exclude-libs,ALL`).
