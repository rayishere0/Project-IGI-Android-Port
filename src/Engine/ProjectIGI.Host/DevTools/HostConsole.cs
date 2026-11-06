using System.Diagnostics;
using ProjectIGI.Core.Configuration;
using ProjectIGI.Core.Configuration.Presets;
using ProjectIGI.Engine.Vfs;
using ProjectIGI.Game.Player;
using ProjectIGI.Input;
using ProjectIGI.Rendering;

namespace ProjectIGI.Host.DevTools;

/// <summary>
/// The desktop shell's console: the registry, the command set, the settings file and the on-screen view.
/// </summary>
/// <remarks>
/// <para>
/// Composed once at start-up. The order matters and is the order the plan calls for: declarations are
/// forced to register, then <c>settings.cfg</c> is applied over the defaults, then the command line's
/// <c>+</c> statements are applied over that. So a command line always wins for the session, and what
/// it put in place is what gets saved — which is what a player switching to <c>+gfx_preset ultra</c>
/// once and then never passing it again expects.
/// </para>
/// <para>
/// Everything the game writes to the console is mirrored into the scrollback, so
/// opening the console shows the log rather than an empty panel.
/// </para>
/// </remarks>
public sealed class HostConsole : IDisposable
{

    private readonly Action<ConsoleLine> _writeLine;
    private readonly string _settingsPath;
    private readonly DeveloperConsole _view;
    private bool _disposed;

    // Seconds since this process started, for stamping console lines. The offset aligns the
    // stopwatch with the process start time, so the clock reads from process start rather than
    // from when this class first loaded.
    private static readonly long ClockStart = Stopwatch.GetTimestamp();
    private static readonly double ClockOffset = Math.Max(0.0, (DateTimeOffset.Now - Process.GetCurrentProcess().StartTime).TotalSeconds);
    private static double ElapsedSeconds => ClockOffset + Stopwatch.GetElapsedTime(ClockStart).TotalSeconds;

    /// <summary>Initialises a new instance of the <see cref="HostConsole"/> class.</summary>
    /// <param name="device">The device the console's font is uploaded to.</param>
    /// <param name="logger">Where to report what the console does.</param>
    /// <exception cref="ArgumentNullException"><paramref name="device"/> is <see langword="null"/>.</exception>
    public HostConsole(IGraphicsDevice device)
    {
        ArgumentNullException.ThrowIfNull(device);

        _settingsPath = SettingsPaths.GetSettingsPath();

        System = new ConsoleSystem();
        Model = new ConsoleModel(System);
        _writeLine = System.Write;
        _view = new DeveloperConsole(device, Model);

        // Console lines are stamped in seconds since the process started, so a command's output and
        // the startup it follows read as one timeline.
        System.Clock = static () => ElapsedSeconds;

        string configDirectory = Path.GetDirectoryName(_settingsPath) ?? SettingsPaths.PortableDirectory;
        BuiltInConsoleCommands.Register(System, new DirectoryConsoleFileSystem(configDirectory));
        GraphicsPresetCommands.Register(System);
        PlayerCheatCVars.CheatsEnabled.Changed += OnCheatsEnabledChanged;
        System.CheatsEnabled = PlayerCheatCVars.CheatsEnabled.Value;
        RegisterShellCommands();

        // Registered here rather than when the view loads, so a settings file or a +command naming a
        // panel is understood -- both run before there is a display to show one on.
        _view.RegisterCommands(System);
    }

    /// <summary>Occurs when a console command has asked the game to quit.</summary>
    public event EventHandler? QuitRequested;

    /// <summary>Gets the console the registry and commands live on.</summary>
    public ConsoleSystem System { get; }

    /// <summary>Gets the on-screen console's state.</summary>
    public ConsoleModel Model { get; }

    /// <summary>Gets the on-screen view: the floating panels, their input and their drawing.</summary>
    public DeveloperConsole View => _view;

    /// <summary>Gets a value indicating whether the console is showing and consuming input.</summary>
    public bool IsOpen => Model.IsOpen;

    /// <summary>Gets the full path of the settings file this console reads and writes.</summary>
    public string SettingsPath => _settingsPath;

