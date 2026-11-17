#version 430
#ifdef GL_ARB_shader_draw_parameters
#extension GL_ARB_shader_draw_parameters : enable
#endif

#ifndef SPIRV_CROSS_CONSTANT_ID_64
#define SPIRV_CROSS_CONSTANT_ID_64 1
#endif
const int cClipYDown = SPIRV_CROSS_CONSTANT_ID_64;
const bool _73 = (cClipYDown != 0);

layout(location = 0) out vec2 entryPointParam_vertexMain_uv;
#ifdef GL_ARB_shader_draw_parameters
#define SPIRV_Cross_BaseVertex gl_BaseVertexARB
#else
uniform int SPIRV_Cross_BaseVertex;
#endif

void main()
{
    uint _33 = uint(gl_VertexID - SPIRV_Cross_BaseVertex);
    float _328 = float((_33 << uint(1)) & 2u);
    float _330 = float(_33 & 2u);
    vec2 _349 = vec2(_328, _330);
    float _334 = _330 * 2.0;
    float _340;
    if (_73)
    {
        _340 = _334 - 1.0;
    }
    else
    {
        _340 = 1.0 - _334;
    }
    gl_Position = vec4((_328 * 2.0) - 1.0, _340, 0.0, 1.0);
    entryPointParam_vertexMain_uv = _349;
}

