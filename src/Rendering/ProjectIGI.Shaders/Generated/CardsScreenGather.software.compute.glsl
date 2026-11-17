#version 430
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

struct _Array_std140_vector_float_4_4
{
    vec4 data[4];
};

struct _Array_std140_vector_float_4_7
{
    vec4 data[7];
};

struct _Array_std140_float4
{
    float data[4];
};

float _7309;

layout(binding = 0, std140) uniform SLANG_ParameterGroup_Globals_std140
{
    _Array_std140_vector_float_4_4 uClipmapOrigin;
    _Array_std140_vector_float_4_7 uSkySh;
    vec4 uUnproject;
    vec3 uViewToWorld0;
    vec3 uViewToWorld1;
    vec3 uViewToWorld2;
    vec3 uCameraToCache;
    vec3 uTraceOrigin;
    vec3 uAtlasSize;
    vec3 uLookupMin;
    vec3 uSkyColour;
    vec3 uGroundSun;
    _Array_std140_float4 uClipmapRange;
    int uShadowLevels;
    int uShadowResolution;
    int uLookupBuckets;
    float uLookupCell;
    int uScreenWidth;
    int uScreenHeight;
    int uProbeStep;
    float uMaxRayIntensity;
    int uScreenTraceSteps;
    float uScreenTraceDistance;
    float uScreenThickness;
    int uSkyShValid;
    float uBounceScale;
    int uDebugSource;
    int uFrame;
    vec3 uColourWorldToView0;
    vec3 uColourWorldToView1;
    vec3 uColourWorldToView2;
    vec3 uColourCameraToCache;
    vec4 uTerrainMap0;
    vec4 uTerrainMap1;
    vec4 uShelterMap0;
    vec4 uShelterMap1;
    vec4 uShelterMap2;
} Globals;

layout(binding = 1, std430) restrict buffer RWStructuredBuffer
{
    ivec2 _member0[];
} uCells;

layout(binding = 2, std430) restrict buffer uCellPages
{
    int _member0[];
} uCellPages_1;

layout(binding = 0, std430) restrict readonly buffer StructuredBuffer
{
    vec4 _member0[];
} uPages;

layout(binding = 0, rgba16f) uniform restrict writeonly image2D uIndirect;
layout(binding = 5) uniform sampler2D _7314;
layout(binding = 6) uniform sampler2D _7316;
layout(binding = 7) uniform sampler2D _7318;
layout(binding = 3) uniform sampler3D _7320;
layout(binding = 8) uniform sampler2D _7323;
layout(binding = 0) uniform sampler2D _7326;
layout(binding = 1) uniform sampler2D _7328;
layout(binding = 2) uniform sampler2D _7330;
layout(binding = 4) uniform sampler2D _7332;
layout(binding = 9) uniform sampler2D _7335;

