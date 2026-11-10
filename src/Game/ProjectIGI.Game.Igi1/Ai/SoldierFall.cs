using ProjectIGI.Core.Numerics;
using ProjectIGI.Game.Igi1.Player;
using ProjectIGI.Game.Weapons;

namespace ProjectIGI.Game.Igi1.Ai;

/// <summary>A soldier falling dead, as its renderer needs it to draw the corpse: where the body lies and how it came down.</summary>
/// <param name="View">The soldier.</param>
/// <param name="Origin">Where the body's root lies, set down on the ground.</param>
/// <param name="Bone">The bone the killing round or blast struck.</param>
/// <param name="Travel">Which way the round came, origin to end.</param>
/// <param name="Category">The killing weapon's category.</param>
/// <param name="Velocity">What the body was already doing: its clip's root motion this tick, out of body space.</param>
/// <param name="DroppedWeapon">Whether it let go of a weapon, which is no longer drawn in its hand.</param>
/// <param name="DeathAnimation">The death clip <c>SoldierDeath.Choose</c> picked, or -1 when no clip change was made and the body keeps its old clip. Carried so the renderer can tell a real death clip from a leftover live one when it decides when to seed the ragdoll.</param>
public readonly record struct SoldierFall(
    SoldierView View,
    Vector3d Origin,
    int Bone,
    Vector3d Travel,
    WeaponCategory Category,
    Vector3d Velocity,
    bool DroppedWeapon,
    int DeathAnimation);
