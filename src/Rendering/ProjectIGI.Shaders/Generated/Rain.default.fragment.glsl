#version 430
#if defined(GL_EXT_control_flow_attributes)
#extension GL_EXT_control_flow_attributes : require
#define SPIRV_CROSS_FLATTEN [[flatten]]
#define SPIRV_CROSS_BRANCH [[dont_flatten]]
#define SPIRV_CROSS_UNROLL [[unroll]]
#define SPIRV_CROSS_LOOP [[dont_unroll]]
#else
#define SPIRV_CROSS_FLATTEN
#define SPIRV_CROSS_BRANCH
#define SPIRV_CROSS_UNROLL
#define SPIRV_CROSS_LOOP
#endif

#ifndef SPIRV_CROSS_CONSTANT_ID_64
#define SPIRV_CROSS_CONSTANT_ID_64 1
#endif
const int cClipYDown = SPIRV_CROSS_CONSTANT_ID_64;
const bool _91 = (cClipYDown != 0);

layout(binding = 0, std140) uniform RainParams_std140
{
    vec4 fog;
    vec4 screen;
    vec4 lens;
} p;

layout(binding = 0) uniform sampler2D _394;
layout(binding = 1) uniform sampler2D _396;

layout(location = 0) out vec4 entryPointParam_fragmentMain;
layout(location = 0) in vec2 input_diffuseUv;
layout(location = 1) in vec4 input_color;
layout(location = 2) in float input_viewDepth;

void main()
{
    vec4 _sampled = texture(_394, input_diffuseUv);
    float shape = _sampled.w;
    float coverage = shape * input_color.w;
    if (coverage < 0.00200000009499490261077880859375)
    {
        discard;
    }
    float _151 = isnan(1.0) ? p.lens.z : (isnan(p.lens.z) ? 1.0 : max(p.lens.z, 1.0));
    float _157 = fract(input_diffuseUv.x * _151) * 2.0;
    float across = _157 - 1.0;
    float _336 = dFdx(input_diffuseUv.x);
    float _339 = dFdy(input_diffuseUv.x);
    vec2 slope = vec2(_336, _339);
    float _177 = length(slope);
    float _178 = isnan(9.9999999747524270787835121154785e-07) ? _177 : (isnan(_177) ? 9.9999999747524270787835121154785e-07 : max(_177, 9.9999999747524270787835121154785e-07));
    float _187 = ((1.0 / _151) / _178) * p.lens.x;
    float rim = across * across;
    vec2 _211 = gl_FragCoord.xy * p.screen.zw;
    float _216 = p.screen.x * p.screen.w;
    int _340 = 0;
    vec3 _341 = vec3(0.0);
    SPIRV_CROSS_UNROLL
    for (;;)
    {
        if (!(_340 < 8))
        {
            break;
        }
        int _352 = _340;
        float _355 = (float(_352) + 0.5) * 0.785398185253143310546875;
        _340++;
        _341 += textureLod(_396, clamp((_211 + (vec2(cos(_355) / _216, sin(_355)) * 0.119999997317790985107421875)) - vec2(0.0, 0.07999999821186065673828125), vec2(0.0), vec2(1.0)), 0.0).xyz;
        continue;
    }
    float _321 = clamp(coverage * 1.39999997615814208984375, 0.0, 1.0);
    vec3 _322 = (((mix(textureLod(_396, clamp((gl_FragCoord.xy + ((slope / vec2(_178)) * ((1.0 - _157) * (isnan(1.0) ? _187 : (isnan(_187) ? 1.0 : max(_187, 1.0)))))) * p.screen.zw, vec2(0.0), vec2(1.0)), 0.0).xyz, _341 * 0.125, vec3(clamp(p.lens.y * (0.699999988079071044921875 + (0.60000002384185791015625 * rim)), 0.0, 1.0))) * ((1.0 + (p.lens.w * rim)) - (0.0599999986588954925537109375 * (1.0 - rim)))) + (input_color.xyz * shape)) + ((input_color.xyz * shape) * (exp((-p.fog.w) * (isnan(0.0) ? input_viewDepth : (isnan(input_viewDepth) ? 0.0 : max(input_viewDepth, 0.0)))) - 1.0))) * _321;
    entryPointParam_fragmentMain = vec4(_322, _321);
}

