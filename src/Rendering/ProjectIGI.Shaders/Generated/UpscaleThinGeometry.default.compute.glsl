#version 430
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

uniform int _486_comp[8] = int[](0, 1, 2, 5, 8, 7, 6, 3);

layout(binding = 0, std140) uniform Params_std140
{
    vec4 size;
    vec4 unproject;
    vec4 control;
} p;

layout(binding = 0, rg8) uniform restrict writeonly image2D uRelaxed;
layout(binding = 0) uniform sampler2D _928;
layout(binding = 1) uniform sampler2D _931;
layout(binding = 2) uniform sampler2D _933;

shared float sLine[100];

void main()
{
    {
        ivec2 _87 = ivec2(gl_GlobalInvocationID.xy);
        ivec2 _94 = ivec2(p.size.xy);
        ivec2 _101 = (ivec2(gl_WorkGroupID.xy) * ivec2(8)) - ivec2(1);
        uint i = gl_LocalInvocationIndex;
        float _653;
        float _654[9];
        int _656;
        float _663;
        float _664;
        float _665;
        float _666;
        float _667;
        float _668;
        float _669;
        float _670;
        float _884;
        for (;;)
        {
            if (!(i < 100u))
            {
                break;
            }
            int _111 = int(i);
            ivec2 _123 = _101 + ivec2(_111 - 10 * (_111 / 10), _111 / 10);
            {
                if (texelFetch(_928, ivec3(clamp(_123, ivec2(0), _94 - ivec2(1)), 0).xy, 0).x <= 0.0)
                {
                    _653 = 0.0;
                }
                else
                {
                    int _655 = -1;
                    for (;;)
                    {
                        if (!(_655 <= 1))
                        {
                            break;
                        }
                        _656 = -1;
                        for (;;)
                        {
                            if (!(_656 <= 1))
                            {
                                break;
                            }
                            int _710 = _656 + 1;
                            vec4 _893 = texelFetch(_928, ivec3(clamp(_123 + ivec2(_656, _655), ivec2(0), _94 - ivec2(1)), 0).xy, 0);
                            float _895 = _893.x;
                            if (_895 <= 0.0)
                            {
                                _884 = p.unproject.w;
                            }
                            else
                            {
                                _884 = ((2.0 * p.unproject.z) * p.unproject.w) / ((p.unproject.w + p.unproject.z) - ((1.0 - (2.0 * _895)) * (p.unproject.w - p.unproject.z)));
                            }
                            _654[((_655 + 1) * 3) + _710] = _884;
                            _656 = _710;
                            continue;
                        }
                        _655++;
                        continue;
                    }
                    float _733 = _654[4] * p.control.x;
                    float _657 = 0.0;
                    float _658 = 0.0;
                    float _659 = 0.0;
                    float _660 = 0.0;
                    float _661 = 0.0;
                    float _662 = 0.0;
                    _656 = 0;
                    for (;;)
                    {
                        if (!(_656 < 3))
                        {
                            break;
                        }
                        int _746 = 3 + _656;
                        if ((_654[_656] - _654[_746]) > _733)
                        {
                            _663 = 1.0;
                        }
                        else
                        {
                            _663 = 0.0;
                        }
                        if ((_654[6 + _656] - _654[_746]) > _733)
                        {
                            _664 = 1.0;
                        }
                        else
                        {
                            _664 = 0.0;
                        }
                        float _766 = _663 + _664;
                        int _768 = _656 * 3;
                        int _771 = _768 + 1;
                        if ((_654[_768] - _654[_771]) > _733)
                        {
                            _665 = 1.0;
                        }
                        else
                        {
                            _665 = 0.0;
                        }
                        if ((_654[_768 + 2] - _654[_771]) > _733)
                        {
                            _666 = 1.0;
                        }
                        else
                        {
                            _666 = 0.0;
                        }
                        float _790 = _665 + _666;
                        if (_656 == 0)
                        {
                            _658 = _766;
                            _661 = _790;
                        }
                        else
                        {
                            if (_656 == 1)
                            {
                                _667 = _766;
                                _668 = _659;
                                _669 = _790;
                                _670 = _662;
                            }
                            else
                            {
                                _667 = _657;
                                _668 = _766;
                                _669 = _660;
                                _670 = _790;
                            }
                            _657 = _667;
                            _659 = _668;
                            _660 = _669;
                            _662 = _670;
                        }
                        _656++;
                        continue;
                    }
                    if (_657 < 2.0)
                    {
                        _663 = 0.0;
                    }
                    else
                    {
                        _663 = clamp(((_658 + _659) - 2.0) * 0.5, 0.0, 1.0);
                    }
                    if (_660 < 2.0)
                    {
                        _664 = 0.0;
                    }
                    else
                    {
                        _664 = clamp(((_661 + _662) - 2.0) * 0.5, 0.0, 1.0);
                    }
                    float _840 = clamp(_663 + _664, 0.0, 1.0);
                    bool _673 = abs(_654[4] - _654[3]) > _733;
                    int _671 = 0;
                    int _672 = 0;
                    for (;;)
                    {
                        if (!(_671 < 8))
                        {
                            break;
                        }
                        bool _863 = abs(_654[4] - _654[_486_comp[_671]]) > _733;
                        if (_863 != _673)
                        {
                            _672++;
                        }
                        _673 = _863;
                        _671++;
                        continue;
                    }
                    float _880 = clamp((float(_672) - 2.0) * 0.5, 0.0, 1.0);
                    _653 = isnan(_880) ? _840 : (isnan(_840) ? _880 : max(_840, _880));
                }
            }
            sLine[i] = _653;
            i += 64u;
            continue;
        }
        barrier();
        bool _33;
        if (_87.x >= _94.x)
        {
            _33 = true;
        }
        else
        {
            _33 = _87.y >= _94.y;
        }
        if (!(_33))
        {
            float believable;
            if (p.control.z > 0.5)
            {
                believable = texelFetch(_931, ivec3(_87, 0).xy, 0).x;
            }
            else
            {
                believable = 1.0;
            }
            ivec2 _564 = ivec2(gl_LocalInvocationID.xy) + ivec2(1);
            float line = 0.0;
            int y = -1;
            for (;;)
            {
                if (!(y <= 1))
                {
                    break;
                }
                int x = -1;
                for (;;)
                {
                    if (!(x <= 1))
                    {
                        break;
                    }
                    int _581 = (((_564.y + y) * 10) + _564.x) + x;
                    line = isnan(sLine[_581]) ? line : (isnan(line) ? sLine[_581] : max(line, sLine[_581]));
                    x++;
                    continue;
                }
                y++;
                continue;
            }
            float speedPx;
            if (p.control.w > 0.5)
            {
                speedPx = length(textureLod(_933, (vec2(_87) + vec2(0.5)) * p.size.zw, 0.0).xy * p.size.xy);
            }
            else
            {
                speedPx = 0.0;
            }
            imageStore(uRelaxed, ivec2(gl_GlobalInvocationID.xy), vec4(mix(believable, 1.0, (line * p.control.y) * clamp(1.0 - speedPx, 0.0, 1.0)), line, 0.0, 0.0));
        }
    }
}

