using ProjectIGI.Core.Graphics;
using ProjectIGI.UI.Drawing;
using ProjectIGI.Input;
using ProjectIGI.UI.Animation;
using ProjectIGI.UI.Focus;
using ProjectIGI.UI.Layout;

namespace ProjectIGI.UI.Widgets;

/// <summary>
/// A row binding an action to a controller control: it shows the current assignment, and on activation
/// listens for the next button press or trigger pull to rebind it.
/// </summary>
/// <remarks>
/// The controller counterpart of <see cref="KeyBindingRow"/>: activating the row puts it into a listening
/// state that shows a prompt; the owning screen, seeing <see cref="IsListening"/>, feeds it the next
/// controller press through <see cref="TryCaptureControl"/> (and an escape to cancel through
/// <see cref="CancelListening"/>). While listening it consumes every navigation direction so a stray
/// stick nudge does not move focus away mid-rebind. Capture reads the controller's own edge tests, never
/// text input, so it needs no keyboard of any kind.
/// </remarks>
public class GamepadBindingRow : Control
{
    private readonly Tween _pulse = new(0f, duration: 0.6f, Ease.InOutQuad);
    private string? _shownName;
    private string _shownCap = string.Empty;

    /// <summary>Initializes a new instance of the <see cref="GamepadBindingRow"/> class.</summary>
    /// <param name="theme">The theme to draw from.</param>
    /// <param name="action">The action name shown on the left.</param>
    /// <param name="boundControl">The initially bound control.</param>
    /// <param name="displayName">The player-facing binding name, or <see langword="null"/> for the control's own name.</param>
    /// <exception cref="ArgumentNullException"><paramref name="theme"/> is <see langword="null"/>.</exception>
    public GamepadBindingRow(UiTheme theme, string action, GamepadControl boundControl, string? displayName = null)
        : base(theme)
    {
        Action = action ?? string.Empty;
        BoundControl = boundControl;
        BoundControlName = displayName ?? GamepadControlNames.DisplayName(boundControl);
    }

    /// <summary>Raised when the bound control changes, with the new control.</summary>
    public event Action<GamepadControl>? BindingChanged;

    /// <summary>Gets or sets the action name.</summary>
    public string Action { get; set; }

    /// <summary>Gets the currently bound control.</summary>
    public GamepadControl BoundControl { get; private set; }

    /// <summary>Gets the player-facing name of the current binding.</summary>
    public string BoundControlName { get; private set; }

    /// <summary>Refreshes the displayed assignment without raising <see cref="BindingChanged"/>.</summary>
    /// <param name="control">The control now bound.</param>
    public void SetBinding(GamepadControl control)
    {
        BoundControl = control;
        BoundControlName = GamepadControlNames.DisplayName(control);
    }

    /// <summary>Gets a value indicating whether the row is waiting for a control to bind.</summary>
    public bool IsListening { get; private set; }

    /// <summary>Feeds a controller press to a listening row, binding it.</summary>
    /// <param name="control">The control pressed.</param>
    /// <returns><see langword="true"/> when the row consumed the press.</returns>
    public bool TryCaptureControl(GamepadControl control)
    {
        if (!IsListening)
        {
            return false;
        }

        IsListening = false;
        if (control != BoundControl)
        {
            BoundControl = control;
            BoundControlName = GamepadControlNames.DisplayName(control);
            BindingChanged?.Invoke(control);
        }

        return true;
    }

    /// <summary>Stops listening without changing the binding: the escape path.</summary>
    public void CancelListening()
    {
        IsListening = false;
    }

    /// <inheritdoc/>
    public override bool HandleNavigate(NavDirection direction) => IsListening;

    /// <inheritdoc/>
    protected override void OnActivate()
    {
        IsListening = true;
        _pulse.SnapTo(0f);
        _pulse.Retarget(1f);
    }

    /// <inheritdoc/>
    protected override void OnUpdate(float elapsedSeconds)
    {
        base.OnUpdate(elapsedSeconds);
        if (IsListening)
        {
            // Ping-pong the pulse so the prompt breathes while waiting.
            _pulse.Update(elapsedSeconds);
            if (_pulse.IsComplete)
            {
                _pulse.Retarget(_pulse.Value >= 0.5f ? 0f : 1f);
            }
        }
    }

    /// <inheritdoc/>
    protected override UiVec2 MeasureContent(LayoutContext context, UiVec2 available) =>
        UiRowStyle.Measure(this, context, available);

    /// <inheritdoc/>
    protected override void OnDraw(UiPainter painter)
    {
        float highlight = UiRowStyle.Highlight(this);

        // The binding is a key cap, the same one the footer's hints use, so a binding reads as the
        // control it is rather than as a word.
        LayoutContext context = painter.Context;
        float appear = Visual.Appear;
        float sizePx = context.Px(13f);
        if (!ReferenceEquals(_shownName, BoundControlName))
        {
            _shownName = BoundControlName;
            _shownCap = BoundControlName.ToUpperInvariant();
        }

        string value = IsListening ? "PRESS A BUTTON…" : _shownCap;
        float textWidth = UiPainter.MeasureLabel(Theme.Mono, value, sizePx, 0.08f);
        float padX = context.Px(10f);
        float height = context.Px(28f);
        float right = Bounds.Right - context.Px(UiRowStyle.Inset);
        var cap = new UiRect(right - textWidth - (padX * 2f), Bounds.Y + ((Bounds.Height - height) * 0.5f), textWidth + (padX * 2f), height);
        UiRowStyle.DrawFrame(painter, this, Action, highlight, cap.X);

        Bgra32 border = IsListening
            ? Interpolate.Lerp(UiPalette.AccentAt(0.35f), Theme.Accent, _pulse.Value)
            : Interpolate.Lerp(UiPalette.KeyBorder, UiPalette.AccentAt(0.45f), highlight);
        if (IsListening)
        {
            painter.FillRect(cap, UiPalette.Fade(UiPalette.AccentAt(0.08f), appear));
        }

        painter.StrokeRect(cap, context.Px(1f), UiPalette.Fade(border, appear));
        Bgra32 text = !IsEnabled ? Theme.TextDisabled : IsListening ? Theme.Accent : Theme.Text;
        painter.DrawLabel(
            Theme.Mono,
            value,
            new UiVec2(cap.X + padX, UiRowStyle.CenterY(Theme.Mono, sizePx, cap)),
            sizePx,
            UiPalette.Fade(text, appear),
            0.08f);
    }
}
