using ProjectIGI.Core.Configuration;
using ProjectIGI.Core.Graphics;
using ProjectIGI.Frontend.Screens;
using ProjectIGI.Game.Player;
using ProjectIGI.Host.Configuration;
using ProjectIGI.Input;
using ProjectIGI.Presentation.Text;
using ProjectIGI.Rendering;
using ProjectIGI.UI;
using ProjectIGI.UI.Layout;

namespace ProjectIGI.Host;

public sealed partial class GameHost
{
    private bool _cheatsModalOpen;

    private void UpdateCheatsOverlay(FrameLoopState state)
    {
        // Active strictly on the main menu landing screen
        bool isMainMenu = _session.Mission == null && !_menuFlow.PauseMenu && state.Shell?.Stack.Top is MainMenuScreen;
        if (!isMainMenu)
        {
            _cheatsModalOpen = false;
            return;
        }

        float width = SafeWindowWidth;
        float height = SafeWindowHeight;
        float scale = Math.Clamp(height / 480f, 1f, 3f);
        float gearW = 20f * scale;
        float gearH = 20f * scale;
        float gearX = width - gearW - (12f * scale);
        float gearY = 12f * scale;

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
            // The gear itself is small (20 units), but a fingertip is not: give it a
            // generous invisible hit area so big fingers can open the cheats modal.
            float hit = 48f * scale;
            float hitX = gearX + (gearW * 0.5f) - (hit * 0.5f);
            float hitY = gearY + (gearH * 0.5f) - (hit * 0.5f);
            if (click && clickX >= hitX && clickX <= hitX + hit && clickY >= hitY && clickY <= hitY + hit)
            {
                _cheatsModalOpen = true;
                // Suppress click so menu beneath does not click Play/Exit
                input.Mouse.SetButton(MouseButton.Left, down: false);
            }

            // Console icon just under the gear: taps toggle the developer console
            // (the same open state the Grave key flips). The soft keyboard follows
            // the console: GameHost derives KeyboardRequested from Console.IsOpen
            // once per frame, so opening the console summons the IME for typing
            // commands. Same generous hit area as the gear.
            // (The icon is 28 units, centred on the gear; see DrawCheatsOverlay.)
            float kbW = 28f * scale;
            float kbH = 28f * scale;
            float kbX = gearX + ((gearW - kbW) * 0.5f);
            float kbY = gearY + gearH + (8f * scale);
            float kbHitX = kbX + (kbW * 0.5f) - (hit * 0.5f);
            float kbHitY = kbY + (kbH * 0.5f) - (hit * 0.5f);
            if (click && clickX >= kbHitX && clickX <= kbHitX + hit && clickY >= kbHitY && clickY <= kbHitY + hit)
            {
                state.Console.Model.IsOpen = !state.Console.Model.IsOpen;
                input.Mouse.SetButton(MouseButton.Left, down: false);
            }

            // Settings icon just under the console icon: taps open the pause menu's
            // configuration screen over the retail menu, so settings can be changed
            // before a mission starts. Same generous hit area as the gear. (The icon
            // is 28 units, centred on the gear; see DrawCheatsOverlay.)
            float stW = 28f * scale;
            float stH = 28f * scale;
            float stX = gearX + ((gearW - stW) * 0.5f);
            float stY = kbY + kbH + (8f * scale);
            float stHitX = stX + (stW * 0.5f) - (hit * 0.5f);
            float stHitY = stY + (stH * 0.5f) - (hit * 0.5f);
            if (click && clickX >= stHitX && clickX <= stHitX + hit && clickY >= stHitY && clickY <= stHitY + hit)
            {
                if (state.Shell is { } shell)
                {
                    // Menu mode is what lets the shell update and draw over the retail
                    // menu; the retail menu's own tasks see idle input while it is set
                    // (UpdateShell marks the frame captured), so the menu underneath
                    // cannot react to taps on the settings.
                    shell.OpenSettingsFromMainMenu();
                    _menuFlow.MenuMode = true;
                    input.Mouse.SetButton(MouseButton.Left, down: false);
                }
            }

            // Co-op icon just under the settings icon: taps open the co-op screen over the
            // retail menu, so the loopback session can be started before a mission starts.
            // Same generous hit area as the gear. (The icon is 28 units, centred on the
            // gear; see DrawCheatsOverlay.)
            float coW = 28f * scale;
            float coH = 28f * scale;
            float coX = gearX + ((gearW - coW) * 0.5f);
            float coY = stY + stH + (8f * scale);
            float coHitX = coX + (coW * 0.5f) - (hit * 0.5f);
            float coHitY = coY + (coH * 0.5f) - (hit * 0.5f);
            if (click && clickX >= coHitX && clickX <= coHitX + hit && clickY >= coHitY && clickY <= coHitY + hit)
            {
                if (state.Shell is { } shell)
                {
                    // Menu mode is what lets the shell update and draw over the retail
                    // menu; the retail menu's own tasks see idle input while it is set
                    // (UpdateShell marks the frame captured), so the menu underneath
                    // cannot react to taps on the co-op screen.
                    shell.OpenCoopFromMainMenu();
                    _menuFlow.MenuMode = true;
                    input.Mouse.SetButton(MouseButton.Left, down: false);
                }
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
        float modalH = Math.Min(410f * scale, height - (32f * scale));
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

        // Row 3: Unlock All Missions
        float r3Y = contentY + (rowHeight * 3f);
        if (clickX >= btnX && clickX <= btnX + btnW && clickY >= r3Y && clickY <= r3Y + btnH)
        {
            PlayerCheatCVars.UnlockAllLevels.Value = !PlayerCheatCVars.UnlockAllLevels.Value;
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
        bool isMainMenu = _session.Mission == null && !_menuFlow.PauseMenu && state.Shell?.Stack.Top is MainMenuScreen;
        if (!isMainMenu)
        {
            return;
        }

        _shellType ??= UiFontLibrary.Typography(_device);

        float width = SafeWindowWidth;
        float height = SafeWindowHeight;
        float scale = Math.Clamp(height / 480f, 1f, 3f);
        float gearW = 20f * scale;
        float gearH = 20f * scale;
        float gearX = width - gearW - (12f * scale);
        float gearY = 12f * scale;

        _device.BeginStageTiming(RenderStage.UserInterface);
        _device.Set2DProjection(SafeWindowWidth, SafeWindowHeight);
        state.Batch.Begin();

        var painter = UiPainter.Create(state.Batch, new LayoutContext(SafeWindowWidth, SafeWindowHeight));

        Bgra32 brightGreen = Bgra32.FromRgb(57, 227, 101);
        Bgra32 darkBg = Bgra32.FromRgba(10, 24, 14, 235);

        // ── 1. Top-Right Tiny Gear Icon Button ──────────────────────────────
        painter.FillRect(new UiRect(gearX, gearY, gearW, gearH), darkBg);
        painter.StrokeRect(new UiRect(gearX, gearY, gearW, gearH), 1.5f * scale, brightGreen);

        // Geometric Gear Icon centered in button
        float gCenterX = gearX + (gearW * 0.5f);
        float gCenterY = gearY + (gearH * 0.5f);
        float gRadius = 4f * scale;

        // Gear teeth (8 teeth)
        float toothW = 2f * scale;
        float toothL = 2.5f * scale;
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

        // ── 1b. Console icon just under the gear ────────────────────────────
        // Tapping it toggles the developer console (the same open state the Grave
        // key flips). It is drawn highlighted while the console is open. It is deliberately
        // bigger and brighter than the gear (28 units, lighter green fill) so it
        // cannot be missed against the dark menu background.
        float kbW = 28f * scale;
        float kbH = 28f * scale;
        float kbX = gearX + ((gearW - kbW) * 0.5f);
        float kbY = gearY + gearH + (8f * scale);
        painter.FillRect(new UiRect(kbX, kbY, kbW, kbH), state.Console.IsOpen ? brightGreen : Bgra32.FromRgba(16, 44, 22, 245));
        painter.StrokeRect(new UiRect(kbX, kbY, kbW, kbH), 2f * scale, brightGreen);
        // Console prompt glyph ">_", centred by measurement. Dark glyph when
        // highlighted, bright green otherwise. (The console's own prompt sigil is
        // "›"; ">_" reads as a terminal prompt at 28 units.)
        Bgra32 glyphColor = state.Console.IsOpen ? Bgra32.FromRgb(10, 24, 14) : brightGreen;
        if (_shellType is { } type)
        {
            const string prompt = ">_";
            float promptSize = 16f * scale;
            UiVec2 promptExtent = type.Mono.Measure(prompt, promptSize);
            painter.DrawText(type.Mono, prompt,
                new UiVec2(kbX + ((kbW - promptExtent.X) * 0.5f), kbY + ((kbH - promptExtent.Y) * 0.5f)),
                promptSize, glyphColor);
        }

        // ── 1c. Settings icon just under the console icon ───────────────────
        // Three slider tracks with a knob on each: the settings glyph, in the same
        // 28-unit box as the console icon. Tapping it opens the configuration
        // screen over the retail menu (see UpdateCheatsOverlay).
        float stW = 28f * scale;
        float stH = 28f * scale;
        float stX = gearX + ((gearW - stW) * 0.5f);
        float stY = kbY + kbH + (8f * scale);
        painter.FillRect(new UiRect(stX, stY, stW, stH), Bgra32.FromRgba(16, 44, 22, 245));
        painter.StrokeRect(new UiRect(stX, stY, stW, stH), 2f * scale, brightGreen);
        float trackX = stX + (5f * scale);
        float trackW = 18f * scale;
        float trackH = 2f * scale;
        float knob = 5f * scale;
        float[] trackY = [stY + (7f * scale), stY + (13f * scale), stY + (19f * scale)];
        float[] knobX = [stX + (8f * scale), stX + (15f * scale), stX + (11f * scale)];
        for (int i = 0; i < 3; i++)
        {
            painter.FillRect(new UiRect(trackX, trackY[i], trackW, trackH), brightGreen);
            painter.FillRect(new UiRect(knobX[i], trackY[i] - (1.5f * scale), knob, knob), brightGreen);
        }

        // ── 1d. Co-op icon just under the settings icon ─────────────────────
        // Two players side by side in the same 28-unit box as the console and
        // settings icons: head and shoulders each. Tapping it opens the co-op
        // screen over the retail menu (see UpdateCheatsOverlay).
        float coW = 28f * scale;
        float coH = 28f * scale;
        float coX = gearX + ((gearW - coW) * 0.5f);
        float coY = stY + stH + (8f * scale);
        painter.FillRect(new UiRect(coX, coY, coW, coH), Bgra32.FromRgba(16, 44, 22, 245));
        painter.StrokeRect(new UiRect(coX, coY, coW, coH), 2f * scale, brightGreen);
        float pHead = 6f * scale;
        float pBodyW = 10f * scale;
        float pBodyH = 9f * scale;
        float pHeadY = coY + (5f * scale);
        float pBodyY = coY + (12f * scale);
        painter.FillRect(new UiRect(coX + (4f * scale), pHeadY, pHead, pHead), brightGreen);
        painter.FillRect(new UiRect(coX + (2f * scale), pBodyY, pBodyW, pBodyH), brightGreen);
        painter.FillRect(new UiRect(coX + (18f * scale), pHeadY, pHead, pHead), brightGreen);
        painter.FillRect(new UiRect(coX + (16f * scale), pBodyY, pBodyW, pBodyH), brightGreen);

        // ── 2. Cheats Modal Overlay ───────────────────────────────────────
        if (_cheatsModalOpen)
        {
            // Dim background
            painter.FillRect(new UiRect(0f, 0f, width, height), Bgra32.FromRgba(0, 0, 0, 215));

            float modalW = Math.Min(700f * scale, width - (32f * scale));
            float modalH = Math.Min(410f * scale, height - (32f * scale));
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
                painter.DrawText(type.Heading, "CHEATS", new UiVec2(modalX + (20f * scale), modalY + (13f * scale)), 17f * scale, brightGreen);
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
            DrawCheatRow(3, "UNLOCK ALL MISSIONS", "All 14 missions are selectable in Campaign", PlayerCheatCVars.UnlockAllLevels.Value);

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
