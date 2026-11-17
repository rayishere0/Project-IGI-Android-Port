#version 430
#extension GL_EXT_texture_shadow_lod : enable
#ifdef GL_EXT_texture_shadow_lod
#define spvShadowLod0(s, c) textureLod(s, c, 0.0)
#else
#define spvShadowLod0(s, c) textureGrad(s, c, vec2(0.0), vec2(0.0))
#endif
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

#ifndef SPIRV_CROSS_CONSTANT_ID_64
#define SPIRV_CROSS_CONSTANT_ID_64 1
#endif
const int cClipYDown = SPIRV_CROSS_CONSTANT_ID_64;

struct _Array_std140_matrix_float_4_4_4
{
    mat4 data[4];
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

struct _Array_std140_vector_float_4_160
{
    vec4 data[160];
};

const bool _127 = (cClipYDown != 0);
uniform vec2 _2344_frag[12] = vec2[](vec2(-0.3260000050067901611328125, -0.4059999883174896240234375), vec2(-0.839999973773956298828125, -0.07400000095367431640625), vec2(-0.69599997997283935546875, 0.4569999873638153076171875), vec2(-0.20299999415874481201171875, 0.620999991893768310546875), vec2(0.96200001239776611328125, -0.194999992847442626953125), vec2(0.472999989986419677734375, -0.4799999892711639404296875), vec2(0.518999993801116943359375, 0.767000019550323486328125), vec2(0.185000002384185791015625, -0.89300000667572021484375), vec2(0.507000029087066650390625, 0.064000003039836883544921875), vec2(0.89600002765655517578125, 0.412000000476837158203125), vec2(-0.3219999969005584716796875, -0.933000028133392333984375), vec2(-0.791999995708465576171875, -0.597999989986419677734375));
uniform vec2 _3596_frag[4] = vec2[](vec2(0.0), vec2(0.430000007152557373046875, 0.709999978542327880859375), vec2(0.790000021457672119140625, 0.23999999463558197021484375), vec2(0.17000000178813934326171875, 0.4600000083446502685546875));
uvec3 _13274;
float _13275;

layout(binding = 0, std140) uniform Gi_std140
{
    vec4 unproject;
    vec4 probeOrigin;
    vec4 probeInvCount;
    vec4 probeMisc;
    vec4 probeSky;
    vec4 camera;
    vec4 giParams;
    layout(row_major) mat4 viewToWorld;
    vec4 cascadeSplits;
    vec4 shadowConfig;
    layout(row_major) _Array_std140_matrix_float_4_4_4 cascadeMatrix;
    vec4 wetness0;
    vec4 wetness1;
    vec4 shelterMap0;
    vec4 shelterMap1;
    vec4 shelterMap2;
    vec4 fog;
    FlashlightParams_std140 flashlight;
} gi;

layout(binding = 2, std140) uniform Light_std140
{
    vec4 sunDirectionModel;
    vec4 sunColourScale;
    vec4 ambient;
    vec4 sky;
    vec4 moon;
    vec4 stars;
} light;

layout(binding = 1, std140) uniform Lamps_std140
{
    vec4 control;
    vec4 source;
    _Array_std140_vector_float_4_160 positionRadius;
    _Array_std140_vector_float_4_160 colourIntensity;
    _Array_std140_vector_float_4_160 direction;
    _Array_std140_vector_float_4_160 rect;
} lamps;

layout(binding = 0) uniform sampler2D _13281;
layout(binding = 2) uniform sampler2D _13284;
layout(binding = 3) uniform sampler2D _13287;
layout(binding = 4) uniform sampler2D _13290;
layout(binding = 19) uniform sampler3D _13292;
layout(binding = 13) uniform sampler2D _13295;
layout(binding = 14) uniform sampler2D _13297;
layout(binding = 15) uniform sampler2D _13299;
layout(binding = 1) uniform sampler2D _13302;
layout(binding = 12) uniform sampler2D _13304;
layout(binding = 9) uniform sampler2D _13306;
layout(binding = 21) uniform sampler2D _13309;
layout(binding = 10) uniform sampler2DArray _13312;
layout(binding = 11) uniform sampler2DArrayShadow _13314;
layout(binding = 17) uniform sampler2D _13316;
layout(binding = 20) uniform sampler2D _13319;
layout(binding = 18) uniform sampler2D _13322;
layout(binding = 5) uniform sampler3D _13324;
layout(binding = 6) uniform sampler3D _13326;
layout(binding = 7) uniform sampler3D _13328;
layout(binding = 8) uniform sampler3D _13330;
layout(binding = 16) uniform sampler2D _13333;

#ifdef GL_ARB_shader_draw_parameters
#define SPIRV_Cross_BaseVertex gl_BaseVertexARB
#else
uniform int SPIRV_Cross_BaseVertex;
#endif
layout(location = 0) out vec4 entryPointParam_fragmentMain;
layout(location = 0) in vec2 input_uv;

mat4 spvWorkaroundRowMajor(mat4 wrap) { return wrap; }

void main()
{
    bool _9635 = false;
    bool _8938 = false;
    {
        float _5334 = fwidth(input_uv.x);
        vec4 _5342 = texelFetch(_13281, ivec3(ivec2(gl_FragCoord.xy), 0).xy, 0);
        vec3 albedo = _5342.xyz;
        vec4 _5351 = texelFetch(_13284, ivec3(ivec2(gl_FragCoord.xy), 0).xy, 0);
        vec3 baked = texelFetch(_13287, ivec3(ivec2(gl_FragCoord.xy), 0).xy, 0).xyz;
        vec4 _5371 = vec4(texelFetch(_13290, ivec3(ivec2(gl_FragCoord.xy), 0).xy, 0).x, 0.0, 0.0, 0.0);
        float depth = _5371.x;
        int debugView = int(light.ambient.w + 0.5);
        bool _152;
        vec3 sunLight;
        if (depth <= 0.0)
        {
            if (debugView != 0)
            {
                _152 = debugView != 11;
            }
            else
            {
                _152 = false;
            }
            if (_152)
            {
                entryPointParam_fragmentMain = vec4(0.0, 0.0, 0.0, 1.0);
            }
            else
            {
                if (light.sky.x > 0.5)
                {
                    float _5377 = (_5351.y * 255.0) - 128.0;
                    float _5372;
                    if (_5377 > 0.5)
                    {
                        _5372 = _5377 * 0.0625;
                    }
                    else
                    {
                        _5372 = 1.0;
                    }
                    vec3 _468 = albedo * _5372;
                    vec3 _5385;
                    {
                        if (gi.fog.z <= 0.0)
                        {
                            _5385 = _468;
                        }
                        else
                        {
                            float _5400 = (gi.unproject.w * gi.fog.x) + gi.fog.y;
                            vec4 _5415 = textureLod(_13292, vec3(input_uv, clamp(((log2(isnan(9.9999999747524270787835121154785e-07) ? _5400 : (isnan(_5400) ? 9.9999999747524270787835121154785e-07 : max(_5400, 9.9999999747524270787835121154785e-07))) * gi.fog.z) - 1.0) * gi.fog.w, 0.0, 1.0)), 0.0);
                            _5385 = (_468 * _5415.w) + _5415.xyz;
                        }
                    }
                    entryPointParam_fragmentMain = vec4(_5385, 1.0);
                }
                else
                {
                    vec2 ndc = (input_uv * 2.0) - vec2(1.0);
                    vec3 _543 = normalize((vec4(normalize(vec3(ndc.x / gi.unproject.x, (-ndc.y) / gi.unproject.y, 1.0)), 0.0) * spvWorkaroundRowMajor(gi.viewToWorld)).xyz);
                    uint _5424 = uvec2(textureSize(_13295, 0)).y;
                    float _5441 = (gi.giParams.w * gi.giParams.w) - 40449600.0;
                    float _5446 = acos(clamp(sqrt(isnan(_5441) ? 0.0 : (isnan(0.0) ? _5441 : max(0.0, _5441))) / gi.giParams.w, -1.0, 1.0));
                    float _5447 = 3.1415927410125732421875 - _5446;
                    float _5450 = acos(clamp(_543.z, -1.0, 1.0));
                    float _5436;
                    if (_5450 < _5447)
                    {
                        float _5462 = 1.0 - (_5450 / _5447);
                        _5436 = (1.0 - sqrt(isnan(_5462) ? 0.0 : (isnan(0.0) ? _5462 : max(0.0, _5462)))) * 0.5;
                    }
                    else
                    {
                        float _5455 = (_5450 - _5447) / (isnan(9.9999999747524270787835121154785e-07) ? _5446 : (isnan(_5446) ? 9.9999999747524270787835121154785e-07 : max(_5446, 9.9999999747524270787835121154785e-07)));
                        _5436 = (sqrt(isnan(_5455) ? 0.0 : (isnan(0.0) ? _5455 : max(0.0, _5455))) * 0.5) + 0.5;
                    }
                    float _5470 = atan(_543.y, _543.x);
                    float _5437;
                    if (_5470 < 0.0)
                    {
                        _5437 = _5470 + 6.283185482025146484375;
                    }
                    else
                    {
                        _5437 = _5470;
                    }
                    vec2 _5479 = vec2(_5437 * 0.15915493667125701904296875, _5436);
                    float _5433 = float(_5424);
                    float _5484 = _5479.y;
                    float _5488 = _5433 - 1.0;
                    float _5490 = (floor(_5433 * 0.5) - 1.0) / (isnan(1.0) ? _5488 : (isnan(_5488) ? 1.0 : max(_5488, 1.0)));
                    _5479.y = isnan(_5490) ? _5484 : (isnan(_5484) ? _5490 : min(_5484, _5490));
                    uvec2 _5498 = uvec2(textureSize(_13295, 0));
                    vec2 _5505 = vec2(float(_5498.x), float(_5498.y));
                    float _686 = 2.0 * _5334;
                    float sunPixelAngle = _686 / (isnan(9.9999997473787516355514526367188e-05) ? gi.unproject.x : (isnan(gi.unproject.x) ? 9.9999997473787516355514526367188e-05 : max(gi.unproject.x, 9.9999997473787516355514526367188e-05)));
                    vec3 _699 = normalize((vec4(light.sunDirectionModel.xyz, 0.0) * spvWorkaroundRowMajor(gi.viewToWorld)).xyz);
                    vec3 _5522;
                    {
                        float _5527 = dot(_543, _699);
                        bool _5523;
                        if (_5527 <= 0.999000012874603271484375)
                        {
                            _5523 = true;
                        }
                        else
                        {
                            _5523 = _699.z <= (-0.0199999995529651641845703125);
                        }
                        if (_5523)
                        {
                            _5522 = vec3(0.0);
                        }
                        else
                        {
                            float _5538 = acos(clamp(_5527, 0.0, 1.0));
                            float _5539 = isnan(sunPixelAngle) ? 0.0046799997799098491668701171875 : (isnan(0.0046799997799098491668701171875) ? sunPixelAngle : max(0.0046799997799098491668701171875, sunPixelAngle));
                            float _5540 = sunPixelAngle * 0.5;
                            float _5544 = 1.0 - smoothstep(_5539 - _5540, _5539 + _5540, _5538);
                            if (_5544 <= 0.0)
                            {
                                _5522 = vec3(0.0);
                            }
                            else
                            {
                                float _5549 = clamp(_5538 / _5539, 0.0, 1.0);
                                float _5551 = 1.0 - (_5549 * _5549);
                                float _5558 = 6.283185482025146484375 * (1.0 - cos(_5539));
                                vec3 _5561 = (light.sunColourScale.xyz * light.sunColourScale.w) / vec3(isnan(9.9999999392252902907785028219223e-09) ? _5558 : (isnan(_5558) ? 9.9999999392252902907785028219223e-09 : max(_5558, 9.9999999392252902907785028219223e-09)));
                                bvec3 _13390 = isnan(_5561);
                                bvec3 _13391 = isnan(vec3(4000.0));
                                vec3 _13392 = min(_5561, vec3(4000.0));
                                vec3 _13393 = vec3(_13390.x ? vec3(4000.0).x : _13392.x, _13390.y ? vec3(4000.0).y : _13392.y, _13390.z ? vec3(4000.0).z : _13392.z);
                                _5522 = vec3(_13391.x ? _5561.x : _13393.x, _13391.y ? _5561.y : _13393.y, _13391.z ? _5561.z : _13393.z) * ((0.4000000059604644775390625 + (0.60000002384185791015625 * sqrt(isnan(0.0) ? _5551 : (isnan(_5551) ? 0.0 : max(_5551, 0.0))))) * _5544);
                            }
                        }
                    }
                    vec3 background = textureLod(_13297, (_5479 * ((_5505 - vec2(1.0)) / _5505)) + (vec2(0.5) / _5505), 0.0).xyz + _5522;
                    if (light.stars.x > 0.0)
                    {
                        _152 = true;
                    }
                    else
                    {
                        _152 = light.moon.w > 0.0;
                    }
                    if (_152)
                    {
                        float pixelAngle = _686 / (isnan(9.9999997473787516355514526367188e-05) ? gi.unproject.x : (isnan(gi.unproject.x) ? 9.9999997473787516355514526367188e-05 : max(gi.unproject.x, 9.9999997473787516355514526367188e-05)));
                        vec3 _798 = normalize(light.moon.xyz);
                        vec3 _5568;
                        {
                            vec3 _5573 = vec3(0.0, 0.0, gi.giParams.w);
                            vec2 _5597;
                            {
                                float _5601 = dot(_543, _543);
                                float _5602 = dot(_5573, _543);
                                float _5610 = (4.0 * (_5602 * _5602)) - ((4.0 * _5601) * (dot(_5573, _5573) - 40449600.0));
                                if (_5610 < 0.0)
                                {
                                    _5597 = vec2(-1.0);
                                }
                                else
                                {
                                    float _5614 = sqrt(_5610);
                                    float _5615 = _5602 * (-2.0);
                                    float _5617 = 2.0 * _5601;
                                    _5597 = vec2((_5615 - _5614) / _5617, (_5615 + _5614) / _5617);
                                }
                            }
                            bool _5569;
                            if (_5597.x > 0.0)
                            {
                                _5569 = true;
                            }
                            else
                            {
                                _5569 = _5597.y > 0.0;
                            }
                            if (_5569)
                            {
                                _5568 = vec3(0.0);
                            }
                            else
                            {
                                float _5585 = _543.z;
                                float _5627 = gi.giParams.w * gi.giParams.w;
                                float _5628 = _5627 - 40449600.0;
                                float _5630 = sqrt(isnan(_5628) ? 0.0 : (isnan(0.0) ? _5628 : max(0.0, _5628)));
                                float _5634 = (_5627 * ((_5585 * _5585) - 1.0)) + 41216400.0;
                                float _5639 = ((-gi.giParams.w) * _5585) + sqrt(isnan(_5634) ? 0.0 : (isnan(0.0) ? _5634 : max(0.0, _5634)));
                                vec3 _5592 = textureLod(_13299, vec2(((isnan(_5639) ? 0.0 : (isnan(0.0) ? _5639 : max(0.0, _5639))) - (6420.0 - gi.giParams.w)) / ((-5544.3291015625) + (_5630 + gi.giParams.w)), _5630 * 0.001141981221735477447509765625), 0.0).xyz;
                                _5568 = _5592 * _5592;
                            }
                        }
                        float _5656 = clamp(1.0 - light.stars.y, 0.0, 1.0);
                        bool _5651;
                        if (light.stars.x > 0.0)
                        {
                            _5651 = _5656 > 0.0;
                        }
                        else
                        {
                            _5651 = false;
                        }
                        vec3 _5652;
                        if (_5651)
                        {
                            vec3 _5772 = _798 - (vec3(0.0, 0.62000000476837158203125, 0.785000026226043701171875) * dot(_798, vec3(0.0, 0.62000000476837158203125, 0.785000026226043701171875)));
                            float _5773 = length(_5772);
                            vec3 _5767;
                            if (_5773 > 9.9999997473787516355514526367188e-05)
                            {
                                _5767 = _5772 / vec3(_5773);
                            }
                            else
                            {
                                _5767 = vec3(1.0, 0.0, 0.0);
                            }
                            vec3 _5786 = vec3(dot(_543, _5767), dot(_543, cross(vec3(0.0, 0.62000000476837158203125, 0.785000026226043701171875), _5767)), dot(_543, vec3(0.0, 0.62000000476837158203125, 0.785000026226043701171875)));
                            float _5671 = 0.3499999940395355224609375 + (0.64999997615814208984375 * clamp(1.0 - (_543.z * 2.5), 0.0, 1.0));
                            vec3 _5788;
                            {
                                vec2 _5789;
                                uint _5857;
                                {
                                    vec3 _5863 = abs(_5786);
                                    float _5864 = _5863.x;
                                    float _5865 = _5863.y;
                                    bool _5858;
                                    if (_5864 >= _5865)
                                    {
                                        _5858 = _5864 >= _5863.z;
                                    }
                                    else
                                    {
                                        _5858 = false;
                                    }
                                    uint _5859;
                                    if (_5858)
                                    {
                                        _5789 = _5786.yz / vec2(_5864);
                                        if (_5786.x > 0.0)
                                        {
                                            _5859 = 0u;
                                        }
                                        else
                                        {
                                            _5859 = 1u;
                                        }
                                        _5857 = _5859;
                                    }
                                    else
                                    {
                                        float _5884 = _5863.z;
                                        if (_5865 >= _5884)
                                        {
                                            _5789 = _5786.xz / vec2(_5865);
                                            if (_5786.y > 0.0)
                                            {
                                                _5859 = 2u;
                                            }
                                            else
                                            {
                                                _5859 = 3u;
                                            }
                                            _5857 = _5859;
                                        }
                                        else
                                        {
                                            _5789 = _5786.xy / vec2(_5884);
                                            if (_5786.z > 0.0)
                                            {
                                                _5859 = 4u;
                                            }
                                            else
                                            {
                                                _5859 = 5u;
                                            }
                                            _5857 = _5859;
                                        }
                                    }
                                }
                                vec2 _5799 = floor(((_5789 * 0.5) + vec2(0.5)) * 55.0);
                                uvec3 _5806 = uvec3(uint(_5799.x), uint(_5799.y), (_5857 * 7919u) + 17u);
                                uvec3 _5919 = (_5806 * uvec3(1664525u)) + uvec3(1013904223u);
                                _5919.x = _5919.x + (_5919.y * _5919.z);
                                _5919.y = _5919.y + (_5919.z * _5919.x);
                                _5919.z = _5919.z + (_5919.x * _5919.y);
                                uvec3 _5946 = _5919 ^ (_5919 >> uvec3(16u));
                                _5946.x = _5946.x + (_5946.y * _5946.z);
                                _5946.y = _5946.y + (_5946.z * _5946.x);
                                _5946.z = _5946.z + (_5946.x * _5946.y);
                                vec3 _5912 = vec3(_5946) * 2.3283064365386962890625e-10;
                                if (_5912.z > 0.5)
                                {
                                    _5788 = vec3(0.0);
                                }
                                else
                                {
                                    uvec3 _5978 = ((_5806 + uvec3(101u, 211u, 307u)) * uvec3(1664525u)) + uvec3(1013904223u);
                                    _5978.x = _5978.x + (_5978.y * _5978.z);
                                    _5978.y = _5978.y + (_5978.z * _5978.x);
                                    _5978.z = _5978.z + (_5978.x * _5978.y);
                                    uvec3 _6005 = _5978 ^ (_5978 >> uvec3(16u));
                                    _6005.x = _6005.x + (_6005.y * _6005.z);
                                    _6005.y = _6005.y + (_6005.z * _6005.x);
                                    _6005.z = _6005.z + (_6005.x * _6005.y);
                                    vec3 _5971 = vec3(_6005) * 2.3283064365386962890625e-10;
                                    vec2 _5823 = ((((_5799 + vec2(0.25)) + (_5912.xy * 0.5)) * vec2(0.01818181760609149932861328125)) - vec2(0.5)) * 2.0;
                                    vec3 _6026;
                                    if (_5857 == 0u)
                                    {
                                        _6026 = vec3(1.0, _5823);
                                    }
                                    else
                                    {
                                        if (_5857 == 1u)
                                        {
                                            _6026 = vec3(-1.0, _5823);
                                        }
                                        else
                                        {
                                            if (_5857 == 2u)
                                            {
                                                _6026 = vec3(_5823.x, 1.0, _5823.y);
                                            }
                                            else
                                            {
                                                if (_5857 == 3u)
                                                {
                                                    _6026 = vec3(_5823.x, -1.0, _5823.y);
                                                }
                                                else
                                                {
                                                    if (_5857 == 4u)
                                                    {
                                                        _6026 = vec3(_5823, 1.0);
                                                    }
                                                    else
                                                    {
                                                        _6026 = vec3(_5823, -1.0);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    float _5826 = length(_5786 - normalize(_6026));
                                    float _5827 = pixelAngle * 0.60000002384185791015625;
                                    float _5828 = isnan(9.9999997473787516355514526367188e-06) ? _5827 : (isnan(_5827) ? 9.9999997473787516355514526367188e-06 : max(_5827, 9.9999997473787516355514526367188e-06));
                                    float _5844 = _5971.z;
                                    vec3 _6070;
                                    {
                                        if (_5844 < 0.180000007152557373046875)
                                        {
                                            _6070 = vec3(0.7200000286102294921875, 0.819999992847442626953125, 1.0);
                                        }
                                        else
                                        {
                                            if (_5844 < 0.62000000476837158203125)
                                            {
                                                _6070 = vec3(0.949999988079071044921875, 0.959999978542327880859375, 1.0);
                                            }
                                            else
                                            {
                                                if (_5844 < 0.86000001430511474609375)
                                                {
                                                    _6070 = vec3(1.0, 0.920000016689300537109375, 0.7599999904632568359375);
                                                }
                                                else
                                                {
                                                    _6070 = vec3(1.0, 0.7599999904632568359375, 0.519999980926513671875);
                                                }
                                            }
                                        }
                                    }
                                    _5788 = _6070 * (((0.014999999664723873138427734375 + (0.98500001430511474609375 * pow(_5971.x, 12.0))) * (1.0 + ((_5671 * 0.449999988079071044921875) * sin((light.stars.z * (2.0 + (6.0 * _5971.y))) + (_5844 * 60.0))))) * exp((-(_5826 * _5826)) / ((2.0 * _5828) * _5828)));
                                }
                            }
                            vec3 _6086;
                            {
                                vec2 _6087;
                                uint _6155;
                                {
                                    vec3 _6161 = abs(_5786);
                                    float _6162 = _6161.x;
                                    float _6163 = _6161.y;
                                    bool _6156;
                                    if (_6162 >= _6163)
                                    {
                                        _6156 = _6162 >= _6161.z;
                                    }
                                    else
                                    {
                                        _6156 = false;
                                    }
                                    uint _6157;
                                    if (_6156)
                                    {
                                        _6087 = _5786.yz / vec2(_6162);
                                        if (_5786.x > 0.0)
                                        {
                                            _6157 = 0u;
                                        }
                                        else
                                        {
                                            _6157 = 1u;
                                        }
                                        _6155 = _6157;
                                    }
                                    else
                                    {
                                        float _6182 = _6161.z;
                                        if (_6163 >= _6182)
                                        {
                                            _6087 = _5786.xz / vec2(_6163);
                                            if (_5786.y > 0.0)
                                            {
                                                _6157 = 2u;
                                            }
                                            else
                                            {
                                                _6157 = 3u;
                                            }
                                            _6155 = _6157;
                                        }
                                        else
                                        {
                                            _6087 = _5786.xy / vec2(_6182);
                                            if (_5786.z > 0.0)
                                            {
                                                _6157 = 4u;
                                            }
                                            else
                                            {
                                                _6157 = 5u;
                                            }
                                            _6155 = _6157;
                                        }
                                    }
                                }
                                vec2 _6097 = floor(((_6087 * 0.5) + vec2(0.5)) * 150.0);
                                uvec3 _6104 = uvec3(uint(_6097.x), uint(_6097.y), (_6155 * 7919u) + 131u);
                                uvec3 _6217 = (_6104 * uvec3(1664525u)) + uvec3(1013904223u);
                                _6217.x = _6217.x + (_6217.y * _6217.z);
                                _6217.y = _6217.y + (_6217.z * _6217.x);
                                _6217.z = _6217.z + (_6217.x * _6217.y);
                                uvec3 _6244 = _6217 ^ (_6217 >> uvec3(16u));
                                _6244.x = _6244.x + (_6244.y * _6244.z);
                                _6244.y = _6244.y + (_6244.z * _6244.x);
                                _6244.z = _6244.z + (_6244.x * _6244.y);
                                vec3 _6210 = vec3(_6244) * 2.3283064365386962890625e-10;
                                if (_6210.z > 0.300000011920928955078125)
                                {
                                    _6086 = vec3(0.0);
                                }
                                else
                                {
                                    uvec3 _6276 = ((_6104 + uvec3(101u, 211u, 307u)) * uvec3(1664525u)) + uvec3(1013904223u);
                                    _6276.x = _6276.x + (_6276.y * _6276.z);
                                    _6276.y = _6276.y + (_6276.z * _6276.x);
                                    _6276.z = _6276.z + (_6276.x * _6276.y);
                                    uvec3 _6303 = _6276 ^ (_6276 >> uvec3(16u));
                                    _6303.x = _6303.x + (_6303.y * _6303.z);
                                    _6303.y = _6303.y + (_6303.z * _6303.x);
                                    _6303.z = _6303.z + (_6303.x * _6303.y);
                                    vec3 _6269 = vec3(_6303) * 2.3283064365386962890625e-10;
                                    vec2 _6121 = ((((_6097 + vec2(0.25)) + (_6210.xy * 0.5)) * vec2(0.006666666828095912933349609375)) - vec2(0.5)) * 2.0;
                                    vec3 _6324;
                                    if (_6155 == 0u)
                                    {
                                        _6324 = vec3(1.0, _6121);
                                    }
                                    else
                                    {
                                        if (_6155 == 1u)
                                        {
                                            _6324 = vec3(-1.0, _6121);
                                        }
                                        else
                                        {
                                            if (_6155 == 2u)
                                            {
                                                _6324 = vec3(_6121.x, 1.0, _6121.y);
                                            }
                                            else
                                            {
                                                if (_6155 == 3u)
                                                {
                                                    _6324 = vec3(_6121.x, -1.0, _6121.y);
                                                }
                                                else
                                                {
                                                    if (_6155 == 4u)
                                                    {
                                                        _6324 = vec3(_6121, 1.0);
                                                    }
                                                    else
                                                    {
                                                        _6324 = vec3(_6121, -1.0);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    float _6124 = length(_5786 - normalize(_6324));
                                    float _6125 = pixelAngle * 0.60000002384185791015625;
                                    float _6126 = isnan(9.9999997473787516355514526367188e-06) ? _6125 : (isnan(_6125) ? 9.9999997473787516355514526367188e-06 : max(_6125, 9.9999997473787516355514526367188e-06));
                                    float _6142 = _6269.z;
                                    vec3 _6368;
                                    {
                                        if (_6142 < 0.180000007152557373046875)
                                        {
                                            _6368 = vec3(0.7200000286102294921875, 0.819999992847442626953125, 1.0);
                                        }
                                        else
                                        {
                                            if (_6142 < 0.62000000476837158203125)
                                            {
                                                _6368 = vec3(0.949999988079071044921875, 0.959999978542327880859375, 1.0);
                                            }
                                            else
                                            {
                                                if (_6142 < 0.86000001430511474609375)
                                                {
                                                    _6368 = vec3(1.0, 0.920000016689300537109375, 0.7599999904632568359375);
                                                }
                                                else
                                                {
                                                    _6368 = vec3(1.0, 0.7599999904632568359375, 0.519999980926513671875);
                                                }
                                            }
                                        }
                                    }
                                    _6086 = _6368 * (((0.014999999664723873138427734375 + (0.98500001430511474609375 * pow(_6269.x, 12.0))) * (1.0 + ((_5671 * 0.449999988079071044921875) * sin((light.stars.z * (2.0 + (6.0 * _6269.y))) + (_6142 * 60.0))))) * exp((-(_6124 * _6124)) / ((2.0 * _6126) * _6126)));
                                }
                            }
                            float _5677 = dot(_5786, normalize(vec3(0.4600000083446502685546875, -0.519999980926513671875, 0.7200000286102294921875)));
                            vec3 _5682 = _5786 * 9.0;
                            vec3 _6385 = floor(_5682);
                            vec3 _6386 = _5682 - _6385;
                            vec3 _6391 = (_6386 * _6386) * (vec3(3.0) - (_6386 * 2.0));
                            uvec3 _6394 = uvec3(ivec3(_6385) + ivec3(4096));
                            uvec3 _6439 = (_6394 * uvec3(1664525u)) + uvec3(1013904223u);
                            _6439.x = _6439.x + (_6439.y * _6439.z);
                            _6439.y = _6439.y + (_6439.z * _6439.x);
                            _6439.z = _6439.z + (_6439.x * _6439.y);
                            uvec3 _6466 = _6439 ^ (_6439 >> uvec3(16u));
                            uvec3 _12709;
                            _12709.x = _6466.x + (_6466.y * _6466.z);
                            uvec3 _12712 = _12709;
                            _12712.y = _12709.y + (_12709.z * _12709.x);
                            uvec3 _12715 = _12709;
                            _12715.z = _12709.z + (_12709.x * _12709.y);
                            uvec3 _6498 = ((_6394 + uvec3(1u, 0u, 0u)) * uvec3(1664525u)) + uvec3(1013904223u);
                            _6498.x = _6498.x + (_6498.y * _6498.z);
                            _6498.y = _6498.y + (_6498.z * _6498.x);
                            _6498.z = _6498.z + (_6498.x * _6498.y);
                            uvec3 _6525 = _6498 ^ (_6498 >> uvec3(16u));
                            uvec3 _12727;
                            _12727.x = _6525.x + (_6525.y * _6525.z);
                            uvec3 _12730 = _12727;
                            _12730.y = _12727.y + (_12727.z * _12727.x);
                            uvec3 _12733 = _12727;
                            _12733.z = _12727.z + (_12727.x * _12727.y);
                            uvec3 _6557 = ((_6394 + uvec3(0u, 1u, 0u)) * uvec3(1664525u)) + uvec3(1013904223u);
                            _6557.x = _6557.x + (_6557.y * _6557.z);
                            _6557.y = _6557.y + (_6557.z * _6557.x);
                            _6557.z = _6557.z + (_6557.x * _6557.y);
                            uvec3 _6584 = _6557 ^ (_6557 >> uvec3(16u));
                            uvec3 _12745;
                            _12745.x = _6584.x + (_6584.y * _6584.z);
                            uvec3 _12748 = _12745;
                            _12748.y = _12745.y + (_12745.z * _12745.x);
                            uvec3 _12751 = _12745;
                            _12751.z = _12745.z + (_12745.x * _12745.y);
                            uvec3 _6616 = ((_6394 + uvec3(1u, 1u, 0u)) * uvec3(1664525u)) + uvec3(1013904223u);
                            _6616.x = _6616.x + (_6616.y * _6616.z);
                            _6616.y = _6616.y + (_6616.z * _6616.x);
                            _6616.z = _6616.z + (_6616.x * _6616.y);
                            uvec3 _6643 = _6616 ^ (_6616 >> uvec3(16u));
                            uvec3 _12763;
                            _12763.x = _6643.x + (_6643.y * _6643.z);
                            uvec3 _12766 = _12763;
                            _12766.y = _12763.y + (_12763.z * _12763.x);
                            uvec3 _12769 = _12763;
                            _12769.z = _12763.z + (_12763.x * _12763.y);
                            uvec3 _6675 = ((_6394 + uvec3(0u, 0u, 1u)) * uvec3(1664525u)) + uvec3(1013904223u);
                            _6675.x = _6675.x + (_6675.y * _6675.z);
                            _6675.y = _6675.y + (_6675.z * _6675.x);
                            _6675.z = _6675.z + (_6675.x * _6675.y);
                            uvec3 _6702 = _6675 ^ (_6675 >> uvec3(16u));
                            uvec3 _12781;
                            _12781.x = _6702.x + (_6702.y * _6702.z);
                            uvec3 _12784 = _12781;
                            _12784.y = _12781.y + (_12781.z * _12781.x);
                            uvec3 _12787 = _12781;
                            _12787.z = _12781.z + (_12781.x * _12781.y);
                            uvec3 _6734 = ((_6394 + uvec3(1u, 0u, 1u)) * uvec3(1664525u)) + uvec3(1013904223u);
                            _6734.x = _6734.x + (_6734.y * _6734.z);
                            _6734.y = _6734.y + (_6734.z * _6734.x);
                            _6734.z = _6734.z + (_6734.x * _6734.y);
                            uvec3 _6761 = _6734 ^ (_6734 >> uvec3(16u));
                            uvec3 _12799;
                            _12799.x = _6761.x + (_6761.y * _6761.z);
                            uvec3 _12802 = _12799;
                            _12802.y = _12799.y + (_12799.z * _12799.x);
                            uvec3 _12805 = _12799;
                            _12805.z = _12799.z + (_12799.x * _12799.y);
                            uvec3 _6793 = ((_6394 + uvec3(0u, 1u, 1u)) * uvec3(1664525u)) + uvec3(1013904223u);
                            _6793.x = _6793.x + (_6793.y * _6793.z);
                            _6793.y = _6793.y + (_6793.z * _6793.x);
                            _6793.z = _6793.z + (_6793.x * _6793.y);
                            uvec3 _6820 = _6793 ^ (_6793 >> uvec3(16u));
                            uvec3 _12817;
                            _12817.x = _6820.x + (_6820.y * _6820.z);
                            uvec3 _12820 = _12817;
                            _12820.y = _12817.y + (_12817.z * _12817.x);
                            uvec3 _12823 = _12817;
                            _12823.z = _12817.z + (_12817.x * _12817.y);
                            uvec3 _6852 = ((_6394 + uvec3(1u)) * uvec3(1664525u)) + uvec3(1013904223u);
                            _6852.x = _6852.x + (_6852.y * _6852.z);
                            _6852.y = _6852.y + (_6852.z * _6852.x);
                            _6852.z = _6852.z + (_6852.x * _6852.y);
                            uvec3 _6879 = _6852 ^ (_6852 >> uvec3(16u));
                            uvec3 _12835;
                            _12835.x = _6879.x + (_6879.y * _6879.z);
                            uvec3 _12838 = _12835;
                            _12838.y = _12835.y + (_12835.z * _12835.x);
                            uvec3 _12841 = _12835;
                            _12841.z = _12835.z + (_12835.x * _12835.y);
                            float _6418 = _6391.x;
                            float _6423 = _6391.y;
                            vec3 _5685 = _5786 * 23.0;
                            vec3 _6902 = floor(_5685);
                            vec3 _6903 = _5685 - _6902;
                            vec3 _6908 = (_6903 * _6903) * (vec3(3.0) - (_6903 * 2.0));
                            uvec3 _6911 = uvec3(ivec3(_6902) + ivec3(4096));
                            uvec3 _6956 = (_6911 * uvec3(1664525u)) + uvec3(1013904223u);
                            _6956.x = _6956.x + (_6956.y * _6956.z);
                            _6956.y = _6956.y + (_6956.z * _6956.x);
                            _6956.z = _6956.z + (_6956.x * _6956.y);
                            uvec3 _6983 = _6956 ^ (_6956 >> uvec3(16u));
                            uvec3 _12853;
                            _12853.x = _6983.x + (_6983.y * _6983.z);
                            uvec3 _12856 = _12853;
                            _12856.y = _12853.y + (_12853.z * _12853.x);
                            uvec3 _12859 = _12853;
                            _12859.z = _12853.z + (_12853.x * _12853.y);
                            uvec3 _7015 = ((_6911 + uvec3(1u, 0u, 0u)) * uvec3(1664525u)) + uvec3(1013904223u);
                            _7015.x = _7015.x + (_7015.y * _7015.z);
                            _7015.y = _7015.y + (_7015.z * _7015.x);
                            _7015.z = _7015.z + (_7015.x * _7015.y);
                            uvec3 _7042 = _7015 ^ (_7015 >> uvec3(16u));
                            uvec3 _12871;
                            _12871.x = _7042.x + (_7042.y * _7042.z);
                            uvec3 _12874 = _12871;
                            _12874.y = _12871.y + (_12871.z * _12871.x);
                            uvec3 _12877 = _12871;
                            _12877.z = _12871.z + (_12871.x * _12871.y);
                            uvec3 _7074 = ((_6911 + uvec3(0u, 1u, 0u)) * uvec3(1664525u)) + uvec3(1013904223u);
                            _7074.x = _7074.x + (_7074.y * _7074.z);
                            _7074.y = _7074.y + (_7074.z * _7074.x);
                            _7074.z = _7074.z + (_7074.x * _7074.y);
                            uvec3 _7101 = _7074 ^ (_7074 >> uvec3(16u));
                            uvec3 _12889;
                            _12889.x = _7101.x + (_7101.y * _7101.z);
                            uvec3 _12892 = _12889;
                            _12892.y = _12889.y + (_12889.z * _12889.x);
                            uvec3 _12895 = _12889;
                            _12895.z = _12889.z + (_12889.x * _12889.y);
                            uvec3 _7133 = ((_6911 + uvec3(1u, 1u, 0u)) * uvec3(1664525u)) + uvec3(1013904223u);
                            _7133.x = _7133.x + (_7133.y * _7133.z);
                            _7133.y = _7133.y + (_7133.z * _7133.x);
                            _7133.z = _7133.z + (_7133.x * _7133.y);
                            uvec3 _7160 = _7133 ^ (_7133 >> uvec3(16u));
                            uvec3 _12907;
                            _12907.x = _7160.x + (_7160.y * _7160.z);
                            uvec3 _12910 = _12907;
                            _12910.y = _12907.y + (_12907.z * _12907.x);
                            uvec3 _12913 = _12907;
                            _12913.z = _12907.z + (_12907.x * _12907.y);
                            uvec3 _7192 = ((_6911 + uvec3(0u, 0u, 1u)) * uvec3(1664525u)) + uvec3(1013904223u);
                            _7192.x = _7192.x + (_7192.y * _7192.z);
                            _7192.y = _7192.y + (_7192.z * _7192.x);
                            _7192.z = _7192.z + (_7192.x * _7192.y);
                            uvec3 _7219 = _7192 ^ (_7192 >> uvec3(16u));
                            uvec3 _12925;
                            _12925.x = _7219.x + (_7219.y * _7219.z);
                            uvec3 _12928 = _12925;
                            _12928.y = _12925.y + (_12925.z * _12925.x);
                            uvec3 _12931 = _12925;
                            _12931.z = _12925.z + (_12925.x * _12925.y);
                            uvec3 _7251 = ((_6911 + uvec3(1u, 0u, 1u)) * uvec3(1664525u)) + uvec3(1013904223u);
                            _7251.x = _7251.x + (_7251.y * _7251.z);
                            _7251.y = _7251.y + (_7251.z * _7251.x);
                            _7251.z = _7251.z + (_7251.x * _7251.y);
                            uvec3 _7278 = _7251 ^ (_7251 >> uvec3(16u));
                            uvec3 _12943;
                            _12943.x = _7278.x + (_7278.y * _7278.z);
                            uvec3 _12946 = _12943;
                            _12946.y = _12943.y + (_12943.z * _12943.x);
                            uvec3 _12949 = _12943;
                            _12949.z = _12943.z + (_12943.x * _12943.y);
                            uvec3 _7310 = ((_6911 + uvec3(0u, 1u, 1u)) * uvec3(1664525u)) + uvec3(1013904223u);
                            _7310.x = _7310.x + (_7310.y * _7310.z);
                            _7310.y = _7310.y + (_7310.z * _7310.x);
                            _7310.z = _7310.z + (_7310.x * _7310.y);
                            uvec3 _7337 = _7310 ^ (_7310 >> uvec3(16u));
                            uvec3 _12961;
                            _12961.x = _7337.x + (_7337.y * _7337.z);
                            uvec3 _12964 = _12961;
                            _12964.y = _12961.y + (_12961.z * _12961.x);
                            uvec3 _12967 = _12961;
                            _12967.z = _12961.z + (_12961.x * _12961.y);
                            uvec3 _7369 = ((_6911 + uvec3(1u)) * uvec3(1664525u)) + uvec3(1013904223u);
                            _7369.x = _7369.x + (_7369.y * _7369.z);
                            _7369.y = _7369.y + (_7369.z * _7369.x);
                            _7369.z = _7369.z + (_7369.x * _7369.y);
                            uvec3 _7396 = _7369 ^ (_7369 >> uvec3(16u));
                            uvec3 _12979;
                            _12979.x = _7396.x + (_7396.y * _7396.z);
                            uvec3 _12982 = _12979;
                            _12982.y = _12979.y + (_12979.z * _12979.x);
                            uvec3 _12985 = _12979;
                            _12985.z = _12979.z + (_12979.x * _12979.y);
                            float _6935 = _6908.x;
                            float _6940 = _6908.y;
                            vec3 _5690 = (_5786 * 14.0) + vec3(3.099999904632568359375, 7.69999980926513671875, 1.2999999523162841796875);
                            vec3 _7419 = floor(_5690);
                            vec3 _7420 = _5690 - _7419;
                            vec3 _7425 = (_7420 * _7420) * (vec3(3.0) - (_7420 * 2.0));
                            uvec3 _7428 = uvec3(ivec3(_7419) + ivec3(4096));
                            uvec3 _7473 = (_7428 * uvec3(1664525u)) + uvec3(1013904223u);
                            _7473.x = _7473.x + (_7473.y * _7473.z);
                            _7473.y = _7473.y + (_7473.z * _7473.x);
                            _7473.z = _7473.z + (_7473.x * _7473.y);
                            uvec3 _7500 = _7473 ^ (_7473 >> uvec3(16u));
                            uvec3 _12997;
                            _12997.x = _7500.x + (_7500.y * _7500.z);
                            uvec3 _13000 = _12997;
                            _13000.y = _12997.y + (_12997.z * _12997.x);
                            uvec3 _13003 = _12997;
                            _13003.z = _12997.z + (_12997.x * _12997.y);
                            uvec3 _7532 = ((_7428 + uvec3(1u, 0u, 0u)) * uvec3(1664525u)) + uvec3(1013904223u);
                            _7532.x = _7532.x + (_7532.y * _7532.z);
                            _7532.y = _7532.y + (_7532.z * _7532.x);
                            _7532.z = _7532.z + (_7532.x * _7532.y);
                            uvec3 _7559 = _7532 ^ (_7532 >> uvec3(16u));
                            uvec3 _13015;
                            _13015.x = _7559.x + (_7559.y * _7559.z);
                            uvec3 _13018 = _13015;
                            _13018.y = _13015.y + (_13015.z * _13015.x);
                            uvec3 _13021 = _13015;
                            _13021.z = _13015.z + (_13015.x * _13015.y);
                            uvec3 _7591 = ((_7428 + uvec3(0u, 1u, 0u)) * uvec3(1664525u)) + uvec3(1013904223u);
                            _7591.x = _7591.x + (_7591.y * _7591.z);
                            _7591.y = _7591.y + (_7591.z * _7591.x);
                            _7591.z = _7591.z + (_7591.x * _7591.y);
                            uvec3 _7618 = _7591 ^ (_7591 >> uvec3(16u));
                            uvec3 _13033;
                            _13033.x = _7618.x + (_7618.y * _7618.z);
                            uvec3 _13036 = _13033;
                            _13036.y = _13033.y + (_13033.z * _13033.x);
                            uvec3 _13039 = _13033;
                            _13039.z = _13033.z + (_13033.x * _13033.y);
                            uvec3 _7650 = ((_7428 + uvec3(1u, 1u, 0u)) * uvec3(1664525u)) + uvec3(1013904223u);
                            _7650.x = _7650.x + (_7650.y * _7650.z);
                            _7650.y = _7650.y + (_7650.z * _7650.x);
                            _7650.z = _7650.z + (_7650.x * _7650.y);
                            uvec3 _7677 = _7650 ^ (_7650 >> uvec3(16u));
                            uvec3 _13051;
                            _13051.x = _7677.x + (_7677.y * _7677.z);
                            uvec3 _13054 = _13051;
                            _13054.y = _13051.y + (_13051.z * _13051.x);
                            uvec3 _13057 = _13051;
                            _13057.z = _13051.z + (_13051.x * _13051.y);
                            uvec3 _7709 = ((_7428 + uvec3(0u, 0u, 1u)) * uvec3(1664525u)) + uvec3(1013904223u);
                            _7709.x = _7709.x + (_7709.y * _7709.z);
                            _7709.y = _7709.y + (_7709.z * _7709.x);
                            _7709.z = _7709.z + (_7709.x * _7709.y);
                            uvec3 _7736 = _7709 ^ (_7709 >> uvec3(16u));
                            uvec3 _13069;
                            _13069.x = _7736.x + (_7736.y * _7736.z);
                            uvec3 _13072 = _13069;
                            _13072.y = _13069.y + (_13069.z * _13069.x);
                            uvec3 _13075 = _13069;
                            _13075.z = _13069.z + (_13069.x * _13069.y);
                            uvec3 _7768 = ((_7428 + uvec3(1u, 0u, 1u)) * uvec3(1664525u)) + uvec3(1013904223u);
                            _7768.x = _7768.x + (_7768.y * _7768.z);
                            _7768.y = _7768.y + (_7768.z * _7768.x);
                            _7768.z = _7768.z + (_7768.x * _7768.y);
                            uvec3 _7795 = _7768 ^ (_7768 >> uvec3(16u));
                            uvec3 _13087;
                            _13087.x = _7795.x + (_7795.y * _7795.z);
                            uvec3 _13090 = _13087;
                            _13090.y = _13087.y + (_13087.z * _13087.x);
                            uvec3 _13093 = _13087;
                            _13093.z = _13087.z + (_13087.x * _13087.y);
                            uvec3 _7827 = ((_7428 + uvec3(0u, 1u, 1u)) * uvec3(1664525u)) + uvec3(1013904223u);
                            _7827.x = _7827.x + (_7827.y * _7827.z);
                            _7827.y = _7827.y + (_7827.z * _7827.x);
                            _7827.z = _7827.z + (_7827.x * _7827.y);
                            uvec3 _7854 = _7827 ^ (_7827 >> uvec3(16u));
                            uvec3 _13105;
                            _13105.x = _7854.x + (_7854.y * _7854.z);
                            uvec3 _13108 = _13105;
                            _13108.y = _13105.y + (_13105.z * _13105.x);
                            uvec3 _13111 = _13105;
                            _13111.z = _13105.z + (_13105.x * _13105.y);
                            uvec3 _7886 = ((_7428 + uvec3(1u)) * uvec3(1664525u)) + uvec3(1013904223u);
                            _7886.x = _7886.x + (_7886.y * _7886.z);
                            _7886.y = _7886.y + (_7886.z * _7886.x);
                            _7886.z = _7886.z + (_7886.x * _7886.y);
                            uvec3 _7913 = _7886 ^ (_7886 >> uvec3(16u));
                            uvec3 _13123;
                            _13123.x = _7913.x + (_7913.y * _7913.z);
                            uvec3 _13126 = _13123;
                            _13126.y = _13123.y + (_13123.z * _13123.x);
                            uvec3 _13129 = _13123;
                            _13129.z = _13123.z + (_13123.x * _13123.y);
                            float _7452 = _7425.x;
                            float _7457 = _7425.y;
                            float _5693 = ((0.550000011920928955078125 * mix(mix(mix((vec3(_12709) * 2.3283064365386962890625e-10).x, (vec3(_12727) * 2.3283064365386962890625e-10).x, _6418), mix((vec3(_12745) * 2.3283064365386962890625e-10).x, (vec3(_12763) * 2.3283064365386962890625e-10).x, _6418), _6423), mix(mix((vec3(_12781) * 2.3283064365386962890625e-10).x, (vec3(_12799) * 2.3283064365386962890625e-10).x, _6418), mix((vec3(_12817) * 2.3283064365386962890625e-10).x, (vec3(_12835) * 2.3283064365386962890625e-10).x, _6418), _6423), _6391.z)) + (0.449999988079071044921875 * mix(mix(mix((vec3(_12853) * 2.3283064365386962890625e-10).x, (vec3(_12871) * 2.3283064365386962890625e-10).x, _6935), mix((vec3(_12889) * 2.3283064365386962890625e-10).x, (vec3(_12907) * 2.3283064365386962890625e-10).x, _6935), _6940), mix(mix((vec3(_12925) * 2.3283064365386962890625e-10).x, (vec3(_12943) * 2.3283064365386962890625e-10).x, _6935), mix((vec3(_12961) * 2.3283064365386962890625e-10).x, (vec3(_12979) * 2.3283064365386962890625e-10).x, _6935), _6940), _6908.z))) * 1.2999999523162841796875;
                            vec3 _5705 = (((_5788 + (_6086 * 0.119999997317790985107421875)) + (vec3(0.85000002384185791015625, 0.89999997615814208984375, 1.0) * (((exp((_5677 * _5677) * (-41.322315216064453125)) * clamp(_5693 - 0.25, 0.0, 1.0)) * (1.0 - (0.60000002384185791015625 * smoothstep(0.3499999940395355224609375, 0.75, mix(mix(mix((vec3(_12997) * 2.3283064365386962890625e-10).x, (vec3(_13015) * 2.3283064365386962890625e-10).x, _7452), mix((vec3(_13033) * 2.3283064365386962890625e-10).x, (vec3(_13051) * 2.3283064365386962890625e-10).x, _7452), _7457), mix(mix((vec3(_13069) * 2.3283064365386962890625e-10).x, (vec3(_13087) * 2.3283064365386962890625e-10).x, _7452), mix((vec3(_13105) * 2.3283064365386962890625e-10).x, (vec3(_13123) * 2.3283064365386962890625e-10).x, _7452), _7457), _7425.z))))) * 0.01200000010430812835693359375))) * light.stars.x) * (_5656 * _5656);
                            _5652 = _5705;
                        }
                        else
                        {
                            _5652 = vec3(0.0);
                        }
                        if (light.moon.w > 0.0)
                        {
                            float _5709 = dot(_543, _798);
                            float _5711 = 2.0 - (2.0 * _5709);
                            float _5713 = sqrt(isnan(0.0) ? _5711 : (isnan(_5711) ? 0.0 : max(_5711, 0.0)));
                            float _5714 = isnan(0.0005249999812804162502288818359375) ? pixelAngle : (isnan(pixelAngle) ? 0.0005249999812804162502288818359375 : max(pixelAngle, 0.0005249999812804162502288818359375));
                            float _5718 = 1.0 - smoothstep(0.010499999858438968658447265625 - _5714, 0.010499999858438968658447265625 + _5714, _5713);
                            if (_5718 > 0.0)
                            {
                                float _5722 = clamp(_5713 * 95.23809814453125, 0.0, 1.0);
                                float _5724 = 1.0 - (_5722 * _5722);
                                vec3 _5733 = (((_543 - _798) * vec3(95.23809814453125)) * 1.60000002384185791015625) + vec3(11.0, 5.0, 2.0);
                                vec3 _7936 = floor(_5733);
                                vec3 _7937 = _5733 - _7936;
                                vec3 _7942 = (_7937 * _7937) * (vec3(3.0) - (_7937 * 2.0));
                                uvec3 _7945 = uvec3(ivec3(_7936) + ivec3(4096));
                                uvec3 _7990 = (_7945 * uvec3(1664525u)) + uvec3(1013904223u);
                                _7990.x = _7990.x + (_7990.y * _7990.z);
                                _7990.y = _7990.y + (_7990.z * _7990.x);
                                _7990.z = _7990.z + (_7990.x * _7990.y);
                                uvec3 _8017 = _7990 ^ (_7990 >> uvec3(16u));
                                uvec3 _13141;
                                _13141.x = _8017.x + (_8017.y * _8017.z);
                                uvec3 _13144 = _13141;
                                _13144.y = _13141.y + (_13141.z * _13141.x);
                                uvec3 _13147 = _13141;
                                _13147.z = _13141.z + (_13141.x * _13141.y);
                                uvec3 _8049 = ((_7945 + uvec3(1u, 0u, 0u)) * uvec3(1664525u)) + uvec3(1013904223u);
                                _8049.x = _8049.x + (_8049.y * _8049.z);
                                _8049.y = _8049.y + (_8049.z * _8049.x);
                                _8049.z = _8049.z + (_8049.x * _8049.y);
                                uvec3 _8076 = _8049 ^ (_8049 >> uvec3(16u));
                                uvec3 _13159;
                                _13159.x = _8076.x + (_8076.y * _8076.z);
                                uvec3 _13162 = _13159;
                                _13162.y = _13159.y + (_13159.z * _13159.x);
                                uvec3 _13165 = _13159;
                                _13165.z = _13159.z + (_13159.x * _13159.y);
                                uvec3 _8108 = ((_7945 + uvec3(0u, 1u, 0u)) * uvec3(1664525u)) + uvec3(1013904223u);
                                _8108.x = _8108.x + (_8108.y * _8108.z);
                                _8108.y = _8108.y + (_8108.z * _8108.x);
                                _8108.z = _8108.z + (_8108.x * _8108.y);
                                uvec3 _8135 = _8108 ^ (_8108 >> uvec3(16u));
                                uvec3 _13177;
                                _13177.x = _8135.x + (_8135.y * _8135.z);
                                uvec3 _13180 = _13177;
                                _13180.y = _13177.y + (_13177.z * _13177.x);
                                uvec3 _13183 = _13177;
                                _13183.z = _13177.z + (_13177.x * _13177.y);
                                uvec3 _8167 = ((_7945 + uvec3(1u, 1u, 0u)) * uvec3(1664525u)) + uvec3(1013904223u);
                                _8167.x = _8167.x + (_8167.y * _8167.z);
                                _8167.y = _8167.y + (_8167.z * _8167.x);
                                _8167.z = _8167.z + (_8167.x * _8167.y);
                                uvec3 _8194 = _8167 ^ (_8167 >> uvec3(16u));
                                uvec3 _13195;
                                _13195.x = _8194.x + (_8194.y * _8194.z);
                                uvec3 _13198 = _13195;
                                _13198.y = _13195.y + (_13195.z * _13195.x);
                                uvec3 _13201 = _13195;
                                _13201.z = _13195.z + (_13195.x * _13195.y);
                                uvec3 _8226 = ((_7945 + uvec3(0u, 0u, 1u)) * uvec3(1664525u)) + uvec3(1013904223u);
                                _8226.x = _8226.x + (_8226.y * _8226.z);
                                _8226.y = _8226.y + (_8226.z * _8226.x);
                                _8226.z = _8226.z + (_8226.x * _8226.y);
                                uvec3 _8253 = _8226 ^ (_8226 >> uvec3(16u));
                                uvec3 _13213;
                                _13213.x = _8253.x + (_8253.y * _8253.z);
                                uvec3 _13216 = _13213;
                                _13216.y = _13213.y + (_13213.z * _13213.x);
                                uvec3 _13219 = _13213;
                                _13219.z = _13213.z + (_13213.x * _13213.y);
                                uvec3 _8285 = ((_7945 + uvec3(1u, 0u, 1u)) * uvec3(1664525u)) + uvec3(1013904223u);
                                _8285.x = _8285.x + (_8285.y * _8285.z);
                                _8285.y = _8285.y + (_8285.z * _8285.x);
                                _8285.z = _8285.z + (_8285.x * _8285.y);
                                uvec3 _8312 = _8285 ^ (_8285 >> uvec3(16u));
                                uvec3 _13231;
                                _13231.x = _8312.x + (_8312.y * _8312.z);
                                uvec3 _13234 = _13231;
                                _13234.y = _13231.y + (_13231.z * _13231.x);
                                uvec3 _13237 = _13231;
                                _13237.z = _13231.z + (_13231.x * _13231.y);
                                uvec3 _8344 = ((_7945 + uvec3(0u, 1u, 1u)) * uvec3(1664525u)) + uvec3(1013904223u);
                                _8344.x = _8344.x + (_8344.y * _8344.z);
                                _8344.y = _8344.y + (_8344.z * _8344.x);
                                _8344.z = _8344.z + (_8344.x * _8344.y);
                                uvec3 _8371 = _8344 ^ (_8344 >> uvec3(16u));
                                uvec3 _13249;
                                _13249.x = _8371.x + (_8371.y * _8371.z);
                                uvec3 _13252 = _13249;
                                _13252.y = _13249.y + (_13249.z * _13249.x);
                                uvec3 _13255 = _13249;
                                _13255.z = _13249.z + (_13249.x * _13249.y);
                                uvec3 _8403 = ((_7945 + uvec3(1u)) * uvec3(1664525u)) + uvec3(1013904223u);
                                _8403.x = _8403.x + (_8403.y * _8403.z);
                                _8403.y = _8403.y + (_8403.z * _8403.x);
                                _8403.z = _8403.z + (_8403.x * _8403.y);
                                uvec3 _8430 = _8403 ^ (_8403 >> uvec3(16u));
                                uvec3 _13267;
                                _13267.x = _8430.x + (_8430.y * _8430.z);
                                uvec3 _13270 = _13267;
                                _13270.y = _13267.y + (_13267.z * _13267.x);
                                uvec3 _13273 = _13267;
                                _13273.z = _13267.z + (_13267.x * _13267.y);
                                float _7969 = _7942.x;
                                float _7974 = _7942.y;
                                vec3 _5745 = vec3(1.0, 0.980000019073486328125, 0.939999997615814208984375) * ((((light.moon.w * _5718) * (0.62000000476837158203125 + (0.37999999523162841796875 * sqrt(isnan(0.0) ? _5724 : (isnan(_5724) ? 0.0 : max(_5724, 0.0)))))) * (1.0 - (0.2800000011920928955078125 * smoothstep(0.449999988079071044921875, 0.800000011920928955078125, mix(mix(mix((vec3(_13141) * 2.3283064365386962890625e-10).x, (vec3(_13159) * 2.3283064365386962890625e-10).x, _7969), mix((vec3(_13177) * 2.3283064365386962890625e-10).x, (vec3(_13195) * 2.3283064365386962890625e-10).x, _7969), _7974), mix(mix((vec3(_13213) * 2.3283064365386962890625e-10).x, (vec3(_13231) * 2.3283064365386962890625e-10).x, _7969), mix((vec3(_13249) * 2.3283064365386962890625e-10).x, (vec3(_13267) * 2.3283064365386962890625e-10).x, _7969), _7974), _7942.z))))) * clamp(1.0 - (light.stars.y * 1.5), 0.0, 1.0));
                                _5652 += _5745;
                            }
                            float _5749 = clamp(_5709, 0.0, 1.0);
                            _5652 += ((vec3(0.819999992847442626953125, 0.87999999523162841796875, 1.0) * light.moon.w) * ((((pow(_5749, 6000.0) * 0.006000000052154064178466796875) * _5656) + (pow(_5749, 180.0) * 0.0003000000142492353916168212890625)) + ((pow(_5749, 18.0) * 0.000600000028498470783233642578125) * light.stars.y)));
                        }
                        sunLight = background + (_5652 * _5568);
                    }
                    else
                    {
                        sunLight = background;
                    }
                    vec3 _8452;
                    {
                        if (gi.fog.z <= 0.0)
                        {
                            _8452 = sunLight;
                        }
                        else
                        {
                            float _8467 = (gi.unproject.w * gi.fog.x) + gi.fog.y;
                            vec4 _8482 = textureLod(_13292, vec3(input_uv, clamp(((log2(isnan(9.9999999747524270787835121154785e-07) ? _8467 : (isnan(_8467) ? 9.9999999747524270787835121154785e-07 : max(_8467, 9.9999999747524270787835121154785e-07))) * gi.fog.z) - 1.0) * gi.fog.w, 0.0, 1.0)), 0.0);
                            _8452 = (sunLight * _8482.w) + _8482.xyz;
                        }
                    }
                    entryPointParam_fragmentMain = vec4(_8452, 1.0);
                }
            }
        }
        else
        {
            vec4 _154;
            if ((int((_5351.w * 255.0) + 0.5) & 15) == 0)
            {
                if (debugView != 0)
                {
                    _152 = debugView != 11;
                }
                else
                {
                    _152 = false;
                }
                if (_152)
                {
                    if (debugView == 1)
                    {
                        _154 = vec4(albedo, 1.0);
                    }
                    else
                    {
                        _154 = vec4(0.0, 0.0, 0.0, 1.0);
                    }
                    entryPointParam_fragmentMain = _154;
                }
                else
                {
                    float _8502 = (_5351.y * 255.0) - 128.0;
                    float _8497;
                    if (_8502 > 0.5)
                    {
                        _8497 = _8502 * 0.0625;
                    }
                    else
                    {
                        _8497 = 1.0;
                    }
                    vec3 _1597 = albedo * _8497;
                    float _8524 = ((2.0 * gi.unproject.z) * gi.unproject.w) / ((gi.unproject.w + gi.unproject.z) - ((1.0 - (2.0 * depth)) * (gi.unproject.w - gi.unproject.z)));
                    vec2 _8527 = (input_uv * 2.0) - vec2(1.0);
                    vec3 _8541;
                    {
                        if (gi.fog.z <= 0.0)
                        {
                            _8541 = _1597;
                        }
                        else
                        {
                            float _8556 = (vec3(_13275, _13275, _8524).z * gi.fog.x) + gi.fog.y;
                            vec4 _8571 = textureLod(_13292, vec3(input_uv, clamp(((log2(isnan(9.9999999747524270787835121154785e-07) ? _8556 : (isnan(_8556) ? 9.9999999747524270787835121154785e-07 : max(_8556, 9.9999999747524270787835121154785e-07))) * gi.fog.z) - 1.0) * gi.fog.w, 0.0, 1.0)), 0.0);
                            _8541 = (_1597 * _8571.w) + _8571.xyz;
                        }
                    }
                    entryPointParam_fragmentMain = vec4(_8541, 1.0);
                }
            }
            else
            {
                vec3 normal = normalize((texelFetch(_13302, ivec3(ivec2(gl_FragCoord.xy), 0).xy, 0).xyz * 2.0) - vec3(1.0));
                int model = int(light.sunDirectionModel.w + 0.5);
                if (debugView == 1)
                {
                    entryPointParam_fragmentMain = vec4(albedo, 1.0);
                }
                else
                {
                    if (debugView == 2)
                    {
                        entryPointParam_fragmentMain = vec4((normal * 0.5) + vec3(0.5), 1.0);
                    }
                    else
                    {
                        if (debugView == 3)
                        {
                            float _8610 = ((2.0 * gi.unproject.z) * gi.unproject.w) / ((gi.unproject.w + gi.unproject.z) - ((1.0 - (2.0 * depth)) * (gi.unproject.w - gi.unproject.z)));
                            vec2 _8613 = (input_uv * 2.0) - vec2(1.0);
                            float _1694 = pow(clamp(vec3(_13275, _13275, _8610).z * 0.0024999999441206455230712890625, 0.0, 1.0), 0.4544999897480010986328125);
                            entryPointParam_fragmentMain = vec4(_1694, _1694, _1694, 1.0);
                        }
                        else
                        {
                            if (debugView == 4)
                            {
                                entryPointParam_fragmentMain = vec4(_5351.zxw, 1.0);
                            }
                            else
                            {
                                if (debugView == 6)
                                {
                                    entryPointParam_fragmentMain = vec4(baked, 1.0);
                                }
                                else
                                {
                                    if (debugView == 7)
                                    {
                                        entryPointParam_fragmentMain = vec4(textureLod(_13304, input_uv, 0.0).xxx, 1.0);
                                    }
                                    else
                                    {
                                        if (debugView == 8)
                                        {
                                            entryPointParam_fragmentMain = vec4(textureLod(_13306, input_uv, 0.0).xyz * gi.giParams.x, 1.0);
                                        }
                                        else
                                        {
                                            if (debugView == 18)
                                            {
                                                entryPointParam_fragmentMain = vec4(_5351.zzz, 1.0);
                                            }
                                            else
                                            {
                                                if (debugView == 19)
                                                {
                                                    entryPointParam_fragmentMain = vec4(_5351.xxx, 1.0);
                                                }
                                                else
                                                {
                                                    if (debugView == 20)
                                                    {
                                                        entryPointParam_fragmentMain = vec4(_5342.www, 1.0);
                                                    }
                                                    else
                                                    {
                                                        if (debugView == 11)
                                                        {
                                                            albedo = vec3(0.180000007152557373046875);
                                                        }
                                                        if (debugView == 28)
                                                        {
                                                            float _8627;
                                                            {
                                                                if (gi.flashlight.control.x <= 0.5)
                                                                {
                                                                    _8627 = 1.0;
                                                                }
                                                                else
                                                                {
                                                                    _8627 = clamp(texelFetch(_13309, ivec3(ivec2(gl_FragCoord.xy), 0).xy, 0).x, 0.0, 1.0);
                                                                }
                                                            }
                                                            entryPointParam_fragmentMain = vec4(_8627, _8627, _8627, 1.0);
                                                        }
                                                        else
                                                        {
                                                            float _8664 = ((2.0 * gi.unproject.z) * gi.unproject.w) / ((gi.unproject.w + gi.unproject.z) - ((1.0 - (2.0 * depth)) * (gi.unproject.w - gi.unproject.z)));
                                                            vec2 _8667 = (input_uv * 2.0) - vec2(1.0);
                                                            vec3 _8679 = vec3((_8667.x * _8664) / gi.unproject.x, ((-_8667.y) * _8664) / gi.unproject.y, _8664);
                                                            vec3 flashDir;
                                                            vec3 _8681;
                                                            {
                                                                flashDir = vec3(0.0, 0.0, 1.0);
                                                                if (!(gi.flashlight.position.w > 0.0))
                                                                {
                                                                    _8681 = vec3(0.0);
                                                                }
                                                                else
                                                                {
                                                                    vec3 _8682;
                                                                    vec3 _8719;
                                                                    {
                                                                        vec3 _8729 = _8679 - gi.flashlight.position.xyz;
                                                                        float _8730 = dot(_8729, _8729);
                                                                        float _8732 = sqrt(isnan(9.9999999392252902907785028219223e-09) ? _8730 : (isnan(_8730) ? 9.9999999392252902907785028219223e-09 : max(_8730, 9.9999999392252902907785028219223e-09)));
                                                                        float _8683 = _8732;
                                                                        _8682 = (-_8729) / vec3(_8732);
                                                                        bool _8720;
                                                                        if (gi.flashlight.position.w <= 0.0)
                                                                        {
                                                                            _8720 = true;
                                                                        }
                                                                        else
                                                                        {
                                                                            _8720 = _8683 >= gi.flashlight.position.w;
                                                                        }
                                                                        if (_8720)
                                                                        {
                                                                            _8719 = vec3(0.0);
                                                                        }
                                                                        else
                                                                        {
                                                                            vec3 _8747 = -_8682;
                                                                            float _8786;
                                                                            {
                                                                                float _8796 = dot(gi.flashlight.axis.xyz, _8747);
                                                                                bool _8787;
                                                                                if (_8796 <= gi.flashlight.axis.w)
                                                                                {
                                                                                    _8787 = true;
                                                                                }
                                                                                else
                                                                                {
                                                                                    _8787 = _8796 <= 0.0;
                                                                                }
                                                                                if (_8787)
                                                                                {
                                                                                    _8786 = 0.0;
                                                                                }
                                                                                else
                                                                                {
                                                                                    float _8807 = 1.0 - (_8796 * _8796);
                                                                                    float _8815 = (sqrt(isnan(0.0) ? _8807 : (isnan(_8807) ? 0.0 : max(_8807, 0.0))) / _8796) / (isnan(9.9999997473787516355514526367188e-05) ? gi.flashlight.cone.x : (isnan(gi.flashlight.cone.x) ? 9.9999997473787516355514526367188e-05 : max(gi.flashlight.cone.x, 9.9999997473787516355514526367188e-05)));
                                                                                    float _8820 = (0.300000011920928955078125 * gi.flashlight.cone.y) * gi.flashlight.cone.y;
                                                                                    float _8827 = _8815 - 0.86000001430511474609375;
                                                                                    vec3 _8839 = cross(gi.flashlight.up.xyz, gi.flashlight.axis.xyz);
                                                                                    float _8840 = length(_8839);
                                                                                    vec3 _8788;
                                                                                    if (_8840 > 9.9999997473787516355514526367188e-05)
                                                                                    {
                                                                                        _8788 = _8839 / vec3(_8840);
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        _8788 = vec3(1.0, 0.0, 0.0);
                                                                                    }
                                                                                    float _8853 = atan(dot(_8747, cross(gi.flashlight.axis.xyz, _8788)), dot(_8747, _8788) + 9.9999999747524270787835121154785e-07);
                                                                                    float _8872 = ((((0.550000011920928955078125 * exp(-((_8815 * _8815) / (isnan(9.9999997473787516355514526367188e-05) ? _8820 : (isnan(_8820) ? 9.9999997473787516355514526367188e-05 : max(_8820, 9.9999997473787516355514526367188e-05)))))) + (0.449999988079071044921875 * (1.0 - smoothstep(gi.flashlight.cone.y, 1.0, _8815)))) + (0.070000000298023223876953125 * exp((_8827 * _8827) * (-249.9999847412109375)))) * ((1.0 + ((0.04500000178813934326171875 * _8815) * sin((5.0 * _8853) + 1.2999999523162841796875))) + (0.02999999932944774627685546875 * sin((33.0 * _8815) + (2.0 * _8853))))) + ((1.0 - smoothstep(1.0, gi.flashlight.cone.z, _8815)) * gi.flashlight.cone.w);
                                                                                    _8786 = isnan(0.0) ? _8872 : (isnan(_8872) ? 0.0 : max(_8872, 0.0));
                                                                                }
                                                                            }
                                                                            if (_8786 <= 0.0)
                                                                            {
                                                                                _8719 = vec3(0.0);
                                                                            }
                                                                            else
                                                                            {
                                                                                float _8753 = _8730 / (gi.flashlight.position.w * gi.flashlight.position.w);
                                                                                float _8756 = clamp(1.0 - (_8753 * _8753), 0.0, 1.0);
                                                                                if (true)
                                                                                {
                                                                                    _8720 = _8683 > 5.0;
                                                                                }
                                                                                else
                                                                                {
                                                                                    _8720 = false;
                                                                                }
                                                                                float _8721;
                                                                                if (_8720)
                                                                                {
                                                                                    _8721 = pow(_8683 * 0.20000000298023223876953125, gi.flashlight.control.z);
                                                                                }
                                                                                else
                                                                                {
                                                                                    _8721 = 1.0;
                                                                                }
                                                                                _8719 = gi.flashlight.colour.xyz * (((_8786 * (_8756 * _8756)) * _8721) / (isnan(gi.flashlight.colour.w) ? _8730 : (isnan(_8730) ? gi.flashlight.colour.w : max(_8730, gi.flashlight.colour.w))));
                                                                            }
                                                                        }
                                                                    }
                                                                    if (all(lessThanEqual(_8719, vec3(0.0))))
                                                                    {
                                                                        _8681 = vec3(0.0);
                                                                    }
                                                                    else
                                                                    {
                                                                        vec3 _8702 = normalize((vec4(_8682, 0.0) * spvWorkaroundRowMajor(gi.viewToWorld)).xyz);
                                                                        flashDir = _8702;
                                                                        if (dot(normal, _8702) <= 0.0)
                                                                        {
                                                                            _8681 = vec3(0.0);
                                                                        }
                                                                        else
                                                                        {
                                                                            float _8877;
                                                                            {
                                                                                if (gi.flashlight.control.x <= 0.5)
                                                                                {
                                                                                    _8877 = 1.0;
                                                                                }
                                                                                else
                                                                                {
                                                                                    _8877 = clamp(texelFetch(_13309, ivec3(ivec2(gl_FragCoord.xy), 0).xy, 0).x, 0.0, 1.0);
                                                                                }
                                                                            }
                                                                            _8681 = _8719 * _8877;
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                            float _2054 = dot(normal, flashDir);
                                                            vec3 flashDiffuse = (albedo * _8681) * (isnan(0.0) ? _2054 : (isnan(_2054) ? 0.0 : max(_2054, 0.0)));
                                                            if (model == 0)
                                                            {
                                                                vec3 _2061 = (albedo * baked) + flashDiffuse;
                                                                vec3 _8900;
                                                                {
                                                                    if (gi.fog.z <= 0.0)
                                                                    {
                                                                        _8900 = _2061;
                                                                    }
                                                                    else
                                                                    {
                                                                        float _8915 = (_8679.z * gi.fog.x) + gi.fog.y;
                                                                        vec4 _8930 = textureLod(_13292, vec3(input_uv, clamp(((log2(isnan(9.9999999747524270787835121154785e-07) ? _8915 : (isnan(_8915) ? 9.9999999747524270787835121154785e-07 : max(_8915, 9.9999999747524270787835121154785e-07))) * gi.fog.z) - 1.0) * gi.fog.w, 0.0, 1.0)), 0.0);
                                                                        _8900 = (_2061 * _8930.w) + _8930.xyz;
                                                                    }
                                                                }
                                                                entryPointParam_fragmentMain = vec4(_8900, 1.0);
                                                            }
                                                            else
                                                            {
                                                                vec3 _2074 = normalize((vec4(light.sunDirectionModel.xyz, 0.0) * spvWorkaroundRowMajor(gi.viewToWorld)).xyz);
                                                                float _2076 = dot(normal, _2074);
                                                                float _2077 = isnan(0.0) ? _2076 : (isnan(_2076) ? 0.0 : max(_2076, 0.0));
                                                                if (_2077 > 0.0)
                                                                {
                                                                    _152 = true;
                                                                }
                                                                else
                                                                {
                                                                    _152 = debugView == 12;
                                                                }
                                                                float visibility;
                                                                if (_152)
                                                                {
                                                                    if (gi.probeMisc.w > 0.5)
                                                                    {
                                                                        visibility = textureLod(_13316, input_uv, 0.0).x;
                                                                    }
                                                                    else
                                                                    {
                                                                        _8938 = false;
                                                                        float _8939;
                                                                        {
                                                                            int _8952 = int(gi.shadowConfig.x + 0.5);
                                                                            if (_8952 <= 0)
                                                                            {
                                                                                _8938 = true;
                                                                                _8939 = 1.0;
                                                                            }
                                                                            else
                                                                            {
                                                                                float _8959 = isnan(1.0) ? gi.probeSky.w : (isnan(gi.probeSky.w) ? 1.0 : max(gi.probeSky.w, 1.0));
                                                                                vec3 _8964 = (vec4(_8679, 1.0) * spvWorkaroundRowMajor(gi.viewToWorld)).xyz;
                                                                                int _8940 = 0;
                                                                                bool _8941;
                                                                                float _8942;
                                                                                float _8943;
                                                                                bool _8944;
                                                                                float _9040;
                                                                                float _9048;
                                                                                float _9223;
                                                                                int _9224;
                                                                                float _9225;
                                                                                float _9338;
                                                                                float _9346;
                                                                                float _9521;
                                                                                int _9522;
                                                                                float _9523;
                                                                                for (;;)
                                                                                {
                                                                                    bool _8967_ladder_break = false;
                                                                                    {
                                                                                        if (!(_8940 < 4))
                                                                                        {
                                                                                            _8967_ladder_break = true;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            if (_8940 >= _8952)
                                                                                            {
                                                                                                _8967_ladder_break = true;
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                float _8977 = _8679.z;
                                                                                                if (!(_8977 > gi.cascadeSplits[_8940]))
                                                                                                {
                                                                                                    {
                                                                                                        float _9063 = length(vec3(spvWorkaroundRowMajor(gi.cascadeMatrix.data[_8940])[0].x, spvWorkaroundRowMajor(gi.cascadeMatrix.data[_8940])[1].x, spvWorkaroundRowMajor(gi.cascadeMatrix.data[_8940])[2].x));
                                                                                                        float _9068 = length(vec3(spvWorkaroundRowMajor(gi.cascadeMatrix.data[_8940])[0].z, spvWorkaroundRowMajor(gi.cascadeMatrix.data[_8940])[1].z, spvWorkaroundRowMajor(gi.cascadeMatrix.data[_8940])[2].z));
                                                                                                        float _9074 = (2.0 * gi.shadowConfig.w) / (isnan(9.9999999747524270787835121154785e-07) ? _9063 : (isnan(_9063) ? 9.9999999747524270787835121154785e-07 : max(_9063, 9.9999999747524270787835121154785e-07)));
                                                                                                        float _9076 = 2.0 / (isnan(9.9999999747524270787835121154785e-07) ? _9068 : (isnan(_9068) ? 9.9999999747524270787835121154785e-07 : max(_9068, 9.9999999747524270787835121154785e-07)));
                                                                                                        vec4 _9083 = vec4(_8964 + (normal * (gi.shadowConfig.z * _9074)), 1.0) * spvWorkaroundRowMajor(gi.cascadeMatrix.data[_8940]);
                                                                                                        vec3 _9087 = _9083.xyz / vec3(_9083.w);
                                                                                                        bool _9091 = all(lessThanEqual(abs(_9087.xy), vec2(1.0)));
                                                                                                        _8941 = _9091;
                                                                                                        if (!_9091)
                                                                                                        {
                                                                                                            _9040 = 1.0;
                                                                                                        }
                                                                                                        else
                                                                                                        {
                                                                                                            float _9102 = ((_9087.z * 0.5) + 0.5) - ((gi.shadowConfig.y * _9074) / _9076);
                                                                                                            float _9115 = length(vec3(spvWorkaroundRowMajor(gi.cascadeMatrix.data[0])[0].x, spvWorkaroundRowMajor(gi.cascadeMatrix.data[0])[1].x, spvWorkaroundRowMajor(gi.cascadeMatrix.data[0])[2].x));
                                                                                                            float _9120 = (_8959 * ((2.0 * gi.shadowConfig.w) / (isnan(9.9999999747524270787835121154785e-07) ? _9115 : (isnan(_9115) ? 9.9999999747524270787835121154785e-07 : max(_9115, 9.9999999747524270787835121154785e-07))))) / (isnan(9.9999999747524270787835121154785e-07) ? _9074 : (isnan(_9074) ? 9.9999999747524270787835121154785e-07 : max(_9074, 9.9999999747524270787835121154785e-07)));
                                                                                                            float _9121 = isnan(1.0) ? _9120 : (isnan(_9120) ? 1.0 : max(_9120, 1.0));
                                                                                                            vec2 _9128 = vec2((_9087.x * 0.5) + 0.5, 0.5 - (_9087.y * 0.5));
                                                                                                            uvec3 _9130 = uvec3(textureSize(_13312, 0));
                                                                                                            ivec2 _9138 = ivec2(int(_9130.x), int(_9130.y));
                                                                                                            float _9141 = clamp(0.140399992465972900390625 / (isnan(9.9999999747524270787835121154785e-07) ? _9074 : (isnan(_9074) ? 9.9999999747524270787835121154785e-07 : max(_9074, 9.9999999747524270787835121154785e-07))), 2.0, 16.0);
                                                                                                            float _9144 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy + vec2(7.0, 3.0), vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) * 6.283185482025146484375;
                                                                                                            float _9145 = sin(_9144);
                                                                                                            float _9146 = cos(_9144);
                                                                                                            int _9044 = 0;
                                                                                                            float _9045 = 0.0;
                                                                                                            float _9046 = 0.0;
                                                                                                            for (;;)
                                                                                                            {
                                                                                                                if (!(_9044 < 12))
                                                                                                                {
                                                                                                                    break;
                                                                                                                }
                                                                                                                vec4 _9181 = texelFetch(_13312, ivec4(clamp(ivec2((_9128 + (vec2((_2344_frag[_9044].x * _9146) - (_2344_frag[_9044].y * _9145), (_2344_frag[_9044].x * _9145) + (_2344_frag[_9044].y * _9146)) * (_9141 * gi.shadowConfig.w))) * vec2(_9138)), ivec2(0), _9138 - ivec2(1)), _8940, 0).xyz, 0);
                                                                                                                float _9182 = _9181.x;
                                                                                                                if (_9182 < _9102)
                                                                                                                {
                                                                                                                    _9045 += (_9102 - _9182);
                                                                                                                    _9046 += 1.0;
                                                                                                                }
                                                                                                                _9044++;
                                                                                                                continue;
                                                                                                            }
                                                                                                            if (_9046 > 0.0)
                                                                                                            {
                                                                                                                float _9207 = (((_9045 / _9046) * _9076) * 0.0046799997799098491668701171875) / (isnan(9.9999999747524270787835121154785e-07) ? _9074 : (isnan(_9074) ? 9.9999999747524270787835121154785e-07 : max(_9074, 9.9999999747524270787835121154785e-07)));
                                                                                                                _9048 = clamp(isnan(_9207) ? _9121 : (isnan(_9121) ? _9207 : max(_9121, _9207)), 1.0, 24.0);
                                                                                                            }
                                                                                                            else
                                                                                                            {
                                                                                                                _9048 = _9121;
                                                                                                            }
                                                                                                            vec3 _9211 = vec3(_9128, _9102);
                                                                                                            {
                                                                                                                if (_9048 <= 1.5)
                                                                                                                {
                                                                                                                    _9224 = -1;
                                                                                                                    _9225 = 0.0;
                                                                                                                    for (;;)
                                                                                                                    {
                                                                                                                        if (!(_9224 <= 1))
                                                                                                                        {
                                                                                                                            break;
                                                                                                                        }
                                                                                                                        int _9226 = -1;
                                                                                                                        for (;;)
                                                                                                                        {
                                                                                                                            if (!(_9226 <= 1))
                                                                                                                            {
                                                                                                                                break;
                                                                                                                            }
                                                                                                                            int _9253 = _9226;
                                                                                                                            _9226++;
                                                                                                                            _9225 += spvShadowLod0(_13314, vec4(vec3(_9211.xy + (vec2(float(_9253), float(_9224)) * gi.shadowConfig.w), float(_8940)), _9102));
                                                                                                                            continue;
                                                                                                                        }
                                                                                                                        _9224++;
                                                                                                                        continue;
                                                                                                                    }
                                                                                                                    _9223 = _9225 * 0.111111111938953399658203125;
                                                                                                                }
                                                                                                                else
                                                                                                                {
                                                                                                                    float _9285 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) * 6.283185482025146484375;
                                                                                                                    float _9286 = sin(_9285);
                                                                                                                    float _9287 = cos(_9285);
                                                                                                                    float _9288 = _9048 * gi.shadowConfig.w;
                                                                                                                    _9224 = 0;
                                                                                                                    _9225 = 0.0;
                                                                                                                    for (;;)
                                                                                                                    {
                                                                                                                        if (!(_9224 < 12))
                                                                                                                        {
                                                                                                                            break;
                                                                                                                        }
                                                                                                                        int _9297 = _9224;
                                                                                                                        _9224++;
                                                                                                                        _9225 += spvShadowLod0(_13314, vec4(vec3(_9211.xy + (vec2((_2344_frag[_9297].x * _9287) - (_2344_frag[_9297].y * _9286), (_2344_frag[_9297].x * _9286) + (_2344_frag[_9297].y * _9287)) * _9288), float(_8940)), _9102));
                                                                                                                        continue;
                                                                                                                    }
                                                                                                                    _9223 = _9225 * 0.083333335816860198974609375;
                                                                                                                }
                                                                                                            }
                                                                                                            _9040 = _9223;
                                                                                                        }
                                                                                                    }
                                                                                                    if (!(!_8941))
                                                                                                    {
                                                                                                        if (_8940 == 0)
                                                                                                        {
                                                                                                            _8942 = 0.0;
                                                                                                        }
                                                                                                        else
                                                                                                        {
                                                                                                            _8942 = gi.cascadeSplits[_8940 - 1];
                                                                                                        }
                                                                                                        float _9001 = _8942;
                                                                                                        float _9003 = (gi.cascadeSplits[_8940] - _9001) * 0.100000001490116119384765625;
                                                                                                        float _9004 = isnan(0.001000000047497451305389404296875) ? _9003 : (isnan(_9003) ? 0.001000000047497451305389404296875 : max(_9003, 0.001000000047497451305389404296875));
                                                                                                        float _9009 = clamp((_8977 - (gi.cascadeSplits[_8940] - _9004)) / _9004, 0.0, 1.0);
                                                                                                        if (_9009 > 0.0)
                                                                                                        {
                                                                                                            int _9014 = _8940 + 1;
                                                                                                            if (_9014 < _8952)
                                                                                                            {
                                                                                                                {
                                                                                                                    float _9361 = length(vec3(spvWorkaroundRowMajor(gi.cascadeMatrix.data[_9014])[0].x, spvWorkaroundRowMajor(gi.cascadeMatrix.data[_9014])[1].x, spvWorkaroundRowMajor(gi.cascadeMatrix.data[_9014])[2].x));
                                                                                                                    float _9366 = length(vec3(spvWorkaroundRowMajor(gi.cascadeMatrix.data[_9014])[0].z, spvWorkaroundRowMajor(gi.cascadeMatrix.data[_9014])[1].z, spvWorkaroundRowMajor(gi.cascadeMatrix.data[_9014])[2].z));
                                                                                                                    float _9372 = (2.0 * gi.shadowConfig.w) / (isnan(9.9999999747524270787835121154785e-07) ? _9361 : (isnan(_9361) ? 9.9999999747524270787835121154785e-07 : max(_9361, 9.9999999747524270787835121154785e-07)));
                                                                                                                    float _9374 = 2.0 / (isnan(9.9999999747524270787835121154785e-07) ? _9366 : (isnan(_9366) ? 9.9999999747524270787835121154785e-07 : max(_9366, 9.9999999747524270787835121154785e-07)));
                                                                                                                    vec4 _9381 = vec4(_8964 + (normal * (gi.shadowConfig.z * _9372)), 1.0) * spvWorkaroundRowMajor(gi.cascadeMatrix.data[_9014]);
                                                                                                                    vec3 _9385 = _9381.xyz / vec3(_9381.w);
                                                                                                                    bool _9389 = all(lessThanEqual(abs(_9385.xy), vec2(1.0)));
                                                                                                                    _8944 = _9389;
                                                                                                                    if (!_9389)
                                                                                                                    {
                                                                                                                        _9338 = 1.0;
                                                                                                                    }
                                                                                                                    else
                                                                                                                    {
                                                                                                                        float _9400 = ((_9385.z * 0.5) + 0.5) - ((gi.shadowConfig.y * _9372) / _9374);
                                                                                                                        float _9413 = length(vec3(spvWorkaroundRowMajor(gi.cascadeMatrix.data[0])[0].x, spvWorkaroundRowMajor(gi.cascadeMatrix.data[0])[1].x, spvWorkaroundRowMajor(gi.cascadeMatrix.data[0])[2].x));
                                                                                                                        float _9418 = (_8959 * ((2.0 * gi.shadowConfig.w) / (isnan(9.9999999747524270787835121154785e-07) ? _9413 : (isnan(_9413) ? 9.9999999747524270787835121154785e-07 : max(_9413, 9.9999999747524270787835121154785e-07))))) / (isnan(9.9999999747524270787835121154785e-07) ? _9372 : (isnan(_9372) ? 9.9999999747524270787835121154785e-07 : max(_9372, 9.9999999747524270787835121154785e-07)));
                                                                                                                        float _9419 = isnan(1.0) ? _9418 : (isnan(_9418) ? 1.0 : max(_9418, 1.0));
                                                                                                                        vec2 _9426 = vec2((_9385.x * 0.5) + 0.5, 0.5 - (_9385.y * 0.5));
                                                                                                                        uvec3 _9428 = uvec3(textureSize(_13312, 0));
                                                                                                                        ivec2 _9436 = ivec2(int(_9428.x), int(_9428.y));
                                                                                                                        float _9439 = clamp(0.140399992465972900390625 / (isnan(9.9999999747524270787835121154785e-07) ? _9372 : (isnan(_9372) ? 9.9999999747524270787835121154785e-07 : max(_9372, 9.9999999747524270787835121154785e-07))), 2.0, 16.0);
                                                                                                                        float _9442 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy + vec2(7.0, 3.0), vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) * 6.283185482025146484375;
                                                                                                                        float _9443 = sin(_9442);
                                                                                                                        float _9444 = cos(_9442);
                                                                                                                        int _9342 = 0;
                                                                                                                        float _9343 = 0.0;
                                                                                                                        float _9344 = 0.0;
                                                                                                                        for (;;)
                                                                                                                        {
                                                                                                                            if (!(_9342 < 12))
                                                                                                                            {
                                                                                                                                break;
                                                                                                                            }
                                                                                                                            vec4 _9479 = texelFetch(_13312, ivec4(clamp(ivec2((_9426 + (vec2((_2344_frag[_9342].x * _9444) - (_2344_frag[_9342].y * _9443), (_2344_frag[_9342].x * _9443) + (_2344_frag[_9342].y * _9444)) * (_9439 * gi.shadowConfig.w))) * vec2(_9436)), ivec2(0), _9436 - ivec2(1)), _9014, 0).xyz, 0);
                                                                                                                            float _9480 = _9479.x;
                                                                                                                            if (_9480 < _9400)
                                                                                                                            {
                                                                                                                                _9343 += (_9400 - _9480);
                                                                                                                                _9344 += 1.0;
                                                                                                                            }
                                                                                                                            _9342++;
                                                                                                                            continue;
                                                                                                                        }
                                                                                                                        if (_9344 > 0.0)
                                                                                                                        {
                                                                                                                            float _9505 = (((_9343 / _9344) * _9374) * 0.0046799997799098491668701171875) / (isnan(9.9999999747524270787835121154785e-07) ? _9372 : (isnan(_9372) ? 9.9999999747524270787835121154785e-07 : max(_9372, 9.9999999747524270787835121154785e-07)));
                                                                                                                            _9346 = clamp(isnan(_9505) ? _9419 : (isnan(_9419) ? _9505 : max(_9419, _9505)), 1.0, 24.0);
                                                                                                                        }
                                                                                                                        else
                                                                                                                        {
                                                                                                                            _9346 = _9419;
                                                                                                                        }
                                                                                                                        vec3 _9509 = vec3(_9426, _9400);
                                                                                                                        {
                                                                                                                            if (_9346 <= 1.5)
                                                                                                                            {
                                                                                                                                _9522 = -1;
                                                                                                                                _9523 = 0.0;
                                                                                                                                for (;;)
                                                                                                                                {
                                                                                                                                    if (!(_9522 <= 1))
                                                                                                                                    {
                                                                                                                                        break;
                                                                                                                                    }
                                                                                                                                    int _9524 = -1;
                                                                                                                                    for (;;)
                                                                                                                                    {
                                                                                                                                        if (!(_9524 <= 1))
                                                                                                                                        {
                                                                                                                                            break;
                                                                                                                                        }
                                                                                                                                        int _9551 = _9524;
                                                                                                                                        _9524++;
                                                                                                                                        _9523 += spvShadowLod0(_13314, vec4(vec3(_9509.xy + (vec2(float(_9551), float(_9522)) * gi.shadowConfig.w), float(_9014)), _9400));
                                                                                                                                        continue;
                                                                                                                                    }
                                                                                                                                    _9522++;
                                                                                                                                    continue;
                                                                                                                                }
                                                                                                                                _9521 = _9523 * 0.111111111938953399658203125;
                                                                                                                            }
                                                                                                                            else
                                                                                                                            {
                                                                                                                                float _9583 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) * 6.283185482025146484375;
                                                                                                                                float _9584 = sin(_9583);
                                                                                                                                float _9585 = cos(_9583);
                                                                                                                                float _9586 = _9346 * gi.shadowConfig.w;
                                                                                                                                _9522 = 0;
                                                                                                                                _9523 = 0.0;
                                                                                                                                for (;;)
                                                                                                                                {
                                                                                                                                    if (!(_9522 < 12))
                                                                                                                                    {
                                                                                                                                        break;
                                                                                                                                    }
                                                                                                                                    int _9595 = _9522;
                                                                                                                                    _9522++;
                                                                                                                                    _9523 += spvShadowLod0(_13314, vec4(vec3(_9509.xy + (vec2((_2344_frag[_9595].x * _9585) - (_2344_frag[_9595].y * _9584), (_2344_frag[_9595].x * _9584) + (_2344_frag[_9595].y * _9585)) * _9586), float(_9014)), _9400));
                                                                                                                                    continue;
                                                                                                                                }
                                                                                                                                _9521 = _9523 * 0.083333335816860198974609375;
                                                                                                                            }
                                                                                                                        }
                                                                                                                        _9338 = _9521;
                                                                                                                    }
                                                                                                                }
                                                                                                                if (_8944)
                                                                                                                {
                                                                                                                    _8942 = _9338;
                                                                                                                }
                                                                                                                else
                                                                                                                {
                                                                                                                    _8942 = 1.0;
                                                                                                                }
                                                                                                                _8943 = _8942;
                                                                                                            }
                                                                                                            else
                                                                                                            {
                                                                                                                _8943 = 1.0;
                                                                                                            }
                                                                                                            _8943 = mix(_9040, _8943, _9009);
                                                                                                        }
                                                                                                        else
                                                                                                        {
                                                                                                            _8943 = _9040;
                                                                                                        }
                                                                                                        _8938 = true;
                                                                                                        _8939 = _8943;
                                                                                                        _8967_ladder_break = true;
                                                                                                    }
                                                                                                }
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                    if (_8967_ladder_break)
                                                                                    {
                                                                                        break;
                                                                                    }
                                                                                    _8940++;
                                                                                    continue;
                                                                                }
                                                                                if (!(_8938))
                                                                                {
                                                                                    _8938 = true;
                                                                                    _8939 = 1.0;
                                                                                }
                                                                            }
                                                                        }
                                                                        if (_8939 > 0.0)
                                                                        {
                                                                            _152 = gi.shadowConfig.x > 0.5;
                                                                        }
                                                                        else
                                                                        {
                                                                            _152 = false;
                                                                        }
                                                                        if (_152)
                                                                        {
                                                                            vec4 _2663 = spvWorkaroundRowMajor(gi.viewToWorld) * vec4(_2074, 0.0);
                                                                            _9635 = false;
                                                                            float _9636;
                                                                            {
                                                                                bool _9637;
                                                                                if (gi.camera.w <= 0.0)
                                                                                {
                                                                                    _9637 = true;
                                                                                }
                                                                                else
                                                                                {
                                                                                    _9637 = _2663.z <= (-0.999000012874603271484375);
                                                                                }
                                                                                if (_9637)
                                                                                {
                                                                                    _9635 = true;
                                                                                    _9636 = 1.0;
                                                                                }
                                                                                else
                                                                                {
                                                                                    uvec2 _9656 = uvec2(textureSize(_13290, 0));
                                                                                    vec2 _9663 = vec2(float(_9656.x), float(_9656.y));
                                                                                    vec3 _9665 = _2663.xyz * (gi.camera.w * 0.083333335816860198974609375);
                                                                                    float _9670 = _8679.z;
                                                                                    float _9671 = 0.0199999995529651641845703125 * _9670;
                                                                                    float _9672 = isnan(_9671) ? 0.300000011920928955078125 : (isnan(0.300000011920928955078125) ? _9671 : max(0.300000011920928955078125, _9671));
                                                                                    float _9674 = 0.00999999977648258209228515625 + (0.00200000009499490261077880859375 * _9670);
                                                                                    int _9640 = 0;
                                                                                    vec3 _9641 = _8679 + (_9665 * fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy + vec2(17.0, 31.0), vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))));
                                                                                    bool _9642;
                                                                                    for (;;)
                                                                                    {
                                                                                        vec3 _9684;
                                                                                        bool _9677_ladder_break = false;
                                                                                        {
                                                                                            if (!(_9640 < 12))
                                                                                            {
                                                                                                _9677_ladder_break = true;
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                _9684 = _9641 + _9665;
                                                                                                if (_9684.z <= gi.unproject.z)
                                                                                                {
                                                                                                    _9677_ladder_break = true;
                                                                                                }
                                                                                                else
                                                                                                {
                                                                                                    vec2 _9706 = vec2(0.5 + (((0.5 * _9684.x) * gi.unproject.x) / _9684.z), 0.5 - (((0.5 * _9684.y) * gi.unproject.y) / _9684.z));
                                                                                                    if (any(lessThan(_9706, vec2(0.0))))
                                                                                                    {
                                                                                                        _9637 = true;
                                                                                                    }
                                                                                                    else
                                                                                                    {
                                                                                                        _9637 = any(greaterThan(_9706, vec2(1.0)));
                                                                                                    }
                                                                                                    if (_9637)
                                                                                                    {
                                                                                                        _9677_ladder_break = true;
                                                                                                    }
                                                                                                    else
                                                                                                    {
                                                                                                        vec4 _9722 = texelFetch(_13290, ivec3(ivec2(_9706 * _9663), 0).xy, 0);
                                                                                                        float _9723 = _9722.x;
                                                                                                        if (!(_9723 <= 0.0))
                                                                                                        {
                                                                                                            float _9728 = _9684.z - (((2.0 * gi.unproject.z) * gi.unproject.w) / ((gi.unproject.w + gi.unproject.z) - ((1.0 - (2.0 * _9723)) * (gi.unproject.w - gi.unproject.z))));
                                                                                                            if (_9728 > _9674)
                                                                                                            {
                                                                                                                _9642 = _9728 < _9672;
                                                                                                            }
                                                                                                            else
                                                                                                            {
                                                                                                                _9642 = false;
                                                                                                            }
                                                                                                            if (_9642)
                                                                                                            {
                                                                                                                _9635 = true;
                                                                                                                _9636 = float(_9640) * 0.083333335816860198974609375;
                                                                                                                _9677_ladder_break = true;
                                                                                                            }
                                                                                                        }
                                                                                                    }
                                                                                                }
                                                                                            }
                                                                                        }
                                                                                        if (_9677_ladder_break)
                                                                                        {
                                                                                            break;
                                                                                        }
                                                                                        _9640++;
                                                                                        _9641 = _9684;
                                                                                        continue;
                                                                                    }
                                                                                    if (!(_9635))
                                                                                    {
                                                                                        _9635 = true;
                                                                                        _9636 = 1.0;
                                                                                    }
                                                                                }
                                                                            }
                                                                            visibility = _8939 * _9636;
                                                                        }
                                                                        else
                                                                        {
                                                                            visibility = _8939;
                                                                        }
                                                                    }
                                                                }
                                                                else
                                                                {
                                                                    visibility = 1.0;
                                                                }
                                                                if (debugView == 12)
                                                                {
                                                                    entryPointParam_fragmentMain = vec4(visibility, visibility, visibility, 1.0);
                                                                }
                                                                else
                                                                {
                                                                    if (model == 1)
                                                                    {
                                                                        if (light.sky.z > 0.5)
                                                                        {
                                                                            sunLight = vec3(0.0);
                                                                        }
                                                                        else
                                                                        {
                                                                            sunLight = (light.sunColourScale.xyz * _2077) * visibility;
                                                                        }
                                                                        vec3 _2886 = ((albedo * (baked + sunLight)) * light.sunColourScale.w) + flashDiffuse;
                                                                        vec3 _9773;
                                                                        {
                                                                            if (gi.fog.z <= 0.0)
                                                                            {
                                                                                _9773 = _2886;
                                                                            }
                                                                            else
                                                                            {
                                                                                float _9788 = (_8679.z * gi.fog.x) + gi.fog.y;
                                                                                vec4 _9803 = textureLod(_13292, vec3(input_uv, clamp(((log2(isnan(9.9999999747524270787835121154785e-07) ? _9788 : (isnan(_9788) ? 9.9999999747524270787835121154785e-07 : max(_9788, 9.9999999747524270787835121154785e-07))) * gi.fog.z) - 1.0) * gi.fog.w, 0.0, 1.0)), 0.0);
                                                                                _9773 = (_2886 * _9803.w) + _9803.xyz;
                                                                            }
                                                                        }
                                                                        entryPointParam_fragmentMain = vec4(_9773, 1.0);
                                                                    }
                                                                    else
                                                                    {
                                                                        float metallic = _5351.x;
                                                                        float specularLevel_1 = _5351.y;
                                                                        float roughness = _5351.z;
                                                                        vec3 _2901 = normalize(-(vec4(_8679, 0.0) * spvWorkaroundRowMajor(gi.viewToWorld)).xyz);
                                                                        vec3 worldRayToPixel = -_2901;
                                                                        float waterMask = 0.0;
                                                                        float waterReflectance = 0.0;
                                                                        if (gi.wetness0.x > 0.0)
                                                                        {
                                                                            _152 = !((int((_5351.w * 255.0) + 0.5) & 16) != 0);
                                                                        }
                                                                        else
                                                                        {
                                                                            _152 = false;
                                                                        }
                                                                        float specularLevel;
                                                                        if (_152)
                                                                        {
                                                                            float _2935 = dot(normal, _2901);
                                                                            float _2936 = isnan(0.001000000047497451305389404296875) ? _2935 : (isnan(_2935) ? 0.001000000047497451305389404296875 : max(_2935, 0.001000000047497451305389404296875));
                                                                            vec4 _2955 = vec4(_8679, 1.0) * spvWorkaroundRowMajor(gi.viewToWorld);
                                                                            {
                                                                                waterMask = 0.0;
                                                                                waterReflectance = 0.0;
                                                                                float _9887 = isnan(0.0) ? gi.wetness0.x : (isnan(gi.wetness0.x) ? 0.0 : max(gi.wetness0.x, 0.0));
                                                                                bool _9828;
                                                                                if (_9887 <= 0.0)
                                                                                {
                                                                                    _9828 = true;
                                                                                }
                                                                                else
                                                                                {
                                                                                    bool _9909;
                                                                                    {
                                                                                        ivec2 _9983 = ivec2(floor(((_2955.xy + gi.camera.xy) - gi.shelterMap0.xy) * gi.shelterMap0.z));
                                                                                        vec2 _12487 = gi.shelterMap2.xy;
                                                                                        bool _9984;
                                                                                        if (gi.wetness1.w > 0.5)
                                                                                        {
                                                                                            _9984 = _9983.x >= 0;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            _9984 = false;
                                                                                        }
                                                                                        if (_9984)
                                                                                        {
                                                                                            _9984 = _9983.y >= 0;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            _9984 = false;
                                                                                        }
                                                                                        if (_9984)
                                                                                        {
                                                                                            _9984 = _9983.x < int(_12487.x);
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            _9984 = false;
                                                                                        }
                                                                                        if (_9984)
                                                                                        {
                                                                                            _9984 = _9983.y < int(_12487.y);
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            _9984 = false;
                                                                                        }
                                                                                        if (!_9984)
                                                                                        {
                                                                                            _9909 = false;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            vec4 _9931 = texelFetch(_13319, ivec3(_9983, 0).xy, 0);
                                                                                            float _12491 = gi.shelterMap0.w;
                                                                                            float _12492 = gi.shelterMap1.x;
                                                                                            float _10034 = floor((_9931.z * 255.0) + 0.5) + (floor((_9931.y * 255.0) + 0.5) * 256.0);
                                                                                            float _10022;
                                                                                            if (_10034 < 0.5)
                                                                                            {
                                                                                                _10022 = -1000000015047466219876688855040.0;
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                _10022 = _12491 + ((_10034 - 1.0) * _12492);
                                                                                            }
                                                                                            float _9937 = _2955.z + gi.camera.z;
                                                                                            float _12496 = gi.shelterMap1.z;
                                                                                            bool _10047;
                                                                                            if (_10022 > (_9937 + gi.shelterMap1.y))
                                                                                            {
                                                                                                _10047 = _10022 < (_9937 + _12496);
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                _10047 = false;
                                                                                            }
                                                                                            _9909 = _10047;
                                                                                        }
                                                                                    }
                                                                                    _9828 = _9909;
                                                                                }
                                                                                if (!(_9828))
                                                                                {
                                                                                    vec3 _9844 = normal;
                                                                                    float _10067 = clamp((_9844.z * 0.5) + 0.5, 0.0, 1.0);
                                                                                    float _10090 = isnan(0.0500000007450580596923828125) ? gi.wetness1.x : (isnan(gi.wetness1.x) ? 0.0500000007450580596923828125 : max(gi.wetness1.x, 0.0500000007450580596923828125));
                                                                                    float _10098 = _10090 * 0.4600000083446502685546875;
                                                                                    vec2 _10123 = vec2((0.800000011920928955078125 * gi.camera.xy.x) - (0.60000002384185791015625 * gi.camera.xy.y), (0.60000002384185791015625 * gi.camera.xy.x) + (0.800000011920928955078125 * gi.camera.xy.y)) / vec2(_10098);
                                                                                    vec2 _10124 = floor(_10123);
                                                                                    float _10150 = _2955.x;
                                                                                    float _10153 = _2955.y;
                                                                                    vec2 _10102 = ((vec2((0.800000011920928955078125 * _10150) - (0.60000002384185791015625 * _10153), (0.60000002384185791015625 * _10150) + (0.800000011920928955078125 * _10153)) / vec2(_10098)) + (_10123 - _10124)) + vec2(11.30000019073486328125);
                                                                                    vec2 _10162 = floor(_10102);
                                                                                    vec2 _10163 = _10102 - _10162;
                                                                                    vec2 _10168 = (_10163 * _10163) * (vec2(3.0) - (_10163 * 2.0));
                                                                                    vec2 _10169 = _10162 + _10124;
                                                                                    uvec2 _10187 = uvec2(ivec2(_10169) + ivec2(1048576));
                                                                                    uint _10192 = (_10187.x * 73856093u) ^ (_10187.y * 19349663u);
                                                                                    uint _10195 = (_10192 ^ (_10192 >> uint(13))) * 1540483477u;
                                                                                    uvec2 _10206 = uvec2(ivec2(_10169 + vec2(1.0, 0.0)) + ivec2(1048576));
                                                                                    uint _10211 = (_10206.x * 73856093u) ^ (_10206.y * 19349663u);
                                                                                    uint _10214 = (_10211 ^ (_10211 >> uint(13))) * 1540483477u;
                                                                                    uvec2 _10225 = uvec2(ivec2(_10169 + vec2(0.0, 1.0)) + ivec2(1048576));
                                                                                    uint _10230 = (_10225.x * 73856093u) ^ (_10225.y * 19349663u);
                                                                                    uint _10233 = (_10230 ^ (_10230 >> uint(13))) * 1540483477u;
                                                                                    uvec2 _10244 = uvec2(ivec2(_10169 + vec2(1.0)) + ivec2(1048576));
                                                                                    uint _10249 = (_10244.x * 73856093u) ^ (_10244.y * 19349663u);
                                                                                    uint _10252 = (_10249 ^ (_10249 >> uint(13))) * 1540483477u;
                                                                                    float _10177 = _10168.x;
                                                                                    float _10181 = mix(mix(float((_10195 ^ (_10195 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, float((_10214 ^ (_10214 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, _10177), mix(float((_10233 ^ (_10233 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, float((_10252 ^ (_10252 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, _10177), _10168.y);
                                                                                    vec2 _10268 = gi.camera.xy / vec2(_10090);
                                                                                    vec2 _10269 = floor(_10268);
                                                                                    vec2 _10110 = ((vec2(_2955.xy) / vec2(_10090)) + (_10268 - _10269)) + vec2((_10181 - 0.5) * 0.4000000059604644775390625);
                                                                                    vec2 _10307 = floor(_10110);
                                                                                    vec2 _10308 = _10110 - _10307;
                                                                                    vec2 _10313 = (_10308 * _10308) * (vec2(3.0) - (_10308 * 2.0));
                                                                                    vec2 _10314 = _10307 + _10269;
                                                                                    uvec2 _10332 = uvec2(ivec2(_10314) + ivec2(1048576));
                                                                                    uint _10337 = (_10332.x * 73856093u) ^ (_10332.y * 19349663u);
                                                                                    uint _10340 = (_10337 ^ (_10337 >> uint(13))) * 1540483477u;
                                                                                    uvec2 _10351 = uvec2(ivec2(_10314 + vec2(1.0, 0.0)) + ivec2(1048576));
                                                                                    uint _10356 = (_10351.x * 73856093u) ^ (_10351.y * 19349663u);
                                                                                    uint _10359 = (_10356 ^ (_10356 >> uint(13))) * 1540483477u;
                                                                                    uvec2 _10370 = uvec2(ivec2(_10314 + vec2(0.0, 1.0)) + ivec2(1048576));
                                                                                    uint _10375 = (_10370.x * 73856093u) ^ (_10370.y * 19349663u);
                                                                                    uint _10378 = (_10375 ^ (_10375 >> uint(13))) * 1540483477u;
                                                                                    uvec2 _10389 = uvec2(ivec2(_10314 + vec2(1.0)) + ivec2(1048576));
                                                                                    uint _10394 = (_10389.x * 73856093u) ^ (_10389.y * 19349663u);
                                                                                    uint _10397 = (_10394 ^ (_10394 >> uint(13))) * 1540483477u;
                                                                                    float _10322 = _10313.x;
                                                                                    float _10077 = clamp((_9887 * mix(0.25, 1.0, _10067 * _10067)) + (((clamp(((clamp(gi.wetness0.y, 0.0, 1.0) - ((mix(mix(float((_10340 ^ (_10340 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, float((_10359 ^ (_10359 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, _10322), mix(float((_10378 ^ (_10378 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, float((_10397 ^ (_10397 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, _10322), _10313.y) * 0.64999997615814208984375) + (_10181 * 0.3499999940395355224609375))) * 6.0) + 0.89999997615814208984375, 0.0, 1.0) * clamp((_9844.z - 0.86000001430511474609375) * 12.0, 0.0, 1.0)) * _9887) * 0.449999988079071044921875), 0.0, 1.0);
                                                                                    float _10423 = isnan(0.0500000007450580596923828125) ? gi.wetness1.x : (isnan(gi.wetness1.x) ? 0.0500000007450580596923828125 : max(gi.wetness1.x, 0.0500000007450580596923828125));
                                                                                    float _10431 = _10423 * 0.4600000083446502685546875;
                                                                                    vec2 _10456 = vec2((0.800000011920928955078125 * gi.camera.xy.x) - (0.60000002384185791015625 * gi.camera.xy.y), (0.60000002384185791015625 * gi.camera.xy.x) + (0.800000011920928955078125 * gi.camera.xy.y)) / vec2(_10431);
                                                                                    vec2 _10457 = floor(_10456);
                                                                                    float _10483 = _2955.x;
                                                                                    float _10486 = _2955.y;
                                                                                    vec2 _10435 = ((vec2((0.800000011920928955078125 * _10483) - (0.60000002384185791015625 * _10486), (0.60000002384185791015625 * _10483) + (0.800000011920928955078125 * _10486)) / vec2(_10431)) + (_10456 - _10457)) + vec2(11.30000019073486328125);
                                                                                    vec2 _10495 = floor(_10435);
                                                                                    vec2 _10496 = _10435 - _10495;
                                                                                    vec2 _10501 = (_10496 * _10496) * (vec2(3.0) - (_10496 * 2.0));
                                                                                    vec2 _10502 = _10495 + _10457;
                                                                                    uvec2 _10520 = uvec2(ivec2(_10502) + ivec2(1048576));
                                                                                    uint _10525 = (_10520.x * 73856093u) ^ (_10520.y * 19349663u);
                                                                                    uint _10528 = (_10525 ^ (_10525 >> uint(13))) * 1540483477u;
                                                                                    uvec2 _10539 = uvec2(ivec2(_10502 + vec2(1.0, 0.0)) + ivec2(1048576));
                                                                                    uint _10544 = (_10539.x * 73856093u) ^ (_10539.y * 19349663u);
                                                                                    uint _10547 = (_10544 ^ (_10544 >> uint(13))) * 1540483477u;
                                                                                    uvec2 _10558 = uvec2(ivec2(_10502 + vec2(0.0, 1.0)) + ivec2(1048576));
                                                                                    uint _10563 = (_10558.x * 73856093u) ^ (_10558.y * 19349663u);
                                                                                    uint _10566 = (_10563 ^ (_10563 >> uint(13))) * 1540483477u;
                                                                                    uvec2 _10577 = uvec2(ivec2(_10502 + vec2(1.0)) + ivec2(1048576));
                                                                                    uint _10582 = (_10577.x * 73856093u) ^ (_10577.y * 19349663u);
                                                                                    uint _10585 = (_10582 ^ (_10582 >> uint(13))) * 1540483477u;
                                                                                    float _10510 = _10501.x;
                                                                                    float _10514 = mix(mix(float((_10528 ^ (_10528 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, float((_10547 ^ (_10547 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, _10510), mix(float((_10566 ^ (_10566 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, float((_10585 ^ (_10585 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, _10510), _10501.y);
                                                                                    vec2 _10601 = gi.camera.xy / vec2(_10423);
                                                                                    vec2 _10602 = floor(_10601);
                                                                                    vec2 _10443 = ((vec2(_2955.xy) / vec2(_10423)) + (_10601 - _10602)) + vec2((_10514 - 0.5) * 0.4000000059604644775390625);
                                                                                    vec2 _10640 = floor(_10443);
                                                                                    vec2 _10641 = _10443 - _10640;
                                                                                    vec2 _10646 = (_10641 * _10641) * (vec2(3.0) - (_10641 * 2.0));
                                                                                    vec2 _10647 = _10640 + _10602;
                                                                                    uvec2 _10665 = uvec2(ivec2(_10647) + ivec2(1048576));
                                                                                    uint _10670 = (_10665.x * 73856093u) ^ (_10665.y * 19349663u);
                                                                                    uint _10673 = (_10670 ^ (_10670 >> uint(13))) * 1540483477u;
                                                                                    uvec2 _10684 = uvec2(ivec2(_10647 + vec2(1.0, 0.0)) + ivec2(1048576));
                                                                                    uint _10689 = (_10684.x * 73856093u) ^ (_10684.y * 19349663u);
                                                                                    uint _10692 = (_10689 ^ (_10689 >> uint(13))) * 1540483477u;
                                                                                    uvec2 _10703 = uvec2(ivec2(_10647 + vec2(0.0, 1.0)) + ivec2(1048576));
                                                                                    uint _10708 = (_10703.x * 73856093u) ^ (_10703.y * 19349663u);
                                                                                    uint _10711 = (_10708 ^ (_10708 >> uint(13))) * 1540483477u;
                                                                                    uvec2 _10722 = uvec2(ivec2(_10647 + vec2(1.0)) + ivec2(1048576));
                                                                                    uint _10727 = (_10722.x * 73856093u) ^ (_10722.y * 19349663u);
                                                                                    uint _10730 = (_10727 ^ (_10727 >> uint(13))) * 1540483477u;
                                                                                    float _10655 = _10646.x;
                                                                                    float _10418 = (clamp((clamp(gi.wetness0.y, 0.0, 1.0) - ((mix(mix(float((_10673 ^ (_10673 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, float((_10692 ^ (_10692 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, _10655), mix(float((_10711 ^ (_10711 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, float((_10730 ^ (_10730 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, _10655), _10646.y) * 0.64999997615814208984375) + (_10514 * 0.3499999940395355224609375))) * 20.0, 0.0, 1.0) * clamp((_9844.z - 0.86000001430511474609375) * 12.0, 0.0, 1.0)) * _9887;
                                                                                    waterMask = _10418;
                                                                                    albedo *= mix(1.0, 0.60000002384185791015625, _10077);
                                                                                    float _10744 = roughness * 0.75;
                                                                                    roughness = mix(roughness, isnan(_10744) ? 0.550000011920928955078125 : (isnan(0.550000011920928955078125) ? _10744 : max(0.550000011920928955078125, _10744)), _10077);
                                                                                    if (!(_10418 <= 0.0))
                                                                                    {
                                                                                        vec3 _9859 = vec3(_10418);
                                                                                        albedo = mix(albedo, albedo * 0.5, _9859);
                                                                                        vec2 _12557 = gi.camera.xy;
                                                                                        float _12560 = gi.wetness1.z;
                                                                                        float _10752 = isnan(0.0199999995529651641845703125) ? gi.wetness1.y : (isnan(gi.wetness1.y) ? 0.0199999995529651641845703125 : max(gi.wetness1.y, 0.0199999995529651641845703125));
                                                                                        float _10755 = gi.wetness0.w * 0.60000002384185791015625;
                                                                                        int _10789 = 0;
                                                                                        vec2 _10790 = vec2(0.0);
                                                                                        vec2 _10893;
                                                                                        vec2 _10898;
                                                                                        SPIRV_CROSS_UNROLL
                                                                                        for (;;)
                                                                                        {
                                                                                            bool _10800_ladder_break = false;
                                                                                            {
                                                                                                if (!(_10789 < 4))
                                                                                                {
                                                                                                    _10800_ladder_break = true;
                                                                                                }
                                                                                                else
                                                                                                {
                                                                                                    vec4 _10791 = vec4(0.0, 0.2199999988079071044921875, 0.439999997615814208984375, 0.660000026226043701171875);
                                                                                                    float _10811 = clamp((gi.wetness0.z - _10791[_10789]) * 4.0, 0.0, 1.0);
                                                                                                    if (!(_10811 <= 0.0))
                                                                                                    {
                                                                                                        vec4 _10792 = vec4(0.519999980926513671875, 0.7400000095367431640625, 0.9700000286102294921875, 1.2799999713897705078125);
                                                                                                        float _10818 = _10752 * _10792[_10789];
                                                                                                        vec2 _10855 = _12557 / vec2(_10818);
                                                                                                        vec2 _10856 = floor(_10855);
                                                                                                        vec4 _10793 = vec4(0.959999978542327880859375, 0.810000002384185791015625, 0.88999998569488525390625, 0.7200000286102294921875);
                                                                                                        vec4 _10794 = vec4(0.0, 0.310000002384185791015625, 0.579999983310699462890625, 0.829999983310699462890625);
                                                                                                        float _10828 = fract((_10755 * _10793[_10789]) + _10794[_10789]);
                                                                                                        vec2 _10833 = ((vec2(_2955.xy) / vec2(_10818)) + (_10855 - _10856)) + _3596_frag[_10789];
                                                                                                        {
                                                                                                            if (_10811 <= 0.0)
                                                                                                            {
                                                                                                                _10893 = vec2(0.0);
                                                                                                            }
                                                                                                            else
                                                                                                            {
                                                                                                                float _10906 = mix(0.20000000298023223876953125, 1.0, clamp(_10811, 0.0, 1.0));
                                                                                                                vec2 _10909 = floor(_10833 - vec2(0.5));
                                                                                                                int _10894 = 0;
                                                                                                                vec2 _10895 = vec2(0.0);
                                                                                                                for (;;)
                                                                                                                {
                                                                                                                    if (!(_10894 < 2))
                                                                                                                    {
                                                                                                                        break;
                                                                                                                    }
                                                                                                                    int _10896 = 0;
                                                                                                                    vec2 _10897 = _10895;
                                                                                                                    for (;;)
                                                                                                                    {
                                                                                                                        bool _10921_ladder_break = false;
                                                                                                                        {
                                                                                                                            if (!(_10896 < 2))
                                                                                                                            {
                                                                                                                                _10921_ladder_break = true;
                                                                                                                            }
                                                                                                                            else
                                                                                                                            {
                                                                                                                                vec2 _10932 = _10909 + vec2(float(_10896), float(_10894));
                                                                                                                                vec2 _10935 = _10833 - (_10932 + vec2(0.5));
                                                                                                                                if (!(dot(_10935, _10935) > 0.608399927616119384765625))
                                                                                                                                {
                                                                                                                                    uvec2 _10995 = uvec2(ivec2(_10932 + _10856) + ivec2(1048576));
                                                                                                                                    uint _11000 = (_10995.x * 73856093u) ^ (_10995.y * 19349663u);
                                                                                                                                    uint _11003 = (_11000 ^ (_11000 >> uint(13))) * 1540483477u;
                                                                                                                                    uint _11005 = _11003 ^ (_11003 >> uint(15));
                                                                                                                                    uint _11006 = _11005 * 668265261u;
                                                                                                                                    uint _11008 = _11006 ^ (_11006 >> uint(15));
                                                                                                                                    uint _11009 = _11008 * 2246822507u;
                                                                                                                                    vec3 _11019 = vec3(float(_11005 & 16777215u), float(_11008 & 16777215u), float((_11009 ^ (_11009 >> uint(13))) & 16777215u)) * 5.9604651880817982601001858711243e-08;
                                                                                                                                    float _10944 = fract(_10828 + _11019.x);
                                                                                                                                    vec2 _10949 = _10935 - ((_11019.yz - vec2(0.5)) * 0.5);
                                                                                                                                    float _10950 = length(_10949);
                                                                                                                                    if (_10950 > 9.9999997473787516355514526367188e-06)
                                                                                                                                    {
                                                                                                                                        _10898 = _10949 / vec2(_10950);
                                                                                                                                    }
                                                                                                                                    else
                                                                                                                                    {
                                                                                                                                        _10898 = vec2(0.0);
                                                                                                                                    }
                                                                                                                                    _10897 -= (_10898 * ((sin(3.1415927410125732421875 * clamp((_10944 - clamp(_10950 * 2.17391300201416015625, 0.0, 1.0)) * 24.0, 0.0, 4.0)) * clamp(_10906 - _10944, 0.0, 1.0)) * 0.449999988079071044921875));
                                                                                                                                }
                                                                                                                            }
                                                                                                                        }
                                                                                                                        if (_10921_ladder_break)
                                                                                                                        {
                                                                                                                            break;
                                                                                                                        }
                                                                                                                        _10896++;
                                                                                                                        continue;
                                                                                                                    }
                                                                                                                    _10894++;
                                                                                                                    _10895 = _10897;
                                                                                                                    continue;
                                                                                                                }
                                                                                                                _10893 = _10895;
                                                                                                            }
                                                                                                        }
                                                                                                        _10790 += _10893;
                                                                                                    }
                                                                                                }
                                                                                            }
                                                                                            if (_10800_ladder_break)
                                                                                            {
                                                                                                break;
                                                                                            }
                                                                                            _10789++;
                                                                                            continue;
                                                                                        }
                                                                                        vec2 _11047 = _12557 * vec2(0.5555555820465087890625);
                                                                                        vec2 _11048 = floor(_11047);
                                                                                        vec2 _11027 = ((vec2(_2955.xy) * vec2(0.5555555820465087890625)) + (_11047 - _11048)) + vec2(gi.wetness0.w * 0.07999999821186065673828125, gi.wetness0.w * 0.0500000007450580596923828125);
                                                                                        vec2 _11086 = floor(_11027);
                                                                                        vec2 _11087 = _11027 - _11086;
                                                                                        vec2 _11092 = (_11087 * _11087) * (vec2(3.0) - (_11087 * 2.0));
                                                                                        vec2 _11093 = _11086 + _11048;
                                                                                        uvec2 _11111 = uvec2(ivec2(_11093) + ivec2(1048576));
                                                                                        uint _11116 = (_11111.x * 73856093u) ^ (_11111.y * 19349663u);
                                                                                        uint _11119 = (_11116 ^ (_11116 >> uint(13))) * 1540483477u;
                                                                                        uvec2 _11130 = uvec2(ivec2(_11093 + vec2(1.0, 0.0)) + ivec2(1048576));
                                                                                        uint _11135 = (_11130.x * 73856093u) ^ (_11130.y * 19349663u);
                                                                                        uint _11138 = (_11135 ^ (_11135 >> uint(13))) * 1540483477u;
                                                                                        uvec2 _11149 = uvec2(ivec2(_11093 + vec2(0.0, 1.0)) + ivec2(1048576));
                                                                                        uint _11154 = (_11149.x * 73856093u) ^ (_11149.y * 19349663u);
                                                                                        uint _11157 = (_11154 ^ (_11154 >> uint(13))) * 1540483477u;
                                                                                        uvec2 _11168 = uvec2(ivec2(_11093 + vec2(1.0)) + ivec2(1048576));
                                                                                        uint _11173 = (_11168.x * 73856093u) ^ (_11168.y * 19349663u);
                                                                                        uint _11176 = (_11173 ^ (_11173 >> uint(13))) * 1540483477u;
                                                                                        float _11101 = _11092.x;
                                                                                        float _11105 = mix(mix(float((_11119 ^ (_11119 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, float((_11138 ^ (_11138 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, _11101), mix(float((_11157 ^ (_11157 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, float((_11176 ^ (_11176 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, _11101), _11092.y);
                                                                                        vec2 _11030 = _11027 + vec2(0.1500000059604644775390625, 0.0);
                                                                                        vec2 _11184 = floor(_11030);
                                                                                        vec2 _11185 = _11030 - _11184;
                                                                                        vec2 _11190 = (_11185 * _11185) * (vec2(3.0) - (_11185 * 2.0));
                                                                                        vec2 _11191 = _11184 + _11048;
                                                                                        uvec2 _11209 = uvec2(ivec2(_11191) + ivec2(1048576));
                                                                                        uint _11214 = (_11209.x * 73856093u) ^ (_11209.y * 19349663u);
                                                                                        uint _11217 = (_11214 ^ (_11214 >> uint(13))) * 1540483477u;
                                                                                        uvec2 _11228 = uvec2(ivec2(_11191 + vec2(1.0, 0.0)) + ivec2(1048576));
                                                                                        uint _11233 = (_11228.x * 73856093u) ^ (_11228.y * 19349663u);
                                                                                        uint _11236 = (_11233 ^ (_11233 >> uint(13))) * 1540483477u;
                                                                                        uvec2 _11247 = uvec2(ivec2(_11191 + vec2(0.0, 1.0)) + ivec2(1048576));
                                                                                        uint _11252 = (_11247.x * 73856093u) ^ (_11247.y * 19349663u);
                                                                                        uint _11255 = (_11252 ^ (_11252 >> uint(13))) * 1540483477u;
                                                                                        uvec2 _11266 = uvec2(ivec2(_11191 + vec2(1.0)) + ivec2(1048576));
                                                                                        uint _11271 = (_11266.x * 73856093u) ^ (_11266.y * 19349663u);
                                                                                        uint _11274 = (_11271 ^ (_11271 >> uint(13))) * 1540483477u;
                                                                                        vec2 _11033 = _11027 + vec2(0.0, 0.1500000059604644775390625);
                                                                                        vec2 _11282 = floor(_11033);
                                                                                        vec2 _11283 = _11033 - _11282;
                                                                                        vec2 _11288 = (_11283 * _11283) * (vec2(3.0) - (_11283 * 2.0));
                                                                                        vec2 _11289 = _11282 + _11048;
                                                                                        uvec2 _11307 = uvec2(ivec2(_11289) + ivec2(1048576));
                                                                                        uint _11312 = (_11307.x * 73856093u) ^ (_11307.y * 19349663u);
                                                                                        uint _11315 = (_11312 ^ (_11312 >> uint(13))) * 1540483477u;
                                                                                        uvec2 _11326 = uvec2(ivec2(_11289 + vec2(1.0, 0.0)) + ivec2(1048576));
                                                                                        uint _11331 = (_11326.x * 73856093u) ^ (_11326.y * 19349663u);
                                                                                        uint _11334 = (_11331 ^ (_11331 >> uint(13))) * 1540483477u;
                                                                                        uvec2 _11345 = uvec2(ivec2(_11289 + vec2(0.0, 1.0)) + ivec2(1048576));
                                                                                        uint _11350 = (_11345.x * 73856093u) ^ (_11345.y * 19349663u);
                                                                                        uint _11353 = (_11350 ^ (_11350 >> uint(13))) * 1540483477u;
                                                                                        uvec2 _11364 = uvec2(ivec2(_11289 + vec2(1.0)) + ivec2(1048576));
                                                                                        uint _11369 = (_11364.x * 73856093u) ^ (_11364.y * 19349663u);
                                                                                        uint _11372 = (_11369 ^ (_11369 >> uint(13))) * 1540483477u;
                                                                                        vec2 _10763 = (vec2(mix(mix(float((_11217 ^ (_11217 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, float((_11236 ^ (_11236 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, _11190.x), mix(float((_11255 ^ (_11255 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, float((_11274 ^ (_11274 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, _11190.x), _11190.y) - _11105, mix(mix(float((_11315 ^ (_11315 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, float((_11334 ^ (_11334 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, _11288.x), mix(float((_11353 ^ (_11353 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, float((_11372 ^ (_11372 >> uint(15))) & 16777215u) * 5.9604651880817982601001858711243e-08, _11288.x), _11288.y) - _11105) * _12560) * 1.60000002384185791015625;
                                                                                        vec2 _10764 = _10790 + _10763;
                                                                                        float _10767 = clamp(((abs((_5334 * 2.0) * _8679.z) / (isnan(9.9999997473787516355514526367188e-05) ? gi.unproject.x : (isnan(gi.unproject.x) ? 9.9999997473787516355514526367188e-05 : max(gi.unproject.x, 9.9999997473787516355514526367188e-05)))) / (isnan(0.07999999821186065673828125) ? _2936 : (isnan(_2936) ? 0.07999999821186065673828125 : max(_2936, 0.07999999821186065673828125)))) / (_10752 * 0.5), 0.0, 1.0);
                                                                                        float _10769 = 1.0 - _10767;
                                                                                        vec3 _9862 = normal;
                                                                                        vec3 _9865 = normalize(mix(_9862, normalize(vec3(_10764 * _10769, 1.0)), _9859));
                                                                                        normal = _9865;
                                                                                        roughness = mix(roughness, clamp((0.0500000007450580596923828125 + ((length(_10764) * _10769) * 0.100000001490116119384765625)) + (((0.20000000298023223876953125 * gi.wetness0.z) + (0.100000001490116119384765625 * _12560)) * _10767), 0.0500000007450580596923828125, 0.319999992847442626953125), _10418);
                                                                                        float _11382 = 1.0 - clamp(dot(_9865, _2901), 0.0, 1.0);
                                                                                        float _11383 = _11382 * _11382;
                                                                                        float _9871 = (0.0199999995529651641845703125 + (((0.980000019073486328125 * _11383) * _11383) * _11382)) * _10418;
                                                                                        waterReflectance = _9871;
                                                                                        albedo *= (1.0 - _9871);
                                                                                    }
                                                                                }
                                                                            }
                                                                            float _3883 = 0.5 * waterMask;
                                                                            specularLevel = isnan(_3883) ? specularLevel_1 : (isnan(specularLevel_1) ? _3883 : max(specularLevel_1, _3883));
                                                                        }
                                                                        else
                                                                        {
                                                                            specularLevel = specularLevel_1;
                                                                        }
                                                                        if (debugView == 13)
                                                                        {
                                                                            entryPointParam_fragmentMain = vec4(waterMask, (normal.xy * 0.5) + vec2(0.5), 1.0);
                                                                        }
                                                                        else
                                                                        {
                                                                            vec3 sunIlluminance = light.sunColourScale.xyz * light.sunColourScale.w;
                                                                            vec3 _11394 = mix(vec3(0.07999999821186065673828125 * specularLevel), albedo, vec3(metallic));
                                                                            float _11395 = isnan(0.0199999995529651641845703125) ? roughness : (isnan(roughness) ? 0.0199999995529651641845703125 : max(roughness, 0.0199999995529651641845703125));
                                                                            float _11396 = _11395 * _11395;
                                                                            float _11397 = _11396 * _11396;
                                                                            vec3 _11398 = _2901 + _2074;
                                                                            float _11399 = dot(_11398, _11398);
                                                                            vec3 _11402 = _11398 * inversesqrt(isnan(9.9999999392252902907785028219223e-09) ? _11399 : (isnan(_11399) ? 9.9999999392252902907785028219223e-09 : max(_11399, 9.9999999392252902907785028219223e-09)));
                                                                            float _11404 = clamp(dot(normal, _11402), 0.0, 1.0);
                                                                            float _11408 = clamp(dot(normal, _2074), 0.0, 1.0);
                                                                            float _11412 = clamp(abs(dot(normal, _2901)) + 9.9999997473787516355514526367188e-06, 0.0, 1.0);
                                                                            float _11416 = ((_11404 * _11404) * (_11397 - 1.0)) + 1.0;
                                                                            float _11423 = mix((2.0 * _11408) * _11412, _11408 + _11412, _11396);
                                                                            vec3 sunLight_1 = ((((albedo * (1.0 - metallic)) * (_11408 * 0.3183098733425140380859375)) + (((_11394 + ((vec3(clamp(50.0 * _11394.y, 0.0, 1.0)) - _11394) * pow(1.0 - clamp(dot(_2901, _11402), 0.0, 1.0), 5.0))) * ((_11397 / ((3.1415927410125732421875 * _11416) * _11416)) * (0.5 / (isnan(9.9999999747524270787835121154785e-07) ? _11423 : (isnan(_11423) ? 9.9999999747524270787835121154785e-07 : max(_11423, 9.9999999747524270787835121154785e-07)))))) * _11408)) * sunIlluminance) * visibility;
                                                                            if (waterReflectance > 0.0)
                                                                            {
                                                                                vec3 _3986 = normalize(reflect(worldRayToPixel, normal));
                                                                                float _11449 = (gi.giParams.w * gi.giParams.w) - 40449600.0;
                                                                                float _11454 = acos(clamp(sqrt(isnan(_11449) ? 0.0 : (isnan(0.0) ? _11449 : max(0.0, _11449))) / gi.giParams.w, -1.0, 1.0));
                                                                                float _11455 = 3.1415927410125732421875 - _11454;
                                                                                float _11458 = acos(clamp(_3986.z, -1.0, 1.0));
                                                                                float _11444;
                                                                                if (_11458 < _11455)
                                                                                {
                                                                                    float _11470 = 1.0 - (_11458 / _11455);
                                                                                    _11444 = (1.0 - sqrt(isnan(_11470) ? 0.0 : (isnan(0.0) ? _11470 : max(0.0, _11470)))) * 0.5;
                                                                                }
                                                                                else
                                                                                {
                                                                                    float _11463 = (_11458 - _11455) / (isnan(9.9999999747524270787835121154785e-07) ? _11454 : (isnan(_11454) ? 9.9999999747524270787835121154785e-07 : max(_11454, 9.9999999747524270787835121154785e-07)));
                                                                                    _11444 = (sqrt(isnan(_11463) ? 0.0 : (isnan(0.0) ? _11463 : max(0.0, _11463))) * 0.5) + 0.5;
                                                                                }
                                                                                float _11478 = atan(_3986.y, _3986.x);
                                                                                float _11445;
                                                                                if (_11478 < 0.0)
                                                                                {
                                                                                    _11445 = _11478 + 6.283185482025146484375;
                                                                                }
                                                                                else
                                                                                {
                                                                                    _11445 = _11478;
                                                                                }
                                                                                uvec2 _11493 = uvec2(textureSize(_13295, 0));
                                                                                vec2 _11500 = vec2(float(_11493.x), float(_11493.y));
                                                                                sunLight = sunLight_1 + ((textureLod(_13297, (vec2(_11445 * 0.15915493667125701904296875, _11444) * ((_11500 - vec2(1.0)) / _11500)) + (vec2(0.5) / _11500), 0.0).xyz * waterReflectance) * clamp(_3986.z * 20.0, 0.0, 1.0));
                                                                            }
                                                                            else
                                                                            {
                                                                                sunLight = sunLight_1;
                                                                            }
                                                                            int _4017 = int(lamps.control.x + 0.5);
                                                                            float _4018 = _8679.z;
                                                                            uvec2 _11536 = uvec2(textureSize(_13302, 0));
                                                                            uint _11537 = _11536.x;
                                                                            uint _11521 = _11537;
                                                                            uint _11538 = _11536.y;
                                                                            uint _11522 = _11538;
                                                                            ivec2 _11545 = ivec2(int(_11537) - 1, int(_11538) - 1);
                                                                            uvec2 _11547 = uvec2(textureSize(_13322, 0));
                                                                            vec2 _11554 = vec2(float(_11547.x), float(_11547.y));
                                                                            vec2 _11557 = (input_uv * _11554) - vec2(0.5);
                                                                            vec2 _11558 = fract(_11557);
                                                                            ivec2 _11560 = ivec2(floor(_11557));
                                                                            ivec2 _11563 = ivec2(_11554) - ivec2(1);
                                                                            float _11564 = _11558.x;
                                                                            float _11565 = 1.0 - _11564;
                                                                            float _11566 = _11558.y;
                                                                            float _11567 = 1.0 - _11566;
                                                                            vec4 _11525 = vec4(_11565 * _11567, _11564 * _11567, _11565 * _11566, _11564 * _11566);
                                                                            float _11526 = 1000000015047466219876688855040.0;
                                                                            vec2 _11528 = vec2(1.0, 0.0);
                                                                            int _11530 = 0;
                                                                            vec2 _11529 = vec2(0.0);
                                                                            float _11527 = 0.0;
                                                                            vec2 _11531;
                                                                            float _11532;
                                                                            for (;;)
                                                                            {
                                                                                bool _11575_ladder_break = false;
                                                                                {
                                                                                    if (!(_11530 < 4))
                                                                                    {
                                                                                        _11575_ladder_break = true;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        ivec2 _11587 = clamp(_11560 + ivec2(_11530 & 1, _11530 >> 1), ivec2(0), _11563);
                                                                                        vec4 _11591 = texelFetch(_13322, ivec3(_11587, 0).xy, 0);
                                                                                        float _11593 = _11591.z;
                                                                                        if (!(_11593 <= 0.0))
                                                                                        {
                                                                                            float _11598 = abs(_11593 - _4018);
                                                                                            if (_11598 < _11526)
                                                                                            {
                                                                                                _11532 = _11598;
                                                                                                _11531 = _11591.xy;
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                _11532 = _11526;
                                                                                                _11531 = _11528;
                                                                                            }
                                                                                            float _11626 = clamp(dot(normalize((texelFetch(_13302, ivec3(clamp(ivec2((vec2(_11587) + vec2(0.5)) * (vec2(float(_11521), float(_11522)) / _11554)), ivec2(0), _11545), 0).xy, 0).xyz * 2.0) - vec3(1.0)), normal), 0.0, 1.0);
                                                                                            float _11631 = 0.02999999932944774627685546875 * _4018;
                                                                                            float _11639 = ((((_11525[_11530] * exp2((-_11598) / (isnan(0.001000000047497451305389404296875) ? _11631 : (isnan(_11631) ? 0.001000000047497451305389404296875 : max(_11631, 0.001000000047497451305389404296875))))) * _11626) * _11626) * _11626) * _11626;
                                                                                            _11526 = _11532;
                                                                                            _11528 = _11531;
                                                                                            _11529 += (_11591.xy * _11639);
                                                                                            _11527 += _11639;
                                                                                        }
                                                                                    }
                                                                                }
                                                                                if (_11575_ladder_break)
                                                                                {
                                                                                    break;
                                                                                }
                                                                                _11530++;
                                                                                continue;
                                                                            }
                                                                            if (_11527 > 9.9999997473787516355514526367188e-05)
                                                                            {
                                                                                _11531 = _11529 / vec2(_11527);
                                                                            }
                                                                            else
                                                                            {
                                                                                _11531 = _11528;
                                                                            }
                                                                            vec3 _11668 = vec3(_11531, _13275);
                                                                            bool lampShadows = lamps.control.y > 0.5;
                                                                            float lampOcclusion;
                                                                            if (lampShadows)
                                                                            {
                                                                                lampOcclusion = clamp(_11668.x, 0.0, 1.0);
                                                                            }
                                                                            else
                                                                            {
                                                                                lampOcclusion = 1.0;
                                                                            }
                                                                            if (debugView == 29)
                                                                            {
                                                                                float _4225 = _11668.y;
                                                                                if (_4225 > 0.0040000001899898052215576171875)
                                                                                {
                                                                                    visibility = clamp(_4225, 0.0, 1.0);
                                                                                }
                                                                                else
                                                                                {
                                                                                    visibility = 0.0;
                                                                                }
                                                                                entryPointParam_fragmentMain = vec4(clamp(_11668.x, 0.0, 1.0), visibility, 0.0, 1.0);
                                                                            }
                                                                            else
                                                                            {
                                                                                float trust;
                                                                                if (debugView == 30)
                                                                                {
                                                                                    float _4241 = clamp(_11668.x, 0.0, 1.0);
                                                                                    float _4242 = _11668.y;
                                                                                    if (_4242 > 0.0)
                                                                                    {
                                                                                        trust = clamp(_4242 - 0.00200000009499490261077880859375, 0.0, 1.0);
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        trust = 0.0;
                                                                                    }
                                                                                    entryPointParam_fragmentMain = vec4(clamp((1.0 - _4241) - trust, 0.0, 1.0), _4241, trust, 1.0);
                                                                                }
                                                                                else
                                                                                {
                                                                                    if (debugView == 26)
                                                                                    {
                                                                                        if (lampShadows)
                                                                                        {
                                                                                            _152 = _11668.y <= 0.0;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            _152 = false;
                                                                                        }
                                                                                        if (_152)
                                                                                        {
                                                                                            _154 = vec4(0.60000002384185791015625, 0.0, 0.0, 1.0);
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            _154 = vec4(lampOcclusion, lampOcclusion, lampOcclusion, 1.0);
                                                                                        }
                                                                                        entryPointParam_fragmentMain = _154;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        int i = 0;
                                                                                        vec3 lampLight = vec3(0.0);
                                                                                        vec3 _11677;
                                                                                        float _11678;
                                                                                        float _11679;
                                                                                        float _11680;
                                                                                        vec3 _11681;
                                                                                        bool _11682;
                                                                                        float _11830;
                                                                                        float _11865;
                                                                                        float _11866;
                                                                                        float _11867;
                                                                                        for (;;)
                                                                                        {
                                                                                            bool _283_ladder_break = false;
                                                                                            {
                                                                                                if (!(i < _4017))
                                                                                                {
                                                                                                    _283_ladder_break = true;
                                                                                                }
                                                                                                else
                                                                                                {
                                                                                                    {
                                                                                                        vec3 _11693 = lamps.positionRadius.data[i].xyz - _8679;
                                                                                                        float _11694 = dot(_11693, _11693);
                                                                                                        {
                                                                                                            float _11834 = lamps.positionRadius.data[i].w * lamps.positionRadius.data[i].w;
                                                                                                            if (_11694 >= _11834)
                                                                                                            {
                                                                                                                _11830 = 0.0;
                                                                                                            }
                                                                                                            else
                                                                                                            {
                                                                                                                float _11839 = _11694 / (isnan(9.9999997473787516355514526367188e-05) ? _11834 : (isnan(_11834) ? 9.9999997473787516355514526367188e-05 : max(_11834, 9.9999997473787516355514526367188e-05)));
                                                                                                                float _11842 = clamp(1.0 - (_11839 * _11839), 0.0, 1.0);
                                                                                                                _11830 = _11842 * _11842;
                                                                                                            }
                                                                                                        }
                                                                                                        if (_11830 <= 0.0)
                                                                                                        {
                                                                                                            _11677 = vec3(0.0);
                                                                                                        }
                                                                                                        else
                                                                                                        {
                                                                                                            vec3 _11704 = (vec4(_11693, 0.0) * spvWorkaroundRowMajor(gi.viewToWorld)).xyz;
                                                                                                            vec3 _11707 = _11704 * inversesqrt(isnan(9.9999999392252902907785028219223e-09) ? _11694 : (isnan(_11694) ? 9.9999999392252902907785028219223e-09 : max(_11694, 9.9999999392252902907785028219223e-09)));
                                                                                                            if (dot(lamps.direction.data[i].xyz, lamps.direction.data[i].xyz) > 0.25)
                                                                                                            {
                                                                                                                float _11855 = dot(normalize((vec4(lamps.direction.data[i].xyz, 0.0) * spvWorkaroundRowMajor(gi.viewToWorld)).xyz), -_11707);
                                                                                                                _11678 = _11830 * (isnan(0.0) ? _11855 : (isnan(_11855) ? 0.0 : max(_11855, 0.0)));
                                                                                                            }
                                                                                                            else
                                                                                                            {
                                                                                                                _11678 = _11830;
                                                                                                            }
                                                                                                            if (_11678 <= 0.0)
                                                                                                            {
                                                                                                                _11677 = vec3(0.0);
                                                                                                            }
                                                                                                            else
                                                                                                            {
                                                                                                                float _11738 = clamp(lamps.direction.data[i].w, 0.0500000007450580596923828125, 1.0);
                                                                                                                vec3 _11747 = (vec4(lamps.rect.data[i].xyz, 0.0) * spvWorkaroundRowMajor(gi.viewToWorld)).xyz;
                                                                                                                if (dot(_11747, _11747) > 9.9999997473787516355514526367188e-05)
                                                                                                                {
                                                                                                                    vec3 _11753 = _11704 - _11747;
                                                                                                                    vec3 _11754 = _11747 * 2.0;
                                                                                                                    {
                                                                                                                        float _11871 = dot(normal, _11753);
                                                                                                                        float _11872 = dot(normal, _11754);
                                                                                                                        if (abs(_11872) > 9.9999999747524270787835121154785e-07)
                                                                                                                        {
                                                                                                                            float _11881 = (-_11871) / _11872;
                                                                                                                            if (_11872 > 0.0)
                                                                                                                            {
                                                                                                                                _11866 = 1.0;
                                                                                                                                _11867 = isnan(_11881) ? 0.0 : (isnan(0.0) ? _11881 : max(0.0, _11881));
                                                                                                                            }
                                                                                                                            else
                                                                                                                            {
                                                                                                                                _11866 = isnan(_11881) ? 1.0 : (isnan(1.0) ? _11881 : min(1.0, _11881));
                                                                                                                                _11867 = 0.0;
                                                                                                                            }
                                                                                                                            if (_11866 <= _11867)
                                                                                                                            {
                                                                                                                                _11865 = 0.0;
                                                                                                                            }
                                                                                                                            else
                                                                                                                            {
                                                                                                                                float _11894 = dot(_11754, _11754);
                                                                                                                                float _11895 = dot(_11753, _11754);
                                                                                                                                float _11896 = dot(_11753, _11753);
                                                                                                                                float _11899 = (_11894 * _11896) - (_11895 * _11895);
                                                                                                                                if (_11899 <= ((9.9999997473787516355514526367188e-06 * _11894) * _11896))
                                                                                                                                {
                                                                                                                                    vec3 _11909 = _11753 + (_11754 * (0.5 * (_11867 + _11866)));
                                                                                                                                    float _11910 = dot(_11909, _11909);
                                                                                                                                    float _11911 = isnan(9.9999997473787516355514526367188e-05) ? _11910 : (isnan(_11910) ? 9.9999997473787516355514526367188e-05 : max(_11910, 9.9999997473787516355514526367188e-05));
                                                                                                                                    _11865 = (clamp(dot(normal, _11909) * inversesqrt(_11911), 0.0, 1.0) / _11911) * (_11866 - _11867);
                                                                                                                                }
                                                                                                                                else
                                                                                                                                {
                                                                                                                                    float _11923 = _11894 * _11867;
                                                                                                                                    float _11926 = 2.0 * _11895;
                                                                                                                                    float _11930 = ((_11923 * _11867) + (_11926 * _11867)) + _11896;
                                                                                                                                    float _11934 = _11894 * _11866;
                                                                                                                                    float _11940 = ((_11934 * _11866) + (_11926 * _11866)) + _11896;
                                                                                                                                    float _11961 = (((_11871 * (_11934 + _11895)) - (_11872 * ((_11895 * _11866) + _11896))) / (_11899 * sqrt(isnan(9.9999999392252902907785028219223e-09) ? _11940 : (isnan(_11940) ? 9.9999999392252902907785028219223e-09 : max(_11940, 9.9999999392252902907785028219223e-09))))) - (((_11871 * (_11923 + _11895)) - (_11872 * ((_11895 * _11867) + _11896))) / (_11899 * sqrt(isnan(9.9999999392252902907785028219223e-09) ? _11930 : (isnan(_11930) ? 9.9999999392252902907785028219223e-09 : max(_11930, 9.9999999392252902907785028219223e-09)))));
                                                                                                                                    _11865 = isnan(0.0) ? _11961 : (isnan(_11961) ? 0.0 : max(_11961, 0.0));
                                                                                                                                }
                                                                                                                            }
                                                                                                                        }
                                                                                                                        else
                                                                                                                        {
                                                                                                                            if (_11871 <= 0.0)
                                                                                                                            {
                                                                                                                                _11865 = 0.0;
                                                                                                                            }
                                                                                                                            else
                                                                                                                            {
                                                                                                                                _11866 = 1.0;
                                                                                                                                _11867 = 0.0;
                                                                                                                                if (_11866 <= _11867)
                                                                                                                                {
                                                                                                                                    _11865 = 0.0;
                                                                                                                                }
                                                                                                                                else
                                                                                                                                {
                                                                                                                                    float _11894 = dot(_11754, _11754);
                                                                                                                                    float _11895 = dot(_11753, _11754);
                                                                                                                                    float _11896 = dot(_11753, _11753);
                                                                                                                                    float _11899 = (_11894 * _11896) - (_11895 * _11895);
                                                                                                                                    if (_11899 <= ((9.9999997473787516355514526367188e-06 * _11894) * _11896))
                                                                                                                                    {
                                                                                                                                        vec3 _11909 = _11753 + (_11754 * (0.5 * (_11867 + _11866)));
                                                                                                                                        float _11910 = dot(_11909, _11909);
                                                                                                                                        float _11911 = isnan(9.9999997473787516355514526367188e-05) ? _11910 : (isnan(_11910) ? 9.9999997473787516355514526367188e-05 : max(_11910, 9.9999997473787516355514526367188e-05));
                                                                                                                                        _11865 = (clamp(dot(normal, _11909) * inversesqrt(_11911), 0.0, 1.0) / _11911) * (_11866 - _11867);
                                                                                                                                    }
                                                                                                                                    else
                                                                                                                                    {
                                                                                                                                        float _11923 = _11894 * _11867;
                                                                                                                                        float _11926 = 2.0 * _11895;
                                                                                                                                        float _11930 = ((_11923 * _11867) + (_11926 * _11867)) + _11896;
                                                                                                                                        float _11934 = _11894 * _11866;
                                                                                                                                        float _11940 = ((_11934 * _11866) + (_11926 * _11866)) + _11896;
                                                                                                                                        float _11961 = (((_11871 * (_11934 + _11895)) - (_11872 * ((_11895 * _11866) + _11896))) / (_11899 * sqrt(isnan(9.9999999392252902907785028219223e-09) ? _11940 : (isnan(_11940) ? 9.9999999392252902907785028219223e-09 : max(_11940, 9.9999999392252902907785028219223e-09))))) - (((_11871 * (_11923 + _11895)) - (_11872 * ((_11895 * _11867) + _11896))) / (_11899 * sqrt(isnan(9.9999999392252902907785028219223e-09) ? _11930 : (isnan(_11930) ? 9.9999999392252902907785028219223e-09 : max(_11930, 9.9999999392252902907785028219223e-09)))));
                                                                                                                                        _11865 = isnan(0.0) ? _11961 : (isnan(_11961) ? 0.0 : max(_11961, 0.0));
                                                                                                                                    }
                                                                                                                                }
                                                                                                                            }
                                                                                                                        }
                                                                                                                    }
                                                                                                                    vec3 _11757 = reflect(-_2901, normal);
                                                                                                                    float _11758 = dot(_11757, _11754);
                                                                                                                    float _11761 = dot(_11754, _11754) - (_11758 * _11758);
                                                                                                                    if (_11761 > 9.9999999747524270787835121154785e-07)
                                                                                                                    {
                                                                                                                        _11679 = ((dot(_11757, _11753) * _11758) - dot(_11753, _11754)) / _11761;
                                                                                                                    }
                                                                                                                    else
                                                                                                                    {
                                                                                                                        _11679 = 0.5;
                                                                                                                    }
                                                                                                                    _11681 = _11753 + (_11754 * clamp(_11679, 0.0, 1.0));
                                                                                                                    _11679 = _11865;
                                                                                                                    _11680 = clamp(lamps.rect.data[i].w, 0.0199999995529651641845703125, _11738);
                                                                                                                }
                                                                                                                else
                                                                                                                {
                                                                                                                    float _11861 = _11738 * _11738;
                                                                                                                    _11681 = _11704;
                                                                                                                    _11679 = clamp(dot(normal, _11707), 0.0, 1.0) / (isnan(_11861) ? _11694 : (isnan(_11694) ? _11861 : max(_11694, _11861)));
                                                                                                                    _11680 = _11738;
                                                                                                                }
                                                                                                                float _11780 = dot(_11681, _11681);
                                                                                                                float _11781 = isnan(9.9999999747524270787835121154785e-07) ? _11780 : (isnan(_11780) ? 9.9999999747524270787835121154785e-07 : max(_11780, 9.9999999747524270787835121154785e-07));
                                                                                                                vec3 _11784 = _11681 * inversesqrt(_11781);
                                                                                                                if (_11679 <= 0.0)
                                                                                                                {
                                                                                                                    _11682 = dot(normal, _11784) <= 0.0;
                                                                                                                }
                                                                                                                else
                                                                                                                {
                                                                                                                    _11682 = false;
                                                                                                                }
                                                                                                                if (_11682)
                                                                                                                {
                                                                                                                    _11677 = vec3(0.0);
                                                                                                                }
                                                                                                                else
                                                                                                                {
                                                                                                                    float _11800 = (isnan(0.0199999995529651641845703125) ? roughness : (isnan(roughness) ? 0.0199999995529651641845703125 : max(roughness, 0.0199999995529651641845703125))) * (isnan(0.0199999995529651641845703125) ? roughness : (isnan(roughness) ? 0.0199999995529651641845703125 : max(roughness, 0.0199999995529651641845703125)));
                                                                                                                    float _11806 = clamp(_11800 + (_11680 / (2.0 * sqrt(_11781))), 0.0, 1.0);
                                                                                                                    float _11810 = sqrt(_11806);
                                                                                                                    vec3 _11971 = mix(vec3(0.07999999821186065673828125 * specularLevel), albedo, vec3(metallic));
                                                                                                                    float _11972 = isnan(0.0199999995529651641845703125) ? _11810 : (isnan(_11810) ? 0.0199999995529651641845703125 : max(_11810, 0.0199999995529651641845703125));
                                                                                                                    float _11973 = _11972 * _11972;
                                                                                                                    float _11974 = _11973 * _11973;
                                                                                                                    vec3 _11975 = _2901 + _11784;
                                                                                                                    float _11976 = dot(_11975, _11975);
                                                                                                                    vec3 _11979 = _11975 * inversesqrt(isnan(9.9999999392252902907785028219223e-09) ? _11976 : (isnan(_11976) ? 9.9999999392252902907785028219223e-09 : max(_11976, 9.9999999392252902907785028219223e-09)));
                                                                                                                    float _11981 = clamp(dot(normal, _11979), 0.0, 1.0);
                                                                                                                    float _11985 = clamp(dot(normal, _11784), 0.0, 1.0);
                                                                                                                    float _11989 = clamp(abs(dot(normal, _2901)) + 9.9999997473787516355514526367188e-06, 0.0, 1.0);
                                                                                                                    float _11993 = ((_11981 * _11981) * (_11974 - 1.0)) + 1.0;
                                                                                                                    float _12000 = mix((2.0 * _11985) * _11989, _11985 + _11989, _11973);
                                                                                                                    float _11816 = _11680 * _11680;
                                                                                                                    _11677 = ((lamps.colourIntensity.data[i].xyz * lamps.colourIntensity.data[i].w) * _11678) * (((albedo * (1.0 - metallic)) * _11679) + ((((((_11971 + ((vec3(clamp(50.0 * _11971.y, 0.0, 1.0)) - _11971) * pow(1.0 - clamp(dot(_2901, _11979), 0.0, 1.0), 5.0))) * ((_11974 / ((3.1415927410125732421875 * _11993) * _11993)) * (0.5 / (isnan(9.9999999747524270787835121154785e-07) ? _12000 : (isnan(_12000) ? 9.9999999747524270787835121154785e-07 : max(_12000, 9.9999999747524270787835121154785e-07)))))) * _11985) * ((_11800 / _11806) * (_11800 / _11806))) * (1.0 / (isnan(_11816) ? _11781 : (isnan(_11781) ? _11816 : max(_11781, _11816))))) * 3.1415927410125732421875));
                                                                                                                }
                                                                                                            }
                                                                                                        }
                                                                                                    }
                                                                                                    vec3 lampTerm = _11677 * lampOcclusion;
                                                                                                    if (!(all(lessThanEqual(lampTerm, vec3(0.0)))))
                                                                                                    {
                                                                                                        sunLight += lampTerm;
                                                                                                        lampLight += lampTerm;
                                                                                                    }
                                                                                                }
                                                                                            }
                                                                                            if (_283_ladder_break)
                                                                                            {
                                                                                                break;
                                                                                            }
                                                                                            i++;
                                                                                            continue;
                                                                                        }
                                                                                        if (debugView == 14)
                                                                                        {
                                                                                            entryPointParam_fragmentMain = vec4(lampLight, 1.0);
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            vec3 flashLight;
                                                                                            if (any(greaterThan(_8681, vec3(0.0))))
                                                                                            {
                                                                                                vec3 _12023 = mix(vec3(0.07999999821186065673828125 * specularLevel), albedo, vec3(metallic));
                                                                                                float _12024 = isnan(0.0199999995529651641845703125) ? roughness : (isnan(roughness) ? 0.0199999995529651641845703125 : max(roughness, 0.0199999995529651641845703125));
                                                                                                float _12025 = _12024 * _12024;
                                                                                                float _12026 = _12025 * _12025;
                                                                                                vec3 _12027 = _2901 + flashDir;
                                                                                                float _12028 = dot(_12027, _12027);
                                                                                                vec3 _12031 = _12027 * inversesqrt(isnan(9.9999999392252902907785028219223e-09) ? _12028 : (isnan(_12028) ? 9.9999999392252902907785028219223e-09 : max(_12028, 9.9999999392252902907785028219223e-09)));
                                                                                                float _12033 = clamp(dot(normal, _12031), 0.0, 1.0);
                                                                                                float _12037 = clamp(dot(normal, flashDir), 0.0, 1.0);
                                                                                                float _12041 = clamp(abs(dot(normal, _2901)) + 9.9999997473787516355514526367188e-06, 0.0, 1.0);
                                                                                                float _12045 = ((_12033 * _12033) * (_12026 - 1.0)) + 1.0;
                                                                                                float _12052 = mix((2.0 * _12037) * _12041, _12037 + _12041, _12025);
                                                                                                vec3 flashLight_1 = ((((albedo * (1.0 - metallic)) * (_12037 * 0.3183098733425140380859375)) + (((_12023 + ((vec3(clamp(50.0 * _12023.y, 0.0, 1.0)) - _12023) * pow(1.0 - clamp(dot(_2901, _12031), 0.0, 1.0), 5.0))) * ((_12026 / ((3.1415927410125732421875 * _12045) * _12045)) * (0.5 / (isnan(9.9999999747524270787835121154785e-07) ? _12052 : (isnan(_12052) ? 9.9999999747524270787835121154785e-07 : max(_12052, 9.9999999747524270787835121154785e-07)))))) * _12037)) * _8681) * 3.1415927410125732421875;
                                                                                                flashLight = flashLight_1;
                                                                                                sunLight += flashLight_1;
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                flashLight = vec3(0.0);
                                                                                            }
                                                                                            if (debugView == 27)
                                                                                            {
                                                                                                entryPointParam_fragmentMain = vec4(flashLight, 1.0);
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                vec3 diffuseColour = albedo - (albedo * metallic);
                                                                                                bool gathered = gi.giParams.x > 0.0;
                                                                                                bool _4722 = !gathered;
                                                                                                if (_4722)
                                                                                                {
                                                                                                    _152 = true;
                                                                                                }
                                                                                                else
                                                                                                {
                                                                                                    _152 = debugView == 9;
                                                                                                }
                                                                                                if (_152)
                                                                                                {
                                                                                                    _152 = gi.probeOrigin.w > 0.5;
                                                                                                }
                                                                                                else
                                                                                                {
                                                                                                    _152 = false;
                                                                                                }
                                                                                                vec3 indirect;
                                                                                                if (_152)
                                                                                                {
                                                                                                    vec3 worldPos = (vec4(_8679, 1.0) * spvWorkaroundRowMajor(gi.viewToWorld)).xyz + gi.camera.xyz;
                                                                                                    vec3 grid = ((worldPos + (normal * gi.probeMisc.x)) - gi.probeOrigin.xyz) / vec3(gi.probeInvCount.w);
                                                                                                    vec3 uvw = (grid + vec3(0.5)) * gi.probeInvCount.xyz;
                                                                                                    if (all(greaterThanEqual(uvw, vec3(0.0))))
                                                                                                    {
                                                                                                        _152 = all(lessThanEqual(uvw, vec3(1.0)));
                                                                                                    }
                                                                                                    else
                                                                                                    {
                                                                                                        _152 = false;
                                                                                                    }
                                                                                                    if (_152)
                                                                                                    {
                                                                                                        vec4 sh = vec4(1.0, normal);
                                                                                                        float _4790 = dot(textureLod(_13324, uvw, 0.0), sh);
                                                                                                        float _4797 = dot(textureLod(_13326, uvw, 0.0), sh);
                                                                                                        float _4804 = dot(textureLod(_13328, uvw, 0.0), sh);
                                                                                                        vec3 probeLight = vec3(isnan(0.0) ? _4790 : (isnan(_4790) ? 0.0 : max(_4790, 0.0)), isnan(0.0) ? _4797 : (isnan(_4797) ? 0.0 : max(_4797, 0.0)), isnan(0.0) ? _4804 : (isnan(_4804) ? 0.0 : max(_4804, 0.0)));
                                                                                                        if (debugView == 9)
                                                                                                        {
                                                                                                            entryPointParam_fragmentMain = vec4(probeLight * gi.probeSky.xyz, 1.0);
                                                                                                        }
                                                                                                        else
                                                                                                        {
                                                                                                            vec4 _sampled_3 = textureLod(_13330, uvw, 0.0);
                                                                                                            float _4823 = _sampled_3.x;
                                                                                                            float _4825 = _sampled_3.y - (_4823 * _4823);
                                                                                                            float _4826 = isnan(9.9999997473787516355514526367188e-05) ? _4825 : (isnan(_4825) ? 9.9999997473787516355514526367188e-05 : max(_4825, 9.9999997473787516355514526367188e-05));
                                                                                                            float _4835 = length(worldPos - (gi.probeOrigin.xyz + (round(grid) * gi.probeInvCount.w)));
                                                                                                            if (_4835 > _4823)
                                                                                                            {
                                                                                                                float difference = _4835 - _4823;
                                                                                                                float trust_1 = _4826 / (_4826 + (difference * difference));
                                                                                                                trust = (trust_1 * trust_1) * trust_1;
                                                                                                            }
                                                                                                            else
                                                                                                            {
                                                                                                                trust = 1.0;
                                                                                                            }
                                                                                                            indirect = mix(light.ambient.xyz, probeLight * gi.probeSky.xyz, vec3(trust * gi.probeMisc.y));
                                                                                                            if (debugView == 9)
                                                                                                            {
                                                                                                                entryPointParam_fragmentMain = vec4(0.0, 0.0, 0.0, 1.0);
                                                                                                            }
                                                                                                            else
                                                                                                            {
                                                                                                                if (gathered)
                                                                                                                {
                                                                                                                    indirect = textureLod(_13306, input_uv, 0.0).xyz * gi.giParams.x;
                                                                                                                }
                                                                                                                float ambientVisibility = _5342.w;
                                                                                                                if (gi.giParams.z > 0.5)
                                                                                                                {
                                                                                                                    trust = ambientVisibility * textureLod(_13304, input_uv, 0.0).x;
                                                                                                                }
                                                                                                                else
                                                                                                                {
                                                                                                                    trust = ambientVisibility;
                                                                                                                }
                                                                                                                vec3 indirect_1;
                                                                                                                if (trust < 1.0)
                                                                                                                {
                                                                                                                    vec3 _12077 = vec3(trust);
                                                                                                                    vec3 _12082 = ((((((albedo * 2.040400028228759765625) - vec3(0.3323999941349029541015625)) * trust) + (vec3(0.6417000293731689453125) - (albedo * 4.79510021209716796875))) * trust) + ((albedo * 2.755199909210205078125) + vec3(0.69029998779296875))) * trust;
                                                                                                                    bvec3 _13800 = isnan(_12077);
                                                                                                                    bvec3 _13801 = isnan(_12082);
                                                                                                                    vec3 _13802 = max(_12077, _12082);
                                                                                                                    vec3 _13803 = vec3(_13800.x ? _12082.x : _13802.x, _13800.y ? _12082.y : _13802.y, _13800.z ? _12082.z : _13802.z);
                                                                                                                    vec3 _12083 = vec3(_13801.x ? _12077.x : _13803.x, _13801.y ? _12077.y : _13803.y, _13801.z ? _12077.z : _13803.z);
                                                                                                                    if (gi.probeOrigin.w > 0.5)
                                                                                                                    {
                                                                                                                        _152 = _4722;
                                                                                                                    }
                                                                                                                    else
                                                                                                                    {
                                                                                                                        _152 = false;
                                                                                                                    }
                                                                                                                    if (_152)
                                                                                                                    {
                                                                                                                        lampLight = mix(vec3(1.0), _12083, vec3(0.5));
                                                                                                                    }
                                                                                                                    else
                                                                                                                    {
                                                                                                                        lampLight = _12083;
                                                                                                                    }
                                                                                                                    indirect_1 = indirect * lampLight;
                                                                                                                }
                                                                                                                else
                                                                                                                {
                                                                                                                    indirect_1 = indirect;
                                                                                                                }
                                                                                                                float _4961 = clamp(dot(normal, _2901), 9.9999997473787516355514526367188e-05, 1.0);
                                                                                                                vec3 _4967 = mix(vec3(0.07999999821186065673828125 * specularLevel), albedo, vec3(metallic));
                                                                                                                float _12086 = 1.0 - roughness;
                                                                                                                float _12087 = _12086 * _12086;
                                                                                                                float _12089 = exp2((-9.27999973297119140625) * _4961);
                                                                                                                float _12097 = 1.03999996185302734375 * ((((isnan(_12089) ? _12087 : (isnan(_12087) ? _12089 : min(_12087, _12089))) * _12086) + 0.0425000004470348358154296875) - (0.0274999998509883880615234375 * roughness));
                                                                                                                vec2 _12102 = vec2((1.03999996185302734375 - (0.572000026702880859375 * roughness)) - _12097, ((0.02199999988079071044921875 * roughness) - 0.039999999105930328369140625) + _12097);
                                                                                                                vec3 ambientSpecular_1 = ((indirect * 0.3183098733425140380859375) * ((_4967 * _12102.x) + vec3(clamp(50.0 * _4967.y, 0.0, 1.0) * _12102.y))) * clamp((pow(_4961 + trust, roughness * roughness) - 1.0) + trust, 0.0, 1.0);
                                                                                                                vec3 ambientSpecular;
                                                                                                                if (gi.shelterMap2.z > 0.0)
                                                                                                                {
                                                                                                                    float _5037 = gi.shelterMap2.z * 0.25;
                                                                                                                    ambientSpecular = ambientSpecular_1 * (1.0 - clamp((gi.shelterMap2.z - roughness) / (isnan(0.001000000047497451305389404296875) ? _5037 : (isnan(_5037) ? 0.001000000047497451305389404296875 : max(_5037, 0.001000000047497451305389404296875))), 0.0, 1.0));
                                                                                                                }
                                                                                                                else
                                                                                                                {
                                                                                                                    ambientSpecular = ambientSpecular_1;
                                                                                                                }
                                                                                                                if (gathered)
                                                                                                                {
                                                                                                                    vec3 _12115 = exp(vec3(-0.01024200022220611572265625, -0.01799800060689449310302734375, -0.03754000365734100341796875) * (_4018 * 0.001000000047497451305389404296875));
                                                                                                                    float _12116 = dot(_2074, worldRayToPixel);
                                                                                                                    float _12143 = 1.6400001049041748046875 + (_12116 * (-1.60000002384185791015625));
                                                                                                                    vec3 _12131 = (((((diffuseColour * 0.3183098733425140380859375) * indirect_1) + ambientSpecular) + sunLight) * _12115) + ((((vec3(0.00580199994146823883056640625, 0.0135580003261566162109375, 0.033100001513957977294921875) * (0.0596831031143665313720703125 * (1.0 + (_12116 * _12116)))) + vec3(0.0039960001595318317413330078125 * (0.359999954700469970703125 / ((12.56637096405029296875 * _12143) * sqrt(isnan(9.9999999392252902907785028219223e-09) ? _12143 : (isnan(_12143) ? 9.9999999392252902907785028219223e-09 : max(_12143, 9.9999999392252902907785028219223e-09))))))) * sunIlluminance) * ((vec3(1.0) - _12115) * vec3(97.637176513671875, 55.561725616455078125, 26.6382503509521484375)));
                                                                                                                    vec3 _12151;
                                                                                                                    {
                                                                                                                        if (gi.fog.z <= 0.0)
                                                                                                                        {
                                                                                                                            _12151 = _12131;
                                                                                                                        }
                                                                                                                        else
                                                                                                                        {
                                                                                                                            float _12166 = (_4018 * gi.fog.x) + gi.fog.y;
                                                                                                                            vec4 _12181 = textureLod(_13292, vec3(input_uv, clamp(((log2(isnan(9.9999999747524270787835121154785e-07) ? _12166 : (isnan(_12166) ? 9.9999999747524270787835121154785e-07 : max(_12166, 9.9999999747524270787835121154785e-07))) * gi.fog.z) - 1.0) * gi.fog.w, 0.0, 1.0)), 0.0);
                                                                                                                            _12151 = (_12131 * _12181.w) + _12181.xyz;
                                                                                                                        }
                                                                                                                    }
                                                                                                                    entryPointParam_fragmentMain = vec4(_12151, 1.0);
                                                                                                                }
                                                                                                                else
                                                                                                                {
                                                                                                                    vec4 _12191 = vec4(normal, 1.0);
                                                                                                                    vec4 _12207 = _12191.xyzz * _12191.yzzx;
                                                                                                                    vec3 _12232 = (vec3(dot(texelFetch(_13333, ivec2(0), 0), _12191), dot(texelFetch(_13333, ivec2(1, 0), 0), _12191), dot(texelFetch(_13333, ivec2(2, 0), 0), _12191)) + vec3(dot(texelFetch(_13333, ivec2(3, 0), 0), _12207), dot(texelFetch(_13333, ivec2(4, 0), 0), _12207), dot(texelFetch(_13333, ivec2(5, 0), 0), _12207))) + (texelFetch(_13333, ivec2(6, 0), 0).xyz * ((normal.x * normal.x) - (normal.y * normal.y)));
                                                                                                                    bvec3 _13825 = isnan(vec3(0.0));
                                                                                                                    bvec3 _13826 = isnan(_12232);
                                                                                                                    vec3 _13827 = max(vec3(0.0), _12232);
                                                                                                                    vec3 _13828 = vec3(_13825.x ? _12232.x : _13827.x, _13825.y ? _12232.y : _13827.y, _13825.z ? _12232.z : _13827.z);
                                                                                                                    vec3 _12239 = exp(vec3(-0.01024200022220611572265625, -0.01799800060689449310302734375, -0.03754000365734100341796875) * (_4018 * 0.001000000047497451305389404296875));
                                                                                                                    float _12240 = dot(_2074, worldRayToPixel);
                                                                                                                    float _12267 = 1.6400001049041748046875 + (_12240 * (-1.60000002384185791015625));
                                                                                                                    vec3 _12255 = ((((((albedo * indirect_1) * light.sunColourScale.w) + (vec3(_13826.x ? vec3(0.0).x : _13828.x, _13826.y ? vec3(0.0).y : _13828.y, _13826.z ? vec3(0.0).z : _13828.z) * diffuseColour)) + ambientSpecular) + sunLight) * _12239) + ((((vec3(0.00580199994146823883056640625, 0.0135580003261566162109375, 0.033100001513957977294921875) * (0.0596831031143665313720703125 * (1.0 + (_12240 * _12240)))) + vec3(0.0039960001595318317413330078125 * (0.359999954700469970703125 / ((12.56637096405029296875 * _12267) * sqrt(isnan(9.9999999392252902907785028219223e-09) ? _12267 : (isnan(_12267) ? 9.9999999392252902907785028219223e-09 : max(_12267, 9.9999999392252902907785028219223e-09))))))) * sunIlluminance) * ((vec3(1.0) - _12239) * vec3(97.637176513671875, 55.561725616455078125, 26.6382503509521484375)));
                                                                                                                    vec3 _12275;
                                                                                                                    {
                                                                                                                        if (gi.fog.z <= 0.0)
                                                                                                                        {
                                                                                                                            _12275 = _12255;
                                                                                                                        }
                                                                                                                        else
                                                                                                                        {
                                                                                                                            float _12290 = (_4018 * gi.fog.x) + gi.fog.y;
                                                                                                                            vec4 _12305 = textureLod(_13292, vec3(input_uv, clamp(((log2(isnan(9.9999999747524270787835121154785e-07) ? _12290 : (isnan(_12290) ? 9.9999999747524270787835121154785e-07 : max(_12290, 9.9999999747524270787835121154785e-07))) * gi.fog.z) - 1.0) * gi.fog.w, 0.0, 1.0)), 0.0);
                                                                                                                            _12275 = (_12255 * _12305.w) + _12305.xyz;
                                                                                                                        }
                                                                                                                    }
                                                                                                                    entryPointParam_fragmentMain = vec4(_12275, 1.0);
                                                                                                                }
                                                                                                            }
                                                                                                        }
                                                                                                    }
                                                                                                    else
                                                                                                    {
                                                                                                        indirect = light.ambient.xyz;
                                                                                                        if (debugView == 9)
                                                                                                        {
                                                                                                            entryPointParam_fragmentMain = vec4(0.0, 0.0, 0.0, 1.0);
                                                                                                        }
                                                                                                        else
                                                                                                        {
                                                                                                            if (gathered)
                                                                                                            {
                                                                                                                indirect = textureLod(_13306, input_uv, 0.0).xyz * gi.giParams.x;
                                                                                                            }
                                                                                                            float ambientVisibility = _5342.w;
                                                                                                            if (gi.giParams.z > 0.5)
                                                                                                            {
                                                                                                                trust = ambientVisibility * textureLod(_13304, input_uv, 0.0).x;
                                                                                                            }
                                                                                                            else
                                                                                                            {
                                                                                                                trust = ambientVisibility;
                                                                                                            }
                                                                                                            vec3 indirect_1;
                                                                                                            if (trust < 1.0)
                                                                                                            {
                                                                                                                vec3 _12077 = vec3(trust);
                                                                                                                vec3 _12082 = ((((((albedo * 2.040400028228759765625) - vec3(0.3323999941349029541015625)) * trust) + (vec3(0.6417000293731689453125) - (albedo * 4.79510021209716796875))) * trust) + ((albedo * 2.755199909210205078125) + vec3(0.69029998779296875))) * trust;
                                                                                                                bvec3 _13800 = isnan(_12077);
                                                                                                                bvec3 _13801 = isnan(_12082);
                                                                                                                vec3 _13802 = max(_12077, _12082);
                                                                                                                vec3 _13803 = vec3(_13800.x ? _12082.x : _13802.x, _13800.y ? _12082.y : _13802.y, _13800.z ? _12082.z : _13802.z);
                                                                                                                vec3 _12083 = vec3(_13801.x ? _12077.x : _13803.x, _13801.y ? _12077.y : _13803.y, _13801.z ? _12077.z : _13803.z);
                                                                                                                if (gi.probeOrigin.w > 0.5)
                                                                                                                {
                                                                                                                    _152 = _4722;
                                                                                                                }
                                                                                                                else
                                                                                                                {
                                                                                                                    _152 = false;
                                                                                                                }
                                                                                                                if (_152)
                                                                                                                {
                                                                                                                    lampLight = mix(vec3(1.0), _12083, vec3(0.5));
                                                                                                                }
                                                                                                                else
                                                                                                                {
                                                                                                                    lampLight = _12083;
                                                                                                                }
                                                                                                                indirect_1 = indirect * lampLight;
                                                                                                            }
                                                                                                            else
                                                                                                            {
                                                                                                                indirect_1 = indirect;
                                                                                                            }
                                                                                                            float _4961 = clamp(dot(normal, _2901), 9.9999997473787516355514526367188e-05, 1.0);
                                                                                                            vec3 _4967 = mix(vec3(0.07999999821186065673828125 * specularLevel), albedo, vec3(metallic));
                                                                                                            float _12086 = 1.0 - roughness;
                                                                                                            float _12087 = _12086 * _12086;
                                                                                                            float _12089 = exp2((-9.27999973297119140625) * _4961);
                                                                                                            float _12097 = 1.03999996185302734375 * ((((isnan(_12089) ? _12087 : (isnan(_12087) ? _12089 : min(_12087, _12089))) * _12086) + 0.0425000004470348358154296875) - (0.0274999998509883880615234375 * roughness));
                                                                                                            vec2 _12102 = vec2((1.03999996185302734375 - (0.572000026702880859375 * roughness)) - _12097, ((0.02199999988079071044921875 * roughness) - 0.039999999105930328369140625) + _12097);
                                                                                                            vec3 ambientSpecular_1 = ((indirect * 0.3183098733425140380859375) * ((_4967 * _12102.x) + vec3(clamp(50.0 * _4967.y, 0.0, 1.0) * _12102.y))) * clamp((pow(_4961 + trust, roughness * roughness) - 1.0) + trust, 0.0, 1.0);
                                                                                                            vec3 ambientSpecular;
                                                                                                            if (gi.shelterMap2.z > 0.0)
                                                                                                            {
                                                                                                                float _5037 = gi.shelterMap2.z * 0.25;
                                                                                                                ambientSpecular = ambientSpecular_1 * (1.0 - clamp((gi.shelterMap2.z - roughness) / (isnan(0.001000000047497451305389404296875) ? _5037 : (isnan(_5037) ? 0.001000000047497451305389404296875 : max(_5037, 0.001000000047497451305389404296875))), 0.0, 1.0));
                                                                                                            }
                                                                                                            else
                                                                                                            {
                                                                                                                ambientSpecular = ambientSpecular_1;
                                                                                                            }
                                                                                                            if (gathered)
                                                                                                            {
                                                                                                                vec3 _12115 = exp(vec3(-0.01024200022220611572265625, -0.01799800060689449310302734375, -0.03754000365734100341796875) * (_4018 * 0.001000000047497451305389404296875));
                                                                                                                float _12116 = dot(_2074, worldRayToPixel);
                                                                                                                float _12143 = 1.6400001049041748046875 + (_12116 * (-1.60000002384185791015625));
                                                                                                                vec3 _12131 = (((((diffuseColour * 0.3183098733425140380859375) * indirect_1) + ambientSpecular) + sunLight) * _12115) + ((((vec3(0.00580199994146823883056640625, 0.0135580003261566162109375, 0.033100001513957977294921875) * (0.0596831031143665313720703125 * (1.0 + (_12116 * _12116)))) + vec3(0.0039960001595318317413330078125 * (0.359999954700469970703125 / ((12.56637096405029296875 * _12143) * sqrt(isnan(9.9999999392252902907785028219223e-09) ? _12143 : (isnan(_12143) ? 9.9999999392252902907785028219223e-09 : max(_12143, 9.9999999392252902907785028219223e-09))))))) * sunIlluminance) * ((vec3(1.0) - _12115) * vec3(97.637176513671875, 55.561725616455078125, 26.6382503509521484375)));
                                                                                                                vec3 _12151;
                                                                                                                {
                                                                                                                    if (gi.fog.z <= 0.0)
                                                                                                                    {
                                                                                                                        _12151 = _12131;
                                                                                                                    }
                                                                                                                    else
                                                                                                                    {
                                                                                                                        float _12166 = (_4018 * gi.fog.x) + gi.fog.y;
                                                                                                                        vec4 _12181 = textureLod(_13292, vec3(input_uv, clamp(((log2(isnan(9.9999999747524270787835121154785e-07) ? _12166 : (isnan(_12166) ? 9.9999999747524270787835121154785e-07 : max(_12166, 9.9999999747524270787835121154785e-07))) * gi.fog.z) - 1.0) * gi.fog.w, 0.0, 1.0)), 0.0);
                                                                                                                        _12151 = (_12131 * _12181.w) + _12181.xyz;
                                                                                                                    }
                                                                                                                }
                                                                                                                entryPointParam_fragmentMain = vec4(_12151, 1.0);
                                                                                                            }
                                                                                                            else
                                                                                                            {
                                                                                                                vec4 _12191 = vec4(normal, 1.0);
                                                                                                                vec4 _12207 = _12191.xyzz * _12191.yzzx;
                                                                                                                vec3 _12232 = (vec3(dot(texelFetch(_13333, ivec2(0), 0), _12191), dot(texelFetch(_13333, ivec2(1, 0), 0), _12191), dot(texelFetch(_13333, ivec2(2, 0), 0), _12191)) + vec3(dot(texelFetch(_13333, ivec2(3, 0), 0), _12207), dot(texelFetch(_13333, ivec2(4, 0), 0), _12207), dot(texelFetch(_13333, ivec2(5, 0), 0), _12207))) + (texelFetch(_13333, ivec2(6, 0), 0).xyz * ((normal.x * normal.x) - (normal.y * normal.y)));
                                                                                                                bvec3 _13825 = isnan(vec3(0.0));
                                                                                                                bvec3 _13826 = isnan(_12232);
                                                                                                                vec3 _13827 = max(vec3(0.0), _12232);
                                                                                                                vec3 _13828 = vec3(_13825.x ? _12232.x : _13827.x, _13825.y ? _12232.y : _13827.y, _13825.z ? _12232.z : _13827.z);
                                                                                                                vec3 _12239 = exp(vec3(-0.01024200022220611572265625, -0.01799800060689449310302734375, -0.03754000365734100341796875) * (_4018 * 0.001000000047497451305389404296875));
                                                                                                                float _12240 = dot(_2074, worldRayToPixel);
                                                                                                                float _12267 = 1.6400001049041748046875 + (_12240 * (-1.60000002384185791015625));
                                                                                                                vec3 _12255 = ((((((albedo * indirect_1) * light.sunColourScale.w) + (vec3(_13826.x ? vec3(0.0).x : _13828.x, _13826.y ? vec3(0.0).y : _13828.y, _13826.z ? vec3(0.0).z : _13828.z) * diffuseColour)) + ambientSpecular) + sunLight) * _12239) + ((((vec3(0.00580199994146823883056640625, 0.0135580003261566162109375, 0.033100001513957977294921875) * (0.0596831031143665313720703125 * (1.0 + (_12240 * _12240)))) + vec3(0.0039960001595318317413330078125 * (0.359999954700469970703125 / ((12.56637096405029296875 * _12267) * sqrt(isnan(9.9999999392252902907785028219223e-09) ? _12267 : (isnan(_12267) ? 9.9999999392252902907785028219223e-09 : max(_12267, 9.9999999392252902907785028219223e-09))))))) * sunIlluminance) * ((vec3(1.0) - _12239) * vec3(97.637176513671875, 55.561725616455078125, 26.6382503509521484375)));
                                                                                                                vec3 _12275;
                                                                                                                {
                                                                                                                    if (gi.fog.z <= 0.0)
                                                                                                                    {
                                                                                                                        _12275 = _12255;
                                                                                                                    }
                                                                                                                    else
                                                                                                                    {
                                                                                                                        float _12290 = (_4018 * gi.fog.x) + gi.fog.y;
                                                                                                                        vec4 _12305 = textureLod(_13292, vec3(input_uv, clamp(((log2(isnan(9.9999999747524270787835121154785e-07) ? _12290 : (isnan(_12290) ? 9.9999999747524270787835121154785e-07 : max(_12290, 9.9999999747524270787835121154785e-07))) * gi.fog.z) - 1.0) * gi.fog.w, 0.0, 1.0)), 0.0);
                                                                                                                        _12275 = (_12255 * _12305.w) + _12305.xyz;
                                                                                                                    }
                                                                                                                }
                                                                                                                entryPointParam_fragmentMain = vec4(_12275, 1.0);
                                                                                                            }
                                                                                                        }
                                                                                                    }
                                                                                                }
                                                                                                else
                                                                                                {
                                                                                                    indirect = light.ambient.xyz;
                                                                                                    if (debugView == 9)
                                                                                                    {
                                                                                                        entryPointParam_fragmentMain = vec4(0.0, 0.0, 0.0, 1.0);
                                                                                                    }
                                                                                                    else
                                                                                                    {
                                                                                                        if (gathered)
                                                                                                        {
                                                                                                            indirect = textureLod(_13306, input_uv, 0.0).xyz * gi.giParams.x;
                                                                                                        }
                                                                                                        float ambientVisibility = _5342.w;
                                                                                                        if (gi.giParams.z > 0.5)
                                                                                                        {
                                                                                                            trust = ambientVisibility * textureLod(_13304, input_uv, 0.0).x;
                                                                                                        }
                                                                                                        else
                                                                                                        {
                                                                                                            trust = ambientVisibility;
                                                                                                        }
                                                                                                        vec3 indirect_1;
                                                                                                        if (trust < 1.0)
                                                                                                        {
                                                                                                            vec3 _12077 = vec3(trust);
                                                                                                            vec3 _12082 = ((((((albedo * 2.040400028228759765625) - vec3(0.3323999941349029541015625)) * trust) + (vec3(0.6417000293731689453125) - (albedo * 4.79510021209716796875))) * trust) + ((albedo * 2.755199909210205078125) + vec3(0.69029998779296875))) * trust;
                                                                                                            bvec3 _13800 = isnan(_12077);
                                                                                                            bvec3 _13801 = isnan(_12082);
                                                                                                            vec3 _13802 = max(_12077, _12082);
                                                                                                            vec3 _13803 = vec3(_13800.x ? _12082.x : _13802.x, _13800.y ? _12082.y : _13802.y, _13800.z ? _12082.z : _13802.z);
                                                                                                            vec3 _12083 = vec3(_13801.x ? _12077.x : _13803.x, _13801.y ? _12077.y : _13803.y, _13801.z ? _12077.z : _13803.z);
                                                                                                            if (gi.probeOrigin.w > 0.5)
                                                                                                            {
                                                                                                                _152 = _4722;
                                                                                                            }
                                                                                                            else
                                                                                                            {
                                                                                                                _152 = false;
                                                                                                            }
                                                                                                            if (_152)
                                                                                                            {
                                                                                                                lampLight = mix(vec3(1.0), _12083, vec3(0.5));
                                                                                                            }
                                                                                                            else
                                                                                                            {
                                                                                                                lampLight = _12083;
                                                                                                            }
                                                                                                            indirect_1 = indirect * lampLight;
                                                                                                        }
                                                                                                        else
                                                                                                        {
                                                                                                            indirect_1 = indirect;
                                                                                                        }
                                                                                                        float _4961 = clamp(dot(normal, _2901), 9.9999997473787516355514526367188e-05, 1.0);
                                                                                                        vec3 _4967 = mix(vec3(0.07999999821186065673828125 * specularLevel), albedo, vec3(metallic));
                                                                                                        float _12086 = 1.0 - roughness;
                                                                                                        float _12087 = _12086 * _12086;
                                                                                                        float _12089 = exp2((-9.27999973297119140625) * _4961);
                                                                                                        float _12097 = 1.03999996185302734375 * ((((isnan(_12089) ? _12087 : (isnan(_12087) ? _12089 : min(_12087, _12089))) * _12086) + 0.0425000004470348358154296875) - (0.0274999998509883880615234375 * roughness));
                                                                                                        vec2 _12102 = vec2((1.03999996185302734375 - (0.572000026702880859375 * roughness)) - _12097, ((0.02199999988079071044921875 * roughness) - 0.039999999105930328369140625) + _12097);
                                                                                                        vec3 ambientSpecular_1 = ((indirect * 0.3183098733425140380859375) * ((_4967 * _12102.x) + vec3(clamp(50.0 * _4967.y, 0.0, 1.0) * _12102.y))) * clamp((pow(_4961 + trust, roughness * roughness) - 1.0) + trust, 0.0, 1.0);
                                                                                                        vec3 ambientSpecular;
                                                                                                        if (gi.shelterMap2.z > 0.0)
                                                                                                        {
                                                                                                            float _5037 = gi.shelterMap2.z * 0.25;
                                                                                                            ambientSpecular = ambientSpecular_1 * (1.0 - clamp((gi.shelterMap2.z - roughness) / (isnan(0.001000000047497451305389404296875) ? _5037 : (isnan(_5037) ? 0.001000000047497451305389404296875 : max(_5037, 0.001000000047497451305389404296875))), 0.0, 1.0));
                                                                                                        }
                                                                                                        else
                                                                                                        {
                                                                                                            ambientSpecular = ambientSpecular_1;
                                                                                                        }
                                                                                                        if (gathered)
                                                                                                        {
                                                                                                            vec3 _12115 = exp(vec3(-0.01024200022220611572265625, -0.01799800060689449310302734375, -0.03754000365734100341796875) * (_4018 * 0.001000000047497451305389404296875));
                                                                                                            float _12116 = dot(_2074, worldRayToPixel);
                                                                                                            float _12143 = 1.6400001049041748046875 + (_12116 * (-1.60000002384185791015625));
                                                                                                            vec3 _12131 = (((((diffuseColour * 0.3183098733425140380859375) * indirect_1) + ambientSpecular) + sunLight) * _12115) + ((((vec3(0.00580199994146823883056640625, 0.0135580003261566162109375, 0.033100001513957977294921875) * (0.0596831031143665313720703125 * (1.0 + (_12116 * _12116)))) + vec3(0.0039960001595318317413330078125 * (0.359999954700469970703125 / ((12.56637096405029296875 * _12143) * sqrt(isnan(9.9999999392252902907785028219223e-09) ? _12143 : (isnan(_12143) ? 9.9999999392252902907785028219223e-09 : max(_12143, 9.9999999392252902907785028219223e-09))))))) * sunIlluminance) * ((vec3(1.0) - _12115) * vec3(97.637176513671875, 55.561725616455078125, 26.6382503509521484375)));
                                                                                                            vec3 _12151;
                                                                                                            {
                                                                                                                if (gi.fog.z <= 0.0)
                                                                                                                {
                                                                                                                    _12151 = _12131;
                                                                                                                }
                                                                                                                else
                                                                                                                {
                                                                                                                    float _12166 = (_4018 * gi.fog.x) + gi.fog.y;
                                                                                                                    vec4 _12181 = textureLod(_13292, vec3(input_uv, clamp(((log2(isnan(9.9999999747524270787835121154785e-07) ? _12166 : (isnan(_12166) ? 9.9999999747524270787835121154785e-07 : max(_12166, 9.9999999747524270787835121154785e-07))) * gi.fog.z) - 1.0) * gi.fog.w, 0.0, 1.0)), 0.0);
                                                                                                                    _12151 = (_12131 * _12181.w) + _12181.xyz;
                                                                                                                }
                                                                                                            }
                                                                                                            entryPointParam_fragmentMain = vec4(_12151, 1.0);
                                                                                                        }
                                                                                                        else
                                                                                                        {
                                                                                                            vec4 _12191 = vec4(normal, 1.0);
                                                                                                            vec4 _12207 = _12191.xyzz * _12191.yzzx;
                                                                                                            vec3 _12232 = (vec3(dot(texelFetch(_13333, ivec2(0), 0), _12191), dot(texelFetch(_13333, ivec2(1, 0), 0), _12191), dot(texelFetch(_13333, ivec2(2, 0), 0), _12191)) + vec3(dot(texelFetch(_13333, ivec2(3, 0), 0), _12207), dot(texelFetch(_13333, ivec2(4, 0), 0), _12207), dot(texelFetch(_13333, ivec2(5, 0), 0), _12207))) + (texelFetch(_13333, ivec2(6, 0), 0).xyz * ((normal.x * normal.x) - (normal.y * normal.y)));
                                                                                                            bvec3 _13825 = isnan(vec3(0.0));
                                                                                                            bvec3 _13826 = isnan(_12232);
                                                                                                            vec3 _13827 = max(vec3(0.0), _12232);
                                                                                                            vec3 _13828 = vec3(_13825.x ? _12232.x : _13827.x, _13825.y ? _12232.y : _13827.y, _13825.z ? _12232.z : _13827.z);
                                                                                                            vec3 _12239 = exp(vec3(-0.01024200022220611572265625, -0.01799800060689449310302734375, -0.03754000365734100341796875) * (_4018 * 0.001000000047497451305389404296875));
                                                                                                            float _12240 = dot(_2074, worldRayToPixel);
                                                                                                            float _12267 = 1.6400001049041748046875 + (_12240 * (-1.60000002384185791015625));
                                                                                                            vec3 _12255 = ((((((albedo * indirect_1) * light.sunColourScale.w) + (vec3(_13826.x ? vec3(0.0).x : _13828.x, _13826.y ? vec3(0.0).y : _13828.y, _13826.z ? vec3(0.0).z : _13828.z) * diffuseColour)) + ambientSpecular) + sunLight) * _12239) + ((((vec3(0.00580199994146823883056640625, 0.0135580003261566162109375, 0.033100001513957977294921875) * (0.0596831031143665313720703125 * (1.0 + (_12240 * _12240)))) + vec3(0.0039960001595318317413330078125 * (0.359999954700469970703125 / ((12.56637096405029296875 * _12267) * sqrt(isnan(9.9999999392252902907785028219223e-09) ? _12267 : (isnan(_12267) ? 9.9999999392252902907785028219223e-09 : max(_12267, 9.9999999392252902907785028219223e-09))))))) * sunIlluminance) * ((vec3(1.0) - _12239) * vec3(97.637176513671875, 55.561725616455078125, 26.6382503509521484375)));
                                                                                                            vec3 _12275;
                                                                                                            {
                                                                                                                if (gi.fog.z <= 0.0)
                                                                                                                {
                                                                                                                    _12275 = _12255;
                                                                                                                }
                                                                                                                else
                                                                                                                {
                                                                                                                    float _12290 = (_4018 * gi.fog.x) + gi.fog.y;
                                                                                                                    vec4 _12305 = textureLod(_13292, vec3(input_uv, clamp(((log2(isnan(9.9999999747524270787835121154785e-07) ? _12290 : (isnan(_12290) ? 9.9999999747524270787835121154785e-07 : max(_12290, 9.9999999747524270787835121154785e-07))) * gi.fog.z) - 1.0) * gi.fog.w, 0.0, 1.0)), 0.0);
                                                                                                                    _12275 = (_12255 * _12305.w) + _12305.xyz;
                                                                                                                }
                                                                                                            }
                                                                                                            entryPointParam_fragmentMain = vec4(_12275, 1.0);
                                                                                                        }
                                                                                                    }
                                                                                                }
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

