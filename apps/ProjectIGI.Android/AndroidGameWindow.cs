using System.Collections.Concurrent;
using ProjectIGI.Input;
using ProjectIGI.Platform;
using ProjectIGI.Rendering;

namespace ProjectIGI.Android;

internal readonly record struct AndroidInputEvent(
    int Kind, // 0 = Touch, 1 = Key, 2 = Resize, 3 = Gyro, 5 = GamepadAxis, 6 = GamepadConnected
    int Action, // For Touch: 0=Down, 1=Up, 2=Move, 3=Cancel. For Key: 0=Up, 1=Down. For GamepadAxis: 0=LeftStick, 1=RightStick, 2=Triggers. For GamepadConnected: 0=Disconnected, 1=Connected
    int IdOrKey,
    float X,
    float Y);

public sealed class AndroidGameWindow : IGameWindow
{
    private readonly ConcurrentQueue<AndroidInputEvent> _eventQueue = new();
    private readonly ConcurrentQueue<string> _textQueue = new();
    // A Return press synthesized from a soft-keyboard newline (see PumpEvents): the
    // key stays down until the next pump so the console's WasPressed edge check can
    // see it, then it is released before the next frame's shadow is taken.
    private bool _returnKeyDownFromText;
    // A new native window after the old one was destroyed (tab-out / rotate). Drained on the
    // game thread by PumpEvents, which invokes SurfaceRecreated so the host can rebind the
    // presentation surface to it. Attempts counts rebind retries for the same surface.
    private readonly ConcurrentQueue<(nint NativeWindow, int Width, int Height, int Attempts)> _surfaceQueue = new();
    private string _title = "Project I.G.I.";
    private int _width;
    private int _height;
    private bool _disposed;
    // Gyroscope look motion accumulated this frame, in radians (yaw, pitch).
    private float _gyroYaw;
    private float _gyroPitch;
    // Gamepad trigger axes as last reported (0..1), and whether L2/R2 also arrived as
    // key events (some pads report the triggers as buttons only): a key-held trigger
    // reads as fully pressed until its key-up arrives.
    private float _leftTriggerAxis;
    private float _rightTriggerAxis;
    private bool _leftTriggerKeyHeld;
    private bool _rightTriggerKeyHeld;

    public AndroidGameWindow(int initialWidth, int initialHeight)
    {
        _width = Math.Max(1, Math.Max(initialWidth, initialHeight));
        _height = Math.Max(1, Math.Min(initialWidth, initialHeight));
    }

    public event EventHandler<WindowResizedEventArgs>? Resized;
    public event EventHandler? CloseRequested;

    /// <summary>
    /// Invoked on the game thread when a new native window arrives after the old one was
    /// destroyed (tab-out / rotate). The host rebinds the presentation surface to it.
    /// Returns true when the rebind succeeded; false to retry the same surface.
    /// </summary>
    public Func<nint, int, int, bool>? SurfaceRecreated { get; set; }

    public string Title
    {
        get => _title;
        set => _title = value ?? string.Empty;
    }

    public int Width => _width;
    public int Height => _height;

    public WindowMode Mode { get; set; } = WindowMode.BorderlessFullscreen;
    public int RefreshRate => 60;
    public bool CursorVisible { get; set; }

    // 0 = 540p ultra, 1 = 720p performance, 2 = 900p balanced, 3 = native. Stored here, but the
    // resolution itself lives in the renderer's r_scale console variable: setting a tier sets
    // r_scale to that tier's height over this window's height, and r_scale is what the frame
    // actually renders at (RenderResolutionPolicy) and what survives a restart (archived CVar).
    // The 540p tier is for low-end phones: on a 720p display the 720p tier is native and buys
    // nothing, so the lowest tier has to render below the display.
    private int _renderScaleMode = 1;

    /// <summary>Gets or sets the render scale tier shown in Settings.</summary>
    public int RenderScaleMode
    {
        get => _renderScaleMode;
        set
        {
            _renderScaleMode = Math.Clamp(value, 0, 3);
            float height = _height > 0 ? _height : 1080f;
            ReconstructionCVars.RenderScale.Value = _renderScaleMode switch
            {
                0 => Math.Clamp(540f / height, 0.25f, 1f),
                1 => Math.Clamp(720f / height, 0.25f, 1f),
                2 => Math.Clamp(900f / height, 0.25f, 1f),
                _ => 1f,
            };
        }
    }

