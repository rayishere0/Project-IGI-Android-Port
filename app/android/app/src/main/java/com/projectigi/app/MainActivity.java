package com.projectigi.app;

import android.app.Activity;
import android.content.ContentValues;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.ActivityInfo;
import android.content.pm.PackageManager;
import android.content.res.AssetManager;
import android.content.res.ColorStateList;
import android.content.res.Configuration;
import android.graphics.Bitmap;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.hardware.input.InputManager;
import android.os.Handler;
import android.os.Looper;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.inputmethod.InputMethodManager;
import android.widget.EditText;
import android.graphics.BitmapFactory;
import android.graphics.BlendMode;
import android.graphics.BlendModeColorFilter;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.SystemClock;
import android.provider.MediaStore;
import android.util.Log;
import android.view.Gravity;
import android.view.InputDevice;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.WindowInsets;
import android.view.WindowInsetsController;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.documentfile.provider.DocumentFile;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.util.Locale;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class MainActivity extends Activity implements SurfaceHolder.Callback {
    private static final String TAG = "ProjectIGI";
    private static final String ASSET_VERSION = "v22_perm_on_start";
    private static final int REQUEST_SELECT_GAME_FOLDER = 2001;
    private static final int REQUEST_SELECT_CONTENT_PACK = 2002;
    private static final int REQUEST_STORAGE_PERMISSIONS = 1002;
    private static final int REQUEST_MICROPHONE = 1003;
    private static final String PREFS_NAME = "projectigi_prefs";
    private static final String PREF_RENDERER_BACKEND = "renderer_backend";

    // Whether RECORD_AUDIO has been asked for, or is already granted, this run: asked once,
    // at the first voice use, never again while the app runs. Denied stays denied until the
    // player re-grants it in system settings; voice send stays off meanwhile and nothing else
    // breaks.
    private boolean micPermissionRequested = false;

    // Content packs live in app-private storage, next to the game data: the engine only ever does
    // plain System.IO, so a pack has to be a real directory, and a folder beside the picked retail
    // folder on shared storage is unreadable to it. The profile is handed to the engine through the
    // options string (-contentprofile); it lives directly under getFilesDir() rather than inside
    // "Project IGI" because that name has a space in it and the options string splits on spaces.
    private static final String CONTENT_DIR_NAME = "content";
    private static final String CONTENT_PROFILE_NAME = "content-profile.json";
    private static final String LOCAL_LAYER_ID = "local";
    private static final String LOCAL_LAYER_NAME = "Local overrides (game folder)";

    private SurfaceView surfaceView;
    private FrameLayout rootLayout;
    private FrameLayout splashLayout;
    private TextView statusText;
    private ProgressBar progressBar;
    private Button selectFolderBtn;
    private Button playBtn;
    private Button vulkanBtn;
    private Button webGpuBtn;
    private Button installPackBtn;
    private Button disableContentBtn;
    private String rendererBackend = "vulkan";

    // Which install the progress bar is reporting, so a pack install does not claim to install game files.
    private String copyStatusLabel = "INSTALLING GAME FILES... ";

    private boolean isExtracted = false;
    private boolean isGameFolderVerified = false;
    private boolean isGameStarted = false;
    private SurfaceHolder pendingHolder = null;

    // Total / copied bytes for the game-folder install, driving the determinate progress bar.
    private long copyTotalBytes = 0;
    private long copyDoneBytes = 0;
    // Last time the progress bar was redrawn (uptime ms), to throttle UI updates.
    private long lastProgressUiMs = 0;
    // Gyroscope aim: the sensor and its listener, and the last event timestamp (ns)
    // so rates (rad/s) integrate into per-event angle deltas.
    private SensorManager sensorManager;
    private Sensor gyroSensor;
    private SensorEventListener gyroListener;
    private long lastGyroTimestampNs = 0;
    // Gamepad: hot-plug detection and stick/trigger axes. The first gamepad found
    // wins: with two pads connected only its buttons and axes reach the game.
    private InputManager inputManager;
    private InputManager.InputDeviceListener gamepadListener;
    private int activeGamepadId = -1;
    private boolean gamepadConnected = false;
    // Last D-pad-as-axes (HAT) position, for pads that report the D-pad as axes
    // instead of keys: transitions are synthesised into DPAD key events below.
    private int prevHatX = 0;
    private int prevHatY = 0;
    // Soft keyboard: a hidden, zero-size EditText the IME types into, and a poller
    // that shows/hides the keyboard when the game focuses a text field.
    private EditText hiddenInput;
    private Handler imeHandler;
    private Runnable imePoller;
    private boolean imeShown = false;
    // True while this Activity is in the foreground. The quit watcher uses it to tell a Quit
    // in the main menu (foreground, game stops) from tabbing out (backgrounded, game stops too).
    private boolean isResumed = false;
    // Watches for the game thread ending while we are in the foreground (a Quit), so Quit in
    // the main menu closes the app instead of leaving a black screen behind.
    private volatile boolean quitWatcherStopped = false;
    private Thread quitWatcherThread = null;

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

        // Handle offline intent extras/saved state strictly null-safe to prevent crash
        String fallbackGameDir = getFilesDir().getAbsolutePath();
        String gameDir = fallbackGameDir;
        String engineMode = "normal";

        if (savedInstanceState != null) {
            try {
                String safeExtra = savedInstanceState.getString("engine_mode");
                if (safeExtra != null) {
                    engineMode = safeExtra;
                }
            } catch (Throwable e) {
                Log.w(TAG, "Safe savedInstanceState extra read bypassed.");
            }
        }

        Intent intent = getIntent();
        if (intent != null) {
            try {
                Bundle extras = intent.getExtras();
                if (extras != null) {
                    String targetMap = extras.getString("map_name");
                    if (targetMap == null) {
                        targetMap = "default";
                        Log.d(TAG, "map_name intent string is null, using fallback game directory: " + fallbackGameDir);
                    }
                    String customDir = extras.getString("game_dir");
                    if (customDir != null) {
                        gameDir = customDir;
                    }
                } else {
                    Log.w(TAG, "Intent bundle is null, explicitly falling back to default string.");
                    gameDir = "/data/user/0/com.projectigi.app/files";
                }
            } catch (Throwable e) {
                Log.e(TAG, "Failed to parse intent bundle safely.", e);
                gameDir = "/data/user/0/com.projectigi.app/files";
            }
        } else {
            gameDir = "/data/user/0/com.projectigi.app/files";
        }

        // Request storage permissions on app startup
        requestStoragePermissionsOnStart();

        // Restore the saved renderer backend (default: Vulkan)
        rendererBackend = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
            .getString(PREF_RENDERER_BACKEND, "vulkan");
        if (!"webgpu".equals(rendererBackend)) rendererBackend = "vulkan";

        rootLayout = new FrameLayout(this);
        rootLayout.setBackgroundColor(Color.BLACK);

        surfaceView = new SurfaceView(this);
        surfaceView.getHolder().setFormat(android.graphics.PixelFormat.RGBA_8888);
        surfaceView.getHolder().addCallback(this);
        surfaceView.setOnTouchListener((v, event) -> onTouchEvent(event));
        rootLayout.addView(surfaceView, new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));

        setupGyroAndKeyboard();
        setupGamepad();

        // Authentic Project I.G.I. Launcher Splash
        splashLayout = new FrameLayout(this);
        splashLayout.setBackgroundColor(Color.rgb(10, 12, 8)); // #0a0c08

        // 1. Background image (img.png)
        Bitmap bmp = null;
        for (String bgPath : new String[]{"img.png", "public/img.png", "public/boot-bg.png", "boot-bg.png"}) {
            try (InputStream is = getAssets().open(bgPath)) {
                bmp = BitmapFactory.decodeStream(is);
                if (bmp != null) {
                    Log.i(TAG, "Loaded launcher background from: " + bgPath);
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
        }

        // Center Tactical Card Container
        float density = getResources().getDisplayMetrics().density;
        LinearLayout cardLayout = new LinearLayout(this);
        cardLayout.setOrientation(LinearLayout.VERTICAL);
        cardLayout.setGravity(Gravity.CENTER_HORIZONTAL);
        cardLayout.setPadding((int)(32 * density), (int)(24 * density), (int)(32 * density), (int)(24 * density));

        // Dark tactical translucent background with green border
        GradientDrawable cardBg = new GradientDrawable();
        cardBg.setColor(Color.argb(225, 10, 22, 14)); // Translucent dark green
        cardBg.setStroke((int)(2 * density), Color.rgb(57, 227, 101)); // Phosphor green
        cardBg.setCornerRadius(10 * density);
        cardLayout.setBackground(cardBg);

        FrameLayout.LayoutParams cardParams = new FrameLayout.LayoutParams(
            (int)(540 * density), FrameLayout.LayoutParams.WRAP_CONTENT);
        cardParams.gravity = Gravity.CENTER;

        // Title
        TextView titleText = new TextView(this);
        titleText.setTextColor(Color.rgb(57, 227, 101));
        titleText.setTextSize(18);
        titleText.setTypeface(Typeface.MONOSPACE, Typeface.BOLD);
        titleText.setLetterSpacing(0.12f);
        titleText.setGravity(Gravity.CENTER);
        titleText.setText("PROJECT I.G.I.: I'M GOING IN");
        cardLayout.addView(titleText);

        // Subtitle
        TextView subtitleText = new TextView(this);
        subtitleText.setTextColor(Color.rgb(180, 205, 185));
        subtitleText.setTextSize(11);
        subtitleText.setTypeface(Typeface.MONOSPACE);
        subtitleText.setGravity(Gravity.CENTER);
        subtitleText.setPadding(0, (int)(4 * density), 0, (int)(16 * density));
        subtitleText.setText("AUTHENTIC GAME FILES REQUIRED");
        cardLayout.addView(subtitleText);

        // Glowing progress bar
        progressBar = new ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal);
        progressBar.setIndeterminate(true);
        progressBar.setProgressTintList(ColorStateList.valueOf(Color.rgb(57, 227, 101)));
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            progressBar.getIndeterminateDrawable().setColorFilter(
                new BlendModeColorFilter(Color.rgb(57, 227, 101), BlendMode.SRC_IN));
        }
        LinearLayout.LayoutParams pbParams = new LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, (int)(5 * density));
        pbParams.bottomMargin = (int)(12 * density);
        cardLayout.addView(progressBar, pbParams);

        // Status Message Text
        statusText = new TextView(this);
        statusText.setTextColor(Color.rgb(109, 184, 74));
        statusText.setTextSize(12);
        statusText.setTypeface(Typeface.MONOSPACE, Typeface.BOLD);
        statusText.setGravity(Gravity.CENTER);
        statusText.setPadding(0, 0, 0, (int)(18 * density));
        statusText.setText("INITIALIZING SYSTEM ASSEMBLIES...");
        cardLayout.addView(statusText);

        // Renderer selector: the backend the engine starts on (Vulkan or WebGPU)
        TextView rendererLabel = new TextView(this);
        rendererLabel.setTextColor(Color.rgb(180, 205, 185));
        rendererLabel.setTextSize(10);
        rendererLabel.setTypeface(Typeface.MONOSPACE, Typeface.BOLD);
        rendererLabel.setGravity(Gravity.CENTER);
        rendererLabel.setLetterSpacing(0.12f);
        rendererLabel.setPadding(0, 0, 0, (int)(6 * density));
        rendererLabel.setText("RENDERER");
        cardLayout.addView(rendererLabel);

        LinearLayout rendererRow = new LinearLayout(this);
        rendererRow.setOrientation(LinearLayout.HORIZONTAL);
        rendererRow.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams rendererRowParams = new LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        rendererRowParams.bottomMargin = (int)(14 * density);
        cardLayout.addView(rendererRow, rendererRowParams);

        vulkanBtn = new Button(this);
        vulkanBtn.setText("VULKAN");
        vulkanBtn.setTextSize(11);
        vulkanBtn.setTypeface(Typeface.MONOSPACE, Typeface.BOLD);
        LinearLayout.LayoutParams vulkanLp = new LinearLayout.LayoutParams(
            (int)(160 * density), (int)(40 * density));
        vulkanLp.rightMargin = (int)(12 * density);
        vulkanBtn.setOnClickListener(v -> setRendererBackend("vulkan"));
        rendererRow.addView(vulkanBtn, vulkanLp);

        webGpuBtn = new Button(this);
        webGpuBtn.setText("WEBGPU");
        webGpuBtn.setTextSize(11);
        webGpuBtn.setTypeface(Typeface.MONOSPACE, Typeface.BOLD);
        LinearLayout.LayoutParams webGpuLp = new LinearLayout.LayoutParams(
            (int)(160 * density), (int)(40 * density));
        webGpuBtn.setOnClickListener(v -> setRendererBackend("webgpu"));
        rendererRow.addView(webGpuBtn, webGpuLp);

        updateRendererButtons();

        // Buttons Layout Row
        LinearLayout btnRow = new LinearLayout(this);
        btnRow.setOrientation(LinearLayout.HORIZONTAL);
        btnRow.setGravity(Gravity.CENTER);

        // 1. Select Game Folder Button
        selectFolderBtn = new Button(this);
        selectFolderBtn.setText("SELECT GAME FOLDER");
        selectFolderBtn.setTextSize(11);
        selectFolderBtn.setTypeface(Typeface.MONOSPACE, Typeface.BOLD);
        selectFolderBtn.setTextColor(Color.WHITE);

        GradientDrawable selectBg = new GradientDrawable();
        selectBg.setColor(Color.rgb(20, 52, 28));
        selectBg.setStroke((int)(1.5f * density), Color.rgb(57, 227, 101));
        selectBg.setCornerRadius(6 * density);
        selectFolderBtn.setBackground(selectBg);

        LinearLayout.LayoutParams selectLp = new LinearLayout.LayoutParams(
            (int)(220 * density), (int)(44 * density));
        selectLp.rightMargin = (int)(12 * density);
        selectFolderBtn.setOnClickListener(v -> openGameFolderPicker());
        btnRow.addView(selectFolderBtn, selectLp);

        // 2. Play Button
        playBtn = new Button(this);
        playBtn.setText("PLAY");
        playBtn.setTextSize(13);
        playBtn.setTypeface(Typeface.MONOSPACE, Typeface.BOLD);

        LinearLayout.LayoutParams playLp = new LinearLayout.LayoutParams(
            (int)(160 * density), (int)(44 * density));
        playBtn.setOnClickListener(v -> onPlayButtonClicked());
        btnRow.addView(playBtn, playLp);

        cardLayout.addView(btnRow);

        // Content row: install a pack, or switch every pack off. Neither needs the game folder: packs
        // live in their own folder, and switching them off is the recovery when a pack breaks the menu.
        LinearLayout contentBtnRow = new LinearLayout(this);
        contentBtnRow.setOrientation(LinearLayout.HORIZONTAL);
        contentBtnRow.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams contentRowParams = new LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        contentRowParams.topMargin = (int)(12 * density);
        cardLayout.addView(contentBtnRow, contentRowParams);

        installPackBtn = new Button(this);
        installPackBtn.setText("INSTALL CONTENT PACK");
        installPackBtn.setTextSize(11);
        installPackBtn.setTypeface(Typeface.MONOSPACE, Typeface.BOLD);
        installPackBtn.setTextColor(Color.WHITE);

        GradientDrawable installBg = new GradientDrawable();
        installBg.setColor(Color.rgb(20, 52, 28));
        installBg.setStroke((int)(1.5f * density), Color.rgb(57, 227, 101));
        installBg.setCornerRadius(6 * density);
        installPackBtn.setBackground(installBg);

        LinearLayout.LayoutParams installLp = new LinearLayout.LayoutParams(
            (int)(220 * density), (int)(44 * density));
        installLp.rightMargin = (int)(12 * density);
        installPackBtn.setOnClickListener(v -> openContentPackPicker());
        contentBtnRow.addView(installPackBtn, installLp);

        disableContentBtn = new Button(this);
        disableContentBtn.setText("DISABLE ALL CONTENT");
        disableContentBtn.setTextSize(11);
        disableContentBtn.setTypeface(Typeface.MONOSPACE, Typeface.BOLD);
        disableContentBtn.setTextColor(Color.WHITE);

        GradientDrawable disableBg = new GradientDrawable();
        disableBg.setColor(Color.rgb(20, 52, 28));
        disableBg.setStroke((int)(1.5f * density), Color.rgb(57, 227, 101));
        disableBg.setCornerRadius(6 * density);
        disableContentBtn.setBackground(disableBg);

        LinearLayout.LayoutParams disableLp = new LinearLayout.LayoutParams(
            (int)(160 * density), (int)(44 * density));
        disableContentBtn.setOnClickListener(v -> disableAllContent());
        contentBtnRow.addView(disableContentBtn, disableLp);

        splashLayout.addView(cardLayout, cardParams);

        rootLayout.addView(splashLayout, new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));

        setContentView(rootLayout);

        // Disable Play button by default
        updatePlayButtonState(false);

        // Apply immersive mode after view is attached
        applyImmersiveMode();

        // Start background asset preparation
        new Thread(this::prepareAssetsAndStart).start();
    }

    private void requestStoragePermissionsOnStart() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            if (checkSelfPermission(android.Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED
                || checkSelfPermission(android.Manifest.permission.READ_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
                requestPermissions(new String[]{
                    android.Manifest.permission.WRITE_EXTERNAL_STORAGE,
                    android.Manifest.permission.READ_EXTERNAL_STORAGE
                }, REQUEST_STORAGE_PERMISSIONS);
            }
        }
    }

    // Co-op voice, at first voice use: the managed side raises MicrophoneRequested the first
    // time voice wants the microphone (push to talk held, or open mic), and this poller — the
    // same 250 ms poller that shows the IME — asks for RECORD_AUDIO once. The grant needs no
    // callback here: the managed mic-open attempt returns null while ungranted and succeeds
    // once granted, so voice send starts working on its own. Denied means voice send stays
    // off; hearing the others and text chat still work.
    private void requestMicrophonePermissionIfWanted() {
        if (micPermissionRequested || !isGameStarted) {
            return;
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return;
        }
        if (checkSelfPermission(android.Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) {
            micPermissionRequested = true;
            return;
        }
        if (!NativeEngine.nativeIsMicrophoneRequested()) {
            return;
        }
        micPermissionRequested = true;
        requestPermissions(new String[]{
            android.Manifest.permission.RECORD_AUDIO
        }, REQUEST_MICROPHONE);
    }

    private void updatePlayButtonState(boolean enabled) {
        isGameFolderVerified = enabled;
        float density = getResources().getDisplayMetrics().density;
        runOnUiThread(() -> {
            playBtn.setEnabled(enabled);
            GradientDrawable playBg = new GradientDrawable();
            playBg.setCornerRadius(6 * density);

            if (enabled) {
                playBg.setColor(Color.rgb(57, 227, 101)); // Phosphor green
                playBg.setStroke((int)(2 * density), Color.rgb(180, 255, 195));
                playBtn.setTextColor(Color.BLACK);
            } else {
                playBg.setColor(Color.rgb(38, 48, 40)); // Disabled dark grey
                playBg.setStroke((int)(1 * density), Color.rgb(65, 80, 68));
                playBtn.setTextColor(Color.rgb(100, 120, 105));
            }
            playBtn.setBackground(playBg);
        });
    }

    private void setRendererBackend(String backend) {
        rendererBackend = "webgpu".equals(backend) ? "webgpu" : "vulkan";
        getSharedPreferences(PREFS_NAME, MODE_PRIVATE).edit()
            .putString(PREF_RENDERER_BACKEND, rendererBackend).apply();
        updateRendererButtons();
    }

    private void updateRendererButtons() {
        if (vulkanBtn == null || webGpuBtn == null) return;
        float density = getResources().getDisplayMetrics().density;
        styleRendererButton(vulkanBtn, "vulkan".equals(rendererBackend), density);
        styleRendererButton(webGpuBtn, "webgpu".equals(rendererBackend), density);
    }

    private void styleRendererButton(Button btn, boolean selected, float density) {
        GradientDrawable bg = new GradientDrawable();
        bg.setCornerRadius(6 * density);
        if (selected) {
            bg.setColor(Color.rgb(57, 227, 101)); // Phosphor green
            bg.setStroke((int)(2 * density), Color.rgb(180, 255, 195));
            btn.setTextColor(Color.BLACK);
        } else {
            bg.setColor(Color.rgb(20, 52, 28)); // Dark green
            bg.setStroke((int)(1 * density), Color.rgb(65, 80, 68));
            btn.setTextColor(Color.rgb(100, 120, 105));
        }
        btn.setBackground(bg);
    }

    private void prepareAssetsAndStart() {
        File filesDir = getFilesDir();
        File marker = new File(filesDir, ".installed_" + ASSET_VERSION);

        if (!marker.exists()) {
            runOnUiThread(() -> statusText.setText("Extracting system assemblies..."));
            Log.i(TAG, "Extracting managed assets to " + filesDir.getAbsolutePath());

            try {
                // Delete managed assemblies
                deleteRecursively(new File(filesDir, "managed"));
                deleteRecursively(new File(filesDir, "Assets"));

                // Extract managed DLLs
                File managedDir = new File(filesDir, "managed");
                copyAssetFolder(getAssets(), "managed", managedDir);

                // Extract engine Assets (fonts, weather, UI images, materials)
                File assetsDir = new File(filesDir, "Assets");
                copyAssetFolder(getAssets(), "public/Assets", assetsDir);
                File managedAssetsDir = new File(managedDir, "Assets");
                copyAssetFolder(getAssets(), "public/Assets", managedAssetsDir);

                // Copy authentic ripped loading.png, boot-bg.png, img.png and libopenal.so
                File[] imgDirs = new File[]{filesDir, assetsDir, managedDir, managedAssetsDir};
                for (File d : imgDirs) {
                    copySingleAssetSafe("img.png", new File(d, "img.png"));
                    copySingleAssetSafe("public/loading.png", new File(d, "loading.png"));
                    copySingleAssetSafe("public/boot-bg.png", new File(d, "boot-bg.png"));
                    copySingleAssetSafe("managed/libopenal.so", new File(d, "libopenal.so"));
                }

                marker.createNewFile();
                Log.i(TAG, "Managed assemblies extraction completed.");
            } catch (Exception e) {
                Log.e(TAG, "Managed extraction error", e);
                runOnUiThread(() -> statusText.setText("Extraction error: " + e.getMessage()));
                return;
            }
        } else {
            try {
                File managedDir = new File(filesDir, "managed");
                copyAssetFolder(getAssets(), "managed", managedDir);
                File assetsDir = new File(filesDir, "Assets");
                File managedAssetsDir = new File(managedDir, "Assets");

                if (!assetsDir.exists()) {
                    copyAssetFolder(getAssets(), "public/Assets", assetsDir);
                }
                if (!managedAssetsDir.exists()) {
                    copyAssetFolder(getAssets(), "public/Assets", managedAssetsDir);
                }
            } catch (Exception e) {
                Log.w(TAG, "Managed sync error", e);
            }
        }

        isExtracted = true;

        // The content profile the engine is handed on launch: created here, on first run, with just the
        // game folder's own overrides in it, so the game never depends on a pack having been installed.
        ensureContentProfile();

        // Check if game folder already exists and is verified
        boolean hasExistingGame = checkExistingGameFolder();
        runOnUiThread(() -> {
            if (hasExistingGame) {
                statusText.setText("GAME FILES VERIFIED & READY!");
                updatePlayButtonState(true);
            } else {
                statusText.setText("SELECT GAME FOLDER TO CONTINUE");
                updatePlayButtonState(false);
            }
        });
    }

    private boolean checkExistingGameFolder() {
        File dataDir = new File(getFilesDir(), "Project IGI");
        if (!dataDir.exists() || !dataDir.isDirectory()) {
            return false;
        }

        // Verify presence of signature Project I.G.I. folders/files
        int matches = 0;
        String[] signatureItems = new String[]{
            "common", "missions", "weapons", "menusystem", "sounds", "humanplayer", "config.qvm", "igi.exe"
        };

        File[] files = dataDir.listFiles();
        if (files == null) return false;

        for (File f : files) {
            String name = f.getName().toLowerCase();
            for (String sig : signatureItems) {
                if (name.equals(sig)) {
                    matches++;
                    break;
                }
            }
        }

        return matches >= 3;
    }

    private void openGameFolderPicker() {
        try {
            Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT_TREE);
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION);
            startActivityForResult(intent, REQUEST_SELECT_GAME_FOLDER);
        } catch (Exception e) {
            Log.e(TAG, "Failed to open folder picker", e);
            Toast.makeText(this, "Failed to open storage folder picker", Toast.LENGTH_SHORT).show();
        }
    }

    // A pack is a folder mirroring the game's paths, picked the same way the game folder is: the
    // system picker hands back a tree, and the tree is copied into app-private storage, because the
    // engine reads plain files and a SAF URI is not a path.
    private void openContentPackPicker() {
        try {
            Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT_TREE);
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION);
            startActivityForResult(intent, REQUEST_SELECT_CONTENT_PACK);
        } catch (Exception e) {
            Log.e(TAG, "Failed to open folder picker", e);
            Toast.makeText(this, "Failed to open storage folder picker", Toast.LENGTH_SHORT).show();
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == REQUEST_SELECT_GAME_FOLDER && resultCode == RESULT_OK && data != null) {
            Uri treeUri = data.getData();
            if (treeUri != null) {
                try {
                    getContentResolver().takePersistableUriPermission(
                        treeUri, Intent.FLAG_GRANT_READ_URI_PERMISSION);
                } catch (Exception ignored) {}

                statusText.setText("VERIFYING GAME FOLDER STRUCTURE...");
                progressBar.setVisibility(View.VISIBLE);
                new Thread(() -> processAndCopyGameFolder(treeUri)).start();
            }
        }
        if (requestCode == REQUEST_SELECT_CONTENT_PACK && resultCode == RESULT_OK && data != null) {
            Uri treeUri = data.getData();
            if (treeUri != null) {
                try {
                    getContentResolver().takePersistableUriPermission(
                        treeUri, Intent.FLAG_GRANT_READ_URI_PERMISSION);
                } catch (Exception ignored) {}

                statusText.setText("VERIFYING CONTENT PACK...");
                progressBar.setVisibility(View.VISIBLE);
                new Thread(() -> processAndCopyContentPack(treeUri)).start();
            }
        }
    }

    private void processAndCopyGameFolder(Uri treeUri) {
        DocumentFile rootDoc = DocumentFile.fromTreeUri(this, treeUri);
        if (rootDoc == null || !rootDoc.exists() || !rootDoc.isDirectory()) {
            runOnUiThread(() -> {
                statusText.setText("INVALID FOLDER SELECTED");
                Toast.makeText(this, "Could not access selected folder", Toast.LENGTH_SHORT).show();
            });
            return;
        }

        // 1. Verify Project I.G.I. folder signatures
        DocumentFile[] children = rootDoc.listFiles();
        int matches = 0;
        String[] signatureItems = new String[]{
            "common", "missions", "weapons", "menusystem", "sounds", "humanplayer", "config.qvm", "igi.exe"
        };

        for (DocumentFile child : children) {
            if (child.getName() != null) {
                String name = child.getName().toLowerCase();
                for (String sig : signatureItems) {
                    if (name.equals(sig)) {
                        matches++;
                        break;
                    }
                }
            }
        }

        if (matches < 2) {
            runOnUiThread(() -> {
                statusText.setText("INVALID GAME FOLDER");
                Toast.makeText(this, "Missing authentic Project I.G.I. game files in selected folder", Toast.LENGTH_LONG).show();
            });
            return;
        }

        // 2. Copy files from SAF tree to internal getFilesDir()/Project IGI
        // First count the total bytes (a metadata-only traversal, no byte transfer),
        // so the progress bar can show real percent instead of spinning.
        runOnUiThread(() -> statusText.setText("COUNTING GAME FILES..."));
        copyStatusLabel = "INSTALLING GAME FILES... ";
        copyTotalBytes = countTreeBytes(rootDoc);
        copyDoneBytes = 0;
        lastProgressUiMs = 0;
        runOnUiThread(() -> {
            progressBar.setIndeterminate(false);
            progressBar.setMax(100);
            progressBar.setProgress(0);
            statusText.setText("INSTALLING GAME FILES... 0%");
        });

        File targetDataDir = new File(getFilesDir(), "Project IGI");
        try {
            if (!targetDataDir.exists()) {
                targetDataDir.mkdirs();
            }
            copyDocumentTree(rootDoc, targetDataDir);

            Log.i(TAG, "Game files successfully copied and verified.");
            runOnUiThread(() -> {
                progressBar.setProgress(100);
                statusText.setText("GAME FILES VERIFIED & READY!");
                updatePlayButtonState(true);
                Toast.makeText(this, "Project I.G.I. game files installed successfully!", Toast.LENGTH_LONG).show();
            });
        } catch (Exception e) {
            Log.e(TAG, "Failed to copy game files", e);
            runOnUiThread(() -> {
                statusText.setText("COPY ERROR: " + e.getMessage());
                Toast.makeText(this, "Failed to copy game files: " + e.getMessage(), Toast.LENGTH_SHORT).show();
            });
        }
    }

    // Sums a SAF tree's bytes without copying anything, so the install can show a
    // real determinate progress bar. Metadata-only (listFiles + length), no streams.
    private long countTreeBytes(DocumentFile doc) {
        long total = 0;
        DocumentFile[] files = doc.listFiles();
        for (DocumentFile file : files) {
            if (file.isDirectory()) {
                total += countTreeBytes(file);
            } else if (file.isFile()) {
                total += Math.max(0, file.length());
            }
        }
        return total;
    }

    // Reports copy progress to the UI thread, throttled so the bar is redrawn at
    // most ~7 times a second (the final 100% always goes through).
    private void reportCopyProgress() {
        if (copyTotalBytes <= 0) {
            return;
        }
        long now = SystemClock.uptimeMillis();
        int pct = (int) Math.min(100, (copyDoneBytes * 100L) / copyTotalBytes);
        if (pct < 100 && now - lastProgressUiMs < 150) {
            return;
        }
        lastProgressUiMs = now;
        final int p = pct;
        final long done = copyDoneBytes;
        final long total = copyTotalBytes;
        final String label = copyStatusLabel;
        runOnUiThread(() -> {
            progressBar.setProgress(p);
            statusText.setText(label + p + "% (" + formatMb(done) + " / " + formatMb(total) + ")");
        });
    }

    private static String formatMb(long bytes) {
        return String.format(Locale.US, "%.0f MB", bytes / (1024.0 * 1024.0));
    }

    private void copyDocumentTree(DocumentFile sourceDoc, File targetDir) throws IOException {
        if (!targetDir.exists()) {
            targetDir.mkdirs();
        }

        DocumentFile[] files = sourceDoc.listFiles();
        for (DocumentFile file : files) {
            if (file.isDirectory()) {
                File subDir = new File(targetDir, file.getName());
                copyDocumentTree(file, subDir);
            } else if (file.isFile()) {
                File targetFile = new File(targetDir, file.getName());
                // Already there with the same size: skip the copy but count it toward
                // progress, so re-selecting the same folder (or resuming) is nearly free.
                if (targetFile.exists() && targetFile.length() == file.length()) {
                    copyDoneBytes += Math.max(0, file.length());
                    reportCopyProgress();
                    continue;
                }
                try (InputStream in = getContentResolver().openInputStream(file.getUri());
                     OutputStream out = new FileOutputStream(targetFile)) {
                    if (in != null) {
                        byte[] buffer = new byte[262144];
                        int read;
                        while ((read = in.read(buffer)) != -1) {
                            out.write(buffer, 0, read);
                            copyDoneBytes += read;
                            reportCopyProgress();
                        }
                    }
                }
            }
        }
    }

    // ── Content packs ──────────────────────────────────────────────────────────────
    // Packs are folders mirroring the game's paths, installed here and listed in the content profile
    // (content-profile.json), which the game is handed with -contentprofile on launch. The launcher
    // owns install and the recovery switch; the game owns the load order and the on/off switches, in
    // Configuration > Content, because only it can see what each pack holds and wins.

    private File getContentProfileFile() {
        return new File(getFilesDir(), CONTENT_PROFILE_NAME);
    }

    private static String readFileToString(File file) throws IOException {
        StringBuilder sb = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(new FileInputStream(file), StandardCharsets.UTF_8))) {
            char[] buffer = new char[8192];
            int read;
            while ((read = reader.read(buffer)) != -1) {
                sb.append(buffer, 0, read);
            }
        }
        return sb.toString();
    }

    // Writes the profile whole or not at all, so a game starting at the same moment never reads half.
    private static void writeProfileJsonAtomic(File profile, JSONObject root) throws IOException {
        File tmp = new File(profile.getParentFile(), profile.getName() + ".tmp");
        try (FileOutputStream out = new FileOutputStream(tmp)) {
            out.write(root.toString(2).getBytes(StandardCharsets.UTF_8));
        }
        if (!tmp.renameTo(profile)) {
            if (profile.exists()) {
                profile.delete();
            }
            if (!tmp.renameTo(profile)) {
                throw new IOException("Could not write " + profile.getName());
            }
        }
    }

    // Creates the profile on first run with just the game folder's own overrides in it, and makes sure
    // an existing one still names that folder — the profile is what decides the load order, and a
    // profile that never mentions the local folder silently drops it. Returns null only when the
    // profile cannot be ensured at all; the game then launches without -contentprofile and runs on the
    // local overrides alone. A profile that is there but is not valid JSON is left alone: the engine
    // falls back to local-only for it, and clobbering it here would lose the player's pack list.
    private File ensureContentProfile() {
        File profile = getContentProfileFile();
        try {
            JSONObject root;
            boolean changed = false;
            if (!profile.exists()) {
                root = new JSONObject();
                changed = true;
            } else {
                try {
                    root = new JSONObject(readFileToString(profile));
                } catch (JSONException e) {
                    Log.w(TAG, "Content profile is not valid JSON; leaving it alone (the game falls back to local overrides).");
                    return profile;
                }
            }

            JSONObject titles = root.optJSONObject("titles");
            if (titles == null) {
                titles = new JSONObject();
                root.put("titles", titles);
                changed = true;
            }
            JSONArray igi1 = titles.optJSONArray("igi1");
            if (igi1 == null) {
                igi1 = new JSONArray();
                titles.put("igi1", igi1);
                changed = true;
            }
            boolean hasLocal = false;
            for (int i = 0; i < igi1.length(); i++) {
                JSONObject layer = igi1.optJSONObject(i);
                if (layer != null && LOCAL_LAYER_ID.equals(layer.optString("id"))) {
                    hasLocal = true;
                    break;
                }
            }
            if (!hasLocal) {
                JSONObject local = new JSONObject();
                local.put("id", LOCAL_LAYER_ID);
                local.put("name", LOCAL_LAYER_NAME);
                local.put("kind", "local");
                local.put("enabled", true);
                igi1.put(local);
                changed = true;
            }

            if (changed) {
                root.put("schema", 1);
                writeProfileJsonAtomic(profile, root);
            }
            return profile;
        } catch (Exception e) {
            Log.w(TAG, "Could not ensure content profile", e);
            return null;
        }
    }

    private static String sanitizePackId(String name) {
        String id = name.toLowerCase(Locale.US).replaceAll("[^a-z0-9]+", "-").replaceAll("^-+|-+$", "");
        return id.isEmpty() ? "pack" : id;
    }

    private static int countFiles(File dir) {
        int count = 0;
        File[] children = dir.listFiles();
        if (children == null) {
            return 0;
        }
        for (File child : children) {
            count += child.isDirectory() ? countFiles(child) : 1;
        }
        return count;
    }

    // Records a pack in the profile, at the top: highest priority wins. A reinstall replaces the
    // earlier entry rather than stacking a second one for the same folder. Returns false when the
    // pack was copied but the profile could not be written, so the caller does not claim success.
    private boolean addPackToProfile(String packId, String packName, File packDir) {
        File profile = ensureContentProfile();
        if (profile == null) {
            runOnUiThread(() -> Toast.makeText(this,
                "Pack copied but the profile could not be written, so it will not load.",
                Toast.LENGTH_LONG).show());
            return false;
        }
        try {
            JSONObject root = new JSONObject(readFileToString(profile));
            JSONObject titles = root.optJSONObject("titles");
            if (titles == null) {
                titles = new JSONObject();
                root.put("titles", titles);
            }
            JSONArray igi1 = titles.optJSONArray("igi1");
            if (igi1 == null) {
                igi1 = new JSONArray();
                titles.put("igi1", igi1);
            }
            for (int i = igi1.length() - 1; i >= 0; i--) {
                JSONObject layer = igi1.optJSONObject(i);
                if (layer != null && packId.equals(layer.optString("id"))) {
                    igi1.remove(i);
                }
            }

            JSONObject spec = new JSONObject();
            spec.put("id", packId);
            spec.put("name", packName);
            spec.put("kind", "pack");
            spec.put("path", packDir.getAbsolutePath());
            spec.put("enabled", true);

            JSONArray reordered = new JSONArray();
            reordered.put(spec);
            for (int i = 0; i < igi1.length(); i++) {
                reordered.put(igi1.get(i));
            }
            titles.put("igi1", reordered);
            root.put("schema", 1);
            writeProfileJsonAtomic(profile, root);
            return true;
        } catch (Exception e) {
            Log.e(TAG, "Failed to record content pack in profile", e);
            runOnUiThread(() -> Toast.makeText(this,
                "Pack copied but the profile could not be written, so it will not load.",
                Toast.LENGTH_LONG).show());
            return false;
        }
    }

    private void processAndCopyContentPack(Uri treeUri) {
        DocumentFile rootDoc = DocumentFile.fromTreeUri(this, treeUri);
        if (rootDoc == null || !rootDoc.exists() || !rootDoc.isDirectory()) {
            runOnUiThread(() -> {
                statusText.setText("INVALID FOLDER SELECTED");
                Toast.makeText(this, "Could not access selected folder", Toast.LENGTH_SHORT).show();
            });
            return;
        }

        String displayName = rootDoc.getName() != null ? rootDoc.getName() : "pack";
        String packId = sanitizePackId(displayName);
        File targetDir = new File(new File(getFilesDir(), CONTENT_DIR_NAME), packId);

        runOnUiThread(() -> statusText.setText("COUNTING CONTENT PACK FILES..."));
        copyStatusLabel = "INSTALLING CONTENT PACK... ";
        copyTotalBytes = countTreeBytes(rootDoc);
        copyDoneBytes = 0;
        lastProgressUiMs = 0;
        runOnUiThread(() -> {
            progressBar.setIndeterminate(false);
            progressBar.setMax(100);
            progressBar.setProgress(0);
            statusText.setText("INSTALLING CONTENT PACK... 0%");
        });

        try {
            // A reinstall replaces the pack outright, so files the new version dropped do not linger.
            if (targetDir.exists()) {
                deleteRecursively(targetDir);
            }
            targetDir.mkdirs();
            copyDocumentTree(rootDoc, targetDir);

            int files = countFiles(targetDir);
            if (files == 0) {
                deleteRecursively(targetDir);
                runOnUiThread(() -> {
                    statusText.setText("EMPTY CONTENT PACK");
                    Toast.makeText(this, "That folder has no files in it.", Toast.LENGTH_LONG).show();
                });
                return;
            }

            boolean recorded = addPackToProfile(packId, displayName, targetDir);
            Log.i(TAG, "Content pack installed: " + packId + " (" + files + " files)");
            if (!recorded) {
                runOnUiThread(() -> statusText.setText("PACK INSTALL ERROR"));
                return;
            }
            runOnUiThread(() -> {
                progressBar.setProgress(100);
                statusText.setText("CONTENT PACK INSTALLED");
                Toast.makeText(this, "Pack '" + displayName + "' installed. Manage it in Configuration > Content.", Toast.LENGTH_LONG).show();
            });
        } catch (Exception e) {
            Log.e(TAG, "Failed to install content pack", e);
            runOnUiThread(() -> {
                statusText.setText("PACK INSTALL ERROR: " + e.getMessage());
                Toast.makeText(this, "Failed to install content pack: " + e.getMessage(), Toast.LENGTH_SHORT).show();
            });
        } finally {
            copyStatusLabel = "INSTALLING GAME FILES... ";
        }
    }

    // Out-of-game recovery: when a pack breaks the menu itself, the in-game switches are unreachable,
    // so the launcher switches everything off in the profile — every pack, and the game folder's own
    // overrides too. Nothing is deleted: the pack folders stay on disk and the packs are re-enabled
    // from Configuration > Content. A corrupt profile is replaced rather than read, so this still works
    // when the profile itself is what broke.
    private void disableAllContent() {
        new Thread(() -> {
            try {
                File profile = getContentProfileFile();
                JSONObject root;
                if (profile.exists()) {
                    try {
                        root = new JSONObject(readFileToString(profile));
                    } catch (JSONException e) {
                        Log.w(TAG, "Content profile is not valid JSON; replacing it with everything off.");
                        root = new JSONObject();
                    }
                } else {
                    root = new JSONObject();
                }

                root.put("schema", 1);
                JSONObject titles = root.optJSONObject("titles");
                if (titles == null) {
                    titles = new JSONObject();
                    root.put("titles", titles);
                }

                boolean hasIgi1 = titles.has("igi1");
                java.util.Iterator<String> keys = titles.keys();
                while (keys.hasNext()) {
                    JSONArray layers = titles.optJSONArray(keys.next());
                    if (layers == null) {
                        continue;
                    }
                    for (int i = 0; i < layers.length(); i++) {
                        JSONObject layer = layers.optJSONObject(i);
                        if (layer != null) {
                            layer.put("enabled", false);
                        }
                    }
                }

                // A profile that never mentioned this game still leaves the local overrides folder live,
                // so name it here, off, rather than leaving the broken art in place.
                if (!hasIgi1) {
                    JSONArray igi1 = new JSONArray();
                    JSONObject local = new JSONObject();
                    local.put("id", LOCAL_LAYER_ID);
                    local.put("name", LOCAL_LAYER_NAME);
                    local.put("kind", "local");
                    local.put("enabled", false);
                    igi1.put(local);
                    titles.put("igi1", igi1);
                }

                writeProfileJsonAtomic(profile, root);
                Log.i(TAG, "All content disabled via launcher recovery.");
                runOnUiThread(() -> {
                    statusText.setText("ALL CONTENT DISABLED");
                    Toast.makeText(this, "All content packs and overrides are off. Re-enable them in Configuration > Content.", Toast.LENGTH_LONG).show();
                });
            } catch (Exception e) {
                Log.e(TAG, "Failed to disable all content", e);
                runOnUiThread(() -> Toast.makeText(this,
                    "Failed to disable content: " + e.getMessage(), Toast.LENGTH_SHORT).show());
            }
        }).start();
    }

    private void onPlayButtonClicked() {
        if (!isGameFolderVerified) {
            Toast.makeText(this, "Please select a valid Project I.G.I. game folder first.", Toast.LENGTH_SHORT).show();
            return;
        }

        // Start game process immediately so renderer and engine loop do not freeze or wait!
        launchGameNow();
    }

    private void launchGameNow() {
        statusText.setText("STARTING " + ("webgpu".equals(rendererBackend) ? "WEBGPU" : "VULKAN") + " RENDERER...");
        if (pendingHolder != null && !isGameStarted) {
            startGameWithHolder(pendingHolder);
        }
    }

    private void exportLogcatToDownloads() {
        new Thread(() -> {
            try {
                // Sleep 2 seconds to capture full CoreCLR boot, JNI bridge, and Vulkan/GLES renderer logs
                Thread.sleep(2000);

                Process process = Runtime.getRuntime().exec("logcat -d -v time");
                BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
                StringBuilder logBuilder = new StringBuilder();
                String line;
                while ((line = reader.readLine()) != null) {
                    logBuilder.append(line).append("\n");
                }

                String logData = logBuilder.toString();
                boolean exported = false;

                // 1. Try MediaStore.Downloads (Android 10+ / API 29+)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    try {
                        ContentValues values = new ContentValues();
                        values.put(MediaStore.MediaColumns.DISPLAY_NAME, "projectigi_logs.txt");
                        values.put(MediaStore.MediaColumns.MIME_TYPE, "text/plain");
                        values.put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS);

                        Uri externalUri = MediaStore.Downloads.EXTERNAL_CONTENT_URI;
                        try {
                            getContentResolver().delete(externalUri, MediaStore.MediaColumns.DISPLAY_NAME + "=?", new String[]{"projectigi_logs.txt"});
                        } catch (Exception ignored) {}

                        Uri uri = getContentResolver().insert(externalUri, values);
                        if (uri != null) {
                            try (OutputStream os = getContentResolver().openOutputStream(uri)) {
                                if (os != null) {
                                    os.write(logData.getBytes(StandardCharsets.UTF_8));
                                    exported = true;
                                }
                            }
                        }
                    } catch (Exception e1) {
                        Log.w(TAG, "MediaStore export failed, trying direct file fallback", e1);
                    }
                }

                // 2. Direct File System Fallback (Downloads folder)
                if (!exported) {
                    File downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS);
                    if (!downloadsDir.exists()) {
                        downloadsDir.mkdirs();
                    }

                    File logFile = new File(downloadsDir, "projectigi_logs.txt");
                    if (logFile.exists()) {
                        logFile.delete();
                    }

                    try (FileOutputStream fos = new FileOutputStream(logFile, false)) {
                        fos.write(logData.getBytes(StandardCharsets.UTF_8));
                        exported = true;
                    }
                }

                Log.i(TAG, "Logcat exported successfully!");
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

        // The content profile rides the options string the engine already parses (-contentprofile):
        // the profile lives directly under getFilesDir(), whose path has no spaces, because the
        // options string splits on spaces. A launch with no usable profile runs on the game folder's
        // overrides alone.
        String options = "-" + rendererBackend;
        File contentProfile = ensureContentProfile();
        if (contentProfile != null) {
            options += " -contentprofile " + contentProfile.getAbsolutePath();
        }

        Log.i(TAG, "Calling nativeStartGame: " + landscapeWidth + "x" + landscapeHeight + " with options: " + options);
        boolean started = NativeEngine.nativeStartGame(holder.getSurface(), landscapeWidth, landscapeHeight, filesDir, nativeLibDir, options);
        if (started) {
            startQuitWatcher();
            // The native delegates only exist once the game has started, so a pad
            // that was already connected at launch is reported here, not in onResume.
            updateGamepadPresence();
        } else {
            isGameStarted = false;
        }
    }

    // Watches the game thread: if it ends while this Activity is in the foreground, the
    // user pressed Quit in the main menu, so close the app entirely instead of leaving
    // a black SurfaceView behind. Backgrounding also ends the game thread, but then
    // isResumed is false, so this does nothing and the surface-restart path takes over.
    private void startQuitWatcher() {
        if (quitWatcherThread != null && quitWatcherThread.isAlive()) return;
        quitWatcherStopped = false;
        quitWatcherThread = new Thread(() -> {
            boolean sawRunning = false;
            while (!quitWatcherStopped) {
                try {
                    Thread.sleep(500);
                } catch (InterruptedException e) {
                    break;
                }
                boolean running = NativeEngine.nativeIsGameRunning();
                if (running) {
                    sawRunning = true;
                    continue;
                }
                if (sawRunning && isResumed && isGameStarted) {
                    Log.i(TAG, "Game exited in the foreground (Quit): closing the app");
                    runOnUiThread(() -> finishAffinity());
                    break;
                }
            }
        });
        quitWatcherThread.start();
    }

    @Override
    public void surfaceCreated(SurfaceHolder holder) {
        Log.i(TAG, "surfaceCreated");
        pendingHolder = holder;
        if (isExtracted && isGameFolderVerified && !isGameStarted) {
            // Holder is ready
        }
        // Returning from the background: the engine survived (it idles with no surface),
        // so hand it the new surface and it resumes in the mission, at the pause menu,
        // instead of restarting to the main menu.
        if (isGameStarted) {
            android.graphics.Rect frame = holder.getSurfaceFrame();
            int w = frame.width() > 0 ? frame.width() : surfaceView.getWidth();
            int h = frame.height() > 0 ? frame.height() : surfaceView.getHeight();
            Log.i(TAG, "surfaceCreated: rebinding live engine to new surface " + w + "x" + h);
            NativeEngine.nativeOnSurfaceRecreated(holder.getSurface(), w, h);
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
        // The surface is gone (app backgrounded) but the engine keeps running: it idles with
        // no surface until a new one arrives, so the player returns to the pause menu in the
        // mission instead of the main menu. isGameStarted stays true.
        NativeEngine.nativeOnSurfaceDestroyed();
        pendingHolder = null;
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        if (!isGameStarted) return false;
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
        if (!isGameStarted) return super.onKeyDown(keyCode, event);
        if (keyCode == KeyEvent.KEYCODE_BACK) {
            // Consume here without sending: onBackPressed() sends the Back key once.
            // Sending it here too pressed Escape twice, which opened the pause menu
            // and immediately closed it again (or skipped past it).
            return true;
        }
        if (isGamepadKeyCode(keyCode) && isSecondGamepad(event.getDeviceId())) {
            return super.onKeyDown(keyCode, event);
        }
        NativeEngine.nativeOnKey(keyCode, true);
        return super.onKeyDown(keyCode, event);
    }

    @Override
    public boolean onKeyUp(int keyCode, KeyEvent event) {
        if (!isGameStarted) return super.onKeyUp(keyCode, event);
        if (isGamepadKeyCode(keyCode) && isSecondGamepad(event.getDeviceId())) {
            return super.onKeyUp(keyCode, event);
        }
        NativeEngine.nativeOnKey(keyCode, false);
        return super.onKeyUp(keyCode, event);
    }

    // Joystick axes never arrive in onTouchEvent: Android delivers them here, as
    // MotionEvents from a SOURCE_JOYSTICK / SOURCE_GAMEPAD device. Buttons and the
    // D-pad arrive as KeyEvents above; the sticks, triggers and (on some pads) the
    // D-pad-as-axes arrive here.
    @Override
    public boolean onGenericMotionEvent(MotionEvent event) {
        if (!isGameStarted) return super.onGenericMotionEvent(event);
        if ((event.getSource() & InputDevice.SOURCE_JOYSTICK) != InputDevice.SOURCE_JOYSTICK
                && (event.getSource() & InputDevice.SOURCE_GAMEPAD) != InputDevice.SOURCE_GAMEPAD) {
            return super.onGenericMotionEvent(event);
        }
        if (isSecondGamepad(event.getDeviceId())) {
            return super.onGenericMotionEvent(event);
        }
        if (activeGamepadId == -1) {
            updateGamepadPresence();
        }
        float lx = event.getAxisValue(MotionEvent.AXIS_X);
        float ly = event.getAxisValue(MotionEvent.AXIS_Y);
        float rx = event.getAxisValue(MotionEvent.AXIS_Z);
        float ry = event.getAxisValue(MotionEvent.AXIS_RZ);
        float lt = event.getAxisValue(MotionEvent.AXIS_LTRIGGER);
        float rt = event.getAxisValue(MotionEvent.AXIS_RTRIGGER);
        NativeEngine.nativeOnGamepadAxis(lx, ly, rx, ry, lt, rt);

        // D-pad-as-axes fallback: some pads report the D-pad on HAT_X/HAT_Y
        // instead of sending DPAD key events. Synthesise the key transitions so
        // the C# side sees one D-pad either way; pads that send both keep working
        // because setting the same button twice is idempotent.
        int hatX = (int) Math.signum(event.getAxisValue(MotionEvent.AXIS_HAT_X));
        int hatY = (int) Math.signum(event.getAxisValue(MotionEvent.AXIS_HAT_Y));
        if (hatX != prevHatX) {
            if (prevHatX == -1) NativeEngine.nativeOnKey(KeyEvent.KEYCODE_DPAD_LEFT, false);
            if (prevHatX == 1) NativeEngine.nativeOnKey(KeyEvent.KEYCODE_DPAD_RIGHT, false);
            if (hatX == -1) NativeEngine.nativeOnKey(KeyEvent.KEYCODE_DPAD_LEFT, true);
            if (hatX == 1) NativeEngine.nativeOnKey(KeyEvent.KEYCODE_DPAD_RIGHT, true);
            prevHatX = hatX;
        }
        if (hatY != prevHatY) {
            if (prevHatY == -1) NativeEngine.nativeOnKey(KeyEvent.KEYCODE_DPAD_UP, false);
            if (prevHatY == 1) NativeEngine.nativeOnKey(KeyEvent.KEYCODE_DPAD_DOWN, false);
            if (hatY == -1) NativeEngine.nativeOnKey(KeyEvent.KEYCODE_DPAD_UP, true);
            if (hatY == 1) NativeEngine.nativeOnKey(KeyEvent.KEYCODE_DPAD_DOWN, true);
            prevHatY = hatY;
        }
        return true;
    }

    @Override
    public void onBackPressed() {
        // If the soft keyboard is showing, the first Back dismisses it (and clears the
        // keyboard request) instead of navigating — standard Android behaviour.
        if (isGameStarted && imeShown) {
            hideSoftKeyboard();
            NativeEngine.nativeSetKeyboardRequested(false);
            return;
        }
        if (isGameStarted) {
            NativeEngine.nativeOnKey(4, true);
            surfaceView.postDelayed(() -> NativeEngine.nativeOnKey(4, false), 50);
        } else {
            super.onBackPressed();
        }
    }

    @Override
    public void onConfigurationChanged(Configuration newConfig) {
        super.onConfigurationChanged(newConfig);
        applyImmersiveMode();
    }

    @Override
    protected void onPause() {
        super.onPause();
        isResumed = false;
        if (sensorManager != null && gyroListener != null) {
            sensorManager.unregisterListener(gyroListener);
        }
        if (inputManager != null && gamepadListener != null) {
            inputManager.unregisterInputDeviceListener(gamepadListener);
        }
        lastGyroTimestampNs = 0;
        hideSoftKeyboard();
        // Clear the soft-keyboard request (derived from the console's open state)
        // and the hidden field's focus, or the IME poller (or a focused EditText)
        // pops the keyboard up again the moment the app returns to the foreground.
        // The keyboard only comes back when the console is opened again or a text
        // field is focused; the managed side also closes the console on return,
        // since this clear while it is open means "close the console".
        NativeEngine.nativeSetKeyboardRequested(false);
        if (hiddenInput != null) {
            hiddenInput.clearFocus();
        }
        // The game goes into its paused state when the app leaves the foreground (Home,
        // recents, switching apps): the same Back press that opens the pause menu in-game.
        // In the main menu Back is a no-op, so this is safe there too. The C# side also
        // forces the pause when the surface is gone, which covers a cutscene (Back alone
        // cannot pause there: skipping needs a hold and the pause check refuses while
        // one plays).
        if (isGameStarted) {
            NativeEngine.nativeOnKey(4, true);
            surfaceView.postDelayed(() -> NativeEngine.nativeOnKey(4, false), 50);
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        isResumed = true;
        if (sensorManager != null && gyroSensor != null && gyroListener != null) {
            sensorManager.registerListener(gyroListener, gyroSensor, SensorManager.SENSOR_DELAY_GAME);
        }
        if (inputManager != null && gamepadListener != null) {
            inputManager.registerInputDeviceListener(gamepadListener, null);
        }
        // Re-scan on every resume: a pad plugged in while the app was backgrounded
        // (or before the game started, when the native side was not listening yet)
        // is picked up here, and a pad unplugged while away is cleared.
        updateGamepadPresence();
    }

    // Gamepad hot-plug: the listener reports add/remove/change, and every resume
    // re-scans, so a pad connected at launch, mid-mission or while backgrounded
    // is found, and unplugging one mid-mission is noticed at once. The native
    // call is a no-op until the game has started (its delegate is not bound yet),
    // so the launch scan is repeated after nativeStartGame returns.
    private void setupGamepad() {
        inputManager = (InputManager) getSystemService(INPUT_SERVICE);
        gamepadListener = new InputManager.InputDeviceListener() {
            @Override
            public void onInputDeviceAdded(int deviceId) {
                updateGamepadPresence();
            }

            @Override
            public void onInputDeviceRemoved(int deviceId) {
                if (deviceId == activeGamepadId) {
                    activeGamepadId = -1;
                    prevHatX = 0;
                    prevHatY = 0;
                }
                updateGamepadPresence();
            }

            @Override
            public void onInputDeviceChanged(int deviceId) {
                updateGamepadPresence();
            }
        };
    }

    private static boolean isGamepadKeyCode(int keyCode) {
        switch (keyCode) {
            case KeyEvent.KEYCODE_BUTTON_A:
            case KeyEvent.KEYCODE_BUTTON_B:
            case KeyEvent.KEYCODE_BUTTON_X:
            case KeyEvent.KEYCODE_BUTTON_Y:
            case KeyEvent.KEYCODE_BUTTON_L1:
            case KeyEvent.KEYCODE_BUTTON_R1:
            case KeyEvent.KEYCODE_BUTTON_L2:
            case KeyEvent.KEYCODE_BUTTON_R2:
            case KeyEvent.KEYCODE_BUTTON_THUMBL:
            case KeyEvent.KEYCODE_BUTTON_THUMBR:
            case KeyEvent.KEYCODE_BUTTON_START:
            case KeyEvent.KEYCODE_BUTTON_SELECT:
            case KeyEvent.KEYCODE_DPAD_UP:
            case KeyEvent.KEYCODE_DPAD_DOWN:
            case KeyEvent.KEYCODE_DPAD_LEFT:
            case KeyEvent.KEYCODE_DPAD_RIGHT:
                return true;
            default:
                return false;
        }
    }

    // First gamepad wins: input from any other gamepad device is ignored while
    // one is tracked. With no pad tracked, nothing is filtered.
    private boolean isSecondGamepad(int deviceId) {
        return activeGamepadId != -1 && deviceId != activeGamepadId;
    }

    private static boolean isGamepadDevice(InputDevice device) {
        if (device == null) {
            return false;
        }
        int sources = device.getSources();
        return (sources & InputDevice.SOURCE_GAMEPAD) == InputDevice.SOURCE_GAMEPAD
                || (sources & InputDevice.SOURCE_JOYSTICK) == InputDevice.SOURCE_JOYSTICK;
    }

    private void updateGamepadPresence() {
        int foundId = -1;
        int[] ids = InputDevice.getDeviceIds();
        if (ids != null) {
            for (int id : ids) {
                if (isGamepadDevice(InputDevice.getDevice(id))) {
                    foundId = id;
                    break;
                }
            }
        }
        activeGamepadId = foundId;
        boolean connected = foundId != -1;
        if (connected != gamepadConnected) {
            gamepadConnected = connected;
            Log.i(TAG, "Gamepad " + (connected ? "connected" : "disconnected") + " (device " + foundId + ")");
        }
        if (isGameStarted) {
            NativeEngine.nativeOnGamepadConnected(connected);
        }
    }

    // Gyroscope aim + the soft keyboard for text fields (player-name box).
    private void setupGyroAndKeyboard() {
        sensorManager = (SensorManager) getSystemService(SENSOR_SERVICE);
        if (sensorManager != null) {
            gyroSensor = sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE);
        }
        gyroListener = new SensorEventListener() {
            @Override
            public void onSensorChanged(SensorEvent event) {
                if (!isGameStarted || gyroSensor == null) {
                    return;
                }
                if (lastGyroTimestampNs == 0) {
                    lastGyroTimestampNs = event.timestamp;
                    return;
                }
                float dt = (event.timestamp - lastGyroTimestampNs) / 1_000_000_000f;
                lastGyroTimestampNs = event.timestamp;
                if (dt <= 0f || dt > 0.1f) {
                    return;
                }
                // Integrate the rates (rad/s) into per-event angle deltas (radians).
                // In landscape the axes are swapped: rotating around the device's X axis
                // (values[0]) tilts the view left/right, and rotating around the Y axis
                // (values[1]) aims up/down. Both are negated so the view follows the tilt:
                // calibrated from a device report where tilt-down moved the view right,
                // tilt-up moved it left, and tilt-right aimed down (axes swapped, signs
                // backwards). If a direction still feels backwards on a given device,
                // flip the sign of that line only.
                float yawDelta = -event.values[0] * dt;
                float pitchDelta = -event.values[1] * dt;
                NativeEngine.nativeOnGyro(yawDelta, pitchDelta);
            }

            @Override
            public void onAccuracyChanged(Sensor sensor, int accuracy) {
            }
        };

        // Hidden, zero-size EditText the IME types into. The game draws its own UI on
        // a SurfaceView, so there is no Android View for the keyboard to target; this
        // invisible field is the target, and its TextWatcher forwards typed text.
        hiddenInput = new EditText(this);
        // Visible (not INVISIBLE): some keyboards refuse to show for an invisible view.
        // It is 1x1 with no background and no cursor, so nothing is actually drawn.
        hiddenInput.setVisibility(View.VISIBLE);
        hiddenInput.setCursorVisible(false);
        hiddenInput.setFocusable(true);
        hiddenInput.setFocusableInTouchMode(true);
        hiddenInput.setInputType(android.text.InputType.TYPE_CLASS_TEXT
            | android.text.InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS);
        hiddenInput.setBackground(null);
        rootLayout.addView(hiddenInput, new FrameLayout.LayoutParams(1, 1));
        final String[] lastText = {""};
        hiddenInput.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
            }

            @Override
            public void afterTextChanged(Editable s) {
                String now = s.toString();
                String prev = lastText[0];
                if (now.length() > prev.length() && now.startsWith(prev)) {
                    // Inserted text: forward only the new characters.
                    NativeEngine.nativeOnText(now.substring(prev.length()));
                } else if (now.length() < prev.length()) {
                    // Deleted text: one Backspace per removed character.
                    int removed = prev.length() - now.length();
                    for (int i = 0; i < removed; i++) {
                        NativeEngine.nativeOnKey(67, true);
                        NativeEngine.nativeOnKey(67, false);
                    }
                }
                lastText[0] = now;
            }
        });

        // Polls whether the game has a text field focused and shows/hides the IME.
        // The game tells us via nativeIsTextFieldFocused(); the IME needs a focused View,
        // which is the hidden EditText above.
        imeHandler = new Handler(Looper.getMainLooper());
        imePoller = new Runnable() {
            @Override
            public void run() {
                updateImeVisibility();
                requestMicrophonePermissionIfWanted();
                if (imeHandler != null) {
                    imeHandler.postDelayed(this, 250);
                }
            }
        };
        imeHandler.post(imePoller);
    }

    private void updateImeVisibility() {
        // Show the keyboard when a text field is focused OR when the developer console
        // is open: the managed side derives the keyboard request from the console's
        // open state, so opening the console (main-menu icon, Grave key, toggleconsole)
        // summons the IME for typing commands, and closing it hides the IME again.
        // Back clears the request while the console is open, and the managed side
        // treats that clear as "close the console" — one Back closes both together.
        boolean focused = isGameStarted && (NativeEngine.nativeIsTextFieldFocused()
            || NativeEngine.nativeIsKeyboardRequested());
        InputMethodManager imm = (InputMethodManager) getSystemService(INPUT_METHOD_SERVICE);
        if (focused && !imeShown) {
            if (hiddenInput != null && imm != null) {
                hiddenInput.requestFocus();
                imm.showSoftInput(hiddenInput, 0);
            }
            imeShown = true;
        } else if (!focused && imeShown) {
            hideSoftKeyboard();
        }
    }

    private void hideSoftKeyboard() {
        if (!imeShown) {
            return;
        }
        imeShown = false;
        InputMethodManager imm = (InputMethodManager) getSystemService(INPUT_METHOD_SERVICE);
        if (hiddenInput != null && imm != null) {
            imm.hideSoftInputFromWindow(hiddenInput.getWindowToken(), 0);
            hiddenInput.setText("");
        }
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
        quitWatcherStopped = true;
        if (quitWatcherThread != null) quitWatcherThread.interrupt();
        if (imeHandler != null && imePoller != null) {
            imeHandler.removeCallbacks(imePoller);
        }
        if (sensorManager != null && gyroListener != null) {
            sensorManager.unregisterListener(gyroListener);
        }
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
