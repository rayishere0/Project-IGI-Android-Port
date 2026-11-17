#version 430

#ifndef SPIRV_CROSS_CONSTANT_ID_64
#define SPIRV_CROSS_CONSTANT_ID_64 1
#endif
const int cClipYDown = SPIRV_CROSS_CONSTANT_ID_64;
const bool _72 = (cClipYDown != 0);

layout(binding = 0, std140) uniform SilhouetteParams_std140
{
    vec4 frame;
    vec4 vignettes;
    vec4 fill0;
    vec4 outline0;
    vec4 fill1;
    vec4 outline1;
    vec4 fill2;
    vec4 outline2;
} p;

layout(binding = 0) uniform sampler2D _824;

#ifdef GL_ARB_shader_draw_parameters
#define SPIRV_Cross_BaseVertex gl_BaseVertexARB
#else
uniform int SPIRV_Cross_BaseVertex;
#endif
layout(location = 0) out vec4 entryPointParam_fragmentMain;

void main()
{
    {
        vec2 _549 = ((gl_FragCoord.xy - (p.frame.xy * 0.5)) / vec2(p.frame.y)) * p.vignettes.xy;
        float _550 = _549.x;
        float _554 = _549.y;
        float _563 = (((16.0 * clamp(0.5 + _550, 0.0, 1.0)) * clamp(0.5 + _554, 0.0, 1.0)) * clamp(0.5 - _550, 0.0, 1.0)) * clamp(0.5 - _554, 0.0, 1.0);
        vec2 _575 = ((gl_FragCoord.xy - (p.frame.xy * 0.5)) / vec2(p.frame.y)) * p.vignettes.zw;
        float _576 = _575.x;
        float _580 = _575.y;
        float _589 = (((16.0 * clamp(0.5 + _576, 0.0, 1.0)) * clamp(0.5 + _580, 0.0, 1.0)) * clamp(0.5 - _576, 0.0, 1.0)) * clamp(0.5 - _580, 0.0, 1.0);
        if ((isnan(_589) ? _563 : (isnan(_563) ? _589 : max(_563, _589))) <= 0.0)
        {
            entryPointParam_fragmentMain = vec4(0.0);
        }
        else
        {
            ivec2 _198 = ivec2(gl_FragCoord.xy);
            vec4 _591;
            {
                bool _592;
                if (any(lessThan(_198, ivec2(0))))
                {
                    _592 = true;
                }
                else
                {
                    _592 = any(greaterThanEqual(_198, ivec2(p.frame.xy)));
                }
                if (_592)
                {
                    _591 = vec4(0.0);
                }
                else
                {
                    _591 = texelFetch(_824, ivec3(_198, 0).xy, 0);
                }
            }
            bvec3 inside = greaterThan(_591.xyz, vec3(0.5));
            vec3 n = vec3(0.0);
            vec3 least = vec3(100.0);
            int dy = 2;
            vec2 s0 = vec2(0.0);
            vec2 s1 = vec2(0.0);
            vec2 s2 = vec2(0.0);
            bool _107;
            vec2 s0_2;
            vec2 s1_2;
            vec2 s2_2;
            vec4 _618;
            bool _619;
            for (;;)
            {
                if (!(dy >= (-2)))
                {
                    break;
                }
                int dx = 2;
                vec2 s0_1 = s0;
                vec2 s1_1 = s1;
                vec2 s2_1 = s2;
                for (;;)
                {
                    bool _121_ladder_break = false;
                    {
                        if (!(dx >= (-2)))
                        {
                            _121_ladder_break = true;
                        }
                        else
                        {
                            if (dx == 0)
                            {
                                _107 = dy == 0;
                            }
                            else
                            {
                                _107 = false;
                            }
                            if (!(_107))
                            {
                                ivec2 _282 = _198 + ivec2(dx, dy);
                                {
                                    if (any(lessThan(_282, ivec2(0))))
                                    {
                                        _619 = true;
                                    }
                                    else
                                    {
                                        _619 = any(greaterThanEqual(_282, ivec2(p.frame.xy)));
                                    }
                                    if (_619)
                                    {
                                        _618 = vec4(0.0);
                                    }
                                    else
                                    {
                                        _618 = texelFetch(_824, ivec3(_282, 0).xy, 0);
                                    }
                                }
                                bvec3 there = greaterThan(_618.xyz, vec3(0.5));
                                vec2 offset = vec2(float(dx), float(dy));
                                float _292 = dot(offset, offset);
                                if (there.x != inside.x)
                                {
                                    vec3 _804 = n;
                                    _804.x = _804.x + 1.0;
                                    n = _804;
                                    vec3 _304 = least;
                                    _304.x = isnan(_292) ? _304.x : (isnan(_304.x) ? _292 : min(_304.x, _292));
                                    least = _304;
                                    s0_2 = s0_1 + offset;
                                }
                                else
                                {
                                    s0_2 = s0_1;
                                }
                                if (there.y != inside.y)
                                {
                                    vec3 _809 = n;
                                    _809.y = _809.y + 1.0;
                                    n = _809;
                                    vec3 _324 = least;
                                    _324.y = isnan(_292) ? _324.y : (isnan(_324.y) ? _292 : min(_324.y, _292));
                                    least = _324;
                                    s1_2 = s1_1 + offset;
                                }
                                else
                                {
                                    s1_2 = s1_1;
                                }
                                if (there.z != inside.z)
                                {
                                    vec3 _814 = n;
                                    _814.z = _814.z + 1.0;
                                    n = _814;
                                    vec3 _344 = least;
                                    _344.z = isnan(_292) ? _344.z : (isnan(_344.z) ? _292 : min(_344.z, _292));
                                    least = _344;
                                    s2_2 = s2_1 + offset;
                                }
                                else
                                {
                                    s2_2 = s2_1;
                                }
                                s0_1 = s0_2;
                                s1_1 = s1_2;
                                s2_1 = s2_2;
                            }
                        }
                    }
                    if (_121_ladder_break)
                    {
                        break;
                    }
                    dx--;
                    continue;
                }
                dy--;
                s0 = s0_1;
                s1 = s1_1;
                s2 = s2_1;
                continue;
            }
            vec4 result = vec4(0.0);
            float _644;
            if (n.z > 0.0)
            {
                _644 = length(s2) / n.z;
            }
            else
            {
                _644 = 100.0;
            }
            float _653 = sqrt(least.z);
            float _657 = (0.89999997615814208984375 * (isnan(_653) ? _644 : (isnan(_644) ? _653 : max(_644, _653)))) - 1.0;
            float _659 = p.frame.z * (isnan(0.0) ? _657 : (isnan(_657) ? 0.0 : max(_657, 0.0)));
            float _664 = p.outline2.w * exp(((-4.0) * _659) * _659);
            float _645;
            if (inside.z)
            {
                _645 = p.fill2.w;
            }
            else
            {
                _645 = 0.0;
            }
            vec3 _671 = p.fill2.xyz * _645;
            float _682 = (1.0 - ((1.0 - _645) * (1.0 - _664))) * _589;
            float _685 = 1.0 - _682;
            result = vec4(((_671 + ((p.outline2.xyz - _671) * _664)) * _589) + (result.xyz * _685), _682 + (result.w * _685));
            float _693;
            if (n.y > 0.0)
            {
                _693 = length(s1) / n.y;
            }
            else
            {
                _693 = 100.0;
            }
            float _702 = sqrt(least.y);
            float _706 = (0.89999997615814208984375 * (isnan(_702) ? _693 : (isnan(_693) ? _702 : max(_693, _702)))) - 1.0;
            float _708 = p.frame.z * (isnan(0.0) ? _706 : (isnan(_706) ? 0.0 : max(_706, 0.0)));
            float _713 = p.outline1.w * exp(((-4.0) * _708) * _708);
            float _694;
            if (inside.y)
            {
                _694 = p.fill1.w;
            }
            else
            {
                _694 = 0.0;
            }
            vec3 _720 = p.fill1.xyz * _694;
            float _731 = (1.0 - ((1.0 - _694) * (1.0 - _713))) * _589;
            float _734 = 1.0 - _731;
            result = vec4(((_720 + ((p.outline1.xyz - _720) * _713)) * _589) + (result.xyz * _734), _731 + (result.w * _734));
            float _742;
            if (n.x > 0.0)
            {
                _742 = length(s0) / n.x;
            }
            else
            {
                _742 = 100.0;
            }
            float _751 = sqrt(least.x);
            float _755 = (0.89999997615814208984375 * (isnan(_751) ? _742 : (isnan(_742) ? _751 : max(_742, _751)))) - 1.0;
            float _757 = p.frame.z * (isnan(0.0) ? _755 : (isnan(_755) ? 0.0 : max(_755, 0.0)));
            float _762 = p.outline0.w * exp(((-4.0) * _757) * _757);
            float _743;
            if (inside.x)
            {
                _743 = p.fill0.w;
            }
            else
            {
                _743 = 0.0;
            }
            vec3 _769 = p.fill0.xyz * _743;
            float _780 = (1.0 - ((1.0 - _743) * (1.0 - _762))) * _563;
            float _783 = 1.0 - _780;
            vec4 _790 = vec4(((_769 + ((p.outline0.xyz - _769) * _762)) * _563) + (result.xyz * _783), _780 + (result.w * _783));
            result = _790;
            entryPointParam_fragmentMain = _790;
        }
    }
}

