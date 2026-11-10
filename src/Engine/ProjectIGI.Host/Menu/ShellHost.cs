using ProjectIGI.Core.Graphics;
using ProjectIGI.Frontend;
using ProjectIGI.Rendering;

namespace ProjectIGI.Host.Menu;

/// <summary>
/// The desktop composition root's side of the cinematic shell: it turns the shell's requests into calls
/// on the game loop, the device and the console.
/// </summary>
/// <remarks>
/// The shell is backend-free, so everything it cannot do itself — leaving the menu into a mission,
/// previewing a level behind the menu, capturing a save thumbnail, quitting, persisting settings — is a
/// delegate the composition root supplies here. This is the same pattern as <c>MenuHost</c>'s
/// <c>StartGame</c>/quit hooks, made into a full <see cref="IShellHost"/>.
/// </remarks>
/// <param name="startMission">Starts a mission at a difficulty and leaves the shell.</param>
/// <param name="setMissionConditions">Sets the hour and weather the campaign is played under.</param>
/// <param name="resumeMission">Closes the pause shell over the current mission.</param>
/// <param name="restartMission">Reloads the current mission from its authored start.</param>
/// <param name="abandonMission">Releases the current mission and returns to the campaign shell.</param>
/// <param name="quit">Closes the game.</param>
/// <param name="switchTitle">Runs a different game; false when it cannot be run.</param>
/// <param name="previewMission">Shows a mission's level behind the menu, or the default showcase when null.</param>
/// <param name="saveSettings">Persists the current settings.</param>
/// <param name="saveProfiles">Persists player profiles and their progress.</param>
/// <param name="captureThumbnail">Captures the current frame as save-thumbnail pixels.</param>
/// <param name="settingUnavailable">Why a setting cannot take effect here, or empty when it can.</param>
/// <param name="missionSaves">The running mission's own save games, or <see langword="null"/>.</param>
/// <param name="inputBindingLabel">The active title's visible control labels.</param>
/// <param name="resetInputBindings">Restores the active title's control defaults.</param>
/// <param name="displayResolutions">The resolutions the display offers, largest first.</param>
/// <param name="playedMods">The mods that change play the running title is played with.</param>
/// <param name="customizeTouchControls">Enters HUD customization mode.</param>
/// <param name="getTouchOpacity">Gets current HUD opacity.</param>
/// <param name="setTouchOpacity">Sets current HUD opacity.</param>
/// <param name="getRenderScale">Gets current render scale mode.</param>
/// <param name="setRenderScale">Sets current render scale mode.</param>
/// <param name="getTouchSensitivity">Gets current touch sensitivity.</param>
/// <param name="setTouchSensitivity">Sets current touch sensitivity.</param>
/// <param name="contentSupported">Whether this host manages content packs.</param>
/// <param name="contentLayers">The content layers for the running title, highest priority first.</param>
/// <param name="setContentLayerEnabled">Switches one content layer on or off, live, and saves it.</param>
/// <param name="moveContentLayer">Moves one content layer up or down in the load order, live, and saves it.</param>
/// <param name="contentConflicts">The paths more than one enabled layer carries, as display lines.</param>
/// <param name="getContentBypassed">Gets whether every content layer is bypassed.</param>
/// <param name="setContentBypassed">Sets whether every content layer is bypassed.</param>
/// <param name="rescanContent">Re-reads the content folders from disk and reloads what changed.</param>
/// <param name="contentProfilePath">Where the content profile lives, or null when none is in force.</param>
/// <param name="returnToRetailMenu">Puts the shell away and returns to the title's own retail main menu.</param>
public sealed class ShellHost(
    Action<int, int> startMission,
    Action<MissionConditions> setMissionConditions,
    Action resumeMission,
    Action restartMission,
    Action abandonMission,
    Action quit,
    Func<string, bool> switchTitle,
    Action<int?> previewMission,
    Action saveSettings,
    Action saveProfiles,
    CaptureThumbnail captureThumbnail,
    Func<string, string>? settingUnavailable = null,
    Func<ProjectIGI.Game.Player.ITitleSaveGames?>? missionSaves = null,
    Func<string, string?>? inputBindingLabel = null,
    Action<ProjectIGI.Game.Config.PlayerProfile>? resetInputBindings = null,
    Func<IReadOnlyList<(int Width, int Height)>>? displayResolutions = null,
    Func<IReadOnlyList<ProjectIGI.Core.Content.ModReference>>? playedMods = null,
    Action? customizeTouchControls = null,
    Func<float>? getTouchOpacity = null,
    Action<float>? setTouchOpacity = null,
    Func<int>? getRenderScale = null,
    Action<int>? setRenderScale = null,
    Func<float>? getTouchSensitivity = null,
    Action<float>? setTouchSensitivity = null,
    Func<bool>? contentSupported = null,
    Func<IReadOnlyList<IShellHost.ContentLayerRow>>? contentLayers = null,
    Func<string, bool, string>? setContentLayerEnabled = null,
    Func<string, bool, string>? moveContentLayer = null,
    Func<IReadOnlyList<string>>? contentConflicts = null,
    Func<bool>? getContentBypassed = null,
    Action<bool>? setContentBypassed = null,
    Func<string>? rescanContent = null,
    Func<string?>? contentProfilePath = null,
    Action? returnToRetailMenu = null) : IShellHost
{
    /// <inheritdoc/>
    public void CustomizeTouchControls() => customizeTouchControls?.Invoke();

    /// <inheritdoc/>
    public float TouchOpacity
    {
        get => getTouchOpacity?.Invoke() ?? 0.75f;
        set => setTouchOpacity?.Invoke(value);
    }

    /// <inheritdoc/>
    public float TouchSensitivity
    {
        get => getTouchSensitivity?.Invoke() ?? 1.0f;
        set => setTouchSensitivity?.Invoke(value);
    }

    /// <inheritdoc/>
    public int RenderScaleMode
    {
        get => getRenderScale?.Invoke() ?? 0;
        set => setRenderScale?.Invoke(value);
    }
    /// <inheritdoc/>
    public IReadOnlyList<ProjectIGI.Core.Content.ModReference> PlayedMods => playedMods?.Invoke() ?? [];

    /// <inheritdoc/>
    public bool ContentSupported => contentSupported?.Invoke() ?? false;

    /// <inheritdoc/>
    public IReadOnlyList<IShellHost.ContentLayerRow> ContentLayers() => contentLayers?.Invoke() ?? [];

    /// <inheritdoc/>
    public string SetContentLayerEnabled(string id, bool enabled) => setContentLayerEnabled?.Invoke(id, enabled) ?? string.Empty;

    /// <inheritdoc/>
    public string MoveContentLayer(string id, bool up) => moveContentLayer?.Invoke(id, up) ?? string.Empty;

    /// <inheritdoc/>
    public IReadOnlyList<string> ContentConflicts() => contentConflicts?.Invoke() ?? [];

    /// <inheritdoc/>
    public bool ContentBypassed
    {
        get => getContentBypassed?.Invoke() ?? false;
        set => setContentBypassed?.Invoke(value);
    }

    /// <inheritdoc/>
    public string RescanContent() => rescanContent?.Invoke() ?? string.Empty;

    /// <inheritdoc/>
    public string? ContentProfilePath => contentProfilePath?.Invoke();

    /// <inheritdoc/>
    public ProjectIGI.Game.Player.ITitleSaveGames? MissionSaves => missionSaves?.Invoke();

    /// <inheritdoc/>
    public void StartMission(int missionId, int difficulty) => startMission(missionId, difficulty);

    /// <inheritdoc/>
    public void SetMissionConditions(MissionConditions conditions) => setMissionConditions(conditions);

    /// <inheritdoc/>
    public void ResumeMission() => resumeMission();

    /// <inheritdoc/>
    public void RestartMission() => restartMission();

    /// <inheritdoc/>
    public void AbandonMission() => abandonMission();

    /// <inheritdoc/>
    public bool SwitchTitle(string titleId) => switchTitle(titleId);

    /// <inheritdoc/>
    public void Quit() => quit();

    /// <inheritdoc/>
    public void PreviewMission(int? missionId) => previewMission(missionId);

    /// <inheritdoc/>
    public void SaveSettings() => saveSettings();

    /// <inheritdoc/>
    public void ReturnToRetailMenu() => returnToRetailMenu?.Invoke();

    /// <inheritdoc/>
    public void SaveProfiles() => saveProfiles();

    /// <inheritdoc/>
    public string? InputBindingLabel(string action) => inputBindingLabel is { } label ? label(action) : action;

    /// <inheritdoc/>
    public void ResetInputBindings(ProjectIGI.Game.Config.PlayerProfile profile)
    {
        if (resetInputBindings is { } reset) { reset(profile); }
        else { profile.ResetBindingsToDefaults(); }
    }

    /// <inheritdoc/>
    public Bgra32[] CaptureThumbnail(out int width, out int height) => captureThumbnail(out width, out height);

    /// <inheritdoc/>
    public string SettingUnavailable(string variable) => settingUnavailable?.Invoke(variable) ?? string.Empty;

    /// <inheritdoc/>
    public IReadOnlyList<(int Width, int Height)> DisplayResolutions() => displayResolutions?.Invoke() ?? [];
}

/// <summary>Captures the current frame for a save-slot thumbnail.</summary>
/// <param name="width">Receives the capture width.</param>
/// <param name="height">Receives the capture height.</param>
/// <returns>The captured pixels, or an empty array when no capture is available.</returns>
public delegate Bgra32[] CaptureThumbnail(out int width, out int height);
