#!/usr/bin/env bash
# Builds libdatachannel 0.23.2 for Android arm64-v8a (the WebRTC transport for
# master-server co-op rooms) on Linux. This is the script that produced the
# libdatachannel.so committed in app/android/app/src/main/jniLibs/arm64-v8a/.
#
#   tools/native/build-datachannel-android.sh [--ndk <path>] [--jobs N]
#       [--work-dir <dir>] [--no-install]
#
# What it does:
#   1. NDK r28c (28.2.13676358) — uses $ANDROID_NDK_HOME / --ndk, or downloads
#      and extracts android-ndk-r28c-linux.zip into the work dir.
#   2. OpenSSL 3.4.1 — downloads the tarball, verifies its sha256, builds it
#      for android-arm64 (API 26, static libs only) with the NDK clang.
#   3. libdatachannel v0.23.2 — shallow-clones the tag plus its submodules,
#      configures with the NDK toolchain (NO_MEDIA + NO_WEBSOCKET: rooms use
#      data channels only, no media tracks, signalling is managed), builds
#      the shared library with OpenSSL/usrsctp/libjuice linked in statically.
#   4. Strips the .so, verifies it (aarch64 ELF, SONAME libdatachannel.so,
#      all 20 rtc_* entry points the managed P/Invoke layer needs), and
#      installs it to app/android/app/src/main/jniLibs/arm64-v8a/ (unless
#      --no-install), with LICENSE + BUILD-INFO.txt beside the build output.
#
# Requirements: bash, curl, git, perl, cmake (>= 3.21), make, unzip, sha256sum.
# No ninja, no vcpkg. Tested on Linux (Ubuntu, cmake 3.28, NDK r28c).
# Takes ~10 minutes, mostly OpenSSL + libdatachannel compilation; -j2 default
# so it stays inside ~6 GB RAM.
#
# Pins — change these and the committed .so no longer matches this script:
#   LIBDATACHANNEL_TAG=v0.23.2  (submodules as recorded by that tag:
#     json 55f93686, libjuice b509b6c, libsrtp ee1a77c, plog 94899e0,
#     usrsctp fec583d)
#   OPENSSL_VERSION=3.4.1  (sha256 002a2d6b30b58bf4bea46c43bdd96365aaf8daa6c428782aa4feee06da197df3)
#   NDK_VERSION=r28c, 28.2.13676358
#     (sha256 dfb20d396df28ca02a8c708314b814a4d961dc9074f9a161932746f815aa552f)
#   ANDROID_API=26 (the port's minSdkVersion), ANDROID_ABI=arm64-v8a.
#
# Two gotchas this script already accounts for (do not "simplify" them away):
#   * OpenSSL's Configure needs ANDROID_NDK_ROOT (not just ANDROID_NDK_HOME)
#     AND the NDK bin dir on PATH, or the build fails with "No such file or
#     directory" for aarch64-linux-android26-clang.
#   * CMake's FindOpenSSL cannot see OPENSSL_ROOT_DIR under the NDK toolchain
#     (CMAKE_FIND_ROOT_PATH_MODE_*=ONLY re-roots it into the sysroot), so the
#     OpenSSL include/lib paths are passed as explicit cache variables.
#   * `git submodule update` without --depth fetches the full history of
#     nlohmann/json and stalls for 10+ minutes; always use --depth 1.
set -euo pipefail

LIBDATACHANNEL_TAG="v0.23.2"
OPENSSL_VERSION="3.4.1"
OPENSSL_SHA256="002a2d6b30b58bf4bea46c43bdd96365aaf8daa6c428782aa4feee06da197df3"
NDK_VERSION="r28c"
NDK_REVISION="28.2.13676358"
NDK_ZIP_SHA256="dfb20d396df28ca02a8c708314b814a4d961dc9074f9a161932746f815aa552f"
ANDROID_API="26"
ANDROID_ABI="arm64-v8a"

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
NDK_ARG=""
JOBS="2"
WORK_DIR="${TMPDIR:-/tmp}/projectigi-datachannel-build"
INSTALL=1

while [ $# -gt 0 ]; do
  case "$1" in
    --ndk) NDK_ARG="$2"; shift 2 ;;
    --jobs) JOBS="$2"; shift 2 ;;
    --work-dir) WORK_DIR="$2"; shift 2 ;;
    --no-install) INSTALL=0; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

