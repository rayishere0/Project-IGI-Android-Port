using System.Runtime.InteropServices;
using OpenIGI.Core.Diagnostics;

namespace OpenIGI.Android;

public sealed partial class AndroidLogSink : ILogSink
{
    private const string Tag = "OpenIGI";

    [LibraryImport("log", EntryPoint = "__android_log_print", StringMarshalling = StringMarshalling.Utf8)]
    private static partial int AndroidLogPrint(int priority, string tag, string fmt, string msg);

    public LogLevel MinimumLevel => LogLevel.Debug;

    public void Emit(in LogRecord record)
    {
        int priority = record.Level switch
        {
            LogLevel.Trace => 2,
            LogLevel.Debug => 3,
            LogLevel.Information => 4,
            LogLevel.Warning => 5,
            LogLevel.Error => 6,
            LogLevel.Fatal => 7,
            _ => 4
        };

        string text = string.IsNullOrEmpty(record.Category) 
            ? record.Message 
            : $"[{record.Category}] {record.Message}";

        if (record.Exception is not null)
        {
            text += $"\n{record.Exception}";
        }

        try
        {
            _ = AndroidLogPrint(priority, Tag, "%s", text);
        }
        catch
        {
            // Silently ignore if liblog is unavailable
        }
    }

    public void Flush() { }

    public void Dispose() { }
}
