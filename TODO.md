# SSA Correct - Project TODO List

## Current Sprint - Foundation & GUI Development

### Completed ✅
- [x] Implement WPF GUI for Bulk Export Workbench
  - [x] Connection management UI (EXO/Compliance/Graph status indicators)
  - [x] Build Queue panel with mailbox selection
  - [x] Queue grid with multi-select support
  - [x] Run controls (Start/Pause/Resume/Retry)
  - [x] Unattended mode toggle + Lock Windows button
- [x] Create Invoke-SsaExchangeGui.ps1 entry point
- [x] Add "Run unattended" mode with explicit toggle
- [x] Implement Windows lock integration (LockWorkStation API)
- [x] Implement mailbox filtering (Inactive/User/Shared/Both)
- [x] Add tooltips for all UI controls
- [x] Add Top 10 by mailbox size load strategy
- [x] Add Top 10 by archive size load strategy
- [x] Fix Ui.ps1 encoding issues (curly quotes)

### High Priority (In Progress)
- [ ] Implement queue engine with controlled concurrency (2-4 concurrent searches)
- [ ] Connect GUI to actual EXO cmdlets (Connect-SsaM365)
- [ ] Implement actual mailbox query logic for each load strategy
- [ ] Add LastMailboxLogonTime retrieval from EXO
- [ ] Add mailbox size retrieval for Top 10 strategies

### Medium Priority
- [ ] Create per-run project folder structure with state persistence
- [ ] Add Exclude/Remove functionality with audit notes in queue grid
- [ ] Implement resumable queue from saved state (queue.json)
- [ ] Create event logging system (events.jsonl)
- [ ] Implement background job processing with runspaces

### Low Priority
- [ ] Add bulk actions (Set ExportType for selected)
- [ ] Implement "Preview count" before building queue
- [ ] Add mailbox size reporting in queue grid
- [ ] Create archive status detection
- [ ] Implement "Open Purview portal" deep links
- [ ] Add summary CSV/JSON export functionality

## Backlog - Future Features

### User Management Tab (Post-v1)
- [ ] Search user by UPN
- [ ] Reset password UI
- [ ] Enable/disable account UI
- [ ] Export user info UI
- [ ] License view integration

### Mailbox Delegation Tab (Post-v1)
- [ ] Add/remove FullAccess UI
- [ ] Add/remove SendAs UI
- [ ] Add/remove SendOnBehalf UI
- [ ] Calendar permissions editor

### Reporting Tab (Post-v1)
- [ ] Mailbox size report UI
- [ ] Top N mailbox sizes view
- [ ] Export to CSV/JSON from GUI

## Technical Debt
- [ ] Refactor Public functions to return structured objects (not just host text)
- [ ] Remove Read-Host prompts from core functions
- [ ] Add consistent error handling/throwing
- [ ] Create background runspace/task pattern for WPF responsiveness
- [ ] Add unit tests for core functions

## Documentation
- [ ] Complete README.md with prerequisites and setup
- [ ] Create GIT-GUIDE.md for versioning strategy
- [ ] Document "Run unattended" security model
- [ ] Add tooltips documentation
- [ ] Create admin user guide

## Release/Distribution
- [ ] Test build-release.ps1 packaging script
- [ ] Create bootstrapper script (bootstrap.ps1)
- [ ] Set up GitHub repository structure
- [ ] Create first GitHub Release (v0.1.0)
- [ ] Test "paste into PowerShell" installation method
- [ ] Test manual zip download method

## Security & Compliance
- [ ] Verify no credentials stored anywhere
- [ ] Verify no admin UPN written to disk
- [ ] Test idle timeout (60s default)
- [ ] Test Windows lock integration
- [ ] Audit event logging for sensitive data
- [ ] Review token cache handling

## Notes
- Default to Primary + Archive ("Both") for export type
- One case per run, one search per mailbox
- Target: Windows PowerShell 5.1
- Queue must be pausable/resumable
- No unattended runs without explicit toggle

---
*Last Updated: 2026-01-31*
