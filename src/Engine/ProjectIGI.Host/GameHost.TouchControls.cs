using ProjectIGI.Core.Diagnostics;
using ProjectIGI.Core.Graphics;
using ProjectIGI.Game.Config;
using ProjectIGI.Game.Player;
using ProjectIGI.Input;
using ProjectIGI.Presentation;
using ProjectIGI.Presentation.Hud.Remastered;
using ProjectIGI.Presentation.Hud.Remastered.Touch;
using ProjectIGI.UI.Layout;

namespace ProjectIGI.Host;

/// <summary>A touch screen's controls: the fingers read once a frame and pressed as the keys the player's actions are bound to.</summary>
/// <remarks>
/// Whatever has a touch screen -- the browser build on a phone, a tablet -- reports its fingers in <see cref="InputState.Touch"/>,
/// and nothing is shown or pressed until the first one comes down. The keys and mouse buttons pressed are the ones the player's
/// profile binds to each action, so a rebinding moves the button with it, and the game reads them as it reads a keyboard.
/// </remarks>
public sealed partial class GameHost
{
    private readonly TouchControls _touchControls = new();
    private readonly HashSet<KeyCode> _touchKeys = [];
    private readonly HashSet<KeyCode> _touchKeysWanted = [];
    private readonly HashSet<MouseButton> _touchButtons = [];
    private readonly HashSet<MouseButton> _touchButtonsWanted = [];
    private (bool Up, bool Down, bool Left, bool Right) _touchStickHeld;
    // Crouch is a toggle, not a hold: one tap crouches, the next stands up, so the
    // player can crouch and move with two fingers (stick + look) instead of holding
    // a third finger on Crouch.
    private bool _crouchToggled;
    private bool _crouchHeldPrev;

    // Gamepad: the pad's own held keys and buttons, separate from the touch ones
    // so each source releases exactly what it pressed.
    private readonly HashSet<KeyCode> _padKeys = [];
    private readonly HashSet<KeyCode> _padKeysWanted = [];
    private readonly HashSet<MouseButton> _padButtons = [];
    private readonly HashSet<MouseButton> _padButtonsWanted = [];
    private (bool Up, bool Down, bool Left, bool Right) _padStickHeld;
    // A pad press is an edge, but the game reads actions on its 30 Hz tick while
    // frames run faster: a one-frame press can fall between ticks and never be
    // seen. Edge actions therefore hold their synthetic key for 100 ms.
    private readonly Dictionary<string, int> _padEdgeHoldUntilMs = [];
    private int _lastGamepadMilliseconds = -1;
    // The virtual pointer the left stick drives over the retail menu, the shell
    // and the map computer: kept between frames so the cursor stays where the
    // stick left it. It only moves while the stick is deflected, so a touch tap
    // can still drive the pointer while a pad is connected.
    private float _gamepadPointerX;
    private float _gamepadPointerY;
    private bool _gamepadPointerPlaced;
    private bool _padPointerClickHeld;

    /// <summary>The right stick's dead zone: deflection below this turns nothing.</summary>
    private const float GamepadStickDeadZone = 0.18f;

    /// <summary>The trigger pressure that counts as pressed (triggers are axes, 0..1).</summary>
    private const float GamepadTriggerThreshold = 0.35f;

    /// <summary>The turn rate at full right-stick deflection: one full turn a second.</summary>
    private const float GamepadMaxTurnRadiansPerSecond = MathF.Tau;

    /// <summary>How fast the virtual pointer crosses the screen, in pixels a second.</summary>
    private const float GamepadPointerSpeedPixelsPerSecond = 900f;

    /// <summary>How fast the left stick moves the map computer's pointer, in mouse counts a second.</summary>
    private const float GamepadComputerPointerCountsPerSecond = 1200f;

    /// <summary>How long an edge action holds its synthetic key, so the 30 Hz tick sees it.</summary>
    private const int GamepadEdgeHoldMilliseconds = 100;

