using ProjectIGI.Core.Configuration;
using ProjectIGI.Rendering;

namespace ProjectIGI.Host;

/// <summary>What the game does when a setting changes, and taking that back when the game ends.</summary>
public sealed partial class GameHost
{
    // Every handler this game put on a setting. The settings belong to the process, not to the game, so a
    // handler left on one outlives it: after F10 built a second game, changing the preset still ran the
    // first one's, which called its disposed renderer and brought the process down.
    private readonly List<(ICVar Variable, EventHandler<CVarChangedEventArgs> Handler)> _settingHandlers = [];

    /// <summary>Runs something whenever a setting changes, for as long as this game runs.</summary>
    /// <param name="variable">The setting.</param>
    /// <param name="handler">What to do.</param>
    private void WhenChanged(ICVar variable, Action handler)
    {
        EventHandler<CVarChangedEventArgs> subscription = (_, _) => handler();
        variable.Changed += subscription;
        _settingHandlers.Add((variable, subscription));
    }

    /// <summary>Opens the offscreen path exactly while motion blur is on, and closes it when it is off.</summary>
    /// <remarks>
    /// The blur is the only effect that needs the capture: the Vanilla preset holds r_hdr and
    /// r_deferred at 0, so the frame is drawn straight to the back buffer and the resolve — blur and
    /// gamma with it — never runs. The two capture flags follow the blur rather than the preset, so
    /// turning the blur on opens the path and turning it off returns to the direct path; nothing else
    /// changes. The lighting stays baked, so no other deferred effect wakes up: shadows need
    /// r_shadows above 0, the screen gather needs its own variable above 0, and both sit at 0 under
    /// Vanilla. The entry shot's own blur override does not reach this: Override and ClearOverride
    /// raise no Changed event, so the shot's authored smear only runs while the player already has
    /// blur on. With blur off it stays off, as it is today.
    /// </remarks>
    private static void ApplyMotionBlurCapture()
    {
        bool on = PostCVars.MotionBlur.Value > 0f;
        FrameCVars.OffscreenScene.Value = on;
        LightingCVars.Deferred.Value = on;
    }

    /// <summary>Takes every handler this game put on a setting back off it.</summary>
    private void ReleaseSettingHandlers()
    {
        foreach ((ICVar variable, EventHandler<CVarChangedEventArgs> handler) in _settingHandlers)
        {
            variable.Changed -= handler;
        }

        _settingHandlers.Clear();
    }
}
