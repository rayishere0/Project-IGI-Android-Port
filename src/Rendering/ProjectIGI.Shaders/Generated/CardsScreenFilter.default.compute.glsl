#version 430
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

uniform ivec2 _207_comp[4] = ivec2[](ivec2(1, 0), ivec2(-1, 0), ivec2(0, 1), ivec2(0, -1));

layout(binding = 0, std140) uniform Globals_std140
{
    int uWidth;
    int uHeight;
    int uRadius;
    int uAccum;
    int uPosition;
    int uSceneNormal;
} g;

layout(binding = 0, rgba16f) uniform restrict writeonly image2D uFiltered;
layout(binding = 1) uniform sampler2D _482;
layout(binding = 0) uniform sampler2D _485;
layout(binding = 2) uniform sampler2D _487;

void main()
{
    {
        ivec2 _105 = ivec2(gl_GlobalInvocationID.xy);
        bool _29;
        if (_105.x >= g.uWidth)
        {
            _29 = true;
        }
        else
        {
            _29 = _105.y >= g.uHeight;
        }
        if (!(_29))
        {
            ivec2 _128 = ivec3(_105, 0).xy;
            vec4 _sampled = texelFetch(_482, _128, 0);
            vec4 _sampled_1 = texelFetch(_485, _128, 0);
            if (_sampled.w <= 0.0)
            {
                imageStore(uFiltered, ivec2(gl_GlobalInvocationID.xy), _sampled_1);
            }
            else
            {
                vec3 _144 = _sampled.xyz;
                vec4 _434 = texture(_487, (vec2(_105) + vec2(0.5)) / vec2(float(g.uWidth), float(g.uHeight)));
                vec3 _420 = (_434.xyz * 2.0) - vec3(1.0);
                float _421 = length(_420);
                vec3 _401;
                if (_421 > 0.001000000047497451305389404296875)
                {
                    _401 = _420 / vec3(_421);
                }
                else
                {
                    _401 = vec3(0.0);
                }
                int i = 0;
                float spacing = 0.0;
                float spacingCount = 0.0;
                for (;;)
                {
                    if (!(i < 4))
                    {
                        break;
                    }
                    vec4 _sampled_2 = texelFetch(_482, ivec3(clamp(_105 + _207_comp[i], ivec2(0), ivec2(g.uWidth - 1, g.uHeight - 1)), 0).xy, 0);
                    if (_sampled_2.w > 0.0)
                    {
                        spacing += length(_sampled_2.xyz - _144);
                        spacingCount += 1.0;
                    }
                    i++;
                    continue;
                }
                if (spacingCount > 0.0)
                {
                    spacing /= spacingCount;
                }
                else
                {
                    spacing = 1.0;
                }
                float _265 = ((2.0 * spacing) * spacing) + 9.9999999747524270787835121154785e-07;
                int y = -g.uRadius;
                vec3 sum = vec3(0.0);
                float weight = 0.0;
                vec3 filtered;
                float facing;
                vec3 _436;
                for (;;)
                {
                    if (!(y <= g.uRadius))
                    {
                        break;
                    }
                    int x = -g.uRadius;
                    filtered = sum;
                    float weight_1 = weight;
                    for (;;)
                    {
                        bool _78_ladder_break = false;
                        {
                            if (!(x <= g.uRadius))
                            {
                                _78_ladder_break = true;
                            }
                            else
                            {
                                ivec2 _300 = clamp(_105 + ivec2(x, y), ivec2(0), ivec2(g.uWidth - 1, g.uHeight - 1));
                                ivec2 _303 = ivec3(_300, 0).xy;
                                vec4 _sampled_3 = texelFetch(_482, _303, 0);
                                if (!(_sampled_3.w <= 0.0))
                                {
                                    vec4 _sampled_4 = texelFetch(_485, _303, 0);
                                    vec3 delta = _sampled_3.xyz - _144;
                                    vec4 _468 = texture(_487, (vec2(_300) + vec2(0.5)) / vec2(float(g.uWidth), float(g.uHeight)));
                                    vec3 _455 = (_468.xyz * 2.0) - vec3(1.0);
                                    float _456 = length(_455);
                                    if (_456 > 0.001000000047497451305389404296875)
                                    {
                                        _436 = _455 / vec3(_456);
                                    }
                                    else
                                    {
                                        _436 = vec3(0.0);
                                    }
                                    if (dot(_401, _401) < 0.5)
                                    {
                                        _29 = true;
                                    }
                                    else
                                    {
                                        _29 = dot(_436, _436) < 0.5;
                                    }
                                    if (_29)
                                    {
                                        facing = 1.0;
                                    }
                                    else
                                    {
                                        float _330 = dot(_401, _436);
                                        float _472 = isnan(0.0) ? _330 : (isnan(_330) ? 0.0 : max(_330, 0.0));
                                        float _473 = _472 * _472;
                                        facing = _473 * _473;
                                    }
                                    float w = (exp((-dot(delta, delta)) / _265) * (_sampled_4.w + 1.0)) * facing;
                                    filtered += (_sampled_4.xyz * w);
                                    weight_1 += w;
                                }
                            }
                        }
                        if (_78_ladder_break)
                        {
                            break;
                        }
                        x++;
                        continue;
                    }
                    y++;
                    sum = filtered;
                    weight = weight_1;
                    continue;
                }
                if (weight > 0.0)
                {
                    filtered = sum / vec3(weight);
                }
                else
                {
                    filtered = _sampled_1.xyz;
                }
                imageStore(uFiltered, ivec2(gl_GlobalInvocationID.xy), vec4(filtered, _sampled_1.w));
            }
        }
    }
}

