#version 430

#ifndef SPIRV_CROSS_CONSTANT_ID_64
#define SPIRV_CROSS_CONSTANT_ID_64 1
#endif
const int cClipYDown = SPIRV_CROSS_CONSTANT_ID_64;
#ifndef SPIRV_CROSS_CONSTANT_ID_66
#define SPIRV_CROSS_CONSTANT_ID_66 0
#endif
const int cSamplerDecodes = SPIRV_CROSS_CONSTANT_ID_66;
const bool _73 = (cClipYDown != 0);
const bool _147 = (cSamplerDecodes != 0);

layout(binding = 0, std140) uniform CardPush_std140
{
    layout(row_major) mat4 modelViewProjection;
    vec4 normal0;
    vec4 normal1;
    vec4 normal2;
    vec4 material;
} push;

layout(location = 0) out vec2 entryPointParam_vertexMain_diffuseUv;
layout(location = 1) out vec4 entryPointParam_vertexMain_color;
layout(location = 2) out vec3 entryPointParam_vertexMain_modelNormal;
layout(location = 0) in vec3 input_position;
layout(location = 1) in vec3 input_normal;
layout(location = 2) in vec2 input_diffuseUv;
layout(location = 4) in vec4 input_colorBgra;

mat4 spvWorkaroundRowMajor(mat4 wrap) { return wrap; }

void main()
{
    vec4 _57 = vec4(input_position, 1.0) * spvWorkaroundRowMajor(push.modelViewProjection);
    vec4 clip = _57;
    float _62 = _57.y;
    float _222;
    if (_73)
    {
        _222 = -_62;
    }
    else
    {
        _222 = _62;
    }
    vec4 _288 = clip;
    _288.y = _222;
    _288.z = (_288.z + _288.w) * 0.5;
    clip = _288;
    gl_Position = _288;
    entryPointParam_vertexMain_diffuseUv = input_diffuseUv;
    entryPointParam_vertexMain_color = input_colorBgra.zyxw;
    entryPointParam_vertexMain_modelNormal = input_normal;
}

