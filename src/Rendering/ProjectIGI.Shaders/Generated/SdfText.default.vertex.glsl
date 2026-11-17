#version 430

#ifndef SPIRV_CROSS_CONSTANT_ID_65
#define SPIRV_CROSS_CONSTANT_ID_65 0
#endif
const int cTargetEncodes = SPIRV_CROSS_CONSTANT_ID_65;
const bool _330 = (cTargetEncodes != 0);

layout(binding = 0, std140) uniform SdfTextPush_std140
{
    vec2 projectionSize;
    vec4 range;
    vec4 outline;
    vec4 glow;
    vec4 glowWidth;
} push;

layout(location = 0) out vec2 entryPointParam_vertexMain_texCoord;
layout(location = 1) out vec4 entryPointParam_vertexMain_color;
layout(location = 0) in vec2 input_position;
layout(location = 1) in vec2 input_texCoord;
layout(location = 2) in vec4 input_colorBgra;

void main()
{
    vec2 _480 = input_texCoord;
    vec4 _481 = input_colorBgra;
    vec2 _368 = ((input_position / vec2(push.projectionSize.x, abs(push.projectionSize.y))) * 2.0) - vec2(1.0);
    float _369;
    if (push.projectionSize.y < 0.0)
    {
        _369 = -_368.y;
    }
    else
    {
        _369 = _368.y;
    }
    vec2 _492 = _368;
    _492.y = _369;
    _368 = _492;
    gl_Position = vec4(_492, 0.0, 1.0);
    entryPointParam_vertexMain_texCoord = _480;
    entryPointParam_vertexMain_color = _481.zyxw;
}

