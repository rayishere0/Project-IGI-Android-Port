using ProjectIGI.Core.Numerics;
using ProjectIGI.Formats.Animation;
using ProjectIGI.Game.Physics;

namespace ProjectIGI.Game.Igi1.Physics;

/// <summary>How far one joint may swing and twist.</summary>
/// <param name="SwingAxis">
/// The direction the child bone's own axis points, in its parent's frame, at the middle of the joint's
/// range — the cone's centre line, which for a knee is not the rest direction.
/// </param>
/// <param name="SwingLimit">
/// The cone's half-angle, in radians — measured from the cone's centre, not from rest, so a knee's cone
/// is the spread around its half-bent middle rather than a ball around straight.
/// </param>
/// <param name="TwistLow">The furthest the joint twists one way about its own axis, in radians.</param>
/// <param name="TwistHigh">And the other way.</param>
/// <param name="PlaneAxis">
/// The normal of the joint's dominant swing plane, in the parent's frame — the hinge axis for a hinge
/// joint, and the lateral axis a ball joint splays sideways around. Zero when the joint has no dominant
/// plane, which is a joint whose range is centred on its rest direction.
/// </param>
/// <param name="IsHinge">Whether the joint's swing stays in its plane well enough to be a hinge.</param>
/// <param name="HingeLow">The furthest the hinge angle goes one way, in radians — only for a hinge.</param>
/// <param name="HingeHigh">And the other way — only for a hinge.</param>
/// <param name="HingePlaneLimit">
/// How far the swing may stray out of the hinge's plane, in radians — only for a hinge.
/// </param>
public readonly record struct RagdollJointRange(
    Vector3f SwingAxis,
    float SwingLimit,
    float TwistLow,
    float TwistHigh,
    Vector3f PlaneAxis,
    bool IsHinge,
    float HingeLow,
    float HingeHigh,
    float HingePlaneLimit);

/// <summary>
/// The range each joint of a rig actually moves through, measured from the animations the game ships
/// for it.
/// </summary>
/// <remarks>
/// <para>
/// <b>This is what makes a corpse fold like a body rather than like a rag, and none of it is invented.</b>
/// A ragdoll needs to know that a knee bends one way and a shoulder rotates freely, and the usual way to
/// supply that is a hand-written table naming bones by index — which for these rigs would be a guess,
/// because their joint roles have never been read.
/// </para>
/// <para>
/// They do not need to be. The animators already answered the question: every clip the game ships is a
/// demonstration of how far each joint is meant to move, so sweeping the rotation tracks and taking the
/// extent of each bone's local rotation <em>measures</em> the limits instead of assuming them. A knee's
/// tracks only ever bend it one way, so the cone that comes out is narrow and centred on a half-bent
/// pose; a shoulder's are wide and centred near its rest.
/// </para>
/// <para>
/// The cone is deliberately widened past what was measured. A clip shows what a living body does, and a
/// dead one goes further than that — the margin is the difference between a limit and a demonstration.
/// </para>
/// </remarks>
public sealed class RagdollLimits
{
    /// <summary>How much wider than the measured range a joint is allowed to be.</summary>
    /// <remarks>
    /// A fifth again. The clips show a living body's working range; a corpse exceeds it, and a limit
    /// set exactly at what was demonstrated would make every fall look braced. Tightened from 1.5 in
    /// Step 1: at one and a half times, the free-travel ball per joint was wide enough to fold a limb
    /// double.
    /// </remarks>
    public const float Margin = 1.2f;

    /// <summary>The narrowest cone a measurement may produce, in radians — 8°.</summary>
    /// <remarks>
    /// A bone that never moves in any clip measures a cone of zero, which would weld it to its parent.
    /// Some are genuinely rigid and should be nearly welded; none should be exactly so, because a solver
    /// cannot satisfy an exact weld and a joint at its limit every substep is a joint that jitters.
    /// </remarks>
    public const float MinimumSwing = 8f * MathF.PI / 180f;

    /// <summary>The widest, in radians — 80°.</summary>
    public const float MaximumSwing = 80f * MathF.PI / 180f;

    /// <summary>The widest a twist may be, in radians — 90° either way.</summary>
    public const float MaximumTwist = 90f * MathF.PI / 180f;

    /// <summary>The narrowest twist range a measurement may produce, in radians — 8° either way.</summary>
    /// <remarks>
    /// The twist mirror of <see cref="MinimumSwing"/>: a bone that never twists in any clip measures a
    /// twist range of exactly zero, which would weld its roll if enforced literally. Some joints
    /// genuinely barely twist and should be nearly welded; none should be exactly so, for the same
    /// reason a cone is never exactly zero — a solver cannot satisfy an exact weld and a joint at its
    /// limit every substep is a joint that jitters.
    /// </remarks>
    public const float MinimumTwist = 8f * MathF.PI / 180f;

