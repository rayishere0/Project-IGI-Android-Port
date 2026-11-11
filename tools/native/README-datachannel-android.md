# libdatachannel for Android (WebRTC transport for co-op rooms)

The master-server co-op path (rooms) talks over WebRTC data channels.
Upstream (`OpenIGI.Net.WebRtc`) P/Invokes libdatachannel's C API as
`DllImport("datachannel")` (`Native.Library = "datachannel"`, upstream
`src/Engine/OpenIGI.Net.WebRtc/Native.cs:8`). On Android that resolves to
`libdatachannel.so` from the APK's `lib/arm64-v8a/` — which is where the
library committed by this change lives, beside `libopenal.so`.

## What is shipped

| File | What it is |
|---|---|
| `app/android/app/src/main/jniLibs/arm64-v8a/libdatachannel.so` | libdatachannel 0.23.2, arm64-v8a, API 26, stripped (8,586,552 bytes; sha256 `3055b9b820ecce267c3bc0648b53148aa6ec1c219e2b15e63383fc351e934d99`) |
| `tools/native/build-datachannel-android.sh` | The Linux build script that produced it (run and verified 2026-11-11) |
| `tools/native/build-datachannel-android.ps1` | Windows entry point — runs the `.sh` inside WSL2 (not tested on Windows here) |
| `THIRD-PARTY-NOTICES.md` (libdatachannel section) | MPL-2.0 notice for the redistributed binary |

Build facts (see `BUILD-INFO.txt` the script writes next to its output):

- libdatachannel **v0.23.2** (`paullouisageneau/libdatachannel`), submodules as
  recorded by that tag: json `55f93686`, libjuice `b509b6c`, libsrtp `ee1a77c`,
  plog `94899e0`, usrsctp `fec583d`.
- OpenSSL **3.4.1** built from source for android-arm64, static libs only.
- NDK **r28c (28.2.13676358)**, `android-26` (the port's minSdk), `arm64-v8a`.
- CMake options: `NO_MEDIA=ON NO_WEBSOCKET=ON` — rooms use data channels
  only (no media tracks; signalling is the managed `ClientWebSocket`), so
  libsrtp is not built at all. OpenSSL, usrsctp and libjuice are linked
  **statically** into the `.so`, exactly like upstream's vcpkg triplets
  (one shared library, static deps); the `.so` needs only system libs
  (`liblog`, `libdl`, `libm`, `libc`).
- SONAME is `libdatachannel.so`, so .NET resolves `DllImport("datachannel")`
  to it with no extra configuration and no JNI wrapper of our own.

## Verification (done here, 2026-11-11)

- `file` → `ELF 64-bit LSB shared object, ARM aarch64`, stripped.
- All 20 `rtc_*` entry points the managed layer needs are exported
  (`rtcCreatePeerConnection`, `rtcDeletePeerConnection`,
  `rtcCreateDataChannelEx`, `rtcSendMessage`, `rtcSetRemoteDescription`,
  `rtcAddRemoteCandidate`, `rtcSetLocalDescriptionCallback`,
  `rtcSetLocalCandidateCallback`, `rtcSetStateChangeCallback`,
  `rtcSetDataChannelCallback`, `rtcSetOpenCallback`, `rtcSetClosedCallback`,
  `rtcSetErrorCallback`, `rtcSetMessageCallback`, `rtcSetUserPointer`,
  `rtcInitLogger`, `rtcSetSctpSettings`, `rtcGetBufferedAmount`,
  `rtcGetSelectedCandidatePair`, `rtcDeleteDataChannel`) — checked with
  `llvm-nm -D --defined-only`.
- Undefined symbols are all system-libc (`@LIBC`) — nothing else to ship.

## Rebuilding

Linux (verified):

```sh
tools/native/build-datachannel-android.sh
```

Windows (WSL2; not tested here):

```powershell
powershell -ExecutionPolicy Bypass -File tools\native\build-datachannel-android.ps1
```

Both scripts download the NDK and the sources into a work dir, build
OpenSSL first, then libdatachannel, verify the `.so`, and install it into
`app/android/app/src/main/jniLibs/arm64-v8a/`. Requirements on Linux:
bash, curl, git, perl, cmake ≥ 3.21, make, unzip, sha256sum. No ninja, no
vcpkg. Takes ~10 minutes at `-j2`.

## Why the .so is committed (not built at Gradle time)

- There is no Android prebuilt from upstream (its releases ship
  win-x64 / linux-x64 / macOS only) and this repo has no CI that builds
  native libraries, so a build-time fetch has nothing to fetch from.
- Building it needs a Unix toolchain (perl + make + NDK clang + CMake) that
  the Windows build machine does not have — the same machine that is
  missing cmake/ninja/gcc for the Road Rash 64 work. Asking every build to
  compile OpenSSL + libdatachannel from source would break the normal
  build for everyone.
- The repo already ships committed native binaries in
  `app/android/app/src/main/jniLibs/arm64-v8a/` (`libopenal.so`, the .NET
  runtime libs). This follows that pattern. The build script + pins above
  keep the binary reproducible instead of a mystery blob.

## What this does NOT do

- No managed WebRTC code is vendored here (no `OpenIGI.Net.WebRtc`, no
  `DataChannelPeerFactory`, no rooms UI). That comes in a separate PR.
  Until it lands, the `.so` is present but unused: solo play, loopback
  co-op and UDP Wi-Fi play are unaffected, and rooms stay unavailable —
  the same conditional design as upstream (`DataChannelPeerFactory.IsAvailable()`
  gates rooms on the library being loadable).
- No licence change: libdatachannel is MPL-2.0; its notice is in
  `THIRD-PARTY-NOTICES.md`. `LICENSE` / `README.md` are untouched.

## Licence

libdatachannel is Mozilla Public License 2.0 — see the notice in
`THIRD-PARTY-NOTICES.md` and the `LICENSE` file the build script copies
beside its output.
