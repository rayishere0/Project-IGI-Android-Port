# Project I.G.I.: I'm Going In (Native Android Engine)

A ground-up, high-performance native Android port of the classic tactical stealth first-person shooter **Project I.G.I.: I'm Going In** (2000).

<img width="1024" height="1024" alt="image" src="https://github.com/user-attachments/assets/95963bea-95a6-4048-8d92-259b3e301c6c" />

This project runs the complete game natively on Android ARM64 devices (`com.projectigi.app`) without emulation or compatibility layers, combining an embedded **.NET 10.0 CoreCLR** runtime, **Vulkan 1.1** graphics, and **OpenAL Soft** spatial audio with authentic retail game logic, assets, and QVM menu system.

---

## User Instructions (How to Play)

For copyright compliance, this APK contains **no copyrighted game data**. To play the game:

1. **Install the APK** on your Android device (ARM64 device running Android 7.0+).
2. **Copy your PC Game Folder** to your Android device storage (e.g., in `/sdcard/Download/Project IGI`). Your game directory must contain the original PC game folders (`common/`, `missions/`, `weapons/`, `menusystem/`, `sounds/`, `humanplayer/`, `config.qvm`, `IGI.exe`).
3. **Launch Project I.G.I.** on your device.
4. On the launcher splash screen, tap **`SELECT GAME FOLDER`**.
5. Select your copied game folder using Android's system file picker.
6. The app will automatically verify the game file structure and enable the **`PLAY`** button.
7. Tap **`PLAY`** to launch into the game!

---

## Architecture: How It's Made & How It Runs

```
┌─────────────────────────────────────────────────────────────┐
│                    Android Application                      │
│            (MainActivity.java / SurfaceView)                │
└──────────────────────────────┬──────────────────────────────┘
                               │ JNI (ANativeWindow)
┌──────────────────────────────▼──────────────────────────────┐
│                    Native Bridge (C++)                      │
│      (libprojectigi.so + libopenal.so via OpenSL ES)        │
└──────────────────────────────┬──────────────────────────────┘
                               │ coreclr_initialize / delegates
┌──────────────────────────────▼──────────────────────────────┐
│             Embedded .NET 10.0 ARM64 Runtime                │
│                (ProjectIGI.Android.dll)                     │
├──────────────────────────────┬──────────────────────────────┤
│ Vulkan 1.1 Render Pipeline   │ OpenAL Soft 3D Audio Engine  │
│ Multi-Touch Input System     │ Pure C# VFS & IFF Decoders   │
│ Authentic I.G.I. AI Engine   │ Retail QVM Virtual Machine   │
└──────────────────────────────┴──────────────────────────────┘
```

1. **Android Shell (`app/android`)**:
   - `MainActivity.java` creates an immersive fullscreen `SurfaceView` and hands its `ANativeWindow` handle down to native C++ via JNI.
   - Includes a standalone SAF game folder selector and verifier to load external authentic game files.

2. **Native Layer (`app/android/app/src/main/cpp`)**:
   - `jni_bridge.cpp` boots the embedded .NET CoreCLR host, passes display parameters, and registers low-latency touch and keyboard callbacks.
   - Compiled with symbol obfuscation (`-fvisibility=hidden -Wl,--exclude-libs,ALL`) to strip internal NDK function signatures.
   - Integrates **OpenAL Soft 1.23.1** compiled natively for Android ARM64 with the `OpenSL ES` backend for low-latency 3D positional audio.

3. **Engine Core (`src/`)**:
   - **`ProjectIGI.Rendering.Vulkan`**: Low-overhead Vulkan 1.1 renderer utilizing ANativeWindow surfaceKHR, optimized forward rendering, baked lightmaps, and high-performance 2D sprite batching.
   - **`ProjectIGI.Game.Igi1`**: Full re-implementation of original Project I.G.I. game logic — guard AI perception/patrol paths, alarms, security cameras, weapon ballistics, bullet penetration, inventory, and health mechanics.
   - **`ProjectIGI.Presentation.Igi1`**: Executes original `mainmenu.qvm` bytecode directly, reproducing the authentic retail menu, mission selector, and debriefing screens.
   - **`ProjectIGI.Audio.OpenAL`**: Drives dynamic environmental reverb, directional footsteps, alarms, and weapon acoustics.

---

## Key Features & Current Build Highlights

- **Decoupled Game Files**: 100% clean repository and APK with no bundled copyrighted game data.
- **Optimized 30 FPS Target Pacing**: Frame loop pacer strictly enforces a **30 FPS** target frame limit by default for smooth battery-friendly mobile gameplay.
- **Authentic Retail Experience**: Includes all 14 campaign missions, cutscenes, briefing audio, textures, weapon models, sound effects, and retail menu screens.
- **Responsive Touch HUD & Controls**:
  - Full multi-touch overlay with dual-stick movement, aiming, crouch, jump, reload, scope, and weapon selection.
  - Interactive **Pause Button (`||`)** that instantly halts game simulation, AI, and level updates.
