#version 430
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

struct _Array_std140_vector_float_4_4
{
    vec4 data[4];
};

struct _Array_std140_float4
{
    float data[4];
};

layout(binding = 0, std140) uniform Params_std140
{
    layout(row_major) mat4 viewToWorld;
    vec4 unproject;
    vec4 resolution;
    vec4 trace;
    vec4 cacheOrigin;
    vec4 cacheGrid;
    vec4 cacheAtlas;
    vec4 debug;
    vec4 cameraWorld;
    uvec4 records;
    vec4 sun;
    vec4 sunColour;
    vec4 ambient;
    vec4 field;
    _Array_std140_vector_float_4_4 sdfOrigin;
    _Array_std140_float4 sdfRange;
    vec4 shelter0;
    vec4 shelter1;
    vec4 shelter2;
} p;

layout(binding = 1, std430) restrict readonly buffer StructuredBuffer
{
    ivec2 _member0[];
} uCells;

layout(binding = 2, std430) restrict readonly buffer uCellPages
{
    int _member0[];
} uCellPages_1;

layout(binding = 0, std430) restrict readonly buffer uPages
{
    vec4 _member0[];
} uPages_1;

layout(binding = 0, rgba16f) uniform restrict writeonly image2D uOut;
layout(binding = 0) uniform sampler2D _4678;
layout(binding = 1) uniform sampler2D _4681;
layout(binding = 2) uniform sampler2D _4683;
layout(binding = 8) uniform sampler2D _4686;
layout(binding = 7) uniform sampler3D _4688;
layout(binding = 3) uniform sampler2D _4691;
layout(binding = 4) uniform sampler2D _4693;
layout(binding = 5) uniform sampler2D _4695;
layout(binding = 6) uniform sampler2D _4697;

mat4 spvWorkaroundRowMajor(mat4 wrap) { return wrap; }