    /// <summary>
    /// Brings the console up: registers every declaration, applies the settings file, then the command line.
    /// </summary>
    /// <param name="fileSystem">Where the console's font is read from.</param>
    /// <param name="startupCommands">The <c>+</c> statements from the command line.</param>
    /// <param name="useSavedSettings">
    /// Whether <c>settings.cfg</c> is read and written. A capture run passes <see langword="false"/> —
    /// see <see cref="IsolatedFromSavedSettings"/>.
    /// </param>
    /// <param name="firstRunPreset">The graphics preset applied when there are no saved settings.</param>
    /// <param name="lockedPreset">
    /// The one graphics preset this build allows, applied over whatever was saved, or <see langword="null"/>
    /// to let the player choose. See <see cref="GraphicsPresetRegistry.LockedPreset"/>.
    /// </param>
    /// <exception cref="ArgumentNullException"><paramref name="fileSystem"/> is <see langword="null"/>.</exception>
    public void Start(
        VirtualFileSystem fileSystem,
        IReadOnlyList<string>? startupCommands = null,
        bool useSavedSettings = true,
        GraphicsPreset firstRunPreset = GraphicsPreset.Enhanced,
        GraphicsPreset? lockedPreset = null)
    {
        ArgumentNullException.ThrowIfNull(fileSystem);

        IsolatedFromSavedSettings = !useSavedSettings;

        // Static field initialisers only run when something touches the declaring class, so the
        // generated registrations are what make the registry complete before settings are read. Both
        // assemblies matter: the console's own con_* variables live here, and without this call a
        // saved layout line would be met with "unknown variable" and silently discarded.
        Rendering.Generated.CVarRegistrations.RegisterAll();
        Game.Generated.CVarRegistrations.RegisterAll();
        Generated.CVarRegistrations.RegisterAll();

        bool settingsLoaded = false;
        if (IsolatedFromSavedSettings)
        {
        }
        else if (SettingsFile.Load(System, _settingsPath))
        {
            settingsLoaded = true;
        }

        // After the file, so a saved choice cannot outlive the lock, and before the command line, so a
        // +gfx_preset there is refused like one typed later.
        if (lockedPreset is { } locked)
        {
            GraphicsPresetRegistry.Default.Lock(locked);
        }
        else if (!IsolatedFromSavedSettings && !settingsLoaded)
        {
            GraphicsPresetRegistry.Default.Apply(firstRunPreset);
        }

        // Labels the restored settings, so a player who saved on High and has touched nothing since is
        // shown High rather than Custom.
        //
        // There was a migration here and it is gone. It existed for builds that shipped Ultra as dynamic
        // when Ultra was meant to be baked: on a settings file that read Custom with dynamic lighting, it
        // forced baked and kept that only if the file then matched Ultra. It has been unreachable since
        // Ultra became dynamic again -- forcing baked cannot make a preset match an Ultra that requires
        // dynamic, so the branch always undid itself -- and now that enhanced and high are dynamic too it
        // would be actively wrong. A settings file from those old builds is simply Custom, which is what
        // it honestly is.
        GraphicsPresetRegistry.Default.Detect();

        foreach (string statement in startupCommands ?? [])
        {
            System.Execute(statement);
        }


        System.Variables.AnyChanged += OnVariableChanged;
        GraphicsPresetRegistry.Default.PresetChanged += OnPresetChanged;

        if (!_view.Load(System))
        {
        }

        System.Write($"ProjectIGI console. {System.Variables.Count} variable(s), {System.Commands.All.Count} command(s).");
        System.Write("Type 'help' for commands, 'cvarlist' for settings, or press Tab to complete.");
    }

