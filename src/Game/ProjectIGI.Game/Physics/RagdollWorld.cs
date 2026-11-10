using ProjectIGI.Core.Numerics;
using ProjectIGI.Game.World;

namespace ProjectIGI.Game.Physics;

/// <summary>Finds the ground beneath a point.</summary>
/// <param name="x">World X, in engine units.</param>
/// <param name="y">World Y, in engine units.</param>
/// <param name="z">The height to search downwards from, in engine units.</param>
/// <param name="ground">Receives the ground surface when one is found: its height and its unit normal.</param>
/// <returns><see langword="true"/> when a surface was found.</returns>
/// <remarks>
/// The same shape as <c>Igi1HumanAi.GroundQuery</c>, declared again here so the solver depends on nothing
/// in the AI — except that this one also carries the surface normal. A ground contact pushed straight up
/// out of a slope sinks the body into it by r·(1−cosθ) and sticks instead of sliding; pushed along the
/// normal it rests on the slope. The desktop shell's <c>MakeGroundQuery</c> satisfies the height-only
/// half, so corpses build their own query that keeps the normal.
/// </remarks>
public delegate bool RagdollGround(double x, double y, double z, out TerrainGround ground);

/// <summary>What a ragdoll collides against.</summary>
/// <remarks>
/// <para>
/// <b>No new collision code is written for ragdolls.</b> Both members are the queries the port already
/// runs against for the player's wall sweep, the ground query and the death-fall solver, so a corpse
/// meets exactly the geometry a living body does and there is one place where that geometry is wrong.
/// </para>
/// <para>
/// Both are optional. A body given neither falls for ever, which is what the unit tests want when they
/// are measuring the constraint passes rather than the contacts.
/// </para>
/// </remarks>
public sealed class RagdollWorld
{
    /// <summary>Initializes a new instance of the <see cref="RagdollWorld"/> class.</summary>
    /// <param name="cast">Casts a ray against placed collision meshes; <see langword="null"/> for none.</param>
    /// <param name="ground">Finds the ground under a point; <see langword="null"/> for none.</param>
    public RagdollWorld(WorldRayCast? cast = null, RagdollGround? ground = null)
    {
        Cast = cast;
        Ground = ground;
    }

    /// <summary>Gets a world with no geometry at all.</summary>
    public static RagdollWorld Empty { get; } = new();

    /// <summary>Gets the ray cast against placed collision meshes.</summary>
    public WorldRayCast? Cast { get; }

    /// <summary>Gets the downward ground query, which reaches the terrain the ray cast does not.</summary>
    public RagdollGround? Ground { get; }

    /// <summary>Gets the solid world triangles around a box, terrain included, for mesh-accurate contacts.</summary>
    /// <remarks>A dropped weapon's rigid body collides against these; without them it falls back to rays.</remarks>
    public CollisionTriangleGather? Triangles { get; init; }

    /// <summary>Gets a ray cast against everything solid, terrain included.</summary>
    /// <remarks>
    /// <see cref="Cast"/> meets placed objects only. The original's pickup probe (<c>0x46C980</c>) traces
    /// fifty metres down through terrain and objects alike, which is what this answers.
    /// </remarks>
    public WorldRayCast? Trace { get; init; }

    /// <summary>Builds a world that is a single horizontal plane, for tests.</summary>
    /// <param name="height">The plane's Z, in engine units.</param>
    /// <returns>The world.</returns>
    public static RagdollWorld Plane(double height) =>
        new(ground: (double x, double y, double z, out TerrainGround ground) =>
        {
            _ = x;
            _ = y;
            _ = z;
            ground = new TerrainGround(height, 0.0, 0.0, 1.0);
            return true;
        });

    /// <summary>Builds a floor with one upright wall in it, for tests.</summary>
    /// <param name="floor">The floor's Z, in engine units.</param>
    /// <param name="wallY">The wall's Y; it faces towards negative Y and is unbounded.</param>
    /// <returns>The world.</returns>
    public static RagdollWorld Room(double floor, double wallY) =>
        new(
            cast: (Vector3d origin, Vector3d end, out WorldRayHit hit) =>
            {
                hit = default;

                double from = origin.Y - wallY;
                double to = end.Y - wallY;
                if (from == to || (from < 0.0 && to < 0.0) || (from > 0.0 && to > 0.0))
                {
                    return false;
                }

                double at = from / (from - to);
                hit = new WorldRayHit(
                    origin + ((end - origin) * at),
                    new Vector3f(0f, -1f, 0f),
                    (end - origin).Length * at);
                return true;
            },
            ground: (double x, double y, double z, out TerrainGround ground) =>
            {
                _ = x;
                _ = y;
                _ = z;
                ground = new TerrainGround(floor, 0.0, 0.0, 1.0);
                return true;
            });

