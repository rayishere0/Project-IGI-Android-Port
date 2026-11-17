#version 430
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(binding = 0, std140) uniform Globals_std140
{
    vec4 uUnproject;
    vec4 uPrevUnproject;
    vec3 uViewToWorld0;
    vec3 uViewToWorld1;
    vec3 uViewToWorld2;
    vec3 uCameraToCache;
    vec3 uPrevWorldToView0;
    vec3 uPrevWorldToView1;
    vec3 uPrevWorldToView2;
    vec3 uPrevCameraToCache;
    vec3 uProbeWorldToView0;
    vec3 uProbeWorldToView1;
    vec3 uProbeWorldToView2;
    vec3 uProbeCameraToCache;
    int uScreenWidth;
    int uScreenHeight;
    int uHasHistory;
    int uMaxFrames;
    int uProbe;
    int uSceneDepth;
    int uSceneNormal;
    int uHistory;
    int uHistoryPosition;
    int uProbePosition;
    int uVelocity;
    int uProbeStep;
    int uProbeFrame;
    int uHasVelocity;
} g;

layout(binding = 0, rgba16f) uniform restrict writeonly image2D uAccum;
layout(binding = 1, rgba16f) uniform restrict writeonly image2D uAccumPosition;
layout(binding = 1) uniform sampler2D _2447;
layout(binding = 2) uniform sampler2D _2449;
layout(binding = 0) uniform sampler2D _2452;
layout(binding = 5) uniform sampler2D _2455;
layout(binding = 6) uniform sampler2D _2457;
layout(binding = 4) uniform sampler2D _2460;
layout(binding = 3) uniform sampler2D _2463;

