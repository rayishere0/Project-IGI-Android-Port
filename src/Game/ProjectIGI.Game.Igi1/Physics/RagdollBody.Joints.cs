using ProjectIGI.Core.Numerics;
using ProjectIGI.Game.Physics;

namespace ProjectIGI.Game.Igi1.Physics;

/// <content>
/// The joints: the friction that bleeds a bone's spin relative to its parent, and the attachment and
/// swing-limit projections that hold each bone to its parent.
/// </content>
public sealed partial class RagdollBody
{
    // Joint friction: bleed the RELATIVE spin between a bone and its parent, which is what makes a
    // corpse limp rather than loose. Done at the velocity level after the solve, so it never fights the
    // constraints -- damping inside the projection would show up as a joint that drifts apart.
    private void DampJoints(double survives)
    {
        for (int i = 0; i < _links.Length; i++)
        {
            RagdollJoint link = _links[i];
            Vector3d relative = _spin[link.Child] - _spin[link.Parent];
            Vector3d bleed = relative * (1.0 - survives) * 0.5;
            _spin[link.Child] -= bleed;
            _spin[link.Parent] += bleed;
        }
    }

    // Leaves first, root LAST. In a Gauss-Seidel sweep the constraint solved last is the one satisfied
    // most accurately, and a hip that has come apart is far worse than a wrist that has -- so the joints
    // near the root get the final word. The skeleton being topologically sorted means walking the list
    // backwards is already leaf-first.
    private void SolveJoints(double poseHold)
    {
        for (int pass = 0; pass < JointIterations; pass++)
        {
            for (int i = _links.Length - 1; i >= 0; i--)
            {
                RagdollJoint link = _links[i];
                SolveDeviation(link);
                SolveTwist(link);
                SolveHinge(link);
                SolveAbduction(link);
                SolveSagittal(link);
                SolvePoseHold(link, poseHold);
                SolveAttachment(link);
            }
        }
    }

    // The joint itself: the two bones' anchor points are the same point, and they must stay so. Solved
    // AFTER the angular limits, because it is the one violation an audience can actually see.
    private void SolveAttachment(RagdollJoint link)
    {
        Vector3d parentArm = Turned(link.Parent, link.ParentAnchor);
        Vector3d childArm = Turned(link.Child, link.ChildAnchor);
        Vector3d gap = (_position[link.Parent] + parentArm) - (_position[link.Child] + childArm);

        double distance = gap.Length;
        if (distance <= 0.0)
        {
            return;
        }

        ApplyPositional(link.Parent, link.Child, parentArm, childArm, gap / distance, distance);
    }

