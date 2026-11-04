using System;
using System.Collections.Concurrent;
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

    /// <summary>Clears the framebuffer cache, disposing what it held.</summary>
    /// <remarks>Call after a swapchain resize: cached framebuffers reference the old
    /// swapchain's images, and reusing one after ResizeMainWindow destroys them is
    /// the same use-after-free family as the command-list bug.</remarks>
    public static void InvalidateFramebufferCache()
    {
        foreach (Framebuffer fb in FbCache.Values)
        {
            try { fb.Dispose(); } catch { }
        }
        FbCache.Clear();
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

    // Set once Finish hands the command list to the returned buffer. From that point the
    // buffer owns the list, and freeing it here would hand vkQueueSubmit a dead
    // VkCommandBuffer on the next SwapBuffers -- the Adreno SIGSEGV that killed frame 2.
    private bool _transferred;

    public IRhiCommandBuffer Finish(string label = "")
    {
        if (_isRecording && CommandList != null)
        {
            CommandList.End();
            _isRecording = false;
        }
        _transferred = true;
        return new VeldridRhiCommandBuffer(CommandList!) { Label = label };
    }

    public void Dispose()
    {
        // Only free a list this encoder still owns: one abandoned without Finish
        // (shutdown, a dropped frame). A finished list belongs to its buffer now.
        if (!_transferred)
        {
            CommandList?.Dispose();
        }
    }
}

/// <summary>Per-device uniform ring that backs <see cref="VeldridRhiRenderPassEncoder.SetPushData"/>.</summary>
/// <remarks>
/// Veldrid exposes no push-constant API, so push data is written into slots of one uniform buffer
/// and bound as set 3 (OPENIGI_PUSH_CONSTANT_GROUP) with a dynamic offset naming the slot. Slots are
/// 256 bytes: that covers every push block the RHI allows and keeps dynamic offsets aligned to the
/// uniform-buffer alignment Vulkan guarantees. The ring holds far more than one frame's push traffic,
/// so a slot is never overwritten while a submitted frame still reads it; the cursor simply wraps.
/// </remarks>
public sealed class VeldridPushRing : IDisposable
{
    public const int SlotSizeBytes = 256;
    public const int SlotCount = 256;

    private readonly GraphicsDevice _device;
    private readonly DeviceBuffer _buffer;
    private readonly Dictionary<ResourceLayout, ResourceSet> _sets = new();
    private readonly object _gate = new();
    private int _nextSlot;

    public VeldridPushRing(GraphicsDevice device)
    {
        _device = device;
        _buffer = device.ResourceFactory.CreateBuffer(new BufferDescription(
            (uint)(SlotSizeBytes * SlotCount),
            BufferUsage.UniformBuffer | BufferUsage.Dynamic));
    }

    /// <summary>Writes push data into the next slot and returns the set and dynamic offset to bind.</summary>
    public (ResourceSet Set, uint Offset) Write(ResourceLayout pushLayout, ReadOnlySpan<byte> data)
    {
        lock (_gate)
        {
            int slot = _nextSlot;
            _nextSlot = (_nextSlot + 1) % SlotCount;
            uint offset = (uint)(slot * SlotSizeBytes);

            if (!_sets.TryGetValue(pushLayout, out ResourceSet? set))
            {
                set = _device.ResourceFactory.CreateResourceSet(new ResourceSetDescription(
                    pushLayout,
                    new DeviceBufferRange(_buffer, 0, SlotSizeBytes)));
                _sets[pushLayout] = set;
            }

            int length = Math.Min(data.Length, SlotSizeBytes);
            if (length > 0)
            {
                unsafe
                {
                    fixed (byte* ptr = data)
                    {
                        _device.UpdateBuffer(_buffer, offset, (IntPtr)ptr, (uint)length);
                    }
                }
            }

            return (set, offset);
        }
    }

    public void Dispose()
    {
        foreach (ResourceSet set in _sets.Values)
        {
            try { set.Dispose(); } catch { }
        }
        _sets.Clear();
        try { _buffer.Dispose(); } catch { }
    }
}

public class VeldridRhiRenderPassEncoder : IRhiRenderPassEncoder
{
    private readonly CommandList _commandList;
    private readonly VeldridRhiCommandEncoder _encoder;
    private static readonly ConcurrentDictionary<GraphicsDevice, VeldridPushRing> PushRings = new();
    private VeldridRhiPipelineLayout? _boundLayout;

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

    public void SetPushData(ReadOnlySpan<byte> data, int offset = 0)
    {
        Begin();
        // Veldrid has no push-constant API, and its pipeline layouts carry no push range, so the
        // previous implementation — OpenGL calls that only exist on the GLES backend — silently set
        // nothing on Vulkan, leaving the sprite shader's projection at (0,0) and every sprite vertex
        // dividing by zero (the black menu). Push data instead rides the per-device uniform ring,
        // bound as set OPENIGI_PUSH_CONSTANT_GROUP (3), which the pipeline layout reserves for
        // pipelines that declare push data. Pipelines without a set-3 layout (no push data, or built
        // before the layout change) simply skip the bind.
        if (offset < 0 || offset > data.Length || _commandList == null)
        {
            return;
        }
        ReadOnlySpan<byte> push = data.Slice(offset);
        if (push.IsEmpty)
        {
            return;
        }
        if (_boundLayout?.ResourceLayouts == null || _boundLayout.ResourceLayouts.Length <= 3)
        {
            return;
        }
        ResourceLayout? pushLayout = _boundLayout.ResourceLayouts[3];
        if (pushLayout == null)
        {
            return;
        }
        VeldridPushRing ring = PushRings.GetOrAdd(_encoder.Device, static device => new VeldridPushRing(device));
        (ResourceSet set, uint dynOffset) = ring.Write(pushLayout, push);
        _commandList.SetGraphicsResourceSet(3, set, new uint[] { dynOffset });
    }
    public void PushDebugGroup(string label) { Begin(); }
    public void PopDebugGroup() { }
    public void EndPass() { }
    public void Dispose() { }

    private bool _hasBoundPipeline;

    public void SetPipeline(IRhiRenderPipeline pipeline)
    {
        Begin();
        _boundLayout = (pipeline as VeldridRhiRenderPipeline)?.Layout as VeldridRhiPipelineLayout;
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

    // NOTE: same gap as the render pass had — compute push data is dropped here. The render-pass
    // fix (uniform ring, set 3) does not cover compute, because Veldrid compute pipelines are
    // created with no resource layouts at all; wiring a push set through compute pipeline creation
    // is follow-up work, and no compute path is on the menu's critical path.
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
