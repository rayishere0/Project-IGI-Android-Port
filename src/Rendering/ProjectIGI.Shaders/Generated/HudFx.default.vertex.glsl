#version 430
#ifdef GL_ARB_shader_draw_parameters
#extension GL_ARB_shader_draw_parameters : enable
#endif

#ifndef SPIRV_CROSS_CONSTANT_ID_64
#define SPIRV_CROSS_CONSTANT_ID_64 1
#endif
const int cClipYDown = SPIRV_CROSS_CONSTANT_ID_64;
const bool _80 = (cClipYDown != 0);

layout(location = 0) out vec2 entryPointParam_vertexMain_uv;
#ifdef GL_ARB_shader_draw_parameters
#define SPIRV_Cross_BaseVertex gl_BaseVertexARB
#else
uniform int SPIRV_Cross_BaseVertex;
#endif

void main()
{
    uint _40 = uint(gl_VertexID - SPIRV_Cross_BaseVertex);
    float _814 = float((_40 << uint(1)) & 2u);
    float _816 = float(_40 & 2u);
    vec2 _1057 = vec2(_814, _816);
    float _820 = _816 * 2.0;
    float _826;
    if (_80)
    {
        _826 = _820 - 1.0;
    }
    else
    {
        _826 = 1.0 - _820;
    }
    gl_Position = vec4((_814 * 2.0) - 1.0, _826, 0.0, 1.0);
    entryPointParam_vertexMain_uv = _1057;
}