    /// <summary>The action each button holds, as the profile names it.</summary>
    private static string? TouchAction(TouchButton button) => button switch
    {
        TouchButton.Fire => "Fire",
        TouchButton.Scope => "AlternateFire",
        TouchButton.Reload => "Reload",
        TouchButton.Jump => "Jump",
        TouchButton.Crouch => "Crouch",
        TouchButton.Use => "Activate",
        TouchButton.Weapon => "NextWeapon",
        TouchButton.Peek => "Peek",
        TouchButton.Map => "MapComputer",
        TouchButton.Binoculars => "Binoculars",
        TouchButton.ZoomIn => "ZoomIn",
        TouchButton.ZoomOut => "ZoomOut",
        TouchButton.Close => "MapComputer",
        _ => null,
    };

    /// <summary>What the game is showing, for the controls: a cutscene, play with the pointer locked, or anything with a pointer.</summary>
    private TouchControlMode CurrentTouchMode()
    {
        if (TouchControls.IsCustomizing)
        {
            return TouchControlMode.Customizing;
        }

        if (!_menuFlow.MenuMode && (_mission.Cutscenes?.IsPlaying == true || TitlePlayer is { IsCutscenePlaying: true }))
        {
            return TouchControlMode.Cutscene;
        }

        if (_computerOpen && !_menuFlow.MenuMode)
        {
            return TouchControlMode.Computer;
        }

        // Play is read from what is on the screen rather than from the cursor lock, which the look gives up and takes back for a
        // frame at a time (a settling frame, the weapon wheel): each change of mode lets every finger go, and the stick with it.
        bool play = _playerMode && !_menuFlow.MenuMode && !_computerOpen && !_session.FailedMenu;
        return play ? TouchControlMode.Play : TouchControlMode.Pointer;
    }