    /// <summary>
    /// How far a joint's swing may stray out of its dominant plane and still count as a hinge, in
    /// radians — 20°.
    /// </summary>
    /// <remarks>
    /// A hinge is a joint whose motion IS a plane. The clips are retail animation, not a metrology lab,
    /// so a knee's swing wanders a few degrees out of its plane; twenty degrees is the line between
    /// that wander and a joint that genuinely moves in two directions. A joint over the line stays a
    /// ball joint and keeps its cone — it loses the hinge term, not its limits.
    /// </remarks>
    public const float HingePlaneThreshold = 20f * MathF.PI / 180f;

    /// <summary>How far past straight a hinge may go before the solver objects, in radians — 5°.</summary>
    /// <remarks>
    /// A hinge measured from the clips never shows hyperextension, so its measured low end sits at
    /// straight. A corpse is not a precision instrument, and a joint exactly at its limit every substep
    /// is a joint that jitters — the allowance is the difference between a limit and a weld. Five
    /// degrees is a knee that has settled, not a knee that has bent the wrong way.
    /// </remarks>
    public const float HingeExtensionAllowance = 5f * MathF.PI / 180f;

    /// <summary>The furthest a leg may splay sideways, in radians — 54°.</summary>
    /// <remarks>
    /// A stated anatomical constant, not a measurement: the clips cannot distinguish sideways from
    /// forwards, which is exactly why the cone alone cannot bound a split. The American Academy of
    /// Orthopaedic Surgeons' normative hip abduction is 45° (AAOS, <i>Joint Motion: Method of Measuring
    /// and Recording</i>, 1965); a dead body goes further than a living one, so the corpse Margin
    /// (×1.2) is applied to it, as it is to every measured limit. The boundary this sets is a leg
    /// spread of 108°, two legs at 54° each, against today's 160° — two legs at the 80° cone cap.
    /// </remarks>
    public const float MaximumAbduction = 54f * MathF.PI / 180f;

    /// <summary>
    /// How far the cone's centre must sit from the rest direction before a joint is treated as having a
    /// dominant swing plane, in radians — 10°.
    /// </summary>
    /// <remarks>
    /// The plane is the one the rest direction and the cone's centre both sit in, and it only exists
    /// when the two are far enough apart for their cross product to mean something. A joint whose range
    /// is symmetric about rest — a shoulder, a spine segment — has its centre on its rest direction and
    /// no dominant plane, and the cone alone is its limit. Ten degrees is the line: a knee's centre
    /// sits a half-bend off straight, a shoulder's does not.
    /// </remarks>
    public const float PlaneMinimumOffset = 10f * MathF.PI / 180f;

    private readonly RagdollJointRange[] _ranges;
    private readonly bool[] _measured;

    private RagdollLimits(RagdollJointRange[] ranges, bool[] measured)
    {
        _ranges = ranges;
        _measured = measured;
    }

    /// <summary>Gets how many bones were measured.</summary>
    public int BoneCount => _ranges.Length;

    /// <summary>Gets one bone's measured range.</summary>
    /// <param name="bone">The bone index.</param>
    /// <param name="range">Receives the range.</param>
    /// <returns><see langword="false"/> when nothing in the corpus ever moved that bone.</returns>
    public bool TryGet(int bone, out RagdollJointRange range)
    {
        if (bone < 0 || bone >= _ranges.Length || !_measured[bone])
        {
            range = default;
            return false;
        }

        range = _ranges[bone];
        return true;
    }

