#pragma once

#include <GLES3/gl3.h>
#include <string>
#include <vector>

namespace openigi {

struct Vertex2D {
    float x, y;
    float u, v;
    float r, g, b, a;
};

class Gles3Renderer {
public:
    static Gles3Renderer& instance();

    bool initialize(int width, int height);
    void resize(int width, int height);
    void shutdown();

    void beginFrame();
    void endFrame();

    // 2D Drawing Primitives
    void drawColorRect(float x, float y, float w, float h, float r, float g, float b, float a);
    void drawWireframeRect(float x, float y, float w, float h, float lineWidth, float r, float g, float b, float a);
    void drawTexturedRect(GLuint textureId, float x, float y, float w, float h, 
                          float r = 1.0f, float g = 1.0f, float b = 1.0f, float a = 1.0f);

    // Authentic Project IGI Presentation
    void drawLoadingScreen(float progress, GLuint backdropTex = 0);
    void drawTacticalHud(float health, float ammo, int currentWeapon, bool infiniteAmmo, bool godMode);
    void drawVirtualTouchControls(float stickX, float stickY, bool stickActive, float lookTouchX, float lookTouchY, bool lookActive);

    // Texture Utility
    GLuint createTexture(int width, int height, const uint8_t* rgbaPixels);
    void deleteTexture(GLuint textureId);

    int getViewportWidth() const { return width_; }
    int getViewportHeight() const { return height_; }

private:
    Gles3Renderer() = default;
    ~Gles3Renderer() { shutdown(); }
    Gles3Renderer(const Gles3Renderer&) = delete;
    Gles3Renderer& operator=(const Gles3Renderer&) = delete;

    GLuint compileShader(GLenum type, const char* source);
    GLuint createProgram(const char* vertexSrc, const char* fragmentSrc);

    int width_{1280};
    int height_{720};
    bool initialized_{false};

    // 2D Shaders & Buffers
    GLuint program2D_{0};
    GLint locScreenSize_{-1};
    GLint locUseTexture_{-1};
    GLint locTexture_{-1};

    GLuint vao2D_{0};
    GLuint vbo2D_{0};

    // Default 1x1 white texture for solid shapes
    GLuint whiteTexture_{0};
};

} // namespace openigi

