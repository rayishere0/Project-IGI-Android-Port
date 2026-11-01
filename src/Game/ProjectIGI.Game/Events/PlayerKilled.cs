using ProjectIGI.Engine.Events;

namespace ProjectIGI.Game.Events;

/// <summary>The player has died.</summary>
public readonly record struct PlayerKilled() : IGameEvent;
