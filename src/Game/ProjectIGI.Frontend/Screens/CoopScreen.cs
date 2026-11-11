using System.Globalization;
using ProjectIGI.Core.Graphics;
using ProjectIGI.Input;
using ProjectIGI.UI;
using ProjectIGI.UI.Focus;
using ProjectIGI.UI.Layout;
using ProjectIGI.UI.Widgets;

namespace ProjectIGI.Frontend.Screens;

/// <summary>
/// The co-op section: the loopback session Milestone 1 can run, the Wi-Fi direct-IP co-op
/// Milestone 2 built — host a game on this Wi-Fi, pick one from the LAN list, or join one by
/// its address — and the rooms Milestone 3 runs on the master server: host a room for friends
/// anywhere to join by its code, or pick one from the public list. Reached from the main menu's
/// Co-op button instead of the console.
/// </summary>
/// <remarks>
/// The closest faithful equivalent of upstream's shell Co-op tab for what exists today. The
/// master server is live again (Ray, 2026-11-11 13:54 IST: build the master server path), so the
/// rooms section is upstream's own — host / join-by-code / public rooms against
/// master.openigi.com over WebRTC, with the relay for pairs whose routers allow nothing better —
/// and Wi-Fi direct-IP stays as the fallback for two phones on the same network.
/// Upstream's screen is a three-column desktop layout — rooms on the left, a live 3D look in the
/// middle to drag round, a HOST panel on the right — with host / join-by-code / public rooms,
/// mission and difficulty pickers, and a room code. What survives here, and what does not:
/// <list type="bullet">
/// <item>The three columns become one stacked column in the port's tactical frame, inside a
/// ScrollView with Back fixed at the bottom (the settings screen's shape): the frame is 920
/// design units wide and the rows — rooms, loopback, Wi-Fi host, LAN list, typed join — are more
/// than it holds. The desktop's 560 px columns were never sized for a phone.</item>
/// <item>Host a room opens it on Mission 1 and the code shows on this screen; the mission starts
/// from Play, when friends are in — NOT from Host, as upstream's does. Port adaptation: starting
/// a mission leaves the menu for the level, so upstream's start-at-once would carry the host into
/// the level before the code was ever seen. Joining a room still starts its mission at once: the
/// joiner follows a host already playing.</item>
/// <item>There is no mission or difficulty picker: the host plays Mission 1 through the
/// existing Play path (difficulty 1, like the campaign screen's OK), and a joiner picks
/// nothing — it follows the host into whatever mission the host starts.</item>
/// <item>Join-by-code, for Wi-Fi, becomes join-by-typed-address: the host has no code, it has a
/// Wi-Fi address, and the screen says where to read it (Android Settings → Wi-Fi — managed code
/// cannot discover it). The address box is the same shape as upstream's code box (a TextBox
/// beside its button); tapping it focuses it, which is what summons the soft keyboard. Rooms
/// keep a real join-by-code box of their own, above.</item>
/// <item>The public room list is upstream's, fed by the master: each a row with name, mission and
/// players, tap to join. Upstream re-asks for its list every 5 seconds; this screen does the
/// same — unlike the LAN broadcast, a refresh keeps what the list had until the new one comes,
/// so it never flickers empty.</item>
/// <item>There is no look preview and no drag-to-turn: the port's ISoldierBodies has none of
/// the preview-body methods upstream's preview needs, and the title runtime names no preview
/// weapon. The screen carries no preview rather than a dead one.</item>
/// <item>There is no room-closed page: a room ending is a note on this screen, and the last code
/// stays in the box for a rejoin. The same holds for a direct session ending, which is a note
/// here too.</item>
/// <item>Chat and marks are typed in the mission (coop_chat, coop_say, coop_mark) and voice
/// is push-to-talk from Settings → Co-op (the voice PR's HUD button and toggle); this screen
/// carries only the note that says so, not a second chat UI. The scoreboard has no key or
/// HUD hand in the port yet, so there is no scoreboard row either. Voice rides the session's
/// own talk channel, so it works over a room exactly as over Wi-Fi or loopback — no
/// transport-specific voice work was needed.</item>
/// </list>
/// <para>
/// The screen never touches the settings return path: it is only reachable from the shell's own
/// main menu (and Back returns there), so closing it cannot put the shell away over a retail menu
/// that is not running, the way the settings icon's unconditional flag can.
/// </para>
/// <para>
/// The wording below is deliberately plain about what loopback is, because Ray read the first
/// version as a lobby with missing partners ("nothing to connect to it seems", 2026-11-11):
/// loopback runs on this device only, the second player is a copy of the player, and there is
/// nothing to connect to, no room and no code, by design. Do not tidy that plain wording back
/// into jargon. The Wi-Fi wording is plain the same way: same network, no accounts, no master
/// server — and when the list is empty, the typed address is the fallback, because some access
/// points filter broadcasts. Rooms are plain the same way again: friends anywhere, by code, no
/// port to open — and when the public list is empty, the code is the way in.
/// </para>
/// </remarks>
public sealed class CoopScreen : ShellScreen
{
    private Label? _statusLabel;
    private Label? _noticeLabel;
    private IgiMenuButton? _toggleBtn;
    private IgiMenuButton? _playBtn;
    private IgiMenuButton? _hostBtn;
    private IgiMenuButton? _leaveBtn;
    private IgiMenuButton? _joinBtn;
    private TextBox? _addressBox;
    private StackPanel? _lanStack;
    private Label? _lanEmptyLabel;
    private ScrollView? _scroll;