    /// <summary>Reads the frame's fingers and presses what they hold. Called straight after the window's events are taken.</summary>
    private void ApplyTouchControls(FrameLoopState state)
    {
        InputState input = _window.Input;
        if (!input.Touch.InUse || _window.Width <= 0 || _window.Height <= 0)
        {
            return;
        }

        // While a controller is connected the touch HUD is hidden and its input
        // is gated off (see ApplyGamepadControls): a palm on invisible buttons
        // must not fire anything. The customizer is the exception — it is entered
        // deliberately from Settings and stays touch-driven.
        bool padActive = input.Gamepad.IsConnected;
        TouchControlMode mode = CurrentTouchMode();
        if (!padActive || mode == TouchControlMode.Customizing)
        {
            _touchControls.Update(input.Touch, mode, new LayoutContext(_window.Width, _window.Height));
        }

        // Leaving play clears the crouch toggle, so the player does not come back
        // from a menu or a computer still crouched.
        if (mode != TouchControlMode.Play)
        {
            _crouchToggled = false;
            _crouchHeldPrev = false;
        }

        // No early return for Customizing: the Play/Computer blocks below are mode-gated, so
        // nothing new is wanted while customizing — but the release section at the end must still
        // run, or touch input held when customization started (e.g. Fire) stays latched and the
        // weapon keeps firing for the whole customization session.
        _touchKeysWanted.Clear();
        _touchButtonsWanted.Clear();
        PlayerProfile? profile = _configuration.Active;

        if (mode == TouchControlMode.Computer && !padActive)
        {
            foreach (TouchButton button in _touchControls.Held)
            {
                if (TouchAction(button) is { } action)
                {
                    Want(profile, action);
                }
            }
        }

        if (mode == TouchControlMode.Play && !padActive)
        {
            // Crouch is a toggle: one tap crouches, the next stands up. Flip it on the
            // press (held -> not held transition), not while the button is down, or a
            // long hold would flip it every frame.
            bool crouchHeld = _touchControls.Held.Contains(TouchButton.Crouch);
            if (crouchHeld && !_crouchHeldPrev)
            {
                _crouchToggled = !_crouchToggled;
            }

            _crouchHeldPrev = crouchHeld;
            if (_crouchToggled)
            {
                Want(profile, "Crouch");
            }

            foreach (TouchButton button in _touchControls.Held)
            {
                if (button == TouchButton.Pause)
                {
                    TryOpenPauseMenu(state);
                }
                else if (button == TouchButton.Crouch)
                {
                    // Handled by the toggle above; do not hold the key while the button is down.
                    continue;
                }
                else if (TouchAction(button) is { } action)
                {
                    Want(profile, action);
                }
            }

            // Each direction is taken past the dead zone and let go only back inside the smaller release zone.
            UiVec2 stick = _touchControls.Stick;
            static bool Hold(bool held, float along) =>
                along > (held ? TouchControls.StickReleaseZone : TouchControls.StickDeadZone);
            _touchStickHeld = (
                Hold(_touchStickHeld.Up, -stick.Y),
                Hold(_touchStickHeld.Down, stick.Y),
                Hold(_touchStickHeld.Left, -stick.X),
                Hold(_touchStickHeld.Right, stick.X));
            if (_touchStickHeld.Up)
            {
                Want(profile, "MoveUp");
            }

            if (_touchStickHeld.Down)
            {
                Want(profile, "MoveDown");
            }

            if (_touchStickHeld.Left)
            {
                Want(profile, "MoveLeft");
            }

            if (_touchStickHeld.Right)
            {
                Want(profile, "MoveRight");
            }

            if (_touchControls.Look is { } look && (look.X != 0f || look.Y != 0f))
            {
                input.Mouse.AddMotion(look.X, look.Y);
            }

        }

        // Gyroscope aim: tilt the phone to turn the view. Only in Play mode and
        // only when the profile enables it. The window accumulates the gyro's
        // angle deltas (radians) each frame; here they become mouse counts so the
        // existing look path (sensitivity, inversion, zoom scaling) applies.
        // The gyro has its own sensitivity (profile.GyroSensitivity, set by the
        // slider in Settings), separate from the mouse sensitivity.
        // Axis signs are a best guess for landscape and must be verified on a
        // real device (flip yaw/pitch here if a direction feels backwards).
        // The motion is drained every frame in Play even while disabled: the sensor keeps
        // feeding the window, and a stale pile-up would spin the view the moment
        // the toggle is switched on. It is applied only while no controller is
        // connected: the pad's right stick owns the look then, and the two would
        // add their motion in the same frame.
        if (mode == TouchControlMode.Play)
        {
            (float gyroYaw, float gyroPitch) = _window.TakeGyroMotion();
            if (!padActive && profile is { GyroEnabled: true } && (gyroYaw != 0f || gyroPitch != 0f))
            {
                float radiansPerCount = MouseLookSettings.FromSensitivity(
                    profile.GyroSensitivity, profile.InvertMouse).RadiansPerCount;
                float countsPerRadian = 1f / MathF.Max(0.00001f, radiansPerCount);
                input.Mouse.AddMotion(gyroYaw * countsPerRadian, gyroPitch * countsPerRadian);
            }
        }

        if (!padActive && _touchControls.Pointer is { } pointer)
        {
            input.Mouse.SetPosition(pointer.At.X, pointer.At.Y);
            if (mode == TouchControlMode.Computer && TacticalComputer is null && _mapComputer?.Pointer is { } computer)
            {
                SteerComputerPointer(input, pointer, computer, profile);
            }

            _touchButtonsWanted.Add(MouseButton.Left);
        }

        // Only what the touches pressed is let go: a key the keyboard holds at the same time stays the keyboard's.
        foreach (KeyCode key in _touchKeys)
        {
            if (!_touchKeysWanted.Contains(key))
            {
                input.Keyboard.SetKey(key, down: false);
            }
        }

        foreach (KeyCode key in _touchKeysWanted)
        {
            if (!_touchKeys.Contains(key))
            {
                input.Keyboard.SetKey(key, down: true);
            }
        }

        foreach (MouseButton button in _touchButtons)
        {
            if (!_touchButtonsWanted.Contains(button))
            {
                input.Mouse.SetButton(button, down: false);
            }
        }

        foreach (MouseButton button in _touchButtonsWanted)
        {
            if (!_touchButtons.Contains(button))
            {
                input.Mouse.SetButton(button, down: true);
            }
        }

        _touchKeys.Clear();
        _touchKeys.UnionWith(_touchKeysWanted);
        _touchButtons.Clear();
        _touchButtons.UnionWith(_touchButtonsWanted);
    }

