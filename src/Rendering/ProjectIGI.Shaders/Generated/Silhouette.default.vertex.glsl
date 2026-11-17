#version 430
#ifdef GL_ARB_shader_draw_parameters
#extension GL_ARB_shader_draw_parameters : enable
#endif

#ifndef SPIRV_CROSS_CONSTANT_ID_64
#define SPIRV_CROSS_CONSTANT_ID_64 1
#endif
const int cClipYDown = SPIRV_CROSS_CONSTANT_ID_64;
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
    float _518 = float((_32 << uint(1)) & 2u);
    float _520 = float(_32 & 2u);
    vec2 _792 = vec2(_518, _520);
    float _524 = _520 * 2.0;
    float _530;
    if (_72)
    {
        _530 = _524 - 1.0;
    }
    else
    {
        _530 = 1.0 - _524;
    }
    gl_Position = vec4((_518 * 2.0) - 1.0, _530, 0.0, 1.0);
    entryPointParam_vertexMain_uv = _792;
}

