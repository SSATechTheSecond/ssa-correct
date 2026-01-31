function Invoke-SsaUserSetEnabled {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$TargetUpn,

    [Parameter(Mandatory)]
    [bool]$Enabled
  )

  if (-not (Test-SsaCommand -Name 'Update-MgUser')) {
    throw 'Microsoft Graph Users cmdlets not available. Ensure Microsoft.Graph is installed and Connect-SsaM365 completed successfully.'
  }

  Update-MgUser -UserId $TargetUpn -AccountEnabled:$Enabled | Out-Null

  $action = if ($Enabled) { 'EnableAccount' } else { 'DisableAccount' }
  Write-Host "$action OK for $TargetUpn"

  $out = Select-SsaOutputMode
  $job = New-SsaJobFolder -JobName "User-$action" -Target $TargetUpn

  $row = [pscustomobject]@{
    Action = $action
    TargetUpn = $TargetUpn
    AccountEnabled = $Enabled
    TimestampUtc = (Get-Date).ToUniversalTime().ToString('o')
  }

  $null = Write-SsaResult -Rows @($row) -OutputMode $out -JobFolder $job -BaseName 'account-enabled'
}
