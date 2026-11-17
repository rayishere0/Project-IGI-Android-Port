#version 430

#ifndef SPIRV_CROSS_CONSTANT_ID_64
#define SPIRV_CROSS_CONSTANT_ID_64 1
#endif
const int cClipYDown = SPIRV_CROSS_CONSTANT_ID_64;
#ifndef SPIRV_CROSS_CONSTANT_ID_66
#define SPIRV_CROSS_CONSTANT_ID_66 0
#endif
const int cSamplerDecodes = SPIRV_CROSS_CONSTANT_ID_66;
#ifndef SPIRV_CROSS_CONSTANT_ID_65
#define SPIRV_CROSS_CONSTANT_ID_65 0
#endif
const int cTargetEncodes = SPIRV_CROSS_CONSTANT_ID_65;
const bool _77 = (cClipYDown != 0);
uniform vec2 _184_frag[16] = vec2[](vec2(-0.612999975681304931640625, -0.61699998378753662109375), vec2(0.17000000178813934326171875, -0.039999999105930328369140625), vec2(-0.2989999949932098388671875, 0.73500001430511474609375), vec2(0.644999980926513671875, 0.507000029087066650390625), vec2(0.421000003814697265625, -0.73500001430511474609375), vec2(-0.859000027179718017578125, 0.1180000007152557373046875), vec2(0.902000010013580322265625, -0.11699999868869781494140625), vec2(-0.1829999983310699462890625, -0.29100000858306884765625), vec2(0.21899999678134918212890625, 0.4180000126361846923828125), vec2(-0.5559999942779541015625, 0.342999994754791259765625), vec2(0.70200002193450927734375, 0.12899999320507049560546875), vec2(-0.114000000059604644775390625, 0.976000010967254638671875), vec2(-0.3829999864101409912109375, -0.912000000476837158203125), vec2(0.512000024318695068359375, -0.3720000088214874267578125), vec2(-0.762000024318695068359375, -0.2899999916553497314453125), vec2(0.0610000006854534149169921875, -0.665000021457672119140625));
const bool _260 = (cSamplerDecodes != 0);
const bool _556 = (cTargetEncodes != 0);

layout(binding = 0, std140) uniform LoadingPush_std140
{
    float time;
    float blur;
    float desaturate;
    float vignette;
    float zoom;
    float grain;
    float scanline;
    float opacity;
    float letterbox;
    float hasPicture;
    float aspect;
    float sweep;
    float reserved0;
    float reserved1;
    float reserved2;
    float reserved3;
} p;

layout(binding = 0) uniform sampler2D _771;

#ifdef GL_ARB_shader_draw_parameters
#define SPIRV_Cross_BaseVertex gl_BaseVertexARB
#else
uniform int SPIRV_Cross_BaseVertex;
#endif
layout(location = 0) out vec4 entryPointParam_fragmentMain;
layout(location = 0) in vec2 input_uv;

