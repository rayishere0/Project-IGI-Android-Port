namespace ProjectIGI.Net;

/// <summary>Random bytes for the handshake that never leave managed code.</summary>
/// <remarks>
/// <para>
/// This exists because <c>RandomNumberGenerator</c> crashes this app on Android: its first call in a
/// session start faults natively with SIGSEGV (fault addr 0x0) inside
/// <c>CryptoNative_GetRandomBytes</c> in <c>libSystem.Security.Cryptography.Native.Android.so</c>
/// (tombstone 2026-11-11 04:50:13 IST, moto g57 power, pid 10650, tid 10820). That native library
/// reaches the JVM through JNI, and its own JNI state is never initialised in this host: the library
/// is loaded by the runtime for a P/Invoke, not through the JVM, so its <c>JNI_OnLoad</c> never runs
/// and its stored <c>JavaVM*</c> stays null. The same signature is dotnet/runtime #51274 ("Missing
/// initialization of JNI"). A native fault bypasses every managed try/catch, so the call itself has
/// to go — not be wrapped.
/// </para>
/// <para>
/// Moving the call to another thread cannot fix it either: the game thread <em>is</em> attached to
/// the JVM by the JNI bridge (<c>jni_bridge.cpp</c>: the game thread calls
/// <c>AttachCurrentThread</c> before entering <c>AndroidHost.Run</c>), and the crash still happens
/// on it. The missing piece is the crypto library's own JNI initialisation, which no thread
/// attachment by the bridge can supply.
/// </para>
/// <para>
/// What these bytes are used for needs no cryptographic strength today: the server's challenge key
/// (<see cref="NetServer"/>), the client's handshake nonce (<see cref="NetClient"/>), a
/// per-connection salt (<see cref="NetConnection"/>) and a query nonce
/// (<see cref="NetQueryClient"/>) — all on the loopback transport, in one process, with no
/// off-path attacker. A <see cref="Random"/> built with an explicit seed is pure managed arithmetic
/// (the parameterless constructor is not used, so no OS entropy source is ever consulted) and can
/// never reach the faulting native call. If this stack ever runs over a real network with untrusted
/// peers, the challenge key should go back to a cryptographic RNG once the runtime's JNI
/// initialisation is fixed — see the PR that introduced this class.
/// </para>
/// </remarks>
internal static class NetRandom
{
    private static readonly Lock _gate = new();
    private static readonly Random _random = new(Seed());

    /// <summary>Fills a span with random bytes.</summary>
    /// <param name="buffer">The span to fill.</param>
    public static void Fill(Span<byte> buffer)
    {
        lock (_gate)
        {
            _random.NextBytes(buffer);
        }
    }

    /// <summary>Gets random bytes.</summary>
    /// <param name="count">How many bytes.</param>
    /// <returns>The bytes.</returns>
    public static byte[] GetBytes(int count)
    {
        byte[] bytes = new byte[count];
        Fill(bytes);
        return bytes;
    }

    /// <summary>Gets a random integer below a bound.</summary>
    /// <param name="maxValue">The exclusive upper bound.</param>
    /// <returns>An integer in [0, <paramref name="maxValue"/>).</returns>
    public static int NextInt32(int maxValue)
    {
        lock (_gate)
        {
            return _random.Next(maxValue);
        }
    }

    // A seed mixed from managed-only sources: the clock, the process and the thread. Every one of
    // these is a plain property read; none of them consults the OS entropy source or the JNI-backed
    // crypto library, so seeding can never fault the way RandomNumberGenerator does.
    private static int Seed()
    {
        unchecked
        {
            long ticks = DateTime.UtcNow.Ticks;
            int seed = Environment.TickCount;
            seed = (seed * 31) ^ (int)(ticks & 0xFFFFFFFF);
            seed = (seed * 31) ^ (int)(ticks >> 32);
            seed = (seed * 31) ^ Environment.ProcessId;
            seed = (seed * 31) ^ Environment.CurrentManagedThreadId;
            return seed;
        }
    }
}
