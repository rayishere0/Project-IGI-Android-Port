#version 430
#ifdef GL_ARB_shader_draw_parameters
#extension GL_ARB_shader_draw_parameters : enable
#endif

#ifndef SPIRV_CROSS_CONSTANT_ID_64
#define SPIRV_CROSS_CONSTANT_ID_64 1
#endif
const int cClipYDown = SPIRV_CROSS_CONSTANT_ID_64;
#ifndef SPIRV_CROSS_CONSTANT_ID_66
#define SPIRV_CROSS_CONSTANT_ID_66 0
#endif
const int cSamplerDecodes = SPIRV_CROSS_CONSTANT_ID_66;
#ifndef SPIRV_CROSS_CONSTANT_ID_65
#define SPIRV_CROSS_CONSTANT_ID_65 0
#endif
const int cTargetEncodes = SPIRV_CROSS_CONSTANT_ID_65;
const bool _77 = (cClipYDown != 0);
const bool _260 = (cSamplerDecodes != 0);
const bool _556 = (cTargetEncodes != 0);

layout(location = 0) out vec2 entryPointParam_vertexMain_uv;
#ifdef GL_ARB_shader_draw_parameters
#define SPIRV_Cross_BaseVertex gl_BaseVertexARB
#else
uniform int SPIRV_Cross_BaseVertex;
#endif

void main()
{
    uint _37 = uint(gl_VertexID - SPIRV_Cross_BaseVertex);
    float _595 = float((_37 << uint(1)) & 2u);
    float _597 = float(_37 & 2u);
    vec2 _746 = vec2(_595, _597);
    float _601 = _597 * 2.0;
    float _607;
    if (_77)
    {
        _607 = _601 - 1.0;
    }
    else
    {
        _607 = 1.0 - _601;
    }
    gl_Position = vec4((_595 * 2.0) - 1.0, _607, 0.0, 1.0);
    entryPointParam_vertexMain_uv = _746;
}

