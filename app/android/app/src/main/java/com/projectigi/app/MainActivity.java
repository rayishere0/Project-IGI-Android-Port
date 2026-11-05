package com.projectigi.app;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.ContentValues;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.SharedPreferences;
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
import android.graphics.drawable.GradientDrawable;
import android.net.Uri;
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
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;

public class MainActivity extends Activity implements SurfaceHolder.Callback {
    private static final String TAG = "ProjectIGI";
    private static final String ASSET_VERSION = "v22_perm_on_start";
    private static final int REQUEST_SELECT_GAME_FOLDER = 2001;
    private static final int REQUEST_STORAGE_PERMISSIONS = 1002;
    private static final String PREFS_NAME = "projectigi_prefs";
    private static final String PREF_RENDERER_BACKEND = "renderer_backend";

    private SurfaceView surfaceView;
    private FrameLayout rootLayout;
    private FrameLayout splashLayout;
    private TextView statusText;
    private ProgressBar progressBar;
    private Button selectFolderBtn;
    private Button playBtn;
    private Button vulkanBtn;
    private Button webGpuBtn;
    private String rendererBackend = "vulkan";

    private boolean isExtracted = false;
    private boolean isGameFolderVerified = false;
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
        runOnUiThread(() -> statusText.setText("INSTALLING GAME FILES... PLEASE WAIT"));

        File targetDataDir = new File(getFilesDir(), "Project IGI");
        try {
            if (!targetDataDir.exists()) {
                targetDataDir.mkdirs();
            }
            copyDocumentTree(rootDoc, targetDataDir);

            Log.i(TAG, "Game files successfully copied and verified.");
            runOnUiThread(() -> {
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
                try (InputStream in = getContentResolver().openInputStream(file.getUri());
                     OutputStream out = new FileOutputStream(targetFile)) {
                    if (in != null) {
                        byte[] buffer = new byte[65536];
                        int read;
                        while ((read = in.read(buffer)) != -1) {
                            out.write(buffer, 0, read);
                        }
                    }
                }
            }
        }
    }

    private void onPlayButtonClicked() {
        if (!isGameFolderVerified) {
            Toast.makeText(this, "Please select a valid Project I.G.I. game folder first.", Toast.LENGTH_SHORT).show();
            return;
        }

        // Start game process immediately so renderer and engine loop do not freeze or wait!
        launchGameNow();

        // Display non-blocking logcat prompt overlay
        showLogcatPromptOverlay();
    }

    private void showLogcatPromptOverlay() {
        if (isFinishing() || (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1 && isDestroyed())) {
            return;
        }

        AlertDialog.Builder builder = new AlertDialog.Builder(this, android.R.style.Theme_DeviceDefault_Dialog_Alert);

        TextView titleView = new TextView(this);
        titleView.setText("DIAGNOSTIC LOGGING");
        titleView.setTextColor(Color.rgb(57, 227, 101)); // #39e365
        titleView.setTextSize(16);
        titleView.setTypeface(Typeface.MONOSPACE, Typeface.BOLD);
        titleView.setPadding(40, 30, 40, 10);
        builder.setCustomTitle(titleView);

        TextView messageView = new TextView(this);
        messageView.setText("Do you want to record active runtime logs during this session and save 'projectigi_logs.txt' into your Downloads folder?");
        messageView.setTextColor(Color.rgb(200, 230, 205));
        messageView.setTextSize(14);
        messageView.setTypeface(Typeface.MONOSPACE);
        messageView.setPadding(40, 10, 40, 20);
        builder.setView(messageView);

        builder.setPositiveButton("YES", (dialog, which) -> {
            dialog.dismiss();
            exportLogcatToDownloads();
        });

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

        Log.i(TAG, "Calling nativeStartGame: " + landscapeWidth + "x" + landscapeHeight);
        NativeEngine.nativeStartGame(holder.getSurface(), landscapeWidth, landscapeHeight, filesDir, nativeLibDir, "-" + rendererBackend);
    }

    @Override
    public void surfaceCreated(SurfaceHolder holder) {
        Log.i(TAG, "surfaceCreated");
        pendingHolder = holder;
        if (isExtracted && isGameFolderVerified && !isGameStarted) {
            // Holder is ready
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
            NativeEngine.nativeOnKey(4, true);
            surfaceView.postDelayed(() -> NativeEngine.nativeOnKey(4, false), 50);
            return true;
        }
        NativeEngine.nativeOnKey(keyCode, true);
        return super.onKeyDown(keyCode, event);
    }

    @Override
    public boolean onKeyUp(int keyCode, KeyEvent event) {
        if (!isGameStarted) return super.onKeyUp(keyCode, event);
        NativeEngine.nativeOnKey(keyCode, false);
        return super.onKeyUp(keyCode, event);
    }

    @Override
    public void onBackPressed() {
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
