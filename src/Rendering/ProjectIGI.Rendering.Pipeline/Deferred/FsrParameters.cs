namespace ProjectIGI.Rendering.Pipeline.Deferred;

/// <summary>The constants the FSR 1.0 passes are handed: the upsample's viewport geometry and the sharpening's strength.</summary>
/// <remarks>
/// The EASU constants are the four blocks AMD's FSR 1.0 computes on the CPU (con0-con3): the input
/// and output viewports and their reciprocals, the half-pixel offsets, and the input-to-output scale.
/// The RCAS constant is the sharpening strength alone, with the output size beside it for the bounds
/// check. All of it is derived from the two sizes, so there is nothing to configure and nothing to
/// get out of step with the render resolution.
/// </remarks>
public static class FsrParameters
{
    /// <summary>How many floats the EASU block holds (four float4s).</summary>
    public const int EasuFloats = 16;

    /// <summary>How many floats the RCAS block holds (two float4s).</summary>
    public const int RcasFloats = 8;

    /// <summary>The RCAS sharpening strength: how much local contrast is restored after the upsample.</summary>
    /// <remarks>
    /// Zero is no sharpening. This is the moderate value FSR 1.0 ships with for its quality preset:
    /// enough to restore the detail the upsample softened, not enough to halo a hard edge.
    /// </remarks>
    public const float Sharpness = 0.2f;

    /// <summary>Writes the EASU block.</summary>
    /// <param name="block">Room for <see cref="EasuFloats"/> floats.</param>
    /// <param name="inputWidth">The render width the picture is upsampled from.</param>
    /// <param name="inputHeight">The render height.</param>
    /// <param name="outputWidth">The output width it is upsampled to.</param>
    /// <param name="outputHeight">The output height.</param>
    public static void WriteEasu(
        Span<float> block,
        int inputWidth,
        int inputHeight,
        int outputWidth,
        int outputHeight)
    {
        if (block.Length != EasuFloats)
        {
            throw new ArgumentException($"The FSR EASU block is {EasuFloats} floats, not {block.Length}.", nameof(block));
        }

        block.Clear();

        // con0: the input viewport and its reciprocal.
        block[0] = inputWidth;
        block[1] = inputHeight;
        block[2] = 1f / Math.Max(1, inputWidth);
        block[3] = 1f / Math.Max(1, inputHeight);

        // con1: the output viewport and its reciprocal.
        block[4] = outputWidth;
        block[5] = outputHeight;
        block[6] = 1f / Math.Max(1, outputWidth);
        block[7] = 1f / Math.Max(1, outputHeight);

        // con2: the half-pixel offsets.
        block[8] = 0.5f / Math.Max(1, inputWidth);
        block[9] = 0.5f / Math.Max(1, inputHeight);
        block[10] = 0.5f / Math.Max(1, outputWidth);
        block[11] = 0.5f / Math.Max(1, outputHeight);

        // con3: the input-to-output scale.
        block[12] = inputWidth / (float)Math.Max(1, outputWidth);
        block[13] = inputHeight / (float)Math.Max(1, outputHeight);
        block[14] = 0f;
        block[15] = 0f;
    }

    /// <summary>Writes the RCAS block.</summary>
    /// <param name="block">Room for <see cref="RcasFloats"/> floats.</param>
    /// <param name="outputWidth">The output width being sharpened.</param>
    /// <param name="outputHeight">The output height.</param>
    public static void WriteRcas(Span<float> block, int outputWidth, int outputHeight)
    {
        if (block.Length != RcasFloats)
        {
            throw new ArgumentException($"The FSR RCAS block is {RcasFloats} floats, not {block.Length}.", nameof(block));
        }

        block.Clear();

        // con0: the sharpening strength, one texel x, one texel y, unused.
        block[0] = Sharpness;
        block[1] = 1f / Math.Max(1, outputWidth);
        block[2] = 1f / Math.Max(1, outputHeight);
        block[3] = 0f;

        // con1: the output size and its reciprocal.
        block[4] = outputWidth;
        block[5] = outputHeight;
        block[6] = 1f / Math.Max(1, outputWidth);
        block[7] = 1f / Math.Max(1, outputHeight);
    }
}
