using System.Runtime.InteropServices;
using ProjectIGI.Android;
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
using ProjectIGI.Rendering.Rhi;
using ProjectIGI.Rendering.Vulkan.Rhi;
using ProjectIGI.Rendering.WebGpu;

// The native bridge (app/android/app/src/main/cpp/jni/jni_bridge.cpp) resolves this type by the
// literal string "OpenIGI.Android.AndroidHost", so the namespace is part of the ABI, not a naming
// preference. It stays OpenIGI.* even though the projects are named ProjectIGI.*.
namespace OpenIGI.Android;

public static class AndroidHost
{
    private static GameHost? _gameHost;
    private static AndroidGameWindow? _window;
    private static ProjectIGI.Rendering.Pipeline.GraphicsDevice? _device;
    private static VulkanRhi? _vulkanRhi;
    private static WebGpuRhiDevice? _webGpuRhi;
    private static LogRouter? _logger;

    public delegate int RunCallback(nint nativeWindow, int width, int height, nint dataDirPtr, nint optionsPtr);
    public delegate void TouchCallback(int action, int pointerId, float x, float y);
    public delegate void KeyCallback(int keyCode, int down);
    public delegate void ResizeCallback(int width, int height);
    public delegate void StopCallback();

    private static DllImportResolver? _openAlResolver;

    // Vulkan-only build: no EGL imports. The native Vulkan surface owns the window exclusively,
    // so the EGL context helpers the Veldrid/OpenGL ES path used are gone.

