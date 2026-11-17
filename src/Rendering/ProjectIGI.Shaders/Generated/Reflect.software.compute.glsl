#version 430
#if defined(GL_EXT_control_flow_attributes)
#extension GL_EXT_control_flow_attributes : require
#define SPIRV_CROSS_FLATTEN [[flatten]]
#define SPIRV_CROSS_BRANCH [[dont_flatten]]
#define SPIRV_CROSS_UNROLL [[unroll]]
#define SPIRV_CROSS_LOOP [[dont_unroll]]
#else
#define SPIRV_CROSS_FLATTEN
#define SPIRV_CROSS_BRANCH
#define SPIRV_CROSS_UNROLL
#define SPIRV_CROSS_LOOP
#endif
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

struct _Array_std140_vector_float_4_4
{
    vec4 data[4];
};

struct _Array_std140_float4
{
    float data[4];
};

uniform vec2 _1102_comp[4] = vec2[](vec2(0.0), vec2(0.430000007152557373046875, 0.709999978542327880859375), vec2(0.790000021457672119140625, 0.23999999463558197021484375), vec2(0.17000000178813934326171875, 0.4600000083446502685546875));

layout(binding = 0, std140) uniform Params_std140
{
    layout(row_major) mat4 viewToWorld;
    vec4 unproject;
    vec4 resolution;
    vec4 ssr;
    vec4 misc;
    vec4 wet0;
    vec4 wet1;
    vec4 wet2;
    vec4 shelter0;
    vec4 shelter1;
    vec4 shelter2;
    vec4 trace;
    vec4 cacheOrigin;
    vec4 cacheGrid;
    vec4 cacheAtlas;
    vec4 trace2;
    vec4 field;
    _Array_std140_vector_float_4_4 sdfOrigin;
    _Array_std140_float4 sdfRange;
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

layout(binding = 0, rgba16f) uniform restrict writeonly image2D uReflection;
layout(binding = 2) uniform sampler2D _6950;
layout(binding = 4) uniform sampler2D _6952;
layout(binding = 3) uniform sampler2D _6954;
layout(binding = 7) uniform sampler2D _6957;
layout(binding = 8) uniform sampler2D _6959;
layout(binding = 1) uniform sampler2D _6962;
layout(binding = 0) uniform sampler2D _6964;
layout(binding = 5) uniform sampler2D _6967;
layout(binding = 6) uniform sampler2D _6969;
layout(binding = 13) uniform sampler3D _6971;
layout(binding = 9) uniform sampler2D _6974;
layout(binding = 10) uniform sampler2D _6976;
layout(binding = 11) uniform sampler2D _6978;
layout(binding = 12) uniform sampler2D _6980;

mat4 spvWorkaroundRowMajor(mat4 wrap) { return wrap; }

void main()
{
    bool _5798 = false;
    bool _5640 = false;
    bool _5482 = false;
    bool _5371 = false;
    {
        ivec2 _287 = ivec2(gl_GlobalInvocationID.xy);
        bool marches;
        if (_287.x >= int(p.resolution.x))
        {
            marches = true;
        }
        else
        {
            marches = _287.y >= int(p.resolution.y);
        }
        if (!(marches))
        {
            vec2 _310 = vec2(_287);
            vec2 uv = (_310 + vec2(0.5)) * p.resolution.zw;
            bool raw = p.wet2.z > 0.5;
            vec4 _3508 = textureLod(_6950, uv, 0.0);
            float _3509 = _3508.x;
            vec4 _sampled = textureLod(_6952, uv, 0.0);
            if (_3509 <= 0.0)
            {
                marches = true;
            }
            else
            {
                marches = (int((_sampled.w * 255.0) + 0.5) & 15) == 0;
            }
            if (marches)
            {
                marches = true;
            }
            else
            {
                marches = _3509 >= 0.89999997615814208984375;
            }
            if (marches)
            {
                marches = true;
            }
            else
            {
                marches = (int((_sampled.w * 255.0) + 0.5) & 16) != 0;
            }
            if (marches)
            {
                imageStore(uReflection, ivec2(gl_GlobalInvocationID.xy), vec4(0.0));
            }
            else
            {
                bool traces = p.trace.x > 0.5;
                bool _396 = !traces;
                if (_396)
                {
                    marches = p.field.x > 0.5;
                }
                else
                {
                    marches = false;
                }
                vec3 _418 = normalize((textureLod(_6954, uv, 0.0).xyz * 2.0) - vec3(1.0));
                float roughness = _sampled.z;
                float _3546 = ((2.0 * p.unproject.z) * p.unproject.w) / ((p.unproject.w + p.unproject.z) - ((1.0 - (2.0 * _3509)) * (p.unproject.w - p.unproject.z)));
                vec2 _3523 = (uv * 2.0) - vec2(1.0);
                vec3 _3533 = vec3((_3523.x * _3546) / p.unproject.x, ((-_3523.y) * _3546) / p.unproject.y, _3546);
                vec3 _476 = normalize(_3533 * mat3(spvWorkaroundRowMajor(p.viewToWorld)[0].xyz, spvWorkaroundRowMajor(p.viewToWorld)[1].xyz, spvWorkaroundRowMajor(p.viewToWorld)[2].xyz));
                vec3 _477 = -_476;
                float _478 = dot(_418, _477);
                float _479 = isnan(0.001000000047497451305389404296875) ? _478 : (isnan(_478) ? 0.001000000047497451305389404296875 : max(_478, 0.001000000047497451305389404296875));
                vec3 _489 = _3533 * mat3(spvWorkaroundRowMajor(p.viewToWorld)[0].xyz, spvWorkaroundRowMajor(p.viewToWorld)[1].xyz, spvWorkaroundRowMajor(p.viewToWorld)[2].xyz);
                float _3558 = isnan(0.0) ? p.misc.x : (isnan(p.misc.x) ? 0.0 : max(p.misc.x, 0.0));
                bool screenAllowed;
                if (_3558 > 0.0)
                {
                    screenAllowed = _418.z > 0.86000001430511474609375;
                }
                else
                {
                    screenAllowed = false;
                }
                if (screenAllowed)
                {
                    bool _3580;
                    {
                        ivec2 _3654 = ivec2(floor(((_489.xy + p.wet1.zw) - p.shelter0.xy) * p.shelter0.z));
                        vec2 _6821 = p.shelter2.xy;
                        bool _3655;
                        if (p.wet2.x > 0.5)
                        {
                            _3655 = _3654.x >= 0;
                        }
                        else
                        {
                            _3655 = false;
                        }
                        if (_3655)
                        {
                            _3655 = _3654.y >= 0;
                        }
                        else
                        {
                            _3655 = false;
                        }
                        if (_3655)
                        {
                            _3655 = _3654.x < int(_6821.x);
                        }
                        else
                        {
                            _3655 = false;
                        }
                        if (_3655)
                        {
                            _3655 = _3654.y < int(_6821.y);
                        }
                        else
                        {
                            _3655 = false;
                        }
                        if (!_3655)
                        {
                            _3580 = false;
                        }
                        else
                        {
                            vec4 _3602 = texelFetch(_6957, ivec3(_3654, 0).xy, 0);
                            float _6825 = p.shelter0.w;
                            float _6826 = p.shelter1.x;
                            float _3705 = floor((_3602.z * 255.0) + 0.5) + (floor((_3602.y * 255.0) + 0.5) * 256.0);
                            float _3693;
                            if (_3705 < 0.5)
                            {
                                _3693 = -1000000015047466219876688855040.0;
                            }
                            else
                            {
                                _3693 = _6825 + ((_3705 - 1.0) * _6826);
                            }
                            float _3609 = _489.z + p.wet2.y;
                            float _6830 = p.shelter1.z;
                            bool _3718;
                            if (_3693 > (_3609 + p.shelter1.y))
                            {
                                _3718 = _3693 < (_3609 + _6830);
                            }
                            else
                            {
                                _3718 = false;
                            }
                            _3580 = _3718;
                        }
                    }
                    screenAllowed = !_3580;
                }
                else
                {
                    screenAllowed = false;
                }
                float puddle;
                if (screenAllowed)
                {
                    float _3747 = isnan(0.0500000007450580596923828125) ? p.wet0.y : (isnan(p.wet0.y) ? 0.0500000007450580596923828125 : max(p.wet0.y, 0.0500000007450580596923828125));
                    float _3755 = _3747 * 0.4600000083446502685546875;
                    vec2 _3780 = vec2((0.800000011920928955078125 * p.wet1.zw.x) - (0.60000002384185791015625 * p.wet1.zw.y), (0.60000002384185791015625 * p.wet1.zw.x) + (0.800000011920928955078125 * p.wet1.zw.y)) / vec2(_3755);
                    vec2 _3781 = floor(_3780);
                    float _3807 = _489.x;
                    float _3810 = _489.y;
                    vec2 _3759 = ((vec2((0.800000011920928955078125 * _3807) - (0.60000002384185791015625 * _3810), (0.60000002384185791015625 * _3807) + (0.800000011920928955078125 * _3810)) / vec2(_3755)) + (_3780 - _3781)) + vec2(11.30000019073486328125);
                    vec2 _3819 = floor(_3759);
                    vec2 _3820 = _3759 - _3819;
                    vec2 _3825 = (_3820 * _3820) * (vec2(3.0) - (_3820 * 2.0));
                    vec2 _3826 = _3819 + _3781;
                    uvec2 _3844 = uvec2(ivec2(_3826) + ivec2(1048576));
                    uint _3849 = (_3844.x * 73856093u) ^ (_3844.y * 19349663u);
                    uint _3852 = (_3849 ^ (_3849 >> uint(13))) * 1540483477u;
                    uvec2 _3863 = uvec2(ivec2(_3826 + vec2(1.0, 0.0)) + ivec2(1048576));
                    uint _3868 = (_3863.x * 73856093u) ^ (_3863.y * 19349663u);
                    uint _3871 = (_3868 ^ (_3868 >> uint(13))) * 1540483477u;
                    uvec2 _3882 = uvec2(ivec2(_3826 + vec2(0.0, 1.0)) + ivec2(1048576));
                    uint _3887 = (_3882.x * 73856093u) ^ (_3882.y * 19349663u);
                    uint _3890 = (_3887 ^ (_3887 >> uint(13))) * 1540483477u;
                    uvec2 _3901 = uvec2(ivec2(_3826 + vec2(1.0)) + ivec2(1048576));
                    uint _3906 = (_3901.x * 73856093u) ^ (_3901.y * 19349663u);
                    uint _3909 = (_3906 ^ (_3906 >> uint(13))) * 1540483477u;
                    float _3834 = _3825.x;
                    float _3838 = mix(mix(float((_3852 ^ (_3852 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, float((_3871 ^ (_3871 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, _3834), mix(float((_3890 ^ (_3890 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, float((_3909 ^ (_3909 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, _3834), _3825.y);
                    vec2 _3925 = p.wet1.zw / vec2(_3747);
                    vec2 _3926 = floor(_3925);
                    vec2 _3767 = ((vec2(_489.xy) / vec2(_3747)) + (_3925 - _3926)) + vec2((_3838 - 0.5) * 0.4000000059604644775390625);
                    vec2 _3964 = floor(_3767);
                    vec2 _3965 = _3767 - _3964;
                    vec2 _3970 = (_3965 * _3965) * (vec2(3.0) - (_3965 * 2.0));
                    vec2 _3971 = _3964 + _3926;
                    uvec2 _3989 = uvec2(ivec2(_3971) + ivec2(1048576));
                    uint _3994 = (_3989.x * 73856093u) ^ (_3989.y * 19349663u);
                    uint _3997 = (_3994 ^ (_3994 >> uint(13))) * 1540483477u;
                    uvec2 _4008 = uvec2(ivec2(_3971 + vec2(1.0, 0.0)) + ivec2(1048576));
                    uint _4013 = (_4008.x * 73856093u) ^ (_4008.y * 19349663u);
                    uint _4016 = (_4013 ^ (_4013 >> uint(13))) * 1540483477u;
                    uvec2 _4027 = uvec2(ivec2(_3971 + vec2(0.0, 1.0)) + ivec2(1048576));
                    uint _4032 = (_4027.x * 73856093u) ^ (_4027.y * 19349663u);
                    uint _4035 = (_4032 ^ (_4032 >> uint(13))) * 1540483477u;
                    uvec2 _4046 = uvec2(ivec2(_3971 + vec2(1.0)) + ivec2(1048576));
                    uint _4051 = (_4046.x * 73856093u) ^ (_4046.y * 19349663u);
                    uint _4054 = (_4051 ^ (_4051 >> uint(13))) * 1540483477u;
                    float _3979 = _3970.x;
                    puddle = (clamp((clamp(p.wet0.x, 0.0, 1.0) - ((mix(mix(float((_3997 ^ (_3997 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, float((_4016 ^ (_4016 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, _3979), mix(float((_4035 ^ (_4035 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, float((_4054 ^ (_4054 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, _3979), _3970.y) * 0.64999997615814208984375) + (_3838 * 0.3499999940395355224609375))) * 20.0, 0.0, 1.0) * clamp((_418.z - 0.86000001430511474609375) * 12.0, 0.0, 1.0)) * _3558;
                }
                else
                {
                    puddle = 0.0;
                }
                float _970 = puddle;
                bool water = _970 > 0.00999999977648258209228515625;
                float ceiling;
                float fade;
                vec2 facetNoise;
                vec3 up;
                vec3 normalW;
                if (water)
                {
                    vec2 _6883 = p.wet1.zw;
                    float _6886 = p.wet1.y;
                    float _4193 = isnan(0.0199999995529651641845703125) ? p.wet1.x : (isnan(p.wet1.x) ? 0.0199999995529651641845703125 : max(p.wet1.x, 0.0199999995529651641845703125));
                    float _4196 = p.wet0.w * 0.60000002384185791015625;
                    int _4230 = 0;
                    vec2 _4231 = vec2(0.0);
                    vec2 _4334;
                    vec2 _4339;
                    SPIRV_CROSS_UNROLL
                    for (;;)
                    {
                        bool _4241_ladder_break = false;
                        {
                            if (!(_4230 < 4))
                            {
                                _4241_ladder_break = true;
                            }
                            else
                            {
                                vec4 _4232 = vec4(0.0, 0.2199999988079071044921875, 0.439999997615814208984375, 0.660000026226043701171875);
                                float _4252 = clamp((p.wet0.z - _4232[_4230]) * 4.0, 0.0, 1.0);
                                if (!(_4252 <= 0.0))
                                {
                                    vec4 _4233 = vec4(0.519999980926513671875, 0.7400000095367431640625, 0.9700000286102294921875, 1.2799999713897705078125);
                                    float _4259 = _4193 * _4233[_4230];
                                    vec2 _4296 = _6883 / vec2(_4259);
                                    vec2 _4297 = floor(_4296);
                                    vec4 _4234 = vec4(0.959999978542327880859375, 0.810000002384185791015625, 0.88999998569488525390625, 0.7200000286102294921875);
                                    vec4 _4235 = vec4(0.0, 0.310000002384185791015625, 0.579999983310699462890625, 0.829999983310699462890625);
                                    float _4269 = fract((_4196 * _4234[_4230]) + _4235[_4230]);
                                    vec2 _4274 = ((vec2(_489.xy) / vec2(_4259)) + (_4296 - _4297)) + _1102_comp[_4230];
                                    {
                                        if (_4252 <= 0.0)
                                        {
                                            _4334 = vec2(0.0);
                                        }
                                        else
                                        {
                                            float _4347 = mix(0.20000000298023223876953125, 1.0, clamp(_4252, 0.0, 1.0));
                                            vec2 _4350 = floor(_4274 - vec2(0.5));
                                            int _4335 = 0;
                                            vec2 _4336 = vec2(0.0);
                                            for (;;)
                                            {
                                                if (!(_4335 < 2))
                                                {
                                                    break;
                                                }
                                                int _4337 = 0;
                                                vec2 _4338 = _4336;
                                                for (;;)
                                                {
                                                    bool _4362_ladder_break = false;
                                                    {
                                                        if (!(_4337 < 2))
                                                        {
                                                            _4362_ladder_break = true;
                                                        }
                                                        else
                                                        {
                                                            vec2 _4373 = _4350 + vec2(float(_4337), float(_4335));
                                                            vec2 _4376 = _4274 - (_4373 + vec2(0.5));
                                                            if (!(dot(_4376, _4376) > 0.608399927616119384765625))
                                                            {
                                                                uvec2 _4436 = uvec2(ivec2(_4373 + _4297) + ivec2(1048576));
                                                                uint _4441 = (_4436.x * 73856093u) ^ (_4436.y * 19349663u);
                                                                uint _4444 = (_4441 ^ (_4441 >> uint(13))) * 1540483477u;
                                                                uint _4446 = _4444 ^ (_4444 >> uint(15));
                                                                uint _4447 = _4446 * 668265261u;
                                                                uint _4449 = _4447 ^ (_4447 >> uint(15));
                                                                uint _4450 = _4449 * 2246822507u;
                                                                vec3 _4460 = vec3(float(_4446 & 16777215u), float(_4449 & 16777215u), float((_4450 ^ (_4450 >> uint(13))) & 16777215u)) * 5.9604651880817982601001858711243e-08;
                                                                float _4385 = fract(_4269 + _4460.x);
                                                                vec2 _4390 = _4376 - ((_4460.yz - vec2(0.5)) * 0.5);
                                                                float _4391 = length(_4390);
                                                                if (_4391 > 9.9999997473787516355514526367188e-06)
                                                                {
                                                                    _4339 = _4390 / vec2(_4391);
                                                                }
                                                                else
                                                                {
                                                                    _4339 = vec2(0.0);
                                                                }
                                                                _4338 -= (_4339 * ((sin(3.1415927410125732421875 * clamp((_4385 - clamp(_4391 * 2.17391300201416015625, 0.0, 1.0)) * 24.0, 0.0, 4.0)) * clamp(_4347 - _4385, 0.0, 1.0)) * 0.449999988079071044921875));
                                                            }
                                                        }
                                                    }
                                                    if (_4362_ladder_break)
                                                    {
                                                        break;
                                                    }
                                                    _4337++;
                                                    continue;
                                                }
                                                _4335++;
                                                _4336 = _4338;
                                                continue;
                                            }
                                            _4334 = _4336;
                                        }
                                    }
                                    _4231 += _4334;
                                }
                            }
                        }
                        if (_4241_ladder_break)
                        {
                            break;
                        }
                        _4230++;
                        continue;
                    }
                    vec2 _4488 = _6883 * vec2(0.5555555820465087890625);
                    vec2 _4489 = floor(_4488);
                    vec2 _4468 = ((vec2(_489.xy) * vec2(0.5555555820465087890625)) + (_4488 - _4489)) + vec2(p.wet0.w * 0.07999999821186065673828125, p.wet0.w * 0.0500000007450580596923828125);
                    vec2 _4527 = floor(_4468);
                    vec2 _4528 = _4468 - _4527;
                    vec2 _4533 = (_4528 * _4528) * (vec2(3.0) - (_4528 * 2.0));
                    vec2 _4534 = _4527 + _4489;
                    uvec2 _4552 = uvec2(ivec2(_4534) + ivec2(1048576));
                    uint _4557 = (_4552.x * 73856093u) ^ (_4552.y * 19349663u);
                    uint _4560 = (_4557 ^ (_4557 >> uint(13))) * 1540483477u;
                    uvec2 _4571 = uvec2(ivec2(_4534 + vec2(1.0, 0.0)) + ivec2(1048576));
                    uint _4576 = (_4571.x * 73856093u) ^ (_4571.y * 19349663u);
                    uint _4579 = (_4576 ^ (_4576 >> uint(13))) * 1540483477u;
                    uvec2 _4590 = uvec2(ivec2(_4534 + vec2(0.0, 1.0)) + ivec2(1048576));
                    uint _4595 = (_4590.x * 73856093u) ^ (_4590.y * 19349663u);
                    uint _4598 = (_4595 ^ (_4595 >> uint(13))) * 1540483477u;
                    uvec2 _4609 = uvec2(ivec2(_4534 + vec2(1.0)) + ivec2(1048576));
                    uint _4614 = (_4609.x * 73856093u) ^ (_4609.y * 19349663u);
                    uint _4617 = (_4614 ^ (_4614 >> uint(13))) * 1540483477u;
                    float _4542 = _4533.x;
                    float _4546 = mix(mix(float((_4560 ^ (_4560 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, float((_4579 ^ (_4579 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, _4542), mix(float((_4598 ^ (_4598 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, float((_4617 ^ (_4617 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, _4542), _4533.y);
                    vec2 _4471 = _4468 + vec2(0.1500000059604644775390625, 0.0);
                    vec2 _4625 = floor(_4471);
                    vec2 _4626 = _4471 - _4625;
                    vec2 _4631 = (_4626 * _4626) * (vec2(3.0) - (_4626 * 2.0));
                    vec2 _4632 = _4625 + _4489;
                    uvec2 _4650 = uvec2(ivec2(_4632) + ivec2(1048576));
                    uint _4655 = (_4650.x * 73856093u) ^ (_4650.y * 19349663u);
                    uint _4658 = (_4655 ^ (_4655 >> uint(13))) * 1540483477u;
                    uvec2 _4669 = uvec2(ivec2(_4632 + vec2(1.0, 0.0)) + ivec2(1048576));
                    uint _4674 = (_4669.x * 73856093u) ^ (_4669.y * 19349663u);
                    uint _4677 = (_4674 ^ (_4674 >> uint(13))) * 1540483477u;
                    uvec2 _4688 = uvec2(ivec2(_4632 + vec2(0.0, 1.0)) + ivec2(1048576));
                    uint _4693 = (_4688.x * 73856093u) ^ (_4688.y * 19349663u);
                    uint _4696 = (_4693 ^ (_4693 >> uint(13))) * 1540483477u;
                    uvec2 _4707 = uvec2(ivec2(_4632 + vec2(1.0)) + ivec2(1048576));
                    uint _4712 = (_4707.x * 73856093u) ^ (_4707.y * 19349663u);
                    uint _4715 = (_4712 ^ (_4712 >> uint(13))) * 1540483477u;
                    float _4640 = _4631.x;
                    vec2 _4474 = _4468 + vec2(0.0, 0.1500000059604644775390625);
                    vec2 _4723 = floor(_4474);
                    vec2 _4724 = _4474 - _4723;
                    vec2 _4729 = (_4724 * _4724) * (vec2(3.0) - (_4724 * 2.0));
                    vec2 _4730 = _4723 + _4489;
                    uvec2 _4748 = uvec2(ivec2(_4730) + ivec2(1048576));
                    uint _4753 = (_4748.x * 73856093u) ^ (_4748.y * 19349663u);
                    uint _4756 = (_4753 ^ (_4753 >> uint(13))) * 1540483477u;
                    uvec2 _4767 = uvec2(ivec2(_4730 + vec2(1.0, 0.0)) + ivec2(1048576));
                    uint _4772 = (_4767.x * 73856093u) ^ (_4767.y * 19349663u);
                    uint _4775 = (_4772 ^ (_4772 >> uint(13))) * 1540483477u;
                    uvec2 _4786 = uvec2(ivec2(_4730 + vec2(0.0, 1.0)) + ivec2(1048576));
                    uint _4791 = (_4786.x * 73856093u) ^ (_4786.y * 19349663u);
                    uint _4794 = (_4791 ^ (_4791 >> uint(13))) * 1540483477u;
                    uvec2 _4805 = uvec2(ivec2(_4730 + vec2(1.0)) + ivec2(1048576));
                    uint _4810 = (_4805.x * 73856093u) ^ (_4805.y * 19349663u);
                    uint _4813 = (_4810 ^ (_4810 >> uint(13))) * 1540483477u;
                    float _4738 = _4729.x;
                    vec2 _4204 = (vec2(mix(mix(float((_4658 ^ (_4658 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, float((_4677 ^ (_4677 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, _4640), mix(float((_4696 ^ (_4696 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, float((_4715 ^ (_4715 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, _4640), _4631.y) - _4546, mix(mix(float((_4756 ^ (_4756 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, float((_4775 ^ (_4775 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, _4738), mix(float((_4794 ^ (_4794 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, float((_4813 ^ (_4813 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, _4738), _4729.y) - _4546) * _6886) * 1.60000002384185791015625;
                    float _4208 = clamp(((abs((2.0 * p.resolution.z) * _3533.z) / (isnan(9.9999997473787516355514526367188e-05) ? p.unproject.x : (isnan(p.unproject.x) ? 9.9999997473787516355514526367188e-05 : max(p.unproject.x, 9.9999997473787516355514526367188e-05)))) / (isnan(0.07999999821186065673828125) ? _479 : (isnan(_479) ? 0.07999999821186065673828125 : max(_479, 0.07999999821186065673828125)))) / (_4193 * 0.5), 0.0, 1.0);
                    vec3 _1367 = normalize(mix(_418, normalize(vec3((_4231 + _4204) * (1.0 - _4208), 1.0)), vec3(puddle)));
                    float _4823 = 1.0 - clamp(dot(_1367, _477), 0.0, 1.0);
                    float _4824 = _4823 * _4823;
                    up = vec3(((0.0199999995529651641845703125 + (((0.980000019073486328125 * _4824) * _4824) * _4823)) * puddle) * clamp(1.0 - (_4208 * 2.0), 0.0, 1.0));
                    normalW = _1367;
                    screenAllowed = true;
                    float _1709 = isnan(up.z) ? up.y : (isnan(up.y) ? up.z : max(up.y, up.z));
                    if ((isnan(_1709) ? up.x : (isnan(up.x) ? _1709 : max(up.x, _1709))) <= 0.0030000000260770320892333984375)
                    {
                        imageStore(uReflection, ivec2(gl_GlobalInvocationID.xy), vec4(0.0));
                    }
                    else
                    {
                        vec3 _1732 = reflect(normalize(_3533), normalize(normalW * transpose(mat3(spvWorkaroundRowMajor(p.viewToWorld)[0].xyz, spvWorkaroundRowMajor(p.viewToWorld)[1].xyz, spvWorkaroundRowMajor(p.viewToWorld)[2].xyz))));
                        bool have;
                        if (_396)
                        {
                            have = _1732.z > 0.0;
                        }
                        else
                        {
                            have = false;
                        }
                        if (!have)
                        {
                            screenAllowed = false;
                        }
                        int _1749 = max(int(p.ssr.x + 0.5), 1);
                        vec2 _4835 = _310 + (vec2(12.0780429840087890625, 9.1174449920654296875) * p.misc.y);
                        have = false;
                        ceiling = -1.0;
                        vec3 previous = _3533;
                        int i = 0;
                        fade = 0.20000000298023223876953125 * (0.5 + fract(52.98291778564453125 * fract((0.067110560834407806396484375 * _4835.x) + (0.005837149918079376220703125 * _4835.y))));
                        bool crossed;
                        float hitEdge;
                        vec3 a;
                        vec3 b;
                        bool met;
                        bool _95;
                        float _5010;
                        for (;;)
                        {
                            vec3 pv;
                            float t;
                            bool _175_ladder_break = false;
                            {
                                if (screenAllowed)
                                {
                                    crossed = i < _1749;
                                }
                                else
                                {
                                    crossed = false;
                                }
                                if (!crossed)
                                {
                                    hitEdge = 0.0;
                                    facetNoise = vec2(0.0);
                                    _175_ladder_break = true;
                                }
                                else
                                {
                                    pv = _3533 + (_1732 * fade);
                                    if (pv.z <= p.unproject.z)
                                    {
                                        met = true;
                                    }
                                    else
                                    {
                                        met = fade > p.misc.z;
                                    }
                                    if (met)
                                    {
                                        hitEdge = 0.0;
                                        facetNoise = vec2(0.0);
                                        _175_ladder_break = true;
                                    }
                                    else
                                    {
                                        float _1801 = fade * 0.07999999821186065673828125;
                                        t = fade + (isnan(_1801) ? 0.20000000298023223876953125 : (isnan(0.20000000298023223876953125) ? _1801 : max(0.20000000298023223876953125, _1801)));
                                        vec2 _4865 = (vec2((pv.x * p.unproject.x) / pv.z, ((-pv.y) * p.unproject.y) / pv.z) * 0.5) + vec2(0.5);
                                        if (any(lessThan(_4865, vec2(0.0))))
                                        {
                                            _95 = true;
                                        }
                                        else
                                        {
                                            _95 = any(greaterThan(_4865, vec2(1.0)));
                                        }
                                        if (_95)
                                        {
                                            hitEdge = 0.0;
                                            facetNoise = vec2(0.0);
                                            _175_ladder_break = true;
                                        }
                                        else
                                        {
                                            uvec2 _4871 = uvec2(textureSize(_6962, 0));
                                            uint _4872 = _4871.x;
                                            uint _4873 = _4871.y;
                                            vec4 _4892 = texelFetch(_6962, ivec3(clamp(ivec2(_4865 * vec2(float(_4872), float(_4873))), ivec2(0), ivec2(int(_4872) - 1, int(_4873) - 1)), 0).xy, 0);
                                            float _4893 = _4892.x;
                                            if (_4893 <= 0.0)
                                            {
                                                ceiling = -1.0;
                                            }
                                            else
                                            {
                                                float diff = pv.z - (((2.0 * p.unproject.z) * p.unproject.w) / ((p.unproject.w + p.unproject.z) - ((1.0 - (2.0 * _4893)) * (p.unproject.w - p.unproject.z))));
                                                if (diff > 0.0)
                                                {
                                                    float _1914 = pv.z * 0.0500000007450580596923828125;
                                                    float _1915 = isnan(_1914) ? p.ssr.w : (isnan(p.ssr.w) ? _1914 : max(p.ssr.w, _1914));
                                                    if (have)
                                                    {
                                                        crossed = ceiling < 0.0;
                                                    }
                                                    else
                                                    {
                                                        crossed = false;
                                                    }
                                                    if (crossed)
                                                    {
                                                        screenAllowed = true;
                                                    }
                                                    else
                                                    {
                                                        screenAllowed = diff < _1915;
                                                    }
                                                    if (screenAllowed)
                                                    {
                                                        a = previous;
                                                        b = pv;
                                                        int k = 0;
                                                        for (;;)
                                                        {
                                                            if (!(k < 5))
                                                            {
                                                                break;
                                                            }
                                                            vec3 _1941 = b;
                                                            vec3 mid = (a + _1941) * 0.5;
                                                            float _4925 = mid.z;
                                                            uvec2 _4942 = uvec2(textureSize(_6962, 0));
                                                            uint _4943 = _4942.x;
                                                            uint _4944 = _4942.y;
                                                            vec4 _4963 = texelFetch(_6962, ivec3(clamp(ivec2(((vec2((mid.x * p.unproject.x) / _4925, ((-mid.y) * p.unproject.y) / _4925) * 0.5) + vec2(0.5)) * vec2(float(_4943), float(_4944))), ivec2(0), ivec2(int(_4943) - 1, int(_4944) - 1)), 0).xy, 0);
                                                            float _4964 = _4963.x;
                                                            if (_4964 > 0.0)
                                                            {
                                                                screenAllowed = (mid.z - (((2.0 * p.unproject.z) * p.unproject.w) / ((p.unproject.w + p.unproject.z) - ((1.0 - (2.0 * _4964)) * (p.unproject.w - p.unproject.z))))) > 0.0;
                                                            }
                                                            else
                                                            {
                                                                screenAllowed = false;
                                                            }
                                                            if (screenAllowed)
                                                            {
                                                                b = mid;
                                                            }
                                                            else
                                                            {
                                                                a = mid;
                                                            }
                                                            k++;
                                                            continue;
                                                        }
                                                        vec2 _5007 = (vec2((b.x * p.unproject.x) / b.z, ((-b.y) * p.unproject.y) / b.z) * 0.5) + vec2(0.5);
                                                        uvec2 _5014 = uvec2(textureSize(_6962, 0));
                                                        uint _5015 = _5014.x;
                                                        uint _5016 = _5014.y;
                                                        vec4 _5035 = texelFetch(_6962, ivec3(clamp(ivec2(_5007 * vec2(float(_5015), float(_5016))), ivec2(0), ivec2(int(_5015) - 1, int(_5016) - 1)), 0).xy, 0);
                                                        float _5036 = _5035.x;
                                                        if (_5036 > 0.0)
                                                        {
                                                            _5010 = ((2.0 * p.unproject.z) * p.unproject.w) / ((p.unproject.w + p.unproject.z) - ((1.0 - (2.0 * _5036)) * (p.unproject.w - p.unproject.z)));
                                                        }
                                                        else
                                                        {
                                                            _5010 = 0.0;
                                                        }
                                                        if (_5010 > 0.0)
                                                        {
                                                            met = (b.z - _5010) < _1915;
                                                        }
                                                        else
                                                        {
                                                            met = false;
                                                        }
                                                        vec2 _2034 = clamp((abs((_5007 * 2.0) - vec2(1.0)) * 5.0) - vec2(4.0), vec2(0.0), vec2(1.0));
                                                        if (met)
                                                        {
                                                            puddle = clamp(1.0 - dot(_2034, _2034), 0.0, 1.0);
                                                        }
                                                        else
                                                        {
                                                            puddle = 0.0;
                                                        }
                                                        hitEdge = puddle;
                                                        facetNoise = _5007;
                                                    }
                                                    else
                                                    {
                                                        hitEdge = 0.0;
                                                        facetNoise = vec2(0.0);
                                                    }
                                                    _175_ladder_break = true;
                                                }
                                                else
                                                {
                                                    ceiling = diff;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            if (_175_ladder_break)
                            {
                                break;
                            }
                            have = true;
                            previous = pv;
                            i++;
                            fade = t;
                            continue;
                        }
                        float screenWeight;
                        if (hitEdge > 0.0)
                        {
                            vec4 _sampled_1 = textureLod(_6964, facetNoise, 0.0);
                            vec3 _2077 = _sampled_1.xyz;
                            bvec3 _7057 = isnan(_2077);
                            bvec3 _7058 = isnan(vec3(0.0));
                            vec3 _7059 = max(_2077, vec3(0.0));
                            vec3 _7060 = vec3(_7057.x ? vec3(0.0).x : _7059.x, _7057.y ? vec3(0.0).y : _7059.y, _7057.z ? vec3(0.0).z : _7059.z);
                            if (water)
                            {
                                puddle = 1.0;
                            }
                            else
                            {
                                puddle = p.ssr.y;
                            }
                            if (water)
                            {
                                vec3 _2092 = normalize(reflect(_476, normalW));
                                float _5076 = (p.misc.w * p.misc.w) - 40449600.0;
                                float _5081 = acos(clamp(sqrt(isnan(_5076) ? 0.0 : (isnan(0.0) ? _5076 : max(0.0, _5076))) / p.misc.w, -1.0, 1.0));
                                float _5082 = 3.1415927410125732421875 - _5081;
                                float _5085 = acos(clamp(_2092.z, -1.0, 1.0));
                                float _5071;
                                if (_5085 < _5082)
                                {
                                    float _5097 = 1.0 - (_5085 / _5082);
                                    _5071 = (1.0 - sqrt(isnan(_5097) ? 0.0 : (isnan(0.0) ? _5097 : max(0.0, _5097)))) * 0.5;
                                }
                                else
                                {
                                    float _5090 = (_5085 - _5082) / (isnan(9.9999999747524270787835121154785e-07) ? _5081 : (isnan(_5081) ? 9.9999999747524270787835121154785e-07 : max(_5081, 9.9999999747524270787835121154785e-07)));
                                    _5071 = (sqrt(isnan(_5090) ? 0.0 : (isnan(0.0) ? _5090 : max(0.0, _5090))) * 0.5) + 0.5;
                                }
                                float _5105 = atan(_2092.y, _2092.x);
                                float _5072;
                                if (_5105 < 0.0)
                                {
                                    _5072 = _5105 + 6.283185482025146484375;
                                }
                                else
                                {
                                    _5072 = _5105;
                                }
                                uvec2 _5120 = uvec2(textureSize(_6967, 0));
                                vec2 _5127 = vec2(float(_5120.x), float(_5120.y));
                                a = textureLod(_6969, (vec2(_5072 * 0.15915493667125701904296875, _5071) * ((_5127 - vec2(1.0)) / _5127)) + (vec2(0.5) / _5127), 0.0).xyz * clamp(_2092.z * 20.0, 0.0, 1.0);
                            }
                            else
                            {
                                a = vec3(0.0);
                            }
                            float screenWeight_1 = hitEdge * step(0.5, _sampled_1.w);
                            screenWeight = screenWeight_1;
                            a = (((vec3(_7058.x ? _2077.x : _7060.x, _7058.y ? _2077.y : _7060.y, _7058.z ? _2077.z : _7060.z) * puddle) - a) * up) * screenWeight_1;
                        }
                        else
                        {
                            screenWeight = 0.0;
                            a = vec3(0.0);
                        }
                        if (marches)
                        {
                            screenAllowed = screenWeight < 0.999000012874603271484375;
                        }
                        else
                        {
                            screenAllowed = false;
                        }
                        if (screenAllowed)
                        {
                            vec3 _2237 = normalW;
                            vec3 _2239 = normalize(reflect(_476, _2237));
                            vec3 originRelative = _489 + (_2237 * (0.0199999995529651641845703125 + (0.0005000000237487256526947021484375 * _3533.z)));
                            vec2 _2252 = _489.xy + p.wet1.zw;
                            float _2256 = _489.z + p.wet2.y;
                            vec2 _6893 = p.shelter0.xy;
                            float _6894 = p.shelter0.z;
                            float _6895 = p.shelter0.w;
                            float _6896 = p.shelter1.x;
                            float _6897 = p.shelter1.y;
                            vec2 _6898 = p.shelter2.xy;
                            float _6899 = p.wet2.x;
                            bool _5181;
                            {
                                ivec2 _5234 = ivec2(floor((_2252 - _6893) * _6894));
                                bool _5235;
                                if (_6899 > 0.5)
                                {
                                    _5235 = _5234.x >= 0;
                                }
                                else
                                {
                                    _5235 = false;
                                }
                                if (_5235)
                                {
                                    _5235 = _5234.y >= 0;
                                }
                                else
                                {
                                    _5235 = false;
                                }
                                if (_5235)
                                {
                                    _5235 = _5234.x < int(_6898.x);
                                }
                                else
                                {
                                    _5235 = false;
                                }
                                if (_5235)
                                {
                                    _5235 = _5234.y < int(_6898.y);
                                }
                                else
                                {
                                    _5235 = false;
                                }
                                if (!_5235)
                                {
                                    _5181 = false;
                                }
                                else
                                {
                                    vec4 _5193 = texelFetch(_6957, ivec3(_5234, 0).xy, 0);
                                    float _5285 = floor((_5193.z * 255.0) + 0.5) + (floor((_5193.y * 255.0) + 0.5) * 256.0);
                                    float _5273;
                                    if (_5285 < 0.5)
                                    {
                                        _5273 = -1000000015047466219876688855040.0;
                                    }
                                    else
                                    {
                                        _5273 = _6895 + ((_5285 - 1.0) * _6896);
                                    }
                                    float _5198 = _2256 + _6897;
                                    if (_5273 <= _5198)
                                    {
                                        _5181 = false;
                                    }
                                    else
                                    {
                                        float _5202 = _2239.z;
                                        if (_5202 <= 0.0500000007450580596923828125)
                                        {
                                            _5181 = false;
                                        }
                                        else
                                        {
                                            ivec2 _5307 = ivec2(floor(((_2252 + (_2239.xy * ((_5273 - _2256) / _5202))) - _6893) * _6894));
                                            bool _5308;
                                            if (_6899 > 0.5)
                                            {
                                                _5308 = _5307.x >= 0;
                                            }
                                            else
                                            {
                                                _5308 = false;
                                            }
                                            if (_5308)
                                            {
                                                _5308 = _5307.y >= 0;
                                            }
                                            else
                                            {
                                                _5308 = false;
                                            }
                                            if (_5308)
                                            {
                                                _5308 = _5307.x < int(_6898.x);
                                            }
                                            else
                                            {
                                                _5308 = false;
                                            }
                                            if (_5308)
                                            {
                                                _5308 = _5307.y < int(_6898.y);
                                            }
                                            else
                                            {
                                                _5308 = false;
                                            }
                                            if (!_5308)
                                            {
                                                _5181 = false;
                                            }
                                            else
                                            {
                                                vec4 _5219 = texelFetch(_6957, ivec3(_5307, 0).xy, 0);
                                                float _5358 = floor((_5219.z * 255.0) + 0.5) + (floor((_5219.y * 255.0) + 0.5) * 256.0);
                                                float _5346;
                                                if (_5358 < 0.5)
                                                {
                                                    _5346 = -1000000015047466219876688855040.0;
                                                }
                                                else
                                                {
                                                    _5346 = _6895 + ((_5358 - 1.0) * _6896);
                                                }
                                                _5181 = _5346 > _5198;
                                            }
                                        }
                                    }
                                }
                            }
                            _5371 = false;
                            vec3 hitRelative;
                            float voxel;
                            bool _5372;
                            {
                                hitRelative = originRelative;
                                voxel = p.sdfOrigin.data[0].w;
                                if (int(p.field.x) <= 0)
                                {
                                    _5371 = true;
                                    _5372 = false;
                                }
                                else
                                {
                                    vec3 _5403 = originRelative + ((normalW * p.sdfOrigin.data[0].w) * 1.5);
                                    bool _5373 = false;
                                    float _5374 = 0.0;
                                    float _5375 = 0.0;
                                    int _5377 = 0;
                                    float _5376 = 0.0;
                                    bool _5378;
                                    bool _5379;
                                    float _5381;
                                    float _5382;
                                    bool _5383;
                                    float _5483;
                                    bool _5485;
                                    bool _5598;
                                    float _5600;
                                    float _5641;
                                    bool _5643;
                                    bool _5756;
                                    float _5758;
                                    float _5799;
                                    bool _5801;
                                    for (;;)
                                    {
                                        if (_5377 < 96)
                                        {
                                            _5378 = _5376 < p.trace.y;
                                        }
                                        else
                                        {
                                            _5378 = false;
                                        }
                                        if (!_5378)
                                        {
                                            break;
                                        }
                                        vec3 _5420 = _5403 + (_2239 * _5376);
                                        _5482 = false;
                                        {
                                            _5379 = false;
                                            _5381 = p.sdfOrigin.data[0].w;
                                            int _5484 = 0;
                                            for (;;)
                                            {
                                                bool _5496_ladder_break = false;
                                                {
                                                    if (!(_5484 < int(p.field.x)))
                                                    {
                                                        _5496_ladder_break = true;
                                                    }
                                                    else
                                                    {
                                                        vec3 _5513 = (_5420 - p.sdfOrigin.data[_5484].xyz) / vec3(p.sdfOrigin.data[_5484].w);
                                                        if (any(lessThan(_5513, vec3(0.5))))
                                                        {
                                                            _5485 = true;
                                                        }
                                                        else
                                                        {
                                                            _5485 = any(greaterThan(_5513, vec3(float(int(p.field.y)) - 0.5, float(int(p.field.y)) - 0.5, float(int(p.field.y)) - 0.5)));
                                                        }
                                                        if (!(_5485))
                                                        {
                                                            _5379 = true;
                                                            _5381 = p.sdfOrigin.data[_5484].w;
                                                            _5482 = true;
                                                            _5483 = ((textureLod(_6971, vec3(_5513.x / float(int(p.field.y)), _5513.y / float(int(p.field.y)), ((float(_5484) * float(int(p.field.y))) + _5513.z) / float(int(p.field.y) * int(p.field.x))), 0.0).x * 2.0) - 1.0) * p.sdfRange.data[_5484];
                                                            _5496_ladder_break = true;
                                                        }
                                                    }
                                                }
                                                if (_5496_ladder_break)
                                                {
                                                    break;
                                                }
                                                _5484++;
                                                continue;
                                            }
                                            if (!(_5482))
                                            {
                                                _5482 = true;
                                                _5483 = 1000000.0;
                                            }
                                        }
                                        if (!_5379)
                                        {
                                            _5371 = true;
                                            _5372 = false;
                                            break;
                                        }
                                        if (_5373)
                                        {
                                            if (_5483 <= 0.0)
                                            {
                                                float _5434 = _5375 - _5483;
                                                if (_5434 > 9.9999997473787516355514526367188e-06)
                                                {
                                                    _5382 = _5374 + ((_5376 - _5374) * (_5375 / _5434));
                                                }
                                                else
                                                {
                                                    _5382 = _5376;
                                                }
                                                voxel = p.sdfOrigin.data[0].w;
                                                int _5596 = 0;
                                                float _5597 = clamp(_5382, _5374, _5376);
                                                for (;;)
                                                {
                                                    if (!(_5596 < 2))
                                                    {
                                                        break;
                                                    }
                                                    vec3 _5618 = _5403 + (_2239 * _5597);
                                                    _5640 = false;
                                                    {
                                                        _5598 = false;
                                                        _5600 = p.sdfOrigin.data[0].w;
                                                        int _5642 = 0;
                                                        for (;;)
                                                        {
                                                            bool _5654_ladder_break = false;
                                                            {
                                                                if (!(_5642 < int(p.field.x)))
                                                                {
                                                                    _5654_ladder_break = true;
                                                                }
                                                                else
                                                                {
                                                                    vec3 _5671 = (_5618 - p.sdfOrigin.data[_5642].xyz) / vec3(p.sdfOrigin.data[_5642].w);
                                                                    if (any(lessThan(_5671, vec3(0.5))))
                                                                    {
                                                                        _5643 = true;
                                                                    }
                                                                    else
                                                                    {
                                                                        _5643 = any(greaterThan(_5671, vec3(float(int(p.field.y)) - 0.5, float(int(p.field.y)) - 0.5, float(int(p.field.y)) - 0.5)));
                                                                    }
                                                                    if (!(_5643))
                                                                    {
                                                                        _5598 = true;
                                                                        _5600 = p.sdfOrigin.data[_5642].w;
                                                                        _5640 = true;
                                                                        _5641 = ((textureLod(_6971, vec3(_5671.x / float(int(p.field.y)), _5671.y / float(int(p.field.y)), ((float(_5642) * float(int(p.field.y))) + _5671.z) / float(int(p.field.y) * int(p.field.x))), 0.0).x * 2.0) - 1.0) * p.sdfRange.data[_5642];
                                                                        _5654_ladder_break = true;
                                                                    }
                                                                }
                                                            }
                                                            if (_5654_ladder_break)
                                                            {
                                                                break;
                                                            }
                                                            _5642++;
                                                            continue;
                                                        }
                                                        if (!(_5640))
                                                        {
                                                            _5640 = true;
                                                            _5641 = 1000000.0;
                                                        }
                                                    }
                                                    if (!_5598)
                                                    {
                                                        break;
                                                    }
                                                    voxel = _5600;
                                                    _5596++;
                                                    _5597 += (isnan(0.0) ? _5641 : (isnan(_5641) ? 0.0 : max(_5641, 0.0)));
                                                    continue;
                                                }
                                                hitRelative = _5403 + (_2239 * (_5597 + (voxel * 0.25)));
                                                _5371 = true;
                                                _5372 = true;
                                                break;
                                            }
                                            if (_5483 > _5375)
                                            {
                                                _5383 = _5375 < (_5381 * 0.0500000007450580596923828125);
                                            }
                                            else
                                            {
                                                _5383 = false;
                                            }
                                            if (_5383)
                                            {
                                                voxel = p.sdfOrigin.data[0].w;
                                                int _5754 = 0;
                                                float _5755 = _5374;
                                                for (;;)
                                                {
                                                    if (!(_5754 < 2))
                                                    {
                                                        break;
                                                    }
                                                    vec3 _5776 = _5403 + (_2239 * _5755);
                                                    _5798 = false;
                                                    {
                                                        _5756 = false;
                                                        _5758 = p.sdfOrigin.data[0].w;
                                                        int _5800 = 0;
                                                        for (;;)
                                                        {
                                                            bool _5812_ladder_break = false;
                                                            {
                                                                if (!(_5800 < int(p.field.x)))
                                                                {
                                                                    _5812_ladder_break = true;
                                                                }
                                                                else
                                                                {
                                                                    vec3 _5829 = (_5776 - p.sdfOrigin.data[_5800].xyz) / vec3(p.sdfOrigin.data[_5800].w);
                                                                    if (any(lessThan(_5829, vec3(0.5))))
                                                                    {
                                                                        _5801 = true;
                                                                    }
                                                                    else
                                                                    {
                                                                        _5801 = any(greaterThan(_5829, vec3(float(int(p.field.y)) - 0.5, float(int(p.field.y)) - 0.5, float(int(p.field.y)) - 0.5)));
                                                                    }
                                                                    if (!(_5801))
                                                                    {
                                                                        _5756 = true;
                                                                        _5758 = p.sdfOrigin.data[_5800].w;
                                                                        _5798 = true;
                                                                        _5799 = ((textureLod(_6971, vec3(_5829.x / float(int(p.field.y)), _5829.y / float(int(p.field.y)), ((float(_5800) * float(int(p.field.y))) + _5829.z) / float(int(p.field.y) * int(p.field.x))), 0.0).x * 2.0) - 1.0) * p.sdfRange.data[_5800];
                                                                        _5812_ladder_break = true;
                                                                    }
                                                                }
                                                            }
                                                            if (_5812_ladder_break)
                                                            {
                                                                break;
                                                            }
                                                            _5800++;
                                                            continue;
                                                        }
                                                        if (!(_5798))
                                                        {
                                                            _5798 = true;
                                                            _5799 = 1000000.0;
                                                        }
                                                    }
                                                    if (!_5756)
                                                    {
                                                        break;
                                                    }
                                                    voxel = _5758;
                                                    _5754++;
                                                    _5755 += (isnan(0.0) ? _5799 : (isnan(_5799) ? 0.0 : max(_5799, 0.0)));
                                                    continue;
                                                }
                                                hitRelative = _5403 + (_2239 * (_5755 + (voxel * 0.25)));
                                                _5371 = true;
                                                _5372 = true;
                                                break;
                                            }
                                        }
                                        float _5467 = _5381 * 0.25;
                                        _5373 = true;
                                        _5374 = _5376;
                                        _5376 += (isnan(_5467) ? _5483 : (isnan(_5483) ? _5467 : max(_5483, _5467)));
                                        _5375 = _5483;
                                        _5377++;
                                        continue;
                                    }
                                    if (!(_5371))
                                    {
                                        _5371 = true;
                                        _5372 = false;
                                    }
                                }
                            }
                            vec3 radiance = vec3(0.0);
                            if (!_5372)
                            {
                                float _6485 = (p.misc.w * p.misc.w) - 40449600.0;
                                float _6490 = acos(clamp(sqrt(isnan(_6485) ? 0.0 : (isnan(0.0) ? _6485 : max(0.0, _6485))) / p.misc.w, -1.0, 1.0));
                                float _6491 = 3.1415927410125732421875 - _6490;
                                float _6494 = acos(clamp(_2239.z, -1.0, 1.0));
                                float _6480;
                                if (_6494 < _6491)
                                {
                                    float _6506 = 1.0 - (_6494 / _6491);
                                    _6480 = (1.0 - sqrt(isnan(_6506) ? 0.0 : (isnan(0.0) ? _6506 : max(0.0, _6506)))) * 0.5;
                                }
                                else
                                {
                                    float _6499 = (_6494 - _6491) / (isnan(9.9999999747524270787835121154785e-07) ? _6490 : (isnan(_6490) ? 9.9999999747524270787835121154785e-07 : max(_6490, 9.9999999747524270787835121154785e-07)));
                                    _6480 = (sqrt(isnan(_6499) ? 0.0 : (isnan(0.0) ? _6499 : max(0.0, _6499))) * 0.5) + 0.5;
                                }
                                float _6514 = atan(_2239.y, _2239.x);
                                float _6481;
                                if (_6514 < 0.0)
                                {
                                    _6481 = _6514 + 6.283185482025146484375;
                                }
                                else
                                {
                                    _6481 = _6514;
                                }
                                uvec2 _6529 = uvec2(textureSize(_6967, 0));
                                vec2 _6536 = vec2(float(_6529.x), float(_6529.y));
                                vec3 _6542 = textureLod(_6969, (vec2(_6481 * 0.15915493667125701904296875, _6480) * ((_6536 - vec2(1.0)) / _6536)) + (vec2(0.5) / _6536), 0.0).xyz;
                                if (_5181)
                                {
                                    normalW = vec3(dot(_6542, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * 0.300000011920928955078125);
                                }
                                else
                                {
                                    normalW = _6542;
                                }
                                float _6560 = clamp(textureLod(_6959, uv, 0.0).w, 0.0, 1.0);
                                radiance = normalW * clamp((pow(_479 + _6560, roughness * roughness) - 1.0) + _6560, 0.0, 1.0);
                            }
                            else
                            {
                                bool _5913;
                                {
                                    radiance = vec3(0.0);
                                    vec3 _5928 = hitRelative * transpose(mat3(spvWorkaroundRowMajor(p.viewToWorld)[0].xyz, spvWorkaroundRowMajor(p.viewToWorld)[1].xyz, spvWorkaroundRowMajor(p.viewToWorld)[2].xyz));
                                    float _5929 = _5928.z;
                                    if (_5929 <= p.unproject.z)
                                    {
                                        _5913 = false;
                                    }
                                    else
                                    {
                                        float _5988 = _5928.z;
                                        vec2 _5999 = (vec2((_5928.x * p.unproject.x) / _5988, ((-_5928.y) * p.unproject.y) / _5988) * 0.5) + vec2(0.5);
                                        bool _5914;
                                        if (any(lessThan(_5999, vec2(0.0))))
                                        {
                                            _5914 = true;
                                        }
                                        else
                                        {
                                            _5914 = any(greaterThan(_5999, vec2(1.0)));
                                        }
                                        if (_5914)
                                        {
                                            _5913 = false;
                                        }
                                        else
                                        {
                                            vec4 _5955 = texelFetch(_6962, ivec3(ivec2(_5999 * p.resolution.xy), 0).xy, 0);
                                            float _5956 = _5955.x;
                                            if (_5956 <= 0.0)
                                            {
                                                _5913 = false;
                                            }
                                            else
                                            {
                                                if (_5956 >= 0.89999997615814208984375)
                                                {
                                                    _5913 = false;
                                                }
                                                else
                                                {
                                                    float _6023 = ((2.0 * p.unproject.z) * p.unproject.w) / ((p.unproject.w + p.unproject.z) - ((1.0 - (2.0 * _5956)) * (p.unproject.w - p.unproject.z)));
                                                    if (abs(_5929 - _6023) > ((0.0199999995529651641845703125 * (isnan(1.0) ? _6023 : (isnan(_6023) ? 1.0 : max(_6023, 1.0)))) + voxel))
                                                    {
                                                        _5913 = false;
                                                    }
                                                    else
                                                    {
                                                        vec3 _5977 = textureLod(_6964, _5999, 0.0).xyz;
                                                        bvec3 _7122 = isnan(_5977);
                                                        bvec3 _7123 = isnan(vec3(0.0));
                                                        vec3 _7124 = max(_5977, vec3(0.0));
                                                        vec3 _7125 = vec3(_7122.x ? vec3(0.0).x : _7124.x, _7122.y ? vec3(0.0).y : _7124.y, _7122.z ? vec3(0.0).z : _7124.z);
                                                        radiance = vec3(_7123.x ? _5977.x : _7125.x, _7123.y ? _5977.y : _7125.y, _7123.z ? _5977.z : _7125.z);
                                                        _5913 = true;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                if (!_5913)
                                {
                                    float _2822 = voxel * 2.0;
                                    float tolerance = 0.25 + _2822;
                                    vec3 _2829 = hitRelative + p.cacheOrigin.xyz;
                                    vec2 litFound;
                                    float agreement;
                                    float cardDepth;
                                    bool _6025;
                                    {
                                        cardDepth = 0.0;
                                        litFound = vec2(0.0);
                                        agreement = 1000000000.0;
                                        if (int(p.cacheGrid.w) <= 0)
                                        {
                                            _6025 = false;
                                        }
                                        else
                                        {
                                            ivec3 _6069 = ivec3(floor((_2829 - p.cacheGrid.xyz) / vec3(p.cacheOrigin.w)));
                                            int _6287 = int((((uint(_6069.x) * 2376512323u) ^ (uint(_6069.y) * 3625334849u)) ^ (uint(_6069.z) * 3407524639u)) & uint(int(p.cacheGrid.w) - 1));
                                            uvec2 _6074 = uvec2(textureSize(_6974, 0));
                                            vec2 _6081 = vec2(float(_6074.x), float(_6074.y));
                                            int _6084 = int(p.cacheGrid.w);
                                            bool _6028 = false;
                                            bool _6029 = false;
                                            int _6030 = 0;
                                            bool _6031;
                                            ivec2 _6032;
                                            bool _6036;
                                            bool _6045;
                                            bool _6046;
                                            bool _6047;
                                            bool _6048;
                                            bool _6049;
                                            ivec2 _6288;
                                            for (;;)
                                            {
                                                if (_6030 <= uCells._member0[_6084].y)
                                                {
                                                    _6031 = !_6028;
                                                }
                                                else
                                                {
                                                    _6031 = false;
                                                }
                                                if (!_6031)
                                                {
                                                    break;
                                                }
                                                bool _6103 = _6030 == 0;
                                                if (_6103)
                                                {
                                                    _6032 = uCells._member0[_6287];
                                                }
                                                else
                                                {
                                                    int _6292 = uCells._member0[_6084].x + ((_6030 - 1) * 6);
                                                    float _6308 = intBitsToFloat(uCellPages_1._member0[_6292 + 3]);
                                                    vec3 _6310 = _2829 - vec3(intBitsToFloat(uCellPages_1._member0[_6292]), intBitsToFloat(uCellPages_1._member0[_6292 + 1]), intBitsToFloat(uCellPages_1._member0[_6292 + 2]));
                                                    if (dot(_6310, _6310) > (_6308 * _6308))
                                                    {
                                                        _6288 = ivec2(0);
                                                    }
                                                    else
                                                    {
                                                        _6288 = ivec2(uCellPages_1._member0[_6292 + 4], uCellPages_1._member0[_6292 + 5]);
                                                    }
                                                    _6032 = _6288;
                                                }
                                                bool _6033 = _6028;
                                                bool _6034 = _6029;
                                                int _6035 = 0;
                                                for (;;)
                                                {
                                                    bool _6115_ladder_break = false;
                                                    {
                                                        if (_6035 < _6032.y)
                                                        {
                                                            _6036 = !_6033;
                                                        }
                                                        else
                                                        {
                                                            _6036 = false;
                                                        }
                                                        if (!_6036)
                                                        {
                                                            _6115_ladder_break = true;
                                                        }
                                                        else
                                                        {
                                                            int _6132 = _6032.x + _6035;
                                                            int _6135 = uCellPages_1._member0[_6132] * 10;
                                                            if (!((uPages_1._member0[_6135 + 5].w > 0.5) == _6103))
                                                            {
                                                                int _6144 = _6135 + 9;
                                                                vec3 _6148 = _2829 - uPages_1._member0[_6144].xyz;
                                                                if (!(dot(_6148, _6148) > (uPages_1._member0[_6144].w * uPages_1._member0[_6144].w)))
                                                                {
                                                                    int _6326 = uCellPages_1._member0[_6132] * 10;
                                                                    vec4 _6043 = uPages_1._member0[_6326];
                                                                    vec4 _6044 = uPages_1._member0[_6326 + 1];
                                                                    int _6332 = _6326 + 2;
                                                                    int _6335 = _6326 + 3;
                                                                    int _6338 = _6326 + 4;
                                                                    int _6344 = _6326 + 6;
                                                                    int _6347 = _6326 + 7;
                                                                    int _6350 = _6326 + 8;
                                                                    vec3 _6357 = _2829 - vec3(uPages_1._member0[_6344].w, uPages_1._member0[_6347].w, uPages_1._member0[_6350].w);
                                                                    vec3 _6042 = vec3(dot(uPages_1._member0[_6344].xyz, vec3(-0.0)), dot(uPages_1._member0[_6347].xyz, vec3(-0.0)), dot(uPages_1._member0[_6350].xyz, vec3(-0.0)));
                                                                    vec3 _6370 = vec3(dot(uPages_1._member0[_6344].xyz, _6357), dot(uPages_1._member0[_6347].xyz, _6357), dot(uPages_1._member0[_6350].xyz, _6357)) - uPages_1._member0[_6332].xyz;
                                                                    vec2 _6373 = vec2(uPages_1._member0[_6332].w, uPages_1._member0[_6335].w);
                                                                    bvec2 _7127 = isnan(_6373);
                                                                    bvec2 _7128 = isnan(vec2(9.9999999747524270787835121154785e-07));
                                                                    vec2 _7129 = max(_6373, vec2(9.9999999747524270787835121154785e-07));
                                                                    vec2 _7130 = vec2(_7127.x ? vec2(9.9999999747524270787835121154785e-07).x : _7129.x, _7127.y ? vec2(9.9999999747524270787835121154785e-07).y : _7129.y);
                                                                    vec2 _6380 = vec2(dot(_6370, uPages_1._member0[_6335].xyz), dot(_6370, uPages_1._member0[_6338].xyz)) / vec2(_7128.x ? _6373.x : _7130.x, _7128.y ? _6373.y : _7130.y);
                                                                    vec2 _6037 = _6380;
                                                                    float _6039 = -dot(_6370, uPages_1._member0[_6326 + 5].xyz);
                                                                    float _6040 = uPages_1._member0[_6338].w;
                                                                    vec3 _6041 = uPages_1._member0[_6326 + 5].xyz;
                                                                    if (abs(_6380.x) > 1.0)
                                                                    {
                                                                        _6045 = true;
                                                                    }
                                                                    else
                                                                    {
                                                                        _6045 = abs(_6037.y) > 1.0;
                                                                    }
                                                                    if (!(_6045))
                                                                    {
                                                                        if (false)
                                                                        {
                                                                            _6046 = dot(_6041, _6042) < (-0.0500000007450580596923828125);
                                                                        }
                                                                        else
                                                                        {
                                                                            _6046 = false;
                                                                        }
                                                                        if (!(_6046))
                                                                        {
                                                                            if (_6039 < ((-0.25) - _2822))
                                                                            {
                                                                                _6047 = true;
                                                                            }
                                                                            else
                                                                            {
                                                                                _6047 = _6039 > (_6040 + tolerance);
                                                                            }
                                                                            if (!(_6047))
                                                                            {
                                                                                vec2 _6199 = (_6037 * 0.5) + vec2(0.5);
                                                                                vec2 _6206 = (_6044.xy + (_6199 * _6044.zw)) / _6081;
                                                                                if (!(textureLod(_6976, _6206, 0.0).w < 0.5))
                                                                                {
                                                                                    float _6226 = abs((textureLod(_6978, _6206, 0.0).x * _6040) - _6039);
                                                                                    if (_6226 < agreement)
                                                                                    {
                                                                                        agreement = _6226;
                                                                                        cardDepth = _6040;
                                                                                        litFound = (_6043.xy + (_6199 * _6043.zw)) / vec3(p.cacheAtlas.xy, 0.0).xy;
                                                                                        _6048 = _6226 < 0.0199999995529651641845703125;
                                                                                        _6049 = true;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        _6048 = _6033;
                                                                                        _6049 = _6034;
                                                                                    }
                                                                                    _6033 = _6048;
                                                                                    _6034 = _6049;
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                    if (_6115_ladder_break)
                                                    {
                                                        break;
                                                    }
                                                    _6035++;
                                                    continue;
                                                }
                                                _6028 = _6033;
                                                _6029 = _6034;
                                                _6030++;
                                                continue;
                                            }
                                            _6025 = _6029;
                                        }
                                    }
                                    if (_6025)
                                    {
                                        screenAllowed = agreement <= (tolerance + (cardDepth * 0.5));
                                    }
                                    else
                                    {
                                        screenAllowed = false;
                                    }
                                    if (screenAllowed)
                                    {
                                        vec3 _3345 = textureLod(_6980, litFound, 0.0).xyz;
                                        bvec3 _7132 = isnan(_3345);
                                        bvec3 _7133 = isnan(vec3(0.0));
                                        vec3 _7134 = max(_3345, vec3(0.0));
                                        vec3 _7135 = vec3(_7132.x ? vec3(0.0).x : _7134.x, _7132.y ? vec3(0.0).y : _7134.y, _7132.z ? vec3(0.0).z : _7134.z);
                                        radiance = vec3(_7133.x ? _3345.x : _7135.x, _7133.y ? _3345.y : _7135.y, _7133.z ? _3345.z : _7135.z) * p.trace.w;
                                        crossed = true;
                                    }
                                    else
                                    {
                                        crossed = _5913;
                                    }
                                }
                                else
                                {
                                    crossed = _5913;
                                }
                                if (!crossed)
                                {
                                    float _6394 = (p.misc.w * p.misc.w) - 40449600.0;
                                    float _6399 = acos(clamp(sqrt(isnan(_6394) ? 0.0 : (isnan(0.0) ? _6394 : max(0.0, _6394))) / p.misc.w, -1.0, 1.0));
                                    float _6400 = 3.1415927410125732421875 - _6399;
                                    float _6403 = acos(clamp(_2239.z, -1.0, 1.0));
                                    float _6389;
                                    if (_6403 < _6400)
                                    {
                                        float _6415 = 1.0 - (_6403 / _6400);
                                        _6389 = (1.0 - sqrt(isnan(_6415) ? 0.0 : (isnan(0.0) ? _6415 : max(0.0, _6415)))) * 0.5;
                                    }
                                    else
                                    {
                                        float _6408 = (_6403 - _6400) / (isnan(9.9999999747524270787835121154785e-07) ? _6399 : (isnan(_6399) ? 9.9999999747524270787835121154785e-07 : max(_6399, 9.9999999747524270787835121154785e-07)));
                                        _6389 = (sqrt(isnan(_6408) ? 0.0 : (isnan(0.0) ? _6408 : max(0.0, _6408))) * 0.5) + 0.5;
                                    }
                                    float _6423 = atan(_2239.y, _2239.x);
                                    float _6390;
                                    if (_6423 < 0.0)
                                    {
                                        _6390 = _6423 + 6.283185482025146484375;
                                    }
                                    else
                                    {
                                        _6390 = _6423;
                                    }
                                    uvec2 _6438 = uvec2(textureSize(_6967, 0));
                                    vec2 _6445 = vec2(float(_6438.x), float(_6438.y));
                                    vec3 _6451 = textureLod(_6969, (vec2(_6390 * 0.15915493667125701904296875, _6389) * ((_6445 - vec2(1.0)) / _6445)) + (vec2(0.5) / _6445), 0.0).xyz;
                                    if (_5181)
                                    {
                                        normalW = vec3(dot(_6451, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * 0.300000011920928955078125);
                                    }
                                    else
                                    {
                                        normalW = _6451;
                                    }
                                    float _6469 = clamp(textureLod(_6959, uv, 0.0).w, 0.0, 1.0);
                                    radiance = normalW * clamp((pow(_479 + _6469, roughness * roughness) - 1.0) + _6469, 0.0, 1.0);
                                }
                            }
                            float _3385 = isnan(radiance.z) ? radiance.y : (isnan(radiance.y) ? radiance.z : max(radiance.y, radiance.z));
                            float _3386 = isnan(_3385) ? radiance.x : (isnan(radiance.x) ? _3385 : max(radiance.x, _3385));
                            if (_3386 > p.trace.z)
                            {
                                radiance *= (p.trace.z / _3386);
                            }
                            if (water)
                            {
                                float _6576 = (p.misc.w * p.misc.w) - 40449600.0;
                                float _6581 = acos(clamp(sqrt(isnan(_6576) ? 0.0 : (isnan(0.0) ? _6576 : max(0.0, _6576))) / p.misc.w, -1.0, 1.0));
                                float _6582 = 3.1415927410125732421875 - _6581;
                                float _6585 = acos(clamp(_2239.z, -1.0, 1.0));
                                float _6571;
                                if (_6585 < _6582)
                                {
                                    float _6597 = 1.0 - (_6585 / _6582);
                                    _6571 = (1.0 - sqrt(isnan(_6597) ? 0.0 : (isnan(0.0) ? _6597 : max(0.0, _6597)))) * 0.5;
                                }
                                else
                                {
                                    float _6590 = (_6585 - _6582) / (isnan(9.9999999747524270787835121154785e-07) ? _6581 : (isnan(_6581) ? 9.9999999747524270787835121154785e-07 : max(_6581, 9.9999999747524270787835121154785e-07)));
                                    _6571 = (sqrt(isnan(_6590) ? 0.0 : (isnan(0.0) ? _6590 : max(0.0, _6590))) * 0.5) + 0.5;
                                }
                                float _6605 = atan(_2239.y, _2239.x);
                                float _6572;
                                if (_6605 < 0.0)
                                {
                                    _6572 = _6605 + 6.283185482025146484375;
                                }
                                else
                                {
                                    _6572 = _6605;
                                }
                                uvec2 _6620 = uvec2(textureSize(_6967, 0));
                                vec2 _6627 = vec2(float(_6620.x), float(_6620.y));
                                b = textureLod(_6969, (vec2(_6572 * 0.15915493667125701904296875, _6571) * ((_6627 - vec2(1.0)) / _6627)) + (vec2(0.5) / _6627), 0.0).xyz * clamp(_2239.z * 20.0, 0.0, 1.0);
                            }
                            else
                            {
                                b = vec3(0.0);
                            }
                            float _3414 = screenWeight;
                            screenWeight = 1.0;
                            a += (((radiance - b) * up) * (1.0 - _3414));
                        }
                        if (!raw)
                        {
                            screenAllowed = !water;
                        }
                        else
                        {
                            screenAllowed = false;
                        }
                        if (screenAllowed)
                        {
                            screenAllowed = roughness > 0.0500000007450580596923828125;
                        }
                        else
                        {
                            screenAllowed = false;
                        }
                        float spread;
                        if (screenAllowed)
                        {
                            spread = 2.0 + roughness;
                        }
                        else
                        {
                            if (traces)
                            {
                                marches = true;
                            }
                            if (marches)
                            {
                                puddle = 1.0;
                            }
                            else
                            {
                                puddle = screenWeight;
                            }
                            spread = puddle;
                        }
                        imageStore(uReflection, ivec2(gl_GlobalInvocationID.xy), vec4(a, spread));
                    }
                }
                else
                {
                    if (traces)
                    {
                        screenAllowed = true;
                    }
                    else
                    {
                        screenAllowed = marches;
                    }
                    if (screenAllowed)
                    {
                        ceiling = p.trace2.x;
                    }
                    else
                    {
                        ceiling = p.ssr.z;
                    }
                    if (roughness > ceiling)
                    {
                        imageStore(uReflection, ivec2(gl_GlobalInvocationID.xy), vec4(0.0));
                    }
                    else
                    {
                        vec3 _1433 = mix(vec3(0.07999999821186065673828125 * _sampled.y), textureLod(_6959, uv, 0.0).xyz, vec3(_sampled.x));
                        float _4068 = 1.0 - roughness;
                        float _4069 = _4068 * _4068;
                        float _4071 = exp2((-9.27999973297119140625) * _479);
                        float _4079 = 1.03999996185302734375 * ((((isnan(_4071) ? _4069 : (isnan(_4069) ? _4071 : min(_4069, _4071))) * _4068) + 0.0425000004470348358154296875) - (0.0274999998509883880615234375 * roughness));
                        vec2 _4084 = vec2((1.03999996185302734375 - (0.572000026702880859375 * roughness)) - _4079, ((0.02199999988079071044921875 * roughness) - 0.039999999105930328369140625) + _4079);
                        if (traces)
                        {
                            screenAllowed = true;
                        }
                        else
                        {
                            screenAllowed = marches;
                        }
                        if (screenAllowed)
                        {
                            float _1486 = ceiling * 0.25;
                            fade = clamp((ceiling - roughness) / (isnan(0.001000000047497451305389404296875) ? _1486 : (isnan(_1486) ? 0.001000000047497451305389404296875 : max(_1486, 0.001000000047497451305389404296875))), 0.0, 1.0);
                        }
                        else
                        {
                            fade = clamp((ceiling - roughness) / (isnan(0.001000000047497451305389404296875) ? ceiling : (isnan(ceiling) ? 0.001000000047497451305389404296875 : max(ceiling, 0.001000000047497451305389404296875))), 0.0, 1.0);
                        }
                        if (roughness > 0.0500000007450580596923828125)
                        {
                            float alpha = roughness * roughness;
                            if (raw)
                            {
                                uvec3 _4132 = (uvec3(gl_GlobalInvocationID.xy, uint(p.misc.y) ^ 408859118u) * uvec3(1664525u)) + uvec3(1013904223u);
                                _4132.x = _4132.x + (_4132.y * _4132.z);
                                _4132.y = _4132.y + (_4132.z * _4132.x);
                                _4132.z = _4132.z + (_4132.x * _4132.y);
                                uvec3 _4159 = _4132 ^ (_4132 >> uvec3(16u));
                                _4159.x = _4159.x + (_4159.y * _4159.z);
                                _4159.y = _4159.y + (_4159.z * _4159.x);
                                uvec3 _6945 = _4159;
                                _6945.z = _4159.z + (_4159.x * _4159.y);
                                facetNoise = (vec3(_4159 >> uvec3(8u)) * 5.9604644775390625e-08).xy;
                            }
                            else
                            {
                                vec2 _4088 = _310 + (vec2(12.0780429840087890625, 9.1174449920654296875) * p.misc.y);
                                vec2 _4103 = (_310 + vec2(31.0, 17.0)) + (vec2(12.0780429840087890625, 9.1174449920654296875) * p.misc.y);
                                facetNoise = vec2(fract(52.98291778564453125 * fract((0.067110560834407806396484375 * _4088.x) + (0.005837149918079376220703125 * _4088.y))), fract(52.98291778564453125 * fract((0.067110560834407806396484375 * _4103.x) + (0.005837149918079376220703125 * _4103.y))));
                            }
                            float _1653 = 1.0 + (((alpha * alpha) - 1.0) * facetNoise.x);
                            float _1657 = sqrt((1.0 - facetNoise.x) / (isnan(9.9999999747524270787835121154785e-07) ? _1653 : (isnan(_1653) ? 9.9999999747524270787835121154785e-07 : max(_1653, 9.9999999747524270787835121154785e-07))));
                            float _1659 = 1.0 - (_1657 * _1657);
                            float _1661 = sqrt(isnan(0.0) ? _1659 : (isnan(_1659) ? 0.0 : max(_1659, 0.0)));
                            float phi = 6.283185482025146484375 * facetNoise.y;
                            if (abs(_418.z) < 0.999000012874603271484375)
                            {
                                up = vec3(0.0, 0.0, 1.0);
                            }
                            else
                            {
                                up = vec3(1.0, 0.0, 0.0);
                            }
                            vec3 _1677 = normalize(cross(up, _418));
                            vec3 _1688 = normalize(((_1677 * (_1661 * cos(phi))) + (cross(_418, _1677) * (_1661 * sin(phi)))) + (_418 * _1657));
                            if (dot(reflect(_476, _1688), _418) > 0.0199999995529651641845703125)
                            {
                                normalW = _1688;
                            }
                            else
                            {
                                normalW = _418;
                            }
                        }
                        else
                        {
                            normalW = _418;
                        }
                        up = ((_1433 * _4084.x) + (vec3(clamp(50.0 * _1433.y, 0.0, 1.0)) * _4084.y)) * fade;
                        screenAllowed = roughness <= p.ssr.z;
                        float _1709 = isnan(up.z) ? up.y : (isnan(up.y) ? up.z : max(up.y, up.z));
                        if ((isnan(_1709) ? up.x : (isnan(up.x) ? _1709 : max(up.x, _1709))) <= 0.0030000000260770320892333984375)
                        {
                            imageStore(uReflection, ivec2(gl_GlobalInvocationID.xy), vec4(0.0));
                        }
                        else
                        {
                            vec3 _1732 = reflect(normalize(_3533), normalize(normalW * transpose(mat3(spvWorkaroundRowMajor(p.viewToWorld)[0].xyz, spvWorkaroundRowMajor(p.viewToWorld)[1].xyz, spvWorkaroundRowMajor(p.viewToWorld)[2].xyz))));
                            bool have;
                            if (_396)
                            {
                                have = _1732.z > 0.0;
                            }
                            else
                            {
                                have = false;
                            }
                            if (!have)
                            {
                                screenAllowed = false;
                            }
                            int _1749 = max(int(p.ssr.x + 0.5), 1);
                            vec2 _4835 = _310 + (vec2(12.0780429840087890625, 9.1174449920654296875) * p.misc.y);
                            have = false;
                            ceiling = -1.0;
                            vec3 previous = _3533;
                            int i = 0;
                            fade = 0.20000000298023223876953125 * (0.5 + fract(52.98291778564453125 * fract((0.067110560834407806396484375 * _4835.x) + (0.005837149918079376220703125 * _4835.y))));
                            bool crossed;
                            float hitEdge;
                            vec3 a;
                            vec3 b;
                            bool met;
                            bool _95;
                            float _5010;
                            for (;;)
                            {
                                vec3 pv;
                                float t;
                                bool _175_ladder_break = false;
                                {
                                    if (screenAllowed)
                                    {
                                        crossed = i < _1749;
                                    }
                                    else
                                    {
                                        crossed = false;
                                    }
                                    if (!crossed)
                                    {
                                        hitEdge = 0.0;
                                        facetNoise = vec2(0.0);
                                        _175_ladder_break = true;
                                    }
                                    else
                                    {
                                        pv = _3533 + (_1732 * fade);
                                        if (pv.z <= p.unproject.z)
                                        {
                                            met = true;
                                        }
                                        else
                                        {
                                            met = fade > p.misc.z;
                                        }
                                        if (met)
                                        {
                                            hitEdge = 0.0;
                                            facetNoise = vec2(0.0);
                                            _175_ladder_break = true;
                                        }
                                        else
                                        {
                                            float _1801 = fade * 0.07999999821186065673828125;
                                            t = fade + (isnan(_1801) ? 0.20000000298023223876953125 : (isnan(0.20000000298023223876953125) ? _1801 : max(0.20000000298023223876953125, _1801)));
                                            vec2 _4865 = (vec2((pv.x * p.unproject.x) / pv.z, ((-pv.y) * p.unproject.y) / pv.z) * 0.5) + vec2(0.5);
                                            if (any(lessThan(_4865, vec2(0.0))))
                                            {
                                                _95 = true;
                                            }
                                            else
                                            {
                                                _95 = any(greaterThan(_4865, vec2(1.0)));
                                            }
                                            if (_95)
                                            {
                                                hitEdge = 0.0;
                                                facetNoise = vec2(0.0);
                                                _175_ladder_break = true;
                                            }
                                            else
                                            {
                                                uvec2 _4871 = uvec2(textureSize(_6962, 0));
                                                uint _4872 = _4871.x;
                                                uint _4873 = _4871.y;
                                                vec4 _4892 = texelFetch(_6962, ivec3(clamp(ivec2(_4865 * vec2(float(_4872), float(_4873))), ivec2(0), ivec2(int(_4872) - 1, int(_4873) - 1)), 0).xy, 0);
                                                float _4893 = _4892.x;
                                                if (_4893 <= 0.0)
                                                {
                                                    ceiling = -1.0;
                                                }
                                                else
                                                {
                                                    float diff = pv.z - (((2.0 * p.unproject.z) * p.unproject.w) / ((p.unproject.w + p.unproject.z) - ((1.0 - (2.0 * _4893)) * (p.unproject.w - p.unproject.z))));
                                                    if (diff > 0.0)
                                                    {
                                                        float _1914 = pv.z * 0.0500000007450580596923828125;
                                                        float _1915 = isnan(_1914) ? p.ssr.w : (isnan(p.ssr.w) ? _1914 : max(p.ssr.w, _1914));
                                                        if (have)
                                                        {
                                                            crossed = ceiling < 0.0;
                                                        }
                                                        else
                                                        {
                                                            crossed = false;
                                                        }
                                                        if (crossed)
                                                        {
                                                            screenAllowed = true;
                                                        }
                                                        else
                                                        {
                                                            screenAllowed = diff < _1915;
                                                        }
                                                        if (screenAllowed)
                                                        {
                                                            a = previous;
                                                            b = pv;
                                                            int k = 0;
                                                            for (;;)
                                                            {
                                                                if (!(k < 5))
                                                                {
                                                                    break;
                                                                }
                                                                vec3 _1941 = b;
                                                                vec3 mid = (a + _1941) * 0.5;
                                                                float _4925 = mid.z;
                                                                uvec2 _4942 = uvec2(textureSize(_6962, 0));
                                                                uint _4943 = _4942.x;
                                                                uint _4944 = _4942.y;
                                                                vec4 _4963 = texelFetch(_6962, ivec3(clamp(ivec2(((vec2((mid.x * p.unproject.x) / _4925, ((-mid.y) * p.unproject.y) / _4925) * 0.5) + vec2(0.5)) * vec2(float(_4943), float(_4944))), ivec2(0), ivec2(int(_4943) - 1, int(_4944) - 1)), 0).xy, 0);
                                                                float _4964 = _4963.x;
                                                                if (_4964 > 0.0)
                                                                {
                                                                    screenAllowed = (mid.z - (((2.0 * p.unproject.z) * p.unproject.w) / ((p.unproject.w + p.unproject.z) - ((1.0 - (2.0 * _4964)) * (p.unproject.w - p.unproject.z))))) > 0.0;
                                                                }
                                                                else
                                                                {
                                                                    screenAllowed = false;
                                                                }
                                                                if (screenAllowed)
                                                                {
                                                                    b = mid;
                                                                }
                                                                else
                                                                {
                                                                    a = mid;
                                                                }
                                                                k++;
                                                                continue;
                                                            }
                                                            vec2 _5007 = (vec2((b.x * p.unproject.x) / b.z, ((-b.y) * p.unproject.y) / b.z) * 0.5) + vec2(0.5);
                                                            uvec2 _5014 = uvec2(textureSize(_6962, 0));
                                                            uint _5015 = _5014.x;
                                                            uint _5016 = _5014.y;
                                                            vec4 _5035 = texelFetch(_6962, ivec3(clamp(ivec2(_5007 * vec2(float(_5015), float(_5016))), ivec2(0), ivec2(int(_5015) - 1, int(_5016) - 1)), 0).xy, 0);
                                                            float _5036 = _5035.x;
                                                            if (_5036 > 0.0)
                                                            {
                                                                _5010 = ((2.0 * p.unproject.z) * p.unproject.w) / ((p.unproject.w + p.unproject.z) - ((1.0 - (2.0 * _5036)) * (p.unproject.w - p.unproject.z)));
                                                            }
                                                            else
                                                            {
                                                                _5010 = 0.0;
                                                            }
                                                            if (_5010 > 0.0)
                                                            {
                                                                met = (b.z - _5010) < _1915;
                                                            }
                                                            else
                                                            {
                                                                met = false;
                                                            }
                                                            vec2 _2034 = clamp((abs((_5007 * 2.0) - vec2(1.0)) * 5.0) - vec2(4.0), vec2(0.0), vec2(1.0));
                                                            if (met)
                                                            {
                                                                puddle = clamp(1.0 - dot(_2034, _2034), 0.0, 1.0);
                                                            }
                                                            else
                                                            {
                                                                puddle = 0.0;
                                                            }
                                                            hitEdge = puddle;
                                                            facetNoise = _5007;
                                                        }
                                                        else
                                                        {
                                                            hitEdge = 0.0;
                                                            facetNoise = vec2(0.0);
                                                        }
                                                        _175_ladder_break = true;
                                                    }
                                                    else
                                                    {
                                                        ceiling = diff;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                if (_175_ladder_break)
                                {
                                    break;
                                }
                                have = true;
                                previous = pv;
                                i++;
                                fade = t;
                                continue;
                            }
                            float screenWeight;
                            if (hitEdge > 0.0)
                            {
                                vec4 _sampled_1 = textureLod(_6964, facetNoise, 0.0);
                                vec3 _2077 = _sampled_1.xyz;
                                bvec3 _7057 = isnan(_2077);
                                bvec3 _7058 = isnan(vec3(0.0));
                                vec3 _7059 = max(_2077, vec3(0.0));
                                vec3 _7060 = vec3(_7057.x ? vec3(0.0).x : _7059.x, _7057.y ? vec3(0.0).y : _7059.y, _7057.z ? vec3(0.0).z : _7059.z);
                                if (water)
                                {
                                    puddle = 1.0;
                                }
                                else
                                {
                                    puddle = p.ssr.y;
                                }
                                if (water)
                                {
                                    vec3 _2092 = normalize(reflect(_476, normalW));
                                    float _5076 = (p.misc.w * p.misc.w) - 40449600.0;
                                    float _5081 = acos(clamp(sqrt(isnan(_5076) ? 0.0 : (isnan(0.0) ? _5076 : max(0.0, _5076))) / p.misc.w, -1.0, 1.0));
                                    float _5082 = 3.1415927410125732421875 - _5081;
                                    float _5085 = acos(clamp(_2092.z, -1.0, 1.0));
                                    float _5071;
                                    if (_5085 < _5082)
                                    {
                                        float _5097 = 1.0 - (_5085 / _5082);
                                        _5071 = (1.0 - sqrt(isnan(_5097) ? 0.0 : (isnan(0.0) ? _5097 : max(0.0, _5097)))) * 0.5;
                                    }
                                    else
                                    {
                                        float _5090 = (_5085 - _5082) / (isnan(9.9999999747524270787835121154785e-07) ? _5081 : (isnan(_5081) ? 9.9999999747524270787835121154785e-07 : max(_5081, 9.9999999747524270787835121154785e-07)));
                                        _5071 = (sqrt(isnan(_5090) ? 0.0 : (isnan(0.0) ? _5090 : max(0.0, _5090))) * 0.5) + 0.5;
                                    }
                                    float _5105 = atan(_2092.y, _2092.x);
                                    float _5072;
                                    if (_5105 < 0.0)
                                    {
                                        _5072 = _5105 + 6.283185482025146484375;
                                    }
                                    else
                                    {
                                        _5072 = _5105;
                                    }
                                    uvec2 _5120 = uvec2(textureSize(_6967, 0));
                                    vec2 _5127 = vec2(float(_5120.x), float(_5120.y));
                                    a = textureLod(_6969, (vec2(_5072 * 0.15915493667125701904296875, _5071) * ((_5127 - vec2(1.0)) / _5127)) + (vec2(0.5) / _5127), 0.0).xyz * clamp(_2092.z * 20.0, 0.0, 1.0);
                                }
                                else
                                {
                                    a = vec3(0.0);
                                }
                                float screenWeight_1 = hitEdge * step(0.5, _sampled_1.w);
                                screenWeight = screenWeight_1;
                                a = (((vec3(_7058.x ? _2077.x : _7060.x, _7058.y ? _2077.y : _7060.y, _7058.z ? _2077.z : _7060.z) * puddle) - a) * up) * screenWeight_1;
                            }
                            else
                            {
                                screenWeight = 0.0;
                                a = vec3(0.0);
                            }
                            if (marches)
                            {
                                screenAllowed = screenWeight < 0.999000012874603271484375;
                            }
                            else
                            {
                                screenAllowed = false;
                            }
                            if (screenAllowed)
                            {
                                vec3 _2237 = normalW;
                                vec3 _2239 = normalize(reflect(_476, _2237));
                                vec3 originRelative = _489 + (_2237 * (0.0199999995529651641845703125 + (0.0005000000237487256526947021484375 * _3533.z)));
                                vec2 _2252 = _489.xy + p.wet1.zw;
                                float _2256 = _489.z + p.wet2.y;
                                vec2 _6893 = p.shelter0.xy;
                                float _6894 = p.shelter0.z;
                                float _6895 = p.shelter0.w;
                                float _6896 = p.shelter1.x;
                                float _6897 = p.shelter1.y;
                                vec2 _6898 = p.shelter2.xy;
                                float _6899 = p.wet2.x;
                                bool _5181;
                                {
                                    ivec2 _5234 = ivec2(floor((_2252 - _6893) * _6894));
                                    bool _5235;
                                    if (_6899 > 0.5)
                                    {
                                        _5235 = _5234.x >= 0;
                                    }
                                    else
                                    {
                                        _5235 = false;
                                    }
                                    if (_5235)
                                    {
                                        _5235 = _5234.y >= 0;
                                    }
                                    else
                                    {
                                        _5235 = false;
                                    }
                                    if (_5235)
                                    {
                                        _5235 = _5234.x < int(_6898.x);
                                    }
                                    else
                                    {
                                        _5235 = false;
                                    }
                                    if (_5235)
                                    {
                                        _5235 = _5234.y < int(_6898.y);
                                    }
                                    else
                                    {
                                        _5235 = false;
                                    }
                                    if (!_5235)
                                    {
                                        _5181 = false;
                                    }
                                    else
                                    {
                                        vec4 _5193 = texelFetch(_6957, ivec3(_5234, 0).xy, 0);
                                        float _5285 = floor((_5193.z * 255.0) + 0.5) + (floor((_5193.y * 255.0) + 0.5) * 256.0);
                                        float _5273;
                                        if (_5285 < 0.5)
                                        {
                                            _5273 = -1000000015047466219876688855040.0;
                                        }
                                        else
                                        {
                                            _5273 = _6895 + ((_5285 - 1.0) * _6896);
                                        }
                                        float _5198 = _2256 + _6897;
                                        if (_5273 <= _5198)
                                        {
                                            _5181 = false;
                                        }
                                        else
                                        {
                                            float _5202 = _2239.z;
                                            if (_5202 <= 0.0500000007450580596923828125)
                                            {
                                                _5181 = false;
                                            }
                                            else
                                            {
                                                ivec2 _5307 = ivec2(floor(((_2252 + (_2239.xy * ((_5273 - _2256) / _5202))) - _6893) * _6894));
                                                bool _5308;
                                                if (_6899 > 0.5)
                                                {
                                                    _5308 = _5307.x >= 0;
                                                }
                                                else
                                                {
                                                    _5308 = false;
                                                }
                                                if (_5308)
                                                {
                                                    _5308 = _5307.y >= 0;
                                                }
                                                else
                                                {
                                                    _5308 = false;
                                                }
                                                if (_5308)
                                                {
                                                    _5308 = _5307.x < int(_6898.x);
                                                }
                                                else
                                                {
                                                    _5308 = false;
                                                }
                                                if (_5308)
                                                {
                                                    _5308 = _5307.y < int(_6898.y);
                                                }
                                                else
                                                {
                                                    _5308 = false;
                                                }
                                                if (!_5308)
                                                {
                                                    _5181 = false;
                                                }
                                                else
                                                {
                                                    vec4 _5219 = texelFetch(_6957, ivec3(_5307, 0).xy, 0);
                                                    float _5358 = floor((_5219.z * 255.0) + 0.5) + (floor((_5219.y * 255.0) + 0.5) * 256.0);
                                                    float _5346;
                                                    if (_5358 < 0.5)
                                                    {
                                                        _5346 = -1000000015047466219876688855040.0;
                                                    }
                                                    else
                                                    {
                                                        _5346 = _6895 + ((_5358 - 1.0) * _6896);
                                                    }
                                                    _5181 = _5346 > _5198;
                                                }
                                            }
                                        }
                                    }
                                }
                                _5371 = false;
                                vec3 hitRelative;
                                float voxel;
                                bool _5372;
                                {
                                    hitRelative = originRelative;
                                    voxel = p.sdfOrigin.data[0].w;
                                    if (int(p.field.x) <= 0)
                                    {
                                        _5371 = true;
                                        _5372 = false;
                                    }
                                    else
                                    {
                                        vec3 _5403 = originRelative + ((normalW * p.sdfOrigin.data[0].w) * 1.5);
                                        bool _5373 = false;
                                        float _5374 = 0.0;
                                        float _5375 = 0.0;
                                        int _5377 = 0;
                                        float _5376 = 0.0;
                                        bool _5378;
                                        bool _5379;
                                        float _5381;
                                        float _5382;
                                        bool _5383;
                                        float _5483;
                                        bool _5485;
                                        bool _5598;
                                        float _5600;
                                        float _5641;
                                        bool _5643;
                                        bool _5756;
                                        float _5758;
                                        float _5799;
                                        bool _5801;
                                        for (;;)
                                        {
                                            if (_5377 < 96)
                                            {
                                                _5378 = _5376 < p.trace.y;
                                            }
                                            else
                                            {
                                                _5378 = false;
                                            }
                                            if (!_5378)
                                            {
                                                break;
                                            }
                                            vec3 _5420 = _5403 + (_2239 * _5376);
                                            _5482 = false;
                                            {
                                                _5379 = false;
                                                _5381 = p.sdfOrigin.data[0].w;
                                                int _5484 = 0;
                                                for (;;)
                                                {
                                                    bool _5496_ladder_break = false;
                                                    {
                                                        if (!(_5484 < int(p.field.x)))
                                                        {
                                                            _5496_ladder_break = true;
                                                        }
                                                        else
                                                        {
                                                            vec3 _5513 = (_5420 - p.sdfOrigin.data[_5484].xyz) / vec3(p.sdfOrigin.data[_5484].w);
                                                            if (any(lessThan(_5513, vec3(0.5))))
                                                            {
                                                                _5485 = true;
                                                            }
                                                            else
                                                            {
                                                                _5485 = any(greaterThan(_5513, vec3(float(int(p.field.y)) - 0.5, float(int(p.field.y)) - 0.5, float(int(p.field.y)) - 0.5)));
                                                            }
                                                            if (!(_5485))
                                                            {
                                                                _5379 = true;
                                                                _5381 = p.sdfOrigin.data[_5484].w;
                                                                _5482 = true;
                                                                _5483 = ((textureLod(_6971, vec3(_5513.x / float(int(p.field.y)), _5513.y / float(int(p.field.y)), ((float(_5484) * float(int(p.field.y))) + _5513.z) / float(int(p.field.y) * int(p.field.x))), 0.0).x * 2.0) - 1.0) * p.sdfRange.data[_5484];
                                                                _5496_ladder_break = true;
                                                            }
                                                        }
                                                    }
                                                    if (_5496_ladder_break)
                                                    {
                                                        break;
                                                    }
                                                    _5484++;
                                                    continue;
                                                }
                                                if (!(_5482))
                                                {
                                                    _5482 = true;
                                                    _5483 = 1000000.0;
                                                }
                                            }
                                            if (!_5379)
                                            {
                                                _5371 = true;
                                                _5372 = false;
                                                break;
                                            }
                                            if (_5373)
                                            {
                                                if (_5483 <= 0.0)
                                                {
                                                    float _5434 = _5375 - _5483;
                                                    if (_5434 > 9.9999997473787516355514526367188e-06)
                                                    {
                                                        _5382 = _5374 + ((_5376 - _5374) * (_5375 / _5434));
                                                    }
                                                    else
                                                    {
                                                        _5382 = _5376;
                                                    }
                                                    voxel = p.sdfOrigin.data[0].w;
                                                    int _5596 = 0;
                                                    float _5597 = clamp(_5382, _5374, _5376);
                                                    for (;;)
                                                    {
                                                        if (!(_5596 < 2))
                                                        {
                                                            break;
                                                        }
                                                        vec3 _5618 = _5403 + (_2239 * _5597);
                                                        _5640 = false;
                                                        {
                                                            _5598 = false;
                                                            _5600 = p.sdfOrigin.data[0].w;
                                                            int _5642 = 0;
                                                            for (;;)
                                                            {
                                                                bool _5654_ladder_break = false;
                                                                {
                                                                    if (!(_5642 < int(p.field.x)))
                                                                    {
                                                                        _5654_ladder_break = true;
                                                                    }
                                                                    else
                                                                    {
                                                                        vec3 _5671 = (_5618 - p.sdfOrigin.data[_5642].xyz) / vec3(p.sdfOrigin.data[_5642].w);
                                                                        if (any(lessThan(_5671, vec3(0.5))))
                                                                        {
                                                                            _5643 = true;
                                                                        }
                                                                        else
                                                                        {
                                                                            _5643 = any(greaterThan(_5671, vec3(float(int(p.field.y)) - 0.5, float(int(p.field.y)) - 0.5, float(int(p.field.y)) - 0.5)));
                                                                        }
                                                                        if (!(_5643))
                                                                        {
                                                                            _5598 = true;
                                                                            _5600 = p.sdfOrigin.data[_5642].w;
                                                                            _5640 = true;
                                                                            _5641 = ((textureLod(_6971, vec3(_5671.x / float(int(p.field.y)), _5671.y / float(int(p.field.y)), ((float(_5642) * float(int(p.field.y))) + _5671.z) / float(int(p.field.y) * int(p.field.x))), 0.0).x * 2.0) - 1.0) * p.sdfRange.data[_5642];
                                                                            _5654_ladder_break = true;
                                                                        }
                                                                    }
                                                                }
                                                                if (_5654_ladder_break)
                                                                {
                                                                    break;
                                                                }
                                                                _5642++;
                                                                continue;
                                                            }
                                                            if (!(_5640))
                                                            {
                                                                _5640 = true;
                                                                _5641 = 1000000.0;
                                                            }
                                                        }
                                                        if (!_5598)
                                                        {
                                                            break;
                                                        }
                                                        voxel = _5600;
                                                        _5596++;
                                                        _5597 += (isnan(0.0) ? _5641 : (isnan(_5641) ? 0.0 : max(_5641, 0.0)));
                                                        continue;
                                                    }
                                                    hitRelative = _5403 + (_2239 * (_5597 + (voxel * 0.25)));
                                                    _5371 = true;
                                                    _5372 = true;
                                                    break;
                                                }
                                                if (_5483 > _5375)
                                                {
                                                    _5383 = _5375 < (_5381 * 0.0500000007450580596923828125);
                                                }
                                                else
                                                {
                                                    _5383 = false;
                                                }
                                                if (_5383)
                                                {
                                                    voxel = p.sdfOrigin.data[0].w;
                                                    int _5754 = 0;
                                                    float _5755 = _5374;
                                                    for (;;)
                                                    {
                                                        if (!(_5754 < 2))
                                                        {
                                                            break;
                                                        }
                                                        vec3 _5776 = _5403 + (_2239 * _5755);
                                                        _5798 = false;
                                                        {
                                                            _5756 = false;
                                                            _5758 = p.sdfOrigin.data[0].w;
                                                            int _5800 = 0;
                                                            for (;;)
                                                            {
                                                                bool _5812_ladder_break = false;
                                                                {
                                                                    if (!(_5800 < int(p.field.x)))
                                                                    {
                                                                        _5812_ladder_break = true;
                                                                    }
                                                                    else
                                                                    {
                                                                        vec3 _5829 = (_5776 - p.sdfOrigin.data[_5800].xyz) / vec3(p.sdfOrigin.data[_5800].w);
                                                                        if (any(lessThan(_5829, vec3(0.5))))
                                                                        {
                                                                            _5801 = true;
                                                                        }
                                                                        else
                                                                        {
                                                                            _5801 = any(greaterThan(_5829, vec3(float(int(p.field.y)) - 0.5, float(int(p.field.y)) - 0.5, float(int(p.field.y)) - 0.5)));
                                                                        }
                                                                        if (!(_5801))
                                                                        {
                                                                            _5756 = true;
                                                                            _5758 = p.sdfOrigin.data[_5800].w;
                                                                            _5798 = true;
                                                                            _5799 = ((textureLod(_6971, vec3(_5829.x / float(int(p.field.y)), _5829.y / float(int(p.field.y)), ((float(_5800) * float(int(p.field.y))) + _5829.z) / float(int(p.field.y) * int(p.field.x))), 0.0).x * 2.0) - 1.0) * p.sdfRange.data[_5800];
                                                                            _5812_ladder_break = true;
                                                                        }
                                                                    }
                                                                }
                                                                if (_5812_ladder_break)
                                                                {
                                                                    break;
                                                                }
                                                                _5800++;
                                                                continue;
                                                            }
                                                            if (!(_5798))
                                                            {
                                                                _5798 = true;
                                                                _5799 = 1000000.0;
                                                            }
                                                        }
                                                        if (!_5756)
                                                        {
                                                            break;
                                                        }
                                                        voxel = _5758;
                                                        _5754++;
                                                        _5755 += (isnan(0.0) ? _5799 : (isnan(_5799) ? 0.0 : max(_5799, 0.0)));
                                                        continue;
                                                    }
                                                    hitRelative = _5403 + (_2239 * (_5755 + (voxel * 0.25)));
                                                    _5371 = true;
                                                    _5372 = true;
                                                    break;
                                                }
                                            }
                                            float _5467 = _5381 * 0.25;
                                            _5373 = true;
                                            _5374 = _5376;
                                            _5376 += (isnan(_5467) ? _5483 : (isnan(_5483) ? _5467 : max(_5483, _5467)));
                                            _5375 = _5483;
                                            _5377++;
                                            continue;
                                        }
                                        if (!(_5371))
                                        {
                                            _5371 = true;
                                            _5372 = false;
                                        }
                                    }
                                }
                                vec3 radiance = vec3(0.0);
                                if (!_5372)
                                {
                                    float _6485 = (p.misc.w * p.misc.w) - 40449600.0;
                                    float _6490 = acos(clamp(sqrt(isnan(_6485) ? 0.0 : (isnan(0.0) ? _6485 : max(0.0, _6485))) / p.misc.w, -1.0, 1.0));
                                    float _6491 = 3.1415927410125732421875 - _6490;
                                    float _6494 = acos(clamp(_2239.z, -1.0, 1.0));
                                    float _6480;
                                    if (_6494 < _6491)
                                    {
                                        float _6506 = 1.0 - (_6494 / _6491);
                                        _6480 = (1.0 - sqrt(isnan(_6506) ? 0.0 : (isnan(0.0) ? _6506 : max(0.0, _6506)))) * 0.5;
                                    }
                                    else
                                    {
                                        float _6499 = (_6494 - _6491) / (isnan(9.9999999747524270787835121154785e-07) ? _6490 : (isnan(_6490) ? 9.9999999747524270787835121154785e-07 : max(_6490, 9.9999999747524270787835121154785e-07)));
                                        _6480 = (sqrt(isnan(_6499) ? 0.0 : (isnan(0.0) ? _6499 : max(0.0, _6499))) * 0.5) + 0.5;
                                    }
                                    float _6514 = atan(_2239.y, _2239.x);
                                    float _6481;
                                    if (_6514 < 0.0)
                                    {
                                        _6481 = _6514 + 6.283185482025146484375;
                                    }
                                    else
                                    {
                                        _6481 = _6514;
                                    }
                                    uvec2 _6529 = uvec2(textureSize(_6967, 0));
                                    vec2 _6536 = vec2(float(_6529.x), float(_6529.y));
                                    vec3 _6542 = textureLod(_6969, (vec2(_6481 * 0.15915493667125701904296875, _6480) * ((_6536 - vec2(1.0)) / _6536)) + (vec2(0.5) / _6536), 0.0).xyz;
                                    if (_5181)
                                    {
                                        normalW = vec3(dot(_6542, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * 0.300000011920928955078125);
                                    }
                                    else
                                    {
                                        normalW = _6542;
                                    }
                                    float _6560 = clamp(textureLod(_6959, uv, 0.0).w, 0.0, 1.0);
                                    radiance = normalW * clamp((pow(_479 + _6560, roughness * roughness) - 1.0) + _6560, 0.0, 1.0);
                                }
                                else
                                {
                                    bool _5913;
                                    {
                                        radiance = vec3(0.0);
                                        vec3 _5928 = hitRelative * transpose(mat3(spvWorkaroundRowMajor(p.viewToWorld)[0].xyz, spvWorkaroundRowMajor(p.viewToWorld)[1].xyz, spvWorkaroundRowMajor(p.viewToWorld)[2].xyz));
                                        float _5929 = _5928.z;
                                        if (_5929 <= p.unproject.z)
                                        {
                                            _5913 = false;
                                        }
                                        else
                                        {
                                            float _5988 = _5928.z;
                                            vec2 _5999 = (vec2((_5928.x * p.unproject.x) / _5988, ((-_5928.y) * p.unproject.y) / _5988) * 0.5) + vec2(0.5);
                                            bool _5914;
                                            if (any(lessThan(_5999, vec2(0.0))))
                                            {
                                                _5914 = true;
                                            }
                                            else
                                            {
                                                _5914 = any(greaterThan(_5999, vec2(1.0)));
                                            }
                                            if (_5914)
                                            {
                                                _5913 = false;
                                            }
                                            else
                                            {
                                                vec4 _5955 = texelFetch(_6962, ivec3(ivec2(_5999 * p.resolution.xy), 0).xy, 0);
                                                float _5956 = _5955.x;
                                                if (_5956 <= 0.0)
                                                {
                                                    _5913 = false;
                                                }
                                                else
                                                {
                                                    if (_5956 >= 0.89999997615814208984375)
                                                    {
                                                        _5913 = false;
                                                    }
                                                    else
                                                    {
                                                        float _6023 = ((2.0 * p.unproject.z) * p.unproject.w) / ((p.unproject.w + p.unproject.z) - ((1.0 - (2.0 * _5956)) * (p.unproject.w - p.unproject.z)));
                                                        if (abs(_5929 - _6023) > ((0.0199999995529651641845703125 * (isnan(1.0) ? _6023 : (isnan(_6023) ? 1.0 : max(_6023, 1.0)))) + voxel))
                                                        {
                                                            _5913 = false;
                                                        }
                                                        else
                                                        {
                                                            vec3 _5977 = textureLod(_6964, _5999, 0.0).xyz;
                                                            bvec3 _7122 = isnan(_5977);
                                                            bvec3 _7123 = isnan(vec3(0.0));
                                                            vec3 _7124 = max(_5977, vec3(0.0));
                                                            vec3 _7125 = vec3(_7122.x ? vec3(0.0).x : _7124.x, _7122.y ? vec3(0.0).y : _7124.y, _7122.z ? vec3(0.0).z : _7124.z);
                                                            radiance = vec3(_7123.x ? _5977.x : _7125.x, _7123.y ? _5977.y : _7125.y, _7123.z ? _5977.z : _7125.z);
                                                            _5913 = true;
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    if (!_5913)
                                    {
                                        float _2822 = voxel * 2.0;
                                        float tolerance = 0.25 + _2822;
                                        vec3 _2829 = hitRelative + p.cacheOrigin.xyz;
                                        vec2 litFound;
                                        float agreement;
                                        float cardDepth;
                                        bool _6025;
                                        {
                                            cardDepth = 0.0;
                                            litFound = vec2(0.0);
                                            agreement = 1000000000.0;
                                            if (int(p.cacheGrid.w) <= 0)
                                            {
                                                _6025 = false;
                                            }
                                            else
                                            {
                                                ivec3 _6069 = ivec3(floor((_2829 - p.cacheGrid.xyz) / vec3(p.cacheOrigin.w)));
                                                int _6287 = int((((uint(_6069.x) * 2376512323u) ^ (uint(_6069.y) * 3625334849u)) ^ (uint(_6069.z) * 3407524639u)) & uint(int(p.cacheGrid.w) - 1));
                                                uvec2 _6074 = uvec2(textureSize(_6974, 0));
                                                vec2 _6081 = vec2(float(_6074.x), float(_6074.y));
                                                int _6084 = int(p.cacheGrid.w);
                                                bool _6028 = false;
                                                bool _6029 = false;
                                                int _6030 = 0;
                                                bool _6031;
                                                ivec2 _6032;
                                                bool _6036;
                                                bool _6045;
                                                bool _6046;
                                                bool _6047;
                                                bool _6048;
                                                bool _6049;
                                                ivec2 _6288;
                                                for (;;)
                                                {
                                                    if (_6030 <= uCells._member0[_6084].y)
                                                    {
                                                        _6031 = !_6028;
                                                    }
                                                    else
                                                    {
                                                        _6031 = false;
                                                    }
                                                    if (!_6031)
                                                    {
                                                        break;
                                                    }
                                                    bool _6103 = _6030 == 0;
                                                    if (_6103)
                                                    {
                                                        _6032 = uCells._member0[_6287];
                                                    }
                                                    else
                                                    {
                                                        int _6292 = uCells._member0[_6084].x + ((_6030 - 1) * 6);
                                                        float _6308 = intBitsToFloat(uCellPages_1._member0[_6292 + 3]);
                                                        vec3 _6310 = _2829 - vec3(intBitsToFloat(uCellPages_1._member0[_6292]), intBitsToFloat(uCellPages_1._member0[_6292 + 1]), intBitsToFloat(uCellPages_1._member0[_6292 + 2]));
                                                        if (dot(_6310, _6310) > (_6308 * _6308))
                                                        {
                                                            _6288 = ivec2(0);
                                                        }
                                                        else
                                                        {
                                                            _6288 = ivec2(uCellPages_1._member0[_6292 + 4], uCellPages_1._member0[_6292 + 5]);
                                                        }
                                                        _6032 = _6288;
                                                    }
                                                    bool _6033 = _6028;
                                                    bool _6034 = _6029;
                                                    int _6035 = 0;
                                                    for (;;)
                                                    {
                                                        bool _6115_ladder_break = false;
                                                        {
                                                            if (_6035 < _6032.y)
                                                            {
                                                                _6036 = !_6033;
                                                            }
                                                            else
                                                            {
                                                                _6036 = false;
                                                            }
                                                            if (!_6036)
                                                            {
                                                                _6115_ladder_break = true;
                                                            }
                                                            else
                                                            {
                                                                int _6132 = _6032.x + _6035;
                                                                int _6135 = uCellPages_1._member0[_6132] * 10;
                                                                if (!((uPages_1._member0[_6135 + 5].w > 0.5) == _6103))
                                                                {
                                                                    int _6144 = _6135 + 9;
                                                                    vec3 _6148 = _2829 - uPages_1._member0[_6144].xyz;
                                                                    if (!(dot(_6148, _6148) > (uPages_1._member0[_6144].w * uPages_1._member0[_6144].w)))
                                                                    {
                                                                        int _6326 = uCellPages_1._member0[_6132] * 10;
                                                                        vec4 _6043 = uPages_1._member0[_6326];
                                                                        vec4 _6044 = uPages_1._member0[_6326 + 1];
                                                                        int _6332 = _6326 + 2;
                                                                        int _6335 = _6326 + 3;
                                                                        int _6338 = _6326 + 4;
                                                                        int _6344 = _6326 + 6;
                                                                        int _6347 = _6326 + 7;
                                                                        int _6350 = _6326 + 8;
                                                                        vec3 _6357 = _2829 - vec3(uPages_1._member0[_6344].w, uPages_1._member0[_6347].w, uPages_1._member0[_6350].w);
                                                                        vec3 _6042 = vec3(dot(uPages_1._member0[_6344].xyz, vec3(-0.0)), dot(uPages_1._member0[_6347].xyz, vec3(-0.0)), dot(uPages_1._member0[_6350].xyz, vec3(-0.0)));
                                                                        vec3 _6370 = vec3(dot(uPages_1._member0[_6344].xyz, _6357), dot(uPages_1._member0[_6347].xyz, _6357), dot(uPages_1._member0[_6350].xyz, _6357)) - uPages_1._member0[_6332].xyz;
                                                                        vec2 _6373 = vec2(uPages_1._member0[_6332].w, uPages_1._member0[_6335].w);
                                                                        bvec2 _7127 = isnan(_6373);
                                                                        bvec2 _7128 = isnan(vec2(9.9999999747524270787835121154785e-07));
                                                                        vec2 _7129 = max(_6373, vec2(9.9999999747524270787835121154785e-07));
                                                                        vec2 _7130 = vec2(_7127.x ? vec2(9.9999999747524270787835121154785e-07).x : _7129.x, _7127.y ? vec2(9.9999999747524270787835121154785e-07).y : _7129.y);
                                                                        vec2 _6380 = vec2(dot(_6370, uPages_1._member0[_6335].xyz), dot(_6370, uPages_1._member0[_6338].xyz)) / vec2(_7128.x ? _6373.x : _7130.x, _7128.y ? _6373.y : _7130.y);
                                                                        vec2 _6037 = _6380;
                                                                        float _6039 = -dot(_6370, uPages_1._member0[_6326 + 5].xyz);
                                                                        float _6040 = uPages_1._member0[_6338].w;
                                                                        vec3 _6041 = uPages_1._member0[_6326 + 5].xyz;
                                                                        if (abs(_6380.x) > 1.0)
                                                                        {
                                                                            _6045 = true;
                                                                        }
                                                                        else
                                                                        {
                                                                            _6045 = abs(_6037.y) > 1.0;
                                                                        }
                                                                        if (!(_6045))
                                                                        {
                                                                            if (false)
                                                                            {
                                                                                _6046 = dot(_6041, _6042) < (-0.0500000007450580596923828125);
                                                                            }
                                                                            else
                                                                            {
                                                                                _6046 = false;
                                                                            }
                                                                            if (!(_6046))
                                                                            {
                                                                                if (_6039 < ((-0.25) - _2822))
                                                                                {
                                                                                    _6047 = true;
                                                                                }
                                                                                else
                                                                                {
                                                                                    _6047 = _6039 > (_6040 + tolerance);
                                                                                }
                                                                                if (!(_6047))
                                                                                {
                                                                                    vec2 _6199 = (_6037 * 0.5) + vec2(0.5);
                                                                                    vec2 _6206 = (_6044.xy + (_6199 * _6044.zw)) / _6081;
                                                                                    if (!(textureLod(_6976, _6206, 0.0).w < 0.5))
                                                                                    {
                                                                                        float _6226 = abs((textureLod(_6978, _6206, 0.0).x * _6040) - _6039);
                                                                                        if (_6226 < agreement)
                                                                                        {
                                                                                            agreement = _6226;
                                                                                            cardDepth = _6040;
                                                                                            litFound = (_6043.xy + (_6199 * _6043.zw)) / vec3(p.cacheAtlas.xy, 0.0).xy;
                                                                                            _6048 = _6226 < 0.0199999995529651641845703125;
                                                                                            _6049 = true;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            _6048 = _6033;
                                                                                            _6049 = _6034;
                                                                                        }
                                                                                        _6033 = _6048;
                                                                                        _6034 = _6049;
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        if (_6115_ladder_break)
                                                        {
                                                            break;
                                                        }
                                                        _6035++;
                                                        continue;
                                                    }
                                                    _6028 = _6033;
                                                    _6029 = _6034;
                                                    _6030++;
                                                    continue;
                                                }
                                                _6025 = _6029;
                                            }
                                        }
                                        if (_6025)
                                        {
                                            screenAllowed = agreement <= (tolerance + (cardDepth * 0.5));
                                        }
                                        else
                                        {
                                            screenAllowed = false;
                                        }
                                        if (screenAllowed)
                                        {
                                            vec3 _3345 = textureLod(_6980, litFound, 0.0).xyz;
                                            bvec3 _7132 = isnan(_3345);
                                            bvec3 _7133 = isnan(vec3(0.0));
                                            vec3 _7134 = max(_3345, vec3(0.0));
                                            vec3 _7135 = vec3(_7132.x ? vec3(0.0).x : _7134.x, _7132.y ? vec3(0.0).y : _7134.y, _7132.z ? vec3(0.0).z : _7134.z);
                                            radiance = vec3(_7133.x ? _3345.x : _7135.x, _7133.y ? _3345.y : _7135.y, _7133.z ? _3345.z : _7135.z) * p.trace.w;
                                            crossed = true;
                                        }
                                        else
                                        {
                                            crossed = _5913;
                                        }
                                    }
                                    else
                                    {
                                        crossed = _5913;
                                    }
                                    if (!crossed)
                                    {
                                        float _6394 = (p.misc.w * p.misc.w) - 40449600.0;
                                        float _6399 = acos(clamp(sqrt(isnan(_6394) ? 0.0 : (isnan(0.0) ? _6394 : max(0.0, _6394))) / p.misc.w, -1.0, 1.0));
                                        float _6400 = 3.1415927410125732421875 - _6399;
                                        float _6403 = acos(clamp(_2239.z, -1.0, 1.0));
                                        float _6389;
                                        if (_6403 < _6400)
                                        {
                                            float _6415 = 1.0 - (_6403 / _6400);
                                            _6389 = (1.0 - sqrt(isnan(_6415) ? 0.0 : (isnan(0.0) ? _6415 : max(0.0, _6415)))) * 0.5;
                                        }
                                        else
                                        {
                                            float _6408 = (_6403 - _6400) / (isnan(9.9999999747524270787835121154785e-07) ? _6399 : (isnan(_6399) ? 9.9999999747524270787835121154785e-07 : max(_6399, 9.9999999747524270787835121154785e-07)));
                                            _6389 = (sqrt(isnan(_6408) ? 0.0 : (isnan(0.0) ? _6408 : max(0.0, _6408))) * 0.5) + 0.5;
                                        }
                                        float _6423 = atan(_2239.y, _2239.x);
                                        float _6390;
                                        if (_6423 < 0.0)
                                        {
                                            _6390 = _6423 + 6.283185482025146484375;
                                        }
                                        else
                                        {
                                            _6390 = _6423;
                                        }
                                        uvec2 _6438 = uvec2(textureSize(_6967, 0));
                                        vec2 _6445 = vec2(float(_6438.x), float(_6438.y));
                                        vec3 _6451 = textureLod(_6969, (vec2(_6390 * 0.15915493667125701904296875, _6389) * ((_6445 - vec2(1.0)) / _6445)) + (vec2(0.5) / _6445), 0.0).xyz;
                                        if (_5181)
                                        {
                                            normalW = vec3(dot(_6451, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * 0.300000011920928955078125);
                                        }
                                        else
                                        {
                                            normalW = _6451;
                                        }
                                        float _6469 = clamp(textureLod(_6959, uv, 0.0).w, 0.0, 1.0);
                                        radiance = normalW * clamp((pow(_479 + _6469, roughness * roughness) - 1.0) + _6469, 0.0, 1.0);
                                    }
                                }
                                float _3385 = isnan(radiance.z) ? radiance.y : (isnan(radiance.y) ? radiance.z : max(radiance.y, radiance.z));
                                float _3386 = isnan(_3385) ? radiance.x : (isnan(radiance.x) ? _3385 : max(radiance.x, _3385));
                                if (_3386 > p.trace.z)
                                {
                                    radiance *= (p.trace.z / _3386);
                                }
                                if (water)
                                {
                                    float _6576 = (p.misc.w * p.misc.w) - 40449600.0;
                                    float _6581 = acos(clamp(sqrt(isnan(_6576) ? 0.0 : (isnan(0.0) ? _6576 : max(0.0, _6576))) / p.misc.w, -1.0, 1.0));
                                    float _6582 = 3.1415927410125732421875 - _6581;
                                    float _6585 = acos(clamp(_2239.z, -1.0, 1.0));
                                    float _6571;
                                    if (_6585 < _6582)
                                    {
                                        float _6597 = 1.0 - (_6585 / _6582);
                                        _6571 = (1.0 - sqrt(isnan(_6597) ? 0.0 : (isnan(0.0) ? _6597 : max(0.0, _6597)))) * 0.5;
                                    }
                                    else
                                    {
                                        float _6590 = (_6585 - _6582) / (isnan(9.9999999747524270787835121154785e-07) ? _6581 : (isnan(_6581) ? 9.9999999747524270787835121154785e-07 : max(_6581, 9.9999999747524270787835121154785e-07)));
                                        _6571 = (sqrt(isnan(_6590) ? 0.0 : (isnan(0.0) ? _6590 : max(0.0, _6590))) * 0.5) + 0.5;
                                    }
                                    float _6605 = atan(_2239.y, _2239.x);
                                    float _6572;
                                    if (_6605 < 0.0)
                                    {
                                        _6572 = _6605 + 6.283185482025146484375;
                                    }
                                    else
                                    {
                                        _6572 = _6605;
                                    }
                                    uvec2 _6620 = uvec2(textureSize(_6967, 0));
                                    vec2 _6627 = vec2(float(_6620.x), float(_6620.y));
                                    b = textureLod(_6969, (vec2(_6572 * 0.15915493667125701904296875, _6571) * ((_6627 - vec2(1.0)) / _6627)) + (vec2(0.5) / _6627), 0.0).xyz * clamp(_2239.z * 20.0, 0.0, 1.0);
                                }
                                else
                                {
                                    b = vec3(0.0);
                                }
                                float _3414 = screenWeight;
                                screenWeight = 1.0;
                                a += (((radiance - b) * up) * (1.0 - _3414));
                            }
                            if (!raw)
                            {
                                screenAllowed = !water;
                            }
                            else
                            {
                                screenAllowed = false;
                            }
                            if (screenAllowed)
                            {
                                screenAllowed = roughness > 0.0500000007450580596923828125;
                            }
                            else
                            {
                                screenAllowed = false;
                            }
                            float spread;
                            if (screenAllowed)
                            {
                                spread = 2.0 + roughness;
                            }
                            else
                            {
                                if (traces)
                                {
                                    marches = true;
                                }
                                if (marches)
                                {
                                    puddle = 1.0;
                                }
                                else
                                {
                                    puddle = screenWeight;
                                }
                                spread = puddle;
                            }
                            imageStore(uReflection, ivec2(gl_GlobalInvocationID.xy), vec4(a, spread));
                        }
                    }
                }
            }
        }
    }
}