    /// <summary>
    /// Eases a bone back toward the middle of its joint's range whenever it has swung further from that
    /// middle than the joint allows.
    /// </summary>
    /// <remarks>
    /// <para>
    /// The cone is centred on the middle of the joint's range, not on its rest direction. A knee's range
    /// is a half-bent middle with the swing spreading around it, so a cone centred there excludes
    /// straight and excludes backwards — the two directions a knee must not go. A cone centred on rest
    /// with the same half-angle allows the same excursion backwards as forwards, which is how a knee
    /// ended up bending the wrong way: the old term measured HOW FAR a joint had rotated, and a knee
    /// bending backwards and a knee bending forwards counted the same.
    /// </para>
    /// <para>
    /// The swing is measured as the angle between the child's current long axis and the cone's centre,
    /// in the parent's frame. That needs no decomposition of the relative rotation — the axis is where
    /// it is, whatever the twist is — so the split objection that used to rule out a swing term does not
    /// apply here: the twist is measured about that same current axis, the hinge about the plane's
    /// normal, and each of those terms acts only inside this cone, where this term is idle. The terms
    /// are mutually exclusive, so they never measure a quantity another is changing.
    /// </para>
    /// <para>
    /// It is also what fixes the limbs going thin. Nothing else in the solver constrains a bone's roll
    /// about its own length — the attachment says where a joint is and nothing about which way the bone
    /// is turned around it — so bones rolled freely, and a skinned mesh whose bones roll relative to
    /// their neighbours pinches: the vertices wind up like a sweet wrapper and the limb narrows to a
    /// point. That reads as a broken model rather than as broken physics, which is exactly how it looked.
    /// </para>
    /// <para>
    /// A <em>soft</em> spring rather than a hard stop, deliberately. A limit is a one-sided inequality
    /// that does nothing until it snaps, and snapping is what made the hard version shake a landed body
    /// to pieces. Taking a fixed fraction of the excess every substep acts continuously, acts hardest
    /// where the violation is worst, and cannot snap.
    /// </para>
    /// <para>
    /// The twist half of the limit now lives in <see cref="SolveTwist"/>, the hinge half in
    /// <see cref="SolveHinge"/>, and the sideways half in <see cref="SolveAbduction"/>: the hinge
    /// and abduction terms measure about the child's <em>current</em> long axis or its plane, and
    /// act only inside this cone — the regime where this term is idle — because their corrections
    /// rotate about the plane normal and WOULD change the swing, so they must not run while the
    /// cone spring is pulling it back. The twist term is the exception: its correction rotates
    /// about the child's own long axis, which cannot move that axis, so it acts everywhere and
    /// the two never fight. The terms are mutually exclusive wherever they need to be, so they
    /// never measure a quantity another is changing.
    /// </para>
    /// </remarks>
    private void SolveDeviation(RagdollJoint link)
    {
        // The child's orientation expressed in its parent's frame. At rest this is the identity, because
        // a rig's rest pose is every local rotation being nothing.
        Quaternion32 relative =
            (_orientation[link.Parent].Conjugate() * _orientation[link.Child]).Normalized();

        // A quaternion and its negation are the same orientation but opposite halves of a turn; taking
        // the near half is what makes the angle below the SHORT way round.
        if (relative.W < 0f)
        {
            relative = new Quaternion32(-relative.X, -relative.Y, -relative.Z, -relative.W);
        }

        // The child's long axis in the parent's frame, as in SolveTwist: the direction the joint has
        // actually swung, whatever the twist is.
        Vector3f swung = relative.Rotate(_aim[link.Child]);

        float angle = MathF.Acos(Math.Clamp(Vector3f.Dot(link.SwingAxis, swung), -1f, 1f));
        float over = angle - link.SwingLimit;
        if (over <= 0f)
        {
            return;
        }

        // The axis taking the swung direction onto the cone's centre, in the parent's frame: rotating
        // about it by the overshoot carries the swing back onto the cone. The axis is in the parent's
        // frame, so it has to be carried into the world before it can turn anything — the constraint
        // acts on world orientations.
        Vector3f axis = Vector3f.Cross(link.SwingAxis, swung);
        if (axis.Length <= RagdollSolver.ParallelEpsilon)
        {
            // The swing is at the far side of the cone, where the cross product has no direction: fall
            // back on the total rotation's own axis, which is the short way round and cannot be
            // degenerate while the swing is outside its limit.
            Vector3f vector = relative.Vector;
            float sine = vector.Length;
            if (sine <= RagdollSolver.ParallelEpsilon)
            {
                return;
            }

            axis = vector / sine;
        }

        Vector3f axisWorld = Direction(link.Parent, axis.Normalized());
        ApplyAngular(link.Parent, link.Child, axisWorld, over * JointStiffness, repair: true);
    }

