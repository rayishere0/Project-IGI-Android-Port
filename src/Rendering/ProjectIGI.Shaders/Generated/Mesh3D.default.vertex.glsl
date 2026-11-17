#version 430

#ifndef SPIRV_CROSS_CONSTANT_ID_1
#define SPIRV_CROSS_CONSTANT_ID_1 0
#endif
const int cReflective = SPIRV_CROSS_CONSTANT_ID_1;
#ifndef SPIRV_CROSS_CONSTANT_ID_64
#define SPIRV_CROSS_CONSTANT_ID_64 1
#endif
const int cClipYDown = SPIRV_CROSS_CONSTANT_ID_64;
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
#ifndef SPIRV_CROSS_CONSTANT_ID_0
#define SPIRV_CROSS_CONSTANT_ID_0 0.501960813999176025390625
#endif
const float cAlphaReference = SPIRV_CROSS_CONSTANT_ID_0;
#ifndef SPIRV_CROSS_CONSTANT_ID_66
#define SPIRV_CROSS_CONSTANT_ID_66 0
#endif
const int cSamplerDecodes = SPIRV_CROSS_CONSTANT_ID_66;
#ifndef SPIRV_CROSS_CONSTANT_ID_12
#define SPIRV_CROSS_CONSTANT_ID_12 0
#endif
const int cLinearScene = SPIRV_CROSS_CONSTANT_ID_12;
const bool _166 = (cReflective != 0);
const bool _374 = (cClipYDown != 0);
const bool _589 = (cSamplerDecodes != 0);
const bool _643 = (cLinearScene == 0);
const bool _722 = (cLinearScene != 0);

layout(binding = 0, std140) uniform MeshPush_std140
{
    layout(row_major) mat4 modelViewProjection;
    vec4 markerExposure;
    vec4 normalKey0;
    vec4 normalKey1;
    vec4 normalKey2;
} push;

layout(location = 0) out vec2 entryPointParam_vertexMain_diffuseUv;
layout(location = 1) out vec2 entryPointParam_vertexMain_lightmapUv;
layout(location = 2) out vec4 entryPointParam_vertexMain_color;
layout(location = 3) out vec3 entryPointParam_vertexMain_normal;
layout(location = 4) out float entryPointParam_vertexMain_fade;
layout(location = 5) out float entryPointParam_vertexMain_fog;
layout(location = 6) out vec3 entryPointParam_vertexMain_reflection;
layout(location = 0) in vec3 input_position;
layout(location = 1) in vec3 input_normal;
layout(location = 2) in vec2 input_diffuseUv;
layout(location = 3) in vec2 input_lightmapUv;
layout(location = 4) in vec4 input_colorBgra;
layout(location = 5) in vec3 input_previousPosition;
layout(location = 6) in vec3 input_previousNormal;

mat4 spvWorkaroundRowMajor(mat4 wrap) { return wrap; }

