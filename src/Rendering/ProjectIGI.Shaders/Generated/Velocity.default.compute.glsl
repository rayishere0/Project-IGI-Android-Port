#version 430
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(binding = 0, std140) uniform Params_std140
{
    layout(row_major) mat4 viewToWorld;
    layout(row_major) mat4 prevWorldToView;
    vec4 unproject;
    vec4 resolution;
    vec4 cameraDelta;
    vec4 prevProjection;
    vec4 jitter;
} p;

layout(binding = 0, rg16f) uniform restrict writeonly image2D uVelocity;
layout(binding = 0) uniform sampler2D _298;

mat4 spvWorkaroundRowMajor(mat4 wrap) { return wrap; }

void main()
{
    {
        ivec2 _45 = ivec2(gl_GlobalInvocationID.xy);
        ivec2 _52 = ivec2(p.resolution.xy);
        bool _26;
        if (_45.x >= _52.x)
        {
            _26 = true;
        }
        else
        {
            _26 = _45.y >= _52.y;
        }
        if (!(_26))
        {
            vec2 rasterUv = (vec2(_45) + vec2(0.5)) * p.resolution.zw;
            vec4 _sampled = textureLod(_298, rasterUv, 0.0);
            float depth = _sampled.x;
            if (depth <= 0.0)
            {
                vec2 skyUv = rasterUv - (p.jitter.xy * p.resolution.zw);
                vec2 ndc = (skyUv * 2.0) - vec2(1.0);
                vec4 _122 = vec4((vec4(vec3(ndc.x / p.unproject.x, (-ndc.y) / p.unproject.y, 1.0), 0.0) * spvWorkaroundRowMajor(p.viewToWorld)).xyz, 0.0) * spvWorkaroundRowMajor(p.prevWorldToView);
                float _124 = _122.z;
                if (_124 <= 9.9999997473787516355514526367188e-05)
                {
                    imageStore(uVelocity, ivec2(gl_GlobalInvocationID.xy), vec4(0.0));
                }
                else
                {
                    imageStore(uVelocity, ivec2(gl_GlobalInvocationID.xy), vec4(skyUv - ((vec2((_122.x * p.prevProjection.x) / _124, ((-_122.y) * p.prevProjection.y) / _124) * 0.5) + vec2(0.5)), 0.0, 0.0));
                }
            }
            else
            {
                if (depth >= 0.89999997615814208984375)
                {
                    imageStore(uVelocity, ivec2(gl_GlobalInvocationID.xy), vec4(0.0));
                }
                else
                {
                    vec2 currentUv = rasterUv - (p.jitter.xy * p.resolution.zw);
                    float _294 = ((2.0 * p.unproject.z) * p.unproject.w) / ((p.unproject.w + p.unproject.z) - ((1.0 - (2.0 * depth)) * (p.unproject.w - p.unproject.z)));
                    vec2 _270 = (currentUv * 2.0) - vec2(1.0);
                    vec4 _225 = vec4((vec4(vec3((_270.x * _294) / p.unproject.x, ((-_270.y) * _294) / p.unproject.y, _294), 0.0) * spvWorkaroundRowMajor(p.viewToWorld)).xyz + p.cameraDelta.xyz, 0.0) * spvWorkaroundRowMajor(p.prevWorldToView);
                    float _227 = _225.z;
                    if (_227 <= p.prevProjection.z)
                    {
                        imageStore(uVelocity, ivec2(gl_GlobalInvocationID.xy), vec4(0.0));
                    }
                    else
                    {
                        imageStore(uVelocity, ivec2(gl_GlobalInvocationID.xy), vec4(currentUv - ((vec2((_225.x * p.prevProjection.x) / _227, ((-_225.y) * p.prevProjection.y) / _227) * 0.5) + vec2(0.5)), 0.0, 0.0));
                    }
                }
            }
        }
    }
}

