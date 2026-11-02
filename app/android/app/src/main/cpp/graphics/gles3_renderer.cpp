#include "gles3_renderer.h"
#include <android/log.h>
#include <cmath>
#include <algorithm>

#define LOG_TAG "ProjectIGI-GLES3"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

namespace projectigi {

namespace {

const char* kVertexShader2D = R"(#version 300 es
precision highp float;

layout(location = 0) in vec2 aPosition;
layout(location = 1) in vec2 aTexCoord;
layout(location = 2) in vec4 aColor;

uniform vec2 uScreenSize;

out vec2 vTexCoord;
out vec4 vColor;

void main() {
    // Map from screen pixels (0,0 top-left) to NDC (-1 to +1)
    vec2 zeroToOne = aPosition / uScreenSize;
    vec2 clipSpace = (zeroToOne * 2.0) - 1.0;

    gl_Position = vec4(clipSpace.x, -clipSpace.y, 0.0, 1.0);
    vTexCoord = aTexCoord;
    vColor = aColor;
}
)";

const char* kFragmentShader2D = R"(#version 300 es
precision mediump float;

in vec2 vTexCoord;
in vec4 vColor;

uniform sampler2D uTexture;
uniform int uUseTexture;

out vec4 fragColor;

void main() {
    if (uUseTexture == 1) {
        vec4 tex = texture(uTexture, vTexCoord);
        fragColor = tex * vColor;
    } else {
        fragColor = vColor;
    }
}
)";

} // namespace

Gles3Renderer& Gles3Renderer::instance() {
    static Gles3Renderer instance;
    return instance;
}

GLuint Gles3Renderer::compileShader(GLenum type, const char* source) {
    GLuint shader = glCreateShader(type);
    glShaderSource(shader, 1, &source, nullptr);
    glCompileShader(shader);

    GLint success;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
    if (!success) {
        char infoLog[512];
        glGetShaderInfoLog(shader, 512, NULL, infoLog);
        __android_log_print(ANDROID_LOG_ERROR, "ProjectIGI", "Shader Compile Error: %s", infoLog);
        glDeleteShader(shader);
        return 0;
    }
    return shader;
}

GLuint Gles3Renderer::createProgram(const char* vertexSrc, const char* fragmentSrc) {
    GLuint vert = compileShader(GL_VERTEX_SHADER, vertexSrc);
    GLuint frag = compileShader(GL_FRAGMENT_SHADER, fragmentSrc);
    if (!vert || !frag) {
        return 0;
    }

    GLuint program = glCreateProgram();
    glAttachShader(program, vert);
    glAttachShader(program, frag);
    glLinkProgram(program);

    GLint success;
    glGetProgramiv(program, GL_LINK_STATUS, &success);
    if (!success) {
        char infoLog[512];
        glGetProgramInfoLog(program, sizeof(infoLog), nullptr, infoLog);
        LOGE("Program linking failed: %s", infoLog);
        glDeleteProgram(program);
        program = 0;
    }

    glDeleteShader(vert);
    glDeleteShader(frag);
    return program;
}

bool Gles3Renderer::initialize(int width, int height) {
    width_ = width > 0 ? width : 1280;
    height_ = height > 0 ? height : 720;

    LOGI("Initializing native OpenGL ES 3.0 Renderer (%dx%d)", width_, height_);

    // 1. Create Shader Program
    program2D_ = createProgram(kVertexShader2D, kFragmentShader2D);
    if (!program2D_) {
        LOGE("Failed to create GLES 3.0 shader program");
        return false;
    }

    locScreenSize_ = glGetUniformLocation(program2D_, "uScreenSize");
    locUseTexture_ = glGetUniformLocation(program2D_, "uUseTexture");
    locTexture_ = glGetUniformLocation(program2D_, "uTexture");

    // 2. Setup VAO and VBO
    glGenVertexArrays(1, &vao2D_);
    glGenBuffers(1, &vbo2D_);

    glBindVertexArray(vao2D_);
    glBindBuffer(GL_ARRAY_BUFFER, vbo2D_);

    // Allocate dynamic buffer for streaming quads
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex2D) * 128, nullptr, GL_DYNAMIC_DRAW);

    // aPosition: (x, y)
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex2D), (const void*)offsetof(Vertex2D, x));

    // aTexCoord: (u, v)
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex2D), (const void*)offsetof(Vertex2D, u));

    // aColor: (r, g, b, a)
    glEnableVertexAttribArray(2);
    glVertexAttribPointer(2, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex2D), (const void*)offsetof(Vertex2D, r));

    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    // 3. Create 1x1 White Texture
    const uint32_t whitePixel = 0xFFFFFFFF;
    whiteTexture_ = createTexture(1, 1, (const uint8_t*)&whitePixel);

    // 4. Default GL States
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glDisable(GL_CULL_FACE);
    glDisable(GL_DEPTH_TEST);

    initialized_ = true;
    LOGI("OpenGL ES 3.0 Renderer successfully initialized!");
    return true;
}

void Gles3Renderer::resize(int width, int height) {
    if (width > 0 && height > 0) {
        width_ = width;
        height_ = height;
        glViewport(0, 0, width_, height_);
    }
}

