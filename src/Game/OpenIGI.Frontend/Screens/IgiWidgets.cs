using System.IO;
using OpenIGI.Core.Graphics;
using OpenIGI.UI;
using OpenIGI.UI.Drawing;
using OpenIGI.UI.Layout;
using OpenIGI.UI.Text;
using OpenIGI.UI.Widgets;

namespace OpenIGI.Frontend.Screens;

/// <summary>
/// Authentic Project I.G.I. 1 title logo: "PROJECT I.G.I. V1.0".
/// Uses the original 3D embossed logo sprite from the game assets if available, or renders crisp authentic vector text.
/// </summary>
public sealed class IgiLogo : UiElement
{
    private readonly UiTheme _theme;
    private UiImage _logoTexture = UiImage.None;
    private bool _attempted;

    /// <summary>Initializes a new instance of the <see cref="IgiLogo"/> class.</summary>
    /// <param name="theme">The UI theme.</param>
    public IgiLogo(UiTheme theme)
    {
        ArgumentNullException.ThrowIfNull(theme);
        _theme = theme;
        Width = 640f;
        Height = 120f;
        HorizontalAlignment = HorizontalAlignment.Center;
    }

    private UiImage GetLogoTexture()
    {
        if (_attempted)
        {
            return _logoTexture;
        }

        _attempted = true;
        string[] candidates =
        [
            "/menu_images/logo.png",
            "menu_images/logo.png",
            "/game/menu_images/logo.png",
            "Project IGI/menu_images/logo.png",
            "/Assets/menu_images/logo.png",
            "Assets/menu_images/logo.png",
            "apps/OpenIGI.Web/wwwroot/menu_images/logo.png"
        ];

        foreach (string path in candidates)
        {
            try
            {
                if (File.Exists(path))
                {
                    (Bgra32[] px, int w, int h) = PngReader.Read(path);
                    if (_theme.ImageFactory is { } factory)
                    {
                        _logoTexture = factory.CreateImage(w, h, px);
                        break;
                    }
                }
            }
            catch
            {
                // Continue to next candidate
            }
        }

        return _logoTexture;
    }

    /// <inheritdoc/>
    protected override UiVec2 MeasureContent(LayoutContext context, UiVec2 available) =>
        new(context.Px(Width), context.Px(Height));

    /// <inheritdoc/>
    protected override void OnDraw(UiPainter painter)
    {
        UiRect b = Bounds;
        if (b.IsEmpty)
        {
            return;
        }

        UiImage logo = GetLogoTexture();
        if (logo.IsValid)
        {
            float targetAspect = 320f / 128f;
            float h = b.Height;
            float w = h * targetAspect;
            if (w > b.Width)
            {
                w = b.Width;
                h = w / targetAspect;
            }

            float lx = b.X + ((b.Width - w) * 0.5f);
            float ly = b.Y + ((b.Height - h) * 0.5f);
            painter.DrawSprite(logo, new UiRect(lx, ly, w, h), UiRect.Unit, Bgra32.White, UiBlend.AlphaBlend);
            return;
        }

        float cx = b.X + (b.Width * 0.5f);

        // "P R O J E C T"
        string sub = "P  R  O  J  E  C  T";
        float subSize = painter.Context.Px(20f);
        float subW = _theme.Heading.Measure(sub, subSize).X;
        painter.DrawText(_theme.Heading, sub, new UiVec2(cx - (subW * 0.5f), b.Y + painter.Context.Px(4f)), subSize, Bgra32.FromRgb(200, 230, 200));

        // "I . G . I ."
        string title = "I . G . I .";
        float titleSize = painter.Context.Px(64f);
        float titleW = _theme.Display.Measure(title, titleSize).X;
        UiVec2 titlePos = new(cx - (titleW * 0.5f), b.Y + painter.Context.Px(26f));

        // Drop shadow
        painter.DrawText(_theme.Display, title, new UiVec2(titlePos.X + 3f, titlePos.Y + 3f), titleSize, Bgra32.FromRgba(0, 0, 0, 200));
        // Main metallic / green text
        painter.DrawText(_theme.Display, title, titlePos, titleSize, Bgra32.FromRgb(220, 250, 220));

        // "V1.0"
        string ver = "V1.0";
        float verSize = painter.Context.Px(18f);
        painter.DrawText(_theme.Mono, ver, new UiVec2(titlePos.X + titleW + painter.Context.Px(8f), titlePos.Y + painter.Context.Px(36f)), verSize, Bgra32.FromRgb(125, 255, 155));
    }
}

/// <summary>
/// A panel with an authentic Project I.G.I. green border and semi-transparent dark background.
/// </summary>
public class IgiBorderedBox : Panel
{
    /// <summary>Gets or sets the border line color.</summary>
    public Bgra32 BorderColor { get; set; } = Bgra32.FromRgb(60, 220, 95);

