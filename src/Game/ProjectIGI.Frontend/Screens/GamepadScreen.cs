using System.Globalization;
using ProjectIGI.Core.Graphics;
using ProjectIGI.Game.Config;
using ProjectIGI.Input;
using ProjectIGI.UI;
using ProjectIGI.UI.Focus;
using ProjectIGI.UI.Layout;
using ProjectIGI.UI.Widgets;

namespace ProjectIGI.Frontend.Screens;

/// <summary>
/// The pause menu's Gamepad page: the controller's own settings, kept out of Configuration —
/// stick sensitivity, the aim lock, the button mapping, and the reset to defaults.
/// </summary>
/// <remarks>
/// Reached from the pause menu's GAMEPAD row and back to it on Done or Back; every row writes the
/// active profile live and leaving the page saves it, so there is no Cancel to lose a change to.
/// The mapping rows capture controller presses directly, never text, so rebinding needs no keyboard.
/// </remarks>
public sealed class GamepadScreen : ShellScreen
{
    private readonly List<GamepadBindingRow> _rows = [];

    private ScrollView? _scroll;
    private UiVec2? _touchDragStart;
    private float _touchDragStartOffset;
    private bool _isDragging;
    private Control? _pendingTapTarget;

    private Slider? _sensitivitySlider;
    private Slider? _radiusSlider;
    private Slider? _strengthSlider;

    /// <summary>Initializes a new instance of the <see cref="GamepadScreen"/> class.</summary>
    /// <param name="context">The shared shell context.</param>
    public GamepadScreen(ShellContext context)
        : base(context)
    {
        // Profiles saved before controller bindings existed carry none: top them up
        // with the defaults now, so the rows below always have something to show.
        context.Config.Active?.RestoreMissingDefaultGamepadBindings();
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
        PlayerProfile? profile = Context.Config.Active;

        var root = new Canvas();

        var frame = new IgiTacticalFrame(theme, "Gamepad")
        {
            Width = 1100f,
            Height = 880f,
            Margin = new Thickness(0f, 15f, 0f, 0f),
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };

        // The rows scroll: the mapping alone is longer than the frame holds, and the
        // Done bar stays fixed at the bottom of the frame.
        _scroll = new ScrollView(theme)
        {
            Width = 1010f,
            Height = 740f,
            Margin = new Thickness(60f, 42f, 30f, 0f),
            ScrollbarWidth = 14f,
            ScrollbarHitWidth = 56f,
        };

        var stack = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 14f,
            Width = 980f,
        };
        _scroll.SetContent(stack);

        if (profile is null)
        {
            var noProfile = new Label(theme.Body, "No profile loaded.", 20f, Bgra32.White)
            {
                Width = 980f,
            };
            stack.AddChild(noProfile);
        }
        else
        {
            BuildRows(theme, stack, profile);
        }

        frame.AddChild(_scroll);

        // ── Bottom Buttons: Done ──────────────────────────────────────────
        var btnBar = new FlexPanel
        {
            Orientation = Orientation.Horizontal,
            Gap = 28f,
            HorizontalAlignment = HorizontalAlignment.Right,
            VerticalAlignment = VerticalAlignment.Bottom,
            Margin = new Thickness(0f, 0f, 32f, 16f),
        };

        var doneBtn = new IgiMenuButton(theme, "DONE")
        {
            TextSize = 30f,
            Height = 60f,
            Width = 180f,
            NormalColor = Bgra32.FromRgb(60, 230, 95),
            HoverColor = Bgra32.FromRgb(220, 255, 220),
        };
        doneBtn.Activated += SaveAndClose;
        btnBar.Add(doneBtn);

        frame.AddChild(btnBar);
        root.Add(frame, new Anchor(UiVec2.Zero, UiVec2.One, Thickness.Zero));

