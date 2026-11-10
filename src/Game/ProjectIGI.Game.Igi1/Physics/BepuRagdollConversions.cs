using System.Numerics;
using ProjectIGI.Core.Numerics;
using ProjectIGI.Formats.Animation;
using ProjectIGI.Game.Physics;
using ProjectIGI.Game.World;

namespace ProjectIGI.Game.Igi1.Physics;

/// <summary>
/// The one place the Bepu prototype translates between the engine and BepuPhysics.
/// </summary>
/// <remarks>
/// <para>
/// Bepu runs in SI metres, Y-up, <see cref="float"/>. The engine runs in double engine units
/// (4096 per metre), Z-up, right-handed. Every value crosses this boundary in exactly one of the
/// helpers below — nothing in the adapter converts inline — so a wrong conversion has one place
/// to be fixed.
/// </para>
/// <para>
/// Axis swap, handedness-preserving: engine (x, y, z) → Bepu (x, z, −y). Bepu up is engine +Z;
/// Bepu +Z is engine −Y, since X × Y = Z in both systems. As a rotation this is −90° about X:
/// (0, 1, 0) → (0, 0, −1) and (0, 0, 1) → (0, 1, 0). Orientations cross as a conjugation by
/// that basis-change rotation: Q_bepu = qB · Q_engine · qB⁻¹, so a body-local vector crosses by
/// the same rotation (which is exactly the axis swap above) and a body-local rotation crosses by
/// conjugation. All three use the same <see cref="BasisChange"/> quaternion.
/// </para>
/// <para>
/// The other half of the boundary is the capsule axis: a Bepu capsule runs along its local Y,
/// a bone runs along its <see cref="RagdollBone.Aim"/> in its own frame. The alignment rotation
/// A takes (0, 1, 0) onto the aim, so a body orientation is Q_body = Q_bone · A and a vector in
/// the body frame is A⁻¹ · v in the bone frame. A is built once per bone, at rig-build time, and
/// reused at seed, anchors, limits and readback — the three stacked transforms (basis change ×
/// alignment × COM shift) live in <see cref="BepuRagdollCorpse"/> and nowhere else.
/// </para>
/// </remarks>
internal static class BepuRagdollConversions
{
    /// <summary>The basis-change rotation: engine coords → Bepu coords, −90° about X.</summary>
    /// <remarks>
    /// (−√2/2, 0, 0, √2/2): sin(−45°) on X, cos(−45°) on W. Its inverse is its conjugate
    /// (√2/2, 0, 0, √2/2). Verified by hand on the basis vectors, not by a test that exists yet:
    /// Vector3.Transform((0,1,0), BasisChange) = (0,0,−1) and
    /// Vector3.Transform((0,0,1), BasisChange) = (0,1,0).
    /// </remarks>
    public static readonly Quaternion BasisChange = new(
        -0.7071067811865476f, 0f, 0f, 0.7071067811865476f);

    /// <summary>The inverse basis change: Bepu coords → engine coords, +90° about X.</summary>
    public static readonly Quaternion BasisChangeInverse = new(
        0.7071067811865476f, 0f, 0f, 0.7071067811865476f);

    /// <summary>Engine units per metre — the same constant the rest of the port uses.</summary>
    public static double UnitsPerMetre => WorldScene.UnitsPerMetre;

    /// <summary>A world position in engine units → Bepu metres.</summary>
    public static Vector3 ToBepuPosition(Vector3d units) => new(
        (float)(units.X / UnitsPerMetre),
        (float)(units.Z / UnitsPerMetre),
        (float)(-units.Y / UnitsPerMetre));

    /// <summary>A Bepu position in metres → a world position in engine units.</summary>
    public static Vector3d ToEnginePosition(Vector3 positionMetres) => new(
        positionMetres.X * UnitsPerMetre,
        -positionMetres.Z * UnitsPerMetre,
        positionMetres.Y * UnitsPerMetre);

    /// <summary>A direction or velocity in engine units → Bepu coords (axis swap, no scaling).</summary>
    public static Vector3 ToBepuDirection(Vector3d direction) => new(
        (float)direction.X, (float)direction.Z, (float)-direction.Y);

    /// <summary>A direction or velocity in Bepu coords → engine coords (axis swap, no scaling).</summary>
    public static Vector3d ToEngineDirection(Vector3 direction) => new(
        direction.X, -direction.Z, direction.Y);

