using System.Diagnostics;
using System.Numerics;
using BepuPhysics;
using BepuPhysics.Collidables;
using BepuPhysics.Constraints;
using BepuUtilities;
using BepuUtilities.Memory;
using ProjectIGI.Core.Diagnostics;
using ProjectIGI.Core.Numerics;
using ProjectIGI.Formats.Animation;
using ProjectIGI.Game;
using ProjectIGI.Game.Physics;
using ProjectIGI.Game.World;

namespace ProjectIGI.Game.Igi1.Physics;

/// <summary>
/// One Bepu <see cref="Simulation"/> per level: the static level mesh, the kinematic dynamic
/// entries, and every corpse seeded into it. Created at level load, stepped once per tick,
/// disposed at level unload — beside the XPBD world, behind the <c>g_ragdoll_bepu</c> flag.
/// </summary>
/// <remarks>
/// <para>
/// This is the prototype, not an integration: it answers, with measurements from Ray's device,
/// whether a whole level builds as a static mesh, whether contacts work on terrain and placed
/// objects, whether dynamic entries work as kinematic bodies, and whether a Bepu corpse settles
/// and stays settled. Everything it needs to answer that is logged at the sites below; nothing
/// here guesses a number the device has to measure.
/// </para>
/// <para>
/// Winding — the one-sided trap. Bepu mesh triangles generate contacts only from the front
/// face, whose normal is n = (C − A) × (B − A) (2.4.0 DLL, <c>TriangleWide.RayTest</c>). The
/// engine's own triangle normal is (B − A) × (C − A) (<c>RigidMeshBody</c>), so the two
/// conventions are opposite: a triangle whose engine normal points out of its solid has its
/// Bepu front face pointing into it. The engine's collision meshes "wind into the solid" and
/// terrain "winds out of it" (<c>CollisionTriangle</c>), so the derived default is placed
/// as-gathered, terrain flipped — and because that derivation rests on reading "winds into/out
/// of" as a statement about the (B − A) × (C − A) normal, it is a derivation, not a measurement.
/// <c>g_ragdoll_bepu_wind</c> exists so Ray can A/B it on device without a rebuild: 0 = the
/// derived default, 1 = both as-gathered, 2 = both flipped. The mode in force is logged per
/// source at level load, and a body falling through a surface is the signal to try another.
/// </para>
/// </remarks>
internal sealed class BepuRagdollWorld : IDisposable
{
    /// <summary>The logger category the soldier logs already use.</summary>
    public const string LogCategory = "Soldier";

    /// <summary>How many solver velocity iterations each substep takes — the demo's 8.</summary>
    public const int VelocityIterations = 8;

    /// <summary>Speculative margin for corpse bodies, 1 cm — the demo's value.</summary>
    public const float SpeculativeMarginMetres = 0.01f;

    /// <summary>
    /// Sleep threshold, squared velocity — the XPBD rest latch (20 units/tick ≈ 0.146 m/s average
    /// bone speed) mapped to Bepu's |v|² + |ω|²: 0.146² ≈ 0.021. A first estimate to be measured.
    /// </summary>
    public const float SleepThreshold = 0.021f;

    /// <summary>Timesteps under the sleep threshold before a body may sleep — the XPBD 12 ticks.</summary>
    public const byte SleepMinTimesteps = 12;

    /// <summary>How far past the placed-objects union the mesh gather reaches, in metres.</summary>
    /// <remarks>
    /// A corpse thrown 100 m is already runaway-invalid, so 128 m past the built area covers
    /// every surface a live corpse can reach, plus the surrounding terrain it could be thrown onto.
    /// </remarks>
    public const double GatherMarginMetres = 128.0;

    /// <summary>How far a placed sphere's centre may sit from the level's median centre before it is a stray.</summary>
    /// <remarks>
    /// The <c>WorldScene</c> trap: one unplaced object at (0, 0, 0) drags the level's bounds out
    /// by kilometres. Anything 2 km from the median is not part of the level a corpse can reach.
    /// </remarks>
    public const double StrayDistanceMetres = 2000.0;

    /// <summary>Most bodies one level may hold before seeding refuses — far above any real level.</summary>
    /// <remarks>
    /// Guards the tag table (indexed by body handle) and the simulation's default 4096-body
    /// capacity. A level holds tens of corpses × ~34 bodies plus tens of kinematics.
    /// </remarks>
    public const int MaxBodiesPerLevel = 4000;

    private readonly BufferPool _pool;
    private readonly BepuBodyTagTable _tags;
    private readonly Dictionary<RagdollSkeleton, BepuRigShapes> _rigs = [];
    private readonly List<BepuRagdollCorpse> _corpses = [];
    private readonly Dictionary<(object Owner, string Name), BepuKinematicEntry> _kinematics = [];
    private readonly HashSet<(object Owner, string Name)> _skippedKinematics = [];
    private readonly List<DynamicCollisionSnapshot> _scratchSnapshots = [];
    private readonly List<DynamicEntryPose> _scratchPoses = [];
    private readonly IProjectIGILogger _logger;
    private readonly ObjectCollisionIndex? _solids;

    private readonly List<(TypedIndex Shape, StaticHandle Static)> _meshStatics = [];

    private int _lastSteppedTick = int.MinValue;
    private int _tick;
    private int _nextRagdollId;
    private int _lastDynamicCount = -1;
    private double _lastStepMs;
    private bool _disposed;

    /// <summary>Gets the simulation the corpses live in.</summary>
    public Simulation Simulation { get; }

    /// <summary>Gets how many corpses are live in the simulation right now.</summary>
    public int CorpseCount => _corpses.Count;

    /// <summary>Gets how many kinematic dynamic entries are live right now.</summary>
    public int KinematicCount => _kinematics.Count;

