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
const bool _71 = (cClipYDown != 0);
const bool _122 = (cTargetEncodes != 0);

layout(location = 0) out vec2 entryPointParam_vertexMain_uv;
#ifdef GL_ARB_shader_draw_parameters
#define SPIRV_Cross_BaseVertex gl_BaseVertexARB
#else
uniform int SPIRV_Cross_BaseVertex;
#endif

void main()
{
    uint _31 = uint(gl_VertexID - SPIRV_Cross_BaseVertex);
    float _166 = float((_31 << uint(1)) & 2u);
    float _168 = float(_31 & 2u);
    vec2 _211 = vec2(_166, _168);
    float _172 = _168 * 2.0;
    float _178;
    if (_71)
    {
        _178 = _172 - 1.0;
    }
    else
    {
        _178 = 1.0 - _172;
    }
    gl_Position = vec4((_166 * 2.0) - 1.0, _178, 0.0, 1.0);
    entryPointParam_vertexMain_uv = _211;
}

