using ProjectIGI.Platform;
using ProjectIGI.Platform.Desktop;

namespace ProjectIGI.Android;

public sealed class AndroidPlatformHost : IPlatformHost
{
    private readonly AndroidGameWindow _window;

    public AndroidPlatformHost(AndroidGameWindow window)
    {
        ArgumentNullException.ThrowIfNull(window);
        _window = window;
    }

    public string Name => "Android";

    public IGameWindow CreateWindow(in WindowSettings settings) => _window;

    public IFramePacer CreateFramePacer() => new DesktopFramePacer();
}

