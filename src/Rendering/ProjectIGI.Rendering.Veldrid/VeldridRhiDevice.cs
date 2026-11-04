using System;
using System.Collections.Generic;
using System.Text;
using ProjectIGI.Rendering.Rhi;
using ProjectIGI.Shaders;
using Veldrid;

namespace ProjectIGI.Rendering.Veldrid;

public class VeldridRhiDevice : IRhiDevice
{
    private readonly GraphicsDevice _device;

    public string AdapterName => _device.DeviceName;
    public string ApiName => _device.BackendType.ToString();
    public double TimestampPeriodNanoseconds => 1.0;
    public string StreamlineUnavailableReason => "Streamline not available on Veldrid backend";
    public RhiFeatures Features => RhiFeatures.None;
    public ShaderTarget ShaderTarget => _device.BackendType == GraphicsBackend.Vulkan ? ShaderTarget.Spirv : ShaderTarget.Wgsl;
    public RhiLimits Limits { get; } = new RhiLimits();

    public RhiTextureFormat SurfaceFormat => MapPixelFormatToRhiTextureFormat(_device.MainSwapchain?.Framebuffer.ColorTargets[0].Target.Format ?? PixelFormat.R8_G8_B8_A8_UNorm);

    public IRhiAccelerationStructures? AccelerationStructures => null;

    public VeldridRhiDevice(GraphicsDevice device)
    {
        _device = device;
    }

    private PixelFormat MapFormat(RhiTextureFormat format)
    {
        bool isOpenGLES = _device.BackendType == GraphicsBackend.OpenGLES;

        switch (format)
        {
            case RhiTextureFormat.R8Unorm: return PixelFormat.R8_UNorm;
            case RhiTextureFormat.Rg8Unorm: return PixelFormat.R8_G8_UNorm;
            case RhiTextureFormat.Rgba8Unorm: return PixelFormat.R8_G8_B8_A8_UNorm;
            case RhiTextureFormat.Rgba8UnormSrgb: return PixelFormat.R8_G8_B8_A8_UNorm_SRgb;
            case RhiTextureFormat.Bgra8Unorm: return isOpenGLES ? PixelFormat.R8_G8_B8_A8_UNorm : PixelFormat.B8_G8_R8_A8_UNorm;
            case RhiTextureFormat.Bgra8UnormSrgb: return isOpenGLES ? PixelFormat.R8_G8_B8_A8_UNorm_SRgb : PixelFormat.B8_G8_R8_A8_UNorm_SRgb;
            case RhiTextureFormat.R16Float: return PixelFormat.R16_Float;
            case RhiTextureFormat.Rg16Float: return PixelFormat.R16_G16_Float;
            case RhiTextureFormat.Rgba16Float: return PixelFormat.R16_G16_B16_A16_Float;
            case RhiTextureFormat.R32Float: return PixelFormat.R32_Float;
            case RhiTextureFormat.Rg32Float: return PixelFormat.R32_G32_Float;
            case RhiTextureFormat.Rgba32Float: return PixelFormat.R32_G32_B32_A32_Float;
            case RhiTextureFormat.R32Uint: return PixelFormat.R32_UInt;
            case RhiTextureFormat.Rgb10A2Unorm: return PixelFormat.R10_G10_B10_A2_UNorm;
            case RhiTextureFormat.Rg11B10Ufloat: return PixelFormat.R11_G11_B10_Float;
            case RhiTextureFormat.Depth32Float: return PixelFormat.D32_Float_S8_UInt;
            case RhiTextureFormat.Depth24PlusStencil8: return PixelFormat.D24_UNorm_S8_UInt;
            case RhiTextureFormat.Depth16Unorm: return PixelFormat.R16_UNorm; // Mapping D16_UNorm to R16_UNorm as fallback
            case RhiTextureFormat.Bc1RgbaUnorm: return PixelFormat.BC1_Rgba_UNorm;
            case RhiTextureFormat.Bc1RgbaUnormSrgb: return PixelFormat.BC1_Rgba_UNorm_SRgb;
            case RhiTextureFormat.Bc7RgbaUnorm: return PixelFormat.BC7_UNorm;
            case RhiTextureFormat.Bc7RgbaUnormSrgb: return PixelFormat.BC7_UNorm_SRgb;
            default: throw new ArgumentOutOfRangeException(nameof(format), format, null);
        }
    }

