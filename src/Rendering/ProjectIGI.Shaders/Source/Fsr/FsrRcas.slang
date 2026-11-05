// FidelityFX Super Resolution 1.0 style robust contrast-adaptive sharpening (RCAS).
//
// The sharpening half of FSR 1.0's architecture, written for this engine's Slang rather than a
// bit-exact port of AMD's shader: it restores the local contrast the upsample softened, without
// ringing. It reads the upscaled picture the EASU pass wrote and sharpens it in place, one
// output pixel at a time.
//
// How it stays robust: the sharpening is a pull towards the centre pixel and away from the
// neighbours' average, but the result is clamped to the neighbourhood's own minimum and maximum,
// so a sharpened pixel can never overshoot past what its neighbours already hold. The amount is
// contrast-adaptive -- a flat area (where the neighbours agree) is sharpened less than a textured
// one -- which is what stops it amplifying noise into grain. The strength comes from the constant
// block (see FsrParameters): 0 is no sharpening, and the engine's default is the value FSR 1.0
// ships with for its quality preset.

[[vk::binding(0, 0)]] Texture2D<float4> uInput;
[[vk::binding(1, 0)]] SamplerState uInputSampler;
[[vk::binding(2, 0)]] [[vk::image_format("rgba16f")]] WTexture2D<float4> uOutput;

struct Params
{
    // sharpening strength (0 is none), one texel x, one texel y, unused.
    float4 con0;
    // output size (w, h, 1/w, 1/h).
    float4 con1;
};

[[vk::binding(3, 0)]] ConstantBuffer<Params> p;

float FsrRcasLuma(float3 c)
{
    return dot(c, float3(0.299, 0.587, 0.114));
}

[numthreads(8, 8, 1)]
void computeMain(uint3 id : SV_DispatchThreadID)
{
    int2 px = int2(id.xy);
    int2 size = int2(p.con1.xy);
    if (px.x >= size.x || px.y >= size.y)
    {
        return;
    }

    float2 texel = p.con0.yz;
    float2 uv = (float2(px) + 0.5) * texel;

    // The five taps: the centre and its four neighbours.
    float3 c = uInput.SampleLevel(uInputSampler, uv, 0.0).rgb;
    float3 n = uInput.SampleLevel(uInputSampler, uv + float2(0.0, -texel.y), 0.0).rgb;
    float3 s = uInput.SampleLevel(uInputSampler, uv + float2(0.0, texel.y), 0.0).rgb;
    float3 w = uInput.SampleLevel(uInputSampler, uv + float2(-texel.x, 0.0), 0.0).rgb;
    float3 e = uInput.SampleLevel(uInputSampler, uv + float2(texel.x, 0.0), 0.0).rgb;

    // The neighbourhood's range, per channel: the sharpened pixel is clamped to it, so it can
    // never overshoot past what its neighbours already hold.
    float3 mn = min(min(min(n, s), w), e);
    float3 mx = max(max(max(n, s), w), e);

    // The neighbours' average, and how far the centre sits from it: that distance is the local
    // contrast the sharpening restores.
    float3 avg = (n + s + w + e) * 0.25;
    float3 diff = c - avg;

    // Contrast-adaptive: the weight falls as the neighbourhood's own range grows, so a flat area
    // (small range) is sharpened more gently than a textured one, and a hard edge (large range)
    // is left mostly alone rather than haloed.
    float range = max(max(mx.r - mn.r, mx.g - mn.g), mx.b - mn.b);
    float weight = p.con0.x / (1.0 + range * 4.0);

    float3 sharpened = clamp(c + diff * weight, mn, mx);
    uOutput[px] = float4(max(sharpened, float3(0.0, 0.0, 0.0)), 1.0);
}
