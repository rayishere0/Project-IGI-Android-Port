using System.Collections.Generic;
using System.IO;
using OpenIGI.Core.Graphics;
using OpenIGI.Input;
using OpenIGI.UI;
using OpenIGI.UI.Drawing;
using OpenIGI.UI.Focus;
using OpenIGI.UI.Layout;
using OpenIGI.UI.Widgets;

namespace OpenIGI.Frontend.Screens;

/// <summary>
/// Authentic Project I.G.I. 1 "Select Mission" screen:
/// Direct replica of the classic mission selection dialog featuring mission thumbnail frame,
/// objective text box, scrollable mission list with solid green active selection, and OK/Cancel actions.
/// </summary>
public sealed class CampaignScreen : ShellScreen
{
    private static readonly (int Id, string Name, string Objective)[] DefaultMissions =
    [
        (1, "Trainyard", "Infiltrate the trainyard and obtain satellite communications data."),
        (2, "SAM Base", "Sabotage the surface-to-air missile installation defenses."),
        (3, "Military Airbase", "Penetrate the military airbase and secure transit vehicle."),
        (4, "GOD", "Locate and secure the surveillance communications uplink."),
        (5, "Radar Base", "Disable radar array systems to blind regional tracking."),
        (6, "Get Priboi", "Locate Priboi inside the compound and escort him to extraction."),
        (7, "Border Crossing", "Evade border patrols and cross the heavily fortified boundary."),
        (8, "Re-supply", "Infiltrate the re-supply depot and replenish tactical armaments."),
        (9, "Missile Trainyard", "Locate missile transport train and plant surveillance bugs."),
        (10, "Defend Priboi", "Establish defensive perimeter and protect Priboi from attack."),
        (11, "Eagle's Nest I", "Infiltrate mountain base via cable car installation."),
        (12, "Eagle's Nest II", "Neutralize fortress guard towers and retrieve nuclear intel."),
        (13, "Nuclear Infiltration", "Breach the underground nuclear storage facility."),
        (14, "Finding the bomb", "Kill Ekk and find the bomb"),
    ];

    private readonly List<IgiMissionRow> _rowWidgets = [];
    private int _selectedIndex;
    private Label? _missionDescLabel;
    private ScrollView? _scroll;
    private UiVec2? _touchDragStart;
    private float _touchDragStartOffset;
    private bool _isDragging;
    private Control? _pendingTapTarget;

    /// <summary>Initializes a new instance of the <see cref="CampaignScreen"/> class.</summary>
    /// <param name="context">The shared shell context.</param>
    public CampaignScreen(ShellContext context)
        : base(context)
    {
    }

    /// <inheritdoc/>
    protected override bool HasChrome => false;

    /// <inheritdoc/>
    protected override ShellTab Tab => ShellTab.Campaign;

    /// <inheritdoc/>
    public override float BackdropBlur => 0f;

    /// <inheritdoc/>
    protected override UiElement? BuildContent(LayoutContext context)
    {
        UiTheme theme = Context.Theme;
        _rowWidgets.Clear();

        var root = new Canvas();

        // 1. Logo at Top Center
        var logo = new IgiLogo(theme)
        {
            Margin = new Thickness(0f, 20f, 0f, 0f),
            VerticalAlignment = VerticalAlignment.Top,
            HorizontalAlignment = HorizontalAlignment.Center,
        };
        root.Add(logo, new Anchor(UiVec2.Zero, new UiVec2(1f, 0.20f), Thickness.Zero));

        // 2. Central Green Tactical Frame ("Select Mission")
        var frame = new IgiTacticalFrame(theme, "Select Mission")
        {
            Width = 1420f,
            Height = 780f,
            Margin = new Thickness(0f, 40f, 0f, 0f),
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
        };

        var mainLayout = new FlexPanel
        {
            Orientation = Orientation.Horizontal,
            Gap = 28f,
            Margin = new Thickness(28f, 68f, 28f, 72f),
        };

        // ── LEFT COLUMN: Thumbnail & Mission Briefing ──────────────────────
        var leftCol = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 20f,
            Width = 560f,
        };

        // Thumbnail / Visual Frame
        var thumbFrame = new TacticalWireframeBox(theme)
        {
            Width = 560f,
            Height = 280f,
        };
        thumbFrame.SetMission(DefaultMissions[0].Id);
        leftCol.AddChild(thumbFrame);

