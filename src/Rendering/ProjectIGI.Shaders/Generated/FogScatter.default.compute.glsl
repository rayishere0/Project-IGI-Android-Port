#version 430
layout(local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

struct _Array_std140_matrix_float_4_4_4
{
    mat4 data[4];
};

struct _Array_std140_vector_float_4_8
{
    vec4 data[8];
};

struct _Array_std140_vector_float_4_160
{
    vec4 data[160];
};

struct FlashlightParams_std140
{
    vec4 position;
    vec4 axis;
    vec4 up;
    vec4 colour;
    vec4 cone;
    vec4 control;
};

struct _Array_std140_vector_float_4_4
{
    vec4 data[4];
};

struct _Array_std140_matrix_float_4_4_240
{
    mat4 data[240];
};

struct _Array_std140_vector_float_4_120
{
    vec4 data[120];
};

struct _Array_std140_vector_int_4_40
{
    ivec4 data[40];
};

layout(binding = 0, std140) uniform FogParams_std140
{
    layout(row_major) mat4 viewToWorld;
    layout(row_major) mat4 prevWorldToView;
    layout(row_major) _Array_std140_matrix_float_4_4_4 cascade;
    vec4 cascadeSplits;
    vec4 grid;
    vec4 unproject;
    vec4 prevUnproject;
    vec4 zParams;
    vec4 medium;
    vec4 march;
    vec4 albedo;
    vec4 sun;
    vec4 sunColour;
    vec4 ambient;
    vec4 camera;
    vec4 jitter;
    vec4 cameraWorld;
    vec4 shelter0;
    vec4 shelter1;
    vec4 shelter2;
    _Array_std140_vector_float_4_8 volumeCentre;
    _Array_std140_vector_float_4_8 volumeExtent;
    _Array_std140_vector_float_4_160 lampPosition;
    _Array_std140_vector_float_4_160 lampColour;
    FlashlightParams_std140 flashlight;
    vec4 phase;
    vec4 dust;
    vec4 records;
    vec4 fieldMisc;
    _Array_std140_vector_float_4_4 fieldOrigin;
    vec4 fieldRange;
    _Array_std140_vector_float_4_160 lampDirection;
} p;

layout(binding = 1, std140) uniform FogLampMapParams_std140
{
    _Array_std140_vector_float_4_4 origin;
    vec4 range;
    ivec4 levels;
    layout(row_major) _Array_std140_matrix_float_4_4_240 mapMatrix;
    _Array_std140_vector_float_4_120 mapDepth;
    _Array_std140_vector_int_4_40 mapSlot;
} uFogLampMapParams;

layout(binding = 0, rgba16f) uniform restrict writeonly image3D uScattering;
layout(binding = 3) uniform sampler2D _4547;
layout(binding = 4) uniform sampler3D _4549;
layout(binding = 0) uniform sampler2DArray _4552;
layout(binding = 5) uniform sampler2DArray _4555;
layout(binding = 1) uniform sampler2D _4558;
layout(binding = 2) uniform sampler3D _4560;

mat4 spvWorkaroundRowMajor(mat4 wrap) { return wrap; }

void main()
{
    bool _4248 = false;
    bool _4169 = false;
    bool _3624 = false;
    bool _3535 = false;
    bool _3308 = false;
    {
        ivec3 _165 = ivec3(gl_GlobalInvocationID);
        if (!(any(greaterThanEqual(_165, ivec3(p.grid.xyz + vec3(0.5))))))
        {
            vec3 _2278 = fract((vec3(_165) + vec3(0.37000000476837158203125)) * 0.103100001811981201171875);
            vec3 _2284 = _2278 + vec3(dot(_2278, _2278.zyx + vec3(31.31999969482421875)));
            vec3 _2294 = fract((vec3(_165.yzx) + vec3(11.1000003814697265625)) * 0.103100001811981201171875);
            vec3 _2300 = _2294 + vec3(dot(_2294, _2294.zyx + vec3(31.31999969482421875)));
            vec3 _2310 = fract((vec3(_165.zxy) + vec3(23.700000762939453125)) * 0.103100001811981201171875);
            vec3 _2316 = _2310 + vec3(dot(_2310, _2310.zyx + vec3(31.31999969482421875)));
            vec3 _224 = fract(p.jitter.xyz + vec3(fract((_2284.x + _2284.y) * _2284.z), fract((_2300.x + _2300.y) * _2300.z), fract((_2316.x + _2316.y) * _2316.z)));
            vec2 _228 = vec2(_165.xy);
            float _235 = float(_165.z);
            float _2335 = (exp2((_235 + _224.z) / p.zParams.z) - p.zParams.y) / p.zParams.x;
            vec2 _2340 = (((_228 + _224.xy) / p.grid.xy) * 2.0) - vec2(1.0);
            vec3 _2353 = vec3((_2340.x * _2335) / p.unproject.x, ((-_2340.y) * _2335) / p.unproject.y, _2335);
            vec4 _288 = vec4(_2353, 0.0) * spvWorkaroundRowMajor(p.viewToWorld);
            vec3 world = _288.xyz;
            bool _2355;
            {
                if (p.shelter1.w < 0.5)
                {
                    _2355 = false;
                }
                else
                {
                    vec3 _2369 = world + p.cameraWorld.xyz;
                    ivec2 _2379 = ivec2(floor((_2369.xy - p.shelter0.xy) * p.shelter0.z));
                    int _2380 = _2379.x;
                    bool _2356;
                    if (_2380 < 0)
                    {
                        _2356 = true;
                    }
                    else
                    {
                        _2356 = _2379.y < 0;
                    }
                    if (_2356)
                    {
                        _2356 = true;
                    }
                    else
                    {
                        _2356 = _2380 >= int(p.shelter2.x);
                    }
                    if (_2356)
                    {
                        _2356 = true;
                    }
                    else
                    {
                        _2356 = _2379.y >= int(p.shelter2.y);
                    }
                    if (_2356)
                    {
                        _2355 = false;
                    }
                    else
                    {
                        vec4 _2412 = texelFetch(_4547, ivec3(_2379, 0).xy, 0);
                        float _2423 = floor((_2412.z * 255.0) + 0.5) + (floor((_2412.y * 255.0) + 0.5) * 256.0);
                        if (_2423 < 0.5)
                        {
                            _2355 = false;
                        }
                        else
                        {
                            float _2433 = p.shelter0.w + ((_2423 - 1.0) * p.shelter1.x);
                            float _2434 = _2369.z;
                            if (_2433 > (_2434 + p.shelter1.y))
                            {
                                _2356 = _2433 < (_2434 + p.shelter1.z);
                            }
                            else
                            {
                                _2356 = false;
                            }
                            _2355 = _2356;
                        }
                    }
                }
            }
            float _2450;
            {
                if (_2355)
                {
                    _2450 = 0.0;
                }
                else
                {
                    float _2460 = _288.z - p.medium.z;
                    float _2481 = 1.0;
                    int _2482 = 0;
                    float _2483;
                    for (;;)
                    {
                        bool _2488_ladder_break = false;
                        {
                            if (!(_2482 < 8))
                            {
                                _2488_ladder_break = true;
                            }
                            else
                            {
                                if (p.volumeExtent.data[_2482].x <= 0.0)
                                {
                                    _2483 = _2481;
                                }
                                else
                                {
                                    vec3 _2511 = abs(world - p.volumeCentre.data[_2482].xyz);
                                    if (p.volumeCentre.data[_2482].w > 0.5)
                                    {
                                        _2483 = length(_2511) / (isnan(0.001000000047497451305389404296875) ? p.volumeExtent.data[_2482].x : (isnan(p.volumeExtent.data[_2482].x) ? 0.001000000047497451305389404296875 : max(p.volumeExtent.data[_2482].x, 0.001000000047497451305389404296875)));
                                    }
                                    else
                                    {
                                        float _2520 = _2511.x / (isnan(0.001000000047497451305389404296875) ? p.volumeExtent.data[_2482].x : (isnan(p.volumeExtent.data[_2482].x) ? 0.001000000047497451305389404296875 : max(p.volumeExtent.data[_2482].x, 0.001000000047497451305389404296875)));
                                        float _2525 = _2511.y / (isnan(0.001000000047497451305389404296875) ? p.volumeExtent.data[_2482].y : (isnan(p.volumeExtent.data[_2482].y) ? 0.001000000047497451305389404296875 : max(p.volumeExtent.data[_2482].y, 0.001000000047497451305389404296875)));
                                        float _2530 = _2511.z / (isnan(0.001000000047497451305389404296875) ? p.volumeExtent.data[_2482].z : (isnan(p.volumeExtent.data[_2482].z) ? 0.001000000047497451305389404296875 : max(p.volumeExtent.data[_2482].z, 0.001000000047497451305389404296875)));
                                        float _2531 = isnan(_2530) ? _2525 : (isnan(_2525) ? _2530 : max(_2525, _2530));
                                        _2483 = isnan(_2531) ? _2520 : (isnan(_2520) ? _2531 : max(_2520, _2531));
                                    }
                                    _2483 = mix(_2481, p.volumeExtent.data[_2482].w, 1.0 - smoothstep(0.699999988079071044921875, 1.0, _2483));
                                }
                            }
                        }
                        if (_2488_ladder_break)
                        {
                            break;
                        }
                        _2481 = _2483;
                        _2482++;
                        continue;
                    }
                    float _2556;
                    {
                        if (p.dust.w <= 0.0)
                        {
                            _2556 = 1.0;
                        }
                        else
                        {
                            vec3 _2573 = world + (fract(p.cameraWorld.xyz * vec3(0.000244140625)) * 4096.0);
                            vec3 _2577 = vec3(0.60000002384185791015625, 0.25, 0.039999999105930328369140625) * p.phase.z;
                            vec3 _2580 = (_2573 + _2577) * vec3(0.0416666679084300994873046875);
                            vec3 _2597 = floor(_2580);
                            vec3 _2598 = fract(_2580);
                            vec3 _2603 = (_2598 * _2598) * (vec3(3.0) - (_2598 * 2.0));
                            vec3 _2632 = fract(_2597 * 0.103100001811981201171875);
                            vec3 _2638 = _2632 + vec3(dot(_2632, _2632.zyx + vec3(31.31999969482421875)));
                            vec3 _2648 = fract((_2597 + vec3(1.0, 0.0, 0.0)) * 0.103100001811981201171875);
                            vec3 _2654 = _2648 + vec3(dot(_2648, _2648.zyx + vec3(31.31999969482421875)));
                            vec3 _2664 = fract((_2597 + vec3(0.0, 1.0, 0.0)) * 0.103100001811981201171875);
                            vec3 _2670 = _2664 + vec3(dot(_2664, _2664.zyx + vec3(31.31999969482421875)));
                            vec3 _2680 = fract((_2597 + vec3(1.0, 1.0, 0.0)) * 0.103100001811981201171875);
                            vec3 _2686 = _2680 + vec3(dot(_2680, _2680.zyx + vec3(31.31999969482421875)));
                            vec3 _2696 = fract((_2597 + vec3(0.0, 0.0, 1.0)) * 0.103100001811981201171875);
                            vec3 _2702 = _2696 + vec3(dot(_2696, _2696.zyx + vec3(31.31999969482421875)));
                            vec3 _2712 = fract((_2597 + vec3(1.0, 0.0, 1.0)) * 0.103100001811981201171875);
                            vec3 _2718 = _2712 + vec3(dot(_2712, _2712.zyx + vec3(31.31999969482421875)));
                            vec3 _2728 = fract((_2597 + vec3(0.0, 1.0, 1.0)) * 0.103100001811981201171875);
                            vec3 _2734 = _2728 + vec3(dot(_2728, _2728.zyx + vec3(31.31999969482421875)));
                            vec3 _2744 = fract((_2597 + vec3(1.0)) * 0.103100001811981201171875);
                            vec3 _2750 = _2744 + vec3(dot(_2744, _2744.zyx + vec3(31.31999969482421875)));
                            float _2619 = _2603.x;
                            float _2622 = _2603.y;
                            float _2582 = mix(mix(mix(fract((_2638.x + _2638.y) * _2638.z), fract((_2654.x + _2654.y) * _2654.z), _2619), mix(fract((_2670.x + _2670.y) * _2670.z), fract((_2686.x + _2686.y) * _2686.z), _2619), _2622), mix(mix(fract((_2702.x + _2702.y) * _2702.z), fract((_2718.x + _2718.y) * _2718.z), _2619), mix(fract((_2734.x + _2734.y) * _2734.z), fract((_2750.x + _2750.y) * _2750.z), _2619), _2622), _2603.z) * 0.699999988079071044921875;
                            vec3 _2586 = (_2573 + (_2577 * 1.7000000476837158203125)) * vec3(0.111111111938953399658203125);
                            vec3 _2759 = floor(_2586);
                            vec3 _2760 = fract(_2586);
                            vec3 _2765 = (_2760 * _2760) * (vec3(3.0) - (_2760 * 2.0));
                            vec3 _2794 = fract(_2759 * 0.103100001811981201171875);
                            vec3 _2800 = _2794 + vec3(dot(_2794, _2794.zyx + vec3(31.31999969482421875)));
                            vec3 _2810 = fract((_2759 + vec3(1.0, 0.0, 0.0)) * 0.103100001811981201171875);
                            vec3 _2816 = _2810 + vec3(dot(_2810, _2810.zyx + vec3(31.31999969482421875)));
                            vec3 _2826 = fract((_2759 + vec3(0.0, 1.0, 0.0)) * 0.103100001811981201171875);
                            vec3 _2832 = _2826 + vec3(dot(_2826, _2826.zyx + vec3(31.31999969482421875)));
                            vec3 _2842 = fract((_2759 + vec3(1.0, 1.0, 0.0)) * 0.103100001811981201171875);
                            vec3 _2848 = _2842 + vec3(dot(_2842, _2842.zyx + vec3(31.31999969482421875)));
                            vec3 _2858 = fract((_2759 + vec3(0.0, 0.0, 1.0)) * 0.103100001811981201171875);
                            vec3 _2864 = _2858 + vec3(dot(_2858, _2858.zyx + vec3(31.31999969482421875)));
                            vec3 _2874 = fract((_2759 + vec3(1.0, 0.0, 1.0)) * 0.103100001811981201171875);
                            vec3 _2880 = _2874 + vec3(dot(_2874, _2874.zyx + vec3(31.31999969482421875)));
                            vec3 _2890 = fract((_2759 + vec3(0.0, 1.0, 1.0)) * 0.103100001811981201171875);
                            vec3 _2896 = _2890 + vec3(dot(_2890, _2890.zyx + vec3(31.31999969482421875)));
                            vec3 _2906 = fract((_2759 + vec3(1.0)) * 0.103100001811981201171875);
                            vec3 _2912 = _2906 + vec3(dot(_2906, _2906.zyx + vec3(31.31999969482421875)));
                            float _2781 = _2765.x;
                            float _2784 = _2765.y;
                            float _2588 = mix(mix(mix(fract((_2800.x + _2800.y) * _2800.z), fract((_2816.x + _2816.y) * _2816.z), _2781), mix(fract((_2832.x + _2832.y) * _2832.z), fract((_2848.x + _2848.y) * _2848.z), _2781), _2784), mix(mix(fract((_2864.x + _2864.y) * _2864.z), fract((_2880.x + _2880.y) * _2880.z), _2781), mix(fract((_2896.x + _2896.y) * _2896.z), fract((_2912.x + _2912.y) * _2912.z), _2781), _2784), _2765.z) * 0.300000011920928955078125;
                            _2556 = mix(1.0, 0.300000011920928955078125 + (1.39999997615814208984375 * (_2582 + _2588)), p.dust.w);
                        }
                    }
                    float _2477 = ((p.medium.x * mix(exp((-(isnan(0.0) ? _2460 : (isnan(_2460) ? 0.0 : max(_2460, 0.0)))) * p.medium.y), 1.0, p.march.x)) * _2481) * _2556;
                    _2450 = isnan(0.0) ? _2477 : (isnan(_2477) ? 0.0 : max(_2477, 0.0));
                }
            }
            float _2920;
            {
                float _2927 = isnan(1.0) ? p.dust.y : (isnan(p.dust.y) ? 1.0 : max(p.dust.y, 1.0));
                if (_2355)
                {
                    _2920 = isnan(0.0) ? p.dust.z : (isnan(p.dust.z) ? 0.0 : max(p.dust.z, 0.0));
                }
                else
                {
                    float _2945;
                    {
                        if (p.dust.w <= 0.0)
                        {
                            _2945 = 1.0;
                        }
                        else
                        {
                            vec3 _2962 = world + (fract(p.cameraWorld.xyz * vec3(0.000244140625)) * 4096.0);
                            vec3 _2966 = vec3(0.60000002384185791015625, 0.25, 0.039999999105930328369140625) * p.phase.z;
                            vec3 _2969 = (_2962 + _2966) * vec3(0.0416666679084300994873046875);
                            vec3 _2986 = floor(_2969);
                            vec3 _2987 = fract(_2969);
                            vec3 _2992 = (_2987 * _2987) * (vec3(3.0) - (_2987 * 2.0));
                            vec3 _3021 = fract(_2986 * 0.103100001811981201171875);
                            vec3 _3027 = _3021 + vec3(dot(_3021, _3021.zyx + vec3(31.31999969482421875)));
                            vec3 _3037 = fract((_2986 + vec3(1.0, 0.0, 0.0)) * 0.103100001811981201171875);
                            vec3 _3043 = _3037 + vec3(dot(_3037, _3037.zyx + vec3(31.31999969482421875)));
                            vec3 _3053 = fract((_2986 + vec3(0.0, 1.0, 0.0)) * 0.103100001811981201171875);
                            vec3 _3059 = _3053 + vec3(dot(_3053, _3053.zyx + vec3(31.31999969482421875)));
                            vec3 _3069 = fract((_2986 + vec3(1.0, 1.0, 0.0)) * 0.103100001811981201171875);
                            vec3 _3075 = _3069 + vec3(dot(_3069, _3069.zyx + vec3(31.31999969482421875)));
                            vec3 _3085 = fract((_2986 + vec3(0.0, 0.0, 1.0)) * 0.103100001811981201171875);
                            vec3 _3091 = _3085 + vec3(dot(_3085, _3085.zyx + vec3(31.31999969482421875)));
                            vec3 _3101 = fract((_2986 + vec3(1.0, 0.0, 1.0)) * 0.103100001811981201171875);
                            vec3 _3107 = _3101 + vec3(dot(_3101, _3101.zyx + vec3(31.31999969482421875)));
                            vec3 _3117 = fract((_2986 + vec3(0.0, 1.0, 1.0)) * 0.103100001811981201171875);
                            vec3 _3123 = _3117 + vec3(dot(_3117, _3117.zyx + vec3(31.31999969482421875)));
                            vec3 _3133 = fract((_2986 + vec3(1.0)) * 0.103100001811981201171875);
                            vec3 _3139 = _3133 + vec3(dot(_3133, _3133.zyx + vec3(31.31999969482421875)));
                            float _3008 = _2992.x;
                            float _3011 = _2992.y;
                            float _2971 = mix(mix(mix(fract((_3027.x + _3027.y) * _3027.z), fract((_3043.x + _3043.y) * _3043.z), _3008), mix(fract((_3059.x + _3059.y) * _3059.z), fract((_3075.x + _3075.y) * _3075.z), _3008), _3011), mix(mix(fract((_3091.x + _3091.y) * _3091.z), fract((_3107.x + _3107.y) * _3107.z), _3008), mix(fract((_3123.x + _3123.y) * _3123.z), fract((_3139.x + _3139.y) * _3139.z), _3008), _3011), _2992.z) * 0.699999988079071044921875;
                            vec3 _2975 = (_2962 + (_2966 * 1.7000000476837158203125)) * vec3(0.111111111938953399658203125);
                            vec3 _3148 = floor(_2975);
                            vec3 _3149 = fract(_2975);
                            vec3 _3154 = (_3149 * _3149) * (vec3(3.0) - (_3149 * 2.0));
                            vec3 _3183 = fract(_3148 * 0.103100001811981201171875);
                            vec3 _3189 = _3183 + vec3(dot(_3183, _3183.zyx + vec3(31.31999969482421875)));
                            vec3 _3199 = fract((_3148 + vec3(1.0, 0.0, 0.0)) * 0.103100001811981201171875);
                            vec3 _3205 = _3199 + vec3(dot(_3199, _3199.zyx + vec3(31.31999969482421875)));
                            vec3 _3215 = fract((_3148 + vec3(0.0, 1.0, 0.0)) * 0.103100001811981201171875);
                            vec3 _3221 = _3215 + vec3(dot(_3215, _3215.zyx + vec3(31.31999969482421875)));
                            vec3 _3231 = fract((_3148 + vec3(1.0, 1.0, 0.0)) * 0.103100001811981201171875);
                            vec3 _3237 = _3231 + vec3(dot(_3231, _3231.zyx + vec3(31.31999969482421875)));
                            vec3 _3247 = fract((_3148 + vec3(0.0, 0.0, 1.0)) * 0.103100001811981201171875);
                            vec3 _3253 = _3247 + vec3(dot(_3247, _3247.zyx + vec3(31.31999969482421875)));
                            vec3 _3263 = fract((_3148 + vec3(1.0, 0.0, 1.0)) * 0.103100001811981201171875);
                            vec3 _3269 = _3263 + vec3(dot(_3263, _3263.zyx + vec3(31.31999969482421875)));
                            vec3 _3279 = fract((_3148 + vec3(0.0, 1.0, 1.0)) * 0.103100001811981201171875);
                            vec3 _3285 = _3279 + vec3(dot(_3279, _3279.zyx + vec3(31.31999969482421875)));
                            vec3 _3295 = fract((_3148 + vec3(1.0)) * 0.103100001811981201171875);
                            vec3 _3301 = _3295 + vec3(dot(_3295, _3295.zyx + vec3(31.31999969482421875)));
                            float _3170 = _3154.x;
                            float _3173 = _3154.y;
                            float _2977 = mix(mix(mix(fract((_3189.x + _3189.y) * _3189.z), fract((_3205.x + _3205.y) * _3205.z), _3170), mix(fract((_3221.x + _3221.y) * _3221.z), fract((_3237.x + _3237.y) * _3237.z), _3170), _3173), mix(mix(fract((_3253.x + _3253.y) * _3253.z), fract((_3269.x + _3269.y) * _3269.z), _3170), mix(fract((_3285.x + _3285.y) * _3285.z), fract((_3301.x + _3301.y) * _3301.z), _3170), _3173), _3154.z) * 0.300000011920928955078125;
                            _2945 = mix(1.0, 0.300000011920928955078125 + (1.39999997615814208984375 * (_2971 + _2977)), p.dust.w);
                        }
                    }
                    float _2940 = (p.dust.x * (1.0 - smoothstep(0.5 * _2927, _2927, _2335))) * _2945;
                    _2920 = isnan(0.0) ? _2940 : (isnan(_2940) ? 0.0 : max(_2940, 0.0));
                }
            }
            vec3 _677 = normalize(_2353);
            float _678 = _2450 + _2920;
            vec3 direct;
            if (_678 > 0.0)
            {
                _3308 = false;
                float _3309;
                {
                    int _3329 = int(p.albedo.w + 0.5);
                    if (_3329 <= 0)
                    {
                        _3308 = true;
                        _3309 = 1.0;
                    }
                    else
                    {
                        int _3335 = clamp(_3329 - 1, 0, 3);
                        float _3310;
                        if (p.cascadeSplits[_3335] > 0.0)
                        {
                            float _3344 = p.cascadeSplits[_3335] * 0.449999988079071044921875;
                            _3310 = clamp((_2353.z - (p.cascadeSplits[_3335] * 0.550000011920928955078125)) / (isnan(0.001000000047497451305389404296875) ? _3344 : (isnan(_3344) ? 0.001000000047497451305389404296875 : max(_3344, 0.001000000047497451305389404296875))), 0.0, 1.0);
                        }
                        else
                        {
                            _3310 = 1.0;
                        }
                        float _3311;
                        if (_3310 > 0.0)
                        {
                            float _3507;
                            {
                                if (int(p.fieldMisc.x + 0.5) <= 0)
                                {
                                    _3507 = 1.0;
                                }
                                else
                                {
                                    vec3 _3527 = normalize((vec4(p.sun.xyz, 0.0) * spvWorkaroundRowMajor(p.viewToWorld)).xyz);
                                    _3535 = false;
                                    float _3536;
                                    {
                                        if (int(p.fieldMisc.x + 0.5) <= 0)
                                        {
                                            _3535 = true;
                                            _3536 = 1.0;
                                        }
                                        else
                                        {
                                            float _3578 = (p.fieldOrigin.data[0].w * float(int(p.fieldMisc.y + 0.5))) * float(1 << (int(p.fieldMisc.x + 0.5) - 1));
                                            int _3537 = 0;
                                            float _3538 = 0.0;
                                            bool _3539;
                                            bool _3540;
                                            float _3542;
                                            float _3625;
                                            bool _3627;
                                            for (;;)
                                            {
                                                if (_3537 < 64)
                                                {
                                                    _3539 = _3538 < _3578;
                                                }
                                                else
                                                {
                                                    _3539 = false;
                                                }
                                                if (!_3539)
                                                {
                                                    break;
                                                }
                                                vec3 _3595 = world + (_3527 * _3538);
                                                _3624 = false;
                                                {
                                                    _3540 = false;
                                                    _3542 = p.fieldOrigin.data[0].w;
                                                    int _3626 = 0;
                                                    for (;;)
                                                    {
                                                        bool _3638_ladder_break = false;
                                                        {
                                                            if (!(_3626 < int(p.fieldMisc.x + 0.5)))
                                                            {
                                                                _3638_ladder_break = true;
                                                            }
                                                            else
                                                            {
                                                                vec3 _3656 = (_3595 - p.fieldOrigin.data[_3626].xyz) / vec3(p.fieldOrigin.data[_3626].w);
                                                                if (any(lessThan(_3656, vec3(0.5))))
                                                                {
                                                                    _3627 = true;
                                                                }
                                                                else
                                                                {
                                                                    _3627 = any(greaterThan(_3656, vec3(float(int(p.fieldMisc.y + 0.5)) - 0.5, float(int(p.fieldMisc.y + 0.5)) - 0.5, float(int(p.fieldMisc.y + 0.5)) - 0.5)));
                                                                }
                                                                if (!(_3627))
                                                                {
                                                                    _3540 = true;
                                                                    _3542 = p.fieldOrigin.data[_3626].w;
                                                                    _3624 = true;
                                                                    _3625 = ((textureLod(_4549, vec3(_3656.x / float(int(p.fieldMisc.y + 0.5)), _3656.y / float(int(p.fieldMisc.y + 0.5)), ((float(_3626) * float(int(p.fieldMisc.y + 0.5))) + _3656.z) / float(int(p.fieldMisc.y + 0.5) * int(p.fieldMisc.x + 0.5))), 0.0).x * 2.0) - 1.0) * p.fieldRange[_3626];
                                                                    _3638_ladder_break = true;
                                                                }
                                                            }
                                                        }
                                                        if (_3638_ladder_break)
                                                        {
                                                            break;
                                                        }
                                                        _3626++;
                                                        continue;
                                                    }
                                                    if (!(_3624))
                                                    {
                                                        _3624 = true;
                                                        _3625 = 1000000.0;
                                                    }
                                                }
                                                if (!_3540)
                                                {
                                                    _3535 = true;
                                                    _3536 = 1.0;
                                                    break;
                                                }
                                                float _3749 = 2.0 * _3542;
                                                if (_3625 < ((0.5 * _3542) * clamp(_3538 / (isnan(9.9999999747524270787835121154785e-07) ? _3749 : (isnan(_3749) ? 9.9999999747524270787835121154785e-07 : max(_3749, 9.9999999747524270787835121154785e-07))), 0.0, 1.0)))
                                                {
                                                    _3535 = true;
                                                    _3536 = 0.0;
                                                    break;
                                                }
                                                float _3610 = _3542 * 0.25;
                                                _3537++;
                                                _3538 += (isnan(_3610) ? _3625 : (isnan(_3625) ? _3610 : max(_3625, _3610)));
                                                continue;
                                            }
                                            if (!(_3535))
                                            {
                                                _3535 = true;
                                                _3536 = 1.0;
                                            }
                                        }
                                    }
                                    _3507 = _3536;
                                }
                            }
                            _3311 = _3507;
                        }
                        else
                        {
                            _3311 = 1.0;
                        }
                        if (_3310 >= 1.0)
                        {
                            _3308 = true;
                            _3309 = _3311;
                        }
                        else
                        {
                            int _3312 = 0;
                            bool _3313;
                            float _3321;
                            for (;;)
                            {
                                bool _3362_ladder_break = false;
                                {
                                    if (!(_3312 < 4))
                                    {
                                        _3362_ladder_break = true;
                                    }
                                    else
                                    {
                                        if (_3312 >= _3329)
                                        {
                                            _3313 = true;
                                        }
                                        else
                                        {
                                            _3313 = _2353.z > p.cascadeSplits[_3312];
                                        }
                                        if (!(_3313))
                                        {
                                            vec4 _3387 = vec4(world, 1.0) * spvWorkaroundRowMajor(p.cascade.data[_3312]);
                                            vec3 _3391 = _3387.xyz / vec3(_3387.w);
                                            if (!(any(greaterThan(abs(_3391.xy), vec2(1.0)))))
                                            {
                                                float _3411 = ((_3391.z * 0.5) + 0.5) - p.sunColour.w;
                                                uvec3 _3413 = uvec3(textureSize(_4552, 0));
                                                vec2 _3421 = vec2(float(_3413.x), float(_3413.y));
                                                vec2 _3424 = (vec2((_3391.x * 0.5) + 0.5, 0.5 - (_3391.y * 0.5)) * _3421) - vec2(0.5);
                                                ivec2 _3426 = ivec2(floor(_3424));
                                                vec2 _3427 = fract(_3424);
                                                int _3318 = 0;
                                                float _3317 = 0.0;
                                                for (;;)
                                                {
                                                    if (!(_3318 < 2))
                                                    {
                                                        break;
                                                    }
                                                    int _3320 = 0;
                                                    float _3319 = _3317;
                                                    for (;;)
                                                    {
                                                        if (!(_3320 < 2))
                                                        {
                                                            break;
                                                        }
                                                        if (_3411 <= texelFetch(_4552, ivec4(clamp(_3426 + ivec2(_3320, _3318), ivec2(0), ivec2(_3421) - ivec2(1)), _3312, 0).xyz, 0).x)
                                                        {
                                                            _3321 = 1.0;
                                                        }
                                                        else
                                                        {
                                                            _3321 = 0.0;
                                                        }
                                                        float _3463 = _3427.x;
                                                        int _3465 = _3320;
                                                        float _3470 = _3427.y;
                                                        _3320++;
                                                        _3319 += ((_3321 * mix(1.0 - _3463, _3463, float(_3465))) * mix(1.0 - _3470, _3470, float(_3318)));
                                                        continue;
                                                    }
                                                    _3318++;
                                                    _3317 = _3319;
                                                    continue;
                                                }
                                                _3308 = true;
                                                _3309 = mix(_3317, _3311, _3310);
                                                _3362_ladder_break = true;
                                            }
                                        }
                                    }
                                }
                                if (_3362_ladder_break)
                                {
                                    break;
                                }
                                _3312++;
                                continue;
                            }
                            if (!(_3308))
                            {
                                _3308 = true;
                                _3309 = _3311;
                            }
                        }
                    }
                }
                float _1270 = dot(_677, p.sun.xyz);
                float _3777 = p.medium.w * p.medium.w;
                float _3781 = (1.0 + _3777) - ((2.0 * p.medium.w) * _1270);
                float _3789 = p.phase.x * p.phase.x;
                float _3793 = (1.0 + _3789) - ((2.0 * p.phase.x) * _1270);
                int rankedLamp[4] = int[](-1, -1, -1, -1);
                vec3 rankedLight[4] = vec3[](vec3(0.0), vec3(0.0), vec3(0.0), vec3(0.0));
                float rankedLuminance[4] = float[](0.0, 0.0, 0.0, 0.0);
                int _1326 = min(int(round(p.camera.w)), 160);
                int i = 0;
                direct = ((p.sunColour.xyz * p.march.z) * mix(mix((1.0 - _3777) / (12.56637096405029296875 * pow(isnan(9.9999997473787516355514526367188e-05) ? _3781 : (isnan(_3781) ? 9.9999997473787516355514526367188e-05 : max(_3781, 9.9999997473787516355514526367188e-05)), 1.5)), (1.0 - _3789) / (12.56637096405029296875 * pow(isnan(9.9999997473787516355514526367188e-05) ? _3793 : (isnan(_3793) ? 9.9999997473787516355514526367188e-05 : max(_3793, 9.9999997473787516355514526367188e-05)), 1.5)), p.phase.y), 0.079577468335628509521484375, p.march.y)) * _3309;
                int r;
                bool _77;
                bool _78;
                float attenuation;
                bool _3800;
                bool _3801;
                float _3936;
                bool _3937;
                vec4 _3938;
                vec3 _3939;
                int _3940;
                int _3941;
                int _3942;
                bool _3943;
                bool _3944;
                vec4 _3945;
                vec3 _3946;
                vec2 _3947;
                float _3952;
                for (;;)
                {
                    bool _92_ladder_break = false;
                    {
                        if (!(i < _1326))
                        {
                            _92_ladder_break = true;
                        }
                        else
                        {
                            vec3 toLight = p.lampPosition.data[i].xyz - _2353;
                            float _1342 = dot(toLight, toLight);
                            if (p.lampPosition.data[i].w <= 0.0)
                            {
                                _77 = true;
                            }
                            else
                            {
                                _77 = _1342 >= (p.lampPosition.data[i].w * p.lampPosition.data[i].w);
                            }
                            if (!(_77))
                            {
                                {
                                    if (p.shelter1.w < 0.5)
                                    {
                                        _3800 = false;
                                    }
                                    else
                                    {
                                        vec3 _3814 = ((vec4(p.lampPosition.data[i].xyz, 0.0) * spvWorkaroundRowMajor(p.viewToWorld)).xyz - vec3(0.0, 0.0, 1.0)) + p.cameraWorld.xyz;
                                        ivec2 _3824 = ivec2(floor((_3814.xy - p.shelter0.xy) * p.shelter0.z));
                                        int _3825 = _3824.x;
                                        if (_3825 < 0)
                                        {
                                            _3801 = true;
                                        }
                                        else
                                        {
                                            _3801 = _3824.y < 0;
                                        }
                                        if (_3801)
                                        {
                                            _3801 = true;
                                        }
                                        else
                                        {
                                            _3801 = _3825 >= int(p.shelter2.x);
                                        }
                                        if (_3801)
                                        {
                                            _3801 = true;
                                        }
                                        else
                                        {
                                            _3801 = _3824.y >= int(p.shelter2.y);
                                        }
                                        if (_3801)
                                        {
                                            _3800 = false;
                                        }
                                        else
                                        {
                                            vec4 _3857 = texelFetch(_4547, ivec3(_3824, 0).xy, 0);
                                            float _3868 = floor((_3857.z * 255.0) + 0.5) + (floor((_3857.y * 255.0) + 0.5) * 256.0);
                                            if (_3868 < 0.5)
                                            {
                                                _3800 = false;
                                            }
                                            else
                                            {
                                                float _3878 = p.shelter0.w + ((_3868 - 1.0) * p.shelter1.x);
                                                float _3879 = _3814.z;
                                                if (_3878 > (_3879 + p.shelter1.y))
                                                {
                                                    _3801 = _3878 < (_3879 + p.shelter1.z);
                                                }
                                                else
                                                {
                                                    _3801 = false;
                                                }
                                                _3800 = _3801;
                                            }
                                        }
                                    }
                                }
                                if (_3800)
                                {
                                    _78 = !_2355;
                                }
                                else
                                {
                                    _78 = false;
                                }
                                if (!(_78))
                                {
                                    float ratio = _1342 / (p.lampPosition.data[i].w * p.lampPosition.data[i].w);
                                    float _1375 = clamp(1.0 - (ratio * ratio), 0.0, 1.0);
                                    float attenuation_1 = (_1375 * _1375) / (_1342 + 1.0);
                                    vec3 direction = toLight / vec3(sqrt(isnan(9.9999999392252902907785028219223e-09) ? _1342 : (isnan(_1342) ? 9.9999999392252902907785028219223e-09 : max(_1342, 9.9999999392252902907785028219223e-09))));
                                    if (dot(p.lampDirection.data[i].xyz, p.lampDirection.data[i].xyz) > 0.25)
                                    {
                                        float _1396 = dot(normalize(p.lampDirection.data[i].xyz), -direction);
                                        attenuation = attenuation_1 * (isnan(0.0) ? _1396 : (isnan(_1396) ? 0.0 : max(_1396, 0.0)));
                                    }
                                    else
                                    {
                                        attenuation = attenuation_1;
                                    }
                                    float _1415 = dot(_677, direction);
                                    float _3913 = p.medium.w * p.medium.w;
                                    float _3917 = (1.0 + _3913) - ((2.0 * p.medium.w) * _1415);
                                    float _3925 = p.phase.x * p.phase.x;
                                    float _3929 = (1.0 + _3925) - ((2.0 * p.phase.x) * _1415);
                                    vec3 lampLight = ((p.lampColour.data[i].xyz * p.lampColour.data[i].w) * attenuation) * mix(mix((1.0 - _3913) / (12.56637096405029296875 * pow(isnan(9.9999997473787516355514526367188e-05) ? _3917 : (isnan(_3917) ? 9.9999997473787516355514526367188e-05 : max(_3917, 9.9999997473787516355514526367188e-05)), 1.5)), (1.0 - _3925) / (12.56637096405029296875 * pow(isnan(9.9999997473787516355514526367188e-05) ? _3929 : (isnan(_3929) ? 9.9999997473787516355514526367188e-05 : max(_3929, 9.9999997473787516355514526367188e-05)), 1.5)), p.phase.y), 0.079577468335628509521484375, p.march.y);
                                    {
                                        if (i < 0)
                                        {
                                            _3937 = true;
                                        }
                                        else
                                        {
                                            _3937 = i >= 160;
                                        }
                                        if (_3937)
                                        {
                                            _3936 = -1.0;
                                        }
                                        else
                                        {
                                            int _3965 = i >> 2;
                                            int _3968 = i & 3;
                                            if (uFogLampMapParams.mapSlot.data[_3965][_3968] < 0)
                                            {
                                                _3936 = -1.0;
                                            }
                                            else
                                            {
                                                int _3974 = uFogLampMapParams.mapSlot.data[_3965][_3968] & 255;
                                                if ((uFogLampMapParams.mapSlot.data[_3965][_3968] & 256) != 0)
                                                {
                                                    _3937 = false;
                                                    _3938 = vec4(0.0, 0.0, 0.0, 1.0);
                                                    _3939 = vec3(0.0);
                                                    _3940 = 0;
                                                    _3941 = _3974;
                                                    for (;;)
                                                    {
                                                        if (_3940 < 6)
                                                        {
                                                            _3943 = !_3937;
                                                        }
                                                        else
                                                        {
                                                            _3943 = false;
                                                        }
                                                        if (!_3943)
                                                        {
                                                            break;
                                                        }
                                                        int _4015 = _3941 + _3940;
                                                        vec4 _4020 = vec4(world, 1.0) * spvWorkaroundRowMajor(uFogLampMapParams.mapMatrix.data[_4015]);
                                                        float _4021 = _4020.w;
                                                        if (_4021 > 9.9999997473787516355514526367188e-05)
                                                        {
                                                            vec3 _4026 = _4020.xyz / vec3(_4021);
                                                            if (all(lessThanEqual(abs(_4026.xy), vec2(1.0))))
                                                            {
                                                                _3944 = true;
                                                                _3945 = _4020;
                                                                _3946 = _4026;
                                                                _3942 = _4015;
                                                            }
                                                            else
                                                            {
                                                                _3944 = _3937;
                                                                _3945 = _3938;
                                                                _3946 = _3939;
                                                                _3942 = _3941;
                                                            }
                                                            _3937 = _3944;
                                                            _3938 = _3945;
                                                            _3939 = _3946;
                                                            _3941 = _3942;
                                                        }
                                                        _3940++;
                                                        continue;
                                                    }
                                                    if (!_3937)
                                                    {
                                                        _3936 = -1.0;
                                                    }
                                                    else
                                                    {
                                                        int _4056 = _3941 >> 1;
                                                        if ((_3941 & 1) != 0)
                                                        {
                                                            _3947 = uFogLampMapParams.mapDepth.data[_4056].zw;
                                                        }
                                                        else
                                                        {
                                                            _3947 = uFogLampMapParams.mapDepth.data[_4056].xy;
                                                        }
                                                        float _4073 = _3947.y / ((-1.0) - _3947.x);
                                                        if (_3938.w <= _4073)
                                                        {
                                                            _3936 = 1.0;
                                                        }
                                                        else
                                                        {
                                                            float _4081 = _3938.w - (0.0500000007450580596923828125 + (0.00999999977648258209228515625 * _3938.w));
                                                            float _4082 = _4073 + 0.004999999888241291046142578125;
                                                            float _4083 = isnan(_4082) ? _4081 : (isnan(_4081) ? _4082 : max(_4081, _4082));
                                                            float _4088 = ((_3947.x + (_3947.y / (isnan(9.9999997473787516355514526367188e-05) ? _4083 : (isnan(_4083) ? 9.9999997473787516355514526367188e-05 : max(_4083, 9.9999997473787516355514526367188e-05))))) * 0.5) + 0.5;
                                                            uvec3 _4090 = uvec3(textureSize(_4555, 0));
                                                            uint _4091 = _4090.x;
                                                            uint _4092 = _4090.y;
                                                            ivec2 _4112 = ivec2(floor((vec2((_3939.x * 0.5) + 0.5, 0.5 - (_3939.y * 0.5)) * vec2(float(_4091), float(_4092))) - vec2(0.5)));
                                                            ivec2 _4119 = ivec2(int(_4091) - 1, int(_4092) - 1);
                                                            _3940 = 0;
                                                            float _3951 = 0.0;
                                                            for (;;)
                                                            {
                                                                if (!(_3940 < 2))
                                                                {
                                                                    break;
                                                                }
                                                                _3942 = 0;
                                                                for (;;)
                                                                {
                                                                    if (!(_3942 < 2))
                                                                    {
                                                                        break;
                                                                    }
                                                                    if (texelFetch(_4555, ivec4(clamp(_4112 + ivec2(_3942, _3940), ivec2(0), _4119), _3941, 0).xyz, 0).x >= _4088)
                                                                    {
                                                                        _3952 = 0.25;
                                                                    }
                                                                    else
                                                                    {
                                                                        _3952 = 0.0;
                                                                    }
                                                                    _3942++;
                                                                    _3951 += _3952;
                                                                    continue;
                                                                }
                                                                _3940++;
                                                                continue;
                                                            }
                                                            _3936 = _3951;
                                                        }
                                                    }
                                                }
                                                else
                                                {
                                                    vec4 _3983 = vec4(world, 1.0) * spvWorkaroundRowMajor(uFogLampMapParams.mapMatrix.data[_3974]);
                                                    float _3984 = _3983.w;
                                                    if (_3984 <= 9.9999997473787516355514526367188e-05)
                                                    {
                                                        _3936 = -1.0;
                                                    }
                                                    else
                                                    {
                                                        vec3 _3990 = _3983.xyz / vec3(_3984);
                                                        if (any(greaterThan(abs(_3990.xy), vec2(1.0))))
                                                        {
                                                            _3936 = -1.0;
                                                        }
                                                        else
                                                        {
                                                            _3938 = _3983;
                                                            _3939 = _3990;
                                                            _3941 = _3974;
                                                            int _4056 = _3941 >> 1;
                                                            if ((_3941 & 1) != 0)
                                                            {
                                                                _3947 = uFogLampMapParams.mapDepth.data[_4056].zw;
                                                            }
                                                            else
                                                            {
                                                                _3947 = uFogLampMapParams.mapDepth.data[_4056].xy;
                                                            }
                                                            float _4073 = _3947.y / ((-1.0) - _3947.x);
                                                            if (_3938.w <= _4073)
                                                            {
                                                                _3936 = 1.0;
                                                            }
                                                            else
                                                            {
                                                                float _4081 = _3938.w - (0.0500000007450580596923828125 + (0.00999999977648258209228515625 * _3938.w));
                                                                float _4082 = _4073 + 0.004999999888241291046142578125;
                                                                float _4083 = isnan(_4082) ? _4081 : (isnan(_4081) ? _4082 : max(_4081, _4082));
                                                                float _4088 = ((_3947.x + (_3947.y / (isnan(9.9999997473787516355514526367188e-05) ? _4083 : (isnan(_4083) ? 9.9999997473787516355514526367188e-05 : max(_4083, 9.9999997473787516355514526367188e-05))))) * 0.5) + 0.5;
                                                                uvec3 _4090 = uvec3(textureSize(_4555, 0));
                                                                uint _4091 = _4090.x;
                                                                uint _4092 = _4090.y;
                                                                ivec2 _4112 = ivec2(floor((vec2((_3939.x * 0.5) + 0.5, 0.5 - (_3939.y * 0.5)) * vec2(float(_4091), float(_4092))) - vec2(0.5)));
                                                                ivec2 _4119 = ivec2(int(_4091) - 1, int(_4092) - 1);
                                                                _3940 = 0;
                                                                float _3951 = 0.0;
                                                                for (;;)
                                                                {
                                                                    if (!(_3940 < 2))
                                                                    {
                                                                        break;
                                                                    }
                                                                    _3942 = 0;
                                                                    for (;;)
                                                                    {
                                                                        if (!(_3942 < 2))
                                                                        {
                                                                            break;
                                                                        }
                                                                        if (texelFetch(_4555, ivec4(clamp(_4112 + ivec2(_3942, _3940), ivec2(0), _4119), _3941, 0).xyz, 0).x >= _4088)
                                                                        {
                                                                            _3952 = 0.25;
                                                                        }
                                                                        else
                                                                        {
                                                                            _3952 = 0.0;
                                                                        }
                                                                        _3942++;
                                                                        _3951 += _3952;
                                                                        continue;
                                                                    }
                                                                    _3940++;
                                                                    continue;
                                                                }
                                                                _3936 = _3951;
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    if (_3936 >= 0.0)
                                    {
                                        direct += (lampLight * _3936);
                                    }
                                    else
                                    {
                                        float _1766 = dot(lampLight, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875));
                                        r = 2;
                                        int r_1 = 1;
                                        for (;;)
                                        {
                                            if (!(r_1 >= 0))
                                            {
                                                break;
                                            }
                                            if (_1766 > rankedLuminance[r_1])
                                            {
                                                r = r_1;
                                            }
                                            r_1--;
                                            continue;
                                        }
                                        if (r < 2)
                                        {
                                            int r_2 = 1;
                                            for (;;)
                                            {
                                                if (!(r_2 > r))
                                                {
                                                    break;
                                                }
                                                int _1802 = r_2 - 1;
                                                rankedLamp[r_2] = rankedLamp[_1802];
                                                rankedLight[r_2] = rankedLight[_1802];
                                                rankedLuminance[r_2] = rankedLuminance[_1802];
                                                r_2 = _1802;
                                                continue;
                                            }
                                            rankedLamp[r] = i;
                                            rankedLight[r] = lampLight;
                                            rankedLuminance[r] = _1766;
                                        }
                                        direct += lampLight;
                                    }
                                }
                            }
                        }
                    }
                    if (_92_ladder_break)
                    {
                        break;
                    }
                    i++;
                    continue;
                }
                r = 0;
                vec3 sky;
                float _4170;
                bool _4173;
                bool _4174;
                float _4176;
                float _4249;
                bool _4251;
                for (;;)
                {
                    if (!(r < 2))
                    {
                        break;
                    }
                    if (rankedLamp[r] >= 0)
                    {
                        float _1864 = clamp(p.lampDirection.data[rankedLamp[r]].w * 0.5, 0.0500000007450580596923828125, 0.20000000298023223876953125);
                        _4169 = false;
                        {
                            if (int(p.fieldMisc.x + 0.5) <= 0)
                            {
                                _4169 = true;
                                _4170 = 1.0;
                            }
                            else
                            {
                                vec3 _4197 = (vec4(p.lampPosition.data[rankedLamp[r]].xyz, 0.0) * spvWorkaroundRowMajor(p.viewToWorld)).xyz - world;
                                float _4198 = length(_4197);
                                float _4200 = _4198 - (isnan(p.fieldOrigin.data[0].w) ? _1864 : (isnan(_1864) ? p.fieldOrigin.data[0].w : max(_1864, p.fieldOrigin.data[0].w)));
                                if (_4200 <= 0.0)
                                {
                                    _4169 = true;
                                    _4170 = 1.0;
                                }
                                else
                                {
                                    vec3 _4205 = _4197 / vec3(_4198);
                                    int _4171 = 0;
                                    float _4172 = 0.0;
                                    for (;;)
                                    {
                                        if (_4171 < 48)
                                        {
                                            _4173 = _4172 < _4200;
                                        }
                                        else
                                        {
                                            _4173 = false;
                                        }
                                        if (!_4173)
                                        {
                                            break;
                                        }
                                        vec3 _4222 = world + (_4205 * _4172);
                                        _4248 = false;
                                        {
                                            _4174 = false;
                                            _4176 = p.fieldOrigin.data[0].w;
                                            int _4250 = 0;
                                            for (;;)
                                            {
                                                bool _4262_ladder_break = false;
                                                {
                                                    if (!(_4250 < int(p.fieldMisc.x + 0.5)))
                                                    {
                                                        _4262_ladder_break = true;
                                                    }
                                                    else
                                                    {
                                                        vec3 _4280 = (_4222 - p.fieldOrigin.data[_4250].xyz) / vec3(p.fieldOrigin.data[_4250].w);
                                                        if (any(lessThan(_4280, vec3(0.5))))
                                                        {
                                                            _4251 = true;
                                                        }
                                                        else
                                                        {
                                                            _4251 = any(greaterThan(_4280, vec3(float(int(p.fieldMisc.y + 0.5)) - 0.5, float(int(p.fieldMisc.y + 0.5)) - 0.5, float(int(p.fieldMisc.y + 0.5)) - 0.5)));
                                                        }
                                                        if (!(_4251))
                                                        {
                                                            _4174 = true;
                                                            _4176 = p.fieldOrigin.data[_4250].w;
                                                            _4248 = true;
                                                            _4249 = ((textureLod(_4549, vec3(_4280.x / float(int(p.fieldMisc.y + 0.5)), _4280.y / float(int(p.fieldMisc.y + 0.5)), ((float(_4250) * float(int(p.fieldMisc.y + 0.5))) + _4280.z) / float(int(p.fieldMisc.y + 0.5) * int(p.fieldMisc.x + 0.5))), 0.0).x * 2.0) - 1.0) * p.fieldRange[_4250];
                                                            _4262_ladder_break = true;
                                                        }
                                                    }
                                                }
                                                if (_4262_ladder_break)
                                                {
                                                    break;
                                                }
                                                _4250++;
                                                continue;
                                            }
                                            if (!(_4248))
                                            {
                                                _4248 = true;
                                                _4249 = 1000000.0;
                                            }
                                        }
                                        if (!_4174)
                                        {
                                            _4169 = true;
                                            _4170 = 1.0;
                                            break;
                                        }
                                        float _4373 = 2.0 * _4176;
                                        if (_4249 < ((0.5 * _4176) * clamp(_4172 / (isnan(9.9999999747524270787835121154785e-07) ? _4373 : (isnan(_4373) ? 9.9999999747524270787835121154785e-07 : max(_4373, 9.9999999747524270787835121154785e-07))), 0.0, 1.0)))
                                        {
                                            _4169 = true;
                                            _4170 = 0.0;
                                            break;
                                        }
                                        float _4234 = _4176 * 0.25;
                                        _4171++;
                                        _4172 += (isnan(_4234) ? _4249 : (isnan(_4249) ? _4234 : max(_4249, _4234)));
                                        continue;
                                    }
                                    if (!(_4169))
                                    {
                                        _4169 = true;
                                        _4170 = 1.0;
                                    }
                                }
                            }
                        }
                        sky = direct - (rankedLight[r] * (1.0 - _4170));
                    }
                    else
                    {
                        sky = direct;
                    }
                    r++;
                    direct = sky;
                    continue;
                }
                if (p.ambient.w > 0.5)
                {
                    vec3 _2003 = (-(vec4(_677, 0.0) * spvWorkaroundRowMajor(p.viewToWorld)).xyz) * p.medium.w;
                    vec4 _4384 = vec4(_2003, 1.0);
                    vec4 _4400 = _4384.xyzz * _4384.yzzx;
                    float _4418 = _2003.x;
                    float _4420 = _2003.y;
                    vec3 _4425 = (vec3(dot(texelFetch(_4558, ivec2(0), 0), _4384), dot(texelFetch(_4558, ivec2(1, 0), 0), _4384), dot(texelFetch(_4558, ivec2(2, 0), 0), _4384)) + vec3(dot(texelFetch(_4558, ivec2(3, 0), 0), _4400), dot(texelFetch(_4558, ivec2(4, 0), 0), _4400), dot(texelFetch(_4558, ivec2(5, 0), 0), _4400))) + (texelFetch(_4558, ivec2(6, 0), 0).xyz * ((_4418 * _4418) - (_4420 * _4420)));
                    bvec3 _4687 = isnan(vec3(0.0));
                    bvec3 _4688 = isnan(_4425);
                    vec3 _4689 = max(vec3(0.0), _4425);
                    vec3 _4690 = vec3(_4687.x ? _4425.x : _4689.x, _4687.y ? _4425.y : _4689.y, _4687.z ? _4425.z : _4689.z);
                    sky = vec3(_4688.x ? vec3(0.0).x : _4690.x, _4688.y ? vec3(0.0).y : _4690.y, _4688.z ? vec3(0.0).z : _4690.z);
                }
                else
                {
                    sky = p.ambient.xyz;
                }
                bvec3 _4692 = isnan(direct);
                bvec3 _4693 = isnan(vec3(0.0));
                vec3 _4694 = max(direct, vec3(0.0));
                vec3 _4695 = vec3(_4692.x ? vec3(0.0).x : _4694.x, _4692.y ? vec3(0.0).y : _4694.y, _4692.z ? vec3(0.0).z : _4694.z);
                direct = ((vec3(_4693.x ? direct.x : _4695.x, _4693.y ? direct.y : _4695.y, _4693.z ? direct.z : _4695.z) * _678) + ((sky * p.march.w) * _2450)) * p.albedo.xyz;
            }
            else
            {
                direct = vec3(0.0);
            }
            vec4 result_1 = vec4(direct, _678);
            vec4 result;
            if (p.jitter.w > 0.5)
            {
                float _4439 = (exp2((_235 + 0.5) / p.zParams.z) - p.zParams.y) / p.zParams.x;
                vec2 _4444 = (((_228 + vec2(0.5)) / p.grid.xy) * 2.0) - vec2(1.0);
                vec3 historyUvw;
                bool _4459;
                {
                    historyUvw = vec3(0.0);
                    vec4 _4471 = vec4((vec4(vec3((_4444.x * _4439) / p.unproject.x, ((-_4444.y) * _4439) / p.unproject.y, _4439), 0.0) * spvWorkaroundRowMajor(p.viewToWorld)).xyz + p.camera.xyz, 0.0) * spvWorkaroundRowMajor(p.prevWorldToView);
                    float _4473 = _4471.z;
                    if (_4473 <= p.prevUnproject.z)
                    {
                        _4459 = false;
                    }
                    else
                    {
                        float _4522 = (p.zParams.x * _4473) + p.zParams.y;
                        vec3 _4500 = vec3((vec2((_4471.x * p.prevUnproject.x) / _4473, ((-_4471.y) * p.prevUnproject.y) / _4473) * 0.5) + vec2(0.5), (p.zParams.z * log2(isnan(9.9999999747524270787835121154785e-07) ? _4522 : (isnan(_4522) ? 9.9999999747524270787835121154785e-07 : max(_4522, 9.9999999747524270787835121154785e-07)))) * p.zParams.w);
                        historyUvw = _4500;
                        bool _4460;
                        if (all(greaterThanEqual(_4500, vec3(0.0))))
                        {
                            _4460 = all(lessThanEqual(historyUvw, vec3(1.0)));
                        }
                        else
                        {
                            _4460 = false;
                        }
                        _4459 = _4460;
                    }
                }
                if (_4459)
                {
                    result = mix(result_1, textureLod(_4560, historyUvw, 0.0), vec4(p.grid.w));
                }
                else
                {
                    result = result_1;
                }
            }
            else
            {
                result = result_1;
            }
            bvec4 _4702 = isnan(result);
            bvec4 _4703 = isnan(vec4(0.0));
            vec4 _4704 = max(result, vec4(0.0));
            vec4 _4705 = vec4(_4702.x ? vec4(0.0).x : _4704.x, _4702.y ? vec4(0.0).y : _4704.y, _4702.z ? vec4(0.0).z : _4704.z, _4702.w ? vec4(0.0).w : _4704.w);
            imageStore(uScattering, ivec3(gl_GlobalInvocationID), vec4(_4703.x ? result.x : _4705.x, _4703.y ? result.y : _4705.y, _4703.z ? result.z : _4705.z, _4703.w ? result.w : _4705.w));
        }
    }
}

