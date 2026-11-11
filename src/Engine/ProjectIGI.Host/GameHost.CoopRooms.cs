using System.Globalization;
using ProjectIGI.Frontend;
using ProjectIGI.Game.Multiplayer;
using ProjectIGI.Host.Multiplayer;
using ProjectIGI.Net.Rooms;
using ProjectIGI.Net.WebRtc;

namespace ProjectIGI.Host;

/// <summary>
/// Co-op through rooms on the master server: a room hosted here for friends anywhere to join by
/// its code, a public list of rooms to join, and the relay for the pairs whose routers allow
/// nothing better. The session runs as the host's tick observer, as one started from the command
/// line does.
/// </summary>
/// <remarks>
/// Milestone 3. Upstream's rooms path (<c>apps/OpenIGI.Desktop/Program.cs</c>, <c>StartSession</c>)
/// reaches the same place: <c>-join</c>/<c>-host</c> go through <c>RoomSessions.Start</c> behind a
/// <c>DataChannelPeerFactory.IsAvailable()</c> check, and the room's transport is built on
/// <c>RoomTransport.DefaultMaster</c> (https://master.openigi.com — upstream's live server, used
/// here as the default; the permission ask to ShahriyarB about using it is outstanding).
/// <para>
/// The library is optional at runtime, exactly as upstream's is: with no libdatachannel beside
/// the game <see cref="DataChannelPeerFactory.IsAvailable"/> is false, no <see cref="CoopRooms"/>
/// is made, and the menu says rooms aren't available here — solo play and Wi-Fi co-op are
/// untouched. The native library itself ships in a separate PR; this one is the managed code
/// that P/Invokes it, so it compiles without the .so and needs it only at runtime, when a room
/// is actually opened.
/// </para>
/// <para>
/// Mutual exclusion with loopback and direct-IP: the three share the single
/// <c>TickObserver</c> slot and the <c>_followInto</c> field, and only one may hold them. A room
/// session beginning stops a running loopback or direct session (in the observe action below,
/// the one place a room session takes the slot), and starting loopback or direct stops a running
/// room (<see cref="StopRoomCoop"/>). A room ending is a note on the Co-op screen, as a direct
/// session's is: there is no room-closed page in the port (upstream opens one over the mission;
/// the port's loopback and direct paths already log the end and stop instead).
/// </para>
/// <para>
/// Voice needs nothing new here: <c>UpdateCoopVoice</c> talks through <c>Talk</c>, the session's
/// <c>ISessionTalk</c>, and both room session types implement it over whatever transport they were
/// built on — a voice packet is a <c>SessionTalk</c> message inside the replicated session, not a
/// UDP datagram, so it rides the WebRTC data channel exactly as it rides the loopback network or
/// a UDP socket. Chat and marks are the same: session-generic, no transport assumption anywhere.
/// </para>
/// </remarks>
public sealed partial class GameHost
{
    // The rooms layer, once made: null where this build has no WebRTC library (see CreateCoop).
    // Made once, before the shell that offers it; the session it holds comes and goes with rooms.
    private CoopRooms? _coop;

    // Whether a room session's end has been told, so it is told once.
    private bool _roomEndedShown;

    /// <summary>Gets or sets what makes this build's WebRTC connections, or <see langword="null"/> where it has none.</summary>
    /// <remarks>
    /// Set by the composition root before <see cref="Start"/>: the desktop's libdatachannel where it is built. Without it
    /// the menu's co-op section says rooms aren't available here. The port has no composition root that knows about
    /// libdatachannel, so <see cref="CreateCoop"/> fills it from <see cref="DataChannelPeerFactory.IsAvailable"/> instead.
    /// </remarks>
    public IRtcPeerFactory? RoomPeers { get; set; }

    // Made once, before the shell that offers it. Null where this build has no WebRTC library: the menu then says rooms
    // aren't available here, and everything else plays as before.
    private CoopRooms? CreateCoop()
    {
        IRtcPeerFactory? peers = RoomPeers ?? (DataChannelPeerFactory.IsAvailable() ? new DataChannelPeerFactory(_logger) : null);
        if (peers is null)
        {
            _logger.Information("Coop", "Rooms need the WebRTC library (libdatachannel), which isn't beside the game; playing alone or over Wi-Fi.");
            return null;
        }

        return new CoopRooms(
            peers,
            () => _titleRuntime.Title.Id,
            () => _configuration.Active?.Name is { Length: > 0 } name ? name : "Jones",
            () => _configuration.Active?.Difficulty ?? 1,
            () => MultiplayerProtocol.ContentFingerprint(_titleRuntime.Title.Id, _titleRuntime.Mods.Select(m => $"{m.Id}@{m.Version}")),
            observer =>
            {
                if (observer is not null)
                {
                    // A room session takes the one TickObserver slot: a loopback or direct session
                    // still running is stopped first, so its session object is disposed rather than
                    // left ticking nowhere. (The Leave() a Host()/Join() runs first only clears the
                    // slot; the dispose is here.)
                    _roomEndedShown = false;
                    StopLoopbackCoop();
                    StopDirectCoop();
                }

                TickObserver = observer;
            },

            // No look preview and no drag-to-turn: the port's ISoldierBodies has none of the
            // preview-body methods upstream's preview needs (BorrowLevel, ShowPreviewBody,
            // TickPreviewBody, DrawPreviewBody), and the title runtime names no preview weapon.
            // The Co-op screen carries no look picker, so these are never called.
            static _ => { },
            static _ => { },
            Version(),
            _logger);
    }

