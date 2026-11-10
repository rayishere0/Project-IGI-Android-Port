using System.Numerics;
using BepuPhysics;
using BepuPhysics.Collidables;
using BepuPhysics.CollisionDetection;
using BepuPhysics.Constraints;
using BepuUtilities;

namespace ProjectIGI.Game.Igi1.Physics;

/// <summary>What the narrow phase needs to know about one Bepu body to filter self-collision.</summary>
/// <param name="RagdollId">
/// Which corpse the body belongs to (≥ 0), or −1 for a body that is not a corpse at all — a
/// kinematic dynamic entry, which must collide with everything.
/// </param>
/// <param name="BoneIndex">The bone's index in its rig, or −1 for a non-corpse body.</param>
/// <param name="ParentBoneIndex">
/// The bone's parent in its rig, or −1 for the root and for non-corpse bodies. The filter rule
/// is adjacency, not hops: the rig only ever suppresses pairs under
/// <see cref="RagdollSkeleton.SelfCollisionSeparation"/> (2) hops apart, and under 2 hops means
/// 0 (the same bone, impossible for two bodies) or 1 — a direct parent/child pair, which the
/// joint already holds together.
/// </param>
internal readonly record struct BepuBodyTag(int RagdollId, int BoneIndex, int ParentBoneIndex)
{
    /// <summary>A tag for a body the filter knows nothing about: collide with everything.</summary>
    public static BepuBodyTag Unknown => new(-1, -1, -1);
}

/// <summary>
/// The self-collision tags, held outside the Bepu callbacks structs on purpose.
/// </summary>
/// <remarks>
/// <para>
/// Bepu takes the narrow-phase callbacks as a <c>struct</c> and stores a copy of it in the
/// simulation (verified in the 2.4.0 DLL: <c>Simulation.Create</c> calls
/// <c>INarrowPhaseCallbacks.Initialize</c> on the stored copy, via <c>ldflda</c> on the
/// <c>NarrowPhase&lt;&gt;.Callbacks</c> field — not on the caller's argument). A
/// <c>CollidableProperty&lt;T&gt;</c> held in the struct therefore cannot be written through the
/// caller's copy: <c>CollidableProperty.Initialize</c> allocates its per-copy buffers (sized to
/// the simulation's body capacity) in the copy it is called on, so tags allocated through the
/// caller's copy would land in arrays the narrow phase never reads.
/// </para>
/// <para>
/// This table is a reference type, so every copy of the callbacks struct — the caller's and the
/// simulation's — reads and writes the same table. It is indexed by <see cref="BodyHandle.Value"/>
/// and grows on demand; growth reallocates inside the table object, so no copy ever diverges.
/// Single host-loop thread only, like the rest of the ragdoll step; no locking.
/// </para>
/// </remarks>
internal sealed class BepuBodyTagTable
{
    private BepuBodyTag[] _tags = [];
    private bool[] _set = [];

    /// <summary>Records a body's tag. Called at seed time, before the first step that could see it.</summary>
    public void Set(BodyHandle handle, BepuBodyTag tag)
    {
        int index = handle.Value;
        if (index >= _tags.Length)
        {
            int capacity = Math.Max(index + 1, _tags.Length == 0 ? 64 : _tags.Length * 2);
            Array.Resize(ref _tags, capacity);
            Array.Resize(ref _set, capacity);
        }

        _tags[index] = tag;
        _set[index] = true;
    }

    /// <summary>Reads a body's tag, or <see cref="BepuBodyTag.Unknown"/> when none was recorded.</summary>
    public BepuBodyTag Get(BodyHandle handle)
    {
        int index = handle.Value;
        return index >= 0 && index < _tags.Length && _set[index] ? _tags[index] : BepuBodyTag.Unknown;
    }
}

/// <summary>
/// The narrow-phase callbacks for the ragdoll simulation: self-collision filtering and contact
/// material. Implements <see cref="INarrowPhaseCallbacks"/> directly — there is no base class in
/// 2.4.0 — as a struct, as <c>Simulation.Create</c> requires.
/// </summary>
internal struct BepuNarrowPhaseCallbacks : INarrowPhaseCallbacks
{
    /// <summary>The shared tag table. A reference, so the simulation's copy reads what the adapter wrote.</summary>
    public BepuBodyTagTable Tags = null!;

    /// <summary>Contact friction: <see cref="RagdollBody.Friction"/> (0.4), the same Coulomb coefficient.</summary>
    public const float ContactFriction = 0.4f;

    /// <summary>
    /// Maximum recovery velocity, 1.5 m/s — the XPBD depenetration cap
    /// (<see cref="RagdollBody.MaximumDepenetrationSpeed"/>, 205 units/tick ≈ 1.5 m/s) in Bepu units.
    /// </summary>
    public const float ContactMaxRecoveryVelocity = 1.5f;

    public void Initialize(Simulation simulation)
    {
        // Nothing to allocate: the tag table is shared by reference (see BepuBodyTagTable).
        // Bepu still calls this on the stored copy; it must exist and must not throw.
    }

    /// <summary>
    /// Self-collision filter: two bodies of the same corpse that are directly joined (parent/child)
    /// never generate contacts — the BallSocket between them already holds them together, and
    /// capsule overlap at a joint would only fight it. Every other pair collides: bones ≥ 2 hops
    /// apart in the same corpse, bodies of different corpses, corpses against kinematics and statics.
    /// </summary>
    public bool AllowContactGeneration(
        int workerIndex, CollidableReference a, CollidableReference b, ref float speculativeMargin)
    {
        if (a.Mobility == CollidableMobility.Static || b.Mobility == CollidableMobility.Static)
        {
            return true;
        }

        BepuBodyTag first = Tags.Get(a.BodyHandle);
        BepuBodyTag second = Tags.Get(b.BodyHandle);
        if (first.RagdollId < 0 || second.RagdollId < 0 || first.RagdollId != second.RagdollId)
        {
            return true;
        }

        return first.BoneIndex != second.ParentBoneIndex
            && second.BoneIndex != first.ParentBoneIndex;
    }

