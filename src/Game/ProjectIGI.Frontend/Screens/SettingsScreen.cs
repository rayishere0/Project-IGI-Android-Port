using System.Globalization;
using ProjectIGI.Core.Graphics;
using ProjectIGI.Input;
using ProjectIGI.Rendering;
using ProjectIGI.UI;
using ProjectIGI.UI.Focus;
using ProjectIGI.UI.Kit.Widgets;
using ProjectIGI.UI.Layout;
using ProjectIGI.UI.Widgets;

namespace ProjectIGI.Frontend.Screens;

/// <summary>
/// Authentic Project I.G.I. 1 "Configuration" screen:
/// Stripped of all unnecessary modifications, providing ONLY the requested options:
/// 1. Touch controls customization (drag-and-drop position, pinch-and-zoom resize, size +/-)
/// 2. Controls alpha slider
/// 3. Max frame rate (FPS cap: 30, 60, 90, 120, Uncapped)
/// 4. Invert mouse/look pitch toggle
/// </summary>
public sealed class SettingsScreen : ShellScreen
{
    private static readonly int[] FpsCapValues = [30, 60, 90, 120, 0];
    private static readonly string[] FpsCapLabels = ["30 FPS", "60 FPS", "90 FPS", "120 FPS", "UNCAPPED"];
    private static readonly string[] RenderScaleLabels = ["540P (ULTRA)", "720P (PERFORMANCE)", "900P (BALANCED)", "NATIVE (MAX)"];

    private readonly float _initialOpacity;
    private readonly float _initialSensitivity;
    private readonly int _initialFpsCap;
    private readonly bool _initialInvert;
    private readonly bool _initialGyro;
    private readonly float _initialGyroSensitivity;
    private readonly float _initialUiScale;
    private readonly float _initialTextScale;
    private readonly int _initialRenderScale;
    private readonly bool _initialShowFps;

    /// <summary>Initializes a new instance of the <see cref="SettingsScreen"/> class.</summary>
    /// <param name="context">The shared shell context.</param>
    public SettingsScreen(ShellContext context)
        : base(context)
    {
        _initialOpacity = context.Host.TouchOpacity;
        _initialSensitivity = context.Host.TouchSensitivity;
        _initialFpsCap = ReconstructionCVars.FrameLimit.Value;
        _initialInvert = context.Config.Active?.InvertMouse ?? false;
        _initialGyro = context.Config.Active?.GyroEnabled ?? false;
        _initialGyroSensitivity = context.Config.Active?.GyroSensitivity ?? 0.5f;
        _initialUiScale = LayoutContext.GlobalUiScale;
        _initialTextScale = LayoutContext.GlobalTextScale;
        _initialRenderScale = context.Host.RenderScaleMode;
        _initialShowFps = DisplayCVars.ShowFps.Value;
    }

    /// <inheritdoc/>
    protected override bool HasChrome => false;

    /// <inheritdoc/>
    protected override ShellTab Tab => ShellTab.Settings;

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

        // 2. Central Green Tactical Frame ("Configuration")
        var frame = new IgiTacticalFrame(theme, "Configuration")
        {
            Width = 1100f,
            Height = 940f,
            Margin = new Thickness(0f, 15f, 0f, 0f),
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };

