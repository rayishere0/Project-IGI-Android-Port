using ProjectIGI.Core.Diagnostics;
using ProjectIGI.Core.Numerics;
using ProjectIGI.Engine.Flow;
using ProjectIGI.Engine.Tasks;
using ProjectIGI.Engine.Time;
using ProjectIGI.Game.Ai;
using ProjectIGI.Game.Player;
using ProjectIGI.Game.Weapons;
using ProjectIGI.Game.World;

namespace ProjectIGI.Game.Hosting;

/// <summary>What the level's blasts ask of whatever shows and plays them: their sounds, their fire and smoke, and the voices they cut.</summary>
public interface IBlastEffectsHost
{
    /// <summary>Gets the log.</summary>
    IProjectIGILogger Logger { get; }

    /// <summary>Gets the game's loop, whose variables an authored blast's expression writes.</summary>
    GameLoop Game { get; }

    /// <summary>Plays a sound definition where something happened.</summary>
    /// <param name="name">The definition.</param>
    /// <param name="positionInUnits">Where.</param>
    /// <param name="priority">Its priority.</param>
    void PlayDefinition(string name, Vector3d positionInUnits, int priority);

    /// <summary>Shatters a pane into its shards.</summary>
    /// <param name="placement">The pane.</param>
    /// <param name="atUnits">Where it was struck.</param>
    void GlassShatter(WorldPlacement placement, Vector3d atUnits);

}
