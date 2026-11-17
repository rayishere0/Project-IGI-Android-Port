#version 430

#ifndef SPIRV_CROSS_CONSTANT_ID_1
#define SPIRV_CROSS_CONSTANT_ID_1 0.0
#endif
const float cSunX = SPIRV_CROSS_CONSTANT_ID_1;
#ifndef SPIRV_CROSS_CONSTANT_ID_2
#define SPIRV_CROSS_CONSTANT_ID_2 0.0
#endif
const float cSunY = SPIRV_CROSS_CONSTANT_ID_2;
#ifndef SPIRV_CROSS_CONSTANT_ID_3
#define SPIRV_CROSS_CONSTANT_ID_3 0.0
#endif
const float cSunZ = SPIRV_CROSS_CONSTANT_ID_3;
#ifndef SPIRV_CROSS_CONSTANT_ID_9
#define SPIRV_CROSS_CONSTANT_ID_9 0.0
#endif
const float cSunRed = SPIRV_CROSS_CONSTANT_ID_9;
#ifndef SPIRV_CROSS_CONSTANT_ID_10
#define SPIRV_CROSS_CONSTANT_ID_10 0.0
#endif
const float cSunGreen = SPIRV_CROSS_CONSTANT_ID_10;
#ifndef SPIRV_CROSS_CONSTANT_ID_11
#define SPIRV_CROSS_CONSTANT_ID_11 0.0
#endif
const float cSunBlue = SPIRV_CROSS_CONSTANT_ID_11;
#ifndef SPIRV_CROSS_CONSTANT_ID_6
#define SPIRV_CROSS_CONSTANT_ID_6 0.0
#endif
const float cAmbientRed = SPIRV_CROSS_CONSTANT_ID_6;
#ifndef SPIRV_CROSS_CONSTANT_ID_7
#define SPIRV_CROSS_CONSTANT_ID_7 0.0
#endif
const float cAmbientGreen = SPIRV_CROSS_CONSTANT_ID_7;
#ifndef SPIRV_CROSS_CONSTANT_ID_8
#define SPIRV_CROSS_CONSTANT_ID_8 0.0
#endif
const float cAmbientBlue = SPIRV_CROSS_CONSTANT_ID_8;
#ifndef SPIRV_CROSS_CONSTANT_ID_64
#define SPIRV_CROSS_CONSTANT_ID_64 1
#endif
const int cClipYDown = SPIRV_CROSS_CONSTANT_ID_64;
#ifndef SPIRV_CROSS_CONSTANT_ID_66
#define SPIRV_CROSS_CONSTANT_ID_66 0
#endif
const int cSamplerDecodes = SPIRV_CROSS_CONSTANT_ID_66;
#ifndef SPIRV_CROSS_CONSTANT_ID_12
#define SPIRV_CROSS_CONSTANT_ID_12 0
#endif
const int cLinearScene = SPIRV_CROSS_CONSTANT_ID_12;
const bool _203 = (cClipYDown != 0);
const bool _259 = (cSamplerDecodes != 0);
const bool _300 = (cLinearScene != 0);

layout(binding = 0, std140) uniform WaterPush_std140
{
    layout(row_major) mat4 modelViewProjection;
    vec4 eyeFacing;
    vec4 diffuseScale;
    vec4 specularFog;
    vec4 fogNormalScale;
} push;

layout(binding = 0) uniform samplerCube _408;

layout(location = 0) out vec4 entryPointParam_fragmentMain;
layout(location = 0) in vec4 input_colour0;
layout(location = 1) in vec3 input_colour1;
layout(location = 2) in vec3 input_reflection;
layout(location = 3) in float input_fog;

void main()
{
    vec4 _sampled = texture(_408, input_reflection);
    vec3 _250 = _sampled.xyz;
    vec3 _352;
    if (_259)
    {
        bvec3 _410 = isnan(_250);
        bvec3 _411 = isnan(vec3(0.0));
        vec3 _412 = max(_250, vec3(0.0));
        vec3 _413 = vec3(_410.x ? vec3(0.0).x : _412.x, _410.y ? vec3(0.0).y : _412.y, _410.z ? vec3(0.0).z : _412.z);
        _352 = mix((pow(vec3(_411.x ? _250.x : _413.x, _411.y ? _250.y : _413.y, _411.z ? _250.z : _413.z), vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), _250 * 12.9200000762939453125, step(_250, vec3(0.003130800090730190277099609375)));
    }
    else
    {
        _352 = _250;
    }
    vec3 _299 = mix(push.fogNormalScale.xyz, clamp((input_colour0.xyz * _352) + input_colour1, vec3(0.0), vec3(1.0)), vec3(input_fog));
    vec3 shown;
    if (_300)
    {
        bvec3 _415 = isnan(_299);
        bvec3 _416 = isnan(vec3(0.0));
        vec3 _417 = max(_299, vec3(0.0));
        vec3 _418 = vec3(_415.x ? vec3(0.0).x : _417.x, _415.y ? vec3(0.0).y : _417.y, _415.z ? vec3(0.0).z : _417.z);
        vec3 _302 = vec3(_416.x ? _299.x : _418.x, _416.y ? _299.y : _418.y, _416.z ? _299.z : _418.z);
        vec3 _380 = (_302 + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375);
        bvec3 _420 = isnan(_380);
        bvec3 _421 = isnan(vec3(0.0));
        vec3 _422 = max(_380, vec3(0.0));
        vec3 _423 = vec3(_420.x ? vec3(0.0).x : _422.x, _420.y ? vec3(0.0).y : _422.y, _420.z ? vec3(0.0).z : _422.z);
        shown = mix(pow(vec3(_421.x ? _380.x : _423.x, _421.y ? _380.y : _423.y, _421.z ? _380.z : _423.z), vec3(2.400000095367431640625)), _302 * vec3(0.077399380505084991455078125), step(_302, vec3(0.040449999272823333740234375))) * push.diffuseScale.w;
    }
    else
    {
        shown = _299;
    }
    entryPointParam_fragmentMain = vec4(shown, input_colour0.w);
}

