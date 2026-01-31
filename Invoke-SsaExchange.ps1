[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot 'src\SsaExchange\SsaExchange.psd1'

Import-Module $modulePath -Force

Invoke-SsaExchangeApp