    /// <summary>Moves the original computer's pointer under the finger.</summary>
    /// <remarks>
    /// The computer moves its pointer by the mouse's counts alone (<c>0x46AC30</c>: half its width for 255 counts at the
    /// profile's sensitivity), so the finger's place is turned into the counts that carry the pointer there, less those already
    /// gathered for the next tick. While the map is dragged the pointer holds still and the counts turn the map, so then the
    /// finger's own travel is passed on, as a mouse's would be.
    /// </remarks>
    private void SteerComputerPointer(InputState input, TouchPointer finger, ComputerPointer computer, PlayerProfile? profile)
    {
        float scale = Math.Max(1, UiScale.Resolve(_options.UiScale, _window.Width, _window.Height));
        float sensitivity = MathF.Max(0.05f, profile?.MouseSensitivity ?? MouseLookSettings.DefaultSensitivity);
        float countsPerPixel = 2f * 255f / (MathF.Max(1f, computer.Width) * sensitivity);

        if (computer.Dragging)
        {
            input.Mouse.AddMotion(finger.Delta.X / scale * countsPerPixel, finger.Delta.Y / scale * countsPerPixel);
            return;
        }

        float wantX = ((finger.At.X / scale) - computer.X) * countsPerPixel;
        float wantY = ((finger.At.Y / scale) - computer.Y) * countsPerPixel;
        input.Mouse.AddMotion(wantX - _computerCountsX, wantY - _computerCountsY);
    }

    /// <summary>Opens the pause menu with the touch Pause button's guards. Shared with the pad's Start button.</summary>
    private void TryOpenPauseMenu(FrameLoopState state)
    {
        if (!_menuFlow.PauseMenu
            && !_computerOpen
            && !_session.FailedMenu
            && _mission.Cutscenes?.IsPlaying != true
            && _mission.MenusEnabled
            && state.Shell is not null
            && _session.Mission is not null)
        {
            _menuFlow.MenuMode = true;
            _menuFlow.PauseMenu = true;
            state.Shell.OpenPauseMenu();
            HostedPlayer?.HoldStill();
            _window.CursorLocked = false;
            _logger.Information("Menu", "Paused via button.");
        }
    }

    private void Want(PlayerProfile? profile, string action) =>
        WantInto(profile, action, _touchKeysWanted, _touchButtonsWanted);

    /// <summary>The pad's half of <see cref="Want"/>: the same synthetic press, tracked in the pad's own sets.</summary>
    private void WantPad(PlayerProfile? profile, string action) =>
        WantInto(profile, action, _padKeysWanted, _padButtonsWanted);

    private static void WantInto(PlayerProfile? profile, string action, HashSet<KeyCode> keysWanted, HashSet<MouseButton> buttonsWanted)
    {
        if (!PlayerProfileInputBindings.TryBoundControl(profile, action, out KeyCode key, out MouseButton? button))
        {
            return;
        }

        if (button is { } mouse)
        {
            buttonsWanted.Add(mouse);
        }
        else
        {
            keysWanted.Add(key);
        }
    }

