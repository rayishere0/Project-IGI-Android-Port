using ProjectIGI.Core.Diagnostics;
using ProjectIGI.Core.Numerics;
using ProjectIGI.Engine.Audio;
using ProjectIGI.Engine.Flow;
using ProjectIGI.Game.World;

namespace ProjectIGI.Game.Hosting;

/// <summary>What a title's cries and impact sounds are played through.</summary>
public interface IMissionSoundHost
{
    /// <summary>Gets the running game, whose clock the impact sounds' quiet windows are timed on.</summary>
    GameLoop Game { get; }

    /// <summary>Gets the log.</summary>
    IProjectIGILogger Logger { get; }

    /// <summary>Gets a value indicating whether the level's weather is on, which wets every footstep.</summary>
    bool IsRaining { get; }

    /// <summary>Gets where sounds play, or <see langword="null"/> for silence.</summary>
    /// <remarks>Silence draws nothing from the sound stream: every cry and impact returns before it picks.</remarks>
    SoundSystem? SoundOutput { get; }
}
