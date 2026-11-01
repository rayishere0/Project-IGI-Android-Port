using System.Runtime.CompilerServices;

// Project I.G.I.'s gameplay, reached by the host it is still driven by and by the suites that test it.
// The title's own presentation reads its simulation's state as it draws it: a title's two halves may know each other,
// as the layering rules let them reference each other. Nothing outside the title is granted this.
[assembly: InternalsVisibleTo("ProjectIGI.Presentation.Igi1")]
[assembly: InternalsVisibleTo("ProjectIGI.Game.Tests")]
[assembly: InternalsVisibleTo("ProjectIGI.Game.Igi1.Tests")]
[assembly: InternalsVisibleTo("ProjectIGI.Desktop.Tests")]
