#version 430
layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

layout(binding = 0, std140) uniform Params_std140
{
    vec4 size;
    vec4 control;
} p;

layout(binding = 0, rgba16f) uniform restrict writeonly image2D uTarget;
layout(binding = 3) uniform sampler2D _603;
layout(binding = 0) uniform sampler2D _605;
layout(binding = 1) uniform sampler2D _607;
layout(binding = 2) uniform sampler2D _609;

shared uint sGroupSamples;

void main()
{
    {
        ivec2 _91 = ivec2(gl_GlobalInvocationID.xy);
        vec2 _93 = vec2(_91);
        float _460 = fract(52.98291778564453125 * fract((0.067110560834407806396484375 * _93.x) + (0.005837149918079376220703125 * _93.y)));
        vec2 _467 = _93 + vec2(12.0780429840087890625, 9.1174449920654296875);
        vec4 _sampled = textureLod(_603, clamp(((_93 * vec2(0.0625)) + ((vec2(_460, fract(52.98291778564453125 * fract((0.067110560834407806396484375 * _467.x) + (0.005837149918079376220703125 * _467.y)))) - vec2(0.5)) * 0.5)) / p.control.xy, vec2(0.0), vec2(1.0) - (vec2(0.5) / p.control.xy)), 0.0);
        vec2 fastest = _sampled.zw;
        vec2 slowest = _sampled.xy;
        float _162 = length(fastest);
        if (gl_LocalInvocationIndex == 0u)
        {
            atomicExchange(sGroupSamples, 0u);
        }
        barrier();
        uint _183 = atomicMax(sGroupSamples, uint(clamp(4.0 * ceil(_162 * 0.25), 4.0, p.control.z)));
        barrier();
        uint samples = atomicAdd(sGroupSamples, 0u);
        uint halfSamples = samples / 2u;
        bool _33;
        if (_91.x >= int(p.size.x))
        {
            _33 = true;
        }
        else
        {
            _33 = _91.y >= int(p.size.y);
        }
        if (!(_33))
        {
            vec2 uv = (_93 + vec2(0.5)) * p.size.zw;
            vec4 _sampled_1 = textureLod(_605, uv, 0.0);
            if (_162 < 0.5)
            {
                imageStore(uTarget, ivec2(gl_GlobalInvocationID.xy), _sampled_1);
            }
            else
            {
                vec2 _226 = fastest * p.size.zw;
                float _227 = float(samples);
                float _230 = clamp((_162 / _227) - 1.0, 0.0, 1.0);
                float sides = float(halfSamples);
                uint s;
                vec4 colour;
                if (dot(slowest, slowest) > ((0.4000000059604644775390625 * _162) * _162))
                {
                    s = 0u;
                    colour = vec4(0.0);
                    for (;;)
                    {
                        if (!(s < halfSamples))
                        {
                            break;
                        }
                        uint _244 = s;
                        float _245 = float(_244);
                        vec2 _253 = clamp(uv + (_226 * ((_245 + _460) / sides)), vec2(0.0), vec2(1.0));
                        vec2 _279 = clamp(uv - (_226 * (((_245 + 1.0) - _460) / sides)), vec2(0.0), vec2(1.0));
                        s++;
                        colour = (colour + mix(textureLod(_605, _253, 0.0), textureLod(_607, _253, 0.0), vec4(_230))) + mix(textureLod(_605, _279, 0.0), textureLod(_607, _279, 0.0), vec4(_230));
                        continue;
                    }
                    imageStore(uTarget, ivec2(gl_GlobalInvocationID.xy), colour * (1.0 / _227));
                }
                else
                {
                    vec4 _sampled_2 = textureLod(_609, uv, 0.0);
                    float _303 = sides / _162;
                    s = 0u;
                    colour = vec4(0.0);
                    float weightSum = 0.0;
                    float usedAhead;
                    bool _41;
                    float usedBehind;
                    for (;;)
                    {
                        if (!(s < halfSamples))
                        {
                            break;
                        }
                        float _312 = float(s);
                        vec2 _320 = clamp(uv + (_226 * ((_312 + _460) / sides)), vec2(0.0), vec2(1.0));
                        vec2 _325 = clamp(uv - (_226 * (((_312 + 1.0) - _460) / sides)), vec2(0.0), vec2(1.0));
                        vec4 _sampled_3 = textureLod(_609, _320, 0.0);
                        vec4 _sampled_4 = textureLod(_609, _325, 0.0);
                        float _539 = _sampled_3.z - _sampled_2.z;
                        float _554 = _312 + (-0.5);
                        float _561 = _312 + (-0.5);
                        float _550 = (clamp(0.5 + _539, 0.0, 1.0) * clamp((_303 * _sampled_2.x) - (isnan(0.0) ? _554 : (isnan(_554) ? 0.0 : max(_554, 0.0))), 0.0, 1.0)) + (clamp(0.5 - _539, 0.0, 1.0) * clamp((_303 * _sampled_3.x) - (isnan(0.0) ? _561 : (isnan(_561) ? 0.0 : max(_561, 0.0))), 0.0, 1.0));
                        float _569 = _sampled_4.z - _sampled_2.z;
                        float _584 = _312 + (-0.5);
                        float _591 = _312 + (-0.5);
                        float _580 = (clamp(0.5 + _569, 0.0, 1.0) * clamp((_303 * _sampled_2.x) - (isnan(0.0) ? _584 : (isnan(_584) ? 0.0 : max(_584, 0.0))), 0.0, 1.0)) + (clamp(0.5 - _569, 0.0, 1.0) * clamp((_303 * _sampled_4.x) - (isnan(0.0) ? _591 : (isnan(_591) ? 0.0 : max(_591, 0.0))), 0.0, 1.0));
                        bool furtherAhead = _sampled_3.z > _sampled_4.z;
                        bool slowerAhead = _sampled_3.x < _sampled_4.x;
                        if (furtherAhead)
                        {
                            _33 = slowerAhead;
                        }
                        else
                        {
                            _33 = false;
                        }
                        if (_33)
                        {
                            usedAhead = _580;
                        }
                        else
                        {
                            usedAhead = _550;
                        }
                        if (furtherAhead)
                        {
                            _41 = true;
                        }
                        else
                        {
                            _41 = slowerAhead;
                        }
                        if (_41)
                        {
                            usedBehind = _580;
                        }
                        else
                        {
                            usedBehind = _550;
                        }
                        s++;
                        colour += ((mix(textureLod(_605, _320, 0.0), textureLod(_607, _320, 0.0), vec4(_230)) * usedAhead) + (mix(textureLod(_605, _325, 0.0), textureLod(_607, _325, 0.0), vec4(_230)) * usedBehind));
                        weightSum += (usedAhead + usedBehind);
                        continue;
                    }
                    float normalise = 0.5 / sides;
                    float _433 = 1.0 - (weightSum * normalise);
                    imageStore(uTarget, ivec2(gl_GlobalInvocationID.xy), (colour * normalise) + (_sampled_1 * (isnan(0.0) ? _433 : (isnan(_433) ? 0.0 : max(_433, 0.0)))));
                }
            }
        }
    }
}

