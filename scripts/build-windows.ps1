# scripts/build-windows.ps1
# Build a redistributable Roosty Windows release zip into dist/.
# Intended for maintainers preparing a GitHub Release.
# Usage:
#   pwsh -File scripts/build-windows.ps1
# Requires: Flutter (stable, Dart 3.x) and Visual Studio with the
# "Desktop development with C++" workload installed.
$ErrorActionPreference = 'Stop'

Write-Host "[1/4] flutter doctor"
flutter doctor

Write-Host "[2/4] clean + pub get"
flutter clean
flutter pub get

Write-Host "[3/4] build windows release"
flutter build windows --release

$pubspec = Get-Content pubspec.yaml -Raw
if ($pubspec -match '(?m)^version:\s*([\d\.]+)') { $version = $Matches[1] }
else { throw "Could not find version in pubspec.yaml" }

$source = Join-Path (Get-Location) 'build\windows\x64\runner\Release'
if (-not (Test-Path $source)) { throw "Build output not found: $source" }

$distDir = Join-Path (Get-Location) 'dist'
New-Item -ItemType Directory -Force -Path $distDir | Out-Null
$zip = Join-Path $distDir "roosty-windows-v$version.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }

Write-Host "[4/4] zip -> $zip"
Compress-Archive -Path (Join-Path $source '*') -DestinationPath $zip -Force

Write-Host ""
Write-Host "OK: $zip"
