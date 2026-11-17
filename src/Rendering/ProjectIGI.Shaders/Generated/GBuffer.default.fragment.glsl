#version 430

#ifndef SPIRV_CROSS_CONSTANT_ID_64
#define SPIRV_CROSS_CONSTANT_ID_64 1
#endif
const int cClipYDown = SPIRV_CROSS_CONSTANT_ID_64;
#ifndef SPIRV_CROSS_CONSTANT_ID_0
#define SPIRV_CROSS_CONSTANT_ID_0 0.501960813999176025390625
#endif
const float cAlphaReference = SPIRV_CROSS_CONSTANT_ID_0;
#ifndef SPIRV_CROSS_CONSTANT_ID_66
#define SPIRV_CROSS_CONSTANT_ID_66 0
#endif
const int cSamplerDecodes = SPIRV_CROSS_CONSTANT_ID_66;
#ifndef SPIRV_CROSS_CONSTANT_ID_13
#define SPIRV_CROSS_CONSTANT_ID_13 0.0
#endif
const float cSunDirectionX = SPIRV_CROSS_CONSTANT_ID_13;
#ifndef SPIRV_CROSS_CONSTANT_ID_14
#define SPIRV_CROSS_CONSTANT_ID_14 0.0
#endif
const float cSunDirectionY = SPIRV_CROSS_CONSTANT_ID_14;
#ifndef SPIRV_CROSS_CONSTANT_ID_15
#define SPIRV_CROSS_CONSTANT_ID_15 0.0
#endif
const float cSunDirectionZ = SPIRV_CROSS_CONSTANT_ID_15;
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
const bool _248 = (cClipYDown != 0);
const bool _515 = (cSamplerDecodes != 0);

layout(binding = 1, std140) uniform GBufferPush_std140
{
    layout(row_major) mat4 modelViewProjection;
    vec4 normal0;
    vec4 normal1;
    vec4 normal2;
    vec4 material;
} push;

layout(binding = 0, std140) uniform SurfaceSettings_std140
{
    vec4 surface;
} frame;

layout(binding = 0) uniform sampler2D _1146;
layout(binding = 1) uniform sampler2D _1148;
layout(binding = 2) uniform sampler2D _1150;

layout(location = 0) out vec4 entryPointParam_fragmentMain_baseColour;
layout(location = 1) out vec4 entryPointParam_fragmentMain_normal;
layout(location = 2) out vec4 entryPointParam_fragmentMain_material;
layout(location = 3) out vec4 entryPointParam_fragmentMain_baked;
layout(location = 0) in vec2 input_diffuseUv;
layout(location = 1) in vec2 input_lightmapUv;
layout(location = 2) in vec4 input_color;
layout(location = 3) in vec3 input_worldNormal;
layout(location = 4) in float input_fade;
layout(location = 5) in vec3 input_surfacePosition;

