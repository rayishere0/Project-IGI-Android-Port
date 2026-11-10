using ProjectIGI.Core.Graphics;
using ProjectIGI.Input;
using ProjectIGI.UI;
using ProjectIGI.UI.Focus;
using ProjectIGI.UI.Layout;
using ProjectIGI.UI.Widgets;

namespace ProjectIGI.Frontend.Screens;

/// <summary>
/// The co-op section: the loopback session Milestone 1 can run, reached from the main menu's
/// Co-op button instead of the console.
/// </summary>
/// <remarks>
/// The closest faithful equivalent of upstream's shell Co-op tab for what exists today: upstream
/// opens its CoopScreen from a header tab and offers host / join-by-code / public rooms, every one
/// of them through the master server and WebRTC. This port has neither yet, so the page offers only
/// what Milestone 1 built - start and stop the loopback session and play mission 1 through it - and
/// shows the room options as disabled rows that say they need Milestone 2, rather than wiring them
/// to dead ends. The console command stays as the dev fallback.
/// <para>
/// The screen never touches the settings return path: it is only reachable from the shell's own
/// main menu (and Back returns there), so closing it cannot put the shell away over a retail menu
/// that is not running, the way the settings icon's unconditional flag can.
/// </para>
/// </remarks>
public sealed class CoopScreen : ShellScreen
{
    private Label? _statusLabel;
    private IgiMenuButton? _toggleBtn;

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

        var menuStack = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 14f,
            Width = 820f,
            Margin = new Thickness(0f, 54f, 0f, 16f),
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };

        // Session status, reusing the console's wording.
        _statusLabel = new Label(theme.Heading, StatusText(), 28f, Bgra32.FromRgb(165, 255, 185))
        {
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        menuStack.AddChild(_statusLabel);

        _toggleBtn = new IgiMenuButton(theme, ToggleText()) { TextSize = 34f, Height = 64f, Width = 760f };
        _toggleBtn.Activated += () =>
        {
            if (Context.Host.CoopLoopbackRunning)
            {
                Context.Host.StopLoopbackCoop();
            }
            else
            {
                Context.Host.StartLoopbackCoop();
            }

            RefreshStatus();
        };
        menuStack.AddChild(_toggleBtn);

        var playBtn = new IgiMenuButton(theme, "Play co-op - Mission 1") { TextSize = 34f, Height = 64f, Width = 760f };
        playBtn.Activated += () =>
        {
            // Leaving for a mission ends the retail-menu visit: if this screen was opened
            // from the retail menu, the flag must not survive into a co-op screen opened
            // later off the shell's own main menu, whose Back belongs there, not on the
            // retail menu.
            Context.CoopFromRetailMenu = false;

            if (!Context.Host.CoopLoopbackRunning)
            {
                Context.Host.StartLoopbackCoop();
            }

            // The existing mission path, difficulty 1 like the campaign screen's OK: the
            // loopback client follows the host into the mission on the next tick.
            Context.Host.StartMission(1, 1);
        };
        menuStack.AddChild(playBtn);

        var loopbackNote = new Label(
            theme.Body,
            "One device: host + client in this process. The second player follows your input once the level is up. Starting co-op turns cheats off while the session runs.",
            20f,
            theme.TextMuted)
        {
            Wrap = true,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        menuStack.AddChild(loopbackNote);

        var roomsHeader = new Label(theme.Heading, "Rooms - Milestone 2", 24f, Bgra32.FromRgb(225, 175, 60))
        {
            HorizontalAlignment = HorizontalAlignment.Center,
            Margin = new Thickness(0f, 12f, 0f, 0f),
        };
        menuStack.AddChild(roomsHeader);

        // Room options, shown but unavailable: Milestone 2 has no master server and no WebRTC
        // yet, so these are disabled rows, not buttons that lead nowhere. Muted grey, and
        // IsEnabled false so Control.Activate cannot fire them.
        menuStack.AddChild(DisabledRoomRow(theme, "Host a room"));
        menuStack.AddChild(DisabledRoomRow(theme, "Join by code"));
        menuStack.AddChild(DisabledRoomRow(theme, "Public rooms"));

        var roomsNote = new Label(
            theme.Body,
            "Rooms need Milestone 2: a master server and WebRTC. Not available yet.",
            20f,
            theme.TextMuted)
        {
            Wrap = true,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        menuStack.AddChild(roomsNote);

        var backBtn = new IgiMenuButton(theme, "Back") { TextSize = 34f, Height = 64f, Width = 760f };
        backBtn.Activated += CloseCoop;
        menuStack.AddChild(backBtn);

        frame.AddChild(menuStack);
        root.Add(frame, new Anchor(UiVec2.Zero, UiVec2.One, Thickness.Zero));

        return root;
    }

    /// <inheritdoc/>
    protected override bool HandleInput(UiNavigation nav, InputState input)
    {
        if (nav.Back)
        {
            CloseCoop();
            return false;
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

    private void RefreshStatus()
    {
        if (_statusLabel is not null)
        {
            _statusLabel.Text = StatusText();
        }

        if (_toggleBtn is not null)
        {
            _toggleBtn.Text = ToggleText();
        }
    }

    private string StatusText() => Context.Host.CoopLoopbackRunning
        ? "Loopback co-op is running."
        : "Loopback co-op is not running.";

    private string ToggleText() => Context.Host.CoopLoopbackRunning
        ? "Stop co-op"
        : "Start co-op";

    private static IgiMenuButton DisabledRoomRow(UiTheme theme, string text)
    {
        return new IgiMenuButton(theme, text)
        {
            TextSize = 28f,
            Height = 52f,
            Width = 760f,
            IsEnabled = false,
            NormalColor = Bgra32.FromRgb(110, 120, 110),
            HoverColor = Bgra32.FromRgb(110, 120, 110),
        };
    }
}
