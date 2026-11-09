using System.Text.Json;
using ProjectIGI.Core.Content;
using ProjectIGI.Engine.Resources;
using ProjectIGI.Frontend;
using ProjectIGI.Rendering;

namespace ProjectIGI.Host;

public sealed partial class GameHost
{
    /// <summary>Gets where the content profile lives, or <see langword="null"/> when no profile is in force.</summary>
    /// <remarks>
    /// The option the launcher passes wins; the environment variable is the desktop launcher's older
    /// hand-off, read the same way <see cref="Content.ContentLayers"/> reads it. A missing file is not an
    /// error here: the profile is created on the first change a player makes.
    /// </remarks>
    public string? ContentProfilePath =>
        _options.ContentProfilePath ?? NonEmpty(Environment.GetEnvironmentVariable(ContentProfile.EnvironmentVariable));

    /// <summary>Gets the content layers for the running title, highest priority first, with what each holds.</summary>
    /// <remarks>
    /// The live stack is the truth for files and wins; the profile is consulted only to name each layer's
    /// kind, because the stack also holds launch folders (a <c>-content</c> folder, a mod's data) that no
    /// profile entry describes.
    /// </remarks>
    public IReadOnlyList<IShellHost.ContentLayerRow> ContentLayers()
    {
        IReadOnlyDictionary<string, ContentLayerSpec> specs = ProfileSpecsForActiveTitle();
        List<IShellHost.ContentLayerRow> rows = [];

        foreach (ResourceOverrides.LayerInfo layer in _overrides.Layers)
        {
            string kind = specs.TryGetValue(layer.Id, out ContentLayerSpec? spec)
                ? spec.Kind switch
                {
                    ContentLayerKind.Pack => "pack",
                    ContentLayerKind.Local => "local",
                    _ => "directory",
                }
                : layer.Name.EndsWith("(-content)", StringComparison.OrdinalIgnoreCase) ? "dev"
                : layer.Name.EndsWith("(mod)", StringComparison.OrdinalIgnoreCase) ? "mod"
                : layer.Name.StartsWith("Legacy", StringComparison.OrdinalIgnoreCase) ? "legacy"
                : "directory";

            rows.Add(new IShellHost.ContentLayerRow(layer.Id, layer.Name, kind, layer.Enabled, layer.Files, layer.Wins));
        }

        return rows;
    }

    /// <summary>Switches one content layer on or off, live, and saves the choice in the profile.</summary>
    /// <param name="id">The layer's id.</param>
    /// <param name="enabled">Whether it should take part.</param>
    /// <returns>A sentence on what changed.</returns>
    /// <remarks>
    /// The switch itself is the console's: the store re-merges from the indexes it holds and the registry
    /// is brought up to date through <see cref="ApplyOverrideChange"/>, which also reloads the level's
    /// textures, so a pack switched on in the pause menu is visible without reloading the mission. A layer
    /// no profile entry describes (a <c>-content</c> folder, a mod's data) is switched live only: there is
    /// nothing to save it as, and inventing a profile entry for it would stack the folder a second time on
    /// the next launch.
    /// </remarks>
    public string SetContentLayerEnabled(string id, bool enabled)
    {
        if (!_overrides.SetEnabled(id, enabled, out ResourceOverrides.ScanResult result))
        {
            return $"No content layer '{id}'.";
        }

        string name = _overrides.Layers.First(layer => string.Equals(layer.Id, id, StringComparison.OrdinalIgnoreCase)).Name;
        string saved = PersistLayerEnabled(id, enabled);
        _ = ApplyOverrideChange(out string reload);
        string report = $"{name} {(enabled ? "on" : "off")}: {result}; {reload}{saved}";

        if (_overrides.Bypassed)
        {
            report += " Every layer is bypassed until the disable-all switch is turned back off.";
        }

        _logger.Information("Overrides", report);
        return report;
    }

