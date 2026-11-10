using ProjectIGI.Game.Multiplayer;
using ProjectIGI.Game.Player;

namespace ProjectIGI.Host;

/// <summary>A session the host's frame can show the scoreboard of.</summary>
public interface ISessionScoreboard
{
    /// <summary>Gets the scoreboard as this end knows it, or <see langword="null"/> before there is one.</summary>
    Scoreboard? CurrentScoreboard { get; }

    /// <summary>Gets this end's own player's entity, whose line is marked, or <see langword="null"/>.</summary>
    int? LocalEntity { get; }

    /// <summary>Gets what the board is headed with: the server's name and its map.</summary>
    string Title { get; }

    /// <summary>Gets the room's code, when the session is played through one.</summary>
    string? RoomCode => null;

    /// <summary>Gets where the session is played: the mission or map, as a player reads it.</summary>
    string Place => Title;

    /// <summary>Gets how far this end's own fallen player's revival has gone, in <c>[0,1]</c>, or <see langword="null"/> while it is up.</summary>
    float? OwnRevive => null;

    /// <summary>Gets whether this player's connection goes through the TURN relay rather than straight to the others.</summary>
    bool Relayed => false;

    /// <summary>Gets whether this player's connection is poor enough to tell them: a long round trip, or rounds of packets lost.</summary>
    bool PoorConnection => false;
}

/// <summary>Something run either side of each game tick: a multiplayer session reads before and sends after.</summary>
/// <remarks>
/// The dedicated server is one: before the tick it takes in what the clients sent, so their commands are there when the
/// level runs; after it, it captures the level and sends each client its snapshot.
/// </remarks>
public interface IHostTickObserver
{
    /// <summary>Called just before the game runs a tick.</summary>
    /// <param name="title">What is ticking: a title's own player (I.G.I. 2) or the hosted mission (I.G.I.).</param>
    void BeforeTitleTick(object title);

    /// <summary>Called just after the game has run a tick.</summary>
    /// <param name="title">What ticked.</param>
    void AfterTitleTick(object title);
}

/// <summary>The host's observers.</summary>
public sealed partial class GameHost
{
    private IHostTickObserver? _tickObserver;

    // What the player's cheat setting was before a session turned cheats off, restored when the session ends.
    private bool _cheatsBeforeSession;

    /// <summary>Gets or sets what runs either side of each tick of the title's player, or <see langword="null"/>.</summary>
    /// <remarks>
    /// One set is a multiplayer session, and while it is set cheats are held off: the session switches cheats off as it
    /// begins, and nothing turns them on until it ends.
    /// M1 ADAPTATION: upstream holds a <c>PlayerCheatLock</c> here; the port has no cheat lock, so the session snapshots
    /// the player's cheat setting and turns cheats off, restoring the snapshot when the session ends. The free-camera
    /// suppression upstream holds here is NOT wired in the port: the loopback session does not gate the free camera.
    /// </remarks>
    public IHostTickObserver? TickObserver
    {
        get => _tickObserver;
        set
        {
            bool was = _tickObserver is not null;
            _tickObserver = value;
            if (value is not null && !was)
            {
                _cheatsBeforeSession = PlayerCheatCVars.CheatsEnabled.Value;
                PlayerCheatCVars.CheatsEnabled.Value = false;
                _logger.Information("Coop", "Cheats are off for the session.");
            }
            else if (value is null && was)
            {
                PlayerCheatCVars.CheatsEnabled.Value = _cheatsBeforeSession;
            }
        }
    }

    // A game that goes with its session still set gives the session's hold back, so it outlives nothing.
    private void ReleaseSessionCheatLock() => TickObserver = null;
}
