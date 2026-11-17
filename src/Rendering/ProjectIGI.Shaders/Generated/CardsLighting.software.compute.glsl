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

uniform ivec2 _1613_comp[4] = ivec2[](ivec2(0), ivec2(1, 0), ivec2(0, 1), ivec2(1));
uniform ivec2 _1798_comp[4] = ivec2[](ivec2(-1, 0), ivec2(1, 0), ivec2(0, -1), ivec2(0, 1));

layout(binding = 0, std140) uniform SLANG_ParameterGroup_Globals_std140
{
    _Array_std140_vector_float_4_4 uClipmapOrigin;
    _Array_std140_vector_float_4_7 uSkySh;
    vec3 uAtlasSize;
    vec3 uLookupMin;
    vec3 uSunDirection;
    vec3 uSunColour;
    vec3 uSkyColour;
    vec3 uActiveCentre;
    vec3 uProbeMin;
    vec3 uTraceOrigin;
    _Array_std140_float4 uClipmapRange;
    int uShadowLevels;
    int uShadowResolution;
    int uLookupBuckets;
    float uLookupCell;
    int uTileCount;
    int uTileOffset;
    int uUseActiveList;
    int uActiveCount;
    int uTileStride;
    float uActiveRadius;
    int uLightCount;
    float uLocalScale;
    int uProbeWidth;
    int uProbeHeight;
    int uTemporalIndex;
    int uMaxFrames;
    int uJitterStride;
    int uMode;
    float uBoost;
    int uSkyShValid;
    int uProbe;
    float uProbeInvExtent;
} Globals;

layout(binding = 6, std430) restrict readonly buffer StructuredBuffer
{
    int _member0[];
} uActiveTiles;

layout(binding = 1, std430) restrict readonly buffer uTiles
{
    ivec4 _member0[];
} uTiles_1;

layout(binding = 0, std430) restrict readonly buffer uPages
{
    vec4 _member0[];
} uPages_1;

layout(binding = 5, std430) restrict buffer RWStructuredBuffer
{
    vec4 _member0[];
} uProbePos;

layout(binding = 3, std430) restrict buffer uCells
{
    ivec2 _member0[];
} uCells_1;

layout(binding = 4, std430) restrict buffer uCellPages
{
    int _member0[];
} uCellPages_1;

layout(binding = 2, std430) restrict readonly buffer uLights
{
    vec4 _member0[];
} uLights_1;

layout(binding = 7, std430) restrict readonly buffer uLampMapRecords
{
    vec4 _member0[];
} uLampMapRecords_1;

layout(binding = 0, rgba16f) uniform restrict image2D uDirect;
layout(binding = 0) uniform sampler2D _6004;
layout(binding = 1) uniform sampler2D _6006;
layout(binding = 2) uniform sampler2D _6008;
layout(binding = 3) uniform sampler2D _6010;
layout(binding = 4) uniform sampler3D _6012;
layout(binding = 6) uniform sampler2D _6014;
layout(binding = 5) uniform sampler2D _6017;
layout(binding = 7) uniform sampler2D _6019;
layout(binding = 8) uniform sampler2DArray _6022;

