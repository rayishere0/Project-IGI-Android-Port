using System.Globalization;
using ProjectIGI.Core.Configuration;
using ProjectIGI.Engine.Time;
using ProjectIGI.Game.Multiplayer;
using ProjectIGI.Host.Multiplayer;
using ProjectIGI.Net;
using ProjectIGI.Net.Udp;

namespace ProjectIGI.Host;

/// <summary>
/// Co-op over Wi-Fi: a direct-IP session between two phones on the same network, over plain UDP.
/// No master server, no relay, no WebRTC, no room code — the host listens on a UDP port and the
/// joiner connects to the host's Wi-Fi address, or picks it from the LAN list.
/// </summary>
/// <remarks>
/// Milestone 2, Wi-Fi-only scope (Ray, 2026-11-11 04:57 IST: the master server is parked).
/// The wiring copies upstream's desktop session start (<c>apps/OpenIGI.Desktop/Program.cs</c>,
/// <c>StartSession</c>): <c>-connect</c> is a <c>SessionClient</c> over
/// <c>UdpTransport.Open(0)</c>, <c>-listen</c> is a <c>HostedSession</c> over
/// <c>UdpTransport.Open(port)</c>. <c>HostedSession</c> and <c>SessionClient</c> are both
/// <see cref="IHostTickObserver"/>s already, so unlike the loopback composite there is no
/// wrapper: the session itself is the tick observer.
/// <para>
/// A joiner follows its host into missions the same way the loopback client does: the host
/// announces the mission it starts (<c>GameHost.Mission.cs</c> calls
/// <c>AnnounceGoing</c>), the client's <c>TakeTravel</c> is read every frame by
/// <see cref="FollowDirectSession"/>, and <see cref="GoIntoMission"/> (the loopback partial's)
/// takes it there. So a joiner joins first and is carried into the mission when the host starts it.
/// </para>
/// <para>
/// Mutual exclusion with loopback and rooms: starting a direct session stops a running loopback
/// or room session, and starting loopback or a room stops a direct one (see
/// <c>GameHost.CoopLoopback.cs</c> and <c>GameHost.CoopRooms.cs</c>). The three share the
/// <c>TickObserver</c> slot and the <c>_followInto</c> field, and only one may hold them.
/// </para>
/// </remarks>
public sealed partial class GameHost
{
    // The direct-IP session, while it runs: a HostedSession (hosting) or a SessionClient (joined).
    private IDisposable? _direct;

    // Whether this end's session ending has been told, so it is told once.
    private bool _directEndedShown;

    // Why the last direct join failed, for the menu and the console to show; null when it did not.
    private string? _directFailure;

    // The LAN discovery in flight, while a refresh is being answered; null otherwise.
    private LanDiscovery? _lanDiscovery;

    // The LAN games found by the last refresh, newest answers first within their arrival order.
    private readonly List<LanServer> _lanServers = [];

    /// <summary>Gets whether a direct-IP co-op session is running.</summary>
    public bool IsDirectCoopRunning => _direct is not null;

    /// <summary>Gets whether this end hosts the direct-IP session.</summary>
    public bool IsDirectCoopHost => _direct is HostedSession;

    // Where this end joined, as typed, for the status line; null when hosting or not joined.
    private string? _directJoinedAddress;

    /// <summary>Gets where the direct-IP session is, in words for the menu, or null when none runs.</summary>
    public string? DirectCoopStatus => _direct switch
    {
        HostedSession hosted => $"Hosting on port {hosted.LocalAddress.Port} — joiners connect to this phone's Wi-Fi address.",
        SessionClient => $"Joined {_directJoinedAddress}.",
        _ => null,
    };

    /// <summary>Gets why the last direct join failed, or null when it did not.</summary>
    public string? DirectCoopFailure => _directFailure;

    /// <summary>Gets the LAN games the last refresh found.</summary>
    public IReadOnlyList<LanServer> LanServers => _lanServers;

