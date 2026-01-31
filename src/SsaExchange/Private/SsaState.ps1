if (-not $script:SsaSession) {
  $script:SsaSession = [ordered]@{
    RunId = $null
    LogPath = $null
    ExportRoot = $null
    AdminUpn = $null
    Connected = [ordered]@{
      ExchangeOnline = $false
      Graph = $false
      Compliance = $false
    }
  }
}

function Get-SsaSession {
  [CmdletBinding()]
  param()
  return $script:SsaSession
}
