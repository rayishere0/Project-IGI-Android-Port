#version 430
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(binding = 0, std140) uniform Params_std140
{
    layout(row_major) mat4 viewToWorld;
    vec4 unproject;
    vec4 resolution;
    vec4 jitter;
} p;

layout(binding = 0, rgba16f) uniform restrict writeonly image2D uOutput;
layout(binding = 0) uniform sampler2D _892;
layout(binding = 1) uniform sampler2D _894;
layout(binding = 2) uniform sampler2D _897;

mat4 spvWorkaroundRowMajor(mat4 wrap) { return wrap; }

void main()
{
    {
        ivec2 _134 = ivec2(gl_GlobalInvocationID.xy);
        ivec2 _140 = ivec2(p.resolution.xy);
        int _141 = _134.x;
        bool inPenumbra;
        if (_141 >= _140.x)
        {
            inPenumbra = true;
        }
        else
        {
            inPenumbra = _134.y >= _140.y;
        }
        if (!(inPenumbra))
        {
            vec4 _687 = texelFetch(_892, ivec3(_134, 0).xy, 0);
            float _169 = _687.y;
            if (_169 <= 0.0)
            {
                imageStore(uOutput, ivec2(gl_GlobalInvocationID.xy), vec4(1.0, 0.0, 0.0, 0.0));
            }
            else
            {
                float _179 = _687.z;
                if (_179 <= 0.0)
                {
                    imageStore(uOutput, ivec2(gl_GlobalInvocationID.xy), vec4(_687.x, _169, 0.0, 0.0));
                }
                else
                {
                    vec2 _701 = ((vec2(_134) + vec2(0.5)) - p.jitter.xy) * p.resolution.zw;
                    vec4 _706 = textureLod(_894, _701, 0.0);
                    float _707 = _706.x;
                    if (_707 <= 0.0)
                    {
                        imageStore(uOutput, ivec2(gl_GlobalInvocationID.xy), vec4(_687.x, _169, 0.0, 0.0));
                    }
                    else
                    {
                        float _737 = ((2.0 * p.unproject.z) * p.unproject.w) / ((p.unproject.w + p.unproject.z) - ((1.0 - (2.0 * _707)) * (p.unproject.w - p.unproject.z)));
                        vec2 _714 = (_701 * 2.0) - vec2(1.0);
                        vec3 _724 = vec3((_714.x * _737) / p.unproject.x, ((-_714.y) * _737) / p.unproject.y, _737);
                        vec3 _277 = (vec4(_724, 0.0) * spvWorkaroundRowMajor(p.viewToWorld)).xyz;
                        uvec2 _743 = uvec2(textureSize(_897, 0));
                        uint _744 = _743.x;
                        uint _745 = _743.y;
                        vec3 _771 = normalize((texelFetch(_897, ivec3(clamp(ivec2(floor(_701 * vec2(float(_744), float(_745)))), ivec2(0), ivec2(int(_744) - 1, int(_745) - 1)), 0).xy, 0).xyz * 2.0) - vec3(1.0));
                        float disocclusion = 1.0 - clamp((_179 - 1.0) * 0.5, 0.0, 1.0);
                        ivec2 _325 = _140 - ivec2(1);
                        float penumbraWidth = _169;
                        int dy = -2;
                        float weightSum = 0.0;
                        float visSum = 0.0;
                        float visSquares = 0.0;
                        float total;
                        float valueWeight;
                        int i;
                        for (;;)
                        {
                            if (!(dy <= 2))
                            {
                                break;
                            }
                            i = -2;
                            total = weightSum;
                            valueWeight = visSum;
                            float visSquares_1 = visSquares;
                            for (;;)
                            {
                                float _355;
                                bool _67_ladder_break = false;
                                {
                                    if (!(i <= 2))
                                    {
                                        _67_ladder_break = true;
                                    }
                                    else
                                    {
                                        vec4 _777 = texelFetch(_892, ivec3(clamp(_134 + ivec2(i, dy), ivec2(0), _325), 0).xy, 0);
                                        float _353 = _777.y;
                                        _355 = isnan(_353) ? penumbraWidth : (isnan(penumbraWidth) ? _353 : max(penumbraWidth, _353));
                                        if (!(_353 <= 0.0))
                                        {
                                            float _369 = exp2((-0.22222222387790679931640625) * float((i * i) + (dy * dy)));
                                            float _372 = _777.x;
                                            total += _369;
                                            valueWeight += (_372 * _369);
                                            visSquares_1 += ((_372 * _372) * _369);
                                        }
                                    }
                                }
                                if (_67_ladder_break)
                                {
                                    break;
                                }
                                penumbraWidth = _355;
                                i++;
                                continue;
                            }
                            dy++;
                            weightSum = total;
                            visSum = valueWeight;
                            visSquares = visSquares_1;
                            continue;
                        }
                        float mean = visSum / (isnan(9.9999999747524270787835121154785e-07) ? weightSum : (isnan(weightSum) ? 9.9999999747524270787835121154785e-07 : max(weightSum, 9.9999999747524270787835121154785e-07)));
                        float _414 = (visSquares / (isnan(9.9999999747524270787835121154785e-07) ? weightSum : (isnan(weightSum) ? 9.9999999747524270787835121154785e-07 : max(weightSum, 9.9999999747524270787835121154785e-07)))) - (mean * mean);
                        float sigma = sqrt(isnan(0.0) ? _414 : (isnan(_414) ? 0.0 : max(_414, 0.0))) * mix(1.0, 2.0, disocclusion);
                        float _428 = _724.z;
                        float _435 = clamp((0.5 * penumbraWidth) * (((p.unproject.x * 0.5) * p.resolution.x) / (isnan(0.001000000047497451305389404296875) ? _428 : (isnan(_428) ? 0.001000000047497451305389404296875 : max(_428, 0.001000000047497451305389404296875)))), 1.0, 24.0);
                        if (mean > 0.0199999995529651641845703125)
                        {
                            inPenumbra = mean < 0.980000019073486328125;
                        }
                        else
                        {
                            inPenumbra = false;
                        }
                        if (inPenumbra)
                        {
                            inPenumbra = _435 > 1.5;
                        }
                        else
                        {
                            inPenumbra = false;
                        }
                        vec2 _458 = _687.xy;
                        bool _45;
                        if (p.jitter.w > 0.5)
                        {
                            if (inPenumbra)
                            {
                                _45 = true;
                            }
                            else
                            {
                                _45 = (sigma / (isnan(0.100000001490116119384765625) ? mean : (isnan(mean) ? 0.100000001490116119384765625 : max(mean, 0.100000001490116119384765625)))) > mix(0.1500000059604644775390625, 0.100000001490116119384765625, disocclusion);
                            }
                        }
                        else
                        {
                            _45 = false;
                        }
                        vec2 sum;
                        if (_45)
                        {
                            if (inPenumbra)
                            {
                                dy = 16;
                            }
                            else
                            {
                                dy = int(round(mix(12.0, 24.0, disocclusion)));
                            }
                            if (inPenumbra)
                            {
                                penumbraWidth = _435;
                            }
                            else
                            {
                                penumbraWidth = 8.0;
                            }
                            if (!inPenumbra)
                            {
                                inPenumbra = _179 >= 6.0;
                            }
                            else
                            {
                                inPenumbra = false;
                            }
                            uint seed = (uint(_141 & 1) | (uint(_134.y & 1) << uint(1))) | (uint(p.jitter.z) << uint(2));
                            uint _783 = (seed ^ (seed >> uint(16))) * 2146121005u;
                            uint _786 = (_783 ^ (_783 >> uint(15))) * 2221713035u;
                            float _542 = (float((_786 ^ (_786 >> uint(16))) >> uint(8)) * 5.9604644775390625e-08) * 6.283185482025146484375;
                            i = 0;
                            sum = _458;
                            total = 1.0;
                            for (;;)
                            {
                                bool _106_ladder_break = false;
                                {
                                    if (!(i < 24))
                                    {
                                        _106_ladder_break = true;
                                    }
                                    else
                                    {
                                        if (i >= dy)
                                        {
                                            _106_ladder_break = true;
                                        }
                                        else
                                        {
                                            float _557 = float(i);
                                            float angle = _542 + (_557 * 2.3999631404876708984375);
                                            ivec2 _577 = ivec2(floor((vec2(_134) + (vec2(cos(angle), sin(angle)) * (penumbraWidth * sqrt((_557 + 0.5) / float(dy))))) + vec2(0.5)));
                                            if (any(lessThan(_577, ivec2(0))))
                                            {
                                                _45 = true;
                                            }
                                            else
                                            {
                                                _45 = any(greaterThanEqual(_577, _140));
                                            }
                                            if (!(_45))
                                            {
                                                vec4 _799 = texelFetch(_892, ivec3(_577, 0).xy, 0);
                                                if (!(_799.y <= 0.0))
                                                {
                                                    vec2 _813 = ((vec2(_577) + vec2(0.5)) - p.jitter.xy) * p.resolution.zw;
                                                    vec4 _818 = textureLod(_894, _813, 0.0);
                                                    float _819 = _818.x;
                                                    if (!(_819 <= 0.0))
                                                    {
                                                        float _848 = ((2.0 * p.unproject.z) * p.unproject.w) / ((p.unproject.w + p.unproject.z) - ((1.0 - (2.0 * _819)) * (p.unproject.w - p.unproject.z)));
                                                        vec2 _825 = (_813 * 2.0) - vec2(1.0);
                                                        float planeDistance = abs(dot((vec4(vec3((_825.x * _848) / p.unproject.x, ((-_825.y) * _848) / p.unproject.y, _848), 0.0) * spvWorkaroundRowMajor(p.viewToWorld)).xyz - _277, _771)) / (isnan(9.9999997473787516355514526367188e-05) ? _428 : (isnan(_428) ? 9.9999997473787516355514526367188e-05 : max(_428, 9.9999997473787516355514526367188e-05)));
                                                        uvec2 _854 = uvec2(textureSize(_897, 0));
                                                        uint _855 = _854.x;
                                                        uint _856 = _854.y;
                                                        if (inPenumbra)
                                                        {
                                                            valueWeight = exp2((-abs(_687.x - _799.x)) / (isnan(0.001000000047497451305389404296875) ? sigma : (isnan(sigma) ? 0.001000000047497451305389404296875 : max(sigma, 0.001000000047497451305389404296875))));
                                                        }
                                                        else
                                                        {
                                                            valueWeight = 1.0;
                                                        }
                                                        float weight = (exp2(((-10000.0) * planeDistance) * planeDistance) * (1.0 - clamp(acos(clamp(dot(_771, normalize((texelFetch(_897, ivec3(clamp(ivec2(floor(_813 * vec2(float(_855), float(_856)))), ivec2(0), ivec2(int(_855) - 1, int(_856) - 1)), 0).xy, 0).xyz * 2.0) - vec3(1.0))), -1.0, 1.0)), 0.0, 1.0))) * valueWeight;
                                                        sum += (_799.xy * weight);
                                                        total += weight;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                if (_106_ladder_break)
                                {
                                    break;
                                }
                                i++;
                                continue;
                            }
                            sum /= vec2(total);
                        }
                        else
                        {
                            sum = _458;
                        }
                        imageStore(uOutput, ivec2(gl_GlobalInvocationID.xy), vec4(clamp(sum.x, 0.0, 1.0), clamp(sum.y, 0.0, 1.0), _428, 0.0));
                    }
                }
            }
        }
    }
}

