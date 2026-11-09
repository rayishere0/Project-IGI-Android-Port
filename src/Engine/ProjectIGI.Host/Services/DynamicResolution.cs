using System.Diagnostics;

namespace ProjectIGI.Host.Services;

/// <summary>
/// Holds the frame rate by shrinking the picture: the PS2 trick, done live.
/// </summary>
/// <remarks>
/// <para>
/// When the frame rate falls below the target, the game steps the render scale down its own ladder
/// until the rate holds; when it holds comfortably for a while it steps back up, slowly, so the picture
/// does not flicker between two scales. The manual Resolution Quality is the ceiling: the scale never
/// rises above what the player picked, and the archived render scale itself is never written, so the
/// player's tier survives a relaunch exactly as picked.
/// </para>
/// <para>
/// Fed once per presented frame with the wall time between frames. A hitch (a load, a tab-out, a shader
/// compile) is not the frame rate, so a single interval over a quarter of a second drops the window
/// instead of dragging the mean down with it. The mean is over the last thirty frames, which is about a
/// second at thirty frames a second and three at ten -- long enough to be steady, short enough to react.
/// </para>
/// </remarks>
public sealed class DynamicResolution
{
    /// <summary>The render scales the ladder steps through, high to low.</summary>
    /// <remarks>
    /// The top three rungs are the pause screen's own tiers (native, 5/6, 2/3); the bottom three extend
    /// them to the render scale's floor. A step is one rung at a time, so the picture shrinks gradually
    /// rather than jumping to the floor on the first slow frame.
    /// </remarks>
    private static readonly float[] Ladder = [1f, 0.833f, 0.667f, 0.5f, 0.375f, 0.25f];

    private const int RingCapacity = 30;
    private const int MinimumSamples = 10;
    private const double HitchMilliseconds = 250.0;
    private const double OverTarget = 1.10;
    private const double UnderTarget = 0.85;
    private static readonly TimeSpan DownCooldown = TimeSpan.FromSeconds(1.0);
    private static readonly TimeSpan UpCooldown = TimeSpan.FromSeconds(2.0);
    private static readonly TimeSpan UpHold = TimeSpan.FromSeconds(4.0);

    private readonly double[] _samples = new double[RingCapacity];
    private int _next;
    private int _count;
    private int _index;
    private long _lastTimestamp;
    private long _nextStepAt;
    private long _goodSince;
    private float _ceiling = 1f;

    /// <summary>The render scale in force, at or below the manual tier's.</summary>
    public float Scale { get; private set; } = 1f;

    /// <summary>Feeds one presented frame's wall time and steps the scale when the rate misses.</summary>
    /// <param name="timestamp">The monotonic timestamp this frame was presented at.</param>
    /// <param name="manualScale">The render scale the player's tier asks for: the ceiling.</param>
    /// <param name="targetFps">The frame rate to hold.</param>
    /// <param name="frameCap">The player's frame cap, or nought for uncapped.</param>
    /// <param name="smooth">Whether smooth motion is on; off latches renders to the 30 Hz tick.</param>
    public void Evaluate(long timestamp, float manualScale, int targetFps, int frameCap, bool smooth)
    {
        // A scale the player picked -- a tier in the pause screen, the retail menu, the console --
        // re-arms the ladder: the manual tier is the ceiling, and the current scale starts there
        // again. This is what stops the service fighting the player's own setting.
        if (Math.Abs(manualScale - _ceiling) > 0.001f)
        {
            _ceiling = manualScale;
            _index = LadderIndex(manualScale);
            Scale = Ladder[_index];
            _count = 0;
            _next = 0;
            _nextStepAt = 0;
            _goodSince = 0;
        }

        if (_lastTimestamp != 0)
        {
            double milliseconds = (timestamp - _lastTimestamp) * 1000.0 / Stopwatch.Frequency;
            if (milliseconds > 0.0 && milliseconds <= HitchMilliseconds)
            {
                _samples[_next] = milliseconds;
                _next = (_next + 1) % RingCapacity;
                _count = Math.Min(_count + 1, RingCapacity);
            }
            else if (milliseconds > HitchMilliseconds)
            {
                _count = 0;
                _next = 0;
            }
        }

        _lastTimestamp = timestamp;

        if (_count < MinimumSamples || timestamp < _nextStepAt)
        {
            return;
        }

        double sum = 0.0;
        for (int i = 0; i < _count; i++)
        {
            sum += _samples[i];
        }

        double mean = sum / _count;

        // The rate that can actually be held: the target, but never above the player's cap, and
        // never above the tick latch when smooth motion is off -- without that last clamp a target
        // of 60 on a 30 Hz latch would walk the ladder to the floor and stay there.
        int effectiveTarget = targetFps;
        if (frameCap > 0)
        {
            effectiveTarget = Math.Min(effectiveTarget, frameCap);
        }

        if (!smooth)
        {
            effectiveTarget = Math.Min(effectiveTarget, 30);
        }

        double targetMilliseconds = 1000.0 / Math.Max(1, effectiveTarget);

        if (mean > targetMilliseconds * OverTarget)
        {
            _goodSince = 0;
            if (StepDown())
            {
                _nextStepAt = timestamp + (long)(DownCooldown.TotalSeconds * Stopwatch.Frequency);
                _count = 0;
                _next = 0;
            }

            return;
        }

        if (mean < targetMilliseconds * UnderTarget)
        {
            if (_goodSince == 0)
            {
                _goodSince = timestamp;
            }
            else if (timestamp - _goodSince >= (long)(UpHold.TotalSeconds * Stopwatch.Frequency))
            {
                if (StepUp())
                {
                    _nextStepAt = timestamp + (long)(UpCooldown.TotalSeconds * Stopwatch.Frequency);
                    _count = 0;
                    _next = 0;
                }

                _goodSince = 0;
            }

            return;
        }

        _goodSince = 0;
    }

    /// <summary>Steps one rung down the ladder, or <see langword="false"/> at the floor.</summary>
    private bool StepDown()
    {
        if (_index >= Ladder.Length - 1)
        {
            return false;
        }

        _index++;
        Scale = Ladder[_index];
        return true;
    }

    /// <summary>Steps one rung up the ladder, or <see langword="false"/> at the ceiling.</summary>
    private bool StepUp()
    {
        if (_index <= 0 || Ladder[_index - 1] > _ceiling + 0.001f)
        {
            return false;
        }

        _index--;
        Scale = Ladder[_index];
        return true;
    }

    /// <summary>The rung the ladder starts on for a ceiling: the highest rung at or below it.</summary>
    private static int LadderIndex(float ceiling)
    {
        for (int i = 0; i < Ladder.Length; i++)
        {
            if (Ladder[i] <= ceiling + 0.001f)
            {
                return i;
            }
        }

        return Ladder.Length - 1;
    }
}