    /// <summary>No compound collidables exist in the prototype; every pair is allowed.</summary>
    public bool AllowContactGeneration(int workerIndex, CollidablePair pair, int childIndexA, int childIndexB) =>
        true;

    /// <summary>
    /// Contact material for every manifold: friction 0.4, no bounce. There is no restitution
    /// property in Bepu — zero bounce is approximated by the soft contact spring plus the low
    /// recovery velocity, exactly as the mapping doc prescribes. The spring (30 Hz, critically
    /// damped) is the demo's contact spring.
    /// </summary>
    /// <remarks>
    /// The generic constraint is verified from the 2.4.0 DLL metadata (GenericParam 569 on this
    /// method): <c>struct</c> + <c>IContactManifold&lt;TManifold&gt;</c>. The <c>unmanaged</c>
    /// spelling is the demo's; it carries the same two constraints.
    /// </remarks>
    public bool ConfigureContactManifold<TManifold>(
        int workerIndex, CollidablePair pair, ref TManifold manifold, ref PairMaterialProperties pairMaterial)
        where TManifold : unmanaged, IContactManifold<TManifold>
    {
        pairMaterial = new PairMaterialProperties(
            ContactFriction, ContactMaxRecoveryVelocity, new SpringSettings(30f, 1f));
        return true;
    }

    /// <summary>No compound collidables exist in the prototype; every manifold becomes a constraint.</summary>
    public bool ConfigureContactManifold(
        int workerIndex, CollidablePair pair, int childIndexA, int childIndexB, ref ConvexContactManifold manifold) =>
        true;

    public void Dispose()
    {
        // Nothing owned: the tag table belongs to the world, not to the callbacks struct.
    }
}

/// <summary>
/// The pose-integrator callbacks for the ragdoll simulation: gravity and damping. Implements
/// <see cref="IPoseIntegratorCallbacks"/> directly — there is no base class in 2.4.0 — as a
/// struct, as <c>Simulation.Create</c> requires.
/// </summary>
/// <remarks>
/// <para>
/// The simulation stores a copy of this struct (like the narrow-phase callbacks), and
/// <c>Simulation</c> exposes no accessor for it — so <see cref="Gravity"/> is read once, at
/// level load, from <c>g_ragdoll_gravity</c>. Changing the CVar mid-level does not move Bepu
/// corpses until the next level; the XPBD path reads it per tick, and that difference is
/// deliberate for the prototype rather than an oversight.
/// </para>
/// <para>
/// Damping is the XPBD per-tick survival fractions in continuous form: linear 0.99 and angular
/// 0.80 per tick become (1 − 0.3·dt) and (1 − 6·dt) per integration, which are exactly 0.99 and
/// 0.80 at dt = 1/30 s and compound correctly across substeps. It is applied on every
/// <see cref="IntegrateVelocity"/> call, including the bounding-box prediction pass (which also
/// integrates with the full frame dt) — as the demos do — so a body damps marginally more than
/// the bare per-tick numbers say. That is a first estimate to be measured, not a tuned value.
/// </para>
/// </remarks>
internal struct BepuPoseIntegratorCallbacks : IPoseIntegratorCallbacks
{
    /// <summary>Gravity in Bepu coords (0, −9.8 × g_ragdoll_gravity, 0), set at level load.</summary>
    public Vector3 Gravity;

    /// <summary>Linear survival per tick (<see cref="RagdollBody.LinearDamping"/>) as a rate: (1 − 0.99) × 30.</summary>
    public const float LinearDampingRate = 0.3f;

    /// <summary>Angular survival per tick (<see cref="RagdollBody.AngularDamping"/>) as a rate: (1 − 0.80) × 30.</summary>
    public const float AngularDampingRate = 6.0f;

    public readonly AngularIntegrationMode AngularIntegrationMode => AngularIntegrationMode.Nonconserving;

    public readonly bool AllowSubstepsForUnconstrainedBodies => false;

    public readonly bool IntegrateVelocityForKinematics => false;

    public void Initialize(Simulation simulation)
    {
    }

    public void PrepareForIntegration(float dt)
    {
        // Nothing to precompute: gravity and damping are functions of the per-call dt below.
    }

    public void IntegrateVelocity(
        Vector<int> bodyIndices, Vector3Wide position, QuaternionWide orientation, BodyInertiaWide localInertia,
        Vector<int> integrationMask, int workerIndex, Vector<float> dt, ref BodyVelocityWide velocity)
    {
        // Gravity: v += g·dt, per lane. Inactive lanes are discarded by the caller, so no masking.
        velocity.Linear.X += new Vector<float>(Gravity.X) * dt;
        velocity.Linear.Y += new Vector<float>(Gravity.Y) * dt;
        velocity.Linear.Z += new Vector<float>(Gravity.Z) * dt;

        // Damping: v *= (1 − rate·dt), per lane, linear and angular separately.
        velocity.Linear *= Vector<float>.One - (new Vector<float>(LinearDampingRate) * dt);
        velocity.Angular *= Vector<float>.One - (new Vector<float>(AngularDampingRate) * dt);
    }
}
