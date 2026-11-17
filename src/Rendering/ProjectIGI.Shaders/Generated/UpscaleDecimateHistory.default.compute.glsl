#version 430
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

uniform ivec2 _289_comp[4] = ivec2[](ivec2(1, 0), ivec2(-1, 0), ivec2(0, 1), ivec2(0, -1));

layout(binding = 0, std140) uniform Params_std140
{
    layout(row_major) mat4 viewToWorld;
    layout(row_major) mat4 prevWorldToView;
    vec4 unproject;
    vec4 resolution;
    vec4 cameraDelta;
    vec4 prevProjection;
    vec4 jitter;
} p;

layout(binding = 0, std430) restrict readonly buffer StructuredBuffer
{
    uint _member0[];
} uOccluder;

layout(binding = 0, r8) uniform restrict writeonly image2D uRejection;
layout(binding = 1) uniform sampler2D _1054;
layout(binding = 3) uniform sampler2D _1056;
layout(binding = 2) uniform sampler2D _1059;
layout(binding = 0) uniform sampler2D _1062;
layout(binding = 4) uniform sampler2D _1065;

mat4 spvWorkaroundRowMajor(mat4 wrap) { return wrap; }

void main()
{
    {
        ivec2 _137 = ivec2(gl_GlobalInvocationID.xy);
        ivec2 _144 = ivec2(p.resolution.xy);
        bool _33;
        if (_137.x >= _144.x)
        {
            _33 = true;
        }
        else
        {
            _33 = _137.y >= _144.y;
        }
        if (!(_33))
        {
            ivec2 _162 = _144 - ivec2(1);
            vec2 rasterUv = (vec2(_137) + vec2(0.5)) * p.resolution.zw;
            vec4 _sampled = textureLod(_1054, rasterUv, 0.0);
            float d = _sampled.x;
            vec2 currentUv = rasterUv - (p.jitter.xy * p.resolution.zw);
            vec2 prevRasterUv = (currentUv - textureLod(_1056, rasterUv, 0.0).xy) + (p.jitter.zw * p.resolution.zw);
            if (any(lessThan(prevRasterUv, vec2(0.0))))
            {
                _33 = true;
            }
            else
            {
                _33 = any(greaterThan(prevRasterUv, vec2(1.0)));
            }
            if (_33)
            {
                imageStore(uRejection, ivec2(gl_GlobalInvocationID.xy), vec4(0.0));
            }
            else
            {
                ivec2 _222 = ivec2(prevRasterUv * p.resolution.xy);
                float _699;
                if (d <= 0.0)
                {
                    _699 = p.unproject.w;
                }
                else
                {
                    _699 = ((2.0 * p.unproject.z) * p.unproject.w) / ((p.unproject.w + p.unproject.z) - ((1.0 - (2.0 * d)) * (p.unproject.w - p.unproject.z)));
                }
                vec2 _282 = texelFetch(_1059, ivec3(_137, 0).xy, 0).xy * p.resolution.xy;
                float eOcc = 0.0;
                int i = 0;
                float eSurf;
                float _730;
                for (;;)
                {
                    bool _64_ladder_break = false;
                    {
                        if (!(i < 4))
                        {
                            _64_ladder_break = true;
                        }
                        else
                        {
                            ivec2 _304 = ivec3(clamp(_137 + _289_comp[i], ivec2(0), _162), 0).xy;
                            if (length((texelFetch(_1059, _304, 0).xy * p.resolution.xy) - _282) > 0.5)
                            {
                                eSurf = eOcc;
                            }
                            else
                            {
                                vec4 _sampled_1 = texelFetch(_1062, _304, 0);
                                float _322 = _sampled_1.x;
                                if (_322 <= 0.0)
                                {
                                    _730 = p.unproject.w;
                                }
                                else
                                {
                                    _730 = ((2.0 * p.unproject.z) * p.unproject.w) / ((p.unproject.w + p.unproject.z) - ((1.0 - (2.0 * _322)) * (p.unproject.w - p.unproject.z)));
                                }
                                float _325 = abs(_730 - _699);
                                eSurf = isnan(_325) ? eOcc : (isnan(eOcc) ? _325 : max(eOcc, _325));
                            }
                        }
                    }
                    if (_64_ladder_break)
                    {
                        break;
                    }
                    eOcc = eSurf;
                    i++;
                    continue;
                }
                float agreement;
                int y;
                int x;
                if (d <= 0.0)
                {
                    eSurf = 0.0;
                    y = -1;
                    for (;;)
                    {
                        if (!(y <= 1))
                        {
                            break;
                        }
                        agreement = eSurf;
                        x = -1;
                        for (;;)
                        {
                            if (!(x <= 1))
                            {
                                break;
                            }
                            if (texelFetch(_1065, ivec3(clamp(_222 + ivec2(x, y), ivec2(0), _162), 0).xy, 0).x <= 0.0)
                            {
                                agreement = 1.0;
                            }
                            x++;
                            continue;
                        }
                        eSurf = agreement;
                        y++;
                        continue;
                    }
                    ivec2 _768 = _144 - ivec2(1);
                    vec2 _774 = (prevRasterUv * p.resolution.xy) - vec2(0.5);
                    vec2 _775 = floor(_774);
                    vec2 _776 = _774 - _775;
                    ivec2 _777 = ivec2(_775);
                    int _761 = 0;
                    float _762 = 0.0;
                    float _763;
                    float _764;
                    for (;;)
                    {
                        if (!(_761 < 4))
                        {
                            break;
                        }
                        int _787 = _761 & 1;
                        int _789 = _761 >> 1;
                        if (_787 == 0)
                        {
                            _763 = 1.0 - _776.x;
                        }
                        else
                        {
                            _763 = _776.x;
                        }
                        if (_789 == 0)
                        {
                            _764 = 1.0 - _776.y;
                        }
                        else
                        {
                            _764 = _776.y;
                        }
                        float _807 = _763 * _764;
                        ivec2 _809 = clamp(_777 + ivec2(_787, _789), ivec2(0), _768);
                        int _814 = (_809.y * _144.x) + _809.x;
                        if (uOccluder._member0[_814] == 0u)
                        {
                            _762 += _807;
                        }
                        else
                        {
                            float _820 = uintBitsToFloat(~uOccluder._member0[_814]);
                            float _852 = (0.5 * p.resolution.y) * p.unproject.y;
                            float _822 = 6.0 * (_820 / (isnan(9.9999999747524270787835121154785e-07) ? _852 : (isnan(_852) ? 9.9999999747524270787835121154785e-07 : max(_852, 9.9999999747524270787835121154785e-07))));
                            _762 += (_807 * clamp(2.0 - ((p.prevProjection.w - _820) / ((isnan(9.9999997473787516355514526367188e-05) ? _822 : (isnan(_822) ? 9.9999997473787516355514526367188e-05 : max(_822, 9.9999997473787516355514526367188e-05))) + eOcc)), 0.0, 1.0));
                        }
                        _761++;
                        continue;
                    }
                    imageStore(uRejection, ivec2(gl_GlobalInvocationID.xy), vec4(isnan(_762) ? eSurf : (isnan(eSurf) ? _762 : min(eSurf, _762)), 0.0, 0.0, 0.0));
                }
                else
                {
                    float _893 = ((2.0 * p.unproject.z) * p.unproject.w) / ((p.unproject.w + p.unproject.z) - ((1.0 - (2.0 * d)) * (p.unproject.w - p.unproject.z)));
                    vec2 _861 = (currentUv * 2.0) - vec2(1.0);
                    vec3 _874 = vec3((_861.x * _893) / p.unproject.x, ((-_861.y) * _893) / p.unproject.y, _893);
                    vec4 _908 = vec4((vec4(_874, 0.0) * spvWorkaroundRowMajor(p.viewToWorld)).xyz + p.cameraDelta.xyz, 0.0) * spvWorkaroundRowMajor(p.prevWorldToView);
                    float _909 = _908.z;
                    if (_909 <= p.prevProjection.z)
                    {
                        imageStore(uRejection, ivec2(gl_GlobalInvocationID.xy), vec4(0.0));
                    }
                    else
                    {
                        eSurf = 0.0;
                        int j = 0;
                        for (;;)
                        {
                            bool _102_ladder_break = false;
                            {
                                if (!(j < 4))
                                {
                                    _102_ladder_break = true;
                                }
                                else
                                {
                                    vec4 _sampled_2 = texelFetch(_1062, ivec3(clamp(_137 + _289_comp[j], ivec2(0), _162), 0).xy, 0);
                                    float nd = _sampled_2.x;
                                    if (nd <= 0.0)
                                    {
                                        agreement = eSurf;
                                    }
                                    else
                                    {
                                        float _609 = abs((((2.0 * p.unproject.z) * p.unproject.w) / ((p.unproject.w + p.unproject.z) - ((1.0 - (2.0 * nd)) * (p.unproject.w - p.unproject.z)))) - _874.z);
                                        agreement = isnan(_609) ? eSurf : (isnan(eSurf) ? _609 : max(eSurf, _609));
                                    }
                                }
                            }
                            if (_102_ladder_break)
                            {
                                break;
                            }
                            eSurf = agreement;
                            j++;
                            continue;
                        }
                        agreement = 0.0;
                        y = -1;
                        float agreement_2;
                        for (;;)
                        {
                            if (!(y <= 1))
                            {
                                break;
                            }
                            float agreement_1 = agreement;
                            x = -1;
                            for (;;)
                            {
                                bool _119_ladder_break = false;
                                {
                                    if (!(x <= 1))
                                    {
                                        _119_ladder_break = true;
                                    }
                                    else
                                    {
                                        vec4 _sampled_3 = texelFetch(_1065, ivec3(clamp(_222 + ivec2(x, y), ivec2(0), _162), 0).xy, 0);
                                        float prevD = _sampled_3.x;
                                        if (prevD <= 0.0)
                                        {
                                            agreement_2 = agreement_1;
                                        }
                                        else
                                        {
                                            float _939 = ((2.0 * p.prevProjection.z) * p.prevProjection.w) / ((p.prevProjection.w + p.prevProjection.z) - ((1.0 - (2.0 * prevD)) * (p.prevProjection.w - p.prevProjection.z)));
                                            float _949 = (0.5 * p.resolution.y) * p.unproject.y;
                                            float _656 = 6.0 * (_939 / (isnan(9.9999999747524270787835121154785e-07) ? _949 : (isnan(_949) ? 9.9999999747524270787835121154785e-07 : max(_949, 9.9999999747524270787835121154785e-07))));
                                            float _664 = clamp(2.0 - (abs(_939 - _909) / ((isnan(9.9999997473787516355514526367188e-05) ? _656 : (isnan(_656) ? 9.9999997473787516355514526367188e-05 : max(_656, 9.9999997473787516355514526367188e-05))) + eSurf)), 0.0, 1.0);
                                            agreement_2 = isnan(_664) ? agreement_1 : (isnan(agreement_1) ? _664 : max(agreement_1, _664));
                                        }
                                    }
                                }
                                if (_119_ladder_break)
                                {
                                    break;
                                }
                                agreement_1 = agreement_2;
                                x++;
                                continue;
                            }
                            agreement = agreement_1;
                            y++;
                            continue;
                        }
                        ivec2 _959 = _144 - ivec2(1);
                        vec2 _965 = (prevRasterUv * p.resolution.xy) - vec2(0.5);
                        vec2 _966 = floor(_965);
                        vec2 _967 = _965 - _966;
                        ivec2 _968 = ivec2(_966);
                        int _952 = 0;
                        float _953 = 0.0;
                        float _954;
                        float _955;
                        for (;;)
                        {
                            if (!(_952 < 4))
                            {
                                break;
                            }
                            int _978 = _952 & 1;
                            int _980 = _952 >> 1;
                            if (_978 == 0)
                            {
                                _954 = 1.0 - _967.x;
                            }
                            else
                            {
                                _954 = _967.x;
                            }
                            if (_980 == 0)
                            {
                                _955 = 1.0 - _967.y;
                            }
                            else
                            {
                                _955 = _967.y;
                            }
                            float _998 = _954 * _955;
                            ivec2 _1000 = clamp(_968 + ivec2(_978, _980), ivec2(0), _959);
                            int _1005 = (_1000.y * _144.x) + _1000.x;
                            if (uOccluder._member0[_1005] == 0u)
                            {
                                _953 += _998;
                            }
                            else
                            {
                                float _1011 = uintBitsToFloat(~uOccluder._member0[_1005]);
                                float _1043 = (0.5 * p.resolution.y) * p.unproject.y;
                                float _1013 = 6.0 * (_1011 / (isnan(9.9999999747524270787835121154785e-07) ? _1043 : (isnan(_1043) ? 9.9999999747524270787835121154785e-07 : max(_1043, 9.9999999747524270787835121154785e-07))));
                                _953 += (_998 * clamp(2.0 - ((_909 - _1011) / ((isnan(9.9999997473787516355514526367188e-05) ? _1013 : (isnan(_1013) ? 9.9999997473787516355514526367188e-05 : max(_1013, 9.9999997473787516355514526367188e-05))) + eOcc)), 0.0, 1.0));
                            }
                            _952++;
                            continue;
                        }
                        imageStore(uRejection, ivec2(gl_GlobalInvocationID.xy), vec4(isnan(_953) ? agreement : (isnan(agreement) ? _953 : min(agreement, _953)), 0.0, 0.0, 0.0));
                    }
                }
            }
        }
    }
}