    /// <summary>
    /// Eases a bone's roll about its own length back inside what the joint allows — the twist half of
    /// the limit <see cref="SolveDeviation"/> deliberately leaves alone.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <see cref="SolveDeviation"/> bounds the swing from the cone's centre, so a joint twisted 60°
    /// about its own axis
    /// with no swing at all is inside its cone and entirely unconstrained — while the measured twist
    /// range for an elbow-class joint is near zero. This term fills that dead zone: it measures the
    /// twist about the child's CURRENT long axis in the parent's frame
    /// (<c>relative.Rotate(_aim[child])</c>), so a twist correction cannot move that axis and therefore
    /// cannot change the swing — and it acts EVERYWHERE, inside the cone and outside it, because
    /// that swing-neutrality is what makes the cone gate unnecessary: a joint pushed past its cone
    /// by the contacts used to keep whatever twist it had, since the cone spring corrects the swing
    /// and nothing corrected the twist until the swing came back inside. The twist is NOT measured
    /// about the fixed rest axis, and NOT about <c>link.SwingAxis</c> — that is a swing datum (the
    /// cone's centre), not a twist axis.
    /// </para>
    /// <para>
    /// A soft spring at <see cref="JointStiffness"/>, not a hard wall: the same fraction-per-application
    /// as the cone term, applied through <c>ApplyAngular(repair: true)</c> so the correction is
    /// excluded from the velocity readback. It does NOT fade with the settle ramp — twist that develops
    /// after the pose-hold has faded is exactly the residual this term exists to fix.
    /// </para>
    /// </remarks>
    private void SolveTwist(RagdollJoint link)
    {
        // The carried body has no anatomical twist range — its grip joint is a hand holding a weapon,
        // not a bone rolling in its socket — so it gets the limit and the attachment only, as in
        // SolvePoseHold.
        if (link.Child >= _boneCount)
        {
            return;
        }

        // The child's orientation expressed in its parent's frame, as in SolveDeviation.
        Quaternion32 relative =
            (_orientation[link.Parent].Conjugate() * _orientation[link.Child]).Normalized();

        // A quaternion and its negation are the same orientation but opposite halves of a turn; taking
        // the near half is what makes the angle below the SHORT way round.
        if (relative.W < 0f)
        {
            relative = new Quaternion32(-relative.X, -relative.Y, -relative.Z, -relative.W);
        }

        Vector3f vector = relative.Vector;
        float sine = vector.Length;
        if (sine <= RagdollSolver.ParallelEpsilon)
        {
            return;
        }

        // The child's CURRENT long axis in the parent's frame. A rotation about this axis cannot move
        // it, so the twist correction is swing-neutral by construction.
        Vector3f aNow = relative.Rotate(_aim[link.Child]);

        // NO cone gate here, deliberately — and that is the difference from SolveHinge and
        // SolveAbduction, which are gated to act only inside the cone. The twist correction
        // rotates about the child's own long axis, and a rotation about that axis cannot move
        // the axis itself: the swung direction after the correction is R_p⁻¹ · Rot(n, Δ) ·
        // R_c · aim, and R_c · aim IS n, which Rot(n, Δ) leaves alone — so the swing angle
        // SolveDeviation measures is invariant under this correction, including through the
        // parent's share of it. The two terms therefore cannot fight, and the twist term
        // does not need to stand down outside the cone. It used to: a joint pushed past its
        // cone by the contacts kept whatever twist it had, because the cone spring corrects
        // the swing and nothing at all corrected the twist until the swing came back
        // inside — which is how a body ended up visibly twisted while every joint was
        // "inside its limits".
        float twist = RagdollLimits.Decompose(relative, aNow).Twist;

        float over = twist > link.TwistHigh ? twist - link.TwistHigh
            : twist < link.TwistLow ? twist - link.TwistLow
            : 0f;
        if (over == 0f)
        {
            return;
        }

        // The axis is in the parent's frame, so it has to be carried into the world before it can turn
        // anything -- the constraint acts on world orientations.
        Vector3f axis = Direction(link.Parent, aNow);
        ApplyAngular(link.Parent, link.Child, axis, over * JointStiffness, repair: true);
    }

