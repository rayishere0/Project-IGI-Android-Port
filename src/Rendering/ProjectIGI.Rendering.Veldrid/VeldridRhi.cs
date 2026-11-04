using System;
using System.Text;
using ProjectIGI.Rendering.Rhi;
using Veldrid;

namespace ProjectIGI.Rendering.Veldrid;

public class VeldridRhiBuffer : IRhiBuffer
{
    public DeviceBuffer Buffer { get; }
    public ulong SizeInBytes { get; }
    public string Label { get; set; }
    public RhiBufferUsage Usage { get; set; }

    public VeldridRhiBuffer(DeviceBuffer buffer, ulong sizeInBytes, string label)
    {
        Buffer = buffer;
        SizeInBytes = sizeInBytes;
        Label = label;
    }

    public void Dispose() => Buffer?.Dispose();
}

public class VeldridRhiTexture : IRhiTexture
{
    public Texture Texture { get; }
    public string Label { get; set; }
    public int Width => Texture != null ? (int)Texture.Width : 0;
    public int Height => Texture != null ? (int)Texture.Height : 0;
    public int DepthOrArrayLayers => Texture != null ? (int)Texture.Depth : 0;
    public int MipLevelCount => Texture != null ? (int)Texture.MipLevels : 0;
    public int SampleCount => Texture != null ? (int)Texture.SampleCount : 0;
    public RhiTextureFormat Format { get; set; }
    public RhiTextureUsage Usage { get; set; }
    public IRhiTextureView View { get; set; } = null!;

    public VeldridRhiTexture(Texture texture, string label)
    {
        Texture = texture;
        Label = label;
    }

    public IRhiTextureView CreateView(in RhiTextureViewDescriptor descriptor)
    {
        return new VeldridRhiTextureView(this, descriptor);
    }

    public void Dispose() => Texture?.Dispose();
}

public class VeldridRhiTextureView : IRhiTextureView
{
    IRhiTexture IRhiTextureView.Texture => Texture;
    public VeldridRhiTexture Texture { get; }
    public RhiTextureViewDescriptor Descriptor { get; }
    public TextureView View { get; set; } = null!;
    public RhiTextureFormat Format { get; set; }
    public string Label { get; set; } = string.Empty;

    public VeldridRhiTextureView(VeldridRhiTexture texture, RhiTextureViewDescriptor descriptor)
    {
        Texture = texture;
        Descriptor = descriptor;
    }

    public void Dispose() => View?.Dispose();
}

public class VeldridRhiSampler : IRhiSampler
{
    public Sampler Sampler { get; }
    public string Label { get; set; } = string.Empty;

    public VeldridRhiSampler(Sampler sampler)
    {
        Sampler = sampler;
    }

    public void Dispose() => Sampler?.Dispose();
}

public class VeldridRhiShaderModule : IRhiShaderModule
{
    public Shader[] Shaders { get; }
    public string Label { get; set; } = string.Empty;

    public VeldridRhiShaderModule(Shader[] shaders)
    {
        Shaders = shaders;
    }

    public void Dispose()
    {
        if (Shaders != null)
        {
            foreach (var s in Shaders) s?.Dispose();
        }
    }
}

public class VeldridRhiBindGroupLayout : IRhiBindGroupLayout
{
    public ResourceLayout Layout { get; }
    public string Label { get; set; } = string.Empty;
    public VeldridRhiBindGroupLayout(ResourceLayout layout) => Layout = layout;
    public void Dispose() => Layout?.Dispose();
}

public class VeldridRhiBindGroup : IRhiBindGroup
{
    public ResourceSet Set { get; }
    public string Label { get; set; } = string.Empty;
    public VeldridRhiBindGroup(ResourceSet set) => Set = set;
    public void Dispose() => Set?.Dispose();
}

public class VeldridRhiPipelineLayout : IRhiPipelineLayout
{
    public ResourceLayout[] ResourceLayouts { get; set; } = Array.Empty<ResourceLayout>();
    public string Label { get; set; } = string.Empty;

    public VeldridRhiPipelineLayout() { }

    public void Dispose()
    {
        if (ResourceLayouts != null)
        {
            foreach (var rl in ResourceLayouts)
            {
                rl?.Dispose();
            }
        }
    }
}

