#version 430

#ifndef SPIRV_CROSS_CONSTANT_ID_64
#define SPIRV_CROSS_CONSTANT_ID_64 1
#endif
const int cClipYDown = SPIRV_CROSS_CONSTANT_ID_64;
#ifndef SPIRV_CROSS_CONSTANT_ID_0
#define SPIRV_CROSS_CONSTANT_ID_0 0.501960813999176025390625
#endif
const float cAlphaReference = SPIRV_CROSS_CONSTANT_ID_0;
const bool _135 = (cClipYDown != 0);

layout(binding = 0, std140) uniform ShadowPush_std140
{
    layout(row_major) mat4 modelViewProjection;
    vec4 terrainRamp;
    vec4 terrainOffset;
} push;

layout(location = 0) out vec2 entryPointParam_vertexMain_diffuseUv;
layout(location = 1) out float entryPointParam_vertexMain_alpha;
layout(location = 0) in vec3 input_position;
layout(location = 1) in vec3 input_normal;
layout(location = 2) in vec2 input_diffuseUv;
layout(location = 3) in vec2 input_lightmapUv;
layout(location = 4) in vec4 input_colorBgra;
layout(location = 5) in vec3 input_previousPosition;

mat4 spvWorkaroundRowMajor(mat4 wrap) { return wrap; }

void main()
{
    vec3 localPosition_1 = input_position + ((input_previousPosition - input_position) * push.terrainOffset.w);
    vec3 localPosition;
    vec2 diffuseUv;
    if (push.terrainRamp.w > 0.5)
    {
        vec3 target = (localPosition_1 + push.terrainOffset.xyz) + input_normal;
        float _84 = abs(target.x);
        float _87 = abs(target.y);
        float _89 = abs(target.z);
        float _90 = isnan(_89) ? _87 : (isnan(_87) ? _89 : max(_87, _89));
        float _101 = clamp((((isnan(_90) ? _84 : (isnan(_84) ? _90 : max(_84, _90))) * push.terrainRamp.x) - push.terrainRamp.y) * push.terrainRamp.z, 0.0, 1.0);
        localPosition = localPosition_1 + (input_normal * _101);
        diffuseUv = input_diffuseUv + (input_lightmapUv * _101);
    }
    else
    {
        localPosition = localPosition_1;
        diffuseUv = input_diffuseUv;
    }
    vec4 _122 = vec4(localPosition, 1.0) * spvWorkaroundRowMajor(push.modelViewProjection);
    vec4 clip = _122;
    float _125 = _122.y;
    float _198;
    if (_135)
    {
        _198 = -_125;
    }
    else
    {
        _198 = _125;
    }
    vec4 _213 = clip;
    _213.y = _198;
    _213.z = (_213.z + _213.w) * 0.5;
    clip = _213;
    vec4 _206 = _213;
    vec2 _207 = diffuseUv;
    float _51;
    if (push.terrainRamp.w > 0.5)
    {
        _51 = 1.0;
    }
    else
    {
        _51 = input_colorBgra.w;
    }
    gl_Position = _206;
    entryPointParam_vertexMain_diffuseUv = _207;
    entryPointParam_vertexMain_alpha = _51;
}

