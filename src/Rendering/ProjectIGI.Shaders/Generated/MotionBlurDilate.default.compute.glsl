#version 430
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(binding = 0, std140) uniform Params_std140
{
    vec4 size;
    vec4 control;
} p;

layout(binding = 0, rgba16f) uniform restrict writeonly image2D uDilated;
layout(binding = 0) uniform sampler2D _405;

void main()
{
    {
        ivec2 _96 = ivec2(gl_GlobalInvocationID.xy);
        ivec2 _102 = ivec2(p.size.xy);
        int _104 = _102.x;
        bool _22;
        if (_96.x >= _104)
        {
            _22 = true;
        }
        else
        {
            _22 = _96.y >= _102.y;
        }
        if (!(_22))
        {
            vec4 _sampled = texelFetch(_405, ivec3(_96, 0).xy, 0);
            float _335 = length(_sampled.zw);
            float _332;
            if (_335 > 0.0)
            {
                _332 = atan(_sampled.w, _sampled.z);
            }
            else
            {
                _332 = 0.0;
            }
            float _348 = length(_sampled.xy);
            float _345;
            if (_348 > 0.0)
            {
                _345 = atan(_sampled.y, _sampled.x);
            }
            else
            {
                _345 = 0.0;
            }
            vec2 fastest = vec2(_335, _332);
            vec2 slowest = vec2(_348, _345);
            int y = -3;
            bool _33;
            bool _34;
            bool _35;
            bool _36;
            vec2 fastest_2;
            vec2 slowest_2;
            float _358;
            float _371;
            for (;;)
            {
                if (!(y <= 3))
                {
                    break;
                }
                vec2 fastest_1 = fastest;
                vec2 slowest_1 = slowest;
                int x = -3;
                for (;;)
                {
                    bool _51_ladder_break = false;
                    {
                        if (!(x <= 3))
                        {
                            _51_ladder_break = true;
                        }
                        else
                        {
                            if (x == 0)
                            {
                                _22 = y == 0;
                            }
                            else
                            {
                                _22 = false;
                            }
                            if (!(_22))
                            {
                                ivec2 neighbour = _96 + ivec2(x, y);
                                int _185 = neighbour.x;
                                if (_185 < 0)
                                {
                                    _33 = true;
                                }
                                else
                                {
                                    _33 = neighbour.y < 0;
                                }
                                if (_33)
                                {
                                    _34 = true;
                                }
                                else
                                {
                                    _34 = _185 >= _104;
                                }
                                if (_34)
                                {
                                    _35 = true;
                                }
                                else
                                {
                                    _35 = neighbour.y >= _102.y;
                                }
                                if (!(_35))
                                {
                                    vec4 _sampled_1 = texelFetch(_405, ivec3(neighbour, 0).xy, 0);
                                    vec2 velocity = _sampled_1.zw * p.control.x;
                                    float _224 = dot(velocity, velocity);
                                    float _227 = inversesqrt(_224 + 9.9999999392252902907785028219223e-09);
                                    vec2 direction = velocity * _227;
                                    float _230 = direction.x;
                                    float _232 = direction.y;
                                    float margin = 0.9900000095367431640625 * (abs(_230) + abs(_232));
                                    vec2 offset = vec2(float(x), float(y));
                                    if (abs(dot(direction, offset)) < ((_224 * _227) + margin))
                                    {
                                        _36 = abs(dot(vec2(-_232, _230), offset)) < margin;
                                    }
                                    else
                                    {
                                        _36 = false;
                                    }
                                    if (_36)
                                    {
                                        float _361 = length(velocity);
                                        if (_361 > 0.0)
                                        {
                                            _358 = atan(velocity.y, velocity.x);
                                        }
                                        else
                                        {
                                            _358 = 0.0;
                                        }
                                        vec2 _370 = vec2(_361, _358);
                                        float _374 = length(_sampled_1.xy);
                                        if (_374 > 0.0)
                                        {
                                            _371 = atan(_sampled_1.y, _sampled_1.x);
                                        }
                                        else
                                        {
                                            _371 = 0.0;
                                        }
                                        vec2 _383 = vec2(_374, _371);
                                        if (fastest_1.x > _370.x)
                                        {
                                            fastest_2 = fastest_1;
                                        }
                                        else
                                        {
                                            fastest_2 = _370;
                                        }
                                        if (slowest_1.x > _383.x)
                                        {
                                            slowest_2 = _383;
                                        }
                                        else
                                        {
                                            slowest_2 = slowest_1;
                                        }
                                    }
                                    else
                                    {
                                        fastest_2 = fastest_1;
                                        slowest_2 = slowest_1;
                                    }
                                    fastest_1 = fastest_2;
                                    slowest_1 = slowest_2;
                                }
                            }
                        }
                    }
                    if (_51_ladder_break)
                    {
                        break;
                    }
                    x++;
                    continue;
                }
                fastest = fastest_1;
                slowest = slowest_1;
                y++;
                continue;
            }
            imageStore(uDilated, ivec2(gl_GlobalInvocationID.xy), vec4(vec2(cos(slowest.y), sin(slowest.y)) * slowest.x, vec2(cos(fastest.y), sin(fastest.y)) * fastest.x));
        }
    }
}