- **Gamepad / Controller Support**:
  - Xbox, PlayStation and generic Android controllers work in menus and in missions — see [Controller Support](#controller-support) below.
  - While a controller is connected the on-screen touch controls hide; unplug it and they come straight back.
- **Clean Cutscene Audio & Skip Rules**:
  - Mission background music automatically pauses during cutscenes for crisp dialogue playback.
  - Interactive hold-to-skip ring for mid-mission cutscenes; post-mission completion cutscenes run unprompted for clean cinematic transitions.
- **Subtle Cheats Gear Icon**: A compact, unobtrusive gear icon on the main menu opens an on-demand modal overlay for:
  - **Infinite Health** (zero damage from bullets, falls, explosions, electric fences)
  - **Infinite Ammunition** (reserves never deplete)
  - **All Weapons** (unlocks full arsenal for the mission)

---

## Controller Support

Connect any Xbox, PlayStation or generic Android controller — in menus and in missions. The left stick moves a virtual pointer in menus (A clicks, B goes back). While a controller is connected, the on-screen touch controls hide; unplug it mid-mission and they come straight back, no restart. If two controllers are connected, the first one wins.

| Input | Action |
|---|---|
| Left stick | Move |
| Right stick | Look (dead zone 0.18; follows Mouse Sensitivity and Invert Mouse; slows while scoped) |
| RT / LT | Fire / Aim |
| RB / LB | Next weapon / Previous weapon |
| A | Jump (hold to skip cutscenes) |
| B | Crouch toggle |
| X / Y | Reload / Use |
| Start | Pause |
| Back / Select | Map computer |
| D-pad Up / Down | Binoculars / Flashlight (zoom in/out while scoped or in binoculars) |
| D-pad Left / Right | Peek (hold) |
| L3 | Walk/run toggle |
| R3 (hold) | Weapon wheel (steer with right stick) |

Weapon categories 1–9, the cheats gear and the on-screen layout customizer stay touch-only, and there is no remap UI yet.

---

## Project Structure

```
.
├── app/
│   └── android/                      # Android Studio Gradle project
│       ├── app/                      # App module (JNI bridge, C++ CMake, game assets)
│       └── capacitor-android/        # Local Android bridge library
├── apps/
│   ├── ProjectIGI.Android/           # Native Android .NET CoreCLR entrypoint
│   └── ProjectIGI.Composition/       # Shared runtime composition & asset resolver
├── src/
│   ├── Audio/                        # OpenAL 3D sound subsystem
│   ├── Core/                         # VFS, IFF/QVM decoders, math, serialization
│   ├── Engine/                       # GameHost engine loop, HUD, touch input, cheats
│   ├── Game/                         # Authentic I.G.I. 1 game rules, AI, missions
│   ├── Platform/                     # Abstract platform contracts, input state
│   ├── Rendering/                    # Vulkan 1.1 RHI, pipeline, shader batching
│   └── UI/                           # 2D UI painter, font rasterizers
├── Directory.Build.props             # Global .NET build configuration
├── Directory.Packages.props          # Central Package Management pins
└── global.json                       # .NET SDK pin
```

---

## Build Prerequisites

Ensure the following tools are installed and present in your `PATH`:

1. **.NET 10.0 SDK** (or newer)
2. **Android SDK** (API Level 34 or 35)
3. **Android NDK** (version `25.x` or `26.x` recommended)
4. **CMake** (3.22.1+) & **Ninja**
5. **Java Development Kit** (JDK 17)

---

## Step-by-Step Build Instructions

### 1. Build and Publish .NET ARM64 Assemblies

From the root of the repository:

```bash
dotnet publish apps/ProjectIGI.Android/ProjectIGI.Android.csproj -c Release -r android-arm64 --no-self-contained
```

Copy the compiled managed `.dll` and `.pdb` files into the Android project's asset directory:

**Windows (PowerShell):**
```powershell
Copy-Item apps\ProjectIGI.Android\bin\Release\net10.0\android-arm64\publish\*.dll app\android\app\src\main\assets\managed\ -Force
Copy-Item apps\ProjectIGI.Android\bin\Release\net10.0\android-arm64\publish\*.pdb app\android\app\src\main\assets\managed\ -Force
```

**Linux / macOS:**
```bash
cp apps/ProjectIGI.Android/bin/Release/net10.0/android-arm64/publish/*.dll app/android/app/src/main/assets/managed/
cp apps/ProjectIGI.Android/bin/Release/net10.0/android-arm64/publish/*.pdb app/android/app/src/main/assets/managed/
```

### 2. Build the Android Release APK

Navigate to the `app/android` directory and run Gradle:

**Windows:**
```cmd
cd app\android
gradlew.bat assembleRelease
```

**Linux / macOS:**
```bash
cd app/android
chmod +x gradlew
./gradlew assembleRelease
```

The generated APK will be located at:
`app/android/app/build/outputs/apk/release/app-release.apk`

---

## In-Game Screenshots

<img width="400" height="600" alt="image" src="https://github.com/user-attachments/assets/a9c8947b-e84b-4117-8ffa-7a4a4b921a35" />
<img width="400" height="600" alt="image" src="https://github.com/user-attachments/assets/f71b2569-e8b2-46a6-80f7-5355e62ac1c4" />
<img width="400" height="600" alt="image" src="https://github.com/user-attachments/assets/f56ae050-50dd-4537-8c10-57dea78125b5" />
<img width="400" height="600" alt="image" src="https://github.com/user-attachments/assets/b5f55f4d-2e06-47e6-8934-d98b2ca77c4b" />
<img width="400" height="600" alt="image" src="https://github.com/user-attachments/assets/c1884a07-a8da-473c-ae34-66bdb1913515" />

---

## Credits & Disclaimer

- **Original Game**: Developed by **Innerloop Studios** and published by **Eidos Interactive** (2000).
- This project is an open-source educational recreation and engine rewrite intended for preservation and modern platform support.
- All trademarks and registered trademarks belong to their respective owners.
