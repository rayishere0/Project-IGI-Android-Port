namespace ProjectIGI.Rendering;

/// <summary>The graphics APIs the renderer can run over on the desktop.</summary>
/// <remarks>
/// Named as <c>ProjectIGI_RENDERER</c> and <c>r_renderer</c> name them. Declared here, beside the settings,
/// so the setting the player chooses and the backend the composition root builds are one type.
/// </remarks>
public enum RendererBackend
{
    /// <summary>Whichever this platform draws best over.</summary>
    Auto,

    /// <summary>OpenGL / OpenGL ES: high-performance default for mobile.</summary>
    OpenGL,

    /// <summary>Vulkan: high-fidelity native Vulkan backend.</summary>
    Vulkan,

    /// <summary>WebGL: browser WebGL / WebGPU canvas.</summary>
    WebGL,

    /// <summary>Direct3D 12: the default on Windows.</summary>
    D3D12,

    /// <summary>WebGPU through wgpu-native: the browser's API, run on the desktop to compare against Vulkan.</summary>
    WebGpu,
}

/// <summary>What <see cref="RendererBackend.Auto"/> and a backend this platform lacks come to.</summary>
public static class RendererBackends
{
    /// <summary>Gets the backend a game starts on when nothing names one.</summary>
    public static RendererBackend Default =>
        OperatingSystem.IsAndroid() ? RendererBackend.OpenGL :
        OperatingSystem.IsWindows() ? RendererBackend.D3D12 :
        RendererBackend.OpenGL;

    /// <summary>The backend a choice draws over on this platform.</summary>
    /// <param name="choice">The choice.</param>
    /// <returns><see cref="Default"/> for automatic, or for Direct3D 12 off Windows; otherwise the choice.</returns>
    public static RendererBackend Resolve(RendererBackend choice) =>
        choice switch
        {
            RendererBackend.Auto => Default,
            RendererBackend.D3D12 when !OperatingSystem.IsWindows() => Default,
            _ => choice,
        };
}
