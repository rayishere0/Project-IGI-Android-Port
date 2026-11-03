#!/usr/bin/env bash
# Deploy Managed Assets Script for OpenIGI Android Port
# Builds the C# assemblies in Release mode and copies them to the Android project assets directory.

set -e

echo "Building .NET ARM64 assemblies in Release mode..."
dotnet publish apps/ProjectIGI.Android/ProjectIGI.Android.csproj -c Release -r android-arm64 --no-self-contained

PUBLISH_DIR="apps/ProjectIGI.Android/bin/Release/net10.0/android-arm64/publish"
TARGET_DIRS=(
    "app/android/app/src/main/assets/managed"
    "app/src/main/assets/managed"
)

for TARGET_DIR in "${TARGET_DIRS[@]}"; do
    mkdir -p "$TARGET_DIR"
    echo "Copying compiled assemblies to $TARGET_DIR..."
    cp "$PUBLISH_DIR"/*.dll "$TARGET_DIR"/
    cp "$PUBLISH_DIR"/*.pdb "$TARGET_DIR"/
done

echo "Deployment complete! Binaries successfully updated in target directories."
