using ProjectIGI.Rendering;

namespace ProjectIGI.Frontend;

/// <summary>
/// What the shell asks of the application it runs inside: starting a mission, quitting, previewing a
/// mission behind the menu, and persisting settings.
/// </summary>
/// <remarks>
/// The shell is backend-free and holds no window, device or game loop, so everything that needs those
/// goes through this seam, which the desktop composition root implements. It is the same shape as the
/// existing menu host's <c>StartGame</c>/quit hooks, widened for the cinematic shell's needs.
/// </remarks>
public interface IShellHost
{
    /// <summary>Leaves the shell and starts a mission at a difficulty.</summary>
    /// <param name="missionId">The mission to start.</param>
    /// <param name="difficulty">The difficulty index to start at.</param>
    void StartMission(int missionId, int difficulty);

    /// <summary>Sets the conditions the campaign is played under, from this mission onwards.</summary>
    /// <param name="conditions">The hour missions open at and the weather they are played in.</param>
    /// <remarks>
    /// Separate from <see cref="StartMission"/> because the choice outlives the mission it was made
    /// beside: it is the campaign's, and the app holds it until the player changes it again. Told as it
    /// is chosen rather than on the way into a level so that the mission previewed behind the menu can
    /// show the hour the player has just asked for.
    /// </remarks>
    void SetMissionConditions(MissionConditions conditions);

    /// <summary>Closes the pause menu and lets the mission underneath run on.</summary>
    /// <remarks>
    /// The pause menu is the shell drawn over a level that is still loaded and simply not being ticked, so
    /// resuming is the app dropping the menu — nothing is reloaded and nothing is placed again.
    /// </remarks>
    void ResumeMission();

    /// <summary>Restarts the mission the pause menu is open over, from its beginning.</summary>
    void RestartMission();

    /// <summary>Abandons the mission the pause menu is open over and returns the shell to the front end.</summary>
    void AbandonMission();

    /// <summary>Closes the game.</summary>
    void Quit();

    /// <summary>Asks the app to run a different game.</summary>
    /// <param name="titleId">The title's id, as <c>GameTitle.Id</c> gives it.</param>
    /// <returns><see langword="false"/> when nothing will happen — it is already running, or not installed.</returns>
    /// <remarks>
    /// The shell says which game the player picked and nothing more. Whether it can be run, when the
    /// swap actually happens and what has to be torn down first are all the app's, and the swap does not
    /// take effect on this call: the app takes it up at a frame boundary, because the shell asking for
    /// it is itself being drawn out of the things a switch replaces.
    /// </remarks>
    bool SwitchTitle(string titleId);

    /// <summary>Asks the app to show a mission's level behind the menu, or none.</summary>
    /// <param name="missionId">The mission to preview, or <see langword="null"/> to show the default showcase.</param>
    /// <remarks>
    /// The app streams the level on a worker thread and moves the showcase camera to it; the shell only
    /// says which mission the player is looking at. Called as the campaign selection changes.
    /// </remarks>
    void PreviewMission(int? missionId);

    /// <summary>Persists the current settings (the CVar archive), e.g. on leaving the settings screen.</summary>
    void SaveSettings();

    /// <summary>Puts the shell away and returns to the title's own retail main menu.</summary>
    /// <remarks>
    /// For settings opened from the retail menu: the shell was only ever drawn over it, so closing
    /// the settings means the app drops menu mode and the retail menu is on screen again. A host
    /// with no retail menus has nothing to return to and leaves this a no-op.
    /// </remarks>
    void ReturnToRetailMenu() { }

    /// <summary>Persists player profiles and their profile-bound progress immediately.</summary>
    void SaveProfiles();

    /// <summary>Enters the interactive drag-and-drop HUD on-screen controls customizer.</summary>
    void CustomizeTouchControls() { }

    /// <summary>Gets or sets the on-screen touch controls opacity.</summary>
    float TouchOpacity { get => 0.75f; set { } }

    /// <summary>Gets or sets the general touch sensitivity multiplier for swipe look and stick movement.</summary>
    float TouchSensitivity { get => 1.0f; set { } }

    /// <summary>Gets or sets the internal graphics rendering scale (0 = Performance 720p, 1 = Balanced 900p, 2 = Native).</summary>
    int RenderScaleMode { get => 0; set { } }

    /// <summary>Names a control for the current title, or returns null when that control belongs to another title.</summary>
    /// <param name="action">The stored profile action.</param>
    /// <returns>The visible label, or null.</returns>
    string? InputBindingLabel(string action) => action;

