struct Params_std140_0
{
    @align(16) outputSize_0 : vec4<f32>,
    @align(16) historySize_0 : vec4<f32>,
    @align(16) control_0 : vec4<f32>,
    @align(16) control2_0 : vec4<f32>,
};

@binding(11) @group(0) var<uniform> p_0 : Params_std140_0;
@binding(3) @group(0) var uVelocity_0 : texture_2d<f32>;

@binding(4) @group(0) var uVelocitySampler_0 : sampler;

@binding(5) @group(0) var uParallax_0 : texture_2d<f32>;

@binding(6) @group(0) var uParallaxSampler_0 : sampler;

@binding(7) @group(0) var uShading_0 : texture_2d<f32>;

@binding(8) @group(0) var uShadingSampler_0 : sampler;

@binding(9) @group(0) var uHistoryMetadata_0 : texture_2d<f32>;

@binding(10) @group(0) var uHistoryMetadataSampler_0 : sampler;

@binding(2) @group(0) var uOutput_0 : texture_storage_2d<rgba16float, write>;

@binding(0) @group(0) var uHistoryColour_0 : texture_2d<f32>;

@binding(1) @group(0) var uHistoryColourSampler_0 : sampler;

fn HdrWeight_0( c_0 : vec3<f32>) -> f32
{
    var _S1 : vec3<f32> = c_0 * vec3<f32>(max(p_0.control2_0.x, 9.9999997473787516e-05f));
    return max(9.9999997473787516e-05f, 1.0f / (_S1.x + 2.0f * _S1.y + _S1.z + 4.0f));
}

fn MitchellNetravali_0( x_0 : f32) -> f32
{
    var ax_0 : f32 = abs(x_0);
    var ax2_0 : f32 = ax_0 * ax_0;
    var ax3_0 : f32 = ax2_0 * ax_0;
    if((ax_0 < 1.0f))
    {
        return (7.0f * ax3_0 + -12.0f * ax2_0 + 5.3333334922790527f) / 6.0f;
    }
    if((ax_0 < 2.0f))
    {
        return (-2.3333332538604736f * ax3_0 + 12.0f * ax2_0 + -20.0f * ax_0 + 10.666666984558105f) / 6.0f;
    }
    return 0.0f;
}