    /// <summary>How far above a point the ground search starts, in engine units.</summary>
    /// <remarks>
    /// <para>
    /// It has to be above the point at all, because <b>the port's ground query only ever looks
    /// downwards</b> and reports nothing when the surface is above where the search began. Start it at
    /// the bone and a body that has got even slightly under a floor can never find that floor again, so
    /// it drops out of the world — and a bone moving fast enough to end a substep below the surface is
    /// exactly how it gets under there.
    /// </para>
    /// <para>
    /// <b>But it must be only just above, and that is not a tuning preference.</b> The query returns the
    /// <em>highest surface below where it starts</em>. Begin the search two metres up and, in any room,
    /// what it finds is the <b>ceiling</b> — which it then reports as the ground, whereupon the contact
    /// dutifully pushes the bone up to it and the corpse flies into the roof. Outdoors there is nothing
    /// overhead so the same code behaves perfectly, which is precisely how a bug like this survives being
    /// tested in a field.
    /// </para>
    /// <para>
    /// Forty centimetres: further than a bone can sink in a tick at any speed it falls, and well under
    /// the height of anything a body could be standing beneath.
    /// </para>
    /// </remarks>
    public const double GroundSearchAboveInUnits = 1638.0;

    /// <summary>How far above a point the ground recovery search starts, in engine units.</summary>
    /// <remarks>
    /// One metre: further than a bone can be buried at seed time on any slope the game ships —
    /// a bone a metre uphill on a 45° slope sits a metre under its local ground — and far
    /// enough above the normal 0.4 m start to matter. It is the start of the search, not a
    /// reach: the delegate still returns the highest surface below it, so a bone in the open
    /// never sees a ceiling through this (the normal search already found its floor), and the
    /// recovery only ever runs when the normal search found nothing at all. See
    /// <see cref="TryGroundRecovered"/>.
    /// </remarks>
    public const double GroundRecoveryAboveInUnits = 4096.0;

    /// <summary>How far above a point the deep ground recovery search starts, in engine units.</summary>
    /// <remarks>
    /// Two metres: the second tier of the recovery (see <see cref="TryGroundDeepRecovered"/>).
    /// A body seeded mid-death-clip spreads bones ~1.8 m horizontally from a single
    /// ground-snapped origin, which on a 45° slope is up to ~1.8 m of rise across the body —
    /// past the 1 m tier — and a body draped over 4+ stair risers buries a limb more than a
    /// metre the same way. Two metres covers a full body length on a 45° slope. It is not
    /// raised further: the search start is also the ceiling the delegate can report, and a
    /// start higher than any room a body could be standing under would find that ceiling.
    /// </remarks>
    public const double GroundDeepRecoveryAboveInUnits = 8192.0;

    /// <summary>Looks for a surface a short way from a point.</summary>
    /// <param name="from">Where to look from, in engine units.</param>
    /// <param name="direction">Which way to look; need not be unit length.</param>
    /// <param name="reach">How far to look, in engine units.</param>
    /// <param name="point">Receives the surface point.</param>
    /// <param name="normal">Receives its outward normal, unit length.</param>
    /// <returns><see langword="false"/> when nothing is that way.</returns>
    /// <remarks>
    /// The ground query answers only downwards, so everything vertical goes through that and everything
    /// else goes through here — the same ray cast the player's own wall sweep uses, so a corpse meets the
    /// walls a living body does. The terrain-inclusive <see cref="Trace"/> is consulted too, and the
    /// nearer of the two hits wins: <see cref="Cast"/> sees placed objects only, so without it a terrain
    /// bank or cliff face — or a stair riser, which is terrain — is invisible to a wall probe, and a bone
    /// thrown at it keeps its horizontal velocity inside the hill until the runaway check drops it back
    /// to the death clip. <see cref="Trace"/> already covers placed objects as well (it is the nearest
    /// of the placed and terrain tracers), so where both hit the nearer one is the surface the bone
    /// actually meets first; where only <see cref="Cast"/> exists (test worlds) the answer is unchanged.
    /// </remarks>
    public bool TrySurface(Vector3d from, Vector3d direction, double reach, out Vector3d point, out Vector3d normal)
    {
        point = default;
        normal = default;

        double length = direction.Length;
        if (length <= 0.0 || reach <= 0.0)
        {
            return false;
        }

        Vector3d unit = direction / length;
        Vector3d end = from + (unit * reach);

        bool found = false;
        WorldRayHit nearest = default;
        if (Cast is { } cast && cast(from, end, out WorldRayHit castHit))
        {
            nearest = castHit;
            found = true;
        }

        if (Trace is { } trace && trace(from, end, out WorldRayHit traceHit)
            && (!found || traceHit.Distance < nearest.Distance))
        {
            nearest = traceHit;
            found = true;
        }

        if (!found)
        {
            return false;
        }

        point = nearest.Position;
        normal = new Vector3d(nearest.Normal.X, nearest.Normal.Y, nearest.Normal.Z);

        double size = normal.Length;
        if (size <= 0.0)
        {
            return false;
        }

        normal /= size;

        // A surface facing the same way the ray travelled is one the ray hit from behind -- the far side
        // of a wall the bone is already inside. Its normal points away from the bone, and pushing along
        // it would drive the bone further in, so it is flipped to face the bone.
        if (Vector3d.Dot(normal, unit) > 0.0)
        {
            normal = -normal;
        }

        return true;
    }

