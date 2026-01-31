function Select-SsaOutputMode {
  [CmdletBinding()]
  param()

  Write-Host ''
  Write-Host 'Output mode:'
  Write-Host '1) Screen only'
  Write-Host '2) Export to CSV'
  Write-Host '3) Export to JSON'
  Write-Host '4) Screen + Export'

  $choice = Read-SsaMenuChoice -Min 1 -Max 4 -Prompt 'Choose output mode'

  switch ($choice) {
    1 { return [pscustomobject]@{ Screen = $true;  Csv = $false; Json = $false } }
    2 { return [pscustomobject]@{ Screen = $false; Csv = $true;  Json = $false } }
    3 { return [pscustomobject]@{ Screen = $false; Csv = $false; Json = $true  } }
    4 { return [pscustomobject]@{ Screen = $true;  Csv = $true;  Json = $true  } }
  }
}

function Write-SsaResult {
  [CmdletBinding()]
  param(
    [Parameter()]
    [AllowNull()]
    [object[]]$Rows = @(),

    [Parameter(Mandatory)]
    [pscustomobject]$OutputMode,

    [Parameter(Mandatory)]
    [string]$JobFolder,

    [string]$BaseName = 'result'
  )

  # Normalize $Rows so callers can pass $null safely.
  $Rows = @($Rows)

  if ($Rows.Count -eq 0) {
    Write-Warning 'No results were returned.'
    Write-SsaLog -Level 'WARN' -Message 'No rows to output' -Data @{ BaseName = $BaseName; OutputMode = $OutputMode }

    if ($OutputMode.Screen) {
      Write-Host '(No results)'
    }

    if ($OutputMode.Csv) {
      $csvPath = Join-Path $JobFolder ("$BaseName.csv")
      '' | Set-Content -Encoding UTF8 -Path $csvPath
      Write-Host "CSV written (empty): $csvPath"
    }

    if ($OutputMode.Json) {
      $jsonPath = Join-Path $JobFolder ("$BaseName.json")
      '[]' | Set-Content -Encoding UTF8 -Path $jsonPath
      Write-Host "JSON written (empty): $jsonPath"
    }

    return [pscustomobject]@{ CsvPath = $csvPath; JsonPath = $jsonPath }
  }

  $written = [ordered]@{ CsvPath = $null; JsonPath = $null }

  if ($OutputMode.Screen) {
    $Rows | Format-Table -AutoSize | Out-Host
  }

  if ($OutputMode.Csv) {
    $csvPath = Join-Path $JobFolder ("$BaseName.csv")
    $Rows | Export-Csv -NoTypeInformation -Path $csvPath
    $written.CsvPath = $csvPath
    Write-Host "CSV written: $csvPath"
  }

  if ($OutputMode.Json) {
    $jsonPath = Join-Path $JobFolder ("$BaseName.json")
    $Rows | ConvertTo-Json -Depth 12 | Set-Content -Encoding UTF8 -Path $jsonPath
    $written.JsonPath = $jsonPath
    Write-Host "JSON written: $jsonPath"
  }

  if ($written.CsvPath -or $written.JsonPath) {
    Write-SsaLog -Level 'INFO' -Message 'Result exported' -Data @{ JobFolder = $JobFolder; CsvPath = $written.CsvPath; JsonPath = $written.JsonPath }
  }

  return [pscustomobject]$written
}
