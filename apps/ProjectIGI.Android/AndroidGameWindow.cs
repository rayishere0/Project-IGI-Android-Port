using System.Collections.Concurrent;
using ProjectIGI.Input;
using ProjectIGI.Platform;
using ProjectIGI.Rendering;

namespace ProjectIGI.Android;

internal readonly record struct AndroidInputEvent(
    int Kind, // 0 = Touch, 1 = Key, 2 = Resize, 3 = Gyro
    int Action, // For Touch: 0=Down, 1=Up, 2=Move, 3=Cancel. For Key: 0=Up, 1=Down
    int IdOrKey,
    float X,
    float Y);

public sealed class AndroidGameWindow : IGameWindow
{
    private readonly ConcurrentQueue<AndroidInputEvent> _eventQueue = new();
    private readonly ConcurrentQueue<string> _textQueue = new();
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
            }
        }

        // Typed text from the Android soft keyboard (hidden EditText): feed the
        // platform's decoded-character queue, which the shell's focused TextBox drains.
        while (_textQueue.TryDequeue(out string? text))
        {
            foreach (char c in text)
            {
                Input.Keyboard.EnqueueCharacter(c);
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
        if (keyCode == 4 || keyCode == (int)KeyCode.Escape)
        {
            Input.Keyboard.SetKey(KeyCode.Escape, down);
        }
        else if (keyCode == 67) // KEYCODE_DEL: the soft keyboard's delete key
        {
            Input.Keyboard.SetKey(KeyCode.Backspace, down);
        }
    }

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