void main()
{
    bool _3742 = false;
    bool _3628 = false;
    bool _3514 = false;
    bool _3400 = false;
    bool _3286 = false;
    bool _3172 = false;
    bool _2792 = false;
    bool _2634 = false;
    bool _2476 = false;
    bool _2365 = false;
    {
        int gRoute = 0;
        ivec2 _98 = ivec2(gl_GlobalInvocationID.xy);
        bool _66;
        if (_98.x >= int(p.resolution.x))
        {
            _66 = true;
        }
        else
        {
            _66 = _98.y >= int(p.resolution.y);
        }
        if (!(_66))
        {
            vec4 _sampled = texelFetch(_4678, ivec3(_98, 0).xy, 0);
            float _127 = _sampled.w;
            if (_127 <= 0.0)
            {
                imageStore(uOut, ivec2(gl_GlobalInvocationID.xy), vec4(0.0));
            }
            else
            {
                vec3 _137 = normalize(_sampled.xyz);
                vec2 ndc = (((vec2(_98) + vec2(0.5)) * p.resolution.zw) * 2.0) - vec2(1.0);
                vec3 _177 = vec3((ndc.x * _127) / p.unproject.x, ((-ndc.y) * _127) / p.unproject.y, _127) * mat3(spvWorkaroundRowMajor(p.viewToWorld)[0].xyz, spvWorkaroundRowMajor(p.viewToWorld)[1].xyz, spvWorkaroundRowMajor(p.viewToWorld)[2].xyz);
                vec3 _178 = normalize(_177);
                vec3 normalW;
                if (dot(_137, _178) > 0.0)
                {
                    normalW = -_137;
                }
                else
                {
                    normalW = _137;
                }
                vec3 _189 = normalize(reflect(_178, normalW));
                float _197 = 0.959999978542327880859375 * pow(1.0 - clamp(dot(normalW, -_178), 0.0, 1.0), 5.0);
                vec3 _1937;
                {
                    gRoute = 0;
                    if (int(p.field.x) <= 0)
                    {
                        uint _2046 = uvec2(textureSize(_4681, 0)).y;
                        float _2063 = (p.trace.w * p.trace.w) - 40449600.0;
                        float _2068 = acos(clamp(sqrt(isnan(_2063) ? 0.0 : (isnan(0.0) ? _2063 : max(0.0, _2063))) / p.trace.w, -1.0, 1.0));
                        float _2069 = 3.1415927410125732421875 - _2068;
                        float _2072 = acos(clamp(_189.z, -1.0, 1.0));
                        float _2058;
                        if (_2072 < _2069)
                        {
                            float _2084 = 1.0 - (_2072 / _2069);
                            _2058 = (1.0 - sqrt(isnan(_2084) ? 0.0 : (isnan(0.0) ? _2084 : max(0.0, _2084)))) * 0.5;
                        }
                        else
                        {
                            float _2077 = (_2072 - _2069) / (isnan(9.9999999747524270787835121154785e-07) ? _2068 : (isnan(_2068) ? 9.9999999747524270787835121154785e-07 : max(_2068, 9.9999999747524270787835121154785e-07)));
                            _2058 = (sqrt(isnan(_2077) ? 0.0 : (isnan(0.0) ? _2077 : max(0.0, _2077))) * 0.5) + 0.5;
                        }
                        float _2092 = atan(_189.y, _189.x);
                        float _2059;
                        if (_2092 < 0.0)
                        {
                            _2059 = _2092 + 6.283185482025146484375;
                        }
                        else
                        {
                            _2059 = _2092;
                        }
                        vec2 _2101 = vec2(_2059 * 0.15915493667125701904296875, _2058);
                        float _2055 = float(_2046);
                        float _2106 = _2101.y;
                        float _2110 = _2055 - 1.0;
                        float _2112 = (floor(_2055 * 0.5) - 1.0) / (isnan(1.0) ? _2110 : (isnan(_2110) ? 1.0 : max(_2110, 1.0)));
                        _2101.y = isnan(_2112) ? _2106 : (isnan(_2106) ? _2112 : min(_2106, _2112));
                        uvec2 _2120 = uvec2(textureSize(_4681, 0));
                        vec2 _2127 = vec2(float(_2120.x), float(_2120.y));
                        _1937 = textureLod(_4683, (_2101 * ((_2127 - vec2(1.0)) / _2127)) + (vec2(0.5) / _2127), 0.0).xyz * smoothstep(-0.100000001490116119384765625, 0.25, _189.z);
                    }
                    else
                    {
                        vec2 _1960 = _177.xy + p.cameraWorld.xy;
                        float _1964 = _177.z + p.cameraWorld.z;
                        vec2 _4644 = p.shelter0.xy;
                        float _4645 = p.shelter0.z;
                        float _4646 = p.shelter0.w;
                        float _4647 = p.shelter1.x;
                        float _4648 = p.shelter1.y;
                        vec2 _4650 = p.shelter2.xy;
                        float _4651 = p.shelter1.w;
                        bool _2175;
                        {
                            ivec2 _2228 = ivec2(floor((_1960 - _4644) * _4645));
                            bool _2229;
                            if (_4651 > 0.5)
                            {
                                _2229 = _2228.x >= 0;
                            }
                            else
                            {
                                _2229 = false;
                            }
                            if (_2229)
                            {
                                _2229 = _2228.y >= 0;
                            }
                            else
                            {
                                _2229 = false;
                            }
                            if (_2229)
                            {
                                _2229 = _2228.x < int(_4650.x);
                            }
                            else
                            {
                                _2229 = false;
                            }
                            if (_2229)
                            {
                                _2229 = _2228.y < int(_4650.y);
                            }
                            else
                            {
                                _2229 = false;
                            }
                            if (!_2229)
                            {
                                _2175 = false;
                            }
                            else
                            {
                                vec4 _2187 = texelFetch(_4686, ivec3(_2228, 0).xy, 0);
                                float _2279 = floor((_2187.z * 255.0) + 0.5) + (floor((_2187.y * 255.0) + 0.5) * 256.0);
                                float _2267;
                                if (_2279 < 0.5)
                                {
                                    _2267 = -1000000015047466219876688855040.0;
                                }
                                else
                                {
                                    _2267 = _4646 + ((_2279 - 1.0) * _4647);
                                }
                                float _2192 = _1964 + _4648;
                                if (_2267 <= _2192)
                                {
                                    _2175 = false;
                                }
                                else
                                {
                                    float _2196 = _189.z;
                                    if (_2196 <= 0.0500000007450580596923828125)
                                    {
                                        _2175 = false;
                                    }
                                    else
                                    {
                                        ivec2 _2301 = ivec2(floor(((_1960 + (_189.xy * ((_2267 - _1964) / _2196))) - _4644) * _4645));
                                        bool _2302;
                                        if (_4651 > 0.5)
                                        {
                                            _2302 = _2301.x >= 0;
                                        }
                                        else
                                        {
                                            _2302 = false;
                                        }
                                        if (_2302)
                                        {
                                            _2302 = _2301.y >= 0;
                                        }
                                        else
                                        {
                                            _2302 = false;
                                        }
                                        if (_2302)
                                        {
                                            _2302 = _2301.x < int(_4650.x);
                                        }
                                        else
                                        {
                                            _2302 = false;
                                        }
                                        if (_2302)
                                        {
                                            _2302 = _2301.y < int(_4650.y);
                                        }
                                        else
                                        {
                                            _2302 = false;
                                        }
                                        if (!_2302)
                                        {
                                            _2175 = false;
                                        }
                                        else
                                        {
                                            vec4 _2213 = texelFetch(_4686, ivec3(_2301, 0).xy, 0);
                                            float _2352 = floor((_2213.z * 255.0) + 0.5) + (floor((_2213.y * 255.0) + 0.5) * 256.0);
                                            float _2340;
                                            if (_2352 < 0.5)
                                            {
                                                _2340 = -1000000015047466219876688855040.0;
                                            }
                                            else
                                            {
                                                _2340 = _4646 + ((_2352 - 1.0) * _4647);
                                            }
                                            _2175 = _2340 > _2192;
                                        }
                                    }
                                }
                            }
                        }
                        _2365 = false;
                        vec3 _1939;
                        float _1940;
                        bool _2366;
                        {
                            _1939 = _177;
                            _1940 = p.sdfOrigin.data[0].w;
                            if (int(p.field.x) <= 0)
                            {
                                _2365 = true;
                                _2366 = false;
                            }
                            else
                            {
                                vec3 _2397 = _177 + ((normalW * p.sdfOrigin.data[0].w) * 1.5);
                                bool _2367 = false;
                                float _2368 = 0.0;
                                float _2369 = 0.0;
                                int _2371 = 0;
                                float _2370 = 0.0;
                                bool _2372;
                                bool _2373;
                                float _2375;
                                float _2376;
                                bool _2377;
                                float _2477;
                                bool _2479;
                                bool _2592;
                                float _2594;
                                float _2635;
                                bool _2637;
                                bool _2750;
                                float _2752;
                                float _2793;
                                bool _2795;
                                for (;;)
                                {
                                    if (_2371 < 96)
                                    {
                                        _2372 = _2370 < p.trace.y;
                                    }
                                    else
                                    {
                                        _2372 = false;
                                    }
                                    if (!_2372)
                                    {
                                        break;
                                    }
                                    vec3 _2414 = _2397 + (_189 * _2370);
                                    _2476 = false;
                                    {
                                        _2373 = false;
                                        _2375 = p.sdfOrigin.data[0].w;
                                        int _2478 = 0;
                                        for (;;)
                                        {
                                            bool _2490_ladder_break = false;
                                            {
                                                if (!(_2478 < int(p.field.x)))
                                                {
                                                    _2490_ladder_break = true;
                                                }
                                                else
                                                {
                                                    vec3 _2507 = (_2414 - p.sdfOrigin.data[_2478].xyz) / vec3(p.sdfOrigin.data[_2478].w);
                                                    if (any(lessThan(_2507, vec3(0.5))))
                                                    {
                                                        _2479 = true;
                                                    }
                                                    else
                                                    {
                                                        _2479 = any(greaterThan(_2507, vec3(float(int(p.field.y)) - 0.5, float(int(p.field.y)) - 0.5, float(int(p.field.y)) - 0.5)));
                                                    }
                                                    if (!(_2479))
                                                    {
                                                        _2373 = true;
                                                        _2375 = p.sdfOrigin.data[_2478].w;
                                                        _2476 = true;
                                                        _2477 = ((textureLod(_4688, vec3(_2507.x / float(int(p.field.y)), _2507.y / float(int(p.field.y)), ((float(_2478) * float(int(p.field.y))) + _2507.z) / float(int(p.field.y) * int(p.field.x))), 0.0).x * 2.0) - 1.0) * p.sdfRange.data[_2478];
                                                        _2490_ladder_break = true;
                                                    }
                                                }
                                            }
                                            if (_2490_ladder_break)
                                            {
                                                break;
                                            }
                                            _2478++;
                                            continue;
                                        }
                                        if (!(_2476))
                                        {
                                            _2476 = true;
                                            _2477 = 1000000.0;
                                        }
                                    }
                                    if (!_2373)
                                    {
                                        _2365 = true;
                                        _2366 = false;
                                        break;
                                    }
                                    if (_2367)
                                    {
                                        if (_2477 <= 0.0)
                                        {
                                            float _2428 = _2369 - _2477;
                                            if (_2428 > 9.9999997473787516355514526367188e-06)
                                            {
                                                _2376 = _2368 + ((_2370 - _2368) * (_2369 / _2428));
                                            }
                                            else
                                            {
                                                _2376 = _2370;
                                            }
                                            _1940 = p.sdfOrigin.data[0].w;
                                            int _2590 = 0;
                                            float _2591 = clamp(_2376, _2368, _2370);
                                            for (;;)
                                            {
                                                if (!(_2590 < 2))
                                                {
                                                    break;
                                                }
                                                vec3 _2612 = _2397 + (_189 * _2591);
                                                _2634 = false;
                                                {
                                                    _2592 = false;
                                                    _2594 = p.sdfOrigin.data[0].w;
                                                    int _2636 = 0;
                                                    for (;;)
                                                    {
                                                        bool _2648_ladder_break = false;
                                                        {
                                                            if (!(_2636 < int(p.field.x)))
                                                            {
                                                                _2648_ladder_break = true;
                                                            }
                                                            else
                                                            {
                                                                vec3 _2665 = (_2612 - p.sdfOrigin.data[_2636].xyz) / vec3(p.sdfOrigin.data[_2636].w);
                                                                if (any(lessThan(_2665, vec3(0.5))))
                                                                {
                                                                    _2637 = true;
                                                                }
                                                                else
                                                                {
                                                                    _2637 = any(greaterThan(_2665, vec3(float(int(p.field.y)) - 0.5, float(int(p.field.y)) - 0.5, float(int(p.field.y)) - 0.5)));
                                                                }
                                                                if (!(_2637))
                                                                {
                                                                    _2592 = true;
                                                                    _2594 = p.sdfOrigin.data[_2636].w;
                                                                    _2634 = true;
                                                                    _2635 = ((textureLod(_4688, vec3(_2665.x / float(int(p.field.y)), _2665.y / float(int(p.field.y)), ((float(_2636) * float(int(p.field.y))) + _2665.z) / float(int(p.field.y) * int(p.field.x))), 0.0).x * 2.0) - 1.0) * p.sdfRange.data[_2636];
                                                                    _2648_ladder_break = true;
                                                                }
                                                            }
                                                        }
                                                        if (_2648_ladder_break)
                                                        {
                                                            break;
                                                        }
                                                        _2636++;
                                                        continue;
                                                    }
                                                    if (!(_2634))
                                                    {
                                                        _2634 = true;
                                                        _2635 = 1000000.0;
                                                    }
                                                }
                                                if (!_2592)
                                                {
                                                    break;
                                                }
                                                _1940 = _2594;
                                                _2590++;
                                                _2591 += (isnan(0.0) ? _2635 : (isnan(_2635) ? 0.0 : max(_2635, 0.0)));
                                                continue;
                                            }
                                            _1939 = _2397 + (_189 * (_2591 + (_1940 * 0.25)));
                                            _2365 = true;
                                            _2366 = true;
                                            break;
                                        }
                                        if (_2477 > _2369)
                                        {
                                            _2377 = _2369 < (_2375 * 0.0500000007450580596923828125);
                                        }
                                        else
                                        {
                                            _2377 = false;
                                        }
                                        if (_2377)
                                        {
                                            _1940 = p.sdfOrigin.data[0].w;
                                            int _2748 = 0;
                                            float _2749 = _2368;
                                            for (;;)
                                            {
                                                if (!(_2748 < 2))
                                                {
                                                    break;
                                                }
                                                vec3 _2770 = _2397 + (_189 * _2749);
                                                _2792 = false;
                                                {
                                                    _2750 = false;
                                                    _2752 = p.sdfOrigin.data[0].w;
                                                    int _2794 = 0;
                                                    for (;;)
                                                    {
                                                        bool _2806_ladder_break = false;
                                                        {
                                                            if (!(_2794 < int(p.field.x)))
                                                            {
                                                                _2806_ladder_break = true;
                                                            }
                                                            else
                                                            {
                                                                vec3 _2823 = (_2770 - p.sdfOrigin.data[_2794].xyz) / vec3(p.sdfOrigin.data[_2794].w);
                                                                if (any(lessThan(_2823, vec3(0.5))))
                                                                {
                                                                    _2795 = true;
                                                                }
                                                                else
                                                                {
                                                                    _2795 = any(greaterThan(_2823, vec3(float(int(p.field.y)) - 0.5, float(int(p.field.y)) - 0.5, float(int(p.field.y)) - 0.5)));
                                                                }
                                                                if (!(_2795))
                                                                {
                                                                    _2750 = true;
                                                                    _2752 = p.sdfOrigin.data[_2794].w;
                                                                    _2792 = true;
                                                                    _2793 = ((textureLod(_4688, vec3(_2823.x / float(int(p.field.y)), _2823.y / float(int(p.field.y)), ((float(_2794) * float(int(p.field.y))) + _2823.z) / float(int(p.field.y) * int(p.field.x))), 0.0).x * 2.0) - 1.0) * p.sdfRange.data[_2794];
                                                                    _2806_ladder_break = true;
                                                                }
                                                            }
                                                        }
                                                        if (_2806_ladder_break)
                                                        {
                                                            break;
                                                        }
                                                        _2794++;
                                                        continue;
                                                    }
                                                    if (!(_2792))
                                                    {
                                                        _2792 = true;
                                                        _2793 = 1000000.0;
                                                    }
                                                }
                                                if (!_2750)
                                                {
                                                    break;
                                                }
                                                _1940 = _2752;
                                                _2748++;
                                                _2749 += (isnan(0.0) ? _2793 : (isnan(_2793) ? 0.0 : max(_2793, 0.0)));
                                                continue;
                                            }
                                            _1939 = _2397 + (_189 * (_2749 + (_1940 * 0.25)));
                                            _2365 = true;
                                            _2366 = true;
                                            break;
                                        }
                                    }
                                    float _2461 = _2375 * 0.25;
                                    _2367 = true;
                                    _2368 = _2370;
                                    _2370 += (isnan(_2461) ? _2477 : (isnan(_2477) ? _2461 : max(_2477, _2461)));
                                    _2369 = _2477;
                                    _2371++;
                                    continue;
                                }
                                if (!(_2365))
                                {
                                    _2365 = true;
                                    _2366 = false;
                                }
                            }
                        }
                        if (!_2366)
                        {
                            if (!_2175)
                            {
                                uint _2917 = uvec2(textureSize(_4681, 0)).y;
                                float _2934 = (p.trace.w * p.trace.w) - 40449600.0;
                                float _2939 = acos(clamp(sqrt(isnan(_2934) ? 0.0 : (isnan(0.0) ? _2934 : max(0.0, _2934))) / p.trace.w, -1.0, 1.0));
                                float _2940 = 3.1415927410125732421875 - _2939;
                                float _2943 = acos(clamp(_189.z, -1.0, 1.0));
                                float _2929;
                                if (_2943 < _2940)
                                {
                                    float _2955 = 1.0 - (_2943 / _2940);
                                    _2929 = (1.0 - sqrt(isnan(_2955) ? 0.0 : (isnan(0.0) ? _2955 : max(0.0, _2955)))) * 0.5;
                                }
                                else
                                {
                                    float _2948 = (_2943 - _2940) / (isnan(9.9999999747524270787835121154785e-07) ? _2939 : (isnan(_2939) ? 9.9999999747524270787835121154785e-07 : max(_2939, 9.9999999747524270787835121154785e-07)));
                                    _2929 = (sqrt(isnan(_2948) ? 0.0 : (isnan(0.0) ? _2948 : max(0.0, _2948))) * 0.5) + 0.5;
                                }
                                float _2963 = atan(_189.y, _189.x);
                                float _2930;
                                if (_2963 < 0.0)
                                {
                                    _2930 = _2963 + 6.283185482025146484375;
                                }
                                else
                                {
                                    _2930 = _2963;
                                }
                                vec2 _2972 = vec2(_2930 * 0.15915493667125701904296875, _2929);
                                float _2926 = float(_2917);
                                float _2977 = _2972.y;
                                float _2981 = _2926 - 1.0;
                                float _2983 = (floor(_2926 * 0.5) - 1.0) / (isnan(1.0) ? _2981 : (isnan(_2981) ? 1.0 : max(_2981, 1.0)));
                                _2972.y = isnan(_2983) ? _2977 : (isnan(_2977) ? _2983 : min(_2977, _2983));
                                uvec2 _2991 = uvec2(textureSize(_4681, 0));
                                vec2 _2998 = vec2(float(_2991.x), float(_2991.y));
                                _1937 = textureLod(_4683, (_2972 * ((_2998 - vec2(1.0)) / _2998)) + (vec2(0.5) / _2998), 0.0).xyz * smoothstep(-0.100000001490116119384765625, 0.25, _189.z);
                            }
                            else
                            {
                                gRoute = 3;
                                uint _3035 = uvec2(textureSize(_4681, 0)).y;
                                float _3052 = (p.trace.w * p.trace.w) - 40449600.0;
                                float _3057 = acos(clamp(sqrt(isnan(_3052) ? 0.0 : (isnan(0.0) ? _3052 : max(0.0, _3052))) / p.trace.w, -1.0, 1.0));
                                float _3058 = 3.1415927410125732421875 - _3057;
                                float _3061 = acos(clamp(_189.z, -1.0, 1.0));
                                float _3047;
                                if (_3061 < _3058)
                                {
                                    float _3073 = 1.0 - (_3061 / _3058);
                                    _3047 = (1.0 - sqrt(isnan(_3073) ? 0.0 : (isnan(0.0) ? _3073 : max(0.0, _3073)))) * 0.5;
                                }
                                else
                                {
                                    float _3066 = (_3061 - _3058) / (isnan(9.9999999747524270787835121154785e-07) ? _3057 : (isnan(_3057) ? 9.9999999747524270787835121154785e-07 : max(_3057, 9.9999999747524270787835121154785e-07)));
                                    _3047 = (sqrt(isnan(_3066) ? 0.0 : (isnan(0.0) ? _3066 : max(0.0, _3066))) * 0.5) + 0.5;
                                }
                                float _3081 = atan(_189.y, _189.x);
                                float _3048;
                                if (_3081 < 0.0)
                                {
                                    _3048 = _3081 + 6.283185482025146484375;
                                }
                                else
                                {
                                    _3048 = _3081;
                                }
                                vec2 _3090 = vec2(_3048 * 0.15915493667125701904296875, _3047);
                                float _3044 = float(_3035);
                                float _3095 = _3090.y;
                                float _3099 = _3044 - 1.0;
                                float _3101 = (floor(_3044 * 0.5) - 1.0) / (isnan(1.0) ? _3099 : (isnan(_3099) ? 1.0 : max(_3099, 1.0)));
                                _3090.y = isnan(_3101) ? _3095 : (isnan(_3095) ? _3101 : min(_3095, _3101));
                                uvec2 _3109 = uvec2(textureSize(_4681, 0));
                                vec2 _3116 = vec2(float(_3109.x), float(_3109.y));
                                _1937 = vec3(dot(textureLod(_4683, (_3090 * ((_3116 - vec2(1.0)) / _3116)) + (vec2(0.5) / _3116), 0.0).xyz * smoothstep(-0.100000001490116119384765625, 0.25, _189.z), vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * 0.300000011920928955078125) + p.ambient.xyz;
                            }
                        }
                        else
                        {
                            float _3139 = isnan(0.001000000047497451305389404296875) ? _1940 : (isnan(_1940) ? 0.001000000047497451305389404296875 : max(_1940, 0.001000000047497451305389404296875));
                            vec3 _3140 = vec3(_3139, 0.0, 0.0);
                            vec3 _3141 = _1939 + _3140;
                            _3172 = false;
                            float _3173;
                            {
                                int _3174 = 0;
                                bool _3175;
                                for (;;)
                                {
                                    bool _3186_ladder_break = false;
                                    {
                                        if (!(_3174 < int(p.field.x)))
                                        {
                                            _3186_ladder_break = true;
                                        }
                                        else
                                        {
                                            vec3 _3203 = (_3141 - p.sdfOrigin.data[_3174].xyz) / vec3(p.sdfOrigin.data[_3174].w);
                                            if (any(lessThan(_3203, vec3(0.5))))
                                            {
                                                _3175 = true;
                                            }
                                            else
                                            {
                                                _3175 = any(greaterThan(_3203, vec3(float(int(p.field.y)) - 0.5, float(int(p.field.y)) - 0.5, float(int(p.field.y)) - 0.5)));
                                            }
                                            if (!(_3175))
                                            {
                                                _3172 = true;
                                                _3173 = ((textureLod(_4688, vec3(_3203.x / float(int(p.field.y)), _3203.y / float(int(p.field.y)), ((float(_3174) * float(int(p.field.y))) + _3203.z) / float(int(p.field.y) * int(p.field.x))), 0.0).x * 2.0) - 1.0) * p.sdfRange.data[_3174];
                                                _3186_ladder_break = true;
                                            }
                                        }
                                    }
                                    if (_3186_ladder_break)
                                    {
                                        break;
                                    }
                                    _3174++;
                                    continue;
                                }
                                if (!(_3172))
                                {
                                    _3172 = true;
                                    _3173 = 1000000.0;
                                }
                            }
                            vec3 _3143 = _1939 - _3140;
                            _3286 = false;
                            float _3287;
                            {
                                int _3288 = 0;
                                bool _3289;
                                for (;;)
                                {
                                    bool _3300_ladder_break = false;
                                    {
                                        if (!(_3288 < int(p.field.x)))
                                        {
                                            _3300_ladder_break = true;
                                        }
                                        else
                                        {
                                            vec3 _3317 = (_3143 - p.sdfOrigin.data[_3288].xyz) / vec3(p.sdfOrigin.data[_3288].w);
                                            if (any(lessThan(_3317, vec3(0.5))))
                                            {
                                                _3289 = true;
                                            }
                                            else
                                            {
                                                _3289 = any(greaterThan(_3317, vec3(float(int(p.field.y)) - 0.5, float(int(p.field.y)) - 0.5, float(int(p.field.y)) - 0.5)));
                                            }
                                            if (!(_3289))
                                            {
                                                _3286 = true;
                                                _3287 = ((textureLod(_4688, vec3(_3317.x / float(int(p.field.y)), _3317.y / float(int(p.field.y)), ((float(_3288) * float(int(p.field.y))) + _3317.z) / float(int(p.field.y) * int(p.field.x))), 0.0).x * 2.0) - 1.0) * p.sdfRange.data[_3288];
                                                _3300_ladder_break = true;
                                            }
                                        }
                                    }
                                    if (_3300_ladder_break)
                                    {
                                        break;
                                    }
                                    _3288++;
                                    continue;
                                }
                                if (!(_3286))
                                {
                                    _3286 = true;
                                    _3287 = 1000000.0;
                                }
                            }
                            vec3 _3146 = vec3(0.0, _3139, 0.0);
                            vec3 _3147 = _1939 + _3146;
                            _3400 = false;
                            float _3401;
                            {
                                int _3402 = 0;
                                bool _3403;
                                for (;;)
                                {
                                    bool _3414_ladder_break = false;
                                    {
                                        if (!(_3402 < int(p.field.x)))
                                        {
                                            _3414_ladder_break = true;
                                        }
                                        else
                                        {
                                            vec3 _3431 = (_3147 - p.sdfOrigin.data[_3402].xyz) / vec3(p.sdfOrigin.data[_3402].w);
                                            if (any(lessThan(_3431, vec3(0.5))))
                                            {
                                                _3403 = true;
                                            }
                                            else
                                            {
                                                _3403 = any(greaterThan(_3431, vec3(float(int(p.field.y)) - 0.5, float(int(p.field.y)) - 0.5, float(int(p.field.y)) - 0.5)));
                                            }
                                            if (!(_3403))
                                            {
                                                _3400 = true;
                                                _3401 = ((textureLod(_4688, vec3(_3431.x / float(int(p.field.y)), _3431.y / float(int(p.field.y)), ((float(_3402) * float(int(p.field.y))) + _3431.z) / float(int(p.field.y) * int(p.field.x))), 0.0).x * 2.0) - 1.0) * p.sdfRange.data[_3402];
                                                _3414_ladder_break = true;
                                            }
                                        }
                                    }
                                    if (_3414_ladder_break)
                                    {
                                        break;
                                    }
                                    _3402++;
                                    continue;
                                }
                                if (!(_3400))
                                {
                                    _3400 = true;
                                    _3401 = 1000000.0;
                                }
                            }
                            vec3 _3149 = _1939 - _3146;
                            _3514 = false;
                            float _3515;
                            {
                                int _3516 = 0;
                                bool _3517;
                                for (;;)
                                {
                                    bool _3528_ladder_break = false;
                                    {
                                        if (!(_3516 < int(p.field.x)))
                                        {
                                            _3528_ladder_break = true;
                                        }
                                        else
                                        {
                                            vec3 _3545 = (_3149 - p.sdfOrigin.data[_3516].xyz) / vec3(p.sdfOrigin.data[_3516].w);
                                            if (any(lessThan(_3545, vec3(0.5))))
                                            {
                                                _3517 = true;
                                            }
                                            else
                                            {
                                                _3517 = any(greaterThan(_3545, vec3(float(int(p.field.y)) - 0.5, float(int(p.field.y)) - 0.5, float(int(p.field.y)) - 0.5)));
                                            }
                                            if (!(_3517))
                                            {
                                                _3514 = true;
                                                _3515 = ((textureLod(_4688, vec3(_3545.x / float(int(p.field.y)), _3545.y / float(int(p.field.y)), ((float(_3516) * float(int(p.field.y))) + _3545.z) / float(int(p.field.y) * int(p.field.x))), 0.0).x * 2.0) - 1.0) * p.sdfRange.data[_3516];
                                                _3528_ladder_break = true;
                                            }
                                        }
                                    }
                                    if (_3528_ladder_break)
                                    {
                                        break;
                                    }
                                    _3516++;
                                    continue;
                                }
                                if (!(_3514))
                                {
                                    _3514 = true;
                                    _3515 = 1000000.0;
                                }
                            }
                            vec3 _3152 = vec3(0.0, 0.0, _3139);
                            vec3 _3153 = _1939 + _3152;
                            _3628 = false;
                            float _3629;
                            {
                                int _3630 = 0;
                                bool _3631;
                                for (;;)
                                {
                                    bool _3642_ladder_break = false;
                                    {
                                        if (!(_3630 < int(p.field.x)))
                                        {
                                            _3642_ladder_break = true;
                                        }
                                        else
                                        {
                                            vec3 _3659 = (_3153 - p.sdfOrigin.data[_3630].xyz) / vec3(p.sdfOrigin.data[_3630].w);
                                            if (any(lessThan(_3659, vec3(0.5))))
                                            {
                                                _3631 = true;
                                            }
                                            else
                                            {
                                                _3631 = any(greaterThan(_3659, vec3(float(int(p.field.y)) - 0.5, float(int(p.field.y)) - 0.5, float(int(p.field.y)) - 0.5)));
                                            }
                                            if (!(_3631))
                                            {
                                                _3628 = true;
                                                _3629 = ((textureLod(_4688, vec3(_3659.x / float(int(p.field.y)), _3659.y / float(int(p.field.y)), ((float(_3630) * float(int(p.field.y))) + _3659.z) / float(int(p.field.y) * int(p.field.x))), 0.0).x * 2.0) - 1.0) * p.sdfRange.data[_3630];
                                                _3642_ladder_break = true;
                                            }
                                        }
                                    }
                                    if (_3642_ladder_break)
                                    {
                                        break;
                                    }
                                    _3630++;
                                    continue;
                                }
                                if (!(_3628))
                                {
                                    _3628 = true;
                                    _3629 = 1000000.0;
                                }
                            }
                            vec3 _3155 = _1939 - _3152;
                            _3742 = false;
                            float _3743;
                            {
                                int _3744 = 0;
                                bool _3745;
                                for (;;)
                                {
                                    bool _3756_ladder_break = false;
                                    {
                                        if (!(_3744 < int(p.field.x)))
                                        {
                                            _3756_ladder_break = true;
                                        }
                                        else
                                        {
                                            vec3 _3773 = (_3155 - p.sdfOrigin.data[_3744].xyz) / vec3(p.sdfOrigin.data[_3744].w);
                                            if (any(lessThan(_3773, vec3(0.5))))
                                            {
                                                _3745 = true;
                                            }
                                            else
                                            {
                                                _3745 = any(greaterThan(_3773, vec3(float(int(p.field.y)) - 0.5, float(int(p.field.y)) - 0.5, float(int(p.field.y)) - 0.5)));
                                            }
                                            if (!(_3745))
                                            {
                                                _3742 = true;
                                                _3743 = ((textureLod(_4688, vec3(_3773.x / float(int(p.field.y)), _3773.y / float(int(p.field.y)), ((float(_3744) * float(int(p.field.y))) + _3773.z) / float(int(p.field.y) * int(p.field.x))), 0.0).x * 2.0) - 1.0) * p.sdfRange.data[_3744];
                                                _3756_ladder_break = true;
                                            }
                                        }
                                    }
                                    if (_3756_ladder_break)
                                    {
                                        break;
                                    }
                                    _3744++;
                                    continue;
                                }
                                if (!(_3742))
                                {
                                    _3742 = true;
                                    _3743 = 1000000.0;
                                }
                            }
                            vec3 _3158 = vec3(_3173 - _3287, _3401 - _3515, _3629 - _3743);
                            float _3159 = dot(_3158, _3158);
                            bool _3135;
                            if (_3159 > 9.9999999600419720025001879548654e-13)
                            {
                                _3135 = _3159 < 1000000.0;
                            }
                            else
                            {
                                _3135 = false;
                            }
                            vec3 _3136;
                            if (_3135)
                            {
                                _3136 = _3158 * inversesqrt(_3159);
                            }
                            else
                            {
                                _3136 = vec3(0.0);
                            }
                            vec3 _1941;
                            if (dot(_3136, _3136) <= 0.0)
                            {
                                _1941 = -_189;
                            }
                            else
                            {
                                _1941 = _3136;
                            }
                            vec3 _1991 = _1939 + p.cacheOrigin.xyz;
                            float _1994 = 0.25 + (_1940 * 2.0);
                            vec3 _1942;
                            bool _3861;
                            {
                                _1942 = vec3(0.0);
                                if (int(p.cacheGrid.w) <= 0)
                                {
                                    _3861 = false;
                                }
                                else
                                {
                                    ivec3 _3903 = ivec3(floor((_1991 - p.cacheGrid.xyz) / vec3(p.cacheOrigin.w)));
                                    int _4256 = int((((uint(_3903.x) * 2376512323u) ^ (uint(_3903.y) * 3625334849u)) ^ (uint(_3903.z) * 3407524639u)) & uint(int(p.cacheGrid.w) - 1));
                                    uvec2 _3908 = uvec2(textureSize(_4691, 0));
                                    vec2 _3915 = vec2(float(_3908.x), float(_3908.y));
                                    int _3918 = int(p.cacheGrid.w);
                                    int _3864 = 0;
                                    float _3865 = 0.0;
                                    ivec2 _3866;
                                    bool _3877;
                                    bool _3878;
                                    vec3 _3880[4];
                                    float _3883;
                                    ivec2 _4257;
                                    for (;;)
                                    {
                                        if (!(_3864 <= uCells._member0[_3918].y))
                                        {
                                            break;
                                        }
                                        bool _3931 = _3864 == 0;
                                        if (_3931)
                                        {
                                            _3866 = uCells._member0[_4256];
                                        }
                                        else
                                        {
                                            int _4261 = uCells._member0[_3918].x + ((_3864 - 1) * 6);
                                            float _4278 = intBitsToFloat(uCellPages_1._member0[_4261 + 3]) + _1994;
                                            vec3 _4279 = _1991 - vec3(intBitsToFloat(uCellPages_1._member0[_4261]), intBitsToFloat(uCellPages_1._member0[_4261 + 1]), intBitsToFloat(uCellPages_1._member0[_4261 + 2]));
                                            if (dot(_4279, _4279) > (_4278 * _4278))
                                            {
                                                _4257 = ivec2(0);
                                            }
                                            else
                                            {
                                                _4257 = ivec2(uCellPages_1._member0[_4261 + 4], uCellPages_1._member0[_4261 + 5]);
                                            }
                                            _3866 = _4257;
                                        }
                                        int _3867 = 0;
                                        float _3868 = _3865;
                                        for (;;)
                                        {
                                            bool _3942_ladder_break = false;
                                            {
                                                if (!(_3867 < _3866.y))
                                                {
                                                    _3942_ladder_break = true;
                                                }
                                                else
                                                {
                                                    int _3953 = _3866.x + _3867;
                                                    int _3956 = uCellPages_1._member0[_3953] * 10;
                                                    if (!((uPages_1._member0[_3956 + 5].w > 0.5) == _3931))
                                                    {
                                                        int _3965 = _3956 + 9;
                                                        vec3 _3969 = _1991 - uPages_1._member0[_3965].xyz;
                                                        float _3971 = uPages_1._member0[_3965].w + _1994;
                                                        if (!(dot(_3969, _3969) > (_3971 * _3971)))
                                                        {
                                                            int _4295 = uCellPages_1._member0[_3953] * 10;
                                                            vec4 _3875 = uPages_1._member0[_4295];
                                                            vec4 _3876 = uPages_1._member0[_4295 + 1];
                                                            int _4301 = _4295 + 2;
                                                            int _4304 = _4295 + 3;
                                                            int _4307 = _4295 + 4;
                                                            int _4313 = _4295 + 6;
                                                            int _4316 = _4295 + 7;
                                                            int _4319 = _4295 + 8;
                                                            vec3 _4326 = _1991 - vec3(uPages_1._member0[_4313].w, uPages_1._member0[_4316].w, uPages_1._member0[_4319].w);
                                                            vec3 _4339 = vec3(dot(uPages_1._member0[_4313].xyz, _4326), dot(uPages_1._member0[_4316].xyz, _4326), dot(uPages_1._member0[_4319].xyz, _4326)) - uPages_1._member0[_4301].xyz;
                                                            vec2 _4342 = vec2(uPages_1._member0[_4301].w, uPages_1._member0[_4304].w);
                                                            bvec2 _4809 = isnan(_4342);
                                                            bvec2 _4810 = isnan(vec2(9.9999999747524270787835121154785e-07));
                                                            vec2 _4811 = max(_4342, vec2(9.9999999747524270787835121154785e-07));
                                                            vec2 _4812 = vec2(_4809.x ? vec2(9.9999999747524270787835121154785e-07).x : _4811.x, _4809.y ? vec2(9.9999999747524270787835121154785e-07).y : _4811.y);
                                                            vec2 _4343 = vec2(_4810.x ? _4342.x : _4812.x, _4810.y ? _4342.y : _4812.y);
                                                            vec2 _3870 = _4343;
                                                            vec2 _3869 = vec2(dot(_4339, uPages_1._member0[_4304].xyz), dot(_4339, uPages_1._member0[_4307].xyz)) / _4343;
                                                            float _3871 = -dot(_4339, uPages_1._member0[_4295 + 5].xyz);
                                                            float _3872 = uPages_1._member0[_4307].w;
                                                            float _3980 = dot(uPages_1._member0[_4295 + 5].xyz, vec3(dot(uPages_1._member0[_4313].xyz, _1941), dot(uPages_1._member0[_4316].xyz, _1941), dot(uPages_1._member0[_4319].xyz, _1941)));
                                                            if (!(_3980 <= 0.0))
                                                            {
                                                                float _3985 = 0.5 * _1994;
                                                                vec2 _3988 = vec2(_3985) / _3870;
                                                                if (abs(_3869.x) > (1.0 + _3988.x))
                                                                {
                                                                    _3877 = true;
                                                                }
                                                                else
                                                                {
                                                                    _3877 = abs(_3869.y) > (1.0 + _3988.y);
                                                                }
                                                                if (!(_3877))
                                                                {
                                                                    if (_3871 < (_1994 * (-0.5)))
                                                                    {
                                                                        _3878 = true;
                                                                    }
                                                                    else
                                                                    {
                                                                        _3878 = _3871 > (_3872 + _3985);
                                                                    }
                                                                    if (!(_3878))
                                                                    {
                                                                        vec2 _4032 = (_3876.xy + (((clamp(_3869, vec2(-1.0), vec2(1.0)) * 0.5) + vec2(0.5)) * _3876.zw)) - vec2(0.5);
                                                                        vec2 _4033 = floor(_4032);
                                                                        vec2 _4034 = _4032 - _4033;
                                                                        bvec2 _4814 = isnan(_3876.zw);
                                                                        bvec2 _4815 = isnan(vec2(9.9999999747524270787835121154785e-07));
                                                                        vec2 _4816 = max(_3876.zw, vec2(9.9999999747524270787835121154785e-07));
                                                                        vec2 _4817 = vec2(_4814.x ? vec2(9.9999999747524270787835121154785e-07).x : _4816.x, _4814.y ? vec2(9.9999999747524270787835121154785e-07).y : _4816.y);
                                                                        vec2 _4040 = _3875.zw / vec2(_4815.x ? _3876.zw.x : _4817.x, _4815.y ? _3876.zw.y : _4817.y);
                                                                        float _4044 = _3871 / (isnan(9.9999999747524270787835121154785e-07) ? _3872 : (isnan(_3872) ? 9.9999999747524270787835121154785e-07 : max(_3872, 9.9999999747524270787835121154785e-07)));
                                                                        float _4046 = 0.5 * _3872;
                                                                        float _4048 = _1994 / (isnan(9.9999999747524270787835121154785e-07) ? _4046 : (isnan(_4046) ? 9.9999999747524270787835121154785e-07 : max(_4046, 9.9999999747524270787835121154785e-07)));
                                                                        vec4 _3879 = vec4(0.0);
                                                                        int _3882 = 0;
                                                                        for (;;)
                                                                        {
                                                                            if (!(_3882 < 4))
                                                                            {
                                                                                break;
                                                                            }
                                                                            vec2 _4063 = vec2(float(_3882 & 1), float(_3882 >> 1));
                                                                            vec2 _4066 = (_4033 + _4063) + vec2(0.5);
                                                                            vec2 _4067 = _4066 / _3915;
                                                                            if (textureLod(_4693, _4067, 0.0).w >= 0.5)
                                                                            {
                                                                                _3883 = 1.0;
                                                                            }
                                                                            else
                                                                            {
                                                                                _3883 = 0.0;
                                                                            }
                                                                            vec2 _4096 = mix(vec2(1.0) - _4034, _4034, _4063);
                                                                            _3879[_3882] = ((_4096.x * _4096.y) * _3883) * (1.0 - clamp((abs(_4044 - textureLod(_4695, _4067, 0.0).x) - _4048) / (0.25 * _4048), 0.0, 1.0));
                                                                            _3880[_3882] = textureLod(_4697, (floor(_3875.xy + ((_4066 - _3876.xy) * _4040)) + vec2(0.5)) / vec3(p.cacheAtlas.xy, 0.0).xy, 0.0).xyz;
                                                                            _3882++;
                                                                            continue;
                                                                        }
                                                                        float _4145 = ((_3879.x + _3879.y) + _3879.z) + _3879.w;
                                                                        float _4146 = (_3980 * _3980) * _4145;
                                                                        if (!(_4146 <= 0.0))
                                                                        {
                                                                            vec3 _4174 = ((((_3880[0] * _3879.x) + (_3880[1] * _3879.y)) + (_3880[2] * _3879.z)) + (_3880[3] * _3879.w)) / vec3(_4145);
                                                                            bvec3 _4829 = isnan(_4174);
                                                                            bvec3 _4830 = isnan(vec3(0.0));
                                                                            vec3 _4831 = max(_4174, vec3(0.0));
                                                                            vec3 _4832 = vec3(_4829.x ? vec3(0.0).x : _4831.x, _4829.y ? vec3(0.0).y : _4831.y, _4829.z ? vec3(0.0).z : _4831.z);
                                                                            _1942 += (vec3(_4830.x ? _4174.x : _4832.x, _4830.y ? _4174.y : _4832.y, _4830.z ? _4174.z : _4832.z) * _4146);
                                                                            _3868 += _4146;
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            if (_3942_ladder_break)
                                            {
                                                break;
                                            }
                                            _3867++;
                                            continue;
                                        }
                                        _3864++;
                                        _3865 = _3868;
                                        continue;
                                    }
                                    if (_3865 <= 0.0)
                                    {
                                        _1942 = vec3(0.0);
                                        _3861 = false;
                                    }
                                    else
                                    {
                                        _1942 /= vec3(_3865);
                                        _3861 = true;
                                    }
                                }
                            }
                            vec3 _1943;
                            if (_3861)
                            {
                                gRoute = 2;
                                _1943 = _1942 * p.cacheAtlas.z;
                            }
                            else
                            {
                                _1943 = vec3(0.0);
                            }
                            if (!_3861)
                            {
                                gRoute = 3;
                                if (_2175)
                                {
                                    uint _4483 = uvec2(textureSize(_4681, 0)).y;
                                    float _4500 = (p.trace.w * p.trace.w) - 40449600.0;
                                    float _4505 = acos(clamp(sqrt(isnan(_4500) ? 0.0 : (isnan(0.0) ? _4500 : max(0.0, _4500))) / p.trace.w, -1.0, 1.0));
                                    float _4506 = 3.1415927410125732421875 - _4505;
                                    float _4509 = acos(clamp(_189.z, -1.0, 1.0));
                                    float _4495;
                                    if (_4509 < _4506)
                                    {
                                        float _4521 = 1.0 - (_4509 / _4506);
                                        _4495 = (1.0 - sqrt(isnan(_4521) ? 0.0 : (isnan(0.0) ? _4521 : max(0.0, _4521)))) * 0.5;
                                    }
                                    else
                                    {
                                        float _4514 = (_4509 - _4506) / (isnan(9.9999999747524270787835121154785e-07) ? _4505 : (isnan(_4505) ? 9.9999999747524270787835121154785e-07 : max(_4505, 9.9999999747524270787835121154785e-07)));
                                        _4495 = (sqrt(isnan(_4514) ? 0.0 : (isnan(0.0) ? _4514 : max(0.0, _4514))) * 0.5) + 0.5;
                                    }
                                    float _4529 = atan(_189.y, _189.x);
                                    float _4496;
                                    if (_4529 < 0.0)
                                    {
                                        _4496 = _4529 + 6.283185482025146484375;
                                    }
                                    else
                                    {
                                        _4496 = _4529;
                                    }
                                    vec2 _4538 = vec2(_4496 * 0.15915493667125701904296875, _4495);
                                    float _4492 = float(_4483);
                                    float _4543 = _4538.y;
                                    float _4547 = _4492 - 1.0;
                                    float _4549 = (floor(_4492 * 0.5) - 1.0) / (isnan(1.0) ? _4547 : (isnan(_4547) ? 1.0 : max(_4547, 1.0)));
                                    _4538.y = isnan(_4549) ? _4543 : (isnan(_4543) ? _4549 : min(_4543, _4549));
                                    uvec2 _4557 = uvec2(textureSize(_4681, 0));
                                    vec2 _4564 = vec2(float(_4557.x), float(_4557.y));
                                    _1941 = vec3(dot(textureLod(_4683, (_4538 * ((_4564 - vec2(1.0)) / _4564)) + (vec2(0.5) / _4564), 0.0).xyz * smoothstep(-0.100000001490116119384765625, 0.25, _189.z), vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * 0.300000011920928955078125) + p.ambient.xyz;
                                }
                                else
                                {
                                    uint _4365 = uvec2(textureSize(_4681, 0)).y;
                                    float _4382 = (p.trace.w * p.trace.w) - 40449600.0;
                                    float _4387 = acos(clamp(sqrt(isnan(_4382) ? 0.0 : (isnan(0.0) ? _4382 : max(0.0, _4382))) / p.trace.w, -1.0, 1.0));
                                    float _4388 = 3.1415927410125732421875 - _4387;
                                    float _4391 = acos(clamp(_189.z, -1.0, 1.0));
                                    float _4377;
                                    if (_4391 < _4388)
                                    {
                                        float _4403 = 1.0 - (_4391 / _4388);
                                        _4377 = (1.0 - sqrt(isnan(_4403) ? 0.0 : (isnan(0.0) ? _4403 : max(0.0, _4403)))) * 0.5;
                                    }
                                    else
                                    {
                                        float _4396 = (_4391 - _4388) / (isnan(9.9999999747524270787835121154785e-07) ? _4387 : (isnan(_4387) ? 9.9999999747524270787835121154785e-07 : max(_4387, 9.9999999747524270787835121154785e-07)));
                                        _4377 = (sqrt(isnan(_4396) ? 0.0 : (isnan(0.0) ? _4396 : max(0.0, _4396))) * 0.5) + 0.5;
                                    }
                                    float _4411 = atan(_189.y, _189.x);
                                    float _4378;
                                    if (_4411 < 0.0)
                                    {
                                        _4378 = _4411 + 6.283185482025146484375;
                                    }
                                    else
                                    {
                                        _4378 = _4411;
                                    }
                                    vec2 _4420 = vec2(_4378 * 0.15915493667125701904296875, _4377);
                                    float _4374 = float(_4365);
                                    float _4425 = _4420.y;
                                    float _4429 = _4374 - 1.0;
                                    float _4431 = (floor(_4374 * 0.5) - 1.0) / (isnan(1.0) ? _4429 : (isnan(_4429) ? 1.0 : max(_4429, 1.0)));
                                    _4420.y = isnan(_4431) ? _4425 : (isnan(_4425) ? _4431 : min(_4425, _4431));
                                    uvec2 _4439 = uvec2(textureSize(_4681, 0));
                                    vec2 _4446 = vec2(float(_4439.x), float(_4439.y));
                                    _1941 = textureLod(_4683, (_4420 * ((_4446 - vec2(1.0)) / _4446)) + (vec2(0.5) / _4446), 0.0).xyz * smoothstep(-0.100000001490116119384765625, 0.25, _189.z);
                                }
                                _1937 = _1941;
                            }
                            else
                            {
                                float _2020 = isnan(_1943.z) ? _1943.y : (isnan(_1943.y) ? _1943.z : max(_1943.y, _1943.z));
                                float _2021 = isnan(_2020) ? _1943.x : (isnan(_1943.x) ? _2020 : max(_1943.x, _2020));
                                if (_2021 > p.trace.z)
                                {
                                    _1943 *= (p.trace.z / _2021);
                                }
                                _1937 = _1943;
                            }
                        }
                    }
                }
                if (p.debug.w > 3.5)
                {
                    imageStore(uOut, ivec2(gl_GlobalInvocationID.xy), vec4((normalW * 0.5) + vec3(0.5), 1.0));
                }
                else
                {
                    if (p.debug.w > 2.5)
                    {
                        imageStore(uOut, ivec2(gl_GlobalInvocationID.xy), vec4((_189 * 0.5) + vec3(0.5), 1.0));
                    }
                    else
                    {
                        if (p.debug.w > 0.5)
                        {
                            _66 = p.debug.w < 1.5;
                        }
                        else
                        {
                            _66 = false;
                        }
                        if (_66)
                        {
                            vec3 _4581;
                            {
                                if (gRoute == 1)
                                {
                                    _4581 = vec3(0.0, 1.0, 0.0);
                                }
                                else
                                {
                                    if (gRoute == 2)
                                    {
                                        _4581 = vec3(0.0, 0.20000000298023223876953125, 1.0);
                                    }
                                    else
                                    {
                                        if (gRoute == 3)
                                        {
                                            _4581 = vec3(1.0, 0.0, 0.0);
                                        }
                                        else
                                        {
                                            if (gRoute == 4)
                                            {
                                                _4581 = vec3(1.0, 0.800000011920928955078125, 0.0);
                                            }
                                            else
                                            {
                                                if (gRoute == 5)
                                                {
                                                    _4581 = vec3(1.0);
                                                }
                                                else
                                                {
                                                    _4581 = vec3(0.25);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            imageStore(uOut, ivec2(gl_GlobalInvocationID.xy), vec4(_4581, 1.0));
                        }
                        else
                        {
                            if (p.debug.x > 0.5)
                            {
                                imageStore(uOut, ivec2(gl_GlobalInvocationID.xy), vec4(_1937, 1.0));
                            }
                            else
                            {
                                imageStore(uOut, ivec2(gl_GlobalInvocationID.xy), vec4((_1937 * ((2.0 * (0.039999999105930328369140625 + _197)) / (_197 + 1.03999996185302734375))) * p.cacheAtlas.w, 1.0));
                            }
                        }
                    }
                }
            }
        }
    }
}

