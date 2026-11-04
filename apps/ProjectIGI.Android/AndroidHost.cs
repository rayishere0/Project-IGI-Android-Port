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
using ProjectIGI.Rendering.Veldrid;
using Veldrid;

// The native bridge (app/android/app/src/main/cpp/jni/jni_bridge.cpp) resolves this type by the
// literal string "OpenIGI.Android.AndroidHost", so the namespace is part of the ABI, not a naming
// preference. It stays OpenIGI.* even though the projects are named ProjectIGI.*.
namespace OpenIGI.Android;

public static class AndroidHost
{
    private static GameHost? _gameHost;
    private static AndroidGameWindow? _window;
    private static ProjectIGI.Rendering.Pipeline.GraphicsDevice? _device;
    private static LogRouter? _logger;

    public delegate int RunCallback(nint nativeWindow, int width, int height, nint dataDirPtr, nint optionsPtr);
    public delegate void TouchCallback(int action, int pointerId, float x, float y);
    public delegate void KeyCallback(int keyCode, int down);
    public delegate void ResizeCallback(int width, int height);
    public delegate void StopCallback();

    private static DllImportResolver? _openAlResolver;

    [DllImport("projectigi", EntryPoint = "veldrid_get_egl_context")]
    private static extern nint GetEglContext();

    [DllImport("projectigi", EntryPoint = "veldrid_get_proc_address")]
    private static extern nint GetProcAddress([MarshalAs(UnmanagedType.LPStr)] string name);

    [DllImport("projectigi", EntryPoint = "veldrid_cache_egl_state")]
    private static extern void CacheEglState();

    [DllImport("projectigi", EntryPoint = "veldrid_make_current")]
    private static extern void MakeCurrent(nint context);

    [DllImport("projectigi", EntryPoint = "veldrid_swap_buffers")]
    private static extern void SwapBuffers();

    [DllImport("projectigi", EntryPoint = "get_current_jni_env")]
    public static extern nint GetCurrentJniEnv();

    [DllImport("projectigi", EntryPoint = "get_android_surface_global_ref")]
    public static extern nint GetAndroidSurfaceGlobalRef();

    [DllImport("projectigi", EntryPoint = "veldrid_init_egl_on_current_thread")]
    public static extern bool InitEglOnCurrentThread();

    private static void ClearCurrentContext()
    {
        MakeCurrent(nint.Zero);
    }

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

            string? backendSetting = SettingsFile.ReadAssignment(settingsPath, "r_backend");
            if (string.IsNullOrEmpty(backendSetting))
            {
                backendSetting = SettingsFile.ReadAssignment(settingsPath, "r_renderer");
            }
            if (string.IsNullOrEmpty(backendSetting))
            {
                backendSetting = "opengl";
            }
            bool useVulkan = backendSetting.Equals("vulkan", StringComparison.OrdinalIgnoreCase);

            // Enforce maximum speed profile on Android mobile unconditionally:
            LightingCVars.Deferred.Value = false;
            FrameCVars.OffscreenScene.Value = false;
            LightingCVars.Lighting.Value = LightingModel.Baked;

            if (!settingsExist)
            {
                // Enforce maximum speed profile on Android mobile by default on initial launch:
                GraphicsPresetRegistry.Default.Apply(GraphicsPreset.Vanilla);
                FrameCVars.MissionWarmUp.Value = 25;
                DisplayCVars.Renderer.Value = useVulkan ? RendererBackend.Vulkan : RendererBackend.OpenGL;
                DisplayCVars.Backend.Value = useVulkan ? "vulkan" : "opengl";
                ReconstructionCVars.FrameLimit.Value = 30;
            }

            AppDomain.CurrentDomain.FirstChanceException += (sender, args) =>
            {
                _logger?.Information("AndroidHost", $"[FirstChanceException] {args.Exception.GetType().Name}: {args.Exception.Message}");
            };

            nint jniEnv = GetCurrentJniEnv();

            if (landscapeWidth <= 0) landscapeWidth = 1280;
            if (landscapeHeight <= 0) landscapeHeight = 720;

            Veldrid.GraphicsDevice? veldridGd = null;
            if (useVulkan)
            {
                _logger.Information("AndroidHost", "Initializing Veldrid GraphicsDevice with Vulkan 1.1 backend and Swapchain.");
                DisplayCVars.Renderer.Value = RendererBackend.Vulkan;
                DisplayCVars.Backend.Value = "vulkan";

                var vOptions = new GraphicsDeviceOptions(
                    debug: true,
                    swapchainDepthFormat: PixelFormat.D24_UNorm_S8_UInt,
                    syncToVerticalBlank: true,
                    resourceBindingModel: ResourceBindingModel.Improved);

                try
                {
                    nint surfaceJObject = GetAndroidSurfaceGlobalRef();
                    nint env = GetCurrentJniEnv();
                    _logger.Information("AndroidHost", $"Creating Veldrid Vulkan surface with Surface JObject: 0x{surfaceJObject:X}, JNIEnv: 0x{env:X}");

                    if (surfaceJObject == nint.Zero)
                    {
                        _logger.Error("AndroidHost", "ERROR: Native surface JObject handle is IntPtr.Zero!");
                        throw new InvalidOperationException("Native surface JObject handle is IntPtr.Zero!");
                    }

                    if (env == nint.Zero)
                    {
                        _logger.Error("AndroidHost", "ERROR: JNIEnv handle is IntPtr.Zero!");
                        throw new InvalidOperationException("JNIEnv handle is IntPtr.Zero!");
                    }

                    var scSource = SwapchainSource.CreateAndroidSurface(surfaceJObject, env);
                    var scDesc = new SwapchainDescription(
                        scSource,
                        (uint)landscapeWidth,
                        (uint)landscapeHeight,
                        vOptions.SwapchainDepthFormat,
                        vOptions.SyncToVerticalBlank,
                        vOptions.SwapchainSrgbFormat);

                    veldridGd = Veldrid.GraphicsDevice.CreateVulkan(vOptions, scDesc);
                }
                catch (Exception ex)
                {
                    _logger.Error("AndroidHost", "Failed to create Veldrid Vulkan GraphicsDevice! Falling back to OpenGL ES...", ex);
                    useVulkan = false;
                    DisplayCVars.Renderer.Value = RendererBackend.OpenGL;
                    DisplayCVars.Backend.Value = "opengl";
                }
            }