    /// <summary>
    /// Reads the frame's gamepad and presses what it holds. Called straight after
    /// <see cref="ApplyTouchControls"/> in the frame pass, so <see cref="InputState.Gamepad"/>
    /// is already fed for the frame, exactly like <see cref="InputState.Touch"/>.
    /// </summary>
    /// <remarks>
    /// <para>
    /// The mapping is the standard shooter layout, and every action goes through
    /// <see cref="WantPad"/> so the pad presses the same profile-bound keys and
    /// mouse buttons touch uses — the player and game code never see a gamepad,
    /// only the keys and buttons they already read.
    /// </para>
    /// <para>
    /// Left stick moves, right stick looks (through <see cref="MouseState.AddMotion"/>,
    /// scaled by the profile's Mouse Sensitivity and Invert Mouse, so the look
    /// slider the player already has governs the stick and the zoom scaling in
    /// the first-person view applies for free). RT fires, LT aims (both
    /// thresholded at 0.35, since triggers are axes with no button entries).
    /// RB/LB change weapon, A jumps, B toggles crouch on the shared toggle,
    /// X reloads, Y uses, Start pauses, Back opens the map computer, the D-pad
    /// is Binoculars / Flashlight / Peek, L3 toggles walk/run, and R3 holds the
    /// weapon wheel open (holding the wheel's bound button is what opens it —
    /// see <c>GameHost.WeaponWheel.SteerWeaponWheel</c>). While binoculars or a
    /// sight are zoomed in, D-pad Up/Down become Zoom In/Out instead.
    /// </para>
    /// <para>
    /// While a controller is connected, touch gameplay input is ignored entirely
    /// (pad priority): <see cref="ApplyTouchControls"/> skips its Play and
    /// Computer blocks and the touch look, and <see cref="DrawTouchControls"/>
    /// hides the HUD. Touch still drives the pointer in Pointer mode, and the
    /// layout customizer stays touch-driven. Disconnecting clears the pad's
    /// state in the window, and the release section below releases whatever the
    /// pad was holding, so the touch HUD comes back with no stuck keys.
    /// </para>
    /// </remarks>
    private void ApplyGamepadControls(FrameLoopState state)
    {
        InputState input = _window.Input;
        GamepadState pad = input.Gamepad;
        TouchControlMode mode = CurrentTouchMode();

        // Leaving play clears the crouch toggle, shared with the touch toggle, so
        // the player does not come back from a menu or a computer still crouched.
        if (mode != TouchControlMode.Play)
        {
            _crouchToggled = false;
            _crouchHeldPrev = false;
        }

        int now = _loop.TimeSource.Milliseconds;
        float elapsed = _lastGamepadMilliseconds < 0
            ? 0f
            : Math.Clamp((now - _lastGamepadMilliseconds) / 1000f, 0f, 0.1f);
        _lastGamepadMilliseconds = now;

        _padKeysWanted.Clear();
        _padButtonsWanted.Clear();
        PlayerProfile? profile = _configuration.Active;

        if (pad.IsConnected)
        {
            if (mode == TouchControlMode.Play)
            {
                ApplyGamepadPlay(state, pad, profile, elapsed, now);
            }
            else if (mode == TouchControlMode.Computer)
            {
                ApplyGamepadComputer(pad, profile, elapsed, now);
            }
            else if (mode == TouchControlMode.Pointer)
            {
                ApplyGamepadPointer(pad, elapsed);
            }
            // Cutscene: the skip hold reads the pad directly (UpdateCutsceneSkip),
            // so there is nothing to map here. Customizing: the layout editor is
            // touch-only; the pad does nothing there.
        }
        else
        {
            // Not connected (including the frame a pad was just unplugged):
            // let go of the pointer click, so it cannot stay held into touch.
            SetPointerClick(down: false);
        }

        // Only what the pad pressed is let go: a key the keyboard or touch holds
        // at the same time stays theirs. This runs even while disconnected, or a
        // button held when the pad was unplugged stays latched.
        foreach (KeyCode key in _padKeys)
        {
            if (!_padKeysWanted.Contains(key))
            {
                input.Keyboard.SetKey(key, down: false);
            }
        }

        foreach (KeyCode key in _padKeysWanted)
        {
            if (!_padKeys.Contains(key))
            {
                input.Keyboard.SetKey(key, down: true);
            }
        }

        foreach (MouseButton button in _padButtons)
        {
            if (!_padButtonsWanted.Contains(button))
            {
                input.Mouse.SetButton(button, down: false);
            }
        }

        foreach (MouseButton button in _padButtonsWanted)
        {
            if (!_padButtons.Contains(button))
            {
                input.Mouse.SetButton(button, down: true);
            }
        }

        _padKeys.Clear();
        _padKeys.UnionWith(_padKeysWanted);
        _padButtons.Clear();
        _padButtons.UnionWith(_padButtonsWanted);
    }

