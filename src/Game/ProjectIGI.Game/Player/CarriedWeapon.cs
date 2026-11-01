using ProjectIGI.Game.Weapons;

namespace ProjectIGI.Game.Player;

/// <summary>One carried weapon: its record, its gun, and the ammunition type it draws from.</summary>
/// <param name="Weapon">The roster record.</param>
/// <param name="Gun">The magazine and the clock.</param>
public readonly record struct CarriedWeapon(WeaponType Weapon, HeldGun Gun);