    /// <summary>Sets the tier that matches the render scale already in force (loaded from settings), so the menu shows the tier actually being rendered.</summary>
    public void SyncRenderScaleMode()
    {
        float height = _height > 0 ? _height : 1080f;
        float scale = ReconstructionCVars.RenderScale.Value;
        float tier0 = Math.Clamp(540f / height, 0.25f, 1f);
        float tier1 = Math.Clamp(720f / height, 0.25f, 1f);
        float tier2 = Math.Clamp(900f / height, 0.25f, 1f);
        float d0 = Math.Abs(scale - tier0);
        float d1 = Math.Abs(scale - tier1);
        float d2 = Math.Abs(scale - tier2);
        float d3 = Math.Abs(scale - 1f);
        _renderScaleMode = d0 <= d1 && d0 <= d2 && d0 <= d3 ? 0 : d1 <= d2 && d1 <= d3 ? 1 : d2 <= d3 ? 2 : 3;
    }

    public bool CursorLocked { get; set; }
    public string ClipboardText { get; set; } = string.Empty;
    public bool IsFocused => true;
    public bool IsClosing { get; private set; }

    public InputState Input { get; } = new();

    public IReadOnlyList<(int Width, int Height, int RefreshRate)> GetDisplayModes() =>
        [(Width, Height, RefreshRate)];

    public void Resize(int width, int height)
    {
        if (width <= 0 || height <= 0)
        {
            return;
        }

        int w = Math.Max(width, height);
        int h = Math.Min(width, height);

        _width = w;
        _height = h;
        Resized?.Invoke(this, new WindowResizedEventArgs(w, h));
    }

    public void Show() { }

    public void PumpEvents()
    {
        ObjectDisposedException.ThrowIf(_disposed, this);

        // Release a Return synthesized from a newline in typed text on the previous
        // pump before the shadow is taken, so a newline in this pump is still a fresh
        // rising edge for WasPressed: BeginFrame copies the current state into the
        // shadow, and releasing after it would leave the shadow holding the key down
        // and hide the next edge.
        if (_returnKeyDownFromText)
        {
            Input.Keyboard.SetKey(KeyCode.Return, false);
            _returnKeyDownFromText = false;
        }

        Input.BeginFrame();

        PumpSurfaceEvents();

        while (_eventQueue.TryDequeue(out AndroidInputEvent ev))
        {
            switch (ev.Kind)
            {
                case 0: // Touch
                    ApplyTouch(ev.Action, ev.IdOrKey, ev.X, ev.Y);
                    break;
                case 1: // Key
                    ApplyKey(ev.IdOrKey, ev.Action == 1);
                    break;
                case 2: // Resize
                    Resize((int)ev.X, (int)ev.Y);
                    break;
                case 3: // Gyro (angle deltas in radians: X = yaw, Y = pitch)
                    _gyroYaw += ev.X;
                    _gyroPitch += ev.Y;
                    break;
                case 5: // Gamepad axis (Action: 0=LeftStick, 1=RightStick, 2=Triggers)
                    ApplyGamepadAxis(ev.Action, ev.X, ev.Y);
                    break;
                case 6: // Gamepad connected/disconnected (Action: 0=Disconnected, 1=Connected)
                    if (ev.Action == 1)
                    {
                        Input.Gamepad.IsConnected = true;
                    }
                    else
                    {
                        // Disconnect clears every held button and stick, so nothing the
                        // pad was holding stays latched into the next frame.
                        Input.Gamepad.Reset();
                    }

                    break;
            }
        }

        // Typed text from a hardware keyboard, decoded by Android: feed the
        // platform's decoded-character queue, which the shell's focused TextBox
        // drains and the console reads. A newline is not a character the console
        // can use -- PromptEditor drops it -- so turn it into the Return press the
        // console's submit trigger reads (DeveloperConsole checks WasPressed(Return)).
        // The press is held until the next pump: a down+up in the same pump would
        // leave the key up before the console reads the edge.
        while (_textQueue.TryDequeue(out string? text))
        {
            foreach (char c in text)
            {
                if (c is '\n' or '\r')
                {
                    Input.Keyboard.SetKey(KeyCode.Return, true);
                    _returnKeyDownFromText = true;
                }
                else
                {
                    Input.Keyboard.EnqueueCharacter(c);
                }
            }
        }
    }