    private void ApplyGamepadPlay(FrameLoopState state, GamepadState pad, PlayerProfile? profile, float elapsed, int now)
    {
        // Triggers are axes, so they are thresholded here and held while past it.
        if (pad.RightTrigger > GamepadTriggerThreshold)
        {
            WantPad(profile, "Fire");
        }

        if (pad.LeftTrigger > GamepadTriggerThreshold)
        {
            WantPad(profile, "AlternateFire");
        }

        EdgeWant(profile, pad, GamepadButton.RightShoulder, "NextWeapon", now);
        EdgeWant(profile, pad, GamepadButton.LeftShoulder, "PrevWeapon", now);
        EdgeWant(profile, pad, GamepadButton.South, "Jump", now);

        // Crouch is a toggle, on the shared toggle with touch: one press crouches,
        // the next stands up.
        if (pad.WasPressed(GamepadButton.East))
        {
            _crouchToggled = !_crouchToggled;
        }

        if (_crouchToggled)
        {
            WantPad(profile, "Crouch");
        }

        EdgeWant(profile, pad, GamepadButton.West, "Reload", now);
        EdgeWant(profile, pad, GamepadButton.North, "Activate", now);

        if (pad.WasPressed(GamepadButton.Start))
        {
            TryOpenPauseMenu(state);
        }

        EdgeWant(profile, pad, GamepadButton.Back, "MapComputer", now);

        // While an optic is zoomed in, D-pad Up/Down step its zoom instead of
        // opening binoculars or toggling the flashlight. A long press on Up to
        // open the binoculars keeps zooming in once they are up.
        if (OpticsZoomed())
        {
            if (pad.IsDown(GamepadButton.DpadUp))
            {
                WantPad(profile, "ZoomIn");
            }

            if (pad.IsDown(GamepadButton.DpadDown))
            {
                WantPad(profile, "ZoomOut");
            }
        }
        else
        {
            EdgeWant(profile, pad, GamepadButton.DpadUp, "Binoculars", now);
            EdgeWant(profile, pad, GamepadButton.DpadDown, "Flashlight", now);
        }

        // Peek is one retail action with no left/right variant: either side leans.
        if (pad.IsDown(GamepadButton.DpadLeft) || pad.IsDown(GamepadButton.DpadRight))
        {
            WantPad(profile, "Peek");
        }

        EdgeWant(profile, pad, GamepadButton.LeftStick, "ToggleWalkRun", now);

        // R3 holds the weapon wheel open: holding its bound button (mouse 3) is
        // what opens the wheel, and the right stick's motion then steers it.
        if (pad.IsDown(GamepadButton.RightStick))
        {
            WantPad(profile, "WeaponWheel");
        }

        // Each direction is taken past the dead zone and let go only back inside
        // the smaller release zone — the same Hold() logic as the touch stick.
        static bool Hold(bool held, float along) =>
            along > (held ? TouchControls.StickReleaseZone : TouchControls.StickDeadZone);
        _padStickHeld = (
            Hold(_padStickHeld.Up, -pad.LeftStickY),
            Hold(_padStickHeld.Down, pad.LeftStickY),
            Hold(_padStickHeld.Left, -pad.LeftStickX),
            Hold(_padStickHeld.Right, pad.LeftStickX));
        if (_padStickHeld.Up)
        {
            WantPad(profile, "MoveUp");
        }

        if (_padStickHeld.Down)
        {
            WantPad(profile, "MoveDown");
        }

        if (_padStickHeld.Left)
        {
            WantPad(profile, "MoveLeft");
        }

        if (_padStickHeld.Right)
        {
            WantPad(profile, "MoveRight");
        }

        ApplyGamepadLook(pad, profile, elapsed);
    }