void main()
{
    vec3 sum;
    if (p.hasPicture > 0.5)
    {
        vec2 _138 = ((input_uv - vec2(0.5)) / vec2(isnan(0.5) ? p.zoom : (isnan(p.zoom) ? 0.5 : max(p.zoom, 0.5)))) + vec2(0.5);
        float radius = p.blur * 0.02199999988079071044921875;
        vec2 _149 = vec2(radius / (isnan(0.100000001490116119384765625) ? p.aspect : (isnan(p.aspect) ? 0.100000001490116119384765625 : max(p.aspect, 0.100000001490116119384765625))), radius);
        float turn = fract(sin(dot(input_uv * vec2(1919.0, 1079.0), vec2(127.09999847412109375, 311.70001220703125))) * 43758.546875) * 6.283185482025146484375;
        float _170 = cos(turn);
        float _171 = sin(turn);
        mat2 _176 = mat2(vec2(_170, _171), vec2(-_171, _170));
        int i = 0;
        sum = vec3(0.0);
        vec3 _698;
        for (;;)
        {
            if (!(i < 16))
            {
                break;
            }
            vec4 _sampled = texture(_771, clamp(_138 + ((_176 * _184_frag[i]) * _149), vec2(0.00200000009499490261077880859375), vec2(0.99800002574920654296875)));
            vec3 _250 = _sampled.xyz;
            if (_260)
            {
                bvec3 _783 = isnan(_250);
                bvec3 _784 = isnan(vec3(0.0));
                vec3 _785 = max(_250, vec3(0.0));
                vec3 _786 = vec3(_783.x ? vec3(0.0).x : _785.x, _783.y ? vec3(0.0).y : _785.y, _783.z ? vec3(0.0).z : _785.z);
                _698 = mix((pow(vec3(_784.x ? _250.x : _786.x, _784.y ? _250.y : _786.y, _784.z ? _250.z : _786.z), vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), _250 * 12.9200000762939453125, step(_250, vec3(0.003130800090730190277099609375)));
            }
            else
            {
                _698 = _250;
            }
            i++;
            sum += _698;
            continue;
        }
        sum *= vec3(0.0625);
    }
    else
    {
        vec2 _615 = (input_uv * vec2(3.0 * p.aspect, 3.0)) + vec2(p.time * 0.02500000037252902984619140625, p.time * (-0.0170000009238719940185546875));
        int _616 = 0;
        float _617 = 0.5;
        float _618 = 0.0;
        for (;;)
        {
            if (!(_616 < 4))
            {
                break;
            }
            vec2 _629 = _615;
            vec2 _649 = floor(_629);
            vec2 _650 = fract(_629);
            vec2 _655 = (_650 * _650) * (vec2(3.0) - (_650 * 2.0));
            float _663 = _655.x;
            float _631 = _617;
            _615 = (_629 * 2.0299999713897705078125) + vec2(17.0, 9.0);
            _616++;
            _617 = _631 * 0.5;
            _618 += (_631 * mix(mix(fract(sin(dot(_649, vec2(127.09999847412109375, 311.70001220703125))) * 43758.546875), fract(sin(dot(_649 + vec2(1.0, 0.0), vec2(127.09999847412109375, 311.70001220703125))) * 43758.546875), _663), mix(fract(sin(dot(_649 + vec2(0.0, 1.0), vec2(127.09999847412109375, 311.70001220703125))) * 43758.546875), fract(sin(dot(_649 + vec2(1.0), vec2(127.09999847412109375, 311.70001220703125))) * 43758.546875), _663), _655.y));
            continue;
        }
        vec2 _421 = fract(input_uv * vec2(20.0 * p.aspect, 20.0));
        float _422 = _421.x;
        float _423 = _421.y;
        float _424 = isnan(_423) ? _422 : (isnan(_422) ? _423 : min(_422, _423));
        float _425 = 1.0 - _422;
        float _426 = 1.0 - _423;
        float _427 = isnan(_426) ? _425 : (isnan(_425) ? _426 : min(_425, _426));
        sum = mix(vec3(0.02999999932944774627685546875, 0.0379999987781047821044921875, 0.0500000007450580596923828125), vec3(0.104999996721744537353515625, 0.12999999523162841796875, 0.16500000655651092529296875), vec3((_618 * 0.85000002384185791015625) + ((1.0 - input_uv.y) * 0.20000000298023223876953125))) + ((vec3(0.550000011920928955078125, 0.699999988079071044921875, 0.89999997615814208984375) * (1.0 - smoothstep(0.0, 0.0500000007450580596923828125, isnan(_427) ? _424 : (isnan(_424) ? _427 : min(_424, _427))))) * 0.04500000178813934326171875);
    }
    vec3 _447 = vec3(dot(sum, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625)));
    float band = (input_uv.x + (input_uv.y * 0.3499999940395355224609375)) - p.sweep;
    float _533 = p.letterbox - 0.0030000000260770320892333984375;
    float _535 = p.letterbox + 0.0030000000260770320892333984375;
    vec3 colour = (((((mix(sum, mix(_447, _447 * vec3(0.839999973773956298828125, 0.939999997615814208984375, 1.10000002384185791015625), vec3(0.64999997615814208984375)), vec3(p.desaturate)) * mix(1.0, 0.519999980926513671875, p.desaturate)) + ((vec3(0.085000000894069671630859375, 0.100000001490116119384765625, 0.125) * exp(((-band) * band) * 36.0)) * p.desaturate)) * mix(1.0, smoothstep(0.980000019073486328125, 0.2800000011920928955078125, length((input_uv - vec2(0.5)) * vec2(1.10000002384185791015625, 1.0))), p.vignette)) * (1.0 - (p.scanline * (0.5 + (0.5 * sin(input_uv.y * 1800.0)))))) + vec3((fract(sin(dot((input_uv * vec2(1920.0, 1080.0)) + vec2(fract(p.time * 7.309999942779541015625)), vec2(127.09999847412109375, 311.70001220703125))) * 43758.546875) - 0.5) * p.grain)) * (smoothstep(_533, _535, input_uv.y) * smoothstep(_533, _535, 1.0 - input_uv.y));
    bvec3 _803 = isnan(colour);
    bvec3 _804 = isnan(vec3(0.0));
    vec3 _805 = max(colour, vec3(0.0));
    vec3 _806 = vec3(_803.x ? vec3(0.0).x : _805.x, _803.y ? vec3(0.0).y : _805.y, _803.z ? vec3(0.0).z : _805.z);
    vec4 _546 = vec4(vec3(_804.x ? colour.x : _806.x, _804.y ? colour.y : _806.y, _804.z ? colour.z : _806.z), p.opacity);
    vec4 _722;
    if (_556)
    {
        vec3 _727 = _546.xyz;
        vec3 _740 = (_727 + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375);
        bvec3 _808 = isnan(_740);
        bvec3 _809 = isnan(vec3(0.0));
        vec3 _810 = max(_740, vec3(0.0));
        vec3 _811 = vec3(_808.x ? vec3(0.0).x : _810.x, _808.y ? vec3(0.0).y : _810.y, _808.z ? vec3(0.0).z : _810.z);
        _722 = vec4(mix(pow(vec3(_809.x ? _740.x : _811.x, _809.y ? _740.y : _811.y, _809.z ? _740.z : _811.z), vec3(2.400000095367431640625)), _727 * vec3(0.077399380505084991455078125), step(_727, vec3(0.040449999272823333740234375))), p.opacity);
    }
    else
    {
        _722 = _546;
    }
    entryPointParam_fragmentMain = _722;
}

