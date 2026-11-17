#version 430

#ifndef SPIRV_CROSS_CONSTANT_ID_66
#define SPIRV_CROSS_CONSTANT_ID_66 0
#endif
const int cSamplerDecodes = SPIRV_CROSS_CONSTANT_ID_66;
#ifndef SPIRV_CROSS_CONSTANT_ID_65
#define SPIRV_CROSS_CONSTANT_ID_65 0
#endif
const int cTargetEncodes = SPIRV_CROSS_CONSTANT_ID_65;
const bool _138 = (cSamplerDecodes != 0);
const bool _180 = (cTargetEncodes != 0);

layout(binding = 0, std140) uniform SpritePush_std140
{
    vec2 projectionSize;
} push;

layout(location = 0) out vec2 entryPointParam_vertexMain_texCoord;
layout(location = 1) out vec4 entryPointParam_vertexMain_color;
layout(location = 0) in vec2 input_position;
layout(location = 1) in vec2 input_texCoord;
layout(location = 2) in vec4 input_colorBgra;

void main()
{
    vec2 _309 = input_texCoord;
    vec4 _310 = input_colorBgra;
    vec2 _214 = ((input_position / vec2(push.projectionSize.x, abs(push.projectionSize.y))) * 2.0) - vec2(1.0);
    float _215;
    if (push.projectionSize.y < 0.0)
    {
        _215 = -_214.y;
    }
    else
    {
        _215 = _214.y;
    }
    vec2 _322 = _214;
    _322.y = _215;
    _214 = _322;
    gl_Position = vec4(_322, 0.0, 1.0);
    entryPointParam_vertexMain_texCoord = _309;
    entryPointParam_vertexMain_color = _310.zyxw;
}

