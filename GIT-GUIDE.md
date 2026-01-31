# Git Workflow & Versioning Guide

## SSA Correct - Version Control Strategy

This guide outlines the Git workflow, branching strategy, and versioning practices for the SSA Correct project.

---

## Table of Contents

1. [Branching Strategy](#branching-strategy)
2. [Versioning System](#versioning-system)
3. [Commit Guidelines](#commit-guidelines)
4. [Release Process](#release-process)
5. [Common Workflows](#common-workflows)
6. [Git Configuration](#git-configuration)

---

## Branching Strategy

### Main Branches

#### `main` (Production)
- **Purpose**: Production-ready code only
- **Protection**: Should be protected against direct commits
- **Deployment**: All releases are tagged from this branch
- **Merge Policy**: Only accept merges from `develop` or `hotfix/*` branches

#### `develop` (Integration)
- **Purpose**: Integration branch for features
- **State**: Should always be in a working state
- **Usage**: Features merge here first, then to `main` for releases
- **Testing**: All features tested before merging

### Supporting Branches

#### Feature Branches (`feature/*`)
- **Purpose**: Develop new features or enhancements
- **Naming**: `feature/short-description` (e.g., `feature/wpf-gui`, `feature/queue-engine`)
- **Branch from**: `develop`
- **Merge into**: `develop`
- **Lifetime**: Temporary (delete after merge)

**Example**:
```bash
git checkout develop
git checkout -b feature/bulk-export-ui
# ... work on feature ...
git add .
git commit -m "Add bulk export workbench UI"
git checkout develop
git merge --no-ff feature/bulk-export-ui
git branch -d feature/bulk-export-ui
```

#### Bugfix Branches (`bugfix/*`)
- **Purpose**: Fix bugs in `develop` branch
- **Naming**: `bugfix/issue-description` (e.g., `bugfix/connection-timeout`)
- **Branch from**: `develop`
- **Merge into**: `develop`
- **Lifetime**: Temporary (delete after merge)

#### Hotfix Branches (`hotfix/*`)
- **Purpose**: Emergency fixes for production
- **Naming**: `hotfix/v1.0.1` or `hotfix/critical-issue`
- **Branch from**: `main`
- **Merge into**: BOTH `main` AND `develop`
- **Lifetime**: Temporary (delete after merge)
- **Version bump**: Patch version (e.g., 1.0.0 → 1.0.1)

**Example**:
```bash
git checkout main
git checkout -b hotfix/v1.0.1
# ... fix critical issue ...
git add .
git commit -m "Fix critical session timeout bug"
# Merge to main
git checkout main
git merge --no-ff hotfix/v1.0.1
git tag -a v1.0.1 -m "Hotfix: session timeout"
# Merge to develop
git checkout develop
git merge --no-ff hotfix/v1.0.1
git branch -d hotfix/v1.0.1
```

#### Release Branches (`release/*`)
- **Purpose**: Prepare for a new production release
- **Naming**: `release/v1.0.0`
- **Branch from**: `develop`
- **Merge into**: BOTH `main` AND `develop`
- **Activities**: Version bump, documentation updates, final testing, bug fixes only
- **Lifetime**: Temporary (delete after merge)

---

## Versioning System

### Semantic Versioning (SemVer)

Format: **MAJOR.MINOR.PATCH** (e.g., `1.2.3`)

- **MAJOR** (X.0.0): Breaking changes, incompatible API changes
- **MINOR** (0.X.0): New features, backward-compatible
- **PATCH** (0.0.X): Bug fixes, backward-compatible

### Version Locations

The version is defined in **ONE authoritative location**:
```
src/SsaExchange/SsaExchange.psd1
```

Update the `ModuleVersion` field:
```powershell
@{
    ModuleVersion = '1.0.0'
    # ... other fields
}
```

All other references (release zips, tags, documentation) derive from this.

### Pre-release Versions

For development/beta releases:
- Format: `1.0.0-beta.1`, `1.0.0-rc.1`
- Not used in module manifest (PowerShell limitation)
- Use Git tags: `v1.0.0-beta.1`

---

## Commit Guidelines

### Commit Message Format

Use clear, conventional commit messages:

```
<type>: <short summary>

<optional body>

<optional footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style/formatting (no logic change)
- `refactor`: Code restructuring (no feature/fix)
- `test`: Add or update tests
- `chore`: Maintenance tasks (dependencies, build, etc.)
- `perf`: Performance improvements
- `security`: Security fixes or improvements

### Examples

**Good commits**:
```bash
feat: Add WPF bulk export workbench

Implements queue grid, connection status, and run controls.
Includes multi-select support and export type configuration.

fix: Resolve session timeout during bulk operations

Increased default idle timeout to 60s and added warning dialog.

docs: Update README with GUI installation steps

chore: Bump version to 1.0.0

security: Remove credential storage from event logs
```

**Bad commits**:
```bash
# Too vague
git commit -m "fixes"
git commit -m "updates"
git commit -m "WIP"

# No context
git commit -m "changed file"
```

### Small, Logical Commits

- **One logical change per commit**
- Commit early and often (on your feature branch)
- Don't commit broken code to `develop` or `main`
- Each commit should pass basic tests if possible

---

## Release Process

### 1. Prepare Release Branch

```bash
# From develop branch
git checkout develop
git pull origin develop
git checkout -b release/v1.0.0
```

### 2. Update Version

Edit `src/SsaExchange/SsaExchange.psd1`:
```powershell
ModuleVersion = '1.0.0'
```

Update `README.md` and `TODO.md` if needed.

Commit:
```bash
git add .
git commit -m "chore: Bump version to 1.0.0"
```

### 3. Build Release Package

```bash
.\build-release.ps1
```

Verify the output in `dist/SSA-Correct_v1.0.0.zip`.

### 4. Final Testing

- Test CLI mode
- Test GUI mode (when implemented)
- Test installation from zip
- Test bootstrapper (when implemented)
- Verify no credentials stored
- Test idle timeout and lock functionality

### 5. Merge to Main

```bash
git checkout main
git merge --no-ff release/v1.0.0
git tag -a v1.0.0 -m "Release v1.0.0: WPF Bulk Export Workbench"
git push origin main --tags
```

### 6. Merge Back to Develop

```bash
git checkout develop
git merge --no-ff release/v1.0.0
git push origin develop
```

### 7. Delete Release Branch

```bash
git branch -d release/v1.0.0
```

### 8. Create GitHub Release

1. Go to GitHub → Releases → Draft a new release
2. Choose tag: `v1.0.0`
3. Title: `v1.0.0 - WPF Bulk Export Workbench`
4. Upload `dist/SSA-Correct_v1.0.0.zip`
5. Add release notes (features, fixes, breaking changes)
6. Publish

---

## Common Workflows

### Starting a New Feature

```bash
git checkout develop
git pull origin develop
git checkout -b feature/my-feature
# ... work ...
git add .
git commit -m "feat: Add my feature"
git push origin feature/my-feature
# ... create pull request to develop ...
```

### Fixing a Bug

```bash
git checkout develop
git pull origin develop
git checkout -b bugfix/fix-description
# ... fix bug ...
git add .
git commit -m "fix: Resolve issue with X"
git checkout develop
git merge --no-ff bugfix/fix-description
git push origin develop
git branch -d bugfix/fix-description
```

### Emergency Hotfix

```bash
git checkout main
git pull origin main
git checkout -b hotfix/v1.0.1
# ... fix critical issue ...
# Update version in manifest to 1.0.1
git add .
git commit -m "fix: Critical security fix"
git checkout main
git merge --no-ff hotfix/v1.0.1
git tag -a v1.0.1 -m "Hotfix v1.0.1"
git push origin main --tags
git checkout develop
git merge --no-ff hotfix/v1.0.1
git push origin develop
git branch -d hotfix/v1.0.1
# Create GitHub release for v1.0.1
```

### Syncing Your Branch

```bash
# Update your feature branch with latest develop
git checkout feature/my-feature
git fetch origin
git rebase origin/develop
# Or use merge if you prefer
git merge origin/develop
```

---

## Git Configuration

### Initial Setup

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### Recommended Aliases

Add to `~/.gitconfig`:

```ini
[alias]
    st = status
    co = checkout
    br = branch
    ci = commit
    unstage = reset HEAD --
    last = log -1 HEAD
    visual = log --oneline --graph --decorate --all
    amend = commit --amend --no-edit
```

Usage:
```bash
git st              # git status
git co develop      # git checkout develop
git visual          # pretty graph view
```

### Recommended .gitignore

Already included in project root:
```
dist/
*.zip
*.log
*.tmp
.idea/
.vscode/
.vs/
```

---

## Best Practices

### DO
✅ Commit small, logical changes
✅ Write clear commit messages
✅ Pull before pushing
✅ Use feature branches
✅ Tag releases
✅ Test before merging to `main`
✅ Delete branches after merge
✅ Keep `main` and `develop` clean

### DON'T
❌ Commit directly to `main`
❌ Commit broken code to shared branches
❌ Commit sensitive data (credentials, tokens)
❌ Commit large binary files unnecessarily
❌ Use `git push --force` on shared branches
❌ Leave stale branches around
❌ Batch unrelated changes into one commit

---

## Branch Protection Rules (GitHub)

### For `main` branch:
- ✅ Require pull request reviews before merging
- ✅ Require status checks to pass (if CI/CD configured)
- ✅ Require branches to be up to date
- ✅ Include administrators (optional but recommended)
- ✅ Restrict who can push (optional)

### For `develop` branch:
- ✅ Require pull request reviews (optional, for team environments)
- ✅ Require status checks to pass

---

## Troubleshooting

### Undo Last Commit (Not Pushed)
```bash
git reset --soft HEAD~1  # Keep changes staged
git reset HEAD~1         # Keep changes unstaged
git reset --hard HEAD~1  # Discard changes (dangerous!)
```

### Discard Local Changes
```bash
git checkout -- <file>   # Single file
git reset --hard         # All files (dangerous!)
```

### Fix Wrong Branch
```bash
# If you committed to develop instead of a feature branch
git checkout develop
git log  # Note the commit hash
git reset --hard HEAD~1  # Undo commit
git checkout -b feature/my-feature
git cherry-pick <commit-hash>
```

### Merge Conflicts
```bash
# During merge, if conflicts occur:
# 1. Git marks conflict in files with <<<<<<, =======, >>>>>>>
# 2. Edit files to resolve
# 3. Stage resolved files
git add <resolved-file>
# 4. Complete merge
git commit
```

---

## Quick Reference

| Command | Description |
|---------|-------------|
| `git status` | Show working directory status |
| `git branch` | List branches |
| `git checkout -b <name>` | Create and switch to new branch |
| `git add <file>` | Stage file |
| `git commit -m "msg"` | Commit staged changes |
| `git push origin <branch>` | Push branch to remote |
| `git pull origin <branch>` | Pull and merge from remote |
| `git merge <branch>` | Merge branch into current |
| `git tag -a v1.0.0 -m "msg"` | Create annotated tag |
| `git push --tags` | Push tags to remote |
| `git log --oneline --graph` | View commit graph |
| `git diff` | Show unstaged changes |
| `git diff --staged` | Show staged changes |

---

**Last Updated**: 2026-01-31
**Project**: SSA Correct
**Versioning**: Semantic Versioning 2.0.0
