using System.Runtime.InteropServices;
using ProjectIGI.Audio.OpenAL;
using ProjectIGI.Composition;
using ProjectIGI.Core.Configuration;
using ProjectIGI.Core.Configuration.Presets;
using ProjectIGI.Core.Diagnostics;
using ProjectIGI.Core.Threading;
using ProjectIGI.Core.Titles;
using ProjectIGI.Engine.Configuration;
using ProjectIGI.Engine.Titles;
using ProjectIGI.Engine.Vfs;
using ProjectIGI.Host;
using ProjectIGI.Host.Configuration;
using ProjectIGI.Host.Infrastructure;
using ProjectIGI.Platform;
using ProjectIGI.Rendering;
using ProjectIGI.Rendering.Pipeline;
using ProjectIGI.Rendering.Vulkan;
using ProjectIGI.Rendering.Vulkan.Rhi;

namespace ProjectIGI.Android;

public static class AndroidHost
{
    private static GameHost? _gameHost;
    private static AndroidGameWindow? _window;
    private static VulkanRhi? _vulkan;
    private static GraphicsDevice? _device;
    private static LogRouter? _logger;

    public delegate int RunCallback(nint nativeWindow, int width, int height, nint dataDirPtr, nint optionsPtr);
    public delegate void TouchCallback(int action, int pointerId, float x, float y);
    public delegate void KeyCallback(int keyCode, int down);
    public delegate void ResizeCallback(int width, int height);
    public delegate void StopCallback();

