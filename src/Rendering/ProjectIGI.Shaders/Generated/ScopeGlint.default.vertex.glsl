#version 430
#ifdef GL_ARB_shader_draw_parameters
#extension GL_ARB_shader_draw_parameters : enable
#endif

#ifndef SPIRV_CROSS_CONSTANT_ID_64
#define SPIRV_CROSS_CONSTANT_ID_64 1
#endif
const int cClipYDown = SPIRV_CROSS_CONSTANT_ID_64;

struct _Array_std140_vector_float_4_7
{
    vec4 data[7];
};

const bool _72 = (cClipYDown != 0);

layout(location = 0) out vec2 entryPointParam_vertexMain_uv;
#ifdef GL_ARB_shader_draw_parameters
#define SPIRV_Cross_BaseVertex gl_BaseVertexARB
#else
uniform int SPIRV_Cross_BaseVertex;
#endif

void main()
{
    uint _32 = uint(gl_VertexID - SPIRV_Cross_BaseVertex);
    float _300 = float((_32 << uint(1)) & 2u);
    float _302 = float(_32 & 2u);
    vec2 _403 = vec2(_300, _302);
    float _306 = _302 * 2.0;
    float _312;
    if (_72)
    {
        _312 = _306 - 1.0;
    }
    else
    {
        _312 = 1.0 - _306;
    }
    gl_Position = vec4((_300 * 2.0) - 1.0, _312, 0.0, 1.0);
    entryPointParam_vertexMain_uv = _403;
}

