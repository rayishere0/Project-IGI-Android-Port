using System.Runtime.CompilerServices;

[assembly: InternalsVisibleTo("ProjectIGI.Game.Tests")]

// The scenario harness reads a mission's cutscene state through the runtime's own testing accessors.
[assembly: InternalsVisibleTo("ProjectIGI.Desktop.Tests")]
