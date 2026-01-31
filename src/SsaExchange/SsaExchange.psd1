@{
  RootModule = 'SsaExchange.psm1'
  ModuleVersion = '0.1.0'
  GUID = 'd639f16a-5dd7-4f3c-8ad4-5f4c3a5c20d0'
  Author = 'Lourens'
  CompanyName = ''
  Copyright = ''
  Description = 'Menu-driven PowerShell app for common Microsoft 365 Exchange Online + Entra ID tasks.'
  PowerShellVersion = '5.1'
  FunctionsToExport = @(
    'Invoke-SsaExchangeApp',
    'Invoke-SsaExchangeGui',
    'Connect-SsaM365',
    'Disconnect-SsaM365',
    'Invoke-SsaUserResetPassword',
    'Invoke-SsaUserSetEnabled',
    'Invoke-SsaUserDelete',
    'Invoke-SsaUserExport',
    'Get-SsaMailboxSizeReport',
    'Invoke-SsaMailboxDelegation',
    'Invoke-SsaPstExportSearchJob'
  )
  CmdletsToExport = @()
  VariablesToExport = @()
  AliasesToExport = @()
  PrivateData = @{
    PSData = @{
      Tags = @('exchange','m365','entra','graph','powershell')
    }
  }
}
