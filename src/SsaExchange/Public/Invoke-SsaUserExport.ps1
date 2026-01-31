function Invoke-SsaUserExport {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$TargetUpn
  )

  if (-not (Test-SsaCommand -Name 'Get-MgUser')) {
    throw 'Microsoft Graph Users cmdlets not available. Ensure Microsoft.Graph is installed and Connect-SsaM365 completed successfully.'
  }

  $user = Get-MgUser -UserId $TargetUpn -Property 'id,displayName,userPrincipalName,accountEnabled,mail,createdDateTime' -ErrorAction Stop

  $row = [pscustomobject]@{
    Id = $user.Id
    DisplayName = $user.DisplayName
    UserPrincipalName = $user.UserPrincipalName
    Mail = $user.Mail
    AccountEnabled = $user.AccountEnabled
    CreatedDateTime = $user.CreatedDateTime
  }

  $out = Select-SsaOutputMode
  $job = New-SsaJobFolder -JobName 'User-Export' -Target $TargetUpn

  $null = Write-SsaResult -Rows @($row) -OutputMode $out -JobFolder $job -BaseName 'user'
}
