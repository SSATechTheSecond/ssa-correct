[CmdletBinding()]
param(
  [string]$OutDir = (Join-Path $PSScriptRoot 'dist')
)

$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$manifestPath = Join-Path $scriptRoot 'src\SsaExchange\SsaExchange.psd1'

if (-not (Test-Path $manifestPath)) {
  throw "Module manifest not found: $manifestPath"
}

$manifest = Import-PowerShellDataFile -Path $manifestPath
$version = $manifest.ModuleVersion
if (-not $version) { throw "ModuleVersion missing in $manifestPath" }

$packageName = "SSA-Correct_v$version"
$stageDir = Join-Path $OutDir $packageName
$zipPath = Join-Path $OutDir "$packageName.zip"

Write-Host "Building SSA Correct v$version..." -ForegroundColor Cyan

# Clean output
if (Test-Path $stageDir) { Remove-Item $stageDir -Recurse -Force }
if (Test-Path $zipPath)  { Remove-Item $zipPath -Force }
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

New-Item -ItemType Directory -Path $stageDir | Out-Null

# Copy runnable files
$include = @(
  'Run-Gui.ps1',
  'Invoke-SsaExchange.ps1',
  'README.md',
  'README.txt',
  'setup.ps1',
  'src',
  'config'
)

foreach ($item in $include) {
  $srcPath = Join-Path $scriptRoot $item
  if (Test-Path $srcPath) {
    Write-Host "  Copying: $item" -ForegroundColor Gray
    Copy-Item -Path $srcPath -Destination (Join-Path $stageDir $item) -Recurse -Force
  }
  else {
    Write-Host "  Skipping (not found): $item" -ForegroundColor Yellow
  }
}

# Remove dev-only stuff if it got copied
$devPaths = @(
  (Join-Path $stageDir '.idea'),
  (Join-Path $stageDir '.vscode'),
  (Join-Path $stageDir '.vs'),
  (Join-Path $stageDir 'dist'),
  (Join-Path $stageDir '*.log')
)

foreach ($devPath in $devPaths) {
  if (Test-Path $devPath) {
    Write-Host "  Removing dev files: $devPath" -ForegroundColor Gray
    Remove-Item $devPath -Recurse -Force -ErrorAction SilentlyContinue
  }
}

# Zip
Write-Host "  Creating zip archive..." -ForegroundColor Gray
Compress-Archive -Path (Join-Path $stageDir '*') -DestinationPath $zipPath -Force

Write-Host ""
Write-Host "Build complete!" -ForegroundColor Green
Write-Host "  Package: $zipPath" -ForegroundColor Cyan
Write-Host "  Size: $([math]::Round((Get-Item $zipPath).Length / 1KB, 2)) KB" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Test the package: Expand-Archive '$zipPath' -DestinationPath 'C:\Temp\test'" -ForegroundColor Gray
Write-Host "  2. Create GitHub Release and upload: $zipPath" -ForegroundColor Gray
Write-Host "  3. Tag the release: git tag -a v$version -m 'Release v$version'" -ForegroundColor Gray