    /// <summary>Measures every joint's range from the clips a rig ships with.</summary>
    /// <param name="set">The animation set, whose skeleton the measurement is against.</param>
    /// <returns>The limits.</returns>
    /// <exception cref="ArgumentNullException"><paramref name="set"/> is <see langword="null"/>.</exception>
    /// <remarks>
    /// <para>
    /// A bone's local rotation is split into the <b>swing</b> that takes its own axis somewhere else and
    /// the <b>twist</b> that spins it about that axis, because a joint limits the two quite differently:
    /// an elbow swings through most of a half-circle and twists barely at all, and a wrist is the other
    /// way round. The split is the standard one — project the rotation's vector part onto the axis to get
    /// the twist, and whatever is left over is the swing.
    /// </para>
    /// <para>
    /// The cone's axis is the <em>average</em> swung direction rather than the rest one. That is the part
    /// that matters for a knee: its clips never straighten it and never bend it forwards, so the average
    /// sits half-bent and the cone around it excludes straight and excludes forwards — which is a hinge,
    /// arrived at by measurement, with no bone named and no axis assumed.
    /// </para>
    /// <para>
    /// The measurement also records whether the swing stays in one plane — a hinge — and, for a ball
    /// joint with a plane, which direction sideways is, so the solver can bound a split the cone alone
    /// cannot see. The hinge's range is the signed angle about the plane's normal, measured the same way
    /// the twist is, and its plane is the one the rest direction and the cone's centre both sit in. A
    /// joint whose range is symmetric about rest has no dominant plane and keeps its cone only.
    /// </para>
    /// </remarks>
    public static RagdollLimits Measure(BoneAnimationSet set)
    {
        ArgumentNullException.ThrowIfNull(set);

        int count = set.Skeleton.BoneCount;
        Vector3f[] axis = new Vector3f[count];
        Vector3f[] swungSum = new Vector3f[count];
        int[] samples = new int[count];
        float[] twistLow = new float[count];
        float[] twistHigh = new float[count];

        for (int bone = 0; bone < count; bone++)
        {
            // The bone's own axis is where its children sit, the same direction the rig gives its capsule.
            Vector3f reach = Vector3f.Zero;
            int kids = 0;
            for (int child = 0; child < count; child++)
            {
                if (set.Skeleton.Parents[child] == bone)
                {
                    reach += set.Skeleton.RestTranslations[child];
                    kids++;
                }
            }

            axis[bone] = kids > 0 && reach.LengthSquared > 0f ? reach.Normalized() : Vector3f.UnitZ;
        }

        foreach (BoneAnimation clip in set.Animations)
        {
            int shared = Math.Min(clip.BoneCount, count);
            for (int bone = 0; bone < shared; bone++)
            {
                foreach (BoneRotationKey key in clip.Rotations(bone))
                {
                    (float twist, Vector3f swung) = Decompose(key.Rotation, axis[bone]);
                    swungSum[bone] += swung;
                    twistLow[bone] = Math.Min(twistLow[bone], twist);
                    twistHigh[bone] = Math.Max(twistHigh[bone], twist);
                    samples[bone]++;
                }
            }
        }

        // A second pass, because the cone's half-angle is measured against the average direction and the
        // average is not known until every sample has been seen.
        Vector3f[] centre = new Vector3f[count];
        float[] swing = new float[count];
        bool[] measured = new bool[count];

        for (int bone = 0; bone < count; bone++)
        {
            measured[bone] = samples[bone] > 0 && swungSum[bone].LengthSquared > 0f;
            centre[bone] = measured[bone] ? swungSum[bone].Normalized() : axis[bone];
        }

        // The dominant swing plane, where the joint has one: the plane the rest direction and the
        // cone's centre both sit in. Its normal is the hinge axis for a joint whose motion stays in
        // that plane, and the lateral axis — the direction a leg splays sideways in — for a ball joint
        // with a plane. A joint whose centre sits on its rest direction has no dominant plane: its
        // motion is symmetric about rest, and no single plane describes it.
        Vector3f[] plane = new Vector3f[count];
        bool[] hasPlane = new bool[count];
        for (int bone = 0; bone < count; bone++)
        {
            Vector3f cross = Vector3f.Cross(axis[bone], centre[bone]);
            hasPlane[bone] = cross.Length >= MathF.Sin(PlaneMinimumOffset);
            plane[bone] = hasPlane[bone] ? cross.Normalized() : Vector3f.Zero;
        }

        float[] maxOut = new float[count];
        float[] hingeLow = new float[count];
        float[] hingeHigh = new float[count];

        foreach (BoneAnimation clip in set.Animations)
        {
            int shared = Math.Min(clip.BoneCount, count);
            for (int bone = 0; bone < shared; bone++)
            {
                if (!measured[bone])
                {
                    continue;
                }

                foreach (BoneRotationKey key in clip.Rotations(bone))
                {
                    (_, Vector3f swung) = Decompose(key.Rotation, axis[bone]);
                    float angle = MathF.Acos(Math.Clamp(Vector3f.Dot(centre[bone], swung), -1f, 1f));
                    swing[bone] = MathF.Max(swing[bone], angle);

                    // How far this key's swing strays out of the joint's dominant plane, and the
                    // signed angle it makes about the plane's normal — the two numbers a hinge is made
                    // of. Both are measured only where the joint has a plane at all.
                    if (hasPlane[bone])
                    {
                        float outOfPlane = MathF.Asin(Math.Clamp(MathF.Abs(Vector3f.Dot(swung, plane[bone])), -1f, 1f));
                        maxOut[bone] = MathF.Max(maxOut[bone], outOfPlane);

                        // The swung direction projected back into the plane, so the signed angle about
                        // the plane's normal is the hinge angle and nothing else.
                        Vector3f flat = swung - (plane[bone] * Vector3f.Dot(swung, plane[bone]));
                        if (flat.LengthSquared > 0f)
                        {
                            flat = flat.Normalized();
                            float hinge = MathF.Atan2(
                                Vector3f.Dot(Vector3f.Cross(axis[bone], flat), plane[bone]),
                                Vector3f.Dot(axis[bone], flat));
                            hingeLow[bone] = Math.Min(hingeLow[bone], hinge);
                            hingeHigh[bone] = Math.Max(hingeHigh[bone], hinge);
                        }
                    }
                }
            }
        }

        RagdollJointRange[] ranges = new RagdollJointRange[count];
        for (int bone = 0; bone < count; bone++)
        {
            // The cone's half-angle is measured from its own centre, not from rest: the cone is the
            // range the joint actually moves through, and the rest direction is inside it by
            // construction — the half-angle is at least the centre's offset from rest, so the bind pose
            // is always legal and the solver never fights the pose the rig was built in.
            float offset = MathF.Acos(Math.Clamp(Vector3f.Dot(centre[bone], axis[bone]), -1f, 1f));
            float halfAngle = MathF.Max(swing[bone], offset);

            // A hinge is a joint whose swing stays in its plane: the out-of-plane stray is small
            // enough that the plane is the motion, not an approximation of it. The hinge's own range
            // is the signed angle about the plane's normal, widened by the margin like every other
            // limit, with a few degrees of grace past straight so a joint exactly at its limit every
            // substep is not a joint that jitters.
            bool hinge = hasPlane[bone] && maxOut[bone] <= HingePlaneThreshold;

            ranges[bone] = new RagdollJointRange(
                centre[bone],
                Math.Clamp(halfAngle * Margin, MinimumSwing, MaximumSwing),
                Math.Clamp(twistLow[bone] * Margin, -MaximumTwist, -MinimumTwist),
                Math.Clamp(twistHigh[bone] * Margin, MinimumTwist, MaximumTwist),
                plane[bone],
                hinge,
                hinge ? hingeLow[bone] * Margin - HingeExtensionAllowance : 0f,
                hinge ? hingeHigh[bone] * Margin : 0f,
                hinge ? Math.Clamp(maxOut[bone] * Margin, MinimumSwing, MaximumSwing) : 0f);
        }

        return new RagdollLimits(ranges, measured);
    }

