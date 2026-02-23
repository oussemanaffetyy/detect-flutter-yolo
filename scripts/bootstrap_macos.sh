#!/usr/bin/env bash
set -euo pipefail

echo "==> Flutter version"
flutter --version

ANDROID_STUDIO_JDK="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
if [ -d "$ANDROID_STUDIO_JDK" ]; then
  echo "==> Configuring Flutter JDK from Android Studio"
  flutter config --jdk-dir "$ANDROID_STUDIO_JDK"
fi

echo "==> Enabling Android target"
flutter config --enable-android

echo "==> Pre-caching Android artifacts"
flutter precache --android

echo "==> Fetching Dart/Flutter dependencies"
flutter pub get

echo "==> Flutter doctor"
flutter doctor -v

echo "Done. Run: flutter run"
