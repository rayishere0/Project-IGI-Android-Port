using OpenIGI.Core.Configuration;
using OpenIGI.Core.Graphics;
using OpenIGI.Game.Player;
using OpenIGI.Host.Configuration;
using OpenIGI.Input;
using OpenIGI.Presentation.Text;
using OpenIGI.Rendering;
using OpenIGI.UI;
using OpenIGI.UI.Layout;

namespace OpenIGI.Host;

public sealed partial class GameHost
{
    private bool _cheatsModalOpen;

    private void UpdateCheatsOverlay(FrameLoopState state)
    {
        // Active whenever on main menu (mission is null and pause menu is not active)
        bool isMainMenu = _session.Mission == null && !_menuFlow.PauseMenu;
        if (!isMainMenu)
        {
            _cheatsModalOpen = false;
            return;
        }

        float width = SafeWindowWidth;
        float height = SafeWindowHeight;
        float scale = Math.Clamp(height / 480f, 1f, 3f);
        float gearW = 124f * scale;
        float gearH = 46f * scale;
        float gearX = width - gearW - (20f * scale);
        float gearY = 16f * scale;

        InputState input = _window.Input;
        bool click = false;
        float clickX = 0f, clickY = 0f;

        // Detect touch tap
        if (input.Touch.InUse)
        {
            foreach (var point in input.Touch.Points)
            {
                if (point.Began)
                {
                    click = true;
                    clickX = point.X;
                    clickY = point.Y;
                    break;
                }
            }
        }

        // Detect mouse click
        if (!click && input.Mouse.WasPressed(MouseButton.Left))
        {
            click = true;
            clickX = input.Mouse.X;
            clickY = input.Mouse.Y;
        }

        if (!_cheatsModalOpen)
        {
            if (click && clickX >= gearX && clickX <= gearX + gearW && clickY >= gearY && clickY <= gearY + gearH)
            {
                _cheatsModalOpen = true;
                // Suppress click so menu beneath does not click Play/Exit
                input.Mouse.SetButton(MouseButton.Left, down: false);
            }
            return;
        }

        // When cheats modal is open, always suppress underlying clicks
        input.Mouse.SetButton(MouseButton.Left, down: false);

        if (!click)
        {
            return;
        }

        float modalW = Math.Min(700f * scale, width - (32f * scale));
        float modalH = Math.Min(340f * scale, height - (32f * scale));
        float modalX = (width - modalW) * 0.5f;
        float modalY = (height - modalH) * 0.5f;

        // Check if clicked outside main modal to dismiss
        if (clickX < modalX || clickX > modalX + modalW || clickY < modalY || clickY > modalY + modalH)
        {
            _cheatsModalOpen = false;
            return;
        }

        float contentY = modalY + (56f * scale);
        float rowHeight = 62f * scale;
        float btnW = 110f * scale;
        float btnH = 40f * scale;
        float btnX = modalX + modalW - btnW - (20f * scale);

        // Row 0: Infinite Health
        float r0Y = contentY;
        if (clickX >= btnX && clickX <= btnX + btnW && clickY >= r0Y && clickY <= r0Y + btnH)
        {
            PlayerCheatCVars.InfiniteHealth.Value = !PlayerCheatCVars.InfiniteHealth.Value;
            state.Console.SaveSettings();
            HostConfiguration.Save(_configuration, _logger);
            return;
        }

        // Row 1: Infinite Ammo
        float r1Y = contentY + rowHeight;
        if (clickX >= btnX && clickX <= btnX + btnW && clickY >= r1Y && clickY <= r1Y + btnH)
        {
            PlayerCheatCVars.InfiniteAmmo.Value = !PlayerCheatCVars.InfiniteAmmo.Value;
            state.Console.SaveSettings();
            HostConfiguration.Save(_configuration, _logger);
            return;
        }

        // Row 2: All Weapons
        float r2Y = contentY + (rowHeight * 2f);
        if (clickX >= btnX && clickX <= btnX + btnW && clickY >= r2Y && clickY <= r2Y + btnH)
        {
            PlayerCheatCVars.AllWeapons.Value = !PlayerCheatCVars.AllWeapons.Value;
            state.Console.SaveSettings();
            HostConfiguration.Save(_configuration, _logger);
            return;
        }

        // Close button at bottom
        float closeW = 220f * scale;
        float closeH = 42f * scale;
        float closeX = modalX + ((modalW - closeW) * 0.5f);
        float closeY = modalY + modalH - closeH - (14f * scale);
        if (clickX >= closeX && clickX <= closeX + closeW && clickY >= closeY && clickY <= closeY + closeH)
        {
            _cheatsModalOpen = false;
        }
    }

