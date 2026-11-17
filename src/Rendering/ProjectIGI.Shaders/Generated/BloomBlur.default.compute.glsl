#version 430
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(binding = 0, std140) uniform Params_std140
{
    vec4 size;
    vec4 control;
} p;

layout(binding = 0, rgba16f) uniform restrict writeonly image2D uTarget;
layout(binding = 0) uniform sampler2D _142;

void main()
{
    {
        ivec2 _36 = ivec2(gl_GlobalInvocationID.xy);
        ivec2 _43 = ivec2(p.size.xy);
        bool _25;
        if (_36.x >= _43.x)
        {
            _25 = true;
        }
        else
        {
            _25 = _36.y >= _43.y;
        }
        if (!(_25))
        {
            vec2 uv = (vec2(_36) + vec2(0.5)) * p.size.zw;
            vec2 step = p.control.xy * p.size.zw;
            vec2 _84 = step * 1.384615421295166015625;
            vec2 _105 = step * 3.23076915740966796875;
            vec3 sum = ((((textureLod(_142, uv, 0.0).xyz * 0.2270270287990570068359375) + (textureLod(_142, uv + _84, 0.0).xyz * 0.3162162303924560546875)) + (textureLod(_142, uv - _84, 0.0).xyz * 0.3162162303924560546875)) + (textureLod(_142, uv + _105, 0.0).xyz * 0.0702702701091766357421875)) + (textureLod(_142, uv - _105, 0.0).xyz * 0.0702702701091766357421875);
            bvec3 _144 = isnan(sum);
            bvec3 _145 = isnan(vec3(0.0));
            vec3 _146 = max(sum, vec3(0.0));
            vec3 _147 = vec3(_144.x ? vec3(0.0).x : _146.x, _144.y ? vec3(0.0).y : _146.y, _144.z ? vec3(0.0).z : _146.z);
            imageStore(uTarget, ivec2(gl_GlobalInvocationID.xy), vec4(vec3(_145.x ? sum.x : _147.x, _145.y ? sum.y : _147.y, _145.z ? sum.z : _147.z), 1.0));
        }
    }
}