    /// <summary>Hosts a direct-IP co-op session on a UDP port, for joiners on this Wi-Fi.</summary>
    /// <param name="port">The UDP port to listen on; <see cref="SessionArguments.DefaultPort"/> (26001) unless told otherwise.</param>
    /// <remarks>
    /// The session attaches to the level on the next tick once one is up (the server creates its
    /// <c>ServerSession</c> in <c>BeforeTitleTick</c>), so this may be run from the main menu before
    /// the mission starts, or mid-mission — exactly like the loopback start. The host then starts the
    /// mission the usual way; joiners follow it in. A hosted session answers LAN broadcast queries
    /// with its name and map (it sets <c>NetServerOptions.Info</c>), so it appears in the joiners'
    /// LAN list without anything else being done.
    /// </remarks>
    public void HostDirectCoop(int port = SessionArguments.DefaultPort)
    {
        if (_direct is not null)
        {
            _logger.Information("Coop", "The direct-IP session is already running.");
            return;
        }

        StopLoopbackCoop();
        StopRoomCoop();
        _directFailure = null;
        _directJoinedAddress = null;

        string name = _configuration.Active?.Name is { Length: > 0 } profileName ? profileName : "Jones";
        string version = Version();
        string map = _session.Mission is { } mission ? mission.Id.ToString(CultureInfo.InvariantCulture) : string.Empty;
        string content = MultiplayerProtocol.ContentFingerprint(
            _titleRuntime.Title.Id, _titleRuntime.Mods.Select(m => $"{m.Id}@{m.Version}"));

        UdpTransport transport;
        try
        {
            transport = UdpTransport.Open(port);
        }
        catch (Exception ex) when (ex is System.Net.Sockets.SocketException or InvalidOperationException)
        {
            _directFailure = $"Could not listen on port {port}: {ex.Message}";
            _logger.Warning("Coop", _directFailure);
            return;
        }

        HostedSession hosted = new(
            transport,
            new HostedSessionOptions(
                Name: $"{name}'s game",
                MaxPlayers: 3,
                Password: string.Empty,
                Mode: "coop",
                Map: map,
                Version: version,
                IncludesHost: true,
                HostName: name,
                Content: content),
            _titleRuntime.Title.Id,
            GameClock.DefaultTickRate,
            _logger);

        _direct = hosted;
        _directEndedShown = false;
        TickObserver = hosted;
        _logger.Information("Coop", $"Direct-IP co-op hosting on port {port}: joiners on this Wi-Fi connect to this phone's address.");
    }

    /// <summary>Joins a direct-IP co-op session by its host's Wi-Fi address.</summary>
    /// <param name="address">The host, as <c>host[:port]</c> — a bare host takes port 26001.</param>
    /// <remarks>
    /// The client attaches once a level is up and then follows its host into missions: join first,
    /// and the host starting a mission carries this phone into it. Joining needs no mission running
    /// on this phone yet.
    /// </remarks>
    public void JoinDirectCoop(string address)
    {
        if (_direct is not null)
        {
            _logger.Information("Coop", "The direct-IP session is already running.");
            return;
        }

        if (string.IsNullOrWhiteSpace(address))
        {
            _directFailure = "Enter the host's Wi-Fi address, as 192.168.1.5 or 192.168.1.5:26001.";
            _logger.Warning("Coop", _directFailure);
            return;
        }

        if (UdpTransport.Parse(address.Trim(), SessionArguments.DefaultPort) is not { } server)
        {
            _directFailure = $"'{address.Trim()}' is not a server address.";
            _logger.Warning("Coop", _directFailure);
            return;
        }

        StopLoopbackCoop();
        StopRoomCoop();
        _directFailure = null;

        string name = _configuration.Active?.Name is { Length: > 0 } profileName ? profileName : "Jones";
        string version = Version();
        string content = MultiplayerProtocol.ContentFingerprint(
            _titleRuntime.Title.Id, _titleRuntime.Mods.Select(m => $"{m.Id}@{m.Version}"));

        SessionClient client = new(
            UdpTransport.Open(0),
            server,
            new JoinRequest(name, version, Password: string.Empty, content),
            _titleRuntime.Title.Id,
            _logger);

        _direct = client;
        _directJoinedAddress = server.ToString();
        _directEndedShown = false;
        TickObserver = client;
        _logger.Information("Coop", $"Direct-IP co-op joining {server}; following the host into its mission when it starts one.");
    }

    /// <summary>Stops the direct-IP session, if one runs, and gives the cheats back.</summary>
    public void StopDirectCoop()
    {
        if (_direct is null)
        {
            return;
        }

        _direct.Dispose();
        _direct = null;
        _directJoinedAddress = null;
        _followInto = null;
        ReleaseSessionCheatLock();
        _logger.Information("Coop", "Direct-IP co-op stopped.");
    }

    /// <summary>Asks every game on this Wi-Fi what it is, for the LAN list.</summary>
    /// <remarks>
    /// One broadcast; the answers arrive over the next second or two and are collected by
    /// <see cref="UpdateLanDiscovery"/>, which the frame loop calls. A refresh while one is in
    /// flight replaces it.
    /// </remarks>
    public void RefreshLanServers()
    {
        _lanDiscovery?.Dispose();
        _lanDiscovery = new LanDiscovery(_titleRuntime.Title.Id);
        _lanServers.Clear();
        _logger.Information("Coop", "Looking for co-op games on this Wi-Fi…");
    }

