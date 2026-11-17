#version 430
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(binding = 0, std140) uniform Params_std140
{
    vec4 size;
    vec4 control;
} p;

layout(binding = 0, rg16f) uniform restrict writeonly image2D uOffset;
layout(binding = 0) uniform sampler2D _861;
layout(binding = 1) uniform sampler2D _863;

void main()
{
    {
        ivec2 _135 = ivec2(gl_GlobalInvocationID.xy);
        ivec2 _142 = ivec2(p.size.xy);
        bool doneP;
        if (_135.x >= _142.x)
        {
            doneP = true;
        }
        else
        {
            doneP = _135.y >= _142.y;
        }
        if (!(doneP))
        {
            vec3 _617 = texelFetch(_861, ivec3(clamp(_135, ivec2(0), _142 - ivec2(1)), 0).xy, 0).xyz;
            bvec3 _865 = isnan(_617);
            bvec3 _866 = isnan(vec3(0.0));
            vec3 _867 = max(_617, vec3(0.0));
            vec3 _868 = vec3(_865.x ? vec3(0.0).x : _867.x, _865.y ? vec3(0.0).y : _867.y, _865.z ? vec3(0.0).z : _867.z);
            float _623 = dot(vec3(_866.x ? _617.x : _868.x, _866.y ? _617.y : _868.y, _866.z ? _617.z : _868.z) * p.control.x, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));
            float _625 = _623 / (0.5 + _623);
            vec3 _639 = texelFetch(_861, ivec3(clamp(_135 + ivec2(0, -1), ivec2(0), _142 - ivec2(1)), 0).xy, 0).xyz;
            bvec3 _870 = isnan(_639);
            bvec3 _871 = isnan(vec3(0.0));
            vec3 _872 = max(_639, vec3(0.0));
            vec3 _873 = vec3(_870.x ? vec3(0.0).x : _872.x, _870.y ? vec3(0.0).y : _872.y, _870.z ? vec3(0.0).z : _872.z);
            float _645 = dot(vec3(_871.x ? _639.x : _873.x, _871.y ? _639.y : _873.y, _871.z ? _639.z : _873.z) * p.control.x, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));
            float _647 = _645 / (0.5 + _645);
            vec3 _661 = texelFetch(_861, ivec3(clamp(_135 + ivec2(0, 1), ivec2(0), _142 - ivec2(1)), 0).xy, 0).xyz;
            bvec3 _875 = isnan(_661);
            bvec3 _876 = isnan(vec3(0.0));
            vec3 _877 = max(_661, vec3(0.0));
            vec3 _878 = vec3(_875.x ? vec3(0.0).x : _877.x, _875.y ? vec3(0.0).y : _877.y, _875.z ? vec3(0.0).z : _877.z);
            float _667 = dot(vec3(_876.x ? _661.x : _878.x, _876.y ? _661.y : _878.y, _876.z ? _661.z : _878.z) * p.control.x, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));
            float _669 = _667 / (0.5 + _667);
            vec3 _683 = texelFetch(_861, ivec3(clamp(_135 + ivec2(1, 0), ivec2(0), _142 - ivec2(1)), 0).xy, 0).xyz;
            bvec3 _880 = isnan(_683);
            bvec3 _881 = isnan(vec3(0.0));
            vec3 _882 = max(_683, vec3(0.0));
            vec3 _883 = vec3(_880.x ? vec3(0.0).x : _882.x, _880.y ? vec3(0.0).y : _882.y, _880.z ? vec3(0.0).z : _882.z);
            float _689 = dot(vec3(_881.x ? _683.x : _883.x, _881.y ? _683.y : _883.y, _881.z ? _683.z : _883.z) * p.control.x, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));
            float _691 = _689 / (0.5 + _689);
            vec3 _705 = texelFetch(_861, ivec3(clamp(_135 + ivec2(-1, 0), ivec2(0), _142 - ivec2(1)), 0).xy, 0).xyz;
            bvec3 _885 = isnan(_705);
            bvec3 _886 = isnan(vec3(0.0));
            vec3 _887 = max(_705, vec3(0.0));
            vec3 _888 = vec3(_885.x ? vec3(0.0).x : _887.x, _885.y ? vec3(0.0).y : _887.y, _885.z ? vec3(0.0).z : _887.z);
            float _711 = dot(vec3(_886.x ? _705.x : _888.x, _886.y ? _705.y : _888.y, _886.z ? _705.z : _888.z) * p.control.x, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));
            float _713 = _711 / (0.5 + _711);
            vec3 _727 = texelFetch(_861, ivec3(clamp(_135 + ivec2(1, -1), ivec2(0), _142 - ivec2(1)), 0).xy, 0).xyz;
            bvec3 _890 = isnan(_727);
            bvec3 _891 = isnan(vec3(0.0));
            vec3 _892 = max(_727, vec3(0.0));
            vec3 _893 = vec3(_890.x ? vec3(0.0).x : _892.x, _890.y ? vec3(0.0).y : _892.y, _890.z ? vec3(0.0).z : _892.z);
            float _733 = dot(vec3(_891.x ? _727.x : _893.x, _891.y ? _727.y : _893.y, _891.z ? _727.z : _893.z) * p.control.x, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));
            float _735 = _733 / (0.5 + _733);
            vec3 _749 = texelFetch(_861, ivec3(clamp(_135 + ivec2(-1), ivec2(0), _142 - ivec2(1)), 0).xy, 0).xyz;
            bvec3 _895 = isnan(_749);
            bvec3 _896 = isnan(vec3(0.0));
            vec3 _897 = max(_749, vec3(0.0));
            vec3 _898 = vec3(_895.x ? vec3(0.0).x : _897.x, _895.y ? vec3(0.0).y : _897.y, _895.z ? vec3(0.0).z : _897.z);
            float _755 = dot(vec3(_896.x ? _749.x : _898.x, _896.y ? _749.y : _898.y, _896.z ? _749.z : _898.z) * p.control.x, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));
            float _757 = _755 / (0.5 + _755);
            vec3 _771 = texelFetch(_861, ivec3(clamp(_135 + ivec2(1), ivec2(0), _142 - ivec2(1)), 0).xy, 0).xyz;
            bvec3 _900 = isnan(_771);
            bvec3 _901 = isnan(vec3(0.0));
            vec3 _902 = max(_771, vec3(0.0));
            vec3 _903 = vec3(_900.x ? vec3(0.0).x : _902.x, _900.y ? vec3(0.0).y : _902.y, _900.z ? vec3(0.0).z : _902.z);
            float _777 = dot(vec3(_901.x ? _771.x : _903.x, _901.y ? _771.y : _903.y, _901.z ? _771.z : _903.z) * p.control.x, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));
            float _779 = _777 / (0.5 + _777);
            vec3 _793 = texelFetch(_861, ivec3(clamp(_135 + ivec2(-1, 1), ivec2(0), _142 - ivec2(1)), 0).xy, 0).xyz;
            bvec3 _905 = isnan(_793);
            bvec3 _906 = isnan(vec3(0.0));
            vec3 _907 = max(_793, vec3(0.0));
            vec3 _908 = vec3(_905.x ? vec3(0.0).x : _907.x, _905.y ? vec3(0.0).y : _907.y, _905.z ? vec3(0.0).z : _907.z);
            float _799 = dot(vec3(_906.x ? _793.x : _908.x, _906.y ? _793.y : _908.y, _906.z ? _793.z : _908.z) * p.control.x, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));
            float _801 = _799 / (0.5 + _799);
            float _225 = isnan(_647) ? _625 : (isnan(_625) ? _647 : min(_625, _647));
            float _226 = isnan(_691) ? _669 : (isnan(_669) ? _691 : min(_669, _691));
            float _227 = isnan(_226) ? _225 : (isnan(_225) ? _226 : min(_225, _226));
            float _228 = isnan(_735) ? _713 : (isnan(_713) ? _735 : min(_713, _735));
            float _229 = isnan(_801) ? _779 : (isnan(_779) ? _801 : min(_779, _801));
            float _230 = isnan(_229) ? _757 : (isnan(_757) ? _229 : min(_757, _229));
            float _231 = isnan(_230) ? _228 : (isnan(_228) ? _230 : min(_228, _230));
            float _233 = isnan(_647) ? _625 : (isnan(_625) ? _647 : max(_625, _647));
            float _234 = isnan(_691) ? _669 : (isnan(_669) ? _691 : max(_669, _691));
            float _235 = isnan(_234) ? _233 : (isnan(_233) ? _234 : max(_233, _234));
            float _236 = isnan(_735) ? _713 : (isnan(_713) ? _735 : max(_713, _735));
            float _237 = isnan(_801) ? _779 : (isnan(_779) ? _801 : max(_779, _801));
            float _238 = isnan(_237) ? _757 : (isnan(_757) ? _237 : max(_757, _237));
            float _239 = isnan(_238) ? _236 : (isnan(_236) ? _238 : max(_236, _238));
            if (((isnan(_239) ? _235 : (isnan(_235) ? _239 : max(_235, _239))) - (isnan(_231) ? _227 : (isnan(_227) ? _231 : min(_227, _231)))) <= 0.0500000007450580596923828125)
            {
                imageStore(uOffset, ivec2(gl_GlobalInvocationID.xy), vec4(0.0));
            }
            else
            {
                float edgeL;
                ivec2 side;
                ivec2 walkDir;
                if (((abs(((_735 + _757) * 0.5) - _647) + abs(((_691 + _713) * 0.5) - _625)) + abs(((_779 + _801) * 0.5) - _669)) > ((abs(((_735 + _779) * 0.5) - _691) + abs(((_647 + _669) * 0.5) - _625)) + abs(((_757 + _801) * 0.5) - _713)))
                {
                    if (abs(_713 - _625) > abs(_691 - _625))
                    {
                        edgeL = _713;
                        side = ivec2(-1, 0);
                    }
                    else
                    {
                        edgeL = _691;
                        side = ivec2(1, 0);
                    }
                    walkDir = ivec2(0, 1);
                }
                else
                {
                    if (abs(_647 - _625) > abs(_669 - _625))
                    {
                        edgeL = _647;
                        side = ivec2(0, -1);
                    }
                    else
                    {
                        edgeL = _669;
                        side = ivec2(0, 1);
                    }
                    walkDir = ivec2(1, 0);
                }
                float _310 = abs(edgeL - _625);
                if ((_310 * 0.5) <= 0.0500000007450580596923828125)
                {
                    imageStore(uOffset, ivec2(gl_GlobalInvocationID.xy), vec4(0.0));
                }
                else
                {
                    vec2 _328 = ((vec2(_135) + vec2(0.5)) + (vec2(side) * 0.5)) * p.size.zw;
                    vec2 _333 = vec2(walkDir) * p.size.zw;
                    float _336 = (edgeL + _625) * 0.5;
                    float _337 = _310 * 0.25;
                    bool brighter = edgeL > _625;
                    doneP = false;
                    bool doneN = false;
                    bool highP = false;
                    bool lowP = false;
                    bool highN = false;
                    bool lowN = false;
                    float lenP = 8.0;
                    float lenN = 8.0;
                    int i = 1;
                    bool incP;
                    bool decP;
                    bool incN;
                    bool decN;
                    float dist;
                    float lenN_1;
                    bool lowN_1;
                    for (;;)
                    {
                        if (!(i <= 8))
                        {
                            break;
                        }
                        if (!doneP)
                        {
                            vec2 _807 = p.size.zw * 0.5;
                            vec3 _819 = textureLod(_863, clamp(_328 + (_333 * float(i)), _807, vec2(1.0) - _807), 0.0).xyz;
                            bvec3 _990 = isnan(_819);
                            bvec3 _991 = isnan(vec3(0.0));
                            vec3 _992 = max(_819, vec3(0.0));
                            vec3 _993 = vec3(_990.x ? vec3(0.0).x : _992.x, _990.y ? vec3(0.0).y : _992.y, _990.z ? vec3(0.0).z : _992.z);
                            float _825 = dot(vec3(_991.x ? _819.x : _993.x, _991.y ? _819.y : _993.y, _991.z ? _819.z : _993.z) * p.control.x, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));
                            float _827 = _825 / (0.5 + _825);
                            if (_827 < (_336 - _337))
                            {
                                incP = true;
                                decP = highP;
                                incN = true;
                                dist = float(i - 1);
                            }
                            else
                            {
                                if (_827 > (_336 + _337))
                                {
                                    incP = true;
                                    decP = true;
                                    dist = float(i - 1);
                                }
                                else
                                {
                                    incP = doneP;
                                    decP = highP;
                                    dist = lenP;
                                }
                                incN = lowP;
                            }
                            lowP = incN;
                        }
                        else
                        {
                            incP = doneP;
                            decP = highP;
                            dist = lenP;
                        }
                        if (!doneN)
                        {
                            vec2 _833 = p.size.zw * 0.5;
                            vec3 _845 = textureLod(_863, clamp(_328 - (_333 * float(i)), _833, vec2(1.0) - _833), 0.0).xyz;
                            bvec3 _995 = isnan(_845);
                            bvec3 _996 = isnan(vec3(0.0));
                            vec3 _997 = max(_845, vec3(0.0));
                            vec3 _998 = vec3(_995.x ? vec3(0.0).x : _997.x, _995.y ? vec3(0.0).y : _997.y, _995.z ? vec3(0.0).z : _997.z);
                            float _851 = dot(vec3(_996.x ? _845.x : _998.x, _996.y ? _845.y : _998.y, _996.z ? _845.z : _998.z) * p.control.x, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));
                            float _853 = _851 / (0.5 + _851);
                            if (_853 < (_336 - _337))
                            {
                                incN = true;
                                decN = highN;
                                lowN_1 = true;
                                lenN_1 = float(i - 1);
                            }
                            else
                            {
                                if (_853 > (_336 + _337))
                                {
                                    incN = true;
                                    decN = true;
                                    lenN_1 = float(i - 1);
                                }
                                else
                                {
                                    incN = doneN;
                                    decN = highN;
                                    lenN_1 = lenN;
                                }
                                lowN_1 = lowN;
                            }
                            lowN = lowN_1;
                        }
                        else
                        {
                            incN = doneN;
                            decN = highN;
                            lenN_1 = lenN;
                        }
                        doneP = incP;
                        doneN = incN;
                        highP = decP;
                        highN = decN;
                        lenP = dist;
                        lenN = lenN_1;
                        i++;
                        continue;
                    }
                    if (brighter)
                    {
                        incP = highP;
                    }
                    else
                    {
                        incP = lowP;
                    }
                    if (brighter)
                    {
                        decP = lowP;
                    }
                    else
                    {
                        decP = highP;
                    }
                    if (brighter)
                    {
                        incN = highN;
                    }
                    else
                    {
                        incN = lowN;
                    }
                    if (brighter)
                    {
                        decN = lowN;
                    }
                    else
                    {
                        decN = highN;
                    }
                    float inv = 1.0 / ((1.0 + lenP) + lenN);
                    if (!doneP)
                    {
                        doneP = !doneN;
                    }
                    else
                    {
                        doneP = false;
                    }
                    if (doneP)
                    {
                        dist = 0.0;
                    }
                    else
                    {
                        if (incP)
                        {
                            doneP = incN;
                        }
                        else
                        {
                            doneP = false;
                        }
                        if (doneP)
                        {
                            dist = 0.5;
                        }
                        else
                        {
                            if (decP)
                            {
                                doneP = decN;
                            }
                            else
                            {
                                doneP = false;
                            }
                            if (doneP)
                            {
                                dist = 0.0;
                            }
                            else
                            {
                                if (incN)
                                {
                                    dist = 0.5 - ((lenN + 0.5) * inv);
                                }
                                else
                                {
                                    if (incP)
                                    {
                                        dist = 0.5 - ((lenP + 0.5) * inv);
                                    }
                                    else
                                    {
                                        dist = 0.0;
                                    }
                                }
                            }
                        }
                    }
                    imageStore(uOffset, ivec2(gl_GlobalInvocationID.xy), vec4(float(side.x) * dist, float(side.y) * dist, 0.0, 0.0));
                }
            }
        }
    }
}

