using System.Globalization;
using ProjectIGI.Core.Graphics;
using ProjectIGI.Game;
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
    private static readonly int[] DynamicTargetValues = [30, 45, 60];
    private static readonly string[] DynamicTargetLabels = ["30 FPS", "45 FPS", "60 FPS"];
    private static readonly float[] ViewDistanceValues = [1f, 0.1f, 0.025f];
    private static readonly string[] ViewDistanceLabels = ["FAR", "MEDIUM", "NEAR"];
    private static readonly string[] ShadowLabels = ["OFF", "LOW", "HIGH"];

    private readonly float _initialOpacity;
    private readonly float _initialSensitivity;
    private readonly int _initialFpsCap;
    private readonly bool _initialInvert;
    private readonly bool _initialGyro;
    private readonly float _initialGyroSensitivity;
    private readonly float _initialUiScale;
    private readonly float _initialTextScale;
    private readonly int _initialRenderScale;
    private readonly bool _initialDynamicResolution;
    private readonly int _initialDynamicTargetFps;
    private readonly float _initialViewDistance;
    private readonly bool _initialShowFps;
    private readonly bool _initialRagdoll;
    private readonly float _initialGamma;
    private readonly float _initialMotionBlur;
    private readonly float _initialFieldOfView;
    private readonly int _initialShadows;
    private readonly int _initialShadowCascades;
    private readonly float _initialShadowDistance;
    private readonly float _initialContactShadows;
    private readonly float _initialShadowSoftness;
    private readonly float _initialShadowAccumulate;

    private ScrollView? _scroll;
    private UiVec2? _touchDragStart;
    private float _touchDragStartOffset;
    private bool _isDragging;
    private Control? _pendingTapTarget;

    // The Content section's rows, rebuilt whenever a pack is switched, moved or rescanned, and the line
    // the last change reports on.
    private StackPanel? _contentSection;
    private Label? _contentStatus;

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
        _initialDynamicResolution = ReconstructionCVars.DynamicResolution.Value;
        _initialDynamicTargetFps = ReconstructionCVars.DynamicTargetFps.Value;
        _initialViewDistance = ReconstructionCVars.ViewDistance.Value;
        _initialShowFps = DisplayCVars.ShowFps.Value;
        _initialRagdoll = GameplayCVars.Ragdoll.Value;
        _initialGamma = PostCVars.Gamma.Value;
        _initialMotionBlur = PostCVars.MotionBlur.Value;
        _initialFieldOfView = GameplayCVars.FieldOfView.Value;
        // StoredValue, not Value: the menu backdrop's lite profile holds r_shadows at 0 through an
        // override while the menu is up, and Cancel must put back the player's real choice, not the
        // override's 0. The same applies to the row's initial selection below.
        _initialShadows = ShadowCVars.Shadows.StoredValue;
        _initialShadowCascades = ShadowCVars.ShadowCascades.StoredValue;
        _initialShadowDistance = ShadowCVars.ShadowDistance.StoredValue;
        _initialContactShadows = ShadowCVars.ContactShadows.StoredValue;
        _initialShadowSoftness = ShadowCVars.ShadowSoftness.StoredValue;
        _initialShadowAccumulate = ShadowCVars.ShadowAccumulate.StoredValue;
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
            Height = 880f,
            Margin = new Thickness(0f, 15f, 0f, 0f),
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };

        // The options scroll: there are more of them than the frame holds, so the list lives in
        // a ScrollView and the OK/Cancel bar stays fixed at the bottom of the frame.
        _scroll = new ScrollView(theme)
        {
            Width = 1010f,
            Height = 740f,
            Margin = new Thickness(60f, 42f, 30f, 0f),
            ScrollbarWidth = 14f,
            ScrollbarHitWidth = 56f,
        };

        var configStack = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 14f,
            Width = 980f,
        };
        _scroll.SetContent(configStack);

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

        // ── Option 4: UI Size Slider (80% to 200%) ─────────────────────────
        int initialUiPct = (int)Math.Round(LayoutContext.GlobalUiScale * 100f);
        var uiSizeSlider = new Slider(theme, "UI Size", 80f, 200f, initialUiPct, 5f)
        {
            Width = 980f,
            Height = 56f,
        };
        uiSizeSlider.ValueChanged += value =>
        {
            LayoutContext.GlobalUiScale = Math.Clamp(value / 100f, 0.8f, 2.0f);
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

        // ── Option 6: Render Resolution Quality (540p / 720p / 900p / Native) ───
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

        // ── Dynamic Resolution: the picture shrinks itself to hold the frame rate ──
        // The PS2 trick, done live: when the frame rate falls below the target below, the game steps
        // the render scale down its own ladder until the rate holds, and steps back up slowly when it
        // holds comfortably, so the picture does not flicker. Your Resolution Quality above is the
        // ceiling -- it never renders above that -- and the archived render scale is never written,
        // so your tier survives a relaunch exactly as picked. Off by default: a capable device
        // renders exactly as before.
        bool dynamicState = ReconstructionCVars.DynamicResolution.Value;
        var dynamicToggle = new Toggle(theme, "Dynamic Resolution", dynamicState)
        {
            Width = 980f,
            Height = 56f,
            Tooltip = "Let the game lower the render resolution itself when the frame rate falls, to hold the target below. Your Resolution Quality is the ceiling -- it never renders above that. Off renders exactly as before.",
        };
        dynamicToggle.ValueChanged += val =>
        {
            ReconstructionCVars.DynamicResolution.Value = val;
        };
        configStack.AddChild(dynamicToggle);

        // ── Dynamic Target FPS: the rate dynamic resolution holds ────────────────
        int currentDynamicTarget = ReconstructionCVars.DynamicTargetFps.Value;
        int selectedDynamicTargetIndex = Array.IndexOf(DynamicTargetValues, currentDynamicTarget);
        if (selectedDynamicTargetIndex < 0)
        {
            selectedDynamicTargetIndex = 0;
        }

        var dynamicTargetCycler = new OptionCycler(theme, "Dynamic Target FPS", DynamicTargetLabels, selectedDynamicTargetIndex)
        {
            Width = 980f,
            Height = 56f,
            ContentWidth = 320f,
            Tooltip = "The frame rate dynamic resolution holds. Held to your Max Frame Rate above: on a fresh install that cap is 30, so 45 and 60 hold at 30 until you raise it.",
        };
        dynamicTargetCycler.SelectionChanged += index =>
        {
            ReconstructionCVars.DynamicTargetFps.Value = DynamicTargetValues[index];
        };
        configStack.AddChild(dynamicTargetCycler);

        // ── View Distance: how far the world draws ──────────────────────────────
        // Shortens the far plane: Far is the original's 100 km, Medium 10 km, Near 2.5 km. The
        // original's own fog hides everything past about two and a half kilometres anyway, so Near
        // loses almost nothing visible and skips drawing what the fog would have hidden. The sky dome
        // sizes itself to the far plane, so it stays put, and the held weapon sits centimetres away,
        // so a 2.5 km far plane still contains it entirely.
        float currentViewDistance = ReconstructionCVars.ViewDistance.Value;
        int selectedViewDistanceIndex = 0;
        for (int i = 0; i < ViewDistanceValues.Length; i++)
        {
            if (Math.Abs(ViewDistanceValues[i] - currentViewDistance) < Math.Abs(ViewDistanceValues[selectedViewDistanceIndex] - currentViewDistance))
            {
                selectedViewDistanceIndex = i;
            }
        }

        var viewDistanceCycler = new OptionCycler(theme, "View Distance", ViewDistanceLabels, selectedViewDistanceIndex)
        {
            Width = 980f,
            Height = 56f,
            ContentWidth = 320f,
            Tooltip = "How far the world draws. Near (2.5 km) skips what the original's fog hides anyway; Far is the original's 100 km.",
        };
        viewDistanceCycler.SelectionChanged += index =>
        {
            ReconstructionCVars.ViewDistance.Value = ViewDistanceValues[index];
        };
        configStack.AddChild(viewDistanceCycler);

        // ── Gamma: how bright the picture reads ─────────────────────────────
        // A display-space power curve applied after the tone map. Above 1 the sun-lit
        // models and mid-tones read brighter; below 1 they read darker. 1 is no change.
        float initialGamma = PostCVars.Gamma.Value;
        var gammaSlider = new Slider(theme, "Gamma", 50f, 250f, (int)Math.Round(initialGamma * 100f), 5f)
        {
            Width = 980f,
            Height = 56f,
        };
        gammaSlider.ValueChanged += value =>
        {
            PostCVars.Gamma.Value = Math.Clamp(value / 100f, 0.5f, 2.5f);
        };
        configStack.AddChild(gammaSlider);

        // ── Motion Blur: how much a frame's movement smears ──────────────────
        // A camera shutter: 0 is off and the picture stays crisp; 100% is a full
        // smear. Turning it on opens the offscreen path the blur reads from — the
        // capture flags follow the setting, so the row is never a dead control — and
        // turning it off closes that path again. It costs frame rate on low-end
        // phones: the 540P tier is the honest first try. The weapon stays crisp
        // while the world smears; the rig's motion is zeroed where it is drawn.
        float initialMotionBlur = PostCVars.MotionBlur.Value;
        var motionBlurSlider = new Slider(theme, "Motion Blur", 0f, 100f, (int)Math.Round(initialMotionBlur * 100f), 5f)
        {
            Width = 980f,
            Height = 56f,
            Tooltip = "Smears movement like a camera shutter. 0 is off.\n\nNeeds the offscreen path, so it costs frame rate — try it at 540P first on a low-end phone.",
        };
        motionBlurSlider.ValueChanged += value =>
        {
            PostCVars.MotionBlur.Value = Math.Clamp(value / 100f, 0f, 1f);
        };
        configStack.AddChild(motionBlurSlider);

        // ── Field of View: how wide the camera sees ─────────────────────────
        // Horizontal degrees; 90 is the original's. Applies at once — the
        // projection is rebuilt every frame — and is ignored while the
        // binoculars are up (their 70° opening is the weapon's own) and
        // during cutscenes (each shot carries its own lens).
        float initialFieldOfView = GameplayCVars.FieldOfView.Value;
        var fieldOfViewSlider = new Slider(theme, "Field of View", 60f, 120f, initialFieldOfView, 1f)
        {
            Width = 980f,
            Height = 56f,
            Format = v => string.Create(CultureInfo.InvariantCulture, $"{v:0}°"),
            Tooltip = "How wide the camera sees, in horizontal degrees. 90 is the original's.\n\nWider sees more at the sides; narrower zooms the view in. Binoculars and cutscenes keep their own lenses.",
        };
        fieldOfViewSlider.ValueChanged += value =>
        {
            GameplayCVars.FieldOfView.Value = Math.Clamp(value, 60f, 120f);
        };
        configStack.AddChild(fieldOfViewSlider);

        // ── Shadows: the sun's shadows, from the cascaded map ──────────────────
        // Off is the shipped picture, exactly as before. Low is the desktop Enhanced tier
        // (1024², 2 cascades, 150 m) and High the desktop High tier (2048², 3 cascades,
        // 220 m, contact shadows) — the same numbers the "Shadow Quality" group in
        // GraphicsMenu sets, so the row and the presets cannot drift apart. Turning it on
        // opens the offscreen path and promotes the lighting to hybrid, so the sun is added
        // shadowed on top of the bakes; turning it off returns to baked. It costs frame rate
        // on low-end phones — the cascade pass redraws the scene once per cascade, and the
        // hybrid switch builds the surface cache and the distance field first — so try it at
        // 540P first. The gun in your hands casts and catches no shadow: the viewmodel is
        // drawn forward, outside the G-buffer the shadows are sampled from, by design.
        // The initial selection reads the stored value, not the live one: behind the menu the
        // backdrop's lite profile overrides r_shadows to 0, which is not the player's choice.
        int initialShadows = ShadowCVars.Shadows.StoredValue;
        int selectedShadowIndex = initialShadows <= 0 ? 0 : initialShadows <= 1024 ? 1 : 2;
        var shadowCycler = new OptionCycler(theme, "Shadows", ShadowLabels, selectedShadowIndex)
        {
            Width = 980f,
            Height = 56f,
            ContentWidth = 320f,
            Tooltip = "Sun shadows from the cascaded shadow map. Off is the shipped picture.\n\nLow is 1024², 2 cascades; High is 2048², 3 cascades with contact shadows. Costs frame rate — try it at 540P first on a low-end phone.",
        };
        shadowCycler.SelectionChanged += ApplyShadowTier;
        configStack.AddChild(shadowCycler);

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

        // ── Gameplay: ragdolls ──────────────────────────────────────────────
        // Simulated bodies instead of the original's canned death animations.
        // Experimental: bodies can still clip through the ground, and the level-1
        // crash on the first ragdoll is still open. Off is the original game, and
        // off is the default. The Bepu prototype solver stays a console-only flag
        // (g_ragdoll_bepu), not a row here.
        var gameplayHeader = new Label(theme.Heading, "GAMEPLAY", 24f, Bgra32.White)
        {
            Width = 980f,
        };
        configStack.AddChild(gameplayHeader);

        bool ragdollState = GameplayCVars.Ragdoll.Value;
        var ragdollToggle = new Toggle(theme, "Ragdolls (Experimental)", ragdollState)
        {
            Width = 980f,
            Height = 56f,
            Tooltip = "Simulated bodies instead of the original's canned death animations.\n\nExperimental — bodies can clip through the ground, and the level-1 crash is still open. Off is the original game.",
        };
        ragdollToggle.ValueChanged += val =>
        {
            GameplayCVars.Ragdoll.Value = val;
        };
        configStack.AddChild(ragdollToggle);

        // ── Content packs: data mods (folders of replacement art) ─────────
        // The engine already resolves packs and the game folder's own overrides folder; this section is
        // the touch path to them. It appears on the host that owns the content profile (Android); a host
        // without one (the desktop launcher owns the Content page there) shows nothing, rather than rows
        // that cannot do anything. Pack changes apply at once and are kept even if this screen is left
        // with Cancel: a toggle IS the choice, and the profile is its record, not these rows.
        if (Context.Host.ContentSupported)
        {
            var contentHeader = new Label(theme.Heading, "CONTENT PACKS", 24f, Bgra32.White)
            {
                Width = 980f,
            };
            configStack.AddChild(contentHeader);

            var contentNote = new Label(
                theme.Body,
                "Packs replace the game's art — textures, sounds, models — file for file. Top of the list wins. "
                + "Changes apply at once in a mission and are kept even if you Cancel; menu art refreshes when you next enter a mission.",
                17f,
                UiPalette.TextBody)
            {
                Wrap = true,
                Width = 980f,
            };
            configStack.AddChild(contentNote);

            _contentSection = new StackPanel
            {
                Orientation = Orientation.Vertical,
                Spacing = 8f,
                Width = 980f,
            };
            configStack.AddChild(_contentSection);

            _contentStatus = new Label(theme.Body, string.Empty, 17f, UiPalette.TextBody)
            {
                Wrap = true,
                Width = 980f,
            };
            configStack.AddChild(_contentStatus);

            RebuildContentRows();
        }

        frame.AddChild(_scroll);

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
            PostCVars.Gamma.Value = _initialGamma;
            PostCVars.MotionBlur.Value = _initialMotionBlur;
            GameplayCVars.FieldOfView.Value = _initialFieldOfView;
            ReconstructionCVars.DynamicResolution.Value = _initialDynamicResolution;
            ReconstructionCVars.DynamicTargetFps.Value = _initialDynamicTargetFps;
            ReconstructionCVars.ViewDistance.Value = _initialViewDistance;
            GameplayCVars.Ragdoll.Value = _initialRagdoll;
            // Siblings first, r_shadows last: restoring r_shadows re-derives the capture path and
            // the lighting model, and the frame after that reads the whole tier at once.
            ShadowCVars.ShadowCascades.Value = _initialShadowCascades;
            ShadowCVars.ShadowDistance.Value = _initialShadowDistance;
            ShadowCVars.ContactShadows.Value = _initialContactShadows;
            ShadowCVars.ShadowSoftness.Value = _initialShadowSoftness;
            ShadowCVars.ShadowAccumulate.Value = _initialShadowAccumulate;
            ShadowCVars.Shadows.Value = _initialShadows;
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

    /// <summary>Applies one Shadows tier: the resolution and its sibling variables, exactly as the desktop "Shadow Quality" group in GraphicsMenu sets them.</summary>
    /// <param name="index">0 for Off, 1 for Low (Enhanced), 2 for High.</param>
    /// <remarks>
    /// Siblings first, r_shadows last: the shadows handler promotes the lighting model the moment
    /// r_shadows goes above 0, and the frame after that reads the whole tier at once. A resolution
    /// the console set outside these tiers (4096, say) reads as High in the row, and picking High
    /// then steps it down to 2048.
    /// </remarks>
    private static void ApplyShadowTier(int index)
    {
        switch (index)
        {
            case 1: // Low = Enhanced
                ShadowCVars.ShadowCascades.Value = 2;
                ShadowCVars.ShadowDistance.Value = 150f;
                ShadowCVars.ContactShadows.Value = 0f;
                ShadowCVars.ShadowSoftness.Value = 1f;
                ShadowCVars.ShadowAccumulate.Value = 8f;
                ShadowCVars.Shadows.Value = 1024;
                break;
            case 2: // High
                ShadowCVars.ShadowCascades.Value = 3;
                ShadowCVars.ShadowDistance.Value = 220f;
                ShadowCVars.ContactShadows.Value = 0.35f;
                ShadowCVars.ShadowSoftness.Value = 1.5f;
                ShadowCVars.ShadowAccumulate.Value = 16f;
                ShadowCVars.Shadows.Value = 2048;
                break;
            default: // Off
                ShadowCVars.ShadowCascades.Value = 1;
                ShadowCVars.ShadowDistance.Value = 220f;
                ShadowCVars.ContactShadows.Value = 0f;
                ShadowCVars.ShadowSoftness.Value = 1f;
                ShadowCVars.ShadowAccumulate.Value = 1f;
                ShadowCVars.Shadows.Value = 0;
                break;
        }
    }

    /// <summary>Rebuilds the Content section's rows from the host's live layer list.</summary>
    /// <remarks>
    /// Rows are rebuilt, not patched: a switch or a move changes the counts and the order of every row
    /// below it, and the list is short. The toggles are constructed with their values, which does not fire
    /// their change events, so rebuilding never re-applies a change.
    /// </remarks>
    private void RebuildContentRows()
    {
        if (_contentSection is null)
        {
            return;
        }

        UiTheme theme = Context.Theme;
        _contentSection.ClearChildren();

        IReadOnlyList<IShellHost.ContentLayerRow> layers = Context.Host.ContentLayers();
        if (layers.Count == 0)
        {
            _contentSection.AddChild(new Label(
                theme.Body,
                "No content packs installed. Install one from the launcher, or drop files in the game folder's overrides folder.",
                17f,
                UiPalette.TextBody)
            {
                Wrap = true,
                Width = 980f,
            });
        }

        for (int index = 0; index < layers.Count; index++)
        {
            IShellHost.ContentLayerRow layer = layers[index];
            string kind = layer.Kind switch
            {
                "local" => "Local overrides",
                "pack" => "Pack",
                "dev" => "Development folder",
                "mod" => "Mod data",
                "legacy" => "Legacy folder",
                _ => "Folder",
            };

            _contentSection.AddChild(new Label(
                theme.Body,
                $"{layer.Name} - {kind}: {layer.Files} file(s), {layer.Wins} win(s)",
                17f,
                UiPalette.TextBody)
            {
                Wrap = true,
                Width = 980f,
            });

            var row = new FlexPanel
            {
                Orientation = Orientation.Horizontal,
                Gap = 12f,
                Width = 980f,
            };

            var enabledToggle = new Toggle(theme, "Enabled", layer.Enabled)
            {
                Width = 560f,
                Height = 56f,
            };
            enabledToggle.ValueChanged += enabled =>
            {
                SetContentStatus(Context.Host.SetContentLayerEnabled(layer.Id, enabled));
                RebuildContentRows();
            };
            row.Add(enabledToggle);

            var upBtn = new Button(theme, "UP")
            {
                Width = 190f,
                Height = 56f,
                IsEnabled = index > 0,
            };
            upBtn.Activated += _ =>
            {
                SetContentStatus(Context.Host.MoveContentLayer(layer.Id, up: true));
                RebuildContentRows();
            };
            row.Add(upBtn);

            var downBtn = new Button(theme, "DOWN")
            {
                Width = 190f,
                Height = 56f,
                IsEnabled = index < layers.Count - 1,
            };
            downBtn.Activated += _ =>
            {
                SetContentStatus(Context.Host.MoveContentLayer(layer.Id, up: false));
                RebuildContentRows();
            };
            row.Add(downBtn);

            _contentSection.AddChild(row);
        }

        // Conflicts: the same file in two packs, and which one wins.
        IReadOnlyList<string> conflicts = Context.Host.ContentConflicts();
        if (conflicts.Count == 0)
        {
            _contentSection.AddChild(new Label(
                theme.Body,
                "No conflicts - no file is claimed by two packs.",
                17f,
                UiPalette.TextBody)
            {
                Wrap = true,
                Width = 980f,
            });
        }
        else
        {
            _contentSection.AddChild(new Label(theme.Body, "Conflicts (top wins):", 17f, UiPalette.TextBody)
            {
                Wrap = true,
                Width = 980f,
            });

            foreach (string conflict in conflicts)
            {
                _contentSection.AddChild(new Label(theme.Body, conflict, 17f, UiPalette.TextBody)
                {
                    Wrap = true,
                    Width = 980f,
                });
            }
        }

        // The touch equivalent of F8: every pack and override off without deleting a file. The variable
        // is not saved, so a relaunch always starts with the packs on; a pack that breaks the menu is
        // recovered from the launcher instead.
        var bypassToggle = new Toggle(theme, "Disable all content", Context.Host.ContentBypassed)
        {
            Width = 980f,
            Height = 56f,
            Tooltip = "The touch equivalent of F8 - every pack and override off, without deleting a file. Turn it back on to restore them.",
        };
        bypassToggle.ValueChanged += bypassed =>
        {
            Context.Host.ContentBypassed = bypassed;
            SetContentStatus(bypassed
                ? "All content bypassed - the game's own art is showing."
                : "Content restored.");
            RebuildContentRows();
        };
        _contentSection.AddChild(bypassToggle);

        var rescanBtn = new Button(theme, "RESCAN CONTENT")
        {
            Accent = ButtonAccent.Ghost,
            Width = 980f,
            Height = 56f,
            TextSize = 24f,
        };
        rescanBtn.Activated += _ =>
        {
            SetContentStatus(Context.Host.RescanContent());
            RebuildContentRows();
        };
        _contentSection.AddChild(rescanBtn);

        string? profilePath = Context.Host.ContentProfilePath;
        _contentSection.AddChild(new Label(
            theme.Body,
            profilePath is null
                ? "No content profile in force - the game folder's overrides alone."
                : $"Profile: {profilePath}",
            17f,
            UiPalette.TextBody)
        {
            Wrap = true,
            Width = 980f,
        });
    }

    private void SetContentStatus(string report)
    {
        if (_contentStatus is not null && report.Length > 0)
        {
            _contentStatus.Text = report;
        }
    }

    private void CloseConfig()
    {
        if (Context.InGame)
        {
            Context.Stack.Reset(new PauseScreen(Context));
        }
        else if (Context.SettingsFromRetailMenu)
        {
            // Opened from the retail main menu, not from the shell's own main menu:
            // the player never saw the shell's landing page, so going back means the
            // shell is put away and the retail menu is on screen again.
            Context.SettingsFromRetailMenu = false;
            Context.Stack.Reset(new MainMenuScreen(Context));
            Context.Host.ReturnToRetailMenu();
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

        // Drag to scroll the options list, mirroring the mission list: a drag scrolls, a
        // tap still activates the control under the pointer.
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
}
