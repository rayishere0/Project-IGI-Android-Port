using System.Collections.Concurrent;
using ProjectIGI.Input;
using ProjectIGI.Platform;

namespace ProjectIGI.Android;

internal readonly record struct AndroidInputEvent(
    int Kind, // 0 = Touch, 1 = Key, 2 = Resize
    int Action, // For Touch: 0=Down, 1=Up, 2=Move, 3=Cancel. For Key: 0=Up, 1=Down
    int IdOrKey,
    float X,
    float Y);

public sealed class AndroidGameWindow : IGameWindow
{
    private readonly ConcurrentQueue<AndroidInputEvent> _eventQueue = new();
    private string _title = "Project I.G.I.";
    private int _width;
    private int _height;
    private bool _disposed;

    public AndroidGameWindow(int initialWidth, int initialHeight)
    {
        _width = Math.Max(1, Math.Max(initialWidth, initialHeight));
        _height = Math.Max(1, Math.Min(initialWidth, initialHeight));
    }

    public event EventHandler<WindowResizedEventArgs>? Resized;
    public event EventHandler? CloseRequested;

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
    public int RenderScaleMode { get; set; } = 2;
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
            }
        }
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
    }

    public void EnqueueTouch(int action, int pointerId, float x, float y)
    {
        _eventQueue.Enqueue(new AndroidInputEvent(0, action, pointerId, x, y));
    }

    public void EnqueueKey(int keyCode, bool down)
    {
        _eventQueue.Enqueue(new AndroidInputEvent(1, down ? 1 : 0, keyCode, 0f, 0f));
    }

    public void EnqueueResize(int width, int height)
    {
        _eventQueue.Enqueue(new AndroidInputEvent(2, 0, 0, width, height));
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
