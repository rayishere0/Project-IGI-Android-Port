#version 430
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(binding = 0, std140) uniform Params_std140
{
    vec4 outputSize;
    vec4 historySize;
    vec4 control;
    vec4 control2;
} p;

layout(binding = 0, rgba16f) uniform restrict writeonly image2D uOutput;
layout(binding = 5) uniform sampler2D _525;
layout(binding = 4) uniform sampler2D _527;
layout(binding = 3) uniform sampler2D _529;
layout(binding = 1) uniform sampler2D _532;
layout(binding = 2) uniform sampler2D _534;
layout(binding = 0) uniform sampler2D _536;

void main()
{
    {
        ivec2 _100 = ivec2(gl_GlobalInvocationID.xy);
        ivec2 _107 = ivec2(p.outputSize.xy);
        bool _33;
        if (_100.x >= _107.x)
        {
            _33 = true;
        }
        else
        {
            _33 = _100.y >= _107.y;
        }
        if (!(_33))
        {
            bvec2 _538 = isnan(p.control.xy);
            bvec2 _539 = isnan(vec2(0.001000000047497451305389404296875));
            vec2 _540 = max(p.control.xy, vec2(0.001000000047497451305389404296875));
            vec2 _541 = vec2(_538.x ? vec2(0.001000000047497451305389404296875).x : _540.x, _538.y ? vec2(0.001000000047497451305389404296875).y : _540.y);
            int debugView = int(p.control.z + 0.5);
            vec3 lo;
            if (debugView != 0)
            {
                vec2 uv = (vec2(_100) + vec2(0.5)) * p.outputSize.zw;
                if (debugView == 1)
                {
                    uvec2 _vecSize = uvec2(textureSize(_532, 0));
                    vec2 v = textureLod(_534, uv, 0.0).xy * vec2(float(_vecSize.x), float(_vecSize.y));
                    lo = vec3(0.5 + (v.y * 0.0500000007450580596923828125), 0.5 + (v.x * 0.0500000007450580596923828125), 0.5);
                }
                else
                {
                    if (debugView == 2)
                    {
                        lo = textureLod(_529, uv, 0.0).xxx;
                    }
                    else
                    {
                        if (debugView == 3)
                        {
                            lo = textureLod(_527, uv, 0.0).xxx;
                        }
                        else
                        {
                            lo = textureLod(_525, (uv * p.historySize.xy) * p.historySize.zw, 0.0).xxx;
                        }
                    }
                }
                imageStore(uOutput, ivec2(gl_GlobalInvocationID.xy), vec4(clamp(lo, vec3(0.0), vec3(1.0)), 1.0));
            }
            else
            {
                vec2 hp = (vec2(_100) + vec2(0.5)) * vec2(_539.x ? p.control.xy.x : _541.x, _539.y ? p.control.xy.y : _541.y);
                vec2 _233 = floor(hp - vec2(1.5)) + vec2(0.5);
                lo = vec3(1000000015047466219876688855040.0);
                vec3 hi = vec3(-1000000015047466219876688855040.0);
                int y = 0;
                vec3 sum = vec3(0.0);
                float sumWeight = 0.0;
                vec3 box = vec3(0.0);
                float boxWeight = 0.0;
                vec3 col;
                float _462;
                float _490;
                for (;;)
                {
                    if (!(y < 4))
                    {
                        break;
                    }
                    col = lo;
                    vec3 hi_1 = hi;
                    int x = 0;
                    for (;;)
                    {
                        if (!(x < 4))
                        {
                            break;
                        }
                        int _258 = x;
                        vec2 pos = _233 + vec2(float(_258), float(y));
                        vec3 _276 = textureLod(_536, clamp(pos * p.historySize.zw, vec2(0.0), vec2(1.0)), 0.0).xyz;
                        bvec3 _543 = isnan(_276);
                        bvec3 _544 = isnan(vec3(0.0));
                        vec3 _545 = max(_276, vec3(0.0));
                        vec3 _546 = vec3(_543.x ? vec3(0.0).x : _545.x, _543.y ? vec3(0.0).y : _545.y, _543.z ? vec3(0.0).z : _545.z);
                        vec3 _277 = vec3(_544.x ? _276.x : _546.x, _544.y ? _276.y : _546.y, _544.z ? _276.z : _546.z);
                        vec3 _451 = _277 * (isnan(9.9999997473787516355514526367188e-05) ? p.control2.x : (isnan(p.control2.x) ? 9.9999997473787516355514526367188e-05 : max(p.control2.x, 9.9999997473787516355514526367188e-05)));
                        float _459 = 1.0 / (((_451.x + (2.0 * _451.y)) + _451.z) + 4.0);
                        float _460 = isnan(_459) ? 9.9999997473787516355514526367188e-05 : (isnan(9.9999997473787516355514526367188e-05) ? _459 : max(9.9999997473787516355514526367188e-05, _459));
                        {
                            float _466 = abs(abs(pos.x - hp.x));
                            float _467 = _466 * _466;
                            float _468 = _467 * _466;
                            if (_466 < 1.0)
                            {
                                _462 = (((7.0 * _468) + ((-12.0) * _467)) + 5.333333492279052734375) * 0.16666667163372039794921875;
                            }
                            else
                            {
                                if (_466 < 2.0)
                                {
                                    _462 = (((((-2.3333332538604736328125) * _468) + (12.0 * _467)) + ((-20.0) * _466)) + 10.66666698455810546875) * 0.16666667163372039794921875;
                                }
                                else
                                {
                                    _462 = 0.0;
                                }
                            }
                        }
                        {
                            float _494 = abs(abs(pos.y - hp.y));
                            float _495 = _494 * _494;
                            float _496 = _495 * _494;
                            if (_494 < 1.0)
                            {
                                _490 = (((7.0 * _496) + ((-12.0) * _495)) + 5.333333492279052734375) * 0.16666667163372039794921875;
                            }
                            else
                            {
                                if (_494 < 2.0)
                                {
                                    _490 = (((((-2.3333332538604736328125) * _496) + (12.0 * _495)) + ((-20.0) * _494)) + 10.66666698455810546875) * 0.16666667163372039794921875;
                                }
                                else
                                {
                                    _490 = 0.0;
                                }
                            }
                        }
                        float wt = (_462 * _490) * _460;
                        bvec3 _558 = isnan(col);
                        bvec3 _559 = isnan(_277);
                        vec3 _560 = min(col, _277);
                        vec3 _561 = vec3(_558.x ? _277.x : _560.x, _558.y ? _277.y : _560.y, _558.z ? _277.z : _560.z);
                        bvec3 _563 = isnan(hi_1);
                        bvec3 _564 = isnan(_277);
                        vec3 _565 = max(hi_1, _277);
                        vec3 _566 = vec3(_563.x ? _277.x : _565.x, _563.y ? _277.y : _565.y, _563.z ? _277.z : _565.z);
                        col = vec3(_559.x ? col.x : _561.x, _559.y ? col.y : _561.y, _559.z ? col.z : _561.z);
                        hi_1 = vec3(_564.x ? hi_1.x : _566.x, _564.y ? hi_1.y : _566.y, _564.z ? hi_1.z : _566.z);
                        x++;
                        sum += (_277 * wt);
                        sumWeight += wt;
                        box += (_277 * _460);
                        boxWeight += _460;
                        continue;
                    }
                    lo = col;
                    hi = hi_1;
                    y++;
                    continue;
                }
                if (sumWeight != 0.0)
                {
                    col = sum / vec3(sumWeight);
                }
                else
                {
                    col = vec3(0.0);
                }
                if (p.control.w > 0.0)
                {
                    _33 = boxWeight > 0.0;
                }
                else
                {
                    _33 = false;
                }
                if (_33)
                {
                    col += ((col - (box / vec3(boxWeight))) * p.control.w);
                }
                vec3 _428 = clamp(col, lo, hi);
                bvec3 _568 = isnan(_428);
                bvec3 _569 = isnan(vec3(0.0));
                vec3 _570 = max(_428, vec3(0.0));
                vec3 _571 = vec3(_568.x ? vec3(0.0).x : _570.x, _568.y ? vec3(0.0).y : _570.y, _568.z ? vec3(0.0).z : _570.z);
                imageStore(uOutput, ivec2(gl_GlobalInvocationID.xy), vec4(vec3(_569.x ? _428.x : _571.x, _569.y ? _428.y : _571.y, _569.z ? _428.z : _571.z), 1.0));
            }
        }
    }
}

