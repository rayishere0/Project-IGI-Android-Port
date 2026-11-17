#version 430
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(binding = 0, std140) uniform Params_std140
{
    vec4 size;
} p;

layout(binding = 0, r8) uniform restrict writeonly image2D uBlend;
layout(binding = 0) uniform sampler2D _348;

shared float sMedian[100];

void main()
{
    {
        ivec2 _74 = ivec2(gl_GlobalInvocationID.xy);
        ivec2 _81 = ivec2(p.size.xy);
        ivec2 _88 = (ivec2(gl_WorkGroupID.xy) * ivec2(8)) - ivec2(1);
        uint i = gl_LocalInvocationIndex;
        float _277[3];
        for (;;)
        {
            if (!(i < 100u))
            {
                break;
            }
            int _98 = int(i);
            ivec2 _110 = _88 + ivec2(_98 - 10 * (_98 / 10), _98 / 10);
            int _278 = -1;
            for (;;)
            {
                if (!(_278 <= 1))
                {
                    break;
                }
                ivec2 _293 = _81 - ivec2(1);
                vec4 _298 = texelFetch(_348, ivec3(clamp(_110 + ivec2(-1, _278), ivec2(0), _293), 0).xy, 0);
                float _300 = _298.x;
                vec4 _308 = texelFetch(_348, ivec3(clamp(_110 + ivec2(0, _278), ivec2(0), _293), 0).xy, 0);
                float _310 = _308.x;
                vec4 _318 = texelFetch(_348, ivec3(clamp(_110 + ivec2(1, _278), ivec2(0), _293), 0).xy, 0);
                float _320 = _318.x;
                int _322 = _278 + 1;
                float _324 = isnan(_310) ? _300 : (isnan(_300) ? _310 : min(_300, _310));
                float _325 = isnan(_310) ? _300 : (isnan(_300) ? _310 : max(_300, _310));
                float _326 = isnan(_320) ? _325 : (isnan(_325) ? _320 : min(_325, _320));
                _277[_322] = isnan(_326) ? _324 : (isnan(_324) ? _326 : max(_324, _326));
                _278 = _322;
                continue;
            }
            float _338 = isnan(_277[1]) ? _277[0] : (isnan(_277[0]) ? _277[1] : min(_277[0], _277[1]));
            float _339 = isnan(_277[1]) ? _277[0] : (isnan(_277[0]) ? _277[1] : max(_277[0], _277[1]));
            float _340 = isnan(_277[2]) ? _339 : (isnan(_339) ? _277[2] : min(_339, _277[2]));
            sMedian[i] = isnan(_340) ? _338 : (isnan(_338) ? _340 : max(_338, _340));
            i += 64u;
            continue;
        }
        barrier();
        bool _28;
        if (_74.x >= _81.x)
        {
            _28 = true;
        }
        else
        {
            _28 = _74.y >= _81.y;
        }
        if (!(_28))
        {
            ivec2 _227 = ivec2(gl_LocalInvocationID.xy) + ivec2(1);
            float blend = 1.0;
            int y = -1;
            for (;;)
            {
                if (!(y <= 1))
                {
                    break;
                }
                int x = -1;
                for (;;)
                {
                    if (!(x <= 1))
                    {
                        break;
                    }
                    int _245 = (((_227.y + y) * 10) + _227.x) + x;
                    blend = isnan(sMedian[_245]) ? blend : (isnan(blend) ? sMedian[_245] : min(blend, sMedian[_245]));
                    x++;
                    continue;
                }
                y++;
                continue;
            }
            imageStore(uBlend, ivec2(gl_GlobalInvocationID.xy), vec4(blend, 0.0, 0.0, 0.0));
        }
    }
}