    /// <summary>Finds the ground height near a point, whether it is above or below.</summary>
    /// <param name="point">The point, in engine units.</param>
    /// <param name="groundZ">Receives the ground height.</param>
    /// <returns><see langword="true"/> when a surface was found.</returns>
    public bool TryGround(Vector3d point, out double groundZ) =>
        TryGround(point, out groundZ, out _);

    /// <summary>
    /// Finds the ground surface near a point, allowing the surface to sit up to a metre above it.
    /// </summary>
    /// <param name="point">The point, in engine units.</param>
    /// <param name="groundZ">Receives the ground height.</param>
    /// <param name="normal">Receives the surface's unit normal — the direction a body resting on it is pushed.</param>
    /// <returns><see langword="true"/> when a surface was found.</returns>
    /// <remarks>
    /// <para>
    /// The recovery half of <see cref="TryGround(Vector3d, out double, out Vector3d)"/>, for a
    /// bone that has got UNDER a surface. The normal search starts only 0.4 m above the point
    /// (<see cref="GroundSearchAboveInUnits"/>), because starting higher finds ceilings in rooms
    /// and pushes corpses into the roof — so a bone more than 0.4 m below a floor finds nothing
    /// at all, falls for ever, and is dropped back to the death clip once it has run 100 m past
    /// where it died, which reads as a body sinking through the ground and teleporting back onto
    /// it. A body seeded mid-death-clip on a slope or across stairs is buried exactly that way:
    /// the seed origin is ground-snapped at one point, and a bone a metre uphill sits over ground
    /// half a metre higher than the origin's.
    /// </para>
    /// <para>
    /// This starts the search a metre above the point instead, so it finds the floor the bone is
    /// under — and then the ordinary contact pushes the bone back out of it at the usual budget,
    /// about 15 cm a tick, instead of the bone being lost. It is used ONLY as a fallback when the
    /// normal search found nothing, so a bone standing on a floor never pays for it and never
    /// sees a ceiling: the normal search succeeds for it first. The one case it can still get
    /// wrong is a bone falling down an indoor shaft with a placed slab within a metre above it,
    /// which is pushed up onto the slab instead of falling — rare, and the body ends up lying on
    /// the slab rather than vanishing.
    /// </para>
    /// </remarks>
    public bool TryGroundRecovered(Vector3d point, out double groundZ, out Vector3d normal) =>
        TryGroundStartingAt(point, GroundRecoveryAboveInUnits, out groundZ, out normal);

    /// <summary>
    /// Finds the ground surface near a point, allowing the surface to sit up to two metres above it.
    /// </summary>
    /// <param name="point">The point, in engine units.</param>
    /// <param name="groundZ">Receives the ground height.</param>
    /// <param name="normal">Receives the surface's unit normal — the direction a body resting on it is pushed.</param>
    /// <returns><see langword="true"/> when a surface was found.</returns>
    /// <remarks>
    /// <para>
    /// The second recovery tier, for a bone buried deeper than the 1 m tier can see: a body seeded
    /// mid-death-clip spreads ~1.8 m from a single ground-snapped origin, which on a 45° slope is
    /// ~1.8 m of rise across the body, and a body draped over 4+ stair risers buries a limb more
    /// than a metre the same way. Only ever consulted when both the normal search and the 1 m
    /// recovery found nothing — and because the ground delegate's window below its start is fixed
    /// (~4.5 m), a start 2 m up can only add a surface sitting between 1 m and 2 m above the bone;
    /// any floor below the bone was already visible to the searches that ran first. Callers must
    /// still only accept a surface above the bone (the bone is buried under it): a surface 1–2 m
    /// above a bone that is standing in the open is a ceiling, not a floor.
    /// </para>
    /// </remarks>
    public bool TryGroundDeepRecovered(Vector3d point, out double groundZ, out Vector3d normal) =>
        TryGroundStartingAt(point, GroundDeepRecoveryAboveInUnits, out groundZ, out normal);

    /// <summary>Finds the ground surface near a point, whether it is above or below.</summary>
    /// <param name="point">The point, in engine units.</param>
    /// <param name="groundZ">Receives the ground height.</param>
    /// <param name="normal">Receives the surface's unit normal — the direction a body resting on it is pushed.</param>
    /// <returns><see langword="true"/> when a surface was found.</returns>
    public bool TryGround(Vector3d point, out double groundZ, out Vector3d normal) =>
        TryGroundStartingAt(point, GroundSearchAboveInUnits, out groundZ, out normal);

    private bool TryGroundStartingAt(Vector3d point, double aboveInUnits, out double groundZ, out Vector3d normal)
    {
        groundZ = 0.0;
        normal = Vector3d.UnitZ;
        if (Ground is not { } ground
            || !ground(point.X, point.Y, point.Z + aboveInUnits, out TerrainGround surface))
        {
            return false;
        }

        groundZ = surface.Height;
        normal = new Vector3d(surface.NormalX, surface.NormalY, surface.NormalZ);
        double size = normal.Length;
        normal = size > 0.0 ? normal / size : Vector3d.UnitZ;
        return true;
    }
}