    /// <summary>Splits a local rotation into how far it twists about an axis and where it puts that axis.</summary>
    /// <param name="rotation">The bone's local rotation.</param>
    /// <param name="axis">Its own axis, in its own frame, unit length.</param>
    /// <returns>The twist angle in radians, and where the axis ends up.</returns>
    /// <remarks>
    /// The swing-twist decomposition: the part of the rotation's vector component along the axis is the
    /// twist, and what remains carries the axis somewhere else. Only the twist ANGLE and the swung
    /// DIRECTION are wanted here, and both come straight out without needing the swing quaternion itself.
    /// </remarks>
    public static (float Twist, Vector3f Swung) Decompose(Quaternion32 rotation, Vector3f axis)
    {
        Quaternion32 q = rotation.Normalized();
        float along = (q.X * axis.X) + (q.Y * axis.Y) + (q.Z * axis.Z);

        // atan2 rather than 2*asin: the angle has to keep its sign and stay meaningful past a quarter
        // turn, and the projection alone loses both.
        float twist = 2f * MathF.Atan2(along, q.W);
        if (twist > MathF.PI)
        {
            twist -= 2f * MathF.PI;
        }
        else if (twist < -MathF.PI)
        {
            twist += 2f * MathF.PI;
        }

        Matrix3f m = BonePose.ToMatrix(q);
        Vector3f swung = new(
            (m.M11 * axis.X) + (m.M12 * axis.Y) + (m.M13 * axis.Z),
            (m.M21 * axis.X) + (m.M22 * axis.Y) + (m.M23 * axis.Z),
            (m.M31 * axis.X) + (m.M32 * axis.Y) + (m.M33 * axis.Z));

        return (twist, swung.LengthSquared > 0f ? swung.Normalized() : axis);
    }
}
