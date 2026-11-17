#version 430

#ifndef SPIRV_CROSS_CONSTANT_ID_64
#define SPIRV_CROSS_CONSTANT_ID_64 1
#endif
const int cClipYDown = SPIRV_CROSS_CONSTANT_ID_64;
const bool _73 = (cClipYDown != 0);
uniform vec2 _196_frag[12] = vec2[](vec2(-0.3260000050067901611328125, -0.4059999883174896240234375), vec2(-0.839999973773956298828125, -0.07400000095367431640625), vec2(-0.69599997997283935546875, 0.4569999873638153076171875), vec2(-0.20299999415874481201171875, 0.620999991893768310546875), vec2(0.96200001239776611328125, -0.194999992847442626953125), vec2(0.472999989986419677734375, -0.4799999892711639404296875), vec2(0.518999993801116943359375, 0.767000019550323486328125), vec2(0.185000002384185791015625, -0.89300000667572021484375), vec2(0.507000029087066650390625, 0.064000003039836883544921875), vec2(0.89600002765655517578125, 0.412000000476837158203125), vec2(-0.3219999969005584716796875, -0.933000028133392333984375), vec2(-0.791999995708465576171875, -0.597999989986419677734375));

layout(binding = 0) uniform sampler2D _366;
layout(binding = 1) uniform sampler2D _369;
layout(binding = 2) uniform sampler2D _372;

#ifdef GL_ARB_shader_draw_parameters
#define SPIRV_Cross_BaseVertex gl_BaseVertexARB
#else
uniform int SPIRV_Cross_BaseVertex;
#endif
layout(location = 0) out vec4 entryPointParam_fragmentMain;

void main()
{
    ivec2 _132 = ivec2(gl_FragCoord.xy);
    ivec2 _135 = ivec3(_132, 0).xy;
    vec4 _sampled = texelFetch(_366, _135, 0);
    vec3 reflection = _sampled.xyz;
    float _140 = _sampled.w;
    vec3 sum;
    if (_140 >= 2.0)
    {
        float roughness = _140 - 2.0;
        float _147 = clamp((roughness * roughness) * 28.0, 0.0, 10.0);
        if (_147 >= 1.0)
        {
            uvec2 _vecSize = uvec2(textureSize(_369, 0));
            ivec2 _164 = ivec2(int(_vecSize.x) - 1, int(_vecSize.y) - 1);
            vec4 _sampled_1 = texelFetch(_369, _135, 0);
            float _167 = _sampled_1.x;
            vec3 _175 = normalize((texelFetch(_372, _135, 0).xyz * 2.0) - vec3(1.0));
            float angle = fract(52.98291778564453125 * fract(dot(vec2(_132), vec2(0.067110560834407806396484375, 0.005837149918079376220703125)))) * 6.283185482025146484375;
            float _187 = sin(angle);
            float _188 = cos(angle);
            int i = 0;
            sum = reflection;
            float weightSum = 1.0;
            float sameDepth;
            for (;;)
            {
                bool _112_ladder_break = false;
                {
                    if (!(i < 12))
                    {
                        _112_ladder_break = true;
                    }
                    else
                    {
                        ivec2 _252 = ivec3(clamp(_132 + ivec2(round(vec2((_196_frag[i].x * _188) - (_196_frag[i].y * _187), (_196_frag[i].x * _187) + (_196_frag[i].y * _188)) * _147)), ivec2(0), _164), 0).xy;
                        vec4 _sampled_2 = texelFetch(_366, _252, 0);
                        if (!(_sampled_2.w < 2.0))
                        {
                            if (abs(texelFetch(_369, _252, 0).x - _167) <= (0.02999999932944774627685546875 * (isnan(9.9999999747524270787835121154785e-07) ? _167 : (isnan(_167) ? 9.9999999747524270787835121154785e-07 : max(_167, 9.9999999747524270787835121154785e-07)))))
                            {
                                sameDepth = 1.0;
                            }
                            else
                            {
                                sameDepth = 0.0;
                            }
                            float _284 = clamp(dot(normalize((texelFetch(_372, _252, 0).xyz * 2.0) - vec3(1.0)), _175), 0.0, 1.0);
                            float weight = (((sameDepth * _284) * _284) * _284) * _284;
                            sum += (_sampled_2.xyz * weight);
                            weightSum += weight;
                        }
                    }
                }
                if (_112_ladder_break)
                {
                    break;
                }
                i++;
                continue;
            }
            sum /= vec3(weightSum);
        }
        else
        {
            sum = reflection;
        }
    }
    else
    {
        sum = reflection;
    }
    bvec3 _379 = isnan(sum);
    bvec3 _380 = isnan(vec3(0.0));
    vec3 _381 = max(sum, vec3(0.0));
    vec3 _382 = vec3(_379.x ? vec3(0.0).x : _381.x, _379.y ? vec3(0.0).y : _381.y, _379.z ? vec3(0.0).z : _381.z);
    entryPointParam_fragmentMain = vec4(vec3(_380.x ? sum.x : _382.x, _380.y ? sum.y : _382.y, _380.z ? sum.z : _382.z), 0.0);
}

