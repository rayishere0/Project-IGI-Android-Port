#version 430
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(binding = 0, std140) uniform Params_std140
{
    layout(row_major) mat4 viewToWorld;
    layout(row_major) mat4 prevWorldToView;
    vec4 unproject;
    vec4 resolution;
    vec4 cameraDelta;
    vec4 prevProjection;
    vec4 control;
    vec4 jitter;
} p;

layout(binding = 0, r8) uniform restrict image2D uShadow;
layout(binding = 1, rgba16f) uniform restrict writeonly image2D uHistory;
layout(binding = 0) uniform sampler2D _850;
layout(binding = 2) uniform sampler2D _853;
layout(binding = 1) uniform sampler2D _855;

shared float gCurrent[8][8];

mat4 spvWorkaroundRowMajor(mat4 wrap) { return wrap; }

void main()
{
    {
        ivec2 _119 = ivec2(gl_GlobalInvocationID.xy);
        ivec2 _125 = ivec2(p.resolution.xy);
        bool inside;
        if (_119.x < _125.x)
        {
            inside = _119.y < _125.y;
        }
        else
        {
            inside = false;
        }
        float current;
        if (inside)
        {
            current = imageLoad(uShadow, ivec2(gl_GlobalInvocationID.xy)).x;
        }
        else
        {
            current = 1.0;
        }
        gCurrent[gl_LocalInvocationID.y][gl_LocalInvocationID.x] = current;
        barrier();
        if (!(!inside))
        {
            float currentMin = current;
            float currentMax = current;
            int ny = -1;
            float accumulated;
            float count;
            float currentMin_1;
            float currentMax_1;
            for (;;)
            {
                if (!(ny <= 1))
                {
                    break;
                }
                accumulated = currentMin;
                count = currentMax;
                int nx = -1;
                for (;;)
                {
                    if (!(nx <= 1))
                    {
                        break;
                    }
                    ivec2 n = ivec2(gl_LocalInvocationID.xy) + ivec2(nx, ny);
                    if (all(greaterThanEqual(n, ivec2(0))))
                    {
                        inside = all(lessThan(n, ivec2(8)));
                    }
                    else
                    {
                        inside = false;
                    }
                    if (inside)
                    {
                        int _212 = n.y;
                        int _214 = n.x;
                        currentMin_1 = isnan(gCurrent[_212][_214]) ? accumulated : (isnan(accumulated) ? gCurrent[_212][_214] : min(accumulated, gCurrent[_212][_214]));
                        currentMax_1 = isnan(gCurrent[_212][_214]) ? count : (isnan(count) ? gCurrent[_212][_214] : max(count, gCurrent[_212][_214]));
                    }
                    else
                    {
                        currentMin_1 = accumulated;
                        currentMax_1 = count;
                    }
                    accumulated = currentMin_1;
                    count = currentMax_1;
                    nx++;
                    continue;
                }
                currentMin = accumulated;
                currentMax = count;
                ny++;
                continue;
            }
            ivec2 _254 = ivec3(_119, 0).xy;
            vec4 _sampled = texelFetch(_850, _254, 0);
            float depth = _sampled.x;
            vec2 uv = ((vec2(_119) + vec2(0.5)) - p.jitter.xy) * p.resolution.zw;
            if (depth <= 0.0)
            {
                imageStore(uHistory, ivec2(gl_GlobalInvocationID.xy), vec4(current, 0.0, 0.0, 0.0));
            }
            else
            {
                float _681 = ((2.0 * p.unproject.z) * p.unproject.w) / ((p.unproject.w + p.unproject.z) - ((1.0 - (2.0 * depth)) * (p.unproject.w - p.unproject.z)));
                vec2 _684 = (uv * 2.0) - vec2(1.0);
                vec3 _696 = vec3((_684.x * _681) / p.unproject.x, ((-_684.y) * _681) / p.unproject.y, _681);
                vec4 _333 = vec4((vec4(_696, 0.0) * spvWorkaroundRowMajor(p.viewToWorld)).xyz + p.cameraDelta.xyz, 0.0) * spvWorkaroundRowMajor(p.prevWorldToView);
                if (p.control.y > 0.5)
                {
                    inside = _333.z > p.prevProjection.z;
                }
                else
                {
                    inside = false;
                }
                if (inside)
                {
                    float _358 = _333.z;
                    vec2 prevUnjittered_1 = (vec2((_333.x * p.prevProjection.x) / _358, ((-_333.y) * p.prevProjection.y) / _358) * 0.5) + vec2(0.5);
                    bool ownMotion;
                    vec2 prevUnjittered;
                    if (p.control.w > 0.5)
                    {
                        vec2 motion = texelFetch(_853, _254, 0).xy;
                        vec2 apart = (motion - (uv - prevUnjittered_1)) * p.resolution.xy;
                        bool _384 = dot(apart, apart) > 2.25;
                        if (_384)
                        {
                            prevUnjittered = uv - motion;
                        }
                        else
                        {
                            prevUnjittered = prevUnjittered_1;
                        }
                        ownMotion = _384;
                    }
                    else
                    {
                        prevUnjittered = prevUnjittered_1;
                        ownMotion = false;
                    }
                    vec2 prevUv = prevUnjittered + (p.jitter.zw * p.resolution.zw);
                    if (all(greaterThanEqual(prevUv, vec2(0.0))))
                    {
                        inside = all(lessThanEqual(prevUv, vec2(1.0)));
                    }
                    else
                    {
                        inside = false;
                    }
                    if (inside)
                    {
                        vec4 _sampled_1 = textureLod(_855, prevUv, 0.0);
                        vec2 _704 = prevUv * p.resolution.xy;
                        vec2 _707 = floor(_704 - vec2(0.5));
                        vec2 _709 = _707 + vec2(0.5);
                        vec2 _710 = _704 - _709;
                        vec2 _711 = _710 * 0.5;
                        vec2 _717 = _710 * (vec2(-0.5) + (_710 * (vec2(1.0) - _711)));
                        vec2 _718 = _710 * _710;
                        vec2 _719 = _710 * 1.5;
                        vec2 _730 = _710 * (vec2(0.5) + (_710 * (vec2(2.0) - _719)));
                        vec2 _733 = _718 * (vec2(-0.5) + _711);
                        vec2 _734 = (vec2(1.0) + (_718 * (vec2(-2.5) + _719))) + _730;
                        bvec2 _867 = isnan(_734);
                        bvec2 _868 = isnan(vec2(9.9999997473787516355514526367188e-06));
                        vec2 _869 = max(_734, vec2(9.9999997473787516355514526367188e-06));
                        vec2 _870 = vec2(_867.x ? vec2(9.9999997473787516355514526367188e-06).x : _869.x, _867.y ? vec2(9.9999997473787516355514526367188e-06).y : _869.y);
                        vec2 _739 = (_707 + vec2(-0.5)) * p.resolution.zw;
                        vec2 _742 = (_707 + vec2(2.5)) * p.resolution.zw;
                        vec2 _744 = (_709 + (_730 / vec2(_868.x ? _734.x : _870.x, _868.y ? _734.y : _870.y))) * p.resolution.zw;
                        float _745 = _739.x;
                        float _746 = _739.y;
                        float _753 = _717.x;
                        float _755 = _717.y;
                        float _757 = _744.x;
                        float _764 = _734.x;
                        float _768 = _742.x;
                        float _775 = _733.x;
                        float _779 = _744.y;
                        float _787 = _734.y;
                        float _808 = _742.y;
                        float _816 = _733.y;
                        _sampled_1.x = clamp(((((((((((textureLod(_855, _739, 0.0) * _753) * _755) + ((textureLod(_855, vec2(_757, _746), 0.0) * _764) * _755)) + ((textureLod(_855, vec2(_768, _746), 0.0) * _775) * _755)) + ((textureLod(_855, vec2(_745, _779), 0.0) * _753) * _787)) + ((textureLod(_855, _744, 0.0) * _764) * _787)) + ((textureLod(_855, vec2(_768, _779), 0.0) * _775) * _787)) + ((textureLod(_855, vec2(_745, _808), 0.0) * _753) * _816)) + ((textureLod(_855, vec2(_757, _808), 0.0) * _764) * _816)) + ((textureLod(_855, _742, 0.0) * _775) * _816)).x, currentMin, currentMax);
                        vec4 history = _sampled_1;
                        vec4 _582 = textureGather(_855, prevUv, 1);
                        float _585 = abs(_582.x - _358);
                        float _588 = abs(_582.y - _358);
                        float _589 = isnan(_588) ? _585 : (isnan(_585) ? _588 : min(_585, _588));
                        float _592 = abs(_582.z - _358);
                        float _595 = abs(_582.w - _358);
                        float _596 = isnan(_595) ? _592 : (isnan(_592) ? _595 : min(_592, _595));
                        bool sameSurface;
                        if (ownMotion)
                        {
                            sameSurface = true;
                        }
                        else
                        {
                            sameSurface = (isnan(_596) ? _589 : (isnan(_589) ? _596 : min(_589, _596))) <= (_358 * p.control.z);
                        }
                        if (sameSurface)
                        {
                            inside = history.z > 0.0;
                        }
                        else
                        {
                            inside = false;
                        }
                        if (inside)
                        {
                            float _622 = history.z + 1.0;
                            float _625 = isnan(1.0) ? p.control.x : (isnan(p.control.x) ? 1.0 : max(p.control.x, 1.0));
                            float _626 = isnan(_625) ? _622 : (isnan(_622) ? _625 : min(_622, _625));
                            accumulated = mix(history.x, current, 1.0 / _626);
                            count = _626;
                        }
                        else
                        {
                            accumulated = current;
                            count = 1.0;
                        }
                    }
                    else
                    {
                        accumulated = current;
                        count = 1.0;
                    }
                }
                else
                {
                    accumulated = current;
                    count = 1.0;
                }
                imageStore(uShadow, ivec2(gl_GlobalInvocationID.xy), vec4(accumulated));
                imageStore(uHistory, ivec2(gl_GlobalInvocationID.xy), vec4(accumulated, _696.z, count, 0.0));
            }
        }
    }
}

