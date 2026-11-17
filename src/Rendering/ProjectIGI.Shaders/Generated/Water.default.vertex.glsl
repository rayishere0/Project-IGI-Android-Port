#version 430

#ifndef SPIRV_CROSS_CONSTANT_ID_1
#define SPIRV_CROSS_CONSTANT_ID_1 0.0
#endif
const float cSunX = SPIRV_CROSS_CONSTANT_ID_1;
#ifndef SPIRV_CROSS_CONSTANT_ID_2
#define SPIRV_CROSS_CONSTANT_ID_2 0.0
#endif
const float cSunY = SPIRV_CROSS_CONSTANT_ID_2;
#ifndef SPIRV_CROSS_CONSTANT_ID_3
#define SPIRV_CROSS_CONSTANT_ID_3 0.0
#endif
const float cSunZ = SPIRV_CROSS_CONSTANT_ID_3;
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
#ifndef SPIRV_CROSS_CONSTANT_ID_6
#define SPIRV_CROSS_CONSTANT_ID_6 0.0
#endif
const float cAmbientRed = SPIRV_CROSS_CONSTANT_ID_6;
#ifndef SPIRV_CROSS_CONSTANT_ID_7
#define SPIRV_CROSS_CONSTANT_ID_7 0.0
#endif
const float cAmbientGreen = SPIRV_CROSS_CONSTANT_ID_7;
#ifndef SPIRV_CROSS_CONSTANT_ID_8
#define SPIRV_CROSS_CONSTANT_ID_8 0.0
#endif
const float cAmbientBlue = SPIRV_CROSS_CONSTANT_ID_8;
#ifndef SPIRV_CROSS_CONSTANT_ID_64
#define SPIRV_CROSS_CONSTANT_ID_64 1
#endif
const int cClipYDown = SPIRV_CROSS_CONSTANT_ID_64;
#ifndef SPIRV_CROSS_CONSTANT_ID_66
#define SPIRV_CROSS_CONSTANT_ID_66 0
#endif
const int cSamplerDecodes = SPIRV_CROSS_CONSTANT_ID_66;
#ifndef SPIRV_CROSS_CONSTANT_ID_12
#define SPIRV_CROSS_CONSTANT_ID_12 0
#endif
const int cLinearScene = SPIRV_CROSS_CONSTANT_ID_12;
const bool _203 = (cClipYDown != 0);
const bool _259 = (cSamplerDecodes != 0);
const bool _300 = (cLinearScene != 0);

layout(binding = 0, std140) uniform WaterPush_std140
{
    layout(row_major) mat4 modelViewProjection;
    vec4 eyeFacing;
    vec4 diffuseScale;
    vec4 specularFog;
    vec4 fogNormalScale;
} push;

layout(location = 0) out vec4 entryPointParam_vertexMain_colour0;
layout(location = 1) out vec3 entryPointParam_vertexMain_colour1;
layout(location = 2) out vec3 entryPointParam_vertexMain_reflection;
layout(location = 3) out float entryPointParam_vertexMain_fog;
layout(location = 0) in vec3 input_position;
layout(location = 1) in vec3 input_normal;
layout(location = 2) in vec2 input_shallowness;

mat4 spvWorkaroundRowMajor(mat4 wrap) { return wrap; }

void main()
{
    vec3 sun = vec3(cSunX, cSunY, cSunZ);
    vec3 sunColour = vec3(cSunRed, cSunGreen, cSunBlue);
    vec3 normal = input_normal * push.fogNormalScale.w;
    vec3 _86 = normalize(push.eyeFacing.xyz - input_position);
    float _97 = dot(_86, normal);
    float _100 = isnan(push.eyeFacing.w) ? _97 : (isnan(_97) ? push.eyeFacing.w : max(_97, push.eyeFacing.w));
    vec3 _388 = ((normal * (_100 * 2.0)) - _86).xzy;
    float grazing = 1.0 - _100;
    float grazing2 = grazing * grazing;
    float _115 = ((grazing2 * grazing2) * grazing) * 0.979632794857025146484375;
    float fresnel = _115 + 0.02036719955503940582275390625;
    float _122 = 0.979632794857025146484375 - _115;
    vec4 _386 = clamp(vec4(fresnel, fresnel, fresnel, _122 * input_shallowness.x), vec4(0.0), vec4(1.0));
    float _138 = dot(normalize(_86 + sun), normal);
    float glint2 = _138 * _138;
    float glint8 = glint2 * glint2;
    vec3 _387 = clamp(((((push.specularFog.xyz * ((glint8 * glint8) * _138)) * sunColour) * fresnel) + ((((sunColour * dot(normal, sun)) * push.diffuseScale.xyz) + vec3(cAmbientRed, cAmbientGreen, cAmbientBlue)) * _122)) * (1.0 - input_shallowness.x), vec3(0.0), vec3(1.0));
    vec4 clip = vec4(input_position, 1.0) * spvWorkaroundRowMajor(push.modelViewProjection);
    float _67;
    if (push.specularFog.w > 0.0)
    {
        _67 = clamp(exp2((-push.specularFog.w) * (isnan(0.0) ? clip.w : (isnan(clip.w) ? 0.0 : max(clip.w, 0.0)))), 0.0, 1.0);
    }
    else
    {
        _67 = 1.0;
    }
    float _389 = _67;
    float _344;
    if (_203)
    {
        _344 = -clip.y;
    }
    else
    {
        _344 = clip.y;
    }
    vec4 _403 = clip;
    _403.y = _344;
    _403.z = (_403.w - _403.z) * 0.5;
    clip = _403;
    gl_Position = _403;
    entryPointParam_vertexMain_colour0 = _386;
    entryPointParam_vertexMain_colour1 = _387;
    entryPointParam_vertexMain_reflection = _388;
    entryPointParam_vertexMain_fog = _389;
}