            if (!useVulkan)
            {
                _logger.Information("AndroidHost", "Binding OpenGL ES context to GraphicsDevice via Veldrid.");
                DisplayCVars.Renderer.Value = RendererBackend.OpenGL;
                DisplayCVars.Backend.Value = "opengl";

                nint currentEglContext = GetEglContext();
                if (currentEglContext == nint.Zero)
                {
                    _logger.Information("AndroidHost", "No active EGL context. Initializing EglManager on current thread for GLES fallback...");
                    bool eglOk = InitEglOnCurrentThread();
                    _logger.Information("AndroidHost", $"InitEglOnCurrentThread returned: {eglOk}");
                    currentEglContext = GetEglContext();
                }

                if (currentEglContext == nint.Zero)
                {
                    MakeCurrent((nint)1);
                    currentEglContext = GetEglContext();
                }

                CacheEglState();

                if (currentEglContext == nint.Zero)
                {
                    _logger.Error("AndroidHost", "FATAL: No EGL context current on game thread!");
                }
                else
                {
                    _logger.Information("AndroidHost", $"EGL context active on game thread: 0x{currentEglContext:X}");
                }

                var platformInfo = new Veldrid.OpenGL.OpenGLPlatformInfo(
                    openGLContextHandle: GetEglContext(),
                    getProcAddress: name => GetProcAddress(name),
                    makeCurrent: ctx => MakeCurrent(ctx),
                    getCurrentContext: () => GetEglContext(),
                    clearCurrentContext: () => MakeCurrent(IntPtr.Zero),
                    deleteContext: _ => { },
                    swapBuffers: () => SwapBuffers(),
                    setSyncToVerticalBlank: _ => { });

                var vOptions = new GraphicsDeviceOptions(
                    debug: false,
                    swapchainDepthFormat: PixelFormat.D24_UNorm_S8_UInt,
                    syncToVerticalBlank: true,
                    resourceBindingModel: ResourceBindingModel.Improved);

                veldridGd = Veldrid.GraphicsDevice.CreateOpenGL(
                    vOptions,
                    platformInfo,
                    (uint)landscapeWidth,
                    (uint)landscapeHeight);
            }

            var rhiDevice = new VeldridRhiDevice(veldridGd!);
            _device = new ProjectIGI.Rendering.Pipeline.GraphicsDevice(
                rhiDevice,
                new DisplayMode(landscapeWidth, landscapeHeight, 32, 60),
                captureFrames: options.ScreenshotPath is not null,
                logger: _logger);

            _logger.Information("AndroidHost", $"Veldrid initialized on adapter: {rhiDevice.AdapterName}");
            rhiDevice.ConfigureSurface(landscapeWidth, landscapeHeight, true);
            _logger.Information("AndroidHost", $"Configured Veldrid surface dimensions: {landscapeWidth}x{landscapeHeight}");

            ProjectIGI.Rendering.Generated.CVarRegistrations.RegisterAll();
            ProjectIGI.Game.Generated.CVarRegistrations.RegisterAll();

            RendererBackend chosenBackend = DisplayCVars.Renderer.Value;
            if (chosenBackend == RendererBackend.Auto)
            {
                chosenBackend = useVulkan ? RendererBackend.Vulkan : RendererBackend.OpenGL;
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
            _window?.Dispose();
            _window = null;
        }
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

    [DllImport("vulkan", EntryPoint = "vkCreateAndroidSurfaceKHR")]
    private static extern unsafe int vkCreateAndroidSurfaceKHR(
        nint instance,
        AndroidSurfaceCreateInfoKHR* pCreateInfo,
        void* pAllocator,
        nint* pSurface);

    private struct AndroidSurfaceCreateInfoKHR
    {
        public int sType;
        public nint pNext;
        public uint flags;
        public nint window;
    }

    private static unsafe Silk.NET.Vulkan.Result CreateAndroidSurface(nint instanceHandle, nint nativeWindow, out Silk.NET.Vulkan.SurfaceKHR surface)
    {
        surface = default;
        AndroidSurfaceCreateInfoKHR createInfo = new()
        {
            sType = 1000008000, // VK_STRUCTURE_TYPE_ANDROID_SURFACE_CREATE_INFO_KHR
            window = nativeWindow
        };

        nint surfaceHandle = 0;
        int result = vkCreateAndroidSurfaceKHR(instanceHandle, &createInfo, null, &surfaceHandle);
        surface = new Silk.NET.Vulkan.SurfaceKHR((ulong)(long)surfaceHandle);
        return (Silk.NET.Vulkan.Result)result;
    }
}