function Ensure-SsaModule {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter(Mandatory)]
    [string]$InstallHint
  )

  if (-not (Get-Module -ListAvailable -Name $Name)) {
    throw "Missing required PowerShell module '$Name'. Install it, e.g.: $InstallHint"
  }
}

function Test-SsaCommand {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Name
  )

  return [bool](Get-Command -Name $Name -ErrorAction SilentlyContinue)
}
