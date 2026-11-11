# Builds libdatachannel 0.23.2 for Android arm64-v8a on Windows, by running
# build-datachannel-android.sh inside WSL2. The native build needs a Unix
# toolchain (perl for OpenSSL's Configure, make, the NDK clang) that the
# Windows machine does not have; WSL2 provides it, and the script does the
# rest. The .so this produces is the same one committed in
# app/android/app/src/main/jniLibs/arm64-v8a/ — run this only to rebuild it.
#
#   powershell -ExecutionPolicy Bypass -File tools\native\build-datachannel-android.ps1
#
# Requirements: WSL2 with a Linux distro (Ubuntu) that has bash, curl, git,
# perl, cmake, make, unzip. Inside WSL the script downloads the NDK r28c and
# builds OpenSSL 3.4.1 + libdatachannel from source (~10 minutes).
#
# NOT tested on Windows here (this repo's agents cannot run Windows); the
# Linux script it delegates to was run and verified on Linux 2026-11-11.
# If WSL is missing, install it first (`wsl --install`) — there is no native
# Windows build path for this library in this repo.
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$ScriptRel = "tools/native/build-datachannel-android.sh"

if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
    throw "WSL is not installed. Install WSL2 (`wsl --install`, then restart) and re-run this script. There is no native Windows build path for libdatachannel in this repo."
}

# Translate the Windows repo path to the WSL mount path (C:\x -> /mnt/c/x).
$Drive = $RepoRoot.Substring(0, 1).ToLower()
$Rest = $RepoRoot.Substring(2).Replace('\', '/')
$WslRepo = "/mnt/$Drive$Rest"

Write-Host "Building libdatachannel for Android arm64-v8a inside WSL ($WslRepo)..." -ForegroundColor Green
wsl bash "$WslRepo/$ScriptRel"
if ($LASTEXITCODE -ne 0) {
    throw "WSL build failed with exit code $LASTEXITCODE. The .so was NOT rebuilt; the committed libdatachannel.so is untouched."
}

Write-Host "Done. libdatachannel.so installed to app\android\app\src\main\jniLibs\arm64-v8a\." -ForegroundColor Cyan