    private BepuRagdollWorld(
        BufferPool pool, Simulation simulation, IProjectIGILogger logger, ObjectCollisionIndex? solids,
        BepuBodyTagTable tags)
    {
        _pool = pool;
        Simulation = simulation;
        _logger = logger;
        _solids = solids;
        // The one table: the callbacks struct holds this same reference, so tags written here are
        // the tags the simulation's copy of the callbacks reads (see BepuBodyTagTable).
        _tags = tags;
    }

    /// <summary>
    /// Builds the level simulation: gathers the whole level as triangles, re-winds them to
    /// Bepu's front-face convention, and adds them as static meshes.
    /// </summary>
    /// <param name="solids">The placed-object collision index, or null when the level has none.</param>
    /// <param name="terrain">The level terrain, or null (level 14) when there is none.</param>
    /// <param name="logger">Where the measurements go.</param>
    /// <returns>The world, or null when the level cannot be built (zero triangles, no solids).</returns>
    /// <remarks>
    /// A build failure never breaks the level: the caller falls back to the XPBD solver and the
    /// log says why. All exceptions are caught here, for the same reason — a prototype must not
    /// take a level load down with it.
    /// </remarks>
    public static BepuRagdollWorld? Build(
        ObjectCollisionIndex? solids, TerrainData? terrain, IProjectIGILogger logger)
    {
        try
        {
            return BuildCore(solids, terrain, logger);
        }
        catch (Exception ex)
        {
            logger.Warning(LogCategory, $"[BepuRagdoll] level mesh build failed ({ex.GetType().Name}: {ex.Message}); Bepu ragdolls are off for this level, XPBD continues.");
            return null;
        }
    }

    private static BepuRagdollWorld? BuildCore(
        ObjectCollisionIndex? solids, TerrainData? terrain, IProjectIGILogger logger)
    {
        if (solids is null || solids.Count == 0)
        {
            logger.Warning(LogCategory, "[BepuRagdoll] level mesh build failed: no placed collision index; Bepu ragdolls are off for this level, XPBD continues.");
            return null;
        }

        (Vector3d Min, Vector3d Max) box = ComputeLevelBox(solids, logger, out int strays);
        if (double.IsInfinity(box.Min.X) || double.IsInfinity(box.Max.X))
        {
            logger.Warning(LogCategory, "[BepuRagdoll] level mesh build failed: every placed sphere was a stray; Bepu ragdolls are off for this level, XPBD continues.");
            return null;
        }

        Vector3d margin = new(
            GatherMarginMetres * BepuRagdollConversions.UnitsPerMetre,
            GatherMarginMetres * BepuRagdollConversions.UnitsPerMetre,
            GatherMarginMetres * BepuRagdollConversions.UnitsPerMetre);
        Vector3d min = box.Min - margin;
        Vector3d max = box.Max + margin;

        List<CollisionTriangle> placed = [];
        Stopwatch watch = Stopwatch.StartNew();
        solids.CollectStaticTriangles(min, max, placed);
        double placedMs = watch.Elapsed.TotalMilliseconds;

        List<CollisionTriangle> terrainTriangles = [];
        watch.Restart();
        if (terrain is not null)
        {
            TerrainRayTrace.CollectTriangles(terrain, min, max, terrainTriangles);
        }

        double terrainMs = watch.Elapsed.TotalMilliseconds;
        int total = placed.Count + terrainTriangles.Count;
        if (total == 0)
        {
            logger.Warning(LogCategory, "[BepuRagdoll] level mesh build failed: the whole-level gather returned zero triangles; Bepu ragdolls are off for this level, XPBD continues. (An empty mesh is a build failure, not an empty world — corpses would fall, then sleep in mid-air.)");
            return null;
        }

        int wind = GameplayCVars.RagdollBepuWinding.Value;
        bool flipPlaced = wind == 2;
        bool flipTerrain = wind == 2 || wind == 0;
        string placedWind = flipPlaced ? "flipped" : "as-gathered";
        string terrainWind = flipTerrain ? "flipped" : "as-gathered";

        BufferPool pool = new();
        BepuBodyTagTable tags = new();
        BepuNarrowPhaseCallbacks narrow = new() { Tags = tags };
        float gravity = GameplayCVars.RagdollGravity.Value;
        BepuPoseIntegratorCallbacks pose = new()
        {
            Gravity = new Vector3(0f, -9.8f * gravity, 0f),
        };
        int substeps = Math.Clamp(GameplayCVars.RagdollSubsteps.Value, 1, 64);
        Simulation simulation = Simulation.Create(
            pool, narrow, pose, new SolveDescription(VelocityIterations, substeps));

        BepuRagdollWorld world = new(pool, simulation, logger, solids, tags);

        watch.Restart();
        if (placed.Count > 0)
        {
            world.AddMesh(placed, flipPlaced);
        }

        if (terrainTriangles.Count > 0)
        {
            world.AddMesh(terrainTriangles, flipTerrain);
        }

        double meshMs = watch.Elapsed.TotalMilliseconds;

        double upm = BepuRagdollConversions.UnitsPerMetre;
        logger.Information(LogCategory,
            $"[BepuRagdoll] level mesh: placed={placed.Count} terrain={terrainTriangles.Count} total={total} "
            + $"gatherPlaced={placedMs:F1}ms gatherTerrain={terrainMs:F1}ms mesh={meshMs:F1}ms "
            + $"boxMin=({min.X / upm:F0},{min.Y / upm:F0},{min.Z / upm:F0})m boxMax=({max.X / upm:F0},{max.Y / upm:F0},{max.Z / upm:F0})m "
            + $"wind=placed:{placedWind}/terrain:{terrainWind} (mode {wind}) straysDropped={strays} "
            + $"dynamics={solids.DynamicEntryCount} gravity={gravity} substeps={substeps}");
        if (placed.Count == 0 || terrainTriangles.Count == 0)
        {
            logger.Warning(LogCategory,
                $"[BepuRagdoll] level mesh is partial: placed={placed.Count} terrain={terrainTriangles.Count} — "
                + "a zero source means that surface does not exist for Bepu corpses on this level.");
        }

        world.RebuildKinematics();
        world._lastDynamicCount = solids.DynamicEntryCount;
        return world;
    }