        // Objective Description Box (matching authentic IGI 1 wireframe layout)
        var descBox = new IgiBorderedBox
        {
            Width = 560f,
            Height = 100f,
            Padding = new Thickness(16f, 16f),
        };

        _missionDescLabel = new Label(theme.Heading, DefaultMissions[0].Objective, 24f, Bgra32.White);
        descBox.AddChild(_missionDescLabel);
        leftCol.AddChild(descBox);
        mainLayout.Add(leftCol);

        // ── RIGHT COLUMN: Mission List (wireframe container matching IGI 1) ─
        var rightCol = new IgiBorderedBox
        {
            Width = 620f,
            Height = 580f,
            Padding = new Thickness(4f, 4f),
        };

        _scroll = new ScrollView(theme)
        {
            Width = 612f,
            Height = 572f,
            ScrollbarWidth = 14f,
            ScrollbarHitWidth = 56f,
        };

        var missionStack = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 4f,
            Width = 590f,
        };

        // Resolve missions (use engine context missions if available, otherwise classic 14)
        (int Id, string Name, string Objective)[] missions = Context.Missions.Count > 0
            ? [.. Context.Missions.Select(m => (m.Id, m.Name, m.Description))]
            : DefaultMissions;

        for (int i = 0; i < missions.Length; i++)
        {
            int index = i;
            var item = missions[i];
            var row = new IgiMissionRow(theme, item.Name)
            {
                IsSelected = index == _selectedIndex,
                Width = 590f,
                Height = 52f,
            };

            row.Activated += () =>
            {
                _selectedIndex = index;
                for (int r = 0; r < _rowWidgets.Count; r++)
                {
                    _rowWidgets[r].IsSelected = r == _selectedIndex;
                }
                thumbFrame.SetMission(item.Id);
                if (_missionDescLabel is not null)
                {
                    _missionDescLabel.Text = string.IsNullOrEmpty(item.Objective)
                        ? "Execute tactical espionage objectives."
                        : item.Objective;
                }
            };

            _rowWidgets.Add(row);
            missionStack.AddChild(row);
        }

        _scroll.AddChild(missionStack);
        rightCol.AddChild(_scroll);
        mainLayout.Add(rightCol);

        frame.AddChild(mainLayout);

        // ── BOTTOM RIGHT BUTTONS: OK & Cancel (stacked vertically matching IGI 1) ─
        var btnBar = new StackPanel
        {
            Orientation = Orientation.Vertical,
            Spacing = 16f,
            HorizontalAlignment = HorizontalAlignment.Right,
            VerticalAlignment = VerticalAlignment.Bottom,
            Margin = new Thickness(0f, 0f, 32f, 28f),
        };

        var okBtn = new IgiMenuButton(theme, "OK")
        {
            TextSize = 32f,
            Height = 54f,
            Width = 140f,
            NormalColor = Bgra32.FromRgb(60, 230, 95),
            HoverColor = Bgra32.FromRgb(220, 255, 220),
        };
        okBtn.Activated += () =>
        {
            int missionId = missions[_selectedIndex].Id;
            Context.Host.StartMission(missionId, 1);
        };
        btnBar.AddChild(okBtn);

        var cancelBtn = new IgiMenuButton(theme, "Cancel")
        {
            TextSize = 32f,
            Height = 54f,
            Width = 140f,
            NormalColor = Bgra32.FromRgb(60, 230, 95),
            HoverColor = Bgra32.FromRgb(220, 255, 220),
        };
        cancelBtn.Activated += () => Context.Stack.Reset(new MainMenuScreen(Context));
        btnBar.AddChild(cancelBtn);

        frame.AddChild(btnBar);
        root.Add(frame, new Anchor(UiVec2.Zero, UiVec2.One, Thickness.Zero));

        return root;
    }

    /// <inheritdoc/>
    protected override bool HandleInput(UiNavigation nav, InputState input)
    {
        if (nav.Back)
        {
            Context.Stack.Reset(new MainMenuScreen(Context));
            return false;
        }

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

/// <summary>
/// Tactical wireframe viewfinder frame for mission visual preview with authentic screenshot display.
/// </summary>
internal sealed class TacticalWireframeBox : UiElement
{
    private readonly UiTheme _theme;
    private int _missionId = 1;
    private UiImage _thumbnail = UiImage.None;
    private readonly Dictionary<int, UiImage> _thumbnailCache = [];

    public TacticalWireframeBox(UiTheme theme)
    {
        _theme = theme;
    }

    public void SetMission(int missionId)
    {
        _missionId = missionId;
        if (!_thumbnailCache.TryGetValue(missionId, out _thumbnail))
        {
            _thumbnail = TryLoadThumbnail(missionId);
            _thumbnailCache[missionId] = _thumbnail;
        }
    }

    private UiImage TryLoadThumbnail(int missionId)
    {
        string[] candidates =
        [
            $"/mission_images/mission{missionId}.png",
            $"mission_images/mission{missionId}.png",
            $"/game/mission_images/mission{missionId}.png",
            $"Project IGI/mission_images/mission{missionId}.png",
            $"/Assets/mission_images/mission{missionId}.png",
            $"Assets/mission_images/mission{missionId}.png",
            $"apps/OpenIGI.Web/wwwroot/mission_images/mission{missionId}.png"
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
                        return factory.CreateImage(w, h, px);
                    }
                }
            }
            catch
            {
                // Continue to next candidate
            }
        }

        return UiImage.None;
    }

    protected override UiVec2 MeasureContent(LayoutContext context, UiVec2 available) =>
        new(context.Px(Width), context.Px(Height));

    protected override void OnDraw(UiPainter painter)
    {
        UiRect b = Bounds;
        if (b.IsEmpty)
        {
            return;
        }

        // 1. Dark tactical background
        painter.FillRect(b, Bgra32.FromRgb(6, 14, 8));

        // 2. Mission thumbnail image from Project IGI assets
        if (!_thumbnail.IsValid && _theme.ImageFactory is not null)
        {
            SetMission(_missionId);
        }

        if (_thumbnail.IsValid)
        {
            painter.DrawSprite(_thumbnail, b, UiRect.Unit, Bgra32.White, UiBlend.Opaque);
        }

        // 3. Green wireframe border over/around the preview
        float stroke = painter.Context.Px(1.5f);
        Bgra32 green = Bgra32.FromRgb(60, 220, 95);
        painter.StrokeRect(b, stroke, green);

        // Corner tick marks
        float tick = painter.Context.Px(16f);
        painter.StrokeSoft(new UiVec2(b.X, b.Y + tick), new UiVec2(b.X, b.Y), stroke, green);
        painter.StrokeSoft(new UiVec2(b.X, b.Y), new UiVec2(b.X + tick, b.Y), stroke, green);

        painter.StrokeSoft(new UiVec2(b.Right - tick, b.Y), new UiVec2(b.Right, b.Y), stroke, green);
        painter.StrokeSoft(new UiVec2(b.Right, b.Y), new UiVec2(b.Right, b.Y + tick), stroke, green);

        painter.StrokeSoft(new UiVec2(b.X, b.Bottom - tick), new UiVec2(b.X, b.Bottom), stroke, green);
        painter.StrokeSoft(new UiVec2(b.X, b.Bottom), new UiVec2(b.X + tick, b.Bottom), stroke, green);

        painter.StrokeSoft(new UiVec2(b.Right - tick, b.Bottom), new UiVec2(b.Right, b.Bottom), stroke, green);
        painter.StrokeSoft(new UiVec2(b.Right, b.Bottom), new UiVec2(b.Right, b.Bottom - tick), stroke, green);

        if (!_thumbnail.IsValid)
        {
            // Fallback crosshair if image not yet loaded
            float cx = b.X + (b.Width * 0.5f);
            float cy = b.Y + (b.Height * 0.5f);
            float arm = painter.Context.Px(24f);
            painter.StrokeSoft(new UiVec2(cx - arm, cy), new UiVec2(cx + arm, cy), stroke, Bgra32.FromRgba(60, 220, 95, 120));
            painter.StrokeSoft(new UiVec2(cx, cy - arm), new UiVec2(cx, cy + arm), stroke, Bgra32.FromRgba(60, 220, 95, 120));

            string text = "[ TACTICAL RECON ]";
            float size = painter.Context.Px(18f);
            float tw = _theme.Mono.Measure(text, size).X;
            painter.DrawText(_theme.Mono, text, new UiVec2(cx - (tw * 0.5f), cy + arm + painter.Context.Px(12f)), size, Bgra32.FromRgba(78, 255, 120, 180));
        }
    }
}
