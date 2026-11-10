# Deploy Managed Assets Script for OpenIGI Android Port
# Builds the C# assemblies in Release mode and copies them to the Android project assets directory.

$ErrorActionPreference = "Stop"

Write-Host "Building .NET ARM64 assemblies in Release mode..." -ForegroundColor Green
dotnet publish apps\ProjectIGI.Android\ProjectIGI.Android.csproj -c Release -r android-arm64 --no-self-contained

# dotnet is a native executable: $ErrorActionPreference = "Stop" does NOT stop the
# script when it exits non-zero, so without this check a failed build falls through
# to the copy below, stale DLLs go into the APK, and the script still prints
# "Deployment complete!". Abort here instead: nothing is copied on a failed build.
if ($LASTEXITCODE -ne 0) {
    throw "dotnet publish failed with exit code $LASTEXITCODE. Assemblies were NOT copied - fix the build errors above and re-run."
}

$publishDir = "apps\ProjectIGI.Android\bin\Release\net10.0\android-arm64\publish"
$targetDirs = @(
    "app\android\app\src\main\assets\managed",
    "app\src\main\assets\managed"
)

foreach ($dir in $targetDirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    Write-Host "Copying compiled assemblies to $dir..." -ForegroundColor Green
    Copy-Item "$publishDir\*.dll" $dir -Force
    Copy-Item "$publishDir\*.pdb" $dir -Force
}

Write-Host "Deployment complete! Binaries successfully updated in target directories." -ForegroundColor Cyan