    /// <summary>
    /// The level box: the union of the placed objects' bounding spheres, with strays dropped.
    /// </summary>
    /// <remarks>
    /// There is no whole-level bounds source anywhere in the code, so this computes one: the
    /// median centre first (a stray at the origin must not move the middle), then every sphere
    /// further than <see cref="StrayDistanceMetres"/> from it is dropped and counted, then the
    /// union of what is left. Terrain is gathered inside this box (expanded by the margin) — the
    /// terrain has no bounds of its own to read, and hills outside the built area are only
    /// reachable by a corpse that is already runaway-invalid.
    /// </remarks>
    private static (Vector3d Min, Vector3d Max) ComputeLevelBox(
        ObjectCollisionIndex solids, IProjectIGILogger logger, out int strays)
    {
        List<Vector3d> centres = [];
        List<(Vector3d Centre, double Radius)> spheres = [];
        for (int i = 0; i < solids.Count; i++)
        {
            (Vector3d centre, double radius) = solids.Bounds(i);
            centres.Add(centre);
            spheres.Add((centre, radius));
        }

        double Median(IReadOnlyList<double> values)
        {
            List<double> sorted = [.. values];
            sorted.Sort();
            return sorted[sorted.Count / 2];
        }

        Vector3d median = new(
            Median(centres.ConvertAll(c => c.X)),
            Median(centres.ConvertAll(c => c.Y)),
            Median(centres.ConvertAll(c => c.Z)));
        double strayUnits = StrayDistanceMetres * BepuRagdollConversions.UnitsPerMetre;

        Vector3d min = new(double.PositiveInfinity, double.PositiveInfinity, double.PositiveInfinity);
        Vector3d max = new(double.NegativeInfinity, double.NegativeInfinity, double.NegativeInfinity);
        strays = 0;
        foreach ((Vector3d centre, double radius) in spheres)
        {
            if ((centre - median).Length > strayUnits)
            {
                strays++;
                continue;
            }

            min = new Vector3d(
                Math.Min(min.X, centre.X - radius),
                Math.Min(min.Y, centre.Y - radius),
                Math.Min(min.Z, centre.Z - radius));
            max = new Vector3d(
                Math.Max(max.X, centre.X + radius),
                Math.Max(max.Y, centre.Y + radius),
                Math.Max(max.Z, centre.Z + radius));
        }

        if (strays > 0)
        {
            logger.Information(LogCategory,
                $"[BepuRagdoll] level box: dropped {strays} stray sphere(s) over {StrayDistanceMetres:F0}m from the median centre.");
        }

        return (min, max);
    }

    /// <summary>Adds one source's triangles as a static mesh, re-wound per the winding mode.</summary>
    /// <remarks>
    /// The flip swaps B and C: (C − A) × (B − A) changes sign, so the front face points the other
    /// way. Triangles go in a pooled <c>Buffer&lt;Triangle&gt;</c> — 2.4.0 has no
    /// <c>Triangle[]</c> constructor and no <c>MeshLoader</c>; the mesh keeps the buffer, so it
    /// is never returned to the pool while the world lives.
    /// </remarks>
    private void AddMesh(List<CollisionTriangle> triangles, bool flip)
    {
        _pool.Take<Triangle>(triangles.Count, out Buffer<Triangle> buffer);
        for (int i = 0; i < triangles.Count; i++)
        {
            CollisionTriangle t = triangles[i];
            Vector3 a = BepuRagdollConversions.ToBepuPosition(t.A);
            Vector3 b = BepuRagdollConversions.ToBepuPosition(t.B);
            Vector3 c = BepuRagdollConversions.ToBepuPosition(t.C);
            buffer[i] = flip ? new Triangle(a, c, b) : new Triangle(a, b, c);
        }

        Vector3 scale = Vector3.One;
        Mesh mesh = new(buffer, scale, _pool);
        TypedIndex shape = Simulation.Shapes.Add(mesh);
        StaticHandle handle = Simulation.Statics.Add(
            new StaticDescription(new RigidPose(Vector3.Zero, Quaternion.Identity), shape));
        _meshStatics.Add((shape, handle));
    }

