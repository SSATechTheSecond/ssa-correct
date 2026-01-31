SSA Exchange (PowerShell)

Run:
  .\Invoke-SsaExchange.ps1

This is a menu-driven PowerShell app that connects interactively each run (no saved credentials) and provides:
- User management (password reset, enable/disable, delete, export user info) via Microsoft Graph
- Access management (mailbox delegation) via Exchange Online PowerShell
- Admin management (mailbox size reporting; PST export search job creation) via Exchange Online + Purview/Compliance

Prerequisites (install once):
- ExchangeOnlineManagement:
    Install-Module ExchangeOnlineManagement -Scope CurrentUser
- Microsoft Graph PowerShell SDK:
    Install-Module Microsoft.Graph -Scope CurrentUser

Notes:
- PST export: As of May 26, 2025, the classic PowerShell export parameters (e.g. New-ComplianceSearchAction -Export) were retired.
  This app creates and polls the compliance search, then writes instructions for exporting/downloading PST via the Purview portal.

Outputs:
- On startup you choose an Export Root folder.
- The app creates a per-run log file in the Export Root:
    SSAExchange_Run_yyyyMMdd_HHmmss.log
- Each job creates a subfolder under the Export Root with job details, CSV/JSON exports, and instructions where applicable.
