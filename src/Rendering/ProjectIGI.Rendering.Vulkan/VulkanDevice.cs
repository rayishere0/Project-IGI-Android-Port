using ProjectIGI.Rendering;
using ProjectIGI.Rendering.Vulkan.Capabilities;
using ProjectIGI.Rendering.Vulkan.Interop;
using ProjectIGI.Rendering.Vulkan.Queues;
using Silk.NET.Core;
using Silk.NET.Core.Native;
using Silk.NET.Vulkan;
using Silk.NET.Vulkan.Extensions.EXT;
using Silk.NET.Vulkan.Extensions.KHR;
using System.Reflection;

namespace ProjectIGI.Rendering.Vulkan;

/// <summary>
/// The logical device: the queues the backend submits to, the device-level extensions it enabled, and
/// the memory properties every allocation is measured against.
/// </summary>
/// <remarks>
/// A logical device is the handle every resource is created against and every command is submitted
/// through. It is created once and lives for the backend's whole life — unlike the swapchain, which is
/// rebuilt on resize — so the queues, the enabled features and the memory properties are read here once
/// and shared out.
/// </remarks>
internal sealed unsafe class VulkanDevice : IDisposable
{
    private readonly Vk _vk;
    private readonly Instance _instance;
    private readonly Pipelines.VulkanPipelineCache _pipelineCache;
    private readonly bool _deviceFaultEnabled;
    private nint _cmdSetCheckpoint;
    private nint _getQueueCheckpointData;
    private bool _disposed;

    /// <summary>Gets where the backend reports diagnostics.</summary>

    /// <summary>Gets the API the device was created through.</summary>
    /// <remarks>
    /// Everything that calls Vulkan on this device goes through this one, never a second
    /// <c>Vk.GetApi</c>: under Streamline it is bound to the interposer, and a call that went around it
    /// would reach the driver behind Streamline's back.
    /// </remarks>
    public Vk Vk => _vk;

    /// <summary>Initialises a new instance of the <see cref="VulkanDevice"/> class.</summary>
    /// <param name="instance">The instance the device is created under.</param>
    /// <param name="selection">The chosen adapter and how it will be used.</param>
    /// <param name="logger">Where to report device creation.</param>
    /// <exception cref="GraphicsDeviceException">The logical device could not be created.</exception>
    public VulkanDevice(VulkanInstance instance, PhysicalDeviceSelection selection)
    {
        ArgumentNullException.ThrowIfNull(instance);
        ArgumentNullException.ThrowIfNull(selection);
        _vk = instance.Vk;
        _instance = instance.Instance;
        _deviceFaultEnabled = selection.Capabilities.EnabledExtensions.Contains("VK_EXT_device_fault");
        Selection = selection;
        Capabilities = selection.Capabilities;

        _vk.GetPhysicalDeviceMemoryProperties(selection.Device, out PhysicalDeviceMemoryProperties memory);
        MemoryProperties = memory;
        SamplerAnisotropy = Capabilities.SamplerAnisotropy;
        SamplerMipLodBias = Capabilities.SamplerMipLodBias;

        Device = CreateDevice(selection);
        LoadDiagnosticCheckpoints();

        VulkanQueuePlan plan = selection.Queues;
        Graphics = QueueAt(plan.Graphics);
        Present = plan.GraphicsAndPresentUnified ? Graphics : QueueAt(plan.Present);

        if (!_vk.TryGetDeviceExtension(instance.Instance, Device, out KhrSwapchain swapchain))
        {
            throw new GraphicsDeviceException("VK_KHR_swapchain is not available on the created device.");
        }

        Swapchain = swapchain;

        if (Capabilities.Synchronization2
            && _vk.TryGetDeviceExtension(instance.Instance, Device, out KhrSynchronization2 sync2))
        {
            Synchronization2 = sync2;
        }

        if (Capabilities.TimelineSemaphore
            && _vk.TryGetDeviceExtension(instance.Instance, Device, out KhrTimelineSemaphore timeline))
        {
            TimelineSemaphores = timeline;
        }

        // After the device and before anything builds a pipeline against it. Every pipeline in the
        // backend is created through this, which is what lets the driver hand back what it compiled on
        // a previous run instead of compiling it again on the frame that first needs it.
        _pipelineCache = new Pipelines.VulkanPipelineCache(_vk, Device, selection.Properties);

    }