    private string? _lanSignature;
    private float _lanSinceRefresh = 999f;
    private float _lanPoll;
    private bool _wasDirectRunning;
    private bool _shownDirectRunning;
    private bool _shownLoopbackRunning;
    private bool _hostAttemptPending;
    private bool _joinAttemptPending;
    private string _joinAddress = string.Empty;
    private bool _leftIntentionally;
    private string _noticeText = string.Empty;
    private bool _noticeError;

    private IgiMenuButton? _hostPublicBtn;
    private IgiMenuButton? _hostPrivateBtn;
    private IgiMenuButton? _leaveRoomBtn;
    private IgiMenuButton? _joinCodeBtn;
    private IgiMenuButton? _refreshRoomsBtn;
    private TextBox? _codeBox;
    private StackPanel? _roomsStack;
    private Label? _roomsEmptyLabel;
    private Label? _roomCodeLabel;
    private Label? _roomPlayersLabel;

    private string? _roomsSignature;
    private float _roomsSinceRefresh = 999f;
    private float _roomsPoll;
    private CoopStatus _shownRoomStatus;
    private bool _wasRoomRunning;
    private bool _leftRoomIntentionally;
    private bool _roomHostPending;
    private bool _roomJoinPending;
    private string _roomJoinCode = string.Empty;

    private UiVec2? _touchDragStart;
    private float _touchDragStartOffset;
    private bool _isDragging;
    private Control? _pendingTapTarget;

    /// <summary>Initializes a new instance of the <see cref="CoopScreen"/> class.</summary>
    /// <param name="context">The shared shell context.</param>
    public CoopScreen(ShellContext context)
        : base(context)
    {
    }

    /// <inheritdoc/>
    protected override bool HasChrome => false;

    /// <inheritdoc/>
    protected override ShellTab Tab => ShellTab.Coop;

    /// <inheritdoc/>
    public override float BackdropBlur => 0f;

