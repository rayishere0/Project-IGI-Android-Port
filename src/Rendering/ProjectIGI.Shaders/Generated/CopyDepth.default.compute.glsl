#version 430
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(binding = 0, r32f) uniform restrict writeonly image2D uPreviousDepth;
layout(binding = 0) uniform sampler2D _80;

void main()
{
    {
        uvec2 _vecSize = uvec2(imageSize(uPreviousDepth));
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
            imageStore(uPreviousDepth, ivec2(gl_GlobalInvocationID.xy), vec4(texelFetch(_80, ivec3(ivec2(gl_GlobalInvocationID.xy), 0).xy, 0).x, 0.0, 0.0, 0.0));
        }
    }
}