void Gles3Renderer::shutdown() {
    if (!initialized_) return;

    if (vao2D_) { glDeleteVertexArrays(1, &vao2D_); vao2D_ = 0; }
    if (vbo2D_) { glDeleteBuffers(1, &vbo2D_); vbo2D_ = 0; }
    if (program2D_) { glDeleteProgram(program2D_); program2D_ = 0; }
    if (whiteTexture_) { deleteTexture(whiteTexture_); whiteTexture_ = 0; }

    initialized_ = false;
    LOGI("OpenGL ES 3.0 Renderer shut down.");
}

void Gles3Renderer::beginFrame() {
    glViewport(0, 0, width_, height_);
    // Authentic deep Project IGI military dark green clear color
    glClearColor(0.03f, 0.08f, 0.05f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glUseProgram(program2D_);
    glUniform2f(locScreenSize_, (float)width_, (float)height_);
}

void Gles3Renderer::endFrame() {
    glFlush();
}

void Gles3Renderer::drawColorRect(float x, float y, float w, float h, float r, float g, float b, float a) {
    Vertex2D vertices[6] = {
        // Triangle 1
        { x,     y,     0.0f, 0.0f, r, g, b, a },
        { x,     y + h, 0.0f, 1.0f, r, g, b, a },
        { x + w, y,     1.0f, 0.0f, r, g, b, a },
        // Triangle 2
        { x + w, y,     1.0f, 0.0f, r, g, b, a },
        { x,     y + h, 0.0f, 1.0f, r, g, b, a },
        { x + w, y + h, 1.0f, 1.0f, r, g, b, a },
    };

    // Use pure vertex color, NO TEXTURE SAMPLING
    glUniform1i(locUseTexture_, 0);

    glBindVertexArray(vao2D_);
    glBindBuffer(GL_ARRAY_BUFFER, vbo2D_);
    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(vertices), vertices);

    glDrawArrays(GL_TRIANGLES, 0, 6);

    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

void Gles3Renderer::drawWireframeRect(float x, float y, float w, float h, float lineWidth, float r, float g, float b, float a) {
    // Top
    drawColorRect(x, y, w, lineWidth, r, g, b, a);
    // Bottom
    drawColorRect(x, y + h - lineWidth, w, lineWidth, r, g, b, a);
    // Left
    drawColorRect(x, y, lineWidth, h, r, g, b, a);
    // Right
    drawColorRect(x + w - lineWidth, y, lineWidth, h, r, g, b, a);
}

void Gles3Renderer::drawTexturedRect(GLuint textureId, float x, float y, float w, float h, 
                                    float r, float g, float b, float a) {
    if (textureId == 0) {
        drawColorRect(x, y, w, h, r, g, b, a);
        return;
    }

    Vertex2D vertices[6] = {
        // Triangle 1
        { x,     y,     0.0f, 0.0f, r, g, b, a },
        { x,     y + h, 0.0f, 1.0f, r, g, b, a },
        { x + w, y,     1.0f, 0.0f, r, g, b, a },
        // Triangle 2
        { x + w, y,     1.0f, 0.0f, r, g, b, a },
        { x,     y + h, 0.0f, 1.0f, r, g, b, a },
        { x + w, y + h, 1.0f, 1.0f, r, g, b, a },
    };

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, textureId);
    glUniform1i(locTexture_, 0);
    glUniform1i(locUseTexture_, 1);

    glBindVertexArray(vao2D_);
    glBindBuffer(GL_ARRAY_BUFFER, vbo2D_);
    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(vertices), vertices);

    glDrawArrays(GL_TRIANGLES, 0, 6);

    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