    private static RhiTextureFormat MapPixelFormatToRhiTextureFormat(PixelFormat format)
    {
        return RhiTextureFormat.Bgra8Unorm; // Just a dummy mapping
    }

    public void Dispose()
    {
        _device.Dispose();
        GC.SuppressFinalize(this);
    }

    private static BufferUsage MapBufferUsage(RhiBufferUsage usage)
    {
        BufferUsage result = 0;
        if (usage.HasFlag(RhiBufferUsage.Vertex)) result |= BufferUsage.VertexBuffer;
        if (usage.HasFlag(RhiBufferUsage.Index)) result |= BufferUsage.IndexBuffer;
        if (usage.HasFlag(RhiBufferUsage.Uniform)) result |= BufferUsage.UniformBuffer;
        if (usage.HasFlag(RhiBufferUsage.Storage)) result |= BufferUsage.StructuredBufferReadWrite;
        if (usage.HasFlag(RhiBufferUsage.Indirect)) result |= BufferUsage.IndirectBuffer;

        if (result == 0 || usage.HasFlag(RhiBufferUsage.CopyDestination) || usage.HasFlag(RhiBufferUsage.MapWrite) || usage.HasFlag(RhiBufferUsage.MapRead))
        {
            result |= BufferUsage.Dynamic;
        }
        return result;
    }

    public IRhiBuffer CreateBuffer(in RhiBufferDescriptor descriptor)
    {
        BufferUsage usage = MapBufferUsage(descriptor.Usage);
        var buffer = _device.ResourceFactory.CreateBuffer(new BufferDescription((uint)descriptor.SizeInBytes, usage));
        return new VeldridRhiBuffer(buffer, descriptor.SizeInBytes, descriptor.Label);
    }

    public IRhiTexture CreateTexture(in RhiTextureDescriptor descriptor)
    {
        PixelFormat pixelFormat = MapFormat(descriptor.Format);
        bool isDepth = descriptor.Format == RhiTextureFormat.Depth32Float ||
                       descriptor.Format == RhiTextureFormat.Depth24PlusStencil8 ||
                       descriptor.Format == RhiTextureFormat.Depth16Unorm ||
                       pixelFormat == PixelFormat.D24_UNorm_S8_UInt ||
                       pixelFormat == PixelFormat.D32_Float_S8_UInt;

        TextureUsage usage = TextureUsage.Sampled;
        if (isDepth)
        {
            usage |= TextureUsage.DepthStencil;
        }
        if (descriptor.Usage.HasFlag(RhiTextureUsage.RenderTarget))
        {
            usage |= TextureUsage.RenderTarget;
        }
        if (descriptor.Usage.HasFlag(RhiTextureUsage.Storage))
        {
            usage |= TextureUsage.Storage;
        }

        uint width = Math.Max(1u, (uint)descriptor.Width);
        uint height = Math.Max(1u, (uint)descriptor.Height);
        uint mipLevels = Math.Max(1u, (uint)descriptor.MipLevelCount);
        uint depthOrArrayLayers = Math.Max(1u, (uint)descriptor.DepthOrArrayLayers);

        global::Veldrid.TextureDescription desc;
        if (descriptor.Dimension == RhiTextureViewDimension.Texture3D)
        {
            desc = global::Veldrid.TextureDescription.Texture3D(width, height, depthOrArrayLayers, mipLevels, pixelFormat, usage);
        }
        else
        {
            desc = global::Veldrid.TextureDescription.Texture2D(width, height, mipLevels, depthOrArrayLayers, pixelFormat, usage);
        }

        var texture = _device.ResourceFactory.CreateTexture(desc);
        var veldridTex = new VeldridRhiTexture(texture, descriptor.Label) { Format = descriptor.Format, Usage = descriptor.Usage };
        if (usage.HasFlag(TextureUsage.Sampled) || usage.HasFlag(TextureUsage.Storage))
        {
            try
            {
                var view = _device.ResourceFactory.CreateTextureView(texture);
                veldridTex.View = new VeldridRhiTextureView(veldridTex, default) { View = view, Format = descriptor.Format };
            }
            catch { }
        }
        return veldridTex;
    }

