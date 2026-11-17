#version 430

#ifndef SPIRV_CROSS_CONSTANT_ID_65
#define SPIRV_CROSS_CONSTANT_ID_65 0
#endif
const int cTargetEncodes = SPIRV_CROSS_CONSTANT_ID_65;
const bool _330 = (cTargetEncodes != 0);

layout(binding = 0, std140) uniform SdfTextPush_std140
{
    vec2 projectionSize;
    vec4 range;
    vec4 outline;
    vec4 glow;
    vec4 glowWidth;
} push;

layout(binding = 1) uniform sampler2D _501;
layout(binding = 0) uniform sampler2D _504;

layout(location = 0) out vec4 entryPointParam_fragmentMain;
layout(location = 0) in vec2 input_texCoord;
layout(location = 1) in vec4 input_color;

void main()
{
    vec4 _sampled = texture(_501, input_texCoord);
    float d = _sampled.w;
    uvec2 _409 = uvec2(textureSize(_504, 0));
    vec2 _431 = fwidth(input_texCoord);
    float _427 = 0.5 * dot(vec2(push.range.x, push.range.x) / vec2(float(_409.x), float(_409.y)), vec2(1.0) / _431);
    float _428 = isnan(1.0) ? _427 : (isnan(_427) ? 1.0 : max(_427, 1.0));
    float _191 = clamp(push.range.y, 0.0, 1.0);
    float _437 = fract(sin(dot(floor(input_texCoord * 1024.0) + vec2(push.range.z * 17.0, push.range.z * 5.0), vec2(127.09999847412109375, 311.70001220703125))) * 43758.546875);
    bool _219 = _191 > 0.0;
    bool _119;
    if (_219)
    {
        _119 = _437 < _191;
    }
    else
    {
        _119 = false;
    }
    if (_119)
    {
        discard;
    }
    float ember;
    if (_219)
    {
        ember = 1.0 - smoothstep(_191, _191 + 0.1599999964237213134765625, _437);
    }
    else
    {
        ember = 0.0;
    }
    vec4 result = vec4(0.0);
    if (push.glow.w > 0.0)
    {
        _119 = push.glowWidth.x > 0.0;
    }
    else
    {
        _119 = false;
    }
    if (_119)
    {
        result = vec4(push.glow.xyz, smoothstep(0.5 - push.glowWidth.x, 0.5, d) * push.glow.w);
    }
    if (push.outline.w > 0.0)
    {
        result = mix(result, vec4(push.outline.xyz, 1.0), vec4(clamp(((d - (0.5 - push.outline.w)) * _428) + 0.5, 0.0, 1.0)));
    }
    vec4 _312 = mix(result, vec4(mix(input_color.xyz, vec3(1.0, 0.86000001430511474609375, 0.62000000476837158203125), vec3(ember * 0.89999997615814208984375)), 1.0), vec4(clamp((((d - 0.5) - (_191 * 0.2199999988079071044921875)) * _428) + 0.5, 0.0, 1.0)));
    _312.w = _312.w * input_color.w;
    result = _312;
    vec4 _438;
    if (_330)
    {
        vec3 _457 = (_312.xyz + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375);
        bvec3 _511 = isnan(_457);
        bvec3 _512 = isnan(vec3(0.0));
        vec3 _513 = max(_457, vec3(0.0));
        vec3 _514 = vec3(_511.x ? vec3(0.0).x : _513.x, _511.y ? vec3(0.0).y : _513.y, _511.z ? vec3(0.0).z : _513.z);
        _438 = vec4(mix(pow(vec3(_512.x ? _457.x : _514.x, _512.y ? _457.y : _514.y, _512.z ? _457.z : _514.z), vec3(2.400000095367431640625)), _312.xyz * vec3(0.077399380505084991455078125), step(_312.xyz, vec3(0.040449999272823333740234375))), _312.w);
    }
    else
    {
        _438 = _312;
    }
    entryPointParam_fragmentMain = _438;
}