    /// <summary>Gets or sets the background fill color.</summary>
    public Bgra32 BackgroundColor { get; set; } = Bgra32.FromRgba(6, 14, 8, 200);

    /// <summary>Gets or sets the border stroke width.</summary>
    public float StrokeWidth { get; set; } = 1.5f;

    /// <inheritdoc/>
    protected override void OnDraw(UiPainter painter)
    {
        UiRect b = Bounds;
        if (!b.IsEmpty)
        {
            painter.FillRect(b, BackgroundColor);
            painter.StrokeRect(b, painter.Context.Px(StrokeWidth), BorderColor);
        }

        base.OnDraw(painter);
    }
}

/// <summary>
/// Authentic Project I.G.I. 1 wireframe tactical container box with a green border and header band.
/// </summary>
public class IgiTacticalFrame : Panel
{
    private readonly UiTheme _theme;

    /// <summary>Initializes a new instance of the <see cref="IgiTacticalFrame"/> class.</summary>
    /// <param name="theme">The UI theme.</param>
    /// <param name="title">Header title.</param>
    public IgiTacticalFrame(UiTheme theme, string title = "")
    {
        ArgumentNullException.ThrowIfNull(theme);
        _theme = theme;
        Title = title;
        HorizontalAlignment = HorizontalAlignment.Center;
        VerticalAlignment = VerticalAlignment.Center;
    }

    /// <summary>Gets or sets the frame title.</summary>
    public string Title { get; set; }

    /// <summary>Gets or sets the header bar height in design units.</summary>
    public float HeaderHeight { get; set; } = 48f;

    /// <summary>Gets or sets the border line color.</summary>
    public Bgra32 BorderColor { get; set; } = Bgra32.FromRgb(60, 225, 95);

    /// <summary>Gets or sets the background fill color.</summary>
    public Bgra32 BackgroundColor { get; set; } = Bgra32.FromRgba(8, 16, 10, 240);

    /// <inheritdoc/>
    protected override UiVec2 MeasureContent(LayoutContext context, UiVec2 available)
    {
        UiVec2 childSize = base.MeasureContent(context, available);
        float w = !float.IsNaN(Width) ? context.Px(Width) : childSize.X;
        float h = !float.IsNaN(Height) ? context.Px(Height) : childSize.Y;
        return new UiVec2(w, h);
    }

    /// <inheritdoc/>
    protected override void OnDraw(UiPainter painter)
    {
        UiRect b = Bounds;
        if (b.IsEmpty)
        {
            return;
        }

        // Background fill
        painter.FillRect(b, BackgroundColor);

        // Green wireframe outline
        float stroke = painter.Context.Px(2f);
        painter.StrokeRect(b, stroke, BorderColor);

        // Header bar divider
        if (!string.IsNullOrEmpty(Title))
        {
            float headerH = painter.Context.Px(HeaderHeight);
            UiVec2 lineStart = new(b.X, b.Y + headerH);
            UiVec2 lineEnd = new(b.Right, b.Y + headerH);
            painter.StrokeSoft(lineStart, lineEnd, stroke, BorderColor);

            // Title text
            float titleSize = painter.Context.Px(24f);
            float textW = _theme.Heading.Measure(Title, titleSize).X;
            float tx = b.X + ((b.Width - textW) * 0.5f);
            float ty = b.Y + ((headerH - titleSize) * 0.5f);
            painter.DrawText(_theme.Heading, Title, new UiVec2(tx, ty), titleSize, Bgra32.White);
        }

        base.OnDraw(painter);
    }
}

/// <summary>
/// Authentic Project I.G.I. 1 menu button: glowing green text that highlights bright white-green on hover/focus.
/// </summary>
public class IgiMenuButton : Control
{
    private readonly UiTheme _theme;

    /// <summary>Initializes a new instance of the <see cref="IgiMenuButton"/> class.</summary>
    /// <param name="theme">The theme.</param>
    /// <param name="text">The button text.</param>
    public IgiMenuButton(UiTheme theme, string text)
        : base(theme)
    {
        ArgumentNullException.ThrowIfNull(theme);
        _theme = theme;
        Text = text ?? string.Empty;
        Width = 620f;
        Height = 68f;
        TextSize = 32f;
        HorizontalAlignment = HorizontalAlignment.Center;
        VerticalAlignment = VerticalAlignment.Center;
    }

    /// <summary>Occurs when the button is pressed or clicked.</summary>
    public new event Action? Activated;

    /// <summary>Gets or sets the button text.</summary>
    public string Text { get; set; }

    /// <summary>Gets or sets text size in design units.</summary>
    public float TextSize { get; set; } = 32f;

    /// <summary>Gets or sets text color when normal.</summary>
    public Bgra32 NormalColor { get; set; } = Bgra32.FromRgb(75, 245, 115);

    /// <summary>Gets or sets text color when hovered or focused.</summary>
    public Bgra32 HoverColor { get; set; } = Bgra32.FromRgb(240, 255, 240);

