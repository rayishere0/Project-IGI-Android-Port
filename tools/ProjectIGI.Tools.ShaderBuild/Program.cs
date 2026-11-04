using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace ProjectIGI.Tools.ShaderBuild;

class Program
{
    static int Main(string[] args)
    {
        Console.WriteLine("[ShaderBuild] Starting ShaderBuild tool...");

        // Locate repository root
        string baseDir = AppContext.BaseDirectory;
        string? repoRoot = FindRepoRoot(baseDir);
        if (repoRoot == null)
        {
            Console.WriteLine("[ShaderBuild] ERROR: Could not locate repository root.");
            return 1;
        }

        string shadersDir = Path.Combine(repoRoot, "src", "Rendering", "ProjectIGI.Shaders");
        string manifestPath = Path.Combine(shadersDir, "ShaderModules.json");
        string generatedDir = Path.Combine(shadersDir, "Generated");

        if (!File.Exists(manifestPath))
        {
            Console.WriteLine($"[ShaderBuild] ERROR: ShaderModules.json not found at {manifestPath}");
            return 1;
        }

        if (!Directory.Exists(generatedDir))
        {
            Directory.CreateDirectory(generatedDir);
        }

        string jsonText = File.ReadAllText(manifestPath);
        using JsonDocument doc = JsonDocument.Parse(jsonText);
        JsonElement root = doc.RootElement;

        if (!root.TryGetProperty("modules", out JsonElement modulesArray))
        {
            Console.WriteLine("[ShaderBuild] ERROR: Invalid ShaderModules.json (missing 'modules' property).");
            return 1;
        }

        int generatedCount = 0;

        foreach (JsonElement module in modulesArray.EnumerateArray())
        {
            string id = module.GetProperty("id").GetString()!;
            if (!module.TryGetProperty("variants", out JsonElement variantsArray))
            {
                continue;
            }

            foreach (JsonElement variant in variantsArray.EnumerateArray())
            {
                string name = variant.GetProperty("name").GetString()!;
                if (name == "veldrid")
                {
                    bool success = ProcessVeldridVariant(generatedDir, id);
                    if (success)
                    {
                        generatedCount++;
                    }
                }
            }
        }

        Console.WriteLine($"[ShaderBuild] Successfully generated {generatedCount} Veldrid shader modules.");
        return 0;
    }

    private static string? FindRepoRoot(string startDir)
    {
        DirectoryInfo? dir = new DirectoryInfo(startDir);
        while (dir != null)
        {
            if (File.Exists(Path.Combine(dir.FullName, "ProjectIGI.slnx")) || Directory.Exists(Path.Combine(dir.FullName, "src")))
            {
                return dir.FullName;
            }
            dir = dir.Parent;
        }
        return null;
    }

    private static bool ProcessVeldridVariant(string generatedDir, string moduleId)
    {
        string defaultSpvPath = Path.Combine(generatedDir, $"{moduleId}.default.spv");
        if (!File.Exists(defaultSpvPath)) defaultSpvPath = Path.Combine(generatedDir, $"{moduleId}.software.spv");
        if (!File.Exists(defaultSpvPath)) defaultSpvPath = Path.Combine(generatedDir, $"{moduleId}.spv");

        if (!File.Exists(defaultSpvPath))
        {
            Console.WriteLine($"[ShaderBuild] WARNING: Base SPV for module '{moduleId}' not found in {generatedDir}");
            return false;
        }

        byte[] inputSpvBytes = File.ReadAllBytes(defaultSpvPath);
        byte[] outputSpvBytes = TransformPushConstantsToUniformBuffer(inputSpvBytes);

        string outputSpvPath = Path.Combine(generatedDir, $"{moduleId}.veldrid.spv");
        File.WriteAllBytes(outputSpvPath, outputSpvBytes);
        Console.WriteLine($"[ShaderBuild] Emitted {Path.GetFileName(outputSpvPath)} ({outputSpvBytes.Length} bytes)");

        // Process reflection JSON if default exists
        string defaultReflectPath = Path.Combine(generatedDir, $"{moduleId}.default.reflection.json");
        if (File.Exists(defaultReflectPath))
        {
            string outputReflectPath = Path.Combine(generatedDir, $"{moduleId}.veldrid.reflection.json");
            TransformReflectionJson(defaultReflectPath, outputReflectPath);
        }

        return true;
    }

    private static byte[] TransformPushConstantsToUniformBuffer(byte[] bytes)
    {
        uint[] words = new uint[bytes.Length / 4];
        Buffer.BlockCopy(bytes, 0, words, 0, bytes.Length);

        List<uint> newWords = new List<uint>();
        for (int i = 0; i < 5; i++) newWords.Add(words[i]);

        List<uint> pushVarIds = new List<uint>();
        int lastDecorateIndex = 5;

        int idx = 5;
        while (idx < words.Length)
        {
            uint header = words[idx];
            int opCode = (int)(header & 0xFFFF);
            int wordCount = (int)(header >> 16);
            if (wordCount == 0) break;

            if (opCode == 71) // OpDecorate
            {
                lastDecorateIndex = idx + wordCount;
            }
            else if (opCode == 32) // OpTypePointer
            {
                if (words[idx + 2] == 7) // PushConstant
                {
                    words[idx + 2] = 2; // Uniform
                }
            }
            else if (opCode == 59) // OpVariable
            {
                if (words[idx + 3] == 7) // PushConstant
                {
                    words[idx + 3] = 2; // Uniform
                    uint varId = words[idx + 2];
                    pushVarIds.Add(varId);
                }
            }

            idx += wordCount;
        }

        idx = 5;
        while (idx < words.Length)
        {
            uint header = words[idx];
            int wordCount = (int)(header >> 16);

            for (int w = 0; w < wordCount; w++)
            {
                newWords.Add(words[idx + w]);
            }

            if (idx + wordCount == lastDecorateIndex)
            {
                foreach (var varId in pushVarIds)
                {
                    // OpDecorate varId DescriptorSet 3
                    newWords.Add((4 << 16) | 71u);
                    newWords.Add(varId);
                    newWords.Add(34u); // DescriptorSet
                    newWords.Add(3u);  // 3

                    // OpDecorate varId Binding 0
                    newWords.Add((4 << 16) | 71u);
                    newWords.Add(varId);
                    newWords.Add(33u); // Binding
                    newWords.Add(0u);  // 0
                }
            }

            idx += wordCount;
        }

        byte[] resultBytes = new byte[newWords.Count * 4];
        Buffer.BlockCopy(newWords.ToArray(), 0, resultBytes, 0, resultBytes.Length);
        return resultBytes;
    }

    private static void TransformReflectionJson(string inputPath, string outputPath)
    {
        string json = File.ReadAllText(inputPath);
        JsonObject? obj = JsonNode.Parse(json) as JsonObject;
        if (obj == null) return;

        obj["variant"] = "veldrid";

        if (obj.ContainsKey("pushBlock") && obj["pushBlock"] != null)
        {
            obj["pushBlock"] = null;
        }

        File.WriteAllText(outputPath, obj.ToJsonString(new JsonSerializerOptions { WriteIndented = true }));
    }
}
