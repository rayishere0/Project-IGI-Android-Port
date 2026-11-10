using ProjectIGI.Core.Diagnostics;
using ProjectIGI.Core.Numerics;
using ProjectIGI.Formats.Animation;
using ProjectIGI.Formats.World;
using ProjectIGI.Game;
using ProjectIGI.Game.Igi1.Physics;
using ProjectIGI.Game.Physics;
using ProjectIGI.Game.World;

namespace ProjectIGI.Game.Igi1.Ai;

/// <summary>What the soldiers' corpses and dropped guns are simulated with: one prepared rig per skeleton, and the world they fall against.</summary>
/// <remarks>
/// Nothing here changes what the original does: the death clip still plays underneath, and a ragdoll only replaces the
/// pose that is drawn.
/// </remarks>
/// <param name="context">The world casts and ground the corpses collide with.</param>
internal sealed class SoldierRagdolls(SoldierContext context)
{
    private readonly SoldierContext _context = context;

    private CollisionTriangleGather? _dropTriangles;

    private WorldRayCast? _dropTrace;

    /// <summary>Whether the Bepu step has thrown this level and Bepu is disabled for the rest of it.</summary>
    /// <remarks>
    /// Set by <see cref="StepBepuRagdolls"/> when <c>StepOnce</c> throws: a solver that threw once
    /// is not stepped again, and no new Bepu corpse is seeded while it is set (see
    /// <see cref="BepuReady"/>). Cleared by <see cref="ReleaseBepuWorld"/>, so a failure in one
    /// level does not poison the next level's freshly built world.
    /// </remarks>
    private bool _bepuFailed;

    /// <summary>Gets one prepared rig per skeleton, shared by every corpse wearing it.</summary>
    // One prepared rig per skeleton, shared by every corpse wearing it. Building it walks the whole bone
    // graph twice, so it must not happen per death -- and it holds no live state, so it need not.
    public Dictionary<BoneAnimationSet, RagdollSkeleton> RagdollRigs { get; } = [];

    /// <summary>Gets or sets what corpses collide against, built on first use.</summary>
    public RagdollWorld? RagdollWorld { get; set; }

    /// <summary>Gets the Bepu simulation for this level, or null when it was not built.</summary>
    /// <remarks>
    /// Built at level load, only when <c>g_ragdoll_bepu</c> is on — the whole-level gather costs a
    /// load-time sweep the XPBD path should never pay. Null means the flag is off or the build
    /// failed; either way every Bepu gate falls back to XPBD, and the build log says which.
    /// </remarks>
    public BepuRagdollWorld? BepuWorld { get; private set; }

    /// <summary>Whether a Bepu world is live for this level.</summary>
    public bool BepuReady => BepuWorld is not null && !_bepuFailed;

    /// <summary>Builds the Bepu level world from the placed solids and the terrain.</summary>
    /// <param name="solids">The placed-object collision index, or null when the level has none.</param>
    /// <param name="terrain">The level terrain, or null (level 14) when there is none.</param>
    /// <remarks>
    /// A build failure never breaks the level: <see cref="BepuRagdollWorld.Build"/> returns null
    /// and logs why, and the Bepu gates fall back to XPBD. Called once per level load, beside
    /// <see cref="SetDroppedWeaponWorld"/> — which is where the same two sources already sit.
    /// </remarks>
    public void SetBepuLevelWorld(ObjectCollisionIndex? solids, TerrainData? terrain)
    {
        ReleaseBepuWorld();
        if (!GameplayCVars.RagdollBepu.Value)
        {
            return;
        }

        BepuWorld = BepuRagdollWorld.Build(solids, terrain, _context.Logger);
    }

    /// <summary>Drops the Bepu level world, if one was built.</summary>
    public void ReleaseBepuWorld()
    {
        BepuWorld?.Dispose();
        BepuWorld = null;
        _bepuFailed = false;
    }

    /// <summary>Steps the Bepu world once for this tick.</summary>
    /// <remarks>
    /// The single Timestep per tick for the Bepu corpses, at the same site the XPBD step runs —
    /// after <c>FinishTick</c>, before the pose loop — so a Bepu corpse and an XPBD corpse are never
    /// stepped twice, and a player corpse seeded after <c>EndTick</c> waits one tick.
    /// <para>
    /// A throw in <c>StepOnce</c> — the kinematic sync, the solver timestep, or the post-step loop —
    /// used to propagate uncaught up the tick and close the game (the only catch on the ragdoll tick
    /// path is the fatal-error catch in <c>AndroidHost.Run</c>). It is contained here instead: the
    /// exception is logged, every live Bepu corpse is marked invalid — the existing per-member loop
    /// in <c>StepRagdolls</c> and the player tick then drop them and fall back to the death clip —
    /// and Bepu is disabled for the rest of the level, so later deaths seed XPBD corpses through
    /// the <c>UseBepuRagdolls</c> gate. The world itself is deliberately NOT disposed here: the
    /// drop path removes corpses from the live simulation, and disposing it would make that removal
    /// throw instead.
    /// </para>
    /// </remarks>
    public void StepBepuRagdolls()
    {
        if (_bepuFailed)
        {
            return;
        }

        try
        {
            BepuWorld?.StepOnce(_context.TickCount);
        }
        catch (Exception ex)
        {
            _bepuFailed = true;
            BepuWorld?.InvalidateAllCorpses();
            _context.Logger.Error(SoldierContext.LogCategory,
                "The Bepu ragdoll step failed; falling back to XPBD ragdolls for the rest of the level.", ex);
        }
    }

