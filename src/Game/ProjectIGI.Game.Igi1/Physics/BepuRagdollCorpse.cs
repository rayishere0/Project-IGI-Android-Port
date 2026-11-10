using System.Numerics;
using BepuPhysics;
using BepuPhysics.Collidables;
using ProjectIGI.Core.Numerics;
using ProjectIGI.Formats.Animation;
using ProjectIGI.Game.Physics;

namespace ProjectIGI.Game.Igi1.Physics;

/// <summary>
/// One Bepu corpse: a set of bodies and constraints in the level simulation, seeded from the
/// same rig, pose and killing round as the XPBD corpse it replaces when the prototype flag is on.
/// </summary>
/// <remarks>
/// <para>
/// A corpse is seeded at rest (plus the killing impulse) and read back through the same
/// <see cref="BonePose.Evaluate"/> the XPBD pose uses, so the skinner, the shaders and the
/// previous-pose stream are untouched by either path. The readback needs three stacked
/// transforms per bone — basis change × alignment × COM shift — and they are all applied here,
/// in one place, mirroring <see cref="RagdollBody.Pose"/> exactly (local rotations as
/// parent⁻¹ × child, root position relative to the frozen <see cref="Origin"/>).
/// </para>
/// <para>
/// What Bepu has no equivalent for is deliberately NOT re-implemented here: the settle ramp, the
/// repair-spin exclusion, the total-angle spring and the leaf-first solve order (see the adapter
/// mapping §2/§6). The prototype relies on Bepu's solver plus sleep and lets the device test
/// decide whether that settles — that is the question the prototype exists to answer.
/// </para>
/// </remarks>
internal sealed class BepuRagdollCorpse
{
    /// <summary>How far a corpse may travel from where it died before it is abandoned — 100 m.</summary>
    /// <remarks>Same backstop as <see cref="RagdollBody.RunawayDistanceInUnits"/> (409,600 units).</remarks>
    public const double RunawayDistanceInMetres = 100.0;

    /// <summary>How many ticks a corpse may stay active — 10 s, the XPBD hard stop.</summary>
    /// <remarks>Same guarantee as <see cref="RagdollBody.MaximumActiveTicks"/> (300).</remarks>
    public const int MaximumActiveTicks = 300;

    private readonly BepuRagdollWorld _world;
    private readonly Quaternion32[] _local;
    private readonly Quaternion32[] _worldRotations;
    private readonly Quaternion32[] _alignmentInverse;
    private readonly Vector3f[] _centres;

    /// <summary>The rig this corpse wears. Its shapes are shared with every corpse wearing it.</summary>
    public RagdollSkeleton Rig { get; }

    /// <summary>Where the body died, in engine units — the frozen placement, as with the XPBD corpse.</summary>
    public Vector3d Origin { get; }

    /// <summary>The tick this corpse was seeded on, in the simulation's tick count.</summary>
    public int SeedTick { get; }

    /// <summary>The corpse's id, for the tag table and the log lines. −1 before it is seeded.</summary>
    public int Id { get; private set; } = -1;

    /// <summary>Assigns the id at seed time.</summary>
    internal void SetId(int id) => Id = id;

    /// <summary>The weapon capsule's shape, when a weapon body was built for this corpse.</summary>
    /// <remarks>Removed with the corpse; a shape is only ever added by the world that seeds it.</remarks>
    internal TypedIndex? WeaponShapeIndex { get; set; }

    /// <summary>The body handles, one per bone, plus the weapon body at index <see cref="Rig"/>.BoneCount when carried.</summary>
    public BodyHandle[] Bodies { get; }

    /// <summary>Whether the corpse carries a weapon body (a body of its own, jointed to the hand).</summary>
    public bool HasAttachment { get; }

    /// <summary>Whether the corpse is still a live part of the simulation.</summary>
    public bool IsValid { get; private set; } = true;

    /// <summary>Whether the corpse has come to rest (all bodies asleep, or the hard stop fired).</summary>
    public bool HasSettled { get; private set; }

    /// <summary>How many ticks from seed to rest, once <see cref="HasSettled"/> is true.</summary>
    public int TicksToSettle { get; private set; } = -1;

    /// <summary>Whether the rest was forced by the 10 s hard stop rather than by sleep.</summary>
    public bool SettledByHardStop { get; private set; }

    /// <summary>Whether the corpse has already been removed from the simulation.</summary>
    public bool Removed { get; private set; }

    internal BepuRagdollCorpse(
        BepuRagdollWorld world, RagdollSkeleton rig, Vector3d origin, int seedTick,
        BodyHandle[] bodies, bool hasAttachment, Quaternion32[] alignmentInverse, Vector3f[] centres)
    {
        _world = world;
        Rig = rig;
        Origin = origin;
        SeedTick = seedTick;
        Bodies = bodies;
        HasAttachment = hasAttachment;
        _alignmentInverse = alignmentInverse;
        _centres = centres;
        _local = new Quaternion32[rig.BoneCount];
        _worldRotations = new Quaternion32[rig.BoneCount];
    }

