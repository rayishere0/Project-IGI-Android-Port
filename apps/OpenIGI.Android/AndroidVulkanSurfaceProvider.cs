using Silk.NET.Core.Native;
using Silk.NET.Vulkan;
using Silk.NET.Vulkan.Extensions.KHR;
using OpenIGI.Rendering;
using OpenIGI.Rendering.Vulkan;

namespace OpenIGI.Android;

/// <summary>
/// Creates a Vulkan surface directly connected to an Android ANativeWindow*.
/// </summary>
public sealed unsafe class AndroidVulkanSurfaceProvider : IVulkanSurfaceProvider
{
    private readonly nint _nativeWindow;

    public AndroidVulkanSurfaceProvider(nint nativeWindow)
    {
        _nativeWindow = nativeWindow;
    }

    public IReadOnlyList<string> GetRequiredInstanceExtensions() =>
    [
        "VK_KHR_surface",
        "VK_KHR_android_surface"
    ];

    public SurfaceKHR CreateSurface(Vk vk, Instance instance, KhrSurface khrSurface)
    {
        if (!vk.TryGetInstanceExtension(instance, out KhrAndroidSurface khrAndroidSurface))
        {
            throw new GraphicsDeviceException("VK_KHR_android_surface is not available on this Vulkan instance.");
        }

        AndroidSurfaceCreateInfoKHR createInfo = new()
        {
            SType = StructureType.AndroidSurfaceCreateInfoKhr,
            Window = (nint*)_nativeWindow
        };

        Result result = khrAndroidSurface.CreateAndroidSurface(instance, in createInfo, null, out SurfaceKHR surface);
        if (result != Result.Success)
        {
            throw new GraphicsDeviceException($"vkCreateAndroidSurfaceKHR failed: {result}");
        }

        return surface;
    }
}

