#version 430
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(binding = 0, std140) uniform Params_std140
{
    vec4 size;
    vec4 control;
} p;

layout(binding = 0, r8) uniform restrict writeonly image2D uRejection;
layout(binding = 1, rgba16f) uniform restrict writeonly image2D uGuide;
layout(binding = 0) uniform sampler2D _2069;
layout(binding = 1) uniform sampler2D _2072;
layout(binding = 2) uniform sampler2D _2074;
layout(binding = 4) uniform sampler2D _2077;
layout(binding = 3) uniform sampler2D _2079;

shared float sInput[1200];
shared float sHistory[1200];
shared float sMid[972];
shared float sInClamped[768];
shared float sHistClamped[768];
shared float sBlur[768];

void main()
{
    {
        ivec2 _373 = ivec2(p.size.xy);
        ivec2 _376 = _373 - ivec2(1);
        ivec2 origin = ivec2(gl_WorkGroupID.xy) * ivec2(8);
        ivec2 _386 = ivec2(gl_LocalInvocationID.xy);
        ivec2 px = origin + _386;
        uint i = gl_LocalInvocationIndex;
        for (;;)
        {
            if (!(i < 400u))
            {
                break;
            }
            int _1833 = int(i);
            ivec2 _1838 = ivec2(_1833 - 20 * (_1833 / 20), _1833 / 20) - ivec2(6);
            ivec2 _425 = clamp(origin + _1838, ivec2(0), _376);
            ivec2 _430 = ivec3(_425, 0).xy;
            vec3 _434 = texelFetch(_2069, _430, 0).xyz;
            bvec3 _2081 = isnan(_434);
            bvec3 _2082 = isnan(vec3(0.0));
            vec3 _2083 = max(_434, vec3(0.0));
            vec3 _2084 = vec3(_2081.x ? vec3(0.0).x : _2083.x, _2081.y ? vec3(0.0).y : _2083.y, _2081.z ? vec3(0.0).z : _2083.z);
            vec3 x_2 = vec3(_2082.x ? _434.x : _2084.x, _2082.y ? _434.y : _2084.y, _2082.z ? _434.z : _2084.z) * p.control.x;
            vec3 inputValue = x_2 / (x_2 + vec3(0.17000000178813934326171875));
            vec3 _465 = textureLod(_2074, clamp(((vec2(_425) + vec2(0.5)) * p.size.zw) - texelFetch(_2072, _430, 0).xy, vec2(0.0), vec2(1.0)), 0.0).xyz;
            bvec3 _2086 = isnan(_465);
            bvec3 _2087 = isnan(vec3(0.0));
            vec3 _2088 = max(_465, vec3(0.0));
            vec3 _2089 = vec3(_2086.x ? vec3(0.0).x : _2088.x, _2086.y ? vec3(0.0).y : _2088.y, _2086.z ? vec3(0.0).z : _2088.z);
            vec3 _466 = vec3(_2087.x ? _465.x : _2089.x, _2087.y ? _465.y : _2089.y, _2087.z ? _465.z : _2089.z);
            int at_ = (((_1838.y + 6) * 20) + (_1838.x + 6)) * 3;
            sInput[at_] = inputValue.x;
            int _484 = at_ + 1;
            sInput[_484] = inputValue.y;
            int _488 = at_ + 2;
            sInput[_488] = inputValue.z;
            sHistory[at_] = _466.x;
            sHistory[_484] = _466.y;
            sHistory[_488] = _466.z;
            i += 64u;
            continue;
        }
        barrier();
        int _513 = _386.y;
        int _516 = _386.x;
        int _519 = (((_513 + 6) * 20) + (_516 + 6)) * 3;
        float _521 = sInput[_519];
        int _522 = _519 + 1;
        float _524 = sInput[_522];
        int _525 = _519 + 2;
        float _527 = sInput[_525];
        float _530 = sHistory[_519];
        float _532 = sHistory[_522];
        float _534 = sHistory[_525];
        i = gl_LocalInvocationIndex;
        vec3 lo;
        vec3 hi;
        vec3 energy;
        vec3 inHi;
        int y;
        int x;
        for (;;)
        {
            if (!(i < 324u))
            {
                break;
            }
            int _1849 = int(i);
            ivec2 _1854 = ivec2(_1849 - 18 * (_1849 / 18), _1849 / 18) - ivec2(5);
            lo = vec3(1000000015047466219876688855040.0);
            hi = vec3(-1000000015047466219876688855040.0);
            y = -1;
            for (;;)
            {
                if (!(y <= 1))
                {
                    break;
                }
                energy = lo;
                inHi = hi;
                x = -1;
                for (;;)
                {
                    if (!(x <= 1))
                    {
                        break;
                    }
                    ivec2 _567 = _1854 + ivec2(x, y);
                    int _574 = (((_567.y + 6) * 20) + (_567.x + 6)) * 3;
                    vec3 s = vec3(sInput[_574], sInput[_574 + 1], sInput[_574 + 2]);
                    bvec3 _2091 = isnan(energy);
                    bvec3 _2092 = isnan(s);
                    vec3 _2093 = min(energy, s);
                    vec3 _2094 = vec3(_2091.x ? s.x : _2093.x, _2091.y ? s.y : _2093.y, _2091.z ? s.z : _2093.z);
                    bvec3 _2096 = isnan(inHi);
                    bvec3 _2097 = isnan(s);
                    vec3 _2098 = max(inHi, s);
                    vec3 _2099 = vec3(_2096.x ? s.x : _2098.x, _2096.y ? s.y : _2098.y, _2096.z ? s.z : _2098.z);
                    energy = vec3(_2092.x ? energy.x : _2094.x, _2092.y ? energy.y : _2094.y, _2092.z ? energy.z : _2094.z);
                    inHi = vec3(_2097.x ? inHi.x : _2099.x, _2097.y ? inHi.y : _2099.y, _2097.z ? inHi.z : _2099.z);
                    x++;
                    continue;
                }
                lo = energy;
                hi = inHi;
                y++;
                continue;
            }
            int _608 = _1854.y;
            int _612 = _1854.x;
            int at_1 = (((_608 + 5) * 18) + (_612 + 5)) * 3;
            int _620 = (((_608 + 6) * 20) + (_612 + 6)) * 3;
            vec3 _632 = clamp(vec3(sHistory[_620], sHistory[_620 + 1], sHistory[_620 + 2]), lo, hi);
            sMid[at_1] = _632.x;
            sMid[at_1 + 1] = _632.y;
            sMid[at_1 + 2] = _632.z;
            i += 64u;
            continue;
        }
        barrier();
        i = gl_LocalInvocationIndex;
        for (;;)
        {
            if (!(i < 256u))
            {
                break;
            }
            int _1865 = int(i);
            ivec2 _1870 = ivec2(_1865 - 16 * (_1865 / 16), _1865 / 16) - ivec2(4);
            lo = vec3(1000000015047466219876688855040.0);
            hi = vec3(-1000000015047466219876688855040.0);
            y = -1;
            for (;;)
            {
                if (!(y <= 1))
                {
                    break;
                }
                energy = lo;
                inHi = hi;
                x = -1;
                for (;;)
                {
                    if (!(x <= 1))
                    {
                        break;
                    }
                    ivec2 _684 = _1870 + ivec2(x, y);
                    int _691 = (((_684.y + 5) * 18) + (_684.x + 5)) * 3;
                    vec3 s_1 = vec3(sMid[_691], sMid[_691 + 1], sMid[_691 + 2]);
                    bvec3 _2101 = isnan(energy);
                    bvec3 _2102 = isnan(s_1);
                    vec3 _2103 = min(energy, s_1);
                    vec3 _2104 = vec3(_2101.x ? s_1.x : _2103.x, _2101.y ? s_1.y : _2103.y, _2101.z ? s_1.z : _2103.z);
                    bvec3 _2106 = isnan(inHi);
                    bvec3 _2107 = isnan(s_1);
                    vec3 _2108 = max(inHi, s_1);
                    vec3 _2109 = vec3(_2106.x ? s_1.x : _2108.x, _2106.y ? s_1.y : _2108.y, _2106.z ? s_1.z : _2108.z);
                    energy = vec3(_2102.x ? energy.x : _2104.x, _2102.y ? energy.y : _2104.y, _2102.z ? energy.z : _2104.z);
                    inHi = vec3(_2107.x ? inHi.x : _2109.x, _2107.y ? inHi.y : _2109.y, _2107.z ? inHi.z : _2109.z);
                    x++;
                    continue;
                }
                lo = energy;
                hi = inHi;
                y++;
                continue;
            }
            int _725 = _1870.y;
            int _729 = _1870.x;
            int at_2 = (((_725 + 4) * 16) + (_729 + 4)) * 3;
            int _737 = (((_725 + 6) * 20) + (_729 + 6)) * 3;
            vec3 _749 = clamp(vec3(sInput[_737], sInput[_737 + 1], sInput[_737 + 2]), lo, hi);
            sInClamped[at_2] = _749.x;
            sInClamped[at_2 + 1] = _749.y;
            sInClamped[at_2 + 2] = _749.z;
            i += 64u;
            continue;
        }
        barrier();
        i = gl_LocalInvocationIndex;
        for (;;)
        {
            if (!(i < 324u))
            {
                break;
            }
            int _1875 = int(i);
            ivec2 _1880 = ivec2(_1875 - 18 * (_1875 / 18), _1875 / 18) - ivec2(5);
            lo = vec3(1000000015047466219876688855040.0);
            hi = vec3(-1000000015047466219876688855040.0);
            y = -1;
            for (;;)
            {
                if (!(y <= 1))
                {
                    break;
                }
                energy = lo;
                inHi = hi;
                x = -1;
                for (;;)
                {
                    if (!(x <= 1))
                    {
                        break;
                    }
                    ivec2 _799 = _1880 + ivec2(x, y);
                    int _806 = (((_799.y + 6) * 20) + (_799.x + 6)) * 3;
                    vec3 s_2 = vec3(sHistory[_806], sHistory[_806 + 1], sHistory[_806 + 2]);
                    bvec3 _2111 = isnan(energy);
                    bvec3 _2112 = isnan(s_2);
                    vec3 _2113 = min(energy, s_2);
                    vec3 _2114 = vec3(_2111.x ? s_2.x : _2113.x, _2111.y ? s_2.y : _2113.y, _2111.z ? s_2.z : _2113.z);
                    bvec3 _2116 = isnan(inHi);
                    bvec3 _2117 = isnan(s_2);
                    vec3 _2118 = max(inHi, s_2);
                    vec3 _2119 = vec3(_2116.x ? s_2.x : _2118.x, _2116.y ? s_2.y : _2118.y, _2116.z ? s_2.z : _2118.z);
                    energy = vec3(_2112.x ? energy.x : _2114.x, _2112.y ? energy.y : _2114.y, _2112.z ? energy.z : _2114.z);
                    inHi = vec3(_2117.x ? inHi.x : _2119.x, _2117.y ? inHi.y : _2119.y, _2117.z ? inHi.z : _2119.z);
                    x++;
                    continue;
                }
                lo = energy;
                hi = inHi;
                y++;
                continue;
            }
            int _840 = _1880.y;
            int _843 = _1880.x;
            int at_3 = (((_840 + 5) * 18) + (_843 + 5)) * 3;
            int _851 = (((_840 + 6) * 20) + (_843 + 6)) * 3;
            vec3 _863 = clamp(vec3(sInput[_851], sInput[_851 + 1], sInput[_851 + 2]), lo, hi);
            sMid[at_3] = _863.x;
            sMid[at_3 + 1] = _863.y;
            sMid[at_3 + 2] = _863.z;
            i += 64u;
            continue;
        }
        barrier();
        i = gl_LocalInvocationIndex;
        for (;;)
        {
            if (!(i < 256u))
            {
                break;
            }
            int _1885 = int(i);
            ivec2 _1890 = ivec2(_1885 - 16 * (_1885 / 16), _1885 / 16) - ivec2(4);
            lo = vec3(1000000015047466219876688855040.0);
            hi = vec3(-1000000015047466219876688855040.0);
            y = -1;
            for (;;)
            {
                if (!(y <= 1))
                {
                    break;
                }
                energy = lo;
                inHi = hi;
                x = -1;
                for (;;)
                {
                    if (!(x <= 1))
                    {
                        break;
                    }
                    ivec2 _909 = _1890 + ivec2(x, y);
                    int _916 = (((_909.y + 5) * 18) + (_909.x + 5)) * 3;
                    vec3 s_3 = vec3(sMid[_916], sMid[_916 + 1], sMid[_916 + 2]);
                    bvec3 _2121 = isnan(energy);
                    bvec3 _2122 = isnan(s_3);
                    vec3 _2123 = min(energy, s_3);
                    vec3 _2124 = vec3(_2121.x ? s_3.x : _2123.x, _2121.y ? s_3.y : _2123.y, _2121.z ? s_3.z : _2123.z);
                    bvec3 _2126 = isnan(inHi);
                    bvec3 _2127 = isnan(s_3);
                    vec3 _2128 = max(inHi, s_3);
                    vec3 _2129 = vec3(_2126.x ? s_3.x : _2128.x, _2126.y ? s_3.y : _2128.y, _2126.z ? s_3.z : _2128.z);
                    energy = vec3(_2122.x ? energy.x : _2124.x, _2122.y ? energy.y : _2124.y, _2122.z ? energy.z : _2124.z);
                    inHi = vec3(_2127.x ? inHi.x : _2129.x, _2127.y ? inHi.y : _2129.y, _2127.z ? inHi.z : _2129.z);
                    x++;
                    continue;
                }
                lo = energy;
                hi = inHi;
                y++;
                continue;
            }
            int _950 = _1890.y;
            int _953 = _1890.x;
            int at_4 = (((_950 + 4) * 16) + (_953 + 4)) * 3;
            int _961 = (((_950 + 6) * 20) + (_953 + 6)) * 3;
            vec3 _973 = clamp(vec3(sHistory[_961], sHistory[_961 + 1], sHistory[_961 + 2]), lo, hi);
            sHistClamped[at_4] = _973.x;
            sHistClamped[at_4 + 1] = _973.y;
            sHistClamped[at_4 + 2] = _973.z;
            i += 64u;
            continue;
        }
        barrier();
        i = gl_LocalInvocationIndex;
        float _1907;
        float _1908;
        for (;;)
        {
            if (!(i < 196u))
            {
                break;
            }
            int _1901 = int(i);
            ivec2 _1906 = ivec2(_1901 - 14 * (_1901 / 14), _1901 / 14) - ivec2(3);
            y = -1;
            lo = vec3(0.0);
            hi = vec3(0.0);
            for (;;)
            {
                if (!(y <= 1))
                {
                    break;
                }
                x = -1;
                for (;;)
                {
                    if (!(x <= 1))
                    {
                        break;
                    }
                    if (x == 0)
                    {
                        _1907 = 0.5;
                    }
                    else
                    {
                        _1907 = 0.25;
                    }
                    if (y == 0)
                    {
                        _1908 = 0.5;
                    }
                    else
                    {
                        _1908 = 0.25;
                    }
                    float _1921 = _1907 * _1908;
                    int _1047 = x;
                    ivec2 _1049 = _1906 + ivec2(_1047, y);
                    int _1056 = (((_1049.y + 4) * 16) + (_1049.x + 4)) * 3;
                    int _1059 = _1056 + 1;
                    int _1062 = _1056 + 2;
                    x++;
                    lo += (vec3(sInClamped[_1056], sInClamped[_1059], sInClamped[_1062]) * _1921);
                    hi += (vec3(sHistClamped[_1056], sHistClamped[_1059], sHistClamped[_1062]) * _1921);
                    continue;
                }
                y++;
                continue;
            }
            int _1095 = _1906.y;
            int _1098 = _1906.x;
            int at_5 = (((_1095 + 4) * 16) + (_1098 + 4)) * 3;
            sBlur[at_5] = lo.x;
            sBlur[at_5 + 1] = lo.y;
            sBlur[at_5 + 2] = lo.z;
            int at_6 = (((_1095 + 5) * 18) + (_1098 + 5)) * 3;
            sMid[at_6] = hi.x;
            sMid[at_6 + 1] = hi.y;
            sMid[at_6 + 2] = hi.z;
            i += 64u;
            continue;
        }
        barrier();
        lo = vec3(1000000015047466219876688855040.0);
        hi = vec3(-1000000015047466219876688855040.0);
        y = -1;
        for (;;)
        {
            if (!(y <= 1))
            {
                break;
            }
            x = -1;
            for (;;)
            {
                if (!(x <= 1))
                {
                    break;
                }
                ivec2 _1159 = _386 + ivec2(x, y);
                int _1166 = (((_1159.y + 4) * 16) + (_1159.x + 4)) * 3;
                vec3 s_4 = vec3(sInClamped[_1166], sInClamped[_1166 + 1], sInClamped[_1166 + 2]);
                bvec3 _2131 = isnan(lo);
                bvec3 _2132 = isnan(s_4);
                vec3 _2133 = min(lo, s_4);
                vec3 _2134 = vec3(_2131.x ? s_4.x : _2133.x, _2131.y ? s_4.y : _2133.y, _2131.z ? s_4.z : _2133.z);
                bvec3 _2136 = isnan(hi);
                bvec3 _2137 = isnan(s_4);
                vec3 _2138 = max(hi, s_4);
                vec3 _2139 = vec3(_2136.x ? s_4.x : _2138.x, _2136.y ? s_4.y : _2138.y, _2136.z ? s_4.z : _2138.z);
                lo = vec3(_2132.x ? lo.x : _2134.x, _2132.y ? lo.y : _2134.y, _2132.z ? lo.z : _2134.z);
                hi = vec3(_2137.x ? hi.x : _2139.x, _2137.y ? hi.y : _2139.y, _2137.z ? hi.z : _2139.z);
                x++;
                continue;
            }
            y++;
            continue;
        }
        int _1200 = (((_513 + 4) * 16) + (_516 + 4)) * 3;
        float _1202 = sBlur[_1200];
        float _1205 = sBlur[_1200 + 1];
        float _1208 = sBlur[_1200 + 2];
        int _1214 = (((_513 + 5) * 18) + (_516 + 5)) * 3;
        float _1216 = sMid[_1214];
        float _1219 = sMid[_1214 + 1];
        float _1222 = sMid[_1214 + 2];
        vec3 _1225 = abs(vec3(_1202, _1205, _1208) - vec3(_1216, _1219, _1222));
        vec3 _1226 = lo;
        vec3 _1227 = hi;
        vec3 _1232 = ((_1227 - _1226) * 0.25) + vec3(0.000244140625);
        bvec3 _2141 = isnan(_1225);
        bvec3 _2142 = isnan(_1232);
        vec3 _2143 = max(_1225, _1232);
        vec3 _2144 = vec3(_2141.x ? _1232.x : _2143.x, _2141.y ? _1232.y : _2143.y, _2141.z ? _1232.z : _2143.z);
        vec3 _1233 = vec3(_2142.x ? _1225.x : _2144.x, _2142.y ? _1225.y : _2144.y, _2142.z ? _1225.z : _2144.z);
        i = gl_LocalInvocationIndex;
        vec3 hLo;
        vec3 hHi;
        for (;;)
        {
            if (!(i < 144u))
            {
                break;
            }
            int _1932 = int(i);
            ivec2 _1937 = ivec2(_1932 - 12 * (_1932 / 12), _1932 / 12) - ivec2(2);
            int _1242 = _1937.y;
            int _1245 = _1937.x;
            int _1248 = (((_1242 + 5) * 18) + (_1245 + 5)) * 3;
            vec3 fh = vec3(sMid[_1248], sMid[_1248 + 1], sMid[_1248 + 2]);
            int _1262 = (((_1242 + 4) * 16) + (_1245 + 4)) * 3;
            vec3 inC = vec3(sInClamped[_1262], sInClamped[_1262 + 1], sInClamped[_1262 + 2]);
            int _1276 = (((_1242 + 6) * 20) + (_1245 + 6)) * 3;
            int _1279 = _1276 + 1;
            int _1282 = _1276 + 2;
            energy = vec3(1000000015047466219876688855040.0);
            inHi = vec3(-1000000015047466219876688855040.0);
            vec3 boxLo = vec3(1000000015047466219876688855040.0);
            vec3 boxHi = vec3(-1000000015047466219876688855040.0);
            y = -1;
            vec3 sumIn = vec3(0.0);
            vec3 sumDiff = vec3(0.0);
            for (;;)
            {
                if (!(y <= 1))
                {
                    break;
                }
                hLo = boxLo;
                hHi = boxHi;
                x = -1;
                for (;;)
                {
                    if (!(x <= 1))
                    {
                        break;
                    }
                    int _1306 = x;
                    ivec2 r = _1937 + ivec2(_1306, y);
                    int _1309 = r.y;
                    int _1312 = r.x;
                    int _1315 = (((_1309 + 4) * 16) + (_1312 + 4)) * 3;
                    int _1318 = _1315 + 1;
                    int _1321 = _1315 + 2;
                    vec3 c = vec3(sInClamped[_1315], sInClamped[_1318], sInClamped[_1321]);
                    vec3 b = vec3(sBlur[_1315], sBlur[_1318], sBlur[_1321]);
                    bvec3 _2146 = isnan(energy);
                    bvec3 _2147 = isnan(c);
                    vec3 _2148 = min(energy, c);
                    vec3 _2149 = vec3(_2146.x ? c.x : _2148.x, _2146.y ? c.y : _2148.y, _2146.z ? c.z : _2148.z);
                    bvec3 _2151 = isnan(inHi);
                    bvec3 _2152 = isnan(c);
                    vec3 _2153 = max(inHi, c);
                    vec3 _2154 = vec3(_2151.x ? c.x : _2153.x, _2151.y ? c.y : _2153.y, _2151.z ? c.z : _2153.z);
                    bvec3 _2156 = isnan(hLo);
                    bvec3 _2157 = isnan(b);
                    vec3 _2158 = min(hLo, b);
                    vec3 _2159 = vec3(_2156.x ? b.x : _2158.x, _2156.y ? b.y : _2158.y, _2156.z ? b.z : _2158.z);
                    bvec3 _2161 = isnan(hHi);
                    bvec3 _2162 = isnan(b);
                    vec3 _2163 = max(hHi, b);
                    vec3 _2164 = vec3(_2161.x ? b.x : _2163.x, _2161.y ? b.y : _2163.y, _2161.z ? b.z : _2163.z);
                    int _1346 = (((_1309 + 6) * 20) + (_1312 + 6)) * 3;
                    energy = vec3(_2147.x ? energy.x : _2149.x, _2147.y ? energy.y : _2149.y, _2147.z ? energy.z : _2149.z);
                    inHi = vec3(_2152.x ? inHi.x : _2154.x, _2152.y ? inHi.y : _2154.y, _2152.z ? inHi.z : _2154.z);
                    hLo = vec3(_2157.x ? hLo.x : _2159.x, _2157.y ? hLo.y : _2159.y, _2157.z ? hLo.z : _2159.z);
                    hHi = vec3(_2162.x ? hHi.x : _2164.x, _2162.y ? hHi.y : _2164.y, _2162.z ? hHi.z : _2164.z);
                    x++;
                    sumIn += c;
                    sumDiff += abs(vec3(sInput[_1346], sInput[_1346 + 1], sInput[_1346 + 2]) - c);
                    continue;
                }
                boxLo = hLo;
                boxHi = hHi;
                y++;
                continue;
            }
            if (p.control.w > 0.0)
            {
                float _1400 = clamp(texelFetch(_2077, ivec3(clamp(origin + _1937, ivec2(0), _376), 0).xy, 0).y * p.control.w, 0.0, 1.0);
                if (_1400 > 0.0078740157186985015869140625)
                {
                    hLo = vec3(1000000015047466219876688855040.0);
                    hHi = vec3(-1000000015047466219876688855040.0);
                    x = -1;
                    for (;;)
                    {
                        if (!(x <= 1))
                        {
                            break;
                        }
                        vec3 hLo_1 = hLo;
                        vec3 hHi_1 = hHi;
                        int x_1 = -1;
                        for (;;)
                        {
                            if (!(x_1 <= 1))
                            {
                                break;
                            }
                            ivec2 _1421 = _1937 + ivec2(x_1, x);
                            int _1428 = (((_1421.y + 5) * 18) + (_1421.x + 5)) * 3;
                            vec3 b_1 = vec3(sMid[_1428], sMid[_1428 + 1], sMid[_1428 + 2]);
                            bvec3 _2166 = isnan(hLo_1);
                            bvec3 _2167 = isnan(b_1);
                            vec3 _2168 = min(hLo_1, b_1);
                            vec3 _2169 = vec3(_2166.x ? b_1.x : _2168.x, _2166.y ? b_1.y : _2168.y, _2166.z ? b_1.z : _2168.z);
                            bvec3 _2171 = isnan(hHi_1);
                            bvec3 _2172 = isnan(b_1);
                            vec3 _2173 = max(hHi_1, b_1);
                            vec3 _2174 = vec3(_2171.x ? b_1.x : _2173.x, _2171.y ? b_1.y : _2173.y, _2171.z ? b_1.z : _2173.z);
                            hLo_1 = vec3(_2167.x ? hLo_1.x : _2169.x, _2167.y ? hLo_1.y : _2169.y, _2167.z ? hLo_1.z : _2169.z);
                            hHi_1 = vec3(_2172.x ? hHi_1.x : _2174.x, _2172.y ? hHi_1.y : _2174.y, _2172.z ? hHi_1.z : _2174.z);
                            x_1++;
                            continue;
                        }
                        hLo = hLo_1;
                        hHi = hHi_1;
                        x++;
                        continue;
                    }
                    bvec3 _2176 = isnan(boxLo);
                    bvec3 _2177 = isnan(hLo);
                    vec3 _2178 = min(boxLo, hLo);
                    vec3 _2179 = vec3(_2176.x ? hLo.x : _2178.x, _2176.y ? hLo.y : _2178.y, _2176.z ? hLo.z : _2178.z);
                    vec3 _1465 = vec3(_1400);
                    bvec3 _2181 = isnan(boxHi);
                    bvec3 _2182 = isnan(hHi);
                    vec3 _2183 = max(boxHi, hHi);
                    vec3 _2184 = vec3(_2181.x ? hHi.x : _2183.x, _2181.y ? hHi.y : _2183.y, _2181.z ? hHi.z : _2183.z);
                    hLo = mix(boxLo, vec3(_2177.x ? boxLo.x : _2179.x, _2177.y ? boxLo.y : _2179.y, _2177.z ? boxLo.z : _2179.z), _1465);
                    hHi = mix(boxHi, vec3(_2182.x ? boxHi.x : _2184.x, _2182.y ? boxHi.y : _2184.y, _2182.z ? boxHi.z : _2184.z), _1465);
                }
                else
                {
                    hLo = boxLo;
                    hHi = boxHi;
                }
            }
            else
            {
                hLo = boxLo;
                hHi = boxHi;
            }
            vec3 _1497 = abs(((inC * 9.0) - sumIn) * vec3(0.125));
            vec3 _1505 = abs(((abs(vec3(sInput[_1276], sInput[_1279], sInput[_1282]) - inC) * 9.0) - sumDiff) * vec3(0.125));
            bvec3 _2186 = isnan(_1505);
            bvec3 _2187 = isnan(_1497);
            vec3 _2188 = min(_1505, _1497);
            vec3 _2189 = vec3(_2186.x ? _1497.x : _2188.x, _2186.y ? _1497.y : _2188.y, _2186.z ? _1497.z : _2188.z);
            vec3 _1506 = vec3(_2187.x ? _1505.x : _2189.x, _2187.y ? _1505.y : _2189.y, _2187.z ? _1505.z : _2189.z);
            bvec3 _2191 = isnan(vec3(0.00048828125));
            bvec3 _2192 = isnan(_1506);
            vec3 _2193 = max(vec3(0.00048828125), _1506);
            vec3 _2194 = vec3(_2191.x ? _1506.x : _2193.x, _2191.y ? _1506.y : _2193.y, _2191.z ? _1506.z : _2193.z);
            vec3 _1507 = vec3(_2192.x ? vec3(0.00048828125).x : _2194.x, _2192.y ? vec3(0.00048828125).y : _2194.y, _2192.z ? vec3(0.00048828125).z : _2194.z);
            vec3 _1512 = (inHi - energy) * vec3(0.0625);
            bvec3 _2196 = isnan(_1507);
            bvec3 _2197 = isnan(_1512);
            vec3 _2198 = max(_1507, _1512);
            vec3 _2199 = vec3(_2196.x ? _1512.x : _2198.x, _2196.y ? _1512.y : _2198.y, _2196.z ? _1512.z : _2198.z);
            vec3 err = vec3(_2197.x ? _1507.x : _2199.x, _2197.y ? _1507.y : _2199.y, _2197.z ? _1507.z : _2199.z) + vec3(0.00048828125);
            vec3 _1522 = abs(clamp(fh, hLo - err, hHi + err) - fh);
            sHistory[_1276] = _1522.x;
            sHistory[_1279] = _1522.y;
            sHistory[_1282] = _1522.z;
            i += 64u;
            continue;
        }
        barrier();
        i = gl_LocalInvocationIndex;
        vec3 values[9];
        for (;;)
        {
            if (!(i < 100u))
            {
                break;
            }
            int _1948 = int(i);
            ivec2 _1953 = ivec2(_1948 - 10 * (_1948 / 10), _1948 / 10) - ivec2(1);
            y = -1;
            for (;;)
            {
                if (!(y <= 1))
                {
                    break;
                }
                x = -1;
                for (;;)
                {
                    if (!(x <= 1))
                    {
                        break;
                    }
                    int _1560 = x + 1;
                    ivec2 _1566 = _1953 + ivec2(x, y);
                    int _1573 = (((_1566.y + 6) * 20) + (_1566.x + 6)) * 3;
                    values[((y + 1) * 3) + _1560] = vec3(sHistory[_1573], sHistory[_1573 + 1], sHistory[_1573 + 2]);
                    x = _1560;
                    continue;
                }
                y++;
                continue;
            }
            int at_7 = (((_1953.y + 4) * 16) + (_1953.x + 4)) * 3;
            bvec3 _2201 = isnan(values[1]);
            bvec3 _2202 = isnan(values[2]);
            vec3 _2203 = min(values[1], values[2]);
            vec3 _2204 = vec3(_2201.x ? values[2].x : _2203.x, _2201.y ? values[2].y : _2203.y, _2201.z ? values[2].z : _2203.z);
            vec3 _1974 = vec3(_2202.x ? values[1].x : _2204.x, _2202.y ? values[1].y : _2204.y, _2202.z ? values[1].z : _2204.z);
            bvec3 _2206 = isnan(values[1]);
            bvec3 _2207 = isnan(values[2]);
            vec3 _2208 = max(values[1], values[2]);
            vec3 _2209 = vec3(_2206.x ? values[2].x : _2208.x, _2206.y ? values[2].y : _2208.y, _2206.z ? values[2].z : _2208.z);
            vec3 _1975 = vec3(_2207.x ? values[1].x : _2209.x, _2207.y ? values[1].y : _2209.y, _2207.z ? values[1].z : _2209.z);
            bvec3 _2211 = isnan(values[4]);
            bvec3 _2212 = isnan(values[5]);
            vec3 _2213 = min(values[4], values[5]);
            vec3 _2214 = vec3(_2211.x ? values[5].x : _2213.x, _2211.y ? values[5].y : _2213.y, _2211.z ? values[5].z : _2213.z);
            vec3 _1976 = vec3(_2212.x ? values[4].x : _2214.x, _2212.y ? values[4].y : _2214.y, _2212.z ? values[4].z : _2214.z);
            bvec3 _2216 = isnan(values[4]);
            bvec3 _2217 = isnan(values[5]);
            vec3 _2218 = max(values[4], values[5]);
            vec3 _2219 = vec3(_2216.x ? values[5].x : _2218.x, _2216.y ? values[5].y : _2218.y, _2216.z ? values[5].z : _2218.z);
            vec3 _1977 = vec3(_2217.x ? values[4].x : _2219.x, _2217.y ? values[4].y : _2219.y, _2217.z ? values[4].z : _2219.z);
            bvec3 _2221 = isnan(values[7]);
            bvec3 _2222 = isnan(values[8]);
            vec3 _2223 = min(values[7], values[8]);
            vec3 _2224 = vec3(_2221.x ? values[8].x : _2223.x, _2221.y ? values[8].y : _2223.y, _2221.z ? values[8].z : _2223.z);
            vec3 _1978 = vec3(_2222.x ? values[7].x : _2224.x, _2222.y ? values[7].y : _2224.y, _2222.z ? values[7].z : _2224.z);
            bvec3 _2226 = isnan(values[7]);
            bvec3 _2227 = isnan(values[8]);
            vec3 _2228 = max(values[7], values[8]);
            vec3 _2229 = vec3(_2226.x ? values[8].x : _2228.x, _2226.y ? values[8].y : _2228.y, _2226.z ? values[8].z : _2228.z);
            vec3 _1979 = vec3(_2227.x ? values[7].x : _2229.x, _2227.y ? values[7].y : _2229.y, _2227.z ? values[7].z : _2229.z);
            bvec3 _2231 = isnan(values[0]);
            bvec3 _2232 = isnan(_1974);
            vec3 _2233 = min(values[0], _1974);
            vec3 _2234 = vec3(_2231.x ? _1974.x : _2233.x, _2231.y ? _1974.y : _2233.y, _2231.z ? _1974.z : _2233.z);
            vec3 _1980 = vec3(_2232.x ? values[0].x : _2234.x, _2232.y ? values[0].y : _2234.y, _2232.z ? values[0].z : _2234.z);
            bvec3 _2236 = isnan(values[0]);
            bvec3 _2237 = isnan(_1974);
            vec3 _2238 = max(values[0], _1974);
            vec3 _2239 = vec3(_2236.x ? _1974.x : _2238.x, _2236.y ? _1974.y : _2238.y, _2236.z ? _1974.z : _2238.z);
            vec3 _1981 = vec3(_2237.x ? values[0].x : _2239.x, _2237.y ? values[0].y : _2239.y, _2237.z ? values[0].z : _2239.z);
            bvec3 _2241 = isnan(values[3]);
            bvec3 _2242 = isnan(_1976);
            vec3 _2243 = min(values[3], _1976);
            vec3 _2244 = vec3(_2241.x ? _1976.x : _2243.x, _2241.y ? _1976.y : _2243.y, _2241.z ? _1976.z : _2243.z);
            vec3 _1982 = vec3(_2242.x ? values[3].x : _2244.x, _2242.y ? values[3].y : _2244.y, _2242.z ? values[3].z : _2244.z);
            bvec3 _2246 = isnan(values[3]);
            bvec3 _2247 = isnan(_1976);
            vec3 _2248 = max(values[3], _1976);
            vec3 _2249 = vec3(_2246.x ? _1976.x : _2248.x, _2246.y ? _1976.y : _2248.y, _2246.z ? _1976.z : _2248.z);
            vec3 _1983 = vec3(_2247.x ? values[3].x : _2249.x, _2247.y ? values[3].y : _2249.y, _2247.z ? values[3].z : _2249.z);
            bvec3 _2251 = isnan(values[6]);
            bvec3 _2252 = isnan(_1978);
            vec3 _2253 = min(values[6], _1978);
            vec3 _2254 = vec3(_2251.x ? _1978.x : _2253.x, _2251.y ? _1978.y : _2253.y, _2251.z ? _1978.z : _2253.z);
            vec3 _1984 = vec3(_2252.x ? values[6].x : _2254.x, _2252.y ? values[6].y : _2254.y, _2252.z ? values[6].z : _2254.z);
            bvec3 _2256 = isnan(values[6]);
            bvec3 _2257 = isnan(_1978);
            vec3 _2258 = max(values[6], _1978);
            vec3 _2259 = vec3(_2256.x ? _1978.x : _2258.x, _2256.y ? _1978.y : _2258.y, _2256.z ? _1978.z : _2258.z);
            vec3 _1985 = vec3(_2257.x ? values[6].x : _2259.x, _2257.y ? values[6].y : _2259.y, _2257.z ? values[6].z : _2259.z);
            bvec3 _2261 = isnan(_1981);
            bvec3 _2262 = isnan(_1975);
            vec3 _2263 = min(_1981, _1975);
            vec3 _2264 = vec3(_2261.x ? _1975.x : _2263.x, _2261.y ? _1975.y : _2263.y, _2261.z ? _1975.z : _2263.z);
            vec3 _1986 = vec3(_2262.x ? _1981.x : _2264.x, _2262.y ? _1981.y : _2264.y, _2262.z ? _1981.z : _2264.z);
            bvec3 _2266 = isnan(_1981);
            bvec3 _2267 = isnan(_1975);
            vec3 _2268 = max(_1981, _1975);
            vec3 _2269 = vec3(_2266.x ? _1975.x : _2268.x, _2266.y ? _1975.y : _2268.y, _2266.z ? _1975.z : _2268.z);
            vec3 _1987 = vec3(_2267.x ? _1981.x : _2269.x, _2267.y ? _1981.y : _2269.y, _2267.z ? _1981.z : _2269.z);
            bvec3 _2271 = isnan(_1983);
            bvec3 _2272 = isnan(_1977);
            vec3 _2273 = min(_1983, _1977);
            vec3 _2274 = vec3(_2271.x ? _1977.x : _2273.x, _2271.y ? _1977.y : _2273.y, _2271.z ? _1977.z : _2273.z);
            vec3 _1988 = vec3(_2272.x ? _1983.x : _2274.x, _2272.y ? _1983.y : _2274.y, _2272.z ? _1983.z : _2274.z);
            bvec3 _2276 = isnan(_1983);
            bvec3 _2277 = isnan(_1977);
            vec3 _2278 = max(_1983, _1977);
            vec3 _2279 = vec3(_2276.x ? _1977.x : _2278.x, _2276.y ? _1977.y : _2278.y, _2276.z ? _1977.z : _2278.z);
            vec3 _1989 = vec3(_2277.x ? _1983.x : _2279.x, _2277.y ? _1983.y : _2279.y, _2277.z ? _1983.z : _2279.z);
            bvec3 _2281 = isnan(_1985);
            bvec3 _2282 = isnan(_1979);
            vec3 _2283 = min(_1985, _1979);
            vec3 _2284 = vec3(_2281.x ? _1979.x : _2283.x, _2281.y ? _1979.y : _2283.y, _2281.z ? _1979.z : _2283.z);
            vec3 _1990 = vec3(_2282.x ? _1985.x : _2284.x, _2282.y ? _1985.y : _2284.y, _2282.z ? _1985.z : _2284.z);
            bvec3 _2286 = isnan(_1985);
            bvec3 _2287 = isnan(_1979);
            vec3 _2288 = max(_1985, _1979);
            vec3 _2289 = vec3(_2286.x ? _1979.x : _2288.x, _2286.y ? _1979.y : _2288.y, _2286.z ? _1979.z : _2288.z);
            vec3 _1991 = vec3(_2287.x ? _1985.x : _2289.x, _2287.y ? _1985.y : _2289.y, _2287.z ? _1985.z : _2289.z);
            bvec3 _2291 = isnan(_1980);
            bvec3 _2292 = isnan(_1982);
            vec3 _2293 = max(_1980, _1982);
            vec3 _2294 = vec3(_2291.x ? _1982.x : _2293.x, _2291.y ? _1982.y : _2293.y, _2291.z ? _1982.z : _2293.z);
            vec3 _1993 = vec3(_2292.x ? _1980.x : _2294.x, _2292.y ? _1980.y : _2294.y, _2292.z ? _1980.z : _2294.z);
            bvec3 _2296 = isnan(_1989);
            bvec3 _2297 = isnan(_1991);
            vec3 _2298 = min(_1989, _1991);
            vec3 _2299 = vec3(_2296.x ? _1991.x : _2298.x, _2296.y ? _1991.y : _2298.y, _2296.z ? _1991.z : _2298.z);
            vec3 _1994 = vec3(_2297.x ? _1989.x : _2299.x, _2297.y ? _1989.y : _2299.y, _2297.z ? _1989.z : _2299.z);
            bvec3 _2301 = isnan(_1988);
            bvec3 _2302 = isnan(_1990);
            vec3 _2303 = min(_1988, _1990);
            vec3 _2304 = vec3(_2301.x ? _1990.x : _2303.x, _2301.y ? _1990.y : _2303.y, _2301.z ? _1990.z : _2303.z);
            vec3 _1996 = vec3(_2302.x ? _1988.x : _2304.x, _2302.y ? _1988.y : _2304.y, _2302.z ? _1988.z : _2304.z);
            bvec3 _2306 = isnan(_1988);
            bvec3 _2307 = isnan(_1990);
            vec3 _2308 = max(_1988, _1990);
            vec3 _2309 = vec3(_2306.x ? _1990.x : _2308.x, _2306.y ? _1990.y : _2308.y, _2306.z ? _1990.z : _2308.z);
            vec3 _1997 = vec3(_2307.x ? _1988.x : _2309.x, _2307.y ? _1988.y : _2309.y, _2307.z ? _1988.z : _2309.z);
            bvec3 _2311 = isnan(_1993);
            bvec3 _2312 = isnan(_1984);
            vec3 _2313 = max(_1993, _1984);
            vec3 _2314 = vec3(_2311.x ? _1984.x : _2313.x, _2311.y ? _1984.y : _2313.y, _2311.z ? _1984.z : _2313.z);
            vec3 _1999 = vec3(_2312.x ? _1993.x : _2314.x, _2312.y ? _1993.y : _2314.y, _2312.z ? _1993.z : _2314.z);
            bvec3 _2316 = isnan(_1986);
            bvec3 _2317 = isnan(_1996);
            vec3 _2318 = max(_1986, _1996);
            vec3 _2319 = vec3(_2316.x ? _1996.x : _2318.x, _2316.y ? _1996.y : _2318.y, _2316.z ? _1996.z : _2318.z);
            vec3 _2001 = vec3(_2317.x ? _1986.x : _2319.x, _2317.y ? _1986.y : _2319.y, _2317.z ? _1986.z : _2319.z);
            bvec3 _2321 = isnan(_1987);
            bvec3 _2322 = isnan(_1994);
            vec3 _2323 = min(_1987, _1994);
            vec3 _2324 = vec3(_2321.x ? _1994.x : _2323.x, _2321.y ? _1994.y : _2323.y, _2321.z ? _1994.z : _2323.z);
            vec3 _2002 = vec3(_2322.x ? _1987.x : _2324.x, _2322.y ? _1987.y : _2324.y, _2322.z ? _1987.z : _2324.z);
            bvec3 _2326 = isnan(_2001);
            bvec3 _2327 = isnan(_1997);
            vec3 _2328 = min(_2001, _1997);
            vec3 _2329 = vec3(_2326.x ? _1997.x : _2328.x, _2326.y ? _1997.y : _2328.y, _2326.z ? _1997.z : _2328.z);
            vec3 _2004 = vec3(_2327.x ? _2001.x : _2329.x, _2327.y ? _2001.y : _2329.y, _2327.z ? _2001.z : _2329.z);
            bvec3 _2331 = isnan(_2004);
            bvec3 _2332 = isnan(_2002);
            vec3 _2333 = min(_2004, _2002);
            vec3 _2334 = vec3(_2331.x ? _2002.x : _2333.x, _2331.y ? _2002.y : _2333.y, _2331.z ? _2002.z : _2333.z);
            vec3 _2006 = vec3(_2332.x ? _2004.x : _2334.x, _2332.y ? _2004.y : _2334.y, _2332.z ? _2004.z : _2334.z);
            bvec3 _2336 = isnan(_2004);
            bvec3 _2337 = isnan(_2002);
            vec3 _2338 = max(_2004, _2002);
            vec3 _2339 = vec3(_2336.x ? _2002.x : _2338.x, _2336.y ? _2002.y : _2338.y, _2336.z ? _2002.z : _2338.z);
            vec3 _2007 = vec3(_2337.x ? _2004.x : _2339.x, _2337.y ? _2004.y : _2339.y, _2337.z ? _2004.z : _2339.z);
            bvec3 _2341 = isnan(_1999);
            bvec3 _2342 = isnan(_2006);
            vec3 _2343 = max(_1999, _2006);
            vec3 _2344 = vec3(_2341.x ? _2006.x : _2343.x, _2341.y ? _2006.y : _2343.y, _2341.z ? _2006.z : _2343.z);
            vec3 _2009 = vec3(_2342.x ? _1999.x : _2344.x, _2342.y ? _1999.y : _2344.y, _2342.z ? _1999.z : _2344.z);
            bvec3 _2346 = isnan(_2009);
            bvec3 _2347 = isnan(_2007);
            vec3 _2348 = min(_2009, _2007);
            vec3 _2349 = vec3(_2346.x ? _2007.x : _2348.x, _2346.y ? _2007.y : _2348.y, _2346.z ? _2007.z : _2348.z);
            vec3 _2010 = vec3(_2347.x ? _2009.x : _2349.x, _2347.y ? _2009.y : _2349.y, _2347.z ? _2009.z : _2349.z);
            sBlur[at_7] = _2010.x;
            sBlur[at_7 + 1] = _2010.y;
            sBlur[at_7 + 2] = _2010.z;
            i += 64u;
            continue;
        }
        barrier();
        bool _65;
        if (px.x >= _373.x)
        {
            _65 = true;
        }
        else
        {
            _65 = px.y >= _373.y;
        }
        if (!(_65))
        {
            energy = vec3(0.0);
            y = -1;
            for (;;)
            {
                if (!(y <= 1))
                {
                    break;
                }
                x = -1;
                for (;;)
                {
                    if (!(x <= 1))
                    {
                        break;
                    }
                    ivec2 _1715 = _386 + ivec2(x, y);
                    int _1722 = (((_1715.y + 4) * 16) + (_1715.x + 4)) * 3;
                    vec3 _1731 = vec3(sBlur[_1722], sBlur[_1722 + 1], sBlur[_1722 + 2]);
                    bvec3 _2351 = isnan(energy);
                    bvec3 _2352 = isnan(_1731);
                    vec3 _2353 = max(energy, _1731);
                    vec3 _2354 = vec3(_2351.x ? _1731.x : _2353.x, _2351.y ? _1731.y : _2353.y, _2351.z ? _1731.z : _2353.z);
                    energy = vec3(_2352.x ? energy.x : _2354.x, _2352.y ? energy.y : _2354.y, _2352.z ? energy.z : _2354.z);
                    x++;
                    continue;
                }
                y++;
                continue;
            }
            bvec3 _2356 = isnan(_1233);
            bvec3 _2357 = isnan(vec3(9.9999999747524270787835121154785e-07));
            vec3 _2358 = max(_1233, vec3(9.9999999747524270787835121154785e-07));
            vec3 _2359 = vec3(_2356.x ? vec3(9.9999999747524270787835121154785e-07).x : _2358.x, _2356.y ? vec3(9.9999999747524270787835121154785e-07).y : _2358.y, _2356.z ? vec3(9.9999999747524270787835121154785e-07).z : _2358.z);
            vec3 _2014 = clamp(vec3(1.0) - (energy / vec3(_2357.x ? _1233.x : _2359.x, _2357.y ? _1233.y : _2359.y, _2357.z ? _1233.z : _2359.z)), vec3(0.0), vec3(1.0));
            float _1765 = _2014.x;
            float _1766 = _2014.y;
            float _1767 = _2014.z;
            float _1768 = isnan(_1767) ? _1766 : (isnan(_1766) ? _1767 : min(_1766, _1767));
            float _1769 = isnan(_1768) ? _1765 : (isnan(_1765) ? _1768 : min(_1765, _1768));
            uvec2 _1770 = uvec2(px);
            imageStore(uRejection, ivec2(_1770), vec4(_1769, 0.0, 0.0, 0.0));
            float parallax;
            if (p.control.z > 0.5)
            {
                parallax = textureLod(_2079, (vec2(px) + vec2(0.5)) * p.size.zw, 0.0).x;
            }
            else
            {
                parallax = 1.0;
            }
            float total;
            if (parallax < 0.5)
            {
                total = 1.0;
            }
            else
            {
                total = clamp(1.0 - (4.0 * _1769), 0.0, 1.0);
            }
            float _1807 = 1.0 - _1769;
            float _1809 = isnan(total) ? _1807 : (isnan(_1807) ? total : max(_1807, total));
            imageStore(uGuide, ivec2(_1770), vec4(mix(vec3(_530, _532, _534), vec3(_521, _524, _527), vec3(isnan(_1809) ? p.control.y : (isnan(p.control.y) ? _1809 : max(p.control.y, _1809)))), 1.0));
        }
    }
}