public class VeldridRhiRenderPipeline : IRhiRenderPipeline
{
    public Pipeline Pipeline { get; }
    public IRhiPipelineLayout Layout { get; set; } = null!;
    public string Label { get; set; } = string.Empty;
    public VeldridRhiRenderPipeline(Pipeline pipeline) => Pipeline = pipeline;
    public void Dispose() => Pipeline?.Dispose();
}

public class VeldridRhiComputePipeline : IRhiComputePipeline
{
    public Pipeline Pipeline { get; }
    public IRhiPipelineLayout Layout { get; set; } = null!;
    public string Label { get; set; } = string.Empty;
    public VeldridRhiComputePipeline(Pipeline pipeline) => Pipeline = pipeline;
    public void Dispose() => Pipeline?.Dispose();
}

public class VeldridRhiQuerySet : IRhiQuerySet
{
    public RhiQueryType Type { get; set; }
    public int Count { get; set; }
    public string Label { get; set; } = string.Empty;
    public void Dispose() { }
}

public class VeldridRhiCommandEncoder : IRhiCommandEncoder
{
    public global::Veldrid.GraphicsDevice Device { get; }
    public CommandList CommandList { get; }
    public string Label { get; set; }
    private bool _isRecording;

    public VeldridRhiCommandEncoder(global::Veldrid.GraphicsDevice device, CommandList commandList, string label)
    {
        Device = device;
        CommandList = commandList;
        Label = label;
    }

    public void EnsureRecording()
    {
        if (!_isRecording && CommandList != null)
        {
            CommandList.Begin();
            _isRecording = true;
        }
    }

    private static readonly System.Collections.Concurrent.ConcurrentDictionary<string, Framebuffer> FbCache = new();

    private Framebuffer? GetOrCreateFramebuffer(Texture? depthTarget, Texture[] colorTargets)
    {
        if (Device == null) return null;
        if (colorTargets.Length == 0 && depthTarget == null) return null;

        StringBuilder sb = new StringBuilder();
        if (depthTarget != null)
        {
            sb.Append("D:").Append(depthTarget.GetHashCode()).Append(";");
        }
        for (int i = 0; i < colorTargets.Length; i++)
        {
            if (colorTargets[i] != null)
            {
                sb.Append("C").Append(i).Append(":").Append(colorTargets[i].GetHashCode()).Append(";");
            }
        }
        string key = sb.ToString();

        return FbCache.GetOrAdd(key, _ =>
        {
            var fbDesc = new FramebufferDescription(depthTarget, colorTargets);
            return Device.ResourceFactory.CreateFramebuffer(fbDesc);
        });
    }

    public IRhiRenderPassEncoder BeginRenderPass(RhiRenderPassDescriptor descriptor)
    {
        EnsureRecording();

        if (CommandList != null && descriptor != null)
        {
            Framebuffer? targetFramebuffer = null;
            Framebuffer swapchainFb = Device.MainSwapchain?.Framebuffer ?? Device.SwapchainFramebuffer;

            if (descriptor.ColorAttachments != null && descriptor.ColorAttachments.Count > 0)
            {
                var firstColorView = descriptor.ColorAttachments[0].View as VeldridRhiTextureView;
                Texture? firstTex = firstColorView?.Texture?.Texture;

                if (firstTex != null && swapchainFb?.ColorTargets.Count > 0 && firstTex == swapchainFb.ColorTargets[0].Target)
                {
                    targetFramebuffer = swapchainFb;
                }
                else if (firstTex != null)
                {
                    var colorTargets = new List<Texture>();
                    for (int i = 0; i < descriptor.ColorAttachments.Count; i++)
                    {
                        if (descriptor.ColorAttachments[i].View is VeldridRhiTextureView tv && tv.Texture?.Texture != null)
                        {
                            colorTargets.Add(tv.Texture.Texture);
                        }
                    }

                    Texture? depthTarget = null;
                    if (descriptor.DepthAttachment.HasValue && descriptor.DepthAttachment.Value.View is VeldridRhiTextureView dtv && dtv.Texture?.Texture != null)
                    {
                        depthTarget = dtv.Texture.Texture;
                    }

                    try
                    {
                        targetFramebuffer = GetOrCreateFramebuffer(depthTarget, colorTargets.ToArray());
                    }
                    catch { }
                }
            }

            if (targetFramebuffer == null)
            {
                targetFramebuffer = swapchainFb;
            }

            if (targetFramebuffer != null)
            {
                CommandList.SetFramebuffer(targetFramebuffer);

                if (descriptor.ColorAttachments != null)
                {
                    for (uint i = 0; i < descriptor.ColorAttachments.Count; i++)
                    {
                        var colorAtt = descriptor.ColorAttachments[(int)i];
                        if (colorAtt.Load == RhiLoadOp.Clear)
                        {
                            var c = colorAtt.ClearValue;
                            CommandList.ClearColorTarget(i, new RgbaFloat(c.R, c.G, c.B, c.A));
                        }
                    }
                }

                if (descriptor.DepthAttachment.HasValue)
                {
                    var depthAtt = descriptor.DepthAttachment.Value;
                    if (depthAtt.DepthLoad == RhiLoadOp.Clear)
                    {
                        CommandList.ClearDepthStencil(depthAtt.DepthClearValue);
                    }
                }
            }
        }

        return new VeldridRhiRenderPassEncoder(CommandList!, this);
    }

