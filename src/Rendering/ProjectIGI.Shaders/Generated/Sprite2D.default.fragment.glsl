#version 430

#ifndef SPIRV_CROSS_CONSTANT_ID_66
#define SPIRV_CROSS_CONSTANT_ID_66 0
#endif
const int cSamplerDecodes = SPIRV_CROSS_CONSTANT_ID_66;
#ifndef SPIRV_CROSS_CONSTANT_ID_65
#define SPIRV_CROSS_CONSTANT_ID_65 0
#endif
const int cTargetEncodes = SPIRV_CROSS_CONSTANT_ID_65;
const bool _138 = (cSamplerDecodes != 0);
const bool _180 = (cTargetEncodes != 0);

layout(binding = 0) uniform sampler2D _325;

layout(location = 0) out vec4 entryPointParam_fragmentMain;
layout(location = 0) in vec2 input_texCoord;
layout(location = 1) in vec4 input_color;

void main()
{
    vec4 _sampled = texture(_325, input_texCoord);
    vec3 _127 = _sampled.xyz;
    vec3 _250;
    if (_138)
    {
        bvec3 _327 = isnan(_127);
        bvec3 _328 = isnan(vec3(0.0));
        vec3 _329 = max(_127, vec3(0.0));
        vec3 _330 = vec3(_327.x ? vec3(0.0).x : _329.x, _327.y ? vec3(0.0).y : _329.y, _327.z ? vec3(0.0).z : _329.z);
        _250 = mix((pow(vec3(_328.x ? _127.x : _330.x, _328.y ? _127.y : _330.y, _328.z ? _127.z : _330.z), vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), _127 * 12.9200000762939453125, step(_127, vec3(0.003130800090730190277099609375)));
    }
    else
    {
        _250 = _127;
    }
    vec4 _170 = vec4(_250, _sampled.w) * input_color;
    vec4 _268;
    if (_180)
    {
        vec3 _272 = _170.xyz;
        vec3 _286 = (_272 + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375);
        bvec3 _332 = isnan(_286);
        bvec3 _333 = isnan(vec3(0.0));
        vec3 _334 = max(_286, vec3(0.0));
        vec3 _335 = vec3(_332.x ? vec3(0.0).x : _334.x, _332.y ? vec3(0.0).y : _334.y, _332.z ? vec3(0.0).z : _334.z);
        _268 = vec4(mix(pow(vec3(_333.x ? _286.x : _335.x, _333.y ? _286.y : _335.y, _333.z ? _286.z : _335.z), vec3(2.400000095367431640625)), _272 * vec3(0.077399380505084991455078125), step(_272, vec3(0.040449999272823333740234375))), _170.w);
    }
    else
    {
        _268 = _170;
    }
    entryPointParam_fragmentMain = _268;
}

