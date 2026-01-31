# SSA Correct - Project TODO List

## Current Sprint - Foundation & GUI Development

### High Priority
- [ ] Implement WPF GUI for Bulk Export Workbench
  - [ ] Connection management UI (EXO/Compliance/Graph status indicators)
  - [ ] Build Queue panel with mailbox selection
  - [ ] Queue grid with multi-select support
  - [ ] Run controls (Start/Pause/Resume/Retry)
  - [ ] Unattended mode toggle + Lock Windows button
- [ ] Create Invoke-SsaExchangeGui.ps1 entry point
- [ ] Implement queue engine with controlled concurrency (2-4 concurrent searches)
- [ ] Add "Run unattended" mode with explicit toggle
- [ ] Implement Windows lock integration (LockWorkStation API)

### Medium Priority
- [ ] Add LastMailboxLogonTime retrieval from EXO
- [ ] Implement mailbox filtering (Inactive/User/Shared/Both)
- [ ] Create per-run project folder structure with state persistence
- [ ] Add Exclude/Remove functionality with audit notes in queue grid
- [ ] Implement resumable queue from saved state (queue.json)
- [ ] Add tooltips for all UI controls
- [ ] Create event logging system (events.jsonl)

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