    private void ApplyGamepadComputer(GamepadState pad, PlayerProfile? profile, float elapsed, int now)
    {
        // The map computer moves its pointer by the mouse's counts alone, so the
        // left stick feeds counts; the tactical computer reads the pointer's
        // position, so the stick moves the virtual pointer too.
        MoveGamepadPointer(pad, elapsed);
        float x = DeadZoned(pad.LeftStickX, GamepadStickDeadZone);
        float y = DeadZoned(pad.LeftStickY, GamepadStickDeadZone);
        if (x != 0f || y != 0f)
        {
            _window.Input.Mouse.AddMotion(
                x * GamepadComputerPointerCountsPerSecond * elapsed,
                y * GamepadComputerPointerCountsPerSecond * elapsed);
        }

        // South clicks, like a tap; Back closes the computer (the same action as
        // the touch Close button).
        SetPointerClick(pad.IsDown(GamepadButton.South));
        EdgeWant(profile, pad, GamepadButton.Back, "MapComputer", now);
    }

    private void ApplyGamepadPointer(GamepadState pad, float elapsed)
    {
        // The retail menu reads the pointer's position and left-button hold,
        // exactly as the touch Pointer mode drives it: the left stick moves the
        // cursor and South clicks. Shell screens navigate on the D-pad and left
        // stick for free through UiNavigation once the pad is fed.
        MoveGamepadPointer(pad, elapsed);
        SetPointerClick(pad.IsDown(GamepadButton.South));

        // East is Back. It reaches the retail menu as one queued Escape press —
        // a pulse, not a hold, so the press queue carries it to the menu's own
        // key drain while the shell reads the same press as Back through the
        // pad directly. A held Escape here would also trip the pause path.
        if (pad.WasPressed(GamepadButton.East))
        {
            _window.Input.Keyboard.SetKey(KeyCode.Escape, down: true);
            _window.Input.Keyboard.SetKey(KeyCode.Escape, down: false);
        }
    }

    /// <summary>Whether an optic is zoomed in: binoculars up, or a sight narrowing the field of view.</summary>
    private bool OpticsZoomed()
    {
        if (BinocularsOpen)
        {
            return true;
        }

        // SightZoom's TanX is the default unzoomed and narrower under a sight;
        // 1f is the current tick, no smoothing needed for a yes/no.
        return _playerMode && Viewpoint?.SightZoom(1f) is { } sight
            && sight.TanX < HumanView.DefaultTanX * 0.999f;
    }

    /// <summary>Turns the view from the right stick, through the profile's mouse look settings.</summary>
    private void ApplyGamepadLook(GamepadState pad, PlayerProfile? profile, float elapsed)
    {
        float x = DeadZoned(pad.RightStickX, GamepadStickDeadZone);
        float y = DeadZoned(pad.RightStickY, GamepadStickDeadZone);
        if (x == 0f && y == 0f)
        {
            return;
        }

        // Deflection becomes radians this frame at up to one full turn a second,
        // then mouse counts through the profile's own sensitivity and inversion —
        // the same conversion as the gyro, so the Mouse Sensitivity slider governs
        // the stick and the zoom scaling in the first-person view applies for
        // free. Stick down looks down, as mouse down does; if a direction feels
        // backwards on a device, flip the sign of that line only.
        float radiansPerCount = MouseLookSettings.FromProfile(profile).RadiansPerCount;
        float countsPerRadian = 1f / MathF.Max(0.00001f, radiansPerCount);
        _window.Input.Mouse.AddMotion(
            x * GamepadMaxTurnRadiansPerSecond * elapsed * countsPerRadian,
            y * GamepadMaxTurnRadiansPerSecond * elapsed * countsPerRadian);
    }

