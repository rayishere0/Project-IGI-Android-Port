using System.Globalization;
using ProjectIGI.Core.Graphics;
using ProjectIGI.Rendering;
using ProjectIGI.UI;
using ProjectIGI.UI.Drawing;
using ProjectIGI.UI.Layout;
using ProjectIGI.UI.Text;

namespace ProjectIGI.Presentation.Hud.Remastered.Touch;

/// <summary>Draws a touch screen's controls with our own I.G.I. styling: flat dark olive, properly translucent, no glow, no glass.</summary>
public static class TouchControlsRenderer
{
    // In-game buttons: flat I.G.I. olive. Idle is translucent so the game shows through;
    // held is clearly more solid, so a press reads instantly. Glyphs stay fully opaque to stay readable.
    private static readonly Bgra32 IgiFill = Bgra32.FromRgba(22, 28, 16, 135);
    private static readonly Bgra32 IgiFillHeld = Bgra32.FromRgba(38, 48, 26, 215);
    private static readonly Bgra32 IgiRim = Bgra32.FromRgba(158, 176, 118, 200);
    private static readonly Bgra32 IgiRimHeld = Bgra32.FromRgba(190, 205, 140, 255);
    private static readonly Bgra32 IgiInk = Bgra32.FromRgba(238, 242, 224, 255);
    private static readonly Bgra32 IgiInkFaint = Bgra32.FromRgba(150, 165, 115, 165);
    private static readonly Bgra32 IgiStickFill = Bgra32.FromRgba(22, 28, 16, 90);
    // The palette below stays for the customization toolbar only; it is a config tool, not the game buttons.
    private static readonly Bgra32 Rim = Bgra32.FromRgba(78, 255, 120, 90);
    private static readonly Bgra32 Ink = Bgra32.FromRgba(220, 255, 215, 240);
    private static readonly Bgra32 InkFaint = Bgra32.FromRgba(110, 160, 105, 140);
    private static readonly Bgra32 Shade = Bgra32.FromRgba(0, 0, 0, 110);
    private static readonly Bgra32 DefaultAccent = Bgra32.FromRgba(78, 255, 120, 255);
    private static readonly Bgra32 HighlightSelect = Bgra32.FromRgba(125, 255, 155, 255);

    /// <summary>Draws the controls in play or in customization mode.</summary>
    public static void Draw(
        SpriteBatch batch, LayoutContext context, TouchControls controls, HudTheme? theme, IHudIconSource? icons, HudModel? model, UiFont? font)
    {
        ArgumentNullException.ThrowIfNull(batch);
        ArgumentNullException.ThrowIfNull(context);
        ArgumentNullException.ThrowIfNull(controls);

        UiPainter painter = UiPainter.Create(batch, context);
        float rim = MathF.Max(1f, context.Px(2f));
        float stroke = MathF.Max(1.5f, context.Px(4f));

        if (TouchControls.IsCustomizing)
        {
            // Dim background during customization for contrast
            painter.FillRect(new UiRect(0f, 0f, context.Viewport.X, context.Viewport.Y), Bgra32.FromRgba(0, 0, 0, 130));
        }

        painter.PushOpacity(TouchControls.GlobalOpacity);

        if (controls.Mode is TouchControlMode.Play or TouchControlMode.Customizing)
        {
            DrawStick(painter, controls, rim, stroke);
        }

        bool offered = model is { Actions.Count: > 0 };
        foreach (TouchButtonSpot spot in controls.Layout)
        {
            bool held = controls.Held.Contains(spot.Button);
            if (spot.Card)
            {
                DrawWeaponCard(painter, batch, context, spot, held, icons, model, font, rim, stroke);
                continue;
            }

            bool live = spot.Button == TouchButton.Use && offered;
            Disc(painter, spot.Centre, spot.Radius, held ? IgiFillHeld : IgiFill, held || live ? IgiRimHeld : IgiRim, held || live ? rim * 1.6f : rim);

            HudIcon action = spot.Button == TouchButton.Use && model is { Actions: [var first, ..] } ? first.Icon : HudIcon.None;
            if (action.IsSome && icons is not null
                && DrawPicture(batch, icons, action, spot.Centre, spot.Radius * 1.25f, spot.Radius * 1.05f, IgiInk))
            {
                continue;
            }

            float size = spot.Radius * (spot.Button == TouchButton.Fire ? 0.5f : 0.46f);
            Bgra32 ink = spot.Button == TouchButton.Use && !offered && !held ? IgiInkFaint : IgiInk;
            DrawGlyph(painter, spot.Button, spot.Centre, size, spot.Radius > context.Px(80f) ? stroke * 1.3f : stroke, ink);
        }

        painter.PopOpacity();

        // If customizing, draw interactive layout overlays and top toolbar
        if (TouchControls.IsCustomizing)
        {
            DrawCustomizationOverlay(painter, context, controls, font, rim, stroke);
        }
    }