    /// <summary>Applies a frame's input.</summary>
    /// <param name="input">The input state for this frame.</param>
    /// <param name="elapsedSeconds">How long since the last call, for the caret blink.</param>
    /// <returns><see langword="true"/> when the console consumed the input and the game should ignore it.</returns>
    public bool Update(InputState input, float elapsedSeconds)
    {
        ArgumentNullException.ThrowIfNull(input);
        // The toggle is handled here rather than in the view, because it is the one key that has to
        // work when the console is shut and the view is doing nothing at all.
        bool wasOpen = Model.IsOpen;
        if (input.Keyboard.WasPressed(ToggleKey))
        {
            Model.IsOpen = !wasOpen;
            DrainCharacters(input.Keyboard);
            input.Captured = true;
            return true;
        }

        // Gamepad navigation is read first, while the frame's input is still uncaptured: once the
        // frame is marked captured every edge test reports nothing.
        if (wasOpen)
        {
            HandleGamepad(input);
        }

        bool consumed = _view.Update(input, elapsedSeconds);
        if (wasOpen)
        {
            input.Captured = true;
        }

        return consumed || wasOpen;
    }

    /// <summary>Draws the console and any panel the reader has left showing.</summary>
    /// <param name="batch">The batch to draw into; it must already be between Begin and End.</param>
    /// <param name="screenWidth">The back buffer's width.</param>
    /// <param name="screenHeight">The back buffer's height.</param>
    /// <param name="scale">Retained for call-site compatibility; the console sizes itself from <c>con_scale</c>.</param>
    public void Draw(SpriteBatch batch, int screenWidth, int screenHeight, float scale = 1f)
    {
        _ = scale;
        _view.Draw(batch, screenWidth, screenHeight);
    }

    /// <summary>Gets a value indicating whether anything needs drawing this frame.</summary>
    /// <remarks>
    /// Not the same question as <see cref="IsOpen"/>: the watch and performance panels can be left
    /// showing with the console shut. It is deliberately false during a capture run, so a reader's
    /// pinned overlay cannot leak into a reference screenshot and break the vanilla pixel gate.
    /// </remarks>
    public bool WantsDraw =>
        Model.IsOpen || (!IsolatedFromSavedSettings && DeveloperConsole.HasVisibleOverlays);

    /// <summary>Gets the entity the World panel has selected, or null when none is.</summary>
    public int? SelectedEntityId => _view.SelectedEntityId;

    /// <summary>Gets a value indicating whether the pointer must be freed and shown this frame.</summary>
    /// <remarks>
    /// Polled from the game loop's cursor chain, which re-asserts the lock on every pass — so a console
    /// that merely released the cursor when it opened would have it taken back a frame later.
    /// </remarks>
    public bool WantsPointer => _view.WantsPointer;

    /// <summary>The key that shows and hides the console.</summary>
    public static KeyCode ToggleKey => KeyCode.Grave;

    /// <summary>
    /// Throws away the characters the toggle key itself produced.
    /// </summary>
    /// <param name="keyboard">The frame's keyboard.</param>
    /// <remarks>
    /// The platform decodes text before the key event is seen, so opening the console would otherwise
    /// leave a backtick sitting in the prompt.
    /// </remarks>
    private static void DrainCharacters(KeyboardState keyboard)
    {
        while (keyboard.TryDequeueCharacter(out _))
        {
            // Discarded.
        }
    }

    /// <summary>
    /// Drives the open console from the game controller, so it is fully navigable without a keyboard —
    /// scroll, history, completion, submit and close. Typing itself still needs a keyboard, as a text
    /// console must.
    /// </summary>
    /// <param name="input">The frame's input.</param>
    private void HandleGamepad(InputState input)
    {
        GamepadState pad = input.Gamepad;
        int page = Math.Max(1, _view.VisibleLines - 2);

        if (pad.WasPressed(GamepadButton.DpadUp))
        {
            Model.Scroll(1, _view.VisibleLines);
        }

        if (pad.WasPressed(GamepadButton.DpadDown))
        {
            Model.Scroll(-1, _view.VisibleLines);
        }

        if (pad.WasPressed(GamepadButton.LeftShoulder))
        {
            Model.Scroll(page, _view.VisibleLines);
        }

        if (pad.WasPressed(GamepadButton.RightShoulder))
        {
            Model.Scroll(-page, _view.VisibleLines);
        }

        if (pad.WasPressed(GamepadButton.DpadLeft))
        {
            Model.HistoryPrevious();
        }

        if (pad.WasPressed(GamepadButton.DpadRight))
        {
            Model.HistoryNext();
        }

        if (pad.WasPressed(GamepadButton.West))
        {
            Model.Complete();
        }

        if (pad.WasPressed(GamepadButton.South) || pad.WasPressed(GamepadButton.Start))
        {
            Model.Submit();
        }

        if (pad.WasPressed(GamepadButton.East) || pad.WasPressed(GamepadButton.Back))
        {
            Model.IsOpen = false;
        }
    }

