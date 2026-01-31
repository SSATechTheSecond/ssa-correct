function Initialize-SsaLogging {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$ExportRoot
  )

  $session = Get-SsaSession

  if (-not $session.RunId) {
    $session.RunId = ([guid]::NewGuid().ToString())
  }

  $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
  $logName = "SSAExchange_Run_${stamp}.log"
  $logPath = Join-Path $ExportRoot $logName

  $session.LogPath = $logPath

  if (-not (Test-Path -LiteralPath $ExportRoot)) {
    New-Item -ItemType Directory -Force -Path $ExportRoot | Out-Null
  }

  "# SSA Exchange log" | Set-Content -Encoding UTF8 -Path $logPath
  "# RunId: $($session.RunId)" | Add-Content -Encoding UTF8 -Path $logPath
  "# StartedUtc: $((Get-Date).ToUniversalTime().ToString('o'))" | Add-Content -Encoding UTF8 -Path $logPath
  "" | Add-Content -Encoding UTF8 -Path $logPath

  Write-SsaLog -Level 'INFO' -Message 'Logging initialized' -Data @{ ExportRoot = $ExportRoot }

  return $logPath
}

function Write-SsaLog {
  [CmdletBinding()]
  param(
    [ValidateSet('DEBUG','INFO','WARN','ERROR')]
    [string]$Level = 'INFO',

    [Parameter(Mandatory)]
    [string]$Message,

    [hashtable]$Data = $null
  )

  $session = Get-SsaSession
  if ([string]::IsNullOrWhiteSpace($session.LogPath)) {
    return
  }

  $ts = (Get-Date).ToUniversalTime().ToString('o')

  $dataJson = ''
  if ($null -ne $Data -and $Data.Count -gt 0) {
    try {
      $dataJson = ($Data | ConvertTo-Json -Compress -Depth 10)
    } catch {
      $dataJson = '{"error":"failed to serialize log data"}'
    }
  }

  $line = if ($dataJson) {
    "$ts [$Level] $Message $dataJson"
  } else {
    "$ts [$Level] $Message"
  }

  try {
    Add-Content -Encoding UTF8 -Path $session.LogPath -Value $line
  } catch {
    # Avoid breaking app flow if logging fails.
  }
}

function Get-SsaErrorData {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    $ErrorRecord
  )

  $ex = $ErrorRecord.Exception

  $data = [ordered]@{
    Message = $ex.Message
    ExceptionType = $ex.GetType().FullName
    FullyQualifiedErrorId = $ErrorRecord.FullyQualifiedErrorId
    CategoryInfo = $ErrorRecord.CategoryInfo.ToString()
  }

  if ($ErrorRecord.InvocationInfo) {
    $data.ScriptName = $ErrorRecord.InvocationInfo.ScriptName
    $data.Line = $ErrorRecord.InvocationInfo.ScriptLineNumber
    $data.PositionMessage = $ErrorRecord.InvocationInfo.PositionMessage
  }

  if ($ErrorRecord.ScriptStackTrace) {
    $data.ScriptStackTrace = $ErrorRecord.ScriptStackTrace
  }

  # Full exception string can be noisy; include it but keep it last.
  $data.Exception = $ex.ToString()

  return $data
}

function Stop-SsaLogging {
  [CmdletBinding()]
  param()

  $session = Get-SsaSession
  if ([string]::IsNullOrWhiteSpace($session.LogPath)) {
    return
  }

  Write-SsaLog -Level 'INFO' -Message 'Run finished' -Data @{ FinishedUtc = (Get-Date).ToUniversalTime().ToString('o') }
}
