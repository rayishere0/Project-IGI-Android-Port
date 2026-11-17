#version 430

#ifndef SPIRV_CROSS_CONSTANT_ID_64
#define SPIRV_CROSS_CONSTANT_ID_64 1
#endif
const int cClipYDown = SPIRV_CROSS_CONSTANT_ID_64;
const bool _87 = (cClipYDown != 0);

layout(binding = 0, std140) uniform ObjectVelocityPush_std140
{
    layout(row_major) mat4 current;
    vec4 previousX;
    vec4 previousY;
    vec4 previousW;
    vec4 pose;
} push;

layout(location = 0) out vec4 entryPointParam_vertexMain_currentClip;
layout(location = 1) out vec4 entryPointParam_vertexMain_previousClip;
layout(location = 0) in vec3 position;
layout(location = 1) in vec3 previousPosition;

mat4 spvWorkaroundRowMajor(mat4 wrap) { return wrap; }

void main()
{
    vec3 poseDelta = previousPosition - position;
    vec4 was = vec4(position + (poseDelta * push.pose.y), 1.0);
    vec4 _54 = vec4(position + (poseDelta * push.pose.x), 1.0) * spvWorkaroundRowMajor(push.current);
    vec4 clip = _54;
    vec4 _201 = _54;
    vec4 _202 = vec4(dot(push.previousX, was), dot(push.previousY, was), 0.0, dot(push.previousW, was));
    float _76 = _54.y;
    float _163;
    if (_87)
    {
        _163 = -_76;
    }
    else
    {
        _163 = _76;
    }
    vec4 _208 = clip;
    _208.y = _163;
    _208.z = (_208.w - _208.z) * 0.5;
    clip = _208;
    gl_Position = _208;
    entryPointParam_vertexMain_currentClip = _201;
    entryPointParam_vertexMain_previousClip = _202;
}