void main()
{
    {
        ivec2 _149 = ivec2(gl_GlobalInvocationID.xy);
        bool ownMotion;
        if (_149.x >= g.uScreenWidth)
        {
            ownMotion = true;
        }
        else
        {
            ownMotion = _149.y >= g.uScreenHeight;
        }
        if (!(ownMotion))
        {
            vec2 uv = (vec2(_149) + vec2(0.5)) / vec2(float(g.uScreenWidth), float(g.uScreenHeight));
            vec4 _1386 = texture(_2447, uv);
            float _1387 = _1386.x;
            if (_1387 <= 0.0)
            {
                imageStore(uAccum, ivec2(gl_GlobalInvocationID.xy), vec4(0.0));
                imageStore(uAccumPosition, ivec2(gl_GlobalInvocationID.xy), vec4(0.0));
            }
            else
            {
                float _1414 = ((2.0 * g.uUnproject.z) * g.uUnproject.w) / ((g.uUnproject.w + g.uUnproject.z) - ((1.0 - (2.0 * _1387)) * (g.uUnproject.w - g.uUnproject.z)));
                vec2 _1417 = (uv * 2.0) - vec2(1.0);
                vec3 _1429 = vec3((_1417.x * _1414) / g.uUnproject.x, ((-1.0) * (_1417.y * _1414)) / g.uUnproject.y, _1414);
                float _278 = _1429.z;
                vec3 world = ((g.uCameraToCache + (g.uViewToWorld0 * _1429.x)) + (g.uViewToWorld1 * _1429.y)) + (g.uViewToWorld2 * _278);
                vec4 _1435 = texture(_2449, uv);
                vec3 storedNormal = (_1435.xyz * 2.0) - vec3(1.0);
                float _298 = length(storedNormal);
                vec3 pixelNormal;
                if (_298 > 0.001000000047497451305389404296875)
                {
                    pixelNormal = storedNormal / vec3(_298);
                }
                else
                {
                    pixelNormal = vec3(0.0);
                }
                vec3 _1438;
                {
                    uvec2 _1470 = uvec2(textureSize(_2452, 0));
                    ivec2 _1477 = ivec2(int(_1470.x), int(_1470.y));
                    vec3 _1501 = ((g.uProbeWorldToView0 * (world.x - g.uProbeCameraToCache.x)) + (g.uProbeWorldToView1 * (world.y - g.uProbeCameraToCache.y))) + (g.uProbeWorldToView2 * (world.z - g.uProbeCameraToCache.z));
                    vec2 _1441;
                    if (_1501.z > g.uUnproject.z)
                    {
                        float _1873 = _1501.z;
                        _1441 = (vec2((_1501.x * g.uUnproject.x) / _1873, ((-1.0) * (_1501.y * g.uUnproject.y)) / _1873) * 0.5) + vec2(0.5);
                    }
                    else
                    {
                        _1441 = uv;
                    }
                    int _1527 = max(g.uProbeStep, 1);
                    uint _1888 = uint(g.uProbeFrame);
                    uint _1889 = _1888 & 7u;
                    vec2 _1534 = (((_1441 * vec2(float(g.uScreenWidth), float(g.uScreenHeight))) - vec2(min(ivec2(floor(((vec2(float(_1889), float((((_1888 & 1u) << uint(2)) | (_1888 & 2u)) | ((_1889 >> uint(2)) & 1u))) + vec2(0.5)) * vec2(0.125)) * float(_1527))), ivec2(_1527 - 1)))) - vec2(0.5)) / vec2(float(max(g.uProbeStep, 1)));
                    vec2 _1535 = floor(_1534);
                    vec2 _1536 = _1534 - _1535;
                    bool _1538 = dot(pixelNormal, pixelNormal) > 0.5;
                    float _1442 = 3.3999999521443642490773241379936e+38;
                    vec3 _1445 = vec3(0.0);
                    int _1448 = 0;
                    vec3 _1446 = vec3(0.0);
                    float _1443 = 0.0;
                    vec3 _1447 = vec3(0.0);
                    float _1444 = 0.0;
                    float _1449;
                    float _1450;
                    float _1451;
                    float _1452;
                    float _1453;
                    float _1454;
                    float _1455;
                    vec3 _1456;
                    vec3 _1457;
                    vec3 _1458;
                    vec3 _1459;
                    int _1460;
                    bool _1461;
                    for (;;)
                    {
                        if (!(_1448 < 2))
                        {
                            break;
                        }
                        _1449 = _1442;
                        _1456 = _1445;
                        _1460 = 0;
                        _1457 = _1446;
                        _1450 = _1443;
                        _1458 = _1447;
                        _1451 = _1444;
                        for (;;)
                        {
                            bool _1555_ladder_break = false;
                            {
                                if (!(_1460 < 2))
                                {
                                    _1555_ladder_break = true;
                                }
                                else
                                {
                                    ivec2 _1565 = ivec2(_1535) + ivec2(_1460, _1448);
                                    if (any(lessThan(_1565, ivec2(0))))
                                    {
                                        _1461 = true;
                                    }
                                    else
                                    {
                                        _1461 = any(greaterThanEqual(_1565, _1477));
                                    }
                                    if (!(_1461))
                                    {
                                        ivec2 _1577 = ivec3(_1565, 0).xy;
                                        vec4 _1579 = texelFetch(_2455, _1577, 0);
                                        if (!(_1579.w <= 0.0))
                                        {
                                            vec3 _1588 = (_1579.xyz + g.uProbeCameraToCache) - world;
                                            if (_1538)
                                            {
                                                _1455 = abs(dot(_1588, pixelNormal));
                                            }
                                            else
                                            {
                                                _1455 = length(_1588);
                                            }
                                            float _1597 = _1455 / (isnan(0.001000000047497451305389404296875) ? _278 : (isnan(_278) ? 0.001000000047497451305389404296875 : max(_278, 0.001000000047497451305389404296875)));
                                            float _1598 = _1597 * _1597;
                                            if (_1460 == 0)
                                            {
                                                _1452 = 1.0 - _1536.x;
                                            }
                                            else
                                            {
                                                _1452 = _1536.x;
                                            }
                                            if (_1448 == 0)
                                            {
                                                _1453 = 1.0 - _1536.y;
                                            }
                                            else
                                            {
                                                _1453 = _1536.y;
                                            }
                                            float _1617 = _1452 * _1453;
                                            vec3 _1621 = texelFetch(_2452, _1577, 0).xyz;
                                            float _1624 = _1617 * exp2((-200000.0) * _1598);
                                            float _1627 = _1617 * exp2((-20000.0) * _1598);
                                            float _1638 = dot(_1588, _1588);
                                            if (_1638 < _1449)
                                            {
                                                _1454 = _1638;
                                                _1459 = _1621;
                                            }
                                            else
                                            {
                                                _1454 = _1449;
                                                _1459 = _1456;
                                            }
                                            _1449 = _1454;
                                            _1456 = _1459;
                                            _1457 += (_1621 * _1624);
                                            _1450 += _1624;
                                            _1458 += (_1621 * _1627);
                                            _1451 += _1627;
                                        }
                                    }
                                }
                            }
                            if (_1555_ladder_break)
                            {
                                break;
                            }
                            _1460++;
                            continue;
                        }
                        _1442 = _1449;
                        _1445 = _1456;
                        _1448++;
                        _1446 = _1457;
                        _1443 = _1450;
                        _1447 = _1458;
                        _1444 = _1451;
                        continue;
                    }
                    int _1462 = 0;
                    _1449 = 0.0;
                    for (;;)
                    {
                        if (!(_1462 < 4))
                        {
                            break;
                        }
                        if ((_1462 & 1) == 0)
                        {
                            _1442 = 1.0 - _1536.x;
                        }
                        else
                        {
                            _1442 = _1536.x;
                        }
                        if ((_1462 >> 1) == 0)
                        {
                            _1444 = 1.0 - _1536.y;
                        }
                        else
                        {
                            _1444 = _1536.y;
                        }
                        _1462++;
                        _1449 += (_1442 * _1444);
                        continue;
                    }
                    if (_1443 > (0.60000002384185791015625 * _1449))
                    {
                        _1438 = _1446 / vec3(_1443);
                    }
                    else
                    {
                        float _1713 = isnan(0.001000000047497451305389404296875) ? _278 : (isnan(_278) ? 0.001000000047497451305389404296875 : max(_278, 0.001000000047497451305389404296875));
                        _1448 = -1;
                        _1456 = vec3(0.0);
                        _1450 = 0.0;
                        _1457 = vec3(0.0);
                        _1451 = 0.0;
                        _1458 = vec3(0.0);
                        _1452 = 0.0;
                        for (;;)
                        {
                            if (!(_1448 <= 2))
                            {
                                break;
                            }
                            _1460 = -1;
                            _1459 = _1456;
                            _1453 = _1450;
                            vec3 _1464 = _1457;
                            _1454 = _1451;
                            vec3 _1465 = _1458;
                            float _1463 = _1452;
                            for (;;)
                            {
                                bool _1730_ladder_break = false;
                                {
                                    if (!(_1460 <= 2))
                                    {
                                        _1730_ladder_break = true;
                                    }
                                    else
                                    {
                                        ivec2 _1740 = ivec2(_1535) + ivec2(_1460, _1448);
                                        if (any(lessThan(_1740, ivec2(0))))
                                        {
                                            _1461 = true;
                                        }
                                        else
                                        {
                                            _1461 = any(greaterThanEqual(_1740, _1477));
                                        }
                                        if (!(_1461))
                                        {
                                            ivec2 _1752 = ivec3(_1740, 0).xy;
                                            vec4 _1754 = texelFetch(_2455, _1752, 0);
                                            if (!(_1754.w <= 0.0))
                                            {
                                                vec3 _1763 = (_1754.xyz + g.uProbeCameraToCache) - world;
                                                if (_1538)
                                                {
                                                    _1455 = abs(dot(_1763, pixelNormal));
                                                }
                                                else
                                                {
                                                    _1455 = length(_1763);
                                                }
                                                float _1771 = _1455 / _1713;
                                                vec2 _1778 = abs(vec2(float(_1460), float(_1448)) - _1536);
                                                float _1781 = 1.0 - (_1778.x * 0.5);
                                                float _1785 = 1.0 - (_1778.y * 0.5);
                                                float _1787 = (isnan(0.0) ? _1781 : (isnan(_1781) ? 0.0 : max(_1781, 0.0))) * (isnan(0.0) ? _1785 : (isnan(_1785) ? 0.0 : max(_1785, 0.0)));
                                                vec3 _1791 = texelFetch(_2452, _1752, 0).xyz;
                                                float _1795 = _1787 * exp2(((-200000.0) * _1771) * _1771);
                                                float _1804 = _1787 * exp2(((-20000.0) * _1771) * _1771);
                                                float _1811 = length(_1763) / _1713;
                                                float _1815 = _1787 / (1.0 + ((_1811 * _1811) * 400.0));
                                                _1459 += (_1791 * _1795);
                                                _1453 += _1795;
                                                _1464 += (_1791 * _1804);
                                                _1454 += _1804;
                                                _1465 += (_1791 * _1815);
                                                _1463 += _1815;
                                            }
                                        }
                                    }
                                }
                                if (_1730_ladder_break)
                                {
                                    break;
                                }
                                _1460++;
                                continue;
                            }
                            _1448++;
                            _1456 = _1459;
                            _1450 = _1453;
                            _1457 = _1464;
                            _1451 = _1454;
                            _1458 = _1465;
                            _1452 = _1463;
                            continue;
                        }
                        if (_1450 > 9.9999997473787516355514526367188e-05)
                        {
                            _1438 = _1456 / vec3(_1450);
                        }
                        else
                        {
                            if (_1451 > 9.9999997473787516355514526367188e-05)
                            {
                                _1438 = _1457 / vec3(_1451);
                            }
                            else
                            {
                                if (_1452 > 9.9999999747524270787835121154785e-07)
                                {
                                    _1445 = _1458 / vec3(_1452);
                                }
                                _1438 = _1445;
                            }
                        }
                    }
                }
                vec2 _979 = vec2(1.0) / vec2(float(g.uScreenWidth), float(g.uScreenHeight));
                float _983 = float(max(g.uProbeStep, 2));
                int s = 0;
                vec3 m1 = _1438;
                vec3 m2 = _1438 * _1438;
                float samples = 1.0;
                vec3 historySum;
                vec2 prevUv;
                vec3 _1966;
                vec2 _1969;
                float _1977;
                float _1978;
                float _1979;
                float _1980;
                float _1981;
                float _1982;
                float _1983;
                vec3 _1984;
                vec3 _1985;
                vec3 _1986;
                vec3 _1987;
                int _1988;
                bool _1989;
                for (;;)
                {
                    bool _74_ladder_break = false;
                    {
                        if (!(s < 4))
                        {
                            _74_ladder_break = true;
                        }
                        else
                        {
                            if (s == 0)
                            {
                                prevUv = vec2(1.0, 0.0);
                            }
                            else
                            {
                                if (s == 1)
                                {
                                    prevUv = vec2(-1.0, 0.0);
                                }
                                else
                                {
                                    if (s == 2)
                                    {
                                        prevUv = vec2(0.0, 1.0);
                                    }
                                    else
                                    {
                                        prevUv = vec2(0.0, -1.0);
                                    }
                                }
                            }
                            vec2 _1019 = clamp(uv + ((prevUv * _979) * _983), vec2(0.0), vec2(1.0));
                            vec4 _1915 = texture(_2447, _1019);
                            float _1916 = _1915.x;
                            if (!(_1916 <= 0.0))
                            {
                                float _1943 = ((2.0 * g.uUnproject.z) * g.uUnproject.w) / ((g.uUnproject.w + g.uUnproject.z) - ((1.0 - (2.0 * _1916)) * (g.uUnproject.w - g.uUnproject.z)));
                                vec2 _1946 = (_1019 * 2.0) - vec2(1.0);
                                vec3 _1958 = vec3((_1946.x * _1943) / g.uUnproject.x, ((-1.0) * (_1946.y * _1943)) / g.uUnproject.y, _1943);
                                vec3 nWorld = ((g.uCameraToCache + (g.uViewToWorld0 * _1958.x)) + (g.uViewToWorld1 * _1958.y)) + (g.uViewToWorld2 * _1958.z);
                                vec4 _1963 = texture(_2449, _1019);
                                vec3 nNormal = (_1963.xyz * 2.0) - vec3(1.0);
                                float _1047 = length(nNormal);
                                if (_1047 > 0.001000000047497451305389404296875)
                                {
                                    historySum = nNormal / vec3(_1047);
                                }
                                else
                                {
                                    historySum = vec3(0.0);
                                }
                                {
                                    uvec2 _1998 = uvec2(textureSize(_2452, 0));
                                    ivec2 _2005 = ivec2(int(_1998.x), int(_1998.y));
                                    vec3 _2029 = ((g.uProbeWorldToView0 * (nWorld.x - g.uProbeCameraToCache.x)) + (g.uProbeWorldToView1 * (nWorld.y - g.uProbeCameraToCache.y))) + (g.uProbeWorldToView2 * (nWorld.z - g.uProbeCameraToCache.z));
                                    if (_2029.z > g.uUnproject.z)
                                    {
                                        float _2401 = _2029.z;
                                        _1969 = (vec2((_2029.x * g.uUnproject.x) / _2401, ((-1.0) * (_2029.y * g.uUnproject.y)) / _2401) * 0.5) + vec2(0.5);
                                    }
                                    else
                                    {
                                        _1969 = _1019;
                                    }
                                    int _2055 = max(g.uProbeStep, 1);
                                    uint _2415 = uint(g.uProbeFrame);
                                    uint _2416 = _2415 & 7u;
                                    vec2 _2062 = (((_1969 * vec2(float(g.uScreenWidth), float(g.uScreenHeight))) - vec2(min(ivec2(floor(((vec2(float(_2416), float((((_2415 & 1u) << uint(2)) | (_2415 & 2u)) | ((_2416 >> uint(2)) & 1u))) + vec2(0.5)) * vec2(0.125)) * float(_2055))), ivec2(_2055 - 1)))) - vec2(0.5)) / vec2(float(max(g.uProbeStep, 1)));
                                    vec2 _2063 = floor(_2062);
                                    vec2 _2064 = _2062 - _2063;
                                    bool _2066 = dot(historySum, historySum) > 0.5;
                                    float _1970 = 3.3999999521443642490773241379936e+38;
                                    vec3 _1973 = vec3(0.0);
                                    int _1976 = 0;
                                    vec3 _1974 = vec3(0.0);
                                    float _1971 = 0.0;
                                    vec3 _1975 = vec3(0.0);
                                    float _1972 = 0.0;
                                    for (;;)
                                    {
                                        if (!(_1976 < 2))
                                        {
                                            break;
                                        }
                                        _1977 = _1970;
                                        _1984 = _1973;
                                        _1988 = 0;
                                        _1985 = _1974;
                                        _1978 = _1971;
                                        _1986 = _1975;
                                        _1979 = _1972;
                                        for (;;)
                                        {
                                            bool _2083_ladder_break = false;
                                            {
                                                if (!(_1988 < 2))
                                                {
                                                    _2083_ladder_break = true;
                                                }
                                                else
                                                {
                                                    ivec2 _2093 = ivec2(_2063) + ivec2(_1988, _1976);
                                                    if (any(lessThan(_2093, ivec2(0))))
                                                    {
                                                        _1989 = true;
                                                    }
                                                    else
                                                    {
                                                        _1989 = any(greaterThanEqual(_2093, _2005));
                                                    }
                                                    if (!(_1989))
                                                    {
                                                        ivec2 _2105 = ivec3(_2093, 0).xy;
                                                        vec4 _2107 = texelFetch(_2455, _2105, 0);
                                                        if (!(_2107.w <= 0.0))
                                                        {
                                                            vec3 _2116 = (_2107.xyz + g.uProbeCameraToCache) - nWorld;
                                                            if (_2066)
                                                            {
                                                                _1983 = abs(dot(_2116, historySum));
                                                            }
                                                            else
                                                            {
                                                                _1983 = length(_2116);
                                                            }
                                                            float _2125 = _1983 / (isnan(0.001000000047497451305389404296875) ? _1958.z : (isnan(_1958.z) ? 0.001000000047497451305389404296875 : max(_1958.z, 0.001000000047497451305389404296875)));
                                                            float _2126 = _2125 * _2125;
                                                            if (_1988 == 0)
                                                            {
                                                                _1980 = 1.0 - _2064.x;
                                                            }
                                                            else
                                                            {
                                                                _1980 = _2064.x;
                                                            }
                                                            if (_1976 == 0)
                                                            {
                                                                _1981 = 1.0 - _2064.y;
                                                            }
                                                            else
                                                            {
                                                                _1981 = _2064.y;
                                                            }
                                                            float _2145 = _1980 * _1981;
                                                            vec3 _2149 = texelFetch(_2452, _2105, 0).xyz;
                                                            float _2152 = _2145 * exp2((-200000.0) * _2126);
                                                            float _2155 = _2145 * exp2((-20000.0) * _2126);
                                                            float _2166 = dot(_2116, _2116);
                                                            if (_2166 < _1977)
                                                            {
                                                                _1982 = _2166;
                                                                _1987 = _2149;
                                                            }
                                                            else
                                                            {
                                                                _1982 = _1977;
                                                                _1987 = _1984;
                                                            }
                                                            _1977 = _1982;
                                                            _1984 = _1987;
                                                            _1985 += (_2149 * _2152);
                                                            _1978 += _2152;
                                                            _1986 += (_2149 * _2155);
                                                            _1979 += _2155;
                                                        }
                                                    }
                                                }
                                            }
                                            if (_2083_ladder_break)
                                            {
                                                break;
                                            }
                                            _1988++;
                                            continue;
                                        }
                                        _1970 = _1977;
                                        _1973 = _1984;
                                        _1976++;
                                        _1974 = _1985;
                                        _1971 = _1978;
                                        _1975 = _1986;
                                        _1972 = _1979;
                                        continue;
                                    }
                                    int _1990 = 0;
                                    _1977 = 0.0;
                                    for (;;)
                                    {
                                        if (!(_1990 < 4))
                                        {
                                            break;
                                        }
                                        if ((_1990 & 1) == 0)
                                        {
                                            _1970 = 1.0 - _2064.x;
                                        }
                                        else
                                        {
                                            _1970 = _2064.x;
                                        }
                                        if ((_1990 >> 1) == 0)
                                        {
                                            _1972 = 1.0 - _2064.y;
                                        }
                                        else
                                        {
                                            _1972 = _2064.y;
                                        }
                                        _1990++;
                                        _1977 += (_1970 * _1972);
                                        continue;
                                    }
                                    if (_1971 > (0.60000002384185791015625 * _1977))
                                    {
                                        _1966 = _1974 / vec3(_1971);
                                    }
                                    else
                                    {
                                        float _2241 = isnan(0.001000000047497451305389404296875) ? _1958.z : (isnan(_1958.z) ? 0.001000000047497451305389404296875 : max(_1958.z, 0.001000000047497451305389404296875));
                                        _1976 = -1;
                                        _1984 = vec3(0.0);
                                        _1978 = 0.0;
                                        _1985 = vec3(0.0);
                                        _1979 = 0.0;
                                        _1986 = vec3(0.0);
                                        _1980 = 0.0;
                                        for (;;)
                                        {
                                            if (!(_1976 <= 2))
                                            {
                                                break;
                                            }
                                            _1988 = -1;
                                            _1987 = _1984;
                                            _1981 = _1978;
                                            vec3 _1992 = _1985;
                                            _1982 = _1979;
                                            vec3 _1993 = _1986;
                                            float _1991 = _1980;
                                            for (;;)
                                            {
                                                bool _2258_ladder_break = false;
                                                {
                                                    if (!(_1988 <= 2))
                                                    {
                                                        _2258_ladder_break = true;
                                                    }
                                                    else
                                                    {
                                                        ivec2 _2268 = ivec2(_2063) + ivec2(_1988, _1976);
                                                        if (any(lessThan(_2268, ivec2(0))))
                                                        {
                                                            _1989 = true;
                                                        }
                                                        else
                                                        {
                                                            _1989 = any(greaterThanEqual(_2268, _2005));
                                                        }
                                                        if (!(_1989))
                                                        {
                                                            ivec2 _2280 = ivec3(_2268, 0).xy;
                                                            vec4 _2282 = texelFetch(_2455, _2280, 0);
                                                            if (!(_2282.w <= 0.0))
                                                            {
                                                                vec3 _2291 = (_2282.xyz + g.uProbeCameraToCache) - nWorld;
                                                                if (_2066)
                                                                {
                                                                    _1983 = abs(dot(_2291, historySum));
                                                                }
                                                                else
                                                                {
                                                                    _1983 = length(_2291);
                                                                }
                                                                float _2299 = _1983 / _2241;
                                                                vec2 _2306 = abs(vec2(float(_1988), float(_1976)) - _2064);
                                                                float _2309 = 1.0 - (_2306.x * 0.5);
                                                                float _2313 = 1.0 - (_2306.y * 0.5);
                                                                float _2315 = (isnan(0.0) ? _2309 : (isnan(_2309) ? 0.0 : max(_2309, 0.0))) * (isnan(0.0) ? _2313 : (isnan(_2313) ? 0.0 : max(_2313, 0.0)));
                                                                vec3 _2319 = texelFetch(_2452, _2280, 0).xyz;
                                                                float _2323 = _2315 * exp2(((-200000.0) * _2299) * _2299);
                                                                float _2332 = _2315 * exp2(((-20000.0) * _2299) * _2299);
                                                                float _2339 = length(_2291) / _2241;
                                                                float _2343 = _2315 / (1.0 + ((_2339 * _2339) * 400.0));
                                                                _1987 += (_2319 * _2323);
                                                                _1981 += _2323;
                                                                _1992 += (_2319 * _2332);
                                                                _1982 += _2332;
                                                                _1993 += (_2319 * _2343);
                                                                _1991 += _2343;
                                                            }
                                                        }
                                                    }
                                                }
                                                if (_2258_ladder_break)
                                                {
                                                    break;
                                                }
                                                _1988++;
                                                continue;
                                            }
                                            _1976++;
                                            _1984 = _1987;
                                            _1978 = _1981;
                                            _1985 = _1992;
                                            _1979 = _1982;
                                            _1986 = _1993;
                                            _1980 = _1991;
                                            continue;
                                        }
                                        if (_1978 > 9.9999997473787516355514526367188e-05)
                                        {
                                            _1966 = _1984 / vec3(_1978);
                                        }
                                        else
                                        {
                                            if (_1979 > 9.9999997473787516355514526367188e-05)
                                            {
                                                _1966 = _1985 / vec3(_1979);
                                            }
                                            else
                                            {
                                                if (_1980 > 9.9999999747524270787835121154785e-07)
                                                {
                                                    _1973 = _1986 / vec3(_1980);
                                                }
                                                _1966 = _1973;
                                            }
                                        }
                                    }
                                }
                                m1 += _1966;
                                m2 += (_1966 * _1966);
                                samples += 1.0;
                            }
                        }
                    }
                    if (_74_ladder_break)
                    {
                        break;
                    }
                    s++;
                    continue;
                }
                float _1077 = samples;
                vec3 mean = m1 / vec3(_1077);
                vec3 _1085 = (m2 / vec3(_1077)) - (mean * mean);
                bvec3 _2505 = isnan(_1085);
                bvec3 _2506 = isnan(vec3(0.0));
                vec3 _2507 = max(_1085, vec3(0.0));
                vec3 _2508 = vec3(_2505.x ? vec3(0.0).x : _2507.x, _2505.y ? vec3(0.0).y : _2507.y, _2505.z ? vec3(0.0).z : _2507.z);
                vec3 _1089 = sqrt(vec3(_2506.x ? _1085.x : _2508.x, _2506.y ? _1085.y : _2508.y, _2506.z ? _1085.z : _2508.z)) * 1.5;
                vec3 accumulated;
                float frames;
                if (g.uHasHistory != 0)
                {
                    vec3 prevView = ((g.uPrevWorldToView0 * (world.x - g.uPrevCameraToCache.x)) + (g.uPrevWorldToView1 * (world.y - g.uPrevCameraToCache.y))) + (g.uPrevWorldToView2 * (world.z - g.uPrevCameraToCache.z));
                    float _1126 = prevView.z;
                    if (_1126 > 0.0)
                    {
                        vec2 prevUv_1 = (vec2((prevView.x * g.uPrevUnproject.x) / _1126, ((-1.0) * (prevView.y * g.uPrevUnproject.y)) / _1126) * 0.5) + vec2(0.5);
                        if (g.uHasVelocity != 0)
                        {
                            vec2 motion = textureLod(_2457, uv, 0.0).xy;
                            vec2 apart = (motion - (uv - prevUv_1)) * vec2(float(g.uScreenWidth), float(g.uScreenHeight));
                            bool _1165 = dot(apart, apart) > 2.25;
                            if (_1165)
                            {
                                prevUv = uv - motion;
                            }
                            else
                            {
                                prevUv = prevUv_1;
                            }
                            ownMotion = _1165;
                        }
                        else
                        {
                            prevUv = prevUv_1;
                            ownMotion = false;
                        }
                        bool _57;
                        if (all(greaterThanEqual(prevUv, vec2(0.0))))
                        {
                            _57 = all(lessThanEqual(prevUv, vec2(1.0)));
                        }
                        else
                        {
                            _57 = false;
                        }
                        if (_57)
                        {
                            vec2 tc = (prevUv * vec2(float(g.uScreenWidth), float(g.uScreenHeight))) - vec2(0.5);
                            vec2 _1203 = floor(tc);
                            vec2 _1204 = tc - _1203;
                            float _1212 = (2.0 * _278) / (g.uUnproject.y * float(g.uScreenHeight));
                            int t = 0;
                            historySum = vec3(0.0);
                            float frameSum = 0.0;
                            float weightSum = 0.0;
                            bool _61;
                            for (;;)
                            {
                                bool _110_ladder_break = false;
                                {
                                    if (!(t < 4))
                                    {
                                        _110_ladder_break = true;
                                    }
                                    else
                                    {
                                        int _1222 = t & 1;
                                        int _1224 = t >> 1;
                                        ivec2 tap = ivec2(_1203) + ivec2(_1222, _1224);
                                        if (any(lessThan(tap, ivec2(0))))
                                        {
                                            _57 = true;
                                        }
                                        else
                                        {
                                            _57 = any(greaterThanEqual(tap, ivec2(g.uScreenWidth, g.uScreenHeight)));
                                        }
                                        if (!(_57))
                                        {
                                            ivec2 _1244 = ivec3(tap, 0).xy;
                                            vec4 _sampled = texelFetch(_2460, _1244, 0);
                                            if (!(_sampled.w <= 0.0))
                                            {
                                                if (!ownMotion)
                                                {
                                                    float _1262 = 4.0 * _1212;
                                                    _61 = abs(dot((_sampled.xyz + g.uPrevCameraToCache) - world, pixelNormal)) > (isnan(_1262) ? 0.0199999995529651641845703125 : (isnan(0.0199999995529651641845703125) ? _1262 : max(0.0199999995529651641845703125, _1262)));
                                                }
                                                else
                                                {
                                                    _61 = false;
                                                }
                                                if (!(_61))
                                                {
                                                    if (_1222 == 0)
                                                    {
                                                        samples = 1.0 - _1204.x;
                                                    }
                                                    else
                                                    {
                                                        samples = _1204.x;
                                                    }
                                                    if (_1224 == 0)
                                                    {
                                                        frames = 1.0 - _1204.y;
                                                    }
                                                    else
                                                    {
                                                        frames = _1204.y;
                                                    }
                                                    float w = samples * frames;
                                                    vec4 _sampled_1 = texelFetch(_2463, _1244, 0);
                                                    historySum += (_sampled_1.xyz * w);
                                                    frameSum += (_sampled_1.w * w);
                                                    weightSum += w;
                                                }
                                            }
                                        }
                                    }
                                }
                                if (_110_ladder_break)
                                {
                                    break;
                                }
                                t++;
                                continue;
                            }
                            if (weightSum > 0.00999999977648258209228515625)
                            {
                                float _1328 = frameSum / weightSum;
                                float _1333 = _1328 + 1.0;
                                float _1337 = float(g.uMaxFrames);
                                float _1338 = isnan(_1337) ? _1333 : (isnan(_1333) ? _1337 : min(_1333, _1337));
                                accumulated = mix(clamp(vec4(historySum / vec3(weightSum), _1328).xyz, mean - _1089, mean + _1089), _1438, vec3(1.0 / (1.0 + _1338)));
                                frames = _1338;
                            }
                            else
                            {
                                accumulated = _1438;
                                frames = 0.0;
                            }
                        }
                        else
                        {
                            accumulated = _1438;
                            frames = 0.0;
                        }
                    }
                    else
                    {
                        accumulated = _1438;
                        frames = 0.0;
                    }
                }
                else
                {
                    accumulated = _1438;
                    frames = 0.0;
                }
                imageStore(uAccum, ivec2(gl_GlobalInvocationID.xy), vec4(accumulated, frames));
                imageStore(uAccumPosition, ivec2(gl_GlobalInvocationID.xy), vec4(world - g.uCameraToCache, 1.0));
            }
        }
    }
}