    /// <summary>Gets the cache every pipeline creation is built through.</summary>
    /// <remarks>
    /// One per device, reached from the device rather than threaded through every pipeline class's
    /// constructor -- they all already take a <see cref="VulkanDevice"/>, and a driver's compiled
    /// output belongs to the device it was compiled for.
    /// </remarks>
    public PipelineCache PipelineCache => _pipelineCache.Handle;

    /// <summary>Gets the chosen adapter and its selection facts.</summary>
    public PhysicalDeviceSelection Selection { get; }

    /// <summary>Gets which optional features the device was created with.</summary>
    public VulkanDeviceCapabilities Capabilities { get; }

    /// <summary>Gets the physical device the logical device runs on.</summary>
    public PhysicalDevice PhysicalDevice => Selection.Device;

    /// <summary>Gets the logical device.</summary>
    public Device Device { get; }

    /// <summary>Gets the queue every submission goes to.</summary>
    public Queue Graphics { get; }

    /// <summary>Gets the queue images are presented from: the graphics queue, where its family can present.</summary>
    public Queue Present { get; }

    /// <summary>Gets the swapchain extension loaded for the device.</summary>
    public KhrSwapchain Swapchain { get; }

    /// <summary>Gets the synchronisation-2 entry points, or <see langword="null"/> when unavailable.</summary>
    public KhrSynchronization2? Synchronization2 { get; }

    /// <summary>Gets the timeline-semaphore entry points, or <see langword="null"/> when unavailable.</summary>
    public KhrTimelineSemaphore? TimelineSemaphores { get; }

    /// <summary>Gets the device's memory heaps and types, for choosing where an allocation lives.</summary>
    public PhysicalDeviceMemoryProperties MemoryProperties { get; }

    /// <summary>Gets a value indicating whether anisotropic sampling was enabled.</summary>
    public bool SamplerAnisotropy { get; }

    /// <summary>Gets a value indicating whether a sampler may bias which mip level it selects.</summary>
    /// <remarks>
    /// True on every conformant adapter. False only on a portable one whose underlying API has no such
    /// control, in which case a sampler asking for a bias would be rejected outright — so the texture
    /// path reads this and asks for none.
    /// </remarks>
    public bool SamplerMipLodBias { get; }

    /// <summary>Describes every memory heap's use and budget, the host's as well as the device's.</summary>
    /// <returns>One line per heap, or a note that the driver does not report budgets.</returns>
    /// <remarks>
    /// The host heap is the one a memory report is usually about: it is where upload staging and every
    /// other host-visible block lives, and what it holds counts against the process.
    /// </remarks>
    public unsafe string DescribeMemoryBudget()
    {
        if (!Capabilities.EnabledExtensions.Contains(VulkanExtensionNames.MemoryBudget))
        {
            return "  (the driver does not report memory budgets)";
        }

        PhysicalDeviceMemoryBudgetPropertiesEXT budget = new()
        {
            SType = StructureType.PhysicalDeviceMemoryBudgetPropertiesExt,
        };

        PhysicalDeviceMemoryProperties2 properties = new()
        {
            SType = StructureType.PhysicalDeviceMemoryProperties2,
            PNext = &budget,
        };

        _vk.GetPhysicalDeviceMemoryProperties2(Selection.Device, &properties);

        var text = new System.Text.StringBuilder();
        for (uint i = 0; i < properties.MemoryProperties.MemoryHeapCount; i++)
        {
            bool deviceLocal = (properties.MemoryProperties.MemoryHeaps[(int)i].Flags & MemoryHeapFlags.DeviceLocalBit) != 0;
            double used = budget.HeapUsage[(int)i] / (1024.0 * 1024.0);
            double allowed = budget.HeapBudget[(int)i] / (1024.0 * 1024.0);
            double size = properties.MemoryProperties.MemoryHeaps[(int)i].Size / (1024.0 * 1024.0);
            text.Append(FormattableString.Invariant(
                $"  heap {i} ({(deviceLocal ? "device" : "host")}): {used:F0} MiB used of {allowed:F0} MiB budget ({size:F0} MiB total)\n"));
        }

        return text.ToString().TrimEnd('\n');
    }

