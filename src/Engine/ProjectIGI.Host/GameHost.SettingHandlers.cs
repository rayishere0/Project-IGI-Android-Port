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

    /// <summary>Opens the offscreen path exactly while something needs it — motion blur, sun shadows, a sub-native render scale or dynamic resolution — and closes it when none of them do.</summary>
    /// <remarks>
    /// The blur is the only effect that used to need the capture: the Vanilla preset holds r_hdr and
    /// r_deferred at 0, so the frame is drawn straight to the back buffer and the resolve — blur and
    /// gamma with it — never runs. The two capture flags follow the blur rather than the preset, so
    /// turning the blur on opens the path and turning it off returns to the direct path; nothing else
    /// changes. The entry shot's own blur override does not reach this: Override and ClearOverride
    /// raise no Changed event, so the shot's authored smear only runs while the player already has
    /// blur on. With blur off it stays off, as it is today.
    /// <para>
    /// Shadows are the second effect that needs the capture, and they share these same two flags — so
    /// this one function derives them from both settings instead of each setting owning a handler that
    /// would switch the flags off under the other. The shadow cascades are fitted only while the capture
    /// is open (see FitSunShadows), and the shadow term is sampled only by the deferred shading pass.
    /// </para>
    /// <para>
    /// A render scale below native is the third thing that needs the capture, and dynamic resolution
    /// the fourth: the direct path draws straight to the back buffer at the window's size, so without
    /// the capture the Resolution Quality tier — and the retail Resolution list, which sets the same
    /// scale — change nothing the player can see, and the first-run 720p tier on Android renders at
    /// native. The dynamic ladder only moves the effective scale, which the direct path never reads,
    /// so with the path closed the ladder is dead too. Neither promotes the lighting model or turns
    /// on the real-time structures: the capture opens with the lighting the player already has. The
    /// manual tier stays the ceiling — the ladder never renders above it — and the archived render
    /// scale is never written by either.
    /// </para>
    /// <para>
    /// Shadows also promote the lighting model to hybrid while they are on, and back to baked when they
    /// go off: the baked branch returns before any shadow is sampled, so a shadow with the model left
    /// baked would fill a map nobody reads. Hybrid adds the shadowed live sun on top of the bakes and
    /// never touches the baked term itself. The promotion is honoured only once the real-time structures
    /// are Ready (see GlobalIllumination.EffectiveLighting), and those build only while r_cards and
    /// r_sdf are on — both Vanilla-off — so this turns those on too while shadows are on, and takes them
    /// back off with the model. Until they are Ready the frame stays baked and the shadows are simply
    /// not there yet; nothing goes wrong, only late. The one-long-frame surface-cache capture and the
    /// distance-field bake are the honest price of the switch, and the first shadowed frame is where
    /// they are paid.
    /// </para>
    /// <para>
    /// The shadow choice is read through StoredValue, not Value: the menu backdrop's lite profile holds
    /// r_shadows at 0 through an override while the menu is up, and an override raises no Changed event
    /// and leaves the stored value alone — so Value reads 0 behind the menu even for a player who has
    /// shadows on. Reading Value here would undo a shadows-on choice the moment it was made from the
    /// menu, and nothing would re-derive it when Play clears the override. The lighting model is
    /// likewise compared through StoredValue, for the same reason. The unwind takes back a stored
    /// hybrid — on Android the shadows row is the only path to hybrid, so that is the hybrid this
    /// handler promoted. A Dynamic the player chose through the console keeps its model and its
    /// structures.
    /// </para>
    /// </remarks>
    private static void ApplyCapturePath()
    {
        bool shadowsOn = ShadowCVars.Shadows.StoredValue > 0;
        bool effectsOn = shadowsOn || PostCVars.MotionBlur.Value > 0f;

        // A sub-native render scale, or dynamic resolution on: both need the capture for the
        // reasons the remarks give. Read through StoredValue, as the shadows read is: no override
        // holds either today, and the stored choice is the player's own either way.
        bool scaleNeedsCapture = ReconstructionCVars.RenderScale.StoredValue < 1f
            || ReconstructionCVars.DynamicResolution.StoredValue;
        bool on = effectsOn || scaleNeedsCapture;
        FrameCVars.OffscreenScene.Value = on;
        LightingCVars.Deferred.Value = on;

        if (shadowsOn)
        {
            if (LightingCVars.Lighting.StoredValue == LightingModel.Baked)
            {
                LightingCVars.Lighting.Value = LightingModel.Hybrid;
            }

            SurfaceCacheCVars.SurfaceCache.Value = true;
            RayTracingCVars.DistanceFields.Value = true;
        }
        else if (LightingCVars.Lighting.StoredValue == LightingModel.Hybrid)
        {
            LightingCVars.Lighting.Value = LightingModel.Baked;
            SurfaceCacheCVars.SurfaceCache.Value = false;
            RayTracingCVars.DistanceFields.Value = false;
        }
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
