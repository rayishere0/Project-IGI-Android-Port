cmake_minimum_required(VERSION 3.22.1)

project("openigi" LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3 -Wall -Wextra -Wno-unused-parameter")

# Build OpenAL Soft natively for Android with OpenSL ES audio backend
set(LIBTYPE "SHARED" CACHE STRING "" FORCE)
set(ALSOFT_UTILS OFF CACHE BOOL "" FORCE)
set(ALSOFT_EXAMPLES OFF CACHE BOOL "" FORCE)
set(ALSOFT_TESTS OFF CACHE BOOL "" FORCE)
set(ALSOFT_CONFIG OFF CACHE BOOL "" FORCE)
set(ALSOFT_INSTALL OFF CACHE BOOL "" FORCE)
set(ALSOFT_BACKEND_OPENSL ON CACHE BOOL "" FORCE)
set(ALSOFT_BACKEND_OBOE OFF CACHE BOOL "" FORCE)
set(ALSOFT_BACKEND_WAVE OFF CACHE BOOL "" FORCE)

add_subdirectory(openal-soft)

add_library(openigi SHARED
    jni/jni_bridge.cpp
)

find_library(LOG_LIB log)
find_library(ANDROID_LIB android)
find_library(OPENSLES_LIB OpenSLES)

target_link_libraries(openigi
    PRIVATE
    OpenAL
    ${ANDROID_LIB}
    ${LOG_LIB}
    ${OPENSLES_LIB}
    ${CMAKE_DL_LIBS}
)
