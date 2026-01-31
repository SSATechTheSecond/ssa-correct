$ErrorActionPreference = 'Stop'

$privateDir = Join-Path $PSScriptRoot 'Private'
$publicDir  = Join-Path $PSScriptRoot 'Public'

Get-ChildItem -Path $privateDir -Filter '*.ps1' -File | ForEach-Object { . $_.FullName }
Get-ChildItem -Path $publicDir  -Filter '*.ps1' -File | ForEach-Object { . $_.FullName }

$publicFunctionNames = Get-ChildItem -Path $publicDir -Filter '*.ps1' -File | ForEach-Object { $_.BaseName }
Export-ModuleMember -Function $publicFunctionNames
