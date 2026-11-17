#version 430

#ifndef SPIRV_CROSS_CONSTANT_ID_64
#define SPIRV_CROSS_CONSTANT_ID_64 1
#endif
const int cClipYDown = SPIRV_CROSS_CONSTANT_ID_64;
#ifndef SPIRV_CROSS_CONSTANT_ID_0
#define SPIRV_CROSS_CONSTANT_ID_0 0.501960813999176025390625
#endif
const float cAlphaReference = SPIRV_CROSS_CONSTANT_ID_0;
#ifndef SPIRV_CROSS_CONSTANT_ID_66
#define SPIRV_CROSS_CONSTANT_ID_66 0
#endif
const int cSamplerDecodes = SPIRV_CROSS_CONSTANT_ID_66;
#ifndef SPIRV_CROSS_CONSTANT_ID_13
#define SPIRV_CROSS_CONSTANT_ID_13 0.0
#endif
const float cSunDirectionX = SPIRV_CROSS_CONSTANT_ID_13;
#ifndef SPIRV_CROSS_CONSTANT_ID_14
#define SPIRV_CROSS_CONSTANT_ID_14 0.0
#endif
const float cSunDirectionY = SPIRV_CROSS_CONSTANT_ID_14;
#ifndef SPIRV_CROSS_CONSTANT_ID_15
#define SPIRV_CROSS_CONSTANT_ID_15 0.0
#endif
const float cSunDirectionZ = SPIRV_CROSS_CONSTANT_ID_15;
#ifndef SPIRV_CROSS_CONSTANT_ID_6
#define SPIRV_CROSS_CONSTANT_ID_6 0.0
#endif
const float cSunAmbientRed = SPIRV_CROSS_CONSTANT_ID_6;
#ifndef SPIRV_CROSS_CONSTANT_ID_7
#define SPIRV_CROSS_CONSTANT_ID_7 0.0
#endif
const float cSunAmbientGreen = SPIRV_CROSS_CONSTANT_ID_7;
#ifndef SPIRV_CROSS_CONSTANT_ID_8
#define SPIRV_CROSS_CONSTANT_ID_8 0.0
#endif
const float cSunAmbientBlue = SPIRV_CROSS_CONSTANT_ID_8;
#ifndef SPIRV_CROSS_CONSTANT_ID_9
#define SPIRV_CROSS_CONSTANT_ID_9 0.0
#endif
const float cSunRed = SPIRV_CROSS_CONSTANT_ID_9;
#ifndef SPIRV_CROSS_CONSTANT_ID_10
#define SPIRV_CROSS_CONSTANT_ID_10 0.0
#endif
const float cSunGreen = SPIRV_CROSS_CONSTANT_ID_10;
#ifndef SPIRV_CROSS_CONSTANT_ID_11
#define SPIRV_CROSS_CONSTANT_ID_11 0.0
#endif
const float cSunBlue = SPIRV_CROSS_CONSTANT_ID_11;
const bool _248 = (cClipYDown != 0);
const bool _515 = (cSamplerDecodes != 0);

layout(binding = 1, std140) uniform GBufferPush_std140
{
    layout(row_major) mat4 modelViewProjection;
    vec4 normal0;
    vec4 normal1;
    vec4 normal2;
    vec4 material;
} push;

layout(location = 0) out vec2 entryPointParam_vertexMain_diffuseUv;
layout(location = 1) out vec2 entryPointParam_vertexMain_lightmapUv;
layout(location = 2) out vec4 entryPointParam_vertexMain_color;
layout(location = 3) out vec3 entryPointParam_vertexMain_worldNormal;
layout(location = 4) out float entryPointParam_vertexMain_fade;
layout(location = 5) out vec3 entryPointParam_vertexMain_surfacePosition;
layout(location = 0) in vec3 input_position;
layout(location = 1) in vec3 input_normal;
layout(location = 2) in vec2 input_diffuseUv;
layout(location = 3) in vec2 input_lightmapUv;
layout(location = 4) in vec4 input_colorBgra;
layout(location = 5) in vec4 input_surfaceNormal;
layout(location = 6) in vec3 input_previousPosition;
layout(location = 7) in vec3 input_previousNormal;