    /// <summary>
    /// Gets a value indicating whether this console is running without the saved settings file.
    /// </summary>
    /// <remarks>
    /// <para>
    /// A capture run must start from the defaults and apply only its command line. Otherwise a setting
    /// a player once changed silently decides what the reference set looks like — which is not
    /// hypothetical: an <c>r_scale 0.85</c> left over from an unrelated experiment quietly rendered
    /// every offscreen capture at 85% and upscaled it, and the resampling showed up as a 74%
    /// whole-frame difference that looked like a renderer bug.
    /// </para>
    /// <para>
    /// It must not <em>write</em> either, for the same reason in the other direction: a capture's
    /// <c>+</c> flags would otherwise be saved into the player's own settings on the way out.
    /// </para>
    /// </remarks>
    public bool IsolatedFromSavedSettings { get; private set; }

    /// <summary>Writes the settings file, unless this console is isolated from it.</summary>
    /// <returns><see langword="true"/> when it was written.</returns>
    public bool SaveSettings()
    {
        if (IsolatedFromSavedSettings)
        {
            return false;
        }

        // The panels' geometry is a setting like any other, so it is folded into the variable that
        // carries it just before the file is rendered rather than being written on every drag.
        _view.SaveLayout();

        bool saved = SettingsFile.Save(System, _settingsPath);
        if (!saved)
        {
        }

        return saved;
    }

    /// <inheritdoc/>
    public void Dispose()
    {
        if (_disposed)
        {
            return;
        }

        _disposed = true;
        System.Variables.AnyChanged -= OnVariableChanged;
        GraphicsPresetRegistry.Default.PresetChanged -= OnPresetChanged;
        PlayerCheatCVars.CheatsEnabled.Changed -= OnCheatsEnabledChanged;
        _view.Dispose();
    }

    private void OnVariableChanged(object? sender, CVarChangedEventArgs e)
    {
        if (e.Variable.Name.StartsWith("r_", StringComparison.OrdinalIgnoreCase))
        {
        }
    }

    private void OnPresetChanged(object? sender, GraphicsPreset preset) =>

    private void RegisterShellCommands()
    {
        System.Commands.Add(
            "quit",
            "Closes the game.",
            _ => QuitRequested?.Invoke(this, EventArgs.Empty));

        System.Commands.Add(
            "clear",
            "Empties the console's scrollback.",
            _ => Model.ClearScrollback());

        // Bindable, and usable from the command line as +toggleconsole -- which is how a headless
        // screenshot run captures the console itself.
        System.Commands.Add(
            "toggleconsole",
            "Shows or hides the console.",
            _ => Model.IsOpen = !Model.IsOpen);

        System.Commands.Add(
            "writeconfig",
            "Writes settings.cfg now instead of waiting for shutdown.",
            context => context.Print(SaveSettings() ? $"Wrote {_settingsPath}." : "Could not write the settings file."));

        System.Commands.Add(
            "cheats",
            "Reports or sets whether cheat commands and variables may be used.",
            context =>
            {
                if (context.Count > 0)
                {
                    // The console's gate and the player cheats' two session gates move together, so
                    // `cheats 1` makes the g_cheat_* variables both assignable and in force.
                    bool enabled = context[0] is "1" or "on" or "true" or "yes";
                    System.CheatsEnabled = enabled;
                    PlayerCheatCVars.DeveloperMode.Value = enabled;
                    PlayerCheatCVars.CheatsEnabled.Value = enabled;
                }

                context.Print($"cheats {(System.CheatsEnabled ? "enabled" : "disabled")}");
            },
            "[0 | 1]");
    }

    // The Extras screen's "Enable cheats" toggle writes the variable directly; the console follows it.
    private void OnCheatsEnabledChanged(object? sender, CVarChangedEventArgs e) =>
        System.CheatsEnabled = PlayerCheatCVars.CheatsEnabled.Value;
}