for tool in curl git perl cmake make unzip sha256sum; do
  command -v "$tool" >/dev/null 2>&1 || { echo "Missing required tool: $tool" >&2; exit 1; }
done

mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# --- 1. NDK ---------------------------------------------------------------
if [ -n "$NDK_ARG" ]; then
  NDK_DIR="$NDK_ARG"
elif [ -n "${ANDROID_NDK_HOME:-}" ]; then
  NDK_DIR="$ANDROID_NDK_HOME"
elif [ -d "$WORK_DIR/android-ndk-r28c" ]; then
  NDK_DIR="$WORK_DIR/android-ndk-r28c"
else
  NDK_ZIP="$WORK_DIR/android-ndk-r28c-linux.zip"
  if [ ! -f "$NDK_ZIP" ]; then
    echo "Downloading Android NDK $NDK_VERSION..."
    curl -sL -o "$NDK_ZIP" "https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-linux.zip"
  fi
  echo "$NDK_ZIP_SHA256  $NDK_ZIP" | sha256sum -c -
  unzip -q -o "$NDK_ZIP" -d "$WORK_DIR"
  NDK_DIR="$WORK_DIR/android-ndk-r28c"
fi
[ -f "$NDK_DIR/source.properties" ] || { echo "Not an NDK directory: $NDK_DIR" >&2; exit 1; }
grep -q "Pkg.Revision = $NDK_REVISION" "$NDK_DIR/source.properties" \
  || echo "WARNING: NDK revision is not $NDK_REVISION (see source.properties)"
export ANDROID_NDK_HOME="$NDK_DIR"
export ANDROID_NDK_ROOT="$NDK_DIR"
export PATH="$NDK_DIR/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH"
echo "NDK: $NDK_DIR ($(grep 'Pkg.Revision' "$NDK_DIR/source.properties"))"

# --- 2. OpenSSL for Android arm64 (static libs) ----------------------------
OPENSSL_PREFIX="$WORK_DIR/openssl-android-arm64"
if [ ! -f "$OPENSSL_PREFIX/lib/libssl.a" ]; then
  OPENSSL_TGZ="$WORK_DIR/openssl-$OPENSSL_VERSION.tar.gz"
  if [ ! -f "$OPENSSL_TGZ" ]; then
    curl -sL -o "$OPENSSL_TGZ" "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz"
  fi
  echo "$OPENSSL_SHA256  $OPENSSL_TGZ" | sha256sum -c -
  tar xzf "$OPENSSL_TGZ"
  ( cd "openssl-$OPENSSL_VERSION" && \
    ./Configure android-arm64 -D__ANDROID_API__=$ANDROID_API \
      --prefix="$OPENSSL_PREFIX" --openssldir="$OPENSSL_PREFIX/ssl" \
      no-shared no-tests no-apps >/dev/null && \
    make -j"$JOBS" build_libs >/dev/null && \
    make install_sw >/dev/null )
fi
[ -f "$OPENSSL_PREFIX/lib/libssl.a" ] && [ -f "$OPENSSL_PREFIX/lib/libcrypto.a" ] \
  || { echo "OpenSSL build failed: no static libs in $OPENSSL_PREFIX/lib" >&2; exit 1; }
echo "OpenSSL $OPENSSL_VERSION built: $OPENSSL_PREFIX/lib/libssl.a"

# --- 3. libdatachannel source + submodules ---------------------------------
SRC_DIR="$WORK_DIR/libdatachannel-src"
if [ ! -d "$SRC_DIR/.git" ]; then
  git clone --branch "$LIBDATACHANNEL_TAG" --depth 1 \
    https://github.com/paullouisageneau/libdatachannel.git "$SRC_DIR" 2>&1 | tail -2
fi
( cd "$SRC_DIR" && git submodule update --init --recursive --depth 1 2>&1 | tail -5 )
# A submodule worktree can end up empty if an earlier update was interrupted
# (git thinks it is checked out because its HEAD matches); force-checkout any
# empty one. The build needs usrsctp + libjuice + plog + json present.
for dep in json libjuice usrsctp plog; do
  if [ -z "$(ls -A "$SRC_DIR/deps/$dep" 2>/dev/null | grep -v '^\.git$')" ]; then
    echo "Re-checking out empty submodule deps/$dep..."
    ( cd "$SRC_DIR/deps/$dep" && git checkout -f HEAD )
  fi
