using ProjectIGI.Core.Configuration;
using ProjectIGI.Core.Numerics;
using ProjectIGI.Game.Weapons;
using ProjectIGI.Game.World;

namespace ProjectIGI.Game.Hosting;

/// <summary>What a title's own impact effects ask of the host: whether they are wanted at all, and whether blood is.</summary>
public interface IImpactEffectsHost
{
    /// <summary>Gets a value indicating whether the original's impact dust, surface chips and blood are drawn at all.</summary>
    bool ImpactEffectsWanted { get; }

    /// <summary>Gets a value indicating whether the player's profile wants blood.</summary>
    bool BloodWanted { get; }
}
