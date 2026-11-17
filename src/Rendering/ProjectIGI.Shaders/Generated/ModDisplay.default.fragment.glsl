#version 430

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

layout(binding = 0) uniform sampler2D _225;

#ifdef GL_ARB_shader_draw_parameters
#define SPIRV_Cross_BaseVertex gl_BaseVertexARB
#else
uniform int SPIRV_Cross_BaseVertex;
#endif
layout(location = 0) out vec4 entryPointParam_fragmentMain;

void main()
{
    vec4 _103 = vec4(texelFetch(_225, ivec3(ivec2(gl_FragCoord.xy), 0).xy, 0).xyz, 1.0);
    vec4 _177;
    if (_113)
    {
        vec3 _181 = _103.xyz;
        vec3 _196 = (_181 + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375);
        bvec3 _227 = isnan(_196);
        bvec3 _228 = isnan(vec3(0.0));
        vec3 _229 = max(_196, vec3(0.0));
        vec3 _230 = vec3(_227.x ? vec3(0.0).x : _229.x, _227.y ? vec3(0.0).y : _229.y, _227.z ? vec3(0.0).z : _229.z);
        _177 = vec4(mix(pow(vec3(_228.x ? _196.x : _230.x, _228.y ? _196.y : _230.y, _228.z ? _196.z : _230.z), vec3(2.400000095367431640625)), _181 * vec3(0.077399380505084991455078125), step(_181, vec3(0.040449999272823333740234375))), 1.0);
    }
    else
    {
        _177 = _103;
    }
    entryPointParam_fragmentMain = _177;
}

