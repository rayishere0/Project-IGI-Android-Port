namespace ProjectIGI.Core.Diagnostics;

/// <summary>An <see cref="IProjectIGILogger"/> that discards everything.</summary>
/// <remarks>Use this as the default when a host has not supplied a logger.</remarks>
public sealed class NullLogger : IProjectIGILogger
{
    private NullLogger()
    {
    }

    /// <summary>Gets the shared instance.</summary>
    public static NullLogger Instance { get; } = new NullLogger();

    /// <inheritdoc/>
    public bool IsEnabled(LogLevel level, string category) => false;

    /// <inheritdoc/>
    public void Log(in LogRecord record)
    {
        // Intentionally empty.
    }
}