    public IRhiComputePassEncoder BeginComputePass(in RhiComputePassDescriptor descriptor = default)
    {
        EnsureRecording();
        return new VeldridRhiComputePassEncoder(CommandList, this);
    }

    public void CopyBufferToBuffer(IRhiBuffer source, ulong sourceOffset, IRhiBuffer destination, ulong destinationOffset, ulong sizeInBytes)
    {
        EnsureRecording();
        if (source is VeldridRhiBuffer srcBuf && destination is VeldridRhiBuffer dstBuf && srcBuf.Buffer != null && dstBuf.Buffer != null)
        {
            CommandList.CopyBuffer(srcBuf.Buffer, (uint)sourceOffset, dstBuf.Buffer, (uint)destinationOffset, (uint)sizeInBytes);
        }
    }

    public void CopyBufferToTexture(in RhiBufferTextureCopy source, in RhiTextureRegion destination, in RhiExtent3D size)
    {
        EnsureRecording();
    }

    public void CopyTextureToBuffer(in RhiTextureRegion source, in RhiBufferTextureCopy destination, in RhiExtent3D size)
    {
        EnsureRecording();
    }

    public void CopyTextureToTexture(in RhiTextureRegion source, in RhiTextureRegion destination, in RhiExtent3D size)
    {
        EnsureRecording();
        if (source.Texture is VeldridRhiTexture srcTex && destination.Texture is VeldridRhiTexture dstTex && srcTex.Texture != null && dstTex.Texture != null)
        {
            CommandList.CopyTexture(
                srcTex.Texture,
                (uint)source.Origin.X,
                (uint)source.Origin.Y,
                (uint)source.Origin.Z,
                (uint)source.MipLevel,
                0,
                dstTex.Texture,
                (uint)destination.Origin.X,
                (uint)destination.Origin.Y,
                (uint)destination.Origin.Z,
                (uint)destination.MipLevel,
                0,
                (uint)size.Width,
                (uint)size.Height,
                (uint)size.DepthOrArrayLayers,
                1);
        }
    }

    public void ClearBuffer(IRhiBuffer buffer, ulong offset = 0, ulong sizeInBytes = 0)
    {
        EnsureRecording();
    }

    public void ResolveQuerySet(IRhiQuerySet querySet, int firstQuery, int queryCount, IRhiBuffer destination, ulong destinationOffset) { EnsureRecording(); }

    public IRhiCommandBuffer Finish(string label = "")
    {
        if (_isRecording && CommandList != null)
        {
            CommandList.End();
            _isRecording = false;
        }
        return new VeldridRhiCommandBuffer(CommandList!) { Label = label };
    }

    public void Dispose() => CommandList?.Dispose();
}

public class VeldridRhiRenderPassEncoder : IRhiRenderPassEncoder
{
    private readonly CommandList _commandList;
    private readonly VeldridRhiCommandEncoder _encoder;

    public CommandList CommandList => _commandList;

    public VeldridRhiRenderPassEncoder(CommandList commandList, VeldridRhiCommandEncoder encoder)
    {
        _commandList = commandList;
        _encoder = encoder;
    }

    public void Begin()
    {
        _encoder?.EnsureRecording();
    }

