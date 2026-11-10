using System.Globalization;
using ProjectIGI.Core.Configuration;
using ProjectIGI.Engine.Time;
using ProjectIGI.Game.Multiplayer;
using ProjectIGI.Host.Multiplayer;
using ProjectIGI.Net;

namespace ProjectIGI.Host;

/// <summary>Co-op on one device: a listen server and its client in this process, over the loopback network.</summary>
/// <remarks>
/// Milestone 1 only. There is no room, no master server and no second device: the host runs the mission, the client
/// joins it over <see cref="LoopbackNetwork"/>, and the client's player runs the host player's input frame (the client
/// world's local frame packs the local rig's last frame), so the second player follows the first.
/// The session is gated behind <c>coop_loopback</c> (off by default) and the <c>coop_loopback</c> console command;
/// with the gate off no session object is constructed and solo play is untouched.
/// </remarks>
public sealed partial class GameHost
{
    // The loopback session, while it runs: the server and the client it joined, driven as one observer.
    private LoopbackSession? _loopback;

    // Where the client last went, until this host has gone there too: one told it during another load waits for that to
    // finish rather than being lost, and only the latest is kept.
    private int? _followInto;

    // Whether the loopback session's end has been told, so it is told once.
    private bool _loopbackEndedShown;

    /// <summary>A loopback session's two ends driven as one tick observer, in the order one process needs.</summary>
    /// <remarks>
    /// Before the tick the server reads what the client sent; after it the server sends its snapshots, and the client
    /// then sends this tick's command and shows every other player where the snapshots put it. The client's
    /// <c>BeforeTitleTick</c> is a no-op; the server's is what binds both ends to the level once it is up.
    /// </remarks>
    private sealed class LoopbackSession(HostedSession server, SessionClient client) : IHostTickObserver, ISessionHold, ISessionFollower, IDisposable
    {
        /// <inheritdoc/>
        public void BeforeTitleTick(object title)
        {
            server.BeforeTitleTick(title);
            client.BeforeTitleTick(title);
        }

        /// <inheritdoc/>
        public void AfterTitleTick(object title)
        {
            server.AfterTitleTick(title);
            client.AfterTitleTick(title);
        }

        /// <inheritdoc/>
        public bool HoldsLevel => server.HoldsLevel || client.HoldsLevel;

        /// <inheritdoc/>
        public void AnnounceGoing(string map) => server.AnnounceGoing(map);

        /// <inheritdoc/>
        public void Pump(object? title)
        {
            server.Pump(title);
            client.Pump(title);
        }

        /// <inheritdoc/>
        public string? TakeTravel() => client.TakeTravel();

        /// <inheritdoc/>
        public string? Ended => client.Ended;

        /// <inheritdoc/>
        public string? RoomCode => client.RoomCode;

        /// <inheritdoc/>
        public void Dispose()
        {
            server.Dispose();
            client.Dispose();
        }
    }

    /// <summary>Starts the loopback session: a listen server on the loopback network, and its client joined to it.</summary>
    /// <remarks>
    /// The sessions attach to the level on the next tick once one is up (the server creates its <c>ServerSession</c> in
    /// <c>BeforeTitleTick</c>, the client its <c>ClientSession</c> in <c>AfterTitleTick</c>), so this may be run from the
    /// main menu before the mission starts, or mid-mission. The client's player is named after the host's with a
    /// <c>2</c>, so the two lines in the log and the scoreboard stay apart.
    /// </remarks>
    private void StartLoopbackCoop()
    {
        if (_loopback is not null)
        {
            _logger.Information("Coop", "The loopback session is already running.");
            return;
        }

        string name = _configuration.Active?.Name is { Length: > 0 } profileName ? profileName : "Jones";
        string version = typeof(GameHost).Assembly
            .GetCustomAttributes(typeof(System.Reflection.AssemblyInformationalVersionAttribute), false)
            .OfType<System.Reflection.AssemblyInformationalVersionAttribute>().FirstOrDefault()?.InformationalVersion ?? "dev";
        string map = _session.Mission is { } mission ? mission.Id.ToString(CultureInfo.InvariantCulture) : string.Empty;

        LoopbackNetwork network = new();
        HostedSession server = new(
            network.Open(SessionArguments.DefaultPort),
            new HostedSessionOptions(
                Name: "Loopback",
                MaxPlayers: 1,
                Password: string.Empty,
                Mode: "objective",
                Map: map,
                Version: version,
                IncludesHost: true,
                HostName: name,
                Content: string.Empty),
            _titleRuntime.Title.Id,
            GameClock.DefaultTickRate,
            _logger);
        SessionClient client = new(
            network.Open(),
            server.LocalAddress,
            new JoinRequest($"{name} 2", version, Password: string.Empty),
            _titleRuntime.Title.Id,
            _logger);

        _loopback = new LoopbackSession(server, client);
        _loopbackEndedShown = false;
        TickObserver = _loopback;
        CoopCVars.Loopback.Value = true;
        _logger.Information("Coop", $"Loopback co-op started: host '{name}' and client '{name} 2' on port {SessionArguments.DefaultPort} in this process.");
    }

