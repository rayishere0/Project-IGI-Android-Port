using ProjectIGI.Core.Graphics;
using ProjectIGI.Game.Player;
using ProjectIGI.Input;
using ProjectIGI.UI;
using ProjectIGI.UI.Focus;
using ProjectIGI.UI.Layout;
using ProjectIGI.UI.Widgets;

namespace ProjectIGI.Frontend.Screens;

/// <summary>
/// Authentic Project I.G.I. 1 "Cheats" screen:
/// Replaces the legacy profile menu, providing instant toggles for:
/// 1. Unlimited Ammo
/// 2. No Damage (Invulnerability)
/// </summary>
public sealed class CheatsScreen : ShellScreen
{
    private IgiMenuButton? _ammoBtn;
    private IgiMenuButton? _damageBtn;
    private IgiMenuButton? _weaponsBtn;

    /// <summary>Initializes a new instance of the <see cref="CheatsScreen"/> class.</summary>
    /// <param name="context">The shared shell context.</param>
    public CheatsScreen(ShellContext context)
        : base(context)
    {
        // Open the gates so cheats take effect immediately
        PlayerCheatCVars.DeveloperMode.Value = true;
        PlayerCheatCVars.CheatsEnabled.Value = true;
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
            Margin = new Thickness(0f, 20f, 0f, 0f),
            VerticalAlignment = VerticalAlignment.Top,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        root.Add(logo, new Anchor(UiVec2.Zero, new UiVec2(1f, 0.20f), Thickness.Zero));

        // 2. Central Green Wireframe Tactical Box ("Cheats")
        var frame = new IgiTacticalFrame(theme, "Cheats")
        {
            Width = 980f,
            Height = 660f,
            Margin = new Thickness(0f, 40f, 0f, 0f),
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };

        var stack = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 28f,
            Width = 880f,
            Margin = new Thickness(0f, 72f, 0f, 24f),
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };

        // Header info note
        var infoLabel = new Label(theme.Heading, "TACTICAL OVERRIDE SYSTEM", 26f, Bgra32.FromRgb(160, 240, 160))
        {
            HorizontalAlignment = HorizontalAlignment.Center,
            Margin = new Thickness(0f, 0f, 0f, 16f),
        };
        stack.AddChild(infoLabel);

        // Cheat 1: Unlimited Ammo
        _ammoBtn = new IgiMenuButton(theme, GetAmmoText())
        {
            TextSize = 34f,
            Height = 72f,
            Width = 840f,
            NormalColor = PlayerCheatCVars.InfiniteAmmo.Value ? Bgra32.FromRgb(78, 255, 120) : Bgra32.FromRgb(150, 180, 150),
        };
        _ammoBtn.Activated += () =>
        {
            PlayerCheatCVars.InfiniteAmmo.Value = !PlayerCheatCVars.InfiniteAmmo.Value;
            _ammoBtn.Text = GetAmmoText();
            _ammoBtn.NormalColor = PlayerCheatCVars.InfiniteAmmo.Value ? Bgra32.FromRgb(78, 255, 120) : Bgra32.FromRgb(150, 180, 150);
        };
        stack.AddChild(_ammoBtn);

        // Cheat 2: No Damage
        _damageBtn = new IgiMenuButton(theme, GetDamageText())
        {
            TextSize = 34f,
            Height = 72f,
            Width = 840f,
            NormalColor = PlayerCheatCVars.InfiniteHealth.Value ? Bgra32.FromRgb(78, 255, 120) : Bgra32.FromRgb(150, 180, 150),
        };
        _damageBtn.Activated += () =>
        {
            PlayerCheatCVars.InfiniteHealth.Value = !PlayerCheatCVars.InfiniteHealth.Value;
            _damageBtn.Text = GetDamageText();
            _damageBtn.NormalColor = PlayerCheatCVars.InfiniteHealth.Value ? Bgra32.FromRgb(78, 255, 120) : Bgra32.FromRgb(150, 180, 150);
        };
        stack.AddChild(_damageBtn);

        // Cheat 3: All Weapons
        _weaponsBtn = new IgiMenuButton(theme, GetWeaponsText())
        {
            TextSize = 34f,
            Height = 72f,
            Width = 840f,
            NormalColor = PlayerCheatCVars.AllWeapons.Value ? Bgra32.FromRgb(78, 255, 120) : Bgra32.FromRgb(150, 180, 150),
        };
        _weaponsBtn.Activated += () =>
        {
            PlayerCheatCVars.AllWeapons.Value = !PlayerCheatCVars.AllWeapons.Value;
            _weaponsBtn.Text = GetWeaponsText();
            _weaponsBtn.NormalColor = PlayerCheatCVars.AllWeapons.Value ? Bgra32.FromRgb(78, 255, 120) : Bgra32.FromRgb(150, 180, 150);
        };
        stack.AddChild(_weaponsBtn);

        frame.AddChild(stack);

        // ── Bottom Buttons: OK & Back ─────────────────────────────────────
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
        okBtn.Activated += () => Context.Stack.Reset(new MainMenuScreen(Context));
        btnBar.Add(okBtn);

        var backBtn = new IgiMenuButton(theme, "Back")
        {
            TextSize = 30f,
            Height = 60f,
            Width = 180f,
            NormalColor = Bgra32.FromRgb(60, 230, 95),
            HoverColor = Bgra32.FromRgb(220, 255, 220),
        };
        backBtn.Activated += () => Context.Stack.Reset(new MainMenuScreen(Context));
        btnBar.Add(backBtn);

        frame.AddChild(btnBar);
        root.Add(frame, new Anchor(UiVec2.Zero, UiVec2.One, Thickness.Zero));

        return root;
    }

    private static string GetAmmoText() =>
        $"Unlimited Ammo:  [ {(PlayerCheatCVars.InfiniteAmmo.Value ? "ON" : "OFF")} ]";

    private static string GetDamageText() =>
        $"No Damage:  [ {(PlayerCheatCVars.InfiniteHealth.Value ? "ON" : "OFF")} ]";

    private static string GetWeaponsText() =>
        $"All Weapons:  [ {(PlayerCheatCVars.AllWeapons.Value ? "ON" : "OFF")} ]";

    /// <inheritdoc/>
    protected override bool HandleInput(UiNavigation nav, InputState input)
    {
        if (nav.Back)
        {
            Context.Stack.Reset(new MainMenuScreen(Context));
            return false;
        }

        return base.HandleInput(nav, input);
    }
}

