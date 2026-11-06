using ProjectIGI.Core.Graphics;
using ProjectIGI.Core.Numerics;
using ProjectIGI.Game.World;
using ProjectIGI.Presentation.Lighting;
using ProjectIGI.Rendering;

namespace ProjectIGI.Host.Lighting;

/// <summary>
/// Writes the surface cache's intermediate atlases out as images, because a capture can only be judged by
/// looking at it: wrong winding shows as models captured inside-out, a wrong card rotation as mirrored
/// pages, a missing scissor as pages bleeding together -- and each produces an atlas of plausible
/// surfaces. These are diagnostics, gated behind <c>r_surfcache_dump</c>, never part of a normal frame.
/// </summary>
internal static class SurfaceCacheDebugDumps
{
    /// <summary>
    /// Runs the screen probe gather once and writes its probe atlas to a PNG, to verify the gather reads
    /// the G-buffer and reconstructs world positions before it is wired into the frame.
    /// </summary>
    public static void ScreenGather(IGraphicsDevice device, SurfaceCacheLighting cards, GlobalDistanceField field, Camera3D eye, Matrix4f projection, float farPlane, int width, int height, string into)
    {
        try
        {
            const int step = 8;
            int gridW = (width + step - 1) / step;
            int gridH = (height + step - 1) / step;

            TextureHandle output = device.CreateStorageTexture(
                gridW, gridH, VolumeFormat.Rgba16F, "cards.screen.indirect");

            Vector3f cameraToCache = new(
                (float)(eye.Position.X - cards.Origin.X),
                (float)(eye.Position.Y - cards.Origin.Y),
                (float)(eye.Position.Z - cards.Origin.Z));

            cards.GatherScreen(
                field,
                device.SceneDepth,
                device.SceneNormal,
                DepthUnprojection.From(projection, 0.1f, farPlane),
                eye.Orientation.Transposed(),
                cameraToCache,
                width,
                height,
                step,
                output);

            Bgra32[] pixels = new Bgra32[gridW * gridH];
            device.ReadStorageTexture(output, pixels);

            long lit = 0;

            foreach (Bgra32 pixel in pixels)
            {
                if (pixel.R > 0 || pixel.G > 0 || pixel.B > 0)
                {
                    lit++;
                }
            }

            Directory.CreateDirectory(into);
            string path = Path.Combine(into, "screen-indirect.png");
            PngWriter.Write(path, pixels, gridW, gridH);

            device.DestroyTexture(output);
        }
        catch (GraphicsDeviceException error)
        {
        }
    }