    /// <summary>
    /// Eases a hinge joint's swing back inside the one direction it bends — the counterpart to
    /// <see cref="SolveDeviation"/> for joints whose motion stays in a plane.
    /// </summary>
    /// <remarks>
    /// <para>
    /// A knee bends one way. The centre-cone bounds how <em>far</em> a joint swings from the middle of
    /// its range, but a cone is a circle: it allows the same excursion backwards as forwards, and the
    /// backwards half is exactly the hyperextension the cone's centre was meant to exclude. The hinge
    /// term bounds the signed angle about the joint's plane normal instead — the one number a hinge
    /// actually has — measured the same way <see cref="SolveTwist"/> measures roll, about the child's
    /// current long axis, and gated to act only inside the cone, where <see cref="SolveDeviation"/> is
    /// idle. The terms are mutually exclusive, so they never measure a quantity another is changing.
    /// </para>
    /// <para>
    /// The out-of-plane half of the hinge is enforced here too: a hinge joint's swing may stray out of
    /// its plane only as far as the clips ever strayed it. A knee displaced sideways is the same class
    /// of wrong as a knee bent backwards, and the cone alone allows both up to its half-angle.
    /// </para>
    /// </remarks>
    private void SolveHinge(RagdollJoint link)
    {
        if (!link.IsHinge || link.Child >= _boneCount)
        {
            return;
        }

        Quaternion32 relative =
            (_orientation[link.Parent].Conjugate() * _orientation[link.Child]).Normalized();
        if (relative.W < 0f)
        {
            relative = new Quaternion32(-relative.X, -relative.Y, -relative.Z, -relative.W);
        }

        // The child's current long axis in the parent's frame, as in SolveTwist.
        Vector3f swung = relative.Rotate(_aim[link.Child]);

        // The gate, as in SolveTwist: inside the cone the deviation spring is idle and this term owns
        // the joint; outside it the cone owns the joint and this term stands down.
        float swingAngle = MathF.Acos(Math.Clamp(Vector3f.Dot(link.SwingAxis, swung), -1f, 1f));
        if (swingAngle > link.SwingLimit)
        {
            return;
        }

        // The signed hinge angle: the angle of the swung direction about the plane's normal, measured
        // from the rest direction. The rest direction is perpendicular to the normal by construction,
        // and the swung direction is projected back into the plane first, so the angle is the hinge
        // angle and nothing else.
        Vector3f flat = swung - (link.PlaneAxis * Vector3f.Dot(swung, link.PlaneAxis));
        if (flat.Length <= RagdollSolver.ParallelEpsilon)
        {
            return;
        }

        flat = flat.Normalized();
        Vector3f rest = _aim[link.Child];
        float hinge = MathF.Atan2(
            Vector3f.Dot(Vector3f.Cross(rest, flat), link.PlaneAxis),
            Vector3f.Dot(rest, flat));

        float over = hinge > link.HingeHigh ? hinge - link.HingeHigh
            : hinge < link.HingeLow ? hinge - link.HingeLow
            : 0f;
        if (over != 0f)
        {
            // The hinge angle is the rotation about the plane's normal, so the correction is a rotation
            // about that normal — the same signed-angle application as SolveTwist.
            Vector3f axis = Direction(link.Parent, link.PlaneAxis);
            ApplyAngular(link.Parent, link.Child, axis, over * JointStiffness, repair: true);
        }

        ClampOutOfPlane(link, swung, link.HingePlaneLimit);
    }

