#version 430

#ifndef SPIRV_CROSS_CONSTANT_ID_1
#define SPIRV_CROSS_CONSTANT_ID_1 0
#endif
const int cReflective = SPIRV_CROSS_CONSTANT_ID_1;
#ifndef SPIRV_CROSS_CONSTANT_ID_64
#define SPIRV_CROSS_CONSTANT_ID_64 1
#endif
const int cClipYDown = SPIRV_CROSS_CONSTANT_ID_64;
#ifndef SPIRV_CROSS_CONSTANT_ID_6
#define SPIRV_CROSS_CONSTANT_ID_6 0.0
#endif
const float cSunAmbientRed = SPIRV_CROSS_CONSTANT_ID_6;
#ifndef SPIRV_CROSS_CONSTANT_ID_7
#define SPIRV_CROSS_CONSTANT_ID_7 0.0
#endif
const float cSunAmbientGreen = SPIRV_CROSS_CONSTANT_ID_7;
#ifndef SPIRV_CROSS_CONSTANT_ID_8
#define SPIRV_CROSS_CONSTANT_ID_8 0.0
#endif
const float cSunAmbientBlue = SPIRV_CROSS_CONSTANT_ID_8;
#ifndef SPIRV_CROSS_CONSTANT_ID_9
#define SPIRV_CROSS_CONSTANT_ID_9 0.0
#endif
const float cSunRed = SPIRV_CROSS_CONSTANT_ID_9;
#ifndef SPIRV_CROSS_CONSTANT_ID_10
#define SPIRV_CROSS_CONSTANT_ID_10 0.0
#endif
const float cSunGreen = SPIRV_CROSS_CONSTANT_ID_10;
#ifndef SPIRV_CROSS_CONSTANT_ID_11
#define SPIRV_CROSS_CONSTANT_ID_11 0.0
#endif
const float cSunBlue = SPIRV_CROSS_CONSTANT_ID_11;
#ifndef SPIRV_CROSS_CONSTANT_ID_0
#define SPIRV_CROSS_CONSTANT_ID_0 0.501960813999176025390625
#endif
const float cAlphaReference = SPIRV_CROSS_CONSTANT_ID_0;
#ifndef SPIRV_CROSS_CONSTANT_ID_66
#define SPIRV_CROSS_CONSTANT_ID_66 0
#endif
const int cSamplerDecodes = SPIRV_CROSS_CONSTANT_ID_66;
#ifndef SPIRV_CROSS_CONSTANT_ID_12
#define SPIRV_CROSS_CONSTANT_ID_12 0
#endif
const int cLinearScene = SPIRV_CROSS_CONSTANT_ID_12;
const bool _166 = (cReflective != 0);
const bool _374 = (cClipYDown != 0);
const bool _589 = (cSamplerDecodes != 0);
const bool _643 = (cLinearScene == 0);
const bool _722 = (cLinearScene != 0);

layout(binding = 0, std140) uniform MeshPush_std140
{
    layout(row_major) mat4 modelViewProjection;
    vec4 markerExposure;
    vec4 normalKey0;
    vec4 normalKey1;
    vec4 normalKey2;
} push;

layout(binding = 0) uniform sampler2D _976;
layout(binding = 1) uniform sampler2D _978;
layout(binding = 2) uniform samplerCube _980;

layout(location = 0) out vec4 entryPointParam_fragmentMain;
layout(location = 0) in vec2 input_diffuseUv;
layout(location = 1) in vec2 input_lightmapUv;
layout(location = 2) in vec4 input_color;
layout(location = 3) in vec3 input_normal;
layout(location = 4) in float input_fade;
layout(location = 5) in float input_fog;
layout(location = 6) in vec3 input_reflection;