    /// <summary>Leaves the room, if in one, and gives the cheats back.</summary>
    /// <remarks>
    /// Called when loopback or direct starts, and when the mission is abandoned (upstream's
    /// <c>_coop?.Leave()</c> in its abandon path). Idempotent: leaving with no room is a no-op.
    /// </remarks>
    private void StopRoomCoop()
    {
        bool was = _coop is { Status.Phase: not CoopPhase.None };
        _coop?.Leave();
        if (was)
        {
            _logger.Information("Coop", "Left the room.");
        }
    }

    // A room client goes where its host goes: on to the next mission, or into the same one again.
    // The host end has nothing to follow (HostedSession is no ISessionFollower), so this only ever
    // acts for a joined client. The end is logged once and the session stopped; there is no room
    // and no room-closed page over a room session, as there is none over a direct one.
    private void FollowRoomSession(FrameLoopState state)
    {
        // Only this session's follower is followed here: a loopback or direct client's follower is
        // its own Follow method's, and following more than one would fight over _followInto. The
        // rooms layer is long-lived, so "a room runs" is its status, not its existence: None means
        // no room, Connecting while it opens or is found, Playing while in one, Failed after one ends.
        if (_coop is not { Status.Phase: not CoopPhase.None } || TickObserver is not ISessionFollower follower)
        {
            return;
        }

        if (follower.Ended is { } reason)
        {
            if (!_roomEndedShown)
            {
                _roomEndedShown = true;
                _logger.Warning("Coop", $"The room ended ({reason}); stopping it.");
                StopRoomCoop();
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
            _logger.Information("Coop", $"Following the room's host into mission {into}.");
            GoIntoMission(state, into);
        }
    }

    /// <summary>Registers the room entry points: <c>coop_room host|join|leave|list|status</c>.</summary>
    /// <param name="console">The console system.</param>
    private void RegisterRoomCommands(ConsoleSystem console)
    {
        console.Commands.Add(
            "coop_room",
            "Hosts or joins a co-op room on the master server (friends anywhere join by its code). coop_room host [mission] [public|private] | join <code> | leave | list | status.",
            context =>
            {
                if (_coop is null)
                {
                    context.Print("Rooms need the WebRTC library (libdatachannel), which isn't in this build yet.");
                    return;
                }

                string arg = context.Count > 0 ? context[0].ToLowerInvariant() : "status";
                switch (arg)
                {
                    case "host":
                    {
                        int mission = _session.Mission?.Id ?? 1;
                        if (context.Count > 1 && (!int.TryParse(context[1], NumberStyles.Integer, CultureInfo.InvariantCulture, out mission)
                            || _missions.Missions.All(m => m.Id != mission)))
                        {
                            context.Error("Usage: coop_room host [mission] [public|private] — the mission is one this game has.");
                            return;
                        }

                        bool listed = true;
                        if (context.Count > 2)
                        {
                            if (context[2].Equals("private", StringComparison.OrdinalIgnoreCase))
                            {
                                listed = false;
                            }
                            else if (!context[2].Equals("public", StringComparison.OrdinalIgnoreCase))
                            {
                                context.Error("Usage: coop_room host [mission] [public|private].");
                                return;
                            }
                        }

                        _coop.Host(mission, _configuration.Active?.Difficulty ?? 1, listed);
                        context.Print($"Opening a {(listed ? "public" : "private")} room on mission {mission} — the code shows on the Co-op screen (coop_room status); start mission {mission} from the menu when friends are in.");
                        break;
                    }

                    case "join":
                    {
                        if (context.Count < 2)
                        {
                            context.Error("Usage: coop_room join <code>.");
                            return;
                        }

                        _coop.Join(context[1]);
                        context.Print($"Finding room {context[1].Trim().ToUpperInvariant()}…");
                        break;
                    }

                    case "leave":
                        _coop.Leave();
                        context.Print("Left the room.");
                        break;

                    case "list":
                        _coop.RefreshListing();
                        if (_coop.Listing is not { } rooms)
                        {
                            context.Print("Looking for public rooms… run coop_room list again in a moment.");
                        }
                        else if (rooms.Count == 0)
                        {
                            context.Print(_coop.ListingError ?? "No public rooms right now.");
                        }
                        else
                        {
                            foreach (CoopRoomInfo room in rooms)
                            {
                                context.Print($"{room.Code} — {room.Name}, {HostedSession.MapName(room.MissionId.ToString(CultureInfo.InvariantCulture))}, {room.Players}/{room.MaxPlayers} players{(room.Passworded ? " (passworded)" : string.Empty)}.");
                            }
                        }

                        break;

                    case "status":
                        CoopStatus status = _coop.Status;
                        context.Print(status.Phase switch
                        {
                            CoopPhase.Playing when status.Hosting => $"Hosting room {status.Code} — friends join with that code.",
                            CoopPhase.Playing => $"In room {status.Code}.",
                            CoopPhase.Connecting => status.Hosting ? "Opening a room…" : $"Finding room {status.Code}…",
                            CoopPhase.Failed => $"The room failed: {status.Error}.",
                            _ => "In no room. coop_room host to open one, coop_room join <code> to join one.",
                        });
                        break;

                    default:
                        context.Error("Usage: coop_room host [mission] [public|private] | join <code> | leave | list | status.");
                        break;
                }
            });
    }
}
