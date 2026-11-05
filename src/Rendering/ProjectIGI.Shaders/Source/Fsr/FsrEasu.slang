// FidelityFX Super Resolution 1.0 style edge-adaptive spatial upsampling (EASU).
//
// The upsample half of FSR 1.0's architecture, written for this engine's Slang rather than a
// bit-exact port of AMD's shader: it turns the render-resolution picture into the output-resolution
// one without any temporal history, with a 12-tap filter whose weights follow the local edge, so a
// diagonal stays a diagonal instead of staircasing the way a bilinear upscale does, and a flat area
// stays flat instead of ringing the way a plain Lanczos does. The sharpening half (RCAS) follows
// in FsrRcas.slang, the same two-pass shape as AMD's FSR 1.0.
//
// The four constant blocks are filled on the CPU (see FsrParameters): con0 is the input viewport
// and its reciprocal, con1 the output viewport and its reciprocal, con2 the half-pixel offsets,
// con3 the input-to-output scale. The input is the lit scene at render resolution; the output is
// an intermediate at output resolution, sharpened afterwards by the RCAS pass.
//
// The luma here is the same Rec.709 luma the temporal resolve uses, so the edge the filter follows
// is the edge the eye follows.

[[vk::binding(0, 0)]] Texture2D<float4> uInput;
[[vk::binding(1, 0)]] SamplerState uInputSampler;
[[vk::binding(2, 0)]] [[vk::image_format("rgba16f")]] WTexture2D<float4> uOutput;

struct Params
{
    // input viewport (w, h, 1/w, 1/h).
    float4 con0;
    // output viewport (w, h, 1/w, 1/h).
    float4 con1;
    // half-pixel offsets (0.5/w_in, 0.5/h_in, 0.5/w_out, 0.5/h_out).
    float4 con2;
    // input-to-output scale (w_in/w_out, h_in/h_out, 0, 0).
    float4 con3;
};

[[vk::binding(3, 0)]] ConstantBuffer<Params> p;

float FsrEasuLuma(float3 c)
{
    return dot(c, float3(0.299, 0.587, 0.114));
}

// The Lanczos2 lobe, the kernel the upsample weights are built from: a sinc windowed by a sinc,
// so it is sharp without the ringing a plain sinc leaves behind.
float FsrEasuLanczos(float x)
{
    const float pi = 3.14159265;
    float ax = abs(x);
    if (ax >= 2.0)
    {
        return 0.0;
    }
    if (ax < 1e-4)
    {
        return 1.0;
    }
    float pix = pi * x;
    return (sin(pix) / pix) * (sin(pix * 0.5) / (pix * 0.5));
}

[numthreads(8, 8, 1)]
void computeMain(uint3 id : SV_DispatchThreadID)
{
    int2 op = int2(id.xy);
    int2 outSize = int2(p.con1.xy);
    if (op.x >= outSize.x || op.y >= outSize.y)
    {
        return;
    }

    // Where this output pixel sits in input space, and how far it is from the nearest input
    // pixel centre. The fractional part is what the kernel is evaluated at.
    float2 pp = (float2(op) + 0.5) * p.con3.xy - 0.5;
    float2 fp = frac(pp);
    int2 ip = int2(floor(pp));

    // The twelve taps: the 4x4 neighbourhood, minus the four corners, which carry nothing the
    // edge direction does not already say. Each is an offset from the base pixel, in input pixels.
    const int2 offsets[12] = {
        int2(-1, -1), int2(0, -1), int2(1, -1), int2(2, -1),
        int2(-1, 0), int2(0, 0), int2(1, 0), int2(2, 0),
        int2(-1, 1), int2(0, 1), int2(1, 1), int2(2, 1),
    };

    // Gather the taps and their luma. The sampler is bilinear and clamped, so a tap off the edge
    // reads the edge texel rather than wrapping.
    float3 tap[12];
    float luma[12];
    for (int i = 0; i < 12; i++)
    {
        float2 uv = (float2(ip + offsets[i]) + 0.5) * p.con0.zw;
        tap[i] = uInput.SampleLevel(uInputSampler, uv, 0.0).rgb;
        luma[i] = FsrEasuLuma(max(tap[i], float3(0.0, 0.0, 0.0)));
    }

    // Which way the edge runs, from the luma gradient: the horizontal difference of the two rows
    // either side of the centre, against the vertical difference of the two columns. The larger
    // one is the direction the edge crosses, and the filter is stretched along the other one.
    float hGrad = abs(luma[1] - luma[2]) + abs(luma[5] - luma[6]) + abs(luma[9] - luma[10]);
    float vGrad = abs(luma[4] - luma[8]) + abs(luma[5] - luma[9]) + abs(luma[6] - luma[10]);
    bool horizontal = hGrad >= vGrad;

    // The kernel offsets, stretched along the edge: along the edge the taps are close together
    // and the kernel is wide (the picture is smooth there), across it they are far apart and the
    // kernel is narrow (the picture changes fast there). This is what keeps a diagonal sharp.
    float2 dir = horizontal ? float2(1.0, 0.0) : float2(0.0, 1.0);
    float2 stretch = horizontal ? float2(1.0, 0.5) : float2(0.5, 1.0);

    float3 sum = float3(0.0, 0.0, 0.0);
    float wsum = 0.0;
    for (int j = 0; j < 12; j++)
    {
        // The tap's distance from the output pixel, in input pixels, stretched along the edge:
        // the tap centre sits at ip + offset + 0.5 and the output pixel at pp = ip + fp.
        float2 d = (float2(offsets[j]) + 0.5 - fp) * stretch;
        float w = FsrEasuLanczos(d.x) * FsrEasuLanczos(d.y);
        // A tap on the far side of a strong edge is down-weighted, so the filter does not pull
        // colour across the edge. luma[5] is the centre tap.
        w *= 1.0 / (1.0 + abs(luma[j] - luma[5]) * 4.0);
        sum += tap[j] * w;
        wsum += w;
    }

    float3 colour = sum / max(wsum, 1e-4);
    uOutput[op] = float4(max(colour, float3(0.0, 0.0, 0.0)), 1.0);
}
