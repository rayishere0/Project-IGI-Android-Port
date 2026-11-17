#version 430
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(binding = 0, std140) uniform Params_std140
{
    vec4 size;
    vec4 range;
} p;

layout(binding = 0, std430) restrict buffer RWStructuredBuffer
{
    uint _member0[];
} uBins;

layout(binding = 0) uniform sampler2D _214;
layout(binding = 1) uniform sampler2D _217;

shared uint sHistogram[64];

void main()
{
    atomicExchange(sHistogram[gl_LocalInvocationIndex], 0u);
    barrier();
    ivec2 _72 = ivec2(gl_GlobalInvocationID.xy);
    bool _29;
    if (_72.x < int(p.size.x))
    {
        _29 = _72.y < int(p.size.y);
    }
    else
    {
        _29 = false;
    }
    if (_29)
    {
        uvec2 _vecSize = uvec2(textureSize(_217, 0));
        if (texelFetch(_217, ivec3(ivec2(((vec2(_72) + vec2(0.5)) * vec2(float(_vecSize.x), float(_vecSize.y))) / p.size.xy), 0).xy, 0).w >= 0.5)
        {
            float _130 = dot(texelFetch(_214, ivec3(_72, 0).xy, 0).xyz, vec3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875));
            float position = clamp((p.range.x * log2(isnan(p.range.z) ? _130 : (isnan(_130) ? p.range.z : max(_130, p.range.z)))) + p.range.y, 0.0, 1.0) * 63.0;
            uint low = uint(position);
            float _157 = fract(position);
            if (low == 0u)
            {
                _29 = _130 <= 1.0000000116860974230803549289703e-07;
            }
            else
            {
                _29 = false;
            }
            float lower;
            if (_29)
            {
                lower = 0.0;
            }
            else
            {
                lower = 1.0 - _157;
            }
            uint lowCount = uint((lower * p.range.w) + 0.5);
            uint highCount = uint((_157 * p.range.w) + 0.5);
            if (lowCount > 0u)
            {
                uint _187 = atomicAdd(sHistogram[low], lowCount);
            }
            if (highCount > 0u)
            {
                uint _192 = atomicAdd(sHistogram[min((low + 1u), 63u)], highCount);
            }
        }
    }
    barrier();
    uint total = atomicAdd(sHistogram[gl_LocalInvocationIndex], 0u);
    if (total > 0u)
    {
        uint _205 = atomicAdd(uBins._member0[gl_LocalInvocationIndex], total);
    }
}