    /// <summary>Gets the body's centre of mass, in engine units — what the death camera frames.</summary>
    /// <remarks>
    /// The mass-weighted centre of the bodies' centres of mass, like
    /// <see cref="RagdollBody.Centre"/>. The carried weapon is not counted, as in the XPBD body.
    /// </remarks>
    public Vector3d Centre
    {
        get
        {
            Simulation simulation = _world.Simulation;
            Vector3d sum = Vector3d.Zero;
            double mass = 0.0;
            for (int bone = 0; bone < Rig.BoneCount; bone++)
            {
                double weight = 1.0 / Rig.BoneAt(bone).InverseMass;
                sum += BepuRagdollConversions.ToEnginePosition(simulation.Bodies[Bodies[bone]].Pose.Position) * weight;
                mass += weight;
            }

            return mass > 0.0 ? sum / mass : Origin;
        }
    }

    /// <summary>Gets where a bone's joint sits in the world, in engine units — the Bepu mirror of <see cref="RagdollBody.PositionOf"/>.</summary>
    /// <param name="bone">The bone index.</param>
    /// <returns>The joint position — the bone's own origin, not its centre of mass.</returns>
    /// <exception cref="ArgumentOutOfRangeException"><paramref name="bone"/> is not a bone of this rig.</exception>
    /// <remarks>
    /// The body's centre of mass less its rotated COM offset, the same subtraction
    /// <see cref="Pose"/> does for the root — read straight from the simulation bodies, so a
    /// sleeping corpse answers exactly as an awake one does.
    /// </remarks>
    public Vector3d JointOf(int bone)
    {
        ArgumentOutOfRangeException.ThrowIfNegative(bone);
        ArgumentOutOfRangeException.ThrowIfGreaterThanOrEqual(bone, Rig.BoneCount);
        Simulation simulation = _world.Simulation;
        Quaternion32 rotation = (BepuRagdollConversions.ToEngineQuaternion(simulation.Bodies[Bodies[bone]].Pose.Orientation) * _alignmentInverse[bone]).Normalized();
        Vector3d centre = BepuRagdollConversions.ToEnginePosition(simulation.Bodies[Bodies[bone]].Pose.Position);
        Vector3f offset = RagdollSolver.Rotate(BonePose.ToMatrix(rotation), _centres[bone]);
        return centre - new Vector3d(offset.X, offset.Y, offset.Z);
    }

    /// <summary>Gets one bone's capsule in world space, for the corpse queries — the Bepu mirror of <see cref="RagdollBody.CapsuleOf"/>.</summary>
    /// <param name="bone">The bone index.</param>
    /// <param name="axisA">One end of the capsule's central axis, in engine units.</param>
    /// <param name="axisB">The other end of the capsule's central axis, in engine units.</param>
    /// <param name="radius">The capsule's radius, in engine units.</param>
    /// <exception cref="ArgumentOutOfRangeException"><paramref name="bone"/> is not a bone of this rig.</exception>
    /// <remarks>
    /// The same capsule the shapes were built from: centred on the body's centre of mass, along
    /// its rotated aim for half its length either way, radius the rig's — read straight from the
    /// simulation bodies, asleep or awake.
    /// </remarks>
    public void CapsuleOf(int bone, out Vector3d axisA, out Vector3d axisB, out double radius)
    {
        ArgumentOutOfRangeException.ThrowIfNegative(bone);
        ArgumentOutOfRangeException.ThrowIfGreaterThanOrEqual(bone, Rig.BoneCount);
        Simulation simulation = _world.Simulation;
        Quaternion32 rotation = (BepuRagdollConversions.ToEngineQuaternion(simulation.Bodies[Bodies[bone]].Pose.Orientation) * _alignmentInverse[bone]).Normalized();
        Vector3d centre = BepuRagdollConversions.ToEnginePosition(simulation.Bodies[Bodies[bone]].Pose.Position);
        RagdollBone shape = Rig.BoneAt(bone);
        Vector3f along = RagdollSolver.Rotate(BonePose.ToMatrix(rotation), shape.Aim) * shape.HalfLength;
        Vector3d step = new(along.X, along.Y, along.Z);
        axisA = centre - step;
        axisB = centre + step;
        radius = shape.Radius;
    }

    /// <summary>Marks the corpse invalid: it has run away and the death clip takes over the drawing.</summary>
    internal void MarkInvalid() => IsValid = false;