    /// <summary>The NVIDIA diagnostic-checkpoints extension, taken wherever it is offered.</summary>
    public const string DiagnosticCheckpointsExtension = "VK_NV_device_diagnostic_checkpoints";

    /// <summary>Records a marker the queue can be asked for if the device is lost.</summary>
    /// <param name="commandBuffer">The command buffer being recorded.</param>
    /// <param name="marker">One of <see cref="VulkanCheckpointMarkers"/>.</param>
    /// <remarks>
    /// Nothing at all on an adapter without the extension; with it, a few bytes of command stream. Legal
    /// inside and outside a render pass, on every queue type.
    /// </remarks>
    public unsafe void Checkpoint(CommandBuffer commandBuffer, nint marker)
    {
        if (_cmdSetCheckpoint != 0)
        {
            ((delegate* unmanaged<CommandBuffer, void*, void>)_cmdSetCheckpoint)(commandBuffer, (void*)marker);
        }
    }

    private unsafe void LoadDiagnosticCheckpoints()
    {
        if (!Capabilities.EnabledExtensions.Contains(DiagnosticCheckpointsExtension))
        {
            return;
        }

        _cmdSetCheckpoint = (nint)_vk.GetDeviceProcAddr(Device, "vkCmdSetCheckpointNV").Handle;
        _getQueueCheckpointData = (nint)_vk.GetDeviceProcAddr(Device, "vkGetQueueCheckpointDataNV").Handle;
        if (_cmdSetCheckpoint == 0 || _getQueueCheckpointData == 0)
        {
            _cmdSetCheckpoint = 0;
            _getQueueCheckpointData = 0;
        }
    }

    /// <summary>Asks the graphics queue which markers it last passed, and logs them oldest first.</summary>
    /// <remarks>
    /// The one report that names a pass. The fault address says what the GPU touched; this says which
    /// stage of which kind of command buffer it was running when it did, which is what turns a remote
    /// log into something that can be bisected.
    /// </remarks>
    private unsafe void ReportCheckpoints()
    {
        if (_getQueueCheckpointData == 0)
        {
            return;
        }

        var read = (delegate* unmanaged<Queue, uint*, VkCheckpointDataNV*, void>)_getQueueCheckpointData;
        uint count = 0;
        read(Graphics, &count, null);
        if (count == 0)
        {
            return;
        }

        count = Math.Min(count, 64u);
        VkCheckpointDataNV* data = stackalloc VkCheckpointDataNV[(int)count];
        for (int i = 0; i < (int)count; i++)
        {
            data[i] = new VkCheckpointDataNV { SType = StructureType.CheckpointDataNV };
        }

        read(Graphics, &count, data);
        for (int i = 0; i < (int)count; i++)
        {
            VkCheckpointDataNV c = data[i];
        }
    }

    public unsafe void ReportDeviceFault()
    {
        ReportCheckpoints();

        if (!_deviceFaultEnabled)
        {
            return;
        }

        if (!_vk.TryGetDeviceExtension(_instance, Device, out ExtDeviceFault ext))
        {
            return;
        }

        // Pre-size the arrays to a capacity and read in one call, rather than the counts-then-info two
        // step -- the null-info counts call marshalled badly and faulted the process before it could say
        // anything at all.
        const int capacity = 256;
        DeviceFaultAddressInfoEXT* addresses = stackalloc DeviceFaultAddressInfoEXT[capacity];
        DeviceFaultVendorInfoEXT* vendors = stackalloc DeviceFaultVendorInfoEXT[capacity];

        DeviceFaultCountsEXT counts = new()
        {
            SType = StructureType.DeviceFaultCountsExt,
            AddressInfoCount = capacity,
            VendorInfoCount = capacity,
        };

        DeviceFaultInfoEXT info = new()
        {
            SType = StructureType.DeviceFaultInfoExt,
            PAddressInfos = addresses,
            PVendorInfos = vendors,
        };

        Result read = ext.GetDeviceFaultInfo(Device, &counts, &info);
        if (read != Result.Success && read != Result.Incomplete)
        {
            return;
        }

        string description = new((sbyte*)info.Description);

        for (int i = 0; i < (int)Math.Min(counts.AddressInfoCount, (uint)capacity); i++)
        {
            DeviceFaultAddressInfoEXT a = addresses[i];
        }

        for (int i = 0; i < (int)Math.Min(counts.VendorInfoCount, (uint)capacity); i++)
        {
            DeviceFaultVendorInfoEXT v = vendors[i];
        }
    }

