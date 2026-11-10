using ProjectIGI.Core.Graphics;
using ProjectIGI.UI;
using ProjectIGI.UI.Layout;
using ProjectIGI.UI.Widgets;

namespace ProjectIGI.Frontend.Screens;

/// <summary>
/// Authentic Project I.G.I. 1 Main Menu:
/// Displays the classic Project I.G.I. logo, dark tactical background, and a green wireframe panel
/// with "Play Project IGI", "Configuration", and "Quit" options.
/// </summary>
public sealed class MainMenuScreen : ShellScreen
{
    private Label? _intelDialog;

    /// <summary>Initializes a new instance of the <see cref="MainMenuScreen"/> class.</summary>
    /// <param name="context">The shared shell context.</param>
    public MainMenuScreen(ShellContext context)
        : base(context)
    {
    }

    /// <inheritdoc/>
    protected override bool HasChrome => false;

    /// <inheritdoc/>
    protected override ShellTab Tab => ShellTab.Home;

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
            Margin = new Thickness(0f, 24f, 0f, 0f),
            VerticalAlignment = VerticalAlignment.Top,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        root.Add(logo, new Anchor(UiVec2.Zero, new UiVec2(1f, 0.22f), Thickness.Zero));

        // 2. Central Green Wireframe Tactical Box ("Main Menu")
        var frame = new IgiTacticalFrame(theme, "Main Menu")
        {
            Width = 920f,
            Height = 720f,
            Margin = new Thickness(0f, 40f, 0f, 0f),
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };

        var menuStack = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 20f,
            Width = 820f,
            Margin = new Thickness(0f, 54f, 0f, 16f),
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };

        var playBtn = new IgiMenuButton(theme, "Play Project IGI") { TextSize = 40f, Height = 78f, Width = 760f };
        playBtn.Activated += () => Context.Stack.Reset(new CampaignScreen(Context));
        menuStack.AddChild(playBtn);

        var configBtn = new IgiMenuButton(theme, "Configuration") { TextSize = 40f, Height = 78f, Width = 760f };
        configBtn.Activated += () => Context.Stack.Reset(new SettingsScreen(Context));
        menuStack.AddChild(configBtn);

        // Upstream's shell labels its co-op tab "Co-op", second after the campaign; the port's
        // landing page has no header tabs, so the same label sits here, between Configuration and
        // Quit. It opens the Co-op screen: loopback start/stop today, rooms in Milestone 2.
        var coopBtn = new IgiMenuButton(theme, "Co-op") { TextSize = 40f, Height = 78f, Width = 760f };
        coopBtn.Activated += () => Context.Stack.Reset(new CoopScreen(Context));
        menuStack.AddChild(coopBtn);

        var quitBtn = new IgiMenuButton(theme, "Quit") { TextSize = 40f, Height = 78f, Width = 760f };
        quitBtn.Activated += () => Context.Host.Quit();
        menuStack.AddChild(quitBtn);

        // Bottom links: "Read Me" and "Credits" in amber/yellow
        var subStack = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 10f,
            Width = 440f,
            Margin = new Thickness(0f, 26f, 0f, 12f),
            HorizontalAlignment = HorizontalAlignment.Center,
        };

        var readmeBtn = new IgiMenuButton(theme, "Read Me")
        {
            TextSize = 28f,
            Height = 54f,
            Width = 420f,
            NormalColor = Bgra32.FromRgb(225, 175, 60),
            HoverColor = Bgra32.FromRgb(255, 230, 140),
        };
        readmeBtn.Activated += () =>
        {
            if (_intelDialog is not null)
            {
                _intelDialog.Text = "All the contents used in this game are intended for educational and experimental purposes only.";
                _intelDialog.Visibility = Visibility.Visible;
            }
        };
        subStack.AddChild(readmeBtn);

        var creditsBtn = new IgiMenuButton(theme, "Credits")
        {
            TextSize = 24f,
            Height = 46f,
            Width = 360f,
            NormalColor = Bgra32.FromRgb(225, 175, 60),
            HoverColor = Bgra32.FromRgb(255, 230, 140),
        };
        creditsBtn.Activated += () =>
        {
            if (_intelDialog is not null)
            {
                _intelDialog.Text = "Background and Controls - ProjectIGI Github project\nMade with Love, By R";
                _intelDialog.Visibility = Visibility.Visible;
            }
        };
        subStack.AddChild(creditsBtn);

        menuStack.AddChild(subStack);
        frame.AddChild(menuStack);
        root.Add(frame, new Anchor(UiVec2.Zero, UiVec2.One, Thickness.Zero));

        // Floating info label
        _intelDialog = new Label(theme.Heading, "", 24f, Bgra32.FromRgb(165, 255, 185))
        {
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Bottom,
            Margin = new Thickness(0f, 0f, 0f, 24f),
            Visibility = Visibility.Collapsed,
        };
        root.Add(_intelDialog, new Anchor(new UiVec2(0f, 0.85f), UiVec2.One, Thickness.Zero));

        return root;
    }

    /// <inheritdoc/>
    protected override void OnEnter()
    {
        // No heavy 3D showcase streaming to guarantee instant, responsive boot
    }
}
