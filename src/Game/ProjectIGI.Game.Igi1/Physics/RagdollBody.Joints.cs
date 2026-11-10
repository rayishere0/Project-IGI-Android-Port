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
    /// Eases a bone back toward its parent whenever it has turned further from it than the joint allows —
    /// in any direction at all, roll included.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <b>One constraint on the whole relative rotation, rather than a swing limit and a twist limit
    /// solved separately, and that is a correction rather than a simplification.</b> Splitting a rotation
    /// into a swing and a twist needs an axis to split about, and on a joint that is already heavily
    /// swung — every joint of a corpse on the ground — the split moves part of the swing into the twist
    /// and part of the twist into the swing. Two constraints then each measure a quantity the other is
    /// changing, and neither converges: measured one way a joint would read 45°, measured the other 83°,
    /// on the same body at the same instant. The total angle between two orientations needs no axis and
    /// has no such ambiguity.
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
    /// The twist half of the limit now lives in <see cref="SolveTwist"/>, and the split above no
    /// longer applies to it the way it would have: the twist term measures about the child's
    /// <em>current</em> long axis, so its correction cannot change the swing, and it acts only
    /// inside this cone — the regime where this term is idle. The two terms are mutually exclusive,
    /// so they never measure a quantity the other is changing.
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

        Vector3f vector = relative.Vector;
        float sine = vector.Length;
        if (sine <= RagdollSolver.ParallelEpsilon)
        {
            return;
        }

        float angle = 2f * MathF.Atan2(sine, relative.W);
        float over = angle - link.SwingLimit;
        if (over <= 0f)
        {
            return;
        }

        // The axis is in the parent's frame, so it has to be carried into the world before it can turn
        // anything -- the constraint acts on world orientations.
        Vector3f axis = Direction(link.Parent, vector / sine);
        ApplyAngular(link.Parent, link.Child, axis, over * JointStiffness, repair: true);
    }

    /// <summary>
    /// Eases a bone's roll about its own length back inside what the joint allows — the twist half of
    /// the limit <see cref="SolveDeviation"/> deliberately leaves alone.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <see cref="SolveDeviation"/> bounds the total angle, so a joint twisted 60° about its own axis
    /// with no swing at all is inside its cone and entirely unconstrained — while the measured twist
    /// range for an elbow-class joint is near zero. This term fills that dead zone: it measures the
    /// twist about the child's CURRENT long axis in the parent's frame
    /// (<c>relative.Rotate(_aim[child])</c>), so a twist correction cannot move that axis and therefore
    /// cannot change the swing, and it acts only while the joint is INSIDE its total-angle cone — the
    /// regime where <see cref="SolveDeviation"/> is idle. The two terms are mutually exclusive, which
    /// is what keeps them from fighting each other the way the swing-twist split warned about above:
    /// outside the cone only the total-angle spring acts, inside it only the twist spring (and the weak
    /// pose-hold) act. The twist is NOT measured about the fixed rest axis, and NOT about
    /// <c>link.SwingAxis</c> — that is a swing datum (the cone's centre), not a twist axis.
    /// </para>
    /// <para>
    /// A soft spring at <see cref="JointStiffness"/>, not a hard wall: the same fraction-per-application
    /// as the total-angle term, applied through <c>ApplyAngular(repair: true)</c> so the correction is
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

        // The gate: inside the total-angle cone SolveDeviation is idle and the twist term owns the
        // roll; outside it the total-angle term owns the joint and the twist term stands down, so the
        // two never demand different corrections of the same rotation at once.
        float angle = 2f * MathF.Atan2(sine, relative.W);
        if (angle > link.SwingLimit)
        {
            return;
        }

        // The child's CURRENT long axis in the parent's frame. A rotation about this axis cannot move
        // it, so the twist correction is swing-neutral by construction.
        Vector3f aNow = relative.Rotate(_aim[link.Child]);
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
