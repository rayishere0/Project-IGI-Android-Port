#version 430

#ifndef SPIRV_CROSS_CONSTANT_ID_64
#define SPIRV_CROSS_CONSTANT_ID_64 1
#endif
const int cClipYDown = SPIRV_CROSS_CONSTANT_ID_64;
const bool _69 = (cClipYDown != 0);

layout(binding = 0, std140) uniform OutlinePush_std140
{
    layout(row_major) mat4 modelViewProjection;
    vec4 colour;
    vec4 control;
    vec4 viewport;
} push;

layout(location = 0) in vec3 input_position;
layout(location = 1) in vec3 input_normal;
layout(location = 5) in vec3 input_previousPosition;
layout(location = 6) in vec3 input_previousNormal;

mat4 spvWorkaroundRowMajor(mat4 wrap) { return wrap; }

void main()
{
    vec4 _53 = vec4(input_position + ((input_previousPosition - input_position) * push.control.y), 1.0) * spvWorkaroundRowMajor(push.modelViewProjection);
    vec4 clip = _53;
    float _58 = _53.y;
    float _151;
    if (_69)
    {
        _151 = -_58;
    }
    else
    {
        _151 = _58;
    }
    vec4 _159 = clip;
    _159.y = _151;
    _159.z = (_159.w - _159.z) * 0.5;
    clip = _159;
    vec4 _91 = vec4(input_normal + ((input_previousNormal - input_normal) * push.control.y), 0.0) * spvWorkaroundRowMajor(push.modelViewProjection);
    vec2 direction_1 = vec2(_91.x, -_91.y);
    float _97 = dot(direction_1, direction_1);
    vec2 direction;
    if (_97 > 9.9999999600419720025001879548654e-13)
    {
        direction = direction_1 * inversesqrt(_97);
    }
    else
    {
        direction = vec2(0.0);
    }
    vec4 _109 = clip;
    vec2 _125 = _109.xy + ((((direction * push.control.x) * 2.0) / push.viewport.xy) * _109.w);
    vec4 _164 = _109;
    _164.x = _125.x;
    _164.y = _125.y;
    _164.z = mix(_164.z, push.control.w * _164.w, push.control.z);
    clip = _164;
    gl_Position = _164;
}

