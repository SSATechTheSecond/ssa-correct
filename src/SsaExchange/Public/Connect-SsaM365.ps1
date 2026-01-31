function Connect-SsaM365 {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$AdminUpn
  )

  $session = Get-SsaSession
  $session.AdminUpn = $AdminUpn

  # Exchange Online
  Ensure-SsaModule -Name 'ExchangeOnlineManagement' -InstallHint 'Install-Module ExchangeOnlineManagement -Scope CurrentUser'

  # ExchangeOnlineManagement prints an informational banner about REST/RPS; suppress it for a cleaner UX.
  $prevInfo = $InformationPreference
  $InformationPreference = 'SilentlyContinue'
  try {
    Import-Module ExchangeOnlineManagement -ErrorAction Stop -InformationAction SilentlyContinue

    Write-Host 'Connecting to Exchange Online...'
    Write-SsaLog -Level 'INFO' -Message 'Connecting to Exchange Online'
    Connect-ExchangeOnline -UserPrincipalName $AdminUpn -ShowBanner:$false -InformationAction SilentlyContinue
    $session.Connected.ExchangeOnline = $true
    Write-SsaLog -Level 'INFO' -Message 'Connected to Exchange Online'

    # Purview / Compliance (for searches)
    if (Test-SsaCommand -Name 'Connect-IPPSSession') {
      Write-Host 'Connecting to Microsoft Purview / Compliance PowerShell...'
      Write-SsaLog -Level 'INFO' -Message 'Connecting to Purview/Compliance PowerShell'

      # Newer Purview/eDiscovery cmdlets require a Search-Only session.
      # If the module supports it, use -EnableSearchOnlySession to avoid runtime failures.
      $ippCmd = Get-Command -Name Connect-IPPSSession -ErrorAction SilentlyContinue | Select-Object -First 1
      if ($ippCmd -and $ippCmd.Parameters.ContainsKey('EnableSearchOnlySession')) {
        Connect-IPPSSession -UserPrincipalName $AdminUpn -EnableSearchOnlySession -ShowBanner:$false -InformationAction SilentlyContinue
      } else {
        Connect-IPPSSession -UserPrincipalName $AdminUpn -ShowBanner:$false -InformationAction SilentlyContinue
      }

      $session.Connected.Compliance = $true
      Write-SsaLog -Level 'INFO' -Message 'Connected to Purview/Compliance PowerShell'
    } else {
      Write-Warning 'Connect-IPPSSession was not found. PST search job creation may not work. (ExchangeOnlineManagement usually provides it.)'
    }
  }
  finally {
    $InformationPreference = $prevInfo
  }

  # Microsoft Graph
  Ensure-SsaModule -Name 'Microsoft.Graph.Authentication' -InstallHint 'Install-Module Microsoft.Graph -Scope CurrentUser'
  Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
  Import-Module Microsoft.Graph.Users -ErrorAction SilentlyContinue

  $scopes = @(
    'User.ReadWrite.All',
    'Directory.AccessAsUser.All'
  )

  Write-Host 'Connecting to Microsoft Graph...'
  Write-SsaLog -Level 'INFO' -Message 'Connecting to Microsoft Graph'
  Connect-MgGraph -Scopes $scopes | Out-Null
  $session.Connected.Graph = $true
  Write-SsaLog -Level 'INFO' -Message 'Connected to Microsoft Graph' -Data @{ Scopes = ($scopes -join ',') }
}
