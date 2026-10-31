#pragma once

#include <jni.h>

#ifdef __cplusplus
extern "C" {
#endif

JNIEXPORT jboolean JNICALL Java_com_openigi_projectigi_NativeEngine_nativeInit
  (JNIEnv *, jclass, jobject, jstring);

JNIEXPORT void JNICALL Java_com_openigi_projectigi_NativeEngine_nativeOnSurfaceCreated
  (JNIEnv *, jclass, jobject);

JNIEXPORT void JNICALL Java_com_openigi_projectigi_NativeEngine_nativeOnSurfaceChanged
  (JNIEnv *, jclass, jint, jint);

JNIEXPORT void JNICALL Java_com_openigi_projectigi_NativeEngine_nativeOnSurfaceDestroyed
  (JNIEnv *, jclass);

JNIEXPORT void JNICALL Java_com_openigi_projectigi_NativeEngine_nativeOnResume
  (JNIEnv *, jclass);

JNIEXPORT void JNICALL Java_com_openigi_projectigi_NativeEngine_nativeOnPause
  (JNIEnv *, jclass);

JNIEXPORT void JNICALL Java_com_openigi_projectigi_NativeEngine_nativeOnTouch
  (JNIEnv *, jclass, jint, jint, jfloat, jfloat);

JNIEXPORT void JNICALL Java_com_openigi_projectigi_NativeEngine_nativeStep
  (JNIEnv *, jclass);

JNIEXPORT void JNICALL Java_com_openigi_projectigi_NativeEngine_nativeShutdown
  (JNIEnv *, jclass);

JNIEXPORT void JNICALL Java_com_openigi_projectigi_NativeEngine_nativeSetTouchSensitivity
  (JNIEnv *, jclass, jfloat);

JNIEXPORT void JNICALL Java_com_openigi_projectigi_NativeEngine_nativeSetCheats
  (JNIEnv *, jclass, jboolean, jboolean, jboolean);

JNIEXPORT jint JNICALL Java_com_openigi_projectigi_NativeEngine_nativeLoadTexture
  (JNIEnv *, jclass, jint, jint, jbyteArray);

#ifdef __cplusplus
}
#endif