    /// <summary>Collects the LAN answers that have arrived since the last frame.</summary>
    /// <remarks>
    /// Called once a frame from <c>BeginFramePass</c>. Only this game's own title is kept: a
    /// server of another title answers the same broadcast, and its line would join the wrong game.
    /// </remarks>
    public void UpdateLanDiscovery()
    {
        if (_lanDiscovery is not { } discovery)
        {
            return;
        }

        foreach (LanServer found in discovery.TakeFound())
        {
            if (found.Info.TitleId != _titleRuntime.Title.Id)
            {
                continue;
            }

            int at = _lanServers.FindIndex(s => s.Address == found.Address);
            if (at >= 0)
            {
                _lanServers[at] = found;
            }
            else
            {
                _lanServers.Add(found);
            }
        }
    }

    // A direct-IP client goes where its host goes: on to the next mission, or into the same one again.
    // The host end has nothing to follow (HostedSession is no ISessionFollower), so this only ever
    // acts for a joined client. The end is logged once and the session stopped; there is no room and
    // no room-closed page over a direct session.
    private void FollowDirectSession(FrameLoopState state)
    {
        if (_direct is null || TickObserver is not ISessionFollower follower)
        {
            return;
        }

        if (follower.Ended is { } reason)
        {
            if (!_directEndedShown)
            {
                _directEndedShown = true;
                _logger.Warning("Coop", $"The direct-IP session ended ({reason}); stopping it.");
                StopDirectCoop();
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
            _logger.Information("Coop", $"Following the direct-IP host into mission {into}.");
            GoIntoMission(state, into);
        }
    }

    /// <summary>Registers the direct-IP entry points: <c>coop_host</c>, <c>coop_join</c>, <c>coop_leave</c>, <c>coop_lan</c>.</summary>
    /// <param name="console">The console system.</param>
    private void RegisterDirectIpCommands(ConsoleSystem console)
    {
        console.Commands.Add(
            "coop_host",
            "Hosts a direct-IP co-op session on this Wi-Fi (joiners connect to this phone's address). coop_host [port].",
            context =>
            {
                int port = SessionArguments.DefaultPort;
                if (context.Count > 0 && (!int.TryParse(context[0], NumberStyles.Integer, CultureInfo.InvariantCulture, out port)
                    || port is < 1 or > 65535))
                {
                    context.Error("Usage: coop_host [port 1-65535].");
                    return;
                }

                HostDirectCoop(port);
                context.Print(_direct is not null
                    ? $"Direct-IP co-op hosting on port {port}. Joiners connect to this phone's Wi-Fi address on port {port}."
                    : _directFailure ?? "Direct-IP co-op did not start; see the log.");
            });

        console.Commands.Add(
            "coop_join",
            "Joins a direct-IP co-op session on this Wi-Fi. coop_join <host[:port]>.",
            context =>
            {
                if (context.Count == 0)
                {
                    context.Error("Usage: coop_join <host[:port]> (e.g. coop_join 192.168.1.5).");
                    return;
                }

                JoinDirectCoop(context[0]);
                context.Print(_direct is not null
                    ? "Direct-IP co-op joining; following the host into its mission when it starts one."
                    : _directFailure ?? "Direct-IP co-op did not start; see the log.");
            },
            "<host[:port]>");

        console.Commands.Add(
            "coop_leave",
            "Stops the direct-IP co-op session, if one runs.",
            context =>
            {
                StopDirectCoop();
                context.Print("Direct-IP co-op stopped.");
            });

        console.Commands.Add(
            "coop_lan",
            "Lists the co-op games on this Wi-Fi. coop_lan [refresh].",
            context =>
            {
                if (context.Count > 0 && context[0].Equals("refresh", StringComparison.OrdinalIgnoreCase))
                {
                    RefreshLanServers();
                    context.Print("Looking for co-op games on this Wi-Fi…");
                    return;
                }

                if (_lanServers.Count == 0)
                {
                    context.Print("No co-op games found on this Wi-Fi yet. coop_lan refresh to look again.");
                    return;
                }

                foreach (LanServer server in _lanServers)
                {
                    context.Print($"{server.Address} — {server.Info.Name}, {HostedSession.MapName(server.Info.Map)}, {server.Info.Players}/{server.Info.MaxPlayers} players.");
                }
            });
    }

    private string Version() => typeof(GameHost).Assembly
        .GetCustomAttributes(typeof(System.Reflection.AssemblyInformationalVersionAttribute), false)
        .OfType<System.Reflection.AssemblyInformationalVersionAttribute>().FirstOrDefault()?.InformationalVersion ?? "dev";
}