    public static int Run(nint nativeWindow, int width, int height, nint dataDirPtr, nint optionsPtr)
    {
        int landscapeWidth = Math.Max(width, height);
        int landscapeHeight = Math.Min(width, height);

        string dataDir = Marshal.PtrToStringUTF8(dataDirPtr) ?? string.Empty;
        string optionsStr = Marshal.PtrToStringUTF8(optionsPtr) ?? string.Empty;

        if (!string.IsNullOrEmpty(dataDir))
        {
            string configDir = Path.Combine(dataDir, ".config");
            Environment.SetEnvironmentVariable("HOME", dataDir);
            Environment.SetEnvironmentVariable("XDG_CONFIG_HOME", configDir);
            Environment.SetEnvironmentVariable("XDG_DATA_HOME", Path.Combine(dataDir, ".local", "share"));
            Environment.SetEnvironmentVariable("ProjectIGI_USER_DIR", dataDir);
            try { Directory.CreateDirectory(configDir); } catch { }
            try { Directory.SetCurrentDirectory(AppContext.BaseDirectory); } catch { }
        }

        _logger = new LogRouter().AddSink(new AndroidLogSink());
        _logger.Information("AndroidHost", $"Booting ProjectIGI Android native host: {landscapeWidth}x{landscapeHeight}, dataDir: '{dataDir}'");

        // Configure OpenAL native library resolver
        try
        {
            string parentDir = !string.IsNullOrEmpty(dataDir) ? (Path.GetDirectoryName(dataDir) ?? dataDir) : string.Empty;
            string nativeLibDir = Environment.GetEnvironmentVariable("ProjectIGI_NATIVE_LIB_DIR") ?? string.Empty;

            DllImportResolver openAlResolver = (libraryName, assembly, searchPath) =>
            {
                if (libraryName.Contains("openal", StringComparison.OrdinalIgnoreCase))
                {
                    string[] candidates = [
                        Path.Combine(nativeLibDir, "libopenal.so"),
                        Path.Combine(AppContext.BaseDirectory, "libopenal.so"),
                        Path.Combine(parentDir, "managed", "libopenal.so"),
                        Path.Combine(parentDir, "libopenal.so"),
                        Path.Combine(dataDir, "libopenal.so"),
                        "/data/user/0/com.projectigi.app/files/managed/libopenal.so",
                        "/data/user/0/com.projectigi.app/files/libopenal.so",
                        "libopenal.so",
                        "openal"
                    ];

                    foreach (string candidate in candidates)
                    {
                        if (string.IsNullOrEmpty(candidate)) continue;
                        try
                        {
                            if (NativeLibrary.TryLoad(candidate, assembly, searchPath, out nint handle))
                            {
                                _logger.Information("AndroidHost", $"Resolved OpenAL via: {candidate}");
                                return handle;
                            }
                        }
                        catch { }
                    }
                    _logger.Warning("AndroidHost", $"Failed to resolve OpenAL from all candidates for library {libraryName}");
                }
                return nint.Zero;
            };
            NativeLibrary.SetDllImportResolver(typeof(Silk.NET.OpenAL.AL).Assembly, openAlResolver);
        }
        catch (Exception ex)
        {
            _logger.Error("AndroidHost", "Error setting OpenAL resolver", ex);
        }

        try
        {
            string[] args = string.IsNullOrWhiteSpace(optionsStr)
                ? []
                : optionsStr.Split(' ', StringSplitOptions.RemoveEmptyEntries);

            HostOptions options = HostOptions.Parse(args);
            IGameTitleRuntime runtime = TitleCatalog.Default;

            VirtualFileSystem fileSystem = new(_logger);
            fileSystem.RegisterDevice(new LocalFileDevice(dataDir));
            FileSystemConfig
                .LoadOrDefault(Path.Combine(dataDir, FileSystemConfig.DefaultFileName), runtime.Layout)
                .ApplyTo(fileSystem);

            _window = new AndroidGameWindow(landscapeWidth, landscapeHeight);
            AndroidPlatformHost platform = new(_window);

            if (optionsStr.Contains("-vulkan", StringComparison.OrdinalIgnoreCase))
            {
                _logger.Information("AndroidHost", "Creating Vulkan surface provider...");
                AndroidVulkanSurfaceProvider surfaceProvider = new(nativeWindow);

                _vulkan = VulkanRhi.CreateForSurface(
                    surfaceProvider,
                    landscapeWidth,
                    landscapeHeight,
                    vsync: true,
                    logger: _logger);

                _device = new GraphicsDevice(
                    _vulkan.Device,
                    new DisplayMode(landscapeWidth, landscapeHeight, 32, 60),
                    captureFrames: options.ScreenshotPath is not null,
                    logger: _logger);

                _logger.Information("AndroidHost", $"Vulkan initialized on adapter: {_vulkan.Device.AdapterName}");
            }
            else
            {
                _logger.Information("AndroidHost", "Falling back to OpenGLES dummy device (Native C++ handles GLES).");
                // For GLES fallback, the native C++ renderer draws the screen, so the managed side
                // bypasses Vulkan initialization but still needs a valid GraphicsDevice placeholder
                // The C# backend only has VulkanRhi, so we skip allocating the graphics device here,
                // and the GameHost logic handles headless/null device rendering.
                _device = null;
            }

            // Ensure all CVars from all assemblies are registered into the catalog before applying preset:
            Rendering.Generated.CVarRegistrations.RegisterAll();
            Game.Generated.CVarRegistrations.RegisterAll();

            string settingsPath = Path.Combine(dataDir, SettingsPaths.SettingsFileName);
            bool settingsExist = File.Exists(settingsPath);

            if (!settingsExist)
            {
                // Enforce maximum speed profile on Android mobile by default on initial launch:
                // 1. Vanilla graphics preset: forward rendering, baked lightmaps, 60+ FPS
                GraphicsPresetRegistry.Default.Apply(GraphicsPreset.Vanilla);

                // 2. Mission warmup frames: brief display of tactical loading screen
                FrameCVars.MissionWarmUp.Value = 25;

                // 3. Disable expensive desktop post passes and G-buffer
                LightingCVars.Deferred.Value = false;
                FrameCVars.OffscreenScene.Value = false;
                LightingCVars.Lighting.Value = LightingModel.Baked;

                // 4. Default graphics API to OpenGL
                DisplayCVars.Renderer.Value = RendererBackend.OpenGL;

                // 5. Default FPS cap to 30 FPS on Android
                ReconstructionCVars.FrameLimit.Value = 30;
            }

            RendererBackend chosenBackend = DisplayCVars.Renderer.Value;
            if (chosenBackend == RendererBackend.Auto)
            {
                chosenBackend = RendererBackend.OpenGL;
                DisplayCVars.Renderer.Value = RendererBackend.OpenGL;
            }
            _logger.Information("AndroidHost", $"Using rendering API: {chosenBackend} (Settings exist: {settingsExist})");

            int exitCode;
            while (true)
            {
                _gameHost = new GameHost(
                    platform,
                    _window,
                    _device,
                    OpenAlAudioDeviceFactory.Instance,
                    ThreadPoolWorkScheduler.Instance,
                    AlwaysReadyLoadGate.Instance,
                    TitleCatalog.Rooted(runtime, dataDir),
                    runtime.Title,
                    fileSystem,
                    options with { Renderer = chosenBackend, FirstRunPreset = GraphicsPreset.Vanilla, VanillaMenu = true },
                    dataDir,
                    _logger);

                _logger.Information("AndroidHost", "Starting game loop...");
                exitCode = _gameHost.Run();
                _logger.Information("AndroidHost", $"Game loop finished with exit code {exitCode}");
                _gameHost.Dispose();
                _gameHost = null;

                if (exitCode != 42)
                {
                    break;
                }

                _logger.Information("AndroidHost", "Restart requested: reloading GameHost with fresh configuration...");
            }
            return exitCode;
        }
        catch (Exception ex)
        {
            _logger.Error("AndroidHost", "Fatal error during game execution", ex);
            return 1;
        }
        finally
        {
            _gameHost?.Dispose();
            _gameHost = null;
            _device?.Dispose();
            _device = null;
            _vulkan?.Dispose();
            _vulkan = null;
            _window?.Dispose();
            _window = null;
        }
    }

    public static void OnTouch(int action, int pointerId, float x, float y)
    {
        _window?.EnqueueTouch(action, pointerId, x, y);
    }

    public static void OnKey(int keyCode, int down)
    {
        _window?.EnqueueKey(keyCode, down != 0);
    }

    public static void OnResize(int width, int height)
    {
        int landscapeWidth = Math.Max(width, height);
        int landscapeHeight = Math.Min(width, height);
        _window?.EnqueueResize(landscapeWidth, landscapeHeight);
    }

    public static void Stop()
    {
        _window?.Close();
    }
}
