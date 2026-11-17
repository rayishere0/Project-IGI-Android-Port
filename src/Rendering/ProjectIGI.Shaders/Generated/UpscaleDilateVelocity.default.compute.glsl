#version 430
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

uniform ivec2 _218_comp[2] = ivec2[](ivec2(1, 0), ivec2(0, 1));

layout(binding = 0, std140) uniform Params_std140
{
    layout(row_major) mat4 viewToWorld;
    layout(row_major) mat4 prevWorldToView;
    vec4 unproject;
    vec4 resolution;
    vec4 cameraDelta;
    vec4 prevProjection;
    vec4 jitter;
} p;

layout(binding = 0, std430) restrict buffer RWStructuredBuffer
{
    uint _member0[];
} uOccluder;

layout(binding = 0, rg16f) uniform restrict writeonly image2D uDilatedVelocity;
layout(binding = 1, r32f) uniform restrict writeonly image2D uClosestDepth;
layout(binding = 0) uniform sampler2D _583;
layout(binding = 1) uniform sampler2D _586;

mat4 spvWorkaroundRowMajor(mat4 wrap) { return wrap; }

void main()
{
    {
        ivec2 _103 = ivec2(gl_GlobalInvocationID.xy);
        ivec2 _110 = ivec2(p.resolution.xy);
        int _112 = _110.x;
        bool _31;
        if (_103.x >= _112)
        {
            _31 = true;
        }
        else
        {
            _31 = _103.y >= _110.y;
        }
        if (!(_31))
        {
            vec4 _453 = texelFetch(_583, ivec3(clamp(_103, ivec2(0), _110 - ivec2(1)), 0).xy, 0);
            float _455 = _453.x;
            float _471 = ((2.0 * p.unproject.z) * p.unproject.w) / ((p.unproject.w + p.unproject.z) - ((1.0 - (2.0 * _455)) * (p.unproject.w - p.unproject.z)));
            float _481 = (0.5 * p.resolution.y) * p.unproject.y;
            float _187 = _471 + (2.0 * (_471 / (isnan(9.9999999747524270787835121154785e-07) ? _481 : (isnan(_481) ? 9.9999999747524270787835121154785e-07 : max(_481, 9.9999999747524270787835121154785e-07)))));
            float _209 = abs(((1.0 - (((p.unproject.w + p.unproject.z) - (((2.0 * p.unproject.z) * p.unproject.w) / (isnan(9.9999999747524270787835121154785e-07) ? _187 : (isnan(_187) ? 9.9999999747524270787835121154785e-07 : max(_187, 9.9999999747524270787835121154785e-07))))) / (p.unproject.w - p.unproject.z))) * 0.5) - _455);
            float bestDepth = _455;
            ivec2 bestOffset = ivec2(0);
            int i = 0;
            float prevViewZ;
            ivec2 bestOffset_1;
            float bestDepth_1;
            ivec2 bestOffset_2;
            for (;;)
            {
                if (!(i < 2))
                {
                    break;
                }
                vec4 _509 = texelFetch(_583, ivec3(clamp(_103 + _218_comp[i], ivec2(0), _110 - ivec2(1)), 0).xy, 0);
                float _511 = _509.x;
                vec4 _520 = texelFetch(_583, ivec3(clamp(_103 - _218_comp[i], ivec2(0), _110 - ivec2(1)), 0).xy, 0);
                float _522 = _520.x;
                float _233 = 0.25 * abs(_522 - _511);
                if ((((_511 + _522) * 0.5) - _455) > (isnan(_209) ? _233 : (isnan(_233) ? _209 : max(_233, _209))))
                {
                    if (_511 > bestDepth)
                    {
                        prevViewZ = _511;
                        bestOffset_1 = _218_comp[i];
                    }
                    else
                    {
                        prevViewZ = bestDepth;
                        bestOffset_1 = bestOffset;
                    }
                    if (_522 > prevViewZ)
                    {
                        bestDepth_1 = _522;
                        bestOffset_2 = -_218_comp[i];
                    }
                    else
                    {
                        bestDepth_1 = prevViewZ;
                        bestOffset_2 = bestOffset_1;
                    }
                    bestDepth = bestDepth_1;
                    bestOffset = bestOffset_2;
                }
                i++;
                continue;
            }
            vec2 dilated = texelFetch(_586, ivec3(clamp(_103 + bestOffset, ivec2(0), _110 - ivec2(1)), 0).xy, 0).xy;
            imageStore(uDilatedVelocity, ivec2(gl_GlobalInvocationID.xy), vec4(dilated, 0.0, 0.0));
            imageStore(uClosestDepth, ivec2(gl_GlobalInvocationID.xy), vec4(bestDepth, 0.0, 0.0, 0.0));
            vec2 currentUv = ((vec2(_103) + vec2(0.5)) * p.resolution.zw) - (p.jitter.xy * p.resolution.zw);
            if (_455 > 0.0)
            {
                float _558 = ((2.0 * p.unproject.z) * p.unproject.w) / ((p.unproject.w + p.unproject.z) - ((1.0 - (2.0 * _455)) * (p.unproject.w - p.unproject.z)));
                vec2 _529 = (currentUv * 2.0) - vec2(1.0);
                prevViewZ = (vec4((vec4(vec3((_529.x * _558) / p.unproject.x, ((-_529.y) * _558) / p.unproject.y, _558), 0.0) * spvWorkaroundRowMajor(p.viewToWorld)).xyz + p.cameraDelta.xyz, 0.0) * spvWorkaroundRowMajor(p.prevWorldToView)).z;
            }
            else
            {
                prevViewZ = p.prevProjection.w;
            }
            if (prevViewZ > p.prevProjection.z)
            {
                ivec2 _382 = ivec2(floor((((currentUv - dilated) + (p.jitter.zw * p.resolution.zw)) * p.resolution.xy) - vec2(0.5)));
                uint _385 = ~floatBitsToUint(prevViewZ);
                int t = 0;
                bool _49;
                bool _50;
                for (;;)
                {
                    if (!(t < 4))
                    {
                        break;
                    }
                    ivec2 at = _382 + ivec2(t & 1, t >> 1);
                    int _396 = at.x;
                    if (_396 >= 0)
                    {
                        _31 = at.y >= 0;
                    }
                    else
                    {
                        _31 = false;
                    }
                    if (_31)
                    {
                        _49 = _396 < _112;
                    }
                    else
                    {
                        _49 = false;
                    }
                    if (_49)
                    {
                        _50 = at.y < _110.y;
                    }
                    else
                    {
                        _50 = false;
                    }
                    if (_50)
                    {
                        uint _431 = atomicMax(uOccluder._member0[(at.y * _112) + _396], _385);
                    }
                    t++;
                    continue;
                }
            }
        }
    }
}

