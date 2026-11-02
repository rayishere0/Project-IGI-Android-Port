cmake_minimum_required(VERSION 3.22.1)

project("projectigi" LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3 -Wall -Wextra -Wno-unused-parameter -fvisibility=hidden -Wl,--exclude-libs,ALL")

# Precompiled OpenAL Soft for Android
add_library(OpenAL SHARED IMPORTED)
set_target_properties(OpenAL PROPERTIES IMPORTED_LOCATION
    "${CMAKE_CURRENT_SOURCE_DIR}/../jniLibs/${ANDROID_ABI}/libopenal.so"
)

add_library(projectigi SHARED
    jni/jni_bridge.cpp
    graphics/egl_manager.cpp
    graphics/gles3_renderer.cpp
)

find_library(LOG_LIB log)
find_library(ANDROID_LIB android)
find_library(OPENSLES_LIB OpenSLES)
find_library(EGL_LIB EGL)
find_library(GLES3_LIB GLESv3)

target_link_libraries(projectigi
    PRIVATE
    OpenAL
    ${ANDROID_LIB}
    ${LOG_LIB}
    ${OPENSLES_LIB}
    ${EGL_LIB}
    ${GLES3_LIB}
    ${CMAKE_DL_LIBS}
)