    public IRhiTextureView CreateTextureView(IRhiTexture texture)
    {
        if (texture is VeldridRhiTexture veldridTex)
        {
            if (veldridTex.Texture != null && (veldridTex.Texture.Usage.HasFlag(TextureUsage.Sampled) || veldridTex.Texture.Usage.HasFlag(TextureUsage.Storage)))
            {
                try
                {
                    var view = _device.ResourceFactory.CreateTextureView(veldridTex.Texture);
                    return new VeldridRhiTextureView(veldridTex, default) { View = view, Format = veldridTex.Format };
                }
                catch { }
            }
            return new VeldridRhiTextureView(veldridTex, default) { Format = veldridTex.Format };
        }
        throw new ArgumentException("Invalid texture type.", nameof(texture));
    }

    public IRhiSampler CreateSampler(in RhiSamplerDescriptor descriptor)
    {
        var sampler = _device.ResourceFactory.CreateSampler(new global::Veldrid.SamplerDescription());
        return new VeldridRhiSampler(sampler) { Label = descriptor.Label };
    }

    public IRhiShaderModule CreateShaderModule(in RhiShaderModuleDescriptor descriptor)
    {
        return new DummyShaderModule(descriptor);
    }

    public IRhiBindGroupLayout CreateBindGroupLayout(RhiBindGroupLayoutDescriptor descriptor)
    {
        try
        {
            var elements = new ResourceLayoutElementDescription[descriptor.Entries.Count];
            for (int i = 0; i < descriptor.Entries.Count; i++)
            {
                var entry = descriptor.Entries[i];
                ResourceKind kind = entry.Type switch
                {
                    RhiBindingType.UniformBuffer => ResourceKind.UniformBuffer,
                    RhiBindingType.ReadOnlyStorageBuffer or RhiBindingType.StorageBuffer => ResourceKind.StructuredBufferReadOnly,
                    RhiBindingType.SampledTexture => ResourceKind.TextureReadOnly,
                    RhiBindingType.StorageTexture => ResourceKind.TextureReadWrite,
                    RhiBindingType.Sampler or RhiBindingType.ComparisonSampler => ResourceKind.Sampler,
                    _ => ResourceKind.UniformBuffer
                };

                global::Veldrid.ShaderStages stages = 0;
                if (entry.Visibility.HasFlag(RhiShaderStages.Vertex)) stages |= global::Veldrid.ShaderStages.Vertex;
                if (entry.Visibility.HasFlag(RhiShaderStages.Fragment)) stages |= global::Veldrid.ShaderStages.Fragment;
                if (entry.Visibility.HasFlag(RhiShaderStages.Compute)) stages |= global::Veldrid.ShaderStages.Compute;
                if (stages == 0) stages = global::Veldrid.ShaderStages.Vertex | global::Veldrid.ShaderStages.Fragment;

                elements[i] = new ResourceLayoutElementDescription($"element_{entry.Binding}", kind, stages);
            }

            var layout = _device.ResourceFactory.CreateResourceLayout(new ResourceLayoutDescription(elements));
            return new VeldridRhiBindGroupLayout(layout) { Label = descriptor.Label };
        }
        catch (Exception)
        {
            return new VeldridRhiBindGroupLayout(null!) { Label = descriptor.Label };
        }
    }

    public IRhiBindGroup CreateBindGroup(RhiBindGroupDescriptor descriptor)
    {
        try
        {
            if (descriptor.Layout is VeldridRhiBindGroupLayout vLayout && vLayout.Layout != null)
            {
                var resourcesList = new List<BindableResource>();
                for (int i = 0; i < descriptor.Entries.Count; i++)
                {
                    var entry = descriptor.Entries[i];
                    if (entry.Buffer is VeldridRhiBuffer vBuf && vBuf.Buffer != null)
                    {
                        ulong size = entry.Size > 0 ? entry.Size : (vBuf.SizeInBytes - entry.Offset);
                        resourcesList.Add(new DeviceBufferRange(vBuf.Buffer, (uint)entry.Offset, (uint)size));
                    }
                    else if (entry.TextureView is VeldridRhiTextureView vView && vView.View != null)
                    {
                        resourcesList.Add(vView.View);
                    }
                    else if (entry.TextureView?.Texture is VeldridRhiTexture vTex && vTex.Texture != null)
                    {
                        resourcesList.Add(vTex.Texture);
                    }
                    else if (entry.Sampler is VeldridRhiSampler vSamp && vSamp.Sampler != null)
                    {
                        resourcesList.Add(vSamp.Sampler);
                    }
                }

                var set = _device.ResourceFactory.CreateResourceSet(new ResourceSetDescription(vLayout.Layout, resourcesList.ToArray()));
                return new VeldridRhiBindGroup(set) { Label = descriptor.Label };
            }
        }
        catch (Exception)
        {
        }
        return new VeldridRhiBindGroup(null!) { Label = descriptor.Label };
    }