    /// <summary>
    /// Drains only the surface-recreated queue, without touching input. The host calls this
    /// at the top of the frame so a surface rebind is processed even while surfaceless.
    /// It must NOT call Input.BeginFrame or drain the input queue: that would clear the
    /// per-frame touch deltas and Began flags a second time and stutter the touch look.
    /// </summary>
    public void PumpSurfaceEvents()
    {
        ObjectDisposedException.ThrowIf(_disposed, this);

        // A new native window after the old one was destroyed (tab-out / rotate): rebind the
        // presentation surface to it on this (game) thread, since RHI calls must run on the
        // thread that created the device. A failed rebind is retried a few times (the surface
        // may not be ready yet); after that it stays lost and a restart recovers.
        while (_surfaceQueue.TryDequeue(out (nint NativeWindow, int Width, int Height, int Attempts) surface))
        {
            bool rebound = SurfaceRecreated?.Invoke(surface.NativeWindow, surface.Width, surface.Height) ?? false;
            if (!rebound && surface.Attempts < 3)
            {
                _surfaceQueue.Enqueue((surface.NativeWindow, surface.Width, surface.Height, surface.Attempts + 1));
            }
        }
    }

    /// <summary>Gets the gyroscope look motion accumulated this frame, in radians (yaw, pitch), and clears it.</summary>
    public (float Yaw, float Pitch) TakeGyroMotion()
    {
        (float Yaw, float Pitch) motion = (_gyroYaw, _gyroPitch);
        _gyroYaw = 0f;
        _gyroPitch = 0f;
        return motion;
    }

    private void ApplyTouch(int action, int pointerId, float x, float y)
    {
        switch (action)
        {
            case 0: // ACTION_DOWN
            case 5: // ACTION_POINTER_DOWN
                Input.Touch.Down(pointerId, x, y);
                break;
            case 2: // ACTION_MOVE
                Input.Touch.Move(pointerId, x, y);
                break;
            case 1: // ACTION_UP
            case 6: // ACTION_POINTER_UP
            case 3: // ACTION_CANCEL
                Input.Touch.Up(pointerId, x, y);
                break;
        }
    }

    private void ApplyKey(int keyCode, bool down)
    {
        // Gamepad buttons arrive here through the same onKeyDown/onKeyUp pipe as the
        // keyboard: Android delivers them as KeyEvents, so no second JNI entry is
        // needed for the buttons. KEYCODE_BUTTON_SELECT (109, the pad's Back/Select)
        // is deliberately NOT the Android system Back key (4): the pad's Back opens
        // the map computer, it never sends Escape.
        if (TryApplyGamepadButton(keyCode, down))
        {
            return;
        }

        if (keyCode == 4 || keyCode == (int)KeyCode.Escape)
        {
            Input.Keyboard.SetKey(KeyCode.Escape, down);
        }
        else if (keyCode == 67) // KEYCODE_DEL: the delete key
        {
            Input.Keyboard.SetKey(KeyCode.Backspace, down);
        }
        else if (keyCode == 68) // KEYCODE_GRAVE: the backtick key that toggles the dev console
        {
            Input.Keyboard.SetKey(KeyCode.Grave, down);
        }
        else if (keyCode == 66) // KEYCODE_ENTER: the Enter key that submits the dev console
        {
            Input.Keyboard.SetKey(KeyCode.Return, down);
        }
        else if (keyCode == 160) // KEYCODE_NUMPAD_ENTER
        {
            Input.Keyboard.SetKey(KeyCode.NumpadEnter, down);
        }
    }

