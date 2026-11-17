#version 430
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(binding = 0, std140) uniform Params_std140
{
    vec4 _input;
    vec4 history;
    vec4 control;
    vec4 control2;
    vec4 control3;
} p;

layout(binding = 0, rgba16f) uniform restrict writeonly image2D uHistoryColour;
layout(binding = 1, r8) uniform restrict writeonly image2D uHistoryMetadata;
layout(binding = 1) uniform sampler2D _1468;
layout(binding = 9) uniform sampler2D _1470;
layout(binding = 2) uniform sampler2D _1472;
layout(binding = 5) uniform sampler2D _1474;
layout(binding = 7) uniform sampler2D _1476;
layout(binding = 8) uniform sampler2D _1478;
layout(binding = 6) uniform sampler2D _1481;
layout(binding = 0) uniform sampler2D _1484;
layout(binding = 3) uniform sampler2D _1486;
layout(binding = 4) uniform sampler2D _1488;

void main()
{
    {
        ivec2 _197 = ivec2(gl_GlobalInvocationID.xy);
        ivec2 _203 = ivec2(p.history.xy);
        bool offScreen;
        if (_197.x >= _203.x)
        {
            offScreen = true;
        }
        else
        {
            offScreen = _197.y >= _203.y;
        }
        if (!(offScreen))
        {
            float _223 = isnan(p.control.y) ? 1.0 : (isnan(1.0) ? p.control.y : max(1.0, p.control.y));
            ivec2 _240 = ivec2(p._input.xy);
            vec2 inputPos_1 = ((vec2(_197) + vec2(0.5)) * p._input.xy) / p.history.xy;
            vec2 uv = inputPos_1 / p._input.xy;
            vec3 _257 = textureLod(_1468, uv, 0.0).xyz;
            bvec3 _1500 = isnan(_257);
            bvec3 _1501 = isnan(vec3(0.0));
            vec3 _1502 = max(_257, vec3(0.0));
            vec3 _1503 = vec3(_1500.x ? vec3(0.0).x : _1502.x, _1500.y ? vec3(0.0).y : _1502.y, _1500.z ? vec3(0.0).z : _1502.z);
            vec4 _263 = textureGather(_1470, uv);
            float _264 = _263.x;
            float _265 = _263.y;
            float _266 = isnan(_265) ? _264 : (isnan(_264) ? _265 : max(_264, _265));
            float _267 = _263.z;
            float _268 = _263.w;
            float _269 = isnan(_268) ? _267 : (isnan(_267) ? _268 : max(_267, _268));
            bool foreground = (isnan(_269) ? _266 : (isnan(_266) ? _269 : max(_266, _269))) >= 0.89999997615814208984375;
            vec2 sj;
            if (foreground)
            {
                sj = vec2(0.0);
            }
            else
            {
                sj = vec2(p.control.w, p.control2.x);
            }
            vec2 uvJ = uv + (sj / p._input.xy);
            vec3 _287 = textureLod(_1468, uvJ, 0.0).xyz;
            bvec3 _1520 = isnan(_287);
            bvec3 _1521 = isnan(vec3(0.0));
            vec3 _1522 = max(_287, vec3(0.0));
            vec3 _1523 = vec3(_1520.x ? vec3(0.0).x : _1522.x, _1520.y ? vec3(0.0).y : _1522.y, _1520.z ? vec3(0.0).z : _1522.z);
            if (p.control.x < 0.5)
            {
                imageStore(uHistoryColour, ivec2(gl_GlobalInvocationID.xy), vec4(vec3(_1501.x ? _257.x : _1503.x, _1501.y ? _257.y : _1503.y, _1501.z ? _257.z : _1503.z), 1.0));
                imageStore(uHistoryMetadata, ivec2(gl_GlobalInvocationID.xy), vec4(1.0, 0.0, 0.0, 0.0));
            }
            else
            {
                vec2 v = textureLod(_1472, uvJ, 0.0).xy;
                vec2 prevUv = uv - v;
                vec2 grid;
                if (abs(p.control.z - p.control3.w) > 9.9999997473787516355514526367188e-06)
                {
                    grid = p.history.xy / vec2(isnan(1.0) ? p.control3.w : (isnan(p.control3.w) ? 1.0 : max(p.control3.w, 1.0)));
                }
                else
                {
                    grid = p._input.xy;
                }
                float _332 = length(v * grid);
                if (any(lessThan(prevUv, vec2(0.0))))
                {
                    offScreen = true;
                }
                else
                {
                    offScreen = any(greaterThan(prevUv, vec2(1.0)));
                }
                float believable;
                if (p.control2.y > 0.5)
                {
                    believable = textureLod(_1474, uvJ, 0.0).x;
                }
                else
                {
                    believable = 1.0;
                }
                float shading;
                if (p.control2.w > 0.5)
                {
                    shading = textureLod(_1476, uvJ, 0.0).x;
                }
                else
                {
                    shading = 1.0;
                }
                float relaxClamp;
                if (p.control2.w > 0.5)
                {
                    relaxClamp = textureLod(_1478, uvJ, 0.0).x;
                }
                else
                {
                    relaxClamp = 1.0;
                }
                bool _53;
                if (offScreen)
                {
                    _53 = true;
                }
                else
                {
                    _53 = believable < 0.5;
                }
                if (_53)
                {
                    relaxClamp = 0.0;
                }
                float relaxClamp_1 = relaxClamp * believable;
                if (offScreen)
                {
                    _53 = true;
                }
                else
                {
                    _53 = foreground;
                }
                float refine;
                if (_53)
                {
                    refine = 0.0;
                }
                else
                {
                    refine = clamp(((16.0 * believable) * shading) - 13.0, 0.0, 1.0);
                }
                float _423 = mix(1.0, isnan(1.0) ? p.control.z : (isnan(p.control.z) ? 1.0 : max(p.control.z, 1.0)), refine);
                vec2 inputPos;
                float lerpAmt;
                if (p.control2.z > 0.5)
                {
                    if (offScreen)
                    {
                        _53 = true;
                    }
                    else
                    {
                        _53 = believable < 0.5;
                    }
                    if (_53)
                    {
                        lerpAmt = 1.0;
                    }
                    else
                    {
                        lerpAmt = clamp(1.0 - (4.0 * (isnan(relaxClamp_1) ? shading : (isnan(shading) ? relaxClamp_1 : min(shading, relaxClamp_1)))), 0.0, 1.0);
                    }
                    inputPos = inputPos_1 + (texelFetch(_1481, ivec3(clamp(ivec2(inputPos_1 + sj), ivec2(0), _240 - ivec2(1)), 0).xy, 0).xy * lerpAmt);
                }
                else
                {
                    inputPos = inputPos_1;
                }
                ivec2 _473 = ivec2(floor(inputPos - vec2(1.0)));
                int gy = 0;
                vec3 sumColour = vec3(0.0);
                lerpAmt = 0.0;
                float cov = 0.0;
                float add;
                float blend;
                int ny;
                vec3 current;
                bool _68;
                bool _69;
                for (;;)
                {
                    if (!(gy < 3))
                    {
                        break;
                    }
                    ny = 0;
                    current = sumColour;
                    add = lerpAmt;
                    blend = cov;
                    for (;;)
                    {
                        bool _129_ladder_break = false;
                        {
                            if (!(ny < 3))
                            {
                                _129_ladder_break = true;
                            }
                            else
                            {
                                ivec2 kk = _473 + ivec2(ny, gy);
                                int _496 = kk.x;
                                if (_496 < 0)
                                {
                                    _53 = true;
                                }
                                else
                                {
                                    _53 = kk.y < 0;
                                }
                                if (_53)
                                {
                                    _68 = true;
                                }
                                else
                                {
                                    _68 = _496 >= _240.x;
                                }
                                if (_68)
                                {
                                    _69 = true;
                                }
                                else
                                {
                                    _69 = kk.y >= _240.y;
                                }
                                if (!(_69))
                                {
                                    vec2 _531 = ((vec2(kk) + vec2(0.5)) - sj) - inputPos;
                                    float _1144 = clamp((_423 * _423) * dot(_531, _531), 0.0, 1.0);
                                    float _1151 = clamp(((1.0 - (1.89999997615814208984375 * _1144)) + ((0.89999997615814208984375 * _1144) * _1144)) + 0.004999999888241291046142578125, 0.0, 1.0);
                                    vec3 _557 = texelFetch(_1484, ivec3(kk, 0).xy, 0).xyz;
                                    bvec3 _1535 = isnan(_557);
                                    bvec3 _1536 = isnan(vec3(0.0));
                                    vec3 _1537 = max(_557, vec3(0.0));
                                    vec3 _1538 = vec3(_1535.x ? vec3(0.0).x : _1537.x, _1535.y ? vec3(0.0).y : _1537.y, _1535.z ? vec3(0.0).z : _1537.z);
                                    vec3 _558 = vec3(_1536.x ? _557.x : _1538.x, _1536.y ? _557.y : _1538.y, _1536.z ? _557.z : _1538.z);
                                    vec3 _1155 = _558 * (isnan(9.9999997473787516355514526367188e-05) ? p.control3.x : (isnan(p.control3.x) ? 9.9999997473787516355514526367188e-05 : max(p.control3.x, 9.9999997473787516355514526367188e-05)));
                                    float _1163 = 1.0 / (((_1155.x + (2.0 * _1155.y)) + _1155.z) + 4.0);
                                    float hw = _1151 * (isnan(_1163) ? 9.9999997473787516355514526367188e-05 : (isnan(9.9999997473787516355514526367188e-05) ? _1163 : max(9.9999997473787516355514526367188e-05, _1163)));
                                    current += (_558 * hw);
                                    add += hw;
                                    blend += _1151;
                                }
                            }
                        }
                        if (_129_ladder_break)
                        {
                            break;
                        }
                        ny++;
                        continue;
                    }
                    gy++;
                    sumColour = current;
                    lerpAmt = add;
                    cov = blend;
                    continue;
                }
                if (lerpAmt > 9.9999999747524270787835121154785e-07)
                {
                    current = sumColour / vec3(lerpAmt);
                }
                else
                {
                    current = vec3(_1521.x ? _287.x : _1523.x, _1521.y ? _287.y : _1523.y, _1521.z ? _287.z : _1523.z);
                }
                float _630 = clamp(cov, 0.0, 1.0);
                if (foreground)
                {
                    imageStore(uHistoryColour, ivec2(gl_GlobalInvocationID.xy), vec4(current, 1.0));
                    imageStore(uHistoryMetadata, ivec2(gl_GlobalInvocationID.xy), vec4(_630 / _223, 0.0, 0.0, 0.0));
                }
                else
                {
                    add = 0.0;
                    vec3 lo = vec3(1000000015047466219876688855040.0);
                    vec3 hi = vec3(-1000000015047466219876688855040.0);
                    ny = -1;
                    vec3 m1 = vec3(0.0);
                    vec3 m2 = vec3(0.0);
                    vec3 h;
                    for (;;)
                    {
                        if (!(ny <= 1))
                        {
                            break;
                        }
                        blend = add;
                        h = lo;
                        vec3 hi_1 = hi;
                        int nx = -1;
                        for (;;)
                        {
                            if (!(nx <= 1))
                            {
                                break;
                            }
                            int _666 = nx;
                            vec4 _sampled = textureLod(_1468, uvJ + (vec2(float(_666), float(ny)) / p._input.xy), 0.0);
                            float _679 = _sampled.w - 1.0;
                            vec3 _682 = _sampled.xyz;
                            bvec3 _1555 = isnan(_682);
                            bvec3 _1556 = isnan(vec3(0.0));
                            vec3 _1557 = max(_682, vec3(0.0));
                            vec3 _1558 = vec3(_1555.x ? vec3(0.0).x : _1557.x, _1555.y ? vec3(0.0).y : _1557.y, _1555.z ? vec3(0.0).z : _1557.z);
                            vec3 _1174 = vec3(_1556.x ? _682.x : _1558.x, _1556.y ? _682.y : _1558.y, _1556.z ? _682.z : _1558.z) * (isnan(9.9999997473787516355514526367188e-05) ? p.control3.x : (isnan(p.control3.x) ? 9.9999997473787516355514526367188e-05 : max(p.control3.x, 9.9999997473787516355514526367188e-05)));
                            vec3 _1177 = _1174 / (_1174 + vec3(0.17000000178813934326171875));
                            vec3 _1178 = _1177 * _1177;
                            bvec3 _1565 = isnan(h);
                            bvec3 _1566 = isnan(_1178);
                            vec3 _1567 = min(h, _1178);
                            vec3 _1568 = vec3(_1565.x ? _1178.x : _1567.x, _1565.y ? _1178.y : _1567.y, _1565.z ? _1178.z : _1567.z);
                            bvec3 _1570 = isnan(hi_1);
                            bvec3 _1571 = isnan(_1178);
                            vec3 _1572 = max(hi_1, _1178);
                            vec3 _1573 = vec3(_1570.x ? _1178.x : _1572.x, _1570.y ? _1178.y : _1572.y, _1570.z ? _1178.z : _1572.z);
                            blend = isnan(_679) ? blend : (isnan(blend) ? _679 : max(blend, _679));
                            h = vec3(_1566.x ? h.x : _1568.x, _1566.y ? h.y : _1568.y, _1566.z ? h.z : _1568.z);
                            hi_1 = vec3(_1571.x ? hi_1.x : _1573.x, _1571.y ? hi_1.y : _1573.y, _1571.z ? hi_1.z : _1573.z);
                            nx++;
                            m1 += _1178;
                            m2 += (_1178 * _1178);
                            continue;
                        }
                        add = blend;
                        lo = h;
                        hi = hi_1;
                        ny++;
                        continue;
                    }
                    float _734 = clamp(4.0 * (isnan(add) ? 0.0 : (isnan(0.0) ? add : max(0.0, add))), 0.0, 1.0);
                    vec3 mu = m1 * vec3(0.111111111938953399658203125);
                    vec3 _743 = (m2 * vec3(0.111111111938953399658203125)) - (vec3(0.012345679104328155517578125) * (m1 * m1));
                    bvec3 _1580 = isnan(_743);
                    bvec3 _1581 = isnan(vec3(0.0));
                    vec3 _1582 = max(_743, vec3(0.0));
                    vec3 _1583 = vec3(_1580.x ? vec3(0.0).x : _1582.x, _1580.y ? vec3(0.0).y : _1582.y, _1580.z ? vec3(0.0).z : _1582.z);
                    vec3 _745 = sqrt(vec3(_1581.x ? _743.x : _1583.x, _1581.y ? _743.y : _1583.y, _1581.z ? _743.z : _1583.z));
                    vec3 _746 = mu - _745;
                    bvec3 _1585 = isnan(lo);
                    bvec3 _1586 = isnan(_746);
                    vec3 _1587 = max(lo, _746);
                    vec3 _1588 = vec3(_1585.x ? _746.x : _1587.x, _1585.y ? _746.y : _1587.y, _1585.z ? _746.z : _1587.z);
                    vec3 _748 = vec3(_1586.x ? lo.x : _1588.x, _1586.y ? lo.y : _1588.y, _1586.z ? lo.z : _1588.z);
                    vec3 _749 = mu + _745;
                    bvec3 _1590 = isnan(hi);
                    bvec3 _1591 = isnan(_749);
                    vec3 _1592 = min(hi, _749);
                    vec3 _1593 = vec3(_1590.x ? _749.x : _1592.x, _1590.y ? _749.y : _1592.y, _1590.z ? _749.z : _1592.z);
                    vec3 _751 = vec3(_1591.x ? hi.x : _1593.x, _1591.y ? hi.y : _1593.y, _1591.z ? hi.z : _1593.z);
                    if (offScreen)
                    {
                        imageStore(uHistoryColour, ivec2(gl_GlobalInvocationID.xy), vec4(current, 1.0 - _734));
                        imageStore(uHistoryMetadata, ivec2(gl_GlobalInvocationID.xy), vec4(1.0 / _223, 0.0, 0.0, 0.0));
                    }
                    else
                    {
                        if (believable < 0.5)
                        {
                            imageStore(uHistoryColour, ivec2(gl_GlobalInvocationID.xy), vec4(current, 1.0 - _734));
                            imageStore(uHistoryMetadata, ivec2(gl_GlobalInvocationID.xy), vec4(_630 / _223, 0.0, 0.0, 0.0));
                        }
                        else
                        {
                            vec2 _1197 = prevUv * p.history.xy;
                            vec2 _1200 = floor(_1197 - vec2(0.5));
                            vec2 _1202 = _1200 + vec2(0.5);
                            vec2 _1203 = _1197 - _1202;
                            vec2 _1204 = _1203 * 0.5;
                            vec2 _1210 = _1203 * (vec2(-0.5) + (_1203 * (vec2(1.0) - _1204)));
                            vec2 _1211 = _1203 * _1203;
                            vec2 _1212 = _1203 * 1.5;
                            vec2 _1223 = _1203 * (vec2(0.5) + (_1203 * (vec2(2.0) - _1212)));
                            vec2 _1226 = _1211 * (vec2(-0.5) + _1204);
                            vec2 _1227 = (vec2(1.0) + (_1211 * (vec2(-2.5) + _1212))) + _1223;
                            bvec2 _1595 = isnan(_1227);
                            bvec2 _1596 = isnan(vec2(9.9999997473787516355514526367188e-06));
                            vec2 _1597 = max(_1227, vec2(9.9999997473787516355514526367188e-06));
                            vec2 _1598 = vec2(_1595.x ? vec2(9.9999997473787516355514526367188e-06).x : _1597.x, _1595.y ? vec2(9.9999997473787516355514526367188e-06).y : _1597.y);
                            vec2 _1237 = (_1200 + vec2(-0.5)) * p.history.zw;
                            vec2 _1240 = (_1202 + (_1223 / vec2(_1596.x ? _1227.x : _1598.x, _1596.y ? _1227.y : _1598.y))) * p.history.zw;
                            vec2 _1243 = (_1200 + vec2(2.5)) * p.history.zw;
                            float _1185[3] = float[](_1237.x, _1240.x, _1243.x);
                            float _1186[3] = float[](_1237.y, _1240.y, _1243.y);
                            float _1187[3] = float[](_1210.x, _1227.x, _1226.x);
                            float _1188[3] = float[](_1210.y, _1227.y, _1226.y);
                            int _1189 = 0;
                            vec4 _1190 = vec4(0.0);
                            for (;;)
                            {
                                if (!(_1189 < 3))
                                {
                                    break;
                                }
                                int _1191 = 0;
                                for (;;)
                                {
                                    if (!(_1191 < 3))
                                    {
                                        break;
                                    }
                                    int _1276 = _1191;
                                    _1191++;
                                    _1190 += (textureLod(_1486, vec2(_1185[_1276], _1186[_1189]), 0.0) * (_1187[_1276] * _1188[_1189]));
                                    continue;
                                }
                                _1189++;
                                continue;
                            }
                            bvec3 _1600 = isnan(_1190.xyz);
                            bvec3 _1601 = isnan(vec3(0.0));
                            vec3 _1602 = max(_1190.xyz, vec3(0.0));
                            vec3 _1603 = vec3(_1600.x ? vec3(0.0).x : _1602.x, _1600.y ? vec3(0.0).y : _1602.y, _1600.z ? vec3(0.0).z : _1602.z);
                            vec3 _938 = vec3(_1601.x ? _1190.xyz.x : _1603.x, _1601.y ? _1190.xyz.y : _1603.y, _1601.z ? _1190.xyz.z : _1603.z);
                            float count = _223 * textureLod(_1488, prevUv, 0.0).x;
                            bool _1311;
                            if (any(isnan(_938)))
                            {
                                _1311 = true;
                            }
                            else
                            {
                                _1311 = any(isinf(_938));
                            }
                            if (!(!_1311))
                            {
                                offScreen = true;
                            }
                            else
                            {
                                offScreen = count < 0.001000000047497451305389404296875;
                            }
                            if (offScreen)
                            {
                                imageStore(uHistoryColour, ivec2(gl_GlobalInvocationID.xy), vec4(current, 1.0 - _734));
                                imageStore(uHistoryMetadata, ivec2(gl_GlobalInvocationID.xy), vec4(_630 / _223, 0.0, 0.0, 0.0));
                            }
                            else
                            {
                                vec3 _1326 = _938 * (isnan(9.9999997473787516355514526367188e-05) ? p.control3.x : (isnan(p.control3.x) ? 9.9999997473787516355514526367188e-05 : max(p.control3.x, 9.9999997473787516355514526367188e-05)));
                                vec3 _1329 = _1326 / (_1326 + vec3(0.17000000178813934326171875));
                                vec3 _1330 = _1329 * _1329;
                                vec3 centre = (_748 + _751) * 0.5;
                                vec3 _993 = (_751 - _748) * 0.5;
                                bvec3 _1610 = isnan(_993);
                                bvec3 _1611 = isnan(vec3(9.9999997473787516355514526367188e-06));
                                vec3 _1612 = max(_993, vec3(9.9999997473787516355514526367188e-06));
                                vec3 _1613 = vec3(_1610.x ? vec3(9.9999997473787516355514526367188e-06).x : _1612.x, _1610.y ? vec3(9.9999997473787516355514526367188e-06).y : _1612.y, _1610.z ? vec3(9.9999997473787516355514526367188e-06).z : _1612.z);
                                vec3 e = _1330 - centre;
                                vec3 ratio = abs(e) / vec3(_1611.x ? _993.x : _1613.x, _1611.y ? _993.y : _1613.y, _1611.z ? _993.z : _1613.z);
                                float _999 = ratio.x;
                                float _1000 = ratio.y;
                                float _1001 = ratio.z;
                                float _1002 = isnan(_1001) ? _1000 : (isnan(_1000) ? _1001 : max(_1000, _1001));
                                float _1003 = isnan(_1002) ? _999 : (isnan(_999) ? _1002 : max(_999, _1002));
                                if (_1003 > 1.0)
                                {
                                    h = centre + (e / vec3(_1003));
                                }
                                else
                                {
                                    h = _1330;
                                }
                                bvec3 _1625 = isnan(h);
                                bvec3 _1626 = isnan(vec3(0.0));
                                vec3 _1627 = max(h, vec3(0.0));
                                vec3 _1628 = vec3(_1625.x ? vec3(0.0).x : _1627.x, _1625.y ? vec3(0.0).y : _1627.y, _1625.z ? vec3(0.0).z : _1627.z);
                                vec3 _1340 = sqrt(vec3(_1626.x ? h.x : _1628.x, _1626.y ? h.y : _1628.y, _1626.z ? h.z : _1628.z));
                                vec3 _1343 = vec3(1.0) - _1340;
                                bvec3 _1630 = isnan(_1343);
                                bvec3 _1631 = isnan(vec3(9.9999997473787516355514526367188e-05));
                                vec3 _1632 = max(_1343, vec3(9.9999997473787516355514526367188e-05));
                                vec3 _1633 = vec3(_1630.x ? vec3(9.9999997473787516355514526367188e-05).x : _1632.x, _1630.y ? vec3(9.9999997473787516355514526367188e-05).y : _1632.y, _1630.z ? vec3(9.9999997473787516355514526367188e-05).z : _1632.z);
                                vec3 _1348 = ((_1340 * 0.17000000178813934326171875) / vec3(_1631.x ? _1343.x : _1633.x, _1631.y ? _1343.y : _1633.y, _1631.z ? _1343.z : _1633.z)) / vec3(isnan(9.9999997473787516355514526367188e-05) ? p.control3.x : (isnan(p.control3.x) ? 9.9999997473787516355514526367188e-05 : max(p.control3.x, 9.9999997473787516355514526367188e-05)));
                                float _1033 = clamp(1.0 - _1190.w, 0.0, 1.0);
                                float _1034 = 1.0 - _1033;
                                float _1035 = isnan(_1034) ? relaxClamp_1 : (isnan(relaxClamp_1) ? _1034 : min(relaxClamp_1, _1034));
                                vec3 _1358 = _1348 * (isnan(9.9999997473787516355514526367188e-05) ? p.control3.x : (isnan(p.control3.x) ? 9.9999997473787516355514526367188e-05 : max(p.control3.x, 9.9999997473787516355514526367188e-05)));
                                float _1366 = 1.0 / (((_1358.x + (2.0 * _1358.y)) + _1358.z) + 4.0);
                                float wClip = (1.0 - _1035) * (isnan(_1366) ? 9.9999997473787516355514526367188e-05 : (isnan(9.9999997473787516355514526367188e-05) ? _1366 : max(9.9999997473787516355514526367188e-05, _1366)));
                                vec3 _1377 = _938 * (isnan(9.9999997473787516355514526367188e-05) ? p.control3.x : (isnan(p.control3.x) ? 9.9999997473787516355514526367188e-05 : max(p.control3.x, 9.9999997473787516355514526367188e-05)));
                                float _1385 = 1.0 / (((_1377.x + (2.0 * _1377.y)) + _1377.z) + 4.0);
                                float wLin = _1035 * (isnan(_1385) ? 9.9999997473787516355514526367188e-05 : (isnan(9.9999997473787516355514526367188e-05) ? _1385 : max(9.9999997473787516355514526367188e-05, _1385)));
                                float _1044 = wClip + wLin;
                                vec3 hist = ((_1348 * wClip) + (_938 * wLin)) / vec3(isnan(9.9999999747524270787835121154785e-07) ? _1044 : (isnan(_1044) ? 9.9999999747524270787835121154785e-07 : max(_1044, 9.9999999747524270787835121154785e-07)));
                                float _1051 = mix(_223, 3.0, clamp(_332 * 0.125, 0.0, 1.0));
                                float _1053 = count + _630;
                                float _1054 = isnan(_223) ? _1053 : (isnan(_1053) ? _223 : min(_1053, _223));
                                float _1055 = isnan(_1051) ? _1054 : (isnan(_1054) ? _1051 : min(_1054, _1051));
                                if (_1055 > 9.9999999747524270787835121154785e-07)
                                {
                                    blend = clamp(_630 / _1055, 0.0, 1.0);
                                }
                                else
                                {
                                    blend = 1.0;
                                }
                                float maxValid = 1.0 - (clamp(1.0 - (4.0 / _223), 0.0, 1.0) * clamp(_332, 0.0, 1.0));
                                float _1400 = (current.x + (2.0 * current.y)) + current.z;
                                float _1408 = (hist.x + (2.0 * hist.y)) + hist.z;
                                float _1085 = isnan(_1408) ? _1400 : (isnan(_1400) ? _1408 : max(_1400, _1408));
                                float _1088 = clamp(abs(_1400 - _1408) / (isnan(9.9999997473787516355514526367188e-05) ? _1085 : (isnan(_1085) ? 9.9999997473787516355514526367188e-05 : max(_1085, 9.9999997473787516355514526367188e-05))), 0.0, 1.0);
                                float _1090 = 1.0 - (isnan(_1088) ? maxValid : (isnan(maxValid) ? _1088 : max(maxValid, _1088)));
                                float _1092 = isnan(_1090) ? blend : (isnan(blend) ? _1090 : max(blend, _1090));
                                float _1097 = clamp(2.0 * (0.5 - (isnan(_1035) ? shading : (isnan(shading) ? _1035 : min(shading, _1035)))), 0.0, 1.0);
                                float _1098 = isnan(_1097) ? _1092 : (isnan(_1092) ? _1097 : max(_1092, _1097));
                                float _1099 = 0.85000002384185791015625 * _734;
                                float _1101 = isnan(_1099) ? _1098 : (isnan(_1098) ? _1099 : max(_1098, _1099));
                                float _1105 = (isnan(0.25) ? _630 : (isnan(_630) ? 0.25 : max(_630, 0.25))) / (isnan(0.001000000047497451305389404296875) ? _1101 : (isnan(_1101) ? 0.001000000047497451305389404296875 : max(_1101, 0.001000000047497451305389404296875)));
                                vec3 _1412 = current * (isnan(9.9999997473787516355514526367188e-05) ? p.control3.x : (isnan(p.control3.x) ? 9.9999997473787516355514526367188e-05 : max(p.control3.x, 9.9999997473787516355514526367188e-05)));
                                float _1420 = 1.0 / (((_1412.x + (2.0 * _1412.y)) + _1412.z) + 4.0);
                                float wc = _1101 * (isnan(_1420) ? 9.9999997473787516355514526367188e-05 : (isnan(9.9999997473787516355514526367188e-05) ? _1420 : max(9.9999997473787516355514526367188e-05, _1420)));
                                vec3 _1431 = hist * (isnan(9.9999997473787516355514526367188e-05) ? p.control3.x : (isnan(p.control3.x) ? 9.9999997473787516355514526367188e-05 : max(p.control3.x, 9.9999997473787516355514526367188e-05)));
                                float _1439 = 1.0 / (((_1431.x + (2.0 * _1431.y)) + _1431.z) + 4.0);
                                float wh = (1.0 - _1101) * (isnan(_1439) ? 9.9999997473787516355514526367188e-05 : (isnan(9.9999997473787516355514526367188e-05) ? _1439 : max(9.9999997473787516355514526367188e-05, _1439)));
                                float _1117 = wc + wh;
                                vec3 result = ((current * wc) + (hist * wh)) / vec3(isnan(9.9999999747524270787835121154785e-07) ? _1117 : (isnan(_1117) ? 9.9999999747524270787835121154785e-07 : max(_1117, 9.9999999747524270787835121154785e-07)));
                                float _1121 = 0.5 * _1033;
                                bvec3 _1760 = isnan(result);
                                bvec3 _1761 = isnan(vec3(0.0));
                                vec3 _1762 = max(result, vec3(0.0));
                                vec3 _1763 = vec3(_1760.x ? vec3(0.0).x : _1762.x, _1760.y ? vec3(0.0).y : _1762.y, _1760.z ? vec3(0.0).z : _1762.z);
                                imageStore(uHistoryColour, ivec2(gl_GlobalInvocationID.xy), vec4(vec3(_1761.x ? result.x : _1763.x, _1761.y ? result.y : _1763.y, _1761.z ? result.z : _1763.z), 1.0 - (isnan(_1121) ? _734 : (isnan(_734) ? _1121 : max(_734, _1121)))));
                                imageStore(uHistoryMetadata, ivec2(gl_GlobalInvocationID.xy), vec4((isnan(_1105) ? _1055 : (isnan(_1055) ? _1105 : min(_1055, _1105))) / _223, 0.0, 0.0, 0.0));
                            }
                        }
                    }
                }
            }
        }
    }
}