    /// <summary>Moves the virtual pointer by the left stick, clamped to the window.</summary>
    private void MoveGamepadPointer(GamepadState pad, float elapsed)
    {
        float x = DeadZoned(pad.LeftStickX, GamepadStickDeadZone);
        float y = DeadZoned(pad.LeftStickY, GamepadStickDeadZone);
        if (x == 0f && y == 0f)
        {
            return;
        }

        // The first move starts from wherever the pointer already is (a touch
        // tap, the shell), so the cursor does not jump to a corner on first use.
        if (!_gamepadPointerPlaced)
        {
            _gamepadPointerX = _window.Input.Mouse.X;
            _gamepadPointerY = _window.Input.Mouse.Y;
            _gamepadPointerPlaced = true;
        }

        _gamepadPointerX = Math.Clamp(
            _gamepadPointerX + (x * GamepadPointerSpeedPixelsPerSecond * elapsed),
            0f, Math.Max(0, _window.Width));
        _gamepadPointerY = Math.Clamp(
            _gamepadPointerY + (y * GamepadPointerSpeedPixelsPerSecond * elapsed),
            0f, Math.Max(0, _window.Height));
        _window.Input.Mouse.SetPosition(_gamepadPointerX, _gamepadPointerY);
    }

    /// <summary>Holds or releases the pointer's left button for the pad's click.</summary>
    /// <remarks>
    /// The click is the pad's own to release: Left is only let go when this method
    /// held it, so a touch tap's Left is never released from under it.
    /// </remarks>
    private void SetPointerClick(bool down)
    {
        if (down && !_padPointerClickHeld)
        {
            _window.Input.Mouse.SetButton(MouseButton.Left, down: true);
            _padPointerClickHeld = true;
        }
        else if (!down && _padPointerClickHeld)
        {
            _window.Input.Mouse.SetButton(MouseButton.Left, down: false);
            _padPointerClickHeld = false;
        }
    }

    /// <summary>Presses an edge action, holding its synthetic key long enough for the 30 Hz tick to see it.</summary>
    private void EdgeWant(PlayerProfile? profile, GamepadState pad, GamepadButton button, string action, int now)
    {
        if (pad.WasPressed(button))
        {
            _padEdgeHoldUntilMs[action] = now + GamepadEdgeHoldMilliseconds;
        }

        if (_padEdgeHoldUntilMs.TryGetValue(action, out int until) && now < until)
        {
            WantPad(profile, action);
        }
    }

    /// <summary>Applies a dead zone with rescaling, so full deflection is still full deflection.</summary>
    private static float DeadZoned(float value, float deadZone)
    {
        float magnitude = MathF.Abs(value);
        if (magnitude <= deadZone)
        {
            return 0f;
        }

        return MathF.Sign(value) * ((magnitude - deadZone) / (1f - deadZone));
    }

    /// <summary>Draws the controls over play, in the title's remastered look.</summary>
    /// <param name="state">The frame loop's state, whose sprite batch they draw into.</param>
    private void DrawTouchControls(FrameLoopState state)
    {
        // A connected controller hides the touch HUD, and ApplyTouchControls gates
        // its input off on the same flag, so no invisible button stays live.
        // The customizer is exempt: it is entered deliberately from Settings.
        // Touch.InUse is a sticky latch that never clears, so on disconnect the
        // HUD comes back on its own with no restart and no stuck state.
        if ((!_window.Input.Touch.InUse && !TouchControls.IsCustomizing)
            || (_window.Input.Gamepad.IsConnected && !TouchControls.IsCustomizing)
            || _touchControls.Mode is not (TouchControlMode.Play or TouchControlMode.Computer or TouchControlMode.Customizing))
        {
            return;
        }

        ITouchHudSource? source = _hudOverlay as ITouchHudSource ?? _titleHud as ITouchHudSource;
        _device.Set2DProjection(SafeWindowWidth, SafeWindowHeight);
        state.Batch.Begin();
        TouchControlsRenderer.Draw(
            state.Batch,
            new LayoutContext(_window.Width, _window.Height),
            _touchControls,
            source?.Theme,
            source?.Icons,
            source?.Model,
            _shellType?.Heading);
        state.Batch.End();
    }
}
