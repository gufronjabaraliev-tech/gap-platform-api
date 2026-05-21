# Firebase Hosting — APK + yuklab olish sahifasi
# 1) https://console.firebase.google.com — yangi loyiha
# 2) npm i -g firebase-tools
# 3) firebase login
# 4) .firebaserc da YOUR_FIREBASE_PROJECT_ID ni almashtiring
# 5) .\deploy.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$apkSrc = Join-Path $root "..\build\app\outputs\flutter-apk\app-release.apk"
$apkDst = Join-Path $root "public\gap.apk"

if (-not (Test-Path $apkSrc)) {
  Write-Host "APK yo'q. Avval: cd ..\ ; flutter build apk --release"
  exit 1
}
Copy-Item $apkSrc $apkDst -Force
Set-Location $root
firebase deploy --only hosting
Write-Host "Tayyor. Firebase Hosting URL ni konsolda ko'rasiz."