    public void SetBindGroup(int index, IRhiBindGroup group, ReadOnlySpan<uint> dynamicOffsets = default)
    {
        Begin();
        if (_commandList != null && group is VeldridRhiBindGroup vGroup && vGroup.Set != null)
        {
            if (dynamicOffsets.Length > 0)
            {
                _commandList.SetGraphicsResourceSet((uint)index, vGroup.Set, dynamicOffsets.ToArray());
            }
            else
            {
                _commandList.SetGraphicsResourceSet((uint)index, vGroup.Set);
            }
        }
    }

    [System.Runtime.InteropServices.DllImport("GLESv2", EntryPoint = "glGetIntegerv")]
    private static extern void glGetIntegerv(int pname, out int paramsVal);

    [System.Runtime.InteropServices.DllImport("GLESv2", EntryPoint = "glGetUniformLocation")]
    private static extern int glGetUniformLocation(int program, [System.Runtime.InteropServices.MarshalAs(System.Runtime.InteropServices.UnmanagedType.LPStr)] string name);

    [System.Runtime.InteropServices.DllImport("GLESv2", EntryPoint = "glUniform2f")]
    private static extern void glUniform2f(int location, float v0, float v1);

    public void SetPushData(ReadOnlySpan<byte> data, int offset = 0)
    {
        Begin();
        if (data.Length >= 8)
        {
            unsafe
            {
                fixed (byte* ptr = data.Slice(offset))
                {
                    float* fPtr = (float*)ptr;
                    float w = fPtr[0];
                    float h = fPtr[1];
                    glGetIntegerv(0x8B8D /* GL_CURRENT_PROGRAM */, out int prog);
                    if (prog > 0)
                    {
                        int loc = glGetUniformLocation(prog, "push.projectionSize");
                        if (loc < 0) loc = glGetUniformLocation(prog, "push");
                        if (loc >= 0)
                        {
                            glUniform2f(loc, w, h);
                        }
                    }
                }
            }
        }
    }
    public void PushDebugGroup(string label) { Begin(); }
    public void PopDebugGroup() { }
    public void EndPass() { }
    public void Dispose() { }

    private bool _hasBoundPipeline;

    public void SetPipeline(IRhiRenderPipeline pipeline)
    {
        Begin();
        if (_commandList != null && pipeline is VeldridRhiRenderPipeline vPipe && vPipe.Pipeline != null)
        {
            _commandList.SetPipeline(vPipe.Pipeline);
            _hasBoundPipeline = true;
        }
    }

    public void SetVertexBuffer(int slot, IRhiBuffer buffer, ulong offset = 0)
    {
        Begin();
        if (_commandList != null && buffer is VeldridRhiBuffer vBuf && vBuf.Buffer != null)
        {
            _commandList.SetVertexBuffer((uint)slot, vBuf.Buffer, (uint)offset);
        }
    }

    public void SetIndexBuffer(IRhiBuffer buffer, RhiIndexFormat format, ulong offset = 0)
    {
        Begin();
        if (_commandList != null && buffer is VeldridRhiBuffer vBuf && vBuf.Buffer != null)
        {
            IndexFormat vFormat = format == RhiIndexFormat.Uint16 ? IndexFormat.UInt16 : IndexFormat.UInt32;
            _commandList.SetIndexBuffer(vBuf.Buffer, vFormat, (uint)offset);
        }
    }

    public void SetViewport(float x, float y, float width, float height, float minDepth = 0f, float maxDepth = 1f)
    {
        Begin();
        if (_commandList != null)
        {
            var viewport = new global::Veldrid.Viewport(x, y, width, height, minDepth, maxDepth);
            _commandList.SetViewport(0, ref viewport);
        }
    }

    public void SetScissor(int x, int y, int width, int height)
    {
        Begin();
        if (_commandList != null)
        {
            uint uX = (uint)Math.Max(0, x);
            uint uY = (uint)Math.Max(0, y);
            uint uW = (uint)Math.Max(0, width);
            uint uH = (uint)Math.Max(0, height);
            _commandList.SetScissorRect(0, uX, uY, uW, uH);
        }
    }

    public void SetBlendConstant(in RhiClearColor color) { Begin(); }

    public void Draw(int vertexCount, int instanceCount = 1, int firstVertex = 0, int firstInstance = 0)
    {
        Begin();
        if (_hasBoundPipeline)
        {
            _commandList?.Draw((uint)vertexCount, (uint)instanceCount, (uint)firstVertex, (uint)firstInstance);
        }
    }

