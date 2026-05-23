## Sentinel Build Helper – build_sentinel.ps1
# -------------------------------------------------
# This PowerShell script automates the steps needed to:
#   1️⃣ Install the Flutter SDK (if not already present)
#   2️⃣ Ensure Android SDK/Platform‑Tools are available
#   3️⃣ Pull project dependencies
#   4️⃣ Build a signed release APK (or AAB)
# -------------------------------------------------
# Usage:
#   1. Open PowerShell **as Administrator**
#   2. Navigate to the project root:
#        cd "C:\Users\Srineedhi\.gemini\antigravity\scratch\sentinel_offline_biometric"
#   3. Run the script:
#        .\build_sentinel.ps1
#   4. Follow any interactive prompts (e.g., keystore password)
# -------------------------------------------------

# ---- Configurable variables ----
$FlutterVersion = "3.22.0-stable"
$FlutterZipUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_${FlutterVersion}.zip"
$FlutterInstallDir = "$env:USERPROFILE\flutter"
$KeystorePath = "$env:USERPROFILE\sentinel_key.jks"   # Adjust if you use a different path
$KeyAlias = "sentinel_key"

# ---- Helper functions ----
function Install-Flutter {
    if (Test-Path "$FlutterInstallDir\bin\flutter.exe") {
        Write-Host "Flutter already installed at $FlutterInstallDir"
        return
    }
    Write-Host "Downloading Flutter $FlutterVersion..."
    $zipPath = "$env:TEMP\flutter_windows_${FlutterVersion}.zip"
    Invoke-WebRequest -Uri $FlutterZipUrl -OutFile $zipPath -UseBasicParsing
    Expand-Archive -Path $zipPath -DestinationPath $FlutterInstallDir -Force
    Write-Host "Flutter extracted to $FlutterInstallDir"
    # Add to PATH for this session
    $env:PATH = "$FlutterInstallDir\bin;$env:PATH"
    Write-Host "Flutter added to PATH (current session)"
}

function Ensure-AndroidSdk {
    # Flutter doctor will prompt for missing Android components.
    # If you have Android Studio installed, the SDK is usually at:
    #   $env:LOCALAPPDATA\Android\Sdk
    $androidSdk = "$env:LOCALAPPDATA\Android\Sdk"
    if (Test-Path $androidSdk) {
        Write-Host "Android SDK found at $androidSdk"
        $env:ANDROID_SDK_ROOT = $androidSdk
        $env:PATH = "$androidSdk\platform-tools;$androidSdk\cmdline-tools\latest\bin;$env:PATH"
    } else {
        Write-Warning "Android SDK not detected. Please install Android Studio (https://developer.android.com/studio) and run it once so the SDK is created."
    }
}

function Run-FlutterDoctor {
    Write-Host "Running flutter doctor to verify environment..."
    flutter doctor
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "flutter doctor reported issues. Resolve them before continuing."
        exit 1
    }
}

function Build-ReleaseAPK {
    Write-Host "Fetching pub dependencies..."
    flutter pub get
    Write-Host "Building signed release APK..."
    # The script assumes you have set keystore variables in your environment or will be prompted.
    flutter build apk --release
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Release APK built successfully. Find it at:"
        Write-Host "$(Resolve-Path .\build\app\outputs\flutter-apk\app-release.apk)"
    } else {
        Write-Error "Failed to build APK. Review the console output above."
    }
}

# ---- Main execution flow ----
Write-Host "=== Sentinel Offline Biometric Build Script ==="
Install-Flutter
Ensure-AndroidSdk
Run-FlutterDoctor
Build-ReleaseAPK
Write-Host "=== Build script completed ==="
