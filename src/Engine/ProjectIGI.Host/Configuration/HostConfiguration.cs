using ProjectIGI.Core.Configuration;
using ProjectIGI.Engine.Vfs;
using ProjectIGI.Game.Config;
using ProjectIGI.Scripting.Qvm;

namespace ProjectIGI.Host.Configuration;

/// <summary>
/// Reads and writes the game's settings and player profiles, always leaving the original installation
/// untouched.
/// </summary>
/// <remarks>
/// <para>
/// What the player accumulates — their profiles, their settings, their progress — is written to
/// <see cref="SettingsPaths"/>, not into the game folder. An installation may sit somewhere the player
/// cannot write, on a read-only mount, or be shared between several people with their own profiles, and
/// none of those work if the game saves next to its own data.
/// </para>
/// <para>
/// The file is ProjectIGI's own <c>ProjectIGI-config.qvm</c> and never the retail <c>config.qvm</c>, which is
/// read but never written. The format is identical, so copying one over the other would work.
/// </para>
/// </remarks>
internal static class HostConfiguration
{
    /// <summary>The file ProjectIGI keeps its own settings and profiles in.</summary>
    public const string FileName = "ProjectIGI-config.qvm";

    /// <summary>Loads the configuration, preferring the player's own file over the installation's.</summary>
    /// <param name="fileSystem">The virtual file system the installation is read through.</param>
    /// <param name="logger">The log read failures are reported to.</param>
    /// <returns>The loaded configuration, or a fresh default when none can be read.</returns>
    /// <remarks>
    /// In order: the player's own file, then one an earlier build left inside the installation, then the
    /// retail file, then defaults. The second of those is only ever read — the next save moves it out to
    /// the per-user location, so profiles made before this moved survive rather than appearing lost.
    /// </remarks>
    public static GameConfig Load(VirtualFileSystem fileSystem)
    {
        GameConfig config = Read(fileSystem);

        // Whichever file it came from: a new player's profiles are the retail file's, and those carry the
        // original's arrow keys. See GameConfig.MigrateControls.
        if (config.MigrateControls())
        {
        }

        return config;
    }

    private static GameConfig Read(VirtualFileSystem fileSystem)
    {
        string userPath = SettingsPaths.GetFilePath(FileName);

        if (File.Exists(userPath))
        {
            try
            {
                return ConfigScript.Load(File.ReadAllBytes(userPath), userPath);
            }
            catch (Exception ex) when (ex is IOException or UnauthorizedAccessException or QvmFormatException)
            {
            }
        }

        // ConfigScript.ProjectIGIPath resolves into the installation, which is where builds before this one
        // wrote. Kept as a read so an existing set of profiles is picked up exactly once and then
        // written out where it should have been.
        foreach (string path in new[] { ConfigScript.ProjectIGIPath, ConfigScript.RetailPath })
        {
            if (!fileSystem.Exists(path))
            {
                continue;
            }

            try
            {
                GameConfig loaded = ConfigScript.Load(fileSystem.ReadAllBytes(path), path);

                if (path == ConfigScript.ProjectIGIPath)
                {
                }

                return loaded;
            }
            catch (Exception ex) when (ex is IOException or QvmFormatException)
            {
            }
        }

        return GameConfig.CreateDefault();
    }

    /// <summary>Writes the configuration to the player's own file.</summary>
    /// <param name="configuration">The configuration to persist.</param>
    /// <param name="logger">The log the save is reported to.</param>
    public static void Save(GameConfig configuration)
    {
        string path = SettingsPaths.GetFilePath(FileName);

        try
        {
            string? directory = Path.GetDirectoryName(path);

            if (!string.IsNullOrEmpty(directory))
            {
                Directory.CreateDirectory(directory);
            }

            File.WriteAllBytes(path, ConfigScriptWriter.Write(configuration));
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException)
        {
        }
    }
}
