using System.Diagnostics;
using System.Globalization;
using System.Runtime;
using System.Text;
using ProjectIGI.Core.Configuration;
using ProjectIGI.Presentation;
using ProjectIGI.Rendering;

namespace ProjectIGI.Host.Services;

/// <summary>Where the game's memory is, and giving back what a finished load leaves idle.</summary>
/// <param name="device">The graphics device, whose own allocations and caches are reported and trimmed.</param>
/// <param name="logger">Where reports are logged.</param>
internal sealed class MemoryDiagnostics(IGraphicsDevice device) : IHostService
{
    /// <summary>The category memory reports are logged under.</summary>

    /// <inheritdoc/>
    public string Name => "Memory";




    /// <summary>Gives back what a finished load leaves idle: upload staging, and the large-object heap's holes.</summary>
    /// <remarks>
    /// Called under the held frame of a backdrop swap, where a collection's pause is not seen. A level's
    /// worth of decoded pictures has just gone through the large-object heap, which the collector does
    /// not compact unless asked -- the holes they leave are memory the process keeps. The browser's runtime
    /// (Mono) has no such heap and throws PlatformNotSupportedException for any mode but Default, so there
    /// the collection runs without it.
    /// </remarks>
    public void TrimAfterLoad()
    {
        device.TrimMemory();
        if (!OperatingSystem.IsBrowser())
        {
            GCSettings.LargeObjectHeapCompactionMode = GCLargeObjectHeapCompactionMode.CompactOnce;
        }

        GC.Collect(2, GCCollectionMode.Forced, blocking: true, compacting: true);
    }

    /// <summary>Drops what a level's load kept for its uploads, once they are done.</summary>
    /// <param name="world">The world's renderer, whose decode cache holds every picture it decoded.</param>
    /// <param name="detailMaps">The material detail maps, whose unclaimed entries go.</param>
    /// <remarks>
    /// The decode cache holds every picture it decoded until the renderer takes it; whatever the level
    /// never drew stays there for as long as the level does. Once the level is resident nothing more will
    /// be taken, so the rest goes, and the staging that carried the uploads with it.
    /// </remarks>
    public void ReleaseLoadLeftovers(IWorldPresenter? world, MaterialDetailPack detailMaps)
    {
        ArgumentNullException.ThrowIfNull(detailMaps);
        if (world?.Decoded is { } decoded)
        {
            decoded.ReleaseUntaken();
            world.Decoded = null;
        }

        detailMaps.ReleaseUnclaimed();
        device.TrimMemory();
    }

    /// <inheritdoc/>
    public void Dispose()
    {
    }

    private static string Mib(long bytes) =>
        FormattableString.Invariant($"{bytes / (1024.0 * 1024.0):F0} MiB");
}