    public void DrawIndexed(int indexCount, int instanceCount = 1, int firstIndex = 0, int baseVertex = 0, int firstInstance = 0)
    {
        Begin();
        if (_hasBoundPipeline)
        {
            _commandList?.DrawIndexed((uint)indexCount, (uint)instanceCount, (uint)firstIndex, baseVertex, (uint)firstInstance);
        }
    }

    public void DrawIndirect(IRhiBuffer arguments, ulong offset)
    {
        Begin();
        if (_commandList != null && arguments is VeldridRhiBuffer vBuf && vBuf.Buffer != null)
        {
            _commandList.DrawIndirect(vBuf.Buffer, (uint)offset, 1, 0);
        }
    }

    public void DrawIndexedIndirect(IRhiBuffer arguments, ulong offset)
    {
        Begin();
        if (_commandList != null && arguments is VeldridRhiBuffer vBuf && vBuf.Buffer != null)
        {
            _commandList.DrawIndexedIndirect(vBuf.Buffer, (uint)offset, 1, 0);
        }
    }

    public void BeginOcclusionQuery(int queryIndex) { Begin(); }
    public void EndOcclusionQuery() { }
}

public class VeldridRhiComputePassEncoder : IRhiComputePassEncoder
{
    private readonly CommandList _commandList;
    private readonly VeldridRhiCommandEncoder _encoder;

    public CommandList CommandList => _commandList;

    public VeldridRhiComputePassEncoder(CommandList commandList, VeldridRhiCommandEncoder encoder)
    {
        _commandList = commandList;
        _encoder = encoder;
    }

    public void Begin()
    {
        _encoder?.EnsureRecording();
    }

    public void SetBindGroup(int index, IRhiBindGroup group, ReadOnlySpan<uint> dynamicOffsets = default)
    {
        Begin();
        if (_commandList != null && group is VeldridRhiBindGroup vGroup && vGroup.Set != null)
        {
            if (dynamicOffsets.Length > 0)
            {
                _commandList.SetComputeResourceSet((uint)index, vGroup.Set, dynamicOffsets.ToArray());
            }
            else
            {
                _commandList.SetComputeResourceSet((uint)index, vGroup.Set);
            }
        }
    }

    public void SetPushData(ReadOnlySpan<byte> data, int offset = 0) { Begin(); }
    public void PushDebugGroup(string label) { Begin(); }
    public void PopDebugGroup() { }
    public void EndPass() { }
    public void Dispose() { }

    private bool _hasBoundPipeline;

    public void SetPipeline(IRhiComputePipeline pipeline)
    {
        Begin();
        if (_commandList != null && pipeline is VeldridRhiComputePipeline vPipe && vPipe.Pipeline != null)
        {
            _commandList.SetPipeline(vPipe.Pipeline);
            _hasBoundPipeline = true;
        }
    }

    public void Dispatch(int x, int y = 1, int z = 1)
    {
        Begin();
        if (_hasBoundPipeline)
        {
            _commandList?.Dispatch((uint)x, (uint)y, (uint)z);
        }
    }

    public void DispatchIndirect(IRhiBuffer arguments, ulong offset)
    {
        Begin();
        if (_commandList != null && arguments is VeldridRhiBuffer vBuf && vBuf.Buffer != null)
        {
            _commandList.DispatchIndirect(vBuf.Buffer, (uint)offset);
        }
    }
}

public class VeldridRhiCommandBuffer : IRhiCommandBuffer
{
    public CommandList CommandList { get; }
    public string Label { get; set; } = string.Empty;
    public VeldridRhiCommandBuffer(CommandList commandList) => CommandList = commandList;
    public void Dispose()
    {
        try
        {
            if (CommandList != null && !CommandList.IsDisposed)
            {
                CommandList.Dispose();
            }
        }
        catch { }
    }
}

public class VeldridRhiWorkMarker : IRhiWorkMarker
{
    public bool IsComplete => true;
}

public class VeldridRhiReadback : IRhiReadback
{
    public bool IsComplete => true;
    public ulong SizeInBytes { get; set; }
    public bool Wait(TimeSpan timeout) { return true; }
    public void GetData(Span<byte> destination) => throw new NotImplementedException();
    public ReadOnlySpan<byte> GetData() => throw new NotImplementedException();
    public void Dispose() { }
}