    /// <summary>Stops the loopback session, if one runs, and gives the cheats back.</summary>
    private void StopLoopbackCoop()
    {
        if (_loopback is null)
        {
            return;
        }

        _loopback.Dispose();
        _loopback = null;
        _followInto = null;
        ReleaseSessionCheatLock();
        CoopCVars.Loopback.Value = false;
        _logger.Information("Coop", "Loopback co-op stopped.");
    }

    // Into a mission from over a played one -- a restart, or a co-op client following its server -- behind the same going-in
    // sequence: the frozen level under the menu is the picture held, the menu leaves, and the place comes back as asked.
    // M1 ADAPTATION: upstream closes the pause menu through the shell and falls back to StartMissionWhenReadable (a
    // browser fetching the next level's files); the port has neither, so the pause menu is cleared the way
    // GameHost.FramePasses does, and a player already in a mission goes in directly.
    private void GoIntoMission(FrameLoopState state, int missionId)
    {
        if (_loadSequence.IsActive)
        {
            return;
        }

        void Go()
        {
            _menuFlow.PauseMenu = false;
            _menuFlow.MenuMode = false;
            ApplyGameplayMotionBlur();
            StartMission(missionId);
            _window.CursorVisible = false;
        }

        // The departure's picture is taken where the menu is drawn, so only from the menu: a player already in a mission --
        // following its host on to the next -- goes in as the host itself did, or the load would wait on a picture never
        // taken, under a card still naming the mission it left.
        if (CinematicLoadAvailable && _menuFlow.MenuMode)
        {
            BeginCinematicLoad(missionId, Go);
        }
        else if (_menuFlow.MenuMode)
        {
            Go();
        }
        else
        {
            StartMission(missionId);
        }
    }

    // A co-op client goes where its server goes: on to the next mission, or into the same one again; and is told, over its
    // mission, when the session is gone. M1 ADAPTATION: upstream opens the room-closed page over the mission; the loopback
    // has no room and no page, so the end is logged once and the session stopped.
    private void FollowLoopbackSession(FrameLoopState state)
    {
        if (TickObserver is not ISessionFollower follower)
        {
            _followInto = null;
            return;
        }

        if (follower.Ended is { } reason)
        {
            if (!_loopbackEndedShown)
            {
                _loopbackEndedShown = true;
                _logger.Warning("Coop", $"The loopback session ended ({reason}); stopping it.");
                StopLoopbackCoop();
            }

            return;
        }

        if (follower.TakeTravel() is { } map
            && int.TryParse(map, NumberStyles.Integer, CultureInfo.InvariantCulture, out int missionId))
        {
            _followInto = missionId;
        }

        if (_followInto is { } into && !_loadSequence.IsActive)
        {
            _followInto = null;
            _logger.Information("Coop", $"Following the loopback host into mission {into}.");
            GoIntoMission(state, into);
        }
    }

    /// <summary>Registers the loopback entry point: <c>coop_loopback [on|off|status]</c>.</summary>
    /// <param name="console">The console system.</param>
    private void RegisterLoopbackCommands(ConsoleSystem console)
    {
        console.Commands.Add(
            "coop_loopback",
            "Starts or stops the loopback co-op session (host + client in this process). coop_loopback [on|off|status].",
            context =>
            {
                string arg = context.Count > 0 ? context[0].ToLowerInvariant() : "status";
                switch (arg)
                {
                    case "on":
                        StartLoopbackCoop();
                        context.Print(_loopback is not null
                            ? "Loopback co-op is running: start mission 1 (or keep playing it) and watch the log for the client joining."
                            : "Loopback co-op did not start; see the log.");
                        break;
                    case "off":
                        StopLoopbackCoop();
                        context.Print("Loopback co-op stopped.");
                        break;
                    case "status":
                        context.Print(_loopback is not null
                            ? "Loopback co-op is running."
                            : "Loopback co-op is not running. coop_loopback on to start it.");
                        break;
                    default:
                        context.Error("Usage: coop_loopback [on|off|status].");
                        break;
                }
            });
    }
}
