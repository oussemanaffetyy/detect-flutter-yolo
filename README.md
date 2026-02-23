# DETECT (Flutter + YOLO TFLite)

Live camera detection app with 3 labels:

- `mouse`
- `headphones`
- `notepad`

Model used by Android:

- `android/app/src/main/assets/best.tflite`

## Clone And Run (Mac + Windows)

### Prerequisites

- Flutter (stable channel)
- Android Studio (with Android SDK)
- Android NDK `28.2.13676358` installed from SDK Manager
- A real Android phone with USB debugging enabled

### 1. Clone

```bash
git clone https://github.com/oussemanaffetyy/detect-flutter-yolo.git
cd flutter_yolo_stream_app
```

### 2. One-time setup (recommended)

Mac:

```bash
bash scripts/bootstrap_macos.sh
```

Windows (PowerShell):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap_windows.ps1
```

### 3. Run

```bash
flutter run
```

## If Java Error Appears

Android Gradle Plugin needs JDK 17. Set Flutter to Android Studio JDK:

Mac:

```bash
flutter config --jdk-dir "/Applications/Android Studio.app/Contents/jbr/Contents/Home"
```

Windows:

```powershell
flutter config --jdk-dir "C:\Program Files\Android\Android Studio\jbr"
```

Then re-run:

```bash
flutter clean
flutter pub get
flutter run
```

## Replace The Model

If you train a new YOLO model (`best.pt`), export it to TFLite then replace:

- `android/app/src/main/assets/best.tflite`

Export example:

```bash
python tools/export_tflite.py \
  --weights /path/to/best.pt \
  --output-dir android/app/src/main/assets \
  --output-name best.tflite
```
