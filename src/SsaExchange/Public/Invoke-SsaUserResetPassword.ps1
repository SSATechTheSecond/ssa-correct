function Invoke-SsaUserResetPassword {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$TargetUpn,

    [bool]$ForceChangePasswordNextSignIn = $true
  )

  if (-not (Test-SsaCommand -Name 'Update-MgUser')) {
    throw 'Microsoft Graph Users cmdlets not available. Ensure Microsoft.Graph is installed and Connect-SsaM365 completed successfully.'
  }

  # Generate a temporary password (not persisted by default)
  try {
    Add-Type -AssemblyName System.Web -ErrorAction Stop
    $tempPassword = [System.Web.Security.Membership]::GeneratePassword(16, 3)
  } catch {
    $chars = 'abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#$%&*?'
    $bytes = New-Object byte[] 16
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    $tempPassword = -join ($bytes | ForEach-Object { $chars[ $_ % $chars.Length ] })

    # Ensure some complexity characters are present
    $tempPassword = ($tempPassword.Substring(0, 12) + 'aA1!')
  }

  Update-MgUser -UserId $TargetUpn -PasswordProfile @{
    Password = $tempPassword
    ForceChangePasswordNextSignIn = $ForceChangePasswordNextSignIn
  } | Out-Null

  Write-Host ''
  Write-Host "Password reset OK for $TargetUpn"
  Write-Host "Temporary password: $tempPassword"
  Write-Host ''

  # Optional: allow exporting the action result, but avoid saving the password by accident.
  if (Confirm-Ssa -Prompt 'Do you want to export a confirmation record (without the password) to the job folder?' -DefaultYes:$true) {
    $out = Select-SsaOutputMode
    $job = New-SsaJobFolder -JobName 'User-PasswordReset' -Target $TargetUpn

    $row = [pscustomobject]@{
      Action = 'ResetPassword'
      TargetUpn = $TargetUpn
      ForceChangePasswordNextSignIn = $ForceChangePasswordNextSignIn
      TimestampUtc = (Get-Date).ToUniversalTime().ToString('o')
      Note = 'Temporary password was displayed on screen and intentionally not saved.'
    }

    $null = Write-SsaResult -Rows @($row) -OutputMode $out -JobFolder $job -BaseName 'password-reset'
  }
}