    /// <summary>
    /// Writes the surface-cache lighting atlases (direct, indirect, final) to PNGs and reports per-texel
    /// statistics, because a reconstruction that is subtly wrong produces lit surfaces in slightly the
    /// wrong places, which looks like nothing at all until a later stage bounces light off them.
    /// </summary>
    /// <param name="device">The device the atlases are read back from.</param>
    /// <param name="lighting">The lit surface cache whose atlases are written.</param>
    /// <param name="into">The directory the images are written to.</param>
    /// <param name="logger">The log the statistics are reported to.</param>
    /// <param name="probe">A non-zero probe index switches the report to min/mean/max per channel.</param>
    /// <param name="name">The file name for the direct-lighting atlas.</param>
    public static void CardLighting(IGraphicsDevice device, SurfaceCacheLighting lighting, string into, int probe = 0, string name = "cards-direct.png")
    {
        try
        {
            Directory.CreateDirectory(into);

            Bgra32[] pixels = new Bgra32[lighting.Width * lighting.Height];
            device.ReadStorageTexture(lighting.DirectLighting, pixels);

            // The bounce and the atlas a trace actually reads, beside the direct term. Judging indirect
            // light from the direct atlas alone is how a gather that returns nothing goes unnoticed.
            //
            // Guarded on its own, because a diagnostic must not be able to take the game down with it:
            // reading these threw at load, the throw escaped the outer catch, and every run after that
            // died before it reached anything worth measuring while looking exactly like a slow gather.
            try
            {
                Bgra32[] extra = new Bgra32[lighting.Width * lighting.Height];

                foreach ((TextureHandle source, string file) in new[]
                {
                    (lighting.IndirectLighting, "cards-indirect.png"),
                    (lighting.FinalLighting, "cards-final.png"),
                })
                {
                    device.ReadStorageTexture(source, extra);
                    string other = Path.Combine(into, file);
                    PngWriter.Write(other, extra, lighting.Width, lighting.Height);

                    long carrying = 0;

                    foreach (Bgra32 pixel in extra)
                    {
                        if (pixel.R > 0 || pixel.G > 0 || pixel.B > 0)
                        {
                            carrying++;
                        }
                    }

                }
            }
            catch (Exception error)
            {
            }

            string path = Path.Combine(into, name);
            PngWriter.Write(path, pixels, lighting.Width, lighting.Height);

            // A probe is judged by its numbers, not its thumbnail: each channel is a question the
            // shader answered per texel, and min/mean/max over the covered texels is the answer.
            if (probe != 0)
            {
                long covered = 0;
                long inside = 0;
                long sumR = 0, sumG = 0, sumB = 0;
                int minR = 255, minG = 255, minB = 255;
                int maxR = 0, maxG = 0, maxB = 0;

                foreach (Bgra32 pixel in pixels)
                {
                    // The shader writes alpha for every covered texel: one when a clipmap contained
                    // the probe point, half when none did. Uncovered atlas stays at zero.
                    if (pixel.A < 64)
                    {
                        continue;
                    }

                    covered++;
                    inside += pixel.A >= 192 ? 1 : 0;
                    sumR += pixel.R;
                    sumG += pixel.G;
                    sumB += pixel.B;
                    minR = Math.Min(minR, pixel.R);
                    minG = Math.Min(minG, pixel.G);
                    minB = Math.Min(minB, pixel.B);
                    maxR = Math.Max(maxR, pixel.R);
                    maxG = Math.Max(maxG, pixel.G);
                    maxB = Math.Max(maxB, pixel.B);
                }

                long n = Math.Max(covered, 1);
                return;
            }

            // What share of the written pages the sun actually reaches, reported rather than eyeballed.
            // A shadow pass is judged by this number: too high and it is not shadowing, too low and it
            // is shadowing everything, and both look plausible in a thumbnail. Unwritten atlas is
            // excluded, because at 77% occupancy the empty quarter would dominate either way.
            long written = 0;
            long bright = 0;

            foreach (Bgra32 pixel in pixels)
            {
                if (pixel.R == 0 && pixel.G == 0 && pixel.B == 0)
                {
                    continue;
                }

                written++;

                if (Math.Max(Math.Max(pixel.R, pixel.G), pixel.B) >= 128)
                {
                    bright++;
                }
            }

        }
        catch (Exception error)
            when (error is IOException or UnauthorizedAccessException or GraphicsDeviceException)
        {
        }
    }

    /// <summary>Writes the four card G-buffer attachments (albedo, normal, material, depth) to PNGs.</summary>
    /// <param name="device">The device the card atlas is read back from.</param>
    /// <param name="cards">The captured card atlas whose layout sizes the images.</param>
    /// <param name="into">The directory the images are written to.</param>
    /// <param name="logger">The log the writes are reported to.</param>
    public static void CardAtlas(IGraphicsDevice device, SurfaceCacheCapture.Result cards, string into)
    {
        try
        {
            Directory.CreateDirectory(into);

            int width = cards.Layout.Width;
            int height = cards.Layout.Height;
            Bgra32[] pixels = new Bgra32[width * height];

            string[] names = ["albedo", "normal", "material", "depth"];

            for (int attachment = 0; attachment < names.Length; attachment++)
            {
                device.ReadCardAtlas(attachment, pixels);

                string path = Path.Combine(into, $"cards-{names[attachment]}.png");
                PngWriter.Write(path, pixels, width, height);
            }
        }
        catch (Exception error)
            when (error is IOException or UnauthorizedAccessException or GraphicsDeviceException)
        {
        }
    }
}
