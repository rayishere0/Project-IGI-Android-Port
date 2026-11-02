package com.projectigi.app;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.ContentValues;
import android.content.DialogInterface;
import android.content.pm.ActivityInfo;
import android.content.pm.PackageManager;
import android.content.res.AssetManager;
import android.content.res.Configuration;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.BlendMode;
import android.graphics.BlendModeColorFilter;
import android.graphics.Color;
import android.graphics.Typeface;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.provider.MediaStore;
import android.util.Log;
import android.view.Gravity;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.WindowInsets;
import android.view.WindowInsetsController;
import android.view.WindowManager;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;

public class MainActivity extends Activity implements SurfaceHolder.Callback {
    private static final String TAG = "ProjectIGI";
    private static final String ASSET_VERSION = "v18_logcat_exporter";

    private SurfaceView surfaceView;
    private FrameLayout rootLayout;
    private FrameLayout splashLayout;
    private TextView statusText;
    private ProgressBar progressBar;

    private boolean isExtracted = false;
    private boolean isGameStarted = false;
    private SurfaceHolder pendingHolder = null;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Force landscape orientation strictly (supports both landscape directions)
        setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE);

        // Keep screen on during gameplay
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        // Sustained performance mode (API 24+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            getWindow().setSustainedPerformanceMode(true);
        }

        rootLayout = new FrameLayout(this);
        rootLayout.setBackgroundColor(Color.BLACK);

        surfaceView = new SurfaceView(this);
        surfaceView.getHolder().addCallback(this);
        surfaceView.setOnTouchListener((v, event) -> onTouchEvent(event));
        rootLayout.addView(surfaceView, new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));

        // Authentic Project I.G.I. Loading Splash
        splashLayout = new FrameLayout(this);
        splashLayout.setBackgroundColor(Color.rgb(10, 12, 8)); // #0a0c08

        // 1. Background image (boot-bg.png)
        Bitmap bmp = null;
        for (String bgPath : new String[]{"public/boot-bg.png", "boot-bg.png", "Assets/boot-bg.png", "public/Assets/boot-bg.png"}) {
            try (InputStream is = getAssets().open(bgPath)) {
                bmp = BitmapFactory.decodeStream(is);
                if (bmp != null) {
                    Log.i(TAG, "Loaded splash background from: " + bgPath);
                    break;
                }
            } catch (Exception ignored) {}
        }
        if (bmp != null) {
            ImageView bgImage = new ImageView(this);
            bgImage.setImageBitmap(bmp);
            bgImage.setScaleType(ImageView.ScaleType.FIT_XY);
            splashLayout.addView(bgImage, new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));
        } else {
            Log.w(TAG, "Could not load splash background image");
        }

        // Center Bottom Progress & Status Wrap
        LinearLayout progressWrap = new LinearLayout(this);
        progressWrap.setOrientation(LinearLayout.VERTICAL);
        progressWrap.setGravity(Gravity.CENTER_HORIZONTAL);
        FrameLayout.LayoutParams wrapParams = new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT, FrameLayout.LayoutParams.WRAP_CONTENT);
        wrapParams.gravity = Gravity.CENTER_HORIZONTAL | Gravity.BOTTOM;
        wrapParams.bottomMargin = (int)(36 * getResources().getDisplayMetrics().density);

        // Glowing progress bar
        progressBar = new ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal);
        progressBar.setIndeterminate(true);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            progressBar.getIndeterminateDrawable().setColorFilter(
                new BlendModeColorFilter(Color.rgb(57, 227, 101), BlendMode.SRC_IN));
        }
        LinearLayout.LayoutParams pbParams = new LinearLayout.LayoutParams(
            (int)(360 * getResources().getDisplayMetrics().density),
            (int)(6 * getResources().getDisplayMetrics().density));
        pbParams.bottomMargin = (int)(10 * getResources().getDisplayMetrics().density);
        progressWrap.addView(progressBar, pbParams);

        statusText = new TextView(this);
        statusText.setTextColor(Color.rgb(109, 184, 74)); // #6db84a bright IGI green
        statusText.setTextSize(13);
        statusText.setTypeface(Typeface.MONOSPACE, Typeface.BOLD);
        statusText.setLetterSpacing(0.18f);
        statusText.setText("INITIALIZING PROJECT I.G.I. NATIVE ENGINE...");
        progressWrap.addView(statusText);

        splashLayout.addView(progressWrap, wrapParams);

        rootLayout.addView(splashLayout, new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));

        setContentView(rootLayout);

        // Apply immersive mode after view is attached
        applyImmersiveMode();

        // Start background asset preparation
        new Thread(this::prepareAssetsAndStart).start();
    }

    private void prepareAssetsAndStart() {
        File filesDir = getFilesDir();
        File marker = new File(filesDir, ".installed_" + ASSET_VERSION);

        if (!marker.exists()) {
            runOnUiThread(() -> statusText.setText("Extracting game assets & engine assemblies..."));
            Log.i(TAG, "Extracting assets to " + filesDir.getAbsolutePath());

            try {
                // Delete any older files/settings
                deleteRecursively(new File(filesDir, "managed"));
                deleteRecursively(new File(filesDir, "Project IGI"));
                deleteRecursively(new File(filesDir, "Assets"));
                deleteRecursively(new File(filesDir, ".config"));
                deleteRecursively(new File(filesDir, ".local"));
                deleteRecursively(new File(filesDir, "menu_images"));
                deleteRecursively(new File(filesDir, "loading_images"));
                deleteRecursively(new File(filesDir, "mission_images"));

                // Extract managed DLLs
                File managedDir = new File(filesDir, "managed");
                copyAssetFolder(getAssets(), "managed", managedDir);

                // Extract Project IGI data
                File dataDir = new File(filesDir, "Project IGI");
                copyAssetFolder(getAssets(), "public/Project IGI", dataDir);

                // Extract engine Assets (fonts, weather, UI images, materials)
                File assetsDir = new File(filesDir, "Assets");
                copyAssetFolder(getAssets(), "public/Assets", assetsDir);
                File managedAssetsDir = new File(managedDir, "Assets");
                copyAssetFolder(getAssets(), "public/Assets", managedAssetsDir);

                // Copy authentic ripped loading.png, boot-bg.png, and libopenal.so
                File[] imgDirs = new File[]{filesDir, dataDir, assetsDir, managedDir, managedAssetsDir};
                for (File d : imgDirs) {
                    copySingleAssetSafe("public/loading.png", new File(d, "loading.png"));
                    copySingleAssetSafe("public/boot-bg.png", new File(d, "boot-bg.png"));
                    copySingleAssetSafe("managed/libopenal.so", new File(d, "libopenal.so"));
                }

                marker.createNewFile();
                Log.i(TAG, "Assets extraction completed successfully.");
            } catch (Exception e) {
                Log.e(TAG, "Asset extraction error", e);
                runOnUiThread(() -> statusText.setText("Asset extraction failed: " + e.getMessage()));
                return;
            }
        } else {
            // Always keep managed assemblies and Assets up to date on app start
            try {
                File managedDir = new File(filesDir, "managed");
                copyAssetFolder(getAssets(), "managed", managedDir);

                File dataDir = new File(filesDir, "Project IGI");
                File assetsDir = new File(filesDir, "Assets");
                File managedAssetsDir = new File(managedDir, "Assets");

                File[] imgDirs = new File[]{filesDir, dataDir, assetsDir, managedDir, managedAssetsDir};
                for (File d : imgDirs) {
                    copySingleAssetSafe("public/loading.png", new File(d, "loading.png"));
                    copySingleAssetSafe("public/boot-bg.png", new File(d, "boot-bg.png"));
                    copySingleAssetSafe("managed/libopenal.so", new File(d, "libopenal.so"));
                }

                if (!assetsDir.exists()) {
                    copyAssetFolder(getAssets(), "public/Assets", assetsDir);
                }
                if (!managedAssetsDir.exists()) {
                    copyAssetFolder(getAssets(), "public/Assets", managedAssetsDir);
                }
            } catch (Exception e) {
                Log.w(TAG, "Managed/Assets sync error", e);
            }
        }

        isExtracted = true;
        runOnUiThread(() -> {
            statusText.setText("Asset loading complete. Starting renderer...");
            showLogcatExportPrompt();
            if (pendingHolder != null && !isGameStarted) {
                startGameWithHolder(pendingHolder);
            }
        });
    }

    private void showLogcatExportPrompt() {
        if (isFinishing() || (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1 && isDestroyed())) {
            return;
        }

        AlertDialog.Builder builder = new AlertDialog.Builder(this, android.R.style.Theme_DeviceDefault_Dialog_Alert);

        TextView titleView = new TextView(this);
        titleView.setText("DIAGNOSTICS & LOGCAT EXPORT");
        titleView.setTextColor(Color.rgb(57, 227, 101)); // #39e365
        titleView.setTextSize(16);
        titleView.setTypeface(Typeface.MONOSPACE, Typeface.BOLD);
        titleView.setPadding(40, 30, 40, 10);
        builder.setCustomTitle(titleView);

        TextView messageView = new TextView(this);
        messageView.setText("Do you want to fetch active Logcat runtime logs and export them as 'projectigi_logs.txt' into your Downloads folder for diagnostics?");
        messageView.setTextColor(Color.rgb(200, 230, 205));
        messageView.setTextSize(14);
        messageView.setTypeface(Typeface.MONOSPACE);
        messageView.setPadding(40, 10, 40, 20);
        builder.setView(messageView);

        builder.setPositiveButton("YES", (dialog, which) -> checkStoragePermissionAndExport());
        builder.setNegativeButton("NO", (dialog, which) -> dialog.dismiss());

        AlertDialog dialog = builder.create();
        if (dialog.getWindow() != null) {
            dialog.getWindow().setBackgroundDrawable(new android.graphics.drawable.ColorDrawable(Color.rgb(10, 24, 14)));
        }
        dialog.show();

        if (dialog.getButton(DialogInterface.BUTTON_POSITIVE) != null) {
            dialog.getButton(DialogInterface.BUTTON_POSITIVE).setTextColor(Color.rgb(57, 227, 101));
            dialog.getButton(DialogInterface.BUTTON_POSITIVE).setTypeface(Typeface.MONOSPACE, Typeface.BOLD);
        }
        if (dialog.getButton(DialogInterface.BUTTON_NEGATIVE) != null) {
            dialog.getButton(DialogInterface.BUTTON_NEGATIVE).setTextColor(Color.rgb(180, 190, 180));
            dialog.getButton(DialogInterface.BUTTON_NEGATIVE).setTypeface(Typeface.MONOSPACE);
        }
    }

    private void checkStoragePermissionAndExport() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            if (checkSelfPermission(android.Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
                requestPermissions(new String[]{android.Manifest.permission.WRITE_EXTERNAL_STORAGE}, 1001);
                return;
            }
        }
        exportLogcatToDownloads();
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == 1001) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                exportLogcatToDownloads();
            } else {
                Toast.makeText(this, "Storage permission denied; cannot export logs.", Toast.LENGTH_SHORT).show();
            }
        }
    }

    private void exportLogcatToDownloads() {
        new Thread(() -> {
            try {
                Process process = Runtime.getRuntime().exec("logcat -d -v time");
                BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
                StringBuilder logBuilder = new StringBuilder();
                String line;
                while ((line = reader.readLine()) != null) {
                    logBuilder.append(line).append("\n");
                }

                File downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS);
                if (!downloadsDir.exists()) {
                    downloadsDir.mkdirs();
                }

                File logFile = new File(downloadsDir, "projectigi_logs.txt");
                try (FileOutputStream fos = new FileOutputStream(logFile)) {
                    fos.write(logBuilder.toString().getBytes(StandardCharsets.UTF_8));
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    try {
                        ContentValues values = new ContentValues();
                        values.put(MediaStore.Downloads.DISPLAY_NAME, "projectigi_logs.txt");
                        values.put(MediaStore.Downloads.MIME_TYPE, "text/plain");
                        values.put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS);
                        getContentResolver().insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values);
                    } catch (Throwable ignored) {}
                }

                Log.i(TAG, "Logcat exported successfully to " + logFile.getAbsolutePath());
                runOnUiThread(() -> Toast.makeText(this, "Logs saved to Downloads/projectigi_logs.txt", Toast.LENGTH_LONG).show());
            } catch (Exception e) {
                Log.e(TAG, "Logcat export error", e);
                runOnUiThread(() -> Toast.makeText(this, "Failed to export logs: " + e.getMessage(), Toast.LENGTH_SHORT).show());
            }
        }).start();
    }

    private void deleteRecursively(File fileOrDir) {
        if (fileOrDir.isDirectory()) {
            File[] children = fileOrDir.listFiles();
            if (children != null) {
                for (File child : children) {
                    deleteRecursively(child);
                }
            }
        }
        fileOrDir.delete();
    }

    private void copyAssetFolder(AssetManager assetManager, String fromAssetPath, File targetFileOrDir) throws IOException {
        String[] list = assetManager.list(fromAssetPath);
        if (list == null || list.length == 0) {
            // Leaf file
            if (targetFileOrDir.getParentFile() != null) {
                targetFileOrDir.getParentFile().mkdirs();
            }
            try (InputStream in = assetManager.open(fromAssetPath);
                 OutputStream out = new FileOutputStream(targetFileOrDir)) {
                byte[] buffer = new byte[65536];
                int read;
                while ((read = in.read(buffer)) != -1) {
                    out.write(buffer, 0, read);
                }
            }
        } else {
            // Directory
            if (!targetFileOrDir.exists()) {
                targetFileOrDir.mkdirs();
            }
            for (String item : list) {
                String subFrom = fromAssetPath.isEmpty() ? item : fromAssetPath + "/" + item;
                File subTo = new File(targetFileOrDir, item);
                copyAssetFolder(assetManager, subFrom, subTo);
            }
        }
    }

    private void copySingleAssetSafe(String assetPath, File targetFile) {
        try {
            if (targetFile.getParentFile() != null) {
                targetFile.getParentFile().mkdirs();
            }
            InputStream in = null;
            try {
                in = getAssets().open(assetPath);
            } catch (Exception e1) {
                String alt = assetPath.startsWith("public/") ? assetPath.substring(7) : "public/" + assetPath;
                try {
                    in = getAssets().open(alt);
                } catch (Exception ignored) {}
            }
            if (in == null) return;
            try (InputStream is = in;
                 OutputStream out = new FileOutputStream(targetFile)) {
                byte[] buffer = new byte[65536];
                int read;
                while ((read = is.read(buffer)) != -1) {
                    out.write(buffer, 0, read);
                }
            }
        } catch (Exception ignored) {}
    }

    private synchronized void startGameWithHolder(SurfaceHolder holder) {
        if (isGameStarted) return;
        isGameStarted = true;

        // Hide splash after starting
        runOnUiThread(() -> {
            if (splashLayout != null) {
                splashLayout.setVisibility(View.GONE);
            }
        });

        int width = surfaceView.getWidth();
        int height = surfaceView.getHeight();
        if (width <= 0) width = getResources().getDisplayMetrics().widthPixels;
        if (height <= 0) height = getResources().getDisplayMetrics().heightPixels;

        int landscapeWidth = Math.max(width, height);
        int landscapeHeight = Math.min(width, height);

        String filesDir = getFilesDir().getAbsolutePath();
        String nativeLibDir = getApplicationInfo().nativeLibraryDir;

        Log.i(TAG, "Calling nativeStartGame: " + landscapeWidth + "x" + landscapeHeight);
        NativeEngine.nativeStartGame(holder.getSurface(), landscapeWidth, landscapeHeight, filesDir, nativeLibDir, "");
    }

    @Override
    public void surfaceCreated(SurfaceHolder holder) {
        Log.i(TAG, "surfaceCreated");
        pendingHolder = holder;
        if (isExtracted && !isGameStarted) {
            startGameWithHolder(holder);
        }
    }

    @Override
    public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
        int landscapeWidth = Math.max(width, height);
        int landscapeHeight = Math.min(width, height);
        Log.i(TAG, "surfaceChanged: " + landscapeWidth + "x" + landscapeHeight);
        NativeEngine.nativeOnSurfaceChanged(landscapeWidth, landscapeHeight);
    }

    @Override
    public void surfaceDestroyed(SurfaceHolder holder) {
        Log.i(TAG, "surfaceDestroyed");
        NativeEngine.nativeOnSurfaceDestroyed();
        isGameStarted = false;
        pendingHolder = null;
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        final int actionMasked = event.getActionMasked();
        final int actionIndex = event.getActionIndex();
        int pointerId = event.getPointerId(actionIndex);
        float x = event.getX(actionIndex);
        float y = event.getY(actionIndex);

        if (actionMasked == MotionEvent.ACTION_MOVE) {
            int pointerCount = event.getPointerCount();
            for (int i = 0; i < pointerCount; i++) {
                NativeEngine.nativeOnTouch(MotionEvent.ACTION_MOVE, event.getPointerId(i), event.getX(i), event.getY(i));
            }
        } else {
            NativeEngine.nativeOnTouch(actionMasked, pointerId, x, y);
        }
        return true;
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        if (keyCode == KeyEvent.KEYCODE_BACK) {
            NativeEngine.nativeOnKey(4, true);
            surfaceView.postDelayed(() -> NativeEngine.nativeOnKey(4, false), 50);
            return true;
        }
        NativeEngine.nativeOnKey(keyCode, true);
        return super.onKeyDown(keyCode, event);
    }

    @Override
    public boolean onKeyUp(int keyCode, KeyEvent event) {
        NativeEngine.nativeOnKey(keyCode, false);
        return super.onKeyUp(keyCode, event);
    }

    @Override
    public void onBackPressed() {
        NativeEngine.nativeOnKey(4, true);
        surfaceView.postDelayed(() -> NativeEngine.nativeOnKey(4, false), 50);
    }

    @Override
    public void onConfigurationChanged(Configuration newConfig) {
        super.onConfigurationChanged(newConfig);
        applyImmersiveMode();
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) {
            applyImmersiveMode();
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        NativeEngine.nativeShutdown();
    }

    private void applyImmersiveMode() {
        View decorView = getWindow().getDecorView();
        if (decorView == null) return;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                WindowInsetsController controller = decorView.getWindowInsetsController();
                if (controller != null) {
                    controller.hide(WindowInsets.Type.statusBars() | WindowInsets.Type.navigationBars());
                    controller.setSystemBarsBehavior(WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
                }
            } catch (Throwable ignored) {}
        } else {
            decorView.setSystemUiVisibility(
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                | View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_FULLSCREEN);
        }
    }
}