void main()
{
    {
        vec4 _sampled = texture(_976, input_diffuseUv);
        bool translucent = push.markerExposure.x < 0.0;
        bool _510;
        if (!translucent)
        {
            _510 = _sampled.w < cAlphaReference;
        }
        else
        {
            _510 = false;
        }
        if (_510)
        {
            discard;
        }
        vec4 _sampled_1 = texture(_978, input_lightmapUv);
        vec3 _579 = _sampled_1.xyz;
        vec3 _860;
        if (_589)
        {
            bvec3 _982 = isnan(_579);
            bvec3 _983 = isnan(vec3(0.0));
            vec3 _984 = max(_579, vec3(0.0));
            vec3 _985 = vec3(_982.x ? vec3(0.0).x : _984.x, _982.y ? vec3(0.0).y : _984.y, _982.z ? vec3(0.0).z : _984.z);
            _860 = mix((pow(vec3(_983.x ? _579.x : _985.x, _983.y ? _579.y : _985.y, _983.z ? _579.z : _985.z), vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), _579 * 12.9200000762939453125, step(_579, vec3(0.003130800090730190277099609375)));
        }
        else
        {
            _860 = _579;
        }
        if (abs(push.normalKey0.w) > 0.5)
        {
            _510 = true;
        }
        else
        {
            _510 = push.markerExposure.x < 0.5;
        }
        vec3 modelTint;
        if (_510)
        {
            modelTint = vec3(1.0);
        }
        else
        {
            modelTint = push.normalKey1.xyz;
        }
        bool _641 = abs(push.markerExposure.x) > 0.5;
        if (_641)
        {
            _510 = _643;
        }
        else
        {
            _510 = false;
        }
        float lightmapGain;
        if (_510)
        {
            lightmapGain = push.markerExposure.y;
        }
        else
        {
            lightmapGain = 1.0;
        }
        vec3 _656 = _sampled.xyz;
        vec3 _878;
        if (_589)
        {
            bvec3 _987 = isnan(_656);
            bvec3 _988 = isnan(vec3(0.0));
            vec3 _989 = max(_656, vec3(0.0));
            vec3 _990 = vec3(_987.x ? vec3(0.0).x : _989.x, _987.y ? vec3(0.0).y : _989.y, _987.z ? vec3(0.0).z : _989.z);
            _878 = mix((pow(vec3(_988.x ? _656.x : _990.x, _988.y ? _656.y : _990.y, _988.z ? _656.z : _990.z), vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), _656 * 12.9200000762939453125, step(_656, vec3(0.003130800090730190277099609375)));
        }
        else
        {
            _878 = _656;
        }
        vec3 base_1 = ((((_878 * _860) * lightmapGain) * input_color.xyz) * input_fade) * modelTint;
        vec3 base;
        if (_166)
        {
            vec4 _sampled_2 = texture(_980, normalize(input_reflection).xzy);
            vec3 _678 = _sampled_2.xyz;
            vec3 _896;
            if (_589)
            {
                bvec3 _992 = isnan(_678);
                bvec3 _993 = isnan(vec3(0.0));
                vec3 _994 = max(_678, vec3(0.0));
                vec3 _995 = vec3(_992.x ? vec3(0.0).x : _994.x, _992.y ? vec3(0.0).y : _994.y, _992.z ? vec3(0.0).z : _994.z);
                _896 = mix((pow(vec3(_993.x ? _678.x : _995.x, _993.y ? _678.y : _995.y, _993.z ? _678.z : _995.z), vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), _678 * 12.9200000762939453125, step(_678, vec3(0.003130800090730190277099609375)));
            }
            else
            {
                _896 = _678;
            }
            base = base_1 + _896;
        }
        else
        {
            base = base_1;
        }
        float alpha;
        if (translucent)
        {
            alpha = _sampled.w * input_color.w;
        }
        else
        {
            if (push.markerExposure.x > 1.5)
            {
                lightmapGain = 0.0;
            }
            else
            {
                lightmapGain = push.markerExposure.x;
            }
            alpha = lightmapGain;
        }
        if (_641)
        {
            float fogShare;
            if (push.normalKey0.w < (-0.5))
            {
                fogShare = input_color.x;
            }
            else
            {
                fogShare = 1.0;
            }
            vec3 _721 = mix(push.normalKey2.xyz * fogShare, base, vec3(input_fog));
            if (_722)
            {
                bvec3 _997 = isnan(_721);
                bvec3 _998 = isnan(vec3(0.0));
                vec3 _999 = max(_721, vec3(0.0));
                vec3 _1000 = vec3(_997.x ? vec3(0.0).x : _999.x, _997.y ? vec3(0.0).y : _999.y, _997.z ? vec3(0.0).z : _999.z);
                vec3 _724 = vec3(_998.x ? _721.x : _1000.x, _998.y ? _721.y : _1000.y, _998.z ? _721.z : _1000.z);
                vec3 _921 = (_724 + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375);
                bvec3 _1002 = isnan(_921);
                bvec3 _1003 = isnan(vec3(0.0));
                vec3 _1004 = max(_921, vec3(0.0));
                vec3 _1005 = vec3(_1002.x ? vec3(0.0).x : _1004.x, _1002.y ? vec3(0.0).y : _1004.y, _1002.z ? vec3(0.0).z : _1004.z);
                entryPointParam_fragmentMain = vec4(mix(pow(vec3(_1003.x ? _921.x : _1005.x, _1003.y ? _921.y : _1005.y, _1003.z ? _921.z : _1005.z), vec3(2.400000095367431640625)), _724 * vec3(0.077399380505084991455078125), step(_724, vec3(0.040449999272823333740234375))) * push.markerExposure.y, alpha);
            }
            else
            {
                entryPointParam_fragmentMain = vec4(_721, alpha);
            }
        }
        else
        {
            if (_722)
            {
                bvec3 _1007 = isnan(base);
                bvec3 _1008 = isnan(vec3(0.0));
                vec3 _1009 = max(base, vec3(0.0));
                vec3 _1010 = vec3(_1007.x ? vec3(0.0).x : _1009.x, _1007.y ? vec3(0.0).y : _1009.y, _1007.z ? vec3(0.0).z : _1009.z);
                vec3 _759 = vec3(_1008.x ? base.x : _1010.x, _1008.y ? base.y : _1010.y, _1008.z ? base.z : _1010.z);
                vec3 _933 = (_759 + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375);
                bvec3 _1012 = isnan(_933);
                bvec3 _1013 = isnan(vec3(0.0));
                vec3 _1014 = max(_933, vec3(0.0));
                vec3 _1015 = vec3(_1012.x ? vec3(0.0).x : _1014.x, _1012.y ? vec3(0.0).y : _1014.y, _1012.z ? vec3(0.0).z : _1014.z);
                base = mix(pow(vec3(_1013.x ? _933.x : _1015.x, _1013.y ? _933.y : _1015.y, _1013.z ? _933.z : _1015.z), vec3(2.400000095367431640625)), _759 * vec3(0.077399380505084991455078125), step(_759, vec3(0.040449999272823333740234375)));
            }
            vec3 _764 = normalize(vec3(-0.3499999940395355224609375, 0.449999988079071044921875, -0.819999992847442626953125));
            vec3 _775 = normalize(input_normal);
            vec3 keyColour = vec3(push.normalKey0.w, push.normalKey1.w, push.normalKey2.w);
            float _801 = dot(_775, _764);
            float _802 = isnan(0.0) ? _801 : (isnan(_801) ? 0.0 : max(_801, 0.0));
            float _803 = dot(_775, normalize(vec3(0.550000011920928955078125, -0.20000000298023223876953125, -0.550000011920928955078125)));
            float _817 = dot(_775, normalize(_764 + vec3(0.0, 0.0, -1.0)));
            float _825 = dot(_775, vec3(0.0, 0.0, -1.0));
            vec3 _831 = mix(vec3(0.039999999105930328369140625), base, vec3(0.3499999940395355224609375)) * keyColour;
            entryPointParam_fragmentMain = vec4(((((base * 0.64999997615814208984375) * ((vec3(push.markerExposure.w, push.markerExposure.w, push.markerExposure.w) + (keyColour * _802)) + ((keyColour * 0.25) * (isnan(0.0) ? _803 : (isnan(_803) ? 0.0 : max(_803, 0.0)))))) + ((_831 * (pow(isnan(0.0) ? _817 : (isnan(_817) ? 0.0 : max(_817, 0.0)), 132.5139312744140625) * 5.620557308197021484375)) * _802)) + (((_831 * pow(1.0 - (isnan(0.0) ? _825 : (isnan(_825) ? 0.0 : max(_825, 0.0))), 4.0)) * 0.3499999940395355224609375) * 0.60000002384185791015625)) * push.markerExposure.y, alpha);
        }
    }
}