    /// <summary>
    /// Seeds a Bepu corpse from the same rig, pose and killing round as the XPBD seed.
    /// </summary>
    /// <returns>The corpse, or null when the world cannot take another body.</returns>
    /// <remarks>
    /// The seed tick is the world's own step count — the age in <see cref="StepOnce"/> is counted
    /// in simulated ticks, so a pause (no steps) does not age a corpse toward its hard stop.
    /// </remarks>
    public BepuRagdollCorpse? SeedCorpse(
        RagdollSkeleton rig, BonePose pose, Vector3d origin, Matrix3f orientation,
        RagdollBone? attachment, int host)
    {
        ObjectDisposedException.ThrowIf(_disposed, this);
        int count = rig.BoneCount + (attachment is null ? 0 : 1);
        int bodies = count;
        foreach (BepuRagdollCorpse existing in _corpses)
        {
            bodies += existing.Bodies.Length;
        }

        if (bodies > MaxBodiesPerLevel)
        {
            _logger.Warning(LogCategory, "[BepuRagdoll] corpse refused: the level is at its body budget; the death clip plays instead.");
            return null;
        }

        BepuRigShapes shapes = RigShapesFor(rig);
        int id = _nextRagdollId++;
        BodyHandle[] handles = new BodyHandle[count];
        Quaternion32[] alignmentInverse = new Quaternion32[count];
        Vector3f[] centres = new Vector3f[count];

        // A failed seed must not leave bodies behind: the caller falls back to the death clip,
        // and untracked bodies would simulate (then sleep) for the rest of the level.
        int addedBodies = 0;
        TypedIndex? weaponShape = null;
        try
        {
            for (int bone = 0; bone < rig.BoneCount; bone++)
            {
                RagdollBone shape = rig.BoneAt(bone);
                handles[bone] = AddBoneBody(id, bone, shape, shapes, rig, pose, origin, orientation);
                addedBodies++;
                alignmentInverse[bone] = shapes.AlignmentInverse[bone];
                centres[bone] = shape.Centre;
            }

            if (attachment is { } carried)
            {
                int slot = rig.BoneCount;
                handles[slot] = AddAttachmentBody(id, slot, host, carried, rig, pose, origin, orientation, out weaponShape);
                addedBodies++;
                alignmentInverse[slot] = shapes.AlignmentInverseFor(carried);
                centres[slot] = carried.Centre;
            }

            for (int j = 0; j < rig.Joints.Count; j++)
            {
                RagdollJoint joint = rig.Joints[j];
                AddJoint(handles[joint.Parent], handles[joint.Child], shapes, j);
            }

            if (attachment is not null)
            {
                AddGripJoint(handles[host], handles[rig.BoneCount], rig, attachment.Value, host);
            }
        }
        catch
        {
            for (int i = 0; i < addedBodies; i++)
            {
                Simulation.Bodies.Remove(handles[i]);
            }

            if (weaponShape is { } shape)
            {
                Simulation.Shapes.Remove(shape);
            }

            throw;
        }

        BepuRagdollCorpse corpse = new(
            this, rig, origin, _tick, handles, attachment is not null, alignmentInverse, centres)
        {
            WeaponShapeIndex = weaponShape,
        };
        corpse.SetId(id);
        _corpses.Add(corpse);
        _logger.Information(LogCategory,
            $"[BepuRagdoll] corpse={id} seeded bones={rig.BoneCount} attachment={attachment is not null} "
            + $"origin=({origin.X / BepuRagdollConversions.UnitsPerMetre:F1},{origin.Y / BepuRagdollConversions.UnitsPerMetre:F1},{origin.Z / BepuRagdollConversions.UnitsPerMetre:F1})m");
        return corpse;
    }

    private BodyHandle AddBoneBody(
        int ragdollId, int bone, RagdollBone shape, BepuRigShapes shapes,
        RagdollSkeleton rig, BonePose pose, Vector3d origin, Matrix3f orientation)
    {
        (Vector3 position, Quaternion rotation) = SeedTransform(
            shape, pose, origin, orientation, bone, shapes.Alignment[bone]);
        BodyInertia inertia = new()
        {
            InverseMass = shape.InverseMass,
            InverseInertiaTensor = shapes.Inertia[bone],
        };
        BodyDescription description = BodyDescription.CreateDynamic(
            new RigidPose(position, rotation),
            new BodyVelocity(Vector3.Zero),
            inertia,
            new CollidableDescription(shapes.Shapes[bone], SpeculativeMarginMetres),
            new BodyActivityDescription(SleepThreshold, SleepMinTimesteps));
        BodyHandle handle = Simulation.Bodies.Add(description);
        int parent = rig.Skeleton.Parents[bone];
        _tags.Set(handle, new BepuBodyTag(ragdollId, bone, parent));
        return handle;
    }

    private BodyHandle AddAttachmentBody(
        int ragdollId, int slot, int host, RagdollBone carried,
        RagdollSkeleton rig, BonePose pose, Vector3d origin, Matrix3f orientation,
        out TypedIndex? weaponShape)
    {
        // The weapon hangs off the hand bone: its seed transform is the hand's joint plus its own
        // centre, exactly as RagdollBody.Seed places it — rotation[slot] = rotation[host], so the
        // carried body's frame IS the hand's frame, and its Bepu orientation is the hand's world
        // orientation times the carried bone's alignment (the capsule Y must land on its aim).
        Matrix3f hostWorld = orientation * pose.Rotations[host];
        Matrix3f alignment = BepuRagdollConversions.AlignmentMatrix(carried.Aim, carried.Reference);
        Matrix3f world = hostWorld * alignment;
        Vector3f joint = RagdollSolver.Rotate(orientation, pose.Positions[host]);
        Vector3f centre = RagdollSolver.Rotate(hostWorld, carried.Centre);
        Vector3d comUnits = origin + new Vector3d(
            joint.X + centre.X, joint.Y + centre.Y, joint.Z + centre.Z);

        float radiusMetres = carried.Radius / (float)BepuRagdollConversions.UnitsPerMetre;
        float lengthMetres = 2f * carried.HalfLength / (float)BepuRagdollConversions.UnitsPerMetre;
        weaponShape = Simulation.Shapes.Add(new Capsule(radiusMetres, lengthMetres));
        BodyInertia inertia = new()
        {
            InverseMass = carried.InverseMass,
            InverseInertiaTensor = ConvertInertia(carried.InverseInertia, alignment),
        };
        BodyDescription description = BodyDescription.CreateDynamic(
            new RigidPose(
                BepuRagdollConversions.ToBepuPosition(comUnits),
                BepuRagdollConversions.ToBepuQuaternion(world)),
            new BodyVelocity(Vector3.Zero),
            inertia,
            new CollidableDescription(weaponShape.Value, SpeculativeMarginMetres),
            new BodyActivityDescription(SleepThreshold, SleepMinTimesteps));
        BodyHandle handle = Simulation.Bodies.Add(description);
        _tags.Set(handle, new BepuBodyTag(ragdollId, slot, host));
        return handle;
    }

    /// <summary>The seed transform of one bone: its COM in Bepu metres, and its body orientation.</summary>
    /// <remarks>
    /// Mirrors <see cref="RagdollBody.Seed"/> exactly — joint position plus the COM offset, in
    /// world space — then converts: the COM is the Bepu body position (a Bepu body sits at its
    /// centre of mass), and the orientation is the bone's world orientation times the alignment
    /// rotation (a Bepu capsule runs along Y; a bone runs along its aim), conjugated into Bepu coords.
    /// </remarks>
    private static (Vector3 Position, Quaternion Rotation) SeedTransform(
        RagdollBone shape, BonePose pose, Vector3d origin, Matrix3f orientation,
        int bone, Matrix3f alignment)
    {
        Matrix3f world = orientation * pose.Rotations[bone];
        Vector3f joint = RagdollSolver.Rotate(orientation, pose.Positions[bone]);
        Vector3f centre = RagdollSolver.Rotate(world, shape.Centre);
        Vector3d comUnits = origin + new Vector3d(
            joint.X + centre.X, joint.Y + centre.Y, joint.Z + centre.Z);
        return (
            BepuRagdollConversions.ToBepuPosition(comUnits),
            BepuRagdollConversions.ToBepuQuaternion(world * alignment));
    }