    /// <summary>Marks the corpse removed: its bodies are out of the simulation.</summary>
    internal void MarkRemoved() => Removed = true;

    /// <summary>Marks the corpse settled, recording how long it took.</summary>
    internal void MarkSettled(int ageTicks, bool byHardStop)
    {
        HasSettled = true;
        TicksToSettle = ageTicks;
        SettledByHardStop = byHardStop;
    }

    /// <summary>Whether every body of this corpse is asleep (out of the active set) right now.</summary>
    public bool AllAsleep()
    {
        Simulation simulation = _world.Simulation;
        foreach (BodyHandle handle in Bodies)
        {
            if (simulation.Bodies[handle].Awake)
            {
                return false;
            }
        }

        return true;
    }

    /// <summary>How far the root body has travelled from where it died, in metres.</summary>
    public double RootDistanceFromOriginInMetres()
    {
        Vector3 root = _world.Simulation.Bodies[Bodies[0]].Pose.Position;
        Vector3 origin = BepuRagdollConversions.ToBepuPosition(Origin);
        return (root - origin).Length();
    }

    /// <summary>Forces every body of this corpse asleep (the 10 s hard stop).</summary>
    public void ForceSleep()
    {
        Simulation simulation = _world.Simulation;
        foreach (BodyHandle handle in Bodies)
        {
            BodyReference body = simulation.Bodies[handle];
            body.Awake = false;
        }
    }

    /// <summary>Adds a velocity to every body — the body's own motion at the moment it died.</summary>
    /// <remarks>
    /// Mirrors <see cref="RagdollBody.AddVelocity"/>: the same velocity for every bone, so the
    /// corpse travels as a piece. Written directly to <c>Velocity.Linear</c> (there is no "add
    /// velocity" API) and every body is woken explicitly — Bepu impulse/velocity writes do not
    /// wake a body.
    /// </remarks>
    public void AddVelocity(Vector3d velocityPerTick)
    {
        Vector3 velocity = BepuRagdollConversions.ToBepuVelocity(velocityPerTick);
        Simulation simulation = _world.Simulation;
        foreach (BodyHandle handle in Bodies)
        {
            BodyReference body = simulation.Bodies[handle];
            body.Velocity.Linear += velocity;
            body.Awake = true;
        }
    }

    /// <summary>
    /// Pushes the corpse with the round that killed it, in SI units.
    /// </summary>
    /// <param name="bone">The bone the round went through; −1 pushes the root instead.</param>
    /// <param name="travel">The round's own line, from the muzzle towards where it ended.</param>
    /// <param name="momentumSi">
    /// The momentum in newton-seconds × cinematic scale × <c>g_ragdoll_force</c>, in kg·m/s —
    /// the XPBD <see cref="RagdollImpulse.MomentumOf"/> with the engine-units round-trip removed.
    /// </param>
    /// <remarks>
    /// Mirrors <see cref="RagdollImpulse.Apply"/> exactly: the body share (0.85) as a uniform
    /// velocity over every bone, the local share (0.15) as momentum per bone, spread 0.55 per hop
    /// out to 6 hops and normalised so the total received equals the total asked. The local share
    /// is applied with <c>ApplyLinearImpulse</c> — at the centre of mass, linear only — never
    /// <c>ApplyImpulse</c> with an offset, which would add spin the model deliberately does not
    /// add. Every body is woken explicitly after its impulse.
    /// </remarks>
    public void ApplyImpulse(int bone, Vector3d travel, double momentumSi)
    {
        Vector3d direction = travel.Normalized();
        if (direction.LengthSquared <= 0.0 || momentumSi == 0.0)
        {
            return;
        }

        Simulation simulation = _world.Simulation;

        // The throw: the same velocity for every bone, so the corpse travels as one piece.
        Vector3 bodyVelocity = BepuRagdollConversions.ToBepuDirection(direction)
            * (float)(momentumSi * RagdollImpulse.BodyShare / Rig.TotalMass);
        foreach (BodyHandle handle in Bodies)
        {
            BodyReference body = simulation.Bodies[handle];
            body.Velocity.Linear += bodyVelocity;
            body.Awake = true;
        }

        int struck = bone >= 0 && bone < Rig.BoneCount ? bone : 0;
        double total = 0.0;
        for (int other = 0; other < Rig.BoneCount; other++)
        {
            int hops = Rig.HopsBetween(struck, other);
            if (hops <= RagdollImpulse.SpreadReach)
            {
                total += Math.Pow(RagdollImpulse.SpreadPerHop, hops);
            }
        }

        if (total <= 0.0)
        {
            return;
        }

        // And the snap, around the bone it went through.
        Vector3 impulseDirection = BepuRagdollConversions.ToBepuDirection(direction);
        double local = momentumSi * (1.0 - RagdollImpulse.BodyShare) / total;
        for (int other = 0; other < Rig.BoneCount; other++)
        {
            int hops = Rig.HopsBetween(struck, other);
            if (hops > RagdollImpulse.SpreadReach)
            {
                continue;
            }

            BodyReference body = simulation.Bodies[Bodies[other]];
            body.ApplyLinearImpulse(
                impulseDirection * (float)(local * Math.Pow(RagdollImpulse.SpreadPerHop, hops)));
            body.Awake = true;
        }
    }

