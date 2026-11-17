#version 430
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

uniform vec2 _226_comp[8] = vec2[](vec2(0.939999997615814208984375, 0.34200000762939453125), vec2(-0.964999973773956298828125, -0.2619999945163726806640625), vec2(0.13500000536441802978515625, -0.4289999902248382568359375), vec2(-0.1369999945163726806640625, 0.4289999902248382568359375), vec2(0.3490000069141387939453125, -0.936999976634979248046875), vec2(-0.273999989032745361328125, 0.96200001239776611328125), vec2(-0.407000005245208740234375, -0.1920000016689300537109375), vec2(0.435000002384185791015625, 0.115999996662139892578125));

layout(binding = 0, std140) uniform Params_std140
{
    vec4 size;
    vec4 unproject;
    vec4 sun;
} p;

layout(binding = 0, r8) uniform restrict writeonly image2D uShadow;
layout(binding = 0) uniform sampler2D _380;
layout(binding = 2) uniform sampler2D _383;
layout(binding = 5) uniform sampler2D _386;
layout(binding = 4) uniform sampler2D _389;
layout(binding = 1) uniform sampler2D _391;
layout(binding = 3) uniform sampler2D _393;
layout(binding = 6) uniform sampler2D _395;

void main()
{
    {
        ivec2 _76 = ivec2(gl_GlobalInvocationID.xy);
        ivec2 _82 = ivec2(p.size.xy);
        int _83 = _76.x;
        bool _31;
        if (_83 >= _82.x)
        {
            _31 = true;
        }
        else
        {
            _31 = _76.y >= _82.y;
        }
        if (!(_31))
        {
            ivec2 _100 = ivec3(_76, 0).xy;
            vec4 _sampled = texelFetch(_380, _100, 0);
            vec4 _sampled_1 = texelFetch(_383, _100, 0);
            float centreDepth = _sampled_1.x;
            vec3 _119 = normalize((texelFetch(_386, _100, 0).xyz * 2.0) - vec3(1.0));
            if (centreDepth <= 0.0)
            {
                _31 = true;
            }
            else
            {
                _31 = _sampled.y <= 0.0;
            }
            if (_31)
            {
                imageStore(uShadow, ivec2(gl_GlobalInvocationID.xy), vec4(_sampled.x));
            }
            else
            {
                float _358 = ((2.0 * p.unproject.z) * p.unproject.w) / ((p.unproject.w + p.unproject.z) - ((1.0 - (2.0 * centreDepth)) * (p.unproject.w - p.unproject.z)));
                float _165 = isnan(9.9999997473787516355514526367188e-05) ? _358 : (isnan(_358) ? 9.9999997473787516355514526367188e-05 : max(_358, 9.9999997473787516355514526367188e-05));
                float pixelRadius = (((p.sun.x * _sampled.y) * p.unproject.x) * (0.5 * p.size.x)) / _165;
                float _187 = 0.3499999940395355224609375 * pixelRadius;
                float _190 = mix(pixelRadius, isnan(_187) ? 2.0 : (isnan(2.0) ? _187 : max(2.0, _187)), smoothstep(0.25, 0.89999997615814208984375, clamp(texelFetch(_389, _100, 0).z * p.sun.y, 0.0, 1.0)));
                if (_190 < 0.5)
                {
                    imageStore(uShadow, ivec2(gl_GlobalInvocationID.xy), vec4(_sampled.x));
                }
                else
                {
                    float _199 = isnan(32.0) ? _190 : (isnan(_190) ? 32.0 : min(_190, 32.0));
                    vec2 _210 = (vec2(1.0) - (vec2(float(_83 & 1), float(_76.y & 1)) * 2.0)) * 0.319999992847442626953125;
                    vec2 _218 = (vec2(_76) + vec2(0.5)) * p.size.zw;
                    int i = 0;
                    float visibility = _sampled.x;
                    float weightSum = 1.0;
                    float weight;
                    for (;;)
                    {
                        if (!(i < 8))
                        {
                            break;
                        }
                        vec2 _269 = clamp(_218 + (((_226_comp[i] + _210) * _199) * p.size.zw), p.size.zw * 0.5, vec2(1.0) - (p.size.zw * 0.5));
                        vec4 _sampled_2 = textureLod(_393, _269, 0.0);
                        float tapDepth = _sampled_2.x;
                        if (tapDepth > 0.0)
                        {
                            _31 = abs((((2.0 * p.unproject.z) * p.unproject.w) / ((p.unproject.w + p.unproject.z) - ((1.0 - (2.0 * tapDepth)) * (p.unproject.w - p.unproject.z)))) - _165) < (_165 * 0.0199999995529651641845703125);
                        }
                        else
                        {
                            _31 = false;
                        }
                        if (_31)
                        {
                            weight = 1.0;
                        }
                        else
                        {
                            weight = 0.0;
                        }
                        float _314 = clamp(dot(normalize((textureLod(_395, _269, 0.0).xyz * 2.0) - vec3(1.0)), _119), 0.0, 1.0);
                        float weight_1 = weight * (((_314 * _314) * _314) * _314);
                        i++;
                        visibility += (textureLod(_391, _269, 0.0).x * weight_1);
                        weightSum += weight_1;
                        continue;
                    }
                    imageStore(uShadow, ivec2(gl_GlobalInvocationID.xy), vec4(visibility / weightSum));
                }
            }
        }
    }
}