    private void AddJoint(BodyHandle parent, BodyHandle child, BepuRigShapes shapes, int joint)
    {
        Simulation.Solver.Add(parent, child, shapes.BallSockets[joint]);
        Simulation.Solver.Add(parent, child, shapes.SwingLimits[joint]);
        Simulation.Solver.Add(parent, child, shapes.TwistLimits[joint]);
        Simulation.Solver.Add(parent, child, BepuRigShapes.Motor);
    }

    private void AddGripJoint(BodyHandle hand, BodyHandle weapon, RagdollSkeleton rig, RagdollBone carried, int host)
    {
        RagdollBone handBone = rig.BoneAt(host);
        Matrix3f handAlignment = BepuRagdollConversions.AlignmentMatrix(handBone.Aim, handBone.Reference);
        Matrix3f weaponAlignment = BepuRagdollConversions.AlignmentMatrix(carried.Aim, carried.Reference);

        // Anchors from each body's centre of mass, in body-local Bepu coords: the joint sits at
        // the hand's origin, so the parent anchor is minus the hand's COM offset, and the child
        // anchor is minus the weapon's COM offset — the same pair RagdollBody builds for the grip.
        Vector3 offsetA = BepuRagdollConversions.ToBepuOffset(
            RagdollSolver.Rotate(handAlignment.Transposed(), -handBone.Centre));
        Vector3 offsetB = BepuRagdollConversions.ToBepuOffset(
            RagdollSolver.Rotate(weaponAlignment.Transposed(), -carried.Centre));
        Simulation.Solver.Add(hand, weapon, new BallSocket
        {
            LocalOffsetA = offsetA,
            LocalOffsetB = offsetB,
            SpringSettings = new SpringSettings(30f, 1f),
        });

        float grip = RagdollWeapon.GripAllowance;
        Vector3 swingAxis = BepuRagdollConversions.ToBepuDirection(
            RagdollSolver.Rotate(handAlignment.Transposed(), new Vector3d(carried.Aim.X, carried.Aim.Y, carried.Aim.Z)));
        Simulation.Solver.Add(hand, weapon, new SwingLimit
        {
            AxisLocalA = Vector3.Normalize(swingAxis),
            AxisLocalB = Vector3.UnitY,
            MinimumDot = MathF.Cos(grip),
            SpringSettings = new SpringSettings(15f, 1f),
        });

        // Twist: both bases share the HAND's reference, so the twist reads zero at the seed grip
        // orientation — the XPBD grip measures twist relative to the seed local rotation, and
        // there is no joint mid-range to read zero at here. (For a rig joint the two bases use
        // their own references and agree at the joint's mid-range instead.)
        Matrix3f basisA = handAlignment.Transposed()
            * BepuRagdollConversions.TwistBasisMatrix(carried.Aim, handBone.Reference);
        Matrix3f basisB = weaponAlignment.Transposed()
            * BepuRagdollConversions.TwistBasisMatrix(carried.Aim, handBone.Reference);
        Simulation.Solver.Add(hand, weapon, new TwistLimit
        {
            LocalBasisA = BepuRagdollConversions.ToBepuQuaternion(basisA),
            LocalBasisB = BepuRagdollConversions.ToBepuQuaternion(basisB),
            MinimumAngle = -grip,
            MaximumAngle = grip,
            SpringSettings = new SpringSettings(15f, 1f),
        });

        Simulation.Solver.Add(hand, weapon, BepuRigShapes.Motor);
    }

    /// <summary>Steps the simulation once for this tick — the single Timestep per tick.</summary>
    /// <remarks>
    /// Guarded by the simulation tick count, so a second call in the same tick is a no-op rather
    /// than a second step. The step runs here, at the <c>StepRagdolls</c> site (after
    /// <c>FinishTick</c>, before the pose loop), never from the player path — so a player corpse
    /// seeded after <c>EndTick</c> waits one tick. Kinematic entries are synced first, so a
    /// corpse never falls through a door that moved.
    /// </remarks>
    public void StepOnce(int tick)
    {
        ObjectDisposedException.ThrowIf(_disposed, this);
        if (tick == _lastSteppedTick)
        {
            return;
        }

        _lastSteppedTick = tick;
        _tick++;

        SyncKinematics();
        Simulation.Solver.SubstepCount = Math.Clamp(GameplayCVars.RagdollSubsteps.Value, 1, 64);

        Stopwatch watch = Stopwatch.StartNew();
        Simulation.Timestep(1f / 30f);
        _lastStepMs = watch.Elapsed.TotalMilliseconds;

        foreach (BepuRagdollCorpse corpse in _corpses.ToArray())
        {
            if (!corpse.IsValid)
            {
                continue;
            }

            int age = _tick - corpse.SeedTick;
            if (corpse.RootDistanceFromOriginInMetres() > BepuRagdollCorpse.RunawayDistanceInMetres)
            {
                corpse.MarkInvalid();
                _logger.Warning(LogCategory,
                    $"[BepuRagdoll] corpse={corpse.Id} runaway: root travelled over {BepuRagdollCorpse.RunawayDistanceInMetres:F0}m from its death; falling back to the death clip.");
                continue;
            }

            if (!corpse.HasSettled)
            {
                if (age >= BepuRagdollCorpse.MaximumActiveTicks)
                {
                    corpse.ForceSleep();
                    corpse.MarkSettled(age, byHardStop: true);
                    _logger.Warning(LogCategory,
                        $"[BepuRagdoll] corpse={corpse.Id} hard stop: still active after {age} ticks (10s); forced asleep. The settle question is answered NO for this corpse — send the seed position and what it was resting on.");
                }
                else if (corpse.AllAsleep())
                {
                    corpse.MarkSettled(age, byHardStop: false);
                    _logger.Information(LogCategory,
                        $"[BepuRagdoll] corpse={corpse.Id} settled after {age} ticks.");
                }
            }
        }

        if (_corpses.Count > 0 && _tick % 30 == 0)
        {
            int bodies = 0;
            foreach (BepuRagdollCorpse corpse in _corpses)
            {
                bodies += corpse.Bodies.Length;
            }

            _logger.Information(LogCategory,
                $"[BepuRagdoll] step: tick={_tick} corpses={_corpses.Count} bodies={bodies} kinematics={_kinematics.Count} lastStepMs={_lastStepMs:F2}");
        }
    }

