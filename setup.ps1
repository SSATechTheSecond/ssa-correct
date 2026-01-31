[CmdletBinding()]
param(
  [switch]$TrustPSGallery,
  [switch]$SkipModuleUpdate
)

$ErrorActionPreference = 'Stop'

function Write-Section([string]$Title) {
  Write-Host ''
  Write-Host ('=' * 70)
  Write-Host $Title
  Write-Host ('=' * 70)
}

function Ensure-Tls12 {
  try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  } catch {
    # Best-effort.
  }
}

function Ensure-NuGetProvider {
  Write-Host 'Ensuring NuGet package provider...'
  $nuget = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
  if (-not $nuget) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
  }
}

function Ensure-PowerShellGet {
  # Many PS5.1 installs have an old PowerShellGet; updating improves Install-Module reliability.
  Write-Host 'Ensuring PowerShellGet is available...'
  try {
    $psGet = Get-Module -ListAvailable PowerShellGet | Sort-Object Version -Descending | Select-Object -First 1
    if (-not $psGet -or $psGet.Version -lt [Version]'2.2.5') {
      Install-Module PowerShellGet -Scope CurrentUser -Force -AllowClobber
      Write-Warning 'PowerShellGet was updated. If installs fail, close/reopen PowerShell and run setup again.'
    }
  } catch {
    Write-Warning "Could not update PowerShellGet automatically: $($_.Exception.Message)"
  }
}

function Ensure-Repository {
  $repo = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
  if (-not $repo) {
    throw 'PSGallery repository not found. PowerShellGet may be broken on this system.'
  }

  if ($TrustPSGallery) {
    if ($repo.InstallationPolicy -ne 'Trusted') {
      Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
      Write-Host 'Set PSGallery to Trusted.'
    }
  }
}

function Install-OrUpdateModule([string]$Name, [string]$MinimumVersion = $null) {
  Write-Host "\nModule: $Name"

  $installed = Get-Module -ListAvailable -Name $Name | Sort-Object Version -Descending | Select-Object -First 1
  if (-not $installed) {
    Write-Host "Installing $Name (CurrentUser)..."
    if ($MinimumVersion) {
      Install-Module $Name -Scope CurrentUser -Force -AllowClobber -MinimumVersion $MinimumVersion
    } else {
      Install-Module $Name -Scope CurrentUser -Force -AllowClobber
    }
    return
  }

  Write-Host "Found $Name version $($installed.Version)"
  if (-not $SkipModuleUpdate) {
    Write-Host "Updating $Name (if newer exists)..."
    try {
      Update-Module $Name -Force
    } catch {
      Write-Warning "Update-Module failed for ${Name}: $($_.Exception.Message)"
      Write-Warning 'This is often OK; you can still try running the app.'
    }
  }
}

Write-Section 'SSA Exchange setup: prerequisites'
Ensure-Tls12
Ensure-NuGetProvider
Ensure-PowerShellGet
Ensure-Repository

Write-Section 'Installing/updating required modules'
Install-OrUpdateModule -Name 'ExchangeOnlineManagement'
Install-OrUpdateModule -Name 'Microsoft.Graph' -MinimumVersion '2.0.0'

Write-Section 'Done'
Write-Host 'Next: run the app with:'
Write-Host '  powershell -ExecutionPolicy Bypass -File .\Invoke-SsaExchange.ps1'
