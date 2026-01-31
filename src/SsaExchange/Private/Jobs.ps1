function Select-SsaFolderDialog {
  [CmdletBinding()]
  param(
    [string]$Description = 'Select a folder',
    [string]$SelectedPath = $null
  )

  try {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop

    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = $Description
    if ($SelectedPath) {
      $dialog.SelectedPath = $SelectedPath
    }

    $result = $dialog.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK -and -not [string]::IsNullOrWhiteSpace($dialog.SelectedPath)) {
      return $dialog.SelectedPath
    }
  } catch {
    # Common failure: not running in STA / GUI not available.
  }

  return $null
}

function Initialize-SsaExportRoot {
  [CmdletBinding()]
  param(
    [string]$DefaultFolderName = 'Exports'
  )

  $session = Get-SsaSession

  $defaultPath = Join-Path (Get-Location) $DefaultFolderName

  Write-Host ''
  Write-Host 'Export Root folder:'
  Write-Host "- Each job will create its own subfolder under this location."
  Write-Host "- Default: $defaultPath"
  Write-Host ''

  $root = $null

  if (Confirm-Ssa -Prompt 'Open a folder picker to choose the Export Root?' -DefaultYes:$false) {
    $root = Select-SsaFolderDialog -Description 'Select Export Root folder' -SelectedPath $defaultPath
    if (-not $root) {
      Write-Warning 'Folder picker not available. Falling back to path prompt.'
    }
  }

  if (-not $root) {
    Write-Host "Press Enter to use: $defaultPath"
    $root = Read-Host 'Enter Export Root path'
    if ([string]::IsNullOrWhiteSpace($root)) {
      $root = $defaultPath
    }
  }

  $root = [System.IO.Path]::GetFullPath($root)

  if (-not (Test-Path -LiteralPath $root)) {
    New-Item -ItemType Directory -Force -Path $root | Out-Null
  }

  $session.ExportRoot = $root
  return $root
}

function New-SsaJobFolder {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$JobName,

    [string]$Target = $null
  )

  $session = Get-SsaSession
  if ([string]::IsNullOrWhiteSpace($session.ExportRoot)) {
    throw 'ExportRoot is not set. Call Initialize-SsaExportRoot first.'
  }

  $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
  $base = $JobName
  if (-not [string]::IsNullOrWhiteSpace($Target)) {
    $base = "$JobName-$Target"
  }

  # Sanitize for filesystem
  $safe = ($base -replace '[^a-zA-Z0-9\-_\.]+', '_')

  $folder = Join-Path $session.ExportRoot ("${safe}_${stamp}")
  New-Item -ItemType Directory -Force -Path $folder | Out-Null

  Write-SsaLog -Level 'INFO' -Message 'Job folder created' -Data @{ JobName = $JobName; Target = $Target; Folder = $folder }

  return $folder
}