    /// <summary>
    /// Eases a ball joint's swing back inside the sideways boundary a human hip has — the leg-spread
    /// cap the directionless cone cannot express.
    /// </summary>
    /// <remarks>
    /// <para>
    /// A cone is a circle: it bounds how far a joint swings from the middle of its range, but it cannot
    /// say that a hip may flex far and may only abduct a little. The measured clips cannot say it
    /// either — they do not distinguish sideways from forwards — so the sideways boundary is a stated
    /// anatomical constant, not a measurement: the AAOS normative hip abduction of 45°, widened by the
    /// corpse Margin to 54° (see <see cref="RagdollLimits.MaximumAbduction"/>). The cap is enforced as
    /// the out-of-plane angle against the joint's dominant swing plane — for a hip, the sagittal plane,
    /// whose normal is the lateral axis a leg splays sideways around.
    /// </para>
    /// <para>
    /// Hinge joints are excluded: their plane is bounded by <see cref="SolveHinge"/> instead, from the
    /// measured stray rather than the anatomical cap. Joints with no dominant plane — a shoulder, whose
    /// range is symmetric about rest — keep the cone alone, which for them is the right limit: a shoulder
    /// genuinely does swing sideways as far as it swings forwards.
    /// </para>
    /// </remarks>
    private void SolveAbduction(RagdollJoint link)
    {
        if (link.IsHinge || link.Child >= _boneCount || link.PlaneAxis == Vector3f.Zero)
        {
            return;
        }

        Quaternion32 relative =
            (_orientation[link.Parent].Conjugate() * _orientation[link.Child]).Normalized();
        if (relative.W < 0f)
        {
            relative = new Quaternion32(-relative.X, -relative.Y, -relative.Z, -relative.W);
        }

        Vector3f swung = relative.Rotate(_aim[link.Child]);

        float swingAngle = MathF.Acos(Math.Clamp(Vector3f.Dot(link.SwingAxis, swung), -1f, 1f));
        if (swingAngle > link.SwingLimit)
        {
            return;
        }

        ClampOutOfPlane(link, swung, RagdollLimits.MaximumAbduction);
    }

    /// <summary>
    /// Eases a ball joint's swing back inside the forwards–backwards range a human leg has — the
    /// sagittal half of the limit the cone and the abduction cap both leave open.
    /// </summary>
    /// <remarks>
    /// <para>
    /// A cone is a circle: it bounds how far a joint swings from the middle of its range, but it
    /// cannot say that a hip may flex far forwards and may only extend a little backwards. The
    /// abduction cap bounds the sideways half and leaves the forwards–backwards half alone, so one
    /// leg forwards and one leg back — the split — was bounded by nothing but the cone's 80°
    /// half-angle, 160° between the legs. This term bounds the signed angle about the joint's
    /// plane normal instead — the one number a sagittal swing actually has — measured the same way
    /// <see cref="SolveHinge"/> measures a hinge angle, and capped at the range the clips
    /// measured for this joint (<see cref="RagdollJoint.SagittalLow"/> /
    /// <see cref="RagdollJoint.SagittalHigh"/>), widened by the corpse margin like every other
    /// measured limit. For a hip that is the gait range — flexion of roughly 60°, extension of
    /// roughly 20° — so the two legs together cannot split further than a living body could.
    /// </para>
    /// <para>
    /// Hinge joints are excluded: their plane is bounded by <see cref="SolveHinge"/> instead, from
    /// the same measured range. Joints with no dominant plane — a shoulder, whose range is
    /// symmetric about rest — keep the cone alone, which for them is the right limit. And like the
    /// hinge term it acts only inside the cone, where <see cref="SolveDeviation"/> is idle: its
    /// correction rotates about the plane normal, which DOES change the swing, so it must not run
    /// while the cone spring is pulling the swing back.
    /// </para>
    /// </remarks>
    private void SolveSagittal(RagdollJoint link)
    {
        if (link.IsHinge || link.Child >= _boneCount || link.PlaneAxis == Vector3f.Zero)
        {
            return;
        }

        Quaternion32 relative =
            (_orientation[link.Parent].Conjugate() * _orientation[link.Child]).Normalized();
        if (relative.W < 0f)
        {
            relative = new Quaternion32(-relative.X, -relative.Y, -relative.Z, -relative.W);
        }

        // The child's current long axis in the parent's frame, as in SolveTwist.
        Vector3f swung = relative.Rotate(_aim[link.Child]);

        // The gate, as in SolveHinge: inside the cone the deviation spring is idle and this term owns
        // the joint; outside it the cone owns the joint and this term stands down.
        float swingAngle = MathF.Acos(Math.Clamp(Vector3f.Dot(link.SwingAxis, swung), -1f, 1f));
        if (swingAngle > link.SwingLimit)
        {
            return;
        }

        // The signed sagittal angle: the angle of the swung direction about the plane's normal,
        // measured from the rest direction — the same computation as SolveHinge's hinge angle,
        // so it compares like with like against the range Measure recorded.
        Vector3f flat = swung - (link.PlaneAxis * Vector3f.Dot(swung, link.PlaneAxis));
        if (flat.Length <= RagdollSolver.ParallelEpsilon)
        {
            return;
        }

        flat = flat.Normalized();
        Vector3f rest = _aim[link.Child];
        float sagittal = MathF.Atan2(
            Vector3f.Dot(Vector3f.Cross(rest, flat), link.PlaneAxis),
            Vector3f.Dot(rest, flat));

        float over = sagittal > link.SagittalHigh ? sagittal - link.SagittalHigh
            : sagittal < link.SagittalLow ? sagittal - link.SagittalLow
            : 0f;
        if (over != 0f)
        {
            // The sagittal angle is the rotation about the plane's normal, so the correction is a
            // rotation about that normal — the same signed-angle application as SolveTwist.
            Vector3f axis = Direction(link.Parent, link.PlaneAxis);
            ApplyAngular(link.Parent, link.Child, axis, over * JointStiffness, repair: true);
        }
    }