    private static void DrawCustomizationOverlay(
        UiPainter painter, LayoutContext context, TouchControls controls, UiFont? font, float rim, float stroke)
    {
        float Px(float d) => context.Px(d);
        UiRect safe = context.SafeRect;

        // Top Toolbar background strip
        float topY = safe.Y + Px(8f);
        float barH = Px(52f);
        UiRect barRect = new(safe.X, safe.Y, safe.Width, barH + Px(16f));
        painter.FillRect(barRect, Bgra32.FromRgba(6, 14, 8, 230));
        painter.StrokeLine(new UiVec2(safe.X, barRect.Bottom), new UiVec2(safe.Right, barRect.Bottom), Px(1.5f), Rim);

        // Header Title
        if (font is not null)
        {
            painter.DrawText(font, "TACTICAL HUD CONFIGURATION // DRAG TO MOVE", new UiVec2(safe.X + Px(16f), topY + Px(14f)), Px(18f), DefaultAccent);
        }

        // Toolbar Buttons
        UiRect saveBox    = new(safe.Right - Px(210f), topY, Px(200f), barH);
        UiRect resetBox   = new(safe.Right - Px(390f), topY, Px(170f), barH);
        UiRect sizePlus   = new(safe.Right - Px(490f), topY, Px(90f), barH);
        UiRect sizeMinus  = new(safe.Right - Px(590f), topY, Px(90f), barH);
        UiRect opacityBox = new(safe.Right - Px(760f), topY, Px(160f), barH);

        DrawToolButton(painter, saveBox, "SAVE & EXIT", font, Px(16f), fillAccent: true);
        DrawToolButton(painter, resetBox, "RESET", font, Px(15f));
        DrawToolButton(painter, sizePlus, "SIZE +", font, Px(15f));
        DrawToolButton(painter, sizeMinus, "SIZE -", font, Px(15f));
        DrawToolButton(painter, opacityBox, $"OPACITY: {(int)(TouchControls.GlobalOpacity * 100)}%", font, Px(14f));

        // Draw Element Bounding / Selection and Labels
        foreach (TouchButtonSpot spot in controls.Layout)
        {
            bool isSelected = TouchControls.SelectedElement == spot.ElementId;
            UiRect box = spot.Card ? spot.Box : new UiRect(spot.Centre.X - spot.Radius, spot.Centre.Y - spot.Radius, spot.Radius * 2f, spot.Radius * 2f);

            if (isSelected)
            {
                DrawSelectionFrame(painter, box, Px(10f), stroke * 0.9f, HighlightSelect);
            }

            string label = spot.ElementId switch
            {
                TouchElementId.FireRight => "FIRE / AIM",
                TouchElementId.FireLeft => "FIRE (L)",
                TouchElementId.Scope => "SCOPE",
                TouchElementId.Reload => "RELOAD",
                TouchElementId.Jump => "JUMP",
                TouchElementId.Crouch => "CROUCH",
                TouchElementId.Peek => "PEEK",
                TouchElementId.ZoomIn => "ZOOM +",
                TouchElementId.ZoomOut => "ZOOM -",
                TouchElementId.WeaponCard => "WEAPON",
                TouchElementId.Use => "ACTION",
                TouchElementId.Pause => "PAUSE",
                TouchElementId.Map => "MAP",
                TouchElementId.Binoculars => "BINOCS",
                _ => "",
            };

            if (font is not null && !string.IsNullOrEmpty(label))
            {
                UiVec2 measure = font.Measure(label, Px(12f));
                painter.DrawText(font, label, new UiVec2(spot.Centre.X - (measure.X * 0.5f), box.Bottom + Px(4f)), Px(12f), isSelected ? HighlightSelect : InkFaint);
            }
        }

        // Joystick selection and label
        bool isStickSelected = TouchControls.SelectedElement == TouchElementId.MovementStick;
        UiRect stickBox = new(controls.StickRest.X - controls.StickReachPixels, controls.StickRest.Y - controls.StickReachPixels, controls.StickReachPixels * 2f, controls.StickReachPixels * 2f);
        if (isStickSelected)
        {
            DrawSelectionFrame(painter, stickBox, Px(12f), stroke * 0.9f, HighlightSelect);
        }

        if (font is not null)
        {
            UiVec2 stickMeasure = font.Measure("JOYSTICK", Px(13f));
            painter.DrawText(font, "JOYSTICK", new UiVec2(controls.StickRest.X - (stickMeasure.X * 0.5f), stickBox.Bottom + Px(4f)), Px(13f), isStickSelected ? HighlightSelect : InkFaint);

            // Bottom instructions bar
            string tip = "TAP & DRAG TO POSITION • USE SIZE +/- TO RESCALE • TAP SAVE & EXIT WHEN DONE";
            UiVec2 tipMeasure = font.Measure(tip, Px(14f));
            float botY = safe.Bottom - Px(24f);
            painter.DrawText(font, tip, new UiVec2(safe.X + (safe.Width * 0.5f) - (tipMeasure.X * 0.5f), botY), Px(14f), DefaultAccent);
        }
    }