void Gles3Renderer::drawLoadingScreen(float progress, GLuint backdropTex) {
    float w = (float)width_;
    float h = (float)height_;

    // 1. Loading screen backdrop
    if (backdropTex > 0) {
        drawTexturedRect(backdropTex, 0.0f, 0.0f, w, h);
    } else {
        // Deep tactical background
        drawColorRect(0.0f, 0.0f, w, h, 0.04f, 0.09f, 0.05f, 1.0f);

        // Center Tactical Frame
        float fw = std::min(w * 0.85f, 960.0f);
        float fh = std::min(h * 0.70f, 540.0f);
        float fx = (w - fw) * 0.5f;
        float fy = (h - fh) * 0.45f;
        drawWireframeRect(fx, fy, fw, fh, 2.0f, 0.22f, 0.90f, 0.38f, 0.7f);

        // Crosshairs in Center
        float cx = w * 0.5f;
        float cy = h * 0.45f;
        float arm = 24.0f;
        drawColorRect(cx - arm, cy - 1.0f, arm * 2.0f, 2.0f, 0.22f, 0.90f, 0.38f, 0.6f);
        drawColorRect(cx - 1.0f, cy - arm, 2.0f, arm * 2.0f, 0.22f, 0.90f, 0.38f, 0.6f);
    }

    // 2. Corner Tactical Brackets (Authentic IGI HUD)
    float bLen = 36.0f;
    float bThick = 3.0f;
    float greenR = 0.24f, greenG = 0.95f, greenB = 0.42f; // Phosphor green

    // Top-left
    drawColorRect(16.0f, 16.0f, bLen, bThick, greenR, greenG, greenB, 1.0f);
    drawColorRect(16.0f, 16.0f, bThick, bLen, greenR, greenG, greenB, 1.0f);

    // Top-right
    drawColorRect(w - 16.0f - bLen, 16.0f, bLen, bThick, greenR, greenG, greenB, 1.0f);
    drawColorRect(w - 16.0f - bThick, 16.0f, bThick, bLen, greenR, greenG, greenB, 1.0f);

    // Bottom-left
    drawColorRect(16.0f, h - 42.0f, bLen, bThick, greenR, greenG, greenB, 1.0f);
    drawColorRect(16.0f, h - 42.0f - bLen, bThick, bLen, greenR, greenG, greenB, 1.0f);

    // Bottom-right
    drawColorRect(w - 16.0f - bLen, h - 42.0f, bLen, bThick, greenR, greenG, greenB, 1.0f);
    drawColorRect(w - 16.0f - bThick, h - 42.0f - bLen, bThick, bLen, greenR, greenG, greenB, 1.0f);

    // 3. Authentic Project IGI Loading Progress Bar Across Bottom
    float barH = std::max(14.0f, 18.0f * (h / 1080.0f));
    float barY = h - barH;
    float p = std::clamp(progress, 0.05f, 1.0f);

    // Dark green track background across full width
    drawColorRect(0.0f, barY, w, barH, 0.06f, 0.22f, 0.10f, 1.0f);

    // Solid bright phosphor green loading progress fill
    drawColorRect(0.0f, barY, w * p, barH, 0.24f, 0.95f, 0.42f, 1.0f);

    // Top highlight hairline on bar
    drawColorRect(0.0f, barY, w * p, 2.0f, 0.70f, 1.0f, 0.75f, 0.9f);
}

void Gles3Renderer::drawTacticalHud(float health, float ammo, int currentWeapon, bool infiniteAmmo, bool godMode) {
    float w = (float)width_;
    float h = (float)height_;

    // Health Bar (Bottom Left)
    float hbW = 220.0f;
    float hbH = 16.0f;
    float hbX = 36.0f;
    float hbY = h - 52.0f;

    drawWireframeRect(hbX - 2.0f, hbY - 2.0f, hbW + 4.0f, hbH + 4.0f, 2.0f, 0.2f, 0.9f, 0.4f, 0.9f);
    drawColorRect(hbX, hbY, hbW, hbH, 0.08f, 0.22f, 0.12f, 0.8f); // track
    float hpPct = std::clamp(health / 100.0f, 0.0f, 1.0f);
    drawColorRect(hbX, hbY, hbW * hpPct, hbH, godMode ? 0.25f : 0.90f, godMode ? 0.98f : 0.28f, 0.35f, 1.0f);

    // Ammo Bar / Counter (Bottom Right)
    float amW = 180.0f;
    float amH = 16.0f;
    float amX = w - amW - 36.0f;
    float amY = h - 52.0f;

    drawWireframeRect(amX - 2.0f, amY - 2.0f, amW + 4.0f, amH + 4.0f, 2.0f, 0.2f, 0.9f, 0.4f, 0.9f);
    drawColorRect(amX, amY, amW, amH, 0.08f, 0.22f, 0.12f, 0.8f);
    float ammoPct = infiniteAmmo ? 1.0f : std::clamp(ammo / 30.0f, 0.0f, 1.0f);
    drawColorRect(amX, amY, amW * ammoPct, amH, 0.24f, 0.95f, 0.42f, 1.0f);
}

void Gles3Renderer::drawVirtualTouchControls(float stickX, float stickY, bool stickActive, 
                                             float lookTouchX, float lookTouchY, bool lookActive) {
    float h = (float)height_;

    // Virtual Stick Base (Left side)
    float baseX = 150.0f;
    float baseY = h - 170.0f;
    float baseSize = 130.0f;

    drawWireframeRect(baseX - (baseSize * 0.5f), baseY - (baseSize * 0.5f), baseSize, baseSize, 2.0f, 0.22f, 0.90f, 0.40f, 0.4f);

    // Virtual Stick Knob
    float knobSize = 52.0f;
    float knobX = baseX + (stickX * 52.0f);
    float knobY = baseY - (stickY * 52.0f);
    drawColorRect(knobX - (knobSize * 0.5f), knobY - (knobSize * 0.5f), knobSize, knobSize, 0.24f, 0.95f, 0.42f, stickActive ? 0.8f : 0.45f);
}

GLuint Gles3Renderer::createTexture(int width, int height, const uint8_t* rgbaPixels) {
    GLuint tex = 0;
    glGenTextures(1, &tex);
    glBindTexture(GL_TEXTURE_2D, tex);

    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, rgbaPixels);

    glBindTexture(GL_TEXTURE_2D, 0);
    return tex;
}

void Gles3Renderer::deleteTexture(GLuint textureId) {
    if (textureId > 0) {
        glDeleteTextures(1, &textureId);
    }
}

} // namespace projectigi