void main()
{
    {
        vec4 _sampled = texture(_1146, input_diffuseUv);
        float alpha = _sampled.w * input_color.w;
        float _954 = fwidth(alpha);
        bool _392;
        if (push.normal2.w > 0.0)
        {
            _392 = _954 > 0.00200000009499490261077880859375;
        }
        else
        {
            _392 = false;
        }
        if (_392)
        {
            if (fract(sin(dot(gl_FragCoord.xy, vec2(12.98980045318603515625, 78.233001708984375)) + push.normal2.w) * 43758.546875) > clamp(((alpha - cAlphaReference) / _954) + 0.5, 0.0, 1.0))
            {
                discard;
            }
        }
        else
        {
            if (alpha < cAlphaReference)
            {
                discard;
            }
        }
        vec3 _505 = _sampled.xyz;
        vec3 _955;
        if (_515)
        {
            _955 = _505;
        }
        else
        {
            vec3 _970 = (_505 + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375);
            bvec3 _1152 = isnan(_970);
            bvec3 _1153 = isnan(vec3(0.0));
            vec3 _1154 = max(_970, vec3(0.0));
            vec3 _1155 = vec3(_1152.x ? vec3(0.0).x : _1154.x, _1152.y ? vec3(0.0).y : _1154.y, _1152.z ? vec3(0.0).z : _1154.z);
            _955 = mix(pow(vec3(_1153.x ? _970.x : _1155.x, _1153.y ? _970.y : _1155.y, _1153.z ? _970.z : _1155.z), vec3(2.400000095367431640625)), _505 * vec3(0.077399380505084991455078125), step(_505, vec3(0.040449999272823333740234375)));
        }
        vec3 _982 = (input_color.xyz + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375);
        bvec3 _1157 = isnan(_982);
        bvec3 _1158 = isnan(vec3(0.0));
        vec3 _1159 = max(_982, vec3(0.0));
        vec3 _1160 = vec3(_1157.x ? vec3(0.0).x : _1159.x, _1157.y ? vec3(0.0).y : _1159.y, _1157.z ? vec3(0.0).z : _1159.z);
        vec3 albedo_1 = (_955 * mix(pow(vec3(_1158.x ? _982.x : _1160.x, _1158.y ? _982.y : _1160.y, _1158.z ? _982.z : _1160.z), vec3(2.400000095367431640625)), input_color.xyz * vec3(0.077399380505084991455078125), step(input_color.xyz, vec3(0.040449999272823333740234375)))) * input_fade;
        vec4 _sampled_1 = texture(_1148, input_lightmapUv);
        vec3 _558 = _sampled_1.xyz;
        vec3 _987;
        if (_515)
        {
            _987 = _558;
        }
        else
        {
            vec3 _1002 = (_558 + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375);
            bvec3 _1162 = isnan(_1002);
            bvec3 _1163 = isnan(vec3(0.0));
            vec3 _1164 = max(_1002, vec3(0.0));
            vec3 _1165 = vec3(_1162.x ? vec3(0.0).x : _1164.x, _1162.y ? vec3(0.0).y : _1164.y, _1162.z ? vec3(0.0).z : _1164.z);
            _987 = mix(pow(vec3(_1163.x ? _1002.x : _1165.x, _1163.y ? _1002.y : _1165.y, _1163.z ? _1002.z : _1165.z), vec3(2.400000095367431640625)), _558 * vec3(0.077399380505084991455078125), step(_558, vec3(0.040449999272823333740234375)));
        }
        vec4 _1115;
        vec4 _1116;
        if (push.normal0.w > 3.5)
        {
            _1115 = vec4(0.0);
            _1116 = vec4(0.0);
            vec3 _1014 = (input_color.xyz + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375);
            bvec3 _1167 = isnan(_1014);
            bvec3 _1168 = isnan(vec3(0.0));
            vec3 _1169 = max(_1014, vec3(0.0));
            vec3 _1170 = vec3(_1167.x ? vec3(0.0).x : _1169.x, _1167.y ? vec3(0.0).y : _1169.y, _1167.z ? vec3(0.0).z : _1169.z);
            entryPointParam_fragmentMain_baseColour = vec4(0.0);
            entryPointParam_fragmentMain_normal = vec4(0.0);
            entryPointParam_fragmentMain_material = vec4(0.0);
            entryPointParam_fragmentMain_baked = vec4(_955 * mix(pow(vec3(_1168.x ? _1014.x : _1170.x, _1168.y ? _1014.y : _1170.y, _1168.z ? _1014.z : _1170.z), vec3(2.400000095367431640625)), input_color.xyz * vec3(0.077399380505084991455078125), step(input_color.xyz, vec3(0.040449999272823333740234375))), 1.0);
        }
        else
        {
            vec3 baked;
            vec3 albedo;
            if (push.normal0.w > 2.5)
            {
                vec4 _sampled_2 = texture(_1148, input_lightmapUv);
                vec3 _604 = _sampled_2.xyz;
                vec3 _1019;
                if (_515)
                {
                    _1019 = _604;
                }
                else
                {
                    vec3 _1034 = (_604 + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375);
                    bvec3 _1172 = isnan(_1034);
                    bvec3 _1173 = isnan(vec3(0.0));
                    vec3 _1174 = max(_1034, vec3(0.0));
                    vec3 _1175 = vec3(_1172.x ? vec3(0.0).x : _1174.x, _1172.y ? vec3(0.0).y : _1174.y, _1172.z ? vec3(0.0).z : _1174.z);
                    _1019 = mix(pow(vec3(_1173.x ? _1034.x : _1175.x, _1173.y ? _1034.y : _1175.y, _1173.z ? _1034.z : _1175.z), vec3(2.400000095367431640625)), _604 * vec3(0.077399380505084991455078125), step(_604, vec3(0.040449999272823333740234375)));
                }
                baked = vec3(push.material.w, push.material.w, push.material.w);
                albedo = albedo_1 * _1019;
            }
            else
            {
                baked = _987 * push.material.w;
                albedo = albedo_1;
            }
            vec3 _621 = normalize(input_worldNormal);
            if (push.normal0.w > 0.100000001490116119384765625)
            {
                _392 = push.normal0.w < 0.5;
            }
            else
            {
                _392 = false;
            }
            if (_392)
            {
                vec3 sunDirection = vec3(cSunDirectionX, cSunDirectionY, cSunDirectionZ);
                if (dot(sunDirection, sunDirection) > 9.9999999392252902907785028219223e-09)
                {
                    float _642 = dot(_621, normalize(sunDirection));
                    baked = clamp(vec3(cSunAmbientRed, cSunAmbientGreen, cSunAmbientBlue) + (vec3(cSunRed, cSunGreen, cSunBlue) * (isnan(0.0) ? _642 : (isnan(_642) ? 0.0 : max(_642, 0.0)))), vec3(0.0), vec3(1.0));
                }
            }
            bool matte = push.normal0.w < (-0.5);
            vec3 normal;
            float roughness;
            float occlusion;
            if (frame.surface.x > 0.0)
            {
                vec4 _sampled_3 = texture(_1150, input_diffuseUv);
                vec3 _677 = vec3((_sampled_3.xy * 2.0) - vec2(1.0), 0.0);
                vec2 _680 = _677.xy;
                float _682 = 1.0 - dot(_680, _680);
                _677.z = sqrt(isnan(0.0) ? _682 : (isnan(_682) ? 0.0 : max(_682, 0.0)));
                vec2 _1071 = dFdx(input_diffuseUv);
                vec2 _1074 = dFdy(input_diffuseUv);
                vec3 _1044 = cross(dFdy(input_surfacePosition), _621);
                vec3 _1045 = cross(_621, dFdx(input_surfacePosition));
                vec3 _1050 = (_1044 * _1071.x) + (_1045 * _1074.x);
                vec3 _1055 = (_1044 * _1071.y) + (_1045 * _1074.y);
                float _1056 = dot(_1050, _1050);
                float _1057 = dot(_1055, _1055);
                float _1058 = isnan(_1057) ? _1056 : (isnan(_1056) ? _1057 : max(_1056, _1057));
                float _1060 = inversesqrt(isnan(9.9999999392252902907785028219223e-09) ? _1058 : (isnan(_1058) ? 9.9999999392252902907785028219223e-09 : max(_1058, 9.9999999392252902907785028219223e-09)));
                normal = normalize(mix(_621, (((_1050 * _1060) * _677.x) + ((_1055 * _1060) * _677.y)) + (_621 * _677.z), vec3(frame.surface.x)));
                roughness = clamp(push.material.x * mix(1.0, _sampled_3.z * 2.0, clamp(frame.surface.x, 0.0, 1.0)), 0.0199999995529651641845703125, 1.0);
                occlusion = _sampled_3.w;
            }
            else
            {
                normal = _621;
                roughness = push.material.x;
                occlusion = 1.0;
            }
            if (frame.surface.y != 1.0)
            {
                _392 = !matte;
            }
            else
            {
                _392 = false;
            }
            if (_392)
            {
                float _801 = roughness * mix(1.0, frame.surface.y, smoothstep(0.550000011920928955078125, 0.85000002384185791015625, clamp(normal.z, 0.0, 1.0)));
                roughness = isnan(1.0) ? _801 : (isnan(_801) ? 1.0 : min(_801, 1.0));
            }
            vec3 _1077 = dFdx(normal);
            vec3 _1080 = dFdy(normal);
            float _814 = roughness;
            float _817 = (dot(_1077, _1077) + dot(_1080, _1080)) * 0.5;
            float _820 = (_814 * _814) + (isnan(0.180000007152557373046875) ? _817 : (isnan(_817) ? 0.180000007152557373046875 : min(_817, 0.180000007152557373046875)));
            _1115 = vec4(albedo, occlusion);
            _1116 = vec4((normalize(normal) * 0.5) + vec3(0.5), 0.0);
            int shadingModel;
            if (push.material.z > 0.0)
            {
                shadingModel = 0;
            }
            else
            {
                shadingModel = 1;
            }
            if (shadingModel == 0)
            {
                roughness = (128.0 + (clamp(push.material.z, 0.0625, 7.9375) * 16.0)) * 0.0039215688593685626983642578125;
            }
            else
            {
                roughness = 0.5;
            }
            float specular;
            if (push.normal0.w > 0.5)
            {
                specular = 0.0;
                roughness = 1.0;
            }
            else
            {
                specular = roughness;
                roughness = sqrt(isnan(_820) ? 1.0 : (isnan(1.0) ? _820 : min(1.0, _820)));
            }
            if (matte)
            {
                _392 = shadingModel == 1;
            }
            else
            {
                _392 = false;
            }
            float metallic;
            if (_392)
            {
                metallic = 0.0;
                specular = 0.0;
                roughness = 1.0;
                shadingModel |= 16;
            }
            else
            {
                metallic = push.material.y;
            }
            entryPointParam_fragmentMain_baseColour = _1115;
            entryPointParam_fragmentMain_normal = _1116;
            entryPointParam_fragmentMain_material = vec4(metallic, specular, isnan(0.015625) ? roughness : (isnan(roughness) ? 0.015625 : max(roughness, 0.015625)), float(shadingModel) * 0.0039215688593685626983642578125);
            entryPointParam_fragmentMain_baked = vec4(baked, 1.0);
        }
    }
}

