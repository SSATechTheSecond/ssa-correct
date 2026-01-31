[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot 'src\SsaExchange\SsaExchange.psd1'

Import-Module $modulePath -Force

# Future: this will launch the WPF GUI once implemented.
if (Get-Command -Name Invoke-SsaExchangeGui -ErrorAction SilentlyContinue) {
  Invoke-SsaExchangeGui
  return
}

Write-Warning "GUI entry point 'Invoke-SsaExchangeGui' not found yet. Launching CLI app instead."
Invoke-SsaExchangeApp