        var configStack = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 14f,
            Width = 980f,
            Margin = new Thickness(60f, 42f, 60f, 42f),
        };

        // ── Option 1: On-Screen Touch Controls Customizer ─────────────────
        var customizeRow = new FlexPanel
        {
            Orientation = Orientation.Horizontal,
            Gap = 16f,
            Width = 980f,
        };

        var customizeBtn = new Button(theme, "CUSTOMIZE ON-SCREEN CONTROLS")
        {
            Accent = ButtonAccent.Ghost,
            Width = 980f,
            Height = 66f,
            TextSize = 24f,
        };
        customizeBtn.Activated += _ => Context.Host.CustomizeTouchControls();
        customizeRow.Add(customizeBtn);
        configStack.AddChild(customizeRow);

        // ── Option 2: Controls Alpha Slider (20% to 100%) ─────────────────
        int initialPct = (int)Math.Round(Context.Host.TouchOpacity * 100f);
        var alphaSlider = new Slider(theme, "Controls Alpha", 20f, 100f, initialPct, 5f)
        {
            Width = 980f,
            Height = 56f,
        };
        alphaSlider.ValueChanged += value =>
        {
            float norm = Math.Clamp(value / 100f, 0.20f, 1.0f);
            Context.Host.TouchOpacity = norm;
        };
        configStack.AddChild(alphaSlider);

        // ── Option 3: Touch Sensitivity Slider (20% to 300%) ──────────────
        int initialSensPct = (int)Math.Round(Context.Host.TouchSensitivity * 100f);
        var sensSlider = new Slider(theme, "Touch Sensitivity", 20f, 300f, initialSensPct, 5f)
        {
            Width = 980f,
            Height = 56f,
        };
        sensSlider.ValueChanged += value =>
        {
            float norm = Math.Clamp(value / 100f, 0.20f, 3.0f);
            Context.Host.TouchSensitivity = norm;
        };
        configStack.AddChild(sensSlider);

        // ── Option 4: UI Size Slider (80% to 150%) ─────────────────────────
        int initialUiPct = (int)Math.Round(LayoutContext.GlobalUiScale * 100f);
        var uiSizeSlider = new Slider(theme, "UI Size", 80f, 150f, initialUiPct, 5f)
        {
            Width = 980f,
            Height = 56f,
        };
        uiSizeSlider.ValueChanged += value =>
        {
            LayoutContext.GlobalUiScale = Math.Clamp(value / 100f, 0.8f, 1.5f);
        };
        configStack.AddChild(uiSizeSlider);

        // ── Option 4: Text Size Slider (80% to 150%) ───────────────────────
        int initialTextPct = (int)Math.Round(LayoutContext.GlobalTextScale * 100f);
        var textSizeSlider = new Slider(theme, "Text Size", 80f, 150f, initialTextPct, 5f)
        {
            Width = 980f,
            Height = 56f,
        };
        textSizeSlider.ValueChanged += value =>
        {
            LayoutContext.GlobalTextScale = Math.Clamp(value / 100f, 0.8f, 1.5f);
        };
        configStack.AddChild(textSizeSlider);

        // ── Option 5: Max Frame Rate (FPS Cap) ───────────────────────────
        int currentFps = ReconstructionCVars.FrameLimit.Value;
        int selectedFpsIndex = Array.IndexOf(FpsCapValues, currentFps);
        if (selectedFpsIndex < 0)
        {
            selectedFpsIndex = 4; // Uncapped default
        }

        var fpsCycler = new OptionCycler(theme, "Max Frame Rate", FpsCapLabels, selectedFpsIndex)
        {
            Width = 980f,
            Height = 56f,
            ContentWidth = 320f,
        };
        fpsCycler.SelectionChanged += index =>
        {
            int cap = FpsCapValues[index];
            ReconstructionCVars.FrameLimit.Value = cap;
        };
        configStack.AddChild(fpsCycler);

        // ── Option 6: Render Resolution Quality (720p / 900p / Native) ───
        int currentRes = Context.Host.RenderScaleMode;
        var resCycler = new OptionCycler(theme, "Resolution Quality", RenderScaleLabels, Math.Clamp(currentRes, 0, 3))
        {
            Width = 980f,
            Height = 56f,
            ContentWidth = 320f,
        };
        resCycler.SelectionChanged += index =>
        {
            Context.Host.RenderScaleMode = index;
        };
        configStack.AddChild(resCycler);

        // ── Option 7: Invert Mouse / Look Pitch ───────────────────────────
        bool invertState = Context.Config.Active?.InvertMouse ?? false;
        var invertToggle = new Toggle(theme, "Invert Look / Mouse", invertState)
        {
            Width = 980f,
            Height = 56f,
        };
        invertToggle.ValueChanged += val =>
        {
            if (Context.Config.Active is { } profile)
            {
                profile.InvertMouse = val;
            }
        };
        configStack.AddChild(invertToggle);

        // ── Gyroscope aim (Android only; tilt the phone to aim) ─────────────
        // This is the live Configuration screen. (An earlier version put this toggle
        // in ControlsSettingsTab, which nothing ever shows, so it never appeared.)
        bool gyroState = Context.Config.Active?.GyroEnabled ?? false;
        var gyroToggle = new Toggle(theme, "Gyroscope aim", gyroState)
        {
            Width = 980f,
            Height = 56f,
            Tooltip = "Tilt the phone to aim. Only on Android, and only while playing.",
        };
        gyroToggle.ValueChanged += val =>
        {
            if (Context.Config.Active is { } profile)
            {
                profile.GyroEnabled = val;
            }
        };
        configStack.AddChild(gyroToggle);

        // ── Gyroscope sensitivity ────────────────────────────────────────────
        float gyroSensState = Context.Config.Active?.GyroSensitivity ?? 0.5f;
        var gyroSensSlider = new Slider(theme, "Gyroscope sensitivity", 0f, 1f, gyroSensState, 0.05f)
        {
            Width = 980f,
            Height = 56f,
            Format = v => string.Create(
                CultureInfo.InvariantCulture,
                $"{MouseLookSettings.FromSensitivity(v, invertPitch: false).TurnDistanceCentimetres():0} cm/360°"),
            Tooltip = "How fast the view turns when you tilt the phone.\n\nSame scale as mouse sensitivity — the readout is how far a full turn takes.",
        };
        gyroSensSlider.ValueChanged += value =>
        {
            if (Context.Config.Active is { } profile)
            {
                profile.GyroSensitivity = value;
            }
        };
        configStack.AddChild(gyroSensSlider);

        // ── Option 8: Show FPS Counter Overlay ───────────────────────────
        bool showFpsState = DisplayCVars.ShowFps.Value;
        var fpsToggle = new Toggle(theme, "Show FPS Counter", showFpsState)
        {
            Width = 980f,
            Height = 56f,
        };
        fpsToggle.ValueChanged += val =>
        {
            DisplayCVars.ShowFps.Value = val;
        };
        configStack.AddChild(fpsToggle);

        frame.AddChild(configStack);

        // ── Bottom Buttons: OK & Cancel ──────────────────────────────────
        var btnBar = new FlexPanel
        {
            Orientation = Orientation.Horizontal,
            Gap = 28f,
            HorizontalAlignment = HorizontalAlignment.Right,
            VerticalAlignment = VerticalAlignment.Bottom,
            Margin = new Thickness(0f, 0f, 32f, 16f),
        };

        var okBtn = new IgiMenuButton(theme, "OK")
        {
            TextSize = 30f,
            Height = 60f,
            Width = 180f,
            NormalColor = Bgra32.FromRgb(60, 230, 95),
            HoverColor = Bgra32.FromRgb(220, 255, 220),
        };
        okBtn.Activated += () =>
        {
            Context.Host.SaveSettings();
            CloseConfig();
        };
        btnBar.Add(okBtn);

        var cancelBtn = new IgiMenuButton(theme, "Cancel")
        {
            TextSize = 30f,
            Height = 60f,
            Width = 180f,
            NormalColor = Bgra32.FromRgb(60, 230, 95),
            HoverColor = Bgra32.FromRgb(220, 255, 220),
        };
        cancelBtn.Activated += () =>
        {
            // Restore initial settings
            Context.Host.TouchOpacity = _initialOpacity;
            Context.Host.TouchSensitivity = _initialSensitivity;
            Context.Host.RenderScaleMode = _initialRenderScale;
            ReconstructionCVars.FrameLimit.Value = _initialFpsCap;
            LayoutContext.GlobalUiScale = _initialUiScale;
            LayoutContext.GlobalTextScale = _initialTextScale;
            DisplayCVars.ShowFps.Value = _initialShowFps;
            if (Context.Config.Active is { } profile)
            {
                profile.InvertMouse = _initialInvert;
                profile.GyroEnabled = _initialGyro;
                profile.GyroSensitivity = _initialGyroSensitivity;
            }
            CloseConfig();
        };
        btnBar.Add(cancelBtn);

        frame.AddChild(btnBar);
        root.Add(frame, new Anchor(UiVec2.Zero, UiVec2.One, Thickness.Zero));

        return root;
    }

    private void CloseConfig()
    {
        if (Context.InGame)
        {
            Context.Stack.Reset(new PauseScreen(Context));
        }
        else
        {
            Context.Stack.Reset(new MainMenuScreen(Context));
        }
    }

    /// <inheritdoc/>
    protected override bool HandleInput(UiNavigation nav, InputState input)
    {
        if (nav.Back)
        {
            CloseConfig();
            return false;
        }

        return base.HandleInput(nav, input);
    }
}
