# scripts/build-windows.ps1
# Build a redistributable Roosty Windows release zip into dist/.
# Intended for maintainers preparing a GitHub Release.
# Usage:
#   pwsh -File scripts/build-windows.ps1
# Requires: Flutter (stable, Dart 3.x) and Visual Studio with the
# "Desktop development with C++" workload installed.
# Tip: close any running roosty.exe (Roosty desktop, mini card) before running.
$ErrorActionPreference = 'Stop'

# Anchor cwd to the repo root so the script is location-agnostic.
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

function Invoke-Native($label, [scriptblock]$cmd) {
  & $cmd
  if ($LASTEXITCODE -ne 0) { throw "$label failed with exit code $LASTEXITCODE" }
}

Write-Host "[1/4] flutter doctor"
Invoke-Native 'flutter doctor' { flutter doctor }

Write-Host "[2/4] clean + pub get"
Invoke-Native 'flutter clean' { flutter clean }
Invoke-Native 'flutter pub get' { flutter pub get }

Write-Host "[3/4] build windows release"
Invoke-Native 'flutter build windows --release' { flutter build windows --release }

$pubspec = Get-Content (Join-Path $repoRoot 'pubspec.yaml') -Raw
if ($pubspec -match '(?m)^version:\s*([\d\.]+)') { $version = $Matches[1] }
else { throw "Could not find version in pubspec.yaml" }

$source = Join-Path $repoRoot 'build\windows\x64\runner\Release'
if (-not (Test-Path $source)) { throw "Build output not found: $source" }

$distDir = Join-Path $repoRoot 'dist'
New-Item -ItemType Directory -Force -Path $distDir | Out-Null
$zip = Join-Path $distDir "roosty-windows-v$version.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }

Write-Host "[4/4] zip -> $zip"
Compress-Archive -Path (Join-Path $source '*') -DestinationPath $zip -Force

Write-Host ""
Write-Host "OK: $zip"