    private void DrawCheatsOverlay(FrameLoopState state)
    {
        bool isMainMenu = _session.Mission == null && !_menuFlow.PauseMenu;
        if (!isMainMenu)
        {
            return;
        }

        _shellType ??= UiFontLibrary.Typography(_device);

        float width = SafeWindowWidth;
        float height = SafeWindowHeight;
        float scale = Math.Clamp(height / 480f, 1f, 3f);
        float gearW = 124f * scale;
        float gearH = 46f * scale;
        float gearX = width - gearW - (20f * scale);
        float gearY = 16f * scale;

        _device.BeginStageTiming(RenderStage.UserInterface);
        _device.Set2DProjection(SafeWindowWidth, SafeWindowHeight);
        state.Batch.Begin();

        var painter = UiPainter.Create(state.Batch, new LayoutContext(SafeWindowWidth, SafeWindowHeight));

        Bgra32 brightGreen = Bgra32.FromRgb(57, 227, 101);
        Bgra32 darkBg = Bgra32.FromRgba(10, 24, 14, 235);

        // ── 1. Top-Right Gear Button ──────────────────────────────────────
        painter.FillRect(new UiRect(gearX, gearY, gearW, gearH), darkBg);
        painter.StrokeRect(new UiRect(gearX, gearY, gearW, gearH), 1.5f * scale, brightGreen);

        // Tactical corner brackets
        float cLen = 7f * scale;
        float cThick = 2f * scale;
        painter.FillRect(new UiRect(gearX, gearY, cLen, cThick), brightGreen);
        painter.FillRect(new UiRect(gearX, gearY, cThick, cLen), brightGreen);
        painter.FillRect(new UiRect(gearX + gearW - cLen, gearY, cLen, cThick), brightGreen);
        painter.FillRect(new UiRect(gearX + gearW - cThick, gearY, cThick, cLen), brightGreen);
        painter.FillRect(new UiRect(gearX, gearY + gearH - cThick, cLen, cThick), brightGreen);
        painter.FillRect(new UiRect(gearX, gearY + gearH - cLen, cThick, cLen), brightGreen);
        painter.FillRect(new UiRect(gearX + gearW - cLen, gearY + gearH - cThick, cLen, cThick), brightGreen);
        painter.FillRect(new UiRect(gearX + gearW - cThick, gearY + gearH - cLen, cThick, cLen), brightGreen);

        // Geometric Gear Icon on the left side of the button
        float gCenterX = gearX + (22f * scale);
        float gCenterY = gearY + (gearH * 0.5f);
        float gRadius = 8f * scale;

        // Gear teeth (8 teeth)
        float toothW = 4f * scale;
        float toothL = 4.5f * scale;
        painter.FillRect(new UiRect(gCenterX - (toothW * 0.5f), gCenterY - gRadius - toothL, toothW, toothL), brightGreen);
        painter.FillRect(new UiRect(gCenterX - (toothW * 0.5f), gCenterY + gRadius, toothW, toothL), brightGreen);
        painter.FillRect(new UiRect(gCenterX - gRadius - toothL, gCenterY - (toothW * 0.5f), toothL, toothW), brightGreen);
        painter.FillRect(new UiRect(gCenterX + gRadius, gCenterY - (toothW * 0.5f), toothL, toothW), brightGreen);
        // Diagonal teeth
        float diag = gRadius * 0.707f;
        painter.FillRect(new UiRect(gCenterX + diag - (toothW * 0.5f), gCenterY - diag - (toothW * 0.5f), toothW, toothW), brightGreen);
        painter.FillRect(new UiRect(gCenterX - diag - (toothW * 0.5f), gCenterY - diag - (toothW * 0.5f), toothW, toothW), brightGreen);
        painter.FillRect(new UiRect(gCenterX + diag - (toothW * 0.5f), gCenterY + diag - (toothW * 0.5f), toothW, toothW), brightGreen);
        painter.FillRect(new UiRect(gCenterX - diag - (toothW * 0.5f), gCenterY + diag - (toothW * 0.5f), toothW, toothW), brightGreen);

        // Gear Hub & axle hole
        painter.FillRect(new UiRect(gCenterX - gRadius, gCenterY - gRadius, gRadius * 2f, gRadius * 2f), brightGreen);
        painter.FillRect(new UiRect(gCenterX - (gRadius * 0.4f), gCenterY - (gRadius * 0.4f), gRadius * 0.8f, gRadius * 0.8f), darkBg);

        // Label: "CHEATS"
        if (_shellType is { } st)
        {
            painter.DrawText(st.Heading, "CHEATS", new UiVec2(gearX + (42f * scale), gearY + (12f * scale)), 16f * scale, brightGreen);
        }

        // ── 2. Cheats Modal Overlay ───────────────────────────────────────
        if (_cheatsModalOpen)
        {
            // Dim background
            painter.FillRect(new UiRect(0f, 0f, width, height), Bgra32.FromRgba(0, 0, 0, 215));

            float modalW = Math.Min(700f * scale, width - (32f * scale));
            float modalH = Math.Min(340f * scale, height - (32f * scale));
            float modalX = (width - modalW) * 0.5f;
            float modalY = (height - modalH) * 0.5f;

            // Main modal box
            painter.FillRect(new UiRect(modalX, modalY, modalW, modalH), Bgra32.FromRgba(8, 18, 11, 252));
            painter.StrokeRect(new UiRect(modalX, modalY, modalW, modalH), 2f * scale, brightGreen);

            // Modal Title Bar
            float barH = 46f * scale;
            painter.FillRect(new UiRect(modalX, modalY, modalW, barH), Bgra32.FromRgba(16, 44, 22, 240));
            painter.FillRect(new UiRect(modalX, modalY + barH, modalW, 1.5f * scale), brightGreen);

            if (_shellType is { } type)
            {
                painter.DrawText(type.Heading, "TACTICAL OPERATIONS - CHEATS", new UiVec2(modalX + (20f * scale), modalY + (13f * scale)), 17f * scale, brightGreen);
            }

            float contentY = modalY + barH + (12f * scale);
            float rowHeight = 62f * scale;
            float btnW = 110f * scale;
            float btnH = 40f * scale;
            float btnX = modalX + modalW - btnW - (20f * scale);

            void DrawCheatRow(int index, string title, string subtitle, bool active, string activeText = "ON", string inactiveText = "OFF")
            {
                float rowY = contentY + (index * rowHeight);
                float textX = modalX + (20f * scale);

                if (_shellType is { } tp)
                {
                    painter.DrawText(tp.Heading, title, new UiVec2(textX, rowY + (4f * scale)), 15f * scale, Bgra32.White);
                    painter.DrawText(tp.Mono, subtitle, new UiVec2(textX, rowY + (25f * scale)), 11f * scale, Bgra32.FromRgb(140, 185, 140));
                }

                UiRect bRect = new(btnX, rowY + (4f * scale), btnW, btnH);
                if (active)
                {
                    painter.FillRect(bRect, Bgra32.FromRgb(40, 160, 60));
                    painter.StrokeRect(bRect, 1.5f * scale, Bgra32.FromRgb(120, 255, 140));
                    if (_shellType is { } tpAct)
                    {
                        painter.DrawText(tpAct.Mono, $"[ {activeText} ]", new UiVec2(btnX + (26f * scale), rowY + (13f * scale)), 14f * scale, Bgra32.White);
                    }
                }
                else
                {
                    painter.FillRect(bRect, Bgra32.FromRgba(25, 35, 25, 200));
                    painter.StrokeRect(bRect, 1f * scale, Bgra32.FromRgb(60, 90, 65));
                    if (_shellType is { } tpInact)
                    {
                        painter.DrawText(tpInact.Mono, $"[ {inactiveText} ]", new UiVec2(btnX + (23f * scale), rowY + (13f * scale)), 14f * scale, Bgra32.FromRgb(110, 140, 115));
                    }
                }
            }

            DrawCheatRow(0, "INFINITE HEALTH", "Zero damage from bullets, explosions, falls and electric fences", PlayerCheatCVars.InfiniteHealth.Value);
            DrawCheatRow(1, "INFINITE AMMUNITION", "Magazines stay filled, reserves never deplete while firing", PlayerCheatCVars.InfiniteAmmo.Value);
            DrawCheatRow(2, "ALL WEAPONS", "Adds all weapons into inventory for the mission", PlayerCheatCVars.AllWeapons.Value);

            // Close button
            float closeW = 220f * scale;
            float closeH = 42f * scale;
            float closeX = modalX + ((modalW - closeW) * 0.5f);
            float closeY = modalY + modalH - closeH - (14f * scale);
            UiRect cRect = new(closeX, closeY, closeW, closeH);
            painter.FillRect(cRect, Bgra32.FromRgba(18, 38, 22, 230));
            painter.StrokeRect(cRect, 1.5f * scale, brightGreen);
            if (_shellType is { } tpClose)
            {
                painter.DrawText(tpClose.Heading, "[ CLOSE ]", new UiVec2(closeX + (68f * scale), closeY + (11f * scale)), 15f * scale, brightGreen);
            }
        }

        state.Batch.End();
        _device.EndStageTiming();
    }
}
