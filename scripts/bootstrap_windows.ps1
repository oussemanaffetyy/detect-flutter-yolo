$ErrorActionPreference = "Stop"

Write-Host "==> Flutter version"
flutter --version

$androidStudioJdk = "C:\Program Files\Android\Android Studio\jbr"
if (Test-Path $androidStudioJdk) {
    Write-Host "==> Configuring Flutter JDK from Android Studio"
    flutter config --jdk-dir "$androidStudioJdk"
}

Write-Host "==> Enabling Android target"
flutter config --enable-android

Write-Host "==> Pre-caching Android artifacts"
flutter precache --android

Write-Host "==> Fetching Dart/Flutter dependencies"
flutter pub get

Write-Host "==> Flutter doctor"
flutter doctor -v

Write-Host "Done. Run: flutter run"
