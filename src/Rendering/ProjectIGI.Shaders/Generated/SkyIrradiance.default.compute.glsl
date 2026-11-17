#version 430
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(binding = 0, std140) uniform Params_std140
{
    vec4 size;
    vec4 sunDir;
    vec4 sunColour;
    vec4 misc;
    vec4 moonDir;
    vec4 moonColour;
} p;

layout(binding = 0, rgba32f) uniform restrict writeonly image2D uIrradiance;
layout(binding = 0) uniform sampler2D _645;
layout(binding = 1) uniform sampler2D _647;

shared vec3 sCoefficients[64][9];

void main()
{
    {
        uint index = (gl_LocalInvocationID.y * 8u) + gl_LocalInvocationID.x;
        vec2 e = (vec2(gl_LocalInvocationID.xy) + vec2(0.5)) * vec2(0.125);
        float phi = 6.283185482025146484375 * e.x;
        float cosTheta = 1.0 - (2.0 * e.y);
        float _107 = 1.0 - (cosTheta * cosTheta);
        float _111 = sqrt(isnan(_107) ? 0.0 : (isnan(0.0) ? _107 : max(0.0, _107)));
        float _113 = _111 * cos(phi);
        float _115 = _111 * sin(phi);
        float _554 = (p.misc.x * p.misc.x) - 40449600.0;
        float _559 = acos(clamp(sqrt(isnan(_554) ? 0.0 : (isnan(0.0) ? _554 : max(0.0, _554))) / p.misc.x, -1.0, 1.0));
        float _560 = 3.1415927410125732421875 - _559;
        float _563 = acos(clamp(cosTheta, -1.0, 1.0));
        float _548;
        if (_563 < _560)
        {
            float _575 = 1.0 - (_563 / _560);
            _548 = (1.0 - sqrt(isnan(_575) ? 0.0 : (isnan(0.0) ? _575 : max(0.0, _575)))) * 0.5;
        }
        else
        {
            float _568 = (_563 - _560) / (isnan(9.9999999747524270787835121154785e-07) ? _559 : (isnan(_559) ? 9.9999999747524270787835121154785e-07 : max(_559, 9.9999999747524270787835121154785e-07)));
            _548 = (sqrt(isnan(_568) ? 0.0 : (isnan(0.0) ? _568 : max(0.0, _568))) * 0.5) + 0.5;
        }
        float _583 = atan(_115, _113);
        float _549;
        if (_583 < 0.0)
        {
            _549 = _583 + 6.283185482025146484375;
        }
        else
        {
            _549 = _583;
        }
        uvec2 _598 = uvec2(textureSize(_645, 0));
        vec2 _605 = vec2(float(_598.x), float(_598.y));
        vec3 _240 = (textureLod(_647, (vec2(_549 * 0.15915493667125701904296875, _548) * ((_605 - vec2(1.0)) / _605)) + (vec2(0.5) / _605), 0.0).xyz * 0.19634954631328582763671875) * p.misc.y;
        float basis[9];
        basis[0] = 0.2820949852466583251953125;
        basis[1] = (-0.48860299587249755859375) * _115;
        basis[2] = 0.48860299587249755859375 * cosTheta;
        basis[3] = (-0.48860299587249755859375) * _113;
        basis[4] = (1.09254801273345947265625 * _113) * _115;
        basis[5] = ((-1.09254801273345947265625) * _115) * cosTheta;
        basis[6] = 0.3153919875621795654296875 * (((3.0 * cosTheta) * cosTheta) - 1.0);
        basis[7] = ((-1.09254801273345947265625) * _113) * cosTheta;
        basis[8] = 0.546274006366729736328125 * ((_113 * _113) - (_115 * _115));
        int i = 0;
        for (;;)
        {
            if (!(i < 9))
            {
                break;
            }
            sCoefficients[index][i] = _240 * basis[i];
            i++;
            continue;
        }
        barrier();
        uint stride = 32u;
        for (;;)
        {
            if (!(stride > 0u))
            {
                break;
            }
            if (index < stride)
            {
                i = 0;
                for (;;)
                {
                    if (!(i < 9))
                    {
                        break;
                    }
                    sCoefficients[index][i] += sCoefficients[index + stride][i];
                    i++;
                    continue;
                }
            }
            barrier();
            stride = stride >> 1u;
            continue;
        }
        if (!(index != 0u))
        {
            i = 0;
            vec3 c[9];
            for (;;)
            {
                if (!(i < 9))
                {
                    break;
                }
                c[i] = sCoefficients[0][i];
                i++;
                continue;
            }
            imageStore(uIrradiance, ivec2(uvec2(0u)), vec4((-0.3257350027561187744140625) * c[3].x, (-0.3257350027561187744140625) * c[1].x, 0.3257350027561187744140625 * c[2].x, (0.2820948064327239990234375 * c[0].x) - (0.07884784042835235595703125 * c[6].x)));
            imageStore(uIrradiance, ivec2(uvec2(1u, 0u)), vec4((-0.3257350027561187744140625) * c[3].y, (-0.3257350027561187744140625) * c[1].y, 0.3257350027561187744140625 * c[2].y, (0.2820948064327239990234375 * c[0].y) - (0.07884784042835235595703125 * c[6].y)));
            imageStore(uIrradiance, ivec2(uvec2(2u, 0u)), vec4((-0.3257350027561187744140625) * c[3].z, (-0.3257350027561187744140625) * c[1].z, 0.3257350027561187744140625 * c[2].z, (0.2820948064327239990234375 * c[0].z) - (0.07884784042835235595703125 * c[6].z)));
            imageStore(uIrradiance, ivec2(uvec2(3u, 0u)), vec4(0.2731371223926544189453125 * c[4].x, (-0.2731371223926544189453125) * c[5].x, 0.23654352128505706787109375 * c[6].x, (-0.2731371223926544189453125) * c[7].x));
            imageStore(uIrradiance, ivec2(uvec2(4u, 0u)), vec4(0.2731371223926544189453125 * c[4].y, (-0.2731371223926544189453125) * c[5].y, 0.23654352128505706787109375 * c[6].y, (-0.2731371223926544189453125) * c[7].y));
            imageStore(uIrradiance, ivec2(uvec2(5u, 0u)), vec4(0.2731371223926544189453125 * c[4].z, (-0.2731371223926544189453125) * c[5].z, 0.23654352128505706787109375 * c[6].z, (-0.2731371223926544189453125) * c[7].z));
            imageStore(uIrradiance, ivec2(uvec2(6u, 0u)), vec4(0.13656856119632720947265625 * c[8].x, 0.13656856119632720947265625 * c[8].y, 0.13656856119632720947265625 * c[8].z, 1.0));
            imageStore(uIrradiance, ivec2(uvec2(7u, 0u)), vec4(c[0] * 0.28209459781646728515625, 1.0));
        }
    }
}

