# SSA Correct

**Exchange Online Bulk Management Tool for Microsoft 365 Administrators**

SSA Correct is a Windows-native PowerShell tool designed to help administrators efficiently manage bulk operations across Microsoft 365, with a focus on Exchange Online mailbox exports, user management, and delegation tasks.

## Overview

Built for administrators managing large Microsoft 365 tenants (tested with 11k+ users), SSA Correct provides:

- **Bulk PST Export Management**: Create and track compliance searches for hundreds of mailboxes with controlled concurrency and resumable workflows
- **Secure Session Management**: No stored credentials, idle timeout protection, and Windows lock integration
- **Audit-Ready Tracking**: Project-based run folders with detailed logs, status tracking, and export instructions
- **Admin-Grade Controls**: Unattended mode with explicit opt-in, throttling controls, and resumable state

## Key Features

### Bulk Export Workbench
- Pull mailboxes directly from Exchange Online (User/Shared/Both)
- Filter by last mailbox activity, type, archive status
- Multi-select queue management with exclude/audit notes
- Controlled concurrency (2-4 concurrent operations) to avoid throttling
- One case per run, one search per mailbox for clean isolation
- Resumable workflows - pause, lock, and resume later

### Security First
- **No stored credentials**: Fresh authentication required each session
- **Idle timeout**: 60-second default with configurable warning
- **Unattended mode**: Explicit opt-in required for lock-and-continue workflows
- **Windows lock integration**: Lock workstation while jobs continue (admin choice)
- **Audit trail**: Event logging without storing sensitive data

### Built-In Features (Current CLI)
- User management (Graph): Reset password, enable/disable, delete, export
- Mailbox delegation (EXO): FullAccess, SendAs, SendOnBehalf, Calendar permissions
- Compliance export jobs (Purview): Create PST export searches with portal instructions

### GUI v1 (Available Now - Alpha)
- **WPF-based Bulk Export Workbench** with professional layout
- **Connection status indicators** with visual lights (EXO/Compliance/Graph)
- **Multiple load strategies**:
  - Inactive only (with customizable threshold: 30/90/180/365 days)
  - Top 10 by mailbox size
  - Top 10 by archive size
  - Load everything (all mailboxes)
- **Queue management grid** with multi-select support
- **Run controls**: Start, Pause, Resume, Retry Failed
- **Unattended mode toggle** with Windows lock integration
- **Export type selection**: Primary/Archive/Both
- **Concurrency control**: 2-5 concurrent operations
- **Tooltips** on all controls for guidance

## Prerequisites

### Required Modules
```powershell
Install-Module ExchangeOnlineManagement -Scope CurrentUser
Install-Module Microsoft.Graph -Scope CurrentUser
```

### Environment
- **Windows PowerShell 5.1** (recommended)
- Windows 10/11 or Windows Server 2016+
- Administrator rights in your Microsoft 365 tenant
- Appropriate role assignments:
  - Exchange administrator (or higher)
  - Compliance administrator (for eDiscovery)
  - User administrator (for Graph operations)

## Installation