    // Shared by SolveHinge and SolveAbduction: eases a swing that has strayed out of its plane back
    // toward the plane, by the overshoot past the given limit. The correction rotates the swung
    // direction onto its own in-plane projection — a rotation about the axis taking the one onto the
    // other — so it changes the out-of-plane angle and nothing else.
    private void ClampOutOfPlane(RagdollJoint link, Vector3f swung, float planeLimit)
    {
        float outOfPlane = MathF.Asin(Math.Clamp(MathF.Abs(Vector3f.Dot(swung, link.PlaneAxis)), -1f, 1f));
        float planeOver = outOfPlane - planeLimit;
        if (planeOver <= 0f)
        {
            return;
        }

        Vector3f flat = swung - (link.PlaneAxis * Vector3f.Dot(swung, link.PlaneAxis));
        if (flat.Length <= RagdollSolver.ParallelEpsilon)
        {
            return;
        }

        flat = flat.Normalized();
        Vector3f axisOut = Vector3f.Cross(swung, flat);
        if (axisOut.Length <= RagdollSolver.ParallelEpsilon)
        {
            return;
        }

        // The rotation that carries the swung direction onto its in-plane projection is about
        // cross(swung, flat) by the overshoot; ApplyAngular turns the relative rotation the other way
        // round, so the axis is negated.
        Vector3f axisWorld = Direction(link.Parent, -axisOut.Normalized());
        ApplyAngular(link.Parent, link.Child, axisWorld, planeOver * JointStiffness, repair: true);
    }

