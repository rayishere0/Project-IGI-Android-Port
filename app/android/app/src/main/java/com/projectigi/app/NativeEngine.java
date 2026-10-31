package com.projectigi.app;

import android.util.Log;
import android.view.Surface;

/**
 * Java interface to the native C++ OpenIGI Engine (libopenigi.so) hosting CoreCLR and Vulkan.
 */
public final class NativeEngine {
    private static final String TAG = "OpenIGI";

    static {
        try {
            System.loadLibrary("openigi");
            Log.i(TAG, "Successfully loaded native NDK library libopenigi.so");
        } catch (UnsatisfiedLinkError e) {
            Log.e(TAG, "Failed to load native library libopenigi.so", e);
        }
    }

    public static native boolean nativeStartGame(
        Surface surface,
        int width,
        int height,
        String filesDir,
        String nativeLibDir,
        String options
    );

    public static native void nativeOnSurfaceChanged(int width, int height);
    public static native void nativeOnSurfaceDestroyed();
    public static native void nativeOnTouch(int action, int pointerId, float x, float y);
    public static native void nativeOnKey(int keyCode, boolean down);
    public static native void nativeShutdown();

    private NativeEngine() {}
}
