using System.Runtime.InteropServices;
using ProjectIGI.Android;
using ProjectIGI.Audio.OpenAL;
using ProjectIGI.Composition;
using ProjectIGI.Core.Configuration;
using ProjectIGI.Core.Configuration.Presets;
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

    // Which backend is presenting, so a surface rebind (tab-out / rotate) calls the right one.
    private static RendererBackend _activeBackend = RendererBackend.Vulkan;

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
                                return handle;
                            }
                        }
                        catch { }
                    }
                }
                return nint.Zero;
            };
            NativeLibrary.SetDllImportResolver(typeof(Silk.NET.OpenAL.AL).Assembly, _openAlResolver);
        }
        catch (Exception ex)
        {
        }

        try
        {
            string[] args = string.IsNullOrWhiteSpace(optionsStr)
                ? []
                : optionsStr.Split(' ', StringSplitOptions.RemoveEmptyEntries);

            HostOptions options = HostOptions.Parse(args);
            IGameTitleRuntime runtime = TitleCatalog.Default;

            VirtualFileSystem fileSystem = new();
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
            };

            if (landscapeWidth <= 0) landscapeWidth = 1280;
            if (landscapeHeight <= 0) landscapeHeight = 720;

            if (nativeWindow == nint.Zero)
            {
                throw new InvalidOperationException("Native window handle is IntPtr.Zero!");
            }

            IRhiDevice rhiDevice;
            RendererBackend chosenBackend;
            if (wantsWebGpu)
            {
                try
                {
                    _webGpuRhi = WebGpuRhiDevice.CreateForWindow(
                        new WebGpuWindowHandles(WebGpuWindowSystem.Android, nint.Zero, nativeWindow),
                        landscapeWidth,
                        landscapeHeight,
                        vsync: true);
                    rhiDevice = _webGpuRhi;
                    chosenBackend = RendererBackend.WebGpu;
                    DisplayCVars.Renderer.Value = RendererBackend.WebGpu;
                }
                catch (Exception webGpuEx)
                {
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
                captureFrames: options.ScreenshotPath is not null);

            _activeBackend = chosenBackend;

            // The window delivers a new native window (after the old one was destroyed) on the
            // game thread, where the RHI rebind must run. The callback is set here, at creation,
            // so it is in place before any surface event can arrive.
            if (_window is { } window)
            {
                window.SurfaceRecreated = RebindSurface;
            }

            // The pipeline GraphicsDevice configures the surface itself (and on resize) through
            // IRhiDevice.ConfigureSurface; there is no manual surface step here.

            ProjectIGI.Rendering.Generated.CVarRegistrations.RegisterAll();
            ProjectIGI.Game.Generated.CVarRegistrations.RegisterAll();


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
                    dataDir);

                exitCode = _gameHost.Run();
                _gameHost.Dispose();
                _gameHost = null;

                if (exitCode != 42)
                {
                    break;
                }

            }
            return exitCode;
        }
        catch (Exception ex)
        {
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
        DisplayCVars.Renderer.Value = RendererBackend.Vulkan;

        // The native window is the ANativeWindow* the JNI bridge obtained from the Surface;
        // AndroidVulkanSurfaceProvider hands it to vkCreateAndroidSurfaceKHR. This mirrors
        // desktop's VulkanRhi.CreateForSurface(new VulkanSurfaceProvider(...)) exactly.
        _vulkanRhi = VulkanRhi.CreateForSurface(
            new AndroidVulkanSurfaceProvider(nativeWindow),
            width,
            height,
            vsync: true,
            enableValidation: false,
            streamline: null);

        IRhiDevice device = _vulkanRhi.Device;
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

    [UnmanagedCallersOnly(EntryPoint = "OnGyro")]
    public static void OnGyro(float yawRadians, float pitchRadians)
    {
        _window?.EnqueueGyro(yawRadians, pitchRadians);
    }

    [UnmanagedCallersOnly(EntryPoint = "OnText")]
    public static void OnText(IntPtr textPtr)
    {
        if (textPtr == IntPtr.Zero)
        {
            return;
        }

        string? text = Marshal.PtrToStringUTF8(textPtr);
        if (!string.IsNullOrEmpty(text))
        {
            _window?.EnqueueText(text);
        }
    }

    /// <summary>Whether the shell currently has a text field focused (for the Android soft keyboard).</summary>
    [UnmanagedCallersOnly(EntryPoint = "IsTextFieldFocused")]
    public static int IsTextFieldFocused()
    {
        return _gameHost is { } host && host.IsTextFieldFocused ? 1 : 0;
    }

    /// <summary>Whether the player asked for the soft keyboard via the main-menu keyboard icon.</summary>
    [UnmanagedCallersOnly(EntryPoint = "IsKeyboardRequested")]
    public static int IsKeyboardRequested()
    {
        return _gameHost is { } host && host.KeyboardRequested ? 1 : 0;
    }

    /// <summary>Sets the soft-keyboard request flag (the Android side clears it when Back dismisses the keyboard).</summary>
    [UnmanagedCallersOnly(EntryPoint = "SetKeyboardRequested")]
    public static void SetKeyboardRequested(int value)
    {
        if (_gameHost is { } host)
        {
            host.KeyboardRequested = value != 0;
        }
    }

    [UnmanagedCallersOnly(EntryPoint = "OnResize")]
    public static void OnResize(int width, int height)
    {
        int landscapeWidth = Math.Max(width, height);
        int landscapeHeight = Math.Min(width, height);
        _window?.EnqueueResize(landscapeWidth, landscapeHeight);
    }

    /// <summary>The native window was destroyed (app backgrounded). Marks the surface lost so the loop idles instead of presenting into it.</summary>
    [UnmanagedCallersOnly(EntryPoint = "OnSurfaceLost")]
    public static void OnSurfaceLost()
    {
        if (_activeBackend == RendererBackend.WebGpu)
        {
            _webGpuRhi?.NotifySurfaceLost();
        }
        else
        {
            _vulkanRhi?.Device.NotifySurfaceLost();
        }

    }

    /// <summary>A new native window arrived after the old one was destroyed. Queued for the game thread, which performs the rebind.</summary>
    [UnmanagedCallersOnly(EntryPoint = "OnSurfaceRecreated")]
    public static void OnSurfaceRecreated(nint nativeWindow, int width, int height)
    {
        // A surface can arrive at 0x0 (created before it is laid out); the swapchain
        // needs at least 1x1, and the next resize corrects it to the real size.
        int landscapeWidth = Math.Max(1, Math.Max(width, height));
        int landscapeHeight = Math.Max(1, Math.Min(width, height));
        _window?.EnqueueSurfaceRecreated(nativeWindow, landscapeWidth, landscapeHeight);
    }

    /// <summary>
    /// Rebinds the presentation surface to a new native window, keeping the device and the mission
    /// alive so the player returns to the pause menu in the mission instead of the main menu.
    /// Runs on the game thread (invoked from PumpEvents).
    /// </summary>
    /// <returns>True if the surface was rebound; false if it failed (the caller retries).</returns>
    /// <remarks>
    /// A failed rebind never throws into the frame loop, because a failed rebind must not turn
    /// a backgrounding into a crash. The surface stays lost and the loop keeps idling; the
    /// window retries the rebind a few times, and a restart recovers.
    /// </remarks>
    private static bool RebindSurface(nint nativeWindow, int width, int height)
    {
        try
        {
            width = Math.Max(1, width);
            height = Math.Max(1, height);

            if (_activeBackend == RendererBackend.WebGpu && _webGpuRhi is { } webGpu)
            {
                webGpu.RebindSurface(
                    new WebGpuWindowHandles(WebGpuWindowSystem.Android, nint.Zero, nativeWindow),
                    width,
                    height,
                    vsync: true);
            }
            else if (_vulkanRhi is { } vulkan)
            {
                vulkan.RebindSurface(nativeWindow, width, height, vsync: true);
            }
            else
            {
                return false;
            }

            return true;
        }
        catch (Exception ex)
        {
            return false;
        }
    }

    [UnmanagedCallersOnly(EntryPoint = "Stop")]
    public static void Stop()
    {
        _window?.Close();
    }
}
