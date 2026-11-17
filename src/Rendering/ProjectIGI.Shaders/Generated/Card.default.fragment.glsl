#version 430

#ifndef SPIRV_CROSS_CONSTANT_ID_64
#define SPIRV_CROSS_CONSTANT_ID_64 1
#endif
const int cClipYDown = SPIRV_CROSS_CONSTANT_ID_64;
#ifndef SPIRV_CROSS_CONSTANT_ID_66
#define SPIRV_CROSS_CONSTANT_ID_66 0
#endif
const int cSamplerDecodes = SPIRV_CROSS_CONSTANT_ID_66;
const bool _73 = (cClipYDown != 0);
const bool _147 = (cSamplerDecodes != 0);

layout(binding = 0, std140) uniform CardPush_std140
{
    layout(row_major) mat4 modelViewProjection;
    vec4 normal0;
    vec4 normal1;
    vec4 normal2;
    vec4 material;
} push;

layout(binding = 0) uniform sampler2D _293;

layout(location = 0) out vec4 entryPointParam_fragmentMain_albedo;
layout(location = 1) out vec4 entryPointParam_fragmentMain_normal;
layout(location = 2) out vec4 entryPointParam_fragmentMain_material;
layout(location = 3) out vec4 entryPointParam_fragmentMain_depth;
layout(location = 0) in vec2 input_diffuseUv;
layout(location = 1) in vec4 input_color;
layout(location = 2) in vec3 input_modelNormal;

void main()
{
    vec4 _sampled = texture(_293, input_diffuseUv);
    if (_sampled.w < 0.5)
    {
        discard;
    }
    vec3 _137 = _sampled.xyz;
    vec3 _230;
    if (_147)
    {
        _230 = _137;
    }
    else
    {
        vec3 _245 = (_137 + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375);
        bvec3 _295 = isnan(_245);
        bvec3 _296 = isnan(vec3(0.0));
        vec3 _297 = max(_245, vec3(0.0));
        vec3 _298 = vec3(_295.x ? vec3(0.0).x : _297.x, _295.y ? vec3(0.0).y : _297.y, _295.z ? vec3(0.0).z : _297.z);
        _230 = mix(pow(vec3(_296.x ? _245.x : _298.x, _296.y ? _245.y : _298.y, _296.z ? _245.z : _298.z), vec3(2.400000095367431640625)), _137 * vec3(0.077399380505084991455078125), step(_137, vec3(0.040449999272823333740234375)));
    }
    vec3 _257 = (input_color.xyz + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375);
    bvec3 _300 = isnan(_257);
    bvec3 _301 = isnan(vec3(0.0));
    vec3 _302 = max(_257, vec3(0.0));
    vec3 _303 = vec3(_300.x ? vec3(0.0).x : _302.x, _300.y ? vec3(0.0).y : _302.y, _300.z ? vec3(0.0).z : _302.z);
    entryPointParam_fragmentMain_albedo = vec4(_230 * mix(pow(vec3(_301.x ? _257.x : _303.x, _301.y ? _257.y : _303.y, _301.z ? _257.z : _303.z), vec3(2.400000095367431640625)), input_color.xyz * vec3(0.077399380505084991455078125), step(input_color.xyz, vec3(0.040449999272823333740234375))), 1.0);
    entryPointParam_fragmentMain_normal = vec4((normalize(input_modelNormal) * 0.5) + vec3(0.5), 1.0);
    entryPointParam_fragmentMain_material = vec4(push.material.x, push.material.y, push.material.z, 1.0);
    entryPointParam_fragmentMain_depth = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);
}