mat4 spvWorkaroundRowMajor(mat4 wrap) { return wrap; }

void main()
{
    bool ramped;
    if (push.normal0.w > 0.5)
    {
        ramped = push.normal0.w < 2.5;
    }
    else
    {
        ramped = false;
    }
    vec3 localPosition_1 = input_position + ((input_previousPosition - input_position) * push.normal1.w);
    float _1105 = 1.0;
    float material;
    vec3 localPosition;
    if (ramped)
    {
        vec3 target = (localPosition_1 + push.normal1.xyz) + input_normal;
        float _164 = abs(target.x);
        float _167 = abs(target.y);
        float _169 = abs(target.z);
        float _170 = isnan(_169) ? _167 : (isnan(_167) ? _169 : max(_167, _169));
        float _178 = clamp((((isnan(_170) ? _164 : (isnan(_164) ? _170 : max(_164, _170))) * push.normal0.x) - push.normal0.y) * push.normal0.z, 0.0, 1.0);
        float selector = input_colorBgra.w * 3.0;
        if (selector < 0.5)
        {
            material = 0.0;
        }
        else
        {
            if (selector < 1.5)
            {
                material = _178;
            }
            else
            {
                if (selector < 2.5)
                {
                    material = 1.0 - _178;
                }
                else
                {
                    material = 1.0;
                }
            }
        }
        if (push.normal0.w > 2.5)
        {
            material = 1.0;
        }
        else
        {
            float _83;
            if (push.normal0.w > 1.5)
            {
                _83 = 1.0 - _178;
            }
            else
            {
                _83 = _178;
            }
            material *= _83;
        }
        _1105 = material;
        material = _178;
        localPosition = localPosition_1 + (input_normal * _178);
    }
    else
    {
        material = 0.0;
        localPosition = localPosition_1;
    }
    vec4 _235 = vec4(localPosition, 1.0) * spvWorkaroundRowMajor(push.modelViewProjection);
    vec4 clip = _235;
    float _238 = _235.y;
    float _944;
    if (_248)
    {
        _944 = -_238;
    }
    else
    {
        _944 = _238;
    }
    vec4 _1139 = clip;
    _1139.y = _944;
    _1139.z = (_1139.w - _1139.z) * 0.5;
    clip = _1139;
    vec4 _1100 = _1139;
    vec3 localNormal;
    if (input_surfaceNormal.w > 0.5)
    {
        localNormal = (input_surfaceNormal.xyz * 2.0) - vec3(1.0);
    }
    else
    {
        localNormal = input_normal + ((input_previousNormal - input_normal) * push.normal1.w);
    }
    if (!ramped)
    {
        localNormal = ((push.normal0.xyz * localNormal.x) + (push.normal1.xyz * localNormal.y)) + (push.normal2.xyz * localNormal.z);
    }
    vec3 _1104 = localNormal;
    if (ramped)
    {
        localPosition += push.normal1.xyz;
    }
    else
    {
        localPosition = ((push.normal0.xyz * localPosition.x) + (push.normal1.xyz * localPosition.y)) + (push.normal2.xyz * localPosition.z);
    }
    vec3 _1106 = localPosition;
    vec2 _88;
    if (ramped)
    {
        _88 = input_diffuseUv + (input_lightmapUv * material);
    }
    else
    {
        _88 = input_diffuseUv;
    }
    vec2 _1101 = _88;
    vec2 _1102 = input_lightmapUv;
    vec4 _89;
    if (ramped)
    {
        _89 = vec4(1.0);
    }
    else
    {
        _89 = input_colorBgra.zyxw;
    }
    gl_Position = _1100;
    entryPointParam_vertexMain_diffuseUv = _1101;
    entryPointParam_vertexMain_lightmapUv = _1102;
    entryPointParam_vertexMain_color = _89;
    entryPointParam_vertexMain_worldNormal = _1104;
    entryPointParam_vertexMain_fade = _1105;
    entryPointParam_vertexMain_surfacePosition = _1106;
}

