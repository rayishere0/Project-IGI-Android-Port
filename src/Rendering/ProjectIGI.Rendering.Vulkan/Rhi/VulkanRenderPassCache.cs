using ProjectIGI.Core.Graphics;
using ProjectIGI.Rendering.Vulkan.Interop;
using Silk.NET.Vulkan;

// Silk.NET spells the Vulkan attachment op enums with an "Attachment" prefix to keep them clear of the
// VkAttachmentDescription fields that carry them. Aliased here so the code below reads as the spec does,
// without the aliases leaking into the property names.
using LoadOp = Silk.NET.Vulkan.AttachmentLoadOp;
using StoreOp = Silk.NET.Vulkan.AttachmentStoreOp;

namespace ProjectIGI.Rendering.Vulkan.Rhi;

/// <summary>
/// Render pass objects and framebuffers, for the devices that cannot begin a pass from its attachments.
/// </summary>
/// <remarks>
/// <para>
/// The RHI describes a pass the way WebGPU does: the attachments are stated when the pass begins. Vulkan
/// 1.3 turns that into <c>vkCmdBeginRendering</c> and there is nothing to keep in step. Before 1.3 -- which
/// is every Adreno 6xx, and a good deal of Mali -- the same description has to be turned into a
/// <c>VkRenderPass</c> plus a <c>VkFramebuffer</c>, and those are objects that must match what is attached.
/// </para>
/// <para>
/// Both are cached here rather than rebuilt per frame, because the formats the engine actually uses are a
/// handful and do not change until the swapchain does. Render passes are keyed by everything baked into
/// them (formats, sample count, load and store ops, depth layout); framebuffers additionally by the exact
/// image views attached, since a framebuffer names its views.
/// </para>
/// <para>
/// Framebuffers are the ones that go stale: a resize destroys the views they name. They are dropped whole
/// on <see cref="InvalidateFramebuffers"/>, which the swapchain-recreation path calls. Render passes survive
/// that, because they name formats and not images.
/// </para>
/// </remarks>
internal sealed unsafe class VulkanRenderPassCache : IDisposable
{
    private readonly Vk _vk;
    private readonly Device _device;
    private readonly Dictionary<RenderPassKey, RenderPass> _passes = [];

    // Framebuffers are not cached across frames. The engine wraps a swapchain image in a fresh texture
    // every frame and disposes the previous one, so the view a framebuffer names is destroyed one frame
    // later -- and the driver hands the same handle value back out for the replacement. Keyed by handle
    // and kept, that turns into a hit on a framebuffer built from a destroyed view, which draws into an
    // image nobody is presenting. Reuse is therefore within a frame only.
    private readonly Dictionary<FramebufferKey, Framebuffer> _frame = [];
    private readonly Dictionary<int, List<Framebuffer>> _bySlot = [];
    private int _slot = -1;
    private bool _disposed;

    /// <summary>Initialises a new instance of the <see cref="VulkanRenderPassCache"/> class.</summary>
    /// <param name="vk">The core Vulkan API.</param>
    /// <param name="device">The device the objects belong to.</param>
    public VulkanRenderPassCache(Vk vk, Device device)
    {
        _vk = vk;
        _device = device;
    }

    /// <summary>Gets how many render passes have been built, for diagnostics.</summary>
    public int PassCount => _passes.Count;

    /// <summary>Gets how many framebuffers the current frame is holding, for diagnostics.</summary>
    public int FramebufferCount => _frame.Count;

    /// <summary>
    /// Starts a frame on a slot, destroying the framebuffers the previous frame on that slot built.
    /// </summary>
    /// <remarks>
    /// Called once the slot's fence has signalled, which is the only moment at which the command buffers
    /// that referenced those framebuffers are known to have finished with them.
    /// </remarks>
    /// <param name="slot">The frame slot about to be recorded.</param>
    public void BeginFrame(int slot)
    {
        if (_bySlot.Remove(slot, out List<Framebuffer>? retired))
        {
            foreach (Framebuffer framebuffer in retired)
            {
                _vk.DestroyFramebuffer(_device, framebuffer, null);
            }
        }

        _slot = slot;
        _frame.Clear();
    }

