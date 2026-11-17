#version 430
#ifdef GL_ARB_shader_draw_parameters
#extension GL_ARB_shader_draw_parameters : enable
#endif

#ifndef SPIRV_CROSS_CONSTANT_ID_64
#define SPIRV_CROSS_CONSTANT_ID_64 1
#endif
const int cClipYDown = SPIRV_CROSS_CONSTANT_ID_64;
#ifndef SPIRV_CROSS_CONSTANT_ID_65
#define SPIRV_CROSS_CONSTANT_ID_65 0
#endif
const int cTargetEncodes = SPIRV_CROSS_CONSTANT_ID_65;
const bool _82 = (cClipYDown != 0);
const bool _1127 = (cTargetEncodes != 0);

layout(location = 0) out vec2 entryPointParam_vertexMain_uv;
#ifdef GL_ARB_shader_draw_parameters
#define SPIRV_Cross_BaseVertex gl_BaseVertexARB
#else
uniform int SPIRV_Cross_BaseVertex;
#endif

void main()
{
    uint _42 = uint(gl_VertexID - SPIRV_Cross_BaseVertex);
    float _1197 = float((_42 << uint(1)) & 2u);
    float _1199 = float(_42 & 2u);
    vec2 _2356 = vec2(_1197, _1199);
    float _1203 = _1199 * 2.0;
    float _1209;
    if (_82)
    {
        _1209 = _1203 - 1.0;
    }
    else
    {
        _1209 = 1.0 - _1203;
    }
    gl_Position = vec4((_1197 * 2.0) - 1.0, _1209, 0.0, 1.0);
    entryPointParam_vertexMain_uv = _2356;
}

