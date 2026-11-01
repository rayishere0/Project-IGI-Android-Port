using ProjectIGI.Core.Graphics;
using ProjectIGI.Input;
using ProjectIGI.UI;
using ProjectIGI.UI.Focus;
using ProjectIGI.UI.Layout;
using ProjectIGI.UI.Widgets;

namespace ProjectIGI.Frontend.Screens;

/// <summary>
/// Authentic Project I.G.I. 1 "Mission Failed" screen:
/// Tactical debriefing dialog presented upon player death or objective failure.
/// </summary>
public sealed class MissionFailedScreen : ShellScreen
{
    /// <summary>Initializes a new instance of the <see cref="MissionFailedScreen"/> class.</summary>
    /// <param name="context">The shared shell context.</param>
    public MissionFailedScreen(ShellContext context)
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

        // Central Tactical Frame with Danger accent: only "Mission Failed" at top bar
        var frame = new IgiTacticalFrame(theme, "Mission Failed")
        {
            Width = 840f,
            Height = 440f,
            BorderColor = Bgra32.FromRgb(255, 75, 65),
            BackgroundColor = Bgra32.FromRgba(18, 10, 10, 240),
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };

        var contentStack = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 24f,
            Width = 720f,
            Margin = new Thickness(0f, 64f, 0f, 24f),
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };

        // 1. Under top bar: "Abort the Mission"
        var abortBtn = new IgiMenuButton(theme, "Abort the Mission")
        {
            TextSize = 34f,
            Height = 72f,
            Width = 660f,
            NormalColor = Bgra32.FromRgb(255, 80, 70),
            HoverColor = Bgra32.FromRgb(255, 180, 170),
        };
        abortBtn.Activated += () => Context.Host.AbandonMission();
        contentStack.AddChild(abortBtn);

        // 2. Under that: "Restart Mission"
        var restartBtn = new IgiMenuButton(theme, "Restart Mission")
        {
            TextSize = 34f,
            Height = 72f,
            Width = 660f,
            NormalColor = Bgra32.FromRgb(78, 255, 120),
            HoverColor = Bgra32.FromRgb(220, 255, 220),
        };
        restartBtn.Activated += () => Context.Host.RestartMission();
        contentStack.AddChild(restartBtn);

        frame.AddChild(contentStack);
        root.Add(frame, new Anchor(UiVec2.Zero, UiVec2.One, Thickness.Zero));

        return root;
    }

    /// <inheritdoc/>
    protected override bool HandleInput(UiNavigation nav, InputState input)
    {
        if (nav.Back || input.Keyboard.WasPressed(KeyCode.Escape))
        {
            Context.Host.AbandonMission();
            return false;
        }

        return base.HandleInput(nav, input);
    }
}