    /// <inheritdoc/>
    protected override UiElement? BuildContent(LayoutContext context)
    {
        UiTheme theme = Context.Theme;

        var root = new Canvas();

        // 1. Logo at Top Center
        var logo = new IgiLogo(theme)
        {
            Margin = new Thickness(0f, 20f, 0f, 0f),
            VerticalAlignment = VerticalAlignment.Top,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        root.Add(logo, new Anchor(UiVec2.Zero, new UiVec2(1f, 0.20f), Thickness.Zero));

        // 2. Central Green Wireframe Tactical Box ("Co-op")
        var frame = new IgiTacticalFrame(theme, "Co-op")
        {
            Width = 920f,
            Height = 780f,
            Margin = new Thickness(0f, 40f, 0f, 0f),
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };

        // The rows scroll: loopback, Wi-Fi host, the LAN list and the typed join are more
        // than the frame holds, so the list lives in a ScrollView and Back stays fixed at
        // the bottom of the frame (the settings screen's shape).
        _scroll = new ScrollView(theme)
        {
            Width = 830f,
            Height = 640f,
            Margin = new Thickness(45f, 54f, 0f, 0f),
            ScrollbarWidth = 14f,
            ScrollbarHitWidth = 56f,
        };

        var menuStack = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 10f,
            Width = 800f,
        };
        _scroll.SetContent(menuStack);

        // Session status, reusing the console's wording. Wrapped: the host's status line
        // ("Hosting on port 26001 — joiners connect to this phone's Wi-Fi address.") is
        // longer than the frame at one line.
        _statusLabel = new Label(theme.Heading, StatusText(), 26f, Bgra32.FromRgb(165, 255, 185))
        {
            Wrap = true,
            Width = 780f,
            TextAlignment = HorizontalAlignment.Center,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        menuStack.AddChild(_statusLabel);

        // The live note under the status: waiting for the host, a join that did not start,
        // or a session that ended without the player leaving it. Empty most of the time.
        _noticeLabel = new Label(theme.Body, string.Empty, 18f, theme.TextMuted)
        {
            Wrap = true,
            Width = 780f,
            TextAlignment = HorizontalAlignment.Center,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        menuStack.AddChild(_noticeLabel);

        // ── On this device (loopback, Milestone 1) ──────────────────────────
        menuStack.AddChild(SectionHeader(theme, "On this device"));

        _toggleBtn = new IgiMenuButton(theme, ToggleText()) { TextSize = 30f, Height = 60f, Width = 760f };
        _toggleBtn.Activated += () =>
        {
            if (Context.Host.CoopLoopbackRunning)
            {
                Context.Host.StopLoopbackCoop();
            }
            else
            {
                // Starting loopback stops a Wi-Fi session (the two share one slot), so a
                // session ending here is the player's own doing, not a drop.
                _leftIntentionally = true;
                Context.Host.StartLoopbackCoop();
            }

            SetNotice(string.Empty, error: false);
            RefreshSessionState();
        };
        menuStack.AddChild(_toggleBtn);

        _playBtn = new IgiMenuButton(theme, "Play co-op - Mission 1") { TextSize = 30f, Height = 60f, Width = 760f };
        _playBtn.Activated += () =>
        {
            // Leaving for a mission ends the retail-menu visit: if this screen was opened
            // from the retail menu, the flag must not survive into a co-op screen opened
            // later off the shell's own main menu, whose Back belongs there, not on the
            // retail menu.
            Context.CoopFromRetailMenu = false;

            if (Context.Host.DirectCoopRunning)
            {
                // Hosting on Wi-Fi: the mission starts under the session that is already
                // running — loopback must not be started, it would stop the Wi-Fi session.
                // (Disabled while joined: the joiner follows the host in and picks nothing.)
                Context.Host.StartMission(1, 1);
                return;
            }

            if (IsRoomHost)
            {
                // Hosting a room: the mission starts under the room that is already
                // running — loopback must not be started, it would stop the room.
                // (Disabled while joined: the joiner follows the host in and picks nothing.)
                Context.Host.StartMission(1, 1);
                return;
            }

            // The existing mission path, difficulty 1 like the campaign screen's OK: the
            // loopback client follows the host into the mission on the next tick.
            if (!Context.Host.CoopLoopbackRunning)
            {
                Context.Host.StartLoopbackCoop();
            }

            Context.Host.StartMission(1, 1);
        };
        menuStack.AddChild(_playBtn);

        var loopbackNote = new Label(
            theme.Body,
            "Loopback only — on this device, nothing to connect to. The second player is a copy of you and follows your input once the level is up. Tap Start co-op, then Play co-op – Mission 1 (Play starts co-op first if it isn't running). Co-op turns cheats off while the session runs.",
            18f,
            theme.TextMuted)
        {
            Wrap = true,
            Width = 780f,
            TextAlignment = HorizontalAlignment.Center,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        menuStack.AddChild(loopbackNote);

        // ── Rooms — play with anyone (master server, Milestone 3) ────────
        menuStack.AddChild(SectionHeader(theme, "Rooms — play with anyone"));

        // The room's code, large, while hosting: friends join with it. Empty otherwise.
        _roomCodeLabel = new Label(theme.Heading, string.Empty, 44f, theme.Accent)
        {
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        menuStack.AddChild(_roomCodeLabel);

        _roomPlayersLabel = new Label(theme.Body, string.Empty, 18f, theme.TextMuted)
        {
            Wrap = true,
            Width = 780f,
            TextAlignment = HorizontalAlignment.Center,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        menuStack.AddChild(_roomPlayersLabel);

        _hostPublicBtn = new IgiMenuButton(theme, "Host a public room – Mission 1") { TextSize = 28f, Height = 56f, Width = 760f };
        _hostPublicBtn.Activated += () =>
        {
            if (Context.Host.Coop is { } coop)
            {
                _leftRoomIntentionally = false;
                _roomHostPending = true;
                coop.Host(1, 1, listed: true);
                SetNotice("Opening a room…", error: false);
            }

            RefreshSessionState();
        };
        menuStack.AddChild(_hostPublicBtn);

        _hostPrivateBtn = new IgiMenuButton(theme, "Host a private room – Mission 1") { TextSize = 28f, Height = 56f, Width = 760f };
        _hostPrivateBtn.Activated += () =>
        {
            if (Context.Host.Coop is { } coop)
            {
                _leftRoomIntentionally = false;
                _roomHostPending = true;
                coop.Host(1, 1, listed: false);
                SetNotice("Opening a room…", error: false);
            }

            RefreshSessionState();
        };
        menuStack.AddChild(_hostPrivateBtn);

        _leaveRoomBtn = new IgiMenuButton(theme, "Leave room") { TextSize = 28f, Height = 56f, Width = 760f };
        _leaveRoomBtn.Activated += () =>
        {
            _leftRoomIntentionally = true;
            Context.Host.Coop?.Leave();
            SetNotice(string.Empty, error: false);
            RefreshSessionState();
        };
        menuStack.AddChild(_leaveRoomBtn);

        var roomsNote = new Label(
            theme.Body,
            Context.Host.Coop is not null
                ? "Rooms run on the master server — friends anywhere join with the room's code, no port to open, no same Wi-Fi. Hosting opens the room on Mission 1: the code shows above, then start the mission with Play when friends are in. A public room is listed below; a private one is reached by its code alone."
                : "Rooms need this build's WebRTC library, which isn't beside the game yet — the rooms below stay empty until it is. Wi-Fi co-op further down still works.",
            18f,
            theme.TextMuted)
        {
            Wrap = true,
            Width = 780f,
            TextAlignment = HorizontalAlignment.Center,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        menuStack.AddChild(roomsNote);

        // ── Join a room by its code ───────────────────────────────────────
        menuStack.AddChild(SectionHeader(theme, "Join a room by its code"));

        var codeRow = new FlexPanel
        {
            Orientation = Orientation.Horizontal,
            Gap = 12f,
            Width = 780f,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        _codeBox = new TextBox(theme)
        {
            Id = "room-code",
            Placeholder = "ROOM CODE",
            MaxLength = 6,
            VerticalAlignment = VerticalAlignment.Center,
            Tooltip = "The host's room code. Tapping the box opens the keyboard.",
        };
        codeRow.Add(_codeBox, 1f);
        _joinCodeBtn = new IgiMenuButton(theme, "Join") { TextSize = 28f, Height = 56f, Width = 150f };
        _joinCodeBtn.Activated += JoinByCode;
        codeRow.Add(_joinCodeBtn);
        menuStack.AddChild(codeRow);

        var codeNote = new Label(
            theme.Body,
            "Tapping the code box opens the keyboard. The code doesn't care about upper or lower case. Joining loads the mission the host plays — you follow the host in automatically.",
            18f,
            theme.TextMuted)
        {
            Wrap = true,
            Width = 780f,
            TextAlignment = HorizontalAlignment.Center,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        menuStack.AddChild(codeNote);

        // ── Public rooms ──────────────────────────────────────────────────
        menuStack.AddChild(SectionHeader(theme, "Public rooms"));

        _refreshRoomsBtn = new IgiMenuButton(theme, "Refresh public rooms") { TextSize = 28f, Height = 56f, Width = 760f };
        _refreshRoomsBtn.Activated += () =>
        {
            Context.Host.Coop?.RefreshListing();
            _roomsSinceRefresh = 0f;
            _roomsSignature = null;
            RebuildRoomsList();
        };
        menuStack.AddChild(_refreshRoomsBtn);

        _roomsStack = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 6f,
            Width = 780f,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        menuStack.AddChild(_roomsStack);

        _roomsEmptyLabel = new Label(theme.Body, "Looking for public rooms…", 18f, theme.TextMuted)
        {
            Wrap = true,
            Width = 780f,
            TextAlignment = HorizontalAlignment.Center,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        menuStack.AddChild(_roomsEmptyLabel);

        // ── Wi-Fi co-op (direct-IP, Milestone 2) ─────────────────────────────
        menuStack.AddChild(SectionHeader(theme, "Wi-Fi co-op"));

        _hostBtn = new IgiMenuButton(theme, "Host a Wi-Fi game") { TextSize = 28f, Height = 56f, Width = 760f };
        _hostBtn.Activated += () =>
        {
            _leftIntentionally = false;
            Context.Host.HostDirectCoop();
            _hostAttemptPending = true;
            SetNotice("Opening a Wi-Fi game…", error: false);
            RefreshSessionState();
        };
        menuStack.AddChild(_hostBtn);

        _leaveBtn = new IgiMenuButton(theme, "Leave Wi-Fi game") { TextSize = 28f, Height = 56f, Width = 760f };
        _leaveBtn.Activated += () =>
        {
            _leftIntentionally = true;
            Context.Host.StopDirectCoop();
            SetNotice(string.Empty, error: false);
            RefreshSessionState();
        };
        menuStack.AddChild(_leaveBtn);

        var wifiNote = new Label(
            theme.Body,
            "Wi-Fi only — both phones on the same network, no accounts, no master server. Joiners connect to this phone's Wi-Fi address: read it in Android Settings → Wi-Fi — the game cannot show its own address. Up to 3 joiners.",
            18f,
            theme.TextMuted)
        {
            Wrap = true,
            Width = 780f,
            TextAlignment = HorizontalAlignment.Center,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        menuStack.AddChild(wifiNote);

        // ── LAN games ─────────────────────────────────────────────────────────
        menuStack.AddChild(SectionHeader(theme, "LAN games on this Wi-Fi"));

        var refreshBtn = new IgiMenuButton(theme, "Refresh LAN games") { TextSize = 28f, Height = 56f, Width = 760f };
        refreshBtn.Activated += () =>
        {
            Context.Host.RefreshLanServers();
            _lanSinceRefresh = 0f;
            _lanSignature = null;
            RebuildLanList();
        };
        menuStack.AddChild(refreshBtn);

        _lanStack = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 6f,
            Width = 780f,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        menuStack.AddChild(_lanStack);

        _lanEmptyLabel = new Label(theme.Body, "Looking for games on this Wi-Fi…", 18f, theme.TextMuted)
        {
            Wrap = true,
            Width = 780f,
            TextAlignment = HorizontalAlignment.Center,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        menuStack.AddChild(_lanEmptyLabel);

        // ── Join by address ───────────────────────────────────────────────────
        menuStack.AddChild(SectionHeader(theme, "Join by address"));

        var addressRow = new FlexPanel
        {
            Orientation = Orientation.Horizontal,
            Gap = 12f,
            Width = 780f,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        _addressBox = new TextBox(theme)
        {
            Id = "wifi-address",
            Placeholder = "192.168.1.5 or 192.168.1.5:26001",
            MaxLength = 45,
            VerticalAlignment = VerticalAlignment.Center,
            Tooltip = "The host's Wi-Fi address. Tapping the box opens the keyboard.",
        };
        addressRow.Add(_addressBox, 1f);
        _joinBtn = new IgiMenuButton(theme, "Join") { TextSize = 28f, Height = 56f, Width = 150f };
        _joinBtn.Activated += JoinByAddress;
        addressRow.Add(_joinBtn);
        menuStack.AddChild(addressRow);

        var addressNote = new Label(
            theme.Body,
            "Tapping the address box opens the keyboard. A bare address joins port 26001. If the list above stays empty, your router may filter broadcasts — this is the fallback.",
            18f,
            theme.TextMuted)
        {
            Wrap = true,
            Width = 780f,
            TextAlignment = HorizontalAlignment.Center,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        menuStack.AddChild(addressNote);

        var talkNote = new Label(
            theme.Body,
            "In a mission: coop_chat to type a line, coop_say to say one, coop_mark to mark where you look. Voice is push-to-talk — Settings → Co-op.",
            18f,
            theme.TextMuted)
        {
            Wrap = true,
            Width = 780f,
            TextAlignment = HorizontalAlignment.Center,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        menuStack.AddChild(talkNote);

        frame.AddChild(_scroll);

        // Back stays fixed at the bottom of the frame, outside the scroll.
        var backBar = new FlexPanel
        {
            Orientation = Orientation.Horizontal,
            Gap = 28f,
            HorizontalAlignment = HorizontalAlignment.Right,
            VerticalAlignment = VerticalAlignment.Bottom,
            Margin = new Thickness(0f, 0f, 32f, 16f),
        };
        var backBtn = new IgiMenuButton(theme, "Back") { TextSize = 28f, Height = 56f, Width = 200f };
        backBtn.Activated += CloseCoop;
        backBar.Add(backBtn);
        frame.AddChild(backBar);

        root.Add(frame, new Anchor(UiVec2.Zero, UiVec2.One, Thickness.Zero));

        RefreshSessionState();
        return root;
    }

    /// <inheritdoc/>
    /// <remarks>
    /// A fresh look for games every time the page opens; the answers arrive over the next
    /// second or two and <see cref="OnUpdate"/> rebuilds the rows as they come in.
    /// </remarks>
    protected override void OnEnter()
    {
        _lanSinceRefresh = 0f;
        _lanSignature = null;
        _wasDirectRunning = Context.Host.DirectCoopRunning;
        Context.Host.RefreshLanServers();
        RebuildLanList();

        _roomsSinceRefresh = 0f;
        _roomsSignature = null;
        _wasRoomRunning = IsRoomRunning;
        Context.Host.Coop?.RefreshListing();
        RebuildRoomsList();
    }

    /// <inheritdoc/>
    /// <remarks>
    /// The LAN answers arrive after the refresh, and a session can end while the page is up,
    /// so the page watches the host every frame and only rebuilds the rows when the list
    /// actually changed — rebuilding every frame would drop the address box's focus and
    /// the keyboard with it.
    /// </remarks>
    protected override void OnUpdate(float elapsedSeconds)
    {
        if (_lanSinceRefresh < 900f)
        {
            _lanSinceRefresh += elapsedSeconds;
        }

        bool directRunning = Context.Host.DirectCoopRunning;
        bool loopbackRunning = Context.Host.CoopLoopbackRunning;

        // A Host tap that never got a session: the only way HostDirectCoop fails is the
        // listen (port taken, Wi-Fi off) — the rooms layer keeps the exact reason on the
        // host, but the menu seam does not expose it, so the screen says the two things
        // it can distinguish: it did not start, and what usually causes that.
        if (_hostAttemptPending)
        {
            _hostAttemptPending = false;
            if (directRunning)
            {
                SetNotice(string.Empty, error: false);
            }
            else
            {
                SetNotice("Could not listen on port 26001 — another app may already use it, or Wi-Fi is off.", error: true);
            }
        }

        // A Join tap that never got a session: the address did not parse (a session
        // already running would have left Join disabled). A well-formed address starts
        // the client at once, so still-not-running one frame later means bad input.
        if (_joinAttemptPending)
        {
            _joinAttemptPending = false;
            if (directRunning)
            {
                SetNotice($"Joined {_joinAddress} — waiting for the host to start a mission.", error: false);
            }
            else
            {
                SetNotice($"Could not join '{_joinAddress}' — that is not a server address. Use the host's Wi-Fi address, as 192.168.1.5 or 192.168.1.5:26001.", error: true);
            }
        }

        // A session that stops without the player leaving it: the host left, the Wi-Fi
        // dropped, or the connection timed out. The rooms layer logs the exact end
        // reason but the menu seam does not expose it, so the screen cannot tell a
        // refusal (different mods) from no answer — it says the session ended and keeps
        // the last address in the box for a rejoin.
        if (_wasDirectRunning && !directRunning && !_leftIntentionally)
        {
            SetNotice("The Wi-Fi session ended — the host left, the Wi-Fi dropped, or the connection timed out. Your last address is still in the box above; tap Join to try again.", error: true);
        }

        if (directRunning)
        {
            // A live session means any later end is unprompted until the player leaves it.
            _leftIntentionally = false;
            if (IsDirectJoined)
            {
                SetNotice("Joined — waiting for the host to start a mission. You follow the host in automatically; you don't pick a mission.", error: false);
            }
            else
            {
                SetNotice(string.Empty, error: false);
            }
        }

        _wasDirectRunning = directRunning;

        // Rooms: the list and the room change in the background, and a room can end
        // while the page is up, so the page watches the rooms layer every frame and
        // only rebuilds the rows when the list actually changed — rebuilding every
        // frame would drop the code box's focus and the keyboard with it.
        CoopStatus roomStatus = RoomStatus;
        bool roomRunning = roomStatus.Phase != CoopPhase.None;

        // A Host or Join tap that never got a room: the master could not be reached,
        // the code was wrong, or the room was full. The rooms layer keeps the exact
        // reason on the status, and the screen says it.
        if (_roomHostPending || _roomJoinPending)
        {
            if (roomStatus.Phase == CoopPhase.Playing)
            {
                _roomHostPending = false;
                _roomJoinPending = false;
                if (roomStatus.Hosting)
                {
                    SetNotice(string.Empty, error: false);
                }
            }
            else if (roomStatus.Phase == CoopPhase.Failed)
            {
                string error = roomStatus.Error ?? "the room failed";
                if (_roomJoinPending)
                {
                    SetNotice($"Couldn't join room '{_roomJoinCode}': {error}.", error: true);
                }
                else
                {
                    SetNotice($"Couldn't open a room: {error}. The master server may be unreachable.", error: true);
                }

                _roomHostPending = false;
                _roomJoinPending = false;
            }
        }

        // A room that stops without the player leaving it: the host left, the
        // connection dropped, or the room closed. The code stays in the box above
        // for a rejoin, as the Wi-Fi address does.
        if (_wasRoomRunning && !roomRunning && !_leftRoomIntentionally)
        {
            SetNotice("The room ended — the host left, the connection dropped, or the room closed. Your last code is still in the box above; tap Join to try again.", error: true);
        }

        if (roomRunning)
        {
            // A live room means any later end is unprompted until the player leaves it.
            _leftRoomIntentionally = false;
        }

        _wasRoomRunning = roomRunning;

        if (roomStatus != _shownRoomStatus)
        {
            RefreshSessionState();
        }

        // The public list is re-asked every few seconds while in no room, as upstream
        // does: unlike the LAN broadcast, a refresh keeps what the list had until the
        // new one comes, so it never flickers empty.
        if (_roomsSinceRefresh < 900f)
        {
            _roomsSinceRefresh += elapsedSeconds;
        }

        if (_roomsSinceRefresh >= 5f && roomStatus.Phase == CoopPhase.None)
        {
            _roomsSinceRefresh = 0f;
            Context.Host.Coop?.RefreshListing();
        }

        _roomsPoll += elapsedSeconds;
        if (_roomsPoll >= 0.25f)
        {
            _roomsPoll = 0f;
            RebuildRoomsList();
        }

        if (directRunning != _shownDirectRunning || loopbackRunning != _shownLoopbackRunning)
        {
            RefreshSessionState();
        }

        // Answers arrive over a second or two, so four looks a second is plenty — and
        // the list is a fresh allocation per read, so every frame would churn for nothing.
        _lanPoll += elapsedSeconds;
        if (_lanPoll >= 0.25f)
        {
            _lanPoll = 0f;
            RebuildLanList();
        }
    }

    /// <inheritdoc/>
    protected override bool HandleInput(UiNavigation nav, InputState input)
    {
        if (nav.Back)
        {
            CloseCoop();
            return false;
        }

        // Drag to scroll the rows, mirroring the mission list: a drag scrolls, a tap
        // still activates the control under the pointer (and focuses the address box,
        // which is what summons the keyboard).
        if (_scroll is not null)
        {
            var pointer = new UiVec2(input.Mouse.X, input.Mouse.Y);
            bool insideScroll = _scroll.Bounds.Contains(pointer);

            if (input.Mouse.WasPressed(MouseButton.Left))
            {
                if (insideScroll && !_scroll.IsOverScrollbar(pointer))
                {
                    _touchDragStart = pointer;
                    _touchDragStartOffset = _scroll.ScrollOffset;
                    _isDragging = false;
                    _pendingTapTarget = Focus?.FocusAt(pointer) as Control;
                    return false;
                }
            }
            else if (_touchDragStart is { } start && input.Mouse.IsDown(MouseButton.Left))
            {
                float dy = pointer.Y - start.Y;
                if (!_isDragging && MathF.Abs(dy) > 10f)
                {
                    _isDragging = true;
                }

                if (_isDragging)
                {
                    _scroll.ScrollOffset = _touchDragStartOffset - dy;
                    return false;
                }
            }
            else if (input.Mouse.WasReleased(MouseButton.Left) || !input.Mouse.IsDown(MouseButton.Left))
            {
                if (_touchDragStart is not null)
                {
                    _touchDragStart = null;
                    if (!_isDragging)
                    {
                        _pendingTapTarget?.ActivateAt(pointer);
                    }

                    _isDragging = false;
                    _pendingTapTarget = null;
                    return false;
                }
            }
        }

        return base.HandleInput(nav, input);
    }

    /// <summary>Leaves the co-op screen: back to the retail menu it was opened from, or to the shell's main menu.</summary>
    /// <remarks>
    /// Mirrors <c>SettingsScreen.CloseConfig</c>: when opened from the retail main menu the player
    /// never saw the shell's landing page, so going back resets the stack to it as the home sentinel
    /// (which keeps the retail-menu overlay icons working) and puts the shell away over the retail
    /// menu. Otherwise Back lands on the shell's main menu as usual.
    /// </remarks>
    private void CloseCoop()
    {
        if (Context.CoopFromRetailMenu)
        {
            Context.CoopFromRetailMenu = false;
            Context.Stack.Reset(new MainMenuScreen(Context));
            Context.Host.ReturnToRetailMenu();
        }
        else
        {
            Context.Stack.Reset(new MainMenuScreen(Context));
        }
    }

    private void JoinByAddress()
    {
        string address = _addressBox?.Text.Trim() ?? string.Empty;
        if (address.Length == 0)
        {
            SetNotice("Enter the host's Wi-Fi address, as 192.168.1.5 or 192.168.1.5:26001.", error: true);
            return;
        }

        JoinAttempt(address);
    }

    private void JoinAttempt(string address)
    {
        _leftIntentionally = false;
        _joinAddress = address;
        _joinAttemptPending = true;
        Context.Host.JoinDirectCoop(address);
        SetNotice($"Joining {address}…", error: false);
        RefreshSessionState();
    }

    private void JoinByCode()
    {
        string code = _codeBox?.Text.Trim() ?? string.Empty;
        if (code.Length == 0)
        {
            SetNotice("Enter the room's code — the host reads it off the Co-op screen.", error: true);
            return;
        }

        JoinRoomByCode(code);
    }

    private void JoinRoomByCode(string code)
    {
        if (Context.Host.Coop is { } coop)
        {
            _leftRoomIntentionally = false;
            _roomJoinCode = code;
            _roomJoinPending = true;
            coop.Join(code);
            SetNotice($"Finding room {code.Trim().ToUpperInvariant()}…", error: false);
        }

        RefreshSessionState();
    }

    private void RefreshSessionState()
    {
        bool directRunning = Context.Host.DirectCoopRunning;
        bool loopbackRunning = Context.Host.CoopLoopbackRunning;
        _shownDirectRunning = directRunning;
        _shownLoopbackRunning = loopbackRunning;

        CoopStatus roomStatus = RoomStatus;
        _shownRoomStatus = roomStatus;
        bool roomRunning = roomStatus.Phase != CoopPhase.None;
        bool roomsAvailable = Context.Host.Coop is not null;

        if (_statusLabel is not null)
        {
            string status = StatusText();
            if (_statusLabel.Text != status)
            {
                _statusLabel.Text = status;

                // The host's status line wraps to two lines; a shorter one is one.
                RequestLayout();
            }
        }

        if (_toggleBtn is not null)
        {
            _toggleBtn.Text = ToggleText();
        }

        // The room's code, large, while hosting; the players with the host, while any.
        if (_roomCodeLabel is not null)
        {
            string code = IsRoomHost ? roomStatus.Code ?? string.Empty : string.Empty;
            if (_roomCodeLabel.Text != code)
            {
                _roomCodeLabel.Text = code;
                RequestLayout();
            }
        }

        if (_roomPlayersLabel is not null)
        {
            string players = roomStatus is { Phase: CoopPhase.Playing, Hosting: true }
                && Context.Host.Coop?.Players is { Count: > 0 } names
                ? $"Playing with: {string.Join(", ", names)}."
                : string.Empty;
            if (_roomPlayersLabel.Text != players)
            {
                _roomPlayersLabel.Text = players;
                RequestLayout();
            }
        }

        // While a Wi-Fi session runs, Host and Join would be no-ops; while joined, Play
        // is the host's to press — the joiner waits. Loopback stays available: starting
        // it stops the Wi-Fi session, which is the player's choice, not a drop.
        ApplyEnabled(_hostBtn, !directRunning);
        ApplyEnabled(_leaveBtn, directRunning);
        ApplyEnabled(_joinBtn, !directRunning);
        ApplyEnabled(_playBtn, (!directRunning || !IsDirectJoined) && (!roomRunning || IsRoomHost));
        if (_addressBox is not null)
        {
            _addressBox.IsEnabled = !directRunning;
        }

        // While a room runs, Host and Join would re-host or re-join over it; Leave is the
        // way out. Loopback and Wi-Fi stay available: starting either stops the room,
        // which is the player's choice, not a drop. With no WebRTC library the room
        // controls stay greyed out, and the note above says why.
        ApplyEnabled(_hostPublicBtn, roomsAvailable && !roomRunning);
        ApplyEnabled(_hostPrivateBtn, roomsAvailable && !roomRunning);
        ApplyEnabled(_leaveRoomBtn, roomsAvailable && roomRunning);
        ApplyEnabled(_joinCodeBtn, roomsAvailable && !roomRunning);
        ApplyEnabled(_refreshRoomsBtn, roomsAvailable);
        if (_codeBox is not null)
        {
            _codeBox.IsEnabled = roomsAvailable && !roomRunning;
        }
    }

    private static void ApplyEnabled(IgiMenuButton? button, bool enabled)
    {
        if (button is null)
        {
            return;
        }

        button.IsEnabled = enabled;
        button.NormalColor = enabled ? Bgra32.FromRgb(75, 245, 115) : Bgra32.FromRgb(110, 120, 110);
        button.HoverColor = enabled ? Bgra32.FromRgb(240, 255, 240) : Bgra32.FromRgb(110, 120, 110);
    }

    private void SetNotice(string text, bool error)
    {
        if (_noticeText == text && _noticeError == error)
        {
            return;
        }

        _noticeText = text;
        _noticeError = error;
        if (_noticeLabel is not null)
        {
            _noticeLabel.Text = text;
            _noticeLabel.Color = error ? Context.Theme.Danger : Context.Theme.TextMuted;

            // A note growing to two lines pushes every row below it down.
            RequestLayout();
        }
    }

    private void RebuildLanList()
    {
        if (_lanStack is null || _lanEmptyLabel is null)
        {
            return;
        }

        var servers = Context.Host.LanServers;
        string signature = string.Join("\n", servers.Select(s => s.Address + "|" + s.Name + "|" + s.Map + "|" + s.Players + "|" + s.MaxPlayers));
        if (signature == _lanSignature)
        {
            // The empty line still ages: "Looking…" becomes "No games found…" after a
            // few seconds with no answers.
            if (servers.Count == 0)
            {
                string empty = _lanSinceRefresh < 3f
                    ? "Looking for games on this Wi-Fi…"
                    : "No games found on this Wi-Fi yet — tap Refresh to look again, or join by address below.";
                if (_lanEmptyLabel.Text != empty)
                {
                    _lanEmptyLabel.Text = empty;
                    RequestLayout();
                }
            }

            return;
        }

        _lanSignature = signature;
        _lanStack.ClearChildren();

        if (servers.Count == 0)
        {
            _lanEmptyLabel.Visibility = Visibility.Visible;
            _lanEmptyLabel.Text = _lanSinceRefresh < 3f
                ? "Looking for games on this Wi-Fi…"
                : "No games found on this Wi-Fi yet — tap Refresh to look again, or join by address below.";
            RequestLayout();
            return;
        }

        _lanEmptyLabel.Visibility = Visibility.Collapsed;

        foreach (var server in servers)
        {
            string address = server.Address;
            var row = new IgiMenuButton(Context.Theme, $"{server.Name} — {server.Map} — {server.Players}/{server.MaxPlayers} players")
            {
                TextSize = 22f,
                Height = 48f,
                Width = 780f,
                Tooltip = address,
                IsEnabled = server.Players < server.MaxPlayers,
            };
            if (!row.IsEnabled)
            {
                row.NormalColor = Bgra32.FromRgb(110, 120, 110);
                row.HoverColor = Bgra32.FromRgb(110, 120, 110);
            }

            row.Activated += () => JoinAttempt(address);
            _lanStack.AddChild(row);
        }

        RequestLayout();
    }

    private void RebuildRoomsList()
    {
        if (_roomsStack is null || _roomsEmptyLabel is null)
        {
            return;
        }

        ICoopRooms? coop = Context.Host.Coop;
        IReadOnlyList<CoopRoomInfo>? rooms = coop?.Listing;
        string signature = rooms is null
            ? "loading|" + (coop?.ListingError ?? string.Empty)
            : string.Join("\n", rooms.Select(r => r.Code + "|" + r.Name + "|" + r.MissionId + "|" + r.Players + "|" + r.MaxPlayers + "|" + r.Passworded))
                + "|" + (coop?.ListingError ?? string.Empty);
        if (signature == _roomsSignature)
        {
            // The empty line still ages: "Looking…" becomes "No public rooms…" after a
            // few seconds with no answer.
            if (rooms is { Count: 0 } && coop?.ListingError is null)
            {
                string empty = _roomsSinceRefresh < 3f
                    ? "Looking for public rooms…"
                    : "No public rooms right now — host one above, or join by code.";
                if (_roomsEmptyLabel.Text != empty)
                {
                    _roomsEmptyLabel.Text = empty;
                    RequestLayout();
                }
            }

            return;
        }

        _roomsSignature = signature;
        _roomsStack.ClearChildren();

        if (rooms is null)
        {
            _roomsEmptyLabel.Visibility = Visibility.Visible;
            _roomsEmptyLabel.Text = coop is null
                ? "Rooms need this build's WebRTC library — see the note above."
                : "Looking for public rooms…";
            RequestLayout();
            return;
        }

        if (rooms.Count == 0)
        {
            _roomsEmptyLabel.Visibility = Visibility.Visible;
            _roomsEmptyLabel.Text = coop?.ListingError is { } error
                ? $"Couldn't list rooms: {error}."
                : _roomsSinceRefresh < 3f
                    ? "Looking for public rooms…"
                    : "No public rooms right now — host one above, or join by code.";
            RequestLayout();
            return;
        }

        _roomsEmptyLabel.Visibility = Visibility.Collapsed;

        foreach (CoopRoomInfo room in rooms)
        {
            string code = room.Code;
            string mission = string.Create(CultureInfo.InvariantCulture, $"Mission {room.MissionId}");
            var row = new IgiMenuButton(Context.Theme, $"{room.Name} — {mission} — {room.Players}/{room.MaxPlayers} players{(room.Passworded ? " — passworded" : string.Empty)}")
            {
                TextSize = 22f,
                Height = 48f,
                Width = 780f,
                Tooltip = code,
                IsEnabled = room.Players < room.MaxPlayers,
            };
            if (!row.IsEnabled)
            {
                row.NormalColor = Bgra32.FromRgb(110, 120, 110);
                row.HoverColor = Bgra32.FromRgb(110, 120, 110);
            }

            // A passworded room takes a password the screen never asks for, so tapping
            // it fails at the join with "wrong password" — the suffix above says so.
            row.Activated += () => JoinRoomByCode(code);
            _roomsStack.AddChild(row);
        }

        RequestLayout();
    }

    private string StatusText()
    {
        CoopStatus room = RoomStatus;
        if (room.Phase != CoopPhase.None)
        {
            return room switch
            {
                { Phase: CoopPhase.Playing, Hosting: true } => $"Room {room.Code} — friends join with this code.",
                { Phase: CoopPhase.Playing } => $"In room {room.Code}.",
                { Phase: CoopPhase.Connecting, Hosting: true } => "Opening a room…",
                { Phase: CoopPhase.Connecting } => $"Finding room {room.Code}…",
                { Phase: CoopPhase.Failed } => $"Couldn't play together: {room.Error}.",
                _ => "Co-op is not running.",
            };
        }

        if (Context.Host.DirectCoopRunning && Context.Host.DirectCoopStatus is { } direct)
        {
            return direct;
        }

        return Context.Host.CoopLoopbackRunning
            ? "Loopback co-op is running."
            : "Co-op is not running.";
    }

    private string ToggleText() => Context.Host.CoopLoopbackRunning
        ? "Stop co-op"
        : "Start co-op";

    /// <summary>Whether the running Wi-Fi session is one this phone joined.</summary>
    /// <remarks>
    /// The rooms layer's own status words (<c>API.md</c>): a host reads "Hosting on port …",
    /// a joiner "Joined …". There is no host flag on the menu seam, so the screen reads the
    /// words — if they ever change, Play falls back to the host's behaviour (start the
    /// mission, never start loopback over a live Wi-Fi session).
    /// </remarks>
    private bool IsDirectJoined => Context.Host.DirectCoopStatus is { } status
        && status.StartsWith("Joined", StringComparison.Ordinal);

    /// <summary>Gets where the player's room is, or none when there is no rooms layer.</summary>
    private CoopStatus RoomStatus => Context.Host.Coop?.Status ?? new CoopStatus(CoopPhase.None);

    /// <summary>Whether a room is open, opening, or being found.</summary>
    private bool IsRoomRunning => RoomStatus.Phase != CoopPhase.None;

    /// <summary>Whether this phone hosts the room it is in.</summary>
    private bool IsRoomHost => RoomStatus is { Phase: CoopPhase.Playing, Hosting: true };

    private static Label SectionHeader(UiTheme theme, string text)
    {
        return new Label(theme.Heading, text, 24f, Bgra32.FromRgb(225, 175, 60))
        {
            HorizontalAlignment = HorizontalAlignment.Center,
            Margin = new Thickness(0f, 10f, 0f, 0f),
        };
    }
}
