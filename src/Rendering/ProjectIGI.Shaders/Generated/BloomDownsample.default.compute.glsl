#version 430
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(binding = 0, std140) uniform Params_std140
{
    vec4 target;
    vec4 control;
} p;

layout(binding = 0, rgba16f) uniform restrict writeonly image2D uTarget;
layout(binding = 0) uniform sampler2D _154;

void main()
{
    {
        ivec2 _42 = ivec2(gl_GlobalInvocationID.xy);
        ivec2 _49 = ivec2(p.target.xy);
        bool _25;
        if (_42.x >= _49.x)
        {
            _25 = true;
        }
        else
        {
            _25 = _42.y >= _49.y;
        }
        if (!(_25))
        {
            vec2 uv = (vec2(_42) + vec2(0.5)) * p.target.zw;
            vec2 offset = p.target.zw * 0.5;
            float _75 = offset.x;
            float _76 = -_75;
            float _77 = offset.y;
            float _78 = -_77;
            vec3 _116 = (((textureLod(_154, uv + vec2(_76, _78), 0.0).xyz + textureLod(_154, uv + vec2(_75, _78), 0.0).xyz) + textureLod(_154, uv + vec2(_76, _77), 0.0).xyz) + textureLod(_154, uv + offset, 0.0).xyz) * 0.25;
            bvec3 _156 = isnan(_116);
            bvec3 _157 = isnan(vec3(0.0));
            vec3 _158 = max(_116, vec3(0.0));
            vec3 _159 = vec3(_156.x ? vec3(0.0).x : _158.x, _156.y ? vec3(0.0).y : _158.y, _156.z ? vec3(0.0).z : _158.z);
            vec3 _118 = vec3(_157.x ? _116.x : _159.x, _157.y ? _116.y : _159.y, _157.z ? _116.z : _159.z);
            vec3 colour;
            if (p.control.x > 0.0)
            {
                colour = _118 * clamp((dot(_118, vec3(0.300000011920928955078125, 0.589999973773956298828125, 0.10999999940395355224609375)) - p.control.x) * 0.5, 0.0, 1.0);
            }
            else
            {
                colour = _118;
            }
            imageStore(uTarget, ivec2(gl_GlobalInvocationID.xy), vec4(colour, 1.0));
        }
    }
}