    /// <summary>Removes a corpse's bodies (and its weapon shape) from the simulation.</summary>
    /// <remarks>
    /// <c>Bodies.Remove</c> removes the connected constraints too (IL-verified in 2.4.0), so
    /// there is nothing else to tear down. Called when the corpse is dropped as invalid and
    /// when its member leaves the world; level unload disposes the whole simulation instead.
    /// </remarks>
    public void RemoveCorpse(BepuRagdollCorpse corpse)
    {
        ObjectDisposedException.ThrowIf(_disposed, this);
        if (corpse.Removed)
        {
            return;
        }

        foreach (BodyHandle handle in corpse.Bodies)
        {
            Simulation.Bodies.Remove(handle);
        }

        if (corpse.WeaponShapeIndex is { } weaponShape)
        {
            Simulation.Shapes.Remove(weaponShape);
        }

        corpse.MarkRemoved();
        _corpses.Remove(corpse);
    }

    /// <summary>Syncs the kinematic dynamic entries, once per tick, before the step.</summary>
    /// <remarks>
    /// The static mesh excludes every dynamic entry (it is a snapshot at its load pose), so a
    /// door, lift or vehicle that moves must be a kinematic body or a corpse falls through it.
    /// Poses are re-read every tick from the index (origin + orientation only — no triangles);
    /// the entry list is only re-enumerated (with triangles, for hulls) when the dynamic count
    /// changes or a known entry goes missing, which is when a door first moves or is destroyed.
    /// </remarks>
    private void SyncKinematics()
    {
        if (_solids is null)
        {
            return;
        }

        _scratchPoses.Clear();
        _solids.CollectDynamicPoses(_scratchPoses);

        HashSet<(object Owner, string Name)> live = [];
        foreach (DynamicEntryPose pose in _scratchPoses)
        {
            live.Add((pose.Owner, pose.InstanceName));
        }

        // A rebuild is needed when the dynamic count changed, when a kinematic body has no live
        // entry any more (retired or destroyed), or when a live entry has neither a body nor a
        // recorded skip. A skipped entry is accounted for — its hull cannot be built from a
        // mesh-fixed point set, so treating it as missing would rebuild (and re-log) every tick.
        bool needsRebuild = _solids.DynamicEntryCount != _lastDynamicCount;
        if (!needsRebuild)
        {
            foreach ((object Owner, string Name) key in _kinematics.Keys)
            {
                if (!live.Contains(key))
                {
                    needsRebuild = true;
                    break;
                }
            }
        }

        if (!needsRebuild)
        {
            foreach (DynamicEntryPose pose in _scratchPoses)
            {
                (object Owner, string Name) key = (pose.Owner, pose.InstanceName);
                if (!_kinematics.ContainsKey(key) && !_skippedKinematics.Contains(key))
                {
                    needsRebuild = true;
                    break;
                }
            }
        }

        if (needsRebuild)
        {
            RebuildKinematics();
            _lastDynamicCount = _solids.DynamicEntryCount;
            return;
        }

        foreach (DynamicEntryPose pose in _scratchPoses)
        {
            if (_kinematics.TryGetValue((pose.Owner, pose.InstanceName), out BepuKinematicEntry entry))
            {
                UpdateKinematicPose(entry, pose);
            }
        }
    }

    private void UpdateKinematicPose(BepuKinematicEntry entry, DynamicEntryPose pose)
    {
        Vector3 origin = BepuRagdollConversions.ToBepuPosition(pose.PoseOrigin);
        Quaternion orientation = BepuRagdollConversions.ToBepuQuaternion(pose.PoseOrientation);
        Vector3 position = origin + Vector3.Transform(entry.HullCentre, orientation);

        BodyReference body = Simulation.Bodies[entry.Handle];
        Vector3 previous = body.Pose.Position;
        ref RigidPose current = ref body.Pose;
        current.Position = position;
        current.Orientation = orientation;
        body.Velocity.Linear = (position - previous) * 30f;
        body.UpdateBounds();
    }

    /// <summary>Re-enumerates the dynamic entries and rebuilds the kinematic set to match.</summary>
    private void RebuildKinematics()
    {
        if (_solids is null)
        {
            return;
        }

        _scratchSnapshots.Clear();
        _solids.CollectDynamicSnapshots(_scratchSnapshots);

        HashSet<(object Owner, string Name)> live = [];
        foreach (DynamicCollisionSnapshot snapshot in _scratchSnapshots)
        {
            live.Add((snapshot.Owner, snapshot.InstanceName));
        }

        foreach ((object Owner, string Name) key in _kinematics.Keys.ToArray())
        {
            if (!live.Contains(key))
            {
                RemoveKinematic(key);
            }
        }

        foreach (DynamicCollisionSnapshot snapshot in _scratchSnapshots)
        {
            (object Owner, string Name) key = (snapshot.Owner, snapshot.InstanceName);
            if (_kinematics.ContainsKey(key) || _skippedKinematics.Contains(key))
            {
                continue;
            }

            TryAddKinematic(snapshot);
        }

        _logger.Information(LogCategory,
            $"[BepuRagdoll] kinematics: dynamicEntries={_solids.DynamicEntryCount} kinematicBodies={_kinematics.Count} skipped={_skippedKinematics.Count}");
    }