    public void WaitIdle() => _vk.DeviceWaitIdle(Device);

    /// <inheritdoc/>
    public void Dispose()
    {
        if (_disposed)
        {
            return;
        }

        _disposed = true;

        // Before the device is destroyed: saving the cache reads it back out of the driver.
        _pipelineCache.Dispose();

        TimelineSemaphores?.Dispose();
        Synchronization2?.Dispose();
        Swapchain.Dispose();
        _vk.DestroyDevice(Device, null);
    }

    private Queue QueueAt(VulkanQueueSlot slot)
    {
        _vk.GetDeviceQueue(Device, slot.Family, slot.Index, out Queue queue);
        return queue;
    }

    private Device CreateDevice(PhysicalDeviceSelection selection)
    {
        // One create-info per distinct family, so a unified adapter asks for a single queue and a split
        // one asks for exactly the families it actually uses.
        IReadOnlyDictionary<uint, uint> queueCounts = selection.Queues.QueueCounts;

        float priority = 1.0f;
        DeviceQueueCreateInfo[] queueInfos = new DeviceQueueCreateInfo[queueCounts.Count];
        int index = 0;
        foreach ((uint family, uint count) in queueCounts)
        {
            queueInfos[index++] = new DeviceQueueCreateInfo
            {
                SType = StructureType.DeviceQueueCreateInfo,
                QueueFamilyIndex = family,
                QueueCount = count,
                PQueuePriorities = &priority,
            };
        }

        // The chain must outlive the create call, so it is built here and disposed only afterwards; every
        // structure in it is one the probe confirmed this adapter implements.
        using VulkanStructChain chain = new();
        PhysicalDeviceFeatures features =
            VulkanCapabilityProbe.BuildEnabledFeatures(selection.Capabilities, chain, selection.ApiVersion);

        // Said BEFORE the call, in full, because of how this one fails. Handing vkCreateDevice a pNext
        // structure whose extension is not among the enabled names is undefined, and a driver that does
        // not recognise it faults rather than returning an error -- so the process dies inside the driver
        // with no VkResult to report and no chance to log afterwards. Written out first, the log names the
        // adapter, the exact extension list and every structure in the chain, which is the whole of what
        // the call was given and enough to see the mismatch without the machine that has it.

        nint extensionNames = SilkMarshal.StringArrayToPtr(selection.DeviceExtensions);
        try
        {
            fixed (DeviceQueueCreateInfo* queues = queueInfos)
            {
                DeviceCreateInfo createInfo = new()
                {
                    SType = StructureType.DeviceCreateInfo,
                    PNext = chain.Head,
                    QueueCreateInfoCount = (uint)queueInfos.Length,
                    PQueueCreateInfos = queues,
                    PEnabledFeatures = &features,
                    EnabledExtensionCount = (uint)selection.DeviceExtensions.Count,
                    PpEnabledExtensionNames = (byte**)extensionNames,
                };

                Device device;
                VkCheck.Ok(_vk.CreateDevice(selection.Device, &createInfo, null, &device), "vkCreateDevice");
                return device;
            }
        }
        finally
        {
            SilkMarshal.Free(extensionNames);
        }
    }

    /// <summary>Names every <see cref="Bool32"/> field of a feature structure that is set.</summary>
    /// <typeparam name="T">The Vulkan feature structure type.</typeparam>
    /// <param name="value">The structure as it will be handed to the driver.</param>
    /// <returns>The set field names, comma-separated, or a note that none is set.</returns>
    private static string RequestedFlags<T>(in T value)
        where T : unmanaged
    {
        // Reflection over a blittable struct, once per process, on the way into a call that may not
        // return: the cost is nothing and the field names are the ones the specification uses.
        object boxed = value;
        List<string> set = [];
        foreach (FieldInfo field in typeof(T).GetFields(BindingFlags.Public | BindingFlags.Instance))
        {
            if (field.FieldType == typeof(Bool32) && (Bool32)field.GetValue(boxed)!)
            {
                set.Add(field.Name);
            }
        }

        return set.Count == 0 ? "none" : string.Join(", ", set);
    }
}
