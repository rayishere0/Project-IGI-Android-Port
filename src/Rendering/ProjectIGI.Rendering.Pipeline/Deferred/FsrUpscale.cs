using ProjectIGI.Rendering.Pipeline.Compute;
using ProjectIGI.Rendering.Pipeline.Targets;
using ProjectIGI.Rendering.Rhi;
using ProjectIGI.Shaders;

namespace ProjectIGI.Rendering.Pipeline.Deferred;

/// <summary>
/// AMD FidelityFX Super Resolution 1.0: two compute passes that turn the render-resolution lit
/// scene into the output-resolution picture without any temporal history.
/// </summary>
/// <remarks>
/// <para>
/// The first pass (EASU) upscales: a 12-tap edge-adaptive filter that follows the local edge, so a
/// diagonal stays a diagonal instead of staircasing the way a bilinear upscale does. The second
/// pass (RCAS) sharpens what the upsample softened, clamped to the neighbourhood so it cannot ring.
/// Together they are FSR 1.0's two-pass shape, and they run wherever the render scale is below one
/// and FSR is the active reconstruction.
/// </para>
/// <para>
/// The passes read the lit scene at render resolution and write the output-resolution picture into
/// <see cref="SceneTargetId.ResolveOutput"/>, the same target the temporal resolve writes, so the
/// resolve that follows reads it the same way. The upsample's own output goes through an
/// intermediate at output resolution (<see cref="SceneTargetId.FsrIntermediate"/>), because the
/// sharpening pass reads the picture it writes.
/// </para>
/// </remarks>
public sealed class FsrUpscale : IDisposable
{
    private readonly ComputePass _easu;
    private readonly ComputePass _rcas;
    private readonly ComputeParameters _easuParams;
    private readonly ComputeParameters _rcasParams;
    private readonly IRhiSampler _sampler;
    private bool _disposed;

    /// <summary>Initialises a new instance of the <see cref="FsrUpscale"/> class.</summary>
    /// <param name="device">The device the passes run on.</param>
    /// <param name="framesInFlight">How many parameter buffers to keep of each.</param>
    public FsrUpscale(IRhiDevice device, int framesInFlight)
    {
        ArgumentNullException.ThrowIfNull(device);

        _easu = new ComputePass(device, ShaderModuleId.FsrEasu, "fsr.easu");
        _rcas = new ComputePass(device, ShaderModuleId.FsrRcas, "fsr.rcas");

        _easuParams = new ComputeParameters(device, FsrParameters.EasuFloats * sizeof(float), framesInFlight, "fsr.easu");
        _rcasParams = new ComputeParameters(device, FsrParameters.RcasFloats * sizeof(float), framesInFlight, "fsr.rcas");

        // One sampler for both passes. Everything these passes read is screen-space and read the
        // same way: bilinear, clamped, because an upsample lands between texels and a coordinate
        // off the edge has no neighbour to wrap to.
        _sampler = device.CreateSampler(new RhiSamplerDescriptor(Label: "fsr"));
    }

    /// <summary>Gets whether a device can run both passes.</summary>
    /// <param name="device">The device.</param>
    public static bool RunsOn(IRhiDevice device)
    {
        ArgumentNullException.ThrowIfNull(device);

        return ((ReadOnlySpan<(ShaderModuleId Module, ShaderVariant Variant)>)
            [
                (ShaderModuleId.FsrEasu, default),
                (ShaderModuleId.FsrRcas, default),
            ]).ToArray().All(entry => ShaderCatalog.Compiles(entry.Module, entry.Variant, device.ShaderTarget));
    }

    /// <summary>Upscales the lit scene from render resolution to output resolution.</summary>
    /// <param name="pass">The compute pass encoder to record into.</param>
    /// <param name="targets">The frame's targets.</param>
    /// <param name="frame">Which frame in flight this is.</param>
    /// <param name="renderWidth">The render width the picture is upsampled from.</param>
    /// <param name="renderHeight">The render height.</param>
    /// <param name="outputWidth">The output width it is upsampled to.</param>
    /// <param name="outputHeight">The output height.</param>
    public void Record(
        IRhiComputePassEncoder pass,
        SceneTargetSet targets,
        int frame,
        int renderWidth,
        int renderHeight,
        int outputWidth,
        int outputHeight)
    {
        ArgumentNullException.ThrowIfNull(pass);
        ArgumentNullException.ThrowIfNull(targets);
        ObjectDisposedException.ThrowIf(_disposed, this);

        // The upsample: the lit scene at render resolution into the intermediate at output
        // resolution.
        Span<float> easu = stackalloc float[FsrParameters.EasuFloats];
        FsrParameters.WriteEasu(easu, renderWidth, renderHeight, outputWidth, outputHeight);

        _easu.Bind("uInput", targets.View(SceneTargetId.Lit));
        _easu.Bind("uOutput", targets.View(SceneTargetId.FsrIntermediate));
        _easu.Bind("p", _easuParams.Write<float>(frame, easu));
        _easu.BindRemainingSamplers(_sampler);
        _easu.Dispatch(pass, outputWidth, outputHeight);

        // The sharpening: the intermediate into the resolve output, which is what the resolve
        // that follows reads.
        Span<float> rcas = stackalloc float[FsrParameters.RcasFloats];
        FsrParameters.WriteRcas(rcas, outputWidth, outputHeight);

        _rcas.Bind("uInput", targets.View(SceneTargetId.FsrIntermediate));
        _rcas.Bind("uOutput", targets.View(SceneTargetId.ResolveOutput));
        _rcas.Bind("p", _rcasParams.Write<float>(frame, rcas));
        _rcas.BindRemainingSamplers(_sampler);
        _rcas.Dispatch(pass, outputWidth, outputHeight);
    }

    /// <inheritdoc/>
    public void Dispose()
    {
        if (_disposed)
        {
            return;
        }

        _disposed = true;
        _easu.Dispose();
        _rcas.Dispose();
        _easuParams.Dispose();
        _rcasParams.Dispose();
        _sampler.Dispose();
    }
}
