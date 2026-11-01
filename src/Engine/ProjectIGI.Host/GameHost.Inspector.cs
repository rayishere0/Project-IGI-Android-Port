using ProjectIGI.Core.Graphics;
using ProjectIGI.Game.Ai;
using ProjectIGI.Game.Player;
using ProjectIGI.Game.World;
using ProjectIGI.Host.DevTools;
using ProjectIGI.Presentation;
using ProjectIGI.Presentation.Cameras;

namespace ProjectIGI.Host;

public sealed partial class GameHost
{
    // The eye and the lens the last frame was drawn with, which the inspector projects a selection through.
    private Camera3D _inspectorEye = Camera3D.Default;
    private float _inspectorTangent = 1f;
    private float _inspectorAspect = 16f / 9f;

    /// <summary>What the console's inspector reads of the host.</summary>
    /// <param name="host">The host.</param>
    private sealed class InspectedWorld(GameHost host) : IInspectedWorld
    {
        public IHostedPlayer? Player => host.HostedPlayer;

        public bool PlayerMode => host._playerMode;

        public bool PlayerDead => host._mission.IsPlayerDead;

        public FreeCamera? Camera => host._camera;

        public WorldScene? Scene => host._scene;

        public IWorldPresenter? World => host._world;

        public ITerrainPresenter? Terrain => host._terrain;

        public IGroundHeightField? Ground => host._mission.Ground;

        public ISoldierBodies? Soldiers => host._soldiers;

        public IInspectableMission Mission => host._mission;

        public Camera3D InspectorEye => host._inspectorEye;

        public float InspectorAspect => host._inspectorAspect;

        public float InspectorTangent => host._inspectorTangent;

        public int WindowWidth => host._window.Width;

        public int WindowHeight => host._window.Height;
    }
}
