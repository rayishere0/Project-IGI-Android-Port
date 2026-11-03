using System;
using System.Collections.Generic;
using System.Collections.Immutable;
using System.Linq;
using System.Text;
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp.Syntax;
using Microsoft.CodeAnalysis.Text;

namespace ProjectIGI.Generators;

/// <summary>
/// Emits the code that makes every <c>[CVarContainer]</c> class register its console variables.
/// </summary>
/// <remarks>
/// <para>
/// Console variables are declared as static fields next to the code that reads them, which means
/// their initialisers only run once something touches the declaring class. That is exactly the wrong
/// time: the settings file is read at start-up, before most subsystems exist, so a hand-written
/// registration list would silently lose whichever variables nobody remembered to add.
/// </para>
/// <para>
/// For each assembly this emits a <c>CVarRegistrations.RegisterAll()</c> that forces the static
/// constructor of every container to run, plus a module initialiser that calls it. The explicit
/// method is what the host calls before loading settings — module initialisers fire on first use of
/// the assembly, which is not guaranteed to have happened by then.
/// </para>
/// </remarks>
[Generator(LanguageNames.CSharp)]
public sealed class CVarContainerGenerator : IIncrementalGenerator
{
    private const string AttributeName = "ProjectIGI.Core.Configuration.CVarContainerAttribute";

    private static readonly DiagnosticDescriptor NotStatic = new(
        "OIGI007",
        "Console variable container must be a static class",
        "'{0}' is marked [CVarContainer] but is not a static class, so its declarations cannot be registered",
        "ProjectIGI",
        DiagnosticSeverity.Error,
        isEnabledByDefault: true);

    /// <inheritdoc/>
    public void Initialize(IncrementalGeneratorInitializationContext context)
    {
        IncrementalValuesProvider<Container?> containers = context.SyntaxProvider
            .ForAttributeWithMetadataName(
                AttributeName,
                static (node, _) => node is ClassDeclarationSyntax,
                static (ctx, _) => Describe(ctx))
            .Where(static container => container is not null);

        // The project's root namespace travels separately from the assembly name on purpose: the assembly
        // name is part of the Android ABI and is rewritten for the port, while the namespaces the engine
        // compiles against stay ProjectIGI.*.
        IncrementalValueProvider<string?> rootNamespace = context.AnalyzerConfigOptionsProvider.Select(
            static (options, _) => options.GlobalOptions.TryGetValue("build_property.RootNamespace", out string? root)
                ? root
                : null);

        IncrementalValueProvider<(ImmutableArray<Container?> Containers, string AssemblyName, string? RootNamespace)> combined =
            containers.Collect()
                .Combine(context.CompilationProvider.Select(static (c, _) => c.AssemblyName ?? "ProjectIGI"))
                .Combine(rootNamespace)
                .Select(static (pair, _) => (
                    Containers: pair.Left.Left,
                    AssemblyName: pair.Left.Right,
                    RootNamespace: pair.Right));

        context.RegisterSourceOutput(
            combined,
            static (ctx, input) => Emit(ctx, input.Containers, input.AssemblyName, input.RootNamespace));
    }

    private static Container? Describe(GeneratorAttributeSyntaxContext context)
    {
        if (context.TargetSymbol is not INamedTypeSymbol type)
        {
            return null;
        }

        bool isStatic = type.IsStatic && type.TypeKind == TypeKind.Class;
        string display = type.ToDisplayString(SymbolDisplayFormat.FullyQualifiedFormat);
        Location location = type.Locations.Length > 0 ? type.Locations[0] : Location.None;

        return new Container(display, type.ToDisplayString(), isStatic, location);
    }

    private static void Emit(
        SourceProductionContext context,
        ImmutableArray<Container?> containers,
        string assemblyName,
        string? rootNamespace)
    {
        List<Container> valid = new();

        foreach (Container? candidate in containers)
        {
            if (candidate is not { } container)
            {
                continue;
            }

            if (!container.IsStatic)
            {
                context.ReportDiagnostic(Diagnostic.Create(NotStatic, container.Location, container.FriendlyName));
                continue;
            }

            valid.Add(container);
        }

        if (valid.Count == 0)
        {
            return;
        }

        // Sorted so the emitted file is byte-identical between builds, which keeps the build deterministic.
        valid.Sort(static (a, b) => string.CompareOrdinal(a.QualifiedName, b.QualifiedName));

        // The namespace these registrations land in follows the project's root namespace, not the assembly
        // name. Assembly identity is part of the Android ABI and is renamed for the port (see
        // Directory.Build.props), while every namespace the engine compiles against stays ProjectIGI.*;
        // deriving this from the assembly name would move the generated class out from under its callers.
        string ns = !string.IsNullOrWhiteSpace(rootNamespace)
            ? Sanitize(rootNamespace)
            : Sanitize(assemblyName);
        StringBuilder source = new();

        source.AppendLine("// <auto-generated/>");
        source.AppendLine("#nullable enable");
        source.AppendLine();
        source.AppendLine($"namespace {ns}.Generated;");
        source.AppendLine();
        source.AppendLine("/// <summary>");
        source.AppendLine($"/// Registers every <c>[CVarContainer]</c> declared in <c>{assemblyName}</c>.");
        source.AppendLine("/// </summary>");
        source.AppendLine("[global::System.CodeDom.Compiler.GeneratedCode(\"ProjectIGI.Generators\", \"1.0\")]");
        source.AppendLine("public static class CVarRegistrations");
        source.AppendLine("{");
        source.AppendLine("    private static bool _done;");
        source.AppendLine();
        source.AppendLine("    /// <summary>Forces every container in this assembly to publish its declarations.</summary>");
        source.AppendLine("    /// <remarks>Safe to call more than once; only the first call does anything.</remarks>");
        source.AppendLine("    [global::System.Runtime.CompilerServices.ModuleInitializer]");
        source.AppendLine("    public static void RegisterAll()");
        source.AppendLine("    {");
        source.AppendLine("        if (_done)");
        source.AppendLine("        {");
        source.AppendLine("            return;");
        source.AppendLine("        }");
        source.AppendLine();
        source.AppendLine("        _done = true;");
        source.AppendLine();

        foreach (Container container in valid)
        {
            source.AppendLine(
                "        global::System.Runtime.CompilerServices.RuntimeHelpers.RunClassConstructor(" +
                $"typeof({container.QualifiedName}).TypeHandle);");
        }

        source.AppendLine("    }");
        source.AppendLine("}");

        context.AddSource("CVarRegistrations.g.cs", SourceText.From(source.ToString(), Encoding.UTF8));
    }

    private static string Sanitize(string assemblyName)
    {
        StringBuilder builder = new(assemblyName.Length);

        foreach (char c in assemblyName)
        {
            builder.Append(char.IsLetterOrDigit(c) || c == '_' || c == '.' ? c : '_');
        }

        string result = builder.ToString().Trim('.');
        return result.Length == 0 || char.IsDigit(result[0]) ? "ProjectIGI" : result;
    }

    /// <summary>One class carrying <c>[CVarContainer]</c>, as the generator needs to see it.</summary>
    /// <remarks>A plain class rather than a record: the analyzer target is netstandard2.0, which has no <c>init</c>.</remarks>
    private sealed class Container(string qualifiedName, string friendlyName, bool isStatic, Location location)
    {
        public string QualifiedName { get; } = qualifiedName;

        public string FriendlyName { get; } = friendlyName;

        public bool IsStatic { get; } = isStatic;

        public Location Location { get; } = location;
    }
}