    private void TryAddKinematic(DynamicCollisionSnapshot snapshot)
    {
        (object Owner, string Name) key = (snapshot.Owner, snapshot.InstanceName);
        if (snapshot.LocalPoints.Length < 4)
        {
            _skippedKinematics.Add(key);
            _logger.Warning(LogCategory,
                $"[BepuRagdoll] kinematic skipped: '{snapshot.InstanceName}' has {snapshot.LocalPoints.Length} hull points (needs 4); corpses may fall through it.");
            return;
        }

        Vector3[] points = new Vector3[snapshot.LocalPoints.Length];
        for (int i = 0; i < points.Length; i++)
        {
            Vector3f p = snapshot.LocalPoints[i];
            points[i] = BepuRagdollConversions.ToBepuPosition(new Vector3d(p.X, p.Y, p.Z));
        }

        BepuPhysics.Collidables.ConvexHull hull;
        Vector3 centre;
        try
        {
            hull = new BepuPhysics.Collidables.ConvexHull(points.AsSpan(), _pool, out centre);
        }
        catch (Exception ex)
        {
            _skippedKinematics.Add(key);
            _logger.Warning(LogCategory,
                $"[BepuRagdoll] kinematic skipped: '{snapshot.InstanceName}' hull build failed ({ex.GetType().Name}: {ex.Message}); corpses may fall through it.");
            return;
        }

        TypedIndex shape = Simulation.Shapes.Add(hull);
        Vector3 origin = BepuRagdollConversions.ToBepuPosition(snapshot.PoseOrigin);
        Quaternion orientation = BepuRagdollConversions.ToBepuQuaternion(snapshot.PoseOrientation);
        Vector3 position = origin + Vector3.Transform(centre, orientation);
        BodyDescription description = BodyDescription.CreateKinematic(
            new RigidPose(position, orientation),
            new BodyVelocity(Vector3.Zero),
            // Passive continuity: a kinematic body teleports between ticks, and a Discrete body
            // can tunnel through a corpse it moved into. The margin is the same 1 cm as a corpse.
            new CollidableDescription(shape, SpeculativeMarginMetres, ContinuousDetection.Passive),
            BodyDescription.GetDefaultActivity(hull));
        BodyHandle handle = Simulation.Bodies.Add(description);
        _tags.Set(handle, BepuBodyTag.Unknown);
        _kinematics[key] = new BepuKinematicEntry(handle, shape, centre);
        _logger.Information(LogCategory,
            $"[BepuRagdoll] kinematic + '{snapshot.InstanceName}' points={points.Length}");
    }

    private void RemoveKinematic((object Owner, string Name) key)
    {
        if (!_kinematics.TryGetValue(key, out BepuKinematicEntry entry))
        {
            return;
        }

        _kinematics.Remove(key);
        Simulation.Bodies.Remove(entry.Handle);
        Simulation.Shapes.RemoveAndDispose(entry.Shape, _pool);
    }

    private BepuRigShapes RigShapesFor(RagdollSkeleton rig)
    {
        if (_rigs.TryGetValue(rig, out BepuRigShapes? shapes))
        {
            return shapes;
        }

        shapes = BepuRigShapes.Build(rig, Simulation);
        _rigs[rig] = shapes;
        return shapes;
    }

    /// <summary>Converts a rig inverse-inertia tensor into Bepu's body frame and units.</summary>
    /// <remarks>
    /// The rig tensor is in the bone frame, in 1/(kg·units²). Bepu wants it in the body frame,
    /// in 1/(kg·m²): conjugate by the alignment rotation (I_body⁻¹ = Aᵀ · I_bone⁻¹ · A, since a
    /// body-frame vector is A⁻¹ · v in the bone frame) and multiply by 4096². The 10 cm inertia
    /// floor the rig builds in is kept — it is not replaced by <c>Capsule.ComputeInertia</c>.
    /// </remarks>
    internal static Symmetric3x3 ConvertInertia(Matrix3f inverseInertia, Matrix3f alignment)
    {
        Matrix3f converted = alignment.Transposed() * inverseInertia * alignment;
        float scale = (float)(BepuRagdollConversions.UnitsPerMetre * BepuRagdollConversions.UnitsPerMetre);
        return new Symmetric3x3
        {
            XX = converted.M11 * scale,
            YX = converted.M21 * scale,
            YY = converted.M22 * scale,
            ZX = converted.M31 * scale,
            ZY = converted.M32 * scale,
            ZZ = converted.M33 * scale,
        };
    }

    public void Dispose()
    {
        if (_disposed)
        {
            return;
        }

        _disposed = true;
        _corpses.Clear();
        foreach ((object Owner, string Name) key in _kinematics.Keys.ToArray())
        {
            RemoveKinematic(key);
        }

        _kinematics.Clear();
        foreach ((TypedIndex Shape, StaticHandle Static) mesh in _meshStatics)
        {
            Simulation.Statics.Remove(mesh.Static);
            Simulation.Shapes.RemoveAndDispose(mesh.Shape, _pool);
        }

        _meshStatics.Clear();
        Simulation.Dispose();
        _pool.Clear();
    }

    /// <summary>One kinematic dynamic entry: its body, its hull shape, and its hull centre.</summary>
    private sealed record BepuKinematicEntry(
        BodyHandle Handle, TypedIndex Shape, Vector3 HullCentre);