    /// <summary>
    /// The render pass a pipeline is built against: formats and sample count, with the ops a pipeline does
    /// not care about.
    /// </summary>
    /// <remarks>
    /// Vulkan decides render pass compatibility from attachment formats and sample counts alone -- load and
    /// store ops are not part of it (spec 8.2). So a pipeline built against this pass is valid inside any
    /// pass with the same formats, whatever that pass clears or keeps. That is what lets the pipeline be
    /// created once, before anyone knows which attachments a frame will use.
    /// </remarks>
    /// <param name="colourFormats">The colour formats, in attachment order.</param>
    /// <param name="depthFormat">The depth format, or <see cref="Format.Undefined"/> for none.</param>
    /// <param name="stencilFormat">The stencil format, or <see cref="Format.Undefined"/> for none.</param>
    /// <param name="samples">The sample count.</param>
    /// <returns>The render pass.</returns>
    public RenderPass PipelineCompatible(
        ReadOnlySpan<Format> colourFormats,
        Format depthFormat,
        Format stencilFormat,
        uint samples)
    {
        int count = colourFormats.Length;
        LoadOp[] loads = new LoadOp[count];
        StoreOp[] stores = new StoreOp[count];

        // A pipeline does not read these, and compatibility does not compare them; Clear/Store is the pair
        // that is valid for every attachment, so it is the one baked into the pipeline-facing pass.
        loads.AsSpan().Fill(LoadOp.Clear);
        stores.AsSpan().Fill(StoreOp.Store);

        RenderPassKey key = new(
            colourFormats.ToArray(),
            depthFormat,
            stencilFormat,
            samples,
            loads,
            stores,
            depthFormat != Format.Undefined ? LoadOp.Clear : LoadOp.DontCare,
            depthFormat != Format.Undefined ? StoreOp.Store : StoreOp.DontCare,
            depthFormat != Format.Undefined ? ImageLayout.DepthStencilAttachmentOptimal : ImageLayout.Undefined);

        return GetOrCreatePass(key);
    }

    /// <summary>The render pass and framebuffer for one pass, built from the attachments it names.</summary>
    /// <param name="colourFormats">The colour formats, in attachment order.</param>
    /// <param name="colourLoads">What each colour attachment does at the start of the pass.</param>
    /// <param name="colourStores">What each colour attachment does at the end of the pass.</param>
    /// <param name="colourViews">The colour image views, in attachment order.</param>
    /// <param name="depthFormat">The depth format, or <see cref="Format.Undefined"/> for none.</param>
    /// <param name="stencilFormat">The stencil format, or <see cref="Format.Undefined"/> for none.</param>
    /// <param name="depthLoad">What the depth attachment does at the start of the pass.</param>
    /// <param name="depthStore">What the depth attachment does at the end of the pass.</param>
    /// <param name="depthLayout">The layout the depth attachment is in for the pass.</param>
    /// <param name="depthView">The depth image view, or a default handle for none.</param>
    /// <param name="samples">The sample count.</param>
    /// <param name="width">The framebuffer width.</param>
    /// <param name="height">The framebuffer height.</param>
    /// <param name="label">The pass name, for the failure message a mixed resolve set produces.</param>
    /// <returns>The pass and the framebuffer built for these views.</returns>
    public (RenderPass Pass, Framebuffer Framebuffer) Begin(
        ReadOnlySpan<Format> colourFormats,
        ReadOnlySpan<LoadOp> colourLoads,
        ReadOnlySpan<StoreOp> colourStores,
        ReadOnlySpan<ImageView> colourViews,
        Format depthFormat,
        Format stencilFormat,
        LoadOp depthLoad,
        StoreOp depthStore,
        ImageLayout depthLayout,
        ImageView depthView,
        uint samples,
        uint width,
        uint height,
        string label)
    {
        bool hasDepth = depthFormat != Format.Undefined;

        RenderPassKey passKey = new(
            colourFormats.ToArray(),
            depthFormat,
            stencilFormat,
            samples,
            colourLoads.ToArray(),
            colourStores.ToArray(),
            hasDepth ? depthLoad : LoadOp.DontCare,
            hasDepth ? depthStore : StoreOp.DontCare,
            hasDepth ? depthLayout : ImageLayout.Undefined);

        RenderPass pass = GetOrCreatePass(passKey);

        ImageView[] views = new ImageView[colourViews.Length + (hasDepth ? 1 : 0)];
        colourViews.CopyTo(views);
        if (hasDepth)
        {
            views[^1] = depthView;
        }

        FramebufferKey framebufferKey = new(pass, views);
        if (!_frame.TryGetValue(framebufferKey, out Framebuffer framebuffer))
        {
            fixed (ImageView* firstView = views)
            {
                FramebufferCreateInfo info = new()
                {
                    SType = StructureType.FramebufferCreateInfo,
                    RenderPass = pass,
                    AttachmentCount = (uint)views.Length,
                    PAttachments = firstView,
                    Width = width,
                    Height = height,
                    Layers = 1,
                };

                VkCheck.Ok(
                    _vk.CreateFramebuffer(_device, &info, null, &framebuffer),
                    $"vkCreateFramebuffer for the pass '{label}'");
            }

            _frame[framebufferKey] = framebuffer;

            if (!_bySlot.TryGetValue(_slot, out List<Framebuffer>? built))
            {
                built = [];
                _bySlot[_slot] = built;
            }

            built.Add(framebuffer);
        }

        return (pass, framebuffer);
    }

