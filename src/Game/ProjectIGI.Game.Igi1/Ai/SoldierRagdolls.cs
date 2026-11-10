using ProjectIGI.Core.Diagnostics;
using ProjectIGI.Core.Numerics;
using ProjectIGI.Formats.Animation;
using ProjectIGI.Formats.World;
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

    /// <summary>Gets one prepared rig per skeleton, shared by every corpse wearing it.</summary>
    // One prepared rig per skeleton, shared by every corpse wearing it. Building it walks the whole bone
    // graph twice, so it must not happen per death -- and it holds no live state, so it need not.
    public Dictionary<BoneAnimationSet, RagdollSkeleton> RagdollRigs { get; } = [];

    /// <summary>Gets or sets what corpses collide against, built on first use.</summary>
    public RagdollWorld? RagdollWorld { get; set; }

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
