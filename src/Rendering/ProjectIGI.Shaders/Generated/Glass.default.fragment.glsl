#version 430

#ifndef SPIRV_CROSS_CONSTANT_ID_64
#define SPIRV_CROSS_CONSTANT_ID_64 1
#endif
const int cClipYDown = SPIRV_CROSS_CONSTANT_ID_64;
const bool _125 = (cClipYDown != 0);

layout(binding = 0) uniform sampler2D _440;

layout(location = 0) out vec4 entryPointParam_fragmentMain;
layout(location = 0) in vec2 input_diffuseUv;
layout(location = 2) in vec4 input_color;
layout(location = 3) in vec3 input_worldNormal;
layout(location = 5) in vec3 input_fromEye;

void main()
{
    vec4 _sampled = texture(_440, input_diffuseUv);
    float alpha = _sampled.w * input_color.w;
    if (alpha >= 0.5)
    {
        discard;
    }
    if (alpha < 0.0199999995529651641845703125)
    {
        discard;
    }
    float _246 = abs(dot(normalize(input_worldNormal), normalize(input_fromEye)));
    float _251 = sqrt(clamp(1.0 - (_246 * _246), 0.0, 1.0));
    float _257 = sqrt(clamp(1.0 - (0.444444477558135986328125 * (_251 * _251)), 0.0, 1.0));
    float _378 = 0.959999978542327880859375 * pow(1.0 - clamp(_246, 0.0, 1.0), 5.0);
    entryPointParam_fragmentMain = vec4(0.0, 0.0, 0.0, 1.0 - ((1.0 - ((2.0 * (0.039999999105930328369140625 + _378)) / (_378 + 1.03999996185302734375))) * exp((-0.0199999995529651641845703125) / (isnan(0.0500000007450580596923828125) ? _257 : (isnan(_257) ? 0.0500000007450580596923828125 : max(_257, 0.0500000007450580596923828125))))));
}

