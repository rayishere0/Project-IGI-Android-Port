#version 430

#ifndef SPIRV_CROSS_CONSTANT_ID_64
#define SPIRV_CROSS_CONSTANT_ID_64 1
#endif
const int cClipYDown = SPIRV_CROSS_CONSTANT_ID_64;
const bool _80 = (cClipYDown != 0);

layout(binding = 0, std140) uniform HudFxParams_std140
{
    vec4 frame;
    vec4 visor;
    vec4 lines;
    vec4 shake;
    vec4 damage;
    vec4 damageColour;
    vec4 alert;
} p;

layout(binding = 0) uniform sampler2D _1105;
layout(binding = 1) uniform sampler2D _1107;
layout(binding = 2) uniform sampler2D _1109;
layout(binding = 3) uniform sampler2D _1111;
layout(binding = 4) uniform sampler2D _1113;
layout(binding = 5) uniform sampler2D _1115;

#ifdef GL_ARB_shader_draw_parameters
#define SPIRV_Cross_BaseVertex gl_BaseVertexARB
#else
uniform int SPIRV_Cross_BaseVertex;
#endif
layout(location = 0) out vec4 entryPointParam_fragmentMain;
layout(location = 0) in vec2 input_uv;

void main()
{
    {
        float _153 = clamp(p.visor.x, 0.0, 1.0);
        if (_153 <= 0.0)
        {
            vec4 _835;
            {
                bool _836;
                if (any(lessThan(input_uv, vec2(0.0))))
                {
                    _836 = true;
                }
                else
                {
                    _836 = any(greaterThan(input_uv, vec2(1.0)));
                }
                if (_836)
                {
                    _835 = vec4(0.0);
                }
                else
                {
                    _835 = textureLod(_1105, input_uv, 0.0);
                }
            }
            entryPointParam_fragmentMain = _835;
        }
        else
        {
            vec2 centred = ((input_uv - ((p.shake.xy * p.frame.zw) * _153)) * 2.0) - vec2(1.0);
            float _207 = dot(centred, centred);
            vec2 centred_1 = centred * (1.0 + ((p.visor.y * _153) * _207));
            vec2 uv = (centred_1 * 0.5) + vec2(0.5);
            vec2 fringe = (centred_1 * (((p.visor.z * _153) * _207) * 0.5)) * p.frame.zw;
            vec2 _227 = uv + fringe;
            vec4 _860;
            {
                bool _861;
                if (any(lessThan(_227, vec2(0.0))))
                {
                    _861 = true;
                }
                else
                {
                    _861 = any(greaterThan(_227, vec2(1.0)));
                }
                if (_861)
                {
                    _860 = vec4(0.0);
                }
                else
                {
                    _860 = textureLod(_1105, _227, 0.0);
                }
            }
            vec4 _885;
            {
                bool _886;
                if (any(lessThan(uv, vec2(0.0))))
                {
                    _886 = true;
                }
                else
                {
                    _886 = any(greaterThan(uv, vec2(1.0)));
                }
                if (_886)
                {
                    _885 = vec4(0.0);
                }
                else
                {
                    _885 = textureLod(_1105, uv, 0.0);
                }
            }
            vec2 _230 = uv - fringe;
            vec4 _910;
            {
                bool _911;
                if (any(lessThan(_230, vec2(0.0))))
                {
                    _911 = true;
                }
                else
                {
                    _911 = any(greaterThan(_230, vec2(1.0)));
                }
                if (_911)
                {
                    _910 = vec4(0.0);
                }
                else
                {
                    _910 = textureLod(_1105, _230, 0.0);
                }
            }
            float _238 = isnan(_910.w) ? _860.w : (isnan(_860.w) ? _910.w : max(_860.w, _910.w));
            vec4 _240 = vec4(_860.x, _885.y, _910.z, isnan(_238) ? _885.w : (isnan(_885.w) ? _238 : max(_885.w, _238)));
            vec3 _267 = (((textureLod(_1107, uv, 0.0) * 0.5) + (textureLod(_1109, uv, 0.0) * 0.300000011920928955078125)) + (textureLod(_1111, uv, 0.0) * 0.20000000298023223876953125)).xyz - vec3(0.449999988079071044921875);
            bvec3 _1127 = isnan(_267);
            bvec3 _1128 = isnan(vec3(0.0));
            vec3 _1129 = max(_267, vec3(0.0));
            vec3 _1130 = vec3(_1127.x ? vec3(0.0).x : _1129.x, _1127.y ? vec3(0.0).y : _1129.y, _1127.z ? vec3(0.0).z : _1129.z);
            vec3 bloom = (vec3(_1128.x ? _267.x : _1130.x, _1128.y ? _267.y : _1130.y, _1128.z ? _267.z : _1130.z) * 1.8181817531585693359375) * (p.visor.w * _153);
            vec3 _278 = _240.xyz + bloom;
            vec4 _1082 = _240;
            _1082.x = _278.x;
            _1082.y = _278.y;
            _1082.z = _278.z;
            _1082.w = clamp(_1082.w + (dot(bloom, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625)) * 0.5), 0.0, 1.0);
            float _299 = uv.y;
            float y = _299 * p.frame.y;
            vec3 _337 = _1082.xyz * ((1.0 - ((p.lines.y * _153) * (0.5 - (0.5 * cos((y * (p.lines.x * 0.000925925909541547298431396484375)) * 6.283185482025146484375))))) + ((0.0599999986588954925537109375 * _153) * exp(-pow((fract(_299 - (p.lines.w * 0.07999999821186065673828125)) - 0.5) * 9.0, 2.0))));
            vec4 _1090 = _1082;
            _1090.x = _337.x;
            _1090.y = _337.y;
            _1090.z = _337.z;
            vec4 colour = _1090;
            float _347 = clamp(p.lines.z, 0.0, 1.0);
            if (_347 < 1.0)
            {
                float _352 = floor(y * 0.16666667163372039794921875);
                colour *= (step(fract(sin(_352 * 17.7960262298583984375) * 43758.546875), _347) * mix(0.3499999940395355224609375, 1.0, step(0.5 - (_347 * 0.5), fract(sin((_352 + floor(p.lines.w * 30.0)) * 12.98980045318603515625) * 43758.546875))));
            }
            float aspect = p.frame.x * p.frame.w;
            vec2 _391 = input_uv - vec2(0.5);
            vec2 _392 = vec2(aspect, 1.0);
            vec2 fromMiddle = _391 * _392;
            float _398 = floor(p.lines.w * 24.0);
            vec2 qa = input_uv * _392;
            vec2 tr = qa - vec2(aspect, 0.0);
            vec2 bl = qa - vec2(0.0, 1.0);
            vec2 br = qa - _392;
            float hit = clamp(((((p.damage.x * exp(dot(qa, qa) * (-2.599999904632568359375))) + (p.damage.y * exp(dot(tr, tr) * (-2.599999904632568359375)))) + (p.damage.z * exp(dot(bl, bl) * (-2.599999904632568359375)))) + (p.damage.w * exp(dot(br, br) * (-2.599999904632568359375)))) * 1.60000002384185791015625, 0.0, 1.0) * _153;
            bool _103;
            if (hit > 0.0)
            {
                _103 = p.damageColour.w > 0.5;
            }
            else
            {
                _103 = false;
            }
            vec3 torn;
            float tear;
            if (_103)
            {
                float _469 = floor((input_uv.y * 1080.0) / (14.0 + (10.0 * fract(sin((floor(input_uv.y * 31.0) + _398) * 12.98980045318603515625) * 43758.546875))));
                vec2 suv = input_uv + vec2(((step(0.62000000476837158203125, fract(sin(((_469 * 3.1700000762939453125) + _398) * 12.98980045318603515625) * 43758.546875)) * (fract(sin((_469 + (_398 * 1.309999942779541015625)) * 12.98980045318603515625) * 43758.546875) - 0.5)) * 0.0500000007450580596923828125) * hit, 0.0);
                vec2 split = (normalize(fromMiddle + vec2(9.9999997473787516355514526367188e-05)) * vec2(1.0 / aspect, 1.0)) * (0.01200000010430812835693359375 * hit);
                vec3 _534 = mix(vec3(textureLod(_1113, suv + split, 0.0).x, textureLod(_1113, suv, 0.0).y, textureLod(_1113, suv - split, 0.0).z), textureLod(_1115, suv, 0.0).xyz, vec3(0.4000000059604644775390625 * hit));
                float _535 = dot(_534, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875));
                vec3 torn_1 = (mix(_534, vec3(_535), vec3(0.5 * hit)) * (1.0 - (0.119999997317790985107421875 * hit))) + (p.damageColour.xyz * ((_535 * 0.25) * hit));
                if (p.damageColour.w > 1.5)
                {
                    bvec3 _1132 = isnan(torn_1);
                    bvec3 _1133 = isnan(vec3(0.0));
                    vec3 _1134 = max(torn_1, vec3(0.0));
                    vec3 _1135 = vec3(_1132.x ? vec3(0.0).x : _1134.x, _1132.y ? vec3(0.0).y : _1134.y, _1132.z ? vec3(0.0).z : _1134.z);
                    vec3 _989 = vec3(_1133.x ? torn_1.x : _1135.x, _1133.y ? torn_1.y : _1135.y, _1133.z ? torn_1.z : _1135.z);
                    bvec3 _991 = lessThanEqual(_989, vec3(0.003130800090730190277099609375));
                    vec3 _992 = _989 * 12.9200000762939453125;
                    vec3 _996 = (pow(_989, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875);
                    torn = vec3(_991.x ? _992.x : _996.x, _991.y ? _992.y : _996.y, _991.z ? _992.z : _996.z);
                }
                else
                {
                    torn = torn_1;
                }
                tear = clamp(hit * 1.5, 0.0, 1.0);
            }
            else
            {
                torn = vec3(0.0);
                tear = 0.0;
            }
            float wheel = clamp(p.shake.z, 0.0, 1.0) * _153;
            if (wheel > 0.0)
            {
                _103 = p.damageColour.w > 0.5;
            }
            else
            {
                _103 = false;
            }
            if (_103)
            {
                int i = 0;
                vec3 smear = vec3(0.0);
                for (;;)
                {
                    if (!(i < 10))
                    {
                        break;
                    }
                    int _618 = i;
                    i++;
                    smear += textureLod(_1113, vec2(0.5) + (_391 * (1.0 - ((float(_618) * 0.0077777779661118984222412109375) * wheel))), 0.0).xyz;
                    continue;
                }
                vec3 _655 = mix(smear * 0.100000001490116119384765625, textureLod(_1115, input_uv, 0.0).xyz, vec3(0.3499999940395355224609375 * wheel));
                float _656 = dot(_655, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875));
                float grey = (_656 * _656) * (3.0 - (2.0 * _656));
                vec2 _685 = input_uv * p.frame.xy;
                uint _1009 = ((uint(_685.x) * 1664525u) ^ (uint(_685.y) * 1013904223u)) ^ (uint(_398) * 2654435761u);
                uint _1012 = (_1009 ^ (_1009 >> uint(16))) * 2146121005u;
                uint _1015 = (_1012 ^ (_1012 >> uint(15))) * 2221713035u;
                vec3 drained_1 = (mix(_655, vec3(grey, grey * 0.98500001430511474609375, grey * 0.959999978542327880859375), vec3(0.920000016689300537109375 * wheel)) * ((1.0 - (0.300000011920928955078125 * wheel)) * (1.0 - ((0.60000002384185791015625 * wheel) * smoothstep(0.25, 0.85000002384185791015625, length(fromMiddle)))))) + vec3((((float(_1015 ^ (_1015 >> uint(16))) * 2.3283064365386962890625e-10) - 0.5) * 0.02500000037252902984619140625) * wheel);
                vec3 drained;
                if (p.damageColour.w > 1.5)
                {
                    bvec3 _1137 = isnan(drained_1);
                    bvec3 _1138 = isnan(vec3(0.0));
                    vec3 _1139 = max(drained_1, vec3(0.0));
                    vec3 _1140 = vec3(_1137.x ? vec3(0.0).x : _1139.x, _1137.y ? vec3(0.0).y : _1139.y, _1137.z ? vec3(0.0).z : _1139.z);
                    vec3 _1022 = vec3(_1138.x ? drained_1.x : _1140.x, _1138.y ? drained_1.y : _1140.y, _1138.z ? drained_1.z : _1140.z);
                    bvec3 _1024 = lessThanEqual(_1022, vec3(0.003130800090730190277099609375));
                    vec3 _1025 = _1022 * 12.9200000762939453125;
                    vec3 _1029 = (pow(_1022, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875);
                    drained = vec3(_1024.x ? _1025.x : _1029.x, _1024.y ? _1025.y : _1029.y, _1024.z ? _1025.z : _1029.z);
                }
                else
                {
                    drained = drained_1;
                }
                float _744 = isnan(wheel) ? tear : (isnan(tear) ? wheel : max(tear, wheel));
                torn = mix(torn * tear, drained, vec3(wheel)) / vec3(isnan(9.9999997473787516355514526367188e-05) ? _744 : (isnan(_744) ? 9.9999997473787516355514526367188e-05 : max(_744, 9.9999997473787516355514526367188e-05)));
                tear = isnan(wheel) ? tear : (isnan(tear) ? wheel : max(tear, wheel));
            }
            float dim;
            if (p.damageColour.w > 0.5)
            {
                dim = 0.0;
            }
            else
            {
                dim = hit * 0.1500000059604644775390625;
            }
            vec4 _1032;
            {
                bool _1033;
                if (any(lessThan(input_uv, vec2(0.0))))
                {
                    _1033 = true;
                }
                else
                {
                    _1033 = any(greaterThan(input_uv, vec2(1.0)));
                }
                if (_1033)
                {
                    _1032 = vec4(0.0);
                }
                else
                {
                    _1032 = textureLod(_1105, input_uv, 0.0);
                }
            }
            vec4 _768 = mix(_1032, colour, vec4(_153));
            vec3 _777 = _768.xyz + (torn * (tear * (1.0 - _768.w)));
            vec4 _1096 = _768;
            _1096.x = _777.x;
            _1096.y = _777.y;
            _1096.z = _777.z;
            _1096.w = _1096.w + ((isnan(dim) ? tear : (isnan(tear) ? dim : max(tear, dim))) * (1.0 - _1096.w));
            entryPointParam_fragmentMain = _1096;
        }
    }
}