### Option 1: Download Release (Recommended for controlled environments)
1. Download the latest release zip from [GitHub Releases](https://github.com/SSATechTheSecond/ssa-correct/releases)
2. Extract to a local folder
3. Unblock files if needed:
   ```powershell
   Get-ChildItem -Path ".\SSA-Correct" -Recurse | Unblock-File
   ```
4. Run the GUI launcher:
   ```powershell
   .\Run-Gui.ps1
   ```

### Option 2: Paste into PowerShell (Quick start - coming soon)
```powershell
iwr -useb https://raw.githubusercontent.com/SSATechTheSecond/ssa-correct/main/bootstrap.ps1 | iex
```

### Option 3: Clone and Run (Development)
```powershell
git clone https://github.com/SSATechTheSecond/ssa-correct.git
cd ssa-correct
.\Run-Gui.ps1
```

## Usage

### GUI Mode (v1 - Alpha - Available Now!)
```powershell
.\Run-Gui.ps1
```

The GUI will launch the Bulk Export Workbench with:
- Connection management (click "Connect" to authenticate)
- Load strategy selection (choose from 4 options)
- Queue building from Exchange Online
- Visual progress tracking
- Unattended mode with lock integration

### CLI Mode (Current)
```powershell
.\Invoke-SsaExchange.ps1
```

The CLI will:
1. Prompt for an Export Root folder (where outputs/logs will be saved)
2. Start a session log
3. Ask for your admin UPN
4. Connect to Exchange Online, Purview, and Microsoft Graph
5. Display an interactive menu for User/Access/Admin tasks

## Bulk Export Workflow

### Current CLI Process
1. Choose "Admin Management" → "Create PST Export Search Job"
2. Enter mailbox identity
3. Choose Primary/Archive/Both
4. Tool creates compliance search and monitors status
5. Outputs job folder with search details and Purview portal instructions

### Upcoming GUI Process (v1)
1. **Connect**: Authenticate to EXO/Compliance/Graph
2. **Build Queue**: Pull mailboxes from EXO with filters
   - Filter by type (User/Shared/Both)
   - Filter by last activity (30/90/180/365 days or custom)
   - Filter by archive status
3. **Review & Select**: Multi-select in queue grid, add notes, exclude if needed
4. **Configure & Run**:
   - Set export type (Primary/Archive/Both)
   - Set concurrency (default: 2-4)
   - Enable "Run unattended" if desired
   - Start queue
5. **Monitor**: Real-time status updates, pause/resume/retry controls
6. **Export**: Follow generated instructions to complete PST export in Purview portal

## Project Structure

```
SSA-Correct/
├── Run-Gui.ps1              # GUI launcher (future)
├── Invoke-SsaExchange.ps1   # CLI launcher (current)
├── build-release.ps1        # Release packaging script
├── setup.ps1                # Prerequisites installer helper
├── README.md                # This file
├── TODO.md                  # Project task tracking
├── GIT-GUIDE.md            # Git workflow and versioning guide
├── .gitignore
├── src/
│   └── SsaExchange/
│       ├── SsaExchange.psd1     # Module manifest
│       ├── SsaExchange.psm1     # Module loader
│       ├── Private/             # Internal helpers
│       │   ├── Logging.ps1
│       │   ├── Jobs.ps1
│       │   ├── Menu.ps1
│       │   ├── Output.ps1
│       │   ├── Dependencies.ps1
│       │   └── State.ps1
│       └── Public/              # Exported functions
│           ├── Connect-SsaM365.ps1
│           ├── Invoke-SsaExchangeApp.ps1
│           ├── Invoke-SsaUserResetPassword.ps1
│           ├── Invoke-SsaMailboxDelegation.ps1
│           ├── Invoke-SsaPstExportSearchJob.ps1
│           └── [other public functions]
└── config/                      # Optional config files
```

## Security & Compliance

### What We Don't Store
- Admin credentials or UPN
- Microsoft Graph or Exchange Online tokens
- Session authentication artifacts
- Full raw command output that may contain sensitive identifiers

### What We Do Store (Project Artifacts)
- Case names and search names
- Mailbox identities being processed (required for resumability)
- Statuses, timestamps, error messages (sanitized)
- Export instructions for Purview portal
- Event logs (operational, non-sensitive)

### Session Management
- **Idle timeout**: Default 60 seconds (configurable)
- **Unattended mode**: Explicit opt-in required
- **Lock integration**: Optionally lock Windows while job continues
- **Re-authentication**: Required after unlock or resume

## Troubleshooting

### Common Issues

**GUI not loading / "Invoke-SsaExchangeGui not found"**
- The WPF GUI is currently in development. Use `.\Invoke-SsaExchange.ps1` for CLI mode

**"Cannot connect to Exchange Online"**
- Verify ExchangeOnlineManagement module is installed
- Check you have appropriate admin permissions
- Ensure MFA is configured if required by your tenant

**"LastLogonTime shows blank"**
- Some mailboxes don't have logon data (never logged in, or data unavailable)
- Shared mailboxes may show odd patterns depending on delegate access
- This is normal - use other filters (type, size, archive status)

**Throttling errors during bulk operations**
- Reduce Max Concurrency setting (try 2 instead of 4)
- Increase poll interval
- Microsoft throttles aggressive bulk operations

## Building a Release

```powershell
.\build-release.ps1
```

This creates `dist\SSA-Correct_vX.Y.Z.zip` with:
- All necessary source files
- Launchers (Run-Gui.ps1, Invoke-SsaExchange.ps1)
- Documentation
- Proper structure for end-user execution

Version is read from `src\SsaExchange\SsaExchange.psd1`.

## Contributing

This is an admin-focused tool for real-world bulk operations. Contributions welcome:
- Security improvements
- UX enhancements for large tenant workflows
- Bug fixes and error handling improvements
- Documentation and examples

Please see TODO.md for current development priorities.

## Roadmap

### v0.1.0 (Current - CLI + GUI Alpha)
- ✅ User management (Graph)
- ✅ Mailbox delegation (EXO)
- ✅ PST export search creation (Purview)
- ✅ Project-based run folders
- ✅ Session logging
- ✅ WPF GUI foundation with Bulk Export Workbench
- ✅ Connection status indicators
- ✅ Queue grid with multi-select
- ✅ Multiple load strategies (Inactive/Top 10 Mailbox/Top 10 Archive/All)
- ✅ Unattended mode with Windows lock integration
- ✅ Run controls (Start/Pause/Resume/Retry)

### v1.0.0 (In Progress - GUI Production)
- ⏳ Connect GUI to actual EXO/Graph cmdlets
- ⏳ Implement real mailbox queries for each load strategy
- ⏳ Controlled concurrency queue engine
- ⏳ Background job processing with runspaces
- ⏳ Per-run project folders from GUI
- ⏳ Resumable queue state persistence

### v1.1.0+ (Future)
- 📋 User management GUI tab
- 📋 Delegation management GUI tab
- 📋 Reporting dashboard
- 📋 Advanced filtering and queries
- 📋 Export scheduling

## License

[Specify your license here]

## Credits

Created by an administrator, for administrators dealing with real-world bulk M365 operations.

Inspired by the "Chris Titus Tech" approach: one tool, easy access, admin-grade functionality.

---

**Version**: 0.1.0
**Last Updated**: 2026-01-31
**Target Platform**: Windows PowerShell 5.1
