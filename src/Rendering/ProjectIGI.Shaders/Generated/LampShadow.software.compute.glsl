#version 430
#extension GL_EXT_texture_shadow_lod : enable
#ifdef GL_EXT_texture_shadow_lod
#define spvShadowLod0(s, c) textureLod(s, c, 0.0)
#else
#define spvShadowLod0(s, c) textureGrad(s, c, vec2(0.0), vec2(0.0))
#endif
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

struct _Array_std140_vector_float_4_160
{
    vec4 data[160];
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

struct _Array_std140_vector_float_4_3840
{
    vec4 data[3840];
};

uniform vec2 _1612_comp[12] = vec2[](vec2(-0.3260000050067901611328125, -0.4059999883174896240234375), vec2(-0.839999973773956298828125, -0.07400000095367431640625), vec2(-0.69599997997283935546875, 0.4569999873638153076171875), vec2(-0.20299999415874481201171875, 0.620999991893768310546875), vec2(0.96200001239776611328125, -0.194999992847442626953125), vec2(0.472999989986419677734375, -0.4799999892711639404296875), vec2(0.518999993801116943359375, 0.767000019550323486328125), vec2(0.185000002384185791015625, -0.89300000667572021484375), vec2(0.507000029087066650390625, 0.064000003039836883544921875), vec2(0.89600002765655517578125, 0.412000000476837158203125), vec2(-0.3219999969005584716796875, -0.933000028133392333984375), vec2(-0.791999995708465576171875, -0.597999989986419677734375));

layout(binding = 0, std140) uniform Params_std140
{
    layout(row_major) mat4 viewToWorld;
    vec4 unproject;
    vec4 resolution;
    vec4 cameraFrame;
    vec4 sunLight;
    vec4 lampControl;
    vec4 lampSource;
    _Array_std140_vector_float_4_160 lampPositionRadius;
    _Array_std140_vector_float_4_160 lampColourIntensity;
    _Array_std140_vector_float_4_160 lampDirection;
    _Array_std140_vector_float_4_160 lampRect;
} p;

layout(binding = 1, std140) uniform FieldParams_std140
{
    _Array_std140_vector_float_4_4 origin;
    vec4 range;
    ivec4 levels;
    layout(row_major) _Array_std140_matrix_float_4_4_240 mapMatrix;
    _Array_std140_vector_float_4_120 mapDepth;
    _Array_std140_vector_int_4_40 mapSlot;
} f;

layout(binding = 2, std140) uniform CoarseParams_std140
{
    _Array_std140_vector_float_4_3840 record;
} c;

layout(binding = 0, rgba16f) uniform restrict writeonly image2D uVisibility;
layout(binding = 0) uniform sampler2D _4757;
layout(binding = 1) uniform sampler2D _4759;
layout(binding = 3) uniform sampler2D _4762;
layout(binding = 4) uniform sampler2DArray _4765;
layout(binding = 5) uniform sampler2DArrayShadow _4767;
layout(binding = 6) uniform sampler2DArray _4770;
layout(binding = 2) uniform sampler3D _4772;

mat4 spvWorkaroundRowMajor(mat4 wrap) { return wrap; }

void main()
{
    bool _4518 = false;
    bool _4332 = false;
    bool _4146 = false;
    bool _3835 = false;
    {
        ivec2 _247 = ivec2(gl_GlobalInvocationID.xy);
        bool _66;
        if (_247.x >= int(p.resolution.x))
        {
            _66 = true;
        }
        else
        {
            _66 = _247.y >= int(p.resolution.y);
        }
        if (!(_66))
        {
            int lampCount = int(p.lampControl.x + 0.5);
            if (lampCount <= 0)
            {
                imageStore(uVisibility, ivec2(gl_GlobalInvocationID.xy), vec4(1.0, 0.0, 0.0, 0.0));
            }
            else
            {
                vec2 uv = (vec2(_247) + vec2(0.5)) * p.resolution.zw;
                vec4 _2858 = textureLod(_4757, uv, 0.0);
                float _2859 = _2858.x;
                if (_2859 <= 0.0)
                {
                    imageStore(uVisibility, ivec2(gl_GlobalInvocationID.xy), vec4(1.0, 0.0, 0.0, 0.0));
                }
                else
                {
                    float _2888 = ((2.0 * p.unproject.z) * p.unproject.w) / ((p.unproject.w + p.unproject.z) - ((1.0 - (2.0 * _2859)) * (p.unproject.w - p.unproject.z)));
                    vec2 _2865 = (uv * 2.0) - vec2(1.0);
                    vec3 _2875 = vec3((_2865.x * _2888) / p.unproject.x, ((-_2865.y) * _2888) / p.unproject.y, _2888);
                    vec3 _366 = normalize((textureLod(_4759, uv, 0.0).xyz * 2.0) - vec3(1.0));
                    float _379 = _2875.z;
                    float originLift = 0.07999999821186065673828125 + (0.0005000000237487256526947021484375 * _379);
                    vec3 _385 = ((vec4(_2875, 1.0) * spvWorkaroundRowMajor(p.viewToWorld)).xyz + p.cameraFrame.xyz) + (_366 * originLift);
                    bool rawNoise = p.lampControl.w > 0.5;
                    float frame;
                    if (rawNoise)
                    {
                        frame = 0.0;
                    }
                    else
                    {
                        frame = float(uint(p.cameraFrame.w) % 65536u);
                    }
                    vec3 pixelRandom;
                    if (rawNoise)
                    {
                        uvec3 _2969 = (uvec3(gl_GlobalInvocationID.xy, uint(p.cameraFrame.w) ^ 1435814677u) * uvec3(1664525u)) + uvec3(1013904223u);
                        _2969.x = _2969.x + (_2969.y * _2969.z);
                        _2969.y = _2969.y + (_2969.z * _2969.x);
                        _2969.z = _2969.z + (_2969.x * _2969.y);
                        uvec3 _2996 = _2969 ^ (_2969 >> uvec3(16u));
                        _2996.x = _2996.x + (_2996.y * _2996.z);
                        _2996.y = _2996.y + (_2996.z * _2996.x);
                        _2996.z = _2996.z + (_2996.x * _2996.y);
                        pixelRandom = vec3(_2996 >> uvec3(8u)) * 5.9604644775390625e-08;
                    }
                    else
                    {
                        uvec3 _2904 = (uvec3(gl_GlobalInvocationID.xy, 2654435769u) * uvec3(1664525u)) + uvec3(1013904223u);
                        _2904.x = _2904.x + (_2904.y * _2904.z);
                        _2904.y = _2904.y + (_2904.z * _2904.x);
                        _2904.z = _2904.z + (_2904.x * _2904.y);
                        uvec3 _2931 = _2904 ^ (_2904 >> uvec3(16u));
                        _2931.x = _2931.x + (_2931.y * _2931.z);
                        _2931.y = _2931.y + (_2931.z * _2931.x);
                        _2931.z = _2931.z + (_2931.x * _2931.y);
                        pixelRandom = vec3(_2931 >> uvec3(8u)) * 5.9604644775390625e-08;
                    }
                    float _518 = fract(pixelRandom.x + (frame * 0.61803400516510009765625));
                    int k = 0;
                    int chosen[2];
                    float pick[2];
                    for (;;)
                    {
                        if (!(k < 2))
                        {
                            break;
                        }
                        chosen[k] = -1;
                        pick[k] = fract(_518 + (float(k) * 0.5));
                        k++;
                        continue;
                    }
                    int i = 0;
                    float weightSum = 0.0;
                    float sunlit;
                    float visibleSum;
                    float _3018;
                    float _3053;
                    for (;;)
                    {
                        bool _130_ladder_break = false;
                        {
                            if (!(i < lampCount))
                            {
                                _130_ladder_break = true;
                            }
                            else
                            {
                                vec3 toLightView = p.lampPositionRadius.data[i].xyz - _2875;
                                float _557 = dot(toLightView, toLightView);
                                {
                                    float _3022 = p.lampPositionRadius.data[i].w * p.lampPositionRadius.data[i].w;
                                    if (_557 >= _3022)
                                    {
                                        _3018 = 0.0;
                                    }
                                    else
                                    {
                                        float _3027 = _557 / (isnan(9.9999997473787516355514526367188e-05) ? _3022 : (isnan(_3022) ? 9.9999997473787516355514526367188e-05 : max(_3022, 9.9999997473787516355514526367188e-05)));
                                        float _3030 = clamp(1.0 - (_3027 * _3027), 0.0, 1.0);
                                        _3018 = _3030 * _3030;
                                    }
                                }
                                if (!(_3018 <= 0.0))
                                {
                                    vec3 toCentre = (vec4(toLightView, 0.0) * spvWorkaroundRowMajor(p.viewToWorld)).xyz;
                                    vec3 centreDir = toCentre * inversesqrt(isnan(9.9999999392252902907785028219223e-09) ? _557 : (isnan(_557) ? 9.9999999392252902907785028219223e-09 : max(_557, 9.9999999392252902907785028219223e-09)));
                                    if (dot(p.lampDirection.data[i].xyz, p.lampDirection.data[i].xyz) > 0.25)
                                    {
                                        float _3043 = dot(normalize((vec4(p.lampDirection.data[i].xyz, 0.0) * spvWorkaroundRowMajor(p.viewToWorld)).xyz), -centreDir);
                                        float window = _3018 * (isnan(0.0) ? _3043 : (isnan(_3043) ? 0.0 : max(_3043, 0.0)));
                                        if (!(window <= 0.0))
                                        {
                                            sunlit = window;
                                            float _633 = clamp(p.lampDirection.data[i].w, 0.0500000007450580596923828125, 1.0);
                                            vec3 halfAxis = (vec4(p.lampRect.data[i].xyz, 0.0) * spvWorkaroundRowMajor(p.viewToWorld)).xyz;
                                            if (dot(halfAxis, halfAxis) > 9.9999997473787516355514526367188e-05)
                                            {
                                                float _650 = clamp(p.lampRect.data[i].w, 0.0199999995529651641845703125, _633);
                                                {
                                                    vec3 _3057 = toCentre - halfAxis;
                                                    vec3 _3058 = toCentre + halfAxis;
                                                    float _3059 = dot(_3057, _3057);
                                                    float _3060 = isnan(9.9999999392252902907785028219223e-09) ? _3059 : (isnan(_3059) ? 9.9999999392252902907785028219223e-09 : max(_3059, 9.9999999392252902907785028219223e-09));
                                                    float _3061 = dot(_3058, _3058);
                                                    float _3062 = isnan(9.9999999392252902907785028219223e-09) ? _3061 : (isnan(_3061) ? 9.9999999392252902907785028219223e-09 : max(_3061, 9.9999999392252902907785028219223e-09));
                                                    float _3063 = dot(toCentre, toCentre);
                                                    float _3064 = isnan(9.9999999392252902907785028219223e-09) ? _3063 : (isnan(_3063) ? 9.9999999392252902907785028219223e-09 : max(_3063, 9.9999999392252902907785028219223e-09));
                                                    float _3067 = dot(_366, _3057) * inversesqrt(_3060);
                                                    float _3070 = dot(_366, _3058) * inversesqrt(_3062);
                                                    if ((isnan(_3070) ? _3067 : (isnan(_3067) ? _3070 : max(_3067, _3070))) <= 0.0)
                                                    {
                                                        _3053 = 0.0;
                                                    }
                                                    else
                                                    {
                                                        float _3075 = _650 * _650;
                                                        float _3081 = clamp(_3067, 0.0, 1.0) / (isnan(_3075) ? _3060 : (isnan(_3060) ? _3075 : max(_3060, _3075)));
                                                        float _3084 = clamp(_3070, 0.0, 1.0) / (isnan(_3075) ? _3062 : (isnan(_3062) ? _3075 : max(_3062, _3075)));
                                                        float _3085 = isnan(_3084) ? _3081 : (isnan(_3081) ? _3084 : max(_3081, _3084));
                                                        float _3088 = clamp(dot(_366, toCentre) * inversesqrt(_3064), 0.0, 1.0) / (isnan(_3075) ? _3064 : (isnan(_3064) ? _3075 : max(_3064, _3075)));
                                                        _3053 = isnan(_3088) ? _3085 : (isnan(_3085) ? _3088 : max(_3085, _3088));
                                                    }
                                                }
                                                visibleSum = _3053;
                                            }
                                            else
                                            {
                                                float _3049 = _633 * _633;
                                                visibleSum = clamp(dot(_366, centreDir), 0.0, 1.0) / (isnan(_3049) ? _557 : (isnan(_557) ? _3049 : max(_557, _3049)));
                                            }
                                            float weight = ((2.0 * sunlit) * visibleSum) * dot(p.lampColourIntensity.data[i].xyz * p.lampColourIntensity.data[i].w, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875));
                                            if (!(weight <= 9.9999999747524270787835121154785e-07))
                                            {
                                                float weightSum_1 = weightSum + weight;
                                                float _740 = weight / (isnan(9.9999999747524270787835121154785e-07) ? weightSum_1 : (isnan(weightSum_1) ? 9.9999999747524270787835121154785e-07 : max(weightSum_1, 9.9999999747524270787835121154785e-07)));
                                                k = 0;
                                                for (;;)
                                                {
                                                    if (!(k < 2))
                                                    {
                                                        break;
                                                    }
                                                    if (pick[k] < _740)
                                                    {
                                                        chosen[k] = i;
                                                        pick[k] /= (isnan(9.9999999747524270787835121154785e-07) ? _740 : (isnan(_740) ? 9.9999999747524270787835121154785e-07 : max(_740, 9.9999999747524270787835121154785e-07)));
                                                    }
                                                    else
                                                    {
                                                        float _761 = 1.0 - _740;
                                                        pick[k] = (pick[k] - _740) / (isnan(9.9999999747524270787835121154785e-07) ? _761 : (isnan(_761) ? 9.9999999747524270787835121154785e-07 : max(_761, 9.9999999747524270787835121154785e-07)));
                                                    }
                                                    pick[k] = isnan(0.999999940395355224609375) ? pick[k] : (isnan(pick[k]) ? 0.999999940395355224609375 : min(pick[k], 0.999999940395355224609375));
                                                    k++;
                                                    continue;
                                                }
                                                weightSum = weightSum_1;
                                            }
                                        }
                                    }
                                    else
                                    {
                                        sunlit = _3018;
                                        float _633 = clamp(p.lampDirection.data[i].w, 0.0500000007450580596923828125, 1.0);
                                        vec3 halfAxis = (vec4(p.lampRect.data[i].xyz, 0.0) * spvWorkaroundRowMajor(p.viewToWorld)).xyz;
                                        if (dot(halfAxis, halfAxis) > 9.9999997473787516355514526367188e-05)
                                        {
                                            float _650 = clamp(p.lampRect.data[i].w, 0.0199999995529651641845703125, _633);
                                            {
                                                vec3 _3057 = toCentre - halfAxis;
                                                vec3 _3058 = toCentre + halfAxis;
                                                float _3059 = dot(_3057, _3057);
                                                float _3060 = isnan(9.9999999392252902907785028219223e-09) ? _3059 : (isnan(_3059) ? 9.9999999392252902907785028219223e-09 : max(_3059, 9.9999999392252902907785028219223e-09));
                                                float _3061 = dot(_3058, _3058);
                                                float _3062 = isnan(9.9999999392252902907785028219223e-09) ? _3061 : (isnan(_3061) ? 9.9999999392252902907785028219223e-09 : max(_3061, 9.9999999392252902907785028219223e-09));
                                                float _3063 = dot(toCentre, toCentre);
                                                float _3064 = isnan(9.9999999392252902907785028219223e-09) ? _3063 : (isnan(_3063) ? 9.9999999392252902907785028219223e-09 : max(_3063, 9.9999999392252902907785028219223e-09));
                                                float _3067 = dot(_366, _3057) * inversesqrt(_3060);
                                                float _3070 = dot(_366, _3058) * inversesqrt(_3062);
                                                if ((isnan(_3070) ? _3067 : (isnan(_3067) ? _3070 : max(_3067, _3070))) <= 0.0)
                                                {
                                                    _3053 = 0.0;
                                                }
                                                else
                                                {
                                                    float _3075 = _650 * _650;
                                                    float _3081 = clamp(_3067, 0.0, 1.0) / (isnan(_3075) ? _3060 : (isnan(_3060) ? _3075 : max(_3060, _3075)));
                                                    float _3084 = clamp(_3070, 0.0, 1.0) / (isnan(_3075) ? _3062 : (isnan(_3062) ? _3075 : max(_3062, _3075)));
                                                    float _3085 = isnan(_3084) ? _3081 : (isnan(_3081) ? _3084 : max(_3081, _3084));
                                                    float _3088 = clamp(dot(_366, toCentre) * inversesqrt(_3064), 0.0, 1.0) / (isnan(_3075) ? _3064 : (isnan(_3064) ? _3075 : max(_3064, _3075)));
                                                    _3053 = isnan(_3088) ? _3085 : (isnan(_3085) ? _3088 : max(_3085, _3088));
                                                }
                                            }
                                            visibleSum = _3053;
                                        }
                                        else
                                        {
                                            float _3049 = _633 * _633;
                                            visibleSum = clamp(dot(_366, centreDir), 0.0, 1.0) / (isnan(_3049) ? _557 : (isnan(_557) ? _3049 : max(_557, _3049)));
                                        }
                                        float weight = ((2.0 * sunlit) * visibleSum) * dot(p.lampColourIntensity.data[i].xyz * p.lampColourIntensity.data[i].w, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875));
                                        if (!(weight <= 9.9999999747524270787835121154785e-07))
                                        {
                                            float weightSum_1 = weightSum + weight;
                                            float _740 = weight / (isnan(9.9999999747524270787835121154785e-07) ? weightSum_1 : (isnan(weightSum_1) ? 9.9999999747524270787835121154785e-07 : max(weightSum_1, 9.9999999747524270787835121154785e-07)));
                                            k = 0;
                                            for (;;)
                                            {
                                                if (!(k < 2))
                                                {
                                                    break;
                                                }
                                                if (pick[k] < _740)
                                                {
                                                    chosen[k] = i;
                                                    pick[k] /= (isnan(9.9999999747524270787835121154785e-07) ? _740 : (isnan(_740) ? 9.9999999747524270787835121154785e-07 : max(_740, 9.9999999747524270787835121154785e-07)));
                                                }
                                                else
                                                {
                                                    float _761 = 1.0 - _740;
                                                    pick[k] = (pick[k] - _740) / (isnan(9.9999999747524270787835121154785e-07) ? _761 : (isnan(_761) ? 9.9999999747524270787835121154785e-07 : max(_761, 9.9999999747524270787835121154785e-07)));
                                                }
                                                pick[k] = isnan(0.999999940395355224609375) ? pick[k] : (isnan(pick[k]) ? 0.999999940395355224609375 : min(pick[k], 0.999999940395355224609375));
                                                k++;
                                                continue;
                                            }
                                            weightSum = weightSum_1;
                                        }
                                    }
                                }
                            }
                        }
                        if (_130_ladder_break)
                        {
                            break;
                        }
                        i++;
                        continue;
                    }
                    if (p.sunLight.w > 0.0)
                    {
                        _66 = weightSum > 0.0;
                    }
                    else
                    {
                        _66 = false;
                    }
                    if (_66)
                    {
                        float _811 = dot(_366, p.sunLight.xyz);
                        sunlit = (p.sunLight.w * (isnan(0.0) ? _811 : (isnan(_811) ? 0.0 : max(_811, 0.0)))) * clamp(texelFetch(_4762, ivec3(_247, 0).xy, 0).x, 0.0, 1.0);
                    }
                    else
                    {
                        sunlit = 0.0;
                    }
                    if (weightSum <= 0.0)
                    {
                        _66 = true;
                    }
                    else
                    {
                        _66 = weightSum < p.lampSource.w;
                    }
                    if (_66)
                    {
                        _66 = true;
                    }
                    else
                    {
                        _66 = weightSum < (0.00999999977648258209228515625 * sunlit);
                    }
                    if (_66)
                    {
                        imageStore(uVisibility, ivec2(gl_GlobalInvocationID.xy), vec4(1.0, 0.0, 0.0, 0.0));
                    }
                    else
                    {
                        k = 0;
                        visibleSum = 0.0;
                        float mappedLitSum = 0.0;
                        float blocked = 0.0;
                        float penumbraSum = 0.0;
                        float fieldRays = 0.0;
                        float nearMissSum = 0.0;
                        float penumbra;
                        vec3 emitting;
                        vec3 axis;
                        bool _93;
                        vec3 up;
                        bool _95;
                        bool onRect;
                        float blocked_1;
                        float penumbraSum_1;
                        float t;
                        float mapped;
                        float sourceWidth;
                        float _3093;
                        float _3094;
                        vec3 _3095;
                        vec4 _3096;
                        mat4 _3097;
                        int _3098;
                        int _3099;
                        int _3100;
                        bool _3102;
                        bool _3103;
                        vec3 _3104;
                        vec4 _3105;
                        mat4 _3106;
                        float _3111;
                        vec2 _3464;
                        vec2 _3480;
                        float _3496;
                        float _3539;
                        float _3574;
                        bool _3575;
                        bool _3836;
                        bool _3839;
                        bool _3840;
                        bool _3841;
                        bool _3843;
                        bool _3848;
                        float _3849;
                        float _3850;
                        bool _3851;
                        float _3852;
                        float _3853;
                        bool _3854;
                        bool _3855;
                        bool _3856;
                        bool _3857;
                        bool _3858;
                        float _4147;
                        bool _4149;
                        float _4333;
                        bool _4335;
                        float _4519;
                        bool _4521;
                        for (;;)
                        {
                            bool _179_ladder_break = false;
                            {
                                if (!(k < 2))
                                {
                                    _179_ladder_break = true;
                                }
                                else
                                {
                                    vec3 lampCentre = (vec4(p.lampPositionRadius.data[chosen[k]].xyz, 1.0) * spvWorkaroundRowMajor(p.viewToWorld)).xyz + p.cameraFrame.xyz;
                                    float _885 = clamp(p.lampDirection.data[chosen[k]].w, 0.0199999995529651641845703125, p.lampSource.x);
                                    if (dot(p.lampDirection.data[chosen[k]].xyz, p.lampDirection.data[chosen[k]].xyz) > 0.25)
                                    {
                                        vec3 _895 = normalize((vec4(p.lampDirection.data[chosen[k]].xyz, 0.0) * spvWorkaroundRowMajor(p.viewToWorld)).xyz);
                                        emitting = _895 * 0.0199999995529651641845703125;
                                        axis = _895;
                                    }
                                    else
                                    {
                                        emitting = vec3(0.0);
                                        axis = normalize(lampCentre - _385);
                                    }
                                    vec2 _916 = fract(pixelRandom.yz + (vec2(0.75487768650054931640625, 0.56984031200408935546875) * ((frame * 2.0) + float(k))));
                                    bool _924 = dot(emitting, emitting) > 0.0;
                                    if (_924)
                                    {
                                        _66 = p.lampRect.data[chosen[k]].w > 0.0;
                                    }
                                    else
                                    {
                                        _66 = false;
                                    }
                                    if (_66)
                                    {
                                        _93 = dot(p.lampRect.data[chosen[k]].xyz, p.lampRect.data[chosen[k]].xyz) > 0.0;
                                    }
                                    else
                                    {
                                        _93 = false;
                                    }
                                    if (_93)
                                    {
                                        vec3 halfLength = (vec4(p.lampRect.data[chosen[k]].xyz, 0.0) * spvWorkaroundRowMajor(p.viewToWorld)).xyz;
                                        vec2 uv_1 = (_916 * 2.0) - vec2(1.0);
                                        up = ((lampCentre + emitting) + (halfLength * uv_1.x)) + ((normalize(cross(axis, halfLength)) * p.lampRect.data[chosen[k]].w) * uv_1.y);
                                    }
                                    else
                                    {
                                        if (abs(axis.z) < 0.89999997615814208984375)
                                        {
                                            up = vec3(0.0, 0.0, 1.0);
                                        }
                                        else
                                        {
                                            up = vec3(1.0, 0.0, 0.0);
                                        }
                                        vec3 _981 = normalize(cross(up, axis));
                                        float spread = sqrt(_916.x) * _885;
                                        float around = 6.283185482025146484375 * _916.y;
                                        up = ((lampCentre + emitting) + (_981 * (spread * cos(around)))) + (cross(axis, _981) * (spread * sin(around)));
                                    }
                                    vec3 toTarget = up - _385;
                                    float _1004 = length(toTarget);
                                    if (_924)
                                    {
                                        _95 = p.lampRect.data[chosen[k]].w > 0.0;
                                    }
                                    else
                                    {
                                        _95 = false;
                                    }
                                    if (_95)
                                    {
                                        onRect = dot(p.lampRect.data[chosen[k]].xyz, p.lampRect.data[chosen[k]].xyz) > 0.0;
                                    }
                                    else
                                    {
                                        onRect = false;
                                    }
                                    if (onRect)
                                    {
                                        penumbra = 0.0500000007450580596923828125;
                                    }
                                    else
                                    {
                                        penumbra = clamp(_885 * 0.5, 0.0500000007450580596923828125, 0.20000000298023223876953125);
                                    }
                                    if (_1004 <= (penumbra + 0.0199999995529651641845703125))
                                    {
                                        visibleSum += 1.0;
                                        blocked_1 = blocked;
                                        penumbraSum_1 = penumbraSum;
                                    }
                                    else
                                    {
                                        float nearMiss = 0.0;
                                        if (onRect)
                                        {
                                            weightSum = length(p.lampRect.data[chosen[k]].xyz) + p.lampRect.data[chosen[k]].w;
                                        }
                                        else
                                        {
                                            weightSum = 2.0 * _885;
                                        }
                                        {
                                            int _3118 = chosen[k] >> 2;
                                            int _3121 = chosen[k] & 3;
                                            if (f.mapSlot.data[_3118][_3121] < 0)
                                            {
                                                _3093 = -1.0;
                                            }
                                            else
                                            {
                                                int _3127 = f.mapSlot.data[_3118][_3121] & 255;
                                                vec4 _3132 = vec4(_385 - p.cameraFrame.xyz, 1.0);
                                                vec4 _3133 = _3132 * spvWorkaroundRowMajor(f.mapMatrix.data[_3127]);
                                                if ((f.mapSlot.data[_3118][_3121] & 256) != 0)
                                                {
                                                    bool _3101 = false;
                                                    _3095 = vec3(0.0);
                                                    _3096 = _3133;
                                                    _3097 = spvWorkaroundRowMajor(f.mapMatrix.data[_3127]);
                                                    _3098 = 0;
                                                    _3099 = _3127;
                                                    for (;;)
                                                    {
                                                        if (_3098 < 6)
                                                        {
                                                            _3102 = !_3101;
                                                        }
                                                        else
                                                        {
                                                            _3102 = false;
                                                        }
                                                        if (!_3102)
                                                        {
                                                            break;
                                                        }
                                                        int _3190 = _3099 + _3098;
                                                        vec4 _3193 = _3132 * spvWorkaroundRowMajor(f.mapMatrix.data[_3190]);
                                                        if (_3193.w > 9.9999997473787516355514526367188e-05)
                                                        {
                                                            vec3 _3199 = _3193.xyz / vec3(_3193.w);
                                                            if (all(lessThanEqual(abs(_3199.xy), vec2(1.0))))
                                                            {
                                                                _3103 = true;
                                                                _3104 = _3199;
                                                                _3105 = _3193;
                                                                _3106 = spvWorkaroundRowMajor(f.mapMatrix.data[_3190]);
                                                                _3100 = _3190;
                                                            }
                                                            else
                                                            {
                                                                _3103 = _3101;
                                                                _3104 = _3095;
                                                                _3105 = _3096;
                                                                _3106 = _3097;
                                                                _3100 = _3099;
                                                            }
                                                            _3101 = _3103;
                                                            _3095 = _3104;
                                                            _3096 = _3105;
                                                            _3097 = _3106;
                                                            _3099 = _3100;
                                                        }
                                                        _3098++;
                                                        continue;
                                                    }
                                                    if (!_3101)
                                                    {
                                                        _3093 = -2.0;
                                                    }
                                                    else
                                                    {
                                                        if (_3095.z < (-1.0))
                                                        {
                                                            _3093 = 1.0;
                                                        }
                                                        else
                                                        {
                                                            vec3 _3241 = vec3(_3097[0].xyz);
                                                            float _3242 = length(_3241);
                                                            float _3243 = isnan(0.001000000047497451305389404296875) ? _3242 : (isnan(_3242) ? 0.001000000047497451305389404296875 : max(_3242, 0.001000000047497451305389404296875));
                                                            int _3484 = _3099 >> 1;
                                                            if ((_3099 & 1) != 0)
                                                            {
                                                                _3480 = f.mapDepth.data[_3484].zw;
                                                            }
                                                            else
                                                            {
                                                                _3480 = f.mapDepth.data[_3484].xy;
                                                            }
                                                            float _3249 = _3480.y / ((-1.0) - _3480.x);
                                                            vec2 _3258 = vec2((_3095.x * 0.5) + 0.5, 0.5 - (_3095.y * 0.5));
                                                            uvec3 _3260 = uvec3(textureSize(_4765, 0));
                                                            uint _3261 = _3260.x;
                                                            float _3266 = float(max(_3261, 1u));
                                                            ivec2 _3272 = ivec2(int(_3261), int(_3260.y));
                                                            vec3 _3295 = vec3(dot(_3241, _366) / _3243, dot(vec3(_3097[1].xyz), _366) / _3243, dot(vec3(_3097[3].xyz), _366));
                                                            float _3296 = dot(_3295, vec3((_3095.x * _3096.w) / _3243, (_3095.y * _3096.w) / _3243, _3096.w));
                                                            float _3306 = (0.014999999664723873138427734375 + (0.0030000000260770320892333984375 * _3096.w)) + (1.5 * ((_3096.w * (2.0 / _3243)) / float(max(_3261, 1u))));
                                                            float _3307 = 2.0 / _3243;
                                                            float _3308 = weightSum / _3307;
                                                            float _3309 = _3096.w * 0.25;
                                                            float _3310 = _3249 + 0.00999999977648258209228515625;
                                                            float _3311 = isnan(_3310) ? _3309 : (isnan(_3309) ? _3310 : max(_3309, _3310));
                                                            float _3313 = _3096.w - _3311;
                                                            float _3320 = clamp(((_3308 * 0.5) * (isnan(0.0) ? _3313 : (isnan(_3313) ? 0.0 : max(_3313, 0.0)))) / (_3311 * _3096.w), 2.0 / _3266, 32.0 / _3266);
                                                            _3098 = -2;
                                                            _3094 = 0.0;
                                                            float _3110 = 0.0;
                                                            for (;;)
                                                            {
                                                                if (!(_3098 <= 2))
                                                                {
                                                                    break;
                                                                }
                                                                _3100 = -2;
                                                                _3111 = _3094;
                                                                float _3112 = _3110;
                                                                for (;;)
                                                                {
                                                                    if (!(_3100 <= 2))
                                                                    {
                                                                        break;
                                                                    }
                                                                    vec2 _3346 = _3258 + (vec2(float(_3100), float(_3098)) * (_3320 * 0.5));
                                                                    vec4 _3357 = texelFetch(_4765, ivec4(clamp(ivec2(_3346 * vec2(_3272)), ivec2(0), _3272 - ivec2(1)), _3099, 0).xyz, 0);
                                                                    float _3358 = _3357.x;
                                                                    float _3509 = dot(_3295, vec3(vec2((_3346.x * 2.0) - 1.0, 1.0 - (_3346.y * 2.0)) / vec2(_3243), 1.0));
                                                                    if (abs(_3509) > 9.9999997473787516355514526367188e-05)
                                                                    {
                                                                        _3496 = _3296 / _3509;
                                                                    }
                                                                    else
                                                                    {
                                                                        _3496 = _3096.w;
                                                                    }
                                                                    float _3516 = 2.0 * ((length(_3346 - _3258) * _3307) * _3096.w);
                                                                    float _3364 = clamp(_3496, _3096.w - _3516, _3096.w + _3516) - _3306;
                                                                    float _3365 = _3249 + 0.004999999888241291046142578125;
                                                                    float _3366 = isnan(_3365) ? _3364 : (isnan(_3364) ? _3365 : max(_3364, _3365));
                                                                    if (_3358 < (((_3480.x + (_3480.y / (isnan(9.9999997473787516355514526367188e-05) ? _3366 : (isnan(_3366) ? 9.9999997473787516355514526367188e-05 : max(_3366, 9.9999997473787516355514526367188e-05))))) * 0.5) + 0.5))
                                                                    {
                                                                        float _3536 = ((_3358 * 2.0) - 1.0) - _3480.x;
                                                                        _3111 += (_3480.y / (isnan(-9.9999999747524270787835121154785e-07) ? _3536 : (isnan(_3536) ? (-9.9999999747524270787835121154785e-07) : min(_3536, -9.9999999747524270787835121154785e-07))));
                                                                        _3112 += 1.0;
                                                                    }
                                                                    _3100++;
                                                                    continue;
                                                                }
                                                                _3098++;
                                                                _3094 = _3111;
                                                                _3110 = _3112;
                                                                continue;
                                                            }
                                                            if (_3110 <= 0.0)
                                                            {
                                                                _3093 = 1.0;
                                                            }
                                                            else
                                                            {
                                                                float _3396 = _3094 / _3110;
                                                                float _3397 = isnan(0.0500000007450580596923828125) ? _3396 : (isnan(_3396) ? 0.0500000007450580596923828125 : max(_3396, 0.0500000007450580596923828125));
                                                                float _3398 = _3096.w - _3397;
                                                                float _3405 = clamp(((_3308 * (isnan(0.0) ? _3398 : (isnan(_3398) ? 0.0 : max(_3398, 0.0)))) / (_3397 * _3096.w)) * 0.5, 1.0 / _3266, 24.0 / _3266);
                                                                float _3412 = fract(52.98291778564453125 * fract(dot(_3258 * vec2(_3272), vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) * 6.283185482025146484375;
                                                                float _3413 = sin(_3412);
                                                                float _3414 = cos(_3412);
                                                                _3100 = 0;
                                                                _3111 = 0.0;
                                                                for (;;)
                                                                {
                                                                    if (!(_3100 < 12))
                                                                    {
                                                                        break;
                                                                    }
                                                                    vec2 _3435 = vec2((_1612_comp[_3100].x * _3414) - (_1612_comp[_3100].y * _3413), (_1612_comp[_3100].x * _3413) + (_1612_comp[_3100].y * _3414)) * _3405;
                                                                    vec2 _3436 = _3258 + _3435;
                                                                    float _3552 = dot(_3295, vec3(vec2((_3436.x * 2.0) - 1.0, 1.0 - (_3436.y * 2.0)) / vec2(_3243), 1.0));
                                                                    if (abs(_3552) > 9.9999997473787516355514526367188e-05)
                                                                    {
                                                                        _3539 = _3296 / _3552;
                                                                    }
                                                                    else
                                                                    {
                                                                        _3539 = _3096.w;
                                                                    }
                                                                    float _3559 = 2.0 * ((length(_3435) * _3307) * _3096.w);
                                                                    float _3441 = clamp(_3539, _3096.w - _3559, _3096.w + _3559) - _3306;
                                                                    float _3442 = _3249 + 0.004999999888241291046142578125;
                                                                    float _3443 = isnan(_3442) ? _3441 : (isnan(_3441) ? _3442 : max(_3441, _3442));
                                                                    _3100++;
                                                                    _3111 += spvShadowLod0(_4767, vec4(vec3(_3436, float(_3099)), ((_3480.x + (_3480.y / (isnan(9.9999997473787516355514526367188e-05) ? _3443 : (isnan(_3443) ? 9.9999997473787516355514526367188e-05 : max(_3443, 9.9999997473787516355514526367188e-05))))) * 0.5) + 0.5));
                                                                    continue;
                                                                }
                                                                _3093 = _3111 * 0.083333335816860198974609375;
                                                            }
                                                        }
                                                    }
                                                }
                                                else
                                                {
                                                    int _3468 = _3127 >> 1;
                                                    if ((f.mapSlot.data[_3118][_3121] & 1) != 0)
                                                    {
                                                        _3464 = f.mapDepth.data[_3468].zw;
                                                    }
                                                    else
                                                    {
                                                        _3464 = f.mapDepth.data[_3468].xy;
                                                    }
                                                    float _3141 = _3464.y / ((-1.0) - _3464.x);
                                                    if (_3133.w <= _3141)
                                                    {
                                                        _3093 = 1.0;
                                                    }
                                                    else
                                                    {
                                                        vec3 _3148 = _3133.xyz / vec3(_3133.w);
                                                        if (any(greaterThan(abs(_3148.xy), vec2(0.980000019073486328125))))
                                                        {
                                                            float _3159 = length(vec3(spvWorkaroundRowMajor(f.mapMatrix.data[_3127])[0].xyz));
                                                            vec3 _3165 = vec3(_3133.xy / vec2(isnan(0.001000000047497451305389404296875) ? _3159 : (isnan(_3159) ? 0.001000000047497451305389404296875 : max(_3159, 0.001000000047497451305389404296875))), _3133.w - _3141);
                                                            if (dot(_3165, _3165) < 2.25)
                                                            {
                                                                _3094 = 1.0;
                                                            }
                                                            else
                                                            {
                                                                _3094 = -2.0;
                                                            }
                                                            _3093 = _3094;
                                                        }
                                                        else
                                                        {
                                                            _3096 = _3133;
                                                            _3097 = spvWorkaroundRowMajor(f.mapMatrix.data[_3127]);
                                                            _3095 = _3148;
                                                            _3099 = _3127;
                                                            vec3 _3241 = vec3(_3097[0].xyz);
                                                            float _3242 = length(_3241);
                                                            float _3243 = isnan(0.001000000047497451305389404296875) ? _3242 : (isnan(_3242) ? 0.001000000047497451305389404296875 : max(_3242, 0.001000000047497451305389404296875));
                                                            int _3484 = _3099 >> 1;
                                                            if ((_3099 & 1) != 0)
                                                            {
                                                                _3480 = f.mapDepth.data[_3484].zw;
                                                            }
                                                            else
                                                            {
                                                                _3480 = f.mapDepth.data[_3484].xy;
                                                            }
                                                            float _3249 = _3480.y / ((-1.0) - _3480.x);
                                                            vec2 _3258 = vec2((_3095.x * 0.5) + 0.5, 0.5 - (_3095.y * 0.5));
                                                            uvec3 _3260 = uvec3(textureSize(_4765, 0));
                                                            uint _3261 = _3260.x;
                                                            float _3266 = float(max(_3261, 1u));
                                                            ivec2 _3272 = ivec2(int(_3261), int(_3260.y));
                                                            vec3 _3295 = vec3(dot(_3241, _366) / _3243, dot(vec3(_3097[1].xyz), _366) / _3243, dot(vec3(_3097[3].xyz), _366));
                                                            float _3296 = dot(_3295, vec3((_3095.x * _3096.w) / _3243, (_3095.y * _3096.w) / _3243, _3096.w));
                                                            float _3306 = (0.014999999664723873138427734375 + (0.0030000000260770320892333984375 * _3096.w)) + (1.5 * ((_3096.w * (2.0 / _3243)) / float(max(_3261, 1u))));
                                                            float _3307 = 2.0 / _3243;
                                                            float _3308 = weightSum / _3307;
                                                            float _3309 = _3096.w * 0.25;
                                                            float _3310 = _3249 + 0.00999999977648258209228515625;
                                                            float _3311 = isnan(_3310) ? _3309 : (isnan(_3309) ? _3310 : max(_3309, _3310));
                                                            float _3313 = _3096.w - _3311;
                                                            float _3320 = clamp(((_3308 * 0.5) * (isnan(0.0) ? _3313 : (isnan(_3313) ? 0.0 : max(_3313, 0.0)))) / (_3311 * _3096.w), 2.0 / _3266, 32.0 / _3266);
                                                            _3098 = -2;
                                                            _3094 = 0.0;
                                                            float _3110 = 0.0;
                                                            for (;;)
                                                            {
                                                                if (!(_3098 <= 2))
                                                                {
                                                                    break;
                                                                }
                                                                _3100 = -2;
                                                                _3111 = _3094;
                                                                float _3112 = _3110;
                                                                for (;;)
                                                                {
                                                                    if (!(_3100 <= 2))
                                                                    {
                                                                        break;
                                                                    }
                                                                    vec2 _3346 = _3258 + (vec2(float(_3100), float(_3098)) * (_3320 * 0.5));
                                                                    vec4 _3357 = texelFetch(_4765, ivec4(clamp(ivec2(_3346 * vec2(_3272)), ivec2(0), _3272 - ivec2(1)), _3099, 0).xyz, 0);
                                                                    float _3358 = _3357.x;
                                                                    float _3509 = dot(_3295, vec3(vec2((_3346.x * 2.0) - 1.0, 1.0 - (_3346.y * 2.0)) / vec2(_3243), 1.0));
                                                                    if (abs(_3509) > 9.9999997473787516355514526367188e-05)
                                                                    {
                                                                        _3496 = _3296 / _3509;
                                                                    }
                                                                    else
                                                                    {
                                                                        _3496 = _3096.w;
                                                                    }
                                                                    float _3516 = 2.0 * ((length(_3346 - _3258) * _3307) * _3096.w);
                                                                    float _3364 = clamp(_3496, _3096.w - _3516, _3096.w + _3516) - _3306;
                                                                    float _3365 = _3249 + 0.004999999888241291046142578125;
                                                                    float _3366 = isnan(_3365) ? _3364 : (isnan(_3364) ? _3365 : max(_3364, _3365));
                                                                    if (_3358 < (((_3480.x + (_3480.y / (isnan(9.9999997473787516355514526367188e-05) ? _3366 : (isnan(_3366) ? 9.9999997473787516355514526367188e-05 : max(_3366, 9.9999997473787516355514526367188e-05))))) * 0.5) + 0.5))
                                                                    {
                                                                        float _3536 = ((_3358 * 2.0) - 1.0) - _3480.x;
                                                                        _3111 += (_3480.y / (isnan(-9.9999999747524270787835121154785e-07) ? _3536 : (isnan(_3536) ? (-9.9999999747524270787835121154785e-07) : min(_3536, -9.9999999747524270787835121154785e-07))));
                                                                        _3112 += 1.0;
                                                                    }
                                                                    _3100++;
                                                                    continue;
                                                                }
                                                                _3098++;
                                                                _3094 = _3111;
                                                                _3110 = _3112;
                                                                continue;
                                                            }
                                                            if (_3110 <= 0.0)
                                                            {
                                                                _3093 = 1.0;
                                                            }
                                                            else
                                                            {
                                                                float _3396 = _3094 / _3110;
                                                                float _3397 = isnan(0.0500000007450580596923828125) ? _3396 : (isnan(_3396) ? 0.0500000007450580596923828125 : max(_3396, 0.0500000007450580596923828125));
                                                                float _3398 = _3096.w - _3397;
                                                                float _3405 = clamp(((_3308 * (isnan(0.0) ? _3398 : (isnan(_3398) ? 0.0 : max(_3398, 0.0)))) / (_3397 * _3096.w)) * 0.5, 1.0 / _3266, 24.0 / _3266);
                                                                float _3412 = fract(52.98291778564453125 * fract(dot(_3258 * vec2(_3272), vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) * 6.283185482025146484375;
                                                                float _3413 = sin(_3412);
                                                                float _3414 = cos(_3412);
                                                                _3100 = 0;
                                                                _3111 = 0.0;
                                                                for (;;)
                                                                {
                                                                    if (!(_3100 < 12))
                                                                    {
                                                                        break;
                                                                    }
                                                                    vec2 _3435 = vec2((_1612_comp[_3100].x * _3414) - (_1612_comp[_3100].y * _3413), (_1612_comp[_3100].x * _3413) + (_1612_comp[_3100].y * _3414)) * _3405;
                                                                    vec2 _3436 = _3258 + _3435;
                                                                    float _3552 = dot(_3295, vec3(vec2((_3436.x * 2.0) - 1.0, 1.0 - (_3436.y * 2.0)) / vec2(_3243), 1.0));
                                                                    if (abs(_3552) > 9.9999997473787516355514526367188e-05)
                                                                    {
                                                                        _3539 = _3296 / _3552;
                                                                    }
                                                                    else
                                                                    {
                                                                        _3539 = _3096.w;
                                                                    }
                                                                    float _3559 = 2.0 * ((length(_3435) * _3307) * _3096.w);
                                                                    float _3441 = clamp(_3539, _3096.w - _3559, _3096.w + _3559) - _3306;
                                                                    float _3442 = _3249 + 0.004999999888241291046142578125;
                                                                    float _3443 = isnan(_3442) ? _3441 : (isnan(_3441) ? _3442 : max(_3441, _3442));
                                                                    _3100++;
                                                                    _3111 += spvShadowLod0(_4767, vec4(vec3(_3436, float(_3099)), ((_3480.x + (_3480.y / (isnan(9.9999997473787516355514526367188e-05) ? _3443 : (isnan(_3443) ? 9.9999997473787516355514526367188e-05 : max(_3443, 9.9999997473787516355514526367188e-05))))) * 0.5) + 0.5));
                                                                    continue;
                                                                }
                                                                _3093 = _3111 * 0.083333335816860198974609375;
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        if (_3093 == (-1.0))
                                        {
                                            vec3 _1697 = _385 - p.cameraFrame.xyz;
                                            {
                                                if (chosen[k] < 0)
                                                {
                                                    _3575 = true;
                                                }
                                                else
                                                {
                                                    _3575 = chosen[k] >= 160;
                                                }
                                                if (_3575)
                                                {
                                                    _3574 = -1.0;
                                                }
                                                else
                                                {
                                                    int _3599 = chosen[k] * 6;
                                                    if (c.record.data[(chosen[k] * 24) + 3].z <= 0.0)
                                                    {
                                                        _3574 = -1.0;
                                                    }
                                                    else
                                                    {
                                                        uvec3 _3611 = uvec3(textureSize(_4770, 0));
                                                        uint _3576 = _3611.x;
                                                        uint _3577 = _3611.y;
                                                        float _3579 = 0.25;
                                                        int _3580 = 0;
                                                        for (;;)
                                                        {
                                                            if (!(_3580 < 6))
                                                            {
                                                                break;
                                                            }
                                                            int _3626 = ((_3599 + _3580) * 4) + 2;
                                                            float _3632 = dot(c.record.data[_3626].xyz, _1697) + c.record.data[_3626].w;
                                                            _3579 = isnan(_3632) ? _3579 : (isnan(_3579) ? _3632 : max(_3579, _3632));
                                                            _3580++;
                                                            continue;
                                                        }
                                                        vec3 _3650 = _1697 + (_366 * (0.0500000007450580596923828125 + (1.5 * ((_3579 * 2.0) / float(max(_3576, 1u))))));
                                                        float _3581 = -1000000015047466219876688855040.0;
                                                        int _3582 = _3599;
                                                        _3580 = 0;
                                                        for (;;)
                                                        {
                                                            if (!(_3580 < 6))
                                                            {
                                                                break;
                                                            }
                                                            int _3660 = _3599 + _3580;
                                                            int _3662 = (_3660 * 4) + 2;
                                                            float _3668 = dot(c.record.data[_3662].xyz, _3650) + c.record.data[_3662].w;
                                                            if (_3668 > _3581)
                                                            {
                                                                _3581 = _3668;
                                                                _3582 = _3660;
                                                            }
                                                            _3580++;
                                                            continue;
                                                        }
                                                        int _3680 = _3582 * 4;
                                                        int _3681 = _3680 + 3;
                                                        if (c.record.data[_3681].z <= 0.0)
                                                        {
                                                            _3574 = -1.0;
                                                        }
                                                        else
                                                        {
                                                            int _3690 = _3680 + 1;
                                                            if (_3581 <= (c.record.data[_3681].y / ((-1.0) - c.record.data[_3681].x)))
                                                            {
                                                                _3574 = 1.0;
                                                            }
                                                            else
                                                            {
                                                                vec2 _3712 = vec2(dot(c.record.data[_3680].xyz, _3650) + c.record.data[_3680].w, dot(c.record.data[_3690].xyz, _3650) + c.record.data[_3690].w) / vec2(_3581);
                                                                ivec2 _3724 = ivec2(int(_3576), int(_3577));
                                                                float _3725 = length(c.record.data[_3680].xyz);
                                                                float _3738 = (0.0500000007450580596923828125 + (0.004999999888241291046142578125 * _3581)) + (2.0 * ((_3581 * (2.0 / (isnan(0.001000000047497451305389404296875) ? _3725 : (isnan(_3725) ? 0.001000000047497451305389404296875 : max(_3725, 0.001000000047497451305389404296875))))) / float(max(_3576, 1u))));
                                                                int _3741 = int(c.record.data[_3681].w + 0.5);
                                                                vec2 _3745 = (vec2((_3712.x * 0.5) + 0.5, 0.5 - (_3712.y * 0.5)) * vec2(_3724)) - vec2(0.5);
                                                                vec2 _3746 = floor(_3745);
                                                                ivec2 _3749 = ivec2(_3746) - ivec2(1);
                                                                vec2 _3750 = _3745 - _3746;
                                                                int _3585 = 0;
                                                                float _3583 = 0.0;
                                                                float _3584 = 0.0;
                                                                for (;;)
                                                                {
                                                                    if (!(_3585 < 4))
                                                                    {
                                                                        break;
                                                                    }
                                                                    int _3587 = 0;
                                                                    float _3586 = _3584;
                                                                    for (;;)
                                                                    {
                                                                        if (!(_3587 < 4))
                                                                        {
                                                                            break;
                                                                        }
                                                                        int _3769 = _3587;
                                                                        float _3782 = ((texelFetch(_4770, ivec4(clamp(_3749 + ivec2(_3769, _3585), ivec2(0), _3724 - ivec2(1)), _3741, 0).xyz, 0).x * 2.0) - 1.0) - c.record.data[_3681].x;
                                                                        vec2 _3834 = clamp(vec2(1.0) - (abs(vec2(float(_3769) - 1.0, float(_3585) - 1.0) - _3750) * vec2(0.5)), vec2(0.0), vec2(1.0));
                                                                        float _3801 = _3834.x * _3834.y;
                                                                        if ((c.record.data[_3681].y / (isnan(-9.9999999747524270787835121154785e-07) ? _3782 : (isnan(_3782) ? (-9.9999999747524270787835121154785e-07) : min(_3782, -9.9999999747524270787835121154785e-07)))) >= (_3581 - _3738))
                                                                        {
                                                                            _3579 = _3801;
                                                                        }
                                                                        else
                                                                        {
                                                                            _3579 = 0.0;
                                                                        }
                                                                        _3587++;
                                                                        _3583 += _3579;
                                                                        _3586 += _3801;
                                                                        continue;
                                                                    }
                                                                    _3585++;
                                                                    _3584 = _3586;
                                                                    continue;
                                                                }
                                                                _3574 = _3583 / (isnan(9.9999997473787516355514526367188e-05) ? _3584 : (isnan(_3584) ? 9.9999997473787516355514526367188e-05 : max(_3584, 9.9999997473787516355514526367188e-05)));
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            mapped = _3574;
                                        }
                                        else
                                        {
                                            mapped = _3093;
                                        }
                                        if (mapped >= 0.0)
                                        {
                                            if (mapped < 1.0)
                                            {
                                                float _2048 = 1.0 - mapped;
                                                blocked_1 = blocked + _2048;
                                                penumbraSum_1 = penumbraSum + (_2048 * 0.0500000007450580596923828125);
                                            }
                                            else
                                            {
                                                blocked_1 = blocked;
                                                penumbraSum_1 = penumbraSum;
                                            }
                                            visibleSum += mapped;
                                            mappedLitSum += mapped;
                                        }
                                        else
                                        {
                                            vec3 rayDirection = toTarget / vec3(_1004);
                                            vec3 _2071 = _385 - p.cameraFrame.xyz;
                                            float _2073 = _1004 - penumbra;
                                            float _2074 = dot(rayDirection, _366);
                                            float _2075 = isnan(0.0) ? _2074 : (isnan(_2074) ? 0.0 : max(_2074, 0.0));
                                            if (_924)
                                            {
                                                sunlit = dot(-rayDirection, axis);
                                            }
                                            else
                                            {
                                                sunlit = 0.0;
                                            }
                                            _3835 = false;
                                            {
                                                t = 0.0;
                                                float _3862 = isnan(1.0) ? _2073 : (isnan(_2073) ? 1.0 : min(_2073, 1.0));
                                                float _3837 = 0.0;
                                                int _3838 = 1;
                                                for (;;)
                                                {
                                                    if (!(_3838 <= 16))
                                                    {
                                                        break;
                                                    }
                                                    float _3874 = _3862 * (float(_3838) * 0.0625);
                                                    vec4 _3880 = spvWorkaroundRowMajor(p.viewToWorld) * vec4(_2071 + (rayDirection * _3874), 0.0);
                                                    float _3882 = _3880.z;
                                                    if (_3882 <= p.unproject.z)
                                                    {
                                                        break;
                                                    }
                                                    float _4115 = _3880.z;
                                                    vec2 _4126 = (vec2((_3880.x * p.unproject.x) / _4115, ((-_3880.y) * p.unproject.y) / _4115) * 0.5) + vec2(0.5);
                                                    if (any(lessThan(_4126, vec2(0.0))))
                                                    {
                                                        _3839 = true;
                                                    }
                                                    else
                                                    {
                                                        _3839 = any(greaterThan(_4126, vec2(1.0)));
                                                    }
                                                    if (_3839)
                                                    {
                                                        break;
                                                    }
                                                    vec4 _4131 = textureLod(_4757, _4126, 0.0);
                                                    float _4132 = _4131.x;
                                                    if (_4132 > 0.0)
                                                    {
                                                        float _4145 = ((2.0 * p.unproject.z) * p.unproject.w) / ((p.unproject.w + p.unproject.z) - ((1.0 - (2.0 * _4132)) * (p.unproject.w - p.unproject.z)));
                                                        float _3906 = _3882 - _4145;
                                                        if (_3906 > 0.0199999995529651641845703125)
                                                        {
                                                            float _3910 = 0.00999999977648258209228515625 * _4145;
                                                            _3840 = _3906 < (isnan(_3910) ? 0.0500000007450580596923828125 : (isnan(0.0500000007450580596923828125) ? _3910 : max(0.0500000007450580596923828125, _3910)));
                                                        }
                                                        else
                                                        {
                                                            _3840 = false;
                                                        }
                                                        if (_3840)
                                                        {
                                                            t = _3874;
                                                            _3835 = true;
                                                            _3836 = true;
                                                            break;
                                                        }
                                                    }
                                                    _3837 = _3874;
                                                    _3838++;
                                                    continue;
                                                }
                                                if (!(_3835))
                                                {
                                                    if (f.levels.x <= 0)
                                                    {
                                                        _3835 = true;
                                                        _3836 = false;
                                                    }
                                                    else
                                                    {
                                                        float _3937 = 0.5 * f.origin.data[0].w;
                                                        float _3939 = isnan(_3937) ? _3837 : (isnan(_3837) ? _3937 : max(_3837, _3937));
                                                        float _3940 = _2073 - _3937;
                                                        vec3 _3942 = _2071 + (rayDirection * _3939);
                                                        _4146 = false;
                                                        {
                                                            _3841 = false;
                                                            int _4148 = 0;
                                                            for (;;)
                                                            {
                                                                bool _4160_ladder_break = false;
                                                                {
                                                                    if (!(_4148 < f.levels.x))
                                                                    {
                                                                        _4160_ladder_break = true;
                                                                    }
                                                                    else
                                                                    {
                                                                        vec3 _4176 = (_3942 - f.origin.data[_4148].xyz) / vec3(f.origin.data[_4148].w);
                                                                        float _4180 = float(f.levels.y) - 0.5;
                                                                        if (any(lessThan(_4176, vec3(0.5))))
                                                                        {
                                                                            _4149 = true;
                                                                        }
                                                                        else
                                                                        {
                                                                            _4149 = any(greaterThan(_4176, vec3(_4180)));
                                                                        }
                                                                        if (!(_4149))
                                                                        {
                                                                            _3841 = true;
                                                                            float _4291 = ((textureLod(_4772, vec3(_4176.x / float(f.levels.y), _4176.y / float(f.levels.y), ((float(_4148) * float(f.levels.y)) + _4176.z) / float(f.levels.y * f.levels.x)), 0.0).x * 2.0) - 1.0) * f.range[_4148];
                                                                            vec3 _4195 = _4176 - vec3(0.5);
                                                                            vec3 _4197 = vec3(_4180) - _4176;
                                                                            bvec3 _4959 = isnan(_4195);
                                                                            bvec3 _4960 = isnan(_4197);
                                                                            vec3 _4961 = min(_4195, _4197);
                                                                            vec3 _4962 = vec3(_4959.x ? _4197.x : _4961.x, _4959.y ? _4197.y : _4961.y, _4959.z ? _4197.z : _4961.z);
                                                                            vec3 _4198 = vec3(_4960.x ? _4195.x : _4962.x, _4960.y ? _4195.y : _4962.y, _4960.z ? _4195.z : _4962.z);
                                                                            float _4199 = _4198.x;
                                                                            float _4200 = _4198.y;
                                                                            float _4201 = _4198.z;
                                                                            float _4202 = isnan(_4201) ? _4200 : (isnan(_4200) ? _4201 : min(_4200, _4201));
                                                                            float _4206 = clamp(1.0 - ((isnan(_4202) ? _4199 : (isnan(_4199) ? _4202 : min(_4199, _4202))) * 0.125), 0.0, 1.0);
                                                                            if (_4206 <= 0.0)
                                                                            {
                                                                                _4149 = true;
                                                                            }
                                                                            else
                                                                            {
                                                                                _4149 = (_4148 + 1) >= f.levels.x;
                                                                            }
                                                                            if (_4149)
                                                                            {
                                                                                _4146 = true;
                                                                                _4147 = _4291;
                                                                                _4160_ladder_break = true;
                                                                            }
                                                                            else
                                                                            {
                                                                                int _4220 = _4148 + 1;
                                                                                vec3 _4227 = (_3942 - f.origin.data[_4220].xyz) / vec3(f.origin.data[_4220].w);
                                                                                if (any(lessThan(_4227, vec3(0.5))))
                                                                                {
                                                                                    _4149 = true;
                                                                                }
                                                                                else
                                                                                {
                                                                                    _4149 = any(greaterThan(_4227, vec3(_4180)));
                                                                                }
                                                                                if (_4149)
                                                                                {
                                                                                    _4146 = true;
                                                                                    _4147 = _4291;
                                                                                    _4160_ladder_break = true;
                                                                                }
                                                                                else
                                                                                {
                                                                                    _4146 = true;
                                                                                    _4147 = mix(_4291, ((textureLod(_4772, vec3(_4227.x / float(f.levels.y), _4227.y / float(f.levels.y), ((float(_4220) * float(f.levels.y)) + _4227.z) / float(f.levels.y * f.levels.x)), 0.0).x * 2.0) - 1.0) * f.range[_4220], _4206);
                                                                                    _4160_ladder_break = true;
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                                if (_4160_ladder_break)
                                                                {
                                                                    break;
                                                                }
                                                                _4148++;
                                                                continue;
                                                            }
                                                            if (!(_4146))
                                                            {
                                                                _4146 = true;
                                                                _4147 = 1000000.0;
                                                            }
                                                        }
                                                        vec3 _3945 = _2071 + (rayDirection * _3940);
                                                        _4332 = false;
                                                        {
                                                            _3843 = false;
                                                            int _4334 = 0;
                                                            for (;;)
                                                            {
                                                                bool _4346_ladder_break = false;
                                                                {
                                                                    if (!(_4334 < f.levels.x))
                                                                    {
                                                                        _4346_ladder_break = true;
                                                                    }
                                                                    else
                                                                    {
                                                                        vec3 _4362 = (_3945 - f.origin.data[_4334].xyz) / vec3(f.origin.data[_4334].w);
                                                                        float _4366 = float(f.levels.y) - 0.5;
                                                                        if (any(lessThan(_4362, vec3(0.5))))
                                                                        {
                                                                            _4335 = true;
                                                                        }
                                                                        else
                                                                        {
                                                                            _4335 = any(greaterThan(_4362, vec3(_4366)));
                                                                        }
                                                                        if (!(_4335))
                                                                        {
                                                                            _3843 = true;
                                                                            float _4477 = ((textureLod(_4772, vec3(_4362.x / float(f.levels.y), _4362.y / float(f.levels.y), ((float(_4334) * float(f.levels.y)) + _4362.z) / float(f.levels.y * f.levels.x)), 0.0).x * 2.0) - 1.0) * f.range[_4334];
                                                                            vec3 _4381 = _4362 - vec3(0.5);
                                                                            vec3 _4383 = vec3(_4366) - _4362;
                                                                            bvec3 _4974 = isnan(_4381);
                                                                            bvec3 _4975 = isnan(_4383);
                                                                            vec3 _4976 = min(_4381, _4383);
                                                                            vec3 _4977 = vec3(_4974.x ? _4383.x : _4976.x, _4974.y ? _4383.y : _4976.y, _4974.z ? _4383.z : _4976.z);
                                                                            vec3 _4384 = vec3(_4975.x ? _4381.x : _4977.x, _4975.y ? _4381.y : _4977.y, _4975.z ? _4381.z : _4977.z);
                                                                            float _4385 = _4384.x;
                                                                            float _4386 = _4384.y;
                                                                            float _4387 = _4384.z;
                                                                            float _4388 = isnan(_4387) ? _4386 : (isnan(_4386) ? _4387 : min(_4386, _4387));
                                                                            float _4392 = clamp(1.0 - ((isnan(_4388) ? _4385 : (isnan(_4385) ? _4388 : min(_4385, _4388))) * 0.125), 0.0, 1.0);
                                                                            if (_4392 <= 0.0)
                                                                            {
                                                                                _4335 = true;
                                                                            }
                                                                            else
                                                                            {
                                                                                _4335 = (_4334 + 1) >= f.levels.x;
                                                                            }
                                                                            if (_4335)
                                                                            {
                                                                                _4332 = true;
                                                                                _4333 = _4477;
                                                                                _4346_ladder_break = true;
                                                                            }
                                                                            else
                                                                            {
                                                                                int _4406 = _4334 + 1;
                                                                                vec3 _4413 = (_3945 - f.origin.data[_4406].xyz) / vec3(f.origin.data[_4406].w);
                                                                                if (any(lessThan(_4413, vec3(0.5))))
                                                                                {
                                                                                    _4335 = true;
                                                                                }
                                                                                else
                                                                                {
                                                                                    _4335 = any(greaterThan(_4413, vec3(_4366)));
                                                                                }
                                                                                if (_4335)
                                                                                {
                                                                                    _4332 = true;
                                                                                    _4333 = _4477;
                                                                                    _4346_ladder_break = true;
                                                                                }
                                                                                else
                                                                                {
                                                                                    _4332 = true;
                                                                                    _4333 = mix(_4477, ((textureLod(_4772, vec3(_4413.x / float(f.levels.y), _4413.y / float(f.levels.y), ((float(_4406) * float(f.levels.y)) + _4413.z) / float(f.levels.y * f.levels.x)), 0.0).x * 2.0) - 1.0) * f.range[_4406], _4392);
                                                                                    _4346_ladder_break = true;
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                                if (_4346_ladder_break)
                                                                {
                                                                    break;
                                                                }
                                                                _4334++;
                                                                continue;
                                                            }
                                                            if (!(_4332))
                                                            {
                                                                _4332 = true;
                                                                _4333 = 1000000.0;
                                                            }
                                                        }
                                                        _3839 = true;
                                                        float _3845 = 0.0;
                                                        int _3847 = 0;
                                                        float _3846 = _3939;
                                                        for (;;)
                                                        {
                                                            bool _3949_ladder_break = false;
                                                            {
                                                                if (_3847 < 64)
                                                                {
                                                                    _3840 = _3846 < _3940;
                                                                }
                                                                else
                                                                {
                                                                    _3840 = false;
                                                                }
                                                                if (!_3840)
                                                                {
                                                                    _3949_ladder_break = true;
                                                                }
                                                                else
                                                                {
                                                                    vec3 _3963 = _2071 + (rayDirection * _3846);
                                                                    _4518 = false;
                                                                    {
                                                                        _3848 = false;
                                                                        _3849 = f.origin.data[0].w;
                                                                        int _4520 = 0;
                                                                        for (;;)
                                                                        {
                                                                            bool _4532_ladder_break = false;
                                                                            {
                                                                                if (!(_4520 < f.levels.x))
                                                                                {
                                                                                    _4532_ladder_break = true;
                                                                                }
                                                                                else
                                                                                {
                                                                                    vec3 _4548 = (_3963 - f.origin.data[_4520].xyz) / vec3(f.origin.data[_4520].w);
                                                                                    float _4552 = float(f.levels.y) - 0.5;
                                                                                    if (any(lessThan(_4548, vec3(0.5))))
                                                                                    {
                                                                                        _4521 = true;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        _4521 = any(greaterThan(_4548, vec3(_4552)));
                                                                                    }
                                                                                    if (!(_4521))
                                                                                    {
                                                                                        _3848 = true;
                                                                                        float _4663 = ((textureLod(_4772, vec3(_4548.x / float(f.levels.y), _4548.y / float(f.levels.y), ((float(_4520) * float(f.levels.y)) + _4548.z) / float(f.levels.y * f.levels.x)), 0.0).x * 2.0) - 1.0) * f.range[_4520];
                                                                                        _3849 = f.origin.data[_4520].w;
                                                                                        vec3 _4567 = _4548 - vec3(0.5);
                                                                                        vec3 _4569 = vec3(_4552) - _4548;
                                                                                        bvec3 _4989 = isnan(_4567);
                                                                                        bvec3 _4990 = isnan(_4569);
                                                                                        vec3 _4991 = min(_4567, _4569);
                                                                                        vec3 _4992 = vec3(_4989.x ? _4569.x : _4991.x, _4989.y ? _4569.y : _4991.y, _4989.z ? _4569.z : _4991.z);
                                                                                        vec3 _4570 = vec3(_4990.x ? _4567.x : _4992.x, _4990.y ? _4567.y : _4992.y, _4990.z ? _4567.z : _4992.z);
                                                                                        float _4571 = _4570.x;
                                                                                        float _4572 = _4570.y;
                                                                                        float _4573 = _4570.z;
                                                                                        float _4574 = isnan(_4573) ? _4572 : (isnan(_4572) ? _4573 : min(_4572, _4573));
                                                                                        float _4578 = clamp(1.0 - ((isnan(_4574) ? _4571 : (isnan(_4571) ? _4574 : min(_4571, _4574))) * 0.125), 0.0, 1.0);
                                                                                        if (_4578 <= 0.0)
                                                                                        {
                                                                                            _4521 = true;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            _4521 = (_4520 + 1) >= f.levels.x;
                                                                                        }
                                                                                        if (_4521)
                                                                                        {
                                                                                            _4518 = true;
                                                                                            _4519 = _4663;
                                                                                            _4532_ladder_break = true;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            int _4592 = _4520 + 1;
                                                                                            vec3 _4599 = (_3963 - f.origin.data[_4592].xyz) / vec3(f.origin.data[_4592].w);
                                                                                            if (any(lessThan(_4599, vec3(0.5))))
                                                                                            {
                                                                                                _4521 = true;
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                _4521 = any(greaterThan(_4599, vec3(_4552)));
                                                                                            }
                                                                                            if (_4521)
                                                                                            {
                                                                                                _4518 = true;
                                                                                                _4519 = _4663;
                                                                                                _4532_ladder_break = true;
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                _3849 = mix(f.origin.data[_4520].w, f.origin.data[_4592].w, _4578);
                                                                                                _4518 = true;
                                                                                                _4519 = mix(_4663, ((textureLod(_4772, vec3(_4599.x / float(f.levels.y), _4599.y / float(f.levels.y), ((float(_4592) * float(f.levels.y)) + _4599.z) / float(f.levels.y * f.levels.x)), 0.0).x * 2.0) - 1.0) * f.range[_4592], _4578);
                                                                                                _4532_ladder_break = true;
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                            if (_4532_ladder_break)
                                                                            {
                                                                                break;
                                                                            }
                                                                            _4520++;
                                                                            continue;
                                                                        }
                                                                        if (!(_4518))
                                                                        {
                                                                            _4518 = true;
                                                                            _4519 = 1000000.0;
                                                                        }
                                                                    }
                                                                    if (!_3848)
                                                                    {
                                                                        _3835 = true;
                                                                        _3836 = false;
                                                                        _3949_ladder_break = true;
                                                                    }
                                                                    else
                                                                    {
                                                                        if (_3839)
                                                                        {
                                                                            if (_3845 <= 0.0)
                                                                            {
                                                                                _3850 = _3846 + (1.5 * _3849);
                                                                            }
                                                                            else
                                                                            {
                                                                                _3850 = _3845;
                                                                            }
                                                                            if (_4519 <= 0.0)
                                                                            {
                                                                                _3851 = _3846 < _3850;
                                                                            }
                                                                            else
                                                                            {
                                                                                _3851 = false;
                                                                            }
                                                                            if (_3851)
                                                                            {
                                                                                _3846 += (_3849 * 0.25);
                                                                            }
                                                                            else
                                                                            {
                                                                                _3851 = false;
                                                                                float _4008 = 0.25 * _3849;
                                                                                if (_3841)
                                                                                {
                                                                                    _3852 = _4147 + ((_3846 - _3939) * _2075);
                                                                                }
                                                                                else
                                                                                {
                                                                                    _3852 = originLift + (_3846 * _2075);
                                                                                }
                                                                                float _4021 = _1004 - _3846;
                                                                                bool _4022 = sunlit <= 0.0;
                                                                                if (_4022)
                                                                                {
                                                                                    _3853 = 1000000000.0;
                                                                                }
                                                                                else
                                                                                {
                                                                                    if (_3843)
                                                                                    {
                                                                                        _3837 = _4333 + ((_3940 - _3846) * sunlit);
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        _3837 = _4021 * sunlit;
                                                                                    }
                                                                                    _3853 = _3837;
                                                                                }
                                                                                if (_4022)
                                                                                {
                                                                                    _3854 = _4021 < (1.5 * _3849);
                                                                                }
                                                                                else
                                                                                {
                                                                                    _3854 = false;
                                                                                }
                                                                                bool _4042 = _4519 < ((0.5 * _3849) * clamp(_3846 / (2.0 * _3849), 0.0, 1.0));
                                                                                if (_4042)
                                                                                {
                                                                                    if (_3854)
                                                                                    {
                                                                                        _3855 = true;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        _3855 = _4519 >= (_3852 - _4008);
                                                                                    }
                                                                                    if (_3855)
                                                                                    {
                                                                                        _3856 = true;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        _3856 = _4519 >= (_3853 - (0.25 * _3849));
                                                                                    }
                                                                                    _3855 = _3856;
                                                                                }
                                                                                else
                                                                                {
                                                                                    _3855 = false;
                                                                                }
                                                                                if (_3855)
                                                                                {
                                                                                    nearMiss = 1.0;
                                                                                }
                                                                                if (!_3854)
                                                                                {
                                                                                    _3856 = _4042;
                                                                                }
                                                                                else
                                                                                {
                                                                                    _3856 = false;
                                                                                }
                                                                                if (_3856)
                                                                                {
                                                                                    _3857 = _4519 < (_3852 - _4008);
                                                                                }
                                                                                else
                                                                                {
                                                                                    _3857 = false;
                                                                                }
                                                                                if (_3857)
                                                                                {
                                                                                    _3858 = _4519 < (_3853 - (0.25 * _3849));
                                                                                }
                                                                                else
                                                                                {
                                                                                    _3858 = false;
                                                                                }
                                                                                if (_3858)
                                                                                {
                                                                                    t = _3846;
                                                                                    _3835 = true;
                                                                                    _3836 = true;
                                                                                    _3949_ladder_break = true;
                                                                                }
                                                                                else
                                                                                {
                                                                                    float _4092 = _3849 * 0.25;
                                                                                    _3839 = _3851;
                                                                                    _3846 += (isnan(_4092) ? _4519 : (isnan(_4519) ? _4092 : max(_4519, _4092)));
                                                                                }
                                                                            }
                                                                        }
                                                                        else
                                                                        {
                                                                            _3851 = _3839;
                                                                            _3850 = _3845;
                                                                            float _4008 = 0.25 * _3849;
                                                                            if (_3841)
                                                                            {
                                                                                _3852 = _4147 + ((_3846 - _3939) * _2075);
                                                                            }
                                                                            else
                                                                            {
                                                                                _3852 = originLift + (_3846 * _2075);
                                                                            }
                                                                            float _4021 = _1004 - _3846;
                                                                            bool _4022 = sunlit <= 0.0;
                                                                            if (_4022)
                                                                            {
                                                                                _3853 = 1000000000.0;
                                                                            }
                                                                            else
                                                                            {
                                                                                if (_3843)
                                                                                {
                                                                                    _3837 = _4333 + ((_3940 - _3846) * sunlit);
                                                                                }
                                                                                else
                                                                                {
                                                                                    _3837 = _4021 * sunlit;
                                                                                }
                                                                                _3853 = _3837;
                                                                            }
                                                                            if (_4022)
                                                                            {
                                                                                _3854 = _4021 < (1.5 * _3849);
                                                                            }
                                                                            else
                                                                            {
                                                                                _3854 = false;
                                                                            }
                                                                            bool _4042 = _4519 < ((0.5 * _3849) * clamp(_3846 / (2.0 * _3849), 0.0, 1.0));
                                                                            if (_4042)
                                                                            {
                                                                                if (_3854)
                                                                                {
                                                                                    _3855 = true;
                                                                                }
                                                                                else
                                                                                {
                                                                                    _3855 = _4519 >= (_3852 - _4008);
                                                                                }
                                                                                if (_3855)
                                                                                {
                                                                                    _3856 = true;
                                                                                }
                                                                                else
                                                                                {
                                                                                    _3856 = _4519 >= (_3853 - (0.25 * _3849));
                                                                                }
                                                                                _3855 = _3856;
                                                                            }
                                                                            else
                                                                            {
                                                                                _3855 = false;
                                                                            }
                                                                            if (_3855)
                                                                            {
                                                                                nearMiss = 1.0;
                                                                            }
                                                                            if (!_3854)
                                                                            {
                                                                                _3856 = _4042;
                                                                            }
                                                                            else
                                                                            {
                                                                                _3856 = false;
                                                                            }
                                                                            if (_3856)
                                                                            {
                                                                                _3857 = _4519 < (_3852 - _4008);
                                                                            }
                                                                            else
                                                                            {
                                                                                _3857 = false;
                                                                            }
                                                                            if (_3857)
                                                                            {
                                                                                _3858 = _4519 < (_3853 - (0.25 * _3849));
                                                                            }
                                                                            else
                                                                            {
                                                                                _3858 = false;
                                                                            }
                                                                            if (_3858)
                                                                            {
                                                                                t = _3846;
                                                                                _3835 = true;
                                                                                _3836 = true;
                                                                                _3949_ladder_break = true;
                                                                            }
                                                                            else
                                                                            {
                                                                                float _4092 = _3849 * 0.25;
                                                                                _3839 = _3851;
                                                                                _3846 += (isnan(_4092) ? _4519 : (isnan(_4519) ? _4092 : max(_4519, _4092)));
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                            if (_3949_ladder_break)
                                                            {
                                                                break;
                                                            }
                                                            _3845 = _3850;
                                                            _3847++;
                                                            continue;
                                                        }
                                                        if (!(_3835))
                                                        {
                                                            _3835 = true;
                                                            _3836 = false;
                                                        }
                                                    }
                                                }
                                            }
                                            if (!_3836)
                                            {
                                                sourceWidth = visibleSum + 1.0;
                                                blocked_1 = blocked;
                                                penumbraSum_1 = penumbraSum;
                                            }
                                            else
                                            {
                                                if (onRect)
                                                {
                                                    sourceWidth = length(p.lampRect.data[chosen[k]].xyz) + p.lampRect.data[chosen[k]].w;
                                                }
                                                else
                                                {
                                                    sourceWidth = 2.0 * _885;
                                                }
                                                float _2729 = sourceWidth;
                                                float _2732 = _1004 - t;
                                                sourceWidth = visibleSum;
                                                blocked_1 = blocked + 1.0;
                                                penumbraSum_1 = penumbraSum + ((_2729 * t) / (isnan(0.0500000007450580596923828125) ? _2732 : (isnan(_2732) ? 0.0500000007450580596923828125 : max(_2732, 0.0500000007450580596923828125))));
                                            }
                                            visibleSum = sourceWidth;
                                            fieldRays += 1.0;
                                            nearMissSum += nearMiss;
                                        }
                                    }
                                }
                            }
                            if (_179_ladder_break)
                            {
                                break;
                            }
                            k++;
                            blocked = blocked_1;
                            penumbraSum = penumbraSum_1;
                            continue;
                        }
                        if (blocked > 0.0)
                        {
                            penumbra = clamp(penumbraSum / blocked, 0.00200000009499490261077880859375, 1.0);
                        }
                        else
                        {
                            penumbra = 0.00200000009499490261077880859375;
                        }
                        if (f.levels.z == 2)
                        {
                            imageStore(uVisibility, ivec2(gl_GlobalInvocationID.xy), vec4(mappedLitSum * 0.5, 0.00200000009499490261077880859375 + (fieldRays * 0.5), 0.0, 0.0));
                        }
                        else
                        {
                            if (f.levels.z != 0)
                            {
                                float _2794 = nearMissSum * 0.5;
                                imageStore(uVisibility, ivec2(gl_GlobalInvocationID.xy), vec4(blocked * 0.5, isnan(0.00200000009499490261077880859375) ? _2794 : (isnan(_2794) ? 0.00200000009499490261077880859375 : max(_2794, 0.00200000009499490261077880859375)), 0.0, 0.0));
                            }
                            else
                            {
                                if (rawNoise)
                                {
                                    frame = _379;
                                }
                                else
                                {
                                    frame = 0.0;
                                }
                                imageStore(uVisibility, ivec2(gl_GlobalInvocationID.xy), vec4(visibleSum * 0.5, penumbra, frame, 0.0));
                            }
                        }
                    }
                }
            }
        }
    }
}

