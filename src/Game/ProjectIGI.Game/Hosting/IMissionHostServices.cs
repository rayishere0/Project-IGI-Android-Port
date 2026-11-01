using ProjectIGI.Game.Player;
using ProjectIGI.Game.World;

namespace ProjectIGI.Game.Hosting;

/// <summary>Everything a title's mission asks of whatever shows and plays it.</summary>
public interface IMissionHostServices : IMissionTickHost, IPlayerSetupHost, IPlayerHarmHost, IMissionSetupHost, IBlastEffectsHost, IMissionSoundHost, IImpactEffectsHost
{
}
