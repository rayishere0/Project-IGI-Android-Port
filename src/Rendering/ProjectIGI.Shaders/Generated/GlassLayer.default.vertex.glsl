#version 430

#ifndef SPIRV_CROSS_CONSTANT_ID_64
#define SPIRV_CROSS_CONSTANT_ID_64 1
#endif
const int cClipYDown = SPIRV_CROSS_CONSTANT_ID_64;
const bool _125 = (cClipYDown != 0);

layout(binding = 0, std140) uniform GlassPush_std140
{
    layout(row_major) mat4 modelViewProjection;
    vec4 normal0;
    vec4 normal1;
    vec4 normal2;
    vec4 glass;
} push;

layout(location = 0) out vec2 entryPointParam_vertexMain_diffuseUv;
layout(location = 1) out vec2 entryPointParam_vertexMain_lightmapUv;
layout(location = 2) out vec4 entryPointParam_vertexMain_color;
layout(location = 3) out vec3 entryPointParam_vertexMain_worldNormal;
layout(location = 4) out float entryPointParam_vertexMain_viewDepth;
layout(location = 5) out vec3 entryPointParam_vertexMain_fromEye;
layout(location = 0) in vec3 input_position;
layout(location = 1) in vec3 input_normal;
layout(location = 2) in vec2 input_diffuseUv;
layout(location = 3) in vec2 input_lightmapUv;
layout(location = 4) in vec4 input_colorBgra;

mat4 spvWorkaroundRowMajor(mat4 wrap) { return wrap; }

void main()
{
    vec3 _399 = input_normal;
    vec2 _362 = input_diffuseUv;
    vec2 _363 = input_lightmapUv;
    vec4 _364 = input_colorBgra.zyxw;
    vec4 _293 = vec4(input_position, 1.0) * spvWorkaroundRowMajor(push.modelViewProjection);
    vec4 _275 = _293;
    float _295 = _293.y;
    float _353;
    if (_125)
    {
        _353 = -_295;
    }
    else
    {
        _353 = _295;
    }
    vec4 _409 = _275;
    _409.y = _353;
    _409.z = (_409.w - _409.z) * 0.5;
    _275 = _409;
    gl_Position = _409;
    entryPointParam_vertexMain_diffuseUv = _362;
    entryPointParam_vertexMain_lightmapUv = _363;
    entryPointParam_vertexMain_color = _364;
    entryPointParam_vertexMain_worldNormal = ((push.normal0.xyz * _399.x) + (push.normal1.xyz * _399.y)) + (push.normal2.xyz * _399.z);
    entryPointParam_vertexMain_viewDepth = _409.w;
    entryPointParam_vertexMain_fromEye = (((push.normal0.xyz * input_position.x) + (push.normal1.xyz * input_position.y)) + (push.normal2.xyz * input_position.z)) + vec3(push.normal0.w, push.normal1.w, push.normal2.w);
}

