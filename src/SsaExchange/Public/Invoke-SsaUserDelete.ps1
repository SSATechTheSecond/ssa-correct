function Invoke-SsaUserDelete {
  [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
  param(
    [Parameter(Mandatory)]
    [string]$TargetUpn
  )

  if (-not (Test-SsaCommand -Name 'Get-MgUser')) {
    throw 'Microsoft Graph Users cmdlets not available. Ensure Microsoft.Graph is installed and Connect-SsaM365 completed successfully.'
  }

  $user = Get-MgUser -UserId $TargetUpn -Property 'id,displayName,userPrincipalName,accountEnabled,mail' -ErrorAction Stop

  $exportFirst = Confirm-Ssa -Prompt 'Export user details to the job folder before deletion?' -DefaultYes:$true
  $out = $null
  $job = $null

  if ($exportFirst) {
    $out = Select-SsaOutputMode
    $job = New-SsaJobFolder -JobName 'User-Delete' -Target $TargetUpn

    $row = [pscustomobject]@{
      Id = $user.Id
      DisplayName = $user.DisplayName
      UserPrincipalName = $user.UserPrincipalName
      Mail = $user.Mail
      AccountEnabled = $user.AccountEnabled
      ExportedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
    }

    $null = Write-SsaResult -Rows @($row) -OutputMode $out -JobFolder $job -BaseName 'user-before-delete'
  }

  if (-not (Confirm-Ssa -Prompt "Are you sure you want to delete $($user.UserPrincipalName) ($($user.DisplayName))?" -DefaultYes:$false)) {
    Write-Host 'Cancelled.'
    return
  }

  if (-not (Confirm-Ssa -Prompt 'Confirm deletion again (this is your final confirmation)' -DefaultYes:$false)) {
    Write-Host 'Cancelled.'
    return
  }

  if ($PSCmdlet.ShouldProcess($user.UserPrincipalName, 'Delete Entra ID user')) {
    Remove-MgUser -UserId $user.Id -ErrorAction Stop
    Write-Host "Delete requested for $($user.UserPrincipalName)."
  }
}