@compute
@workgroup_size(8, 8, 1)
fn computeMain(@builtin(global_invocation_id) id_0 : vec3<u32>)
{
    var _S2 : vec2<i32> = vec2<i32>(id_0.xy);
    var _S3 : vec2<i32> = vec2<i32>(p_0.outputSize_0.xy);
    var _S4 : bool;
    if(((_S2.x) >= (_S3.x)))
    {
        _S4 = true;
    }
    else
    {
        _S4 = ((_S2.y) >= (_S3.y));
    }
    if(_S4)
    {
        return;
    }
    var _S5 : vec2<f32> = max(p_0.control_0.xy, vec2<f32>(0.0010000000474974513f, 0.0010000000474974513f));
    var debugView_0 : i32 = i32(p_0.control_0.z + 0.5f);
    var shown_0 : vec3<f32>;
    if(debugView_0 != i32(0))
    {
        var uv_0 : vec2<f32> = (vec2<f32>(_S2) + vec2<f32>(0.5f)) * p_0.outputSize_0.zw;
        if(debugView_0 == i32(1))
        {
            var velocityWidth_0 : u32;
            var velocityHeight_0 : u32;
            {var dim = textureDimensions((uVelocity_0));((velocityWidth_0)) = dim.x;((velocityHeight_0)) = dim.y;};
            var v_0 : vec2<f32> = (textureSampleLevel((uVelocity_0), (uVelocitySampler_0), (uv_0), (0.0f))).xy * vec2<f32>(f32(velocityWidth_0), f32(velocityHeight_0));
            shown_0 = vec3<f32>(0.5f + v_0.y / 20.0f, 0.5f + v_0.x / 20.0f, 0.5f);
        }
        else
        {
            if(debugView_0 == i32(2))
            {
                shown_0 = (textureSampleLevel((uParallax_0), (uParallaxSampler_0), (uv_0), (0.0f))).xxx;
            }
            else
            {
                if(debugView_0 == i32(3))
                {
                    shown_0 = (textureSampleLevel((uShading_0), (uShadingSampler_0), (uv_0), (0.0f))).xxx;
                }
                else
                {
                    shown_0 = (textureSampleLevel((uHistoryMetadata_0), (uHistoryMetadataSampler_0), (uv_0 * p_0.historySize_0.xy * p_0.historySize_0.zw), (0.0f))).xxx;
                }
            }
        }
        textureStore((uOutput_0), (vec2<u32>(_S2)), (vec4<f32>(clamp(shown_0, vec3<f32>(0.0f, 0.0f, 0.0f), vec3<f32>(1.0f, 1.0f, 1.0f)), 1.0f)));
        return;
    }
    var _S6 : vec2<f32> = vec2<f32>(0.5f);
    var hp_0 : vec2<f32> = (vec2<f32>(_S2) + _S6) * _S5;
    var _S7 : vec2<f32> = floor(hp_0 - vec2<f32>(1.5f)) + _S6;
    const _S8 : vec3<f32> = vec3<f32>(1.00000001504746622e+30f, 1.00000001504746622e+30f, 1.00000001504746622e+30f);
    const _S9 : vec3<f32> = vec3<f32>(-1.00000001504746622e+30f, -1.00000001504746622e+30f, -1.00000001504746622e+30f);
    var _S10 : vec2<f32> = vec2<f32>(0.0f);
    var _S11 : vec2<f32> = vec2<f32>(1.0f);
    var _S12 : vec3<f32> = vec3<f32>(0.0f);
    var _S13 : vec3<f32> = max((textureSampleLevel((uHistoryColour_0), (uHistoryColourSampler_0), (clamp(_S7 * p_0.historySize_0.zw, _S10, _S11)), (0.0f))).xyz, _S12);
    var hw_0 : f32 = HdrWeight_0(_S13);
    var _S14 : f32 = hp_0.x;
    var _S15 : f32 = hp_0.y;
    var wt_0 : f32 = MitchellNetravali_0(abs(_S7.x - _S14)) * MitchellNetravali_0(abs(_S7.y - _S15)) * hw_0;
    var pos_0 : vec2<f32> = _S7 + vec2<f32>(1.0f, 0.0f);
    var _S16 : vec3<f32> = max((textureSampleLevel((uHistoryColour_0), (uHistoryColourSampler_0), (clamp(pos_0 * p_0.historySize_0.zw, _S10, _S11)), (0.0f))).xyz, _S12);
    var hw_1 : f32 = HdrWeight_0(_S16);
    var wt_1 : f32 = MitchellNetravali_0(abs(pos_0.x - _S14)) * MitchellNetravali_0(abs(pos_0.y - _S15)) * hw_1;
    var pos_1 : vec2<f32> = _S7 + vec2<f32>(2.0f, 0.0f);
    var _S17 : vec3<f32> = max((textureSampleLevel((uHistoryColour_0), (uHistoryColourSampler_0), (clamp(pos_1 * p_0.historySize_0.zw, _S10, _S11)), (0.0f))).xyz, _S12);
    var hw_2 : f32 = HdrWeight_0(_S17);
    var wt_2 : f32 = MitchellNetravali_0(abs(pos_1.x - _S14)) * MitchellNetravali_0(abs(pos_1.y - _S15)) * hw_2;
    var pos_2 : vec2<f32> = _S7 + vec2<f32>(3.0f, 0.0f);
    var _S18 : vec3<f32> = max((textureSampleLevel((uHistoryColour_0), (uHistoryColourSampler_0), (clamp(pos_2 * p_0.historySize_0.zw, _S10, _S11)), (0.0f))).xyz, _S12);
    var hw_3 : f32 = HdrWeight_0(_S18);
    var wt_3 : f32 = MitchellNetravali_0(abs(pos_2.x - _S14)) * MitchellNetravali_0(abs(pos_2.y - _S15)) * hw_3;
    var pos_3 : vec2<f32> = _S7 + vec2<f32>(0.0f, 1.0f);
    var _S19 : vec3<f32> = max((textureSampleLevel((uHistoryColour_0), (uHistoryColourSampler_0), (clamp(pos_3 * p_0.historySize_0.zw, _S10, _S11)), (0.0f))).xyz, _S12);
    var hw_4 : f32 = HdrWeight_0(_S19);
    var wt_4 : f32 = MitchellNetravali_0(abs(pos_3.x - _S14)) * MitchellNetravali_0(abs(pos_3.y - _S15)) * hw_4;
    var pos_4 : vec2<f32> = _S7 + vec2<f32>(1.0f, 1.0f);
    var _S20 : vec3<f32> = max((textureSampleLevel((uHistoryColour_0), (uHistoryColourSampler_0), (clamp(pos_4 * p_0.historySize_0.zw, _S10, _S11)), (0.0f))).xyz, _S12);
    var hw_5 : f32 = HdrWeight_0(_S20);
    var wt_5 : f32 = MitchellNetravali_0(abs(pos_4.x - _S14)) * MitchellNetravali_0(abs(pos_4.y - _S15)) * hw_5;
    var pos_5 : vec2<f32> = _S7 + vec2<f32>(2.0f, 1.0f);
    var _S21 : vec3<f32> = max((textureSampleLevel((uHistoryColour_0), (uHistoryColourSampler_0), (clamp(pos_5 * p_0.historySize_0.zw, _S10, _S11)), (0.0f))).xyz, _S12);
    var hw_6 : f32 = HdrWeight_0(_S21);
    var wt_6 : f32 = MitchellNetravali_0(abs(pos_5.x - _S14)) * MitchellNetravali_0(abs(pos_5.y - _S15)) * hw_6;
    var pos_6 : vec2<f32> = _S7 + vec2<f32>(3.0f, 1.0f);
    var _S22 : vec3<f32> = max((textureSampleLevel((uHistoryColour_0), (uHistoryColourSampler_0), (clamp(pos_6 * p_0.historySize_0.zw, _S10, _S11)), (0.0f))).xyz, _S12);
    var hw_7 : f32 = HdrWeight_0(_S22);
    var wt_7 : f32 = MitchellNetravali_0(abs(pos_6.x - _S14)) * MitchellNetravali_0(abs(pos_6.y - _S15)) * hw_7;
    var pos_7 : vec2<f32> = _S7 + vec2<f32>(0.0f, 2.0f);
    var _S23 : vec3<f32> = max((textureSampleLevel((uHistoryColour_0), (uHistoryColourSampler_0), (clamp(pos_7 * p_0.historySize_0.zw, _S10, _S11)), (0.0f))).xyz, _S12);
    var hw_8 : f32 = HdrWeight_0(_S23);
    var wt_8 : f32 = MitchellNetravali_0(abs(pos_7.x - _S14)) * MitchellNetravali_0(abs(pos_7.y - _S15)) * hw_8;
    var pos_8 : vec2<f32> = _S7 + vec2<f32>(1.0f, 2.0f);
    var _S24 : vec3<f32> = max((textureSampleLevel((uHistoryColour_0), (uHistoryColourSampler_0), (clamp(pos_8 * p_0.historySize_0.zw, _S10, _S11)), (0.0f))).xyz, _S12);
    var hw_9 : f32 = HdrWeight_0(_S24);
    var wt_9 : f32 = MitchellNetravali_0(abs(pos_8.x - _S14)) * MitchellNetravali_0(abs(pos_8.y - _S15)) * hw_9;
    var pos_9 : vec2<f32> = _S7 + vec2<f32>(2.0f, 2.0f);
    var _S25 : vec3<f32> = max((textureSampleLevel((uHistoryColour_0), (uHistoryColourSampler_0), (clamp(pos_9 * p_0.historySize_0.zw, _S10, _S11)), (0.0f))).xyz, _S12);
    var hw_10 : f32 = HdrWeight_0(_S25);
    var wt_10 : f32 = MitchellNetravali_0(abs(pos_9.x - _S14)) * MitchellNetravali_0(abs(pos_9.y - _S15)) * hw_10;
    var pos_10 : vec2<f32> = _S7 + vec2<f32>(3.0f, 2.0f);
    var _S26 : vec3<f32> = max((textureSampleLevel((uHistoryColour_0), (uHistoryColourSampler_0), (clamp(pos_10 * p_0.historySize_0.zw, _S10, _S11)), (0.0f))).xyz, _S12);
    var hw_11 : f32 = HdrWeight_0(_S26);
    var wt_11 : f32 = MitchellNetravali_0(abs(pos_10.x - _S14)) * MitchellNetravali_0(abs(pos_10.y - _S15)) * hw_11;
    var pos_11 : vec2<f32> = _S7 + vec2<f32>(0.0f, 3.0f);
    var _S27 : vec3<f32> = max((textureSampleLevel((uHistoryColour_0), (uHistoryColourSampler_0), (clamp(pos_11 * p_0.historySize_0.zw, _S10, _S11)), (0.0f))).xyz, _S12);
    var hw_12 : f32 = HdrWeight_0(_S27);
    var wt_12 : f32 = MitchellNetravali_0(abs(pos_11.x - _S14)) * MitchellNetravali_0(abs(pos_11.y - _S15)) * hw_12;
    var pos_12 : vec2<f32> = _S7 + vec2<f32>(1.0f, 3.0f);
    var _S28 : vec3<f32> = max((textureSampleLevel((uHistoryColour_0), (uHistoryColourSampler_0), (clamp(pos_12 * p_0.historySize_0.zw, _S10, _S11)), (0.0f))).xyz, _S12);
    var hw_13 : f32 = HdrWeight_0(_S28);
    var wt_13 : f32 = MitchellNetravali_0(abs(pos_12.x - _S14)) * MitchellNetravali_0(abs(pos_12.y - _S15)) * hw_13;
    var pos_13 : vec2<f32> = _S7 + vec2<f32>(2.0f, 3.0f);
    var _S29 : vec3<f32> = max((textureSampleLevel((uHistoryColour_0), (uHistoryColourSampler_0), (clamp(pos_13 * p_0.historySize_0.zw, _S10, _S11)), (0.0f))).xyz, _S12);
    var hw_14 : f32 = HdrWeight_0(_S29);
    var wt_14 : f32 = MitchellNetravali_0(abs(pos_13.x - _S14)) * MitchellNetravali_0(abs(pos_13.y - _S15)) * hw_14;
    var pos_14 : vec2<f32> = _S7 + vec2<f32>(3.0f, 3.0f);
    var _S30 : vec3<f32> = max((textureSampleLevel((uHistoryColour_0), (uHistoryColourSampler_0), (clamp(pos_14 * p_0.historySize_0.zw, _S10, _S11)), (0.0f))).xyz, _S12);
    var hw_15 : f32 = HdrWeight_0(_S30);
    var wt_15 : f32 = MitchellNetravali_0(abs(pos_14.x - _S14)) * MitchellNetravali_0(abs(pos_14.y - _S15)) * hw_15;
    var sum_0 : vec3<f32> = _S13 * vec3<f32>(wt_0) + _S16 * vec3<f32>(wt_1) + _S17 * vec3<f32>(wt_2) + _S18 * vec3<f32>(wt_3) + _S19 * vec3<f32>(wt_4) + _S20 * vec3<f32>(wt_5) + _S21 * vec3<f32>(wt_6) + _S22 * vec3<f32>(wt_7) + _S23 * vec3<f32>(wt_8) + _S24 * vec3<f32>(wt_9) + _S25 * vec3<f32>(wt_10) + _S26 * vec3<f32>(wt_11) + _S27 * vec3<f32>(wt_12) + _S28 * vec3<f32>(wt_13) + _S29 * vec3<f32>(wt_14) + _S30 * vec3<f32>(wt_15);
    var sumWeight_0 : f32 = wt_0 + wt_1 + wt_2 + wt_3 + wt_4 + wt_5 + wt_6 + wt_7 + wt_8 + wt_9 + wt_10 + wt_11 + wt_12 + wt_13 + wt_14 + wt_15;
    var box_0 : vec3<f32> = _S13 * vec3<f32>(hw_0) + _S16 * vec3<f32>(hw_1) + _S17 * vec3<f32>(hw_2) + _S18 * vec3<f32>(hw_3) + _S19 * vec3<f32>(hw_4) + _S20 * vec3<f32>(hw_5) + _S21 * vec3<f32>(hw_6) + _S22 * vec3<f32>(hw_7) + _S23 * vec3<f32>(hw_8) + _S24 * vec3<f32>(hw_9) + _S25 * vec3<f32>(hw_10) + _S26 * vec3<f32>(hw_11) + _S27 * vec3<f32>(hw_12) + _S28 * vec3<f32>(hw_13) + _S29 * vec3<f32>(hw_14) + _S30 * vec3<f32>(hw_15);
    var boxWeight_0 : f32 = hw_0 + hw_1 + hw_2 + hw_3 + hw_4 + hw_5 + hw_6 + hw_7 + hw_8 + hw_9 + hw_10 + hw_11 + hw_12 + hw_13 + hw_14 + hw_15;
    var _S31 : vec3<f32> = min(min(min(min(min(min(min(min(min(min(min(min(min(min(min(min(_S8, _S13), _S16), _S17), _S18), _S19), _S20), _S21), _S22), _S23), _S24), _S25), _S26), _S27), _S28), _S29), _S30);
    var _S32 : vec3<f32> = max(max(max(max(max(max(max(max(max(max(max(max(max(max(max(max(_S9, _S13), _S16), _S17), _S18), _S19), _S20), _S21), _S22), _S23), _S24), _S25), _S26), _S27), _S28), _S29), _S30);
    if(sumWeight_0 != 0.0f)
    {
        shown_0 = sum_0 / vec3<f32>(sumWeight_0);
    }
    else
    {
        shown_0 = vec3<f32>(0.0f, 0.0f, 0.0f);
    }
    var sharpen_0 : f32 = p_0.control_0.w;
    if((sharpen_0 > 0.0f))
    {
        _S4 = (boxWeight_0 > 0.0f);
    }
    else
    {
        _S4 = false;
    }
    if(_S4)
    {
        shown_0 = shown_0 + (shown_0 - box_0 / vec3<f32>(boxWeight_0)) * vec3<f32>(sharpen_0);
    }
    textureStore((uOutput_0), (vec2<u32>(_S2)), (vec4<f32>(max(clamp(shown_0, _S31, _S32), _S12), 1.0f)));
    return;
}

