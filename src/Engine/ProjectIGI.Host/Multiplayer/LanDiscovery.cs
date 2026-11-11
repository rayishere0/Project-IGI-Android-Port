using System.Diagnostics;
using ProjectIGI.Game.Multiplayer;
using ProjectIGI.Net;
using ProjectIGI.Net.Udp;

namespace ProjectIGI.Host.Multiplayer;

/// <summary>A game on the local network, as LAN discovery found it.</summary>
/// <param name="Address">Where it listens, as <c>host:port</c>.</param>
/// <param name="Info">What it says about itself: name, map, players.</param>
/// <param name="PingSeconds">The round trip of the query that found it.</param>
public sealed record LanServer(string Address, ServerInfo Info, double PingSeconds);

/// <summary>
/// Finds co-op games on the local network: one broadcast query, and the answers
/// the listening servers send back. No master server, no account, no relay — the
/// same Wi-Fi the game itself plays over.
/// </summary>
/// <remarks>
/// The query half of the repo's own server browser (<see cref="NetQueryClient"/>):
/// a host's <c>HostedSession</c> already answers these queries (it sets
/// <c>NetServerOptions.Info</c>), so discovery needs no work on the host's side.
/// The transport is IPv4-only on purpose — <see cref="UdpTransport.Open"/>'s
/// own note says LAN discovery stays on IPv4 so its broadcasts go out everywhere.
/// </remarks>
public sealed class LanDiscovery : IDisposable
{
    private readonly NetQueryClient _query;
    private readonly Stopwatch _clock = Stopwatch.StartNew();
    private bool _disposed;

    /// <summary>Initializes a new instance of the <see cref="LanDiscovery"/> class.</summary>
    /// <param name="titleId">The game's id, which keys the protocol.</param>
    public LanDiscovery(string titleId)
    {
        ArgumentNullException.ThrowIfNull(titleId);
        _query = new NetQueryClient(UdpTransport.Open(0, ipv4Only: true), MultiplayerProtocol.IdFor(titleId));
        _query.QueryLocalNetwork(SessionArguments.DefaultPort, Now);
    }

    /// <summary>Reads the answers that have arrived since the last call.</summary>
    /// <returns>The servers found this call.</returns>
    public List<LanServer> TakeFound()
    {
        List<LanServer> found = [];
        double now = Now;
        _query.Update(now);
        while (_query.TryReceive(out NetServerInfo answer))
        {
            if (ServerInfo.Decode(answer.Info) is { } info)
            {
                found.Add(new LanServer(answer.Address.ToString(), info, answer.Ping));
            }
        }

        return found;
    }

    /// <inheritdoc/>
    public void Dispose()
    {
        if (_disposed)
        {
            return;
        }

        _disposed = true;
        _query.Dispose();
    }

    private double Now => _clock.Elapsed.TotalSeconds;
}
