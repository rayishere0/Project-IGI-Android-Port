using ProjectIGI.Core.Graphics;

namespace ProjectIGI.UI.Widgets;

/// <summary>
/// The design's colour tokens: one amber accent over dark glass, and a ramp of warm greys for text.
/// </summary>
/// <remarks>
/// <para>
/// Every literal colour in the interface comes from here, so the game's menus, its HUD, the developer
/// console and the launcher read as one product. <see cref="UiTheme"/> takes its defaults from these, and a
/// widget asks its theme for a role rather than naming a colour, so a screen that wants a different look
/// builds a different theme rather than editing a widget.
/// </para>
/// <para>
/// Translucent tokens are given as straight alpha over whatever is behind them — the live scene behind
/// the menu, the launcher's hero image — which is the whole point of the glass: it is never opaque.
/// </para>
/// </remarks>
public static class UiPalette
{
    /// <summary>The page behind everything: <c>#080C07</c>.</summary>
    public static Bgra32 Backdrop => Bgra32.FromRgb(8, 12, 7);

    /// <summary>The base of a stage, and the dark text punched out of an accent fill: <c>#090E08</c>.</summary>
    public static Bgra32 Ink => Bgra32.FromRgb(9, 14, 8);

    /// <summary>The accent: military phosphor green <c>#4EFF78</c>.</summary>
    public static Bgra32 Accent => Bgra32.FromRgb(78, 255, 120);

    /// <summary>A hovered accent fill: <c>#7DFF9B</c>.</summary>
    public static Bgra32 AccentHover => Bgra32.FromRgb(125, 255, 155);

    /// <summary>A hovered accent link or text: <c>#A5FFB9</c>.</summary>
    public static Bgra32 AccentLight => Bgra32.FromRgb(165, 255, 185);

    /// <summary>Selected and hovered text: white.</summary>
    public static Bgra32 TextBright => Bgra32.White;

    /// <summary>Primary text: <c>#D8EDD2</c>.</summary>
    public static Bgra32 Text => Bgra32.FromRgb(216, 237, 210);

    /// <summary>A settings row's caption: <c>#BFDBB8</c>.</summary>
    public static Bgra32 TextLabel => Bgra32.FromRgb(191, 219, 184);

    /// <summary>Prose: a briefing, a description: <c>#A8C7A0</c>.</summary>
    public static Bgra32 TextBody => Bgra32.FromRgb(168, 199, 160);

    /// <summary>An unselected name in a list: <c>#8DB385</c>.</summary>
    public static Bgra32 TextSecondary => Bgra32.FromRgb(141, 179, 133);

    /// <summary>An inactive segment or a hint's label: <c>#74996C</c>.</summary>
    public static Bgra32 TextTertiary => Bgra32.FromRgb(116, 153, 108);

    /// <summary>A caption, an inactive tab, a chevron: <c>#5E8256</c>.</summary>
    public static Bgra32 TextMuted => Bgra32.FromRgb(94, 130, 86);

    /// <summary>A dim mark: an arrow, an empty slot, the off side of a toggle: <c>#4A6B43</c>.</summary>
    public static Bgra32 TextDim => Bgra32.FromRgb(74, 107, 67);

    /// <summary>Something that cannot be used: <c>#344F30</c>.</summary>
    public static Bgra32 TextDisabled => Bgra32.FromRgb(52, 79, 48);

    /// <summary>Success, ready, a fix: <c>#4EFF78</c>.</summary>
    public static Bgra32 Success => Bgra32.FromRgb(78, 255, 120);

    /// <summary>Information, a plugin, a change: <c>#72C2FF</c>.</summary>
    public static Bgra32 Info => Bgra32.FromRgb(114, 194, 255);

    /// <summary>A warning's message text: <c>#FFB640</c>.</summary>
    public static Bgra32 Warning => Bgra32.FromRgb(255, 182, 64);

    /// <summary>An error: <c>#FF4D40</c>.</summary>
    public static Bgra32 Danger => Bgra32.FromRgb(255, 77, 64);

    /// <summary>A destructive action's caption: <c>#FF5D50</c>.</summary>
    public static Bgra32 Destructive => Bgra32.FromRgb(255, 93, 80);

    /// <summary>A destructive action's border: <c>rgba(255,77,64,.5)</c>.</summary>
    public static Bgra32 DestructiveBorder => Bgra32.FromRgba(255, 77, 64, 128);

    /// <summary>A destructive action's hover wash: <c>rgba(255,77,64,.12)</c>.</summary>
    public static Bgra32 DestructiveWash => Bgra32.FromRgba(255, 77, 64, 31);

    /// <summary>A glass panel's tint: tactical olive glass <c>rgba(8,16,8,.75)</c>.</summary>
    public static Bgra32 Glass => Bgra32.FromRgba(8, 16, 8, 192);

    /// <summary>A denser glass, for a panel holding a list: <c>rgba(6,12,6,.82)</c>.</summary>
    public static Bgra32 GlassDense => Bgra32.FromRgba(6, 12, 6, 210);

    /// <summary>A floating menu's glass: <c>rgba(6,12,6,.95)</c>.</summary>
    public static Bgra32 GlassMenu => Bgra32.FromRgba(6, 12, 6, 242);

    /// <summary>A panel's hairline border: phosphor green at .15.</summary>
    public static Bgra32 Hairline => Bgra32.FromRgba(78, 255, 120, 38);

    /// <summary>A header or footer rule: phosphor green at .18.</summary>
    public static Bgra32 Rule => Bgra32.FromRgba(78, 255, 120, 46);

    /// <summary>A row's hover wash: phosphor green at .06.</summary>
    public static Bgra32 HoverWash => Bgra32.FromRgba(78, 255, 120, 15);

    /// <summary>A slider's or progress bar's empty track: phosphor green at .12.</summary>
    public static Bgra32 Track => Bgra32.FromRgba(78, 255, 120, 31);

    /// <summary>A ghost button's border: phosphor green at .25.</summary>
    public static Bgra32 GhostBorder => Bgra32.FromRgba(78, 255, 120, 64);

    /// <summary>A key cap's border: phosphor green at .2.</summary>
    public static Bgra32 KeyBorder => Bgra32.FromRgba(78, 255, 120, 51);

    /// <summary>White at an opacity — the design's hairlines and washes are all this.</summary>
    /// <param name="alpha">The opacity, 0 to 1.</param>
    /// <returns>The colour.</returns>
    public static Bgra32 White(float alpha) => Bgra32.FromRgba(255, 255, 255, ToByte(alpha));

    /// <summary>The accent at an opacity — selections, tints and glows are all this.</summary>
    /// <param name="alpha">The opacity, 0 to 1.</param>
    /// <returns>The colour.</returns>
    public static Bgra32 AccentAt(float alpha) => Accent.WithAlpha(ToByte(alpha));

    /// <summary>The page ink at an opacity — the vignettes and scrims are all this.</summary>
    /// <param name="alpha">The opacity, 0 to 1.</param>
    /// <returns>The colour.</returns>
    public static Bgra32 InkAt(float alpha) => Bgra32.FromRgba(6, 8, 9, ToByte(alpha));

    /// <summary>Scales a colour's alpha.</summary>
    /// <param name="color">The colour.</param>
    /// <param name="factor">The factor, 0 to 1.</param>
    /// <returns>The faded colour.</returns>
    public static Bgra32 Fade(Bgra32 color, float factor) => color.WithAlpha((byte)(color.A * Math.Clamp(factor, 0f, 1f)));

    private static byte ToByte(float alpha) => (byte)MathF.Round(Math.Clamp(alpha, 0f, 1f) * 255f);
}