    /// <summary>Moves one content layer up (towards winning) or down in the load order, live, and saves it.</summary>
    /// <param name="id">The layer's id.</param>
    /// <param name="up">Whether it moves towards the top.</param>
    /// <returns>A sentence on what changed.</returns>
    public string MoveContentLayer(string id, bool up)
    {
        IReadOnlyList<ResourceOverrides.LayerInfo> layers = _overrides.Layers;
        int at = layers.ToList().FindIndex(layer => string.Equals(layer.Id, id, StringComparison.OrdinalIgnoreCase));
        if (at < 0)
        {
            return $"No content layer '{id}'.";
        }

        int to = at + (up ? -1 : 1);
        if (to < 0 || to >= layers.Count)
        {
            return $"{layers[at].Name} is already at the {(up ? "top" : "bottom")}.";
        }

        List<string> order = [.. layers.Select(layer => layer.Id)];
        (order[at], order[to]) = (order[to], order[at]);

        if (!_overrides.SetOrder(order, out ResourceOverrides.ScanResult result))
        {
            return $"Could not move {layers[at].Name}.";
        }

        string saved = PersistLayerOrder([.. order]);
        _ = ApplyOverrideChange(out string reload);
        string report = $"{layers[at].Name} moved {(up ? "up" : "down")}: {result}; {reload}{saved}";
        _logger.Information("Overrides", report);
        return report;
    }

    /// <summary>Gets the paths more than one enabled layer carries, as "path — winner wins over ..." lines.</summary>
    /// <remarks>Capped at six lines: a pack that shadows a whole archive can conflict on hundreds of paths.</remarks>
    public IReadOnlyList<string> ContentConflicts()
    {
        IReadOnlyList<ResourceOverrides.LayerInfo> layers = _overrides.Layers;
        List<string> lines = [];

        foreach (ResourceOverrides.Conflict conflict in _overrides.Conflicts().Take(6))
        {
            string covered = string.Join(", ", conflict.Covered.Select(index => layers[index].Name));
            lines.Add($"{conflict.Path} — {layers[conflict.Winner].Name} wins over {covered}");
        }

        return lines;
    }

    /// <summary>Gets or sets whether every content layer is bypassed (the touch equivalent of F8).</summary>
    /// <remarks>
    /// The same body the F8 watcher runs, so the key and the row cannot disagree: the variable is set, the
    /// store is bypassed, and what is loaded is brought up to date. The variable is not saved, so a
    /// relaunch always starts with the packs on — a pack that breaks the menu is recovered from the
    /// launcher, which writes the profile instead.
    /// </remarks>
    public bool ContentBypassed
    {
        get => _overrides.Bypassed;
        set
        {
            MaterialCVars.OverridesEnabled.Value = !value;
            _overridesApplied = !value;
            _overrides.Bypassed = value;

            if (!_overrides.HasContent)
            {
                return;
            }

            int swapped = ApplyOverrideChange(out string report);
            _logger.Information(
                "Overrides",
                value
                    ? $"Content bypassed from Configuration; {swapped} resource(s) back to the game's own."
                    : $"Content restored from Configuration; {swapped} resource(s) swapped in. {report}");
        }
    }

    /// <summary>Re-reads the content folders from disk and reloads what changed.</summary>
    /// <returns>A sentence on what changed.</returns>
    public string RescanContent()
    {
        ResourceOverrides.ScanResult scan = _overrides.Rescan();
        _ = ApplyOverrideChange(out string report);
        string line = $"{scan}; {report}";
        _logger.Information("Overrides", "Content rescanned from Configuration: " + line);
        return line;
    }

    // The profile's list for the running title, by layer id, or empty when there is no profile or it does
    // not mention this title. A profile that cannot be read is a warning at boot already; here it is read
    // again, because the player may have installed a pack since the title loaded.
    private IReadOnlyDictionary<string, ContentLayerSpec> ProfileSpecsForActiveTitle()
    {
        string? path = ContentProfilePath;
        if (string.IsNullOrWhiteSpace(path))
        {
            return new Dictionary<string, ContentLayerSpec>();
        }

        ContentProfile? profile = ReadContentProfile(path);
        if (profile is null)
        {
            return new Dictionary<string, ContentLayerSpec>();
        }

        // First entry wins: a hand-edited profile may repeat an id, and the resolve already de-duplicates
        // the live stack the same way rather than failing the title load.
        var specs = new Dictionary<string, ContentLayerSpec>(StringComparer.OrdinalIgnoreCase);
        foreach (ContentLayerSpec spec in profile.For(_titleRuntime.Title.Id))
        {
            specs.TryAdd(spec.Id, spec);
        }

        return specs;
    }