    /// <summary>Drops every framebuffer, because the views they name are about to stop existing.</summary>
    /// <remarks>
    /// Only safe with the device idle: the callers that need it are the ones rebuilding the swapchain, and
    /// they wait first.
    /// </remarks>
    public void InvalidateFramebuffers()
    {
        foreach (List<Framebuffer> framebuffers in _bySlot.Values)
        {
            foreach (Framebuffer framebuffer in framebuffers)
            {
                _vk.DestroyFramebuffer(_device, framebuffer, null);
            }
        }

        _bySlot.Clear();
        _frame.Clear();
    }

    /// <inheritdoc/>
    public void Dispose()
    {
        if (_disposed)
        {
            return;
        }

        _disposed = true;
        InvalidateFramebuffers();

        foreach (RenderPass pass in _passes.Values)
        {
            _vk.DestroyRenderPass(_device, pass, null);
        }

        _passes.Clear();
    }

    private RenderPass GetOrCreatePass(in RenderPassKey key)
    {
        if (_passes.TryGetValue(key, out RenderPass existing))
        {
            return existing;
        }

        int colourCount = key.Colours.Length;
        bool hasDepth = key.Depth != Format.Undefined;

        // The attachments in the order the pass names them: colours first, then depth. Resolve attachments
        // are not built here -- the engine creates every pipeline at SampleCount 1 and nothing sets a
        // resolve target, so a resolving pass would be a change of behaviour worth noticing rather than a
        // silently half-built framebuffer.
        AttachmentDescription[] attachments = new AttachmentDescription[colourCount + (hasDepth ? 1 : 0)];

        for (int i = 0; i < colourCount; i++)
        {
            attachments[i] = new AttachmentDescription
            {
                Format = key.Colours[i],
                Samples = (SampleCountFlags)key.Samples,
                LoadOp = key.Loads[i],
                StoreOp = key.Stores[i],
                StencilLoadOp = LoadOp.DontCare,
                StencilStoreOp = StoreOp.DontCare,

                // The encoder has already moved the image into this layout before the pass begins, and moves
                // it back out afterwards, so the pass itself is not asked to transition anything.
                InitialLayout = ImageLayout.ColorAttachmentOptimal,
                FinalLayout = ImageLayout.ColorAttachmentOptimal,
            };
        }

        if (hasDepth)
        {
            attachments[^1] = new AttachmentDescription
            {
                Format = key.Depth,
                Samples = (SampleCountFlags)key.Samples,
                LoadOp = key.DepthLoad,
                StoreOp = key.DepthStore,
                StencilLoadOp = key.DepthLoad,
                StencilStoreOp = key.DepthStore,
                InitialLayout = key.DepthLayout,
                FinalLayout = key.DepthLayout,
            };
        }

        AttachmentReference[] colourReferences = new AttachmentReference[colourCount];
        for (int i = 0; i < colourCount; i++)
        {
            colourReferences[i] = new AttachmentReference
            {
                Attachment = (uint)i,
                Layout = ImageLayout.ColorAttachmentOptimal,
            };
        }

        AttachmentReference depthReference = new()
        {
            Attachment = hasDepth ? (uint)colourCount : uint.MaxValue,
            Layout = key.DepthLayout,
        };

        // Conservative on purpose: every stage that could have written before this pass is made to finish,
        // and every stage that could read after it is made to wait. The encoder already records explicit
        // barriers around the pass, so this is belt and braces rather than the only ordering.
        SubpassDependency[] dependencies =
        [
            new()
            {
                SrcSubpass = uint.MaxValue,
                DstSubpass = 0,
                SrcStageMask = PipelineStageFlags.ColorAttachmentOutputBit
                    | PipelineStageFlags.EarlyFragmentTestsBit
                    | PipelineStageFlags.LateFragmentTestsBit,
                DstStageMask = PipelineStageFlags.ColorAttachmentOutputBit
                    | PipelineStageFlags.EarlyFragmentTestsBit
                    | PipelineStageFlags.LateFragmentTestsBit,
                SrcAccessMask = 0,
                DstAccessMask = AccessFlags.ColorAttachmentWriteBit | AccessFlags.DepthStencilAttachmentWriteBit,
                DependencyFlags = 0,
            },
            new()
            {
                SrcSubpass = 0,
                DstSubpass = uint.MaxValue,
                SrcStageMask = PipelineStageFlags.ColorAttachmentOutputBit
                    | PipelineStageFlags.EarlyFragmentTestsBit
                    | PipelineStageFlags.LateFragmentTestsBit,
                DstStageMask = PipelineStageFlags.ColorAttachmentOutputBit
                    | PipelineStageFlags.EarlyFragmentTestsBit
                    | PipelineStageFlags.LateFragmentTestsBit,
                SrcAccessMask = AccessFlags.ColorAttachmentWriteBit | AccessFlags.DepthStencilAttachmentWriteBit,
                DstAccessMask = AccessFlags.ColorAttachmentReadBit
                    | AccessFlags.ColorAttachmentWriteBit
                    | AccessFlags.DepthStencilAttachmentReadBit
                    | AccessFlags.DepthStencilAttachmentWriteBit
                    | AccessFlags.ShaderReadBit,
                DependencyFlags = 0,
            },
        ];

        RenderPass created;
        fixed (AttachmentDescription* firstAttachment = attachments)
        fixed (AttachmentReference* firstColour = colourReferences)
        fixed (SubpassDependency* firstDependency = dependencies)
        {
            SubpassDescription subpass = new()
            {
                PipelineBindPoint = PipelineBindPoint.Graphics,
                ColorAttachmentCount = (uint)colourCount,
                PColorAttachments = colourCount > 0 ? firstColour : null,
                PDepthStencilAttachment = hasDepth ? &depthReference : null,
            };

            RenderPassCreateInfo info = new()
            {
                SType = StructureType.RenderPassCreateInfo,
                AttachmentCount = (uint)attachments.Length,
                PAttachments = firstAttachment,
                SubpassCount = 1,
                PSubpasses = &subpass,
                DependencyCount = (uint)dependencies.Length,
                PDependencies = firstDependency,
            };

            VkCheck.Ok(_vk.CreateRenderPass(_device, &info, null, &created), "vkCreateRenderPass");
        }

        _passes[key] = created;
        return created;
    }

