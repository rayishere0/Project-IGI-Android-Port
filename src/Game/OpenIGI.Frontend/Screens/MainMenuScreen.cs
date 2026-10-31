using OpenIGI.Core.Graphics;
using OpenIGI.UI;
using OpenIGI.UI.Layout;
using OpenIGI.UI.Widgets;

namespace OpenIGI.Frontend.Screens;

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
            Width = 840f,
            Height = 660f,
            Margin = new Thickness(0f, 40f, 0f, 0f),
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };

        var menuStack = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 16f,
            Width = 740f,
            Margin = new Thickness(0f, 54f, 0f, 16f),
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };

        var playBtn = new IgiMenuButton(theme, "Play Project IGI") { TextSize = 34f, Height = 66f, Width = 680f };
        playBtn.Activated += () => Context.Stack.Reset(new CampaignScreen(Context));
        menuStack.AddChild(playBtn);

        var configBtn = new IgiMenuButton(theme, "Configuration") { TextSize = 34f, Height = 66f, Width = 680f };
        configBtn.Activated += () => Context.Stack.Reset(new SettingsScreen(Context));
        menuStack.AddChild(configBtn);

        var cheatsBtn = new IgiMenuButton(theme, "Cheats") { TextSize = 34f, Height = 66f, Width = 680f };
        cheatsBtn.Activated += () => Context.Stack.Reset(new CheatsScreen(Context));
        menuStack.AddChild(cheatsBtn);

        var quitBtn = new IgiMenuButton(theme, "Quit") { TextSize = 34f, Height = 66f, Width = 680f };
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
            TextSize = 24f,
            Height = 46f,
            Width = 360f,
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
                _intelDialog.Text = "Background and Controls - OpenIGI Github project\nMade with Love, By R";
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