void main()
{
    vec3 localPosition_1 = input_position + ((input_previousPosition - input_position) * push.markerExposure.z);
    vec3 localNormal = input_normal + ((input_previousNormal - input_normal) * push.markerExposure.z);
    vec3 _945 = vec3(0.0);
    if (_166)
    {
        vec3 _169 = normalize(-localPosition_1);
        vec3 _171 = normalize(localNormal);
        _945 = (_171 * (2.0 * dot(_169, _171))) - _169;
    }
    float _943 = 1.0;
    float terrain;
    if (abs(push.markerExposure.x) > 0.5)
    {
        terrain = push.normalKey0.w;
    }
    else
    {
        terrain = 0.0;
    }
    bool _199 = terrain > 0.5;
    float material;
    float facing;
    vec3 localPosition;
    vec2 diffuseUv;
    if (_199)
    {
        vec3 target = (input_position + push.normalKey1.xyz) + input_normal;
        float _213 = abs(target.x);
        float _215 = abs(target.y);
        float _217 = abs(target.z);
        float _218 = isnan(_217) ? _215 : (isnan(_215) ? _217 : max(_215, _217));
        float _226 = clamp((((isnan(_218) ? _213 : (isnan(_213) ? _218 : max(_213, _218))) * push.normalKey0.x) - push.normalKey0.y) * push.normalKey0.z, 0.0, 1.0);
        float selector = input_colorBgra.w * 3.0;
        if (selector < 0.5)
        {
            material = 0.0;
        }
        else
        {
            if (selector < 1.5)
            {
                material = _226;
            }
            else
            {
                if (selector < 2.5)
                {
                    material = 1.0 - _226;
                }
                else
                {
                    material = 1.0;
                }
            }
        }
        if (terrain > 2.5)
        {
            material = 1.0;
        }
        else
        {
            if (terrain > 1.5)
            {
                facing = 1.0 - _226;
            }
            else
            {
                facing = _226;
            }
            material *= facing;
        }
        _943 = material;
        localPosition = input_position + (input_normal * _226);
        diffuseUv = input_diffuseUv + (input_lightmapUv * _226);
    }
    else
    {
        localPosition = localPosition_1;
        diffuseUv = input_diffuseUv;
    }
    vec4 clip = vec4(localPosition, 1.0) * spvWorkaroundRowMajor(push.modelViewProjection);
    bool _84;
    if (abs(push.markerExposure.x) > 0.5)
    {
        _84 = push.markerExposure.x < 1.5;
    }
    else
    {
        _84 = false;
    }
    if (_84)
    {
        material = push.normalKey2.w;
    }
    else
    {
        material = 0.0;
    }
    bool _316 = material > 0.0;
    if (_316)
    {
        facing = clamp(exp((-material) * (isnan(0.0) ? clip.w : (isnan(clip.w) ? 0.0 : max(clip.w, 0.0)))), 0.0, 1.0);
    }
    else
    {
        facing = 1.0;
    }
    float _944 = facing;
    if (_316)
    {
        _84 = terrain < 0.5;
    }
    else
    {
        _84 = false;
    }
    if (_84)
    {
        _84 = push.normalKey1.w > 0.0;
    }
    else
    {
        _84 = false;
    }
    if (_84)
    {
        _944 = clamp(push.normalKey1.w - (material * clip.w), 0.0, 1.0);
    }
    float _852;
    if (_374)
    {
        _852 = -clip.y;
    }
    else
    {
        _852 = clip.y;
    }
    vec4 _965 = clip;
    _965.y = _852;
    _965.z = (_965.w - _965.z) * 0.5;
    clip = _965;
    vec4 _938 = _965;
    vec2 _939 = diffuseUv;
    vec2 _940 = input_lightmapUv;
    vec4 _85;
    if (_199)
    {
        _85 = vec4(1.0);
    }
    else
    {
        _85 = input_colorBgra.zyxw;
    }
    vec4 _941 = _85;
    if (abs(push.markerExposure.x) > 0.5)
    {
        _84 = terrain < 0.5;
    }
    else
    {
        _84 = false;
    }
    if (_84)
    {
        _84 = push.normalKey0.w >= 0.0;
    }
    else
    {
        _84 = false;
    }
    if (_84)
    {
        _84 = dot(push.normalKey0.xyz, push.normalKey0.xyz) > 9.9999999392252902907785028219223e-09;
    }
    else
    {
        _84 = false;
    }
    if (_84)
    {
        float _446 = length(localNormal);
        if (_446 > 0.0)
        {
            facing = dot(localNormal / vec3(_446), push.normalKey0.xyz);
        }
        else
        {
            facing = 0.0;
        }
        vec4 _462 = _941;
        vec3 _467 = _462.xyz * clamp(vec3(cSunAmbientRed, cSunAmbientGreen, cSunAmbientBlue) + (vec3(cSunRed, cSunGreen, cSunBlue) * (isnan(0.0) ? facing : (isnan(facing) ? 0.0 : max(facing, 0.0)))), vec3(0.0), vec3(1.0));
        vec4 _970 = _462;
        _970.x = _467.x;
        _970.y = _467.y;
        _970.z = _467.z;
        _941 = _970;
    }
    gl_Position = _938;
    entryPointParam_vertexMain_diffuseUv = _939;
    entryPointParam_vertexMain_lightmapUv = _940;
    entryPointParam_vertexMain_color = _941;
    entryPointParam_vertexMain_normal = vec3(dot(push.normalKey0.xyz, localNormal), dot(push.normalKey1.xyz, localNormal), dot(push.normalKey2.xyz, localNormal));
    entryPointParam_vertexMain_fade = _943;
    entryPointParam_vertexMain_fog = _944;
    entryPointParam_vertexMain_reflection = _945;
}

