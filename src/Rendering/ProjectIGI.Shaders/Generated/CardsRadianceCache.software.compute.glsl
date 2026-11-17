#version 430
layout(local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

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

layout(binding = 0, std140) uniform SLANG_ParameterGroup_Globals_std140
{
    _Array_std140_vector_float_4_4 uClipmapOrigin;
    _Array_std140_vector_float_4_7 uSkySh;
    vec3 uAtlasSize;
    vec3 uLookupMin;
    vec3 uSkyColour;
    vec3 uCacheOrigin;
    vec3 uCacheCount;
    vec3 uTraceOrigin;
    _Array_std140_float4 uClipmapRange;
    int uShadowLevels;
    int uShadowResolution;
    int uLookupBuckets;
    float uLookupCell;
    int uSkyShValid;
    float uBounceScale;
    float uCacheSpacing;
    int uSlabBegin;
    int uSlabEnd;
    float uAlpha;
    int uRayCount;
    int uSweep;
    float uCacheScale;
    float uSkyReject;
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

layout(binding = 0, rgba16f) uniform restrict image3D uCacheRed;
layout(binding = 1, rgba16f) uniform restrict image3D uCacheGreen;
layout(binding = 2, rgba16f) uniform restrict image3D uCacheBlue;
layout(binding = 3, rgba16f) uniform restrict image3D uCacheDistance;
layout(binding = 3) uniform sampler3D _1987;
layout(binding = 0) uniform sampler2D _1990;
layout(binding = 1) uniform sampler2D _1992;
layout(binding = 2) uniform sampler2D _1994;
layout(binding = 4) uniform sampler2D _1996;

void main()
{
    bool _1462 = false;
    bool _1381 = false;
    {
        ivec3 _141 = ivec3(Globals.uCacheCount + vec3(0.5));
        int _144 = int(gl_GlobalInvocationID.x);
        int _147 = int(gl_GlobalInvocationID.y);
        int _155 = Globals.uSlabBegin + int(gl_GlobalInvocationID.z);
        ivec3 probe = ivec3(_144, _147, _155);
        int _157 = _141.x;
        bool sky;
        if (_144 >= _157)
        {
            sky = true;
        }
        else
        {
            sky = _147 >= _141.y;
        }
        if (sky)
        {
            sky = true;
        }
        else
        {
            sky = _155 >= Globals.uSlabEnd;
        }
        if (sky)
        {
            sky = true;
        }
        else
        {
            sky = _155 >= _141.z;
        }
        if (!(sky))
        {
            if (Globals.uShadowLevels <= 0)
            {
                sky = true;
            }
            else
            {
                sky = Globals.uLookupBuckets <= 0;
            }
            if (!(sky))
            {
                vec3 _214 = Globals.uCacheOrigin + (vec3(probe) * Globals.uCacheSpacing);
                float _221 = fract(float(Globals.uSweep) * 0.61803400516510009765625);
                float _229 = Globals.uCacheSpacing * float(max(_157, max(_141.y, _141.z)));
                int ray = 0;
                float escaped = 0.0;
                vec3 s0 = vec3(0.0);
                vec3 s1 = vec3(0.0);
                vec3 s2 = vec3(0.0);
                vec3 s3 = vec3(0.0);
                vec3 c0 = vec3(0.0);
                vec3 c1 = vec3(0.0);
                vec3 c2 = vec3(0.0);
                vec3 c3 = vec3(0.0);
                float distSum = 0.0;
                float distSqSum = 0.0;
                float skyTrust;
                vec3 hit;
                vec3 radiance;
                vec2 litFound;
                float _1382;
                bool _1385;
                bool _1386;
                float _1388;
                float _1463;
                bool _1465;
                vec3 _1573;
                bool _1629;
                bool _1635;
                ivec2 _1636;
                bool _1640;
                bool _1649;
                bool _1650;
                bool _1651;
                bool _1652;
                bool _1653;
                ivec2 _1883;
                for (;;)
                {
                    if (!(ray < Globals.uRayCount))
                    {
                        break;
                    }
                    float _1363 = float(ray) + _221;
                    float _1369 = clamp(1.0 - (((2.0 * _1363) + 1.0) / float(Globals.uRayCount)), -1.0, 1.0);
                    float _1371 = 1.0 - (_1369 * _1369);
                    float _1373 = sqrt(isnan(_1371) ? 0.0 : (isnan(0.0) ? _1371 : max(0.0, _1371)));
                    float _1375 = _1363 * 3.8832223415374755859375;
                    vec3 _1380 = vec3(_1373 * cos(_1375), _1373 * sin(_1375), _1369);
                    _1381 = false;
                    {
                        hit = _214;
                        if (Globals.uShadowLevels <= 0)
                        {
                            _1381 = true;
                            _1382 = 1.0;
                        }
                        else
                        {
                            vec3 _1405 = _214 + ((_1380 * Globals.uClipmapOrigin.data[0].w) * 1.5);
                            float _1416 = (Globals.uClipmapOrigin.data[0].w * float(Globals.uShadowResolution)) * float(1 << (Globals.uShadowLevels - 1));
                            int _1383 = 0;
                            float _1384 = 0.0;
                            for (;;)
                            {
                                if (_1383 < 64)
                                {
                                    _1385 = _1384 < _1416;
                                }
                                else
                                {
                                    _1385 = false;
                                }
                                if (!_1385)
                                {
                                    break;
                                }
                                vec3 _1433 = _1405 + (_1380 * _1384);
                                _1462 = false;
                                {
                                    _1386 = false;
                                    _1388 = Globals.uClipmapOrigin.data[0].w;
                                    int _1464 = 0;
                                    for (;;)
                                    {
                                        bool _1476_ladder_break = false;
                                        {
                                            if (!(_1464 < Globals.uShadowLevels))
                                            {
                                                _1476_ladder_break = true;
                                            }
                                            else
                                            {
                                                vec3 _1491 = (_1433 - Globals.uClipmapOrigin.data[_1464].xyz) / vec3(Globals.uClipmapOrigin.data[_1464].w);
                                                if (any(lessThan(_1491, vec3(0.5))))
                                                {
                                                    _1465 = true;
                                                }
                                                else
                                                {
                                                    _1465 = any(greaterThan(_1491, vec3(float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5, float(Globals.uShadowResolution) - 0.5)));
                                                }
                                                if (!(_1465))
                                                {
                                                    _1386 = true;
                                                    _1388 = Globals.uClipmapOrigin.data[_1464].w;
                                                    _1462 = true;
                                                    _1463 = ((textureLod(_1987, vec3(_1491.x / float(Globals.uShadowResolution), _1491.y / float(Globals.uShadowResolution), ((float(_1464) * float(Globals.uShadowResolution)) + _1491.z) / float(Globals.uShadowResolution * Globals.uShadowLevels)), 0.0).x * 2.0) - 1.0) * Globals.uClipmapRange.data[_1464];
                                                    _1476_ladder_break = true;
                                                }
                                            }
                                        }
                                        if (_1476_ladder_break)
                                        {
                                            break;
                                        }
                                        _1464++;
                                        continue;
                                    }
                                    if (!(_1462))
                                    {
                                        _1462 = true;
                                        _1463 = 1000000.0;
                                    }
                                }
                                if (!_1386)
                                {
                                    _1381 = true;
                                    _1382 = 1.0;
                                    break;
                                }
                                float _1563 = 2.0 * _1388;
                                float _1567 = (0.5 * _1388) * clamp(_1384 / (isnan(9.9999999747524270787835121154785e-07) ? _1563 : (isnan(_1563) ? 9.9999999747524270787835121154785e-07 : max(_1563, 9.9999999747524270787835121154785e-07))), 0.0, 1.0);
                                float _1569 = (_1384 + _1463) - _1567;
                                float _1389 = isnan(0.0) ? _1569 : (isnan(_1569) ? 0.0 : max(_1569, 0.0));
                                if (_1463 < _1567)
                                {
                                    hit = _1405 + (_1380 * _1389);
                                    _1381 = true;
                                    _1382 = 0.0;
                                    break;
                                }
                                float _1448 = _1388 * 0.25;
                                _1383++;
                                _1384 += (isnan(_1448) ? _1463 : (isnan(_1463) ? _1448 : max(_1463, _1448)));
                                continue;
                            }
                            if (!(_1381))
                            {
                                _1381 = true;
                                _1382 = 1.0;
                            }
                        }
                    }
                    if (_1382 <= 0.5)
                    {
                        {
                            litFound = vec2(0.0);
                            float agreement = 1000000000.0;
                            if (Globals.uLookupBuckets <= 0)
                            {
                                _1629 = false;
                            }
                            else
                            {
                                ivec3 _1670 = ivec3(floor((hit - Globals.uLookupMin) / vec3(Globals.uLookupCell)));
                                int _1882 = int((((uint(_1670.x) * 2376512323u) ^ (uint(_1670.y) * 3625334849u)) ^ (uint(_1670.z) * 3407524639u)) & uint(Globals.uLookupBuckets - 1));
                                uvec2 _1675 = uvec2(textureSize(_1990, 0));
                                vec2 _1682 = vec2(float(_1675.x), float(_1675.y));
                                bool _1632 = false;
                                bool _1633 = false;
                                int _1634 = 0;
                                for (;;)
                                {
                                    if (_1634 <= uCells._member0[Globals.uLookupBuckets].y)
                                    {
                                        _1635 = !_1632;
                                    }
                                    else
                                    {
                                        _1635 = false;
                                    }
                                    if (!_1635)
                                    {
                                        break;
                                    }
                                    bool _1702 = _1634 == 0;
                                    if (_1702)
                                    {
                                        _1636 = uCells._member0[_1882];
                                    }
                                    else
                                    {
                                        int _1887 = uCells._member0[Globals.uLookupBuckets].x + ((_1634 - 1) * 6);
                                        float _1903 = intBitsToFloat(uCellPages_1._member0[_1887 + 3]);
                                        vec3 _1905 = hit - vec3(intBitsToFloat(uCellPages_1._member0[_1887]), intBitsToFloat(uCellPages_1._member0[_1887 + 1]), intBitsToFloat(uCellPages_1._member0[_1887 + 2]));
                                        if (dot(_1905, _1905) > (_1903 * _1903))
                                        {
                                            _1883 = ivec2(0);
                                        }
                                        else
                                        {
                                            _1883 = ivec2(uCellPages_1._member0[_1887 + 4], uCellPages_1._member0[_1887 + 5]);
                                        }
                                        _1636 = _1883;
                                    }
                                    bool _1637 = _1632;
                                    bool _1638 = _1633;
                                    int _1639 = 0;
                                    for (;;)
                                    {
                                        bool _1714_ladder_break = false;
                                        {
                                            if (_1639 < _1636.y)
                                            {
                                                _1640 = !_1637;
                                            }
                                            else
                                            {
                                                _1640 = false;
                                            }
                                            if (!_1640)
                                            {
                                                _1714_ladder_break = true;
                                            }
                                            else
                                            {
                                                int _1731 = _1636.x + _1639;
                                                int _1734 = uCellPages_1._member0[_1731] * 10;
                                                if (!((uPages._member0[_1734 + 5].w > 0.5) == _1702))
                                                {
                                                    int _1743 = _1734 + 9;
                                                    vec3 _1747 = hit - uPages._member0[_1743].xyz;
                                                    if (!(dot(_1747, _1747) > (uPages._member0[_1743].w * uPages._member0[_1743].w)))
                                                    {
                                                        vec3 _1754 = -_1380;
                                                        int _1921 = uCellPages_1._member0[_1731] * 10;
                                                        vec4 _1647 = uPages._member0[_1921];
                                                        vec4 _1648 = uPages._member0[_1921 + 1];
                                                        int _1927 = _1921 + 2;
                                                        int _1930 = _1921 + 3;
                                                        int _1933 = _1921 + 4;
                                                        int _1939 = _1921 + 6;
                                                        int _1942 = _1921 + 7;
                                                        int _1945 = _1921 + 8;
                                                        vec3 _1952 = hit - vec3(uPages._member0[_1939].w, uPages._member0[_1942].w, uPages._member0[_1945].w);
                                                        vec3 _1646 = vec3(dot(uPages._member0[_1939].xyz, _1754), dot(uPages._member0[_1942].xyz, _1754), dot(uPages._member0[_1945].xyz, _1754));
                                                        vec3 _1965 = vec3(dot(uPages._member0[_1939].xyz, _1952), dot(uPages._member0[_1942].xyz, _1952), dot(uPages._member0[_1945].xyz, _1952)) - uPages._member0[_1927].xyz;
                                                        vec2 _1968 = vec2(uPages._member0[_1927].w, uPages._member0[_1930].w);
                                                        bvec2 _2018 = isnan(_1968);
                                                        bvec2 _2019 = isnan(vec2(9.9999999747524270787835121154785e-07));
                                                        vec2 _2020 = max(_1968, vec2(9.9999999747524270787835121154785e-07));
                                                        vec2 _2021 = vec2(_2018.x ? vec2(9.9999999747524270787835121154785e-07).x : _2020.x, _2018.y ? vec2(9.9999999747524270787835121154785e-07).y : _2020.y);
                                                        vec2 _1975 = vec2(dot(_1965, uPages._member0[_1930].xyz), dot(_1965, uPages._member0[_1933].xyz)) / vec2(_2019.x ? _1968.x : _2021.x, _2019.y ? _1968.y : _2021.y);
                                                        vec2 _1641 = _1975;
                                                        float _1643 = -dot(_1965, uPages._member0[_1921 + 5].xyz);
                                                        float _1644 = uPages._member0[_1933].w;
                                                        vec3 _1645 = uPages._member0[_1921 + 5].xyz;
                                                        if (abs(_1975.x) > 1.0)
                                                        {
                                                            _1649 = true;
                                                        }
                                                        else
                                                        {
                                                            _1649 = abs(_1641.y) > 1.0;
                                                        }
                                                        if (!(_1649))
                                                        {
                                                            if (dot(_1380, _1380) > 0.5)
                                                            {
                                                                _1650 = dot(_1645, _1646) < (-0.0500000007450580596923828125);
                                                            }
                                                            else
                                                            {
                                                                _1650 = false;
                                                            }
                                                            if (!(_1650))
                                                            {
                                                                if (_1643 < (-0.25))
                                                                {
                                                                    _1651 = true;
                                                                }
                                                                else
                                                                {
                                                                    _1651 = _1643 > (_1644 + 0.25);
                                                                }
                                                                if (!(_1651))
                                                                {
                                                                    vec2 _1798 = (_1641 * 0.5) + vec2(0.5);
                                                                    vec2 _1805 = (_1648.xy + (_1798 * _1648.zw)) / _1682;
                                                                    if (!(textureLod(_1992, _1805, 0.0).w < 0.5))
                                                                    {
                                                                        float _1825 = abs((textureLod(_1994, _1805, 0.0).x * _1644) - _1643);
                                                                        if (_1825 < agreement)
                                                                        {
                                                                            agreement = _1825;
                                                                            litFound = (_1647.xy + (_1798 * _1647.zw)) / Globals.uAtlasSize.xy;
                                                                            _1652 = _1825 < 0.0199999995529651641845703125;
                                                                            _1653 = true;
                                                                        }
                                                                        else
                                                                        {
                                                                            _1652 = _1637;
                                                                            _1653 = _1638;
                                                                        }
                                                                        _1637 = _1652;
                                                                        _1638 = _1653;
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        if (_1714_ladder_break)
                                        {
                                            break;
                                        }
                                        _1639++;
                                        continue;
                                    }
                                    _1632 = _1637;
                                    _1633 = _1638;
                                    _1634++;
                                    continue;
                                }
                                _1629 = _1633;
                            }
                        }
                        if (_1629)
                        {
                            radiance = textureLod(_1996, litFound, 0.0).xyz * Globals.uBounceScale;
                        }
                        else
                        {
                            radiance = vec3(0.0);
                        }
                        sky = false;
                        skyTrust = length(hit - _214);
                    }
                    else
                    {
                        {
                            if (Globals.uSkyShValid == 0)
                            {
                                _1573 = Globals.uSkyColour;
                            }
                            else
                            {
                                vec4 _1584 = vec4(_1380, 1.0);
                                vec4 _1587 = _1584.xyzz * _1584.yzzx;
                                float _1613 = _1380.x;
                                float _1615 = _1380.y;
                                vec3 _1620 = (vec3(dot(Globals.uSkySh.data[0], _1584), dot(Globals.uSkySh.data[1], _1584), dot(Globals.uSkySh.data[2], _1584)) + vec3(dot(Globals.uSkySh.data[3], _1587), dot(Globals.uSkySh.data[4], _1587), dot(Globals.uSkySh.data[5], _1587))) + (Globals.uSkySh.data[6].xyz * ((_1613 * _1613) - (_1615 * _1615)));
                                bvec3 _2023 = isnan(vec3(0.0));
                                bvec3 _2024 = isnan(_1620);
                                vec3 _2025 = max(vec3(0.0), _1620);
                                vec3 _2026 = vec3(_2023.x ? _1620.x : _2025.x, _2023.y ? _1620.y : _2025.y, _2023.z ? _1620.z : _2025.z);
                                _1573 = vec3(_2024.x ? vec3(0.0).x : _2026.x, _2024.y ? vec3(0.0).y : _2026.y, _2024.z ? vec3(0.0).z : _2026.z);
                            }
                        }
                        radiance = _1573;
                        sky = true;
                        skyTrust = _229;
                        escaped += 1.0;
                    }
                    bvec3 _2028 = isnan(radiance);
                    bvec3 _2029 = isnan(vec3(8.0));
                    vec3 _2030 = min(radiance, vec3(8.0));
                    vec3 _2031 = vec3(_2028.x ? vec3(8.0).x : _2030.x, _2028.y ? vec3(8.0).y : _2030.y, _2028.z ? vec3(8.0).z : _2030.z);
                    vec3 _1134 = vec3(_2029.x ? radiance.x : _2031.x, _2029.y ? radiance.y : _2031.y, _2029.z ? radiance.z : _2031.z);
                    if (sky)
                    {
                        s0 += (_1134 * 0.2820949852466583251953125);
                        s1 += (_1134 * (0.48860299587249755859375 * _1380.x));
                        s2 += (_1134 * (0.48860299587249755859375 * _1380.y));
                        s3 += (_1134 * (0.48860299587249755859375 * _1380.z));
                    }
                    else
                    {
                        c0 += (_1134 * 0.2820949852466583251953125);
                        c1 += (_1134 * (0.48860299587249755859375 * _1380.x));
                        c2 += (_1134 * (0.48860299587249755859375 * _1380.y));
                        c3 += (_1134 * (0.48860299587249755859375 * _1380.z));
                    }
                    ray++;
                    distSum += skyTrust;
                    distSqSum += (skyTrust * skyTrust);
                    continue;
                }
                if (Globals.uSkyReject <= 0.0)
                {
                    skyTrust = 1.0;
                }
                else
                {
                    skyTrust = smoothstep(Globals.uSkyReject * 0.3300000131130218505859375, Globals.uSkyReject, escaped / float(Globals.uRayCount));
                }
                float scale = (12.56637096405029296875 / float(Globals.uRayCount)) * Globals.uCacheScale;
                vec3 c0_1 = (c0 + (s0 * skyTrust)) * scale;
                vec3 c1_1 = (c1 + (s1 * skyTrust)) * scale;
                vec3 c2_1 = (c2 + (s2 * skyTrust)) * scale;
                vec3 c3_1 = (c3 + (s3 * skyTrust)) * scale;
                float invN = 1.0 / float(Globals.uRayCount);
                vec4 red_1 = vec4(c0_1.x, c1_1.x, c2_1.x, c3_1.x);
                vec4 green_1 = vec4(c0_1.y, c1_1.y, c2_1.y, c3_1.y);
                vec4 blue_1 = vec4(c0_1.z, c1_1.z, c2_1.z, c3_1.z);
                vec4 moments_1 = vec4(distSum * invN, distSqSum * invN, 0.0, 0.0);
                vec4 red;
                vec4 green;
                vec4 blue;
                vec4 moments;
                if (Globals.uAlpha < 1.0)
                {
                    red = mix(imageLoad(uCacheRed, probe), red_1, vec4(Globals.uAlpha));
                    green = mix(imageLoad(uCacheGreen, probe), green_1, vec4(Globals.uAlpha));
                    blue = mix(imageLoad(uCacheBlue, probe), blue_1, vec4(Globals.uAlpha));
                    moments = mix(imageLoad(uCacheDistance, probe), moments_1, vec4(Globals.uAlpha));
                }
                else
                {
                    red = red_1;
                    green = green_1;
                    blue = blue_1;
                    moments = moments_1;
                }
                uvec3 _1318 = uvec3(probe);
                imageStore(uCacheRed, ivec3(_1318), red);
                imageStore(uCacheGreen, ivec3(_1318), green);
                imageStore(uCacheBlue, ivec3(_1318), blue);
                imageStore(uCacheDistance, ivec3(_1318), moments);
            }
        }
    }
}

