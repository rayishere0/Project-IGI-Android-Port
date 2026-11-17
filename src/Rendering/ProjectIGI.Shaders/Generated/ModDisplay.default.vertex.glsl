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
const bool _70 = (cClipYDown != 0);
const bool _113 = (cTargetEncodes != 0);

layout(location = 0) out vec2 entryPointParam_vertexMain_uv;
#ifdef GL_ARB_shader_draw_parameters
#define SPIRV_Cross_BaseVertex gl_BaseVertexARB
#else
uniform int SPIRV_Cross_BaseVertex;
#endif

void main()
{
    uint _30 = uint(gl_VertexID - SPIRV_Cross_BaseVertex);
    float _157 = float((_30 << uint(1)) & 2u);
    float _159 = float(_30 & 2u);
    vec2 _202 = vec2(_157, _159);
    float _163 = _159 * 2.0;
    float _169;
    if (_70)
    {
        _169 = _163 - 1.0;
    }
    else
    {
        _169 = 1.0 - _163;
    }
    gl_Position = vec4((_157 * 2.0) - 1.0, _169, 0.0, 1.0);
    entryPointParam_vertexMain_uv = _202;
}

