using ProjectIGI.Core.Numerics;
using ProjectIGI.Engine.Flow;
using ProjectIGI.Engine.Resources;
using ProjectIGI.Engine.Tasks;
using ProjectIGI.Engine.Vfs;
using ProjectIGI.Formats.Animation;
using ProjectIGI.Formats.World;
using ProjectIGI.Game.Player;
using ProjectIGI.Game.Weapons;
using ProjectIGI.Game.World;

namespace ProjectIGI.Game.Hosting;

/// <summary>What making a title's player asks of whatever shows and plays it.</summary>
public interface IPlayerSetupHost
{
    /// <summary>Gets the log.</summary>

    /// <summary>Gets the game's loop, whose namespace, types and tree the player's tables and scripts load into.</summary>
    GameLoop Game { get; }

    /// <summary>Gets the files the tables are read from.</summary>
    VirtualFileSystem FileSystem { get; }

    /// <summary>Gets the resources the scripts are registered as.</summary>
    ResourceRegistry Resources { get; }

    /// <summary>Gets the mission's terrain, which the grenades and the view model trace.</summary>
    TerrainData? Terrain { get; }

    /// <summary>Gets the level's built scene, whose ladders the player climbs and whose vehicles' guns turn.</summary>
    WorldScene? Scene { get; }

    /// <summary>Reads, once a session, the animation sets the player's body and its first-person rig use.</summary>
    /// <returns>The body's set, or <see langword="null"/> when there is none.</returns>
    BoneAnimationSet? ReadSharedAnimations();

    /// <summary>Records that a stage of the load has finished, for the load's timings.</summary>
    /// <param name="what">What finished.</param>
    void EndStage(string what);

    /// <summary>Shows a gun a soldier dropped.</summary>
    /// <param name="loaded">The mission, whose packs hold the gun's model.</param>
    /// <param name="pickup">The dropped gun.</param>
    void WeaponDropped(LoadedMission loaded, GunPickup pickup);

    /// <summary>Hands the effects the game material the open ground is made of.</summary>
    /// <param name="row">The material's row, or <see langword="null"/> when the terrain declares none.</param>
    void TerrainRowRead(int? row);

}