    /// <summary>
    /// Eases a bone back toward the local rotation it had when the body died — the one term in the
    /// solver that says where a limb <em>should</em> be, rather than where it may not go.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <see cref="SolveDeviation"/> is a one-sided wall: inside the cone it does nothing, so a limb
    /// is a free pendulum over most of its travel and nothing defines a preferred shape. That is the
    /// Euphoria gap — a muscle holds a body toward a pose, and this solver had no such term. This is
    /// that term, in its smallest form: the same computation as <see cref="SolveDeviation"/>, with the
    /// target moved from the identity to the seeded local rotation and the dead zone removed.
    /// </para>
    /// <para>
    /// The target is the <em>seeded</em> pose, not the bind pose: driving every corpse toward identity
    /// would straighten bodies that died bent or crouched into mannequins. The seeded pose preserves
    /// the death shape, which is why seeding from the drawn pose exists.
    /// </para>
    /// <para>
    /// Applied as a repair, exactly like the limit: the correction is accumulated in
    /// <c>_repairSpin</c> and excluded from the velocity readback in <c>Recover</c>, so a corpse does
    /// not read its own spring back as spin and dance. The existing <c>DampJoints</c> supplies the
    /// damping half of the muscle model, so no new damper is added here.
    /// </para>
    /// <para>
    /// <paramref name="strength"/> is the settle fade (1 while falling, 0 once settled): a spring
    /// toward a fixed dead pose at full strength forever would fight gravity and contacts and hang the
    /// corpse in its death shape instead of letting it collapse onto the floor.
    /// </para>
    /// </remarks>
    private void SolvePoseHold(RagdollJoint link, double strength)
    {
        // The carried body has no seeded target — it is simulated alongside the bones, not part of
        // the pose — so its grip joint gets the limit and the attachment only.
        if (strength <= 0.0 || link.Child >= _boneCount)
        {
            return;
        }

        Quaternion32 target = _seedLocal[link.Child];

        // The child's orientation expressed in its parent's frame, as in SolveDeviation.
        Quaternion32 relative =
            (_orientation[link.Parent].Conjugate() * _orientation[link.Child]).Normalized();

        // A quaternion and its negation are the same orientation but opposite halves of a turn; taking
        // the near half is what makes the angle below the SHORT way round.
        if (relative.W < 0f)
        {
            relative = new Quaternion32(-relative.X, -relative.Y, -relative.Z, -relative.W);
        }

        // The rotation that carries the seeded local pose into the current one: relative is
        // target * error, so turning the joint back by error returns it to the seeded pose.
        Quaternion32 error = (target.Conjugate() * relative).Normalized();
        if (error.W < 0f)
        {
            error = new Quaternion32(-error.X, -error.Y, -error.Z, -error.W);
        }

        Vector3f vector = error.Vector;
        float sine = vector.Length;
        if (sine <= RagdollSolver.ParallelEpsilon)
        {
            return;
        }

        float angle = 2f * MathF.Atan2(sine, error.W);

        // The axis is in the parent's frame, so it has to be carried into the world before it can turn
        // anything -- the constraint acts on world orientations.
        Vector3f axis = Direction(link.Parent, vector / sine);
        ApplyAngular(link.Parent, link.Child, axis, angle * PoseHoldStiffness * strength, repair: true);
    }

    /// <summary>The XPBD angular projection: turn two bodies so a rotation violation is closed.</summary>
    /// <remarks>
    /// <b>A joint limit is applied as a repair, and that is what makes a corpse settle.</b> The reasoning
    /// is the contacts' exactly: the velocities here are measured from how far things turned, so a limb
    /// shoved back inside its cone reads afterwards as a limb that was <em>spinning</em> that fast. On
    /// the ground the contacts push bones past their limits every substep, the limits push back, and each
    /// push-back is handed to the body as angular speed it never had — a corpse that lands and then
    /// twitches, rolls and dances, which is precisely what this looked like before the correction was
    /// excluded from the velocity.
    /// </remarks>
    private void ApplyAngular(int a, int b, Vector3f axis, double violation, bool repair = false)
    {
        Vector3d n = new(axis.X, axis.Y, axis.Z);
        double weightA = Vector3d.Dot(n, RagdollSolver.Rotate(_inverseInertia[a], n));
        double weightB = Vector3d.Dot(n, RagdollSolver.Rotate(_inverseInertia[b], n));
        double total = weightA + weightB;
        if (total <= 0.0)
        {
            return;
        }

        Vector3d impulse = n * (violation / total);
        Vector3d turnA = RagdollSolver.Rotate(_inverseInertia[a], impulse);
        Vector3d turnB = RagdollSolver.Rotate(_inverseInertia[b], -impulse);

        Turn(a, turnA);
        Turn(b, turnB);

        if (repair)
        {
            _repairSpin[a] += turnA;
            _repairSpin[b] += turnB;
        }
    }
}