    [UnmanagedCallersOnly(EntryPoint = "Run")]
    public static int Run(nint nativeWindow, int width, int height, nint dataDirPtr, nint optionsPtr)
    {
        AppDomain.CurrentDomain.UnhandledException += (sender, args) =>
        {
            var ex = (Exception)args.ExceptionObject;
            Console.WriteLine($"[AndroidHost] FATAL UNHANDLED EXCEPTION: {ex}");
        };

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

            _openAlResolver = (libraryName, assembly, searchPath) =>
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
            NativeLibrary.SetDllImportResolver(typeof(Silk.NET.OpenAL.AL).Assembly, _openAlResolver);
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
            string settingsPath = Path.Combine(dataDir, SettingsPaths.SettingsFileName);
            bool settingsExist = File.Exists(settingsPath);

            // The launcher passes the backend the player picked (-vulkan / -webgpu) in the
            // options string. WebGPU is attempted when picked; if its library or surface
            // cannot be created (no libwgpu_native.so in the APK yet, or the adapter
            // refuses), it falls back to native Vulkan so the game still starts.
            bool wantsWebGpu = optionsStr.Contains("webgpu", StringComparison.OrdinalIgnoreCase);

            // Enforce maximum speed profile on Android mobile unconditionally:
            LightingCVars.Deferred.Value = false;
            FrameCVars.OffscreenScene.Value = false;
            LightingCVars.Lighting.Value = LightingModel.Baked;

            // Force the original classic IGI HUD (disables Remastered overlays)
            HudCVars.RemasteredHud.Value = false;

            if (!settingsExist)
            {
                // Enforce maximum speed profile on Android mobile by default on initial launch:
                GraphicsPresetRegistry.Default.Apply(GraphicsPreset.Vanilla);
                FrameCVars.MissionWarmUp.Value = 25;
                DisplayCVars.Renderer.Value = RendererBackend.Vulkan;
                ReconstructionCVars.FrameLimit.Value = 30;

                // Phones render far below native by default: a full-resolution 2400x1080
                // frame is too much for a mid-range mobile GPU through WebGPU (10-20 fps).
                // 720p-equivalent, upscaled by the temporal upscaler, is the performance tier;
                // the 540p ultra tier is one tap away in Settings for low-end devices.
                _window?.RenderScaleMode = 1;
            }

            // Show the tier actually being rendered (the r_scale loaded from settings), so
            // the menu does not claim 720p while the frame is native, or the reverse.
            _window?.SyncRenderScaleMode();

            AppDomain.CurrentDomain.FirstChanceException += (sender, args) =>
            {
                _logger?.Information("AndroidHost", $"[FirstChanceException] {args.Exception.GetType().Name}: {args.Exception.Message}");
            };

            if (landscapeWidth <= 0) landscapeWidth = 1280;
            if (landscapeHeight <= 0) landscapeHeight = 720;

            if (nativeWindow == nint.Zero)
            {
                _logger.Error("AndroidHost", "ERROR: Native window handle is IntPtr.Zero!");
                throw new InvalidOperationException("Native window handle is IntPtr.Zero!");
            }

            IRhiDevice rhiDevice;
            RendererBackend chosenBackend;
            if (wantsWebGpu)
            {
                try
                {
                    _logger.Information("AndroidHost", "Initializing WebGPU device.");
                    _webGpuRhi = WebGpuRhiDevice.CreateForWindow(
                        new WebGpuWindowHandles(WebGpuWindowSystem.Android, nint.Zero, nativeWindow),
                        landscapeWidth,
                        landscapeHeight,
                        vsync: true);
                    rhiDevice = _webGpuRhi;
                    chosenBackend = RendererBackend.WebGpu;
                    DisplayCVars.Renderer.Value = RendererBackend.WebGpu;
                    _logger.Information("AndroidHost", $"WebGPU initialized on adapter: {rhiDevice.AdapterName}");
                }
                catch (Exception webGpuEx)
                {
                    _logger.Error("AndroidHost", "WebGPU could not start (is libwgpu_native.so in the APK?) — falling back to native Vulkan.", webGpuEx);
                    _webGpuRhi?.Dispose();
                    _webGpuRhi = null;
                    (rhiDevice, chosenBackend) = CreateVulkanRhi(nativeWindow, landscapeWidth, landscapeHeight);
                }
            }
            else
            {
                (rhiDevice, chosenBackend) = CreateVulkanRhi(nativeWindow, landscapeWidth, landscapeHeight);
            }

            _device = new ProjectIGI.Rendering.Pipeline.GraphicsDevice(
                rhiDevice,
                new DisplayMode(landscapeWidth, landscapeHeight, 32, 60),
                captureFrames: options.ScreenshotPath is not null,
                logger: _logger);

            // The pipeline GraphicsDevice configures the surface itself (and on resize) through
            // IRhiDevice.ConfigureSurface; there is no manual surface step here.

            ProjectIGI.Rendering.Generated.CVarRegistrations.RegisterAll();
            ProjectIGI.Game.Generated.CVarRegistrations.RegisterAll();

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
            _vulkanRhi?.Dispose();
            _vulkanRhi = null;
            _webGpuRhi?.Dispose();
            _webGpuRhi = null;
            _window?.Dispose();
            _window = null;
        }
    }

    private static (IRhiDevice Device, RendererBackend Backend) CreateVulkanRhi(nint nativeWindow, int width, int height)
    {
        LogRouter logger = _logger!;

        logger.Information("AndroidHost", "Initializing native Vulkan 1.3 device.");
        DisplayCVars.Renderer.Value = RendererBackend.Vulkan;

        // The native window is the ANativeWindow* the JNI bridge obtained from the Surface;
        // AndroidVulkanSurfaceProvider hands it to vkCreateAndroidSurfaceKHR. This mirrors
        // desktop's VulkanRhi.CreateForSurface(new VulkanSurfaceProvider(...)) exactly.
        _vulkanRhi = VulkanRhi.CreateForSurface(
            new AndroidVulkanSurfaceProvider(nativeWindow),
            width,
            height,
            vsync: true,
            logger,
            enableValidation: false,
            streamline: null);

        IRhiDevice device = _vulkanRhi.Device;
        logger.Information("AndroidHost", $"Native Vulkan initialized on adapter: {device.AdapterName}");
        return (device, RendererBackend.Vulkan);
    }

    [UnmanagedCallersOnly(EntryPoint = "OnTouch")]
    public static void OnTouch(int action, int pointerId, float x, float y)
    {
        _window?.EnqueueTouch(action, pointerId, x, y);
    }

    [UnmanagedCallersOnly(EntryPoint = "OnNativeTouch")]
    public static void OnNativeTouch(int action, float x, float y)
    {
        _window?.EnqueueTouch(action, 0, x, y);
    }

    [UnmanagedCallersOnly(EntryPoint = "OnKey")]
    public static void OnKey(int keyCode, int down)
    {
        _window?.EnqueueKey(keyCode, down != 0);
    }

    [UnmanagedCallersOnly(EntryPoint = "OnResize")]
    public static void OnResize(int width, int height)
    {
        int landscapeWidth = Math.Max(width, height);
        int landscapeHeight = Math.Min(width, height);
        _window?.EnqueueResize(landscapeWidth, landscapeHeight);
    }

    [UnmanagedCallersOnly(EntryPoint = "Stop")]
    public static void Stop()
    {
        _window?.Close();
    }
}