void main()
{
    bool _5735 = false;
    bool _5637 = false;
    bool _5539 = false;
    bool _5441 = false;
    bool _5343 = false;
    bool _5245 = false;
    bool _5147 = false;
    bool _4174 = false;
    bool _4064 = false;
    bool _3983 = false;
    {
        ivec2 _82 = ivec2(gl_GlobalInvocationID.xy);
        ivec2 grid = (ivec2(Globals.uScreenWidth, Globals.uScreenHeight) + ivec2(Globals.uProbeStep - 1)) / ivec2(Globals.uProbeStep);
        bool _66;
        if (_82.x >= grid.x)
        {
            _66 = true;
        }
        else
        {
            _66 = _82.y >= grid.y;
        }
        if (!(_66))
        {
            vec2 uv = (vec2(min(((_82 * ivec2(Globals.uProbeStep)) + ivec2(Globals.uProbeStep / 2)), (ivec2(Globals.uScreenWidth, Globals.uScreenHeight) - ivec2(1)))) + vec2(0.5)) / vec2(float(Globals.uScreenWidth), float(Globals.uScreenHeight));
            vec4 _3115 = textureLod(_7314, uv, 0.0);
            float _3116 = _3115.x;
            if (_3116 <= 0.0)
            {
                imageStore(uIndirect, ivec2(gl_GlobalInvocationID.xy), vec4(0.0));
            }
            else
            {
                float _3135 = ((2.0 * Globals.uUnproject.z) * Globals.uUnproject.w) / ((Globals.uUnproject.w + Globals.uUnproject.z) - ((1.0 - (2.0 * _3116)) * (Globals.uUnproject.w - Globals.uUnproject.z)));
                vec2 _3138 = (uv * 2.0) - vec2(1.0);
                vec3 _3150 = vec3((_3138.x * _3135) / Globals.uUnproject.x, ((-1.0) * (_3138.y * _3135)) / Globals.uUnproject.y, _3135);
                vec3 world = ((Globals.uCameraToCache + (Globals.uViewToWorld0 * _3150.x)) + (Globals.uViewToWorld1 * _3150.y)) + (Globals.uViewToWorld2 * _3150.z);
                vec3 _240 = normalize((textureLod(_7316, uv, 0.0).xyz * 2.0) - vec3(1.0));
                vec3 worldNormal;
                if (dot(_240, world - Globals.uCameraToCache) > 0.0)
                {
                    worldNormal = -_240;
                }
                else
                {
                    worldNormal = _240;
                }
                vec3 _3152;
                {
                    bool _3153;
                    if (Globals.uShadowLevels <= 0)
                    {
                        _3153 = true;
                    }
                    else
                    {
                        _3153 = Globals.uLookupBuckets <= 0;
                    }
                    if (_3153)
                    {
                        _3152 = vec3(0.0);
                    }
                    else
                    {
                        vec3 _7262;
                        vec3 _7263;
                        vec3 _7264;
                        {
                            vec3 _7277 = worldNormal;
                            if (worldNormal.z < (-0.99999988079071044921875))
                            {
                                _7262 = vec3(0.0, -1.0, 0.0);
                                _7263 = vec3(-1.0, 0.0, 0.0);
                                _7264 = _7277;
                            }
                            else
                            {
                                float _3572 = 1.0 / (1.0 + worldNormal.z);
                                float _3574 = -worldNormal.x;
                                float _3577 = (_3574 * worldNormal.y) * _3572;
                                _7262 = vec3(1.0 - ((worldNormal.x * worldNormal.x) * _3572), _3577, _3574);
                                _7263 = vec3(_3577, 1.0 - ((worldNormal.y * worldNormal.y) * _3572), -worldNormal.y);
                                _7264 = _7277;
                            }
                        }
                        vec3 _3603 = vec3(dot(Globals.uViewToWorld0, worldNormal), dot(Globals.uViewToWorld1, worldNormal), dot(Globals.uViewToWorld2, worldNormal));
                        int _3154 = 0;
                        vec3 _3155 = vec3(0.0);
                        float _3158 = 0.0;
                        float _3159 = 0.0;
                        vec3 _3156 = vec3(0.0);
                        float _3160 = 0.0;
                        vec3 _3157 = vec3(0.0);
                        float _3161 = 0.0;
                        vec3 _3162;
                        int _3164;
                        vec3 _3165;
                        bool _3166;
                        int _3167;
                        vec3 _3168;
                        vec3 _3169;
                        vec3 _3170;
                        vec3 _3171;
                        float _3172;
                        float _3173;
                        float _3174;
                        float _3175;
                        vec3 _3176;
                        bool _3177;
                        bool _3178;
                        int _3179;
                        vec3 _3180;
                        float _3181;
                        vec3 _3182;
                        vec2 _3184;
                        bool _3186;
                        float _3187;
                        vec3 _3188;
                        bool _3189;
                        bool _3633;
                        bool _3634;
                        vec3 _3635;
                        float _3638;
                        bool _3639;
                        vec3 _3965;
                        float _3984;
                        bool _3987;
                        bool _3988;
                        float _3990;
                        float _4065;
                        bool _4067;
                        float _4175;
                        bool _4176;
                        float _4294;
                        bool _4319;
                        float _4357;
                        float _4382;
                        bool _4407;
                        float _4445;
                        bool _4475;
                        ivec2 _4480;
                        bool _4491;
                        bool _4492;
                        vec3 _4494[4];
                        float _4497;
                        ivec2 _4862;
                        vec3 _4959;
                        vec3 _4978;
                        vec3 _5030;
                        vec3 _5081;
                        vec3 _5100;
                        bool _5101;
                        float _5103;
                        vec3 _5107;
                        bool _5150;
                        float _5246;
                        bool _5248;
                        float _5344;
                        bool _5346;
                        float _5442;
                        bool _5444;
                        float _5540;
                        bool _5542;
                        float _5638;
                        bool _5640;
                        float _5736;
                        bool _5738;
                        bool _5834;
                        bool _5900;
                        float _5938;
                        bool _5963;
                        bool _5979;
                        bool _6045;
                        float _6083;
                        bool _6108;
                        bool _6128;
                        ivec2 _6133;
                        bool _6144;
                        bool _6145;
                        vec3 _6147[4];
                        float _6150;
                        ivec2 _6515;
                        bool _6617;
                        bool _6623;
                        ivec2 _6624;
                        bool _6628;
                        bool _6637;
                        bool _6638;
                        bool _6639;
                        bool _6640;
                        bool _6641;
                        ivec2 _6871;
                        vec3 _6968;
                        vec3 _6986;
                        vec3 _7004;
                        for (;;)
                        {
                            if (!(_3154 < 16))
                            {
                                break;
                            }
                            vec2 _3224 = (vec2(float(_3154 - 4 * (_3154 / 4)), float(_3154 / 4)) + vec2(0.5)) * vec2(0.25);
                            float _3226 = 6.283185482025146484375 * _3224.x;
                            float _3228 = sqrt(_3224.y);
                            float _3230 = 1.0 - (_3228 * _3228);
                            float _3232 = sqrt(isnan(_3230) ? 0.0 : (isnan(0.0) ? _3230 : max(0.0, _3230)));
                            vec3 _3619 = ((_7262 * (_3232 * cos(_3226))) + (_7263 * (_3232 * sin(_3226)))) + (_7264 * _3228);
                            if (Globals.uScreenTraceSteps > 0)
                            {
                                vec3 _3631 = vec3(dot(Globals.uViewToWorld0, _3619), dot(Globals.uViewToWorld1, _3619), dot(Globals.uViewToWorld2, _3619));
                                {
                                    _3165 = vec3(0.0);
                                    if (Globals.uScreenTraceSteps <= 0)
                                    {
                                        _3634 = true;
                                    }
                                    else
                                    {
                                        _3634 = _3631.z == 0.0;
                                    }
                                    if (_3634)
                                    {
                                        _3633 = false;
                                    }
                                    else
                                    {
                                        vec3 _3657 = _3150 + (_3603 * 0.0199999995529651641845703125);
                                        vec3 _3661 = _3657 + (_3631 * Globals.uScreenTraceDistance);
                                        if (_3661.z < (Globals.uUnproject.z + 0.00999999977648258209228515625))
                                        {
                                            _3635 = _3657 + (_3631 * (((Globals.uUnproject.z + 0.00999999977648258209228515625) - _3657.z) / _3631.z));
                                        }
                                        else
                                        {
                                            _3635 = _3661;
                                        }
                                        if (_3635.z <= Globals.uUnproject.z)
                                        {
                                            _3633 = false;
                                        }
                                        else
                                        {
                                            vec2 _3859 = (vec2((_3657.x * Globals.uUnproject.x) / _3657.z, ((-1.0) * (_3657.y * Globals.uUnproject.y)) / _3657.z) * 0.5) + vec2(0.5);
                                            vec2 _3690 = ((vec2((_3635.x * Globals.uUnproject.x) / _3635.z, ((-1.0) * (_3635.y * Globals.uUnproject.y)) / _3635.z) * 0.5) + vec2(0.5)) - _3859;
                                            int _3705 = int(clamp(length(_3690 / (vec2(1.0) / vec2(float(Globals.uScreenWidth), float(Globals.uScreenHeight)))), 1.0, float(Globals.uScreenTraceSteps)));
                                            float _3707 = 1.0 / float(_3705);
                                            float _3711 = fract(sin(dot(_3859, vec2(12.98980045318603515625, 78.233001708984375))) * 43758.546875);
                                            float _3636 = 0.0;
                                            int _3637 = 1;
                                            for (;;)
                                            {
                                                if (!(_3637 <= 256))
                                                {
                                                    _3638 = -1.0;
                                                    break;
                                                }
                                                if (_3637 > _3705)
                                                {
                                                    _3638 = -1.0;
                                                    break;
                                                }
                                                float _3728 = _3707 * (float(_3637) + _3711);
                                                if (_3728 > 1.0)
                                                {
                                                    _3638 = -1.0;
                                                    break;
                                                }
                                                vec2 _3733 = _3859 + (_3690 * _3728);
                                                if (any(lessThan(_3733, vec2(0.0))))
                                                {
                                                    _3634 = true;
                                                }
                                                else
                                                {
                                                    _3634 = any(greaterThan(_3733, vec2(1.0)));
                                                }
                                                if (_3634)
                                                {
                                                    _3638 = -1.0;
                                                    break;
                                                }
                                                float _3900 = ((2.0 * Globals.uUnproject.z) * Globals.uUnproject.w) / ((Globals.uUnproject.w + Globals.uUnproject.z) - ((1.0 - (2.0 * textureLod(_7314, _3733, 0.0).x)) * (Globals.uUnproject.w - Globals.uUnproject.z)));
                                                vec2 _3903 = (_3733 * 2.0) - vec2(1.0);
                                                vec3 _3915 = vec3(_7309, _7309, _3900);
                                                float _3752 = _3915.z;
                                                float _3753 = (1.0 / mix(1.0 / _3657.z, 1.0 / _3635.z, _3728)) - _3752;
                                                if (_3753 > 0.0)
                                                {
                                                    _3639 = _3753 < (Globals.uScreenThickness + (_3752 * 0.0199999995529651641845703125));
                                                }
                                                else
                                                {
                                                    _3639 = false;
                                                }
                                                if (_3639)
                                                {
                                                    _3638 = _3636;
                                                    float _3640 = _3728;
                                                    int _3641 = 0;
                                                    for (;;)
                                                    {
                                                        if (!(_3641 < 4))
                                                        {
                                                            break;
                                                        }
                                                        float _3775 = _3640;
                                                        float _3777 = (_3638 + _3775) * 0.5;
                                                        vec2 _3783 = _3859 + (_3690 * _3777);
                                                        float _3937 = ((2.0 * Globals.uUnproject.z) * Globals.uUnproject.w) / ((Globals.uUnproject.w + Globals.uUnproject.z) - ((1.0 - (2.0 * textureLod(_7314, _3783, 0.0).x)) * (Globals.uUnproject.w - Globals.uUnproject.z)));
                                                        vec2 _3940 = (_3783 * 2.0) - vec2(1.0);
                                                        if (((1.0 / mix(1.0 / _3657.z, 1.0 / _3635.z, _3777)) - vec3(_7309, _7309, _3937).z) > 0.0)
                                                        {
                                                            _3640 = _3777;
                                                        }
                                                        else
                                                        {
                                                            _3638 = _3777;
                                                        }
                                                        _3641++;
                                                        continue;
                                                    }
                                                    _3638 = _3640;
                                                    break;
                                                }
                                                _3636 = _3728;
                                                _3637++;
                                                continue;
                                            }
                                            if (_3638 <= 0.0)
                                            {
                                                _3633 = false;
                                            }
                                            else
                                            {
                                                vec2 _3813 = _3859 + (_3690 * _3638);
                                                vec3 _3822 = (textureLod(_7316, _3813, 0.0).xyz * 2.0) - vec3(1.0);
                                                if (dot(vec3(dot(Globals.uViewToWorld0, _3822), dot(Globals.uViewToWorld1, _3822), dot(Globals.uViewToWorld2, _3822)), _3631) >= 0.0)
                                                {
                                                    _3633 = false;
                                                }
                                                else
                                                {
                                                    vec4 _3831 = textureLod(_7318, _3813, 0.0);
                                                    if (_3831.w < 0.5)
                                                    {
                                                        _3633 = false;
                                                    }
                                                    else
                                                    {
                                                        vec3 _3837 = _3831.xyz;
                                                        float _3968 = _3831.x;
                                                        float _3969 = _3831.y;
                                                        float _3970 = _3831.z;
                                                        float _3971 = isnan(_3970) ? _3969 : (isnan(_3969) ? _3970 : max(_3969, _3970));
                                                        float _3972 = isnan(_3971) ? _3968 : (isnan(_3968) ? _3971 : max(_3968, _3971));
                                                        if (_3972 > Globals.uMaxRayIntensity)
                                                        {
                                                            _3965 = _3837 * (Globals.uMaxRayIntensity / _3972);
                                                        }
                                                        else
                                                        {
                                                            _3965 = _3837;
                                                        }
                                                        _3165 = _3965;
                                                        _3633 = true;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                if (_3633)
                                {
                                    _3164 = 1;
                                    _3162 = _3165;
                                }
                                else
                                {
                                    _3164 = 0;
                                    _3162 = vec3(0.0);
                                }
                                _3153 = _3633;
                            }
                            else
                            {
                                _3153 = false;
                                _3164 = 0;
                                _3162 = vec3(0.0);
                            }
                            if (!_3153)
                            {
                                _3983 = false;
                                {
                                    _3176 = world;
                                    if (Globals.uShadowLevels <= 0)
                                    {
                                        _3983 = true;
                                        _3984 = 1.0;
                                    }
                                    else
                                    {
                                        vec3 _4007 = world + ((worldNormal * Globals.uClipmapOrigin.data[0].w) * 1.5);
                                        float _4018 = (Globals.uClipmapOrigin.data[0].w * float(Globals.uShadowResolution)) * float(1 << (Globals.uShadowLevels - 1));
                                        int _3985 = 0;
                                        float _3986 = 0.0;
                                        for (;;)
                                        {
                                            if (_3985 < 64)
                                            {
                                                _3987 = _3986 < _4018;
                                            }
                                            else
                                            {
                                                _3987 = false;
                                            }
                                            if (!_3987)
                                            {
                                                break;
                                            }
                                            vec3 _4035 = _4007 + (_3619 * _3986);
                                            _4064 = false;
                                            {
                                                _3988 = false;
                                                _3990 = Globals.uClipmapOrigin.data[0].w;
                                                int _4066 = 0;
                                                for (;;)
                                                {
                                                    bool _4078_ladder_break = false;
                                                    {
                                                        if (!(_4066 < Globals.uShadowLevels))
                                                        {
                                                            _4078_ladder_break = true;
                                                        }
                                                        else
                                                        {
                                                            vec3 _4093 = (_4035 - Globals.uClipmapOrigin.data[_4066].xyz) / vec3(Globals.uClipmapOrigin.data[_4066].w);
                                                            if (any(lessThan(_4093, vec3(0.5))))
                                                            {
                                                                _4067 = true;
                                                            }
                                                            else
                                                            {
                                                                _4067 = any(greaterThan(_4093, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                            }
                                                            if (!(_4067))
                                                            {
                                                                _3988 = true;
                                                                _3990 = Globals.uClipmapOrigin.data[_4066].w;
                                                                _4064 = true;
                                                                _4065 = ((textureLod(_7320, vec3(_4093.x / float(Globals.uShadowResolution), _4093.y / float(Globals.uShadowResolution), ((float(_4066) * float(Globals.uShadowResolution)) + _4093.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_4066];
                                                                _4078_ladder_break = true;
                                                            }
                                                        }
                                                    }
                                                    if (_4078_ladder_break)
                                                    {
                                                        break;
                                                    }
                                                    _4066++;
                                                    continue;
                                                }
                                                if (!(_4064))
                                                {
                                                    _4064 = true;
                                                    _4065 = 1000000.0;
                                                }
                                            }
                                            if (!_3988)
                                            {
                                                _3983 = true;
                                                _3984 = 1.0;
                                                break;
                                            }
                                            float _4165 = 2.0 * _3990;
                                            float _4169 = (0.5 * _3990) * clamp(_3986 / (isnan(9.9999999747524270787835121154785e-07) ? _4165 : (isnan(_4165) ? 9.9999999747524270787835121154785e-07 : max(_4165, 9.9999999747524270787835121154785e-07))), 0.0, 1.0);
                                            float _4171 = (_3986 + _4065) - _4169;
                                            float _3991 = isnan(0.0) ? _4171 : (isnan(_4171) ? 0.0 : max(_4171, 0.0));
                                            if (_4065 < _4169)
                                            {
                                                _3176 = _4007 + (_3619 * _3991);
                                                _3983 = true;
                                                _3984 = 0.0;
                                                break;
                                            }
                                            float _4050 = _3990 * 0.25;
                                            _3985++;
                                            _3986 += (isnan(_4050) ? _4065 : (isnan(_4065) ? _4050 : max(_4065, _4050)));
                                            continue;
                                        }
                                        if (!(_3983))
                                        {
                                            _3983 = true;
                                            _3984 = 1.0;
                                        }
                                    }
                                }
                                bool _3263 = _3984 <= 0.5;
                                vec3 _3265 = world + (worldNormal * 0.100000001490116119384765625);
                                vec3 _3268 = _3265 + Globals.uTraceOrigin;
                                _4174 = false;
                                {
                                    if (Globals.uTerrainMap0.w < 0.5)
                                    {
                                        _4176 = true;
                                    }
                                    else
                                    {
                                        _4176 = _3619.z > (-0.00999999977648258209228515625);
                                    }
                                    if (_4176)
                                    {
                                        _4176 = true;
                                    }
                                    else
                                    {
                                        _4176 = Globals.uTerrainMap0.z <= 0.0;
                                    }
                                    if (_4176)
                                    {
                                        _4174 = true;
                                        _4175 = -1.0;
                                    }
                                    else
                                    {
                                        float _4205 = 0.5 / Globals.uTerrainMap0.z;
                                        float _4177 = 0.0;
                                        int _4178 = 1;
                                        for (;;)
                                        {
                                            if (!(_4178 <= 64))
                                            {
                                                break;
                                            }
                                            float _4216 = float(_4178) * _4205;
                                            float _4217 = isnan(32.0) ? _4216 : (isnan(_4216) ? 32.0 : min(_4216, 32.0));
                                            vec3 _4219 = _3268 + (_3619 * _4217);
                                            float _7240 = Globals.uTerrainMap1.z;
                                            float _7241 = Globals.uTerrainMap1.w;
                                            vec2 _7242 = Globals.uTerrainMap1.xy;
                                            ivec2 _4318 = ivec2(floor((_4219.xy - Globals.uTerrainMap0.xy) * Globals.uTerrainMap0.z));
                                            if (Globals.uTerrainMap0.w > 0.5)
                                            {
                                                _4319 = _4318.x >= 0;
                                            }
                                            else
                                            {
                                                _4319 = false;
                                            }
                                            if (_4319)
                                            {
                                                _4319 = _4318.y >= 0;
                                            }
                                            else
                                            {
                                                _4319 = false;
                                            }
                                            if (_4319)
                                            {
                                                _4319 = _4318.x < int(_7242.x);
                                            }
                                            else
                                            {
                                                _4319 = false;
                                            }
                                            if (_4319)
                                            {
                                                _4319 = _4318.y < int(_7242.y);
                                            }
                                            else
                                            {
                                                _4319 = false;
                                            }
                                            if (_4319)
                                            {
                                                vec4 _4304 = texelFetch(_7323, ivec3(_4318, 0).xy, 0);
                                                float _4369 = floor((_4304.z * 255.0) + 0.5) + (floor((_4304.y * 255.0) + 0.5) * 256.0);
                                                if (_4369 < 0.5)
                                                {
                                                    _4357 = -1000000015047466219876688855040.0;
                                                }
                                                else
                                                {
                                                    _4357 = _7240 + ((_4369 - 1.0) * _7241);
                                                }
                                                _4294 = _4357;
                                            }
                                            else
                                            {
                                                _4294 = -1000000015047466219876688855040.0;
                                            }
                                            if (_4219.z <= _4294)
                                            {
                                                float _4180 = _4177;
                                                float _4181 = _4217;
                                                int _4182 = 0;
                                                for (;;)
                                                {
                                                    if (!(_4182 < 4))
                                                    {
                                                        break;
                                                    }
                                                    float _4235 = _4181;
                                                    float _4237 = (_4180 + _4235) * 0.5;
                                                    vec3 _4239 = _3268 + (_3619 * _4237);
                                                    float _7252 = Globals.uTerrainMap1.z;
                                                    float _7253 = Globals.uTerrainMap1.w;
                                                    vec2 _7254 = Globals.uTerrainMap1.xy;
                                                    ivec2 _4406 = ivec2(floor((_4239.xy - Globals.uTerrainMap0.xy) * Globals.uTerrainMap0.z));
                                                    if (Globals.uTerrainMap0.w > 0.5)
                                                    {
                                                        _4407 = _4406.x >= 0;
                                                    }
                                                    else
                                                    {
                                                        _4407 = false;
                                                    }
                                                    if (_4407)
                                                    {
                                                        _4407 = _4406.y >= 0;
                                                    }
                                                    else
                                                    {
                                                        _4407 = false;
                                                    }
                                                    if (_4407)
                                                    {
                                                        _4407 = _4406.x < int(_7254.x);
                                                    }
                                                    else
                                                    {
                                                        _4407 = false;
                                                    }
                                                    if (_4407)
                                                    {
                                                        _4407 = _4406.y < int(_7254.y);
                                                    }
                                                    else
                                                    {
                                                        _4407 = false;
                                                    }
                                                    if (_4407)
                                                    {
                                                        vec4 _4392 = texelFetch(_7323, ivec3(_4406, 0).xy, 0);
                                                        float _4457 = floor((_4392.z * 255.0) + 0.5) + (floor((_4392.y * 255.0) + 0.5) * 256.0);
                                                        if (_4457 < 0.5)
                                                        {
                                                            _4445 = -1000000015047466219876688855040.0;
                                                        }
                                                        else
                                                        {
                                                            _4445 = _7252 + ((_4457 - 1.0) * _7253);
                                                        }
                                                        _4382 = _4445;
                                                    }
                                                    else
                                                    {
                                                        _4382 = -1000000015047466219876688855040.0;
                                                    }
                                                    if (_4239.z <= _4382)
                                                    {
                                                        _4181 = _4237;
                                                    }
                                                    else
                                                    {
                                                        _4180 = _4237;
                                                    }
                                                    _4182++;
                                                    continue;
                                                }
                                                _4174 = true;
                                                _4175 = _4181;
                                                break;
                                            }
                                            if (_4217 >= 32.0)
                                            {
                                                break;
                                            }
                                            _4177 = _4217;
                                            _4178++;
                                            continue;
                                        }
                                        if (!(_4174))
                                        {
                                            _4174 = true;
                                            _4175 = -1.0;
                                        }
                                    }
                                }
                                if (_4175 >= 0.0)
                                {
                                    if (!_3263)
                                    {
                                        _3166 = true;
                                    }
                                    else
                                    {
                                        _3166 = length(_3176 - world) > _4175;
                                    }
                                }
                                else
                                {
                                    _3166 = false;
                                }
                                if (_3166)
                                {
                                    vec3 _3291 = _3265 + (_3619 * _4175);
                                    float _3297 = 0.5 * Globals.uClipmapOrigin.data[0].w;
                                    {
                                        _3182 = vec3(0.0);
                                        if (Globals.uLookupBuckets <= 0)
                                        {
                                            _4475 = false;
                                        }
                                        else
                                        {
                                            ivec3 _4514 = ivec3(floor((_3291 - Globals.uLookupMin) / vec3(Globals.uLookupCell)));
                                            int _4861 = int((((uint(_4514.x) * 2376512323u) ^ (uint(_4514.y) * 3625334849u)) ^ (uint(_4514.z) * 3407524639u)) & uint(Globals.uLookupBuckets - 1));
                                            uvec2 _4519 = uvec2(textureSize(_7326, 0));
                                            vec2 _4526 = vec2(float(_4519.x), float(_4519.y));
                                            int _4478 = 0;
                                            float _4479 = 0.0;
                                            for (;;)
                                            {
                                                if (!(_4478 <= uCells._member0[Globals.uLookupBuckets].y))
                                                {
                                                    break;
                                                }
                                                bool _4540 = _4478 == 0;
                                                if (_4540)
                                                {
                                                    _4480 = uCells._member0[_4861];
                                                }
                                                else
                                                {
                                                    int _4866 = uCells._member0[Globals.uLookupBuckets].x + ((_4478 - 1) * 6);
                                                    float _4883 = intBitsToFloat(uCellPages_1._member0[_4866 + 3]) + _3297;
                                                    vec3 _4884 = _3291 - vec3(intBitsToFloat(uCellPages_1._member0[_4866]), intBitsToFloat(uCellPages_1._member0[_4866 + 1]), intBitsToFloat(uCellPages_1._member0[_4866 + 2]));
                                                    if (dot(_4884, _4884) > (_4883 * _4883))
                                                    {
                                                        _4862 = ivec2(0);
                                                    }
                                                    else
                                                    {
                                                        _4862 = ivec2(uCellPages_1._member0[_4866 + 4], uCellPages_1._member0[_4866 + 5]);
                                                    }
                                                    _4480 = _4862;
                                                }
                                                int _4481 = 0;
                                                float _4482 = _4479;
                                                for (;;)
                                                {
                                                    bool _4551_ladder_break = false;
                                                    {
                                                        if (!(_4481 < _4480.y))
                                                        {
                                                            _4551_ladder_break = true;
                                                        }
                                                        else
                                                        {
                                                            int _4562 = _4480.x + _4481;
                                                            int _4565 = uCellPages_1._member0[_4562] * 10;
                                                            if (!((uPages._member0[_4565 + 5].w > 0.5) == _4540))
                                                            {
                                                                int _4574 = _4565 + 9;
                                                                vec3 _4578 = _3291 - uPages._member0[_4574].xyz;
                                                                float _4580 = uPages._member0[_4574].w + _3297;
                                                                if (!(dot(_4578, _4578) > (_4580 * _4580)))
                                                                {
                                                                    int _4900 = uCellPages_1._member0[_4562] * 10;
                                                                    vec4 _4489 = uPages._member0[_4900];
                                                                    vec4 _4490 = uPages._member0[_4900 + 1];
                                                                    int _4906 = _4900 + 2;
                                                                    int _4909 = _4900 + 3;
                                                                    int _4912 = _4900 + 4;
                                                                    int _4918 = _4900 + 6;
                                                                    int _4921 = _4900 + 7;
                                                                    int _4924 = _4900 + 8;
                                                                    vec3 _4931 = _3291 - vec3(uPages._member0[_4918].w, uPages._member0[_4921].w, uPages._member0[_4924].w);
                                                                    vec3 _4944 = vec3(dot(uPages._member0[_4918].xyz, _4931), dot(uPages._member0[_4921].xyz, _4931), dot(uPages._member0[_4924].xyz, _4931)) - uPages._member0[_4906].xyz;
                                                                    vec2 _4947 = vec2(uPages._member0[_4906].w, uPages._member0[_4909].w);
                                                                    bvec2 _7372 = isnan(_4947);
                                                                    bvec2 _7373 = isnan(vec2(9.9999999747524270787835121154785e-07));
                                                                    vec2 _7374 = max(_4947, vec2(9.9999999747524270787835121154785e-07));
                                                                    vec2 _7375 = vec2(_7372.x ? vec2(9.9999999747524270787835121154785e-07).x : _7374.x, _7372.y ? vec2(9.9999999747524270787835121154785e-07).y : _7374.y);
                                                                    vec2 _4948 = vec2(_7373.x ? _4947.x : _7375.x, _7373.y ? _4947.y : _7375.y);
                                                                    vec2 _4484 = _4948;
                                                                    vec2 _4483 = vec2(dot(_4944, uPages._member0[_4909].xyz), dot(_4944, uPages._member0[_4912].xyz)) / _4948;
                                                                    float _4485 = -dot(_4944, uPages._member0[_4900 + 5].xyz);
                                                                    float _4486 = uPages._member0[_4912].w;
                                                                    float _4589 = dot(uPages._member0[_4900 + 5].xyz, vec3(uPages._member0[_4918].z, uPages._member0[_4921].z, uPages._member0[_4924].z));
                                                                    if (!(_4589 <= 0.0))
                                                                    {
                                                                        float _4594 = Globals.uClipmapOrigin.data[0].w * 0.25;
                                                                        vec2 _4597 = vec2(_4594) / _4484;
                                                                        if (abs(_4483.x) > (1.0 + _4597.x))
                                                                        {
                                                                            _4491 = true;
                                                                        }
                                                                        else
                                                                        {
                                                                            _4491 = abs(_4483.y) > (1.0 + _4597.y);
                                                                        }
                                                                        if (!(_4491))
                                                                        {
                                                                            if (_4485 < (Globals.uClipmapOrigin.data[0].w * (-0.25)))
                                                                            {
                                                                                _4492 = true;
                                                                            }
                                                                            else
                                                                            {
                                                                                _4492 = _4485 > (_4486 + _4594);
                                                                            }
                                                                            if (!(_4492))
                                                                            {
                                                                                vec2 _4641 = (_4490.xy + (((clamp(_4483, vec2(-1.0), vec2(1.0)) * 0.5) + vec2(0.5)) * _4490.zw)) - vec2(0.5);
                                                                                vec2 _4642 = floor(_4641);
                                                                                vec2 _4643 = _4641 - _4642;
                                                                                bvec2 _7377 = isnan(_4490.zw);
                                                                                bvec2 _7378 = isnan(vec2(9.9999999747524270787835121154785e-07));
                                                                                vec2 _7379 = max(_4490.zw, vec2(9.9999999747524270787835121154785e-07));
                                                                                vec2 _7380 = vec2(_7377.x ? vec2(9.9999999747524270787835121154785e-07).x : _7379.x, _7377.y ? vec2(9.9999999747524270787835121154785e-07).y : _7379.y);
                                                                                vec2 _4649 = _4489.zw / vec2(_7378.x ? _4490.zw.x : _7380.x, _7378.y ? _4490.zw.y : _7380.y);
                                                                                float _4653 = _4485 / (isnan(9.9999999747524270787835121154785e-07) ? _4486 : (isnan(_4486) ? 9.9999999747524270787835121154785e-07 : max(_4486, 9.9999999747524270787835121154785e-07)));
                                                                                float _4655 = 0.5 * _4486;
                                                                                float _4657 = _3297 / (isnan(9.9999999747524270787835121154785e-07) ? _4655 : (isnan(_4655) ? 9.9999999747524270787835121154785e-07 : max(_4655, 9.9999999747524270787835121154785e-07)));
                                                                                vec4 _4493 = vec4(0.0);
                                                                                int _4496 = 0;
                                                                                for (;;)
                                                                                {
                                                                                    if (!(_4496 < 4))
                                                                                    {
                                                                                        break;
                                                                                    }
                                                                                    vec2 _4672 = vec2(float(_4496 & 1), float(_4496 >> 1));
                                                                                    vec2 _4675 = (_4642 + _4672) + vec2(0.5);
                                                                                    vec2 _4676 = _4675 / _4526;
                                                                                    if (textureLod(_7328, _4676, 0.0).w >= 0.5)
                                                                                    {
                                                                                        _4497 = 1.0;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        _4497 = 0.0;
                                                                                    }
                                                                                    vec2 _4705 = mix(vec2(1.0) - _4643, _4643, _4672);
                                                                                    _4493[_4496] = ((_4705.x * _4705.y) * _4497) * (1.0 - clamp((abs(_4653 - textureLod(_7330, _4676, 0.0).x) - _4657) / (0.25 * _4657), 0.0, 1.0));
                                                                                    _4494[_4496] = textureLod(_7332, (floor(_4489.xy + ((_4675 - _4490.xy) * _4649)) + vec2(0.5)) / Globals.uAtlasSize.xy, 0.0).xyz;
                                                                                    _4496++;
                                                                                    continue;
                                                                                }
                                                                                float _4752 = ((_4493.x + _4493.y) + _4493.z) + _4493.w;
                                                                                float _4753 = (_4589 * _4589) * _4752;
                                                                                if (!(_4753 <= 0.0))
                                                                                {
                                                                                    vec3 _4781 = ((((_4494[0] * _4493.x) + (_4494[1] * _4493.y)) + (_4494[2] * _4493.z)) + (_4494[3] * _4493.w)) / vec3(_4752);
                                                                                    bvec3 _7392 = isnan(_4781);
                                                                                    bvec3 _7393 = isnan(vec3(0.0));
                                                                                    vec3 _7394 = max(_4781, vec3(0.0));
                                                                                    vec3 _7395 = vec3(_7392.x ? vec3(0.0).x : _7394.x, _7392.y ? vec3(0.0).y : _7394.y, _7392.z ? vec3(0.0).z : _7394.z);
                                                                                    _3182 += (vec3(_7393.x ? _4781.x : _7395.x, _7393.y ? _4781.y : _7395.y, _7393.z ? _4781.z : _7395.z) * _4753);
                                                                                    _4482 += _4753;
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                    if (_4551_ladder_break)
                                                    {
                                                        break;
                                                    }
                                                    _4481++;
                                                    continue;
                                                }
                                                _4478++;
                                                _4479 = _4482;
                                                continue;
                                            }
                                            if (_4479 <= 0.0)
                                            {
                                                _3182 = vec3(0.0);
                                                _4475 = false;
                                            }
                                            else
                                            {
                                                _3182 /= vec3(_4479);
                                                _4475 = true;
                                            }
                                        }
                                    }
                                    if (_4475)
                                    {
                                        vec3 _3309 = _3182 * Globals.uBounceScale;
                                        float _4962 = _3309.x;
                                        float _4963 = _3309.y;
                                        float _4964 = _3309.z;
                                        float _4965 = isnan(_4964) ? _4963 : (isnan(_4963) ? _4964 : max(_4963, _4964));
                                        float _4966 = isnan(_4965) ? _4962 : (isnan(_4962) ? _4965 : max(_4962, _4965));
                                        if (_4966 > Globals.uMaxRayIntensity)
                                        {
                                            _4959 = _3309 * (Globals.uMaxRayIntensity / _4966);
                                        }
                                        else
                                        {
                                            _4959 = _3309;
                                        }
                                        _3177 = true;
                                        _3179 = 2;
                                        _3168 = _3309;
                                        _3180 = _3155 + _4959;
                                        _3181 = _3158 + 1.0;
                                    }
                                    else
                                    {
                                        _3177 = _3153;
                                        _3179 = _3164;
                                        _3168 = _3162;
                                        _3180 = _3155;
                                        _3181 = _3158;
                                    }
                                    _3178 = false;
                                }
                                else
                                {
                                    _3177 = _3153;
                                    _3178 = _3263;
                                    _3179 = _3164;
                                    _3168 = _3162;
                                    _3180 = _3155;
                                    _3181 = _3158;
                                }
                                if (_3177)
                                {
                                    _3167 = _3179;
                                    _3170 = _3168;
                                    _3173 = 1.0;
                                    _3171 = _3180;
                                    _3174 = _3181;
                                    _3175 = _3159;
                                    _3169 = _3156;
                                    _3172 = _3160;
                                }
                                else
                                {
                                    if (_3178)
                                    {
                                        float _3348 = 1.5 * Globals.uClipmapOrigin.data[0].w;
                                        {
                                            _5147 = false;
                                            {
                                                _5101 = false;
                                                _5103 = Globals.uClipmapOrigin.data[0].w;
                                                int _5149 = 0;
                                                for (;;)
                                                {
                                                    bool _5161_ladder_break = false;
                                                    {
                                                        if (!(_5149 < Globals.uShadowLevels))
                                                        {
                                                            _5161_ladder_break = true;
                                                        }
                                                        else
                                                        {
                                                            vec3 _5176 = (_3176 - Globals.uClipmapOrigin.data[_5149].xyz) / vec3(Globals.uClipmapOrigin.data[_5149].w);
                                                            if (any(lessThan(_5176, vec3(0.5))))
                                                            {
                                                                _5150 = true;
                                                            }
                                                            else
                                                            {
                                                                _5150 = any(greaterThan(_5176, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                            }
                                                            if (!(_5150))
                                                            {
                                                                _5101 = true;
                                                                _5103 = Globals.uClipmapOrigin.data[_5149].w;
                                                                _5147 = true;
                                                                _5161_ladder_break = true;
                                                            }
                                                        }
                                                    }
                                                    if (_5161_ladder_break)
                                                    {
                                                        break;
                                                    }
                                                    _5149++;
                                                    continue;
                                                }
                                                if (!(_5147))
                                                {
                                                    _5147 = true;
                                                }
                                            }
                                            if (!_5101)
                                            {
                                                _5100 = vec3(0.0);
                                            }
                                            else
                                            {
                                                float _5117 = 0.5 * _5103;
                                                vec3 _5118 = vec3(_5117, 0.0, 0.0);
                                                vec3 _5119 = _3176 + _5118;
                                                _5245 = false;
                                                {
                                                    int _5247 = 0;
                                                    for (;;)
                                                    {
                                                        bool _5259_ladder_break = false;
                                                        {
                                                            if (!(_5247 < Globals.uShadowLevels))
                                                            {
                                                                _5259_ladder_break = true;
                                                            }
                                                            else
                                                            {
                                                                vec3 _5274 = (_5119 - Globals.uClipmapOrigin.data[_5247].xyz) / vec3(Globals.uClipmapOrigin.data[_5247].w);
                                                                if (any(lessThan(_5274, vec3(0.5))))
                                                                {
                                                                    _5248 = true;
                                                                }
                                                                else
                                                                {
                                                                    _5248 = any(greaterThan(_5274, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                }
                                                                if (!(_5248))
                                                                {
                                                                    _5245 = true;
                                                                    _5246 = ((textureLod(_7320, vec3(_5274.x / float(Globals.uShadowResolution), _5274.y / float(Globals.uShadowResolution), ((float(_5247) * float(Globals.uShadowResolution)) + _5274.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_5247];
                                                                    _5259_ladder_break = true;
                                                                }
                                                            }
                                                        }
                                                        if (_5259_ladder_break)
                                                        {
                                                            break;
                                                        }
                                                        _5247++;
                                                        continue;
                                                    }
                                                    if (!(_5245))
                                                    {
                                                        _5245 = true;
                                                        _5246 = 1000000.0;
                                                    }
                                                }
                                                vec3 _5121 = _3176 - _5118;
                                                _5343 = false;
                                                {
                                                    int _5345 = 0;
                                                    for (;;)
                                                    {
                                                        bool _5357_ladder_break = false;
                                                        {
                                                            if (!(_5345 < Globals.uShadowLevels))
                                                            {
                                                                _5357_ladder_break = true;
                                                            }
                                                            else
                                                            {
                                                                vec3 _5372 = (_5121 - Globals.uClipmapOrigin.data[_5345].xyz) / vec3(Globals.uClipmapOrigin.data[_5345].w);
                                                                if (any(lessThan(_5372, vec3(0.5))))
                                                                {
                                                                    _5346 = true;
                                                                }
                                                                else
                                                                {
                                                                    _5346 = any(greaterThan(_5372, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                }
                                                                if (!(_5346))
                                                                {
                                                                    _5343 = true;
                                                                    _5344 = ((textureLod(_7320, vec3(_5372.x / float(Globals.uShadowResolution), _5372.y / float(Globals.uShadowResolution), ((float(_5345) * float(Globals.uShadowResolution)) + _5372.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_5345];
                                                                    _5357_ladder_break = true;
                                                                }
                                                            }
                                                        }
                                                        if (_5357_ladder_break)
                                                        {
                                                            break;
                                                        }
                                                        _5345++;
                                                        continue;
                                                    }
                                                    if (!(_5343))
                                                    {
                                                        _5343 = true;
                                                        _5344 = 1000000.0;
                                                    }
                                                }
                                                vec3 _5124 = vec3(0.0, _5117, 0.0);
                                                vec3 _5125 = _3176 + _5124;
                                                _5441 = false;
                                                {
                                                    int _5443 = 0;
                                                    for (;;)
                                                    {
                                                        bool _5455_ladder_break = false;
                                                        {
                                                            if (!(_5443 < Globals.uShadowLevels))
                                                            {
                                                                _5455_ladder_break = true;
                                                            }
                                                            else
                                                            {
                                                                vec3 _5470 = (_5125 - Globals.uClipmapOrigin.data[_5443].xyz) / vec3(Globals.uClipmapOrigin.data[_5443].w);
                                                                if (any(lessThan(_5470, vec3(0.5))))
                                                                {
                                                                    _5444 = true;
                                                                }
                                                                else
                                                                {
                                                                    _5444 = any(greaterThan(_5470, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                }
                                                                if (!(_5444))
                                                                {
                                                                    _5441 = true;
                                                                    _5442 = ((textureLod(_7320, vec3(_5470.x / float(Globals.uShadowResolution), _5470.y / float(Globals.uShadowResolution), ((float(_5443) * float(Globals.uShadowResolution)) + _5470.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_5443];
                                                                    _5455_ladder_break = true;
                                                                }
                                                            }
                                                        }
                                                        if (_5455_ladder_break)
                                                        {
                                                            break;
                                                        }
                                                        _5443++;
                                                        continue;
                                                    }
                                                    if (!(_5441))
                                                    {
                                                        _5441 = true;
                                                        _5442 = 1000000.0;
                                                    }
                                                }
                                                vec3 _5127 = _3176 - _5124;
                                                _5539 = false;
                                                {
                                                    int _5541 = 0;
                                                    for (;;)
                                                    {
                                                        bool _5553_ladder_break = false;
                                                        {
                                                            if (!(_5541 < Globals.uShadowLevels))
                                                            {
                                                                _5553_ladder_break = true;
                                                            }
                                                            else
                                                            {
                                                                vec3 _5568 = (_5127 - Globals.uClipmapOrigin.data[_5541].xyz) / vec3(Globals.uClipmapOrigin.data[_5541].w);
                                                                if (any(lessThan(_5568, vec3(0.5))))
                                                                {
                                                                    _5542 = true;
                                                                }
                                                                else
                                                                {
                                                                    _5542 = any(greaterThan(_5568, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                }
                                                                if (!(_5542))
                                                                {
                                                                    _5539 = true;
                                                                    _5540 = ((textureLod(_7320, vec3(_5568.x / float(Globals.uShadowResolution), _5568.y / float(Globals.uShadowResolution), ((float(_5541) * float(Globals.uShadowResolution)) + _5568.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_5541];
                                                                    _5553_ladder_break = true;
                                                                }
                                                            }
                                                        }
                                                        if (_5553_ladder_break)
                                                        {
                                                            break;
                                                        }
                                                        _5541++;
                                                        continue;
                                                    }
                                                    if (!(_5539))
                                                    {
                                                        _5539 = true;
                                                        _5540 = 1000000.0;
                                                    }
                                                }
                                                vec3 _5130 = vec3(0.0, 0.0, _5117);
                                                vec3 _5131 = _3176 + _5130;
                                                _5637 = false;
                                                {
                                                    int _5639 = 0;
                                                    for (;;)
                                                    {
                                                        bool _5651_ladder_break = false;
                                                        {
                                                            if (!(_5639 < Globals.uShadowLevels))
                                                            {
                                                                _5651_ladder_break = true;
                                                            }
                                                            else
                                                            {
                                                                vec3 _5666 = (_5131 - Globals.uClipmapOrigin.data[_5639].xyz) / vec3(Globals.uClipmapOrigin.data[_5639].w);
                                                                if (any(lessThan(_5666, vec3(0.5))))
                                                                {
                                                                    _5640 = true;
                                                                }
                                                                else
                                                                {
                                                                    _5640 = any(greaterThan(_5666, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                }
                                                                if (!(_5640))
                                                                {
                                                                    _5637 = true;
                                                                    _5638 = ((textureLod(_7320, vec3(_5666.x / float(Globals.uShadowResolution), _5666.y / float(Globals.uShadowResolution), ((float(_5639) * float(Globals.uShadowResolution)) + _5666.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_5639];
                                                                    _5651_ladder_break = true;
                                                                }
                                                            }
                                                        }
                                                        if (_5651_ladder_break)
                                                        {
                                                            break;
                                                        }
                                                        _5639++;
                                                        continue;
                                                    }
                                                    if (!(_5637))
                                                    {
                                                        _5637 = true;
                                                        _5638 = 1000000.0;
                                                    }
                                                }
                                                vec3 _5133 = _3176 - _5130;
                                                _5735 = false;
                                                {
                                                    int _5737 = 0;
                                                    for (;;)
                                                    {
                                                        bool _5749_ladder_break = false;
                                                        {
                                                            if (!(_5737 < Globals.uShadowLevels))
                                                            {
                                                                _5749_ladder_break = true;
                                                            }
                                                            else
                                                            {
                                                                vec3 _5764 = (_5133 - Globals.uClipmapOrigin.data[_5737].xyz) / vec3(Globals.uClipmapOrigin.data[_5737].w);
                                                                if (any(lessThan(_5764, vec3(0.5))))
                                                                {
                                                                    _5738 = true;
                                                                }
                                                                else
                                                                {
                                                                    _5738 = any(greaterThan(_5764, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                }
                                                                if (!(_5738))
                                                                {
                                                                    _5735 = true;
                                                                    _5736 = ((textureLod(_7320, vec3(_5764.x / float(Globals.uShadowResolution), _5764.y / float(Globals.uShadowResolution), ((float(_5737) * float(Globals.uShadowResolution)) + _5764.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_5737];
                                                                    _5749_ladder_break = true;
                                                                }
                                                            }
                                                        }
                                                        if (_5749_ladder_break)
                                                        {
                                                            break;
                                                        }
                                                        _5737++;
                                                        continue;
                                                    }
                                                    if (!(_5735))
                                                    {
                                                        _5735 = true;
                                                        _5736 = 1000000.0;
                                                    }
                                                }
                                                vec3 _5136 = vec3(_5246 - _5344, _5442 - _5540, _5638 - _5736);
                                                float _5137 = dot(_5136, _5136);
                                                if (_5137 < 1.0000000133514319600180897396058e-10)
                                                {
                                                    _5107 = vec3(0.0);
                                                }
                                                else
                                                {
                                                    _5107 = _5136 * inversesqrt(_5137);
                                                }
                                                _5100 = _5107;
                                            }
                                        }
                                        vec3 _3363 = world + Globals.uTraceOrigin;
                                        {
                                            float _7138 = Globals.uShelterMap1.z;
                                            float _7139 = Globals.uShelterMap1.w;
                                            float _7140 = Globals.uShelterMap2.x;
                                            float _7141 = Globals.uShelterMap2.y;
                                            ivec2 _5899 = ivec2(floor((_3363.xy - Globals.uShelterMap0.xy) * Globals.uShelterMap0.z));
                                            vec2 _7184 = Globals.uShelterMap1.xy;
                                            if (Globals.uShelterMap0.w > 0.5)
                                            {
                                                _5900 = _5899.x >= 0;
                                            }
                                            else
                                            {
                                                _5900 = false;
                                            }
                                            if (_5900)
                                            {
                                                _5900 = _5899.y >= 0;
                                            }
                                            else
                                            {
                                                _5900 = false;
                                            }
                                            if (_5900)
                                            {
                                                _5900 = _5899.x < int(_7184.x);
                                            }
                                            else
                                            {
                                                _5900 = false;
                                            }
                                            if (_5900)
                                            {
                                                _5900 = _5899.y < int(_7184.y);
                                            }
                                            else
                                            {
                                                _5900 = false;
                                            }
                                            if (!_5900)
                                            {
                                                _5834 = false;
                                            }
                                            else
                                            {
                                                vec4 _5883 = texelFetch(_7335, ivec3(_5899, 0).xy, 0);
                                                float _7188 = _7138;
                                                float _7189 = _7139;
                                                float _5950 = floor((_5883.z * 255.0) + 0.5) + (floor((_5883.y * 255.0) + 0.5) * 256.0);
                                                if (_5950 < 0.5)
                                                {
                                                    _5938 = -1000000015047466219876688855040.0;
                                                }
                                                else
                                                {
                                                    _5938 = _7188 + ((_5950 - 1.0) * _7189);
                                                }
                                                float _5886 = _3363.z;
                                                float _7193 = _7141;
                                                if (_5938 > (_5886 + _7140))
                                                {
                                                    _5963 = _5938 < (_5886 + _7193);
                                                }
                                                else
                                                {
                                                    _5963 = false;
                                                }
                                                _5834 = _5963;
                                            }
                                        }
                                        if (!_5834)
                                        {
                                            vec3 _3370 = _3176 + Globals.uTraceOrigin;
                                            {
                                                float _7076 = Globals.uShelterMap1.z;
                                                float _7077 = Globals.uShelterMap1.w;
                                                float _7078 = Globals.uShelterMap2.x;
                                                float _7079 = Globals.uShelterMap2.y;
                                                ivec2 _6044 = ivec2(floor((_3370.xy - Globals.uShelterMap0.xy) * Globals.uShelterMap0.z));
                                                vec2 _7124 = Globals.uShelterMap1.xy;
                                                if (Globals.uShelterMap0.w > 0.5)
                                                {
                                                    _6045 = _6044.x >= 0;
                                                }
                                                else
                                                {
                                                    _6045 = false;
                                                }
                                                if (_6045)
                                                {
                                                    _6045 = _6044.y >= 0;
                                                }
                                                else
                                                {
                                                    _6045 = false;
                                                }
                                                if (_6045)
                                                {
                                                    _6045 = _6044.x < int(_7124.x);
                                                }
                                                else
                                                {
                                                    _6045 = false;
                                                }
                                                if (_6045)
                                                {
                                                    _6045 = _6044.y < int(_7124.y);
                                                }
                                                else
                                                {
                                                    _6045 = false;
                                                }
                                                if (!_6045)
                                                {
                                                    _5979 = false;
                                                }
                                                else
                                                {
                                                    vec4 _6028 = texelFetch(_7335, ivec3(_6044, 0).xy, 0);
                                                    float _7128 = _7076;
                                                    float _7129 = _7077;
                                                    float _6095 = floor((_6028.z * 255.0) + 0.5) + (floor((_6028.y * 255.0) + 0.5) * 256.0);
                                                    if (_6095 < 0.5)
                                                    {
                                                        _6083 = -1000000015047466219876688855040.0;
                                                    }
                                                    else
                                                    {
                                                        _6083 = _7128 + ((_6095 - 1.0) * _7129);
                                                    }
                                                    float _6031 = _3370.z;
                                                    float _7133 = _7079;
                                                    if (_6083 > (_6031 + _7078))
                                                    {
                                                        _6108 = _6083 < (_6031 + _7133);
                                                    }
                                                    else
                                                    {
                                                        _6108 = false;
                                                    }
                                                    _5979 = _6108;
                                                }
                                            }
                                            _3186 = _5979;
                                        }
                                        else
                                        {
                                            _3186 = false;
                                        }
                                        if (_3186)
                                        {
                                            _3172 = 0.0;
                                            _3187 = _3159 + 1.0;
                                        }
                                        else
                                        {
                                            _3172 = smoothstep(_3348, 2.0 * Globals.uClipmapOrigin.data[0].w, length(_3176 - world)) * smoothstep(0.75 * Globals.uClipmapOrigin.data[0].w, _3348, dot(_3176 - world, worldNormal));
                                            _3187 = _3159;
                                        }
                                        if (dot(_5100, _3619) > 0.0)
                                        {
                                            _3169 = -_5100;
                                        }
                                        else
                                        {
                                            _3169 = _5100;
                                        }
                                        if (_3172 <= 0.0)
                                        {
                                            _3167 = _3179;
                                            _3170 = _3168;
                                            _3173 = 0.0;
                                            _3171 = _3180;
                                            _3174 = _3181;
                                            _3175 = _3187;
                                        }
                                        else
                                        {
                                            if (dot(_3169, _3169) > 0.5)
                                            {
                                                float _3396 = 0.5 * Globals.uClipmapOrigin.data[0].w;
                                                {
                                                    _3188 = vec3(0.0);
                                                    if (Globals.uLookupBuckets <= 0)
                                                    {
                                                        _6128 = false;
                                                    }
                                                    else
                                                    {
                                                        ivec3 _6167 = ivec3(floor((_3176 - Globals.uLookupMin) / vec3(Globals.uLookupCell)));
                                                        int _6514 = int((((uint(_6167.x) * 2376512323u) ^ (uint(_6167.y) * 3625334849u)) ^ (uint(_6167.z) * 3407524639u)) & uint(Globals.uLookupBuckets - 1));
                                                        uvec2 _6172 = uvec2(textureSize(_7326, 0));
                                                        vec2 _6179 = vec2(float(_6172.x), float(_6172.y));
                                                        int _6131 = 0;
                                                        float _6132 = 0.0;
                                                        for (;;)
                                                        {
                                                            if (!(_6131 <= uCells._member0[Globals.uLookupBuckets].y))
                                                            {
                                                                break;
                                                            }
                                                            bool _6193 = _6131 == 0;
                                                            if (_6193)
                                                            {
                                                                _6133 = uCells._member0[_6514];
                                                            }
                                                            else
                                                            {
                                                                int _6519 = uCells._member0[Globals.uLookupBuckets].x + ((_6131 - 1) * 6);
                                                                float _6536 = intBitsToFloat(uCellPages_1._member0[_6519 + 3]) + _3396;
                                                                vec3 _6537 = _3176 - vec3(intBitsToFloat(uCellPages_1._member0[_6519]), intBitsToFloat(uCellPages_1._member0[_6519 + 1]), intBitsToFloat(uCellPages_1._member0[_6519 + 2]));
                                                                if (dot(_6537, _6537) > (_6536 * _6536))
                                                                {
                                                                    _6515 = ivec2(0);
                                                                }
                                                                else
                                                                {
                                                                    _6515 = ivec2(uCellPages_1._member0[_6519 + 4], uCellPages_1._member0[_6519 + 5]);
                                                                }
                                                                _6133 = _6515;
                                                            }
                                                            int _6134 = 0;
                                                            float _6135 = _6132;
                                                            for (;;)
                                                            {
                                                                bool _6204_ladder_break = false;
                                                                {
                                                                    if (!(_6134 < _6133.y))
                                                                    {
                                                                        _6204_ladder_break = true;
                                                                    }
                                                                    else
                                                                    {
                                                                        int _6215 = _6133.x + _6134;
                                                                        int _6218 = uCellPages_1._member0[_6215] * 10;
                                                                        if (!((uPages._member0[_6218 + 5].w > 0.5) == _6193))
                                                                        {
                                                                            int _6227 = _6218 + 9;
                                                                            vec3 _6231 = _3176 - uPages._member0[_6227].xyz;
                                                                            float _6233 = uPages._member0[_6227].w + _3396;
                                                                            if (!(dot(_6231, _6231) > (_6233 * _6233)))
                                                                            {
                                                                                int _6553 = uCellPages_1._member0[_6215] * 10;
                                                                                vec4 _6142 = uPages._member0[_6553];
                                                                                vec4 _6143 = uPages._member0[_6553 + 1];
                                                                                int _6559 = _6553 + 2;
                                                                                int _6562 = _6553 + 3;
                                                                                int _6565 = _6553 + 4;
                                                                                int _6571 = _6553 + 6;
                                                                                int _6574 = _6553 + 7;
                                                                                int _6577 = _6553 + 8;
                                                                                vec3 _6584 = _3176 - vec3(uPages._member0[_6571].w, uPages._member0[_6574].w, uPages._member0[_6577].w);
                                                                                vec3 _6597 = vec3(dot(uPages._member0[_6571].xyz, _6584), dot(uPages._member0[_6574].xyz, _6584), dot(uPages._member0[_6577].xyz, _6584)) - uPages._member0[_6559].xyz;
                                                                                vec2 _6600 = vec2(uPages._member0[_6559].w, uPages._member0[_6562].w);
                                                                                bvec2 _7407 = isnan(_6600);
                                                                                bvec2 _7408 = isnan(vec2(9.9999999747524270787835121154785e-07));
                                                                                vec2 _7409 = max(_6600, vec2(9.9999999747524270787835121154785e-07));
                                                                                vec2 _7410 = vec2(_7407.x ? vec2(9.9999999747524270787835121154785e-07).x : _7409.x, _7407.y ? vec2(9.9999999747524270787835121154785e-07).y : _7409.y);
                                                                                vec2 _6601 = vec2(_7408.x ? _6600.x : _7410.x, _7408.y ? _6600.y : _7410.y);
                                                                                vec2 _6137 = _6601;
                                                                                vec2 _6136 = vec2(dot(_6597, uPages._member0[_6562].xyz), dot(_6597, uPages._member0[_6565].xyz)) / _6601;
                                                                                float _6138 = -dot(_6597, uPages._member0[_6553 + 5].xyz);
                                                                                float _6139 = uPages._member0[_6565].w;
                                                                                float _6242 = dot(uPages._member0[_6553 + 5].xyz, vec3(dot(uPages._member0[_6571].xyz, _3169), dot(uPages._member0[_6574].xyz, _3169), dot(uPages._member0[_6577].xyz, _3169)));
                                                                                if (!(_6242 <= 0.0))
                                                                                {
                                                                                    float _6247 = Globals.uClipmapOrigin.data[0].w * 0.25;
                                                                                    vec2 _6250 = vec2(_6247) / _6137;
                                                                                    if (abs(_6136.x) > (1.0 + _6250.x))
                                                                                    {
                                                                                        _6144 = true;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        _6144 = abs(_6136.y) > (1.0 + _6250.y);
                                                                                    }
                                                                                    if (!(_6144))
                                                                                    {
                                                                                        if (_6138 < (Globals.uClipmapOrigin.data[0].w * (-0.25)))
                                                                                        {
                                                                                            _6145 = true;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            _6145 = _6138 > (_6139 + _6247);
                                                                                        }
                                                                                        if (!(_6145))
                                                                                        {
                                                                                            vec2 _6294 = (_6143.xy + (((clamp(_6136, vec2(-1.0), vec2(1.0)) * 0.5) + vec2(0.5)) * _6143.zw)) - vec2(0.5);
                                                                                            vec2 _6295 = floor(_6294);
                                                                                            vec2 _6296 = _6294 - _6295;
                                                                                            bvec2 _7412 = isnan(_6143.zw);
                                                                                            bvec2 _7413 = isnan(vec2(9.9999999747524270787835121154785e-07));
                                                                                            vec2 _7414 = max(_6143.zw, vec2(9.9999999747524270787835121154785e-07));
                                                                                            vec2 _7415 = vec2(_7412.x ? vec2(9.9999999747524270787835121154785e-07).x : _7414.x, _7412.y ? vec2(9.9999999747524270787835121154785e-07).y : _7414.y);
                                                                                            vec2 _6302 = _6142.zw / vec2(_7413.x ? _6143.zw.x : _7415.x, _7413.y ? _6143.zw.y : _7415.y);
                                                                                            float _6306 = _6138 / (isnan(9.9999999747524270787835121154785e-07) ? _6139 : (isnan(_6139) ? 9.9999999747524270787835121154785e-07 : max(_6139, 9.9999999747524270787835121154785e-07)));
                                                                                            float _6308 = 0.5 * _6139;
                                                                                            float _6310 = _3396 / (isnan(9.9999999747524270787835121154785e-07) ? _6308 : (isnan(_6308) ? 9.9999999747524270787835121154785e-07 : max(_6308, 9.9999999747524270787835121154785e-07)));
                                                                                            vec4 _6146 = vec4(0.0);
                                                                                            int _6149 = 0;
                                                                                            for (;;)
                                                                                            {
                                                                                                if (!(_6149 < 4))
                                                                                                {
                                                                                                    break;
                                                                                                }
                                                                                                vec2 _6325 = vec2(float(_6149 & 1), float(_6149 >> 1));
                                                                                                vec2 _6328 = (_6295 + _6325) + vec2(0.5);
                                                                                                vec2 _6329 = _6328 / _6179;
                                                                                                if (textureLod(_7328, _6329, 0.0).w >= 0.5)
                                                                                                {
                                                                                                    _6150 = 1.0;
                                                                                                }
                                                                                                else
                                                                                                {
                                                                                                    _6150 = 0.0;
                                                                                                }
                                                                                                vec2 _6358 = mix(vec2(1.0) - _6296, _6296, _6325);
                                                                                                _6146[_6149] = ((_6358.x * _6358.y) * _6150) * (1.0 - clamp((abs(_6306 - textureLod(_7330, _6329, 0.0).x) - _6310) / (0.25 * _6310), 0.0, 1.0));
                                                                                                _6147[_6149] = textureLod(_7332, (floor(_6142.xy + ((_6328 - _6143.xy) * _6302)) + vec2(0.5)) / Globals.uAtlasSize.xy, 0.0).xyz;
                                                                                                _6149++;
                                                                                                continue;
                                                                                            }
                                                                                            float _6405 = ((_6146.x + _6146.y) + _6146.z) + _6146.w;
                                                                                            float _6406 = (_6242 * _6242) * _6405;
                                                                                            if (!(_6406 <= 0.0))
                                                                                            {
                                                                                                vec3 _6434 = ((((_6147[0] * _6146.x) + (_6147[1] * _6146.y)) + (_6147[2] * _6146.z)) + (_6147[3] * _6146.w)) / vec3(_6405);
                                                                                                bvec3 _7427 = isnan(_6434);
                                                                                                bvec3 _7428 = isnan(vec3(0.0));
                                                                                                vec3 _7429 = max(_6434, vec3(0.0));
                                                                                                vec3 _7430 = vec3(_7427.x ? vec3(0.0).x : _7429.x, _7427.y ? vec3(0.0).y : _7429.y, _7427.z ? vec3(0.0).z : _7429.z);
                                                                                                _3188 += (vec3(_7428.x ? _6434.x : _7430.x, _7428.y ? _6434.y : _7430.y, _7428.z ? _6434.z : _7430.z) * _6406);
                                                                                                _6135 += _6406;
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                                if (_6204_ladder_break)
                                                                {
                                                                    break;
                                                                }
                                                                _6134++;
                                                                continue;
                                                            }
                                                            _6131++;
                                                            _6132 = _6135;
                                                            continue;
                                                        }
                                                        if (_6132 <= 0.0)
                                                        {
                                                            _3188 = vec3(0.0);
                                                            _6128 = false;
                                                        }
                                                        else
                                                        {
                                                            _3188 /= vec3(_6132);
                                                            _6128 = true;
                                                        }
                                                    }
                                                }
                                                _3189 = _6128;
                                            }
                                            else
                                            {
                                                _3189 = false;
                                            }
                                            if (_3189)
                                            {
                                                vec3 _3438 = _3188 * Globals.uBounceScale;
                                                float _6989 = _3438.x;
                                                float _6990 = _3438.y;
                                                float _6991 = _3438.z;
                                                float _6992 = isnan(_6991) ? _6990 : (isnan(_6990) ? _6991 : max(_6990, _6991));
                                                float _6993 = isnan(_6992) ? _6989 : (isnan(_6989) ? _6992 : max(_6989, _6992));
                                                if (_6993 > Globals.uMaxRayIntensity)
                                                {
                                                    _6986 = _3438 * (Globals.uMaxRayIntensity / _6993);
                                                }
                                                else
                                                {
                                                    _6986 = _3438;
                                                }
                                                _3167 = 2;
                                                _3170 = _3438;
                                                _3173 = _3172;
                                                _3171 = _3180 + (_6986 * _3172);
                                                _3174 = _3181 + _3172;
                                                _3175 = _3187;
                                            }
                                            else
                                            {
                                                {
                                                    _3184 = vec2(0.0);
                                                    float _3185 = 1000000000.0;
                                                    if (Globals.uLookupBuckets <= 0)
                                                    {
                                                        _6617 = false;
                                                    }
                                                    else
                                                    {
                                                        ivec3 _6658 = ivec3(floor((_3176 - Globals.uLookupMin) / vec3(Globals.uLookupCell)));
                                                        int _6870 = int((((uint(_6658.x) * 2376512323u) ^ (uint(_6658.y) * 3625334849u)) ^ (uint(_6658.z) * 3407524639u)) & uint(Globals.uLookupBuckets - 1));
                                                        uvec2 _6663 = uvec2(textureSize(_7326, 0));
                                                        vec2 _6670 = vec2(float(_6663.x), float(_6663.y));
                                                        bool _6620 = false;
                                                        bool _6621 = false;
                                                        int _6622 = 0;
                                                        for (;;)
                                                        {
                                                            if (_6622 <= uCells._member0[Globals.uLookupBuckets].y)
                                                            {
                                                                _6623 = !_6620;
                                                            }
                                                            else
                                                            {
                                                                _6623 = false;
                                                            }
                                                            if (!_6623)
                                                            {
                                                                break;
                                                            }
                                                            bool _6690 = _6622 == 0;
                                                            if (_6690)
                                                            {
                                                                _6624 = uCells._member0[_6870];
                                                            }
                                                            else
                                                            {
                                                                int _6875 = uCells._member0[Globals.uLookupBuckets].x + ((_6622 - 1) * 6);
                                                                float _6891 = intBitsToFloat(uCellPages_1._member0[_6875 + 3]);
                                                                vec3 _6893 = _3176 - vec3(intBitsToFloat(uCellPages_1._member0[_6875]), intBitsToFloat(uCellPages_1._member0[_6875 + 1]), intBitsToFloat(uCellPages_1._member0[_6875 + 2]));
                                                                if (dot(_6893, _6893) > (_6891 * _6891))
                                                                {
                                                                    _6871 = ivec2(0);
                                                                }
                                                                else
                                                                {
                                                                    _6871 = ivec2(uCellPages_1._member0[_6875 + 4], uCellPages_1._member0[_6875 + 5]);
                                                                }
                                                                _6624 = _6871;
                                                            }
                                                            bool _6625 = _6620;
                                                            bool _6626 = _6621;
                                                            int _6627 = 0;
                                                            for (;;)
                                                            {
                                                                bool _6702_ladder_break = false;
                                                                {
                                                                    if (_6627 < _6624.y)
                                                                    {
                                                                        _6628 = !_6625;
                                                                    }
                                                                    else
                                                                    {
                                                                        _6628 = false;
                                                                    }
                                                                    if (!_6628)
                                                                    {
                                                                        _6702_ladder_break = true;
                                                                    }
                                                                    else
                                                                    {
                                                                        int _6719 = _6624.x + _6627;
                                                                        int _6722 = uCellPages_1._member0[_6719] * 10;
                                                                        if (!((uPages._member0[_6722 + 5].w > 0.5) == _6690))
                                                                        {
                                                                            int _6731 = _6722 + 9;
                                                                            vec3 _6735 = _3176 - uPages._member0[_6731].xyz;
                                                                            if (!(dot(_6735, _6735) > (uPages._member0[_6731].w * uPages._member0[_6731].w)))
                                                                            {
                                                                                vec3 _6742 = -_3619;
                                                                                int _6909 = uCellPages_1._member0[_6719] * 10;
                                                                                vec4 _6635 = uPages._member0[_6909];
                                                                                vec4 _6636 = uPages._member0[_6909 + 1];
                                                                                int _6915 = _6909 + 2;
                                                                                int _6918 = _6909 + 3;
                                                                                int _6921 = _6909 + 4;
                                                                                int _6927 = _6909 + 6;
                                                                                int _6930 = _6909 + 7;
                                                                                int _6933 = _6909 + 8;
                                                                                vec3 _6940 = _3176 - vec3(uPages._member0[_6927].w, uPages._member0[_6930].w, uPages._member0[_6933].w);
                                                                                vec3 _6634 = vec3(dot(uPages._member0[_6927].xyz, _6742), dot(uPages._member0[_6930].xyz, _6742), dot(uPages._member0[_6933].xyz, _6742));
                                                                                vec3 _6953 = vec3(dot(uPages._member0[_6927].xyz, _6940), dot(uPages._member0[_6930].xyz, _6940), dot(uPages._member0[_6933].xyz, _6940)) - uPages._member0[_6915].xyz;
                                                                                vec2 _6956 = vec2(uPages._member0[_6915].w, uPages._member0[_6918].w);
                                                                                bvec2 _7442 = isnan(_6956);
                                                                                bvec2 _7443 = isnan(vec2(9.9999999747524270787835121154785e-07));
                                                                                vec2 _7444 = max(_6956, vec2(9.9999999747524270787835121154785e-07));
                                                                                vec2 _7445 = vec2(_7442.x ? vec2(9.9999999747524270787835121154785e-07).x : _7444.x, _7442.y ? vec2(9.9999999747524270787835121154785e-07).y : _7444.y);
                                                                                vec2 _6963 = vec2(dot(_6953, uPages._member0[_6918].xyz), dot(_6953, uPages._member0[_6921].xyz)) / vec2(_7443.x ? _6956.x : _7445.x, _7443.y ? _6956.y : _7445.y);
                                                                                vec2 _6629 = _6963;
                                                                                float _6631 = -dot(_6953, uPages._member0[_6909 + 5].xyz);
                                                                                float _6632 = uPages._member0[_6921].w;
                                                                                vec3 _6633 = uPages._member0[_6909 + 5].xyz;
                                                                                if (abs(_6963.x) > 1.0)
                                                                                {
                                                                                    _6637 = true;
                                                                                }
                                                                                else
                                                                                {
                                                                                    _6637 = abs(_6629.y) > 1.0;
                                                                                }
                                                                                if (!(_6637))
                                                                                {
                                                                                    if (dot(_3619, _3619) > 0.5)
                                                                                    {
                                                                                        _6638 = dot(_6633, _6634) < (-0.0500000007450580596923828125);
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        _6638 = false;
                                                                                    }
                                                                                    if (!(_6638))
                                                                                    {
                                                                                        if (_6631 < (-0.25))
                                                                                        {
                                                                                            _6639 = true;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            _6639 = _6631 > (_6632 + 0.25);
                                                                                        }
                                                                                        if (!(_6639))
                                                                                        {
                                                                                            vec2 _6786 = (_6629 * 0.5) + vec2(0.5);
                                                                                            vec2 _6793 = (_6636.xy + (_6786 * _6636.zw)) / _6670;
                                                                                            if (!(textureLod(_7328, _6793, 0.0).w < 0.5))
                                                                                            {
                                                                                                float _6813 = abs((textureLod(_7330, _6793, 0.0).x * _6632) - _6631);
                                                                                                if (_6813 < _3185)
                                                                                                {
                                                                                                    _3185 = _6813;
                                                                                                    _3184 = (_6635.xy + (_6786 * _6635.zw)) / Globals.uAtlasSize.xy;
                                                                                                    _6640 = _6813 < 0.0199999995529651641845703125;
                                                                                                    _6641 = true;
                                                                                                }
                                                                                                else
                                                                                                {
                                                                                                    _6640 = _6625;
                                                                                                    _6641 = _6626;
                                                                                                }
                                                                                                _6625 = _6640;
                                                                                                _6626 = _6641;
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                                if (_6702_ladder_break)
                                                                {
                                                                    break;
                                                                }
                                                                _6627++;
                                                                continue;
                                                            }
                                                            _6620 = _6625;
                                                            _6621 = _6626;
                                                            _6622++;
                                                            continue;
                                                        }
                                                        _6617 = _6621;
                                                    }
                                                }
                                                if (_6617)
                                                {
                                                    vec3 _3422 = textureLod(_7332, _3184, 0.0).xyz * Globals.uBounceScale;
                                                    float _6971 = _3422.x;
                                                    float _6972 = _3422.y;
                                                    float _6973 = _3422.z;
                                                    float _6974 = isnan(_6973) ? _6972 : (isnan(_6972) ? _6973 : max(_6972, _6973));
                                                    float _6975 = isnan(_6974) ? _6971 : (isnan(_6971) ? _6974 : max(_6971, _6974));
                                                    if (_6975 > Globals.uMaxRayIntensity)
                                                    {
                                                        _6968 = _3422 * (Globals.uMaxRayIntensity / _6975);
                                                    }
                                                    else
                                                    {
                                                        _6968 = _3422;
                                                    }
                                                    _3167 = 2;
                                                    _3170 = _3422;
                                                    _3173 = _3172;
                                                    _3171 = _3180 + (_6968 * _3172);
                                                    _3174 = _3181 + _3172;
                                                    _3175 = _3187;
                                                }
                                                else
                                                {
                                                    _3167 = _3179;
                                                    _3170 = _3168;
                                                    _3173 = 0.0;
                                                    _3171 = _3180;
                                                    _3174 = _3181;
                                                    _3175 = _3187 + _3172;
                                                }
                                            }
                                        }
                                        _3169 = _3156;
                                        _3172 = _3160;
                                    }
                                    else
                                    {
                                        if (_3619.z >= 0.0)
                                        {
                                            {
                                                if (Globals.uSkyShValid == 0)
                                                {
                                                    _5030 = Globals.uSkyColour;
                                                }
                                                else
                                                {
                                                    vec4 _5041 = vec4(_3619, 1.0);
                                                    vec4 _5044 = _5041.xyzz * _5041.yzzx;
                                                    float _5070 = _3619.x;
                                                    float _5072 = _3619.y;
                                                    vec3 _5077 = (vec3(dot(Globals.uSkySh.data[0], _5041), dot(Globals.uSkySh.data[1], _5041), dot(Globals.uSkySh.data[2], _5041)) + vec3(dot(Globals.uSkySh.data[3], _5044), dot(Globals.uSkySh.data[4], _5044), dot(Globals.uSkySh.data[5], _5044))) + (Globals.uSkySh.data[6].xyz * ((_5070 * _5070) - (_5072 * _5072)));
                                                    bvec3 _7457 = isnan(vec3(0.0));
                                                    bvec3 _7458 = isnan(_5077);
                                                    vec3 _7459 = max(vec3(0.0), _5077);
                                                    vec3 _7460 = vec3(_7457.x ? _5077.x : _7459.x, _7457.y ? _5077.y : _7459.y, _7457.z ? _5077.z : _7459.z);
                                                    _5030 = vec3(_7458.x ? vec3(0.0).x : _7460.x, _7458.y ? vec3(0.0).y : _7460.y, _7458.z ? vec3(0.0).z : _7460.z);
                                                }
                                            }
                                            _3169 = _5030;
                                        }
                                        else
                                        {
                                            {
                                                if (Globals.uSkyShValid == 0)
                                                {
                                                    _4978 = Globals.uSkyColour;
                                                }
                                                else
                                                {
                                                    vec4 _4989 = vec4(vec3(0.0, 0.0, 1.0), 1.0);
                                                    vec4 _4992 = _4989.xyzz * _4989.yzzx;
                                                    vec3 _5024 = vec3(dot(Globals.uSkySh.data[0], _4989), dot(Globals.uSkySh.data[1], _4989), dot(Globals.uSkySh.data[2], _4989)) + vec3(dot(Globals.uSkySh.data[3], _4992), dot(Globals.uSkySh.data[4], _4992), dot(Globals.uSkySh.data[5], _4992));
                                                    bvec3 _7462 = isnan(vec3(0.0));
                                                    bvec3 _7463 = isnan(_5024);
                                                    vec3 _7464 = max(vec3(0.0), _5024);
                                                    vec3 _7465 = vec3(_7462.x ? _5024.x : _7464.x, _7462.y ? _5024.y : _7464.y, _7462.z ? _5024.z : _7464.z);
                                                    _4978 = vec3(_7463.x ? vec3(0.0).x : _7465.x, _7463.y ? vec3(0.0).y : _7465.y, _7463.z ? vec3(0.0).z : _7465.z);
                                                }
                                            }
                                            _3169 = (_4978 + Globals.uGroundSun) * 0.25;
                                        }
                                        float _5087 = isnan(_3169.z) ? _3169.y : (isnan(_3169.y) ? _3169.z : max(_3169.y, _3169.z));
                                        float _5088 = isnan(_5087) ? _3169.x : (isnan(_3169.x) ? _5087 : max(_3169.x, _5087));
                                        if (_5088 > Globals.uMaxRayIntensity)
                                        {
                                            _5081 = _3169 * (Globals.uMaxRayIntensity / _5088);
                                        }
                                        else
                                        {
                                            _5081 = _3169;
                                        }
                                        _3167 = 3;
                                        _3170 = _3169;
                                        _3173 = 1.0;
                                        _3171 = _3180;
                                        _3174 = _3181;
                                        _3175 = _3159;
                                        _3169 = _3156 + _5081;
                                        _3172 = _3160 + 1.0;
                                    }
                                }
                            }
                            else
                            {
                                _3167 = _3164;
                                _3170 = _3162;
                                _3173 = 1.0;
                                _3171 = _3155;
                                _3174 = _3158;
                                _3175 = _3159;
                                _3169 = _3156;
                                _3172 = _3160;
                            }
                            if (Globals.uDebugSource != 0)
                            {
                                _3166 = _3167 != Globals.uDebugSource;
                            }
                            else
                            {
                                _3166 = false;
                            }
                            if (_3166)
                            {
                                _3168 = vec3(0.0);
                            }
                            else
                            {
                                _3168 = _3170;
                            }
                            float _7010 = isnan(_3168.z) ? _3168.y : (isnan(_3168.y) ? _3168.z : max(_3168.y, _3168.z));
                            float _7011 = isnan(_7010) ? _3168.x : (isnan(_3168.x) ? _7010 : max(_3168.x, _7010));
                            if (_7011 > Globals.uMaxRayIntensity)
                            {
                                _7004 = _3168 * (Globals.uMaxRayIntensity / _7011);
                            }
                            else
                            {
                                _7004 = _3168;
                            }
                            _3154++;
                            _3155 = _3171;
                            _3158 = _3174;
                            _3159 = _3175;
                            _3156 = _3169;
                            _3160 = _3172;
                            _3157 += (_7004 * _3173);
                            _3161 += _3173;
                            continue;
                        }
                        if (_3159 > 0.0)
                        {
                            if (Globals.uDebugSource == 0)
                            {
                                _3153 = true;
                            }
                            else
                            {
                                _3153 = Globals.uDebugSource == 2;
                            }
                        }
                        else
                        {
                            _3153 = false;
                        }
                        if (_3153)
                        {
                            if (_3158 > 0.0)
                            {
                                _3162 = _3155 / vec3(_3158);
                            }
                            else
                            {
                                if (_3160 > 0.0)
                                {
                                    _3155 = _3156 / vec3(_3160);
                                }
                                else
                                {
                                    vec3 _7023;
                                    {
                                        if (Globals.uSkyShValid == 0)
                                        {
                                            _7023 = Globals.uSkyColour;
                                        }
                                        else
                                        {
                                            vec4 _7034 = vec4(vec3(0.0, 0.0, 1.0), 1.0);
                                            vec4 _7037 = _7034.xyzz * _7034.yzzx;
                                            vec3 _7069 = vec3(dot(Globals.uSkySh.data[0], _7034), dot(Globals.uSkySh.data[1], _7034), dot(Globals.uSkySh.data[2], _7034)) + vec3(dot(Globals.uSkySh.data[3], _7037), dot(Globals.uSkySh.data[4], _7037), dot(Globals.uSkySh.data[5], _7037));
                                            bvec3 _7487 = isnan(vec3(0.0));
                                            bvec3 _7488 = isnan(_7069);
                                            vec3 _7489 = max(vec3(0.0), _7069);
                                            vec3 _7490 = vec3(_7487.x ? _7069.x : _7489.x, _7487.y ? _7069.y : _7489.y, _7487.z ? _7069.z : _7489.z);
                                            _7023 = vec3(_7488.x ? vec3(0.0).x : _7490.x, _7488.y ? vec3(0.0).y : _7490.y, _7488.z ? vec3(0.0).z : _7490.z);
                                        }
                                    }
                                    _3155 = _7023;
                                }
                                _3162 = _3155 * 0.25;
                            }
                            _3161 += _3159;
                            _3157 += (_3162 * _3159);
                        }
                        vec3 _3553 = _3157 * (3.1415927410125732421875 / (isnan(4.0) ? _3161 : (isnan(_3161) ? 4.0 : max(_3161, 4.0))));
                        bvec3 _7497 = isnan(_3553);
                        bvec3 _7498 = isnan(vec3(0.0));
                        vec3 _7499 = max(_3553, vec3(0.0));
                        vec3 _7500 = vec3(_7497.x ? vec3(0.0).x : _7499.x, _7497.y ? vec3(0.0).y : _7499.y, _7497.z ? vec3(0.0).z : _7499.z);
                        _3152 = vec3(_7498.x ? _3553.x : _7500.x, _7498.y ? _3553.y : _7500.y, _7498.z ? _3553.z : _7500.z);
                    }
                }
                imageStore(uIndirect, ivec2(gl_GlobalInvocationID.xy), vec4(_3152, 1.0));
            }
        }
    }
}

