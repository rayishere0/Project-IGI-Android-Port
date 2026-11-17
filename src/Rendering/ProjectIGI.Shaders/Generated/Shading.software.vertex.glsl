#version 430
#ifdef GL_ARB_shader_draw_parameters
#extension GL_ARB_shader_draw_parameters : enable
#endif

#ifndef SPIRV_CROSS_CONSTANT_ID_64
#define SPIRV_CROSS_CONSTANT_ID_64 1
#endif
const int cClipYDown = SPIRV_CROSS_CONSTANT_ID_64;

struct _Array_std140_matrix_float_4_4_4
{
    mat4 data[4];
};

struct FlashlightParams_std140
{
    vec4 position;
    vec4 axis;
    vec4 up;
    vec4 colour;
    vec4 cone;
    vec4 control;
};

struct _Array_std140_vector_float_4_160
{
    vec4 data[160];
};

const bool _127 = (cClipYDown != 0);
uvec3 _13274;
float _13275;

layout(location = 0) out vec2 entryPointParam_vertexMain_uv;
#ifdef GL_ARB_shader_draw_parameters
#define SPIRV_Cross_BaseVertex gl_BaseVertexARB
#else
uniform int SPIRV_Cross_BaseVertex;
#endif

void main()
{
    uint _87 = uint(gl_VertexID - SPIRV_Cross_BaseVertex);
    float _5312 = float((_87 << uint(1)) & 2u);
    float _5314 = float(_87 & 2u);
    vec2 _12314 = vec2(_5312, _5314);
    float _5318 = _5314 * 2.0;
    float _5324;
    if (_127)
    {
        _5324 = _5318 - 1.0;
    }
    else
    {
        _5324 = 1.0 - _5318;
    }
    gl_Position = vec4((_5312 * 2.0) - 1.0, _5324, 0.0, 1.0);
    entryPointParam_vertexMain_uv = _12314;
}

