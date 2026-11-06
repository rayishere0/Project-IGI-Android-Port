using System.Diagnostics.CodeAnalysis;
using ProjectIGI.Core.Content;
using ProjectIGI.Core.Titles;
using ProjectIGI.Engine.Events;
using ProjectIGI.Engine.Resources;
using ProjectIGI.Engine.Titles;
using ProjectIGI.Engine.Vfs;

namespace ProjectIGI.Modding;

/// <summary>What a mod reads of a game's session once the session has loaded its tables.</summary>
public interface IModContext
{
    /// <summary>Gets the mod's manifest.</summary>
    ModManifest Manifest { get; }

    /// <summary>Gets the game.</summary>
    GameTitle Title { get; }

    /// <summary>Gets the mod's directory.</summary>
    string Directory { get; }

    /// <summary>Gets the tables and worlds the game's modules published.</summary>
    IServiceCatalog Services { get; }

    /// <summary>Gets the session's events.</summary>
    GameEvents Events { get; }

    /// <summary>Gets the virtual file system the game reads through.</summary>
    VirtualFileSystem FileSystem { get; }

    /// <summary>Gets the resource registry the game's archives are open in.</summary>
    ResourceRegistry Resources { get; }

    /// <summary>Gets where diagnostics go.</summary>

    /// <summary>Finds where a game is installed.</summary>
    /// <param name="title">The game.</param>
    /// <param name="root">Receives its data directory.</param>
    /// <returns>Whether it is installed.</returns>
    bool TryGetDataRoot(GameTitle title, [NotNullWhen(true)] out string? root);
}
