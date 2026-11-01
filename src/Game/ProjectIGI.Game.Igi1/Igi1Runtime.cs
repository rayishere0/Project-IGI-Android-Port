using ProjectIGI.Core.Titles;
using ProjectIGI.Engine.Titles;
using ProjectIGI.Formats;

namespace ProjectIGI.Game.Igi1;

/// <summary>Project I.G.I., as the engine runs it.</summary>
public sealed class Igi1Runtime : IGameTitleRuntime
{
    /// <inheritdoc/>
    public GameTitle Title => GameTitle.Igi1;

    /// <inheritdoc/>
    public ITitleDataLayout Layout { get; } = new Igi1DataLayout();

    /// <inheritdoc/>
    public AssetFormatProfile Formats => AssetFormatProfile.Igi1;

    /// <inheritdoc/>
    public IReadOnlyList<IContentModule> Modules => Igi1ContentModules.All;
}