    private static void DrawToolButton(UiPainter painter, UiRect box, string text, UiFont? font, float fontSize, bool fillAccent = false)
    {
        painter.FillRect(box, fillAccent ? DefaultAccent : Bgra32.FromRgba(10, 20, 12, 220));
        painter.StrokeRect(box, 1.5f, fillAccent ? HighlightSelect : Rim);
        if (font is not null)
        {
            UiVec2 measure = font.Measure(text, fontSize);
            painter.DrawText(font, text, new UiVec2(box.Center.X - (measure.X * 0.5f), box.Center.Y - (measure.Y * 0.5f)), fontSize, fillAccent ? Bgra32.FromRgb(5, 10, 5) : Ink);
        }
    }

    private static void DrawSelectionFrame(UiPainter painter, UiRect box, float cornerLen, float stroke, Bgra32 color)
    {
        UiRect outer = box.Inflate(new Thickness(4f));
        // Corners: TL
        painter.StrokeLine(new UiVec2(outer.X, outer.Y), new UiVec2(outer.X + cornerLen, outer.Y), stroke, color);
        painter.StrokeLine(new UiVec2(outer.X, outer.Y), new UiVec2(outer.X, outer.Y + cornerLen), stroke, color);
        // TR
        painter.StrokeLine(new UiVec2(outer.Right, outer.Y), new UiVec2(outer.Right - cornerLen, outer.Y), stroke, color);
        painter.StrokeLine(new UiVec2(outer.Right, outer.Y), new UiVec2(outer.Right, outer.Y + cornerLen), stroke, color);
        // BL
        painter.StrokeLine(new UiVec2(outer.X, outer.Bottom), new UiVec2(outer.X + cornerLen, outer.Bottom), stroke, color);
        painter.StrokeLine(new UiVec2(outer.X, outer.Bottom), new UiVec2(outer.X, outer.Bottom - cornerLen), stroke, color);
        // BR
        painter.StrokeLine(new UiVec2(outer.Right, outer.Bottom), new UiVec2(outer.Right - cornerLen, outer.Bottom), stroke, color);
        painter.StrokeLine(new UiVec2(outer.Right, outer.Bottom), new UiVec2(outer.Right, outer.Bottom - cornerLen), stroke, color);
    }

    private static void Disc(UiPainter painter, UiVec2 centre, float radius, Bgra32 fill, Bgra32 edge, float thickness)
    {
        painter.FillArc(centre, radius, radius + MathF.Max(2f, radius * 0.06f), 0f, MathF.Tau, Shade);
        painter.FillArc(centre, 0f, radius, 0f, MathF.Tau, fill);
        painter.FillArc(centre, radius - thickness, radius, 0f, MathF.Tau, edge);
    }

    private static void DrawStick(UiPainter painter, TouchControls controls, float rim, float stroke)
    {
        float reach = controls.StickReachPixels;
        UiVec2 origin = controls.StickOrigin ?? controls.StickRest;
        bool active = controls.StickOrigin is not null;
        painter.PushOpacity(active ? 1f : 0.85f);

        painter.FillArc(origin, 0f, reach, 0f, MathF.Tau, IgiStickFill);
        painter.FillArc(origin, reach - rim, reach, 0f, MathF.Tau, IgiRim);

        float caret = reach * 0.09f;
        float at = reach - (caret * 1.8f);
        painter.DrawChevron(new UiVec2(origin.X, origin.Y - at), caret, UiDirection.Up, stroke * 0.6f, IgiInkFaint);
        painter.DrawChevron(new UiVec2(origin.X, origin.Y + at), caret, UiDirection.Down, stroke * 0.6f, IgiInkFaint);
        painter.DrawChevron(new UiVec2(origin.X - at, origin.Y), caret, UiDirection.Left, stroke * 0.6f, IgiInkFaint);
        painter.DrawChevron(new UiVec2(origin.X + at, origin.Y), caret, UiDirection.Right, stroke * 0.6f, IgiInkFaint);

        UiVec2 knob = new(origin.X + (controls.Stick.X * reach), origin.Y + (controls.Stick.Y * reach));
        float knobRadius = reach * 0.4f;
        Disc(painter, knob, knobRadius, active ? IgiFillHeld : IgiFill, active ? IgiRimHeld : IgiRim, rim);
        painter.PopOpacity();
    }

