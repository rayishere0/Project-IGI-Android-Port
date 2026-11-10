using ProjectIGI.Core.Graphics;
using ProjectIGI.Input;
using ProjectIGI.UI;
using ProjectIGI.UI.Focus;
using ProjectIGI.UI.Layout;
using ProjectIGI.UI.Widgets;

namespace ProjectIGI.Frontend.Screens;

/// <summary>
/// Authentic Project I.G.I. 1 "Paused" menu:
/// Centered green wireframe tactical dialog over the suspended mission, offering:
/// Resume, Restart Mission, Customize Controls, Configuration, and Abort Mission.
/// </summary>
public sealed class PauseScreen : ShellScreen
{
    /// <summary>Initializes a new instance of the <see cref="PauseScreen"/> class.</summary>
    /// <param name="context">The shared shell context.</param>
    public PauseScreen(ShellContext context)
        : base(context)
    {
    }

    /// <inheritdoc/>
    protected override bool HasChrome => false;

    /// <inheritdoc/>
    protected override ShellTab Tab => ShellTab.Home;

    /// <inheritdoc/>
    public override float BackdropBlur => 4f;

    /// <inheritdoc/>
    protected override UiElement? BuildContent(LayoutContext context)
    {
        UiTheme theme = Context.Theme;

        var root = new Canvas();

        // Central Green Wireframe Tactical Box ("Paused")
        var frame = new IgiTacticalFrame(theme, "Paused")
        {
            Width = 880f,
            Height = 720f,
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };

        var menuStack = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 22f,
            Width = 780f,
            Margin = new Thickness(0f, 68f, 0f, 20f),
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };

        var resumeBtn = new IgiMenuButton(theme, "RESUME") { TextSize = 34f, Height = 76f, Width = 740f };
        resumeBtn.Activated += () => Context.Host.ResumeMission();
        menuStack.AddChild(resumeBtn);

        var restartBtn = new IgiMenuButton(theme, "RESTART MISSION") { TextSize = 34f, Height = 76f, Width = 740f };
        restartBtn.Activated += () => Context.Host.RestartMission();
        menuStack.AddChild(restartBtn);

        var customBtn = new IgiMenuButton(theme, "CUSTOMIZE CONTROLS") { TextSize = 34f, Height = 76f, Width = 740f };
        customBtn.Activated += () => Context.Host.CustomizeTouchControls();
        menuStack.AddChild(customBtn);

        var configBtn = new IgiMenuButton(theme, "CONFIGURATION") { TextSize = 34f, Height = 76f, Width = 740f };
        configBtn.Activated += () => Context.Stack.Reset(new SettingsScreen(Context));
        menuStack.AddChild(configBtn);

        // In-mission co-op: only when a loopback session runs, a status line and a stop button.
        // Stopping mid-mission is what the session supports (the M1 start/stop may run mid-mission);
        // the page rebuilds so the row is gone once the session stops. Nothing shows when no
        // session runs, so solo pause menus are unchanged.
        if (Context.Host.CoopLoopbackRunning)
        {
            var coopLabel = new Label(theme.Heading, "Co-op: loopback session running", 24f, Bgra32.FromRgb(165, 255, 185))
            {
                HorizontalAlignment = HorizontalAlignment.Center,
            };
            menuStack.AddChild(coopLabel);

            var stopCoopBtn = new IgiMenuButton(theme, "STOP CO-OP") { TextSize = 30f, Height = 64f, Width = 740f };
            stopCoopBtn.Activated += () =>
            {
                Context.Host.StopLoopbackCoop();
                Context.Stack.Reset(new PauseScreen(Context));
            };
            menuStack.AddChild(stopCoopBtn);
        }

        var abortBtn = new IgiMenuButton(theme, "ABORT MISSION")
        {
            TextSize = 34f,
            Height = 76f,
            Width = 740f,
            NormalColor = Bgra32.FromRgb(255, 95, 80),
            HoverColor = Bgra32.FromRgb(255, 180, 170),
        };
        abortBtn.Activated += () => Context.Host.AbandonMission();
        menuStack.AddChild(abortBtn);

        frame.AddChild(menuStack);
        root.Add(frame, new Anchor(UiVec2.Zero, UiVec2.One, Thickness.Zero));

        return root;
    }

    /// <inheritdoc/>
    protected override bool HandleInput(UiNavigation nav, InputState input)
    {
        if (nav.Back || input.Keyboard.WasPressed(KeyCode.Escape))
        {
            Context.Host.ResumeMission();
            return false;
        }

        return base.HandleInput(nav, input);
    }
}