    /// <inheritdoc/>
    public override UiRect PointerBounds => Bounds.IsEmpty ? Bounds : Bounds.Inflate(new Thickness(6f, 4f));

    /// <inheritdoc/>
    public override void Activate()
    {
        base.Activate();
        Activated?.Invoke();
    }

    /// <inheritdoc/>
    protected override UiVec2 MeasureContent(LayoutContext context, UiVec2 available)
    {
        float w = !float.IsNaN(Width) ? context.Px(Width) : MathF.Max(context.Px(500f), _theme.Heading.Measure(Text, context.Px(TextSize)).X + context.Px(80f));
        float h = !float.IsNaN(Height) ? context.Px(Height) : context.Px(TextSize * 2.1f);
        return new UiVec2(w, h);
    }

    /// <inheritdoc/>
    protected override void OnDraw(UiPainter painter)
    {
        UiRect b = Bounds;
        if (b.IsEmpty)
        {
            return;
        }

        bool isHovered = IsPointerOver || Visual.Focus > 0.05f || Visual.Press > 0.05f;

        float size = painter.Context.Px(TextSize);
        float tw = _theme.Heading.Measure(Text, size).X;
        float tx = b.X + ((b.Width - tw) * 0.5f);
        float ty = b.Y + ((b.Height - size) * 0.5f);

        if (isHovered)
        {
            // Subtle tactical wash and green outline on hover/focus/tap for visual touch feedback
            painter.FillRect(b, Bgra32.FromRgba(78, 255, 120, 45));
            painter.StrokeRect(b, painter.Context.Px(1.5f), Bgra32.FromRgb(78, 255, 120));

            // Glowing text
            painter.DrawText(_theme.Heading, Text, new UiVec2(tx, ty - 1f), size, Bgra32.FromRgba(78, 255, 120, 110));
            painter.DrawText(_theme.Heading, Text, new UiVec2(tx, ty + 1f), size, Bgra32.FromRgba(78, 255, 120, 110));
            painter.DrawText(_theme.Heading, Text, new UiVec2(tx, ty), size, HoverColor);
        }
        else
        {
            painter.DrawText(_theme.Heading, Text, new UiVec2(tx, ty), size, NormalColor);
        }
    }
}

/// <summary>
/// A single row in the authentic Project I.G.I. 1 mission selector list.
/// When selected, draws a solid bright phosphor green rectangle with dark text, matching the original game.
/// </summary>
public sealed class IgiMissionRow : Control
{
    private readonly UiTheme _theme;

    /// <summary>Initializes a new instance of the <see cref="IgiMissionRow"/> class.</summary>
    /// <param name="theme">The UI theme.</param>
    /// <param name="title">Mission title.</param>
    public IgiMissionRow(UiTheme theme, string title)
        : base(theme)
    {
        ArgumentNullException.ThrowIfNull(theme);
        _theme = theme;
        Title = title ?? string.Empty;
        Width = 760f;
        Height = 52f;
    }

    /// <summary>Occurs when this mission row is clicked or tapped.</summary>
    public new event Action? Activated;

    /// <summary>Gets the mission title.</summary>
    public string Title { get; }

    /// <summary>Gets or sets whether this row is the currently selected mission.</summary>
    public bool IsSelected { get; set; }

    /// <inheritdoc/>
    public override UiRect PointerBounds => Bounds.IsEmpty ? Bounds : Bounds.Inflate(new Thickness(6f, 4f));

    /// <inheritdoc/>
    public override void Activate()
    {
        base.Activate();
        Activated?.Invoke();
    }

    /// <inheritdoc/>
    protected override UiVec2 MeasureContent(LayoutContext context, UiVec2 available)
    {
        float w = !float.IsNaN(Width) ? context.Px(Width) : context.Px(760f);
        float h = !float.IsNaN(Height) ? context.Px(Height) : context.Px(52f);
        return new UiVec2(w, h);
    }

    /// <inheritdoc/>
    protected override void OnDraw(UiPainter painter)
    {
        UiRect b = Bounds;
        if (b.IsEmpty)
        {
            return;
        }

        float size = painter.Context.Px(26f);
        float padX = painter.Context.Px(14f);
        float ty = b.Y + ((b.Height - size) * 0.5f);

        if (IsSelected)
        {
            // Solid bright phosphor green selection bar
            painter.FillRect(b, Bgra32.FromRgb(55, 235, 95));
            // Dark military text on green
            painter.DrawText(_theme.Heading, Title, new UiVec2(b.X + padX, ty), size, Bgra32.FromRgb(10, 20, 12));
        }
        else
        {
            if (IsPointerOver || Visual.Focus > 0.05f)
            {
                painter.FillRect(b, Bgra32.FromRgba(60, 220, 95, 40));
            }
            // Green text
            painter.DrawText(_theme.Heading, Title, new UiVec2(b.X + padX, ty), size, Bgra32.FromRgb(75, 235, 115));
        }
    }
}