    private static void DrawWeaponCard(
        UiPainter painter, SpriteBatch batch, LayoutContext context, TouchButtonSpot spot, bool held,
        IHudIconSource? icons, HudModel? model, UiFont? font, float rim, float stroke)
    {
        UiRect box = spot.Box;
        float cut = box.Height * 0.22f;
        painter.FillCutRect(box with { Y = box.Y + context.Px(3f) }, cut, UiCorners.TopLeft | UiCorners.BottomRight, Shade);
        painter.FillCutRect(box, cut, UiCorners.TopLeft | UiCorners.BottomRight, held ? IgiFillHeld : IgiFill);
        painter.StrokeCutRect(box, cut, UiCorners.TopLeft | UiCorners.BottomRight, rim, held ? IgiRimHeld : IgiRim);

        float mark = box.Height * 0.16f;
        UiVec2 corner = new(box.X + (mark * 1.6f), box.Y + (mark * 1.5f));
        DrawGlyph(painter, TouchButton.Weapon, corner, mark, stroke * 0.7f, IgiInkFaint);

        HudWeaponView? weapon = model?.Weapon;
        string? rounds = weapon is { Magazine: { } loaded }
            ? weapon.Value.Reserve is { } spare ? $"{loaded.ToString(CultureInfo.InvariantCulture)} / {spare.ToString(CultureInfo.InvariantCulture)}" : loaded.ToString(CultureInfo.InvariantCulture)
            : null;
        float textWidth = 0f;
        float textSize = box.Height * 0.3f;
        if (rounds is not null && font is not null)
        {
            UiVec2 extent = font.Measure(rounds, textSize);
            textWidth = extent.X + (box.Height * 0.25f);
            painter.DrawText(font, rounds, new UiVec2(box.Right - textWidth, box.Bottom - extent.Y - (box.Height * 0.16f)), textSize, IgiInk);
        }

        UiVec2 middle = new(box.X + ((box.Width - textWidth) * 0.5f) + (mark * 0.8f), box.Y + (box.Height * 0.5f));
        if (weapon is { Icon.IsSome: true } shown && icons is not null
            && DrawPicture(batch, icons, shown.Icon, middle, (box.Width - textWidth) * 0.7f, box.Height * 0.66f, IgiInk))
        {
            return;
        }

        DrawGlyph(painter, TouchButton.Weapon, middle, box.Height * 0.25f, stroke, IgiInk);
    }

    private static bool DrawPicture(SpriteBatch batch, IHudIconSource icons, HudIcon icon, UiVec2 centre, float maxWidth, float maxHeight, Bgra32 ink)
    {
        if (!icons.TryMeasure(icon, out float width, out float height) || width <= 0f || height <= 0f)
        {
            return false;
        }

        float scale = MathF.Min(maxWidth / width, maxHeight / height);
        icons.Draw(batch, icon, centre.X - (width * scale * 0.5f), centre.Y - (height * scale * 0.5f), scale, ink);
        return true;
    }

