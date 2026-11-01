#pragma once

#include <jni.h>

#ifdef __cplusplus
extern "C" {
#endif

JNIEXPORT jboolean JNICALL Java_com_projectigi_app_NativeEngine_nativeStartGame
  (JNIEnv *, jclass, jobject, jint, jint, jstring, jstring, jstring);

JNIEXPORT void JNICALL Java_com_projectigi_app_NativeEngine_nativeOnSurfaceChanged
  (JNIEnv *, jclass, jint, jint);

JNIEXPORT void JNICALL Java_com_projectigi_app_NativeEngine_nativeOnSurfaceDestroyed
  (JNIEnv *, jclass);

JNIEXPORT void JNICALL Java_com_projectigi_app_NativeEngine_nativeOnTouch
  (JNIEnv *, jclass, jint, jint, jfloat, jfloat);

JNIEXPORT void JNICALL Java_com_projectigi_app_NativeEngine_nativeOnKey
  (JNIEnv *, jclass, jint, jboolean);

JNIEXPORT void JNICALL Java_com_projectigi_app_NativeEngine_nativeShutdown
  (JNIEnv *, jclass);

#ifdef __cplusplus
}
#endif
