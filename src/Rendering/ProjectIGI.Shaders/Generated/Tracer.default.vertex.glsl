#version 430

#ifndef SPIRV_CROSS_CONSTANT_ID_64
#define SPIRV_CROSS_CONSTANT_ID_64 1
#endif
const int cClipYDown = SPIRV_CROSS_CONSTANT_ID_64;
#ifndef SPIRV_CROSS_CONSTANT_ID_65
#define SPIRV_CROSS_CONSTANT_ID_65 0
#endif
const int cTargetEncodes = SPIRV_CROSS_CONSTANT_ID_65;
const bool _82 = (cClipYDown != 0);
const bool _190 = (cTargetEncodes != 0);

layout(binding = 0, std140) uniform TracerPush_std140
{
    layout(row_major) mat4 modelViewProjection;
    vec4 style;
} push;

layout(location = 0) out vec2 entryPointParam_vertexMain_strip;
layout(location = 1) out vec4 entryPointParam_vertexMain_color;
layout(location = 0) in vec3 input_position;
layout(location = 2) in vec2 input_diffuseUv;
layout(location = 4) in vec4 input_colorBgra;

mat4 spvWorkaroundRowMajor(mat4 wrap) { return wrap; }

void main()
{
    vec2 _490 = input_diffuseUv;
    vec4 _491 = input_colorBgra.zyxw;
    vec4 _67 = vec4(input_position, 1.0) * spvWorkaroundRowMajor(push.modelViewProjection);
    vec4 clip = _67;
    float _71 = _67.y;
    float _317;
    if (_82)
    {
        _317 = -_71;
    }
    else
    {
        _317 = _71;
    }
    vec4 _513 = clip;
    _513.y = _317;
    _513.z = (_513.w - _513.z) * 0.5;
    clip = _513;
    gl_Position = _513;
    entryPointParam_vertexMain_strip = _490;
    entryPointParam_vertexMain_color = _491;
}