    /// <summary>Removes a Bepu corpse's bodies from the simulation.</summary>
    /// <remarks>
    /// Contained like the step: a throw while removing bodies — a simulation left inconsistent by
    /// a failed step — used to propagate uncaught up the tick and close the game. It is logged and
    /// the corpse is marked invalid instead, so the step loop skips it and the death clip plays;
    /// the bodies leak for the rest of the level, which is the cheaper failure.
    /// </remarks>
    public void RemoveBepuCorpse(BepuRagdollCorpse corpse)
    {
        try
        {
            BepuWorld?.RemoveCorpse(corpse);
        }
        catch (Exception ex)
        {
            corpse.MarkInvalid();
            _context.Logger.Error(SoldierContext.LogCategory,
                "Could not remove a Bepu ragdoll from the simulation; leaving it invalid.", ex);
        }
    }

    /// <summary>Gives dropped weapons the world they collide with.</summary>
    /// <param name="triangles">The solid triangles near a box, terrain included, for the realistic body.</param>
    /// <param name="trace">A cast against everything solid, terrain included, for the original's drop probe.</param>
    public void SetDroppedWeaponWorld(CollisionTriangleGather? triangles, WorldRayCast? trace)
    {
        _dropTriangles = triangles;
        _dropTrace = trace;
        RagdollWorld = null;
    }

    /// <summary>The prepared rig for an animation set, built once and shared by every corpse wearing it.</summary>
    /// <remarks>
    /// Keyed by the SET rather than the skeleton, because the joint limits are measured from the set's
    /// own clips — the animators' demonstration of how far each joint is meant to move, which is what
    /// gives a knee a hinge without any bone being named. Building it sweeps every rotation key in the
    /// set twice, so it must happen once per mission and not once per death.
    /// </remarks>
    public RagdollSkeleton? RagdollRigFor(BoneAnimationSet set, MefModel? model)
    {
        if (RagdollRigs.TryGetValue(set, out RagdollSkeleton? rig))
        {
            return rig;
        }

        try
        {
            rig = RagdollSkeleton.Build(set.Skeleton, RagdollLimits.Measure(set), model);
        }
        catch (ArgumentException ex)
        {
            // A rig the solver cannot use is not fatal: the retail death clip is still playing
            // underneath, so the body falls the way it always did and only the remaster is skipped.
            _context.Logger.Warning(SoldierContext.LogCategory, $"Skeleton {set.Skeleton.Id} cannot drive a ragdoll: {ex.Message}");
            return null;
        }

        RagdollRigs[set] = rig;
        return rig;
    }

    /// <summary>What corpses collide against — the same two queries a living body uses.</summary>
    public RagdollWorld RagdollWorldForCorpses()
    {
        if (RagdollWorld is { } world)
        {
            return world;
        }

        RagdollWorld = new RagdollWorld(_context.Cast, MakeCorpseGroundQuery())
        {
            Triangles = _dropTriangles,
            Trace = _dropTrace,
        };
        return RagdollWorld;
    }

    /// <summary>The ground query corpses stand on: placed collision and terrain, highest wins.</summary>
    /// <remarks>
    /// The same surfaces <see cref="SoldierContext.MakeGroundQuery"/> finds, in the same probe window —
    /// but keeping the surface normal the shared query throws away. A corpse pushed straight up out of
    /// a slope sinks into it by r·(1−cosθ) and sticks instead of sliding; pushed along the normal it
    /// rests on the slope. The shared query is untouched: brains, footsteps and the death-fall solver
    /// still take the height-only one.
    /// </remarks>
    /// <returns>The query, or <see langword="null"/> when the level has neither.</returns>
    private RagdollGround? MakeCorpseGroundQuery()
    {
        IGroundHeightField? terrain = _context.Terrain;
        WorldRayCast? cast = _context.Cast;
        if (terrain is null && cast is null)
        {
            return null;
        }

        return (double x, double y, double z, out TerrainGround ground) =>
        {
            // The same double.MinValue start MakeGroundQuery uses, so a terrain surface wins over
            // "nothing found" exactly as it does there.
            ground = new TerrainGround(double.MinValue, 0.0, 0.0, 1.0);
            bool found = false;

            if (cast is not null
                && cast(
                    new Vector3d(x, y, z),
                    new Vector3d(x, y, z - SoldierContext.ProbeBelowInUnits - SoldierContext.ProbeAboveInUnits),
                    out WorldRayHit hit))
            {
                Vector3d normal = new Vector3d(hit.Normal.X, hit.Normal.Y, hit.Normal.Z);
                double size = normal.Length;
                ground = new TerrainGround(
                    hit.Position.Z,
                    size > 0.0 ? normal.X / size : 0.0,
                    size > 0.0 ? normal.Y / size : 0.0,
                    size > 0.0 ? normal.Z / size : 1.0);
                found = true;
            }

            if (terrain is not null
                && terrain.TryGetGround(x, y, z, out TerrainGround surface)
                && surface.Height >= z - SoldierContext.ProbeBelowInUnits - SoldierContext.ProbeAboveInUnits
                && surface.Height <= z)
            {
                if (surface.Height > ground.Height)
                {
                    ground = surface;
                }

                found = true;
            }

            return found;
        };
    }
}