    /// <summary>A velocity in engine units per tick → Bepu metres per second.</summary>
    public static Vector3 ToBepuVelocity(Vector3d unitsPerTick)
    {
        // Units per tick → metres per second: × 30 ticks per second, ÷ 4096 units per metre.
        double scale = 30.0 / UnitsPerMetre;
        return new Vector3(
            (float)(unitsPerTick.X * scale),
            (float)(unitsPerTick.Z * scale),
            (float)(-unitsPerTick.Y * scale));
    }

    /// <summary>A body-frame offset in engine units → Bepu metres (axis swap + scale).</summary>
    /// <remarks>
    /// The same linear map as <see cref="ToBepuPosition"/>: an offset is a position minus a
    /// position, so the axis swap and the 1/4096 scale apply identically.
    /// </remarks>
    public static Vector3 ToBepuOffset(Vector3f units) => new(
        units.X / (float)UnitsPerMetre,
        units.Z / (float)UnitsPerMetre,
        -units.Y / (float)UnitsPerMetre);

    /// <summary>An engine world orientation → the same rotation in Bepu coords.</summary>
    /// <remarks>
    /// Through <see cref="RagdollPose.QuaternionOf"/> — the inverse of
    /// <see cref="BonePose.ToMatrix"/>, not of <c>Quaternion32.ToMatrix</c>, which differs by a
    /// transpose — then conjugated by the basis change. Component order is (x, y, z, w) on both
    /// sides; only the basis changes.
    /// </remarks>
    public static Quaternion ToBepuQuaternion(Matrix3f engine)
    {
        Quaternion32 q = RagdollPose.QuaternionOf(engine);
        Quaternion sys = new(q.X, q.Y, q.Z, q.W);
        return BasisChange * sys * BasisChangeInverse;
    }

    /// <summary>A Bepu world orientation → the same rotation in engine coords.</summary>
    public static Quaternion32 ToEngineQuaternion(Quaternion bepu)
    {
        Quaternion sys = BasisChangeInverse * bepu * BasisChange;
        return new Quaternion32(sys.X, sys.Y, sys.Z, sys.W);
    }

    /// <summary>
    /// The rotation taking a capsule's local Y onto a bone's aim, in the bone's own frame.
    /// </summary>
    /// <param name="aim">The bone's long axis, unit length, in its own frame.</param>
    /// <param name="reference">
    /// A unit vector perpendicular to <paramref name="aim"/> — the bone's
    /// <see cref="RagdollBone.Reference"/>.
    /// </param>
    /// <returns>
    /// The rotation as a matrix in the <c>M · v</c> convention: its second column is
    /// <paramref name="aim"/>, its first column is aim × reference, its third column is the
    /// reference. Columns (t, aim, p) with t = aim × p satisfy t × aim = p, so the frame is
    /// right-handed, and it maps (0, 1, 0) onto the aim.
    /// </returns>
    public static Matrix3f AlignmentMatrix(Vector3f aim, Vector3f reference)
    {
        Vector3f third = Vector3f.Cross(aim, reference);
        return new Matrix3f(
            third.X, aim.X, reference.X,
            third.Y, aim.Y, reference.Y,
            third.Z, aim.Z, reference.Z);
    }

    /// <summary>
    /// A twist basis: the rotation whose local Z is the twist axis and whose local X is the
    /// reference direction, in whatever frame the two arguments are expressed in.
    /// </summary>
    /// <remarks>
    /// The reference is projected perpendicular to the twist axis first, so a reference that is
    /// not quite perpendicular (a measured swing axis against a bone's reference) still yields an
    /// orthonormal basis. The Y axis is Z × X, so X × Y = Z and the basis is right-handed.
    /// </remarks>
    public static Matrix3f TwistBasisMatrix(Vector3f twistAxis, Vector3f reference)
    {
        Vector3f z = twistAxis.Normalized();
        Vector3f x = reference - (z * Vector3f.Dot(reference, z));
        if (x.LengthSquared < 1e-6f)
        {
            x = RagdollSkeleton.Perpendicular(z);
        }

        x = x.Normalized();
        Vector3f y = Vector3f.Cross(z, x);
        return new Matrix3f(
            x.X, y.X, z.X,
            x.Y, y.Y, z.Y,
            x.Z, y.Z, z.Z);
    }
}
