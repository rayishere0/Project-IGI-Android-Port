// The register model the title's drawing shares with its game: the client's FPU computes at 24-bit precision, rounding
// toward zero (see X87Single), the same alias ProjectIGI.Game.Igi2 declares.
global using Fpu = ProjectIGI.Core.Numerics.X87Single;
