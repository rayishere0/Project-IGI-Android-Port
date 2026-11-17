#version 430

#ifndef SPIRV_CROSS_CONSTANT_ID_64
#define SPIRV_CROSS_CONSTANT_ID_64 1
#endif
const int cClipYDown = SPIRV_CROSS_CONSTANT_ID_64;
#ifndef SPIRV_CROSS_CONSTANT_ID_65
#define SPIRV_CROSS_CONSTANT_ID_65 0
#endif
const int cTargetEncodes = SPIRV_CROSS_CONSTANT_ID_65;
const bool _82 = (cClipYDown != 0);
const bool _190 = (cTargetEncodes != 0);

layout(binding = 0, std140) uniform TracerPush_std140
{
    layout(row_major) mat4 modelViewProjection;
    vec4 style;
} push;

layout(location = 0) out vec4 entryPointParam_fragmentMain;
layout(location = 0) in vec2 input_strip;
layout(location = 1) in vec4 input_color;

void main()
{
    vec4 _114;
    if (push.style.x < 0.5)
    {
        vec4 _498 = input_color;
        vec4 _326;
        {
            float _333 = clamp(_498.w, 0.0, 1.0);
            if (push.style.w != 0.0)
            {
                vec3 _359 = (_498.xyz + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375);
                bvec3 _518 = isnan(_359);
                bvec3 _519 = isnan(vec3(0.0));
                vec3 _520 = max(_359, vec3(0.0));
                vec3 _521 = vec3(_518.x ? vec3(0.0).x : _520.x, _518.y ? vec3(0.0).y : _520.y, _518.z ? vec3(0.0).z : _520.z);
                _326 = vec4(mix(pow(vec3(_519.x ? _359.x : _521.x, _519.y ? _359.y : _521.y, _519.z ? _359.z : _521.z), vec3(2.400000095367431640625)), _498.xyz * vec3(0.077399380505084991455078125), step(_498.xyz, vec3(0.040449999272823333740234375))) * push.style.z, _333);
            }
            else
            {
                vec4 _347 = vec4(_498.xyz, _333);
                vec4 _364;
                if (_190)
                {
                    vec3 _368 = _347.xyz;
                    vec3 _382 = (_368 + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375);
                    bvec3 _523 = isnan(_382);
                    bvec3 _524 = isnan(vec3(0.0));
                    vec3 _525 = max(_382, vec3(0.0));
                    vec3 _526 = vec3(_523.x ? vec3(0.0).x : _525.x, _523.y ? vec3(0.0).y : _525.y, _523.z ? vec3(0.0).z : _525.z);
                    _364 = vec4(mix(pow(vec3(_524.x ? _382.x : _526.x, _524.y ? _382.y : _526.y, _524.z ? _382.z : _526.z), vec3(2.400000095367431640625)), _368 * vec3(0.077399380505084991455078125), step(_368, vec3(0.040449999272823333740234375))), _333);
                }
                else
                {
                    _364 = _347;
                }
                _326 = _364;
            }
        }
        _114 = _326;
    }
    else
    {
        vec2 _500 = input_strip;
        vec4 _501 = input_color;
        vec4 _388;
        {
            float _396 = (_500.y * 2.0) - 1.0;
            float _397 = _396 * _396;
            float _400 = exp(_397 * (-9.0));
            float _404 = exp(_397 * (-3.0)) * (1.0 - _397);
            float _408 = clamp(_501.w, 0.0, 1.0);
            float _409 = _408 * _408;
            vec3 _448 = (_501.xyz + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375);
            bvec3 _528 = isnan(_448);
            bvec3 _529 = isnan(vec3(0.0));
            vec3 _530 = max(_448, vec3(0.0));
            vec3 _531 = vec3(_528.x ? vec3(0.0).x : _530.x, _528.y ? vec3(0.0).y : _530.y, _528.z ? vec3(0.0).z : _530.z);
            vec3 _452 = mix(pow(vec3(_529.x ? _448.x : _531.x, _529.y ? _448.y : _531.y, _529.z ? _448.z : _531.z), vec3(2.400000095367431640625)), _501.xyz * vec3(0.077399380505084991455078125), step(_501.xyz, vec3(0.040449999272823333740234375)));
            vec3 _421 = ((((_452 * _404) * 0.3499999940395355224609375) + (mix(_452, vec3(1.0, 0.959999978542327880859375, 0.86000001430511474609375), vec3(0.3499999940395355224609375)) * _400)) * _409) * push.style.y;
            float _425 = clamp(((_404 * 0.4000000059604644775390625) + _400) * _409, 0.0, 1.0);
            if (push.style.w != 0.0)
            {
                _388 = vec4(_421 * push.style.z, _425);
            }
            else
            {
                vec3 _455 = clamp(_421, vec3(0.0), vec3(1.0));
                bvec3 _533 = isnan(_455);
                bvec3 _534 = isnan(vec3(0.0));
                vec3 _535 = max(_455, vec3(0.0));
                vec3 _536 = vec3(_533.x ? vec3(0.0).x : _535.x, _533.y ? vec3(0.0).y : _535.y, _533.z ? vec3(0.0).z : _535.z);
                vec4 _437 = vec4(mix((pow(vec3(_534.x ? _455.x : _536.x, _534.y ? _455.y : _536.y, _534.z ? _455.z : _536.z), vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), _455 * 12.9200000762939453125, step(_455, vec3(0.003130800090730190277099609375))), _425);
                vec4 _466;
                if (_190)
                {
                    vec3 _470 = _437.xyz;
                    vec3 _484 = (_470 + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375);
                    bvec3 _538 = isnan(_484);
                    bvec3 _539 = isnan(vec3(0.0));
                    vec3 _540 = max(_484, vec3(0.0));
                    vec3 _541 = vec3(_538.x ? vec3(0.0).x : _540.x, _538.y ? vec3(0.0).y : _540.y, _538.z ? vec3(0.0).z : _540.z);
                    _466 = vec4(mix(pow(vec3(_539.x ? _484.x : _541.x, _539.y ? _484.y : _541.y, _539.z ? _484.z : _541.z), vec3(2.400000095367431640625)), _470 * vec3(0.077399380505084991455078125), step(_470, vec3(0.040449999272823333740234375))), _425);
                }
                else
                {
                    _466 = _437;
                }
                _388 = _466;
            }
        }
        _114 = _388;
    }
    entryPointParam_fragmentMain = _114;
}

