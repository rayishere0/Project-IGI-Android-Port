#version 430

#ifndef SPIRV_CROSS_CONSTANT_ID_64
#define SPIRV_CROSS_CONSTANT_ID_64 1
#endif
const int cClipYDown = SPIRV_CROSS_CONSTANT_ID_64;
const bool _91 = (cClipYDown != 0);

layout(binding = 1, std140) uniform RainPush_std140
{
    layout(row_major) mat4 modelViewProjection;
} push;

layout(location = 0) out vec2 entryPointParam_vertexMain_diffuseUv;
layout(location = 1) out vec4 entryPointParam_vertexMain_color;
layout(location = 2) out float entryPointParam_vertexMain_viewDepth;
layout(location = 0) in vec3 input_position;
layout(location = 2) in vec2 input_diffuseUv;
layout(location = 4) in vec4 input_colorBgra;

mat4 spvWorkaroundRowMajor(mat4 wrap) { return wrap; }

void main()
{
    vec2 _381 = input_diffuseUv;
    vec4 _382 = input_colorBgra.zyxw;
    vec4 _76 = vec4(input_position, 1.0) * spvWorkaroundRowMajor(push.modelViewProjection);
    vec4 clip = _76;
    float _80 = _76.y;
    float _326;
    if (_91)
    {
        _326 = -_80;
    }
    else
    {
        _326 = _80;
    }
    vec4 _389 = clip;
    _389.y = _326;
    _389.z = (_389.w - _389.z) * 0.5;
    clip = _389;
    gl_Position = _389;
    entryPointParam_vertexMain_diffuseUv = _381;
    entryPointParam_vertexMain_color = _382;
    entryPointParam_vertexMain_viewDepth = _389.w;
}

