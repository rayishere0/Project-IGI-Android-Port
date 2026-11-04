// The GLES backend talks to one Silk.NET surface: the GL class from Silk.NET.OpenGLES, and the context
// interface it is resolved through from Silk.NET.Core. Brought in once here so every file that touches
// the API states the game-side namespaces it needs and no more.
global using Silk.NET.Core.Contexts;
global using Silk.NET.OpenGLES;