    /// <summary>The pose the corpse is drawn from this tick — its rig's, or the Bepu bodies'.</summary>
    /// <remarks>
    /// Mirrors <see cref="RagdollBody.Pose"/>: per-bone local rotations (parent⁻¹ × child) fed to
    /// <see cref="BonePose.Evaluate"/>, with the root position relative to the frozen
    /// <see cref="Origin"/>. Three stacked transforms per bone: the Bepu body orientation is
    /// conjugated back to engine coords, the alignment rotation is removed (a Bepu body faces
    /// along its capsule Y; a bone faces along its aim), and the centre-of-mass shift is removed
    /// (a Bepu body sits at its COM; a bone's origin is its joint).
    /// </remarks>
    public BonePose Pose()
    {
        Simulation simulation = _world.Simulation;
        for (int bone = 0; bone < Rig.BoneCount; bone++)
        {
            Quaternion32 bodyEngine =
                BepuRagdollConversions.ToEngineQuaternion(simulation.Bodies[Bodies[bone]].Pose.Orientation);
            _worldRotations[bone] = (bodyEngine * _alignmentInverse[bone]).Normalized();
        }

        for (int bone = 0; bone < Rig.BoneCount; bone++)
        {
            int parent = Rig.Skeleton.Parents[bone];
            Quaternion32 above = parent == BoneSkeleton.NoParent
                ? Quaternion32.Identity
                : _worldRotations[parent];
            _local[bone] = (above.Conjugate() * _worldRotations[bone]).Normalized();
        }

        // Root joint = root COM − (root orientation × root COM offset), relative to the origin.
        Vector3 rootComMetres = simulation.Bodies[Bodies[0]].Pose.Position;
        Vector3d rootComUnits = BepuRagdollConversions.ToEnginePosition(rootComMetres);
        Matrix3f rootRotation = BonePose.ToMatrix(_worldRotations[0]);
        Vector3f centre = RagdollSolver.Rotate(rootRotation, _centres[0]);
        Vector3d root = rootComUnits - new Vector3d(centre.X, centre.Y, centre.Z) - Origin;
        return BonePose.Evaluate(
            Rig.Skeleton,
            _local,
            new Vector3f((float)root.X, (float)root.Y, (float)root.Z));
    }

    /// <summary>Gets where the carried weapon's own origin sits, relative to <see cref="Origin"/>.</summary>
    /// <remarks>
    /// Mirrors <see cref="RagdollBody.AttachmentPosition"/>: the carried body's origin is its hand
    /// joint — COM minus the rotated COM offset — relative to the corpse's origin.
    /// </remarks>
    public Vector3f AttachmentPosition
    {
        get
        {
            if (!HasAttachment)
            {
                return default;
            }

            int slot = Rig.BoneCount;
            Vector3 carriedComMetres = _world.Simulation.Bodies[Bodies[slot]].Pose.Position;
            Vector3d carriedComUnits = BepuRagdollConversions.ToEnginePosition(carriedComMetres);
            Quaternion32 bodyEngine = BepuRagdollConversions.ToEngineQuaternion(
                _world.Simulation.Bodies[Bodies[slot]].Pose.Orientation);
            Matrix3f rotation = BonePose.ToMatrix((bodyEngine * _alignmentInverse[slot]).Normalized());
            Vector3f centre = RagdollSolver.Rotate(rotation, _centres[slot]);
            Vector3d at = carriedComUnits - new Vector3d(centre.X, centre.Y, centre.Z) - Origin;
            return new Vector3f((float)at.X, (float)at.Y, (float)at.Z);
        }
    }

    /// <summary>Gets which way the carried weapon is facing.</summary>
    /// <remarks>Mirrors <see cref="RagdollBody.AttachmentRotation"/>.</remarks>
    public Matrix3f AttachmentRotation
    {
        get
        {
            if (!HasAttachment)
            {
                return Matrix3f.Identity;
            }

            int slot = Rig.BoneCount;
            Quaternion32 bodyEngine = BepuRagdollConversions.ToEngineQuaternion(
                _world.Simulation.Bodies[Bodies[slot]].Pose.Orientation);
            return BonePose.ToMatrix((bodyEngine * _alignmentInverse[slot]).Normalized());
        }
    }
}