    /// <summary>Everything baked into a render pass object, and nothing that is not.</summary>
    private readonly struct RenderPassKey : IEquatable<RenderPassKey>
    {
        private readonly int _hash;

        public RenderPassKey(
            Format[] colours,
            Format depth,
            Format stencil,
            uint samples,
            LoadOp[] loads,
            StoreOp[] stores,
            LoadOp depthLoad,
            StoreOp depthStore,
            ImageLayout depthLayout)
        {
            Colours = colours;
            Depth = depth;
            Stencil = stencil;
            Samples = samples;
            Loads = loads;
            Stores = stores;
            DepthLoad = depthLoad;
            DepthStore = depthStore;
            DepthLayout = depthLayout;

            HashCode hash = default;
            foreach (Format colour in colours)
            {
                hash.Add(colour);
            }

            foreach (LoadOp load in loads)
            {
                hash.Add(load);
            }

            foreach (StoreOp store in stores)
            {
                hash.Add(store);
            }

            hash.Add(depth);
            hash.Add(stencil);
            hash.Add(samples);
            hash.Add(depthLoad);
            hash.Add(depthStore);
            hash.Add(depthLayout);
            _hash = hash.ToHashCode();
        }

        public Format[] Colours { get; }

        public Format Depth { get; }

        public Format Stencil { get; }

        public uint Samples { get; }

        public LoadOp[] Loads { get; }

        public StoreOp[] Stores { get; }

        public LoadOp DepthLoad { get; }

        public StoreOp DepthStore { get; }

        public ImageLayout DepthLayout { get; }

        public bool Equals(RenderPassKey other) =>
            _hash == other._hash
            && Samples == other.Samples
            && Depth == other.Depth
            && Stencil == other.Stencil
            && DepthLoad == other.DepthLoad
            && DepthStore == other.DepthStore
            && DepthLayout == other.DepthLayout
            && Colours.AsSpan().SequenceEqual(other.Colours)
            && Loads.AsSpan().SequenceEqual(other.Loads)
            && Stores.AsSpan().SequenceEqual(other.Stores);

        public override bool Equals(object? obj) => obj is RenderPassKey other && Equals(other);

        public override int GetHashCode() => _hash;
    }

    /// <summary>A framebuffer is a render pass plus the exact views attached to it.</summary>
    private readonly struct FramebufferKey : IEquatable<FramebufferKey>
    {
        private readonly int _hash;

        public FramebufferKey(RenderPass pass, ImageView[] views)
        {
            Pass = pass;
            Views = views;

            HashCode hash = default;
            hash.Add(pass.Handle);
            foreach (ImageView view in views)
            {
                hash.Add(view.Handle);
            }

            _hash = hash.ToHashCode();
        }

        public RenderPass Pass { get; }

        public ImageView[] Views { get; }

        public bool Equals(FramebufferKey other) =>
            _hash == other._hash
            && Pass.Handle == other.Pass.Handle
            && Views.AsSpan().SequenceEqual(other.Views);

        public override bool Equals(object? obj) => obj is FramebufferKey other && Equals(other);

        public override int GetHashCode() => _hash;
    }
}