void main()
{
    bool _5831 = false;
    bool _5755 = false;
    bool _5394 = false;
    bool _5313 = false;
    bool _4978 = false;
    bool _4897 = false;
    bool _4790 = false;
    bool _4680 = false;
    bool _4588 = false;
    bool _3353 = false;
    bool _3272 = false;
    {
        int slot = (int(gl_WorkGroupID.x) * max(Globals.uTileStride, 1)) + Globals.uTileOffset;
        int tile;
        if (Globals.uUseActiveList != 0)
        {
            if (!(slot >= Globals.uActiveCount))
            {
                tile = uActiveTiles._member0[slot];
                if (!(tile >= Globals.uTileCount))
                {
                    ivec2 within = (uTiles_1._member0[tile].yz * ivec2(8)) + ivec2(gl_LocalInvocationID.xy);
                    int at = uTiles_1._member0[tile].x * 10;
                    int _230 = at + 5;
                    if (!(uPages_1._member0[_230].w > 0.5))
                    {
                        if (Globals.uActiveRadius > 0.0)
                        {
                            int _247 = at + 9;
                            vec3 toCentre = uPages_1._member0[_247].xyz - Globals.uActiveCentre;
                            float limit = Globals.uActiveRadius + uPages_1._member0[_247].w;
                            if (!(dot(toCentre, toCentre) > (limit * limit)))
                            {
                                int _267 = at + 1;
                                int _272 = int(uPages_1._member0[at].z);
                                bool _80;
                                if (within.x >= _272)
                                {
                                    _80 = true;
                                }
                                else
                                {
                                    _80 = within.y >= int(uPages_1._member0[at].w);
                                }
                                if (!(_80))
                                {
                                    int _287 = at + 2;
                                    int _291 = at + 3;
                                    int _295 = at + 4;
                                    int _300 = at + 6;
                                    int _304 = at + 7;
                                    int _307 = at + 8;
                                    vec2 uv = (vec2(within) + vec2(0.5)) / vec2(uPages_1._member0[at].zw);
                                    uvec2 _vecSize = uvec2(textureSize(_6004, 0));
                                    vec2 cardUv = (uPages_1._member0[_267].xy + (uv * uPages_1._member0[_267].zw)) / vec2(float(_vecSize.x), float(_vecSize.y));
                                    vec4 _sampled = textureLod(_6006, cardUv, 0.0);
                                    ivec2 pageAt = ivec2(int(uPages_1._member0[at].x), int(uPages_1._member0[at].y));
                                    if (_sampled.w < 0.5)
                                    {
                                        imageStore(uDirect, ivec2(uvec2(pageAt + within)), vec4(0.0));
                                    }
                                    else
                                    {
                                        vec3 _363 = normalize((textureLod(_6008, cardUv, 0.0).xyz * 2.0) - vec3(1.0));
                                        vec3 local = ((uPages_1._member0[_287].xyz + ((uPages_1._member0[_291].xyz * ((uv.x * 2.0) - 1.0)) * uPages_1._member0[_287].w)) + ((uPages_1._member0[_295].xyz * ((uv.y * 2.0) - 1.0)) * uPages_1._member0[_291].w)) - (uPages_1._member0[_230].xyz * (textureLod(_6010, cardUv, 0.0).x * uPages_1._member0[_295].w));
                                        vec3 _395 = vec3(uPages_1._member0[_300].x, uPages_1._member0[_304].x, uPages_1._member0[_307].x);
                                        vec3 _400 = vec3(uPages_1._member0[_300].y, uPages_1._member0[_304].y, uPages_1._member0[_307].y);
                                        vec3 _405 = vec3(uPages_1._member0[_300].z, uPages_1._member0[_304].z, uPages_1._member0[_307].z);
                                        vec3 world = vec3(dot(_395, local), dot(_400, local), dot(_405, local)) + vec3(uPages_1._member0[_300].w, uPages_1._member0[_304].w, uPages_1._member0[_307].w);
                                        vec3 _417 = normalize(vec3(dot(_395, _363), dot(_400, _363), dot(_405, _363)));
                                        ivec2 texelAt = pageAt + within;
                                        float visibility;
                                        if (Globals.uMode == 1)
                                        {
                                            if (((texelAt.x | texelAt.y) & 3) != 0)
                                            {
                                                imageStore(uDirect, ivec2(uvec2(texelAt)), vec4(0.0));
                                            }
                                            else
                                            {
                                                ivec2 probeCoord = texelAt >> ivec2(2);
                                                uProbePos._member0[(probeCoord.y * Globals.uProbeWidth) + probeCoord.x] = vec4(world, 1.0);
                                                vec2 _3036;
                                                {
                                                    if (Globals.uTemporalIndex <= 0)
                                                    {
                                                        _3036 = vec2(0.5);
                                                    }
                                                    else
                                                    {
                                                        float _3051 = float(((uint(probeCoord.x) * 73856093u) ^ (uint(probeCoord.y) * 19349663u)) & 65535u);
                                                        int _3057 = (Globals.uTemporalIndex / max(Globals.uJitterStride, 1)) & 65535;
                                                        uint _3072 = uint(_3057);
                                                        uint _3075 = (_3072 << 16u) | (_3072 >> 16u);
                                                        uint _3080 = ((_3075 & 1431655765u) << 1u) | ((_3075 & 2863311530u) >> 1u);
                                                        uint _3085 = ((_3080 & 858993459u) << 2u) | ((_3080 & 3435973836u) >> 2u);
                                                        uint _3090 = ((_3085 & 252645135u) << 4u) | ((_3085 & 4042322160u) >> 4u);
                                                        _3036 = fract(vec2(fract(float(_3057) * 0.61803400516510009765625), float(((_3090 & 16711935u) << 8u) | ((_3090 & 4278255360u) >> 8u)) * 2.3283064365386962890625e-10) + vec2(_3051 * 1.52587890625e-05, fract(_3051 * 2.4689239580766297876834869384766e-05)));
                                                    }
                                                }
                                                vec3 _3099;
                                                {
                                                    bool _3100;
                                                    if (Globals.uShadowLevels <= 0)
                                                    {
                                                        _3100 = true;
                                                    }
                                                    else
                                                    {
                                                        _3100 = Globals.uLookupBuckets <= 0;
                                                    }
                                                    if (_3100)
                                                    {
                                                        _3099 = vec3(0.0);
                                                    }
                                                    else
                                                    {
                                                        vec3 _5941;
                                                        vec3 _5942;
                                                        vec3 _5943;
                                                        {
                                                            vec3 _5956 = _417;
                                                            float _3228 = _417.z;
                                                            if (_3228 < (-0.99999988079071044921875))
                                                            {
                                                                _5941 = vec3(0.0, -1.0, 0.0);
                                                                _5942 = vec3(-1.0, 0.0, 0.0);
                                                                _5943 = _5956;
                                                            }
                                                            else
                                                            {
                                                                float _3236 = 1.0 / (1.0 + _3228);
                                                                float _3237 = _417.x;
                                                                float _3238 = -_3237;
                                                                float _3239 = _417.y;
                                                                float _3241 = (_3238 * _3239) * _3236;
                                                                _5941 = vec3(1.0 - ((_3237 * _3237) * _3236), _3241, _3238);
                                                                _5942 = vec3(_3241, 1.0 - ((_3239 * _3239) * _3236), -_3239);
                                                                _5943 = _5956;
                                                            }
                                                        }
                                                        int _3101 = 0;
                                                        vec4 _3102 = vec4(0.0);
                                                        vec4 _3103 = vec4(0.0);
                                                        vec4 _3104 = vec4(0.0);
                                                        vec3 _3106;
                                                        vec3 _3107;
                                                        vec2 _3109;
                                                        float _3273;
                                                        bool _3276;
                                                        bool _3277;
                                                        float _3279;
                                                        float _3354;
                                                        bool _3356;
                                                        bool _3468;
                                                        bool _3474;
                                                        ivec2 _3475;
                                                        bool _3479;
                                                        bool _3488;
                                                        bool _3489;
                                                        bool _3490;
                                                        bool _3491;
                                                        bool _3492;
                                                        ivec2 _3722;
                                                        for (;;)
                                                        {
                                                            if (!(_3101 < 16))
                                                            {
                                                                break;
                                                            }
                                                            int _3140 = _3101;
                                                            vec2 _3149 = (vec2(float(_3140 - 4 * (_3140 / 4)), float(_3140 / 4)) + _3036) * vec2(0.25);
                                                            float _3151 = 6.283185482025146484375 * _3149.x;
                                                            float _3152 = _3149.y;
                                                            float _3154 = 1.0 - (_3152 * _3152);
                                                            float _3156 = sqrt(isnan(_3154) ? 0.0 : (isnan(0.0) ? _3154 : max(0.0, _3154)));
                                                            vec3 _3271 = ((_5941 * (_3156 * cos(_3151))) + (_5942 * (_3156 * sin(_3151)))) + (_5943 * _3152);
                                                            _3272 = false;
                                                            {
                                                                _3106 = world;
                                                                if (Globals.uShadowLevels <= 0)
                                                                {
                                                                    _3272 = true;
                                                                    _3273 = 1.0;
                                                                }
                                                                else
                                                                {
                                                                    vec3 _3296 = world + ((_417 * Globals.uClipmapOrigin.data[0].w) * 1.5);
                                                                    float _3307 = (Globals.uClipmapOrigin.data[0].w * float(Globals.uShadowResolution)) * float(1 << (Globals.uShadowLevels - 1));
                                                                    int _3274 = 0;
                                                                    float _3275 = 0.0;
                                                                    for (;;)
                                                                    {
                                                                        if (_3274 < 64)
                                                                        {
                                                                            _3276 = _3275 < _3307;
                                                                        }
                                                                        else
                                                                        {
                                                                            _3276 = false;
                                                                        }
                                                                        if (!_3276)
                                                                        {
                                                                            break;
                                                                        }
                                                                        vec3 _3324 = _3296 + (_3271 * _3275);
                                                                        _3353 = false;
                                                                        {
                                                                            _3277 = false;
                                                                            _3279 = Globals.uClipmapOrigin.data[0].w;
                                                                            int _3355 = 0;
                                                                            for (;;)
                                                                            {
                                                                                bool _3367_ladder_break = false;
                                                                                {
                                                                                    if (!(_3355 < Globals.uShadowLevels))
                                                                                    {
                                                                                        _3367_ladder_break = true;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        vec3 _3382 = (_3324 - Globals.uClipmapOrigin.data[_3355].xyz) / vec3(Globals.uClipmapOrigin.data[_3355].w);
                                                                                        if (any(lessThan(_3382, vec3(0.5))))
                                                                                        {
                                                                                            _3356 = true;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            _3356 = any(greaterThan(_3382, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                                        }
                                                                                        if (!(_3356))
                                                                                        {
                                                                                            _3277 = true;
                                                                                            _3279 = Globals.uClipmapOrigin.data[_3355].w;
                                                                                            _3353 = true;
                                                                                            _3354 = ((textureLod(_6012, vec3(_3382.x / float(Globals.uShadowResolution), _3382.y / float(Globals.uShadowResolution), ((float(_3355) * float(Globals.uShadowResolution)) + _3382.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_3355];
                                                                                            _3367_ladder_break = true;
                                                                                        }
                                                                                    }
                                                                                }
                                                                                if (_3367_ladder_break)
                                                                                {
                                                                                    break;
                                                                                }
                                                                                _3355++;
                                                                                continue;
                                                                            }
                                                                            if (!(_3353))
                                                                            {
                                                                                _3353 = true;
                                                                                _3354 = 1000000.0;
                                                                            }
                                                                        }
                                                                        if (!_3277)
                                                                        {
                                                                            _3272 = true;
                                                                            _3273 = 1.0;
                                                                            break;
                                                                        }
                                                                        float _3454 = 2.0 * _3279;
                                                                        float _3458 = (0.5 * _3279) * clamp(_3275 / (isnan(9.9999999747524270787835121154785e-07) ? _3454 : (isnan(_3454) ? 9.9999999747524270787835121154785e-07 : max(_3454, 9.9999999747524270787835121154785e-07))), 0.0, 1.0);
                                                                        float _3460 = (_3275 + _3354) - _3458;
                                                                        float _3280 = isnan(0.0) ? _3460 : (isnan(_3460) ? 0.0 : max(_3460, 0.0));
                                                                        if (_3354 < _3458)
                                                                        {
                                                                            _3106 = _3296 + (_3271 * _3280);
                                                                            _3272 = true;
                                                                            _3273 = 0.0;
                                                                            break;
                                                                        }
                                                                        float _3339 = _3279 * 0.25;
                                                                        _3274++;
                                                                        _3275 += (isnan(_3339) ? _3354 : (isnan(_3354) ? _3339 : max(_3354, _3339)));
                                                                        continue;
                                                                    }
                                                                    if (!(_3272))
                                                                    {
                                                                        _3272 = true;
                                                                        _3273 = 1.0;
                                                                    }
                                                                }
                                                            }
                                                            if (_3273 <= 0.5)
                                                            {
                                                                {
                                                                    _3109 = vec2(0.0);
                                                                    float _3110 = 1000000000.0;
                                                                    if (Globals.uLookupBuckets <= 0)
                                                                    {
                                                                        _3468 = false;
                                                                    }
                                                                    else
                                                                    {
                                                                        ivec3 _3509 = ivec3(floor((_3106 - Globals.uLookupMin) / vec3(Globals.uLookupCell)));
                                                                        int _3721 = int((((uint(_3509.x) * 2376512323u) ^ (uint(_3509.y) * 3625334849u)) ^ (uint(_3509.z) * 3407524639u)) & uint(Globals.uLookupBuckets - 1));
                                                                        uvec2 _3514 = uvec2(textureSize(_6004, 0));
                                                                        vec2 _3521 = vec2(float(_3514.x), float(_3514.y));
                                                                        bool _3471 = false;
                                                                        bool _3472 = false;
                                                                        int _3473 = 0;
                                                                        for (;;)
                                                                        {
                                                                            if (_3473 <= uCells_1._member0[Globals.uLookupBuckets].y)
                                                                            {
                                                                                _3474 = !_3471;
                                                                            }
                                                                            else
                                                                            {
                                                                                _3474 = false;
                                                                            }
                                                                            if (!_3474)
                                                                            {
                                                                                break;
                                                                            }
                                                                            bool _3541 = _3473 == 0;
                                                                            if (_3541)
                                                                            {
                                                                                _3475 = uCells_1._member0[_3721];
                                                                            }
                                                                            else
                                                                            {
                                                                                int _3726 = uCells_1._member0[Globals.uLookupBuckets].x + ((_3473 - 1) * 6);
                                                                                float _3742 = intBitsToFloat(uCellPages_1._member0[_3726 + 3]);
                                                                                vec3 _3744 = _3106 - vec3(intBitsToFloat(uCellPages_1._member0[_3726]), intBitsToFloat(uCellPages_1._member0[_3726 + 1]), intBitsToFloat(uCellPages_1._member0[_3726 + 2]));
                                                                                if (dot(_3744, _3744) > (_3742 * _3742))
                                                                                {
                                                                                    _3722 = ivec2(0);
                                                                                }
                                                                                else
                                                                                {
                                                                                    _3722 = ivec2(uCellPages_1._member0[_3726 + 4], uCellPages_1._member0[_3726 + 5]);
                                                                                }
                                                                                _3475 = _3722;
                                                                            }
                                                                            bool _3476 = _3471;
                                                                            bool _3477 = _3472;
                                                                            int _3478 = 0;
                                                                            for (;;)
                                                                            {
                                                                                bool _3553_ladder_break = false;
                                                                                {
                                                                                    if (_3478 < _3475.y)
                                                                                    {
                                                                                        _3479 = !_3476;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        _3479 = false;
                                                                                    }
                                                                                    if (!_3479)
                                                                                    {
                                                                                        _3553_ladder_break = true;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        int _3570 = _3475.x + _3478;
                                                                                        int _3573 = uCellPages_1._member0[_3570] * 10;
                                                                                        if (!((uPages_1._member0[_3573 + 5].w > 0.5) == _3541))
                                                                                        {
                                                                                            int _3582 = _3573 + 9;
                                                                                            vec3 _3586 = _3106 - uPages_1._member0[_3582].xyz;
                                                                                            if (!(dot(_3586, _3586) > (uPages_1._member0[_3582].w * uPages_1._member0[_3582].w)))
                                                                                            {
                                                                                                vec3 _3593 = -_3271;
                                                                                                int _3760 = uCellPages_1._member0[_3570] * 10;
                                                                                                vec4 _3486 = uPages_1._member0[_3760];
                                                                                                vec4 _3487 = uPages_1._member0[_3760 + 1];
                                                                                                int _3766 = _3760 + 2;
                                                                                                int _3769 = _3760 + 3;
                                                                                                int _3772 = _3760 + 4;
                                                                                                int _3778 = _3760 + 6;
                                                                                                int _3781 = _3760 + 7;
                                                                                                int _3784 = _3760 + 8;
                                                                                                vec3 _3791 = _3106 - vec3(uPages_1._member0[_3778].w, uPages_1._member0[_3781].w, uPages_1._member0[_3784].w);
                                                                                                vec3 _3485 = vec3(dot(uPages_1._member0[_3778].xyz, _3593), dot(uPages_1._member0[_3781].xyz, _3593), dot(uPages_1._member0[_3784].xyz, _3593));
                                                                                                vec3 _3804 = vec3(dot(uPages_1._member0[_3778].xyz, _3791), dot(uPages_1._member0[_3781].xyz, _3791), dot(uPages_1._member0[_3784].xyz, _3791)) - uPages_1._member0[_3766].xyz;
                                                                                                vec2 _3807 = vec2(uPages_1._member0[_3766].w, uPages_1._member0[_3769].w);
                                                                                                bvec2 _6044 = isnan(_3807);
                                                                                                bvec2 _6045 = isnan(vec2(9.9999999747524270787835121154785e-07));
                                                                                                vec2 _6046 = max(_3807, vec2(9.9999999747524270787835121154785e-07));
                                                                                                vec2 _6047 = vec2(_6044.x ? vec2(9.9999999747524270787835121154785e-07).x : _6046.x, _6044.y ? vec2(9.9999999747524270787835121154785e-07).y : _6046.y);
                                                                                                vec2 _3814 = vec2(dot(_3804, uPages_1._member0[_3769].xyz), dot(_3804, uPages_1._member0[_3772].xyz)) / vec2(_6045.x ? _3807.x : _6047.x, _6045.y ? _3807.y : _6047.y);
                                                                                                vec2 _3480 = _3814;
                                                                                                float _3482 = -dot(_3804, uPages_1._member0[_3760 + 5].xyz);
                                                                                                float _3483 = uPages_1._member0[_3772].w;
                                                                                                vec3 _3484 = uPages_1._member0[_3760 + 5].xyz;
                                                                                                if (abs(_3814.x) > 1.0)
                                                                                                {
                                                                                                    _3488 = true;
                                                                                                }
                                                                                                else
                                                                                                {
                                                                                                    _3488 = abs(_3480.y) > 1.0;
                                                                                                }
                                                                                                if (!(_3488))
                                                                                                {
                                                                                                    if (dot(_3271, _3271) > 0.5)
                                                                                                    {
                                                                                                        _3489 = dot(_3484, _3485) < (-0.0500000007450580596923828125);
                                                                                                    }
                                                                                                    else
                                                                                                    {
                                                                                                        _3489 = false;
                                                                                                    }
                                                                                                    if (!(_3489))
                                                                                                    {
                                                                                                        if (_3482 < (-0.25))
                                                                                                        {
                                                                                                            _3490 = true;
                                                                                                        }
                                                                                                        else
                                                                                                        {
                                                                                                            _3490 = _3482 > (_3483 + 0.25);
                                                                                                        }
                                                                                                        if (!(_3490))
                                                                                                        {
                                                                                                            vec2 _3637 = (_3480 * 0.5) + vec2(0.5);
                                                                                                            vec2 _3644 = (_3487.xy + (_3637 * _3487.zw)) / _3521;
                                                                                                            if (!(textureLod(_6006, _3644, 0.0).w < 0.5))
                                                                                                            {
                                                                                                                float _3664 = abs((textureLod(_6010, _3644, 0.0).x * _3483) - _3482);
                                                                                                                if (_3664 < _3110)
                                                                                                                {
                                                                                                                    _3110 = _3664;
                                                                                                                    _3109 = (_3486.xy + (_3637 * _3486.zw)) / Globals.uAtlasSize.xy;
                                                                                                                    _3491 = _3664 < 0.0199999995529651641845703125;
                                                                                                                    _3492 = true;
                                                                                                                }
                                                                                                                else
                                                                                                                {
                                                                                                                    _3491 = _3476;
                                                                                                                    _3492 = _3477;
                                                                                                                }
                                                                                                                _3476 = _3491;
                                                                                                                _3477 = _3492;
                                                                                                            }
                                                                                                        }
                                                                                                    }
                                                                                                }
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                                if (_3553_ladder_break)
                                                                                {
                                                                                    break;
                                                                                }
                                                                                _3478++;
                                                                                continue;
                                                                            }
                                                                            _3471 = _3476;
                                                                            _3472 = _3477;
                                                                            _3473++;
                                                                            continue;
                                                                        }
                                                                        _3468 = _3472;
                                                                    }
                                                                }
                                                                if (_3468)
                                                                {
                                                                    _3107 = textureLod(_6014, _3109, 0.0).xyz * smoothstep(1.5 * Globals.uClipmapOrigin.data[0].w, 2.0 * Globals.uClipmapOrigin.data[0].w, length(_3106 - world));
                                                                }
                                                                else
                                                                {
                                                                    _3107 = vec3(0.0);
                                                                }
                                                            }
                                                            else
                                                            {
                                                                _3107 = vec3(0.0);
                                                            }
                                                            vec4 _3827 = vec4(0.2820949852466583251953125, (-0.48860299587249755859375) * _3271.y, 0.48860299587249755859375 * _3271.z, (-0.48860299587249755859375) * _3271.x);
                                                            _3101++;
                                                            _3102 += (_3827 * _3107.x);
                                                            _3103 += (_3827 * _3107.y);
                                                            _3104 += (_3827 * _3107.z);
                                                            continue;
                                                        }
                                                        vec4 _3844 = vec4(0.2820949852466583251953125, (-0.48860299587249755859375) * _417.y, 0.48860299587249755859375 * _417.z, (-0.48860299587249755859375) * _417.x);
                                                        vec4 _3835 = vec4(_3844.x * 3.1415927410125732421875, _3844.yzw * 2.094395160675048828125);
                                                        vec3 _3217 = vec3(dot(_3102, _3835), dot(_3103, _3835), dot(_3104, _3835)) * 0.3926990926265716552734375;
                                                        bvec3 _6049 = isnan(_3217);
                                                        bvec3 _6050 = isnan(vec3(0.0));
                                                        vec3 _6051 = max(_3217, vec3(0.0));
                                                        vec3 _6052 = vec3(_6049.x ? vec3(0.0).x : _6051.x, _6049.y ? vec3(0.0).y : _6051.y, _6049.z ? vec3(0.0).z : _6051.z);
                                                        _3099 = vec3(_6050.x ? _3217.x : _6052.x, _6050.y ? _3217.y : _6052.y, _6050.z ? _3217.z : _6052.z);
                                                    }
                                                }
                                                vec4 _sampled_1 = imageLoad(uDirect, texelAt);
                                                if (Globals.uTemporalIndex > 0)
                                                {
                                                    visibility = _sampled_1.w;
                                                }
                                                else
                                                {
                                                    visibility = 0.0;
                                                }
                                                float limit_1 = float(Globals.uMaxFrames);
                                                float _1575 = visibility + 1.0;
                                                float _1576 = limit_1 + 1.0;
                                                imageStore(uDirect, ivec2(uvec2(texelAt)), vec4(mix(_sampled_1.xyz, _3099, vec3(1.0 / (1.0 + (isnan(limit_1) ? visibility : (isnan(visibility) ? limit_1 : min(visibility, limit_1)))))), isnan(_1576) ? _1575 : (isnan(_1575) ? _1576 : min(_1575, _1576))));
                                            }
                                        }
                                        else
                                        {
                                            int light;
                                            vec3 lit;
                                            if (Globals.uMode == 2)
                                            {
                                                ivec2 _1593 = pageAt + ivec2(_272, int(uPages_1._member0[at].w));
                                                ivec2 probe00 = texelAt >> ivec2(2);
                                                vec2 _1604 = (vec2(texelAt - (probe00 * ivec2(4))) + vec2(1.0)) * vec2(0.16666667163372039794921875);
                                                light = 0;
                                                lit = vec3(0.0);
                                                visibility = 0.0;
                                                vec3 position;
                                                bool _3846;
                                                bool _3847;
                                                float _3896;
                                                vec3 _3914;
                                                bool _3973;
                                                bool _3974;
                                                float _4023;
                                                for (;;)
                                                {
                                                    bool _126_ladder_break = false;
                                                    {
                                                        if (!(light < 4))
                                                        {
                                                            _126_ladder_break = true;
                                                        }
                                                        else
                                                        {
                                                            ivec2 probeCoord_1 = probe00 + _1613_comp[light];
                                                            {
                                                                position = vec3(0.0);
                                                                if (any(lessThan(probeCoord_1, ivec2(0))))
                                                                {
                                                                    _3847 = true;
                                                                }
                                                                else
                                                                {
                                                                    _3847 = probeCoord_1.x >= Globals.uProbeWidth;
                                                                }
                                                                if (_3847)
                                                                {
                                                                    _3847 = true;
                                                                }
                                                                else
                                                                {
                                                                    _3847 = probeCoord_1.y >= Globals.uProbeHeight;
                                                                }
                                                                if (_3847)
                                                                {
                                                                    _3846 = false;
                                                                }
                                                                else
                                                                {
                                                                    ivec2 _3872 = probeCoord_1 * ivec2(4);
                                                                    if (any(lessThan(_3872, pageAt)))
                                                                    {
                                                                        _3847 = true;
                                                                    }
                                                                    else
                                                                    {
                                                                        _3847 = any(greaterThanEqual(_3872, _1593));
                                                                    }
                                                                    if (_3847)
                                                                    {
                                                                        _3846 = false;
                                                                    }
                                                                    else
                                                                    {
                                                                        int _3888 = (probeCoord_1.y * Globals.uProbeWidth) + probeCoord_1.x;
                                                                        position = uProbePos._member0[_3888].xyz;
                                                                        _3846 = uProbePos._member0[_3888].w >= 0.5;
                                                                    }
                                                                }
                                                            }
                                                            if (!(!_3846))
                                                            {
                                                                vec3 _3899 = world - position;
                                                                if ((abs(dot(_3899, _417)) / (length(_3899) + 0.00999999977648258209228515625)) < 0.257759988307952880859375)
                                                                {
                                                                    _3896 = 1.0;
                                                                }
                                                                else
                                                                {
                                                                    _3896 = 0.0;
                                                                }
                                                                if (!(_3896 <= 0.0))
                                                                {
                                                                    vec2 _1737 = mix(vec2(1.0) - _1604, _1604, vec2(_1613_comp[light]));
                                                                    float w = _1737.x * _1737.y;
                                                                    int _3910 = 0;
                                                                    vec3 _3911 = textureLod(_6019, (vec2(probeCoord_1 * ivec2(4)) + vec2(0.5)) / Globals.uAtlasSize.xy, 0.0).xyz * 2.0;
                                                                    float _3912 = 2.0;
                                                                    for (;;)
                                                                    {
                                                                        bool _3921_ladder_break = false;
                                                                        {
                                                                            if (!(_3910 < 4))
                                                                            {
                                                                                _3921_ladder_break = true;
                                                                            }
                                                                            else
                                                                            {
                                                                                ivec2 _3930 = probeCoord_1 + _1798_comp[_3910];
                                                                                {
                                                                                    _3914 = vec3(0.0);
                                                                                    if (any(lessThan(_3930, ivec2(0))))
                                                                                    {
                                                                                        _3974 = true;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        _3974 = _3930.x >= Globals.uProbeWidth;
                                                                                    }
                                                                                    if (_3974)
                                                                                    {
                                                                                        _3974 = true;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        _3974 = _3930.y >= Globals.uProbeHeight;
                                                                                    }
                                                                                    if (_3974)
                                                                                    {
                                                                                        _3973 = false;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        ivec2 _3999 = _3930 * ivec2(4);
                                                                                        if (any(lessThan(_3999, pageAt)))
                                                                                        {
                                                                                            _3974 = true;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            _3974 = any(greaterThanEqual(_3999, _1593));
                                                                                        }
                                                                                        if (_3974)
                                                                                        {
                                                                                            _3973 = false;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            int _4015 = (_3930.y * Globals.uProbeWidth) + _3930.x;
                                                                                            _3914 = uProbePos._member0[_4015].xyz;
                                                                                            _3973 = uProbePos._member0[_4015].w >= 0.5;
                                                                                        }
                                                                                    }
                                                                                }
                                                                                if (!(!_3973))
                                                                                {
                                                                                    vec3 _4026 = world - _3914;
                                                                                    if ((abs(dot(_4026, _417)) / (length(_4026) + 0.00999999977648258209228515625)) < 0.257759988307952880859375)
                                                                                    {
                                                                                        _4023 = 1.0;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        _4023 = 0.0;
                                                                                    }
                                                                                    if (!(_4023 <= 0.0))
                                                                                    {
                                                                                        _3911 += textureLod(_6019, (vec2(_3930 * ivec2(4)) + vec2(0.5)) / Globals.uAtlasSize.xy, 0.0).xyz;
                                                                                        _3912 += 1.0;
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                        if (_3921_ladder_break)
                                                                        {
                                                                            break;
                                                                        }
                                                                        _3910++;
                                                                        continue;
                                                                    }
                                                                    lit += ((_3911 / vec3(_3912)) * w);
                                                                    visibility += w;
                                                                }
                                                            }
                                                        }
                                                    }
                                                    if (_126_ladder_break)
                                                    {
                                                        break;
                                                    }
                                                    light++;
                                                    continue;
                                                }
                                                vec3 indirect;
                                                if (visibility > 0.0)
                                                {
                                                    indirect = lit / vec3(visibility);
                                                }
                                                else
                                                {
                                                    indirect = textureLod(_6019, (vec2(probe00 * ivec2(4)) + vec2(0.5)) / Globals.uAtlasSize.xy, 0.0).xyz;
                                                }
                                                vec3 _1862 = _sampled.xyz;
                                                vec3 _4072;
                                                {
                                                    if (Globals.uBoost >= 1.0)
                                                    {
                                                        _4072 = _1862;
                                                    }
                                                    else
                                                    {
                                                        float _4079 = dot(_1862, vec3(0.300000011920928955078125, 0.589999973773956298828125, 0.10999999940395355224609375));
                                                        vec3 _4091 = clamp(_1862 * (pow(isnan(0.0) ? _4079 : (isnan(_4079) ? 0.0 : max(_4079, 0.0)), Globals.uBoost) / (isnan(9.9999999392252902907785028219223e-09) ? _4079 : (isnan(_4079) ? 9.9999999392252902907785028219223e-09 : max(_4079, 9.9999999392252902907785028219223e-09)))), vec3(0.0), vec3(1.0));
                                                        bvec3 _6074 = isnan(_4091);
                                                        bvec3 _6075 = isnan(vec3(0.9900000095367431640625));
                                                        vec3 _6076 = min(_4091, vec3(0.9900000095367431640625));
                                                        vec3 _6077 = vec3(_6074.x ? vec3(0.9900000095367431640625).x : _6076.x, _6074.y ? vec3(0.9900000095367431640625).y : _6076.y, _6074.z ? vec3(0.9900000095367431640625).z : _6076.z);
                                                        _4072 = vec3(_6075.x ? _4091.x : _6077.x, _6075.y ? _4091.y : _6077.y, _6075.z ? _4091.z : _6077.z);
                                                    }
                                                }
                                                imageStore(uDirect, ivec2(uvec2(texelAt)), vec4((texelFetch(_6017, ivec3(texelAt, 0).xy, 0).xyz + indirect) * (_4072 * vec3(0.3183098733425140380859375)), 1.0));
                                            }
                                            else
                                            {
                                                if (Globals.uMode == 3)
                                                {
                                                    vec3 _1920 = _sampled.xyz;
                                                    vec3 _4093;
                                                    {
                                                        if (Globals.uBoost >= 1.0)
                                                        {
                                                            _4093 = _1920;
                                                        }
                                                        else
                                                        {
                                                            float _4100 = dot(_1920, vec3(0.300000011920928955078125, 0.589999973773956298828125, 0.10999999940395355224609375));
                                                            vec3 _4112 = clamp(_1920 * (pow(isnan(0.0) ? _4100 : (isnan(_4100) ? 0.0 : max(_4100, 0.0)), Globals.uBoost) / (isnan(9.9999999392252902907785028219223e-09) ? _4100 : (isnan(_4100) ? 9.9999999392252902907785028219223e-09 : max(_4100, 9.9999999392252902907785028219223e-09)))), vec3(0.0), vec3(1.0));
                                                            bvec3 _6089 = isnan(_4112);
                                                            bvec3 _6090 = isnan(vec3(0.9900000095367431640625));
                                                            vec3 _6091 = min(_4112, vec3(0.9900000095367431640625));
                                                            vec3 _6092 = vec3(_6089.x ? vec3(0.9900000095367431640625).x : _6091.x, _6089.y ? vec3(0.9900000095367431640625).y : _6091.y, _6089.z ? vec3(0.9900000095367431640625).z : _6091.z);
                                                            _4093 = vec3(_6090.x ? _4112.x : _6092.x, _6090.y ? _4112.y : _6092.y, _6090.z ? _4112.z : _6092.z);
                                                        }
                                                    }
                                                    imageStore(uDirect, ivec2(uvec2(texelAt)), vec4(texelFetch(_6017, ivec3(texelAt, 0).xy, 0).xyz * (_4093 * vec3(0.3183098733425140380859375)), 1.0));
                                                }
                                                else
                                                {
                                                    if (Globals.uProbe != 0)
                                                    {
                                                        vec4 _4114;
                                                        {
                                                            if (Globals.uProbe == 5)
                                                            {
                                                                if (((texelAt.x | texelAt.y) & 7) != 0)
                                                                {
                                                                    _4114 = vec4(0.0);
                                                                }
                                                                else
                                                                {
                                                                    vec2 _4115;
                                                                    bool _4237;
                                                                    {
                                                                        _4115 = vec2(0.0);
                                                                        float _4117 = 1000000000.0;
                                                                        if (Globals.uLookupBuckets <= 0)
                                                                        {
                                                                            _4237 = false;
                                                                        }
                                                                        else
                                                                        {
                                                                            ivec3 _4278 = ivec3(floor((world - Globals.uLookupMin) / vec3(Globals.uLookupCell)));
                                                                            int _4490 = int((((uint(_4278.x) * 2376512323u) ^ (uint(_4278.y) * 3625334849u)) ^ (uint(_4278.z) * 3407524639u)) & uint(Globals.uLookupBuckets - 1));
                                                                            uvec2 _4283 = uvec2(textureSize(_6004, 0));
                                                                            vec2 _4290 = vec2(float(_4283.x), float(_4283.y));
                                                                            bool _4240 = false;
                                                                            bool _4241 = false;
                                                                            int _4242 = 0;
                                                                            bool _4243;
                                                                            ivec2 _4244;
                                                                            bool _4248;
                                                                            bool _4257;
                                                                            bool _4258;
                                                                            bool _4259;
                                                                            bool _4260;
                                                                            bool _4261;
                                                                            ivec2 _4491;
                                                                            for (;;)
                                                                            {
                                                                                if (_4242 <= uCells_1._member0[Globals.uLookupBuckets].y)
                                                                                {
                                                                                    _4243 = !_4240;
                                                                                }
                                                                                else
                                                                                {
                                                                                    _4243 = false;
                                                                                }
                                                                                if (!_4243)
                                                                                {
                                                                                    break;
                                                                                }
                                                                                bool _4310 = _4242 == 0;
                                                                                if (_4310)
                                                                                {
                                                                                    _4244 = uCells_1._member0[_4490];
                                                                                }
                                                                                else
                                                                                {
                                                                                    int _4495 = uCells_1._member0[Globals.uLookupBuckets].x + ((_4242 - 1) * 6);
                                                                                    float _4511 = intBitsToFloat(uCellPages_1._member0[_4495 + 3]);
                                                                                    vec3 _4513 = world - vec3(intBitsToFloat(uCellPages_1._member0[_4495]), intBitsToFloat(uCellPages_1._member0[_4495 + 1]), intBitsToFloat(uCellPages_1._member0[_4495 + 2]));
                                                                                    if (dot(_4513, _4513) > (_4511 * _4511))
                                                                                    {
                                                                                        _4491 = ivec2(0);
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        _4491 = ivec2(uCellPages_1._member0[_4495 + 4], uCellPages_1._member0[_4495 + 5]);
                                                                                    }
                                                                                    _4244 = _4491;
                                                                                }
                                                                                bool _4245 = _4240;
                                                                                bool _4246 = _4241;
                                                                                int _4247 = 0;
                                                                                for (;;)
                                                                                {
                                                                                    bool _4322_ladder_break = false;
                                                                                    {
                                                                                        if (_4247 < _4244.y)
                                                                                        {
                                                                                            _4248 = !_4245;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            _4248 = false;
                                                                                        }
                                                                                        if (!_4248)
                                                                                        {
                                                                                            _4322_ladder_break = true;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            int _4339 = _4244.x + _4247;
                                                                                            int _4342 = uCellPages_1._member0[_4339] * 10;
                                                                                            if (!((uPages_1._member0[_4342 + 5].w > 0.5) == _4310))
                                                                                            {
                                                                                                int _4351 = _4342 + 9;
                                                                                                vec3 _4355 = world - uPages_1._member0[_4351].xyz;
                                                                                                if (!(dot(_4355, _4355) > (uPages_1._member0[_4351].w * uPages_1._member0[_4351].w)))
                                                                                                {
                                                                                                    int _4529 = uCellPages_1._member0[_4339] * 10;
                                                                                                    vec4 _4256 = uPages_1._member0[_4529 + 1];
                                                                                                    int _4535 = _4529 + 2;
                                                                                                    int _4538 = _4529 + 3;
                                                                                                    int _4541 = _4529 + 4;
                                                                                                    int _4547 = _4529 + 6;
                                                                                                    int _4550 = _4529 + 7;
                                                                                                    int _4553 = _4529 + 8;
                                                                                                    vec3 _4560 = world - vec3(uPages_1._member0[_4547].w, uPages_1._member0[_4550].w, uPages_1._member0[_4553].w);
                                                                                                    vec3 _4254 = vec3(dot(uPages_1._member0[_4547].xyz, vec3(-0.0)), dot(uPages_1._member0[_4550].xyz, vec3(-0.0)), dot(uPages_1._member0[_4553].xyz, vec3(-0.0)));
                                                                                                    vec3 _4573 = vec3(dot(uPages_1._member0[_4547].xyz, _4560), dot(uPages_1._member0[_4550].xyz, _4560), dot(uPages_1._member0[_4553].xyz, _4560)) - uPages_1._member0[_4535].xyz;
                                                                                                    vec2 _4576 = vec2(uPages_1._member0[_4535].w, uPages_1._member0[_4538].w);
                                                                                                    bvec2 _6094 = isnan(_4576);
                                                                                                    bvec2 _6095 = isnan(vec2(9.9999999747524270787835121154785e-07));
                                                                                                    vec2 _6096 = max(_4576, vec2(9.9999999747524270787835121154785e-07));
                                                                                                    vec2 _6097 = vec2(_6094.x ? vec2(9.9999999747524270787835121154785e-07).x : _6096.x, _6094.y ? vec2(9.9999999747524270787835121154785e-07).y : _6096.y);
                                                                                                    vec2 _4583 = vec2(dot(_4573, uPages_1._member0[_4538].xyz), dot(_4573, uPages_1._member0[_4541].xyz)) / vec2(_6095.x ? _4576.x : _6097.x, _6095.y ? _4576.y : _6097.y);
                                                                                                    vec2 _4249 = _4583;
                                                                                                    float _4251 = -dot(_4573, uPages_1._member0[_4529 + 5].xyz);
                                                                                                    float _4252 = uPages_1._member0[_4541].w;
                                                                                                    vec3 _4253 = uPages_1._member0[_4529 + 5].xyz;
                                                                                                    if (abs(_4583.x) > 1.0)
                                                                                                    {
                                                                                                        _4257 = true;
                                                                                                    }
                                                                                                    else
                                                                                                    {
                                                                                                        _4257 = abs(_4249.y) > 1.0;
                                                                                                    }
                                                                                                    if (!(_4257))
                                                                                                    {
                                                                                                        if (false)
                                                                                                        {
                                                                                                            _4258 = dot(_4253, _4254) < (-0.0500000007450580596923828125);
                                                                                                        }
                                                                                                        else
                                                                                                        {
                                                                                                            _4258 = false;
                                                                                                        }
                                                                                                        if (!(_4258))
                                                                                                        {
                                                                                                            if (_4251 < (-0.25))
                                                                                                            {
                                                                                                                _4259 = true;
                                                                                                            }
                                                                                                            else
                                                                                                            {
                                                                                                                _4259 = _4251 > (_4252 + 0.25);
                                                                                                            }
                                                                                                            if (!(_4259))
                                                                                                            {
                                                                                                                vec2 _4413 = (_4256.xy + (((_4249 * 0.5) + vec2(0.5)) * _4256.zw)) / _4290;
                                                                                                                if (!(textureLod(_6006, _4413, 0.0).w < 0.5))
                                                                                                                {
                                                                                                                    float _4433 = abs((textureLod(_6010, _4413, 0.0).x * _4252) - _4251);
                                                                                                                    if (_4433 < _4117)
                                                                                                                    {
                                                                                                                        _4117 = _4433;
                                                                                                                        _4115 = _4413;
                                                                                                                        _4260 = _4433 < 0.0199999995529651641845703125;
                                                                                                                        _4261 = true;
                                                                                                                    }
                                                                                                                    else
                                                                                                                    {
                                                                                                                        _4260 = _4245;
                                                                                                                        _4261 = _4246;
                                                                                                                    }
                                                                                                                    _4245 = _4260;
                                                                                                                    _4246 = _4261;
                                                                                                                }
                                                                                                            }
                                                                                                        }
                                                                                                    }
                                                                                                }
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                    if (_4322_ladder_break)
                                                                                    {
                                                                                        break;
                                                                                    }
                                                                                    _4247++;
                                                                                    continue;
                                                                                }
                                                                                _4240 = _4245;
                                                                                _4241 = _4246;
                                                                                _4242++;
                                                                                continue;
                                                                            }
                                                                            _4237 = _4241;
                                                                        }
                                                                    }
                                                                    if (!_4237)
                                                                    {
                                                                        _4114 = vec4(1.0, 0.0, 0.0, 1.0);
                                                                    }
                                                                    else
                                                                    {
                                                                        uvec2 _4146 = uvec2(textureSize(_6004, 0));
                                                                        vec2 _4157 = abs(_4115 - cardUv) * vec2(float(_4146.x), float(_4146.y));
                                                                        float _4158 = _4157.x;
                                                                        float _4159 = _4157.y;
                                                                        vec4 _4120;
                                                                        if ((isnan(_4159) ? _4158 : (isnan(_4158) ? _4159 : max(_4158, _4159))) < 1.5)
                                                                        {
                                                                            _4120 = vec4(0.0, 1.0, 0.0, 1.0);
                                                                        }
                                                                        else
                                                                        {
                                                                            _4120 = vec4(1.0, 1.0, 0.0, 1.0);
                                                                        }
                                                                        _4114 = _4120;
                                                                    }
                                                                }
                                                            }
                                                            else
                                                            {
                                                                if (Globals.uProbe == 4)
                                                                {
                                                                    _4588 = false;
                                                                    vec4 _4589;
                                                                    {
                                                                        int _4608 = max((Globals.uShadowLevels - 1), 0);
                                                                        vec3 _4614 = world + ((_417 * Globals.uClipmapOrigin.data[0].w) * 1.5);
                                                                        float _4623 = (Globals.uClipmapOrigin.data[0].w * float(Globals.uShadowResolution)) * float(1 << (Globals.uShadowLevels - 1));
                                                                        int _4590 = 0;
                                                                        float _4591 = 0.0;
                                                                        bool _4592;
                                                                        bool _4593;
                                                                        float _4595;
                                                                        float _4681;
                                                                        bool _4683;
                                                                        for (;;)
                                                                        {
                                                                            if (_4590 < 64)
                                                                            {
                                                                                _4592 = _4591 < _4623;
                                                                            }
                                                                            else
                                                                            {
                                                                                _4592 = false;
                                                                            }
                                                                            if (!_4592)
                                                                            {
                                                                                break;
                                                                            }
                                                                            vec3 _4642 = _4614 + (Globals.uSunDirection * _4591);
                                                                            _4680 = false;
                                                                            {
                                                                                _4593 = false;
                                                                                _4595 = Globals.uClipmapOrigin.data[0].w;
                                                                                int _4682 = 0;
                                                                                for (;;)
                                                                                {
                                                                                    bool _4694_ladder_break = false;
                                                                                    {
                                                                                        if (!(_4682 < Globals.uShadowLevels))
                                                                                        {
                                                                                            _4694_ladder_break = true;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            vec3 _4709 = (_4642 - Globals.uClipmapOrigin.data[_4682].xyz) / vec3(Globals.uClipmapOrigin.data[_4682].w);
                                                                                            if (any(lessThan(_4709, vec3(0.5))))
                                                                                            {
                                                                                                _4683 = true;
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                _4683 = any(greaterThan(_4709, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                                            }
                                                                                            if (!(_4683))
                                                                                            {
                                                                                                _4593 = true;
                                                                                                _4595 = Globals.uClipmapOrigin.data[_4682].w;
                                                                                                _4680 = true;
                                                                                                _4681 = ((textureLod(_6012, vec3(_4709.x / float(Globals.uShadowResolution), _4709.y / float(Globals.uShadowResolution), ((float(_4682) * float(Globals.uShadowResolution)) + _4709.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_4682];
                                                                                                _4694_ladder_break = true;
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                    if (_4694_ladder_break)
                                                                                    {
                                                                                        break;
                                                                                    }
                                                                                    _4682++;
                                                                                    continue;
                                                                                }
                                                                                if (!(_4680))
                                                                                {
                                                                                    _4680 = true;
                                                                                    _4681 = 1000000.0;
                                                                                }
                                                                            }
                                                                            if (!_4593)
                                                                            {
                                                                                _4588 = true;
                                                                                _4589 = vec4(1.0, 0.0, _4591 / _4623, 1.0);
                                                                                break;
                                                                            }
                                                                            float _4781 = 2.0 * _4595;
                                                                            if (_4681 < ((0.5 * _4595) * clamp(_4591 / (isnan(9.9999999747524270787835121154785e-07) ? _4781 : (isnan(_4781) ? 9.9999999747524270787835121154785e-07 : max(_4781, 9.9999999747524270787835121154785e-07))), 0.0, 1.0)))
                                                                            {
                                                                                _4588 = true;
                                                                                _4589 = vec4(0.0, _4595 / Globals.uClipmapOrigin.data[_4608].w, _4591 / _4623, 1.0);
                                                                                break;
                                                                            }
                                                                            float _4662 = _4595 * 0.25;
                                                                            _4590++;
                                                                            _4591 += (isnan(_4662) ? _4681 : (isnan(_4681) ? _4662 : max(_4681, _4662)));
                                                                            continue;
                                                                        }
                                                                        if (!(_4588))
                                                                        {
                                                                            _4588 = true;
                                                                            _4589 = vec4(0.5, 0.0, clamp(_4591 / _4623, 0.0, 1.0), 1.0);
                                                                        }
                                                                    }
                                                                    _4114 = _4589;
                                                                }
                                                                else
                                                                {
                                                                    if (Globals.uProbe == 2)
                                                                    {
                                                                        _4114 = vec4(clamp((world - Globals.uProbeMin) * Globals.uProbeInvExtent, vec3(0.0), vec3(1.0)), 1.0);
                                                                    }
                                                                    else
                                                                    {
                                                                        if (Globals.uProbe == 3)
                                                                        {
                                                                            _4114 = vec4((_417 * 0.5) + vec3(0.5), 1.0);
                                                                        }
                                                                        else
                                                                        {
                                                                            vec3 _4199 = world + ((_417 * Globals.uClipmapOrigin.data[0].w) * 1.5);
                                                                            _4790 = false;
                                                                            bool _4121;
                                                                            float _4122;
                                                                            float _4791;
                                                                            {
                                                                                _4121 = false;
                                                                                _4122 = 0.0;
                                                                                int _4792 = 0;
                                                                                bool _4793;
                                                                                for (;;)
                                                                                {
                                                                                    bool _4804_ladder_break = false;
                                                                                    {
                                                                                        if (!(_4792 < Globals.uShadowLevels))
                                                                                        {
                                                                                            _4804_ladder_break = true;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            vec3 _4819 = (_4199 - Globals.uClipmapOrigin.data[_4792].xyz) / vec3(Globals.uClipmapOrigin.data[_4792].w);
                                                                                            if (any(lessThan(_4819, vec3(0.5))))
                                                                                            {
                                                                                                _4793 = true;
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                _4793 = any(greaterThan(_4819, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                                            }
                                                                                            if (!(_4793))
                                                                                            {
                                                                                                _4121 = true;
                                                                                                vec4 _4866 = textureLod(_6012, vec3(_4819.x / float(Globals.uShadowResolution), _4819.y / float(Globals.uShadowResolution), ((float(_4792) * float(Globals.uShadowResolution)) + _4819.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0);
                                                                                                float _4868 = _4866.x;
                                                                                                _4122 = _4868;
                                                                                                _4790 = true;
                                                                                                _4791 = ((_4868 * 2.0) - 1.0) * Globals.uClipmapRange.data[_4792];
                                                                                                _4804_ladder_break = true;
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                    if (_4804_ladder_break)
                                                                                    {
                                                                                        break;
                                                                                    }
                                                                                    _4792++;
                                                                                    continue;
                                                                                }
                                                                                if (!(_4790))
                                                                                {
                                                                                    _4790 = true;
                                                                                    _4791 = 1000000.0;
                                                                                }
                                                                            }
                                                                            float _4124;
                                                                            if (Globals.uShadowLevels > 0)
                                                                            {
                                                                                _4124 = clamp(Globals.uClipmapRange.data[0] / (Globals.uClipmapOrigin.data[0].w * 4.0), 0.0, 1.0);
                                                                            }
                                                                            else
                                                                            {
                                                                                _4124 = 0.0;
                                                                            }
                                                                            float _4125;
                                                                            if (_4121)
                                                                            {
                                                                                _4125 = clamp(_4791 / (Globals.uClipmapOrigin.data[0].w * 4.0), 0.0, 1.0);
                                                                            }
                                                                            else
                                                                            {
                                                                                _4125 = 1.0;
                                                                            }
                                                                            float _4126;
                                                                            if (_4121)
                                                                            {
                                                                                _4126 = 1.0;
                                                                            }
                                                                            else
                                                                            {
                                                                                _4126 = 0.5;
                                                                            }
                                                                            _4114 = vec4(_4124, _4122, _4125, _4126);
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        imageStore(uDirect, ivec2(uvec2(texelAt)), _4114);
                                                    }
                                                    else
                                                    {
                                                        float _2222 = dot(_417, Globals.uSunDirection);
                                                        float _2223 = isnan(0.0) ? _2222 : (isnan(_2222) ? 0.0 : max(_2222, 0.0));
                                                        if (_2223 > 0.0)
                                                        {
                                                            _4897 = false;
                                                            float _4898;
                                                            {
                                                                if (Globals.uShadowLevels <= 0)
                                                                {
                                                                    _4897 = true;
                                                                    _4898 = 1.0;
                                                                }
                                                                else
                                                                {
                                                                    vec3 _4921 = world + ((_417 * Globals.uClipmapOrigin.data[0].w) * 1.5);
                                                                    float _4932 = (Globals.uClipmapOrigin.data[0].w * float(Globals.uShadowResolution)) * float(1 << (Globals.uShadowLevels - 1));
                                                                    int _4899 = 0;
                                                                    float _4900 = 0.0;
                                                                    bool _4901;
                                                                    bool _4902;
                                                                    float _4904;
                                                                    float _4979;
                                                                    bool _4981;
                                                                    for (;;)
                                                                    {
                                                                        if (_4899 < 64)
                                                                        {
                                                                            _4901 = _4900 < _4932;
                                                                        }
                                                                        else
                                                                        {
                                                                            _4901 = false;
                                                                        }
                                                                        if (!_4901)
                                                                        {
                                                                            break;
                                                                        }
                                                                        vec3 _4949 = _4921 + (Globals.uSunDirection * _4900);
                                                                        _4978 = false;
                                                                        {
                                                                            _4902 = false;
                                                                            _4904 = Globals.uClipmapOrigin.data[0].w;
                                                                            int _4980 = 0;
                                                                            for (;;)
                                                                            {
                                                                                bool _4992_ladder_break = false;
                                                                                {
                                                                                    if (!(_4980 < Globals.uShadowLevels))
                                                                                    {
                                                                                        _4992_ladder_break = true;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        vec3 _5007 = (_4949 - Globals.uClipmapOrigin.data[_4980].xyz) / vec3(Globals.uClipmapOrigin.data[_4980].w);
                                                                                        if (any(lessThan(_5007, vec3(0.5))))
                                                                                        {
                                                                                            _4981 = true;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            _4981 = any(greaterThan(_5007, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                                        }
                                                                                        if (!(_4981))
                                                                                        {
                                                                                            _4902 = true;
                                                                                            _4904 = Globals.uClipmapOrigin.data[_4980].w;
                                                                                            _4978 = true;
                                                                                            _4979 = ((textureLod(_6012, vec3(_5007.x / float(Globals.uShadowResolution), _5007.y / float(Globals.uShadowResolution), ((float(_4980) * float(Globals.uShadowResolution)) + _5007.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_4980];
                                                                                            _4992_ladder_break = true;
                                                                                        }
                                                                                    }
                                                                                }
                                                                                if (_4992_ladder_break)
                                                                                {
                                                                                    break;
                                                                                }
                                                                                _4980++;
                                                                                continue;
                                                                            }
                                                                            if (!(_4978))
                                                                            {
                                                                                _4978 = true;
                                                                                _4979 = 1000000.0;
                                                                            }
                                                                        }
                                                                        if (!_4902)
                                                                        {
                                                                            _4897 = true;
                                                                            _4898 = 1.0;
                                                                            break;
                                                                        }
                                                                        float _5079 = 2.0 * _4904;
                                                                        if (_4979 < ((0.5 * _4904) * clamp(_4900 / (isnan(9.9999999747524270787835121154785e-07) ? _5079 : (isnan(_5079) ? 9.9999999747524270787835121154785e-07 : max(_5079, 9.9999999747524270787835121154785e-07))), 0.0, 1.0)))
                                                                        {
                                                                            _4897 = true;
                                                                            _4898 = 0.0;
                                                                            break;
                                                                        }
                                                                        float _4964 = _4904 * 0.25;
                                                                        _4899++;
                                                                        _4900 += (isnan(_4964) ? _4979 : (isnan(_4979) ? _4964 : max(_4979, _4964)));
                                                                        continue;
                                                                    }
                                                                    if (!(_4897))
                                                                    {
                                                                        _4897 = true;
                                                                        _4898 = 1.0;
                                                                    }
                                                                }
                                                            }
                                                            visibility = _4898;
                                                        }
                                                        else
                                                        {
                                                            visibility = 1.0;
                                                        }
                                                        vec3 _5089;
                                                        {
                                                            if (Globals.uShadowLevels <= 0)
                                                            {
                                                                vec3 _5170;
                                                                {
                                                                    if (Globals.uSkyShValid == 0)
                                                                    {
                                                                        _5170 = Globals.uSkyColour * ((_417.z * 0.5) + 0.5);
                                                                    }
                                                                    else
                                                                    {
                                                                        vec4 _5185 = vec4(_417, 1.0);
                                                                        vec4 _5188 = _5185.xyzz * _5185.yzzx;
                                                                        float _5214 = _417.x;
                                                                        float _5216 = _417.y;
                                                                        vec3 _5221 = (vec3(dot(Globals.uSkySh.data[0], _5185), dot(Globals.uSkySh.data[1], _5185), dot(Globals.uSkySh.data[2], _5185)) + vec3(dot(Globals.uSkySh.data[3], _5188), dot(Globals.uSkySh.data[4], _5188), dot(Globals.uSkySh.data[5], _5188))) + (Globals.uSkySh.data[6].xyz * ((_5214 * _5214) - (_5216 * _5216)));
                                                                        bvec3 _6129 = isnan(vec3(0.0));
                                                                        bvec3 _6130 = isnan(_5221);
                                                                        vec3 _6131 = max(vec3(0.0), _5221);
                                                                        vec3 _6132 = vec3(_6129.x ? _5221.x : _6131.x, _6129.y ? _5221.y : _6131.y, _6129.z ? _5221.z : _6131.z);
                                                                        _5170 = vec3(_6130.x ? vec3(0.0).x : _6132.x, _6130.y ? vec3(0.0).y : _6132.y, _6130.z ? vec3(0.0).z : _6132.z);
                                                                    }
                                                                }
                                                                _5089 = _5170 * 3.1415927410125732421875;
                                                            }
                                                            else
                                                            {
                                                                vec3 _5090;
                                                                if (abs(_417.z) < 0.89999997615814208984375)
                                                                {
                                                                    _5090 = vec3(0.0, 0.0, 1.0);
                                                                }
                                                                else
                                                                {
                                                                    _5090 = vec3(1.0, 0.0, 0.0);
                                                                }
                                                                vec3 _5111 = normalize(cross(_417, _5090));
                                                                vec3 _5112 = cross(_417, _5111);
                                                                vec3 _5114 = floor(world * 8.0);
                                                                float _5118 = fract(sin(dot(_5114, vec3(12.98980045318603515625, 78.233001708984375, 37.71900177001953125))) * 43758.546875);
                                                                float _5122 = fract(sin(dot(_5114, vec3(39.34600067138671875, 11.1350002288818359375, 83.154998779296875))) * 24634.634765625);
                                                                int _5092 = 0;
                                                                vec3 _5091 = vec3(0.0);
                                                                vec3 _5254;
                                                                float _5314;
                                                                bool _5317;
                                                                bool _5318;
                                                                float _5320;
                                                                float _5395;
                                                                bool _5397;
                                                                for (;;)
                                                                {
                                                                    if (!(_5092 < 8))
                                                                    {
                                                                        break;
                                                                    }
                                                                    float _5134 = (float(_5092) + _5122) * 0.125;
                                                                    uint _5227 = uint(_5092);
                                                                    uint _5230 = (_5227 << 16u) | (_5227 >> 16u);
                                                                    uint _5235 = ((_5230 & 1431655765u) << 1u) | ((_5230 & 2863311530u) >> 1u);
                                                                    uint _5240 = ((_5235 & 858993459u) << 2u) | ((_5235 & 3435973836u) >> 2u);
                                                                    uint _5245 = ((_5240 & 252645135u) << 4u) | ((_5240 & 4042322160u) >> 4u);
                                                                    float _5139 = sqrt(_5134);
                                                                    float _5140 = 6.283185482025146484375 * fract((float(((_5245 & 16711935u) << 8u) | ((_5245 & 4278255360u) >> 8u)) * 2.3283064365386962890625e-10) + _5118);
                                                                    float _5148 = 1.0 - _5134;
                                                                    vec3 _5153 = normalize(((_5111 * (_5139 * cos(_5140))) + (_5112 * (_5139 * sin(_5140)))) + (_417 * sqrt(isnan(_5148) ? 0.0 : (isnan(0.0) ? _5148 : max(0.0, _5148)))));
                                                                    {
                                                                        if (Globals.uSkyShValid == 0)
                                                                        {
                                                                            _5254 = Globals.uSkyColour * ((_5153.z * 0.5) + 0.5);
                                                                        }
                                                                        else
                                                                        {
                                                                            vec4 _5269 = vec4(_5153, 1.0);
                                                                            vec4 _5272 = _5269.xyzz * _5269.yzzx;
                                                                            float _5298 = _5153.x;
                                                                            float _5300 = _5153.y;
                                                                            vec3 _5305 = (vec3(dot(Globals.uSkySh.data[0], _5269), dot(Globals.uSkySh.data[1], _5269), dot(Globals.uSkySh.data[2], _5269)) + vec3(dot(Globals.uSkySh.data[3], _5272), dot(Globals.uSkySh.data[4], _5272), dot(Globals.uSkySh.data[5], _5272))) + (Globals.uSkySh.data[6].xyz * ((_5298 * _5298) - (_5300 * _5300)));
                                                                            bvec3 _6139 = isnan(vec3(0.0));
                                                                            bvec3 _6140 = isnan(_5305);
                                                                            vec3 _6141 = max(vec3(0.0), _5305);
                                                                            vec3 _6142 = vec3(_6139.x ? _5305.x : _6141.x, _6139.y ? _5305.y : _6141.y, _6139.z ? _5305.z : _6141.z);
                                                                            _5254 = vec3(_6140.x ? vec3(0.0).x : _6142.x, _6140.y ? vec3(0.0).y : _6142.y, _6140.z ? vec3(0.0).z : _6142.z);
                                                                        }
                                                                    }
                                                                    _5313 = false;
                                                                    {
                                                                        if (Globals.uShadowLevels <= 0)
                                                                        {
                                                                            _5313 = true;
                                                                            _5314 = 1.0;
                                                                        }
                                                                        else
                                                                        {
                                                                            vec3 _5337 = world + ((_417 * Globals.uClipmapOrigin.data[0].w) * 1.5);
                                                                            float _5348 = (Globals.uClipmapOrigin.data[0].w * float(Globals.uShadowResolution)) * float(1 << (Globals.uShadowLevels - 1));
                                                                            int _5315 = 0;
                                                                            float _5316 = 0.0;
                                                                            for (;;)
                                                                            {
                                                                                if (_5315 < 64)
                                                                                {
                                                                                    _5317 = _5316 < _5348;
                                                                                }
                                                                                else
                                                                                {
                                                                                    _5317 = false;
                                                                                }
                                                                                if (!_5317)
                                                                                {
                                                                                    break;
                                                                                }
                                                                                vec3 _5365 = _5337 + (_5153 * _5316);
                                                                                _5394 = false;
                                                                                {
                                                                                    _5318 = false;
                                                                                    _5320 = Globals.uClipmapOrigin.data[0].w;
                                                                                    int _5396 = 0;
                                                                                    for (;;)
                                                                                    {
                                                                                        bool _5408_ladder_break = false;
                                                                                        {
                                                                                            if (!(_5396 < Globals.uShadowLevels))
                                                                                            {
                                                                                                _5408_ladder_break = true;
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                vec3 _5423 = (_5365 - Globals.uClipmapOrigin.data[_5396].xyz) / vec3(Globals.uClipmapOrigin.data[_5396].w);
                                                                                                if (any(lessThan(_5423, vec3(0.5))))
                                                                                                {
                                                                                                    _5397 = true;
                                                                                                }
                                                                                                else
                                                                                                {
                                                                                                    _5397 = any(greaterThan(_5423, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                                                }
                                                                                                if (!(_5397))
                                                                                                {
                                                                                                    _5318 = true;
                                                                                                    _5320 = Globals.uClipmapOrigin.data[_5396].w;
                                                                                                    _5394 = true;
                                                                                                    _5395 = ((textureLod(_6012, vec3(_5423.x / float(Globals.uShadowResolution), _5423.y / float(Globals.uShadowResolution), ((float(_5396) * float(Globals.uShadowResolution)) + _5423.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_5396];
                                                                                                    _5408_ladder_break = true;
                                                                                                }
                                                                                            }
                                                                                        }
                                                                                        if (_5408_ladder_break)
                                                                                        {
                                                                                            break;
                                                                                        }
                                                                                        _5396++;
                                                                                        continue;
                                                                                    }
                                                                                    if (!(_5394))
                                                                                    {
                                                                                        _5394 = true;
                                                                                        _5395 = 1000000.0;
                                                                                    }
                                                                                }
                                                                                if (!_5318)
                                                                                {
                                                                                    _5313 = true;
                                                                                    _5314 = 1.0;
                                                                                    break;
                                                                                }
                                                                                float _5495 = 2.0 * _5320;
                                                                                if (_5395 < ((0.5 * _5320) * clamp(_5316 / (isnan(9.9999999747524270787835121154785e-07) ? _5495 : (isnan(_5495) ? 9.9999999747524270787835121154785e-07 : max(_5495, 9.9999999747524270787835121154785e-07))), 0.0, 1.0)))
                                                                                {
                                                                                    _5313 = true;
                                                                                    _5314 = 0.0;
                                                                                    break;
                                                                                }
                                                                                float _5380 = _5320 * 0.25;
                                                                                _5315++;
                                                                                _5316 += (isnan(_5380) ? _5395 : (isnan(_5395) ? _5380 : max(_5395, _5380)));
                                                                                continue;
                                                                            }
                                                                            if (!(_5313))
                                                                            {
                                                                                _5313 = true;
                                                                                _5314 = 1.0;
                                                                            }
                                                                        }
                                                                    }
                                                                    _5092++;
                                                                    _5091 += (_5254 * _5314);
                                                                    continue;
                                                                }
                                                                _5089 = _5091 * 0.3926990926265716552734375;
                                                            }
                                                        }
                                                        light = 0;
                                                        lit = ((Globals.uSunColour * _2223) * visibility) + _5089;
                                                        float aim;
                                                        float reaches;
                                                        float _5505;
                                                        float _5756;
                                                        bool _5759;
                                                        bool _5760;
                                                        float _5762;
                                                        float _5832;
                                                        bool _5834;
                                                        for (;;)
                                                        {
                                                            bool _151_ladder_break = false;
                                                            {
                                                                if (!(light < Globals.uLightCount))
                                                                {
                                                                    _151_ladder_break = true;
                                                                }
                                                                else
                                                                {
                                                                    int _2434 = light * 3;
                                                                    int _2437 = _2434 + 1;
                                                                    int _2440 = _2434 + 2;
                                                                    vec3 delta = uLights_1._member0[_2434].xyz - world;
                                                                    float _2445 = dot(delta, delta);
                                                                    float _2447 = uLights_1._member0[_2434].w * 3.0;
                                                                    float _2449 = isnan(2.0) ? _2447 : (isnan(_2447) ? 2.0 : max(_2447, 2.0));
                                                                    float reachSquared = _2449 * _2449;
                                                                    if (!(_2445 >= reachSquared))
                                                                    {
                                                                        vec3 toLight = delta * inversesqrt(isnan(9.9999999747524270787835121154785e-07) ? _2445 : (isnan(_2445) ? 9.9999999747524270787835121154785e-07 : max(_2445, 9.9999999747524270787835121154785e-07)));
                                                                        float _2457 = dot(_417, toLight);
                                                                        float _2458 = isnan(0.0) ? _2457 : (isnan(_2457) ? 0.0 : max(_2457, 0.0));
                                                                        if (!(_2458 <= 0.0))
                                                                        {
                                                                            float _2468 = clamp(1.0 - ((_2445 * _2445) / (reachSquared * reachSquared)), 0.0, 1.0);
                                                                            if (dot(uLights_1._member0[_2440].xyz, uLights_1._member0[_2440].xyz) > 0.25)
                                                                            {
                                                                                float _2475 = dot(normalize(uLights_1._member0[_2440].xyz), -toLight);
                                                                                aim = isnan(0.0) ? _2475 : (isnan(_2475) ? 0.0 : max(_2475, 0.0));
                                                                            }
                                                                            else
                                                                            {
                                                                                aim = 1.0;
                                                                            }
                                                                            float contribution = (((((uLights_1._member0[_2437].w * Globals.uLocalScale) * _2458) * (1.0 / (_2445 + 1.0))) * _2468) * _2468) * aim;
                                                                            if (!((contribution * dot(uLights_1._member0[_2437].xyz, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875))) < 9.9999997473787516355514526367188e-06))
                                                                            {
                                                                                int _2504 = floatBitsToInt(uLights_1._member0[_2440].w);
                                                                                {
                                                                                    if (_2504 < 0)
                                                                                    {
                                                                                        _5505 = -1.0;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        uint _5506 = uvec3(textureSize(_6022, 0)).x;
                                                                                        float _5509 = 0.25;
                                                                                        int _5510 = 0;
                                                                                        for (;;)
                                                                                        {
                                                                                            if (!(_5510 < 6))
                                                                                            {
                                                                                                break;
                                                                                            }
                                                                                            int _5543 = ((_2504 + _5510) * 5) + 3;
                                                                                            float _5549 = dot(uLampMapRecords_1._member0[_5543].xyz, world) + uLampMapRecords_1._member0[_5543].w;
                                                                                            _5509 = isnan(_5549) ? _5509 : (isnan(_5509) ? _5549 : max(_5509, _5549));
                                                                                            _5510++;
                                                                                            continue;
                                                                                        }
                                                                                        vec3 _5567 = world + (_417 * (0.0500000007450580596923828125 + (1.5 * ((_5509 * 2.0) / float(max(_5506, 1u))))));
                                                                                        float _5511 = -1000000015047466219876688855040.0;
                                                                                        int _5512 = _2504;
                                                                                        _5510 = 0;
                                                                                        for (;;)
                                                                                        {
                                                                                            if (!(_5510 < 6))
                                                                                            {
                                                                                                break;
                                                                                            }
                                                                                            int _5577 = _2504 + _5510;
                                                                                            int _5579 = (_5577 * 5) + 3;
                                                                                            float _5585 = dot(uLampMapRecords_1._member0[_5579].xyz, _5567) + uLampMapRecords_1._member0[_5579].w;
                                                                                            if (_5585 > _5511)
                                                                                            {
                                                                                                _5511 = _5585;
                                                                                                _5512 = _5577;
                                                                                            }
                                                                                            _5510++;
                                                                                            continue;
                                                                                        }
                                                                                        int _5597 = _5512 * 5;
                                                                                        int _5598 = _5597 + 4;
                                                                                        if (uLampMapRecords_1._member0[_5598].z <= 0.0)
                                                                                        {
                                                                                            _5505 = -1.0;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            int _5607 = _5597 + 1;
                                                                                            if (_5511 <= (uLampMapRecords_1._member0[_5598].y / ((-1.0) - uLampMapRecords_1._member0[_5598].x)))
                                                                                            {
                                                                                                _5505 = 1.0;
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                vec2 _5629 = vec2(dot(uLampMapRecords_1._member0[_5597].xyz, _5567) + uLampMapRecords_1._member0[_5597].w, dot(uLampMapRecords_1._member0[_5607].xyz, _5567) + uLampMapRecords_1._member0[_5607].w) / vec2(_5511);
                                                                                                uvec3 _5638 = uvec3(textureSize(_6022, 0));
                                                                                                uint _5639 = _5638.x;
                                                                                                ivec2 _5646 = ivec2(int(_5639), int(_5638.y));
                                                                                                float _5647 = length(uLampMapRecords_1._member0[_5597].xyz);
                                                                                                float _5660 = (0.0500000007450580596923828125 + (0.004999999888241291046142578125 * _5511)) + (2.0 * ((_5511 * (2.0 / (isnan(0.001000000047497451305389404296875) ? _5647 : (isnan(_5647) ? 0.001000000047497451305389404296875 : max(_5647, 0.001000000047497451305389404296875))))) / float(max(_5639, 1u))));
                                                                                                vec2 _5664 = (vec2((_5629.x * 0.5) + 0.5, 0.5 - (_5629.y * 0.5)) * vec2(_5646)) - vec2(0.5);
                                                                                                vec2 _5665 = floor(_5664);
                                                                                                ivec2 _5668 = ivec2(_5665) - ivec2(1);
                                                                                                vec2 _5669 = _5664 - _5665;
                                                                                                int _5518 = 0;
                                                                                                float _5516 = 0.0;
                                                                                                float _5517 = 0.0;
                                                                                                for (;;)
                                                                                                {
                                                                                                    if (!(_5518 < 4))
                                                                                                    {
                                                                                                        break;
                                                                                                    }
                                                                                                    int _5520 = 0;
                                                                                                    float _5519 = _5517;
                                                                                                    for (;;)
                                                                                                    {
                                                                                                        if (!(_5520 < 4))
                                                                                                        {
                                                                                                            break;
                                                                                                        }
                                                                                                        int _5688 = _5520;
                                                                                                        float _5702 = ((texelFetch(_6022, ivec4(clamp(_5668 + ivec2(_5688, _5518), ivec2(0), _5646 - ivec2(1)), _5512, 0).xyz, 0).x * 2.0) - 1.0) - uLampMapRecords_1._member0[_5598].x;
                                                                                                        vec2 _5754 = clamp(vec2(1.0) - (abs(vec2(float(_5688) - 1.0, float(_5518) - 1.0) - _5669) * vec2(0.5)), vec2(0.0), vec2(1.0));
                                                                                                        float _5721 = _5754.x * _5754.y;
                                                                                                        if ((uLampMapRecords_1._member0[_5598].y / (isnan(-9.9999999747524270787835121154785e-07) ? _5702 : (isnan(_5702) ? (-9.9999999747524270787835121154785e-07) : min(_5702, -9.9999999747524270787835121154785e-07)))) >= (_5511 - _5660))
                                                                                                        {
                                                                                                            _5509 = _5721;
                                                                                                        }
                                                                                                        else
                                                                                                        {
                                                                                                            _5509 = 0.0;
                                                                                                        }
                                                                                                        _5520++;
                                                                                                        _5516 += _5509;
                                                                                                        _5519 += _5721;
                                                                                                        continue;
                                                                                                    }
                                                                                                    _5518++;
                                                                                                    _5517 = _5519;
                                                                                                    continue;
                                                                                                }
                                                                                                _5505 = _5516 / (isnan(9.9999997473787516355514526367188e-05) ? _5517 : (isnan(_5517) ? 9.9999997473787516355514526367188e-05 : max(_5517, 9.9999997473787516355514526367188e-05)));
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                                if (_5505 < 0.0)
                                                                                {
                                                                                    _5755 = false;
                                                                                    {
                                                                                        if (Globals.uShadowLevels <= 0)
                                                                                        {
                                                                                            _5755 = true;
                                                                                            _5756 = 1.0;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            vec3 _5779 = world + ((_417 * Globals.uClipmapOrigin.data[0].w) * 1.5);
                                                                                            vec3 _5780 = uLights_1._member0[_2434].xyz - _5779;
                                                                                            float _5781 = length(_5780);
                                                                                            float _5783 = _5781 - (isnan(Globals.uClipmapOrigin.data[0].w) ? 0.119999997317790985107421875 : (isnan(0.119999997317790985107421875) ? Globals.uClipmapOrigin.data[0].w : max(0.119999997317790985107421875, Globals.uClipmapOrigin.data[0].w)));
                                                                                            if (_5783 <= 0.0)
                                                                                            {
                                                                                                _5755 = true;
                                                                                                _5756 = 1.0;
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                vec3 _5788 = _5780 / vec3(_5781);
                                                                                                int _5757 = 0;
                                                                                                float _5758 = 0.0;
                                                                                                for (;;)
                                                                                                {
                                                                                                    if (_5757 < 48)
                                                                                                    {
                                                                                                        _5759 = _5758 < _5783;
                                                                                                    }
                                                                                                    else
                                                                                                    {
                                                                                                        _5759 = false;
                                                                                                    }
                                                                                                    if (!_5759)
                                                                                                    {
                                                                                                        break;
                                                                                                    }
                                                                                                    vec3 _5805 = _5779 + (_5788 * _5758);
                                                                                                    _5831 = false;
                                                                                                    {
                                                                                                        _5760 = false;
                                                                                                        _5762 = Globals.uClipmapOrigin.data[0].w;
                                                                                                        int _5833 = 0;
                                                                                                        for (;;)
                                                                                                        {
                                                                                                            bool _5845_ladder_break = false;
                                                                                                            {
                                                                                                                if (!(_5833 < Globals.uShadowLevels))
                                                                                                                {
                                                                                                                    _5845_ladder_break = true;
                                                                                                                }
                                                                                                                else
                                                                                                                {
                                                                                                                    vec3 _5860 = (_5805 - Globals.uClipmapOrigin.data[_5833].xyz) / vec3(Globals.uClipmapOrigin.data[_5833].w);
                                                                                                                    if (any(lessThan(_5860, vec3(0.5))))
                                                                                                                    {
                                                                                                                        _5834 = true;
                                                                                                                    }
                                                                                                                    else
                                                                                                                    {
                                                                                                                        _5834 = any(greaterThan(_5860, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                                                                    }
                                                                                                                    if (!(_5834))
                                                                                                                    {
                                                                                                                        _5760 = true;
                                                                                                                        _5762 = Globals.uClipmapOrigin.data[_5833].w;
                                                                                                                        _5831 = true;
                                                                                                                        _5832 = ((textureLod(_6012, vec3(_5860.x / float(Globals.uShadowResolution), _5860.y / float(Globals.uShadowResolution), ((float(_5833) * float(Globals.uShadowResolution)) + _5860.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_5833];
                                                                                                                        _5845_ladder_break = true;
                                                                                                                    }
                                                                                                                }
                                                                                                            }
                                                                                                            if (_5845_ladder_break)
                                                                                                            {
                                                                                                                break;
                                                                                                            }
                                                                                                            _5833++;
                                                                                                            continue;
                                                                                                        }
                                                                                                        if (!(_5831))
                                                                                                        {
                                                                                                            _5831 = true;
                                                                                                            _5832 = 1000000.0;
                                                                                                        }
                                                                                                    }
                                                                                                    if (!_5760)
                                                                                                    {
                                                                                                        _5755 = true;
                                                                                                        _5756 = 1.0;
                                                                                                        break;
                                                                                                    }
                                                                                                    float _5932 = 2.0 * _5762;
                                                                                                    if (_5832 < ((0.5 * _5762) * clamp(_5758 / (isnan(9.9999999747524270787835121154785e-07) ? _5932 : (isnan(_5932) ? 9.9999999747524270787835121154785e-07 : max(_5932, 9.9999999747524270787835121154785e-07))), 0.0, 1.0)))
                                                                                                    {
                                                                                                        _5755 = true;
                                                                                                        _5756 = 0.0;
                                                                                                        break;
                                                                                                    }
                                                                                                    float _5817 = _5762 * 0.25;
                                                                                                    _5757++;
                                                                                                    _5758 += (isnan(_5817) ? _5832 : (isnan(_5832) ? _5817 : max(_5832, _5817)));
                                                                                                    continue;
                                                                                                }
                                                                                                if (!(_5755))
                                                                                                {
                                                                                                    _5755 = true;
                                                                                                    _5756 = 1.0;
                                                                                                }
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                    reaches = _5756;
                                                                                }
                                                                                else
                                                                                {
                                                                                    reaches = _5505;
                                                                                }
                                                                                if (!(reaches <= 0.0))
                                                                                {
                                                                                    lit += (uLights_1._member0[_2437].xyz * (contribution * reaches));
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                            if (_151_ladder_break)
                                                            {
                                                                break;
                                                            }
                                                            light++;
                                                            continue;
                                                        }
                                                        imageStore(uDirect, ivec2(uvec2(texelAt)), vec4(lit, 1.0));
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        else
                        {
                            int _267 = at + 1;
                            int _272 = int(uPages_1._member0[at].z);
                            bool _80;
                            if (within.x >= _272)
                            {
                                _80 = true;
                            }
                            else
                            {
                                _80 = within.y >= int(uPages_1._member0[at].w);
                            }
                            if (!(_80))
                            {
                                int _287 = at + 2;
                                int _291 = at + 3;
                                int _295 = at + 4;
                                int _300 = at + 6;
                                int _304 = at + 7;
                                int _307 = at + 8;
                                vec2 uv = (vec2(within) + vec2(0.5)) / vec2(uPages_1._member0[at].zw);
                                uvec2 _vecSize = uvec2(textureSize(_6004, 0));
                                vec2 cardUv = (uPages_1._member0[_267].xy + (uv * uPages_1._member0[_267].zw)) / vec2(float(_vecSize.x), float(_vecSize.y));
                                vec4 _sampled = textureLod(_6006, cardUv, 0.0);
                                ivec2 pageAt = ivec2(int(uPages_1._member0[at].x), int(uPages_1._member0[at].y));
                                if (_sampled.w < 0.5)
                                {
                                    imageStore(uDirect, ivec2(uvec2(pageAt + within)), vec4(0.0));
                                }
                                else
                                {
                                    vec3 _363 = normalize((textureLod(_6008, cardUv, 0.0).xyz * 2.0) - vec3(1.0));
                                    vec3 local = ((uPages_1._member0[_287].xyz + ((uPages_1._member0[_291].xyz * ((uv.x * 2.0) - 1.0)) * uPages_1._member0[_287].w)) + ((uPages_1._member0[_295].xyz * ((uv.y * 2.0) - 1.0)) * uPages_1._member0[_291].w)) - (uPages_1._member0[_230].xyz * (textureLod(_6010, cardUv, 0.0).x * uPages_1._member0[_295].w));
                                    vec3 _395 = vec3(uPages_1._member0[_300].x, uPages_1._member0[_304].x, uPages_1._member0[_307].x);
                                    vec3 _400 = vec3(uPages_1._member0[_300].y, uPages_1._member0[_304].y, uPages_1._member0[_307].y);
                                    vec3 _405 = vec3(uPages_1._member0[_300].z, uPages_1._member0[_304].z, uPages_1._member0[_307].z);
                                    vec3 world = vec3(dot(_395, local), dot(_400, local), dot(_405, local)) + vec3(uPages_1._member0[_300].w, uPages_1._member0[_304].w, uPages_1._member0[_307].w);
                                    vec3 _417 = normalize(vec3(dot(_395, _363), dot(_400, _363), dot(_405, _363)));
                                    ivec2 texelAt = pageAt + within;
                                    float visibility;
                                    if (Globals.uMode == 1)
                                    {
                                        if (((texelAt.x | texelAt.y) & 3) != 0)
                                        {
                                            imageStore(uDirect, ivec2(uvec2(texelAt)), vec4(0.0));
                                        }
                                        else
                                        {
                                            ivec2 probeCoord = texelAt >> ivec2(2);
                                            uProbePos._member0[(probeCoord.y * Globals.uProbeWidth) + probeCoord.x] = vec4(world, 1.0);
                                            vec2 _3036;
                                            {
                                                if (Globals.uTemporalIndex <= 0)
                                                {
                                                    _3036 = vec2(0.5);
                                                }
                                                else
                                                {
                                                    float _3051 = float(((uint(probeCoord.x) * 73856093u) ^ (uint(probeCoord.y) * 19349663u)) & 65535u);
                                                    int _3057 = (Globals.uTemporalIndex / max(Globals.uJitterStride, 1)) & 65535;
                                                    uint _3072 = uint(_3057);
                                                    uint _3075 = (_3072 << 16u) | (_3072 >> 16u);
                                                    uint _3080 = ((_3075 & 1431655765u) << 1u) | ((_3075 & 2863311530u) >> 1u);
                                                    uint _3085 = ((_3080 & 858993459u) << 2u) | ((_3080 & 3435973836u) >> 2u);
                                                    uint _3090 = ((_3085 & 252645135u) << 4u) | ((_3085 & 4042322160u) >> 4u);
                                                    _3036 = fract(vec2(fract(float(_3057) * 0.61803400516510009765625), float(((_3090 & 16711935u) << 8u) | ((_3090 & 4278255360u) >> 8u)) * 2.3283064365386962890625e-10) + vec2(_3051 * 1.52587890625e-05, fract(_3051 * 2.4689239580766297876834869384766e-05)));
                                                }
                                            }
                                            vec3 _3099;
                                            {
                                                bool _3100;
                                                if (Globals.uShadowLevels <= 0)
                                                {
                                                    _3100 = true;
                                                }
                                                else
                                                {
                                                    _3100 = Globals.uLookupBuckets <= 0;
                                                }
                                                if (_3100)
                                                {
                                                    _3099 = vec3(0.0);
                                                }
                                                else
                                                {
                                                    vec3 _5941;
                                                    vec3 _5942;
                                                    vec3 _5943;
                                                    {
                                                        vec3 _5956 = _417;
                                                        float _3228 = _417.z;
                                                        if (_3228 < (-0.99999988079071044921875))
                                                        {
                                                            _5941 = vec3(0.0, -1.0, 0.0);
                                                            _5942 = vec3(-1.0, 0.0, 0.0);
                                                            _5943 = _5956;
                                                        }
                                                        else
                                                        {
                                                            float _3236 = 1.0 / (1.0 + _3228);
                                                            float _3237 = _417.x;
                                                            float _3238 = -_3237;
                                                            float _3239 = _417.y;
                                                            float _3241 = (_3238 * _3239) * _3236;
                                                            _5941 = vec3(1.0 - ((_3237 * _3237) * _3236), _3241, _3238);
                                                            _5942 = vec3(_3241, 1.0 - ((_3239 * _3239) * _3236), -_3239);
                                                            _5943 = _5956;
                                                        }
                                                    }
                                                    int _3101 = 0;
                                                    vec4 _3102 = vec4(0.0);
                                                    vec4 _3103 = vec4(0.0);
                                                    vec4 _3104 = vec4(0.0);
                                                    vec3 _3106;
                                                    vec3 _3107;
                                                    vec2 _3109;
                                                    float _3273;
                                                    bool _3276;
                                                    bool _3277;
                                                    float _3279;
                                                    float _3354;
                                                    bool _3356;
                                                    bool _3468;
                                                    bool _3474;
                                                    ivec2 _3475;
                                                    bool _3479;
                                                    bool _3488;
                                                    bool _3489;
                                                    bool _3490;
                                                    bool _3491;
                                                    bool _3492;
                                                    ivec2 _3722;
                                                    for (;;)
                                                    {
                                                        if (!(_3101 < 16))
                                                        {
                                                            break;
                                                        }
                                                        int _3140 = _3101;
                                                        vec2 _3149 = (vec2(float(_3140 - 4 * (_3140 / 4)), float(_3140 / 4)) + _3036) * vec2(0.25);
                                                        float _3151 = 6.283185482025146484375 * _3149.x;
                                                        float _3152 = _3149.y;
                                                        float _3154 = 1.0 - (_3152 * _3152);
                                                        float _3156 = sqrt(isnan(_3154) ? 0.0 : (isnan(0.0) ? _3154 : max(0.0, _3154)));
                                                        vec3 _3271 = ((_5941 * (_3156 * cos(_3151))) + (_5942 * (_3156 * sin(_3151)))) + (_5943 * _3152);
                                                        _3272 = false;
                                                        {
                                                            _3106 = world;
                                                            if (Globals.uShadowLevels <= 0)
                                                            {
                                                                _3272 = true;
                                                                _3273 = 1.0;
                                                            }
                                                            else
                                                            {
                                                                vec3 _3296 = world + ((_417 * Globals.uClipmapOrigin.data[0].w) * 1.5);
                                                                float _3307 = (Globals.uClipmapOrigin.data[0].w * float(Globals.uShadowResolution)) * float(1 << (Globals.uShadowLevels - 1));
                                                                int _3274 = 0;
                                                                float _3275 = 0.0;
                                                                for (;;)
                                                                {
                                                                    if (_3274 < 64)
                                                                    {
                                                                        _3276 = _3275 < _3307;
                                                                    }
                                                                    else
                                                                    {
                                                                        _3276 = false;
                                                                    }
                                                                    if (!_3276)
                                                                    {
                                                                        break;
                                                                    }
                                                                    vec3 _3324 = _3296 + (_3271 * _3275);
                                                                    _3353 = false;
                                                                    {
                                                                        _3277 = false;
                                                                        _3279 = Globals.uClipmapOrigin.data[0].w;
                                                                        int _3355 = 0;
                                                                        for (;;)
                                                                        {
                                                                            bool _3367_ladder_break = false;
                                                                            {
                                                                                if (!(_3355 < Globals.uShadowLevels))
                                                                                {
                                                                                    _3367_ladder_break = true;
                                                                                }
                                                                                else
                                                                                {
                                                                                    vec3 _3382 = (_3324 - Globals.uClipmapOrigin.data[_3355].xyz) / vec3(Globals.uClipmapOrigin.data[_3355].w);
                                                                                    if (any(lessThan(_3382, vec3(0.5))))
                                                                                    {
                                                                                        _3356 = true;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        _3356 = any(greaterThan(_3382, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                                    }
                                                                                    if (!(_3356))
                                                                                    {
                                                                                        _3277 = true;
                                                                                        _3279 = Globals.uClipmapOrigin.data[_3355].w;
                                                                                        _3353 = true;
                                                                                        _3354 = ((textureLod(_6012, vec3(_3382.x / float(Globals.uShadowResolution), _3382.y / float(Globals.uShadowResolution), ((float(_3355) * float(Globals.uShadowResolution)) + _3382.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_3355];
                                                                                        _3367_ladder_break = true;
                                                                                    }
                                                                                }
                                                                            }
                                                                            if (_3367_ladder_break)
                                                                            {
                                                                                break;
                                                                            }
                                                                            _3355++;
                                                                            continue;
                                                                        }
                                                                        if (!(_3353))
                                                                        {
                                                                            _3353 = true;
                                                                            _3354 = 1000000.0;
                                                                        }
                                                                    }
                                                                    if (!_3277)
                                                                    {
                                                                        _3272 = true;
                                                                        _3273 = 1.0;
                                                                        break;
                                                                    }
                                                                    float _3454 = 2.0 * _3279;
                                                                    float _3458 = (0.5 * _3279) * clamp(_3275 / (isnan(9.9999999747524270787835121154785e-07) ? _3454 : (isnan(_3454) ? 9.9999999747524270787835121154785e-07 : max(_3454, 9.9999999747524270787835121154785e-07))), 0.0, 1.0);
                                                                    float _3460 = (_3275 + _3354) - _3458;
                                                                    float _3280 = isnan(0.0) ? _3460 : (isnan(_3460) ? 0.0 : max(_3460, 0.0));
                                                                    if (_3354 < _3458)
                                                                    {
                                                                        _3106 = _3296 + (_3271 * _3280);
                                                                        _3272 = true;
                                                                        _3273 = 0.0;
                                                                        break;
                                                                    }
                                                                    float _3339 = _3279 * 0.25;
                                                                    _3274++;
                                                                    _3275 += (isnan(_3339) ? _3354 : (isnan(_3354) ? _3339 : max(_3354, _3339)));
                                                                    continue;
                                                                }
                                                                if (!(_3272))
                                                                {
                                                                    _3272 = true;
                                                                    _3273 = 1.0;
                                                                }
                                                            }
                                                        }
                                                        if (_3273 <= 0.5)
                                                        {
                                                            {
                                                                _3109 = vec2(0.0);
                                                                float _3110 = 1000000000.0;
                                                                if (Globals.uLookupBuckets <= 0)
                                                                {
                                                                    _3468 = false;
                                                                }
                                                                else
                                                                {
                                                                    ivec3 _3509 = ivec3(floor((_3106 - Globals.uLookupMin) / vec3(Globals.uLookupCell)));
                                                                    int _3721 = int((((uint(_3509.x) * 2376512323u) ^ (uint(_3509.y) * 3625334849u)) ^ (uint(_3509.z) * 3407524639u)) & uint(Globals.uLookupBuckets - 1));
                                                                    uvec2 _3514 = uvec2(textureSize(_6004, 0));
                                                                    vec2 _3521 = vec2(float(_3514.x), float(_3514.y));
                                                                    bool _3471 = false;
                                                                    bool _3472 = false;
                                                                    int _3473 = 0;
                                                                    for (;;)
                                                                    {
                                                                        if (_3473 <= uCells_1._member0[Globals.uLookupBuckets].y)
                                                                        {
                                                                            _3474 = !_3471;
                                                                        }
                                                                        else
                                                                        {
                                                                            _3474 = false;
                                                                        }
                                                                        if (!_3474)
                                                                        {
                                                                            break;
                                                                        }
                                                                        bool _3541 = _3473 == 0;
                                                                        if (_3541)
                                                                        {
                                                                            _3475 = uCells_1._member0[_3721];
                                                                        }
                                                                        else
                                                                        {
                                                                            int _3726 = uCells_1._member0[Globals.uLookupBuckets].x + ((_3473 - 1) * 6);
                                                                            float _3742 = intBitsToFloat(uCellPages_1._member0[_3726 + 3]);
                                                                            vec3 _3744 = _3106 - vec3(intBitsToFloat(uCellPages_1._member0[_3726]), intBitsToFloat(uCellPages_1._member0[_3726 + 1]), intBitsToFloat(uCellPages_1._member0[_3726 + 2]));
                                                                            if (dot(_3744, _3744) > (_3742 * _3742))
                                                                            {
                                                                                _3722 = ivec2(0);
                                                                            }
                                                                            else
                                                                            {
                                                                                _3722 = ivec2(uCellPages_1._member0[_3726 + 4], uCellPages_1._member0[_3726 + 5]);
                                                                            }
                                                                            _3475 = _3722;
                                                                        }
                                                                        bool _3476 = _3471;
                                                                        bool _3477 = _3472;
                                                                        int _3478 = 0;
                                                                        for (;;)
                                                                        {
                                                                            bool _3553_ladder_break = false;
                                                                            {
                                                                                if (_3478 < _3475.y)
                                                                                {
                                                                                    _3479 = !_3476;
                                                                                }
                                                                                else
                                                                                {
                                                                                    _3479 = false;
                                                                                }
                                                                                if (!_3479)
                                                                                {
                                                                                    _3553_ladder_break = true;
                                                                                }
                                                                                else
                                                                                {
                                                                                    int _3570 = _3475.x + _3478;
                                                                                    int _3573 = uCellPages_1._member0[_3570] * 10;
                                                                                    if (!((uPages_1._member0[_3573 + 5].w > 0.5) == _3541))
                                                                                    {
                                                                                        int _3582 = _3573 + 9;
                                                                                        vec3 _3586 = _3106 - uPages_1._member0[_3582].xyz;
                                                                                        if (!(dot(_3586, _3586) > (uPages_1._member0[_3582].w * uPages_1._member0[_3582].w)))
                                                                                        {
                                                                                            vec3 _3593 = -_3271;
                                                                                            int _3760 = uCellPages_1._member0[_3570] * 10;
                                                                                            vec4 _3486 = uPages_1._member0[_3760];
                                                                                            vec4 _3487 = uPages_1._member0[_3760 + 1];
                                                                                            int _3766 = _3760 + 2;
                                                                                            int _3769 = _3760 + 3;
                                                                                            int _3772 = _3760 + 4;
                                                                                            int _3778 = _3760 + 6;
                                                                                            int _3781 = _3760 + 7;
                                                                                            int _3784 = _3760 + 8;
                                                                                            vec3 _3791 = _3106 - vec3(uPages_1._member0[_3778].w, uPages_1._member0[_3781].w, uPages_1._member0[_3784].w);
                                                                                            vec3 _3485 = vec3(dot(uPages_1._member0[_3778].xyz, _3593), dot(uPages_1._member0[_3781].xyz, _3593), dot(uPages_1._member0[_3784].xyz, _3593));
                                                                                            vec3 _3804 = vec3(dot(uPages_1._member0[_3778].xyz, _3791), dot(uPages_1._member0[_3781].xyz, _3791), dot(uPages_1._member0[_3784].xyz, _3791)) - uPages_1._member0[_3766].xyz;
                                                                                            vec2 _3807 = vec2(uPages_1._member0[_3766].w, uPages_1._member0[_3769].w);
                                                                                            bvec2 _6044 = isnan(_3807);
                                                                                            bvec2 _6045 = isnan(vec2(9.9999999747524270787835121154785e-07));
                                                                                            vec2 _6046 = max(_3807, vec2(9.9999999747524270787835121154785e-07));
                                                                                            vec2 _6047 = vec2(_6044.x ? vec2(9.9999999747524270787835121154785e-07).x : _6046.x, _6044.y ? vec2(9.9999999747524270787835121154785e-07).y : _6046.y);
                                                                                            vec2 _3814 = vec2(dot(_3804, uPages_1._member0[_3769].xyz), dot(_3804, uPages_1._member0[_3772].xyz)) / vec2(_6045.x ? _3807.x : _6047.x, _6045.y ? _3807.y : _6047.y);
                                                                                            vec2 _3480 = _3814;
                                                                                            float _3482 = -dot(_3804, uPages_1._member0[_3760 + 5].xyz);
                                                                                            float _3483 = uPages_1._member0[_3772].w;
                                                                                            vec3 _3484 = uPages_1._member0[_3760 + 5].xyz;
                                                                                            if (abs(_3814.x) > 1.0)
                                                                                            {
                                                                                                _3488 = true;
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                _3488 = abs(_3480.y) > 1.0;
                                                                                            }
                                                                                            if (!(_3488))
                                                                                            {
                                                                                                if (dot(_3271, _3271) > 0.5)
                                                                                                {
                                                                                                    _3489 = dot(_3484, _3485) < (-0.0500000007450580596923828125);
                                                                                                }
                                                                                                else
                                                                                                {
                                                                                                    _3489 = false;
                                                                                                }
                                                                                                if (!(_3489))
                                                                                                {
                                                                                                    if (_3482 < (-0.25))
                                                                                                    {
                                                                                                        _3490 = true;
                                                                                                    }
                                                                                                    else
                                                                                                    {
                                                                                                        _3490 = _3482 > (_3483 + 0.25);
                                                                                                    }
                                                                                                    if (!(_3490))
                                                                                                    {
                                                                                                        vec2 _3637 = (_3480 * 0.5) + vec2(0.5);
                                                                                                        vec2 _3644 = (_3487.xy + (_3637 * _3487.zw)) / _3521;
                                                                                                        if (!(textureLod(_6006, _3644, 0.0).w < 0.5))
                                                                                                        {
                                                                                                            float _3664 = abs((textureLod(_6010, _3644, 0.0).x * _3483) - _3482);
                                                                                                            if (_3664 < _3110)
                                                                                                            {
                                                                                                                _3110 = _3664;
                                                                                                                _3109 = (_3486.xy + (_3637 * _3486.zw)) / Globals.uAtlasSize.xy;
                                                                                                                _3491 = _3664 < 0.0199999995529651641845703125;
                                                                                                                _3492 = true;
                                                                                                            }
                                                                                                            else
                                                                                                            {
                                                                                                                _3491 = _3476;
                                                                                                                _3492 = _3477;
                                                                                                            }
                                                                                                            _3476 = _3491;
                                                                                                            _3477 = _3492;
                                                                                                        }
                                                                                                    }
                                                                                                }
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                            if (_3553_ladder_break)
                                                                            {
                                                                                break;
                                                                            }
                                                                            _3478++;
                                                                            continue;
                                                                        }
                                                                        _3471 = _3476;
                                                                        _3472 = _3477;
                                                                        _3473++;
                                                                        continue;
                                                                    }
                                                                    _3468 = _3472;
                                                                }
                                                            }
                                                            if (_3468)
                                                            {
                                                                _3107 = textureLod(_6014, _3109, 0.0).xyz * smoothstep(1.5 * Globals.uClipmapOrigin.data[0].w, 2.0 * Globals.uClipmapOrigin.data[0].w, length(_3106 - world));
                                                            }
                                                            else
                                                            {
                                                                _3107 = vec3(0.0);
                                                            }
                                                        }
                                                        else
                                                        {
                                                            _3107 = vec3(0.0);
                                                        }
                                                        vec4 _3827 = vec4(0.2820949852466583251953125, (-0.48860299587249755859375) * _3271.y, 0.48860299587249755859375 * _3271.z, (-0.48860299587249755859375) * _3271.x);
                                                        _3101++;
                                                        _3102 += (_3827 * _3107.x);
                                                        _3103 += (_3827 * _3107.y);
                                                        _3104 += (_3827 * _3107.z);
                                                        continue;
                                                    }
                                                    vec4 _3844 = vec4(0.2820949852466583251953125, (-0.48860299587249755859375) * _417.y, 0.48860299587249755859375 * _417.z, (-0.48860299587249755859375) * _417.x);
                                                    vec4 _3835 = vec4(_3844.x * 3.1415927410125732421875, _3844.yzw * 2.094395160675048828125);
                                                    vec3 _3217 = vec3(dot(_3102, _3835), dot(_3103, _3835), dot(_3104, _3835)) * 0.3926990926265716552734375;
                                                    bvec3 _6049 = isnan(_3217);
                                                    bvec3 _6050 = isnan(vec3(0.0));
                                                    vec3 _6051 = max(_3217, vec3(0.0));
                                                    vec3 _6052 = vec3(_6049.x ? vec3(0.0).x : _6051.x, _6049.y ? vec3(0.0).y : _6051.y, _6049.z ? vec3(0.0).z : _6051.z);
                                                    _3099 = vec3(_6050.x ? _3217.x : _6052.x, _6050.y ? _3217.y : _6052.y, _6050.z ? _3217.z : _6052.z);
                                                }
                                            }
                                            vec4 _sampled_1 = imageLoad(uDirect, texelAt);
                                            if (Globals.uTemporalIndex > 0)
                                            {
                                                visibility = _sampled_1.w;
                                            }
                                            else
                                            {
                                                visibility = 0.0;
                                            }
                                            float limit_1 = float(Globals.uMaxFrames);
                                            float _1575 = visibility + 1.0;
                                            float _1576 = limit_1 + 1.0;
                                            imageStore(uDirect, ivec2(uvec2(texelAt)), vec4(mix(_sampled_1.xyz, _3099, vec3(1.0 / (1.0 + (isnan(limit_1) ? visibility : (isnan(visibility) ? limit_1 : min(visibility, limit_1)))))), isnan(_1576) ? _1575 : (isnan(_1575) ? _1576 : min(_1575, _1576))));
                                        }
                                    }
                                    else
                                    {
                                        int light;
                                        vec3 lit;
                                        if (Globals.uMode == 2)
                                        {
                                            ivec2 _1593 = pageAt + ivec2(_272, int(uPages_1._member0[at].w));
                                            ivec2 probe00 = texelAt >> ivec2(2);
                                            vec2 _1604 = (vec2(texelAt - (probe00 * ivec2(4))) + vec2(1.0)) * vec2(0.16666667163372039794921875);
                                            light = 0;
                                            lit = vec3(0.0);
                                            visibility = 0.0;
                                            vec3 position;
                                            bool _3846;
                                            bool _3847;
                                            float _3896;
                                            vec3 _3914;
                                            bool _3973;
                                            bool _3974;
                                            float _4023;
                                            for (;;)
                                            {
                                                bool _126_ladder_break = false;
                                                {
                                                    if (!(light < 4))
                                                    {
                                                        _126_ladder_break = true;
                                                    }
                                                    else
                                                    {
                                                        ivec2 probeCoord_1 = probe00 + _1613_comp[light];
                                                        {
                                                            position = vec3(0.0);
                                                            if (any(lessThan(probeCoord_1, ivec2(0))))
                                                            {
                                                                _3847 = true;
                                                            }
                                                            else
                                                            {
                                                                _3847 = probeCoord_1.x >= Globals.uProbeWidth;
                                                            }
                                                            if (_3847)
                                                            {
                                                                _3847 = true;
                                                            }
                                                            else
                                                            {
                                                                _3847 = probeCoord_1.y >= Globals.uProbeHeight;
                                                            }
                                                            if (_3847)
                                                            {
                                                                _3846 = false;
                                                            }
                                                            else
                                                            {
                                                                ivec2 _3872 = probeCoord_1 * ivec2(4);
                                                                if (any(lessThan(_3872, pageAt)))
                                                                {
                                                                    _3847 = true;
                                                                }
                                                                else
                                                                {
                                                                    _3847 = any(greaterThanEqual(_3872, _1593));
                                                                }
                                                                if (_3847)
                                                                {
                                                                    _3846 = false;
                                                                }
                                                                else
                                                                {
                                                                    int _3888 = (probeCoord_1.y * Globals.uProbeWidth) + probeCoord_1.x;
                                                                    position = uProbePos._member0[_3888].xyz;
                                                                    _3846 = uProbePos._member0[_3888].w >= 0.5;
                                                                }
                                                            }
                                                        }
                                                        if (!(!_3846))
                                                        {
                                                            vec3 _3899 = world - position;
                                                            if ((abs(dot(_3899, _417)) / (length(_3899) + 0.00999999977648258209228515625)) < 0.257759988307952880859375)
                                                            {
                                                                _3896 = 1.0;
                                                            }
                                                            else
                                                            {
                                                                _3896 = 0.0;
                                                            }
                                                            if (!(_3896 <= 0.0))
                                                            {
                                                                vec2 _1737 = mix(vec2(1.0) - _1604, _1604, vec2(_1613_comp[light]));
                                                                float w = _1737.x * _1737.y;
                                                                int _3910 = 0;
                                                                vec3 _3911 = textureLod(_6019, (vec2(probeCoord_1 * ivec2(4)) + vec2(0.5)) / Globals.uAtlasSize.xy, 0.0).xyz * 2.0;
                                                                float _3912 = 2.0;
                                                                for (;;)
                                                                {
                                                                    bool _3921_ladder_break = false;
                                                                    {
                                                                        if (!(_3910 < 4))
                                                                        {
                                                                            _3921_ladder_break = true;
                                                                        }
                                                                        else
                                                                        {
                                                                            ivec2 _3930 = probeCoord_1 + _1798_comp[_3910];
                                                                            {
                                                                                _3914 = vec3(0.0);
                                                                                if (any(lessThan(_3930, ivec2(0))))
                                                                                {
                                                                                    _3974 = true;
                                                                                }
                                                                                else
                                                                                {
                                                                                    _3974 = _3930.x >= Globals.uProbeWidth;
                                                                                }
                                                                                if (_3974)
                                                                                {
                                                                                    _3974 = true;
                                                                                }
                                                                                else
                                                                                {
                                                                                    _3974 = _3930.y >= Globals.uProbeHeight;
                                                                                }
                                                                                if (_3974)
                                                                                {
                                                                                    _3973 = false;
                                                                                }
                                                                                else
                                                                                {
                                                                                    ivec2 _3999 = _3930 * ivec2(4);
                                                                                    if (any(lessThan(_3999, pageAt)))
                                                                                    {
                                                                                        _3974 = true;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        _3974 = any(greaterThanEqual(_3999, _1593));
                                                                                    }
                                                                                    if (_3974)
                                                                                    {
                                                                                        _3973 = false;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        int _4015 = (_3930.y * Globals.uProbeWidth) + _3930.x;
                                                                                        _3914 = uProbePos._member0[_4015].xyz;
                                                                                        _3973 = uProbePos._member0[_4015].w >= 0.5;
                                                                                    }
                                                                                }
                                                                            }
                                                                            if (!(!_3973))
                                                                            {
                                                                                vec3 _4026 = world - _3914;
                                                                                if ((abs(dot(_4026, _417)) / (length(_4026) + 0.00999999977648258209228515625)) < 0.257759988307952880859375)
                                                                                {
                                                                                    _4023 = 1.0;
                                                                                }
                                                                                else
                                                                                {
                                                                                    _4023 = 0.0;
                                                                                }
                                                                                if (!(_4023 <= 0.0))
                                                                                {
                                                                                    _3911 += textureLod(_6019, (vec2(_3930 * ivec2(4)) + vec2(0.5)) / Globals.uAtlasSize.xy, 0.0).xyz;
                                                                                    _3912 += 1.0;
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                    if (_3921_ladder_break)
                                                                    {
                                                                        break;
                                                                    }
                                                                    _3910++;
                                                                    continue;
                                                                }
                                                                lit += ((_3911 / vec3(_3912)) * w);
                                                                visibility += w;
                                                            }
                                                        }
                                                    }
                                                }
                                                if (_126_ladder_break)
                                                {
                                                    break;
                                                }
                                                light++;
                                                continue;
                                            }
                                            vec3 indirect;
                                            if (visibility > 0.0)
                                            {
                                                indirect = lit / vec3(visibility);
                                            }
                                            else
                                            {
                                                indirect = textureLod(_6019, (vec2(probe00 * ivec2(4)) + vec2(0.5)) / Globals.uAtlasSize.xy, 0.0).xyz;
                                            }
                                            vec3 _1862 = _sampled.xyz;
                                            vec3 _4072;
                                            {
                                                if (Globals.uBoost >= 1.0)
                                                {
                                                    _4072 = _1862;
                                                }
                                                else
                                                {
                                                    float _4079 = dot(_1862, vec3(0.300000011920928955078125, 0.589999973773956298828125, 0.10999999940395355224609375));
                                                    vec3 _4091 = clamp(_1862 * (pow(isnan(0.0) ? _4079 : (isnan(_4079) ? 0.0 : max(_4079, 0.0)), Globals.uBoost) / (isnan(9.9999999392252902907785028219223e-09) ? _4079 : (isnan(_4079) ? 9.9999999392252902907785028219223e-09 : max(_4079, 9.9999999392252902907785028219223e-09)))), vec3(0.0), vec3(1.0));
                                                    bvec3 _6074 = isnan(_4091);
                                                    bvec3 _6075 = isnan(vec3(0.9900000095367431640625));
                                                    vec3 _6076 = min(_4091, vec3(0.9900000095367431640625));
                                                    vec3 _6077 = vec3(_6074.x ? vec3(0.9900000095367431640625).x : _6076.x, _6074.y ? vec3(0.9900000095367431640625).y : _6076.y, _6074.z ? vec3(0.9900000095367431640625).z : _6076.z);
                                                    _4072 = vec3(_6075.x ? _4091.x : _6077.x, _6075.y ? _4091.y : _6077.y, _6075.z ? _4091.z : _6077.z);
                                                }
                                            }
                                            imageStore(uDirect, ivec2(uvec2(texelAt)), vec4((texelFetch(_6017, ivec3(texelAt, 0).xy, 0).xyz + indirect) * (_4072 * vec3(0.3183098733425140380859375)), 1.0));
                                        }
                                        else
                                        {
                                            if (Globals.uMode == 3)
                                            {
                                                vec3 _1920 = _sampled.xyz;
                                                vec3 _4093;
                                                {
                                                    if (Globals.uBoost >= 1.0)
                                                    {
                                                        _4093 = _1920;
                                                    }
                                                    else
                                                    {
                                                        float _4100 = dot(_1920, vec3(0.300000011920928955078125, 0.589999973773956298828125, 0.10999999940395355224609375));
                                                        vec3 _4112 = clamp(_1920 * (pow(isnan(0.0) ? _4100 : (isnan(_4100) ? 0.0 : max(_4100, 0.0)), Globals.uBoost) / (isnan(9.9999999392252902907785028219223e-09) ? _4100 : (isnan(_4100) ? 9.9999999392252902907785028219223e-09 : max(_4100, 9.9999999392252902907785028219223e-09)))), vec3(0.0), vec3(1.0));
                                                        bvec3 _6089 = isnan(_4112);
                                                        bvec3 _6090 = isnan(vec3(0.9900000095367431640625));
                                                        vec3 _6091 = min(_4112, vec3(0.9900000095367431640625));
                                                        vec3 _6092 = vec3(_6089.x ? vec3(0.9900000095367431640625).x : _6091.x, _6089.y ? vec3(0.9900000095367431640625).y : _6091.y, _6089.z ? vec3(0.9900000095367431640625).z : _6091.z);
                                                        _4093 = vec3(_6090.x ? _4112.x : _6092.x, _6090.y ? _4112.y : _6092.y, _6090.z ? _4112.z : _6092.z);
                                                    }
                                                }
                                                imageStore(uDirect, ivec2(uvec2(texelAt)), vec4(texelFetch(_6017, ivec3(texelAt, 0).xy, 0).xyz * (_4093 * vec3(0.3183098733425140380859375)), 1.0));
                                            }
                                            else
                                            {
                                                if (Globals.uProbe != 0)
                                                {
                                                    vec4 _4114;
                                                    {
                                                        if (Globals.uProbe == 5)
                                                        {
                                                            if (((texelAt.x | texelAt.y) & 7) != 0)
                                                            {
                                                                _4114 = vec4(0.0);
                                                            }
                                                            else
                                                            {
                                                                vec2 _4115;
                                                                bool _4237;
                                                                {
                                                                    _4115 = vec2(0.0);
                                                                    float _4117 = 1000000000.0;
                                                                    if (Globals.uLookupBuckets <= 0)
                                                                    {
                                                                        _4237 = false;
                                                                    }
                                                                    else
                                                                    {
                                                                        ivec3 _4278 = ivec3(floor((world - Globals.uLookupMin) / vec3(Globals.uLookupCell)));
                                                                        int _4490 = int((((uint(_4278.x) * 2376512323u) ^ (uint(_4278.y) * 3625334849u)) ^ (uint(_4278.z) * 3407524639u)) & uint(Globals.uLookupBuckets - 1));
                                                                        uvec2 _4283 = uvec2(textureSize(_6004, 0));
                                                                        vec2 _4290 = vec2(float(_4283.x), float(_4283.y));
                                                                        bool _4240 = false;
                                                                        bool _4241 = false;
                                                                        int _4242 = 0;
                                                                        bool _4243;
                                                                        ivec2 _4244;
                                                                        bool _4248;
                                                                        bool _4257;
                                                                        bool _4258;
                                                                        bool _4259;
                                                                        bool _4260;
                                                                        bool _4261;
                                                                        ivec2 _4491;
                                                                        for (;;)
                                                                        {
                                                                            if (_4242 <= uCells_1._member0[Globals.uLookupBuckets].y)
                                                                            {
                                                                                _4243 = !_4240;
                                                                            }
                                                                            else
                                                                            {
                                                                                _4243 = false;
                                                                            }
                                                                            if (!_4243)
                                                                            {
                                                                                break;
                                                                            }
                                                                            bool _4310 = _4242 == 0;
                                                                            if (_4310)
                                                                            {
                                                                                _4244 = uCells_1._member0[_4490];
                                                                            }
                                                                            else
                                                                            {
                                                                                int _4495 = uCells_1._member0[Globals.uLookupBuckets].x + ((_4242 - 1) * 6);
                                                                                float _4511 = intBitsToFloat(uCellPages_1._member0[_4495 + 3]);
                                                                                vec3 _4513 = world - vec3(intBitsToFloat(uCellPages_1._member0[_4495]), intBitsToFloat(uCellPages_1._member0[_4495 + 1]), intBitsToFloat(uCellPages_1._member0[_4495 + 2]));
                                                                                if (dot(_4513, _4513) > (_4511 * _4511))
                                                                                {
                                                                                    _4491 = ivec2(0);
                                                                                }
                                                                                else
                                                                                {
                                                                                    _4491 = ivec2(uCellPages_1._member0[_4495 + 4], uCellPages_1._member0[_4495 + 5]);
                                                                                }
                                                                                _4244 = _4491;
                                                                            }
                                                                            bool _4245 = _4240;
                                                                            bool _4246 = _4241;
                                                                            int _4247 = 0;
                                                                            for (;;)
                                                                            {
                                                                                bool _4322_ladder_break = false;
                                                                                {
                                                                                    if (_4247 < _4244.y)
                                                                                    {
                                                                                        _4248 = !_4245;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        _4248 = false;
                                                                                    }
                                                                                    if (!_4248)
                                                                                    {
                                                                                        _4322_ladder_break = true;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        int _4339 = _4244.x + _4247;
                                                                                        int _4342 = uCellPages_1._member0[_4339] * 10;
                                                                                        if (!((uPages_1._member0[_4342 + 5].w > 0.5) == _4310))
                                                                                        {
                                                                                            int _4351 = _4342 + 9;
                                                                                            vec3 _4355 = world - uPages_1._member0[_4351].xyz;
                                                                                            if (!(dot(_4355, _4355) > (uPages_1._member0[_4351].w * uPages_1._member0[_4351].w)))
                                                                                            {
                                                                                                int _4529 = uCellPages_1._member0[_4339] * 10;
                                                                                                vec4 _4256 = uPages_1._member0[_4529 + 1];
                                                                                                int _4535 = _4529 + 2;
                                                                                                int _4538 = _4529 + 3;
                                                                                                int _4541 = _4529 + 4;
                                                                                                int _4547 = _4529 + 6;
                                                                                                int _4550 = _4529 + 7;
                                                                                                int _4553 = _4529 + 8;
                                                                                                vec3 _4560 = world - vec3(uPages_1._member0[_4547].w, uPages_1._member0[_4550].w, uPages_1._member0[_4553].w);
                                                                                                vec3 _4254 = vec3(dot(uPages_1._member0[_4547].xyz, vec3(-0.0)), dot(uPages_1._member0[_4550].xyz, vec3(-0.0)), dot(uPages_1._member0[_4553].xyz, vec3(-0.0)));
                                                                                                vec3 _4573 = vec3(dot(uPages_1._member0[_4547].xyz, _4560), dot(uPages_1._member0[_4550].xyz, _4560), dot(uPages_1._member0[_4553].xyz, _4560)) - uPages_1._member0[_4535].xyz;
                                                                                                vec2 _4576 = vec2(uPages_1._member0[_4535].w, uPages_1._member0[_4538].w);
                                                                                                bvec2 _6094 = isnan(_4576);
                                                                                                bvec2 _6095 = isnan(vec2(9.9999999747524270787835121154785e-07));
                                                                                                vec2 _6096 = max(_4576, vec2(9.9999999747524270787835121154785e-07));
                                                                                                vec2 _6097 = vec2(_6094.x ? vec2(9.9999999747524270787835121154785e-07).x : _6096.x, _6094.y ? vec2(9.9999999747524270787835121154785e-07).y : _6096.y);
                                                                                                vec2 _4583 = vec2(dot(_4573, uPages_1._member0[_4538].xyz), dot(_4573, uPages_1._member0[_4541].xyz)) / vec2(_6095.x ? _4576.x : _6097.x, _6095.y ? _4576.y : _6097.y);
                                                                                                vec2 _4249 = _4583;
                                                                                                float _4251 = -dot(_4573, uPages_1._member0[_4529 + 5].xyz);
                                                                                                float _4252 = uPages_1._member0[_4541].w;
                                                                                                vec3 _4253 = uPages_1._member0[_4529 + 5].xyz;
                                                                                                if (abs(_4583.x) > 1.0)
                                                                                                {
                                                                                                    _4257 = true;
                                                                                                }
                                                                                                else
                                                                                                {
                                                                                                    _4257 = abs(_4249.y) > 1.0;
                                                                                                }
                                                                                                if (!(_4257))
                                                                                                {
                                                                                                    if (false)
                                                                                                    {
                                                                                                        _4258 = dot(_4253, _4254) < (-0.0500000007450580596923828125);
                                                                                                    }
                                                                                                    else
                                                                                                    {
                                                                                                        _4258 = false;
                                                                                                    }
                                                                                                    if (!(_4258))
                                                                                                    {
                                                                                                        if (_4251 < (-0.25))
                                                                                                        {
                                                                                                            _4259 = true;
                                                                                                        }
                                                                                                        else
                                                                                                        {
                                                                                                            _4259 = _4251 > (_4252 + 0.25);
                                                                                                        }
                                                                                                        if (!(_4259))
                                                                                                        {
                                                                                                            vec2 _4413 = (_4256.xy + (((_4249 * 0.5) + vec2(0.5)) * _4256.zw)) / _4290;
                                                                                                            if (!(textureLod(_6006, _4413, 0.0).w < 0.5))
                                                                                                            {
                                                                                                                float _4433 = abs((textureLod(_6010, _4413, 0.0).x * _4252) - _4251);
                                                                                                                if (_4433 < _4117)
                                                                                                                {
                                                                                                                    _4117 = _4433;
                                                                                                                    _4115 = _4413;
                                                                                                                    _4260 = _4433 < 0.0199999995529651641845703125;
                                                                                                                    _4261 = true;
                                                                                                                }
                                                                                                                else
                                                                                                                {
                                                                                                                    _4260 = _4245;
                                                                                                                    _4261 = _4246;
                                                                                                                }
                                                                                                                _4245 = _4260;
                                                                                                                _4246 = _4261;
                                                                                                            }
                                                                                                        }
                                                                                                    }
                                                                                                }
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                                if (_4322_ladder_break)
                                                                                {
                                                                                    break;
                                                                                }
                                                                                _4247++;
                                                                                continue;
                                                                            }
                                                                            _4240 = _4245;
                                                                            _4241 = _4246;
                                                                            _4242++;
                                                                            continue;
                                                                        }
                                                                        _4237 = _4241;
                                                                    }
                                                                }
                                                                if (!_4237)
                                                                {
                                                                    _4114 = vec4(1.0, 0.0, 0.0, 1.0);
                                                                }
                                                                else
                                                                {
                                                                    uvec2 _4146 = uvec2(textureSize(_6004, 0));
                                                                    vec2 _4157 = abs(_4115 - cardUv) * vec2(float(_4146.x), float(_4146.y));
                                                                    float _4158 = _4157.x;
                                                                    float _4159 = _4157.y;
                                                                    vec4 _4120;
                                                                    if ((isnan(_4159) ? _4158 : (isnan(_4158) ? _4159 : max(_4158, _4159))) < 1.5)
                                                                    {
                                                                        _4120 = vec4(0.0, 1.0, 0.0, 1.0);
                                                                    }
                                                                    else
                                                                    {
                                                                        _4120 = vec4(1.0, 1.0, 0.0, 1.0);
                                                                    }
                                                                    _4114 = _4120;
                                                                }
                                                            }
                                                        }
                                                        else
                                                        {
                                                            if (Globals.uProbe == 4)
                                                            {
                                                                _4588 = false;
                                                                vec4 _4589;
                                                                {
                                                                    int _4608 = max((Globals.uShadowLevels - 1), 0);
                                                                    vec3 _4614 = world + ((_417 * Globals.uClipmapOrigin.data[0].w) * 1.5);
                                                                    float _4623 = (Globals.uClipmapOrigin.data[0].w * float(Globals.uShadowResolution)) * float(1 << (Globals.uShadowLevels - 1));
                                                                    int _4590 = 0;
                                                                    float _4591 = 0.0;
                                                                    bool _4592;
                                                                    bool _4593;
                                                                    float _4595;
                                                                    float _4681;
                                                                    bool _4683;
                                                                    for (;;)
                                                                    {
                                                                        if (_4590 < 64)
                                                                        {
                                                                            _4592 = _4591 < _4623;
                                                                        }
                                                                        else
                                                                        {
                                                                            _4592 = false;
                                                                        }
                                                                        if (!_4592)
                                                                        {
                                                                            break;
                                                                        }
                                                                        vec3 _4642 = _4614 + (Globals.uSunDirection * _4591);
                                                                        _4680 = false;
                                                                        {
                                                                            _4593 = false;
                                                                            _4595 = Globals.uClipmapOrigin.data[0].w;
                                                                            int _4682 = 0;
                                                                            for (;;)
                                                                            {
                                                                                bool _4694_ladder_break = false;
                                                                                {
                                                                                    if (!(_4682 < Globals.uShadowLevels))
                                                                                    {
                                                                                        _4694_ladder_break = true;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        vec3 _4709 = (_4642 - Globals.uClipmapOrigin.data[_4682].xyz) / vec3(Globals.uClipmapOrigin.data[_4682].w);
                                                                                        if (any(lessThan(_4709, vec3(0.5))))
                                                                                        {
                                                                                            _4683 = true;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            _4683 = any(greaterThan(_4709, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                                        }
                                                                                        if (!(_4683))
                                                                                        {
                                                                                            _4593 = true;
                                                                                            _4595 = Globals.uClipmapOrigin.data[_4682].w;
                                                                                            _4680 = true;
                                                                                            _4681 = ((textureLod(_6012, vec3(_4709.x / float(Globals.uShadowResolution), _4709.y / float(Globals.uShadowResolution), ((float(_4682) * float(Globals.uShadowResolution)) + _4709.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_4682];
                                                                                            _4694_ladder_break = true;
                                                                                        }
                                                                                    }
                                                                                }
                                                                                if (_4694_ladder_break)
                                                                                {
                                                                                    break;
                                                                                }
                                                                                _4682++;
                                                                                continue;
                                                                            }
                                                                            if (!(_4680))
                                                                            {
                                                                                _4680 = true;
                                                                                _4681 = 1000000.0;
                                                                            }
                                                                        }
                                                                        if (!_4593)
                                                                        {
                                                                            _4588 = true;
                                                                            _4589 = vec4(1.0, 0.0, _4591 / _4623, 1.0);
                                                                            break;
                                                                        }
                                                                        float _4781 = 2.0 * _4595;
                                                                        if (_4681 < ((0.5 * _4595) * clamp(_4591 / (isnan(9.9999999747524270787835121154785e-07) ? _4781 : (isnan(_4781) ? 9.9999999747524270787835121154785e-07 : max(_4781, 9.9999999747524270787835121154785e-07))), 0.0, 1.0)))
                                                                        {
                                                                            _4588 = true;
                                                                            _4589 = vec4(0.0, _4595 / Globals.uClipmapOrigin.data[_4608].w, _4591 / _4623, 1.0);
                                                                            break;
                                                                        }
                                                                        float _4662 = _4595 * 0.25;
                                                                        _4590++;
                                                                        _4591 += (isnan(_4662) ? _4681 : (isnan(_4681) ? _4662 : max(_4681, _4662)));
                                                                        continue;
                                                                    }
                                                                    if (!(_4588))
                                                                    {
                                                                        _4588 = true;
                                                                        _4589 = vec4(0.5, 0.0, clamp(_4591 / _4623, 0.0, 1.0), 1.0);
                                                                    }
                                                                }
                                                                _4114 = _4589;
                                                            }
                                                            else
                                                            {
                                                                if (Globals.uProbe == 2)
                                                                {
                                                                    _4114 = vec4(clamp((world - Globals.uProbeMin) * Globals.uProbeInvExtent, vec3(0.0), vec3(1.0)), 1.0);
                                                                }
                                                                else
                                                                {
                                                                    if (Globals.uProbe == 3)
                                                                    {
                                                                        _4114 = vec4((_417 * 0.5) + vec3(0.5), 1.0);
                                                                    }
                                                                    else
                                                                    {
                                                                        vec3 _4199 = world + ((_417 * Globals.uClipmapOrigin.data[0].w) * 1.5);
                                                                        _4790 = false;
                                                                        bool _4121;
                                                                        float _4122;
                                                                        float _4791;
                                                                        {
                                                                            _4121 = false;
                                                                            _4122 = 0.0;
                                                                            int _4792 = 0;
                                                                            bool _4793;
                                                                            for (;;)
                                                                            {
                                                                                bool _4804_ladder_break = false;
                                                                                {
                                                                                    if (!(_4792 < Globals.uShadowLevels))
                                                                                    {
                                                                                        _4804_ladder_break = true;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        vec3 _4819 = (_4199 - Globals.uClipmapOrigin.data[_4792].xyz) / vec3(Globals.uClipmapOrigin.data[_4792].w);
                                                                                        if (any(lessThan(_4819, vec3(0.5))))
                                                                                        {
                                                                                            _4793 = true;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            _4793 = any(greaterThan(_4819, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                                        }
                                                                                        if (!(_4793))
                                                                                        {
                                                                                            _4121 = true;
                                                                                            vec4 _4866 = textureLod(_6012, vec3(_4819.x / float(Globals.uShadowResolution), _4819.y / float(Globals.uShadowResolution), ((float(_4792) * float(Globals.uShadowResolution)) + _4819.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0);
                                                                                            float _4868 = _4866.x;
                                                                                            _4122 = _4868;
                                                                                            _4790 = true;
                                                                                            _4791 = ((_4868 * 2.0) - 1.0) * Globals.uClipmapRange.data[_4792];
                                                                                            _4804_ladder_break = true;
                                                                                        }
                                                                                    }
                                                                                }
                                                                                if (_4804_ladder_break)
                                                                                {
                                                                                    break;
                                                                                }
                                                                                _4792++;
                                                                                continue;
                                                                            }
                                                                            if (!(_4790))
                                                                            {
                                                                                _4790 = true;
                                                                                _4791 = 1000000.0;
                                                                            }
                                                                        }
                                                                        float _4124;
                                                                        if (Globals.uShadowLevels > 0)
                                                                        {
                                                                            _4124 = clamp(Globals.uClipmapRange.data[0] / (Globals.uClipmapOrigin.data[0].w * 4.0), 0.0, 1.0);
                                                                        }
                                                                        else
                                                                        {
                                                                            _4124 = 0.0;
                                                                        }
                                                                        float _4125;
                                                                        if (_4121)
                                                                        {
                                                                            _4125 = clamp(_4791 / (Globals.uClipmapOrigin.data[0].w * 4.0), 0.0, 1.0);
                                                                        }
                                                                        else
                                                                        {
                                                                            _4125 = 1.0;
                                                                        }
                                                                        float _4126;
                                                                        if (_4121)
                                                                        {
                                                                            _4126 = 1.0;
                                                                        }
                                                                        else
                                                                        {
                                                                            _4126 = 0.5;
                                                                        }
                                                                        _4114 = vec4(_4124, _4122, _4125, _4126);
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                    imageStore(uDirect, ivec2(uvec2(texelAt)), _4114);
                                                }
                                                else
                                                {
                                                    float _2222 = dot(_417, Globals.uSunDirection);
                                                    float _2223 = isnan(0.0) ? _2222 : (isnan(_2222) ? 0.0 : max(_2222, 0.0));
                                                    if (_2223 > 0.0)
                                                    {
                                                        _4897 = false;
                                                        float _4898;
                                                        {
                                                            if (Globals.uShadowLevels <= 0)
                                                            {
                                                                _4897 = true;
                                                                _4898 = 1.0;
                                                            }
                                                            else
                                                            {
                                                                vec3 _4921 = world + ((_417 * Globals.uClipmapOrigin.data[0].w) * 1.5);
                                                                float _4932 = (Globals.uClipmapOrigin.data[0].w * float(Globals.uShadowResolution)) * float(1 << (Globals.uShadowLevels - 1));
                                                                int _4899 = 0;
                                                                float _4900 = 0.0;
                                                                bool _4901;
                                                                bool _4902;
                                                                float _4904;
                                                                float _4979;
                                                                bool _4981;
                                                                for (;;)
                                                                {
                                                                    if (_4899 < 64)
                                                                    {
                                                                        _4901 = _4900 < _4932;
                                                                    }
                                                                    else
                                                                    {
                                                                        _4901 = false;
                                                                    }
                                                                    if (!_4901)
                                                                    {
                                                                        break;
                                                                    }
                                                                    vec3 _4949 = _4921 + (Globals.uSunDirection * _4900);
                                                                    _4978 = false;
                                                                    {
                                                                        _4902 = false;
                                                                        _4904 = Globals.uClipmapOrigin.data[0].w;
                                                                        int _4980 = 0;
                                                                        for (;;)
                                                                        {
                                                                            bool _4992_ladder_break = false;
                                                                            {
                                                                                if (!(_4980 < Globals.uShadowLevels))
                                                                                {
                                                                                    _4992_ladder_break = true;
                                                                                }
                                                                                else
                                                                                {
                                                                                    vec3 _5007 = (_4949 - Globals.uClipmapOrigin.data[_4980].xyz) / vec3(Globals.uClipmapOrigin.data[_4980].w);
                                                                                    if (any(lessThan(_5007, vec3(0.5))))
                                                                                    {
                                                                                        _4981 = true;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        _4981 = any(greaterThan(_5007, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                                    }
                                                                                    if (!(_4981))
                                                                                    {
                                                                                        _4902 = true;
                                                                                        _4904 = Globals.uClipmapOrigin.data[_4980].w;
                                                                                        _4978 = true;
                                                                                        _4979 = ((textureLod(_6012, vec3(_5007.x / float(Globals.uShadowResolution), _5007.y / float(Globals.uShadowResolution), ((float(_4980) * float(Globals.uShadowResolution)) + _5007.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_4980];
                                                                                        _4992_ladder_break = true;
                                                                                    }
                                                                                }
                                                                            }
                                                                            if (_4992_ladder_break)
                                                                            {
                                                                                break;
                                                                            }
                                                                            _4980++;
                                                                            continue;
                                                                        }
                                                                        if (!(_4978))
                                                                        {
                                                                            _4978 = true;
                                                                            _4979 = 1000000.0;
                                                                        }
                                                                    }
                                                                    if (!_4902)
                                                                    {
                                                                        _4897 = true;
                                                                        _4898 = 1.0;
                                                                        break;
                                                                    }
                                                                    float _5079 = 2.0 * _4904;
                                                                    if (_4979 < ((0.5 * _4904) * clamp(_4900 / (isnan(9.9999999747524270787835121154785e-07) ? _5079 : (isnan(_5079) ? 9.9999999747524270787835121154785e-07 : max(_5079, 9.9999999747524270787835121154785e-07))), 0.0, 1.0)))
                                                                    {
                                                                        _4897 = true;
                                                                        _4898 = 0.0;
                                                                        break;
                                                                    }
                                                                    float _4964 = _4904 * 0.25;
                                                                    _4899++;
                                                                    _4900 += (isnan(_4964) ? _4979 : (isnan(_4979) ? _4964 : max(_4979, _4964)));
                                                                    continue;
                                                                }
                                                                if (!(_4897))
                                                                {
                                                                    _4897 = true;
                                                                    _4898 = 1.0;
                                                                }
                                                            }
                                                        }
                                                        visibility = _4898;
                                                    }
                                                    else
                                                    {
                                                        visibility = 1.0;
                                                    }
                                                    vec3 _5089;
                                                    {
                                                        if (Globals.uShadowLevels <= 0)
                                                        {
                                                            vec3 _5170;
                                                            {
                                                                if (Globals.uSkyShValid == 0)
                                                                {
                                                                    _5170 = Globals.uSkyColour * ((_417.z * 0.5) + 0.5);
                                                                }
                                                                else
                                                                {
                                                                    vec4 _5185 = vec4(_417, 1.0);
                                                                    vec4 _5188 = _5185.xyzz * _5185.yzzx;
                                                                    float _5214 = _417.x;
                                                                    float _5216 = _417.y;
                                                                    vec3 _5221 = (vec3(dot(Globals.uSkySh.data[0], _5185), dot(Globals.uSkySh.data[1], _5185), dot(Globals.uSkySh.data[2], _5185)) + vec3(dot(Globals.uSkySh.data[3], _5188), dot(Globals.uSkySh.data[4], _5188), dot(Globals.uSkySh.data[5], _5188))) + (Globals.uSkySh.data[6].xyz * ((_5214 * _5214) - (_5216 * _5216)));
                                                                    bvec3 _6129 = isnan(vec3(0.0));
                                                                    bvec3 _6130 = isnan(_5221);
                                                                    vec3 _6131 = max(vec3(0.0), _5221);
                                                                    vec3 _6132 = vec3(_6129.x ? _5221.x : _6131.x, _6129.y ? _5221.y : _6131.y, _6129.z ? _5221.z : _6131.z);
                                                                    _5170 = vec3(_6130.x ? vec3(0.0).x : _6132.x, _6130.y ? vec3(0.0).y : _6132.y, _6130.z ? vec3(0.0).z : _6132.z);
                                                                }
                                                            }
                                                            _5089 = _5170 * 3.1415927410125732421875;
                                                        }
                                                        else
                                                        {
                                                            vec3 _5090;
                                                            if (abs(_417.z) < 0.89999997615814208984375)
                                                            {
                                                                _5090 = vec3(0.0, 0.0, 1.0);
                                                            }
                                                            else
                                                            {
                                                                _5090 = vec3(1.0, 0.0, 0.0);
                                                            }
                                                            vec3 _5111 = normalize(cross(_417, _5090));
                                                            vec3 _5112 = cross(_417, _5111);
                                                            vec3 _5114 = floor(world * 8.0);
                                                            float _5118 = fract(sin(dot(_5114, vec3(12.98980045318603515625, 78.233001708984375, 37.71900177001953125))) * 43758.546875);
                                                            float _5122 = fract(sin(dot(_5114, vec3(39.34600067138671875, 11.1350002288818359375, 83.154998779296875))) * 24634.634765625);
                                                            int _5092 = 0;
                                                            vec3 _5091 = vec3(0.0);
                                                            vec3 _5254;
                                                            float _5314;
                                                            bool _5317;
                                                            bool _5318;
                                                            float _5320;
                                                            float _5395;
                                                            bool _5397;
                                                            for (;;)
                                                            {
                                                                if (!(_5092 < 8))
                                                                {
                                                                    break;
                                                                }
                                                                float _5134 = (float(_5092) + _5122) * 0.125;
                                                                uint _5227 = uint(_5092);
                                                                uint _5230 = (_5227 << 16u) | (_5227 >> 16u);
                                                                uint _5235 = ((_5230 & 1431655765u) << 1u) | ((_5230 & 2863311530u) >> 1u);
                                                                uint _5240 = ((_5235 & 858993459u) << 2u) | ((_5235 & 3435973836u) >> 2u);
                                                                uint _5245 = ((_5240 & 252645135u) << 4u) | ((_5240 & 4042322160u) >> 4u);
                                                                float _5139 = sqrt(_5134);
                                                                float _5140 = 6.283185482025146484375 * fract((float(((_5245 & 16711935u) << 8u) | ((_5245 & 4278255360u) >> 8u)) * 2.3283064365386962890625e-10) + _5118);
                                                                float _5148 = 1.0 - _5134;
                                                                vec3 _5153 = normalize(((_5111 * (_5139 * cos(_5140))) + (_5112 * (_5139 * sin(_5140)))) + (_417 * sqrt(isnan(_5148) ? 0.0 : (isnan(0.0) ? _5148 : max(0.0, _5148)))));
                                                                {
                                                                    if (Globals.uSkyShValid == 0)
                                                                    {
                                                                        _5254 = Globals.uSkyColour * ((_5153.z * 0.5) + 0.5);
                                                                    }
                                                                    else
                                                                    {
                                                                        vec4 _5269 = vec4(_5153, 1.0);
                                                                        vec4 _5272 = _5269.xyzz * _5269.yzzx;
                                                                        float _5298 = _5153.x;
                                                                        float _5300 = _5153.y;
                                                                        vec3 _5305 = (vec3(dot(Globals.uSkySh.data[0], _5269), dot(Globals.uSkySh.data[1], _5269), dot(Globals.uSkySh.data[2], _5269)) + vec3(dot(Globals.uSkySh.data[3], _5272), dot(Globals.uSkySh.data[4], _5272), dot(Globals.uSkySh.data[5], _5272))) + (Globals.uSkySh.data[6].xyz * ((_5298 * _5298) - (_5300 * _5300)));
                                                                        bvec3 _6139 = isnan(vec3(0.0));
                                                                        bvec3 _6140 = isnan(_5305);
                                                                        vec3 _6141 = max(vec3(0.0), _5305);
                                                                        vec3 _6142 = vec3(_6139.x ? _5305.x : _6141.x, _6139.y ? _5305.y : _6141.y, _6139.z ? _5305.z : _6141.z);
                                                                        _5254 = vec3(_6140.x ? vec3(0.0).x : _6142.x, _6140.y ? vec3(0.0).y : _6142.y, _6140.z ? vec3(0.0).z : _6142.z);
                                                                    }
                                                                }
                                                                _5313 = false;
                                                                {
                                                                    if (Globals.uShadowLevels <= 0)
                                                                    {
                                                                        _5313 = true;
                                                                        _5314 = 1.0;
                                                                    }
                                                                    else
                                                                    {
                                                                        vec3 _5337 = world + ((_417 * Globals.uClipmapOrigin.data[0].w) * 1.5);
                                                                        float _5348 = (Globals.uClipmapOrigin.data[0].w * float(Globals.uShadowResolution)) * float(1 << (Globals.uShadowLevels - 1));
                                                                        int _5315 = 0;
                                                                        float _5316 = 0.0;
                                                                        for (;;)
                                                                        {
                                                                            if (_5315 < 64)
                                                                            {
                                                                                _5317 = _5316 < _5348;
                                                                            }
                                                                            else
                                                                            {
                                                                                _5317 = false;
                                                                            }
                                                                            if (!_5317)
                                                                            {
                                                                                break;
                                                                            }
                                                                            vec3 _5365 = _5337 + (_5153 * _5316);
                                                                            _5394 = false;
                                                                            {
                                                                                _5318 = false;
                                                                                _5320 = Globals.uClipmapOrigin.data[0].w;
                                                                                int _5396 = 0;
                                                                                for (;;)
                                                                                {
                                                                                    bool _5408_ladder_break = false;
                                                                                    {
                                                                                        if (!(_5396 < Globals.uShadowLevels))
                                                                                        {
                                                                                            _5408_ladder_break = true;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            vec3 _5423 = (_5365 - Globals.uClipmapOrigin.data[_5396].xyz) / vec3(Globals.uClipmapOrigin.data[_5396].w);
                                                                                            if (any(lessThan(_5423, vec3(0.5))))
                                                                                            {
                                                                                                _5397 = true;
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                _5397 = any(greaterThan(_5423, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                                            }
                                                                                            if (!(_5397))
                                                                                            {
                                                                                                _5318 = true;
                                                                                                _5320 = Globals.uClipmapOrigin.data[_5396].w;
                                                                                                _5394 = true;
                                                                                                _5395 = ((textureLod(_6012, vec3(_5423.x / float(Globals.uShadowResolution), _5423.y / float(Globals.uShadowResolution), ((float(_5396) * float(Globals.uShadowResolution)) + _5423.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_5396];
                                                                                                _5408_ladder_break = true;
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                    if (_5408_ladder_break)
                                                                                    {
                                                                                        break;
                                                                                    }
                                                                                    _5396++;
                                                                                    continue;
                                                                                }
                                                                                if (!(_5394))
                                                                                {
                                                                                    _5394 = true;
                                                                                    _5395 = 1000000.0;
                                                                                }
                                                                            }
                                                                            if (!_5318)
                                                                            {
                                                                                _5313 = true;
                                                                                _5314 = 1.0;
                                                                                break;
                                                                            }
                                                                            float _5495 = 2.0 * _5320;
                                                                            if (_5395 < ((0.5 * _5320) * clamp(_5316 / (isnan(9.9999999747524270787835121154785e-07) ? _5495 : (isnan(_5495) ? 9.9999999747524270787835121154785e-07 : max(_5495, 9.9999999747524270787835121154785e-07))), 0.0, 1.0)))
                                                                            {
                                                                                _5313 = true;
                                                                                _5314 = 0.0;
                                                                                break;
                                                                            }
                                                                            float _5380 = _5320 * 0.25;
                                                                            _5315++;
                                                                            _5316 += (isnan(_5380) ? _5395 : (isnan(_5395) ? _5380 : max(_5395, _5380)));
                                                                            continue;
                                                                        }
                                                                        if (!(_5313))
                                                                        {
                                                                            _5313 = true;
                                                                            _5314 = 1.0;
                                                                        }
                                                                    }
                                                                }
                                                                _5092++;
                                                                _5091 += (_5254 * _5314);
                                                                continue;
                                                            }
                                                            _5089 = _5091 * 0.3926990926265716552734375;
                                                        }
                                                    }
                                                    light = 0;
                                                    lit = ((Globals.uSunColour * _2223) * visibility) + _5089;
                                                    float aim;
                                                    float reaches;
                                                    float _5505;
                                                    float _5756;
                                                    bool _5759;
                                                    bool _5760;
                                                    float _5762;
                                                    float _5832;
                                                    bool _5834;
                                                    for (;;)
                                                    {
                                                        bool _151_ladder_break = false;
                                                        {
                                                            if (!(light < Globals.uLightCount))
                                                            {
                                                                _151_ladder_break = true;
                                                            }
                                                            else
                                                            {
                                                                int _2434 = light * 3;
                                                                int _2437 = _2434 + 1;
                                                                int _2440 = _2434 + 2;
                                                                vec3 delta = uLights_1._member0[_2434].xyz - world;
                                                                float _2445 = dot(delta, delta);
                                                                float _2447 = uLights_1._member0[_2434].w * 3.0;
                                                                float _2449 = isnan(2.0) ? _2447 : (isnan(_2447) ? 2.0 : max(_2447, 2.0));
                                                                float reachSquared = _2449 * _2449;
                                                                if (!(_2445 >= reachSquared))
                                                                {
                                                                    vec3 toLight = delta * inversesqrt(isnan(9.9999999747524270787835121154785e-07) ? _2445 : (isnan(_2445) ? 9.9999999747524270787835121154785e-07 : max(_2445, 9.9999999747524270787835121154785e-07)));
                                                                    float _2457 = dot(_417, toLight);
                                                                    float _2458 = isnan(0.0) ? _2457 : (isnan(_2457) ? 0.0 : max(_2457, 0.0));
                                                                    if (!(_2458 <= 0.0))
                                                                    {
                                                                        float _2468 = clamp(1.0 - ((_2445 * _2445) / (reachSquared * reachSquared)), 0.0, 1.0);
                                                                        if (dot(uLights_1._member0[_2440].xyz, uLights_1._member0[_2440].xyz) > 0.25)
                                                                        {
                                                                            float _2475 = dot(normalize(uLights_1._member0[_2440].xyz), -toLight);
                                                                            aim = isnan(0.0) ? _2475 : (isnan(_2475) ? 0.0 : max(_2475, 0.0));
                                                                        }
                                                                        else
                                                                        {
                                                                            aim = 1.0;
                                                                        }
                                                                        float contribution = (((((uLights_1._member0[_2437].w * Globals.uLocalScale) * _2458) * (1.0 / (_2445 + 1.0))) * _2468) * _2468) * aim;
                                                                        if (!((contribution * dot(uLights_1._member0[_2437].xyz, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875))) < 9.9999997473787516355514526367188e-06))
                                                                        {
                                                                            int _2504 = floatBitsToInt(uLights_1._member0[_2440].w);
                                                                            {
                                                                                if (_2504 < 0)
                                                                                {
                                                                                    _5505 = -1.0;
                                                                                }
                                                                                else
                                                                                {
                                                                                    uint _5506 = uvec3(textureSize(_6022, 0)).x;
                                                                                    float _5509 = 0.25;
                                                                                    int _5510 = 0;
                                                                                    for (;;)
                                                                                    {
                                                                                        if (!(_5510 < 6))
                                                                                        {
                                                                                            break;
                                                                                        }
                                                                                        int _5543 = ((_2504 + _5510) * 5) + 3;
                                                                                        float _5549 = dot(uLampMapRecords_1._member0[_5543].xyz, world) + uLampMapRecords_1._member0[_5543].w;
                                                                                        _5509 = isnan(_5549) ? _5509 : (isnan(_5509) ? _5549 : max(_5509, _5549));
                                                                                        _5510++;
                                                                                        continue;
                                                                                    }
                                                                                    vec3 _5567 = world + (_417 * (0.0500000007450580596923828125 + (1.5 * ((_5509 * 2.0) / float(max(_5506, 1u))))));
                                                                                    float _5511 = -1000000015047466219876688855040.0;
                                                                                    int _5512 = _2504;
                                                                                    _5510 = 0;
                                                                                    for (;;)
                                                                                    {
                                                                                        if (!(_5510 < 6))
                                                                                        {
                                                                                            break;
                                                                                        }
                                                                                        int _5577 = _2504 + _5510;
                                                                                        int _5579 = (_5577 * 5) + 3;
                                                                                        float _5585 = dot(uLampMapRecords_1._member0[_5579].xyz, _5567) + uLampMapRecords_1._member0[_5579].w;
                                                                                        if (_5585 > _5511)
                                                                                        {
                                                                                            _5511 = _5585;
                                                                                            _5512 = _5577;
                                                                                        }
                                                                                        _5510++;
                                                                                        continue;
                                                                                    }
                                                                                    int _5597 = _5512 * 5;
                                                                                    int _5598 = _5597 + 4;
                                                                                    if (uLampMapRecords_1._member0[_5598].z <= 0.0)
                                                                                    {
                                                                                        _5505 = -1.0;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        int _5607 = _5597 + 1;
                                                                                        if (_5511 <= (uLampMapRecords_1._member0[_5598].y / ((-1.0) - uLampMapRecords_1._member0[_5598].x)))
                                                                                        {
                                                                                            _5505 = 1.0;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            vec2 _5629 = vec2(dot(uLampMapRecords_1._member0[_5597].xyz, _5567) + uLampMapRecords_1._member0[_5597].w, dot(uLampMapRecords_1._member0[_5607].xyz, _5567) + uLampMapRecords_1._member0[_5607].w) / vec2(_5511);
                                                                                            uvec3 _5638 = uvec3(textureSize(_6022, 0));
                                                                                            uint _5639 = _5638.x;
                                                                                            ivec2 _5646 = ivec2(int(_5639), int(_5638.y));
                                                                                            float _5647 = length(uLampMapRecords_1._member0[_5597].xyz);
                                                                                            float _5660 = (0.0500000007450580596923828125 + (0.004999999888241291046142578125 * _5511)) + (2.0 * ((_5511 * (2.0 / (isnan(0.001000000047497451305389404296875) ? _5647 : (isnan(_5647) ? 0.001000000047497451305389404296875 : max(_5647, 0.001000000047497451305389404296875))))) / float(max(_5639, 1u))));
                                                                                            vec2 _5664 = (vec2((_5629.x * 0.5) + 0.5, 0.5 - (_5629.y * 0.5)) * vec2(_5646)) - vec2(0.5);
                                                                                            vec2 _5665 = floor(_5664);
                                                                                            ivec2 _5668 = ivec2(_5665) - ivec2(1);
                                                                                            vec2 _5669 = _5664 - _5665;
                                                                                            int _5518 = 0;
                                                                                            float _5516 = 0.0;
                                                                                            float _5517 = 0.0;
                                                                                            for (;;)
                                                                                            {
                                                                                                if (!(_5518 < 4))
                                                                                                {
                                                                                                    break;
                                                                                                }
                                                                                                int _5520 = 0;
                                                                                                float _5519 = _5517;
                                                                                                for (;;)
                                                                                                {
                                                                                                    if (!(_5520 < 4))
                                                                                                    {
                                                                                                        break;
                                                                                                    }
                                                                                                    int _5688 = _5520;
                                                                                                    float _5702 = ((texelFetch(_6022, ivec4(clamp(_5668 + ivec2(_5688, _5518), ivec2(0), _5646 - ivec2(1)), _5512, 0).xyz, 0).x * 2.0) - 1.0) - uLampMapRecords_1._member0[_5598].x;
                                                                                                    vec2 _5754 = clamp(vec2(1.0) - (abs(vec2(float(_5688) - 1.0, float(_5518) - 1.0) - _5669) * vec2(0.5)), vec2(0.0), vec2(1.0));
                                                                                                    float _5721 = _5754.x * _5754.y;
                                                                                                    if ((uLampMapRecords_1._member0[_5598].y / (isnan(-9.9999999747524270787835121154785e-07) ? _5702 : (isnan(_5702) ? (-9.9999999747524270787835121154785e-07) : min(_5702, -9.9999999747524270787835121154785e-07)))) >= (_5511 - _5660))
                                                                                                    {
                                                                                                        _5509 = _5721;
                                                                                                    }
                                                                                                    else
                                                                                                    {
                                                                                                        _5509 = 0.0;
                                                                                                    }
                                                                                                    _5520++;
                                                                                                    _5516 += _5509;
                                                                                                    _5519 += _5721;
                                                                                                    continue;
                                                                                                }
                                                                                                _5518++;
                                                                                                _5517 = _5519;
                                                                                                continue;
                                                                                            }
                                                                                            _5505 = _5516 / (isnan(9.9999997473787516355514526367188e-05) ? _5517 : (isnan(_5517) ? 9.9999997473787516355514526367188e-05 : max(_5517, 9.9999997473787516355514526367188e-05)));
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                            if (_5505 < 0.0)
                                                                            {
                                                                                _5755 = false;
                                                                                {
                                                                                    if (Globals.uShadowLevels <= 0)
                                                                                    {
                                                                                        _5755 = true;
                                                                                        _5756 = 1.0;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        vec3 _5779 = world + ((_417 * Globals.uClipmapOrigin.data[0].w) * 1.5);
                                                                                        vec3 _5780 = uLights_1._member0[_2434].xyz - _5779;
                                                                                        float _5781 = length(_5780);
                                                                                        float _5783 = _5781 - (isnan(Globals.uClipmapOrigin.data[0].w) ? 0.119999997317790985107421875 : (isnan(0.119999997317790985107421875) ? Globals.uClipmapOrigin.data[0].w : max(0.119999997317790985107421875, Globals.uClipmapOrigin.data[0].w)));
                                                                                        if (_5783 <= 0.0)
                                                                                        {
                                                                                            _5755 = true;
                                                                                            _5756 = 1.0;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            vec3 _5788 = _5780 / vec3(_5781);
                                                                                            int _5757 = 0;
                                                                                            float _5758 = 0.0;
                                                                                            for (;;)
                                                                                            {
                                                                                                if (_5757 < 48)
                                                                                                {
                                                                                                    _5759 = _5758 < _5783;
                                                                                                }
                                                                                                else
                                                                                                {
                                                                                                    _5759 = false;
                                                                                                }
                                                                                                if (!_5759)
                                                                                                {
                                                                                                    break;
                                                                                                }
                                                                                                vec3 _5805 = _5779 + (_5788 * _5758);
                                                                                                _5831 = false;
                                                                                                {
                                                                                                    _5760 = false;
                                                                                                    _5762 = Globals.uClipmapOrigin.data[0].w;
                                                                                                    int _5833 = 0;
                                                                                                    for (;;)
                                                                                                    {
                                                                                                        bool _5845_ladder_break = false;
                                                                                                        {
                                                                                                            if (!(_5833 < Globals.uShadowLevels))
                                                                                                            {
                                                                                                                _5845_ladder_break = true;
                                                                                                            }
                                                                                                            else
                                                                                                            {
                                                                                                                vec3 _5860 = (_5805 - Globals.uClipmapOrigin.data[_5833].xyz) / vec3(Globals.uClipmapOrigin.data[_5833].w);
                                                                                                                if (any(lessThan(_5860, vec3(0.5))))
                                                                                                                {
                                                                                                                    _5834 = true;
                                                                                                                }
                                                                                                                else
                                                                                                                {
                                                                                                                    _5834 = any(greaterThan(_5860, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                                                                }
                                                                                                                if (!(_5834))
                                                                                                                {
                                                                                                                    _5760 = true;
                                                                                                                    _5762 = Globals.uClipmapOrigin.data[_5833].w;
                                                                                                                    _5831 = true;
                                                                                                                    _5832 = ((textureLod(_6012, vec3(_5860.x / float(Globals.uShadowResolution), _5860.y / float(Globals.uShadowResolution), ((float(_5833) * float(Globals.uShadowResolution)) + _5860.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_5833];
                                                                                                                    _5845_ladder_break = true;
                                                                                                                }
                                                                                                            }
                                                                                                        }
                                                                                                        if (_5845_ladder_break)
                                                                                                        {
                                                                                                            break;
                                                                                                        }
                                                                                                        _5833++;
                                                                                                        continue;
                                                                                                    }
                                                                                                    if (!(_5831))
                                                                                                    {
                                                                                                        _5831 = true;
                                                                                                        _5832 = 1000000.0;
                                                                                                    }
                                                                                                }
                                                                                                if (!_5760)
                                                                                                {
                                                                                                    _5755 = true;
                                                                                                    _5756 = 1.0;
                                                                                                    break;
                                                                                                }
                                                                                                float _5932 = 2.0 * _5762;
                                                                                                if (_5832 < ((0.5 * _5762) * clamp(_5758 / (isnan(9.9999999747524270787835121154785e-07) ? _5932 : (isnan(_5932) ? 9.9999999747524270787835121154785e-07 : max(_5932, 9.9999999747524270787835121154785e-07))), 0.0, 1.0)))
                                                                                                {
                                                                                                    _5755 = true;
                                                                                                    _5756 = 0.0;
                                                                                                    break;
                                                                                                }
                                                                                                float _5817 = _5762 * 0.25;
                                                                                                _5757++;
                                                                                                _5758 += (isnan(_5817) ? _5832 : (isnan(_5832) ? _5817 : max(_5832, _5817)));
                                                                                                continue;
                                                                                            }
                                                                                            if (!(_5755))
                                                                                            {
                                                                                                _5755 = true;
                                                                                                _5756 = 1.0;
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                                reaches = _5756;
                                                                            }
                                                                            else
                                                                            {
                                                                                reaches = _5505;
                                                                            }
                                                                            if (!(reaches <= 0.0))
                                                                            {
                                                                                lit += (uLights_1._member0[_2437].xyz * (contribution * reaches));
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        if (_151_ladder_break)
                                                        {
                                                            break;
                                                        }
                                                        light++;
                                                        continue;
                                                    }
                                                    imageStore(uDirect, ivec2(uvec2(texelAt)), vec4(lit, 1.0));
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
        else
        {
            tile = slot;
            if (!(tile >= Globals.uTileCount))
            {
                ivec2 within = (uTiles_1._member0[tile].yz * ivec2(8)) + ivec2(gl_LocalInvocationID.xy);
                int at = uTiles_1._member0[tile].x * 10;
                int _230 = at + 5;
                if (!(uPages_1._member0[_230].w > 0.5))
                {
                    if (Globals.uActiveRadius > 0.0)
                    {
                        int _247 = at + 9;
                        vec3 toCentre = uPages_1._member0[_247].xyz - Globals.uActiveCentre;
                        float limit = Globals.uActiveRadius + uPages_1._member0[_247].w;
                        if (!(dot(toCentre, toCentre) > (limit * limit)))
                        {
                            int _267 = at + 1;
                            int _272 = int(uPages_1._member0[at].z);
                            bool _80;
                            if (within.x >= _272)
                            {
                                _80 = true;
                            }
                            else
                            {
                                _80 = within.y >= int(uPages_1._member0[at].w);
                            }
                            if (!(_80))
                            {
                                int _287 = at + 2;
                                int _291 = at + 3;
                                int _295 = at + 4;
                                int _300 = at + 6;
                                int _304 = at + 7;
                                int _307 = at + 8;
                                vec2 uv = (vec2(within) + vec2(0.5)) / vec2(uPages_1._member0[at].zw);
                                uvec2 _vecSize = uvec2(textureSize(_6004, 0));
                                vec2 cardUv = (uPages_1._member0[_267].xy + (uv * uPages_1._member0[_267].zw)) / vec2(float(_vecSize.x), float(_vecSize.y));
                                vec4 _sampled = textureLod(_6006, cardUv, 0.0);
                                ivec2 pageAt = ivec2(int(uPages_1._member0[at].x), int(uPages_1._member0[at].y));
                                if (_sampled.w < 0.5)
                                {
                                    imageStore(uDirect, ivec2(uvec2(pageAt + within)), vec4(0.0));
                                }
                                else
                                {
                                    vec3 _363 = normalize((textureLod(_6008, cardUv, 0.0).xyz * 2.0) - vec3(1.0));
                                    vec3 local = ((uPages_1._member0[_287].xyz + ((uPages_1._member0[_291].xyz * ((uv.x * 2.0) - 1.0)) * uPages_1._member0[_287].w)) + ((uPages_1._member0[_295].xyz * ((uv.y * 2.0) - 1.0)) * uPages_1._member0[_291].w)) - (uPages_1._member0[_230].xyz * (textureLod(_6010, cardUv, 0.0).x * uPages_1._member0[_295].w));
                                    vec3 _395 = vec3(uPages_1._member0[_300].x, uPages_1._member0[_304].x, uPages_1._member0[_307].x);
                                    vec3 _400 = vec3(uPages_1._member0[_300].y, uPages_1._member0[_304].y, uPages_1._member0[_307].y);
                                    vec3 _405 = vec3(uPages_1._member0[_300].z, uPages_1._member0[_304].z, uPages_1._member0[_307].z);
                                    vec3 world = vec3(dot(_395, local), dot(_400, local), dot(_405, local)) + vec3(uPages_1._member0[_300].w, uPages_1._member0[_304].w, uPages_1._member0[_307].w);
                                    vec3 _417 = normalize(vec3(dot(_395, _363), dot(_400, _363), dot(_405, _363)));
                                    ivec2 texelAt = pageAt + within;
                                    float visibility;
                                    if (Globals.uMode == 1)
                                    {
                                        if (((texelAt.x | texelAt.y) & 3) != 0)
                                        {
                                            imageStore(uDirect, ivec2(uvec2(texelAt)), vec4(0.0));
                                        }
                                        else
                                        {
                                            ivec2 probeCoord = texelAt >> ivec2(2);
                                            uProbePos._member0[(probeCoord.y * Globals.uProbeWidth) + probeCoord.x] = vec4(world, 1.0);
                                            vec2 _3036;
                                            {
                                                if (Globals.uTemporalIndex <= 0)
                                                {
                                                    _3036 = vec2(0.5);
                                                }
                                                else
                                                {
                                                    float _3051 = float(((uint(probeCoord.x) * 73856093u) ^ (uint(probeCoord.y) * 19349663u)) & 65535u);
                                                    int _3057 = (Globals.uTemporalIndex / max(Globals.uJitterStride, 1)) & 65535;
                                                    uint _3072 = uint(_3057);
                                                    uint _3075 = (_3072 << 16u) | (_3072 >> 16u);
                                                    uint _3080 = ((_3075 & 1431655765u) << 1u) | ((_3075 & 2863311530u) >> 1u);
                                                    uint _3085 = ((_3080 & 858993459u) << 2u) | ((_3080 & 3435973836u) >> 2u);
                                                    uint _3090 = ((_3085 & 252645135u) << 4u) | ((_3085 & 4042322160u) >> 4u);
                                                    _3036 = fract(vec2(fract(float(_3057) * 0.61803400516510009765625), float(((_3090 & 16711935u) << 8u) | ((_3090 & 4278255360u) >> 8u)) * 2.3283064365386962890625e-10) + vec2(_3051 * 1.52587890625e-05, fract(_3051 * 2.4689239580766297876834869384766e-05)));
                                                }
                                            }
                                            vec3 _3099;
                                            {
                                                bool _3100;
                                                if (Globals.uShadowLevels <= 0)
                                                {
                                                    _3100 = true;
                                                }
                                                else
                                                {
                                                    _3100 = Globals.uLookupBuckets <= 0;
                                                }
                                                if (_3100)
                                                {
                                                    _3099 = vec3(0.0);
                                                }
                                                else
                                                {
                                                    vec3 _5941;
                                                    vec3 _5942;
                                                    vec3 _5943;
                                                    {
                                                        vec3 _5956 = _417;
                                                        float _3228 = _417.z;
                                                        if (_3228 < (-0.99999988079071044921875))
                                                        {
                                                            _5941 = vec3(0.0, -1.0, 0.0);
                                                            _5942 = vec3(-1.0, 0.0, 0.0);
                                                            _5943 = _5956;
                                                        }
                                                        else
                                                        {
                                                            float _3236 = 1.0 / (1.0 + _3228);
                                                            float _3237 = _417.x;
                                                            float _3238 = -_3237;
                                                            float _3239 = _417.y;
                                                            float _3241 = (_3238 * _3239) * _3236;
                                                            _5941 = vec3(1.0 - ((_3237 * _3237) * _3236), _3241, _3238);
                                                            _5942 = vec3(_3241, 1.0 - ((_3239 * _3239) * _3236), -_3239);
                                                            _5943 = _5956;
                                                        }
                                                    }
                                                    int _3101 = 0;
                                                    vec4 _3102 = vec4(0.0);
                                                    vec4 _3103 = vec4(0.0);
                                                    vec4 _3104 = vec4(0.0);
                                                    vec3 _3106;
                                                    vec3 _3107;
                                                    vec2 _3109;
                                                    float _3273;
                                                    bool _3276;
                                                    bool _3277;
                                                    float _3279;
                                                    float _3354;
                                                    bool _3356;
                                                    bool _3468;
                                                    bool _3474;
                                                    ivec2 _3475;
                                                    bool _3479;
                                                    bool _3488;
                                                    bool _3489;
                                                    bool _3490;
                                                    bool _3491;
                                                    bool _3492;
                                                    ivec2 _3722;
                                                    for (;;)
                                                    {
                                                        if (!(_3101 < 16))
                                                        {
                                                            break;
                                                        }
                                                        int _3140 = _3101;
                                                        vec2 _3149 = (vec2(float(_3140 - 4 * (_3140 / 4)), float(_3140 / 4)) + _3036) * vec2(0.25);
                                                        float _3151 = 6.283185482025146484375 * _3149.x;
                                                        float _3152 = _3149.y;
                                                        float _3154 = 1.0 - (_3152 * _3152);
                                                        float _3156 = sqrt(isnan(_3154) ? 0.0 : (isnan(0.0) ? _3154 : max(0.0, _3154)));
                                                        vec3 _3271 = ((_5941 * (_3156 * cos(_3151))) + (_5942 * (_3156 * sin(_3151)))) + (_5943 * _3152);
                                                        _3272 = false;
                                                        {
                                                            _3106 = world;
                                                            if (Globals.uShadowLevels <= 0)
                                                            {
                                                                _3272 = true;
                                                                _3273 = 1.0;
                                                            }
                                                            else
                                                            {
                                                                vec3 _3296 = world + ((_417 * Globals.uClipmapOrigin.data[0].w) * 1.5);
                                                                float _3307 = (Globals.uClipmapOrigin.data[0].w * float(Globals.uShadowResolution)) * float(1 << (Globals.uShadowLevels - 1));
                                                                int _3274 = 0;
                                                                float _3275 = 0.0;
                                                                for (;;)
                                                                {
                                                                    if (_3274 < 64)
                                                                    {
                                                                        _3276 = _3275 < _3307;
                                                                    }
                                                                    else
                                                                    {
                                                                        _3276 = false;
                                                                    }
                                                                    if (!_3276)
                                                                    {
                                                                        break;
                                                                    }
                                                                    vec3 _3324 = _3296 + (_3271 * _3275);
                                                                    _3353 = false;
                                                                    {
                                                                        _3277 = false;
                                                                        _3279 = Globals.uClipmapOrigin.data[0].w;
                                                                        int _3355 = 0;
                                                                        for (;;)
                                                                        {
                                                                            bool _3367_ladder_break = false;
                                                                            {
                                                                                if (!(_3355 < Globals.uShadowLevels))
                                                                                {
                                                                                    _3367_ladder_break = true;
                                                                                }
                                                                                else
                                                                                {
                                                                                    vec3 _3382 = (_3324 - Globals.uClipmapOrigin.data[_3355].xyz) / vec3(Globals.uClipmapOrigin.data[_3355].w);
                                                                                    if (any(lessThan(_3382, vec3(0.5))))
                                                                                    {
                                                                                        _3356 = true;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        _3356 = any(greaterThan(_3382, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                                    }
                                                                                    if (!(_3356))
                                                                                    {
                                                                                        _3277 = true;
                                                                                        _3279 = Globals.uClipmapOrigin.data[_3355].w;
                                                                                        _3353 = true;
                                                                                        _3354 = ((textureLod(_6012, vec3(_3382.x / float(Globals.uShadowResolution), _3382.y / float(Globals.uShadowResolution), ((float(_3355) * float(Globals.uShadowResolution)) + _3382.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_3355];
                                                                                        _3367_ladder_break = true;
                                                                                    }
                                                                                }
                                                                            }
                                                                            if (_3367_ladder_break)
                                                                            {
                                                                                break;
                                                                            }
                                                                            _3355++;
                                                                            continue;
                                                                        }
                                                                        if (!(_3353))
                                                                        {
                                                                            _3353 = true;
                                                                            _3354 = 1000000.0;
                                                                        }
                                                                    }
                                                                    if (!_3277)
                                                                    {
                                                                        _3272 = true;
                                                                        _3273 = 1.0;
                                                                        break;
                                                                    }
                                                                    float _3454 = 2.0 * _3279;
                                                                    float _3458 = (0.5 * _3279) * clamp(_3275 / (isnan(9.9999999747524270787835121154785e-07) ? _3454 : (isnan(_3454) ? 9.9999999747524270787835121154785e-07 : max(_3454, 9.9999999747524270787835121154785e-07))), 0.0, 1.0);
                                                                    float _3460 = (_3275 + _3354) - _3458;
                                                                    float _3280 = isnan(0.0) ? _3460 : (isnan(_3460) ? 0.0 : max(_3460, 0.0));
                                                                    if (_3354 < _3458)
                                                                    {
                                                                        _3106 = _3296 + (_3271 * _3280);
                                                                        _3272 = true;
                                                                        _3273 = 0.0;
                                                                        break;
                                                                    }
                                                                    float _3339 = _3279 * 0.25;
                                                                    _3274++;
                                                                    _3275 += (isnan(_3339) ? _3354 : (isnan(_3354) ? _3339 : max(_3354, _3339)));
                                                                    continue;
                                                                }
                                                                if (!(_3272))
                                                                {
                                                                    _3272 = true;
                                                                    _3273 = 1.0;
                                                                }
                                                            }
                                                        }
                                                        if (_3273 <= 0.5)
                                                        {
                                                            {
                                                                _3109 = vec2(0.0);
                                                                float _3110 = 1000000000.0;
                                                                if (Globals.uLookupBuckets <= 0)
                                                                {
                                                                    _3468 = false;
                                                                }
                                                                else
                                                                {
                                                                    ivec3 _3509 = ivec3(floor((_3106 - Globals.uLookupMin) / vec3(Globals.uLookupCell)));
                                                                    int _3721 = int((((uint(_3509.x) * 2376512323u) ^ (uint(_3509.y) * 3625334849u)) ^ (uint(_3509.z) * 3407524639u)) & uint(Globals.uLookupBuckets - 1));
                                                                    uvec2 _3514 = uvec2(textureSize(_6004, 0));
                                                                    vec2 _3521 = vec2(float(_3514.x), float(_3514.y));
                                                                    bool _3471 = false;
                                                                    bool _3472 = false;
                                                                    int _3473 = 0;
                                                                    for (;;)
                                                                    {
                                                                        if (_3473 <= uCells_1._member0[Globals.uLookupBuckets].y)
                                                                        {
                                                                            _3474 = !_3471;
                                                                        }
                                                                        else
                                                                        {
                                                                            _3474 = false;
                                                                        }
                                                                        if (!_3474)
                                                                        {
                                                                            break;
                                                                        }
                                                                        bool _3541 = _3473 == 0;
                                                                        if (_3541)
                                                                        {
                                                                            _3475 = uCells_1._member0[_3721];
                                                                        }
                                                                        else
                                                                        {
                                                                            int _3726 = uCells_1._member0[Globals.uLookupBuckets].x + ((_3473 - 1) * 6);
                                                                            float _3742 = intBitsToFloat(uCellPages_1._member0[_3726 + 3]);
                                                                            vec3 _3744 = _3106 - vec3(intBitsToFloat(uCellPages_1._member0[_3726]), intBitsToFloat(uCellPages_1._member0[_3726 + 1]), intBitsToFloat(uCellPages_1._member0[_3726 + 2]));
                                                                            if (dot(_3744, _3744) > (_3742 * _3742))
                                                                            {
                                                                                _3722 = ivec2(0);
                                                                            }
                                                                            else
                                                                            {
                                                                                _3722 = ivec2(uCellPages_1._member0[_3726 + 4], uCellPages_1._member0[_3726 + 5]);
                                                                            }
                                                                            _3475 = _3722;
                                                                        }
                                                                        bool _3476 = _3471;
                                                                        bool _3477 = _3472;
                                                                        int _3478 = 0;
                                                                        for (;;)
                                                                        {
                                                                            bool _3553_ladder_break = false;
                                                                            {
                                                                                if (_3478 < _3475.y)
                                                                                {
                                                                                    _3479 = !_3476;
                                                                                }
                                                                                else
                                                                                {
                                                                                    _3479 = false;
                                                                                }
                                                                                if (!_3479)
                                                                                {
                                                                                    _3553_ladder_break = true;
                                                                                }
                                                                                else
                                                                                {
                                                                                    int _3570 = _3475.x + _3478;
                                                                                    int _3573 = uCellPages_1._member0[_3570] * 10;
                                                                                    if (!((uPages_1._member0[_3573 + 5].w > 0.5) == _3541))
                                                                                    {
                                                                                        int _3582 = _3573 + 9;
                                                                                        vec3 _3586 = _3106 - uPages_1._member0[_3582].xyz;
                                                                                        if (!(dot(_3586, _3586) > (uPages_1._member0[_3582].w * uPages_1._member0[_3582].w)))
                                                                                        {
                                                                                            vec3 _3593 = -_3271;
                                                                                            int _3760 = uCellPages_1._member0[_3570] * 10;
                                                                                            vec4 _3486 = uPages_1._member0[_3760];
                                                                                            vec4 _3487 = uPages_1._member0[_3760 + 1];
                                                                                            int _3766 = _3760 + 2;
                                                                                            int _3769 = _3760 + 3;
                                                                                            int _3772 = _3760 + 4;
                                                                                            int _3778 = _3760 + 6;
                                                                                            int _3781 = _3760 + 7;
                                                                                            int _3784 = _3760 + 8;
                                                                                            vec3 _3791 = _3106 - vec3(uPages_1._member0[_3778].w, uPages_1._member0[_3781].w, uPages_1._member0[_3784].w);
                                                                                            vec3 _3485 = vec3(dot(uPages_1._member0[_3778].xyz, _3593), dot(uPages_1._member0[_3781].xyz, _3593), dot(uPages_1._member0[_3784].xyz, _3593));
                                                                                            vec3 _3804 = vec3(dot(uPages_1._member0[_3778].xyz, _3791), dot(uPages_1._member0[_3781].xyz, _3791), dot(uPages_1._member0[_3784].xyz, _3791)) - uPages_1._member0[_3766].xyz;
                                                                                            vec2 _3807 = vec2(uPages_1._member0[_3766].w, uPages_1._member0[_3769].w);
                                                                                            bvec2 _6044 = isnan(_3807);
                                                                                            bvec2 _6045 = isnan(vec2(9.9999999747524270787835121154785e-07));
                                                                                            vec2 _6046 = max(_3807, vec2(9.9999999747524270787835121154785e-07));
                                                                                            vec2 _6047 = vec2(_6044.x ? vec2(9.9999999747524270787835121154785e-07).x : _6046.x, _6044.y ? vec2(9.9999999747524270787835121154785e-07).y : _6046.y);
                                                                                            vec2 _3814 = vec2(dot(_3804, uPages_1._member0[_3769].xyz), dot(_3804, uPages_1._member0[_3772].xyz)) / vec2(_6045.x ? _3807.x : _6047.x, _6045.y ? _3807.y : _6047.y);
                                                                                            vec2 _3480 = _3814;
                                                                                            float _3482 = -dot(_3804, uPages_1._member0[_3760 + 5].xyz);
                                                                                            float _3483 = uPages_1._member0[_3772].w;
                                                                                            vec3 _3484 = uPages_1._member0[_3760 + 5].xyz;
                                                                                            if (abs(_3814.x) > 1.0)
                                                                                            {
                                                                                                _3488 = true;
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                _3488 = abs(_3480.y) > 1.0;
                                                                                            }
                                                                                            if (!(_3488))
                                                                                            {
                                                                                                if (dot(_3271, _3271) > 0.5)
                                                                                                {
                                                                                                    _3489 = dot(_3484, _3485) < (-0.0500000007450580596923828125);
                                                                                                }
                                                                                                else
                                                                                                {
                                                                                                    _3489 = false;
                                                                                                }
                                                                                                if (!(_3489))
                                                                                                {
                                                                                                    if (_3482 < (-0.25))
                                                                                                    {
                                                                                                        _3490 = true;
                                                                                                    }
                                                                                                    else
                                                                                                    {
                                                                                                        _3490 = _3482 > (_3483 + 0.25);
                                                                                                    }
                                                                                                    if (!(_3490))
                                                                                                    {
                                                                                                        vec2 _3637 = (_3480 * 0.5) + vec2(0.5);
                                                                                                        vec2 _3644 = (_3487.xy + (_3637 * _3487.zw)) / _3521;
                                                                                                        if (!(textureLod(_6006, _3644, 0.0).w < 0.5))
                                                                                                        {
                                                                                                            float _3664 = abs((textureLod(_6010, _3644, 0.0).x * _3483) - _3482);
                                                                                                            if (_3664 < _3110)
                                                                                                            {
                                                                                                                _3110 = _3664;
                                                                                                                _3109 = (_3486.xy + (_3637 * _3486.zw)) / Globals.uAtlasSize.xy;
                                                                                                                _3491 = _3664 < 0.0199999995529651641845703125;
                                                                                                                _3492 = true;
                                                                                                            }
                                                                                                            else
                                                                                                            {
                                                                                                                _3491 = _3476;
                                                                                                                _3492 = _3477;
                                                                                                            }
                                                                                                            _3476 = _3491;
                                                                                                            _3477 = _3492;
                                                                                                        }
                                                                                                    }
                                                                                                }
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                            if (_3553_ladder_break)
                                                                            {
                                                                                break;
                                                                            }
                                                                            _3478++;
                                                                            continue;
                                                                        }
                                                                        _3471 = _3476;
                                                                        _3472 = _3477;
                                                                        _3473++;
                                                                        continue;
                                                                    }
                                                                    _3468 = _3472;
                                                                }
                                                            }
                                                            if (_3468)
                                                            {
                                                                _3107 = textureLod(_6014, _3109, 0.0).xyz * smoothstep(1.5 * Globals.uClipmapOrigin.data[0].w, 2.0 * Globals.uClipmapOrigin.data[0].w, length(_3106 - world));
                                                            }
                                                            else
                                                            {
                                                                _3107 = vec3(0.0);
                                                            }
                                                        }
                                                        else
                                                        {
                                                            _3107 = vec3(0.0);
                                                        }
                                                        vec4 _3827 = vec4(0.2820949852466583251953125, (-0.48860299587249755859375) * _3271.y, 0.48860299587249755859375 * _3271.z, (-0.48860299587249755859375) * _3271.x);
                                                        _3101++;
                                                        _3102 += (_3827 * _3107.x);
                                                        _3103 += (_3827 * _3107.y);
                                                        _3104 += (_3827 * _3107.z);
                                                        continue;
                                                    }
                                                    vec4 _3844 = vec4(0.2820949852466583251953125, (-0.48860299587249755859375) * _417.y, 0.48860299587249755859375 * _417.z, (-0.48860299587249755859375) * _417.x);
                                                    vec4 _3835 = vec4(_3844.x * 3.1415927410125732421875, _3844.yzw * 2.094395160675048828125);
                                                    vec3 _3217 = vec3(dot(_3102, _3835), dot(_3103, _3835), dot(_3104, _3835)) * 0.3926990926265716552734375;
                                                    bvec3 _6049 = isnan(_3217);
                                                    bvec3 _6050 = isnan(vec3(0.0));
                                                    vec3 _6051 = max(_3217, vec3(0.0));
                                                    vec3 _6052 = vec3(_6049.x ? vec3(0.0).x : _6051.x, _6049.y ? vec3(0.0).y : _6051.y, _6049.z ? vec3(0.0).z : _6051.z);
                                                    _3099 = vec3(_6050.x ? _3217.x : _6052.x, _6050.y ? _3217.y : _6052.y, _6050.z ? _3217.z : _6052.z);
                                                }
                                            }
                                            vec4 _sampled_1 = imageLoad(uDirect, texelAt);
                                            if (Globals.uTemporalIndex > 0)
                                            {
                                                visibility = _sampled_1.w;
                                            }
                                            else
                                            {
                                                visibility = 0.0;
                                            }
                                            float limit_1 = float(Globals.uMaxFrames);
                                            float _1575 = visibility + 1.0;
                                            float _1576 = limit_1 + 1.0;
                                            imageStore(uDirect, ivec2(uvec2(texelAt)), vec4(mix(_sampled_1.xyz, _3099, vec3(1.0 / (1.0 + (isnan(limit_1) ? visibility : (isnan(visibility) ? limit_1 : min(visibility, limit_1)))))), isnan(_1576) ? _1575 : (isnan(_1575) ? _1576 : min(_1575, _1576))));
                                        }
                                    }
                                    else
                                    {
                                        int light;
                                        vec3 lit;
                                        if (Globals.uMode == 2)
                                        {
                                            ivec2 _1593 = pageAt + ivec2(_272, int(uPages_1._member0[at].w));
                                            ivec2 probe00 = texelAt >> ivec2(2);
                                            vec2 _1604 = (vec2(texelAt - (probe00 * ivec2(4))) + vec2(1.0)) * vec2(0.16666667163372039794921875);
                                            light = 0;
                                            lit = vec3(0.0);
                                            visibility = 0.0;
                                            vec3 position;
                                            bool _3846;
                                            bool _3847;
                                            float _3896;
                                            vec3 _3914;
                                            bool _3973;
                                            bool _3974;
                                            float _4023;
                                            for (;;)
                                            {
                                                bool _126_ladder_break = false;
                                                {
                                                    if (!(light < 4))
                                                    {
                                                        _126_ladder_break = true;
                                                    }
                                                    else
                                                    {
                                                        ivec2 probeCoord_1 = probe00 + _1613_comp[light];
                                                        {
                                                            position = vec3(0.0);
                                                            if (any(lessThan(probeCoord_1, ivec2(0))))
                                                            {
                                                                _3847 = true;
                                                            }
                                                            else
                                                            {
                                                                _3847 = probeCoord_1.x >= Globals.uProbeWidth;
                                                            }
                                                            if (_3847)
                                                            {
                                                                _3847 = true;
                                                            }
                                                            else
                                                            {
                                                                _3847 = probeCoord_1.y >= Globals.uProbeHeight;
                                                            }
                                                            if (_3847)
                                                            {
                                                                _3846 = false;
                                                            }
                                                            else
                                                            {
                                                                ivec2 _3872 = probeCoord_1 * ivec2(4);
                                                                if (any(lessThan(_3872, pageAt)))
                                                                {
                                                                    _3847 = true;
                                                                }
                                                                else
                                                                {
                                                                    _3847 = any(greaterThanEqual(_3872, _1593));
                                                                }
                                                                if (_3847)
                                                                {
                                                                    _3846 = false;
                                                                }
                                                                else
                                                                {
                                                                    int _3888 = (probeCoord_1.y * Globals.uProbeWidth) + probeCoord_1.x;
                                                                    position = uProbePos._member0[_3888].xyz;
                                                                    _3846 = uProbePos._member0[_3888].w >= 0.5;
                                                                }
                                                            }
                                                        }
                                                        if (!(!_3846))
                                                        {
                                                            vec3 _3899 = world - position;
                                                            if ((abs(dot(_3899, _417)) / (length(_3899) + 0.00999999977648258209228515625)) < 0.257759988307952880859375)
                                                            {
                                                                _3896 = 1.0;
                                                            }
                                                            else
                                                            {
                                                                _3896 = 0.0;
                                                            }
                                                            if (!(_3896 <= 0.0))
                                                            {
                                                                vec2 _1737 = mix(vec2(1.0) - _1604, _1604, vec2(_1613_comp[light]));
                                                                float w = _1737.x * _1737.y;
                                                                int _3910 = 0;
                                                                vec3 _3911 = textureLod(_6019, (vec2(probeCoord_1 * ivec2(4)) + vec2(0.5)) / Globals.uAtlasSize.xy, 0.0).xyz * 2.0;
                                                                float _3912 = 2.0;
                                                                for (;;)
                                                                {
                                                                    bool _3921_ladder_break = false;
                                                                    {
                                                                        if (!(_3910 < 4))
                                                                        {
                                                                            _3921_ladder_break = true;
                                                                        }
                                                                        else
                                                                        {
                                                                            ivec2 _3930 = probeCoord_1 + _1798_comp[_3910];
                                                                            {
                                                                                _3914 = vec3(0.0);
                                                                                if (any(lessThan(_3930, ivec2(0))))
                                                                                {
                                                                                    _3974 = true;
                                                                                }
                                                                                else
                                                                                {
                                                                                    _3974 = _3930.x >= Globals.uProbeWidth;
                                                                                }
                                                                                if (_3974)
                                                                                {
                                                                                    _3974 = true;
                                                                                }
                                                                                else
                                                                                {
                                                                                    _3974 = _3930.y >= Globals.uProbeHeight;
                                                                                }
                                                                                if (_3974)
                                                                                {
                                                                                    _3973 = false;
                                                                                }
                                                                                else
                                                                                {
                                                                                    ivec2 _3999 = _3930 * ivec2(4);
                                                                                    if (any(lessThan(_3999, pageAt)))
                                                                                    {
                                                                                        _3974 = true;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        _3974 = any(greaterThanEqual(_3999, _1593));
                                                                                    }
                                                                                    if (_3974)
                                                                                    {
                                                                                        _3973 = false;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        int _4015 = (_3930.y * Globals.uProbeWidth) + _3930.x;
                                                                                        _3914 = uProbePos._member0[_4015].xyz;
                                                                                        _3973 = uProbePos._member0[_4015].w >= 0.5;
                                                                                    }
                                                                                }
                                                                            }
                                                                            if (!(!_3973))
                                                                            {
                                                                                vec3 _4026 = world - _3914;
                                                                                if ((abs(dot(_4026, _417)) / (length(_4026) + 0.00999999977648258209228515625)) < 0.257759988307952880859375)
                                                                                {
                                                                                    _4023 = 1.0;
                                                                                }
                                                                                else
                                                                                {
                                                                                    _4023 = 0.0;
                                                                                }
                                                                                if (!(_4023 <= 0.0))
                                                                                {
                                                                                    _3911 += textureLod(_6019, (vec2(_3930 * ivec2(4)) + vec2(0.5)) / Globals.uAtlasSize.xy, 0.0).xyz;
                                                                                    _3912 += 1.0;
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                    if (_3921_ladder_break)
                                                                    {
                                                                        break;
                                                                    }
                                                                    _3910++;
                                                                    continue;
                                                                }
                                                                lit += ((_3911 / vec3(_3912)) * w);
                                                                visibility += w;
                                                            }
                                                        }
                                                    }
                                                }
                                                if (_126_ladder_break)
                                                {
                                                    break;
                                                }
                                                light++;
                                                continue;
                                            }
                                            vec3 indirect;
                                            if (visibility > 0.0)
                                            {
                                                indirect = lit / vec3(visibility);
                                            }
                                            else
                                            {
                                                indirect = textureLod(_6019, (vec2(probe00 * ivec2(4)) + vec2(0.5)) / Globals.uAtlasSize.xy, 0.0).xyz;
                                            }
                                            vec3 _1862 = _sampled.xyz;
                                            vec3 _4072;
                                            {
                                                if (Globals.uBoost >= 1.0)
                                                {
                                                    _4072 = _1862;
                                                }
                                                else
                                                {
                                                    float _4079 = dot(_1862, vec3(0.300000011920928955078125, 0.589999973773956298828125, 0.10999999940395355224609375));
                                                    vec3 _4091 = clamp(_1862 * (pow(isnan(0.0) ? _4079 : (isnan(_4079) ? 0.0 : max(_4079, 0.0)), Globals.uBoost) / (isnan(9.9999999392252902907785028219223e-09) ? _4079 : (isnan(_4079) ? 9.9999999392252902907785028219223e-09 : max(_4079, 9.9999999392252902907785028219223e-09)))), vec3(0.0), vec3(1.0));
                                                    bvec3 _6074 = isnan(_4091);
                                                    bvec3 _6075 = isnan(vec3(0.9900000095367431640625));
                                                    vec3 _6076 = min(_4091, vec3(0.9900000095367431640625));
                                                    vec3 _6077 = vec3(_6074.x ? vec3(0.9900000095367431640625).x : _6076.x, _6074.y ? vec3(0.9900000095367431640625).y : _6076.y, _6074.z ? vec3(0.9900000095367431640625).z : _6076.z);
                                                    _4072 = vec3(_6075.x ? _4091.x : _6077.x, _6075.y ? _4091.y : _6077.y, _6075.z ? _4091.z : _6077.z);
                                                }
                                            }
                                            imageStore(uDirect, ivec2(uvec2(texelAt)), vec4((texelFetch(_6017, ivec3(texelAt, 0).xy, 0).xyz + indirect) * (_4072 * vec3(0.3183098733425140380859375)), 1.0));
                                        }
                                        else
                                        {
                                            if (Globals.uMode == 3)
                                            {
                                                vec3 _1920 = _sampled.xyz;
                                                vec3 _4093;
                                                {
                                                    if (Globals.uBoost >= 1.0)
                                                    {
                                                        _4093 = _1920;
                                                    }
                                                    else
                                                    {
                                                        float _4100 = dot(_1920, vec3(0.300000011920928955078125, 0.589999973773956298828125, 0.10999999940395355224609375));
                                                        vec3 _4112 = clamp(_1920 * (pow(isnan(0.0) ? _4100 : (isnan(_4100) ? 0.0 : max(_4100, 0.0)), Globals.uBoost) / (isnan(9.9999999392252902907785028219223e-09) ? _4100 : (isnan(_4100) ? 9.9999999392252902907785028219223e-09 : max(_4100, 9.9999999392252902907785028219223e-09)))), vec3(0.0), vec3(1.0));
                                                        bvec3 _6089 = isnan(_4112);
                                                        bvec3 _6090 = isnan(vec3(0.9900000095367431640625));
                                                        vec3 _6091 = min(_4112, vec3(0.9900000095367431640625));
                                                        vec3 _6092 = vec3(_6089.x ? vec3(0.9900000095367431640625).x : _6091.x, _6089.y ? vec3(0.9900000095367431640625).y : _6091.y, _6089.z ? vec3(0.9900000095367431640625).z : _6091.z);
                                                        _4093 = vec3(_6090.x ? _4112.x : _6092.x, _6090.y ? _4112.y : _6092.y, _6090.z ? _4112.z : _6092.z);
                                                    }
                                                }
                                                imageStore(uDirect, ivec2(uvec2(texelAt)), vec4(texelFetch(_6017, ivec3(texelAt, 0).xy, 0).xyz * (_4093 * vec3(0.3183098733425140380859375)), 1.0));
                                            }
                                            else
                                            {
                                                if (Globals.uProbe != 0)
                                                {
                                                    vec4 _4114;
                                                    {
                                                        if (Globals.uProbe == 5)
                                                        {
                                                            if (((texelAt.x | texelAt.y) & 7) != 0)
                                                            {
                                                                _4114 = vec4(0.0);
                                                            }
                                                            else
                                                            {
                                                                vec2 _4115;
                                                                bool _4237;
                                                                {
                                                                    _4115 = vec2(0.0);
                                                                    float _4117 = 1000000000.0;
                                                                    if (Globals.uLookupBuckets <= 0)
                                                                    {
                                                                        _4237 = false;
                                                                    }
                                                                    else
                                                                    {
                                                                        ivec3 _4278 = ivec3(floor((world - Globals.uLookupMin) / vec3(Globals.uLookupCell)));
                                                                        int _4490 = int((((uint(_4278.x) * 2376512323u) ^ (uint(_4278.y) * 3625334849u)) ^ (uint(_4278.z) * 3407524639u)) & uint(Globals.uLookupBuckets - 1));
                                                                        uvec2 _4283 = uvec2(textureSize(_6004, 0));
                                                                        vec2 _4290 = vec2(float(_4283.x), float(_4283.y));
                                                                        bool _4240 = false;
                                                                        bool _4241 = false;
                                                                        int _4242 = 0;
                                                                        bool _4243;
                                                                        ivec2 _4244;
                                                                        bool _4248;
                                                                        bool _4257;
                                                                        bool _4258;
                                                                        bool _4259;
                                                                        bool _4260;
                                                                        bool _4261;
                                                                        ivec2 _4491;
                                                                        for (;;)
                                                                        {
                                                                            if (_4242 <= uCells_1._member0[Globals.uLookupBuckets].y)
                                                                            {
                                                                                _4243 = !_4240;
                                                                            }
                                                                            else
                                                                            {
                                                                                _4243 = false;
                                                                            }
                                                                            if (!_4243)
                                                                            {
                                                                                break;
                                                                            }
                                                                            bool _4310 = _4242 == 0;
                                                                            if (_4310)
                                                                            {
                                                                                _4244 = uCells_1._member0[_4490];
                                                                            }
                                                                            else
                                                                            {
                                                                                int _4495 = uCells_1._member0[Globals.uLookupBuckets].x + ((_4242 - 1) * 6);
                                                                                float _4511 = intBitsToFloat(uCellPages_1._member0[_4495 + 3]);
                                                                                vec3 _4513 = world - vec3(intBitsToFloat(uCellPages_1._member0[_4495]), intBitsToFloat(uCellPages_1._member0[_4495 + 1]), intBitsToFloat(uCellPages_1._member0[_4495 + 2]));
                                                                                if (dot(_4513, _4513) > (_4511 * _4511))
                                                                                {
                                                                                    _4491 = ivec2(0);
                                                                                }
                                                                                else
                                                                                {
                                                                                    _4491 = ivec2(uCellPages_1._member0[_4495 + 4], uCellPages_1._member0[_4495 + 5]);
                                                                                }
                                                                                _4244 = _4491;
                                                                            }
                                                                            bool _4245 = _4240;
                                                                            bool _4246 = _4241;
                                                                            int _4247 = 0;
                                                                            for (;;)
                                                                            {
                                                                                bool _4322_ladder_break = false;
                                                                                {
                                                                                    if (_4247 < _4244.y)
                                                                                    {
                                                                                        _4248 = !_4245;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        _4248 = false;
                                                                                    }
                                                                                    if (!_4248)
                                                                                    {
                                                                                        _4322_ladder_break = true;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        int _4339 = _4244.x + _4247;
                                                                                        int _4342 = uCellPages_1._member0[_4339] * 10;
                                                                                        if (!((uPages_1._member0[_4342 + 5].w > 0.5) == _4310))
                                                                                        {
                                                                                            int _4351 = _4342 + 9;
                                                                                            vec3 _4355 = world - uPages_1._member0[_4351].xyz;
                                                                                            if (!(dot(_4355, _4355) > (uPages_1._member0[_4351].w * uPages_1._member0[_4351].w)))
                                                                                            {
                                                                                                int _4529 = uCellPages_1._member0[_4339] * 10;
                                                                                                vec4 _4256 = uPages_1._member0[_4529 + 1];
                                                                                                int _4535 = _4529 + 2;
                                                                                                int _4538 = _4529 + 3;
                                                                                                int _4541 = _4529 + 4;
                                                                                                int _4547 = _4529 + 6;
                                                                                                int _4550 = _4529 + 7;
                                                                                                int _4553 = _4529 + 8;
                                                                                                vec3 _4560 = world - vec3(uPages_1._member0[_4547].w, uPages_1._member0[_4550].w, uPages_1._member0[_4553].w);
                                                                                                vec3 _4254 = vec3(dot(uPages_1._member0[_4547].xyz, vec3(-0.0)), dot(uPages_1._member0[_4550].xyz, vec3(-0.0)), dot(uPages_1._member0[_4553].xyz, vec3(-0.0)));
                                                                                                vec3 _4573 = vec3(dot(uPages_1._member0[_4547].xyz, _4560), dot(uPages_1._member0[_4550].xyz, _4560), dot(uPages_1._member0[_4553].xyz, _4560)) - uPages_1._member0[_4535].xyz;
                                                                                                vec2 _4576 = vec2(uPages_1._member0[_4535].w, uPages_1._member0[_4538].w);
                                                                                                bvec2 _6094 = isnan(_4576);
                                                                                                bvec2 _6095 = isnan(vec2(9.9999999747524270787835121154785e-07));
                                                                                                vec2 _6096 = max(_4576, vec2(9.9999999747524270787835121154785e-07));
                                                                                                vec2 _6097 = vec2(_6094.x ? vec2(9.9999999747524270787835121154785e-07).x : _6096.x, _6094.y ? vec2(9.9999999747524270787835121154785e-07).y : _6096.y);
                                                                                                vec2 _4583 = vec2(dot(_4573, uPages_1._member0[_4538].xyz), dot(_4573, uPages_1._member0[_4541].xyz)) / vec2(_6095.x ? _4576.x : _6097.x, _6095.y ? _4576.y : _6097.y);
                                                                                                vec2 _4249 = _4583;
                                                                                                float _4251 = -dot(_4573, uPages_1._member0[_4529 + 5].xyz);
                                                                                                float _4252 = uPages_1._member0[_4541].w;
                                                                                                vec3 _4253 = uPages_1._member0[_4529 + 5].xyz;
                                                                                                if (abs(_4583.x) > 1.0)
                                                                                                {
                                                                                                    _4257 = true;
                                                                                                }
                                                                                                else
                                                                                                {
                                                                                                    _4257 = abs(_4249.y) > 1.0;
                                                                                                }
                                                                                                if (!(_4257))
                                                                                                {
                                                                                                    if (false)
                                                                                                    {
                                                                                                        _4258 = dot(_4253, _4254) < (-0.0500000007450580596923828125);
                                                                                                    }
                                                                                                    else
                                                                                                    {
                                                                                                        _4258 = false;
                                                                                                    }
                                                                                                    if (!(_4258))
                                                                                                    {
                                                                                                        if (_4251 < (-0.25))
                                                                                                        {
                                                                                                            _4259 = true;
                                                                                                        }
                                                                                                        else
                                                                                                        {
                                                                                                            _4259 = _4251 > (_4252 + 0.25);
                                                                                                        }
                                                                                                        if (!(_4259))
                                                                                                        {
                                                                                                            vec2 _4413 = (_4256.xy + (((_4249 * 0.5) + vec2(0.5)) * _4256.zw)) / _4290;
                                                                                                            if (!(textureLod(_6006, _4413, 0.0).w < 0.5))
                                                                                                            {
                                                                                                                float _4433 = abs((textureLod(_6010, _4413, 0.0).x * _4252) - _4251);
                                                                                                                if (_4433 < _4117)
                                                                                                                {
                                                                                                                    _4117 = _4433;
                                                                                                                    _4115 = _4413;
                                                                                                                    _4260 = _4433 < 0.0199999995529651641845703125;
                                                                                                                    _4261 = true;
                                                                                                                }
                                                                                                                else
                                                                                                                {
                                                                                                                    _4260 = _4245;
                                                                                                                    _4261 = _4246;
                                                                                                                }
                                                                                                                _4245 = _4260;
                                                                                                                _4246 = _4261;
                                                                                                            }
                                                                                                        }
                                                                                                    }
                                                                                                }
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                                if (_4322_ladder_break)
                                                                                {
                                                                                    break;
                                                                                }
                                                                                _4247++;
                                                                                continue;
                                                                            }
                                                                            _4240 = _4245;
                                                                            _4241 = _4246;
                                                                            _4242++;
                                                                            continue;
                                                                        }
                                                                        _4237 = _4241;
                                                                    }
                                                                }
                                                                if (!_4237)
                                                                {
                                                                    _4114 = vec4(1.0, 0.0, 0.0, 1.0);
                                                                }
                                                                else
                                                                {
                                                                    uvec2 _4146 = uvec2(textureSize(_6004, 0));
                                                                    vec2 _4157 = abs(_4115 - cardUv) * vec2(float(_4146.x), float(_4146.y));
                                                                    float _4158 = _4157.x;
                                                                    float _4159 = _4157.y;
                                                                    vec4 _4120;
                                                                    if ((isnan(_4159) ? _4158 : (isnan(_4158) ? _4159 : max(_4158, _4159))) < 1.5)
                                                                    {
                                                                        _4120 = vec4(0.0, 1.0, 0.0, 1.0);
                                                                    }
                                                                    else
                                                                    {
                                                                        _4120 = vec4(1.0, 1.0, 0.0, 1.0);
                                                                    }
                                                                    _4114 = _4120;
                                                                }
                                                            }
                                                        }
                                                        else
                                                        {
                                                            if (Globals.uProbe == 4)
                                                            {
                                                                _4588 = false;
                                                                vec4 _4589;
                                                                {
                                                                    int _4608 = max((Globals.uShadowLevels - 1), 0);
                                                                    vec3 _4614 = world + ((_417 * Globals.uClipmapOrigin.data[0].w) * 1.5);
                                                                    float _4623 = (Globals.uClipmapOrigin.data[0].w * float(Globals.uShadowResolution)) * float(1 << (Globals.uShadowLevels - 1));
                                                                    int _4590 = 0;
                                                                    float _4591 = 0.0;
                                                                    bool _4592;
                                                                    bool _4593;
                                                                    float _4595;
                                                                    float _4681;
                                                                    bool _4683;
                                                                    for (;;)
                                                                    {
                                                                        if (_4590 < 64)
                                                                        {
                                                                            _4592 = _4591 < _4623;
                                                                        }
                                                                        else
                                                                        {
                                                                            _4592 = false;
                                                                        }
                                                                        if (!_4592)
                                                                        {
                                                                            break;
                                                                        }
                                                                        vec3 _4642 = _4614 + (Globals.uSunDirection * _4591);
                                                                        _4680 = false;
                                                                        {
                                                                            _4593 = false;
                                                                            _4595 = Globals.uClipmapOrigin.data[0].w;
                                                                            int _4682 = 0;
                                                                            for (;;)
                                                                            {
                                                                                bool _4694_ladder_break = false;
                                                                                {
                                                                                    if (!(_4682 < Globals.uShadowLevels))
                                                                                    {
                                                                                        _4694_ladder_break = true;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        vec3 _4709 = (_4642 - Globals.uClipmapOrigin.data[_4682].xyz) / vec3(Globals.uClipmapOrigin.data[_4682].w);
                                                                                        if (any(lessThan(_4709, vec3(0.5))))
                                                                                        {
                                                                                            _4683 = true;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            _4683 = any(greaterThan(_4709, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                                        }
                                                                                        if (!(_4683))
                                                                                        {
                                                                                            _4593 = true;
                                                                                            _4595 = Globals.uClipmapOrigin.data[_4682].w;
                                                                                            _4680 = true;
                                                                                            _4681 = ((textureLod(_6012, vec3(_4709.x / float(Globals.uShadowResolution), _4709.y / float(Globals.uShadowResolution), ((float(_4682) * float(Globals.uShadowResolution)) + _4709.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_4682];
                                                                                            _4694_ladder_break = true;
                                                                                        }
                                                                                    }
                                                                                }
                                                                                if (_4694_ladder_break)
                                                                                {
                                                                                    break;
                                                                                }
                                                                                _4682++;
                                                                                continue;
                                                                            }
                                                                            if (!(_4680))
                                                                            {
                                                                                _4680 = true;
                                                                                _4681 = 1000000.0;
                                                                            }
                                                                        }
                                                                        if (!_4593)
                                                                        {
                                                                            _4588 = true;
                                                                            _4589 = vec4(1.0, 0.0, _4591 / _4623, 1.0);
                                                                            break;
                                                                        }
                                                                        float _4781 = 2.0 * _4595;
                                                                        if (_4681 < ((0.5 * _4595) * clamp(_4591 / (isnan(9.9999999747524270787835121154785e-07) ? _4781 : (isnan(_4781) ? 9.9999999747524270787835121154785e-07 : max(_4781, 9.9999999747524270787835121154785e-07))), 0.0, 1.0)))
                                                                        {
                                                                            _4588 = true;
                                                                            _4589 = vec4(0.0, _4595 / Globals.uClipmapOrigin.data[_4608].w, _4591 / _4623, 1.0);
                                                                            break;
                                                                        }
                                                                        float _4662 = _4595 * 0.25;
                                                                        _4590++;
                                                                        _4591 += (isnan(_4662) ? _4681 : (isnan(_4681) ? _4662 : max(_4681, _4662)));
                                                                        continue;
                                                                    }
                                                                    if (!(_4588))
                                                                    {
                                                                        _4588 = true;
                                                                        _4589 = vec4(0.5, 0.0, clamp(_4591 / _4623, 0.0, 1.0), 1.0);
                                                                    }
                                                                }
                                                                _4114 = _4589;
                                                            }
                                                            else
                                                            {
                                                                if (Globals.uProbe == 2)
                                                                {
                                                                    _4114 = vec4(clamp((world - Globals.uProbeMin) * Globals.uProbeInvExtent, vec3(0.0), vec3(1.0)), 1.0);
                                                                }
                                                                else
                                                                {
                                                                    if (Globals.uProbe == 3)
                                                                    {
                                                                        _4114 = vec4((_417 * 0.5) + vec3(0.5), 1.0);
                                                                    }
                                                                    else
                                                                    {
                                                                        vec3 _4199 = world + ((_417 * Globals.uClipmapOrigin.data[0].w) * 1.5);
                                                                        _4790 = false;
                                                                        bool _4121;
                                                                        float _4122;
                                                                        float _4791;
                                                                        {
                                                                            _4121 = false;
                                                                            _4122 = 0.0;
                                                                            int _4792 = 0;
                                                                            bool _4793;
                                                                            for (;;)
                                                                            {
                                                                                bool _4804_ladder_break = false;
                                                                                {
                                                                                    if (!(_4792 < Globals.uShadowLevels))
                                                                                    {
                                                                                        _4804_ladder_break = true;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        vec3 _4819 = (_4199 - Globals.uClipmapOrigin.data[_4792].xyz) / vec3(Globals.uClipmapOrigin.data[_4792].w);
                                                                                        if (any(lessThan(_4819, vec3(0.5))))
                                                                                        {
                                                                                            _4793 = true;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            _4793 = any(greaterThan(_4819, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                                        }
                                                                                        if (!(_4793))
                                                                                        {
                                                                                            _4121 = true;
                                                                                            vec4 _4866 = textureLod(_6012, vec3(_4819.x / float(Globals.uShadowResolution), _4819.y / float(Globals.uShadowResolution), ((float(_4792) * float(Globals.uShadowResolution)) + _4819.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0);
                                                                                            float _4868 = _4866.x;
                                                                                            _4122 = _4868;
                                                                                            _4790 = true;
                                                                                            _4791 = ((_4868 * 2.0) - 1.0) * Globals.uClipmapRange.data[_4792];
                                                                                            _4804_ladder_break = true;
                                                                                        }
                                                                                    }
                                                                                }
                                                                                if (_4804_ladder_break)
                                                                                {
                                                                                    break;
                                                                                }
                                                                                _4792++;
                                                                                continue;
                                                                            }
                                                                            if (!(_4790))
                                                                            {
                                                                                _4790 = true;
                                                                                _4791 = 1000000.0;
                                                                            }
                                                                        }
                                                                        float _4124;
                                                                        if (Globals.uShadowLevels > 0)
                                                                        {
                                                                            _4124 = clamp(Globals.uClipmapRange.data[0] / (Globals.uClipmapOrigin.data[0].w * 4.0), 0.0, 1.0);
                                                                        }
                                                                        else
                                                                        {
                                                                            _4124 = 0.0;
                                                                        }
                                                                        float _4125;
                                                                        if (_4121)
                                                                        {
                                                                            _4125 = clamp(_4791 / (Globals.uClipmapOrigin.data[0].w * 4.0), 0.0, 1.0);
                                                                        }
                                                                        else
                                                                        {
                                                                            _4125 = 1.0;
                                                                        }
                                                                        float _4126;
                                                                        if (_4121)
                                                                        {
                                                                            _4126 = 1.0;
                                                                        }
                                                                        else
                                                                        {
                                                                            _4126 = 0.5;
                                                                        }
                                                                        _4114 = vec4(_4124, _4122, _4125, _4126);
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                    imageStore(uDirect, ivec2(uvec2(texelAt)), _4114);
                                                }
                                                else
                                                {
                                                    float _2222 = dot(_417, Globals.uSunDirection);
                                                    float _2223 = isnan(0.0) ? _2222 : (isnan(_2222) ? 0.0 : max(_2222, 0.0));
                                                    if (_2223 > 0.0)
                                                    {
                                                        _4897 = false;
                                                        float _4898;
                                                        {
                                                            if (Globals.uShadowLevels <= 0)
                                                            {
                                                                _4897 = true;
                                                                _4898 = 1.0;
                                                            }
                                                            else
                                                            {
                                                                vec3 _4921 = world + ((_417 * Globals.uClipmapOrigin.data[0].w) * 1.5);
                                                                float _4932 = (Globals.uClipmapOrigin.data[0].w * float(Globals.uShadowResolution)) * float(1 << (Globals.uShadowLevels - 1));
                                                                int _4899 = 0;
                                                                float _4900 = 0.0;
                                                                bool _4901;
                                                                bool _4902;
                                                                float _4904;
                                                                float _4979;
                                                                bool _4981;
                                                                for (;;)
                                                                {
                                                                    if (_4899 < 64)
                                                                    {
                                                                        _4901 = _4900 < _4932;
                                                                    }
                                                                    else
                                                                    {
                                                                        _4901 = false;
                                                                    }
                                                                    if (!_4901)
                                                                    {
                                                                        break;
                                                                    }
                                                                    vec3 _4949 = _4921 + (Globals.uSunDirection * _4900);
                                                                    _4978 = false;
                                                                    {
                                                                        _4902 = false;
                                                                        _4904 = Globals.uClipmapOrigin.data[0].w;
                                                                        int _4980 = 0;
                                                                        for (;;)
                                                                        {
                                                                            bool _4992_ladder_break = false;
                                                                            {
                                                                                if (!(_4980 < Globals.uShadowLevels))
                                                                                {
                                                                                    _4992_ladder_break = true;
                                                                                }
                                                                                else
                                                                                {
                                                                                    vec3 _5007 = (_4949 - Globals.uClipmapOrigin.data[_4980].xyz) / vec3(Globals.uClipmapOrigin.data[_4980].w);
                                                                                    if (any(lessThan(_5007, vec3(0.5))))
                                                                                    {
                                                                                        _4981 = true;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        _4981 = any(greaterThan(_5007, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                                    }
                                                                                    if (!(_4981))
                                                                                    {
                                                                                        _4902 = true;
                                                                                        _4904 = Globals.uClipmapOrigin.data[_4980].w;
                                                                                        _4978 = true;
                                                                                        _4979 = ((textureLod(_6012, vec3(_5007.x / float(Globals.uShadowResolution), _5007.y / float(Globals.uShadowResolution), ((float(_4980) * float(Globals.uShadowResolution)) + _5007.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_4980];
                                                                                        _4992_ladder_break = true;
                                                                                    }
                                                                                }
                                                                            }
                                                                            if (_4992_ladder_break)
                                                                            {
                                                                                break;
                                                                            }
                                                                            _4980++;
                                                                            continue;
                                                                        }
                                                                        if (!(_4978))
                                                                        {
                                                                            _4978 = true;
                                                                            _4979 = 1000000.0;
                                                                        }
                                                                    }
                                                                    if (!_4902)
                                                                    {
                                                                        _4897 = true;
                                                                        _4898 = 1.0;
                                                                        break;
                                                                    }
                                                                    float _5079 = 2.0 * _4904;
                                                                    if (_4979 < ((0.5 * _4904) * clamp(_4900 / (isnan(9.9999999747524270787835121154785e-07) ? _5079 : (isnan(_5079) ? 9.9999999747524270787835121154785e-07 : max(_5079, 9.9999999747524270787835121154785e-07))), 0.0, 1.0)))
                                                                    {
                                                                        _4897 = true;
                                                                        _4898 = 0.0;
                                                                        break;
                                                                    }
                                                                    float _4964 = _4904 * 0.25;
                                                                    _4899++;
                                                                    _4900 += (isnan(_4964) ? _4979 : (isnan(_4979) ? _4964 : max(_4979, _4964)));
                                                                    continue;
                                                                }
                                                                if (!(_4897))
                                                                {
                                                                    _4897 = true;
                                                                    _4898 = 1.0;
                                                                }
                                                            }
                                                        }
                                                        visibility = _4898;
                                                    }
                                                    else
                                                    {
                                                        visibility = 1.0;
                                                    }
                                                    vec3 _5089;
                                                    {
                                                        if (Globals.uShadowLevels <= 0)
                                                        {
                                                            vec3 _5170;
                                                            {
                                                                if (Globals.uSkyShValid == 0)
                                                                {
                                                                    _5170 = Globals.uSkyColour * ((_417.z * 0.5) + 0.5);
                                                                }
                                                                else
                                                                {
                                                                    vec4 _5185 = vec4(_417, 1.0);
                                                                    vec4 _5188 = _5185.xyzz * _5185.yzzx;
                                                                    float _5214 = _417.x;
                                                                    float _5216 = _417.y;
                                                                    vec3 _5221 = (vec3(dot(Globals.uSkySh.data[0], _5185), dot(Globals.uSkySh.data[1], _5185), dot(Globals.uSkySh.data[2], _5185)) + vec3(dot(Globals.uSkySh.data[3], _5188), dot(Globals.uSkySh.data[4], _5188), dot(Globals.uSkySh.data[5], _5188))) + (Globals.uSkySh.data[6].xyz * ((_5214 * _5214) - (_5216 * _5216)));
                                                                    bvec3 _6129 = isnan(vec3(0.0));
                                                                    bvec3 _6130 = isnan(_5221);
                                                                    vec3 _6131 = max(vec3(0.0), _5221);
                                                                    vec3 _6132 = vec3(_6129.x ? _5221.x : _6131.x, _6129.y ? _5221.y : _6131.y, _6129.z ? _5221.z : _6131.z);
                                                                    _5170 = vec3(_6130.x ? vec3(0.0).x : _6132.x, _6130.y ? vec3(0.0).y : _6132.y, _6130.z ? vec3(0.0).z : _6132.z);
                                                                }
                                                            }
                                                            _5089 = _5170 * 3.1415927410125732421875;
                                                        }
                                                        else
                                                        {
                                                            vec3 _5090;
                                                            if (abs(_417.z) < 0.89999997615814208984375)
                                                            {
                                                                _5090 = vec3(0.0, 0.0, 1.0);
                                                            }
                                                            else
                                                            {
                                                                _5090 = vec3(1.0, 0.0, 0.0);
                                                            }
                                                            vec3 _5111 = normalize(cross(_417, _5090));
                                                            vec3 _5112 = cross(_417, _5111);
                                                            vec3 _5114 = floor(world * 8.0);
                                                            float _5118 = fract(sin(dot(_5114, vec3(12.98980045318603515625, 78.233001708984375, 37.71900177001953125))) * 43758.546875);
                                                            float _5122 = fract(sin(dot(_5114, vec3(39.34600067138671875, 11.1350002288818359375, 83.154998779296875))) * 24634.634765625);
                                                            int _5092 = 0;
                                                            vec3 _5091 = vec3(0.0);
                                                            vec3 _5254;
                                                            float _5314;
                                                            bool _5317;
                                                            bool _5318;
                                                            float _5320;
                                                            float _5395;
                                                            bool _5397;
                                                            for (;;)
                                                            {
                                                                if (!(_5092 < 8))
                                                                {
                                                                    break;
                                                                }
                                                                float _5134 = (float(_5092) + _5122) * 0.125;
                                                                uint _5227 = uint(_5092);
                                                                uint _5230 = (_5227 << 16u) | (_5227 >> 16u);
                                                                uint _5235 = ((_5230 & 1431655765u) << 1u) | ((_5230 & 2863311530u) >> 1u);
                                                                uint _5240 = ((_5235 & 858993459u) << 2u) | ((_5235 & 3435973836u) >> 2u);
                                                                uint _5245 = ((_5240 & 252645135u) << 4u) | ((_5240 & 4042322160u) >> 4u);
                                                                float _5139 = sqrt(_5134);
                                                                float _5140 = 6.283185482025146484375 * fract((float(((_5245 & 16711935u) << 8u) | ((_5245 & 4278255360u) >> 8u)) * 2.3283064365386962890625e-10) + _5118);
                                                                float _5148 = 1.0 - _5134;
                                                                vec3 _5153 = normalize(((_5111 * (_5139 * cos(_5140))) + (_5112 * (_5139 * sin(_5140)))) + (_417 * sqrt(isnan(_5148) ? 0.0 : (isnan(0.0) ? _5148 : max(0.0, _5148)))));
                                                                {
                                                                    if (Globals.uSkyShValid == 0)
                                                                    {
                                                                        _5254 = Globals.uSkyColour * ((_5153.z * 0.5) + 0.5);
                                                                    }
                                                                    else
                                                                    {
                                                                        vec4 _5269 = vec4(_5153, 1.0);
                                                                        vec4 _5272 = _5269.xyzz * _5269.yzzx;
                                                                        float _5298 = _5153.x;
                                                                        float _5300 = _5153.y;
                                                                        vec3 _5305 = (vec3(dot(Globals.uSkySh.data[0], _5269), dot(Globals.uSkySh.data[1], _5269), dot(Globals.uSkySh.data[2], _5269)) + vec3(dot(Globals.uSkySh.data[3], _5272), dot(Globals.uSkySh.data[4], _5272), dot(Globals.uSkySh.data[5], _5272))) + (Globals.uSkySh.data[6].xyz * ((_5298 * _5298) - (_5300 * _5300)));
                                                                        bvec3 _6139 = isnan(vec3(0.0));
                                                                        bvec3 _6140 = isnan(_5305);
                                                                        vec3 _6141 = max(vec3(0.0), _5305);
                                                                        vec3 _6142 = vec3(_6139.x ? _5305.x : _6141.x, _6139.y ? _5305.y : _6141.y, _6139.z ? _5305.z : _6141.z);
                                                                        _5254 = vec3(_6140.x ? vec3(0.0).x : _6142.x, _6140.y ? vec3(0.0).y : _6142.y, _6140.z ? vec3(0.0).z : _6142.z);
                                                                    }
                                                                }
                                                                _5313 = false;
                                                                {
                                                                    if (Globals.uShadowLevels <= 0)
                                                                    {
                                                                        _5313 = true;
                                                                        _5314 = 1.0;
                                                                    }
                                                                    else
                                                                    {
                                                                        vec3 _5337 = world + ((_417 * Globals.uClipmapOrigin.data[0].w) * 1.5);
                                                                        float _5348 = (Globals.uClipmapOrigin.data[0].w * float(Globals.uShadowResolution)) * float(1 << (Globals.uShadowLevels - 1));
                                                                        int _5315 = 0;
                                                                        float _5316 = 0.0;
                                                                        for (;;)
                                                                        {
                                                                            if (_5315 < 64)
                                                                            {
                                                                                _5317 = _5316 < _5348;
                                                                            }
                                                                            else
                                                                            {
                                                                                _5317 = false;
                                                                            }
                                                                            if (!_5317)
                                                                            {
                                                                                break;
                                                                            }
                                                                            vec3 _5365 = _5337 + (_5153 * _5316);
                                                                            _5394 = false;
                                                                            {
                                                                                _5318 = false;
                                                                                _5320 = Globals.uClipmapOrigin.data[0].w;
                                                                                int _5396 = 0;
                                                                                for (;;)
                                                                                {
                                                                                    bool _5408_ladder_break = false;
                                                                                    {
                                                                                        if (!(_5396 < Globals.uShadowLevels))
                                                                                        {
                                                                                            _5408_ladder_break = true;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            vec3 _5423 = (_5365 - Globals.uClipmapOrigin.data[_5396].xyz) / vec3(Globals.uClipmapOrigin.data[_5396].w);
                                                                                            if (any(lessThan(_5423, vec3(0.5))))
                                                                                            {
                                                                                                _5397 = true;
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                _5397 = any(greaterThan(_5423, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                                            }
                                                                                            if (!(_5397))
                                                                                            {
                                                                                                _5318 = true;
                                                                                                _5320 = Globals.uClipmapOrigin.data[_5396].w;
                                                                                                _5394 = true;
                                                                                                _5395 = ((textureLod(_6012, vec3(_5423.x / float(Globals.uShadowResolution), _5423.y / float(Globals.uShadowResolution), ((float(_5396) * float(Globals.uShadowResolution)) + _5423.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_5396];
                                                                                                _5408_ladder_break = true;
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                    if (_5408_ladder_break)
                                                                                    {
                                                                                        break;
                                                                                    }
                                                                                    _5396++;
                                                                                    continue;
                                                                                }
                                                                                if (!(_5394))
                                                                                {
                                                                                    _5394 = true;
                                                                                    _5395 = 1000000.0;
                                                                                }
                                                                            }
                                                                            if (!_5318)
                                                                            {
                                                                                _5313 = true;
                                                                                _5314 = 1.0;
                                                                                break;
                                                                            }
                                                                            float _5495 = 2.0 * _5320;
                                                                            if (_5395 < ((0.5 * _5320) * clamp(_5316 / (isnan(9.9999999747524270787835121154785e-07) ? _5495 : (isnan(_5495) ? 9.9999999747524270787835121154785e-07 : max(_5495, 9.9999999747524270787835121154785e-07))), 0.0, 1.0)))
                                                                            {
                                                                                _5313 = true;
                                                                                _5314 = 0.0;
                                                                                break;
                                                                            }
                                                                            float _5380 = _5320 * 0.25;
                                                                            _5315++;
                                                                            _5316 += (isnan(_5380) ? _5395 : (isnan(_5395) ? _5380 : max(_5395, _5380)));
                                                                            continue;
                                                                        }
                                                                        if (!(_5313))
                                                                        {
                                                                            _5313 = true;
                                                                            _5314 = 1.0;
                                                                        }
                                                                    }
                                                                }
                                                                _5092++;
                                                                _5091 += (_5254 * _5314);
                                                                continue;
                                                            }
                                                            _5089 = _5091 * 0.3926990926265716552734375;
                                                        }
                                                    }
                                                    light = 0;
                                                    lit = ((Globals.uSunColour * _2223) * visibility) + _5089;
                                                    float aim;
                                                    float reaches;
                                                    float _5505;
                                                    float _5756;
                                                    bool _5759;
                                                    bool _5760;
                                                    float _5762;
                                                    float _5832;
                                                    bool _5834;
                                                    for (;;)
                                                    {
                                                        bool _151_ladder_break = false;
                                                        {
                                                            if (!(light < Globals.uLightCount))
                                                            {
                                                                _151_ladder_break = true;
                                                            }
                                                            else
                                                            {
                                                                int _2434 = light * 3;
                                                                int _2437 = _2434 + 1;
                                                                int _2440 = _2434 + 2;
                                                                vec3 delta = uLights_1._member0[_2434].xyz - world;
                                                                float _2445 = dot(delta, delta);
                                                                float _2447 = uLights_1._member0[_2434].w * 3.0;
                                                                float _2449 = isnan(2.0) ? _2447 : (isnan(_2447) ? 2.0 : max(_2447, 2.0));
                                                                float reachSquared = _2449 * _2449;
                                                                if (!(_2445 >= reachSquared))
                                                                {
                                                                    vec3 toLight = delta * inversesqrt(isnan(9.9999999747524270787835121154785e-07) ? _2445 : (isnan(_2445) ? 9.9999999747524270787835121154785e-07 : max(_2445, 9.9999999747524270787835121154785e-07)));
                                                                    float _2457 = dot(_417, toLight);
                                                                    float _2458 = isnan(0.0) ? _2457 : (isnan(_2457) ? 0.0 : max(_2457, 0.0));
                                                                    if (!(_2458 <= 0.0))
                                                                    {
                                                                        float _2468 = clamp(1.0 - ((_2445 * _2445) / (reachSquared * reachSquared)), 0.0, 1.0);
                                                                        if (dot(uLights_1._member0[_2440].xyz, uLights_1._member0[_2440].xyz) > 0.25)
                                                                        {
                                                                            float _2475 = dot(normalize(uLights_1._member0[_2440].xyz), -toLight);
                                                                            aim = isnan(0.0) ? _2475 : (isnan(_2475) ? 0.0 : max(_2475, 0.0));
                                                                        }
                                                                        else
                                                                        {
                                                                            aim = 1.0;
                                                                        }
                                                                        float contribution = (((((uLights_1._member0[_2437].w * Globals.uLocalScale) * _2458) * (1.0 / (_2445 + 1.0))) * _2468) * _2468) * aim;
                                                                        if (!((contribution * dot(uLights_1._member0[_2437].xyz, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875))) < 9.9999997473787516355514526367188e-06))
                                                                        {
                                                                            int _2504 = floatBitsToInt(uLights_1._member0[_2440].w);
                                                                            {
                                                                                if (_2504 < 0)
                                                                                {
                                                                                    _5505 = -1.0;
                                                                                }
                                                                                else
                                                                                {
                                                                                    uint _5506 = uvec3(textureSize(_6022, 0)).x;
                                                                                    float _5509 = 0.25;
                                                                                    int _5510 = 0;
                                                                                    for (;;)
                                                                                    {
                                                                                        if (!(_5510 < 6))
                                                                                        {
                                                                                            break;
                                                                                        }
                                                                                        int _5543 = ((_2504 + _5510) * 5) + 3;
                                                                                        float _5549 = dot(uLampMapRecords_1._member0[_5543].xyz, world) + uLampMapRecords_1._member0[_5543].w;
                                                                                        _5509 = isnan(_5549) ? _5509 : (isnan(_5509) ? _5549 : max(_5509, _5549));
                                                                                        _5510++;
                                                                                        continue;
                                                                                    }
                                                                                    vec3 _5567 = world + (_417 * (0.0500000007450580596923828125 + (1.5 * ((_5509 * 2.0) / float(max(_5506, 1u))))));
                                                                                    float _5511 = -1000000015047466219876688855040.0;
                                                                                    int _5512 = _2504;
                                                                                    _5510 = 0;
                                                                                    for (;;)
                                                                                    {
                                                                                        if (!(_5510 < 6))
                                                                                        {
                                                                                            break;
                                                                                        }
                                                                                        int _5577 = _2504 + _5510;
                                                                                        int _5579 = (_5577 * 5) + 3;
                                                                                        float _5585 = dot(uLampMapRecords_1._member0[_5579].xyz, _5567) + uLampMapRecords_1._member0[_5579].w;
                                                                                        if (_5585 > _5511)
                                                                                        {
                                                                                            _5511 = _5585;
                                                                                            _5512 = _5577;
                                                                                        }
                                                                                        _5510++;
                                                                                        continue;
                                                                                    }
                                                                                    int _5597 = _5512 * 5;
                                                                                    int _5598 = _5597 + 4;
                                                                                    if (uLampMapRecords_1._member0[_5598].z <= 0.0)
                                                                                    {
                                                                                        _5505 = -1.0;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        int _5607 = _5597 + 1;
                                                                                        if (_5511 <= (uLampMapRecords_1._member0[_5598].y / ((-1.0) - uLampMapRecords_1._member0[_5598].x)))
                                                                                        {
                                                                                            _5505 = 1.0;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            vec2 _5629 = vec2(dot(uLampMapRecords_1._member0[_5597].xyz, _5567) + uLampMapRecords_1._member0[_5597].w, dot(uLampMapRecords_1._member0[_5607].xyz, _5567) + uLampMapRecords_1._member0[_5607].w) / vec2(_5511);
                                                                                            uvec3 _5638 = uvec3(textureSize(_6022, 0));
                                                                                            uint _5639 = _5638.x;
                                                                                            ivec2 _5646 = ivec2(int(_5639), int(_5638.y));
                                                                                            float _5647 = length(uLampMapRecords_1._member0[_5597].xyz);
                                                                                            float _5660 = (0.0500000007450580596923828125 + (0.004999999888241291046142578125 * _5511)) + (2.0 * ((_5511 * (2.0 / (isnan(0.001000000047497451305389404296875) ? _5647 : (isnan(_5647) ? 0.001000000047497451305389404296875 : max(_5647, 0.001000000047497451305389404296875))))) / float(max(_5639, 1u))));
                                                                                            vec2 _5664 = (vec2((_5629.x * 0.5) + 0.5, 0.5 - (_5629.y * 0.5)) * vec2(_5646)) - vec2(0.5);
                                                                                            vec2 _5665 = floor(_5664);
                                                                                            ivec2 _5668 = ivec2(_5665) - ivec2(1);
                                                                                            vec2 _5669 = _5664 - _5665;
                                                                                            int _5518 = 0;
                                                                                            float _5516 = 0.0;
                                                                                            float _5517 = 0.0;
                                                                                            for (;;)
                                                                                            {
                                                                                                if (!(_5518 < 4))
                                                                                                {
                                                                                                    break;
                                                                                                }
                                                                                                int _5520 = 0;
                                                                                                float _5519 = _5517;
                                                                                                for (;;)
                                                                                                {
                                                                                                    if (!(_5520 < 4))
                                                                                                    {
                                                                                                        break;
                                                                                                    }
                                                                                                    int _5688 = _5520;
                                                                                                    float _5702 = ((texelFetch(_6022, ivec4(clamp(_5668 + ivec2(_5688, _5518), ivec2(0), _5646 - ivec2(1)), _5512, 0).xyz, 0).x * 2.0) - 1.0) - uLampMapRecords_1._member0[_5598].x;
                                                                                                    vec2 _5754 = clamp(vec2(1.0) - (abs(vec2(float(_5688) - 1.0, float(_5518) - 1.0) - _5669) * vec2(0.5)), vec2(0.0), vec2(1.0));
                                                                                                    float _5721 = _5754.x * _5754.y;
                                                                                                    if ((uLampMapRecords_1._member0[_5598].y / (isnan(-9.9999999747524270787835121154785e-07) ? _5702 : (isnan(_5702) ? (-9.9999999747524270787835121154785e-07) : min(_5702, -9.9999999747524270787835121154785e-07)))) >= (_5511 - _5660))
                                                                                                    {
                                                                                                        _5509 = _5721;
                                                                                                    }
                                                                                                    else
                                                                                                    {
                                                                                                        _5509 = 0.0;
                                                                                                    }
                                                                                                    _5520++;
                                                                                                    _5516 += _5509;
                                                                                                    _5519 += _5721;
                                                                                                    continue;
                                                                                                }
                                                                                                _5518++;
                                                                                                _5517 = _5519;
                                                                                                continue;
                                                                                            }
                                                                                            _5505 = _5516 / (isnan(9.9999997473787516355514526367188e-05) ? _5517 : (isnan(_5517) ? 9.9999997473787516355514526367188e-05 : max(_5517, 9.9999997473787516355514526367188e-05)));
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                            if (_5505 < 0.0)
                                                                            {
                                                                                _5755 = false;
                                                                                {
                                                                                    if (Globals.uShadowLevels <= 0)
                                                                                    {
                                                                                        _5755 = true;
                                                                                        _5756 = 1.0;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        vec3 _5779 = world + ((_417 * Globals.uClipmapOrigin.data[0].w) * 1.5);
                                                                                        vec3 _5780 = uLights_1._member0[_2434].xyz - _5779;
                                                                                        float _5781 = length(_5780);
                                                                                        float _5783 = _5781 - (isnan(Globals.uClipmapOrigin.data[0].w) ? 0.119999997317790985107421875 : (isnan(0.119999997317790985107421875) ? Globals.uClipmapOrigin.data[0].w : max(0.119999997317790985107421875, Globals.uClipmapOrigin.data[0].w)));
                                                                                        if (_5783 <= 0.0)
                                                                                        {
                                                                                            _5755 = true;
                                                                                            _5756 = 1.0;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            vec3 _5788 = _5780 / vec3(_5781);
                                                                                            int _5757 = 0;
                                                                                            float _5758 = 0.0;
                                                                                            for (;;)
                                                                                            {
                                                                                                if (_5757 < 48)
                                                                                                {
                                                                                                    _5759 = _5758 < _5783;
                                                                                                }
                                                                                                else
                                                                                                {
                                                                                                    _5759 = false;
                                                                                                }
                                                                                                if (!_5759)
                                                                                                {
                                                                                                    break;
                                                                                                }
                                                                                                vec3 _5805 = _5779 + (_5788 * _5758);
                                                                                                _5831 = false;
                                                                                                {
                                                                                                    _5760 = false;
                                                                                                    _5762 = Globals.uClipmapOrigin.data[0].w;
                                                                                                    int _5833 = 0;
                                                                                                    for (;;)
                                                                                                    {
                                                                                                        bool _5845_ladder_break = false;
                                                                                                        {
                                                                                                            if (!(_5833 < Globals.uShadowLevels))
                                                                                                            {
                                                                                                                _5845_ladder_break = true;
                                                                                                            }
                                                                                                            else
                                                                                                            {
                                                                                                                vec3 _5860 = (_5805 - Globals.uClipmapOrigin.data[_5833].xyz) / vec3(Globals.uClipmapOrigin.data[_5833].w);
                                                                                                                if (any(lessThan(_5860, vec3(0.5))))
                                                                                                                {
                                                                                                                    _5834 = true;
                                                                                                                }
                                                                                                                else
                                                                                                                {
                                                                                                                    _5834 = any(greaterThan(_5860, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                                                                }
                                                                                                                if (!(_5834))
                                                                                                                {
                                                                                                                    _5760 = true;
                                                                                                                    _5762 = Globals.uClipmapOrigin.data[_5833].w;
                                                                                                                    _5831 = true;
                                                                                                                    _5832 = ((textureLod(_6012, vec3(_5860.x / float(Globals.uShadowResolution), _5860.y / float(Globals.uShadowResolution), ((float(_5833) * float(Globals.uShadowResolution)) + _5860.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_5833];
                                                                                                                    _5845_ladder_break = true;
                                                                                                                }
                                                                                                            }
                                                                                                        }
                                                                                                        if (_5845_ladder_break)
                                                                                                        {
                                                                                                            break;
                                                                                                        }
                                                                                                        _5833++;
                                                                                                        continue;
                                                                                                    }
                                                                                                    if (!(_5831))
                                                                                                    {
                                                                                                        _5831 = true;
                                                                                                        _5832 = 1000000.0;
                                                                                                    }
                                                                                                }
                                                                                                if (!_5760)
                                                                                                {
                                                                                                    _5755 = true;
                                                                                                    _5756 = 1.0;
                                                                                                    break;
                                                                                                }
                                                                                                float _5932 = 2.0 * _5762;
                                                                                                if (_5832 < ((0.5 * _5762) * clamp(_5758 / (isnan(9.9999999747524270787835121154785e-07) ? _5932 : (isnan(_5932) ? 9.9999999747524270787835121154785e-07 : max(_5932, 9.9999999747524270787835121154785e-07))), 0.0, 1.0)))
                                                                                                {
                                                                                                    _5755 = true;
                                                                                                    _5756 = 0.0;
                                                                                                    break;
                                                                                                }
                                                                                                float _5817 = _5762 * 0.25;
                                                                                                _5757++;
                                                                                                _5758 += (isnan(_5817) ? _5832 : (isnan(_5832) ? _5817 : max(_5832, _5817)));
                                                                                                continue;
                                                                                            }
                                                                                            if (!(_5755))
                                                                                            {
                                                                                                _5755 = true;
                                                                                                _5756 = 1.0;
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                                reaches = _5756;
                                                                            }
                                                                            else
                                                                            {
                                                                                reaches = _5505;
                                                                            }
                                                                            if (!(reaches <= 0.0))
                                                                            {
                                                                                lit += (uLights_1._member0[_2437].xyz * (contribution * reaches));
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        if (_151_ladder_break)
                                                        {
                                                            break;
                                                        }
                                                        light++;
                                                        continue;
                                                    }
                                                    imageStore(uDirect, ivec2(uvec2(texelAt)), vec4(lit, 1.0));
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    else
                    {
                        int _267 = at + 1;
                        int _272 = int(uPages_1._member0[at].z);
                        bool _80;
                        if (within.x >= _272)
                        {
                            _80 = true;
                        }
                        else
                        {
                            _80 = within.y >= int(uPages_1._member0[at].w);
                        }
                        if (!(_80))
                        {
                            int _287 = at + 2;
                            int _291 = at + 3;
                            int _295 = at + 4;
                            int _300 = at + 6;
                            int _304 = at + 7;
                            int _307 = at + 8;
                            vec2 uv = (vec2(within) + vec2(0.5)) / vec2(uPages_1._member0[at].zw);
                            uvec2 _vecSize = uvec2(textureSize(_6004, 0));
                            vec2 cardUv = (uPages_1._member0[_267].xy + (uv * uPages_1._member0[_267].zw)) / vec2(float(_vecSize.x), float(_vecSize.y));
                            vec4 _sampled = textureLod(_6006, cardUv, 0.0);
                            ivec2 pageAt = ivec2(int(uPages_1._member0[at].x), int(uPages_1._member0[at].y));
                            if (_sampled.w < 0.5)
                            {
                                imageStore(uDirect, ivec2(uvec2(pageAt + within)), vec4(0.0));
                            }
                            else
                            {
                                vec3 _363 = normalize((textureLod(_6008, cardUv, 0.0).xyz * 2.0) - vec3(1.0));
                                vec3 local = ((uPages_1._member0[_287].xyz + ((uPages_1._member0[_291].xyz * ((uv.x * 2.0) - 1.0)) * uPages_1._member0[_287].w)) + ((uPages_1._member0[_295].xyz * ((uv.y * 2.0) - 1.0)) * uPages_1._member0[_291].w)) - (uPages_1._member0[_230].xyz * (textureLod(_6010, cardUv, 0.0).x * uPages_1._member0[_295].w));
                                vec3 _395 = vec3(uPages_1._member0[_300].x, uPages_1._member0[_304].x, uPages_1._member0[_307].x);
                                vec3 _400 = vec3(uPages_1._member0[_300].y, uPages_1._member0[_304].y, uPages_1._member0[_307].y);
                                vec3 _405 = vec3(uPages_1._member0[_300].z, uPages_1._member0[_304].z, uPages_1._member0[_307].z);
                                vec3 world = vec3(dot(_395, local), dot(_400, local), dot(_405, local)) + vec3(uPages_1._member0[_300].w, uPages_1._member0[_304].w, uPages_1._member0[_307].w);
                                vec3 _417 = normalize(vec3(dot(_395, _363), dot(_400, _363), dot(_405, _363)));
                                ivec2 texelAt = pageAt + within;
                                float visibility;
                                if (Globals.uMode == 1)
                                {
                                    if (((texelAt.x | texelAt.y) & 3) != 0)
                                    {
                                        imageStore(uDirect, ivec2(uvec2(texelAt)), vec4(0.0));
                                    }
                                    else
                                    {
                                        ivec2 probeCoord = texelAt >> ivec2(2);
                                        uProbePos._member0[(probeCoord.y * Globals.uProbeWidth) + probeCoord.x] = vec4(world, 1.0);
                                        vec2 _3036;
                                        {
                                            if (Globals.uTemporalIndex <= 0)
                                            {
                                                _3036 = vec2(0.5);
                                            }
                                            else
                                            {
                                                float _3051 = float(((uint(probeCoord.x) * 73856093u) ^ (uint(probeCoord.y) * 19349663u)) & 65535u);
                                                int _3057 = (Globals.uTemporalIndex / max(Globals.uJitterStride, 1)) & 65535;
                                                uint _3072 = uint(_3057);
                                                uint _3075 = (_3072 << 16u) | (_3072 >> 16u);
                                                uint _3080 = ((_3075 & 1431655765u) << 1u) | ((_3075 & 2863311530u) >> 1u);
                                                uint _3085 = ((_3080 & 858993459u) << 2u) | ((_3080 & 3435973836u) >> 2u);
                                                uint _3090 = ((_3085 & 252645135u) << 4u) | ((_3085 & 4042322160u) >> 4u);
                                                _3036 = fract(vec2(fract(float(_3057) * 0.61803400516510009765625), float(((_3090 & 16711935u) << 8u) | ((_3090 & 4278255360u) >> 8u)) * 2.3283064365386962890625e-10) + vec2(_3051 * 1.52587890625e-05, fract(_3051 * 2.4689239580766297876834869384766e-05)));
                                            }
                                        }
                                        vec3 _3099;
                                        {
                                            bool _3100;
                                            if (Globals.uShadowLevels <= 0)
                                            {
                                                _3100 = true;
                                            }
                                            else
                                            {
                                                _3100 = Globals.uLookupBuckets <= 0;
                                            }
                                            if (_3100)
                                            {
                                                _3099 = vec3(0.0);
                                            }
                                            else
                                            {
                                                vec3 _5941;
                                                vec3 _5942;
                                                vec3 _5943;
                                                {
                                                    vec3 _5956 = _417;
                                                    float _3228 = _417.z;
                                                    if (_3228 < (-0.99999988079071044921875))
                                                    {
                                                        _5941 = vec3(0.0, -1.0, 0.0);
                                                        _5942 = vec3(-1.0, 0.0, 0.0);
                                                        _5943 = _5956;
                                                    }
                                                    else
                                                    {
                                                        float _3236 = 1.0 / (1.0 + _3228);
                                                        float _3237 = _417.x;
                                                        float _3238 = -_3237;
                                                        float _3239 = _417.y;
                                                        float _3241 = (_3238 * _3239) * _3236;
                                                        _5941 = vec3(1.0 - ((_3237 * _3237) * _3236), _3241, _3238);
                                                        _5942 = vec3(_3241, 1.0 - ((_3239 * _3239) * _3236), -_3239);
                                                        _5943 = _5956;
                                                    }
                                                }
                                                int _3101 = 0;
                                                vec4 _3102 = vec4(0.0);
                                                vec4 _3103 = vec4(0.0);
                                                vec4 _3104 = vec4(0.0);
                                                vec3 _3106;
                                                vec3 _3107;
                                                vec2 _3109;
                                                float _3273;
                                                bool _3276;
                                                bool _3277;
                                                float _3279;
                                                float _3354;
                                                bool _3356;
                                                bool _3468;
                                                bool _3474;
                                                ivec2 _3475;
                                                bool _3479;
                                                bool _3488;
                                                bool _3489;
                                                bool _3490;
                                                bool _3491;
                                                bool _3492;
                                                ivec2 _3722;
                                                for (;;)
                                                {
                                                    if (!(_3101 < 16))
                                                    {
                                                        break;
                                                    }
                                                    int _3140 = _3101;
                                                    vec2 _3149 = (vec2(float(_3140 - 4 * (_3140 / 4)), float(_3140 / 4)) + _3036) * vec2(0.25);
                                                    float _3151 = 6.283185482025146484375 * _3149.x;
                                                    float _3152 = _3149.y;
                                                    float _3154 = 1.0 - (_3152 * _3152);
                                                    float _3156 = sqrt(isnan(_3154) ? 0.0 : (isnan(0.0) ? _3154 : max(0.0, _3154)));
                                                    vec3 _3271 = ((_5941 * (_3156 * cos(_3151))) + (_5942 * (_3156 * sin(_3151)))) + (_5943 * _3152);
                                                    _3272 = false;
                                                    {
                                                        _3106 = world;
                                                        if (Globals.uShadowLevels <= 0)
                                                        {
                                                            _3272 = true;
                                                            _3273 = 1.0;
                                                        }
                                                        else
                                                        {
                                                            vec3 _3296 = world + ((_417 * Globals.uClipmapOrigin.data[0].w) * 1.5);
                                                            float _3307 = (Globals.uClipmapOrigin.data[0].w * float(Globals.uShadowResolution)) * float(1 << (Globals.uShadowLevels - 1));
                                                            int _3274 = 0;
                                                            float _3275 = 0.0;
                                                            for (;;)
                                                            {
                                                                if (_3274 < 64)
                                                                {
                                                                    _3276 = _3275 < _3307;
                                                                }
                                                                else
                                                                {
                                                                    _3276 = false;
                                                                }
                                                                if (!_3276)
                                                                {
                                                                    break;
                                                                }
                                                                vec3 _3324 = _3296 + (_3271 * _3275);
                                                                _3353 = false;
                                                                {
                                                                    _3277 = false;
                                                                    _3279 = Globals.uClipmapOrigin.data[0].w;
                                                                    int _3355 = 0;
                                                                    for (;;)
                                                                    {
                                                                        bool _3367_ladder_break = false;
                                                                        {
                                                                            if (!(_3355 < Globals.uShadowLevels))
                                                                            {
                                                                                _3367_ladder_break = true;
                                                                            }
                                                                            else
                                                                            {
                                                                                vec3 _3382 = (_3324 - Globals.uClipmapOrigin.data[_3355].xyz) / vec3(Globals.uClipmapOrigin.data[_3355].w);
                                                                                if (any(lessThan(_3382, vec3(0.5))))
                                                                                {
                                                                                    _3356 = true;
                                                                                }
                                                                                else
                                                                                {
                                                                                    _3356 = any(greaterThan(_3382, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                                }
                                                                                if (!(_3356))
                                                                                {
                                                                                    _3277 = true;
                                                                                    _3279 = Globals.uClipmapOrigin.data[_3355].w;
                                                                                    _3353 = true;
                                                                                    _3354 = ((textureLod(_6012, vec3(_3382.x / float(Globals.uShadowResolution), _3382.y / float(Globals.uShadowResolution), ((float(_3355) * float(Globals.uShadowResolution)) + _3382.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_3355];
                                                                                    _3367_ladder_break = true;
                                                                                }
                                                                            }
                                                                        }
                                                                        if (_3367_ladder_break)
                                                                        {
                                                                            break;
                                                                        }
                                                                        _3355++;
                                                                        continue;
                                                                    }
                                                                    if (!(_3353))
                                                                    {
                                                                        _3353 = true;
                                                                        _3354 = 1000000.0;
                                                                    }
                                                                }
                                                                if (!_3277)
                                                                {
                                                                    _3272 = true;
                                                                    _3273 = 1.0;
                                                                    break;
                                                                }
                                                                float _3454 = 2.0 * _3279;
                                                                float _3458 = (0.5 * _3279) * clamp(_3275 / (isnan(9.9999999747524270787835121154785e-07) ? _3454 : (isnan(_3454) ? 9.9999999747524270787835121154785e-07 : max(_3454, 9.9999999747524270787835121154785e-07))), 0.0, 1.0);
                                                                float _3460 = (_3275 + _3354) - _3458;
                                                                float _3280 = isnan(0.0) ? _3460 : (isnan(_3460) ? 0.0 : max(_3460, 0.0));
                                                                if (_3354 < _3458)
                                                                {
                                                                    _3106 = _3296 + (_3271 * _3280);
                                                                    _3272 = true;
                                                                    _3273 = 0.0;
                                                                    break;
                                                                }
                                                                float _3339 = _3279 * 0.25;
                                                                _3274++;
                                                                _3275 += (isnan(_3339) ? _3354 : (isnan(_3354) ? _3339 : max(_3354, _3339)));
                                                                continue;
                                                            }
                                                            if (!(_3272))
                                                            {
                                                                _3272 = true;
                                                                _3273 = 1.0;
                                                            }
                                                        }
                                                    }
                                                    if (_3273 <= 0.5)
                                                    {
                                                        {
                                                            _3109 = vec2(0.0);
                                                            float _3110 = 1000000000.0;
                                                            if (Globals.uLookupBuckets <= 0)
                                                            {
                                                                _3468 = false;
                                                            }
                                                            else
                                                            {
                                                                ivec3 _3509 = ivec3(floor((_3106 - Globals.uLookupMin) / vec3(Globals.uLookupCell)));
                                                                int _3721 = int((((uint(_3509.x) * 2376512323u) ^ (uint(_3509.y) * 3625334849u)) ^ (uint(_3509.z) * 3407524639u)) & uint(Globals.uLookupBuckets - 1));
                                                                uvec2 _3514 = uvec2(textureSize(_6004, 0));
                                                                vec2 _3521 = vec2(float(_3514.x), float(_3514.y));
                                                                bool _3471 = false;
                                                                bool _3472 = false;
                                                                int _3473 = 0;
                                                                for (;;)
                                                                {
                                                                    if (_3473 <= uCells_1._member0[Globals.uLookupBuckets].y)
                                                                    {
                                                                        _3474 = !_3471;
                                                                    }
                                                                    else
                                                                    {
                                                                        _3474 = false;
                                                                    }
                                                                    if (!_3474)
                                                                    {
                                                                        break;
                                                                    }
                                                                    bool _3541 = _3473 == 0;
                                                                    if (_3541)
                                                                    {
                                                                        _3475 = uCells_1._member0[_3721];
                                                                    }
                                                                    else
                                                                    {
                                                                        int _3726 = uCells_1._member0[Globals.uLookupBuckets].x + ((_3473 - 1) * 6);
                                                                        float _3742 = intBitsToFloat(uCellPages_1._member0[_3726 + 3]);
                                                                        vec3 _3744 = _3106 - vec3(intBitsToFloat(uCellPages_1._member0[_3726]), intBitsToFloat(uCellPages_1._member0[_3726 + 1]), intBitsToFloat(uCellPages_1._member0[_3726 + 2]));
                                                                        if (dot(_3744, _3744) > (_3742 * _3742))
                                                                        {
                                                                            _3722 = ivec2(0);
                                                                        }
                                                                        else
                                                                        {
                                                                            _3722 = ivec2(uCellPages_1._member0[_3726 + 4], uCellPages_1._member0[_3726 + 5]);
                                                                        }
                                                                        _3475 = _3722;
                                                                    }
                                                                    bool _3476 = _3471;
                                                                    bool _3477 = _3472;
                                                                    int _3478 = 0;
                                                                    for (;;)
                                                                    {
                                                                        bool _3553_ladder_break = false;
                                                                        {
                                                                            if (_3478 < _3475.y)
                                                                            {
                                                                                _3479 = !_3476;
                                                                            }
                                                                            else
                                                                            {
                                                                                _3479 = false;
                                                                            }
                                                                            if (!_3479)
                                                                            {
                                                                                _3553_ladder_break = true;
                                                                            }
                                                                            else
                                                                            {
                                                                                int _3570 = _3475.x + _3478;
                                                                                int _3573 = uCellPages_1._member0[_3570] * 10;
                                                                                if (!((uPages_1._member0[_3573 + 5].w > 0.5) == _3541))
                                                                                {
                                                                                    int _3582 = _3573 + 9;
                                                                                    vec3 _3586 = _3106 - uPages_1._member0[_3582].xyz;
                                                                                    if (!(dot(_3586, _3586) > (uPages_1._member0[_3582].w * uPages_1._member0[_3582].w)))
                                                                                    {
                                                                                        vec3 _3593 = -_3271;
                                                                                        int _3760 = uCellPages_1._member0[_3570] * 10;
                                                                                        vec4 _3486 = uPages_1._member0[_3760];
                                                                                        vec4 _3487 = uPages_1._member0[_3760 + 1];
                                                                                        int _3766 = _3760 + 2;
                                                                                        int _3769 = _3760 + 3;
                                                                                        int _3772 = _3760 + 4;
                                                                                        int _3778 = _3760 + 6;
                                                                                        int _3781 = _3760 + 7;
                                                                                        int _3784 = _3760 + 8;
                                                                                        vec3 _3791 = _3106 - vec3(uPages_1._member0[_3778].w, uPages_1._member0[_3781].w, uPages_1._member0[_3784].w);
                                                                                        vec3 _3485 = vec3(dot(uPages_1._member0[_3778].xyz, _3593), dot(uPages_1._member0[_3781].xyz, _3593), dot(uPages_1._member0[_3784].xyz, _3593));
                                                                                        vec3 _3804 = vec3(dot(uPages_1._member0[_3778].xyz, _3791), dot(uPages_1._member0[_3781].xyz, _3791), dot(uPages_1._member0[_3784].xyz, _3791)) - uPages_1._member0[_3766].xyz;
                                                                                        vec2 _3807 = vec2(uPages_1._member0[_3766].w, uPages_1._member0[_3769].w);
                                                                                        bvec2 _6044 = isnan(_3807);
                                                                                        bvec2 _6045 = isnan(vec2(9.9999999747524270787835121154785e-07));
                                                                                        vec2 _6046 = max(_3807, vec2(9.9999999747524270787835121154785e-07));
                                                                                        vec2 _6047 = vec2(_6044.x ? vec2(9.9999999747524270787835121154785e-07).x : _6046.x, _6044.y ? vec2(9.9999999747524270787835121154785e-07).y : _6046.y);
                                                                                        vec2 _3814 = vec2(dot(_3804, uPages_1._member0[_3769].xyz), dot(_3804, uPages_1._member0[_3772].xyz)) / vec2(_6045.x ? _3807.x : _6047.x, _6045.y ? _3807.y : _6047.y);
                                                                                        vec2 _3480 = _3814;
                                                                                        float _3482 = -dot(_3804, uPages_1._member0[_3760 + 5].xyz);
                                                                                        float _3483 = uPages_1._member0[_3772].w;
                                                                                        vec3 _3484 = uPages_1._member0[_3760 + 5].xyz;
                                                                                        if (abs(_3814.x) > 1.0)
                                                                                        {
                                                                                            _3488 = true;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            _3488 = abs(_3480.y) > 1.0;
                                                                                        }
                                                                                        if (!(_3488))
                                                                                        {
                                                                                            if (dot(_3271, _3271) > 0.5)
                                                                                            {
                                                                                                _3489 = dot(_3484, _3485) < (-0.0500000007450580596923828125);
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                _3489 = false;
                                                                                            }
                                                                                            if (!(_3489))
                                                                                            {
                                                                                                if (_3482 < (-0.25))
                                                                                                {
                                                                                                    _3490 = true;
                                                                                                }
                                                                                                else
                                                                                                {
                                                                                                    _3490 = _3482 > (_3483 + 0.25);
                                                                                                }
                                                                                                if (!(_3490))
                                                                                                {
                                                                                                    vec2 _3637 = (_3480 * 0.5) + vec2(0.5);
                                                                                                    vec2 _3644 = (_3487.xy + (_3637 * _3487.zw)) / _3521;
                                                                                                    if (!(textureLod(_6006, _3644, 0.0).w < 0.5))
                                                                                                    {
                                                                                                        float _3664 = abs((textureLod(_6010, _3644, 0.0).x * _3483) - _3482);
                                                                                                        if (_3664 < _3110)
                                                                                                        {
                                                                                                            _3110 = _3664;
                                                                                                            _3109 = (_3486.xy + (_3637 * _3486.zw)) / Globals.uAtlasSize.xy;
                                                                                                            _3491 = _3664 < 0.0199999995529651641845703125;
                                                                                                            _3492 = true;
                                                                                                        }
                                                                                                        else
                                                                                                        {
                                                                                                            _3491 = _3476;
                                                                                                            _3492 = _3477;
                                                                                                        }
                                                                                                        _3476 = _3491;
                                                                                                        _3477 = _3492;
                                                                                                    }
                                                                                                }
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                        if (_3553_ladder_break)
                                                                        {
                                                                            break;
                                                                        }
                                                                        _3478++;
                                                                        continue;
                                                                    }
                                                                    _3471 = _3476;
                                                                    _3472 = _3477;
                                                                    _3473++;
                                                                    continue;
                                                                }
                                                                _3468 = _3472;
                                                            }
                                                        }
                                                        if (_3468)
                                                        {
                                                            _3107 = textureLod(_6014, _3109, 0.0).xyz * smoothstep(1.5 * Globals.uClipmapOrigin.data[0].w, 2.0 * Globals.uClipmapOrigin.data[0].w, length(_3106 - world));
                                                        }
                                                        else
                                                        {
                                                            _3107 = vec3(0.0);
                                                        }
                                                    }
                                                    else
                                                    {
                                                        _3107 = vec3(0.0);
                                                    }
                                                    vec4 _3827 = vec4(0.2820949852466583251953125, (-0.48860299587249755859375) * _3271.y, 0.48860299587249755859375 * _3271.z, (-0.48860299587249755859375) * _3271.x);
                                                    _3101++;
                                                    _3102 += (_3827 * _3107.x);
                                                    _3103 += (_3827 * _3107.y);
                                                    _3104 += (_3827 * _3107.z);
                                                    continue;
                                                }
                                                vec4 _3844 = vec4(0.2820949852466583251953125, (-0.48860299587249755859375) * _417.y, 0.48860299587249755859375 * _417.z, (-0.48860299587249755859375) * _417.x);
                                                vec4 _3835 = vec4(_3844.x * 3.1415927410125732421875, _3844.yzw * 2.094395160675048828125);
                                                vec3 _3217 = vec3(dot(_3102, _3835), dot(_3103, _3835), dot(_3104, _3835)) * 0.3926990926265716552734375;
                                                bvec3 _6049 = isnan(_3217);
                                                bvec3 _6050 = isnan(vec3(0.0));
                                                vec3 _6051 = max(_3217, vec3(0.0));
                                                vec3 _6052 = vec3(_6049.x ? vec3(0.0).x : _6051.x, _6049.y ? vec3(0.0).y : _6051.y, _6049.z ? vec3(0.0).z : _6051.z);
                                                _3099 = vec3(_6050.x ? _3217.x : _6052.x, _6050.y ? _3217.y : _6052.y, _6050.z ? _3217.z : _6052.z);
                                            }
                                        }
                                        vec4 _sampled_1 = imageLoad(uDirect, texelAt);
                                        if (Globals.uTemporalIndex > 0)
                                        {
                                            visibility = _sampled_1.w;
                                        }
                                        else
                                        {
                                            visibility = 0.0;
                                        }
                                        float limit_1 = float(Globals.uMaxFrames);
                                        float _1575 = visibility + 1.0;
                                        float _1576 = limit_1 + 1.0;
                                        imageStore(uDirect, ivec2(uvec2(texelAt)), vec4(mix(_sampled_1.xyz, _3099, vec3(1.0 / (1.0 + (isnan(limit_1) ? visibility : (isnan(visibility) ? limit_1 : min(visibility, limit_1)))))), isnan(_1576) ? _1575 : (isnan(_1575) ? _1576 : min(_1575, _1576))));
                                    }
                                }
                                else
                                {
                                    int light;
                                    vec3 lit;
                                    if (Globals.uMode == 2)
                                    {
                                        ivec2 _1593 = pageAt + ivec2(_272, int(uPages_1._member0[at].w));
                                        ivec2 probe00 = texelAt >> ivec2(2);
                                        vec2 _1604 = (vec2(texelAt - (probe00 * ivec2(4))) + vec2(1.0)) * vec2(0.16666667163372039794921875);
                                        light = 0;
                                        lit = vec3(0.0);
                                        visibility = 0.0;
                                        vec3 position;
                                        bool _3846;
                                        bool _3847;
                                        float _3896;
                                        vec3 _3914;
                                        bool _3973;
                                        bool _3974;
                                        float _4023;
                                        for (;;)
                                        {
                                            bool _126_ladder_break = false;
                                            {
                                                if (!(light < 4))
                                                {
                                                    _126_ladder_break = true;
                                                }
                                                else
                                                {
                                                    ivec2 probeCoord_1 = probe00 + _1613_comp[light];
                                                    {
                                                        position = vec3(0.0);
                                                        if (any(lessThan(probeCoord_1, ivec2(0))))
                                                        {
                                                            _3847 = true;
                                                        }
                                                        else
                                                        {
                                                            _3847 = probeCoord_1.x >= Globals.uProbeWidth;
                                                        }
                                                        if (_3847)
                                                        {
                                                            _3847 = true;
                                                        }
                                                        else
                                                        {
                                                            _3847 = probeCoord_1.y >= Globals.uProbeHeight;
                                                        }
                                                        if (_3847)
                                                        {
                                                            _3846 = false;
                                                        }
                                                        else
                                                        {
                                                            ivec2 _3872 = probeCoord_1 * ivec2(4);
                                                            if (any(lessThan(_3872, pageAt)))
                                                            {
                                                                _3847 = true;
                                                            }
                                                            else
                                                            {
                                                                _3847 = any(greaterThanEqual(_3872, _1593));
                                                            }
                                                            if (_3847)
                                                            {
                                                                _3846 = false;
                                                            }
                                                            else
                                                            {
                                                                int _3888 = (probeCoord_1.y * Globals.uProbeWidth) + probeCoord_1.x;
                                                                position = uProbePos._member0[_3888].xyz;
                                                                _3846 = uProbePos._member0[_3888].w >= 0.5;
                                                            }
                                                        }
                                                    }
                                                    if (!(!_3846))
                                                    {
                                                        vec3 _3899 = world - position;
                                                        if ((abs(dot(_3899, _417)) / (length(_3899) + 0.00999999977648258209228515625)) < 0.257759988307952880859375)
                                                        {
                                                            _3896 = 1.0;
                                                        }
                                                        else
                                                        {
                                                            _3896 = 0.0;
                                                        }
                                                        if (!(_3896 <= 0.0))
                                                        {
                                                            vec2 _1737 = mix(vec2(1.0) - _1604, _1604, vec2(_1613_comp[light]));
                                                            float w = _1737.x * _1737.y;
                                                            int _3910 = 0;
                                                            vec3 _3911 = textureLod(_6019, (vec2(probeCoord_1 * ivec2(4)) + vec2(0.5)) / Globals.uAtlasSize.xy, 0.0).xyz * 2.0;
                                                            float _3912 = 2.0;
                                                            for (;;)
                                                            {
                                                                bool _3921_ladder_break = false;
                                                                {
                                                                    if (!(_3910 < 4))
                                                                    {
                                                                        _3921_ladder_break = true;
                                                                    }
                                                                    else
                                                                    {
                                                                        ivec2 _3930 = probeCoord_1 + _1798_comp[_3910];
                                                                        {
                                                                            _3914 = vec3(0.0);
                                                                            if (any(lessThan(_3930, ivec2(0))))
                                                                            {
                                                                                _3974 = true;
                                                                            }
                                                                            else
                                                                            {
                                                                                _3974 = _3930.x >= Globals.uProbeWidth;
                                                                            }
                                                                            if (_3974)
                                                                            {
                                                                                _3974 = true;
                                                                            }
                                                                            else
                                                                            {
                                                                                _3974 = _3930.y >= Globals.uProbeHeight;
                                                                            }
                                                                            if (_3974)
                                                                            {
                                                                                _3973 = false;
                                                                            }
                                                                            else
                                                                            {
                                                                                ivec2 _3999 = _3930 * ivec2(4);
                                                                                if (any(lessThan(_3999, pageAt)))
                                                                                {
                                                                                    _3974 = true;
                                                                                }
                                                                                else
                                                                                {
                                                                                    _3974 = any(greaterThanEqual(_3999, _1593));
                                                                                }
                                                                                if (_3974)
                                                                                {
                                                                                    _3973 = false;
                                                                                }
                                                                                else
                                                                                {
                                                                                    int _4015 = (_3930.y * Globals.uProbeWidth) + _3930.x;
                                                                                    _3914 = uProbePos._member0[_4015].xyz;
                                                                                    _3973 = uProbePos._member0[_4015].w >= 0.5;
                                                                                }
                                                                            }
                                                                        }
                                                                        if (!(!_3973))
                                                                        {
                                                                            vec3 _4026 = world - _3914;
                                                                            if ((abs(dot(_4026, _417)) / (length(_4026) + 0.00999999977648258209228515625)) < 0.257759988307952880859375)
                                                                            {
                                                                                _4023 = 1.0;
                                                                            }
                                                                            else
                                                                            {
                                                                                _4023 = 0.0;
                                                                            }
                                                                            if (!(_4023 <= 0.0))
                                                                            {
                                                                                _3911 += textureLod(_6019, (vec2(_3930 * ivec2(4)) + vec2(0.5)) / Globals.uAtlasSize.xy, 0.0).xyz;
                                                                                _3912 += 1.0;
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                                if (_3921_ladder_break)
                                                                {
                                                                    break;
                                                                }
                                                                _3910++;
                                                                continue;
                                                            }
                                                            lit += ((_3911 / vec3(_3912)) * w);
                                                            visibility += w;
                                                        }
                                                    }
                                                }
                                            }
                                            if (_126_ladder_break)
                                            {
                                                break;
                                            }
                                            light++;
                                            continue;
                                        }
                                        vec3 indirect;
                                        if (visibility > 0.0)
                                        {
                                            indirect = lit / vec3(visibility);
                                        }
                                        else
                                        {
                                            indirect = textureLod(_6019, (vec2(probe00 * ivec2(4)) + vec2(0.5)) / Globals.uAtlasSize.xy, 0.0).xyz;
                                        }
                                        vec3 _1862 = _sampled.xyz;
                                        vec3 _4072;
                                        {
                                            if (Globals.uBoost >= 1.0)
                                            {
                                                _4072 = _1862;
                                            }
                                            else
                                            {
                                                float _4079 = dot(_1862, vec3(0.300000011920928955078125, 0.589999973773956298828125, 0.10999999940395355224609375));
                                                vec3 _4091 = clamp(_1862 * (pow(isnan(0.0) ? _4079 : (isnan(_4079) ? 0.0 : max(_4079, 0.0)), Globals.uBoost) / (isnan(9.9999999392252902907785028219223e-09) ? _4079 : (isnan(_4079) ? 9.9999999392252902907785028219223e-09 : max(_4079, 9.9999999392252902907785028219223e-09)))), vec3(0.0), vec3(1.0));
                                                bvec3 _6074 = isnan(_4091);
                                                bvec3 _6075 = isnan(vec3(0.9900000095367431640625));
                                                vec3 _6076 = min(_4091, vec3(0.9900000095367431640625));
                                                vec3 _6077 = vec3(_6074.x ? vec3(0.9900000095367431640625).x : _6076.x, _6074.y ? vec3(0.9900000095367431640625).y : _6076.y, _6074.z ? vec3(0.9900000095367431640625).z : _6076.z);
                                                _4072 = vec3(_6075.x ? _4091.x : _6077.x, _6075.y ? _4091.y : _6077.y, _6075.z ? _4091.z : _6077.z);
                                            }
                                        }
                                        imageStore(uDirect, ivec2(uvec2(texelAt)), vec4((texelFetch(_6017, ivec3(texelAt, 0).xy, 0).xyz + indirect) * (_4072 * vec3(0.3183098733425140380859375)), 1.0));
                                    }
                                    else
                                    {
                                        if (Globals.uMode == 3)
                                        {
                                            vec3 _1920 = _sampled.xyz;
                                            vec3 _4093;
                                            {
                                                if (Globals.uBoost >= 1.0)
                                                {
                                                    _4093 = _1920;
                                                }
                                                else
                                                {
                                                    float _4100 = dot(_1920, vec3(0.300000011920928955078125, 0.589999973773956298828125, 0.10999999940395355224609375));
                                                    vec3 _4112 = clamp(_1920 * (pow(isnan(0.0) ? _4100 : (isnan(_4100) ? 0.0 : max(_4100, 0.0)), Globals.uBoost) / (isnan(9.9999999392252902907785028219223e-09) ? _4100 : (isnan(_4100) ? 9.9999999392252902907785028219223e-09 : max(_4100, 9.9999999392252902907785028219223e-09)))), vec3(0.0), vec3(1.0));
                                                    bvec3 _6089 = isnan(_4112);
                                                    bvec3 _6090 = isnan(vec3(0.9900000095367431640625));
                                                    vec3 _6091 = min(_4112, vec3(0.9900000095367431640625));
                                                    vec3 _6092 = vec3(_6089.x ? vec3(0.9900000095367431640625).x : _6091.x, _6089.y ? vec3(0.9900000095367431640625).y : _6091.y, _6089.z ? vec3(0.9900000095367431640625).z : _6091.z);
                                                    _4093 = vec3(_6090.x ? _4112.x : _6092.x, _6090.y ? _4112.y : _6092.y, _6090.z ? _4112.z : _6092.z);
                                                }
                                            }
                                            imageStore(uDirect, ivec2(uvec2(texelAt)), vec4(texelFetch(_6017, ivec3(texelAt, 0).xy, 0).xyz * (_4093 * vec3(0.3183098733425140380859375)), 1.0));
                                        }
                                        else
                                        {
                                            if (Globals.uProbe != 0)
                                            {
                                                vec4 _4114;
                                                {
                                                    if (Globals.uProbe == 5)
                                                    {
                                                        if (((texelAt.x | texelAt.y) & 7) != 0)
                                                        {
                                                            _4114 = vec4(0.0);
                                                        }
                                                        else
                                                        {
                                                            vec2 _4115;
                                                            bool _4237;
                                                            {
                                                                _4115 = vec2(0.0);
                                                                float _4117 = 1000000000.0;
                                                                if (Globals.uLookupBuckets <= 0)
                                                                {
                                                                    _4237 = false;
                                                                }
                                                                else
                                                                {
                                                                    ivec3 _4278 = ivec3(floor((world - Globals.uLookupMin) / vec3(Globals.uLookupCell)));
                                                                    int _4490 = int((((uint(_4278.x) * 2376512323u) ^ (uint(_4278.y) * 3625334849u)) ^ (uint(_4278.z) * 3407524639u)) & uint(Globals.uLookupBuckets - 1));
                                                                    uvec2 _4283 = uvec2(textureSize(_6004, 0));
                                                                    vec2 _4290 = vec2(float(_4283.x), float(_4283.y));
                                                                    bool _4240 = false;
                                                                    bool _4241 = false;
                                                                    int _4242 = 0;
                                                                    bool _4243;
                                                                    ivec2 _4244;
                                                                    bool _4248;
                                                                    bool _4257;
                                                                    bool _4258;
                                                                    bool _4259;
                                                                    bool _4260;
                                                                    bool _4261;
                                                                    ivec2 _4491;
                                                                    for (;;)
                                                                    {
                                                                        if (_4242 <= uCells_1._member0[Globals.uLookupBuckets].y)
                                                                        {
                                                                            _4243 = !_4240;
                                                                        }
                                                                        else
                                                                        {
                                                                            _4243 = false;
                                                                        }
                                                                        if (!_4243)
                                                                        {
                                                                            break;
                                                                        }
                                                                        bool _4310 = _4242 == 0;
                                                                        if (_4310)
                                                                        {
                                                                            _4244 = uCells_1._member0[_4490];
                                                                        }
                                                                        else
                                                                        {
                                                                            int _4495 = uCells_1._member0[Globals.uLookupBuckets].x + ((_4242 - 1) * 6);
                                                                            float _4511 = intBitsToFloat(uCellPages_1._member0[_4495 + 3]);
                                                                            vec3 _4513 = world - vec3(intBitsToFloat(uCellPages_1._member0[_4495]), intBitsToFloat(uCellPages_1._member0[_4495 + 1]), intBitsToFloat(uCellPages_1._member0[_4495 + 2]));
                                                                            if (dot(_4513, _4513) > (_4511 * _4511))
                                                                            {
                                                                                _4491 = ivec2(0);
                                                                            }
                                                                            else
                                                                            {
                                                                                _4491 = ivec2(uCellPages_1._member0[_4495 + 4], uCellPages_1._member0[_4495 + 5]);
                                                                            }
                                                                            _4244 = _4491;
                                                                        }
                                                                        bool _4245 = _4240;
                                                                        bool _4246 = _4241;
                                                                        int _4247 = 0;
                                                                        for (;;)
                                                                        {
                                                                            bool _4322_ladder_break = false;
                                                                            {
                                                                                if (_4247 < _4244.y)
                                                                                {
                                                                                    _4248 = !_4245;
                                                                                }
                                                                                else
                                                                                {
                                                                                    _4248 = false;
                                                                                }
                                                                                if (!_4248)
                                                                                {
                                                                                    _4322_ladder_break = true;
                                                                                }
                                                                                else
                                                                                {
                                                                                    int _4339 = _4244.x + _4247;
                                                                                    int _4342 = uCellPages_1._member0[_4339] * 10;
                                                                                    if (!((uPages_1._member0[_4342 + 5].w > 0.5) == _4310))
                                                                                    {
                                                                                        int _4351 = _4342 + 9;
                                                                                        vec3 _4355 = world - uPages_1._member0[_4351].xyz;
                                                                                        if (!(dot(_4355, _4355) > (uPages_1._member0[_4351].w * uPages_1._member0[_4351].w)))
                                                                                        {
                                                                                            int _4529 = uCellPages_1._member0[_4339] * 10;
                                                                                            vec4 _4256 = uPages_1._member0[_4529 + 1];
                                                                                            int _4535 = _4529 + 2;
                                                                                            int _4538 = _4529 + 3;
                                                                                            int _4541 = _4529 + 4;
                                                                                            int _4547 = _4529 + 6;
                                                                                            int _4550 = _4529 + 7;
                                                                                            int _4553 = _4529 + 8;
                                                                                            vec3 _4560 = world - vec3(uPages_1._member0[_4547].w, uPages_1._member0[_4550].w, uPages_1._member0[_4553].w);
                                                                                            vec3 _4254 = vec3(dot(uPages_1._member0[_4547].xyz, vec3(-0.0)), dot(uPages_1._member0[_4550].xyz, vec3(-0.0)), dot(uPages_1._member0[_4553].xyz, vec3(-0.0)));
                                                                                            vec3 _4573 = vec3(dot(uPages_1._member0[_4547].xyz, _4560), dot(uPages_1._member0[_4550].xyz, _4560), dot(uPages_1._member0[_4553].xyz, _4560)) - uPages_1._member0[_4535].xyz;
                                                                                            vec2 _4576 = vec2(uPages_1._member0[_4535].w, uPages_1._member0[_4538].w);
                                                                                            bvec2 _6094 = isnan(_4576);
                                                                                            bvec2 _6095 = isnan(vec2(9.9999999747524270787835121154785e-07));
                                                                                            vec2 _6096 = max(_4576, vec2(9.9999999747524270787835121154785e-07));
                                                                                            vec2 _6097 = vec2(_6094.x ? vec2(9.9999999747524270787835121154785e-07).x : _6096.x, _6094.y ? vec2(9.9999999747524270787835121154785e-07).y : _6096.y);
                                                                                            vec2 _4583 = vec2(dot(_4573, uPages_1._member0[_4538].xyz), dot(_4573, uPages_1._member0[_4541].xyz)) / vec2(_6095.x ? _4576.x : _6097.x, _6095.y ? _4576.y : _6097.y);
                                                                                            vec2 _4249 = _4583;
                                                                                            float _4251 = -dot(_4573, uPages_1._member0[_4529 + 5].xyz);
                                                                                            float _4252 = uPages_1._member0[_4541].w;
                                                                                            vec3 _4253 = uPages_1._member0[_4529 + 5].xyz;
                                                                                            if (abs(_4583.x) > 1.0)
                                                                                            {
                                                                                                _4257 = true;
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                _4257 = abs(_4249.y) > 1.0;
                                                                                            }
                                                                                            if (!(_4257))
                                                                                            {
                                                                                                if (false)
                                                                                                {
                                                                                                    _4258 = dot(_4253, _4254) < (-0.0500000007450580596923828125);
                                                                                                }
                                                                                                else
                                                                                                {
                                                                                                    _4258 = false;
                                                                                                }
                                                                                                if (!(_4258))
                                                                                                {
                                                                                                    if (_4251 < (-0.25))
                                                                                                    {
                                                                                                        _4259 = true;
                                                                                                    }
                                                                                                    else
                                                                                                    {
                                                                                                        _4259 = _4251 > (_4252 + 0.25);
                                                                                                    }
                                                                                                    if (!(_4259))
                                                                                                    {
                                                                                                        vec2 _4413 = (_4256.xy + (((_4249 * 0.5) + vec2(0.5)) * _4256.zw)) / _4290;
                                                                                                        if (!(textureLod(_6006, _4413, 0.0).w < 0.5))
                                                                                                        {
                                                                                                            float _4433 = abs((textureLod(_6010, _4413, 0.0).x * _4252) - _4251);
                                                                                                            if (_4433 < _4117)
                                                                                                            {
                                                                                                                _4117 = _4433;
                                                                                                                _4115 = _4413;
                                                                                                                _4260 = _4433 < 0.0199999995529651641845703125;
                                                                                                                _4261 = true;
                                                                                                            }
                                                                                                            else
                                                                                                            {
                                                                                                                _4260 = _4245;
                                                                                                                _4261 = _4246;
                                                                                                            }
                                                                                                            _4245 = _4260;
                                                                                                            _4246 = _4261;
                                                                                                        }
                                                                                                    }
                                                                                                }
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                            if (_4322_ladder_break)
                                                                            {
                                                                                break;
                                                                            }
                                                                            _4247++;
                                                                            continue;
                                                                        }
                                                                        _4240 = _4245;
                                                                        _4241 = _4246;
                                                                        _4242++;
                                                                        continue;
                                                                    }
                                                                    _4237 = _4241;
                                                                }
                                                            }
                                                            if (!_4237)
                                                            {
                                                                _4114 = vec4(1.0, 0.0, 0.0, 1.0);
                                                            }
                                                            else
                                                            {
                                                                uvec2 _4146 = uvec2(textureSize(_6004, 0));
                                                                vec2 _4157 = abs(_4115 - cardUv) * vec2(float(_4146.x), float(_4146.y));
                                                                float _4158 = _4157.x;
                                                                float _4159 = _4157.y;
                                                                vec4 _4120;
                                                                if ((isnan(_4159) ? _4158 : (isnan(_4158) ? _4159 : max(_4158, _4159))) < 1.5)
                                                                {
                                                                    _4120 = vec4(0.0, 1.0, 0.0, 1.0);
                                                                }
                                                                else
                                                                {
                                                                    _4120 = vec4(1.0, 1.0, 0.0, 1.0);
                                                                }
                                                                _4114 = _4120;
                                                            }
                                                        }
                                                    }
                                                    else
                                                    {
                                                        if (Globals.uProbe == 4)
                                                        {
                                                            _4588 = false;
                                                            vec4 _4589;
                                                            {
                                                                int _4608 = max((Globals.uShadowLevels - 1), 0);
                                                                vec3 _4614 = world + ((_417 * Globals.uClipmapOrigin.data[0].w) * 1.5);
                                                                float _4623 = (Globals.uClipmapOrigin.data[0].w * float(Globals.uShadowResolution)) * float(1 << (Globals.uShadowLevels - 1));
                                                                int _4590 = 0;
                                                                float _4591 = 0.0;
                                                                bool _4592;
                                                                bool _4593;
                                                                float _4595;
                                                                float _4681;
                                                                bool _4683;
                                                                for (;;)
                                                                {
                                                                    if (_4590 < 64)
                                                                    {
                                                                        _4592 = _4591 < _4623;
                                                                    }
                                                                    else
                                                                    {
                                                                        _4592 = false;
                                                                    }
                                                                    if (!_4592)
                                                                    {
                                                                        break;
                                                                    }
                                                                    vec3 _4642 = _4614 + (Globals.uSunDirection * _4591);
                                                                    _4680 = false;
                                                                    {
                                                                        _4593 = false;
                                                                        _4595 = Globals.uClipmapOrigin.data[0].w;
                                                                        int _4682 = 0;
                                                                        for (;;)
                                                                        {
                                                                            bool _4694_ladder_break = false;
                                                                            {
                                                                                if (!(_4682 < Globals.uShadowLevels))
                                                                                {
                                                                                    _4694_ladder_break = true;
                                                                                }
                                                                                else
                                                                                {
                                                                                    vec3 _4709 = (_4642 - Globals.uClipmapOrigin.data[_4682].xyz) / vec3(Globals.uClipmapOrigin.data[_4682].w);
                                                                                    if (any(lessThan(_4709, vec3(0.5))))
                                                                                    {
                                                                                        _4683 = true;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        _4683 = any(greaterThan(_4709, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                                    }
                                                                                    if (!(_4683))
                                                                                    {
                                                                                        _4593 = true;
                                                                                        _4595 = Globals.uClipmapOrigin.data[_4682].w;
                                                                                        _4680 = true;
                                                                                        _4681 = ((textureLod(_6012, vec3(_4709.x / float(Globals.uShadowResolution), _4709.y / float(Globals.uShadowResolution), ((float(_4682) * float(Globals.uShadowResolution)) + _4709.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_4682];
                                                                                        _4694_ladder_break = true;
                                                                                    }
                                                                                }
                                                                            }
                                                                            if (_4694_ladder_break)
                                                                            {
                                                                                break;
                                                                            }
                                                                            _4682++;
                                                                            continue;
                                                                        }
                                                                        if (!(_4680))
                                                                        {
                                                                            _4680 = true;
                                                                            _4681 = 1000000.0;
                                                                        }
                                                                    }
                                                                    if (!_4593)
                                                                    {
                                                                        _4588 = true;
                                                                        _4589 = vec4(1.0, 0.0, _4591 / _4623, 1.0);
                                                                        break;
                                                                    }
                                                                    float _4781 = 2.0 * _4595;
                                                                    if (_4681 < ((0.5 * _4595) * clamp(_4591 / (isnan(9.9999999747524270787835121154785e-07) ? _4781 : (isnan(_4781) ? 9.9999999747524270787835121154785e-07 : max(_4781, 9.9999999747524270787835121154785e-07))), 0.0, 1.0)))
                                                                    {
                                                                        _4588 = true;
                                                                        _4589 = vec4(0.0, _4595 / Globals.uClipmapOrigin.data[_4608].w, _4591 / _4623, 1.0);
                                                                        break;
                                                                    }
                                                                    float _4662 = _4595 * 0.25;
                                                                    _4590++;
                                                                    _4591 += (isnan(_4662) ? _4681 : (isnan(_4681) ? _4662 : max(_4681, _4662)));
                                                                    continue;
                                                                }
                                                                if (!(_4588))
                                                                {
                                                                    _4588 = true;
                                                                    _4589 = vec4(0.5, 0.0, clamp(_4591 / _4623, 0.0, 1.0), 1.0);
                                                                }
                                                            }
                                                            _4114 = _4589;
                                                        }
                                                        else
                                                        {
                                                            if (Globals.uProbe == 2)
                                                            {
                                                                _4114 = vec4(clamp((world - Globals.uProbeMin) * Globals.uProbeInvExtent, vec3(0.0), vec3(1.0)), 1.0);
                                                            }
                                                            else
                                                            {
                                                                if (Globals.uProbe == 3)
                                                                {
                                                                    _4114 = vec4((_417 * 0.5) + vec3(0.5), 1.0);
                                                                }
                                                                else
                                                                {
                                                                    vec3 _4199 = world + ((_417 * Globals.uClipmapOrigin.data[0].w) * 1.5);
                                                                    _4790 = false;
                                                                    bool _4121;
                                                                    float _4122;
                                                                    float _4791;
                                                                    {
                                                                        _4121 = false;
                                                                        _4122 = 0.0;
                                                                        int _4792 = 0;
                                                                        bool _4793;
                                                                        for (;;)
                                                                        {
                                                                            bool _4804_ladder_break = false;
                                                                            {
                                                                                if (!(_4792 < Globals.uShadowLevels))
                                                                                {
                                                                                    _4804_ladder_break = true;
                                                                                }
                                                                                else
                                                                                {
                                                                                    vec3 _4819 = (_4199 - Globals.uClipmapOrigin.data[_4792].xyz) / vec3(Globals.uClipmapOrigin.data[_4792].w);
                                                                                    if (any(lessThan(_4819, vec3(0.5))))
                                                                                    {
                                                                                        _4793 = true;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        _4793 = any(greaterThan(_4819, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                                    }
                                                                                    if (!(_4793))
                                                                                    {
                                                                                        _4121 = true;
                                                                                        vec4 _4866 = textureLod(_6012, vec3(_4819.x / float(Globals.uShadowResolution), _4819.y / float(Globals.uShadowResolution), ((float(_4792) * float(Globals.uShadowResolution)) + _4819.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0);
                                                                                        float _4868 = _4866.x;
                                                                                        _4122 = _4868;
                                                                                        _4790 = true;
                                                                                        _4791 = ((_4868 * 2.0) - 1.0) * Globals.uClipmapRange.data[_4792];
                                                                                        _4804_ladder_break = true;
                                                                                    }
                                                                                }
                                                                            }
                                                                            if (_4804_ladder_break)
                                                                            {
                                                                                break;
                                                                            }
                                                                            _4792++;
                                                                            continue;
                                                                        }
                                                                        if (!(_4790))
                                                                        {
                                                                            _4790 = true;
                                                                            _4791 = 1000000.0;
                                                                        }
                                                                    }
                                                                    float _4124;
                                                                    if (Globals.uShadowLevels > 0)
                                                                    {
                                                                        _4124 = clamp(Globals.uClipmapRange.data[0] / (Globals.uClipmapOrigin.data[0].w * 4.0), 0.0, 1.0);
                                                                    }
                                                                    else
                                                                    {
                                                                        _4124 = 0.0;
                                                                    }
                                                                    float _4125;
                                                                    if (_4121)
                                                                    {
                                                                        _4125 = clamp(_4791 / (Globals.uClipmapOrigin.data[0].w * 4.0), 0.0, 1.0);
                                                                    }
                                                                    else
                                                                    {
                                                                        _4125 = 1.0;
                                                                    }
                                                                    float _4126;
                                                                    if (_4121)
                                                                    {
                                                                        _4126 = 1.0;
                                                                    }
                                                                    else
                                                                    {
                                                                        _4126 = 0.5;
                                                                    }
                                                                    _4114 = vec4(_4124, _4122, _4125, _4126);
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                                imageStore(uDirect, ivec2(uvec2(texelAt)), _4114);
                                            }
                                            else
                                            {
                                                float _2222 = dot(_417, Globals.uSunDirection);
                                                float _2223 = isnan(0.0) ? _2222 : (isnan(_2222) ? 0.0 : max(_2222, 0.0));
                                                if (_2223 > 0.0)
                                                {
                                                    _4897 = false;
                                                    float _4898;
                                                    {
                                                        if (Globals.uShadowLevels <= 0)
                                                        {
                                                            _4897 = true;
                                                            _4898 = 1.0;
                                                        }
                                                        else
                                                        {
                                                            vec3 _4921 = world + ((_417 * Globals.uClipmapOrigin.data[0].w) * 1.5);
                                                            float _4932 = (Globals.uClipmapOrigin.data[0].w * float(Globals.uShadowResolution)) * float(1 << (Globals.uShadowLevels - 1));
                                                            int _4899 = 0;
                                                            float _4900 = 0.0;
                                                            bool _4901;
                                                            bool _4902;
                                                            float _4904;
                                                            float _4979;
                                                            bool _4981;
                                                            for (;;)
                                                            {
                                                                if (_4899 < 64)
                                                                {
                                                                    _4901 = _4900 < _4932;
                                                                }
                                                                else
                                                                {
                                                                    _4901 = false;
                                                                }
                                                                if (!_4901)
                                                                {
                                                                    break;
                                                                }
                                                                vec3 _4949 = _4921 + (Globals.uSunDirection * _4900);
                                                                _4978 = false;
                                                                {
                                                                    _4902 = false;
                                                                    _4904 = Globals.uClipmapOrigin.data[0].w;
                                                                    int _4980 = 0;
                                                                    for (;;)
                                                                    {
                                                                        bool _4992_ladder_break = false;
                                                                        {
                                                                            if (!(_4980 < Globals.uShadowLevels))
                                                                            {
                                                                                _4992_ladder_break = true;
                                                                            }
                                                                            else
                                                                            {
                                                                                vec3 _5007 = (_4949 - Globals.uClipmapOrigin.data[_4980].xyz) / vec3(Globals.uClipmapOrigin.data[_4980].w);
                                                                                if (any(lessThan(_5007, vec3(0.5))))
                                                                                {
                                                                                    _4981 = true;
                                                                                }
                                                                                else
                                                                                {
                                                                                    _4981 = any(greaterThan(_5007, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                                }
                                                                                if (!(_4981))
                                                                                {
                                                                                    _4902 = true;
                                                                                    _4904 = Globals.uClipmapOrigin.data[_4980].w;
                                                                                    _4978 = true;
                                                                                    _4979 = ((textureLod(_6012, vec3(_5007.x / float(Globals.uShadowResolution), _5007.y / float(Globals.uShadowResolution), ((float(_4980) * float(Globals.uShadowResolution)) + _5007.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_4980];
                                                                                    _4992_ladder_break = true;
                                                                                }
                                                                            }
                                                                        }
                                                                        if (_4992_ladder_break)
                                                                        {
                                                                            break;
                                                                        }
                                                                        _4980++;
                                                                        continue;
                                                                    }
                                                                    if (!(_4978))
                                                                    {
                                                                        _4978 = true;
                                                                        _4979 = 1000000.0;
                                                                    }
                                                                }
                                                                if (!_4902)
                                                                {
                                                                    _4897 = true;
                                                                    _4898 = 1.0;
                                                                    break;
                                                                }
                                                                float _5079 = 2.0 * _4904;
                                                                if (_4979 < ((0.5 * _4904) * clamp(_4900 / (isnan(9.9999999747524270787835121154785e-07) ? _5079 : (isnan(_5079) ? 9.9999999747524270787835121154785e-07 : max(_5079, 9.9999999747524270787835121154785e-07))), 0.0, 1.0)))
                                                                {
                                                                    _4897 = true;
                                                                    _4898 = 0.0;
                                                                    break;
                                                                }
                                                                float _4964 = _4904 * 0.25;
                                                                _4899++;
                                                                _4900 += (isnan(_4964) ? _4979 : (isnan(_4979) ? _4964 : max(_4979, _4964)));
                                                                continue;
                                                            }
                                                            if (!(_4897))
                                                            {
                                                                _4897 = true;
                                                                _4898 = 1.0;
                                                            }
                                                        }
                                                    }
                                                    visibility = _4898;
                                                }
                                                else
                                                {
                                                    visibility = 1.0;
                                                }
                                                vec3 _5089;
                                                {
                                                    if (Globals.uShadowLevels <= 0)
                                                    {
                                                        vec3 _5170;
                                                        {
                                                            if (Globals.uSkyShValid == 0)
                                                            {
                                                                _5170 = Globals.uSkyColour * ((_417.z * 0.5) + 0.5);
                                                            }
                                                            else
                                                            {
                                                                vec4 _5185 = vec4(_417, 1.0);
                                                                vec4 _5188 = _5185.xyzz * _5185.yzzx;
                                                                float _5214 = _417.x;
                                                                float _5216 = _417.y;
                                                                vec3 _5221 = (vec3(dot(Globals.uSkySh.data[0], _5185), dot(Globals.uSkySh.data[1], _5185), dot(Globals.uSkySh.data[2], _5185)) + vec3(dot(Globals.uSkySh.data[3], _5188), dot(Globals.uSkySh.data[4], _5188), dot(Globals.uSkySh.data[5], _5188))) + (Globals.uSkySh.data[6].xyz * ((_5214 * _5214) - (_5216 * _5216)));
                                                                bvec3 _6129 = isnan(vec3(0.0));
                                                                bvec3 _6130 = isnan(_5221);
                                                                vec3 _6131 = max(vec3(0.0), _5221);
                                                                vec3 _6132 = vec3(_6129.x ? _5221.x : _6131.x, _6129.y ? _5221.y : _6131.y, _6129.z ? _5221.z : _6131.z);
                                                                _5170 = vec3(_6130.x ? vec3(0.0).x : _6132.x, _6130.y ? vec3(0.0).y : _6132.y, _6130.z ? vec3(0.0).z : _6132.z);
                                                            }
                                                        }
                                                        _5089 = _5170 * 3.1415927410125732421875;
                                                    }
                                                    else
                                                    {
                                                        vec3 _5090;
                                                        if (abs(_417.z) < 0.89999997615814208984375)
                                                        {
                                                            _5090 = vec3(0.0, 0.0, 1.0);
                                                        }
                                                        else
                                                        {
                                                            _5090 = vec3(1.0, 0.0, 0.0);
                                                        }
                                                        vec3 _5111 = normalize(cross(_417, _5090));
                                                        vec3 _5112 = cross(_417, _5111);
                                                        vec3 _5114 = floor(world * 8.0);
                                                        float _5118 = fract(sin(dot(_5114, vec3(12.98980045318603515625, 78.233001708984375, 37.71900177001953125))) * 43758.546875);
                                                        float _5122 = fract(sin(dot(_5114, vec3(39.34600067138671875, 11.1350002288818359375, 83.154998779296875))) * 24634.634765625);
                                                        int _5092 = 0;
                                                        vec3 _5091 = vec3(0.0);
                                                        vec3 _5254;
                                                        float _5314;
                                                        bool _5317;
                                                        bool _5318;
                                                        float _5320;
                                                        float _5395;
                                                        bool _5397;
                                                        for (;;)
                                                        {
                                                            if (!(_5092 < 8))
                                                            {
                                                                break;
                                                            }
                                                            float _5134 = (float(_5092) + _5122) * 0.125;
                                                            uint _5227 = uint(_5092);
                                                            uint _5230 = (_5227 << 16u) | (_5227 >> 16u);
                                                            uint _5235 = ((_5230 & 1431655765u) << 1u) | ((_5230 & 2863311530u) >> 1u);
                                                            uint _5240 = ((_5235 & 858993459u) << 2u) | ((_5235 & 3435973836u) >> 2u);
                                                            uint _5245 = ((_5240 & 252645135u) << 4u) | ((_5240 & 4042322160u) >> 4u);
                                                            float _5139 = sqrt(_5134);
                                                            float _5140 = 6.283185482025146484375 * fract((float(((_5245 & 16711935u) << 8u) | ((_5245 & 4278255360u) >> 8u)) * 2.3283064365386962890625e-10) + _5118);
                                                            float _5148 = 1.0 - _5134;
                                                            vec3 _5153 = normalize(((_5111 * (_5139 * cos(_5140))) + (_5112 * (_5139 * sin(_5140)))) + (_417 * sqrt(isnan(_5148) ? 0.0 : (isnan(0.0) ? _5148 : max(0.0, _5148)))));
                                                            {
                                                                if (Globals.uSkyShValid == 0)
                                                                {
                                                                    _5254 = Globals.uSkyColour * ((_5153.z * 0.5) + 0.5);
                                                                }
                                                                else
                                                                {
                                                                    vec4 _5269 = vec4(_5153, 1.0);
                                                                    vec4 _5272 = _5269.xyzz * _5269.yzzx;
                                                                    float _5298 = _5153.x;
                                                                    float _5300 = _5153.y;
                                                                    vec3 _5305 = (vec3(dot(Globals.uSkySh.data[0], _5269), dot(Globals.uSkySh.data[1], _5269), dot(Globals.uSkySh.data[2], _5269)) + vec3(dot(Globals.uSkySh.data[3], _5272), dot(Globals.uSkySh.data[4], _5272), dot(Globals.uSkySh.data[5], _5272))) + (Globals.uSkySh.data[6].xyz * ((_5298 * _5298) - (_5300 * _5300)));
                                                                    bvec3 _6139 = isnan(vec3(0.0));
                                                                    bvec3 _6140 = isnan(_5305);
                                                                    vec3 _6141 = max(vec3(0.0), _5305);
                                                                    vec3 _6142 = vec3(_6139.x ? _5305.x : _6141.x, _6139.y ? _5305.y : _6141.y, _6139.z ? _5305.z : _6141.z);
                                                                    _5254 = vec3(_6140.x ? vec3(0.0).x : _6142.x, _6140.y ? vec3(0.0).y : _6142.y, _6140.z ? vec3(0.0).z : _6142.z);
                                                                }
                                                            }
                                                            _5313 = false;
                                                            {
                                                                if (Globals.uShadowLevels <= 0)
                                                                {
                                                                    _5313 = true;
                                                                    _5314 = 1.0;
                                                                }
                                                                else
                                                                {
                                                                    vec3 _5337 = world + ((_417 * Globals.uClipmapOrigin.data[0].w) * 1.5);
                                                                    float _5348 = (Globals.uClipmapOrigin.data[0].w * float(Globals.uShadowResolution)) * float(1 << (Globals.uShadowLevels - 1));
                                                                    int _5315 = 0;
                                                                    float _5316 = 0.0;
                                                                    for (;;)
                                                                    {
                                                                        if (_5315 < 64)
                                                                        {
                                                                            _5317 = _5316 < _5348;
                                                                        }
                                                                        else
                                                                        {
                                                                            _5317 = false;
                                                                        }
                                                                        if (!_5317)
                                                                        {
                                                                            break;
                                                                        }
                                                                        vec3 _5365 = _5337 + (_5153 * _5316);
                                                                        _5394 = false;
                                                                        {
                                                                            _5318 = false;
                                                                            _5320 = Globals.uClipmapOrigin.data[0].w;
                                                                            int _5396 = 0;
                                                                            for (;;)
                                                                            {
                                                                                bool _5408_ladder_break = false;
                                                                                {
                                                                                    if (!(_5396 < Globals.uShadowLevels))
                                                                                    {
                                                                                        _5408_ladder_break = true;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        vec3 _5423 = (_5365 - Globals.uClipmapOrigin.data[_5396].xyz) / vec3(Globals.uClipmapOrigin.data[_5396].w);
                                                                                        if (any(lessThan(_5423, vec3(0.5))))
                                                                                        {
                                                                                            _5397 = true;
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            _5397 = any(greaterThan(_5423, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                                        }
                                                                                        if (!(_5397))
                                                                                        {
                                                                                            _5318 = true;
                                                                                            _5320 = Globals.uClipmapOrigin.data[_5396].w;
                                                                                            _5394 = true;
                                                                                            _5395 = ((textureLod(_6012, vec3(_5423.x / float(Globals.uShadowResolution), _5423.y / float(Globals.uShadowResolution), ((float(_5396) * float(Globals.uShadowResolution)) + _5423.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_5396];
                                                                                            _5408_ladder_break = true;
                                                                                        }
                                                                                    }
                                                                                }
                                                                                if (_5408_ladder_break)
                                                                                {
                                                                                    break;
                                                                                }
                                                                                _5396++;
                                                                                continue;
                                                                            }
                                                                            if (!(_5394))
                                                                            {
                                                                                _5394 = true;
                                                                                _5395 = 1000000.0;
                                                                            }
                                                                        }
                                                                        if (!_5318)
                                                                        {
                                                                            _5313 = true;
                                                                            _5314 = 1.0;
                                                                            break;
                                                                        }
                                                                        float _5495 = 2.0 * _5320;
                                                                        if (_5395 < ((0.5 * _5320) * clamp(_5316 / (isnan(9.9999999747524270787835121154785e-07) ? _5495 : (isnan(_5495) ? 9.9999999747524270787835121154785e-07 : max(_5495, 9.9999999747524270787835121154785e-07))), 0.0, 1.0)))
                                                                        {
                                                                            _5313 = true;
                                                                            _5314 = 0.0;
                                                                            break;
                                                                        }
                                                                        float _5380 = _5320 * 0.25;
                                                                        _5315++;
                                                                        _5316 += (isnan(_5380) ? _5395 : (isnan(_5395) ? _5380 : max(_5395, _5380)));
                                                                        continue;
                                                                    }
                                                                    if (!(_5313))
                                                                    {
                                                                        _5313 = true;
                                                                        _5314 = 1.0;
                                                                    }
                                                                }
                                                            }
                                                            _5092++;
                                                            _5091 += (_5254 * _5314);
                                                            continue;
                                                        }
                                                        _5089 = _5091 * 0.3926990926265716552734375;
                                                    }
                                                }
                                                light = 0;
                                                lit = ((Globals.uSunColour * _2223) * visibility) + _5089;
                                                float aim;
                                                float reaches;
                                                float _5505;
                                                float _5756;
                                                bool _5759;
                                                bool _5760;
                                                float _5762;
                                                float _5832;
                                                bool _5834;
                                                for (;;)
                                                {
                                                    bool _151_ladder_break = false;
                                                    {
                                                        if (!(light < Globals.uLightCount))
                                                        {
                                                            _151_ladder_break = true;
                                                        }
                                                        else
                                                        {
                                                            int _2434 = light * 3;
                                                            int _2437 = _2434 + 1;
                                                            int _2440 = _2434 + 2;
                                                            vec3 delta = uLights_1._member0[_2434].xyz - world;
                                                            float _2445 = dot(delta, delta);
                                                            float _2447 = uLights_1._member0[_2434].w * 3.0;
                                                            float _2449 = isnan(2.0) ? _2447 : (isnan(_2447) ? 2.0 : max(_2447, 2.0));
                                                            float reachSquared = _2449 * _2449;
                                                            if (!(_2445 >= reachSquared))
                                                            {
                                                                vec3 toLight = delta * inversesqrt(isnan(9.9999999747524270787835121154785e-07) ? _2445 : (isnan(_2445) ? 9.9999999747524270787835121154785e-07 : max(_2445, 9.9999999747524270787835121154785e-07)));
                                                                float _2457 = dot(_417, toLight);
                                                                float _2458 = isnan(0.0) ? _2457 : (isnan(_2457) ? 0.0 : max(_2457, 0.0));
                                                                if (!(_2458 <= 0.0))
                                                                {
                                                                    float _2468 = clamp(1.0 - ((_2445 * _2445) / (reachSquared * reachSquared)), 0.0, 1.0);
                                                                    if (dot(uLights_1._member0[_2440].xyz, uLights_1._member0[_2440].xyz) > 0.25)
                                                                    {
                                                                        float _2475 = dot(normalize(uLights_1._member0[_2440].xyz), -toLight);
                                                                        aim = isnan(0.0) ? _2475 : (isnan(_2475) ? 0.0 : max(_2475, 0.0));
                                                                    }
                                                                    else
                                                                    {
                                                                        aim = 1.0;
                                                                    }
                                                                    float contribution = (((((uLights_1._member0[_2437].w * Globals.uLocalScale) * _2458) * (1.0 / (_2445 + 1.0))) * _2468) * _2468) * aim;
                                                                    if (!((contribution * dot(uLights_1._member0[_2437].xyz, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875))) < 9.9999997473787516355514526367188e-06))
                                                                    {
                                                                        int _2504 = floatBitsToInt(uLights_1._member0[_2440].w);
                                                                        {
                                                                            if (_2504 < 0)
                                                                            {
                                                                                _5505 = -1.0;
                                                                            }
                                                                            else
                                                                            {
                                                                                uint _5506 = uvec3(textureSize(_6022, 0)).x;
                                                                                float _5509 = 0.25;
                                                                                int _5510 = 0;
                                                                                for (;;)
                                                                                {
                                                                                    if (!(_5510 < 6))
                                                                                    {
                                                                                        break;
                                                                                    }
                                                                                    int _5543 = ((_2504 + _5510) * 5) + 3;
                                                                                    float _5549 = dot(uLampMapRecords_1._member0[_5543].xyz, world) + uLampMapRecords_1._member0[_5543].w;
                                                                                    _5509 = isnan(_5549) ? _5509 : (isnan(_5509) ? _5549 : max(_5509, _5549));
                                                                                    _5510++;
                                                                                    continue;
                                                                                }
                                                                                vec3 _5567 = world + (_417 * (0.0500000007450580596923828125 + (1.5 * ((_5509 * 2.0) / float(max(_5506, 1u))))));
                                                                                float _5511 = -1000000015047466219876688855040.0;
                                                                                int _5512 = _2504;
                                                                                _5510 = 0;
                                                                                for (;;)
                                                                                {
                                                                                    if (!(_5510 < 6))
                                                                                    {
                                                                                        break;
                                                                                    }
                                                                                    int _5577 = _2504 + _5510;
                                                                                    int _5579 = (_5577 * 5) + 3;
                                                                                    float _5585 = dot(uLampMapRecords_1._member0[_5579].xyz, _5567) + uLampMapRecords_1._member0[_5579].w;
                                                                                    if (_5585 > _5511)
                                                                                    {
                                                                                        _5511 = _5585;
                                                                                        _5512 = _5577;
                                                                                    }
                                                                                    _5510++;
                                                                                    continue;
                                                                                }
                                                                                int _5597 = _5512 * 5;
                                                                                int _5598 = _5597 + 4;
                                                                                if (uLampMapRecords_1._member0[_5598].z <= 0.0)
                                                                                {
                                                                                    _5505 = -1.0;
                                                                                }
                                                                                else
                                                                                {
                                                                                    int _5607 = _5597 + 1;
                                                                                    if (_5511 <= (uLampMapRecords_1._member0[_5598].y / ((-1.0) - uLampMapRecords_1._member0[_5598].x)))
                                                                                    {
                                                                                        _5505 = 1.0;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        vec2 _5629 = vec2(dot(uLampMapRecords_1._member0[_5597].xyz, _5567) + uLampMapRecords_1._member0[_5597].w, dot(uLampMapRecords_1._member0[_5607].xyz, _5567) + uLampMapRecords_1._member0[_5607].w) / vec2(_5511);
                                                                                        uvec3 _5638 = uvec3(textureSize(_6022, 0));
                                                                                        uint _5639 = _5638.x;
                                                                                        ivec2 _5646 = ivec2(int(_5639), int(_5638.y));
                                                                                        float _5647 = length(uLampMapRecords_1._member0[_5597].xyz);
                                                                                        float _5660 = (0.0500000007450580596923828125 + (0.004999999888241291046142578125 * _5511)) + (2.0 * ((_5511 * (2.0 / (isnan(0.001000000047497451305389404296875) ? _5647 : (isnan(_5647) ? 0.001000000047497451305389404296875 : max(_5647, 0.001000000047497451305389404296875))))) / float(max(_5639, 1u))));
                                                                                        vec2 _5664 = (vec2((_5629.x * 0.5) + 0.5, 0.5 - (_5629.y * 0.5)) * vec2(_5646)) - vec2(0.5);
                                                                                        vec2 _5665 = floor(_5664);
                                                                                        ivec2 _5668 = ivec2(_5665) - ivec2(1);
                                                                                        vec2 _5669 = _5664 - _5665;
                                                                                        int _5518 = 0;
                                                                                        float _5516 = 0.0;
                                                                                        float _5517 = 0.0;
                                                                                        for (;;)
                                                                                        {
                                                                                            if (!(_5518 < 4))
                                                                                            {
                                                                                                break;
                                                                                            }
                                                                                            int _5520 = 0;
                                                                                            float _5519 = _5517;
                                                                                            for (;;)
                                                                                            {
                                                                                                if (!(_5520 < 4))
                                                                                                {
                                                                                                    break;
                                                                                                }
                                                                                                int _5688 = _5520;
                                                                                                float _5702 = ((texelFetch(_6022, ivec4(clamp(_5668 + ivec2(_5688, _5518), ivec2(0), _5646 - ivec2(1)), _5512, 0).xyz, 0).x * 2.0) - 1.0) - uLampMapRecords_1._member0[_5598].x;
                                                                                                vec2 _5754 = clamp(vec2(1.0) - (abs(vec2(float(_5688) - 1.0, float(_5518) - 1.0) - _5669) * vec2(0.5)), vec2(0.0), vec2(1.0));
                                                                                                float _5721 = _5754.x * _5754.y;
                                                                                                if ((uLampMapRecords_1._member0[_5598].y / (isnan(-9.9999999747524270787835121154785e-07) ? _5702 : (isnan(_5702) ? (-9.9999999747524270787835121154785e-07) : min(_5702, -9.9999999747524270787835121154785e-07)))) >= (_5511 - _5660))
                                                                                                {
                                                                                                    _5509 = _5721;
                                                                                                }
                                                                                                else
                                                                                                {
                                                                                                    _5509 = 0.0;
                                                                                                }
                                                                                                _5520++;
                                                                                                _5516 += _5509;
                                                                                                _5519 += _5721;
                                                                                                continue;
                                                                                            }
                                                                                            _5518++;
                                                                                            _5517 = _5519;
                                                                                            continue;
                                                                                        }
                                                                                        _5505 = _5516 / (isnan(9.9999997473787516355514526367188e-05) ? _5517 : (isnan(_5517) ? 9.9999997473787516355514526367188e-05 : max(_5517, 9.9999997473787516355514526367188e-05)));
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                        if (_5505 < 0.0)
                                                                        {
                                                                            _5755 = false;
                                                                            {
                                                                                if (Globals.uShadowLevels <= 0)
                                                                                {
                                                                                    _5755 = true;
                                                                                    _5756 = 1.0;
                                                                                }
                                                                                else
                                                                                {
                                                                                    vec3 _5779 = world + ((_417 * Globals.uClipmapOrigin.data[0].w) * 1.5);
                                                                                    vec3 _5780 = uLights_1._member0[_2434].xyz - _5779;
                                                                                    float _5781 = length(_5780);
                                                                                    float _5783 = _5781 - (isnan(Globals.uClipmapOrigin.data[0].w) ? 0.119999997317790985107421875 : (isnan(0.119999997317790985107421875) ? Globals.uClipmapOrigin.data[0].w : max(0.119999997317790985107421875, Globals.uClipmapOrigin.data[0].w)));
                                                                                    if (_5783 <= 0.0)
                                                                                    {
                                                                                        _5755 = true;
                                                                                        _5756 = 1.0;
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        vec3 _5788 = _5780 / vec3(_5781);
                                                                                        int _5757 = 0;
                                                                                        float _5758 = 0.0;
                                                                                        for (;;)
                                                                                        {
                                                                                            if (_5757 < 48)
                                                                                            {
                                                                                                _5759 = _5758 < _5783;
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                _5759 = false;
                                                                                            }
                                                                                            if (!_5759)
                                                                                            {
                                                                                                break;
                                                                                            }
                                                                                            vec3 _5805 = _5779 + (_5788 * _5758);
                                                                                            _5831 = false;
                                                                                            {
                                                                                                _5760 = false;
                                                                                                _5762 = Globals.uClipmapOrigin.data[0].w;
                                                                                                int _5833 = 0;
                                                                                                for (;;)
                                                                                                {
                                                                                                    bool _5845_ladder_break = false;
                                                                                                    {
                                                                                                        if (!(_5833 < Globals.uShadowLevels))
                                                                                                        {
                                                                                                            _5845_ladder_break = true;
                                                                                                        }
                                                                                                        else
                                                                                                        {
                                                                                                            vec3 _5860 = (_5805 - Globals.uClipmapOrigin.data[_5833].xyz) / vec3(Globals.uClipmapOrigin.data[_5833].w);
                                                                                                            if (any(lessThan(_5860, vec3(0.5))))
                                                                                                            {
                                                                                                                _5834 = true;
                                                                                                            }
                                                                                                            else
                                                                                                            {
                                                                                                                _5834 = any(greaterThan(_5860, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                                                                            }
                                                                                                            if (!(_5834))
                                                                                                            {
                                                                                                                _5760 = true;
                                                                                                                _5762 = Globals.uClipmapOrigin.data[_5833].w;
                                                                                                                _5831 = true;
                                                                                                                _5832 = ((textureLod(_6012, vec3(_5860.x / float(Globals.uShadowResolution), _5860.y / float(Globals.uShadowResolution), ((float(_5833) * float(Globals.uShadowResolution)) + _5860.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_5833];
                                                                                                                _5845_ladder_break = true;
                                                                                                            }
                                                                                                        }
                                                                                                    }
                                                                                                    if (_5845_ladder_break)
                                                                                                    {
                                                                                                        break;
                                                                                                    }
                                                                                                    _5833++;
                                                                                                    continue;
                                                                                                }
                                                                                                if (!(_5831))
                                                                                                {
                                                                                                    _5831 = true;
                                                                                                    _5832 = 1000000.0;
                                                                                                }
                                                                                            }
                                                                                            if (!_5760)
                                                                                            {
                                                                                                _5755 = true;
                                                                                                _5756 = 1.0;
                                                                                                break;
                                                                                            }
                                                                                            float _5932 = 2.0 * _5762;
                                                                                            if (_5832 < ((0.5 * _5762) * clamp(_5758 / (isnan(9.9999999747524270787835121154785e-07) ? _5932 : (isnan(_5932) ? 9.9999999747524270787835121154785e-07 : max(_5932, 9.9999999747524270787835121154785e-07))), 0.0, 1.0)))
                                                                                            {
                                                                                                _5755 = true;
                                                                                                _5756 = 0.0;
                                                                                                break;
                                                                                            }
                                                                                            float _5817 = _5762 * 0.25;
                                                                                            _5757++;
                                                                                            _5758 += (isnan(_5817) ? _5832 : (isnan(_5832) ? _5817 : max(_5832, _5817)));
                                                                                            continue;
                                                                                        }
                                                                                        if (!(_5755))
                                                                                        {
                                                                                            _5755 = true;
                                                                                            _5756 = 1.0;
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                            reaches = _5756;
                                                                        }
                                                                        else
                                                                        {
                                                                            reaches = _5505;
                                                                        }
                                                                        if (!(reaches <= 0.0))
                                                                        {
                                                                            lit += (uLights_1._member0[_2437].xyz * (contribution * reaches));
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                    if (_151_ladder_break)
                                                    {
                                                        break;
                                                    }
                                                    light++;
                                                    continue;
                                                }
                                                imageStore(uDirect, ivec2(uvec2(texelAt)), vec4(lit, 1.0));
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

