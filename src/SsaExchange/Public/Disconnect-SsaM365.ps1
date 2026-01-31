function Disconnect-SsaM365 {
  [CmdletBinding()]
  param()

  $session = Get-SsaSession

  if ($session.Connected.Graph -and (Test-SsaCommand -Name 'Disconnect-MgGraph')) {
    Disconnect-MgGraph | Out-Null
    $session.Connected.Graph = $false
  }

  if ($session.Connected.ExchangeOnline -and (Test-SsaCommand -Name 'Disconnect-ExchangeOnline')) {
    Disconnect-ExchangeOnline -Confirm:$false
    $session.Connected.ExchangeOnline = $false
  }

  # Compliance session is usually tied to the EXO connection; best-effort only.
  $session.Connected.Compliance = $false
}