    /// <summary>Per-rig Bepu data, built once and shared by every corpse wearing the rig.</summary>
    /// <remarks>
    /// Shapes are shared (one capsule per bone per rig); the joint descriptions are precomputed
    /// per joint, so seeding a corpse is bodies + <c>Solver.Add</c> calls and no conversions.
    /// Spring choices are first estimates from the demo: BallSocket 30 Hz (the demo's contact
    /// spring — a joint that separates reads as a dislocation), Swing/Twist 15 Hz (the demo's
    /// spine joints). The motor is the demo's joint damper: maximum force, softness 0.01.
    /// </remarks>
    private sealed class BepuRigShapes
    {
        public static readonly AngularMotor Motor = new()
        {
            TargetVelocityLocalA = Vector3.Zero,
            Settings = new MotorSettings(float.MaxValue, 0.01f),
        };

        public required TypedIndex[] Shapes { get; init; }
        public required Matrix3f[] Alignment { get; init; }
        public required Quaternion32[] AlignmentInverse { get; init; }
        public required Symmetric3x3[] Inertia { get; init; }
        public required BallSocket[] BallSockets { get; init; }
        public required SwingLimit[] SwingLimits { get; init; }
        public required TwistLimit[] TwistLimits { get; init; }

        /// <summary>The alignment-inverse quaternion for an attachment body (built from its own aim).</summary>
        public Quaternion32 AlignmentInverseFor(RagdollBone carried)
        {
            Matrix3f alignment = BepuRagdollConversions.AlignmentMatrix(carried.Aim, carried.Reference);
            return RagdollPose.QuaternionOf(alignment.Transposed());
        }

        public static BepuRigShapes Build(RagdollSkeleton rig, Simulation simulation)
        {
            int bones = rig.BoneCount;
            TypedIndex[] shapes = new TypedIndex[bones];
            Matrix3f[] alignment = new Matrix3f[bones];
            Quaternion32[] alignmentInverse = new Quaternion32[bones];
            Symmetric3x3[] inertia = new Symmetric3x3[bones];

            for (int bone = 0; bone < bones; bone++)
            {
                RagdollBone shape = rig.BoneAt(bone);
                // The capsule ctor takes the FULL line-segment length — passing the rig's
                // half-length would build every capsule half as long (IL-verified in 2.4.0:
                // HalfLength = length * 0.5f).
                float radiusMetres = shape.Radius / (float)BepuRagdollConversions.UnitsPerMetre;
                float lengthMetres = 2f * shape.HalfLength / (float)BepuRagdollConversions.UnitsPerMetre;
                shapes[bone] = simulation.Shapes.Add(new Capsule(radiusMetres, lengthMetres));
                alignment[bone] = BepuRagdollConversions.AlignmentMatrix(shape.Aim, shape.Reference);
                alignmentInverse[bone] = RagdollPose.QuaternionOf(alignment[bone].Transposed());
                inertia[bone] = ConvertInertia(shape.InverseInertia, alignment[bone]);
            }

            BallSocket[] ballSockets = new BallSocket[rig.Joints.Count];
            SwingLimit[] swingLimits = new SwingLimit[rig.Joints.Count];
            TwistLimit[] twistLimits = new TwistLimit[rig.Joints.Count];

            for (int j = 0; j < rig.Joints.Count; j++)
            {
                RagdollJoint joint = rig.Joints[j];
                RagdollBone parentBone = rig.BoneAt(joint.Parent);
                RagdollBone childBone = rig.BoneAt(joint.Child);
                Matrix3f parentAlignment = alignment[joint.Parent];
                Matrix3f childAlignment = alignment[joint.Child];

                // Anchors are from each bone's centre of mass, in its bone frame; the BallSocket
                // wants them in the body frame (A⁻¹ · v), in Bepu coords, in metres.
                ballSockets[j] = new BallSocket
                {
                    LocalOffsetA = BepuRagdollConversions.ToBepuOffset(
                        RagdollSolver.Rotate(parentAlignment.Transposed(), joint.ParentAnchor)),
                    LocalOffsetB = BepuRagdollConversions.ToBepuOffset(
                        RagdollSolver.Rotate(childAlignment.Transposed(), joint.ChildAnchor)),
                    SpringSettings = new SpringSettings(30f, 1f),
                };

                // Swing: the cone is centred on the measured axis (in the parent body frame) and
                // the child's own axis is its capsule Y in its body frame. 2.4.0 has no
                // MaximumSwingAngle — the limit is MinimumDot = cos(half-angle).
                Vector3 axisA = BepuRagdollConversions.ToBepuDirection(
                    RagdollSolver.Rotate(parentAlignment.Transposed(), new Vector3d(joint.SwingAxis.X, joint.SwingAxis.Y, joint.SwingAxis.Z)));
                swingLimits[j] = new SwingLimit
                {
                    AxisLocalA = Vector3.Normalize(axisA),
                    AxisLocalB = Vector3.UnitY,
                    MinimumDot = MathF.Cos(joint.SwingLimit),
                    SpringSettings = new SpringSettings(15f, 1f),
                };

                // Twist: bases built so the twist reads zero at the joint's mid-range relative
                // orientation (the parent basis uses the swing axis and the parent's reference;
                // the child basis uses its own aim and reference, and the two agree at mid-range
                // by construction — see the twist-basis derivation in the PR body).
                Matrix3f basisA = parentAlignment.Transposed()
                    * BepuRagdollConversions.TwistBasisMatrix(joint.SwingAxis, parentBone.Reference);
                Matrix3f basisB = childAlignment.Transposed()
                    * BepuRagdollConversions.TwistBasisMatrix(childBone.Aim, childBone.Reference);
                twistLimits[j] = new TwistLimit
                {
                    LocalBasisA = BepuRagdollConversions.ToBepuQuaternion(basisA),
                    LocalBasisB = BepuRagdollConversions.ToBepuQuaternion(basisB),
                    MinimumAngle = joint.TwistLow,
                    MaximumAngle = joint.TwistHigh,
                    SpringSettings = new SpringSettings(15f, 1f),
                };
            }

            return new BepuRigShapes
            {
                Shapes = shapes,
                Alignment = alignment,
                AlignmentInverse = alignmentInverse,
                Inertia = inertia,
                BallSockets = ballSockets,
                SwingLimits = swingLimits,
                TwistLimits = twistLimits,
            };
        }
    }
}