done
[ -f "$SRC_DIR/deps/usrsctp/usrsctplib/usrsctp.h" ] \
  || { echo "Submodules missing: deps/usrsctp is empty" >&2; exit 1; }
echo "libdatachannel $LIBDATACHANNEL_TAG: $(cd "$SRC_DIR" && git rev-parse HEAD)"
( cd "$SRC_DIR" && git submodule status )

# --- 4. Configure + build --------------------------------------------------
BUILD_DIR="$WORK_DIR/build-android-arm64"
cmake -S "$SRC_DIR" -B "$BUILD_DIR" -G "Unix Makefiles" \
  -DCMAKE_TOOLCHAIN_FILE="$NDK_DIR/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=$ANDROID_ABI -DANDROID_PLATFORM=android-$ANDROID_API \
  -DCMAKE_BUILD_TYPE=Release \
  -DOPENSSL_INCLUDE_DIR="$OPENSSL_PREFIX/include" \
  -DOPENSSL_SSL_LIBRARY="$OPENSSL_PREFIX/lib/libssl.a" \
  -DOPENSSL_CRYPTO_LIBRARY="$OPENSSL_PREFIX/lib/libcrypto.a" \
  -DOPENSSL_USE_STATIC_LIBS=TRUE \
  -DNO_MEDIA=ON -DNO_WEBSOCKET=ON -DNO_TESTS=ON -DNO_EXAMPLES=ON
cmake --build "$BUILD_DIR" -j"$JOBS"

# --- 5. Strip, verify, install ---------------------------------------------
OUT_DIR="$WORK_DIR/third-party/libdatachannel/android-arm64"
mkdir -p "$OUT_DIR/arm64-v8a"
cp "$BUILD_DIR/libdatachannel.so" "$OUT_DIR/arm64-v8a/libdatachannel.so"
"$NDK_DIR/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip" \
  "$OUT_DIR/arm64-v8a/libdatachannel.so"
cp "$SRC_DIR/LICENSE" "$OUT_DIR/LICENSE"

SO="$OUT_DIR/arm64-v8a/libdatachannel.so"
file "$SO"
[ "$("$NDK_DIR/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-readelf" -d "$SO" | grep -c SONAME)" -ge 1 ] || exit 1
for sym in rtcSetSctpSettings rtcGetBufferedAmount rtcInitLogger \
    rtcCreatePeerConnection rtcDeletePeerConnection rtcSetUserPointer \
    rtcSetLocalDescriptionCallback rtcSetLocalCandidateCallback \
    rtcSetStateChangeCallback rtcSetDataChannelCallback rtcSetRemoteDescription \
    rtcAddRemoteCandidate rtcCreateDataChannelEx rtcSetOpenCallback \
    rtcSetClosedCallback rtcSetErrorCallback rtcSetMessageCallback \
    rtcSendMessage rtcGetSelectedCandidatePair rtcDeleteDataChannel; do
  "$NDK_DIR/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-nm" -D --defined-only "$SO" \
    | grep -q " T $sym\$" || { echo "MISSING SYMBOL: $sym" >&2; exit 1; }
done
echo "Verified: all 20 rtc_* entry points present."
{
  echo "libdatachannel $LIBDATACHANNEL_TAG for Android $ANDROID_ABI (API $ANDROID_API)"
  echo "Built: $(date -u +%Y-%m-%dT%H:%M:%SZ) on Linux"
  echo "NDK: $NDK_REVISION"
  echo "OpenSSL: $OPENSSL_VERSION (static, built from source)"
  echo "libdatachannel HEAD: $(cd "$SRC_DIR" && git rev-parse HEAD)"
  echo "Submodules:"; ( cd "$SRC_DIR" && git submodule status )
  echo "Options: NO_MEDIA=ON NO_WEBSOCKET=ON (data channels only)"
  echo "SHA256: $(sha256sum "$SO" | cut -d' ' -f1)"
  echo "Size (stripped): $(stat -c%s "$SO") bytes"
} > "$OUT_DIR/BUILD-INFO.txt"

if [ "$INSTALL" -eq 1 ]; then
  DEST="$REPO_ROOT/app/android/app/src/main/jniLibs/arm64-v8a/libdatachannel.so"
  cp "$SO" "$DEST"
  echo "Installed: $DEST"
fi
echo "Done. Output: $OUT_DIR"
