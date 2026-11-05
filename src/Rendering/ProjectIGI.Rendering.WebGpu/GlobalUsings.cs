// The entry points, under a name that is not also this project's namespace.
//
// The generated class is ProjectIGI.Rendering.WebGpu.Native.WebGpu, and code in ProjectIGI.Rendering.WebGpu
// that writes WebGpu.wgpuDeviceCreateBuffer resolves the first part against the enclosing namespace
// rather than the class, which fails to compile in a way that reads as a missing reference. An alias
// says which was meant, once, for the whole project.
global using Wgpu = ProjectIGI.Rendering.WebGpu.Native.WebGpu;