    private ContentProfile? ReadContentProfile(string path)
    {
        try
        {
            return ContentProfile.Read(path);
        }
        catch (Exception error) when (error is IOException or UnauthorizedAccessException or JsonException)
        {
            _logger.Warning("Overrides", $"Content profile '{path}' could not be read, so this change is live-only: {error.Message}");
            return null;
        }
    }

    // Writes the running title's list back with one change applied, keeping every other title's list
    // exactly as read. Returns the sentence the settings screen appends to its report.
    private string WriteProfileForActiveTitle(Func<List<ContentLayerSpec>, List<ContentLayerSpec>> change)
    {
        string? path = ContentProfilePath;
        if (string.IsNullOrWhiteSpace(path))
        {
            return " (not saved — no content profile in force).";
        }

        // A profile that is there but cannot be read is left alone, not overwritten with a fresh one:
        // clobbering it here would lose the player's pack list, and the engine already falls back to
        // the local overrides folder for it. A missing file is created fresh below.
        bool exists = File.Exists(path);
        ContentProfile? read = exists ? ReadContentProfile(path) : null;
        if (exists && read is null)
        {
            return " (not saved — the profile could not be read).";
        }

        ContentProfile profile = read
            ?? new ContentProfile(ContentProfile.CurrentSchema, new Dictionary<string, IReadOnlyList<ContentLayerSpec>>());
        string titleId = _titleRuntime.Title.Id;
        var titles = new Dictionary<string, IReadOnlyList<ContentLayerSpec>>(profile.Titles, StringComparer.OrdinalIgnoreCase);
        titles[titleId] = change([.. profile.For(titleId)]);

        try
        {
            ContentProfile.Write(path, profile with { Titles = titles });
            return " (saved).";
        }
        catch (Exception error) when (error is IOException or UnauthorizedAccessException)
        {
            _logger.Warning("Overrides", $"Content profile '{path}' could not be written, so this change is live-only: {error.Message}");
            return " (not saved — the profile could not be written).";
        }
    }

    // Records one layer's switch in the profile: the entry it has, or a fresh local entry when the layer
    // IS the local one and the profile never mentioned it. Other launch-only layers are live-only.
    private string PersistLayerEnabled(string id, bool enabled)
    {
        bool isLocal = string.Equals(id, ContentLayerSpec.LocalId, StringComparison.OrdinalIgnoreCase);

        if (!isLocal && !ProfileSpecsForActiveTitle().ContainsKey(id))
        {
            return " (live only — a launch folder, not a profile entry).";
        }

        return WriteProfileForActiveTitle(specs =>
        {
            int at = specs.FindIndex(spec => string.Equals(spec.Id, id, StringComparison.OrdinalIgnoreCase));
            if (at >= 0)
            {
                specs[at] = specs[at] with { Enabled = enabled };
            }
            else
            {
                // The local layer, on an install whose profile predates it: appended at the bottom, where
                // the game folder's own overrides have always sat.
                specs.Add(ContentLayerSpec.Local(enabled));
            }

            return specs;
        });
    }

    // Records the load order in the profile: the live order, restricted to the entries the profile has.
    // Launch-only layers keep their live places but are not invented as entries for them.
    private string PersistLayerOrder(IReadOnlyList<string> order)
    {
        IReadOnlyDictionary<string, ContentLayerSpec> specs = ProfileSpecsForActiveTitle();
        if (specs.Count == 0)
        {
            return " (live only — no profile entries to reorder).";
        }

        return WriteProfileForActiveTitle(current =>
        {
            var byId = new Dictionary<string, ContentLayerSpec>(StringComparer.OrdinalIgnoreCase);
            foreach (ContentLayerSpec spec in current)
            {
                byId.TryAdd(spec.Id, spec);
            }

            return [.. order.Where(byId.ContainsKey).Select(id => byId[id])];
        });
    }

    private static string? NonEmpty(string? value) => string.IsNullOrWhiteSpace(value) ? null : value;
}