    /// <summary>Restores the active title's control defaults.</summary>
    /// <param name="profile">The profile being edited.</param>
    void ResetInputBindings(ProjectIGI.Game.Config.PlayerProfile profile) => profile.ResetBindingsToDefaults();

    /// <summary>Gets the running mission's own save games, for a title that keeps them, or <see langword="null"/>.</summary>
    ProjectIGI.Game.Player.ITitleSaveGames? MissionSaves => null;

    /// <summary>Gets the mods that change play the running title is played with, which a save slot records.</summary>
    IReadOnlyList<ProjectIGI.Core.Content.ModReference> PlayedMods => [];

    /// <summary>One content layer as the settings screen shows it: a pack (or folder) and what it holds.</summary>
    /// <param name="Id">The layer's id, as the profile and the console name it.</param>
    /// <param name="Name">What the player sees it called.</param>
    /// <param name="Kind">pack, local, directory, dev, mod or legacy.</param>
    /// <param name="Enabled">Whether it takes part.</param>
    /// <param name="Files">How many paths the layer holds.</param>
    /// <param name="Wins">How many of those paths this layer supplies.</param>
    public sealed record ContentLayerRow(string Id, string Name, string Kind, bool Enabled, int Files, int Wins);

    /// <summary>Whether this host can manage content packs at all.</summary>
    /// <remarks>
    /// The desktop launcher owns the Content page there, so a host that has no profile to write answers
    /// no; the Android host answers yes, because the launcher hands it the profile and nothing else does.
    /// </remarks>
    bool ContentSupported => false;

    /// <summary>Gets the content layers for the running title, highest priority first.</summary>
    IReadOnlyList<ContentLayerRow> ContentLayers() => [];

    /// <summary>Switches one content layer on or off, live, and saves the choice in the profile.</summary>
    /// <param name="id">The layer's id.</param>
    /// <param name="enabled">Whether it should take part.</param>
    /// <returns>A sentence on what changed, for the settings screen.</returns>
    string SetContentLayerEnabled(string id, bool enabled) => string.Empty;

    /// <summary>Moves one content layer up (towards winning) or down in the load order, live, and saves it.</summary>
    /// <param name="id">The layer's id.</param>
    /// <param name="up">Whether it moves towards the top.</param>
    /// <returns>A sentence on what changed, for the settings screen.</returns>
    string MoveContentLayer(string id, bool up) => string.Empty;

    /// <summary>Gets the paths more than one enabled layer carries, as "path — winner wins over ..." lines.</summary>
    IReadOnlyList<string> ContentConflicts() => [];

    /// <summary>Gets or sets whether every content layer is bypassed (the touch equivalent of F8).</summary>
    /// <remarks>
    /// The comparison switch, not a deletion: the packs stay installed and switched on, and turning it
    /// back off restores them. It is the <c>r_overrides</c> variable, which is not saved, so a relaunch
    /// always starts with the packs on — a pack that breaks the menu is recovered from the launcher instead.
    /// </remarks>
    bool ContentBypassed { get => false; set { } }

    /// <summary>Re-reads the content folders from disk and reloads what changed.</summary>
    /// <returns>A sentence on what changed, for the settings screen.</returns>
    string RescanContent() => string.Empty;

    /// <summary>Gets where the content profile lives, or <see langword="null"/> when no profile is in force.</summary>
    string? ContentProfilePath => null;

    /// <summary>Captures the current frame for a save-slot thumbnail.</summary>
    /// <param name="width">Receives the capture width.</param>
    /// <param name="height">Receives the capture height.</param>
    /// <returns>The captured pixels, or an empty array when no capture is available.</returns>
    ProjectIGI.Core.Graphics.Bgra32[] CaptureThumbnail(out int width, out int height);

    /// <summary>Says why a setting cannot take effect on this machine, or nothing when it can.</summary>
    /// <param name="variable">The console variable the setting's row drives.</param>
    /// <returns>The reason, for the row's tooltip; empty when the setting works here.</returns>
    /// <remarks>
    /// For the settings that depend on hardware or an optional download -- NVIDIA's features -- and for the
    /// ones another setting takes over, such as the render scale while DLSS chooses the render size. The
    /// row stays visible and is greyed out, so the player learns the option exists and what it needs.
    /// </remarks>
    string SettingUnavailable(string variable) => string.Empty;

    /// <summary>Lists the resolutions the display the game is on offers, largest first.</summary>
    /// <returns>The sizes; empty where the host cannot say, and the settings page then offers only the desktop's.</returns>
    IReadOnlyList<(int Width, int Height)> DisplayResolutions() => [];
}
