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

float _9339;

layout(binding = 0, std140) uniform SLANG_ParameterGroup_Globals_std140
{
    _Array_std140_vector_float_4_4 uClipmapOrigin;
    _Array_std140_vector_float_4_7 uSkySh;
    vec4 uUnproject;
    vec4 uPrevUnproject;
    vec3 uViewToWorld0;
    vec3 uViewToWorld1;
    vec3 uViewToWorld2;
    vec3 uCameraToCache;
    vec3 uTraceOrigin;
    vec3 uPrevWorldToView0;
    vec3 uPrevWorldToView1;
    vec3 uPrevWorldToView2;
    vec3 uPrevCameraToCache;
    vec3 uColourWorldToView0;
    vec3 uColourWorldToView1;
    vec3 uColourWorldToView2;
    vec3 uColourCameraToCache;
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
    vec4 uTerrainMap0;
    vec4 uTerrainMap1;
    vec4 uShelterMap0;
    vec4 uShelterMap1;
    vec4 uShelterMap2;
    int uHasHistory;
    int uFrameIndex;
    int uMaxAccumulated;
    int uHasVelocity;
    int uGatherPass;
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
layout(binding = 1, rgba16f) uniform restrict writeonly image2D uPosition;
layout(binding = 5) uniform sampler2D _9344;
layout(binding = 6) uniform sampler2D _9346;
layout(binding = 8) uniform sampler2D _9349;
layout(binding = 9) uniform sampler2D _9351;
layout(binding = 3) uniform sampler3D _9353;
layout(binding = 12) uniform sampler2D _9356;
layout(binding = 0) uniform sampler2D _9359;
layout(binding = 1) uniform sampler2D _9361;
layout(binding = 2) uniform sampler2D _9363;
layout(binding = 4) uniform sampler2D _9365;
layout(binding = 13) uniform sampler2D _9368;
layout(binding = 10) uniform sampler2D _9371;
layout(binding = 11) uniform sampler2D _9373;
layout(binding = 7) uniform sampler2D _9376;

void main()
{
    bool _7214 = false;
    bool _7116 = false;
    bool _7018 = false;
    bool _6920 = false;
    bool _6822 = false;
    bool _6724 = false;
    bool _6626 = false;
    bool _5653 = false;
    bool _5543 = false;
    bool _5462 = false;
    {
        ivec2 _233 = ivec2(gl_GlobalInvocationID.xy);
        ivec2 grid = (ivec2(Globals.uScreenWidth, Globals.uScreenHeight) + ivec2(Globals.uProbeStep - 1)) / ivec2(Globals.uProbeStep);
        bool ownMotion;
        if (_233.x >= grid.x)
        {
            ownMotion = true;
        }
        else
        {
            ownMotion = _233.y >= grid.y;
        }
        if (!(ownMotion))
        {
            vec3 world;
            vec3 viewPosition;
            vec3 worldNormal;
            bool _4181;
            {
                world = vec3(0.0);
                viewPosition = vec3(0.0);
                worldNormal = vec3(0.0, 0.0, 1.0);
                uint _4257 = uint(Globals.uFrameIndex);
                uint _4258 = _4257 & 7u;
                vec2 _4210 = (vec2(min(((_233 * ivec2(Globals.uProbeStep)) + min(ivec2(floor(((vec2(float(_4258), float((((_4257 & 1u) << uint(2)) | (_4257 & 2u)) | ((_4258 >> uint(2)) & 1u))) + vec2(0.5)) * vec2(0.125)) * float(Globals.uProbeStep))), ivec2(Globals.uProbeStep - 1))), (ivec2(Globals.uScreenWidth, Globals.uScreenHeight) - ivec2(1)))) + vec2(0.5)) / vec2(float(Globals.uScreenWidth), float(Globals.uScreenHeight));
                vec4 _4284 = textureLod(_9344, _4210, 0.0);
                float _4285 = _4284.x;
                if (_4285 <= 0.0)
                {
                    _4181 = false;
                }
                else
                {
                    float _4304 = ((2.0 * Globals.uUnproject.z) * Globals.uUnproject.w) / ((Globals.uUnproject.w + Globals.uUnproject.z) - ((1.0 - (2.0 * _4285)) * (Globals.uUnproject.w - Globals.uUnproject.z)));
                    vec2 _4307 = (_4210 * 2.0) - vec2(1.0);
                    vec3 _4319 = vec3((_4307.x * _4304) / Globals.uUnproject.x, ((-1.0) * (_4307.y * _4304)) / Globals.uUnproject.y, _4304);
                    viewPosition = _4319;
                    vec3 _4233 = ((Globals.uCameraToCache + (Globals.uViewToWorld0 * _4319.x)) + (Globals.uViewToWorld1 * _4319.y)) + (Globals.uViewToWorld2 * _4319.z);
                    world = _4233;
                    vec3 _4243 = normalize((textureLod(_9346, _4210, 0.0).xyz * 2.0) - vec3(1.0));
                    worldNormal = _4243;
                    if (dot(_4243, _4233 - Globals.uCameraToCache) > 0.0)
                    {
                        worldNormal = -worldNormal;
                    }
                    _4181 = true;
                }
            }
            vec3 nMin;
            float nCount;
            if (Globals.uGatherPass == 0)
            {
                if (_4181)
                {
                    vec2 _4321;
                    {
                        if (Globals.uFrameIndex <= 0)
                        {
                            _4321 = vec2(0.5);
                        }
                        else
                        {
                            float _4336 = float(((uint(_233.x) * 73856093u) ^ (uint(_233.y) * 19349663u)) & 65535u);
                            uint _4339 = uint(Globals.uFrameIndex & 65535);
                            uint _4356 = (_4339 << 16u) | (_4339 >> 16u);
                            uint _4361 = ((_4356 & 1431655765u) << 1u) | ((_4356 & 2863311530u) >> 1u);
                            uint _4366 = ((_4361 & 858993459u) << 2u) | ((_4361 & 3435973836u) >> 2u);
                            uint _4371 = ((_4366 & 252645135u) << 4u) | ((_4366 & 4042322160u) >> 4u);
                            _4321 = fract(vec2(fract(float(_4339) * 0.61803400516510009765625), float(((_4371 & 16711935u) << 8u) | ((_4371 & 4278255360u) >> 8u)) * 2.3283064365386962890625e-10) + vec2(_4336 * 1.52587890625e-05, fract(_4336 * 2.4689239580766297876834869384766e-05)));
                        }
                    }
                    vec3 _4380;
                    {
                        bool _4381;
                        if (Globals.uShadowLevels <= 0)
                        {
                            _4381 = true;
                        }
                        else
                        {
                            _4381 = Globals.uLookupBuckets <= 0;
                        }
                        if (_4381)
                        {
                            _4380 = vec3(0.0);
                        }
                        else
                        {
                            vec3 _9287;
                            vec3 _9288;
                            vec3 _9289;
                            {
                                vec3 _9302 = worldNormal;
                                if (worldNormal.z < (-0.99999988079071044921875))
                                {
                                    _9287 = vec3(0.0, -1.0, 0.0);
                                    _9288 = vec3(-1.0, 0.0, 0.0);
                                    _9289 = _9302;
                                }
                                else
                                {
                                    float _4800 = 1.0 / (1.0 + worldNormal.z);
                                    float _4802 = -worldNormal.x;
                                    float _4805 = (_4802 * worldNormal.y) * _4800;
                                    _9287 = vec3(1.0 - ((worldNormal.x * worldNormal.x) * _4800), _4805, _4802);
                                    _9288 = vec3(_4805, 1.0 - ((worldNormal.y * worldNormal.y) * _4800), -worldNormal.y);
                                    _9289 = _9302;
                                }
                            }
                            vec3 _4831 = vec3(dot(Globals.uViewToWorld0, worldNormal), dot(Globals.uViewToWorld1, worldNormal), dot(Globals.uViewToWorld2, worldNormal));
                            int _4382 = 0;
                            vec3 _4383 = vec3(0.0);
                            float _4386 = 0.0;
                            float _4387 = 0.0;
                            vec3 _4384 = vec3(0.0);
                            float _4388 = 0.0;
                            vec3 _4385 = vec3(0.0);
                            float _4389 = 0.0;
                            vec3 _4390;
                            int _4392;
                            vec3 _4393;
                            bool _4394;
                            int _4395;
                            vec3 _4396;
                            vec3 _4397;
                            vec3 _4398;
                            vec3 _4399;
                            float _4400;
                            float _4401;
                            float _4402;
                            float _4403;
                            vec3 _4404;
                            bool _4405;
                            bool _4406;
                            int _4407;
                            vec3 _4408;
                            float _4409;
                            vec3 _4410;
                            vec2 _4412;
                            bool _4414;
                            float _4415;
                            vec3 _4416;
                            bool _4417;
                            bool _4861;
                            bool _4862;
                            vec3 _4863;
                            float _4866;
                            bool _4867;
                            vec3 _5444;
                            float _5463;
                            bool _5466;
                            bool _5467;
                            float _5469;
                            float _5544;
                            bool _5546;
                            float _5654;
                            bool _5655;
                            float _5773;
                            bool _5798;
                            float _5836;
                            float _5861;
                            bool _5886;
                            float _5924;
                            bool _5954;
                            ivec2 _5959;
                            bool _5970;
                            bool _5971;
                            vec3 _5973[4];
                            float _5976;
                            ivec2 _6341;
                            vec3 _6438;
                            vec3 _6457;
                            vec3 _6509;
                            vec3 _6560;
                            vec3 _6579;
                            bool _6580;
                            float _6582;
                            vec3 _6586;
                            bool _6629;
                            float _6725;
                            bool _6727;
                            float _6823;
                            bool _6825;
                            float _6921;
                            bool _6923;
                            float _7019;
                            bool _7021;
                            float _7117;
                            bool _7119;
                            float _7215;
                            bool _7217;
                            bool _7313;
                            bool _7379;
                            float _7417;
                            bool _7442;
                            bool _7458;
                            bool _7524;
                            float _7562;
                            bool _7587;
                            bool _7607;
                            ivec2 _7612;
                            bool _7623;
                            bool _7624;
                            vec3 _7626[4];
                            float _7629;
                            ivec2 _7994;
                            bool _8096;
                            bool _8102;
                            ivec2 _8103;
                            bool _8107;
                            bool _8116;
                            bool _8117;
                            bool _8118;
                            bool _8119;
                            bool _8120;
                            ivec2 _8350;
                            vec3 _8447;
                            vec3 _8465;
                            vec3 _8483;
                            for (;;)
                            {
                                if (!(_4382 < 16))
                                {
                                    break;
                                }
                                vec2 _4452 = (vec2(float(_4382 - 4 * (_4382 / 4)), float(_4382 / 4)) + _4321) * vec2(0.25);
                                float _4454 = 6.283185482025146484375 * _4452.x;
                                float _4456 = sqrt(_4452.y);
                                float _4458 = 1.0 - (_4456 * _4456);
                                float _4460 = sqrt(isnan(_4458) ? 0.0 : (isnan(0.0) ? _4458 : max(0.0, _4458)));
                                vec3 _4847 = ((_9287 * (_4460 * cos(_4454))) + (_9288 * (_4460 * sin(_4454)))) + (_9289 * _4456);
                                if (Globals.uScreenTraceSteps > 0)
                                {
                                    vec3 _4859 = vec3(dot(Globals.uViewToWorld0, _4847), dot(Globals.uViewToWorld1, _4847), dot(Globals.uViewToWorld2, _4847));
                                    {
                                        _4393 = vec3(0.0);
                                        if (Globals.uScreenTraceSteps <= 0)
                                        {
                                            _4862 = true;
                                        }
                                        else
                                        {
                                            _4862 = _4859.z == 0.0;
                                        }
                                        if (_4862)
                                        {
                                            _4861 = false;
                                        }
                                        else
                                        {
                                            vec3 _4885 = viewPosition + (_4831 * 0.0199999995529651641845703125);
                                            vec3 _4889 = _4885 + (_4859 * Globals.uScreenTraceDistance);
                                            if (_4889.z < (Globals.uUnproject.z + 0.00999999977648258209228515625))
                                            {
                                                _4863 = _4885 + (_4859 * (((Globals.uUnproject.z + 0.00999999977648258209228515625) - _4885.z) / _4859.z));
                                            }
                                            else
                                            {
                                                _4863 = _4889;
                                            }
                                            if (_4863.z <= Globals.uUnproject.z)
                                            {
                                                _4861 = false;
                                            }
                                            else
                                            {
                                                float _5252 = _4885.z;
                                                vec2 _5263 = (vec2((_4885.x * Globals.uUnproject.x) / _5252, ((-1.0) * (_4885.y * Globals.uUnproject.y)) / _5252) * 0.5) + vec2(0.5);
                                                vec2 _4918 = ((vec2((_4863.x * Globals.uUnproject.x) / _4863.z, ((-1.0) * (_4863.y * Globals.uUnproject.y)) / _4863.z) * 0.5) + vec2(0.5)) - _5263;
                                                int _4933 = int(clamp(length(_4918 / (vec2(1.0) / vec2(float(Globals.uScreenWidth), float(Globals.uScreenHeight)))), 1.0, float(Globals.uScreenTraceSteps)));
                                                float _4935 = 1.0 / float(_4933);
                                                float _4952 = fract(52.98291778564453125 * fract(dot((_5263 * vec2(float(Globals.uScreenWidth), float(Globals.uScreenHeight))) + vec2(5.588237762451171875 * float(Globals.uFrameIndex & 63)), vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));
                                                float _4864 = 0.0;
                                                int _4865 = 1;
                                                for (;;)
                                                {
                                                    if (!(_4865 <= 256))
                                                    {
                                                        _4866 = -1.0;
                                                        break;
                                                    }
                                                    if (_4865 > _4933)
                                                    {
                                                        _4866 = -1.0;
                                                        break;
                                                    }
                                                    float _4969 = _4935 * (float(_4865) + _4952);
                                                    if (_4969 > 1.0)
                                                    {
                                                        _4866 = -1.0;
                                                        break;
                                                    }
                                                    vec2 _4974 = _5263 + (_4918 * _4969);
                                                    if (any(lessThan(_4974, vec2(0.0))))
                                                    {
                                                        _4862 = true;
                                                    }
                                                    else
                                                    {
                                                        _4862 = any(greaterThan(_4974, vec2(1.0)));
                                                    }
                                                    if (_4862)
                                                    {
                                                        _4866 = -1.0;
                                                        break;
                                                    }
                                                    float _4985 = _4885.z;
                                                    float _5304 = ((2.0 * Globals.uUnproject.z) * Globals.uUnproject.w) / ((Globals.uUnproject.w + Globals.uUnproject.z) - ((1.0 - (2.0 * textureLod(_9344, _4974, 0.0).x)) * (Globals.uUnproject.w - Globals.uUnproject.z)));
                                                    vec2 _5307 = (_4974 * 2.0) - vec2(1.0);
                                                    vec3 _5319 = vec3(_9339, _9339, _5304);
                                                    float _4993 = _5319.z;
                                                    float _4994 = (1.0 / mix(1.0 / _4985, 1.0 / _4863.z, _4969)) - _4993;
                                                    if (_4994 > 0.0)
                                                    {
                                                        _4867 = _4994 < (Globals.uScreenThickness + (_4993 * 0.0199999995529651641845703125));
                                                    }
                                                    else
                                                    {
                                                        _4867 = false;
                                                    }
                                                    if (_4867)
                                                    {
                                                        _4866 = _4864;
                                                        float _4868 = _4969;
                                                        int _4869 = 0;
                                                        for (;;)
                                                        {
                                                            if (!(_4869 < 4))
                                                            {
                                                                break;
                                                            }
                                                            float _5016 = _4868;
                                                            float _5018 = (_4866 + _5016) * 0.5;
                                                            vec2 _5024 = _5263 + (_4918 * _5018);
                                                            float _5341 = ((2.0 * Globals.uUnproject.z) * Globals.uUnproject.w) / ((Globals.uUnproject.w + Globals.uUnproject.z) - ((1.0 - (2.0 * textureLod(_9344, _5024, 0.0).x)) * (Globals.uUnproject.w - Globals.uUnproject.z)));
                                                            vec2 _5344 = (_5024 * 2.0) - vec2(1.0);
                                                            if (((1.0 / mix(1.0 / _4985, 1.0 / _4863.z, _5018)) - vec3(_9339, _9339, _5341).z) > 0.0)
                                                            {
                                                                _4868 = _5018;
                                                            }
                                                            else
                                                            {
                                                                _4866 = _5018;
                                                            }
                                                            _4869++;
                                                            continue;
                                                        }
                                                        _4866 = _4868;
                                                        break;
                                                    }
                                                    _4864 = _4969;
                                                    _4865++;
                                                    continue;
                                                }
                                                if (_4866 <= 0.0)
                                                {
                                                    _4861 = false;
                                                }
                                                else
                                                {
                                                    vec2 _5054 = _5263 + (_4918 * _4866);
                                                    vec3 _5063 = (textureLod(_9346, _5054, 0.0).xyz * 2.0) - vec3(1.0);
                                                    vec3 _5368 = vec3(dot(Globals.uViewToWorld0, _5063), dot(Globals.uViewToWorld1, _5063), dot(Globals.uViewToWorld2, _5063));
                                                    if (dot(_5368, _4859) >= 0.0)
                                                    {
                                                        _4861 = false;
                                                    }
                                                    else
                                                    {
                                                        float _5390 = ((2.0 * Globals.uUnproject.z) * Globals.uUnproject.w) / ((Globals.uUnproject.w + Globals.uUnproject.z) - ((1.0 - (2.0 * textureLod(_9344, _5054, 0.0).x)) * (Globals.uUnproject.w - Globals.uUnproject.z)));
                                                        vec2 _5393 = (_5054 * 2.0) - vec2(1.0);
                                                        vec3 _5405 = vec3((_5393.x * _5390) / Globals.uUnproject.x, ((-1.0) * (_5393.y * _5390)) / Globals.uUnproject.y, _5390);
                                                        vec3 _5088 = ((Globals.uCameraToCache + (Globals.uViewToWorld0 * _5405.x)) + (Globals.uViewToWorld1 * _5405.y)) + (Globals.uViewToWorld2 * _5405.z);
                                                        float _5091 = _5088.x;
                                                        float _5099 = _5088.y;
                                                        float _5107 = _5088.z;
                                                        vec3 _5112 = ((Globals.uColourWorldToView0 * (_5091 - Globals.uColourCameraToCache.x)) + (Globals.uColourWorldToView1 * (_5099 - Globals.uColourCameraToCache.y))) + (Globals.uColourWorldToView2 * (_5107 - Globals.uColourCameraToCache.z));
                                                        if (Globals.uHasHistory == 0)
                                                        {
                                                            _4862 = true;
                                                        }
                                                        else
                                                        {
                                                            _4862 = _5112.z <= Globals.uUnproject.z;
                                                        }
                                                        if (_4862)
                                                        {
                                                            _4861 = false;
                                                        }
                                                        else
                                                        {
                                                            float _5413 = _5112.z;
                                                            vec2 _5424 = (vec2((_5112.x * Globals.uUnproject.x) / _5413, ((-1.0) * (_5112.y * Globals.uUnproject.y)) / _5413) * 0.5) + vec2(0.5);
                                                            if (any(lessThan(_5424, vec2(0.0))))
                                                            {
                                                                _4862 = true;
                                                            }
                                                            else
                                                            {
                                                                _4862 = any(greaterThan(_5424, vec2(1.0)));
                                                            }
                                                            if (_4862)
                                                            {
                                                                _4861 = false;
                                                            }
                                                            else
                                                            {
                                                                vec3 _5157 = ((Globals.uPrevWorldToView0 * (_5091 - Globals.uPrevCameraToCache.x)) + (Globals.uPrevWorldToView1 * (_5099 - Globals.uPrevCameraToCache.y))) + (Globals.uPrevWorldToView2 * (_5107 - Globals.uPrevCameraToCache.z));
                                                                float _5158 = _5157.z;
                                                                if (_5158 <= Globals.uUnproject.z)
                                                                {
                                                                    _4861 = false;
                                                                }
                                                                else
                                                                {
                                                                    float _5432 = _5157.z;
                                                                    vec4 _5191 = texelFetch(_9349, ivec3(clamp(ivec2(((vec2((_5157.x * Globals.uUnproject.x) / _5432, ((-1.0) * (_5157.y * Globals.uUnproject.y)) / _5432) * 0.5) + vec2(0.5)) * vec2(float(Globals.uScreenWidth), float(Globals.uScreenHeight))) / ivec2(Globals.uProbeStep), ivec2(0), ((ivec2(Globals.uScreenWidth, Globals.uScreenHeight) + ivec2(Globals.uProbeStep - 1)) / ivec2(Globals.uProbeStep)) - ivec2(1)), 0).xy, 0);
                                                                    if (_5191.w <= 0.0)
                                                                    {
                                                                        _4862 = true;
                                                                    }
                                                                    else
                                                                    {
                                                                        float _5224 = 2.0 * (((2.0 * _5158) * float(Globals.uProbeStep)) / (Globals.uUnproject.y * float(Globals.uScreenHeight)));
                                                                        _4862 = abs(dot((_5191.xyz + Globals.uPrevCameraToCache) - _5088, normalize(((Globals.uViewToWorld0 * _5368.x) + (Globals.uViewToWorld1 * _5368.y)) + (Globals.uViewToWorld2 * _5368.z)))) > (isnan(_5224) ? 0.100000001490116119384765625 : (isnan(0.100000001490116119384765625) ? _5224 : max(0.100000001490116119384765625, _5224)));
                                                                    }
                                                                    if (_4862)
                                                                    {
                                                                        _4861 = false;
                                                                    }
                                                                    else
                                                                    {
                                                                        vec4 _5235 = textureLod(_9351, _5424, 0.0);
                                                                        if (_5235.w < 0.5)
                                                                        {
                                                                            _4861 = false;
                                                                        }
                                                                        else
                                                                        {
                                                                            vec3 _5241 = _5235.xyz;
                                                                            float _5447 = _5235.x;
                                                                            float _5448 = _5235.y;
                                                                            float _5449 = _5235.z;
                                                                            float _5450 = isnan(_5449) ? _5448 : (isnan(_5448) ? _5449 : max(_5448, _5449));
                                                                            float _5451 = isnan(_5450) ? _5447 : (isnan(_5447) ? _5450 : max(_5447, _5450));
                                                                            if (_5451 > Globals.uMaxRayIntensity)
                                                                            {
                                                                                _5444 = _5241 * (Globals.uMaxRayIntensity / _5451);
                                                                            }
                                                                            else
                                                                            {
                                                                                _5444 = _5241;
                                                                            }
                                                                            _4393 = _5444;
                                                                            _4861 = true;
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
                                    if (_4861)
                                    {
                                        _4392 = 1;
                                        _4390 = _4393;
                                    }
                                    else
                                    {
                                        _4392 = 0;
                                        _4390 = vec3(0.0);
                                    }
                                    _4381 = _4861;
                                }
                                else
                                {
                                    _4381 = false;
                                    _4392 = 0;
                                    _4390 = vec3(0.0);
                                }
                                if (!_4381)
                                {
                                    _5462 = false;
                                    {
                                        _4404 = world;
                                        if (Globals.uShadowLevels <= 0)
                                        {
                                            _5462 = true;
                                            _5463 = 1.0;
                                        }
                                        else
                                        {
                                            vec3 _5486 = world + ((worldNormal * Globals.uClipmapOrigin.data[0].w) * 1.5);
                                            float _5497 = (Globals.uClipmapOrigin.data[0].w * float(Globals.uShadowResolution)) * float(1 << (Globals.uShadowLevels - 1));
                                            int _5464 = 0;
                                            float _5465 = 0.0;
                                            for (;;)
                                            {
                                                if (_5464 < 64)
                                                {
                                                    _5466 = _5465 < _5497;
                                                }
                                                else
                                                {
                                                    _5466 = false;
                                                }
                                                if (!_5466)
                                                {
                                                    break;
                                                }
                                                vec3 _5514 = _5486 + (_4847 * _5465);
                                                _5543 = false;
                                                {
                                                    _5467 = false;
                                                    _5469 = Globals.uClipmapOrigin.data[0].w;
                                                    int _5545 = 0;
                                                    for (;;)
                                                    {
                                                        bool _5557_ladder_break = false;
                                                        {
                                                            if (!(_5545 < Globals.uShadowLevels))
                                                            {
                                                                _5557_ladder_break = true;
                                                            }
                                                            else
                                                            {
                                                                vec3 _5572 = (_5514 - Globals.uClipmapOrigin.data[_5545].xyz) / vec3(Globals.uClipmapOrigin.data[_5545].w);
                                                                if (any(lessThan(_5572, vec3(0.5))))
                                                                {
                                                                    _5546 = true;
                                                                }
                                                                else
                                                                {
                                                                    _5546 = any(greaterThan(_5572, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                }
                                                                if (!(_5546))
                                                                {
                                                                    _5467 = true;
                                                                    _5469 = Globals.uClipmapOrigin.data[_5545].w;
                                                                    _5543 = true;
                                                                    _5544 = ((textureLod(_9353, vec3(_5572.x / float(Globals.uShadowResolution), _5572.y / float(Globals.uShadowResolution), ((float(_5545) * float(Globals.uShadowResolution)) + _5572.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_5545];
                                                                    _5557_ladder_break = true;
                                                                }
                                                            }
                                                        }
                                                        if (_5557_ladder_break)
                                                        {
                                                            break;
                                                        }
                                                        _5545++;
                                                        continue;
                                                    }
                                                    if (!(_5543))
                                                    {
                                                        _5543 = true;
                                                        _5544 = 1000000.0;
                                                    }
                                                }
                                                if (!_5467)
                                                {
                                                    _5462 = true;
                                                    _5463 = 1.0;
                                                    break;
                                                }
                                                float _5644 = 2.0 * _5469;
                                                float _5648 = (0.5 * _5469) * clamp(_5465 / (isnan(9.9999999747524270787835121154785e-07) ? _5644 : (isnan(_5644) ? 9.9999999747524270787835121154785e-07 : max(_5644, 9.9999999747524270787835121154785e-07))), 0.0, 1.0);
                                                float _5650 = (_5465 + _5544) - _5648;
                                                float _5470 = isnan(0.0) ? _5650 : (isnan(_5650) ? 0.0 : max(_5650, 0.0));
                                                if (_5544 < _5648)
                                                {
                                                    _4404 = _5486 + (_4847 * _5470);
                                                    _5462 = true;
                                                    _5463 = 0.0;
                                                    break;
                                                }
                                                float _5529 = _5469 * 0.25;
                                                _5464++;
                                                _5465 += (isnan(_5529) ? _5544 : (isnan(_5544) ? _5529 : max(_5544, _5529)));
                                                continue;
                                            }
                                            if (!(_5462))
                                            {
                                                _5462 = true;
                                                _5463 = 1.0;
                                            }
                                        }
                                    }
                                    bool _4491 = _5463 <= 0.5;
                                    vec3 _4493 = world + (worldNormal * 0.100000001490116119384765625);
                                    vec3 _4496 = _4493 + Globals.uTraceOrigin;
                                    _5653 = false;
                                    {
                                        if (Globals.uTerrainMap0.w < 0.5)
                                        {
                                            _5655 = true;
                                        }
                                        else
                                        {
                                            _5655 = _4847.z > (-0.00999999977648258209228515625);
                                        }
                                        if (_5655)
                                        {
                                            _5655 = true;
                                        }
                                        else
                                        {
                                            _5655 = Globals.uTerrainMap0.z <= 0.0;
                                        }
                                        if (_5655)
                                        {
                                            _5653 = true;
                                            _5654 = -1.0;
                                        }
                                        else
                                        {
                                            float _5684 = 0.5 / Globals.uTerrainMap0.z;
                                            float _5656 = 0.0;
                                            int _5657 = 1;
                                            for (;;)
                                            {
                                                if (!(_5657 <= 64))
                                                {
                                                    break;
                                                }
                                                float _5695 = float(_5657) * _5684;
                                                float _5696 = isnan(32.0) ? _5695 : (isnan(_5695) ? 32.0 : min(_5695, 32.0));
                                                vec3 _5698 = _4496 + (_4847 * _5696);
                                                float _9265 = Globals.uTerrainMap1.z;
                                                float _9266 = Globals.uTerrainMap1.w;
                                                vec2 _9267 = Globals.uTerrainMap1.xy;
                                                ivec2 _5797 = ivec2(floor((_5698.xy - Globals.uTerrainMap0.xy) * Globals.uTerrainMap0.z));
                                                if (Globals.uTerrainMap0.w > 0.5)
                                                {
                                                    _5798 = _5797.x >= 0;
                                                }
                                                else
                                                {
                                                    _5798 = false;
                                                }
                                                if (_5798)
                                                {
                                                    _5798 = _5797.y >= 0;
                                                }
                                                else
                                                {
                                                    _5798 = false;
                                                }
                                                if (_5798)
                                                {
                                                    _5798 = _5797.x < int(_9267.x);
                                                }
                                                else
                                                {
                                                    _5798 = false;
                                                }
                                                if (_5798)
                                                {
                                                    _5798 = _5797.y < int(_9267.y);
                                                }
                                                else
                                                {
                                                    _5798 = false;
                                                }
                                                if (_5798)
                                                {
                                                    vec4 _5783 = texelFetch(_9356, ivec3(_5797, 0).xy, 0);
                                                    float _5848 = floor((_5783.z * 255.0) + 0.5) + (floor((_5783.y * 255.0) + 0.5) * 256.0);
                                                    if (_5848 < 0.5)
                                                    {
                                                        _5836 = -1000000015047466219876688855040.0;
                                                    }
                                                    else
                                                    {
                                                        _5836 = _9265 + ((_5848 - 1.0) * _9266);
                                                    }
                                                    _5773 = _5836;
                                                }
                                                else
                                                {
                                                    _5773 = -1000000015047466219876688855040.0;
                                                }
                                                if (_5698.z <= _5773)
                                                {
                                                    float _5659 = _5656;
                                                    float _5660 = _5696;
                                                    int _5661 = 0;
                                                    for (;;)
                                                    {
                                                        if (!(_5661 < 4))
                                                        {
                                                            break;
                                                        }
                                                        float _5714 = _5660;
                                                        float _5716 = (_5659 + _5714) * 0.5;
                                                        vec3 _5718 = _4496 + (_4847 * _5716);
                                                        float _9277 = Globals.uTerrainMap1.z;
                                                        float _9278 = Globals.uTerrainMap1.w;
                                                        vec2 _9279 = Globals.uTerrainMap1.xy;
                                                        ivec2 _5885 = ivec2(floor((_5718.xy - Globals.uTerrainMap0.xy) * Globals.uTerrainMap0.z));
                                                        if (Globals.uTerrainMap0.w > 0.5)
                                                        {
                                                            _5886 = _5885.x >= 0;
                                                        }
                                                        else
                                                        {
                                                            _5886 = false;
                                                        }
                                                        if (_5886)
                                                        {
                                                            _5886 = _5885.y >= 0;
                                                        }
                                                        else
                                                        {
                                                            _5886 = false;
                                                        }
                                                        if (_5886)
                                                        {
                                                            _5886 = _5885.x < int(_9279.x);
                                                        }
                                                        else
                                                        {
                                                            _5886 = false;
                                                        }
                                                        if (_5886)
                                                        {
                                                            _5886 = _5885.y < int(_9279.y);
                                                        }
                                                        else
                                                        {
                                                            _5886 = false;
                                                        }
                                                        if (_5886)
                                                        {
                                                            vec4 _5871 = texelFetch(_9356, ivec3(_5885, 0).xy, 0);
                                                            float _5936 = floor((_5871.z * 255.0) + 0.5) + (floor((_5871.y * 255.0) + 0.5) * 256.0);
                                                            if (_5936 < 0.5)
                                                            {
                                                                _5924 = -1000000015047466219876688855040.0;
                                                            }
                                                            else
                                                            {
                                                                _5924 = _9277 + ((_5936 - 1.0) * _9278);
                                                            }
                                                            _5861 = _5924;
                                                        }
                                                        else
                                                        {
                                                            _5861 = -1000000015047466219876688855040.0;
                                                        }
                                                        if (_5718.z <= _5861)
                                                        {
                                                            _5660 = _5716;
                                                        }
                                                        else
                                                        {
                                                            _5659 = _5716;
                                                        }
                                                        _5661++;
                                                        continue;
                                                    }
                                                    _5653 = true;
                                                    _5654 = _5660;
                                                    break;
                                                }
                                                if (_5696 >= 32.0)
                                                {
                                                    break;
                                                }
                                                _5656 = _5696;
                                                _5657++;
                                                continue;
                                            }
                                            if (!(_5653))
                                            {
                                                _5653 = true;
                                                _5654 = -1.0;
                                            }
                                        }
                                    }
                                    if (_5654 >= 0.0)
                                    {
                                        if (!_4491)
                                        {
                                            _4394 = true;
                                        }
                                        else
                                        {
                                            _4394 = length(_4404 - world) > _5654;
                                        }
                                    }
                                    else
                                    {
                                        _4394 = false;
                                    }
                                    if (_4394)
                                    {
                                        vec3 _4519 = _4493 + (_4847 * _5654);
                                        float _4525 = 0.5 * Globals.uClipmapOrigin.data[0].w;
                                        {
                                            _4410 = vec3(0.0);
                                            if (Globals.uLookupBuckets <= 0)
                                            {
                                                _5954 = false;
                                            }
                                            else
                                            {
                                                ivec3 _5993 = ivec3(floor((_4519 - Globals.uLookupMin) / vec3(Globals.uLookupCell)));
                                                int _6340 = int((((uint(_5993.x) * 2376512323u) ^ (uint(_5993.y) * 3625334849u)) ^ (uint(_5993.z) * 3407524639u)) & uint(Globals.uLookupBuckets - 1));
                                                uvec2 _5998 = uvec2(textureSize(_9359, 0));
                                                vec2 _6005 = vec2(float(_5998.x), float(_5998.y));
                                                int _5957 = 0;
                                                float _5958 = 0.0;
                                                for (;;)
                                                {
                                                    if (!(_5957 <= uCells._member0[Globals.uLookupBuckets].y))
                                                    {
                                                        break;
                                                    }
                                                    bool _6019 = _5957 == 0;
                                                    if (_6019)
                                                    {
                                                        _5959 = uCells._member0[_6340];
                                                    }
                                                    else
                                                    {
                                                        int _6345 = uCells._member0[Globals.uLookupBuckets].x + ((_5957 - 1) * 6);
                                                        float _6362 = intBitsToFloat(uCellPages_1._member0[_6345 + 3]) + _4525;
                                                        vec3 _6363 = _4519 - vec3(intBitsToFloat(uCellPages_1._member0[_6345]), intBitsToFloat(uCellPages_1._member0[_6345 + 1]), intBitsToFloat(uCellPages_1._member0[_6345 + 2]));
                                                        if (dot(_6363, _6363) > (_6362 * _6362))
                                                        {
                                                            _6341 = ivec2(0);
                                                        }
                                                        else
                                                        {
                                                            _6341 = ivec2(uCellPages_1._member0[_6345 + 4], uCellPages_1._member0[_6345 + 5]);
                                                        }
                                                        _5959 = _6341;
                                                    }
                                                    int _5960 = 0;
                                                    float _5961 = _5958;
                                                    for (;;)
                                                    {
                                                        bool _6030_ladder_break = false;
                                                        {
                                                            if (!(_5960 < _5959.y))
                                                            {
                                                                _6030_ladder_break = true;
                                                            }
                                                            else
                                                            {
                                                                int _6041 = _5959.x + _5960;
                                                                int _6044 = uCellPages_1._member0[_6041] * 10;
                                                                if (!((uPages._member0[_6044 + 5].w > 0.5) == _6019))
                                                                {
                                                                    int _6053 = _6044 + 9;
                                                                    vec3 _6057 = _4519 - uPages._member0[_6053].xyz;
                                                                    float _6059 = uPages._member0[_6053].w + _4525;
                                                                    if (!(dot(_6057, _6057) > (_6059 * _6059)))
                                                                    {
                                                                        int _6379 = uCellPages_1._member0[_6041] * 10;
                                                                        vec4 _5968 = uPages._member0[_6379];
                                                                        vec4 _5969 = uPages._member0[_6379 + 1];
                                                                        int _6385 = _6379 + 2;
                                                                        int _6388 = _6379 + 3;
                                                                        int _6391 = _6379 + 4;
                                                                        int _6397 = _6379 + 6;
                                                                        int _6400 = _6379 + 7;
                                                                        int _6403 = _6379 + 8;
                                                                        vec3 _6410 = _4519 - vec3(uPages._member0[_6397].w, uPages._member0[_6400].w, uPages._member0[_6403].w);
                                                                        vec3 _6423 = vec3(dot(uPages._member0[_6397].xyz, _6410), dot(uPages._member0[_6400].xyz, _6410), dot(uPages._member0[_6403].xyz, _6410)) - uPages._member0[_6385].xyz;
                                                                        vec2 _6426 = vec2(uPages._member0[_6385].w, uPages._member0[_6388].w);
                                                                        bvec2 _9418 = isnan(_6426);
                                                                        bvec2 _9419 = isnan(vec2(9.9999999747524270787835121154785e-07));
                                                                        vec2 _9420 = max(_6426, vec2(9.9999999747524270787835121154785e-07));
                                                                        vec2 _9421 = vec2(_9418.x ? vec2(9.9999999747524270787835121154785e-07).x : _9420.x, _9418.y ? vec2(9.9999999747524270787835121154785e-07).y : _9420.y);
                                                                        vec2 _6427 = vec2(_9419.x ? _6426.x : _9421.x, _9419.y ? _6426.y : _9421.y);
                                                                        vec2 _5963 = _6427;
                                                                        vec2 _5962 = vec2(dot(_6423, uPages._member0[_6388].xyz), dot(_6423, uPages._member0[_6391].xyz)) / _6427;
                                                                        float _5964 = -dot(_6423, uPages._member0[_6379 + 5].xyz);
                                                                        float _5965 = uPages._member0[_6391].w;
                                                                        float _6068 = dot(uPages._member0[_6379 + 5].xyz, vec3(uPages._member0[_6397].z, uPages._member0[_6400].z, uPages._member0[_6403].z));
                                                                        if (!(_6068 <= 0.0))
                                                                        {
                                                                            float _6073 = Globals.uClipmapOrigin.data[0].w * 0.25;
                                                                            vec2 _6076 = vec2(_6073) / _5963;
                                                                            if (abs(_5962.x) > (1.0 + _6076.x))
                                                                            {
                                                                                _5970 = true;
                                                                            }
                                                                            else
                                                                            {
                                                                                _5970 = abs(_5962.y) > (1.0 + _6076.y);
                                                                            }
                                                                            if (!(_5970))
                                                                            {
                                                                                if (_5964 < (Globals.uClipmapOrigin.data[0].w * (-0.25)))
                                                                                {
                                                                                    _5971 = true;
                                                                                }
                                                                                else
                                                                                {
                                                                                    _5971 = _5964 > (_5965 + _6073);
                                                                                }
                                                                                if (!(_5971))
                                                                                {
                                                                                    vec2 _6120 = (_5969.xy + (((clamp(_5962, vec2(-1.0), vec2(1.0)) * 0.5) + vec2(0.5)) * _5969.zw)) - vec2(0.5);
                                                                                    vec2 _6121 = floor(_6120);
                                                                                    vec2 _6122 = _6120 - _6121;
                                                                                    bvec2 _9423 = isnan(_5969.zw);
                                                                                    bvec2 _9424 = isnan(vec2(9.9999999747524270787835121154785e-07));
                                                                                    vec2 _9425 = max(_5969.zw, vec2(9.9999999747524270787835121154785e-07));
                                                                                    vec2 _9426 = vec2(_9423.x ? vec2(9.9999999747524270787835121154785e-07).x : _9425.x, _9423.y ? vec2(9.9999999747524270787835121154785e-07).y : _9425.y);
                                                                                    vec2 _6128 = _5968.zw / vec2(_9424.x ? _5969.zw.x : _9426.x, _9424.y ? _5969.zw.y : _9426.y);
                                                                                    float _6132 = _5964 / (isnan(9.9999999747524270787835121154785e-07) ? _5965 : (isnan(_5965) ? 9.9999999747524270787835121154785e-07 : max(_5965, 9.9999999747524270787835121154785e-07)));
                                                                                    float _6134 = 0.5 * _5965;
                                                                                    float _6136 = _4525 / (isnan(9.9999999747524270787835121154785e-07) ? _6134 : (isnan(_6134) ? 9.9999999747524270787835121154785e-07 : max(_6134, 9.9999999747524270787835121154785e-07)));
                                                                                    vec4 _5972 = vec4(0.0);
                                                                                    int _5975 = 0;
                                                                                    for (;;)
                                                                                    {
                                                                                        if (!(_5975 < 4))
                                                                                        {
                                                                                            break;
                                                                                        }
                                                                                        vec2 _6151 = vec2(float(_5975 & 1), float(_5975 >> 1));
                                                                                        vec2 _6154 = (_6121 + _6151) + vec2(0.5);
                                                                                        vec2 _6155 = _6154 / _6005;
                                                                                        if (textureLod(_9361, _6155, 0.0).w >= 0.5)
                                                                                        {
                                                                                            _5976 = 1.0;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            _5976 = 0.0;
                                                                                        }
                                                                                        vec2 _6184 = mix(vec2(1.0) - _6122, _6122, _6151);
                                                                                        _5972[_5975] = ((_6184.x * _6184.y) * _5976) * (1.0 - clamp((abs(_6132 - textureLod(_9363, _6155, 0.0).x) - _6136) / (0.25 * _6136), 0.0, 1.0));
                                                                                        _5973[_5975] = textureLod(_9365, (floor(_5968.xy + ((_6154 - _5969.xy) * _6128)) + vec2(0.5)) / Globals.uAtlasSize.xy, 0.0).xyz;
                                                                                        _5975++;
                                                                                        continue;
                                                                                    }
                                                                                    float _6231 = ((_5972.x + _5972.y) + _5972.z) + _5972.w;
                                                                                    float _6232 = (_6068 * _6068) * _6231;
                                                                                    if (!(_6232 <= 0.0))
                                                                                    {
                                                                                        vec3 _6260 = ((((_5973[0] * _5972.x) + (_5973[1] * _5972.y)) + (_5973[2] * _5972.z)) + (_5973[3] * _5972.w)) / vec3(_6231);
                                                                                        bvec3 _9438 = isnan(_6260);
                                                                                        bvec3 _9439 = isnan(vec3(0.0));
                                                                                        vec3 _9440 = max(_6260, vec3(0.0));
                                                                                        vec3 _9441 = vec3(_9438.x ? vec3(0.0).x : _9440.x, _9438.y ? vec3(0.0).y : _9440.y, _9438.z ? vec3(0.0).z : _9440.z);
                                                                                        _4410 += (vec3(_9439.x ? _6260.x : _9441.x, _9439.y ? _6260.y : _9441.y, _9439.z ? _6260.z : _9441.z) * _6232);
                                                                                        _5961 += _6232;
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        if (_6030_ladder_break)
                                                        {
                                                            break;
                                                        }
                                                        _5960++;
                                                        continue;
                                                    }
                                                    _5957++;
                                                    _5958 = _5961;
                                                    continue;
                                                }
                                                if (_5958 <= 0.0)
                                                {
                                                    _4410 = vec3(0.0);
                                                    _5954 = false;
                                                }
                                                else
                                                {
                                                    _4410 /= vec3(_5958);
                                                    _5954 = true;
                                                }
                                            }
                                        }
                                        if (_5954)
                                        {
                                            vec3 _4537 = _4410 * Globals.uBounceScale;
                                            float _6441 = _4537.x;
                                            float _6442 = _4537.y;
                                            float _6443 = _4537.z;
                                            float _6444 = isnan(_6443) ? _6442 : (isnan(_6442) ? _6443 : max(_6442, _6443));
                                            float _6445 = isnan(_6444) ? _6441 : (isnan(_6441) ? _6444 : max(_6441, _6444));
                                            if (_6445 > Globals.uMaxRayIntensity)
                                            {
                                                _6438 = _4537 * (Globals.uMaxRayIntensity / _6445);
                                            }
                                            else
                                            {
                                                _6438 = _4537;
                                            }
                                            _4405 = true;
                                            _4407 = 2;
                                            _4396 = _4537;
                                            _4408 = _4383 + _6438;
                                            _4409 = _4386 + 1.0;
                                        }
                                        else
                                        {
                                            _4405 = _4381;
                                            _4407 = _4392;
                                            _4396 = _4390;
                                            _4408 = _4383;
                                            _4409 = _4386;
                                        }
                                        _4406 = false;
                                    }
                                    else
                                    {
                                        _4405 = _4381;
                                        _4406 = _4491;
                                        _4407 = _4392;
                                        _4396 = _4390;
                                        _4408 = _4383;
                                        _4409 = _4386;
                                    }
                                    if (_4405)
                                    {
                                        _4395 = _4407;
                                        _4398 = _4396;
                                        _4401 = 1.0;
                                        _4399 = _4408;
                                        _4402 = _4409;
                                        _4403 = _4387;
                                        _4397 = _4384;
                                        _4400 = _4388;
                                    }
                                    else
                                    {
                                        if (_4406)
                                        {
                                            float _4576 = 1.5 * Globals.uClipmapOrigin.data[0].w;
                                            {
                                                _6626 = false;
                                                {
                                                    _6580 = false;
                                                    _6582 = Globals.uClipmapOrigin.data[0].w;
                                                    int _6628 = 0;
                                                    for (;;)
                                                    {
                                                        bool _6640_ladder_break = false;
                                                        {
                                                            if (!(_6628 < Globals.uShadowLevels))
                                                            {
                                                                _6640_ladder_break = true;
                                                            }
                                                            else
                                                            {
                                                                vec3 _6655 = (_4404 - Globals.uClipmapOrigin.data[_6628].xyz) / vec3(Globals.uClipmapOrigin.data[_6628].w);
                                                                if (any(lessThan(_6655, vec3(0.5))))
                                                                {
                                                                    _6629 = true;
                                                                }
                                                                else
                                                                {
                                                                    _6629 = any(greaterThan(_6655, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                }
                                                                if (!(_6629))
                                                                {
                                                                    _6580 = true;
                                                                    _6582 = Globals.uClipmapOrigin.data[_6628].w;
                                                                    _6626 = true;
                                                                    _6640_ladder_break = true;
                                                                }
                                                            }
                                                        }
                                                        if (_6640_ladder_break)
                                                        {
                                                            break;
                                                        }
                                                        _6628++;
                                                        continue;
                                                    }
                                                    if (!(_6626))
                                                    {
                                                        _6626 = true;
                                                    }
                                                }
                                                if (!_6580)
                                                {
                                                    _6579 = vec3(0.0);
                                                }
                                                else
                                                {
                                                    float _6596 = 0.5 * _6582;
                                                    vec3 _6597 = vec3(_6596, 0.0, 0.0);
                                                    vec3 _6598 = _4404 + _6597;
                                                    _6724 = false;
                                                    {
                                                        int _6726 = 0;
                                                        for (;;)
                                                        {
                                                            bool _6738_ladder_break = false;
                                                            {
                                                                if (!(_6726 < Globals.uShadowLevels))
                                                                {
                                                                    _6738_ladder_break = true;
                                                                }
                                                                else
                                                                {
                                                                    vec3 _6753 = (_6598 - Globals.uClipmapOrigin.data[_6726].xyz) / vec3(Globals.uClipmapOrigin.data[_6726].w);
                                                                    if (any(lessThan(_6753, vec3(0.5))))
                                                                    {
                                                                        _6727 = true;
                                                                    }
                                                                    else
                                                                    {
                                                                        _6727 = any(greaterThan(_6753, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                    }
                                                                    if (!(_6727))
                                                                    {
                                                                        _6724 = true;
                                                                        _6725 = ((textureLod(_9353, vec3(_6753.x / float(Globals.uShadowResolution), _6753.y / float(Globals.uShadowResolution), ((float(_6726) * float(Globals.uShadowResolution)) + _6753.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_6726];
                                                                        _6738_ladder_break = true;
                                                                    }
                                                                }
                                                            }
                                                            if (_6738_ladder_break)
                                                            {
                                                                break;
                                                            }
                                                            _6726++;
                                                            continue;
                                                        }
                                                        if (!(_6724))
                                                        {
                                                            _6724 = true;
                                                            _6725 = 1000000.0;
                                                        }
                                                    }
                                                    vec3 _6600 = _4404 - _6597;
                                                    _6822 = false;
                                                    {
                                                        int _6824 = 0;
                                                        for (;;)
                                                        {
                                                            bool _6836_ladder_break = false;
                                                            {
                                                                if (!(_6824 < Globals.uShadowLevels))
                                                                {
                                                                    _6836_ladder_break = true;
                                                                }
                                                                else
                                                                {
                                                                    vec3 _6851 = (_6600 - Globals.uClipmapOrigin.data[_6824].xyz) / vec3(Globals.uClipmapOrigin.data[_6824].w);
                                                                    if (any(lessThan(_6851, vec3(0.5))))
                                                                    {
                                                                        _6825 = true;
                                                                    }
                                                                    else
                                                                    {
                                                                        _6825 = any(greaterThan(_6851, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                    }
                                                                    if (!(_6825))
                                                                    {
                                                                        _6822 = true;
                                                                        _6823 = ((textureLod(_9353, vec3(_6851.x / float(Globals.uShadowResolution), _6851.y / float(Globals.uShadowResolution), ((float(_6824) * float(Globals.uShadowResolution)) + _6851.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_6824];
                                                                        _6836_ladder_break = true;
                                                                    }
                                                                }
                                                            }
                                                            if (_6836_ladder_break)
                                                            {
                                                                break;
                                                            }
                                                            _6824++;
                                                            continue;
                                                        }
                                                        if (!(_6822))
                                                        {
                                                            _6822 = true;
                                                            _6823 = 1000000.0;
                                                        }
                                                    }
                                                    vec3 _6603 = vec3(0.0, _6596, 0.0);
                                                    vec3 _6604 = _4404 + _6603;
                                                    _6920 = false;
                                                    {
                                                        int _6922 = 0;
                                                        for (;;)
                                                        {
                                                            bool _6934_ladder_break = false;
                                                            {
                                                                if (!(_6922 < Globals.uShadowLevels))
                                                                {
                                                                    _6934_ladder_break = true;
                                                                }
                                                                else
                                                                {
                                                                    vec3 _6949 = (_6604 - Globals.uClipmapOrigin.data[_6922].xyz) / vec3(Globals.uClipmapOrigin.data[_6922].w);
                                                                    if (any(lessThan(_6949, vec3(0.5))))
                                                                    {
                                                                        _6923 = true;
                                                                    }
                                                                    else
                                                                    {
                                                                        _6923 = any(greaterThan(_6949, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                    }
                                                                    if (!(_6923))
                                                                    {
                                                                        _6920 = true;
                                                                        _6921 = ((textureLod(_9353, vec3(_6949.x / float(Globals.uShadowResolution), _6949.y / float(Globals.uShadowResolution), ((float(_6922) * float(Globals.uShadowResolution)) + _6949.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_6922];
                                                                        _6934_ladder_break = true;
                                                                    }
                                                                }
                                                            }
                                                            if (_6934_ladder_break)
                                                            {
                                                                break;
                                                            }
                                                            _6922++;
                                                            continue;
                                                        }
                                                        if (!(_6920))
                                                        {
                                                            _6920 = true;
                                                            _6921 = 1000000.0;
                                                        }
                                                    }
                                                    vec3 _6606 = _4404 - _6603;
                                                    _7018 = false;
                                                    {
                                                        int _7020 = 0;
                                                        for (;;)
                                                        {
                                                            bool _7032_ladder_break = false;
                                                            {
                                                                if (!(_7020 < Globals.uShadowLevels))
                                                                {
                                                                    _7032_ladder_break = true;
                                                                }
                                                                else
                                                                {
                                                                    vec3 _7047 = (_6606 - Globals.uClipmapOrigin.data[_7020].xyz) / vec3(Globals.uClipmapOrigin.data[_7020].w);
                                                                    if (any(lessThan(_7047, vec3(0.5))))
                                                                    {
                                                                        _7021 = true;
                                                                    }
                                                                    else
                                                                    {
                                                                        _7021 = any(greaterThan(_7047, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                    }
                                                                    if (!(_7021))
                                                                    {
                                                                        _7018 = true;
                                                                        _7019 = ((textureLod(_9353, vec3(_7047.x / float(Globals.uShadowResolution), _7047.y / float(Globals.uShadowResolution), ((float(_7020) * float(Globals.uShadowResolution)) + _7047.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_7020];
                                                                        _7032_ladder_break = true;
                                                                    }
                                                                }
                                                            }
                                                            if (_7032_ladder_break)
                                                            {
                                                                break;
                                                            }
                                                            _7020++;
                                                            continue;
                                                        }
                                                        if (!(_7018))
                                                        {
                                                            _7018 = true;
                                                            _7019 = 1000000.0;
                                                        }
                                                    }
                                                    vec3 _6609 = vec3(0.0, 0.0, _6596);
                                                    vec3 _6610 = _4404 + _6609;
                                                    _7116 = false;
                                                    {
                                                        int _7118 = 0;
                                                        for (;;)
                                                        {
                                                            bool _7130_ladder_break = false;
                                                            {
                                                                if (!(_7118 < Globals.uShadowLevels))
                                                                {
                                                                    _7130_ladder_break = true;
                                                                }
                                                                else
                                                                {
                                                                    vec3 _7145 = (_6610 - Globals.uClipmapOrigin.data[_7118].xyz) / vec3(Globals.uClipmapOrigin.data[_7118].w);
                                                                    if (any(lessThan(_7145, vec3(0.5))))
                                                                    {
                                                                        _7119 = true;
                                                                    }
                                                                    else
                                                                    {
                                                                        _7119 = any(greaterThan(_7145, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                    }
                                                                    if (!(_7119))
                                                                    {
                                                                        _7116 = true;
                                                                        _7117 = ((textureLod(_9353, vec3(_7145.x / float(Globals.uShadowResolution), _7145.y / float(Globals.uShadowResolution), ((float(_7118) * float(Globals.uShadowResolution)) + _7145.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_7118];
                                                                        _7130_ladder_break = true;
                                                                    }
                                                                }
                                                            }
                                                            if (_7130_ladder_break)
                                                            {
                                                                break;
                                                            }
                                                            _7118++;
                                                            continue;
                                                        }
                                                        if (!(_7116))
                                                        {
                                                            _7116 = true;
                                                            _7117 = 1000000.0;
                                                        }
                                                    }
                                                    vec3 _6612 = _4404 - _6609;
                                                    _7214 = false;
                                                    {
                                                        int _7216 = 0;
                                                        for (;;)
                                                        {
                                                            bool _7228_ladder_break = false;
                                                            {
                                                                if (!(_7216 < Globals.uShadowLevels))
                                                                {
                                                                    _7228_ladder_break = true;
                                                                }
                                                                else
                                                                {
                                                                    vec3 _7243 = (_6612 - Globals.uClipmapOrigin.data[_7216].xyz) / vec3(Globals.uClipmapOrigin.data[_7216].w);
                                                                    if (any(lessThan(_7243, vec3(0.5))))
                                                                    {
                                                                        _7217 = true;
                                                                    }
                                                                    else
                                                                    {
                                                                        _7217 = any(greaterThan(_7243, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                    }
                                                                    if (!(_7217))
                                                                    {
                                                                        _7214 = true;
                                                                        _7215 = ((textureLod(_9353, vec3(_7243.x / float(Globals.uShadowResolution), _7243.y / float(Globals.uShadowResolution), ((float(_7216) * float(Globals.uShadowResolution)) + _7243.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_7216];
                                                                        _7228_ladder_break = true;
                                                                    }
                                                                }
                                                            }
                                                            if (_7228_ladder_break)
                                                            {
                                                                break;
                                                            }
                                                            _7216++;
                                                            continue;
                                                        }
                                                        if (!(_7214))
                                                        {
                                                            _7214 = true;
                                                            _7215 = 1000000.0;
                                                        }
                                                    }
                                                    vec3 _6615 = vec3(_6725 - _6823, _6921 - _7019, _7117 - _7215);
                                                    float _6616 = dot(_6615, _6615);
                                                    if (_6616 < 1.0000000133514319600180897396058e-10)
                                                    {
                                                        _6586 = vec3(0.0);
                                                    }
                                                    else
                                                    {
                                                        _6586 = _6615 * inversesqrt(_6616);
                                                    }
                                                    _6579 = _6586;
                                                }
                                            }
                                            vec3 _4591 = world + Globals.uTraceOrigin;
                                            {
                                                float _9163 = Globals.uShelterMap1.z;
                                                float _9164 = Globals.uShelterMap1.w;
                                                float _9165 = Globals.uShelterMap2.x;
                                                float _9166 = Globals.uShelterMap2.y;
                                                ivec2 _7378 = ivec2(floor((_4591.xy - Globals.uShelterMap0.xy) * Globals.uShelterMap0.z));
                                                vec2 _9209 = Globals.uShelterMap1.xy;
                                                if (Globals.uShelterMap0.w > 0.5)
                                                {
                                                    _7379 = _7378.x >= 0;
                                                }
                                                else
                                                {
                                                    _7379 = false;
                                                }
                                                if (_7379)
                                                {
                                                    _7379 = _7378.y >= 0;
                                                }
                                                else
                                                {
                                                    _7379 = false;
                                                }
                                                if (_7379)
                                                {
                                                    _7379 = _7378.x < int(_9209.x);
                                                }
                                                else
                                                {
                                                    _7379 = false;
                                                }
                                                if (_7379)
                                                {
                                                    _7379 = _7378.y < int(_9209.y);
                                                }
                                                else
                                                {
                                                    _7379 = false;
                                                }
                                                if (!_7379)
                                                {
                                                    _7313 = false;
                                                }
                                                else
                                                {
                                                    vec4 _7362 = texelFetch(_9368, ivec3(_7378, 0).xy, 0);
                                                    float _9213 = _9163;
                                                    float _9214 = _9164;
                                                    float _7429 = floor((_7362.z * 255.0) + 0.5) + (floor((_7362.y * 255.0) + 0.5) * 256.0);
                                                    if (_7429 < 0.5)
                                                    {
                                                        _7417 = -1000000015047466219876688855040.0;
                                                    }
                                                    else
                                                    {
                                                        _7417 = _9213 + ((_7429 - 1.0) * _9214);
                                                    }
                                                    float _7365 = _4591.z;
                                                    float _9218 = _9166;
                                                    if (_7417 > (_7365 + _9165))
                                                    {
                                                        _7442 = _7417 < (_7365 + _9218);
                                                    }
                                                    else
                                                    {
                                                        _7442 = false;
                                                    }
                                                    _7313 = _7442;
                                                }
                                            }
                                            if (!_7313)
                                            {
                                                vec3 _4598 = _4404 + Globals.uTraceOrigin;
                                                {
                                                    float _9101 = Globals.uShelterMap1.z;
                                                    float _9102 = Globals.uShelterMap1.w;
                                                    float _9103 = Globals.uShelterMap2.x;
                                                    float _9104 = Globals.uShelterMap2.y;
                                                    ivec2 _7523 = ivec2(floor((_4598.xy - Globals.uShelterMap0.xy) * Globals.uShelterMap0.z));
                                                    vec2 _9149 = Globals.uShelterMap1.xy;
                                                    if (Globals.uShelterMap0.w > 0.5)
                                                    {
                                                        _7524 = _7523.x >= 0;
                                                    }
                                                    else
                                                    {
                                                        _7524 = false;
                                                    }
                                                    if (_7524)
                                                    {
                                                        _7524 = _7523.y >= 0;
                                                    }
                                                    else
                                                    {
                                                        _7524 = false;
                                                    }
                                                    if (_7524)
                                                    {
                                                        _7524 = _7523.x < int(_9149.x);
                                                    }
                                                    else
                                                    {
                                                        _7524 = false;
                                                    }
                                                    if (_7524)
                                                    {
                                                        _7524 = _7523.y < int(_9149.y);
                                                    }
                                                    else
                                                    {
                                                        _7524 = false;
                                                    }
                                                    if (!_7524)
                                                    {
                                                        _7458 = false;
                                                    }
                                                    else
                                                    {
                                                        vec4 _7507 = texelFetch(_9368, ivec3(_7523, 0).xy, 0);
                                                        float _9153 = _9101;
                                                        float _9154 = _9102;
                                                        float _7574 = floor((_7507.z * 255.0) + 0.5) + (floor((_7507.y * 255.0) + 0.5) * 256.0);
                                                        if (_7574 < 0.5)
                                                        {
                                                            _7562 = -1000000015047466219876688855040.0;
                                                        }
                                                        else
                                                        {
                                                            _7562 = _9153 + ((_7574 - 1.0) * _9154);
                                                        }
                                                        float _7510 = _4598.z;
                                                        float _9158 = _9104;
                                                        if (_7562 > (_7510 + _9103))
                                                        {
                                                            _7587 = _7562 < (_7510 + _9158);
                                                        }
                                                        else
                                                        {
                                                            _7587 = false;
                                                        }
                                                        _7458 = _7587;
                                                    }
                                                }
                                                _4414 = _7458;
                                            }
                                            else
                                            {
                                                _4414 = false;
                                            }
                                            if (_4414)
                                            {
                                                _4400 = 0.0;
                                                _4415 = _4387 + 1.0;
                                            }
                                            else
                                            {
                                                _4400 = smoothstep(_4576, 2.0 * Globals.uClipmapOrigin.data[0].w, length(_4404 - world)) * smoothstep(0.75 * Globals.uClipmapOrigin.data[0].w, _4576, dot(_4404 - world, worldNormal));
                                                _4415 = _4387;
                                            }
                                            if (dot(_6579, _4847) > 0.0)
                                            {
                                                _4397 = -_6579;
                                            }
                                            else
                                            {
                                                _4397 = _6579;
                                            }
                                            if (_4400 <= 0.0)
                                            {
                                                _4395 = _4407;
                                                _4398 = _4396;
                                                _4401 = 0.0;
                                                _4399 = _4408;
                                                _4402 = _4409;
                                                _4403 = _4415;
                                            }
                                            else
                                            {
                                                if (dot(_4397, _4397) > 0.5)
                                                {
                                                    float _4624 = 0.5 * Globals.uClipmapOrigin.data[0].w;
                                                    {
                                                        _4416 = vec3(0.0);
                                                        if (Globals.uLookupBuckets <= 0)
                                                        {
                                                            _7607 = false;
                                                        }
                                                        else
                                                        {
                                                            ivec3 _7646 = ivec3(floor((_4404 - Globals.uLookupMin) / vec3(Globals.uLookupCell)));
                                                            int _7993 = int((((uint(_7646.x) * 2376512323u) ^ (uint(_7646.y) * 3625334849u)) ^ (uint(_7646.z) * 3407524639u)) & uint(Globals.uLookupBuckets - 1));
                                                            uvec2 _7651 = uvec2(textureSize(_9359, 0));
                                                            vec2 _7658 = vec2(float(_7651.x), float(_7651.y));
                                                            int _7610 = 0;
                                                            float _7611 = 0.0;
                                                            for (;;)
                                                            {
                                                                if (!(_7610 <= uCells._member0[Globals.uLookupBuckets].y))
                                                                {
                                                                    break;
                                                                }
                                                                bool _7672 = _7610 == 0;
                                                                if (_7672)
                                                                {
                                                                    _7612 = uCells._member0[_7993];
                                                                }
                                                                else
                                                                {
                                                                    int _7998 = uCells._member0[Globals.uLookupBuckets].x + ((_7610 - 1) * 6);
                                                                    float _8015 = intBitsToFloat(uCellPages_1._member0[_7998 + 3]) + _4624;
                                                                    vec3 _8016 = _4404 - vec3(intBitsToFloat(uCellPages_1._member0[_7998]), intBitsToFloat(uCellPages_1._member0[_7998 + 1]), intBitsToFloat(uCellPages_1._member0[_7998 + 2]));
                                                                    if (dot(_8016, _8016) > (_8015 * _8015))
                                                                    {
                                                                        _7994 = ivec2(0);
                                                                    }
                                                                    else
                                                                    {
                                                                        _7994 = ivec2(uCellPages_1._member0[_7998 + 4], uCellPages_1._member0[_7998 + 5]);
                                                                    }
                                                                    _7612 = _7994;
                                                                }
                                                                int _7613 = 0;
                                                                float _7614 = _7611;
                                                                for (;;)
                                                                {
                                                                    bool _7683_ladder_break = false;
                                                                    {
                                                                        if (!(_7613 < _7612.y))
                                                                        {
                                                                            _7683_ladder_break = true;
                                                                        }
                                                                        else
                                                                        {
                                                                            int _7694 = _7612.x + _7613;
                                                                            int _7697 = uCellPages_1._member0[_7694] * 10;
                                                                            if (!((uPages._member0[_7697 + 5].w > 0.5) == _7672))
                                                                            {
                                                                                int _7706 = _7697 + 9;
                                                                                vec3 _7710 = _4404 - uPages._member0[_7706].xyz;
                                                                                float _7712 = uPages._member0[_7706].w + _4624;
                                                                                if (!(dot(_7710, _7710) > (_7712 * _7712)))
                                                                                {
                                                                                    int _8032 = uCellPages_1._member0[_7694] * 10;
                                                                                    vec4 _7621 = uPages._member0[_8032];
                                                                                    vec4 _7622 = uPages._member0[_8032 + 1];
                                                                                    int _8038 = _8032 + 2;
                                                                                    int _8041 = _8032 + 3;
                                                                                    int _8044 = _8032 + 4;
                                                                                    int _8050 = _8032 + 6;
                                                                                    int _8053 = _8032 + 7;
                                                                                    int _8056 = _8032 + 8;
                                                                                    vec3 _8063 = _4404 - vec3(uPages._member0[_8050].w, uPages._member0[_8053].w, uPages._member0[_8056].w);
                                                                                    vec3 _8076 = vec3(dot(uPages._member0[_8050].xyz, _8063), dot(uPages._member0[_8053].xyz, _8063), dot(uPages._member0[_8056].xyz, _8063)) - uPages._member0[_8038].xyz;
                                                                                    vec2 _8079 = vec2(uPages._member0[_8038].w, uPages._member0[_8041].w);
                                                                                    bvec2 _9453 = isnan(_8079);
                                                                                    bvec2 _9454 = isnan(vec2(9.9999999747524270787835121154785e-07));
                                                                                    vec2 _9455 = max(_8079, vec2(9.9999999747524270787835121154785e-07));
                                                                                    vec2 _9456 = vec2(_9453.x ? vec2(9.9999999747524270787835121154785e-07).x : _9455.x, _9453.y ? vec2(9.9999999747524270787835121154785e-07).y : _9455.y);
                                                                                    vec2 _8080 = vec2(_9454.x ? _8079.x : _9456.x, _9454.y ? _8079.y : _9456.y);
                                                                                    vec2 _7616 = _8080;
                                                                                    vec2 _7615 = vec2(dot(_8076, uPages._member0[_8041].xyz), dot(_8076, uPages._member0[_8044].xyz)) / _8080;
                                                                                    float _7617 = -dot(_8076, uPages._member0[_8032 + 5].xyz);
                                                                                    float _7618 = uPages._member0[_8044].w;
                                                                                    float _7721 = dot(uPages._member0[_8032 + 5].xyz, vec3(dot(uPages._member0[_8050].xyz, _4397), dot(uPages._member0[_8053].xyz, _4397), dot(uPages._member0[_8056].xyz, _4397)));
                                                                                    if (!(_7721 <= 0.0))
                                                                                    {
                                                                                        float _7726 = Globals.uClipmapOrigin.data[0].w * 0.25;
                                                                                        vec2 _7729 = vec2(_7726) / _7616;
                                                                                        if (abs(_7615.x) > (1.0 + _7729.x))
                                                                                        {
                                                                                            _7623 = true;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            _7623 = abs(_7615.y) > (1.0 + _7729.y);
                                                                                        }
                                                                                        if (!(_7623))
                                                                                        {
                                                                                            if (_7617 < (Globals.uClipmapOrigin.data[0].w * (-0.25)))
                                                                                            {
                                                                                                _7624 = true;
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                _7624 = _7617 > (_7618 + _7726);
                                                                                            }
                                                                                            if (!(_7624))
                                                                                            {
                                                                                                vec2 _7773 = (_7622.xy + (((clamp(_7615, vec2(-1.0), vec2(1.0)) * 0.5) + vec2(0.5)) * _7622.zw)) - vec2(0.5);
                                                                                                vec2 _7774 = floor(_7773);
                                                                                                vec2 _7775 = _7773 - _7774;
                                                                                                bvec2 _9458 = isnan(_7622.zw);
                                                                                                bvec2 _9459 = isnan(vec2(9.9999999747524270787835121154785e-07));
                                                                                                vec2 _9460 = max(_7622.zw, vec2(9.9999999747524270787835121154785e-07));
                                                                                                vec2 _9461 = vec2(_9458.x ? vec2(9.9999999747524270787835121154785e-07).x : _9460.x, _9458.y ? vec2(9.9999999747524270787835121154785e-07).y : _9460.y);
                                                                                                vec2 _7781 = _7621.zw / vec2(_9459.x ? _7622.zw.x : _9461.x, _9459.y ? _7622.zw.y : _9461.y);
                                                                                                float _7785 = _7617 / (isnan(9.9999999747524270787835121154785e-07) ? _7618 : (isnan(_7618) ? 9.9999999747524270787835121154785e-07 : max(_7618, 9.9999999747524270787835121154785e-07)));
                                                                                                float _7787 = 0.5 * _7618;
                                                                                                float _7789 = _4624 / (isnan(9.9999999747524270787835121154785e-07) ? _7787 : (isnan(_7787) ? 9.9999999747524270787835121154785e-07 : max(_7787, 9.9999999747524270787835121154785e-07)));
                                                                                                vec4 _7625 = vec4(0.0);
                                                                                                int _7628 = 0;
                                                                                                for (;;)
                                                                                                {
                                                                                                    if (!(_7628 < 4))
                                                                                                    {
                                                                                                        break;
                                                                                                    }
                                                                                                    vec2 _7804 = vec2(float(_7628 & 1), float(_7628 >> 1));
                                                                                                    vec2 _7807 = (_7774 + _7804) + vec2(0.5);
                                                                                                    vec2 _7808 = _7807 / _7658;
                                                                                                    if (textureLod(_9361, _7808, 0.0).w >= 0.5)
                                                                                                    {
                                                                                                        _7629 = 1.0;
                                                                                                    }
                                                                                                    else
                                                                                                    {
                                                                                                        _7629 = 0.0;
                                                                                                    }
                                                                                                    vec2 _7837 = mix(vec2(1.0) - _7775, _7775, _7804);
                                                                                                    _7625[_7628] = ((_7837.x * _7837.y) * _7629) * (1.0 - clamp((abs(_7785 - textureLod(_9363, _7808, 0.0).x) - _7789) / (0.25 * _7789), 0.0, 1.0));
                                                                                                    _7626[_7628] = textureLod(_9365, (floor(_7621.xy + ((_7807 - _7622.xy) * _7781)) + vec2(0.5)) / Globals.uAtlasSize.xy, 0.0).xyz;
                                                                                                    _7628++;
                                                                                                    continue;
                                                                                                }
                                                                                                float _7884 = ((_7625.x + _7625.y) + _7625.z) + _7625.w;
                                                                                                float _7885 = (_7721 * _7721) * _7884;
                                                                                                if (!(_7885 <= 0.0))
                                                                                                {
                                                                                                    vec3 _7913 = ((((_7626[0] * _7625.x) + (_7626[1] * _7625.y)) + (_7626[2] * _7625.z)) + (_7626[3] * _7625.w)) / vec3(_7884);
                                                                                                    bvec3 _9473 = isnan(_7913);
                                                                                                    bvec3 _9474 = isnan(vec3(0.0));
                                                                                                    vec3 _9475 = max(_7913, vec3(0.0));
                                                                                                    vec3 _9476 = vec3(_9473.x ? vec3(0.0).x : _9475.x, _9473.y ? vec3(0.0).y : _9475.y, _9473.z ? vec3(0.0).z : _9475.z);
                                                                                                    _4416 += (vec3(_9474.x ? _7913.x : _9476.x, _9474.y ? _7913.y : _9476.y, _9474.z ? _7913.z : _9476.z) * _7885);
                                                                                                    _7614 += _7885;
                                                                                                }
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                    if (_7683_ladder_break)
                                                                    {
                                                                        break;
                                                                    }
                                                                    _7613++;
                                                                    continue;
                                                                }
                                                                _7610++;
                                                                _7611 = _7614;
                                                                continue;
                                                            }
                                                            if (_7611 <= 0.0)
                                                            {
                                                                _4416 = vec3(0.0);
                                                                _7607 = false;
                                                            }
                                                            else
                                                            {
                                                                _4416 /= vec3(_7611);
                                                                _7607 = true;
                                                            }
                                                        }
                                                    }
                                                    _4417 = _7607;
                                                }
                                                else
                                                {
                                                    _4417 = false;
                                                }
                                                if (_4417)
                                                {
                                                    vec3 _4666 = _4416 * Globals.uBounceScale;
                                                    float _8468 = _4666.x;
                                                    float _8469 = _4666.y;
                                                    float _8470 = _4666.z;
                                                    float _8471 = isnan(_8470) ? _8469 : (isnan(_8469) ? _8470 : max(_8469, _8470));
                                                    float _8472 = isnan(_8471) ? _8468 : (isnan(_8468) ? _8471 : max(_8468, _8471));
                                                    if (_8472 > Globals.uMaxRayIntensity)
                                                    {
                                                        _8465 = _4666 * (Globals.uMaxRayIntensity / _8472);
                                                    }
                                                    else
                                                    {
                                                        _8465 = _4666;
                                                    }
                                                    _4395 = 2;
                                                    _4398 = _4666;
                                                    _4401 = _4400;
                                                    _4399 = _4408 + (_8465 * _4400);
                                                    _4402 = _4409 + _4400;
                                                    _4403 = _4415;
                                                }
                                                else
                                                {
                                                    {
                                                        _4412 = vec2(0.0);
                                                        float _4413 = 1000000000.0;
                                                        if (Globals.uLookupBuckets <= 0)
                                                        {
                                                            _8096 = false;
                                                        }
                                                        else
                                                        {
                                                            ivec3 _8137 = ivec3(floor((_4404 - Globals.uLookupMin) / vec3(Globals.uLookupCell)));
                                                            int _8349 = int((((uint(_8137.x) * 2376512323u) ^ (uint(_8137.y) * 3625334849u)) ^ (uint(_8137.z) * 3407524639u)) & uint(Globals.uLookupBuckets - 1));
                                                            uvec2 _8142 = uvec2(textureSize(_9359, 0));
                                                            vec2 _8149 = vec2(float(_8142.x), float(_8142.y));
                                                            bool _8099 = false;
                                                            bool _8100 = false;
                                                            int _8101 = 0;
                                                            for (;;)
                                                            {
                                                                if (_8101 <= uCells._member0[Globals.uLookupBuckets].y)
                                                                {
                                                                    _8102 = !_8099;
                                                                }
                                                                else
                                                                {
                                                                    _8102 = false;
                                                                }
                                                                if (!_8102)
                                                                {
                                                                    break;
                                                                }
                                                                bool _8169 = _8101 == 0;
                                                                if (_8169)
                                                                {
                                                                    _8103 = uCells._member0[_8349];
                                                                }
                                                                else
                                                                {
                                                                    int _8354 = uCells._member0[Globals.uLookupBuckets].x + ((_8101 - 1) * 6);
                                                                    float _8370 = intBitsToFloat(uCellPages_1._member0[_8354 + 3]);
                                                                    vec3 _8372 = _4404 - vec3(intBitsToFloat(uCellPages_1._member0[_8354]), intBitsToFloat(uCellPages_1._member0[_8354 + 1]), intBitsToFloat(uCellPages_1._member0[_8354 + 2]));
                                                                    if (dot(_8372, _8372) > (_8370 * _8370))
                                                                    {
                                                                        _8350 = ivec2(0);
                                                                    }
                                                                    else
                                                                    {
                                                                        _8350 = ivec2(uCellPages_1._member0[_8354 + 4], uCellPages_1._member0[_8354 + 5]);
                                                                    }
                                                                    _8103 = _8350;
                                                                }
                                                                bool _8104 = _8099;
                                                                bool _8105 = _8100;
                                                                int _8106 = 0;
                                                                for (;;)
                                                                {
                                                                    bool _8181_ladder_break = false;
                                                                    {
                                                                        if (_8106 < _8103.y)
                                                                        {
                                                                            _8107 = !_8104;
                                                                        }
                                                                        else
                                                                        {
                                                                            _8107 = false;
                                                                        }
                                                                        if (!_8107)
                                                                        {
                                                                            _8181_ladder_break = true;
                                                                        }
                                                                        else
                                                                        {
                                                                            int _8198 = _8103.x + _8106;
                                                                            int _8201 = uCellPages_1._member0[_8198] * 10;
                                                                            if (!((uPages._member0[_8201 + 5].w > 0.5) == _8169))
                                                                            {
                                                                                int _8210 = _8201 + 9;
                                                                                vec3 _8214 = _4404 - uPages._member0[_8210].xyz;
                                                                                if (!(dot(_8214, _8214) > (uPages._member0[_8210].w * uPages._member0[_8210].w)))
                                                                                {
                                                                                    vec3 _8221 = -_4847;
                                                                                    int _8388 = uCellPages_1._member0[_8198] * 10;
                                                                                    vec4 _8114 = uPages._member0[_8388];
                                                                                    vec4 _8115 = uPages._member0[_8388 + 1];
                                                                                    int _8394 = _8388 + 2;
                                                                                    int _8397 = _8388 + 3;
                                                                                    int _8400 = _8388 + 4;
                                                                                    int _8406 = _8388 + 6;
                                                                                    int _8409 = _8388 + 7;
                                                                                    int _8412 = _8388 + 8;
                                                                                    vec3 _8419 = _4404 - vec3(uPages._member0[_8406].w, uPages._member0[_8409].w, uPages._member0[_8412].w);
                                                                                    vec3 _8113 = vec3(dot(uPages._member0[_8406].xyz, _8221), dot(uPages._member0[_8409].xyz, _8221), dot(uPages._member0[_8412].xyz, _8221));
                                                                                    vec3 _8432 = vec3(dot(uPages._member0[_8406].xyz, _8419), dot(uPages._member0[_8409].xyz, _8419), dot(uPages._member0[_8412].xyz, _8419)) - uPages._member0[_8394].xyz;
                                                                                    vec2 _8435 = vec2(uPages._member0[_8394].w, uPages._member0[_8397].w);
                                                                                    bvec2 _9488 = isnan(_8435);
                                                                                    bvec2 _9489 = isnan(vec2(9.9999999747524270787835121154785e-07));
                                                                                    vec2 _9490 = max(_8435, vec2(9.9999999747524270787835121154785e-07));
                                                                                    vec2 _9491 = vec2(_9488.x ? vec2(9.9999999747524270787835121154785e-07).x : _9490.x, _9488.y ? vec2(9.9999999747524270787835121154785e-07).y : _9490.y);
                                                                                    vec2 _8442 = vec2(dot(_8432, uPages._member0[_8397].xyz), dot(_8432, uPages._member0[_8400].xyz)) / vec2(_9489.x ? _8435.x : _9491.x, _9489.y ? _8435.y : _9491.y);
                                                                                    vec2 _8108 = _8442;
                                                                                    float _8110 = -dot(_8432, uPages._member0[_8388 + 5].xyz);
                                                                                    float _8111 = uPages._member0[_8400].w;
                                                                                    vec3 _8112 = uPages._member0[_8388 + 5].xyz;
                                                                                    if (abs(_8442.x) > 1.0)
                                                                                    {
                                                                                        _8116 = true;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        _8116 = abs(_8108.y) > 1.0;
                                                                                    }
                                                                                    if (!(_8116))
                                                                                    {
                                                                                        if (dot(_4847, _4847) > 0.5)
                                                                                        {
                                                                                            _8117 = dot(_8112, _8113) < (-0.0500000007450580596923828125);
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            _8117 = false;
                                                                                        }
                                                                                        if (!(_8117))
                                                                                        {
                                                                                            if (_8110 < (-0.25))
                                                                                            {
                                                                                                _8118 = true;
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                _8118 = _8110 > (_8111 + 0.25);
                                                                                            }
                                                                                            if (!(_8118))
                                                                                            {
                                                                                                vec2 _8265 = (_8108 * 0.5) + vec2(0.5);
                                                                                                vec2 _8272 = (_8115.xy + (_8265 * _8115.zw)) / _8149;
                                                                                                if (!(textureLod(_9361, _8272, 0.0).w < 0.5))
                                                                                                {
                                                                                                    float _8292 = abs((textureLod(_9363, _8272, 0.0).x * _8111) - _8110);
                                                                                                    if (_8292 < _4413)
                                                                                                    {
                                                                                                        _4413 = _8292;
                                                                                                        _4412 = (_8114.xy + (_8265 * _8114.zw)) / Globals.uAtlasSize.xy;
                                                                                                        _8119 = _8292 < 0.0199999995529651641845703125;
                                                                                                        _8120 = true;
                                                                                                    }
                                                                                                    else
                                                                                                    {
                                                                                                        _8119 = _8104;
                                                                                                        _8120 = _8105;
                                                                                                    }
                                                                                                    _8104 = _8119;
                                                                                                    _8105 = _8120;
                                                                                                }
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                    if (_8181_ladder_break)
                                                                    {
                                                                        break;
                                                                    }
                                                                    _8106++;
                                                                    continue;
                                                                }
                                                                _8099 = _8104;
                                                                _8100 = _8105;
                                                                _8101++;
                                                                continue;
                                                            }
                                                            _8096 = _8100;
                                                        }
                                                    }
                                                    if (_8096)
                                                    {
                                                        vec3 _4650 = textureLod(_9365, _4412, 0.0).xyz * Globals.uBounceScale;
                                                        float _8450 = _4650.x;
                                                        float _8451 = _4650.y;
                                                        float _8452 = _4650.z;
                                                        float _8453 = isnan(_8452) ? _8451 : (isnan(_8451) ? _8452 : max(_8451, _8452));
                                                        float _8454 = isnan(_8453) ? _8450 : (isnan(_8450) ? _8453 : max(_8450, _8453));
                                                        if (_8454 > Globals.uMaxRayIntensity)
                                                        {
                                                            _8447 = _4650 * (Globals.uMaxRayIntensity / _8454);
                                                        }
                                                        else
                                                        {
                                                            _8447 = _4650;
                                                        }
                                                        _4395 = 2;
                                                        _4398 = _4650;
                                                        _4401 = _4400;
                                                        _4399 = _4408 + (_8447 * _4400);
                                                        _4402 = _4409 + _4400;
                                                        _4403 = _4415;
                                                    }
                                                    else
                                                    {
                                                        _4395 = _4407;
                                                        _4398 = _4396;
                                                        _4401 = 0.0;
                                                        _4399 = _4408;
                                                        _4402 = _4409;
                                                        _4403 = _4415 + _4400;
                                                    }
                                                }
                                            }
                                            _4397 = _4384;
                                            _4400 = _4388;
                                        }
                                        else
                                        {
                                            if (_4847.z >= 0.0)
                                            {
                                                {
                                                    if (Globals.uSkyShValid == 0)
                                                    {
                                                        _6509 = Globals.uSkyColour;
                                                    }
                                                    else
                                                    {
                                                        vec4 _6520 = vec4(_4847, 1.0);
                                                        vec4 _6523 = _6520.xyzz * _6520.yzzx;
                                                        float _6549 = _4847.x;
                                                        float _6551 = _4847.y;
                                                        vec3 _6556 = (vec3(dot(Globals.uSkySh.data[0], _6520), dot(Globals.uSkySh.data[1], _6520), dot(Globals.uSkySh.data[2], _6520)) + vec3(dot(Globals.uSkySh.data[3], _6523), dot(Globals.uSkySh.data[4], _6523), dot(Globals.uSkySh.data[5], _6523))) + (Globals.uSkySh.data[6].xyz * ((_6549 * _6549) - (_6551 * _6551)));
                                                        bvec3 _9503 = isnan(vec3(0.0));
                                                        bvec3 _9504 = isnan(_6556);
                                                        vec3 _9505 = max(vec3(0.0), _6556);
                                                        vec3 _9506 = vec3(_9503.x ? _6556.x : _9505.x, _9503.y ? _6556.y : _9505.y, _9503.z ? _6556.z : _9505.z);
                                                        _6509 = vec3(_9504.x ? vec3(0.0).x : _9506.x, _9504.y ? vec3(0.0).y : _9506.y, _9504.z ? vec3(0.0).z : _9506.z);
                                                    }
                                                }
                                                _4397 = _6509;
                                            }
                                            else
                                            {
                                                {
                                                    if (Globals.uSkyShValid == 0)
                                                    {
                                                        _6457 = Globals.uSkyColour;
                                                    }
                                                    else
                                                    {
                                                        vec4 _6468 = vec4(vec3(0.0, 0.0, 1.0), 1.0);
                                                        vec4 _6471 = _6468.xyzz * _6468.yzzx;
                                                        vec3 _6503 = vec3(dot(Globals.uSkySh.data[0], _6468), dot(Globals.uSkySh.data[1], _6468), dot(Globals.uSkySh.data[2], _6468)) + vec3(dot(Globals.uSkySh.data[3], _6471), dot(Globals.uSkySh.data[4], _6471), dot(Globals.uSkySh.data[5], _6471));
                                                        bvec3 _9508 = isnan(vec3(0.0));
                                                        bvec3 _9509 = isnan(_6503);
                                                        vec3 _9510 = max(vec3(0.0), _6503);
                                                        vec3 _9511 = vec3(_9508.x ? _6503.x : _9510.x, _9508.y ? _6503.y : _9510.y, _9508.z ? _6503.z : _9510.z);
                                                        _6457 = vec3(_9509.x ? vec3(0.0).x : _9511.x, _9509.y ? vec3(0.0).y : _9511.y, _9509.z ? vec3(0.0).z : _9511.z);
                                                    }
                                                }
                                                _4397 = (_6457 + Globals.uGroundSun) * 0.25;
                                            }
                                            float _6566 = isnan(_4397.z) ? _4397.y : (isnan(_4397.y) ? _4397.z : max(_4397.y, _4397.z));
                                            float _6567 = isnan(_6566) ? _4397.x : (isnan(_4397.x) ? _6566 : max(_4397.x, _6566));
                                            if (_6567 > Globals.uMaxRayIntensity)
                                            {
                                                _6560 = _4397 * (Globals.uMaxRayIntensity / _6567);
                                            }
                                            else
                                            {
                                                _6560 = _4397;
                                            }
                                            _4395 = 3;
                                            _4398 = _4397;
                                            _4401 = 1.0;
                                            _4399 = _4408;
                                            _4402 = _4409;
                                            _4403 = _4387;
                                            _4397 = _4384 + _6560;
                                            _4400 = _4388 + 1.0;
                                        }
                                    }
                                }
                                else
                                {
                                    _4395 = _4392;
                                    _4398 = _4390;
                                    _4401 = 1.0;
                                    _4399 = _4383;
                                    _4402 = _4386;
                                    _4403 = _4387;
                                    _4397 = _4384;
                                    _4400 = _4388;
                                }
                                if (Globals.uDebugSource != 0)
                                {
                                    _4394 = _4395 != Globals.uDebugSource;
                                }
                                else
                                {
                                    _4394 = false;
                                }
                                if (_4394)
                                {
                                    _4396 = vec3(0.0);
                                }
                                else
                                {
                                    _4396 = _4398;
                                }
                                float _8489 = isnan(_4396.z) ? _4396.y : (isnan(_4396.y) ? _4396.z : max(_4396.y, _4396.z));
                                float _8490 = isnan(_8489) ? _4396.x : (isnan(_4396.x) ? _8489 : max(_4396.x, _8489));
                                if (_8490 > Globals.uMaxRayIntensity)
                                {
                                    _8483 = _4396 * (Globals.uMaxRayIntensity / _8490);
                                }
                                else
                                {
                                    _8483 = _4396;
                                }
                                _4382++;
                                _4383 = _4399;
                                _4386 = _4402;
                                _4387 = _4403;
                                _4384 = _4397;
                                _4388 = _4400;
                                _4385 += (_8483 * _4401);
                                _4389 += _4401;
                                continue;
                            }
                            if (_4387 > 0.0)
                            {
                                if (Globals.uDebugSource == 0)
                                {
                                    _4381 = true;
                                }
                                else
                                {
                                    _4381 = Globals.uDebugSource == 2;
                                }
                            }
                            else
                            {
                                _4381 = false;
                            }
                            if (_4381)
                            {
                                if (_4386 > 0.0)
                                {
                                    _4390 = _4383 / vec3(_4386);
                                }
                                else
                                {
                                    if (_4388 > 0.0)
                                    {
                                        _4383 = _4384 / vec3(_4388);
                                    }
                                    else
                                    {
                                        vec3 _8502;
                                        {
                                            if (Globals.uSkyShValid == 0)
                                            {
                                                _8502 = Globals.uSkyColour;
                                            }
                                            else
                                            {
                                                vec4 _8513 = vec4(vec3(0.0, 0.0, 1.0), 1.0);
                                                vec4 _8516 = _8513.xyzz * _8513.yzzx;
                                                vec3 _8548 = vec3(dot(Globals.uSkySh.data[0], _8513), dot(Globals.uSkySh.data[1], _8513), dot(Globals.uSkySh.data[2], _8513)) + vec3(dot(Globals.uSkySh.data[3], _8516), dot(Globals.uSkySh.data[4], _8516), dot(Globals.uSkySh.data[5], _8516));
                                                bvec3 _9533 = isnan(vec3(0.0));
                                                bvec3 _9534 = isnan(_8548);
                                                vec3 _9535 = max(vec3(0.0), _8548);
                                                vec3 _9536 = vec3(_9533.x ? _8548.x : _9535.x, _9533.y ? _8548.y : _9535.y, _9533.z ? _8548.z : _9535.z);
                                                _8502 = vec3(_9534.x ? vec3(0.0).x : _9536.x, _9534.y ? vec3(0.0).y : _9536.y, _9534.z ? vec3(0.0).z : _9536.z);
                                            }
                                        }
                                        _4383 = _8502;
                                    }
                                    _4390 = _4383 * 0.25;
                                }
                                _4389 += _4387;
                                _4385 += (_4390 * _4387);
                            }
                            vec3 _4781 = _4385 * (3.1415927410125732421875 / (isnan(4.0) ? _4389 : (isnan(_4389) ? 4.0 : max(_4389, 4.0))));
                            bvec3 _9543 = isnan(_4781);
                            bvec3 _9544 = isnan(vec3(0.0));
                            vec3 _9545 = max(_4781, vec3(0.0));
                            vec3 _9546 = vec3(_9543.x ? vec3(0.0).x : _9545.x, _9543.y ? vec3(0.0).y : _9545.y, _9543.z ? vec3(0.0).z : _9545.z);
                            _4380 = vec3(_9544.x ? _4781.x : _9546.x, _9544.y ? _4781.y : _9546.y, _9544.z ? _4781.z : _9546.z);
                        }
                    }
                    if (Globals.uDebugSource == 4)
                    {
                        vec3 _3556 = -worldNormal;
                        vec2 litFound;
                        bool _8558;
                        {
                            litFound = vec2(0.0);
                            float agreement = 1000000000.0;
                            if (Globals.uLookupBuckets <= 0)
                            {
                                _8558 = false;
                            }
                            else
                            {
                                ivec3 _8599 = ivec3(floor((world - Globals.uLookupMin) / vec3(Globals.uLookupCell)));
                                int _8811 = int((((uint(_8599.x) * 2376512323u) ^ (uint(_8599.y) * 3625334849u)) ^ (uint(_8599.z) * 3407524639u)) & uint(Globals.uLookupBuckets - 1));
                                uvec2 _8604 = uvec2(textureSize(_9359, 0));
                                vec2 _8611 = vec2(float(_8604.x), float(_8604.y));
                                bool _8561 = false;
                                bool _8562 = false;
                                int _8563 = 0;
                                bool _8564;
                                ivec2 _8565;
                                bool _8569;
                                bool _8578;
                                bool _8579;
                                bool _8580;
                                bool _8581;
                                bool _8582;
                                ivec2 _8812;
                                for (;;)
                                {
                                    if (_8563 <= uCells._member0[Globals.uLookupBuckets].y)
                                    {
                                        _8564 = !_8561;
                                    }
                                    else
                                    {
                                        _8564 = false;
                                    }
                                    if (!_8564)
                                    {
                                        break;
                                    }
                                    bool _8631 = _8563 == 0;
                                    if (_8631)
                                    {
                                        _8565 = uCells._member0[_8811];
                                    }
                                    else
                                    {
                                        int _8816 = uCells._member0[Globals.uLookupBuckets].x + ((_8563 - 1) * 6);
                                        float _8832 = intBitsToFloat(uCellPages_1._member0[_8816 + 3]);
                                        vec3 _8834 = world - vec3(intBitsToFloat(uCellPages_1._member0[_8816]), intBitsToFloat(uCellPages_1._member0[_8816 + 1]), intBitsToFloat(uCellPages_1._member0[_8816 + 2]));
                                        if (dot(_8834, _8834) > (_8832 * _8832))
                                        {
                                            _8812 = ivec2(0);
                                        }
                                        else
                                        {
                                            _8812 = ivec2(uCellPages_1._member0[_8816 + 4], uCellPages_1._member0[_8816 + 5]);
                                        }
                                        _8565 = _8812;
                                    }
                                    bool _8566 = _8561;
                                    bool _8567 = _8562;
                                    int _8568 = 0;
                                    for (;;)
                                    {
                                        bool _8643_ladder_break = false;
                                        {
                                            if (_8568 < _8565.y)
                                            {
                                                _8569 = !_8566;
                                            }
                                            else
                                            {
                                                _8569 = false;
                                            }
                                            if (!_8569)
                                            {
                                                _8643_ladder_break = true;
                                            }
                                            else
                                            {
                                                int _8660 = _8565.x + _8568;
                                                int _8663 = uCellPages_1._member0[_8660] * 10;
                                                if (!((uPages._member0[_8663 + 5].w > 0.5) == _8631))
                                                {
                                                    int _8672 = _8663 + 9;
                                                    vec3 _8676 = world - uPages._member0[_8672].xyz;
                                                    if (!(dot(_8676, _8676) > (uPages._member0[_8672].w * uPages._member0[_8672].w)))
                                                    {
                                                        int _8850 = uCellPages_1._member0[_8660] * 10;
                                                        vec4 _8576 = uPages._member0[_8850];
                                                        vec4 _8577 = uPages._member0[_8850 + 1];
                                                        int _8856 = _8850 + 2;
                                                        int _8859 = _8850 + 3;
                                                        int _8862 = _8850 + 4;
                                                        int _8868 = _8850 + 6;
                                                        int _8871 = _8850 + 7;
                                                        int _8874 = _8850 + 8;
                                                        vec3 _8881 = world - vec3(uPages._member0[_8868].w, uPages._member0[_8871].w, uPages._member0[_8874].w);
                                                        vec3 _8575 = vec3(dot(uPages._member0[_8868].xyz, worldNormal), dot(uPages._member0[_8871].xyz, worldNormal), dot(uPages._member0[_8874].xyz, worldNormal));
                                                        vec3 _8894 = vec3(dot(uPages._member0[_8868].xyz, _8881), dot(uPages._member0[_8871].xyz, _8881), dot(uPages._member0[_8874].xyz, _8881)) - uPages._member0[_8856].xyz;
                                                        vec2 _8897 = vec2(uPages._member0[_8856].w, uPages._member0[_8859].w);
                                                        bvec2 _9548 = isnan(_8897);
                                                        bvec2 _9549 = isnan(vec2(9.9999999747524270787835121154785e-07));
                                                        vec2 _9550 = max(_8897, vec2(9.9999999747524270787835121154785e-07));
                                                        vec2 _9551 = vec2(_9548.x ? vec2(9.9999999747524270787835121154785e-07).x : _9550.x, _9548.y ? vec2(9.9999999747524270787835121154785e-07).y : _9550.y);
                                                        vec2 _8904 = vec2(dot(_8894, uPages._member0[_8859].xyz), dot(_8894, uPages._member0[_8862].xyz)) / vec2(_9549.x ? _8897.x : _9551.x, _9549.y ? _8897.y : _9551.y);
                                                        vec2 _8570 = _8904;
                                                        float _8572 = -dot(_8894, uPages._member0[_8850 + 5].xyz);
                                                        float _8573 = uPages._member0[_8862].w;
                                                        vec3 _8574 = uPages._member0[_8850 + 5].xyz;
                                                        if (abs(_8904.x) > 1.0)
                                                        {
                                                            _8578 = true;
                                                        }
                                                        else
                                                        {
                                                            _8578 = abs(_8570.y) > 1.0;
                                                        }
                                                        if (!(_8578))
                                                        {
                                                            if (dot(_3556, _3556) > 0.5)
                                                            {
                                                                _8579 = dot(_8574, _8575) < (-0.0500000007450580596923828125);
                                                            }
                                                            else
                                                            {
                                                                _8579 = false;
                                                            }
                                                            if (!(_8579))
                                                            {
                                                                if (_8572 < (-0.25))
                                                                {
                                                                    _8580 = true;
                                                                }
                                                                else
                                                                {
                                                                    _8580 = _8572 > (_8573 + 0.25);
                                                                }
                                                                if (!(_8580))
                                                                {
                                                                    vec2 _8727 = (_8570 * 0.5) + vec2(0.5);
                                                                    vec2 _8734 = (_8577.xy + (_8727 * _8577.zw)) / _8611;
                                                                    if (!(textureLod(_9361, _8734, 0.0).w < 0.5))
                                                                    {
                                                                        float _8754 = abs((textureLod(_9363, _8734, 0.0).x * _8573) - _8572);
                                                                        if (_8754 < agreement)
                                                                        {
                                                                            agreement = _8754;
                                                                            litFound = (_8576.xy + (_8727 * _8576.zw)) / Globals.uAtlasSize.xy;
                                                                            _8581 = _8754 < 0.0199999995529651641845703125;
                                                                            _8582 = true;
                                                                        }
                                                                        else
                                                                        {
                                                                            _8581 = _8566;
                                                                            _8582 = _8567;
                                                                        }
                                                                        _8566 = _8581;
                                                                        _8567 = _8582;
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        if (_8643_ladder_break)
                                        {
                                            break;
                                        }
                                        _8568++;
                                        continue;
                                    }
                                    _8561 = _8566;
                                    _8562 = _8567;
                                    _8563++;
                                    continue;
                                }
                                _8558 = _8562;
                            }
                        }
                        if (_8558)
                        {
                            nMin = textureLod(_9365, litFound, 0.0).xyz;
                        }
                        else
                        {
                            nMin = vec3(0.0);
                        }
                    }
                    else
                    {
                        nMin = _4380;
                    }
                }
                else
                {
                    nMin = vec3(0.0);
                }
                if (_4181)
                {
                    nCount = 1.0;
                }
                else
                {
                    nCount = 0.0;
                }
                imageStore(uIndirect, ivec2(gl_GlobalInvocationID.xy), vec4(nMin, nCount));
                vec4 _90;
                if (_4181)
                {
                    _90 = vec4(world - Globals.uCameraToCache, 1.0);
                }
                else
                {
                    _90 = vec4(0.0);
                }
                imageStore(uPosition, ivec2(gl_GlobalInvocationID.xy), _90);
            }
            else
            {
                if (!_4181)
                {
                    imageStore(uIndirect, ivec2(gl_GlobalInvocationID.xy), vec4(0.0));
                    imageStore(uPosition, ivec2(gl_GlobalInvocationID.xy), vec4(0.0));
                }
                else
                {
                    vec3 current = texelFetch(_9371, ivec3(_233, 0).xy, 0).xyz;
                    float _3620 = 0.0599999986588954925537109375 * length(viewPosition);
                    float _3622 = isnan(_3620) ? 0.3499999940395355224609375 : (isnan(0.3499999940395355224609375) ? _3620 : max(0.3499999940395355224609375, _3620));
                    nMin = current;
                    vec3 nMax = current;
                    int dy = -1;
                    vec3 nSum = current;
                    nCount = 1.0;
                    bool _95;
                    bool _96;
                    vec3 historySum;
                    vec3 accumulated;
                    int t;
                    float frameSum;
                    float weightSum;
                    vec3 nMin_1;
                    vec3 nMax_1;
                    vec3 nWorld;
                    vec3 nNormal;
                    bool _108;
                    bool _109;
                    vec3 nSum_2;
                    bool _8910;
                    for (;;)
                    {
                        if (!(dy <= 1))
                        {
                            break;
                        }
                        historySum = nMin;
                        accumulated = nMax;
                        t = -1;
                        vec3 nSum_1 = nSum;
                        frameSum = nCount;
                        for (;;)
                        {
                            bool _144_ladder_break = false;
                            {
                                if (!(t <= 1))
                                {
                                    _144_ladder_break = true;
                                }
                                else
                                {
                                    if (t == 0)
                                    {
                                        ownMotion = dy == 0;
                                    }
                                    else
                                    {
                                        ownMotion = false;
                                    }
                                    if (ownMotion)
                                    {
                                        nMin_1 = historySum;
                                        nMax_1 = accumulated;
                                    }
                                    else
                                    {
                                        ivec2 n = _233 + ivec2(t, dy);
                                        if (any(lessThan(n, ivec2(0))))
                                        {
                                            _95 = true;
                                        }
                                        else
                                        {
                                            _95 = any(greaterThanEqual(n, grid));
                                        }
                                        if (_95)
                                        {
                                            nMin_1 = historySum;
                                            nMax_1 = accumulated;
                                        }
                                        else
                                        {
                                            vec4 _sampled = texelFetch(_9371, ivec3(n, 0).xy, 0);
                                            if (_sampled.w > 0.5)
                                            {
                                                {
                                                    nWorld = vec3(0.0);
                                                    nNormal = vec3(0.0, 0.0, 1.0);
                                                    uint _8986 = uint(Globals.uFrameIndex);
                                                    uint _8987 = _8986 & 7u;
                                                    vec2 _8939 = (vec2(min(((n * ivec2(Globals.uProbeStep)) + min(ivec2(floor(((vec2(float(_8987), float((((_8986 & 1u) << uint(2)) | (_8986 & 2u)) | ((_8987 >> uint(2)) & 1u))) + vec2(0.5)) * vec2(0.125)) * float(Globals.uProbeStep))), ivec2(Globals.uProbeStep - 1))), (ivec2(Globals.uScreenWidth, Globals.uScreenHeight) - ivec2(1)))) + vec2(0.5)) / vec2(float(Globals.uScreenWidth), float(Globals.uScreenHeight));
                                                    vec4 _9013 = textureLod(_9344, _8939, 0.0);
                                                    float _9014 = _9013.x;
                                                    if (_9014 <= 0.0)
                                                    {
                                                        _8910 = false;
                                                    }
                                                    else
                                                    {
                                                        float _9033 = ((2.0 * Globals.uUnproject.z) * Globals.uUnproject.w) / ((Globals.uUnproject.w + Globals.uUnproject.z) - ((1.0 - (2.0 * _9014)) * (Globals.uUnproject.w - Globals.uUnproject.z)));
                                                        vec2 _9036 = (_8939 * 2.0) - vec2(1.0);
                                                        vec3 _9048 = vec3((_9036.x * _9033) / Globals.uUnproject.x, ((-1.0) * (_9036.y * _9033)) / Globals.uUnproject.y, _9033);
                                                        vec3 _8962 = ((Globals.uCameraToCache + (Globals.uViewToWorld0 * _9048.x)) + (Globals.uViewToWorld1 * _9048.y)) + (Globals.uViewToWorld2 * _9048.z);
                                                        nWorld = _8962;
                                                        vec3 _8972 = normalize((textureLod(_9346, _8939, 0.0).xyz * 2.0) - vec3(1.0));
                                                        nNormal = _8972;
                                                        if (dot(_8972, _8962 - Globals.uCameraToCache) > 0.0)
                                                        {
                                                            nNormal = -nNormal;
                                                        }
                                                        _8910 = true;
                                                    }
                                                }
                                                _96 = _8910;
                                            }
                                            else
                                            {
                                                _96 = false;
                                            }
                                            if (_96)
                                            {
                                                _108 = distance(nWorld, world) < _3622;
                                            }
                                            else
                                            {
                                                _108 = false;
                                            }
                                            if (_108)
                                            {
                                                _109 = dot(nNormal, worldNormal) > 0.800000011920928955078125;
                                            }
                                            else
                                            {
                                                _109 = false;
                                            }
                                            if (_109)
                                            {
                                                vec3 _3718 = _sampled.xyz;
                                                bvec3 _9558 = isnan(historySum);
                                                bvec3 _9559 = isnan(_3718);
                                                vec3 _9560 = min(historySum, _3718);
                                                vec3 _9561 = vec3(_9558.x ? _3718.x : _9560.x, _9558.y ? _3718.y : _9560.y, _9558.z ? _3718.z : _9560.z);
                                                bvec3 _9563 = isnan(accumulated);
                                                bvec3 _9564 = isnan(_3718);
                                                vec3 _9565 = max(accumulated, _3718);
                                                vec3 _9566 = vec3(_9563.x ? _3718.x : _9565.x, _9563.y ? _3718.y : _9565.y, _9563.z ? _3718.z : _9565.z);
                                                nMin_1 = vec3(_9559.x ? historySum.x : _9561.x, _9559.y ? historySum.y : _9561.y, _9559.z ? historySum.z : _9561.z);
                                                nMax_1 = vec3(_9564.x ? accumulated.x : _9566.x, _9564.y ? accumulated.y : _9566.y, _9564.z ? accumulated.z : _9566.z);
                                                nSum_2 = nSum_1 + _3718;
                                                weightSum = frameSum + 1.0;
                                            }
                                            else
                                            {
                                                nMin_1 = historySum;
                                                nMax_1 = accumulated;
                                                nSum_2 = nSum_1;
                                                weightSum = frameSum;
                                            }
                                            nSum_1 = nSum_2;
                                            frameSum = weightSum;
                                        }
                                    }
                                }
                            }
                            if (_144_ladder_break)
                            {
                                break;
                            }
                            historySum = nMin_1;
                            accumulated = nMax_1;
                            t++;
                            continue;
                        }
                        nMin = historySum;
                        nMax = accumulated;
                        dy++;
                        nSum = nSum_1;
                        nCount = frameSum;
                        continue;
                    }
                    float _3772 = nCount;
                    vec3 est = nSum / vec3(_3772);
                    float frames;
                    if (Globals.uHasHistory != 0)
                    {
                        vec3 prevView = ((Globals.uPrevWorldToView0 * (world.x - Globals.uPrevCameraToCache.x)) + (Globals.uPrevWorldToView1 * (world.y - Globals.uPrevCameraToCache.y))) + (Globals.uPrevWorldToView2 * (world.z - Globals.uPrevCameraToCache.z));
                        float _3806 = prevView.z;
                        if (_3806 > 0.0)
                        {
                            vec2 prevUv_1 = (vec2((prevView.x * Globals.uPrevUnproject.x) / _3806, ((-1.0) * (prevView.y * Globals.uPrevUnproject.y)) / _3806) * 0.5) + vec2(0.5);
                            vec2 prevUv;
                            if (Globals.uHasVelocity != 0)
                            {
                                uint _9051 = uint(Globals.uFrameIndex);
                                uint _9052 = _9051 & 7u;
                                vec2 screen = vec2(float(Globals.uScreenWidth), float(Globals.uScreenHeight));
                                vec2 probeUv = (vec2(min(((_233 * ivec2(Globals.uProbeStep)) + min(ivec2(floor(((vec2(float(_9052), float((((_9051 & 1u) << uint(2)) | (_9051 & 2u)) | ((_9052 >> uint(2)) & 1u))) + vec2(0.5)) * vec2(0.125)) * float(Globals.uProbeStep))), ivec2(Globals.uProbeStep - 1))), (ivec2(Globals.uScreenWidth, Globals.uScreenHeight) - ivec2(1)))) + vec2(0.5)) / screen;
                                vec2 motion = textureLod(_9373, probeUv, 0.0).xy;
                                vec2 apart = (motion - (probeUv - prevUv_1)) * screen;
                                bool _3863 = dot(apart, apart) > 2.25;
                                if (_3863)
                                {
                                    prevUv = probeUv - motion;
                                }
                                else
                                {
                                    prevUv = prevUv_1;
                                }
                                ownMotion = _3863;
                            }
                            else
                            {
                                prevUv = prevUv_1;
                                ownMotion = false;
                            }
                            if (all(greaterThanEqual(prevUv, vec2(0.0))))
                            {
                                _95 = all(lessThanEqual(prevUv, vec2(1.0)));
                            }
                            else
                            {
                                _95 = false;
                            }
                            if (_95)
                            {
                                uint _9076 = uint(Globals.uFrameIndex - 1);
                                uint _9077 = _9076 & 7u;
                                vec2 tc = (((prevUv * vec2(float(Globals.uScreenWidth), float(Globals.uScreenHeight))) - vec2(min(ivec2(floor(((vec2(float(_9077), float((((_9076 & 1u) << uint(2)) | (_9076 & 2u)) | ((_9077 >> uint(2)) & 1u))) + vec2(0.5)) * vec2(0.125)) * float(Globals.uProbeStep))), ivec2(Globals.uProbeStep - 1)))) - vec2(0.5)) / vec2(float(Globals.uProbeStep));
                                vec2 _3911 = floor(tc);
                                vec2 _3912 = tc - _3911;
                                float _3925 = ((2.0 * viewPosition.z) * float(Globals.uProbeStep)) / (Globals.uUnproject.y * float(Globals.uScreenHeight));
                                t = 0;
                                historySum = vec3(0.0);
                                frameSum = 0.0;
                                weightSum = 0.0;
                                for (;;)
                                {
                                    bool _193_ladder_break = false;
                                    {
                                        if (!(t < 4))
                                        {
                                            _193_ladder_break = true;
                                        }
                                        else
                                        {
                                            int _3936 = t & 1;
                                            int _3938 = t >> 1;
                                            ivec2 tap = ivec2(_3911) + ivec2(_3936, _3938);
                                            if (any(lessThan(tap, ivec2(0))))
                                            {
                                                _95 = true;
                                            }
                                            else
                                            {
                                                _95 = any(greaterThanEqual(tap, grid));
                                            }
                                            if (!(_95))
                                            {
                                                ivec2 _3955 = ivec3(tap, 0).xy;
                                                vec4 _sampled_1 = texelFetch(_9349, _3955, 0);
                                                if (!(_sampled_1.w <= 0.0))
                                                {
                                                    if (!ownMotion)
                                                    {
                                                        float _3974 = 0.5 * _3925;
                                                        _96 = abs(dot((_sampled_1.xyz + Globals.uPrevCameraToCache) - world, worldNormal)) > (isnan(_3974) ? 0.0500000007450580596923828125 : (isnan(0.0500000007450580596923828125) ? _3974 : max(0.0500000007450580596923828125, _3974)));
                                                    }
                                                    else
                                                    {
                                                        _96 = false;
                                                    }
                                                    if (!(_96))
                                                    {
                                                        if (_3936 == 0)
                                                        {
                                                            nCount = 1.0 - _3912.x;
                                                        }
                                                        else
                                                        {
                                                            nCount = _3912.x;
                                                        }
                                                        if (_3938 == 0)
                                                        {
                                                            frames = 1.0 - _3912.y;
                                                        }
                                                        else
                                                        {
                                                            frames = _3912.y;
                                                        }
                                                        float w = nCount * frames;
                                                        vec4 _sampled_2 = texelFetch(_9376, _3955, 0);
                                                        historySum += (_sampled_2.xyz * w);
                                                        frameSum += (_sampled_2.w * w);
                                                        weightSum += w;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    if (_193_ladder_break)
                                    {
                                        break;
                                    }
                                    t++;
                                    continue;
                                }
                                if (weightSum > 0.00999999977648258209228515625)
                                {
                                    vec3 windowCentre = (nMin + nMax) * 0.5;
                                    vec3 _4049 = ((((nMax - nMin) * 0.5) + (windowCentre * 0.25)) + vec3(0.001000000047497451305389404296875)) * 2.0;
                                    float _4056 = (frameSum / weightSum) + 1.0;
                                    float _4060 = float(Globals.uMaxAccumulated);
                                    float _4061 = isnan(_4060) ? _4056 : (isnan(_4056) ? _4060 : min(_4056, _4060));
                                    accumulated = mix(clamp(historySum / vec3(weightSum), windowCentre - _4049, windowCentre + _4049), est, vec3(1.0 / (1.0 + _4061)));
                                    frames = _4061;
                                }
                                else
                                {
                                    accumulated = est;
                                    frames = 0.0;
                                }
                            }
                            else
                            {
                                accumulated = est;
                                frames = 0.0;
                            }
                        }
                        else
                        {
                            accumulated = est;
                            frames = 0.0;
                        }
                    }
                    else
                    {
                        accumulated = est;
                        frames = 0.0;
                    }
                    if (Globals.uDebugSource == 4)
                    {
                        accumulated = current;
                        frames = 1.0;
                    }
                    imageStore(uIndirect, ivec2(gl_GlobalInvocationID.xy), vec4(accumulated, frames));
                    imageStore(uPosition, ivec2(gl_GlobalInvocationID.xy), vec4(world - Globals.uCameraToCache, 1.0));
                }
            }
        }
    }
}