        return root;
    }

    private void BuildRows(UiTheme theme, StackPanel stack, PlayerProfile profile)
    {
        // ── Controller ────────────────────────────────────────────────────
        var controllerHeader = new Label(theme.Heading, "CONTROLLER", 24f, Bgra32.White)
        {
            Width = 980f,
        };
        stack.AddChild(controllerHeader);

        _sensitivitySlider = new Slider(
            theme, "Controller Sensitivity", 0f, 100f,
            Math.Clamp(profile.GamepadSensitivity, 0f, 1f) * 100f, 5f)
        {
            Width = 980f,
            Height = 56f,
            Format = value => value.ToString("0", CultureInfo.InvariantCulture) + "%",
        };
        _sensitivitySlider.ValueChanged += value =>
        {
            profile.GamepadSensitivity = Math.Clamp(value / 100f, 0f, 1f);
        };
        stack.AddChild(_sensitivitySlider);

        // ── Aim lock ──────────────────────────────────────────────────────
        var aimHeader = new Label(theme.Heading, "AIM LOCK", 24f, Bgra32.White)
        {
            Width = 980f,
        };
        stack.AddChild(aimHeader);

        _radiusSlider = new Slider(
            theme, "Aim Lock Radius", 0f, 100f,
            Math.Clamp(profile.AimLockRadius, 0f, 1f) * 100f, 5f)
        {
            Width = 980f,
            Height = 56f,
            Format = value => value <= 0f
                ? "OFF"
                : value.ToString("0", CultureInfo.InvariantCulture) + "%",
        };
        _radiusSlider.ValueChanged += value =>
        {
            profile.AimLockRadius = Math.Clamp(value / 100f, 0f, 1f);
        };
        stack.AddChild(_radiusSlider);

        _strengthSlider = new Slider(
            theme, "Aim Lock Strength", 0f, 100f,
            Math.Clamp(profile.AimLockStrength, 0f, 1f) * 100f, 5f)
        {
            Width = 980f,
            Height = 56f,
            Format = value => value <= 0f
                ? "OFF"
                : value.ToString("0", CultureInfo.InvariantCulture) + "%",
        };
        _strengthSlider.ValueChanged += value =>
        {
            profile.AimLockStrength = Math.Clamp(value / 100f, 0f, 1f);
        };
        stack.AddChild(_strengthSlider);

        var aimNote = new Label(
            theme.Body,
            "Radius is how much of the half field of view around the crosshair reaches a guard; strength is how hard the view leans. Either at OFF turns the lock off.",
            17f,
            UiPalette.TextBody)
        {
            Wrap = true,
            Width = 980f,
        };
        stack.AddChild(aimNote);

        // ── Button mapping ────────────────────────────────────────────────
        var mappingHeader = new Label(theme.Heading, "BUTTON MAPPING", 24f, Bgra32.White)
        {
            Width = 980f,
        };
        stack.AddChild(mappingHeader);

        var mappingNote = new Label(
            theme.Body,
            "Select a row, then press a button or pull a trigger to bind it. A control another action already uses swaps the two. Escape cancels.",
            17f,
            UiPalette.TextBody)
        {
            Wrap = true,
            Width = 980f,
        };
        stack.AddChild(mappingNote);

        int peekSeen = 0;
        foreach (GamepadBinding binding in profile.GamepadBindings)
        {
            string label = RowLabel(binding.Action, ref peekSeen);
            var row = new GamepadBindingRow(theme, label, binding.Control)
            {
                Width = 980f,
                Height = 56f,
            };
            int index = _rows.Count;
            row.BindingChanged += control =>
            {
                if (Context.Config.Active is { } active)
                {
                    // A swap moves another row's assignment, so every row refreshes.
                    active.RebindGamepad(index, control);
                    RefreshRows(active);
                }
            };
            _rows.Add(row);
            stack.AddChild(row);
        }

        // ── Reset ─────────────────────────────────────────────────────────
        var resetBtn = new Button(theme, "RESET GAMEPAD TO DEFAULTS")
        {
            Accent = ButtonAccent.Ghost,
            Width = 980f,
            Height = 66f,
            TextSize = 24f,
        };
        resetBtn.Activated += _ =>
        {
            if (Context.Config.Active is { } active)
            {
                active.ResetGamepadToDefaults();
                RefreshRows(active);
                if (_sensitivitySlider is not null)
                {
                    _sensitivitySlider.Value = active.GamepadSensitivity * 100f;
                }

                if (_radiusSlider is not null)
                {
                    _radiusSlider.Value = active.AimLockRadius * 100f;
                }

                if (_strengthSlider is not null)
                {
                    _strengthSlider.Value = active.AimLockStrength * 100f;
                }
            }
        };
        stack.AddChild(resetBtn);
    }

    private static string RowLabel(string action, ref int peekSeen)
    {
        // Peek legitimately holds two rows, one per side of the D-pad: the first
        // is the left lean, the second the right.
        if (string.Equals(action, "Peek", StringComparison.OrdinalIgnoreCase))
        {
            string label = peekSeen == 0 ? "Peek Left" : "Peek Right";
            peekSeen++;
            return label;
        }

        return action switch
        {
            "Fire" => "Fire",
            "AlternateFire" => "Aim / Alt Fire",
            "NextWeapon" => "Next Weapon",
            "PrevWeapon" => "Previous Weapon",
            "Jump" => "Jump",
            "Crouch" => "Crouch (Toggle)",
            "Reload" => "Reload",
            "Activate" => "Use / Activate",
            "Pause" => "Pause Menu",
            "MapComputer" => "Map Computer",
            "Binoculars" => "Binoculars",
            "Flashlight" => "Flashlight",
            "ToggleWalkRun" => "Walk / Run",
            "WeaponWheel" => "Weapon Wheel",
            _ => action,
        };
    }

    private void RefreshRows(PlayerProfile profile)
    {
        for (int i = 0; i < _rows.Count && i < profile.GamepadBindings.Count; i++)
        {
            _rows[i].SetBinding(profile.GamepadBindings[i].Control);
        }
    }

    /// <summary>Saves the profile and returns to the pause menu this page was opened from.</summary>
    private void SaveAndClose()
    {
        Context.Host.SaveProfiles();
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
        // Capture feeding runs before navigation: while a row listens, the pressed
        // control binds it — including East, which navigation would otherwise read
        // as Back, and the D-pad, which it would read as directions. The press that
        // activated the row cannot capture itself: it was an edge on the frame
        // before, and edges only fire once.
        GamepadBindingRow? listening = null;
        foreach (GamepadBindingRow row in _rows)
        {
            if (row.IsListening)
            {
                listening = row;
                break;
            }
        }

        if (listening is not null)
        {
            if (input.Keyboard.WasPressed(KeyCode.Escape))
            {
                listening.CancelListening();
                return false;
            }

            foreach (GamepadControl control in GamepadControlNames.AllBindable)
            {
                if (input.Gamepad.WasPressed(control, GamepadState.TriggerThreshold))
                {
                    listening.TryCaptureControl(control);
                    return false;
                }
            }

            // No capture this frame: the listening row consumes directions itself,
            // so focus cannot wander mid-rebind.
            return base.HandleInput(nav, input);
        }

        if (nav.Back)
        {
            SaveAndClose();
            return false;
        }

        // Drag to scroll the rows, mirroring the settings screen: a drag scrolls, a
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