    /// <summary>Maps an Android gamepad key code onto <see cref="GamepadState"/>, if it is one.</summary>
    /// <returns><see langword="true"/> when the code was a gamepad button and was consumed.</returns>
    private bool TryApplyGamepadButton(int keyCode, bool down)
    {
        GamepadButton? button = keyCode switch
        {
            96 => GamepadButton.South, // KEYCODE_BUTTON_A
            97 => GamepadButton.East, // KEYCODE_BUTTON_B
            99 => GamepadButton.West, // KEYCODE_BUTTON_X
            100 => GamepadButton.North, // KEYCODE_BUTTON_Y
            102 => GamepadButton.LeftShoulder, // KEYCODE_BUTTON_L1
            103 => GamepadButton.RightShoulder, // KEYCODE_BUTTON_R1
            106 => GamepadButton.LeftStick, // KEYCODE_BUTTON_THUMBL
            107 => GamepadButton.RightStick, // KEYCODE_BUTTON_THUMBR
            108 => GamepadButton.Start, // KEYCODE_BUTTON_START
            109 => GamepadButton.Back, // KEYCODE_BUTTON_SELECT
            19 => GamepadButton.DpadUp, // KEYCODE_DPAD_UP
            20 => GamepadButton.DpadDown, // KEYCODE_DPAD_DOWN
            21 => GamepadButton.DpadLeft, // KEYCODE_DPAD_LEFT
            22 => GamepadButton.DpadRight, // KEYCODE_DPAD_RIGHT
            _ => null,
        };

        if (button is { } padButton)
        {
            Input.Gamepad.SetButton(padButton, down);
            return true;
        }

        // L2/R2 (104/105) are analogue triggers on most pads and arrive as axes;
        // some pads report them as keys only, so a key-held trigger counts as fully
        // pressed. The axis path (ApplyGamepadAxis) reports the same state.
        if (keyCode == 104) // KEYCODE_BUTTON_L2
        {
            _leftTriggerKeyHeld = down;
            ApplyTriggers();
            return true;
        }

        if (keyCode == 105) // KEYCODE_BUTTON_R2
        {
            _rightTriggerKeyHeld = down;
            ApplyTriggers();
            return true;
        }

        return false;
    }

    private void ApplyGamepadAxis(int action, float x, float y)
    {
        switch (action)
        {
            case 0: // Left stick, -1..1, Y positive down
                Input.Gamepad.SetLeftStick(
                    Math.Clamp(x, -1f, 1f),
                    Math.Clamp(y, -1f, 1f));
                break;
            case 1: // Right stick, -1..1, Y positive down
                Input.Gamepad.SetRightStick(
                    Math.Clamp(x, -1f, 1f),
                    Math.Clamp(y, -1f, 1f));
                break;
            case 2: // Triggers, 0..1
                _leftTriggerAxis = Math.Clamp(x, 0f, 1f);
                _rightTriggerAxis = Math.Clamp(y, 0f, 1f);
                ApplyTriggers();
                break;
        }
    }

    private void ApplyTriggers() =>
        Input.Gamepad.SetTriggers(
            _leftTriggerKeyHeld ? 1f : _leftTriggerAxis,
            _rightTriggerKeyHeld ? 1f : _rightTriggerAxis);

    public void EnqueueTouch(int action, int pointerId, float x, float y)
    {
        _eventQueue.Enqueue(new AndroidInputEvent(0, action, pointerId, x, y));
    }

    public void EnqueueKey(int keyCode, bool down)
    {
        _eventQueue.Enqueue(new AndroidInputEvent(1, down ? 1 : 0, keyCode, 0f, 0f));
    }

    public void EnqueueGyro(float yawRadians, float pitchRadians)
    {
        _eventQueue.Enqueue(new AndroidInputEvent(3, 0, 0, yawRadians, pitchRadians));
    }

    /// <summary>Queues a gamepad's stick and trigger axes for the game thread (all -1..1 except the triggers, 0..1).</summary>
    public void EnqueueGamepadAxis(float leftX, float leftY, float rightX, float rightY, float leftTrigger, float rightTrigger)
    {
        _eventQueue.Enqueue(new AndroidInputEvent(5, 0, 0, leftX, leftY));
        _eventQueue.Enqueue(new AndroidInputEvent(5, 1, 0, rightX, rightY));
        _eventQueue.Enqueue(new AndroidInputEvent(5, 2, 0, leftTrigger, rightTrigger));
    }

    /// <summary>Queues a gamepad connect/disconnect for the game thread.</summary>
    public void EnqueueGamepadConnected(bool connected)
    {
        _eventQueue.Enqueue(new AndroidInputEvent(6, connected ? 1 : 0, 0, 0f, 0f));
    }

    public void EnqueueText(string text)
    {
        _textQueue.Enqueue(text);
    }

    public void EnqueueResize(int width, int height)
    {
        _eventQueue.Enqueue(new AndroidInputEvent(2, 0, 0, width, height));
    }

    /// <summary>Queues a new native window (after the old one was destroyed) for PumpEvents.</summary>
    public void EnqueueSurfaceRecreated(nint nativeWindow, int width, int height)
    {
        _surfaceQueue.Enqueue((nativeWindow, width, height, 0));
    }

    public void Close()
    {
        if (!_disposed && !IsClosing)
        {
            IsClosing = true;
            CloseRequested?.Invoke(this, EventArgs.Empty);
        }
    }

    public void Dispose()
    {
        _disposed = true;
    }
}
