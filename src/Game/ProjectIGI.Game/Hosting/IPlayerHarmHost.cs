using ProjectIGI.Core.Diagnostics;
using ProjectIGI.Core.Numerics;
using ProjectIGI.Engine.Flow;
using ProjectIGI.Game.Player;
using ProjectIGI.Game.Weapons;
using ProjectIGI.Game.World;

namespace ProjectIGI.Game.Hosting;

/// <summary>What the player's damage and death ask of whatever plays and shows them.</summary>
public interface IPlayerHarmHost
{
    /// <summary>Gets the log.</summary>
    IProjectIGILogger Logger { get; }

    /// <summary>Gets the game's loop, whose clock the player's grunts are gated on.</summary>
    GameLoop Game { get; }

    /// <summary>Plays a sound definition.</summary>
    /// <param name="name">The definition.</param>
    /// <param name="positionInUnits">Where, or <see langword="null"/> for the listener's own.</param>
    /// <param name="priority">Its priority.</param>
    void PlayDefinition(string name, Vector3d? positionInUnits = null, int priority = 0);

    /// <summary>Hands the view to the camera that pulls back over the fallen body.</summary>
    /// <param name="position">The body, in world units.</param>
    /// <param name="facing">The way it was thrown.</param>
    /// <param name="walls">What pulls the camera in.</param>
    void BeginDeathCamera(Vector3d position, float facing, WorldRayCast walls);
}