    private static void DrawGlyph(UiPainter painter, TouchButton button, UiVec2 c, float size, float stroke, Bgra32 ink)
    {
        UiVec2 P(float x, float y) => new(c.X + (x * size), c.Y + (y * size));
        void Line(float x0, float y0, float x1, float y1) => painter.StrokeLine(P(x0, y0), P(x1, y1), stroke, ink);
        void Ring(float x, float y, float r) => painter.FillArc(P(x, y), (r * size) - (stroke * 0.5f), (r * size) + (stroke * 0.5f), 0f, MathF.Tau, ink);
        void Dot(float x, float y, float r) => painter.FillDot(P(x, y), r * size, ink);

        switch (button)
        {
            case TouchButton.Fire:
                ReadOnlySpan<UiVec2> round =
                [
                    P(0.85f, -0.85f), P(0.55f, -0.35f), P(-0.45f, 0.65f), P(-0.65f, 0.45f), P(0.35f, -0.55f),
                ];
                painter.FillPolygon(round, ink);
                Line(-0.55f, 0.75f, -0.85f, 1.05f);
                Line(-0.75f, 0.55f, -1.05f, 0.85f);
                break;
            case TouchButton.Scope:
                Ring(0f, 0f, 0.72f);
                Line(0f, -1.05f, 0f, -0.35f);
                Line(0f, 0.35f, 0f, 1.05f);
                Line(-1.05f, 0f, -0.35f, 0f);
                Line(0.35f, 0f, 1.05f, 0f);
                Dot(0f, 0f, 0.1f);
                break;
            case TouchButton.Reload:
                painter.FillQuad(P(-0.35f, -0.75f), P(0.15f, -0.75f), P(0.35f, 0.75f), P(-0.15f, 0.75f), ink);
                painter.FillArc(c, size * 0.86f, (size * 0.86f) + stroke, 0.45f, 2.6f, ink);
                painter.FillTriangle(P(-0.15f, 0.62f), P(0.32f, 0.98f), P(-0.25f, 1.12f), ink);
                break;
            case TouchButton.Jump:
                painter.DrawChevron(P(0f, -0.3f), size * 0.62f, UiDirection.Up, stroke, ink);
                painter.DrawChevron(P(0f, 0.32f), size * 0.62f, UiDirection.Up, stroke, ink);
                break;
            case TouchButton.Crouch:
                Dot(0.15f, -0.72f, 0.2f);
                Line(0.08f, -0.45f, -0.12f, 0.15f);
                Line(-0.12f, 0.15f, 0.45f, 0.2f);
                Line(0.45f, 0.2f, 0.45f, 0.8f);
                Line(-0.12f, 0.15f, -0.45f, 0.8f);
                Line(0.05f, -0.3f, 0.55f, -0.3f);
                break;
            case TouchButton.Peek:
                painter.FillRect(new UiRect(c.X - (size * 0.85f), c.Y - (size * 0.95f), size * 0.35f, size * 1.9f), ink);
                Dot(0.1f, -0.45f, 0.22f);
                Line(-0.05f, -0.2f, 0.25f, 0.85f);
                painter.DrawChevron(P(0.65f, -0.45f), size * 0.22f, UiDirection.Right, stroke * 0.8f, ink);
                break;
            case TouchButton.Use:
                Ring(0f, 0f, 0.78f);
                Dot(0f, 0f, 0.2f);
                break;
            case TouchButton.Weapon:
                Line(-0.8f, -0.32f, 0.55f, -0.32f);
                painter.FillTriangle(P(0.95f, -0.32f), P(0.5f, -0.68f), P(0.5f, 0.04f), ink);
                Line(0.8f, 0.38f, -0.55f, 0.38f);
                painter.FillTriangle(P(-0.95f, 0.38f), P(-0.5f, 0.02f), P(-0.5f, 0.74f), ink);
                break;
            case TouchButton.Pause:
                painter.FillRect(new UiRect(c.X - (size * 0.48f), c.Y - (size * 0.6f), size * 0.3f, size * 1.2f), ink);
                painter.FillRect(new UiRect(c.X + (size * 0.18f), c.Y - (size * 0.6f), size * 0.3f, size * 1.2f), ink);
                break;
            case TouchButton.Map:
                ReadOnlySpan<UiVec2> fold =
                [
                    P(-0.9f, -0.62f), P(-0.3f, -0.82f), P(0.3f, -0.62f), P(0.9f, -0.82f),
                    P(0.9f, 0.62f), P(0.3f, 0.82f), P(-0.3f, 0.62f), P(-0.9f, 0.82f),
                ];
                painter.StrokePolygon(fold, stroke, ink);
                Line(-0.3f, -0.82f, -0.3f, 0.62f);
                Line(0.3f, -0.62f, 0.3f, 0.82f);
                break;
            case TouchButton.Binoculars:
                Ring(-0.46f, 0.2f, 0.38f);
                Ring(0.46f, 0.2f, 0.38f);
                Line(-0.12f, -0.15f, 0.12f, -0.15f);
                Line(-0.62f, -0.15f, -0.4f, -0.68f);
                Line(0.62f, -0.15f, 0.4f, -0.68f);
                break;
            case TouchButton.ZoomIn:
                Line(-0.6f, 0f, 0.6f, 0f);
                Line(0f, -0.6f, 0f, 0.6f);
                break;
            case TouchButton.ZoomOut:
                Line(-0.6f, 0f, 0.6f, 0f);
                break;
            case TouchButton.Close:
                Line(-0.6f, -0.6f, 0.6f, 0.6f);
                Line(-0.6f, 0.6f, 0.6f, -0.6f);
                break;
        }
    }
}
