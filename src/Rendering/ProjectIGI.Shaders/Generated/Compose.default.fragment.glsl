#version 430

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

layout(binding = 0) uniform sampler2D _234;
layout(binding = 1) uniform sampler2D _237;

#ifdef GL_ARB_shader_draw_parameters
#define SPIRV_Cross_BaseVertex gl_BaseVertexARB
#else
uniform int SPIRV_Cross_BaseVertex;
#endif
layout(location = 0) out vec4 entryPointParam_fragmentMain;

void main()
{
    ivec2 _98 = ivec3(ivec2(gl_FragCoord.xy), 0).xy;
    vec4 _sampled = texelFetch(_237, _98, 0);
    vec4 _112 = vec4(_sampled.xyz + (texelFetch(_234, _98, 0).xyz * (1.0 - _sampled.w)), 1.0);
    vec4 _186;
    if (_122)
    {
        vec3 _190 = _112.xyz;
        vec3 _205 = (_190 + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375);
        bvec3 _239 = isnan(_205);
        bvec3 _240 = isnan(vec3(0.0));
        vec3 _241 = max(_205, vec3(0.0));
        vec3 _242 = vec3(_239.x ? vec3(0.0).x : _241.x, _239.y ? vec3(0.0).y : _241.y, _239.z ? vec3(0.0).z : _241.z);
        _186 = vec4(mix(pow(vec3(_240.x ? _205.x : _242.x, _240.y ? _205.y : _242.y, _240.z ? _205.z : _242.z), vec3(2.400000095367431640625)), _190 * vec3(0.077399380505084991455078125), step(_190, vec3(0.040449999272823333740234375))), 1.0);
    }
    else
    {
        _186 = _112;
    }
    entryPointParam_fragmentMain = _186;
}