    public IRhiPipelineLayout CreatePipelineLayout(RhiPipelineLayoutDescriptor descriptor)
    {
        try
        {
            var resLayouts = new List<ResourceLayout>();
            if (descriptor.BindGroupLayouts != null)
            {
                foreach (var bgl in descriptor.BindGroupLayouts)
                {
                    if (bgl is VeldridRhiBindGroupLayout vLayout && vLayout.Layout != null)
                    {
                        resLayouts.Add(vLayout.Layout);
                    }
                }
            }

            // Veldrid has no push-constant API, so push data rides a uniform buffer bound as
            // set OPENIGI_PUSH_CONSTANT_GROUP (3); see VeldridRhiRenderPassEncoder.SetPushData.
            // Veldrid numbers sets by position in this list, so the sets between the last bind
            // group and group 3 are padded with empty layouts. If the padding fails, the layout
            // is returned without a push set and SetPushData becomes a no-op, as today.
            if (descriptor.PushDataBytes > 0)
            {
                try
                {
                    while (resLayouts.Count < 3)
                    {
                        resLayouts.Add(_device.ResourceFactory.CreateResourceLayout(new ResourceLayoutDescription()));
                    }

                    global::Veldrid.ShaderStages pushStages = 0;
                    if (descriptor.PushDataVisibility.HasFlag(RhiShaderStages.Vertex)) pushStages |= global::Veldrid.ShaderStages.Vertex;
                    if (descriptor.PushDataVisibility.HasFlag(RhiShaderStages.Fragment)) pushStages |= global::Veldrid.ShaderStages.Fragment;
                    if (descriptor.PushDataVisibility.HasFlag(RhiShaderStages.Compute)) pushStages |= global::Veldrid.ShaderStages.Compute;
                    if (pushStages == 0) pushStages = global::Veldrid.ShaderStages.Vertex | global::Veldrid.ShaderStages.Fragment;

                    resLayouts.Add(_device.ResourceFactory.CreateResourceLayout(new ResourceLayoutDescription(
                        new ResourceLayoutElementDescription("push", ResourceKind.UniformBuffer, pushStages))));
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"[VeldridRhiDevice] Could not add push-data layout to '{descriptor.Label}': {ex.Message}");
                }
            }

            return new VeldridRhiPipelineLayout() { Label = descriptor.Label, ResourceLayouts = resLayouts.ToArray() };
        }
        catch (Exception)
        {
            return new VeldridRhiPipelineLayout() { Label = descriptor.Label };
        }
    }

    private static VertexLayoutDescription[] MapVertexLayouts(IReadOnlyList<RhiVertexBufferLayout>? layouts)
    {
        if (layouts == null || layouts.Count == 0) return Array.Empty<VertexLayoutDescription>();

        var vLayouts = new VertexLayoutDescription[layouts.Count];
        for (int i = 0; i < layouts.Count; i++)
        {
            var rhiLayout = layouts[i];
            var elements = new VertexElementDescription[rhiLayout.Attributes.Count];
            for (int j = 0; j < rhiLayout.Attributes.Count; j++)
            {
                var attr = rhiLayout.Attributes[j];
                VertexElementFormat fmt = attr.Format switch
                {
                    RhiVertexFormat.Float32 => VertexElementFormat.Float1,
                    RhiVertexFormat.Float32x2 => VertexElementFormat.Float2,
                    RhiVertexFormat.Float32x3 => VertexElementFormat.Float3,
                    RhiVertexFormat.Float32x4 => VertexElementFormat.Float4,
                    RhiVertexFormat.Unorm8x4 => VertexElementFormat.Byte4_Norm,
                    RhiVertexFormat.Uint8x4 => VertexElementFormat.Byte4,
                    RhiVertexFormat.Uint32 => VertexElementFormat.UInt1,
                    _ => VertexElementFormat.Float4
                };
                elements[j] = new VertexElementDescription($"attr_{attr.Location}", VertexElementSemantic.TextureCoordinate, fmt);
            }
            vLayouts[i] = new VertexLayoutDescription((uint)rhiLayout.Stride, elements);
        }
        return vLayouts;
    }

    /// <summary>Gets a module's SPIR-V for Veldrid, preferring the variant compiled without push constants.</summary>
    /// <remarks>
    /// Veldrid cannot set Vulkan push constants: its pipeline layouts carry no push range, and its
    /// command lists expose no push API. So the Veldrid build of each push-using module compiles the
    /// push block as a group-3 uniform buffer (OPENIGI_NO_PUSH_CONSTANTS), which
    /// <see cref="VeldridRhiRenderPassEncoder.SetPushData"/> feeds from a ring. Until that variant is
    /// built, this falls back to the requested variant, preserving today's behaviour (the push block
    /// reads zero) rather than failing pipeline creation.
    /// </remarks>
    private static ReadOnlyMemory<byte> GetSpirvForVeldrid(ShaderModuleId module, ShaderVariant variant)
    {
        try
        {
            return ShaderCatalog.GetSpirv(module, new ShaderVariant("veldrid"));
        }
        catch (InvalidOperationException)
        {
            return ShaderCatalog.GetSpirv(module, variant);
        }
    }

    public IRhiRenderPipeline CreateRenderPipeline(RhiRenderPipelineDescriptor descriptor)
    {
        bool isDeferredEnabled = LightingCVars.Deferred.Value;
        bool isDeferredPass = descriptor.Label?.Contains("Deferred") == true || descriptor.Label?.Contains("Occlusion") == true;

        if (isDeferredPass && !isDeferredEnabled)
        {
            return new VeldridRhiRenderPipeline(null!) { Label = descriptor.Label };
        }

        try
        {
            var vertMod = descriptor.Vertex.Module as DummyShaderModule;
            var fragMod = descriptor.Fragment?.Module as DummyShaderModule;

            if (vertMod == null)
            {
                return new VeldridRhiRenderPipeline(null!) { Label = descriptor.Label };
            }

            Shader[] shaders;

            if (_device.BackendType == GraphicsBackend.Vulkan)
            {
                ReadOnlyMemory<byte> vertSpv = GetSpirvForVeldrid(vertMod.Descriptor.Module, vertMod.Descriptor.Variant);
                string vertEntryPoint = string.IsNullOrWhiteSpace(descriptor.Vertex.EntryPoint) ? "main" : descriptor.Vertex.EntryPoint;
                var vertDesc = new ShaderDescription(global::Veldrid.ShaderStages.Vertex, vertSpv.ToArray(), vertEntryPoint);
                var vertShader = _device.ResourceFactory.CreateShader(vertDesc);

                if (fragMod != null)
                {
                    ReadOnlyMemory<byte> fragSpv = GetSpirvForVeldrid(fragMod.Descriptor.Module, fragMod.Descriptor.Variant);
                    string fragEntryPoint = string.IsNullOrWhiteSpace(descriptor.Fragment?.EntryPoint) ? "main" : descriptor.Fragment!.EntryPoint;
                    var fragDesc = new ShaderDescription(global::Veldrid.ShaderStages.Fragment, fragSpv.ToArray(), fragEntryPoint);
                    var fragShader = _device.ResourceFactory.CreateShader(fragDesc);

                    shaders = new[] { vertShader, fragShader };
                }
                else
                {
                    shaders = new[] { vertShader };
                }
            }
            else
            {
                // Direct GLSL/ESSL 300 shader creation path for OpenGLES/OpenGL
                string rawGlsl = "";
                try { rawGlsl = ShaderCatalog.GetGlslEs(vertMod.Descriptor.Module, vertMod.Descriptor.Variant); } catch { }

                string vertGlsl;
                if (!string.IsNullOrEmpty(rawGlsl))
                {
                    vertGlsl = rawGlsl.Contains("#version 300 es")
                        ? rawGlsl.Replace("#version 300 es", "#version 300 es\n#define VERTEX 1\n")
                        : "#version 300 es\n#define VERTEX 1\n" + rawGlsl;
                }
                else
                {
                    vertGlsl = "#version 300 es\nprecision mediump float;\nlayout(location = 0) in vec2 aPos;\nlayout(location = 1) in vec2 aUv;\nlayout(location = 2) in vec4 aColor;\nout vec2 vUv;\nout vec4 vColor;\nvoid main() { vUv = aUv; vColor = aColor; gl_Position = vec4(aPos, 0.0, 1.0); }";
                }

                string vertEntryPoint = string.IsNullOrWhiteSpace(descriptor.Vertex.EntryPoint) ? "main" : descriptor.Vertex.EntryPoint;
                var vertDesc = new ShaderDescription(global::Veldrid.ShaderStages.Vertex, Encoding.UTF8.GetBytes(vertGlsl), vertEntryPoint);
                var vertShader = _device.ResourceFactory.CreateShader(vertDesc);

                if (fragMod != null)
                {
                    string fragRawGlsl = "";
                    try { fragRawGlsl = ShaderCatalog.GetGlslEs(fragMod.Descriptor.Module, fragMod.Descriptor.Variant); } catch { }

                    string fragGlsl;
                    if (!string.IsNullOrEmpty(fragRawGlsl))
                    {
                        fragGlsl = fragRawGlsl.Contains("#version 300 es")
                            ? fragRawGlsl.Replace("#version 300 es", "#version 300 es\n#define FRAGMENT 1\n")
                            : "#version 300 es\n#define FRAGMENT 1\n" + fragRawGlsl;
                    }
                    else
                    {
                        fragGlsl = "#version 300 es\nprecision mediump float;\nin vec2 vUv;\nin vec4 vColor;\nout vec4 fragColor;\nuniform sampler2D uTexture;\nvoid main() { fragColor = texture(uTexture, vUv) * vColor; }";
                    }

                    string fragEntryPoint = string.IsNullOrWhiteSpace(descriptor.Fragment?.EntryPoint) ? "main" : descriptor.Fragment!.EntryPoint;
                    var fragDesc = new ShaderDescription(global::Veldrid.ShaderStages.Fragment, Encoding.UTF8.GetBytes(fragGlsl), fragEntryPoint);
                    var fragShader = _device.ResourceFactory.CreateShader(fragDesc);

                    shaders = new[] { vertShader, fragShader };
                }
                else
                {
                    shaders = new[] { vertShader };
                }
            }

            VertexLayoutDescription[] vLayouts = MapVertexLayouts(descriptor.VertexBuffers);

            ResourceLayout[] resLayouts = Array.Empty<ResourceLayout>();
            if (descriptor.Layout is VeldridRhiPipelineLayout vPipelineLayout && vPipelineLayout.ResourceLayouts != null)
            {
                resLayouts = vPipelineLayout.ResourceLayouts;
            }

            var pipelineDesc = new GraphicsPipelineDescription(
                BlendStateDescription.SingleAlphaBlend,
                DepthStencilStateDescription.Disabled,
                RasterizerStateDescription.CullNone,
                PrimitiveTopology.TriangleList,
                new ShaderSetDescription(vLayouts, shaders),
                resLayouts,
                _device.MainSwapchain?.Framebuffer?.OutputDescription ?? _device.SwapchainFramebuffer.OutputDescription);

            var pipeline = _device.ResourceFactory.CreateGraphicsPipeline(pipelineDesc);
            return new VeldridRhiRenderPipeline(pipeline) { Label = descriptor.Label, Layout = descriptor.Layout };
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[VeldridRhiDevice] Error creating render pipeline '{descriptor.Label}': {ex}");
            return new VeldridRhiRenderPipeline(null!) { Label = descriptor.Label };
        }
    }

    public IRhiComputePipeline CreateComputePipeline(RhiComputePipelineDescriptor descriptor)
    {
        try
        {
            var compMod = descriptor.Compute.Module as DummyShaderModule;
            if (compMod == null) return new VeldridRhiComputePipeline(null!) { Label = descriptor.Label };

            Shader shader;
            if (_device.BackendType == GraphicsBackend.Vulkan)
            {
                ReadOnlyMemory<byte> compSpv = ShaderCatalog.GetSpirv(compMod.Descriptor.Module, compMod.Descriptor.Variant);
                string entryPoint = string.IsNullOrWhiteSpace(descriptor.Compute.EntryPoint) ? "main" : descriptor.Compute.EntryPoint;
                var compDesc = new ShaderDescription(global::Veldrid.ShaderStages.Compute, compSpv.ToArray(), entryPoint);
                shader = _device.ResourceFactory.CreateShader(compDesc);
            }
            else
            {
                string compGlsl = "";
                try { compGlsl = ShaderCatalog.GetGlslEs(compMod.Descriptor.Module, compMod.Descriptor.Variant); } catch { }
                if (string.IsNullOrEmpty(compGlsl))
                {
                    compGlsl = "#version 300 es\nlayout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;\nvoid main() {}";
                }

                string entryPoint = string.IsNullOrWhiteSpace(descriptor.Compute.EntryPoint) ? "main" : descriptor.Compute.EntryPoint;
                var compDesc = new ShaderDescription(global::Veldrid.ShaderStages.Compute, Encoding.UTF8.GetBytes(compGlsl), entryPoint);
                shader = _device.ResourceFactory.CreateShader(compDesc);
            }

            var computePipelineDesc = new ComputePipelineDescription(
                shader,
                Array.Empty<ResourceLayout>(),
                1, 1, 1);
            var pipeline = _device.ResourceFactory.CreateComputePipeline(computePipelineDesc);
            return new VeldridRhiComputePipeline(pipeline) { Label = descriptor.Label };
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[VeldridRhiDevice] Error creating compute pipeline '{descriptor.Label}': {ex}");
            return new VeldridRhiComputePipeline(null!) { Label = descriptor.Label };
        }
    }

    public IRhiQuerySet CreateQuerySet(in RhiQuerySetDescriptor descriptor) => new VeldridRhiQuerySet() { Label = descriptor.Label, Type = descriptor.Type, Count = descriptor.Count };

    public IRhiCommandEncoder CreateCommandEncoder(string label = "")
    {
        var cl = _device.ResourceFactory.CreateCommandList();
        return new VeldridRhiCommandEncoder(_device, cl, label);
    }

    public void Submit(ReadOnlySpan<IRhiCommandBuffer> commands)
    {
        if (_device == null) return;

        foreach (var cmd in commands)
        {
            if (cmd is VeldridRhiCommandBuffer vCmd && vCmd.CommandList != null)
            {
                try
                {
                    _device.SubmitCommands(vCmd.CommandList);
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"[VeldridRhiDevice] Error in Submit: {ex}");
                }
            }
        }
    }

    public void Flush() { _device?.WaitForIdle(); }
    public void WriteBuffer(IRhiBuffer buffer, ulong offset, ReadOnlySpan<byte> data)
    {
        if (buffer is VeldridRhiBuffer veldridBuf && veldridBuf.Buffer != null && _device != null)
        {
            unsafe
            {
                fixed (byte* ptr = data)
                {
                    _device.UpdateBuffer(veldridBuf.Buffer, (uint)offset, (nint)ptr, (uint)data.Length);
                }
            }
        }
        else if (buffer == null)
        {
            return;
        }
        else
        {
            throw new ArgumentException("Invalid buffer type passed to WriteBuffer.", nameof(buffer));
        }
    }

    public void WriteTexture<T>(in RhiTextureRegion destination, ReadOnlySpan<T> data, int bytesPerRow, in RhiExtent3D size) where T : unmanaged
    {
        if (destination.Texture is VeldridRhiTexture veldridTex)
        {
            var tex = veldridTex.Texture;
            if (tex == null || _device == null) return;

            uint mipLevel = (uint)Math.Clamp(destination.MipLevel, 0, (int)Math.Max(1u, tex.MipLevels) - 1);

            // Calculate target dimensions for the specific mip level
            uint targetWidth = Math.Max(1u, tex.Width >> (int)mipLevel);
            uint targetHeight = Math.Max(1u, tex.Height >> (int)mipLevel);
            uint targetDepth = Math.Max(1u, tex.Depth >> (int)mipLevel);

            // Clamp offsets and sizes safely
            uint x = (uint)Math.Clamp(destination.Origin.X, 0, (int)targetWidth);
            uint y = (uint)Math.Clamp(destination.Origin.Y, 0, (int)targetHeight);
            uint z = (uint)Math.Clamp(destination.Origin.Z, 0, (int)targetDepth);
            uint w = Math.Min((uint)Math.Max(0, size.Width), targetWidth - x);
            uint h = Math.Min((uint)Math.Max(0, size.Height), targetHeight - y);
            uint d = Math.Min((uint)Math.Max(0, size.DepthOrArrayLayers), targetDepth - z);

            if (w == 0 || h == 0 || d == 0) return;

            unsafe
            {
                fixed (T* ptr = data)
                {
                    _device.UpdateTexture(
                        tex,
                        (nint)ptr,
                        (uint)(data.Length * sizeof(T)),
                        x, y, z,
                        w, h, d,
                        mipLevel,
                        0);
                }
            }
        }
        else
        {
            throw new ArgumentException("Invalid texture type passed to WriteTexture.", nameof(destination));
        }
    }
    public IRhiReadback ReadBuffer(IRhiBuffer buffer, ulong offset = 0, ulong sizeInBytes = 0) => new VeldridRhiReadback() { SizeInBytes = sizeInBytes };

    private VeldridRhiTextureView? _swapchainView;

    public bool BeginFrame(out RhiFrame frame)
    {
        _commandListIndex = 0;

        if (_device == null)
        {
            frame = default;
            return false;
        }

        Framebuffer? fb = _device.MainSwapchain?.Framebuffer ?? _device.SwapchainFramebuffer;
        if (fb == null)
        {
            frame = default;
            return false;
        }

        uint width = fb.Width;
        uint height = fb.Height;

        Texture? swapchainTex = (fb.ColorTargets.Count > 0) ? fb.ColorTargets[0].Target : null;
        if (swapchainTex != null)
        {
            var veldridTex = new VeldridRhiTexture(swapchainTex, "swapchain")
            {
                Format = MapPixelFormatToRhiTextureFormat(swapchainTex.Format)
            };
            _swapchainView = new VeldridRhiTextureView(veldridTex, default) { Format = veldridTex.Format };
        }

        if (_swapchainView == null)
        {
            frame = default;
            return false;
        }

        frame = new RhiFrame(_swapchainView, 0, 0);
        return true;
    }

    public bool EndFrame(in RhiFrame frame)
    {
        if (_device == null) return false;

        try
        {
            if (_device.MainSwapchain != null)
            {
                _device.SwapBuffers(_device.MainSwapchain);
            }
            else
            {
                _device.SwapBuffers();
            }

            if (_device.BackendType == GraphicsBackend.Vulkan)
            {
                _device.WaitForIdle();
            }

            return true;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[VeldridRhiDevice] Error in EndFrame: {ex}");
            return false;
        }
    }

    public void ConfigureSurface(int width, int height, bool vsync)
    {
        if (_device == null || width <= 0 || height <= 0) return;

        try
        {
            if (_device.MainSwapchain != null)
            {
                _device.ResizeMainWindow((uint)width, (uint)height);
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[VeldridRhiDevice] Error in ConfigureSurface: {ex}");
        }
        // The resize just destroyed the old swapchain's images; any framebuffer the
        // encoder cached against them is dangling now.
        VeldridRhiCommandEncoder.InvalidateFramebufferCache();
        _swapchainView = null;
    }

    public void WaitIdle() => _device?.WaitForIdle();

    public IRhiWorkMarker MarkSubmittedWork() => new VeldridRhiWorkMarker();
}

public class DummyShaderModule : IRhiShaderModule
{
    public RhiShaderModuleDescriptor Descriptor { get; }
    public string Label { get; set; } = string.Empty;

    public DummyShaderModule(RhiShaderModuleDescriptor descriptor)
    {
        Descriptor = descriptor;
        Label = descriptor.Label;
    }

    public void Dispose() { }
}
