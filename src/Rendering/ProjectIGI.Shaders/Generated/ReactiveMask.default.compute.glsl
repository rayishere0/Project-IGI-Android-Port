#version 430
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(binding = 0, r32f) uniform restrict writeonly image2D uMask;
layout(binding = 0) uniform sampler2D _87;

void main()
{
    {
        uvec2 _vecSize = uvec2(imageSize(uMask));
        uint height = _vecSize.y;
        bool _21;
        if (gl_GlobalInvocationID.x >= _vecSize.x)
        {
            _21 = true;
        }
        else
        {
            _21 = gl_GlobalInvocationID.y >= height;
        }
        if (!(_21))
        {
            imageStore(uMask, ivec2(gl_GlobalInvocationID.xy), vec4(clamp((texelFetch(_87, ivec3(ivec2(gl_GlobalInvocationID.xy), 0).xy, 0).w - 1.0) * 4.0, 0.0, 1.0), 0.0, 0.0, 0.0));
        }
    }
}

