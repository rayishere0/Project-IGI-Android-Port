#version 430
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(binding = 0, std140) uniform Params_std140
{
    layout(row_major) mat4 viewToWorld;
    layout(row_major) mat4 prevWorldToView;
    vec4 unproject;
    vec4 prevUnproject;
    vec4 resolution;
    vec4 cameraDelta;
    vec4 jitter;
    vec4 control;
} p;

layout(binding = 0, rgba16f) uniform restrict writeonly image2D uOutput;
layout(binding = 1) uniform sampler2D _978;
layout(binding = 0) uniform sampler2D _981;
layout(binding = 3) uniform sampler2D _984;
layout(binding = 2) uniform sampler2D _987;

mat4 spvWorkaroundRowMajor(mat4 wrap) { return wrap; }

void main()
{
    {
        ivec2 _118 = ivec2(gl_GlobalInvocationID.xy);
        bool ownMotion;
        if (_118.x >= int(p.resolution.x))
        {
            ownMotion = true;
        }
        else
        {
            ownMotion = _118.y >= int(p.resolution.y);
        }
        if (!(ownMotion))
        {
            vec2 _753 = ((vec2(_118) + vec2(0.5)) - p.jitter.xy) * p.resolution.zw;
            vec4 _758 = textureLod(_978, _753, 0.0);
            float _759 = _758.x;
            if (_759 <= 0.0)
            {
                imageStore(uOutput, ivec2(gl_GlobalInvocationID.xy), vec4(1.0, 0.0, 0.0, 0.0));
            }
            else
            {
                float _788 = ((2.0 * p.unproject.z) * p.unproject.w) / ((p.unproject.w + p.unproject.z) - ((1.0 - (2.0 * _759)) * (p.unproject.w - p.unproject.z)));
                vec2 _765 = (_753 * 2.0) - vec2(1.0);
                vec3 _775 = vec3((_765.x * _788) / p.unproject.x, ((-_765.y) * _788) / p.unproject.y, _788);
                vec4 _802 = texelFetch(_981, ivec3(clamp(_118, ivec2(0), ivec2(p.resolution.xy) - ivec2(1)), 0).xy, 0);
                vec2 current = _802.xy;
                if (_802.y <= 0.0)
                {
                    imageStore(uOutput, ivec2(gl_GlobalInvocationID.xy), vec4(1.0, 0.0, 1.0, _775.z));
                }
                else
                {
                    int _804 = -2;
                    vec2 _805 = vec2(0.0);
                    vec2 _806 = vec2(0.0);
                    float _807 = 0.0;
                    bool _812;
                    for (;;)
                    {
                        if (!(_804 <= 2))
                        {
                            break;
                        }
                        int _808 = -2;
                        vec2 _809 = _805;
                        vec2 _810 = _806;
                        float _811 = _807;
                        for (;;)
                        {
                            bool _827_ladder_break = false;
                            {
                                if (!(_808 <= 2))
                                {
                                    _827_ladder_break = true;
                                }
                                else
                                {
                                    if (abs(_808) == 2)
                                    {
                                        _812 = abs(_804) == 2;
                                    }
                                    else
                                    {
                                        _812 = false;
                                    }
                                    if (!(_812))
                                    {
                                        vec4 _921 = texelFetch(_981, ivec3(clamp(_118 + ivec2(_808, _804), ivec2(0), ivec2(p.resolution.xy) - ivec2(1)), 0).xy, 0);
                                        vec2 _850 = _921.xy;
                                        if (!(_921.y <= 0.0))
                                        {
                                            _809 += _850;
                                            _810 += (_850 * _850);
                                            _811 += 1.0;
                                        }
                                    }
                                }
                            }
                            if (_827_ladder_break)
                            {
                                break;
                            }
                            _808++;
                            continue;
                        }
                        _804++;
                        _805 = _809;
                        _806 = _810;
                        _807 = _811;
                        continue;
                    }
                    float _878 = isnan(1.0) ? _807 : (isnan(_807) ? 1.0 : max(_807, 1.0));
                    vec2 _881 = _805 / vec2(_878);
                    vec2 _886 = (_806 / vec2(_878)) - (_881 * _881);
                    bvec2 _994 = isnan(_886);
                    bvec2 _995 = isnan(vec2(0.0));
                    vec2 _996 = max(_886, vec2(0.0));
                    vec2 _997 = vec2(_994.x ? vec2(0.0).x : _996.x, _994.y ? vec2(0.0).y : _996.y);
                    vec2 _889 = sqrt(vec2(_995.x ? _886.x : _997.x, _995.y ? _886.y : _997.y)) * 1.25;
                    vec2 _890 = _881 - _889;
                    vec2 _891 = _881 + _889;
                    bvec2 _999 = isnan(_890);
                    bvec2 _1000 = isnan(current);
                    vec2 _1001 = min(_890, current);
                    vec2 _1002 = vec2(_999.x ? current.x : _1001.x, _999.y ? current.y : _1001.y);
                    vec2 _893 = vec2(_1000.x ? _890.x : _1002.x, _1000.y ? _890.y : _1002.y);
                    bvec2 _1004 = isnan(_891);
                    bvec2 _1005 = isnan(current);
                    vec2 _1006 = max(_891, current);
                    vec2 _1007 = vec2(_1004.x ? current.x : _1006.x, _1004.y ? current.y : _1006.y);
                    vec2 _895 = vec2(_1005.x ? _891.x : _1007.x, _1005.y ? _891.y : _1007.y);
                    float _897 = 1.5 / _878;
                    float _900 = _893.x;
                    float _901 = _881.x;
                    float _902 = _901 - _897;
                    _893.x = isnan(_902) ? _900 : (isnan(_900) ? _902 : min(_900, _902));
                    vec2 low = _893;
                    float _906 = _895.x;
                    float _907 = _901 + _897;
                    _895.x = isnan(_907) ? _906 : (isnan(_906) ? _907 : max(_906, _907));
                    vec2 high = _895;
                    vec2 extent = (_895 - _893) * 0.5;
                    if (p.cameraDelta.w > 0.5)
                    {
                        ownMotion = p.control.x > 0.5;
                    }
                    else
                    {
                        ownMotion = false;
                    }
                    vec2 result;
                    float cap;
                    if (ownMotion)
                    {
                        vec4 _450 = vec4((vec4(_775, 0.0) * spvWorkaroundRowMajor(p.viewToWorld)).xyz + p.cameraDelta.xyz, 0.0) * spvWorkaroundRowMajor(p.prevWorldToView);
                        float _452 = _450.z;
                        if (_452 > p.prevUnproject.z)
                        {
                            vec2 prevUv_1 = (vec2((_450.x * p.prevUnproject.x) / _452, -((_450.y * p.prevUnproject.y) / _452)) * 0.5) + vec2(0.5);
                            vec2 prevUv;
                            if (p.control.y > 0.5)
                            {
                                uvec2 _928 = uvec2(textureSize(_984, 0));
                                uint _929 = _928.x;
                                uint _930 = _928.y;
                                vec2 _952 = texelFetch(_984, ivec3(clamp(ivec2(floor(_753 * vec2(float(_929), float(_930)))), ivec2(0), ivec2(int(_929) - 1, int(_930) - 1)), 0).xy, 0).xy;
                                bool _522 = length((_952 - (_753 - prevUv_1)) * p.resolution.xy) > 1.5;
                                if (_522)
                                {
                                    prevUv = _753 - _952;
                                }
                                else
                                {
                                    prevUv = prevUv_1;
                                }
                                ownMotion = _522;
                            }
                            else
                            {
                                prevUv = prevUv_1;
                                ownMotion = false;
                            }
                            vec2 historyUv = prevUv + (p.jitter.zw * p.resolution.zw);
                            bool _43;
                            if (all(greaterThanEqual(historyUv, vec2(0.0))))
                            {
                                _43 = all(lessThanEqual(historyUv, vec2(1.0)));
                            }
                            else
                            {
                                _43 = false;
                            }
                            if (_43)
                            {
                                vec2 position = (historyUv * p.resolution.xy) - vec2(0.5);
                                vec2 _562 = floor(position);
                                vec2 _563 = position - _562;
                                ivec2 _564 = ivec2(_562);
                                float _566 = 0.02999999932944774627685546875 * (isnan(1.0) ? _452 : (isnan(_452) ? 1.0 : max(_452, 1.0)));
                                int i = 0;
                                vec3 weighted = vec3(0.0);
                                float weightSum = 0.0;
                                bool _51;
                                float weight;
                                for (;;)
                                {
                                    if (!(i < 4))
                                    {
                                        break;
                                    }
                                    int _575 = i;
                                    ivec2 corner = ivec2(_575 & 1, _575 >> 1);
                                    vec2 _583 = mix(vec2(1.0) - _563, _563, vec2(corner));
                                    vec4 _965 = texelFetch(_987, ivec3(clamp(_564 + corner, ivec2(0), ivec2(p.resolution.xy) - ivec2(1)), 0).xy, 0);
                                    if (!ownMotion)
                                    {
                                        _43 = abs(_965.w - _452) > _566;
                                    }
                                    else
                                    {
                                        _43 = false;
                                    }
                                    if (_43)
                                    {
                                        cap = 0.0;
                                    }
                                    else
                                    {
                                        cap = _583.x * _583.y;
                                    }
                                    if (_965.y <= 9.9999997473787516355514526367188e-05)
                                    {
                                        _51 = true;
                                    }
                                    else
                                    {
                                        _51 = _965.z < 0.5;
                                    }
                                    if (_51)
                                    {
                                        weight = 0.0;
                                    }
                                    else
                                    {
                                        weight = cap;
                                    }
                                    i++;
                                    weighted += (_965.xyz * weight);
                                    weightSum += weight;
                                    continue;
                                }
                                if (weightSum > 0.001000000047497451305389404296875)
                                {
                                    vec3 history = weighted / vec3(weightSum);
                                    float historyVis = history.x;
                                    float historyFrames = history.z;
                                    if (historyFrames > 0.0)
                                    {
                                        float _674 = clamp(historyVis, low.x, high.x);
                                        float _677 = extent.x;
                                        float _682 = clamp(1.0 - (abs(_674 - historyVis) / (isnan(0.00999999977648258209228515625) ? _677 : (isnan(_677) ? 0.00999999977648258209228515625 : max(_677, 0.00999999977648258209228515625)))), 0.0, 1.0);
                                        if (p.control.z > 0.5)
                                        {
                                            cap = 4.0;
                                        }
                                        else
                                        {
                                            cap = mix(4.0, 32.0, _682);
                                        }
                                        float _696 = historyFrames + 1.0;
                                        float _698 = isnan(cap) ? _696 : (isnan(_696) ? cap : min(_696, cap));
                                        result = mix(vec2(mix(_674, historyVis, _682), history.y), current, vec2(1.0 / _698));
                                        cap = _698;
                                    }
                                    else
                                    {
                                        result = current;
                                        cap = 1.0;
                                    }
                                }
                                else
                                {
                                    result = current;
                                    cap = 1.0;
                                }
                            }
                            else
                            {
                                result = current;
                                cap = 1.0;
                            }
                        }
                        else
                        {
                            result = current;
                            cap = 1.0;
                        }
                    }
                    else
                    {
                        result = current;
                        cap = 1.0;
                    }
                    imageStore(uOutput, ivec2(gl_GlobalInvocationID.xy), vec4(clamp(result.x, 0.0, 1.0), clamp(result.y, 0.0, 1.0), cap, _775.z));
                }
            }
        }
    }
}

