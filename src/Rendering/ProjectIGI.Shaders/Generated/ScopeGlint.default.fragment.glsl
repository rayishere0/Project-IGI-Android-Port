#version 430

#ifndef SPIRV_CROSS_CONSTANT_ID_64
#define SPIRV_CROSS_CONSTANT_ID_64 1
#endif
const int cClipYDown = SPIRV_CROSS_CONSTANT_ID_64;

struct _Array_std140_vector_float_4_7
{
    vec4 data[7];
};

const bool _72 = (cClipYDown != 0);

layout(binding = 0, std140) uniform ScopeGlintParams_std140
{
    vec4 frame;
    _Array_std140_vector_float_4_7 glints;
} p;

#ifdef GL_ARB_shader_draw_parameters
#define SPIRV_Cross_BaseVertex gl_BaseVertexARB
#else
uniform int SPIRV_Cross_BaseVertex;
#endif
layout(location = 0) out vec4 entryPointParam_fragmentMain;
layout(location = 0) in vec2 input_uv;

void main()
{
    vec2 _126 = input_uv * p.frame.xy;
    int _130 = min(int(p.frame.w), 7);
    int i = 0;
    vec3 light = vec3(0.0);
    bool _99;
    bool _100;
    for (;;)
    {
        bool _103_ladder_break = false;
        {
            if (!(i < _130))
            {
                _103_ladder_break = true;
            }
            else
            {
                if (p.glints.data[i].z <= 0.0)
                {
                    _99 = true;
                }
                else
                {
                    _99 = p.glints.data[i].w <= 0.0;
                }
                if (!(_99))
                {
                    vec2 d = (_126 - p.glints.data[i].xy) / vec2(p.glints.data[i].z);
                    if (abs(d.x) > 6.0)
                    {
                        _100 = true;
                    }
                    else
                    {
                        _100 = abs(d.y) > 4.0;
                    }
                    if (!(_100))
                    {
                        float _182 = float(i);
                        float _322 = dot(d, d);
                        float _326 = (p.frame.z * 3.099999904632568359375) + (_182 * 11.326000213623046875);
                        float _368 = floor(_326);
                        float _369 = fract(_326);
                        float _331 = (p.frame.z * 11.0) + (_182 * 1.618000030517578125);
                        float _386 = floor(_331);
                        float _387 = fract(_331);
                        vec3 light_1 = light + ((((vec3(1.0, 0.949999988079071044921875, 0.86000001430511474609375) * (exp(_322 * (-70.0)) * 3.0)) + (vec3(1.0, 0.949999988079071044921875, 0.86000001430511474609375) * ((exp(_322 * (-2.7999999523162841796875)) * 0.319999992847442626953125) + (exp(sqrt(_322) * (-1.2999999523162841796875)) * 0.100000001490116119384765625)))) + (vec3(0.920000016689300537109375, 0.949999988079071044921875, 1.0) * ((exp(abs(d.y) * (-40.0)) * exp(abs(d.x) * (-1.5))) * 0.300000011920928955078125))) * (p.glints.data[i].w * ((0.7200000286102294921875 + (0.20000000298023223876953125 * mix(fract(sin(_368 * 12.98980045318603515625) * 43758.546875), fract(sin((_368 + 1.0) * 12.98980045318603515625) * 43758.546875), (_369 * _369) * (3.0 - (2.0 * _369))))) + (0.07999999821186065673828125 * mix(fract(sin(_386 * 12.98980045318603515625) * 43758.546875), fract(sin((_386 + 1.0) * 12.98980045318603515625) * 43758.546875), (_387 * _387) * (3.0 - (2.0 * _387)))))));
                        light = light_1;
                    }
                }
            }
        }
        if (_103_ladder_break)
        {
            break;
        }
        i++;
        continue;
    }
    entryPointParam_fragmentMain = vec4(light, 0.0);
}

