# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2026-06-04

### Added
- ✨ Windows cross-platform compatibility
  - Replaced `cp -r` with Node.js `fs.cpSync` API
  - Replaced `chmod +x` with `fs.chmodSync` (skipped on Windows)
  - Added platform detection for Windows-specific behavior

### Fixed
- 🐛 TDD_GATE false positives on non-source files
  - Added exclusion rules for LICENSE, .gitignore, .gitleaks.toml, package-lock.json
  - Now correctly identifies only actual source code files
- 🐛 commit-msg hook not supporting `spec` and `tweak` commit types
  - Added `spec` for specification documents (PRD, plan, design)
  - Added `tweak` for small changes via /tweak shortcut
- 🐛 PRD gate macOS grep compatibility issue
  - Changed from `grep -qiE` to separate `grep -qi` calls
  - Uses "User Stor" to match both "User Story" and "User Stories"
- 🐛 TDD_GATE not recognizing Node.js test files
  - Added patterns: `^test\.`, `test\.js$`, `test\.ts$`, `test\.py$`
  - Now correctly matches test.js, test.ts, test.py, etc.

### Documentation
- 📚 Updated README.md, README.zh.md, README.en.md to v1.0.1
- 📚 Added Windows platform support notes
- 📚 Added detailed changelog section
- 📚 Updated command count from 6 to 9

## [1.0.0] - 2026-06-04

### Added
- 🎉 First public release on npm as `aiit-base`
- 9 slash commands for Claude Code:
  - `/discover` — Transform ideas into PRD specs (Phase 1)
  - `/plan` — Decompose PRD into executable tasks (Phase 2)
  - `/execute` — TDD implementation loop (Phase 3)
  - `/verify` — 7-step verification process (Phase 4)
  - `/close-phase` — Archive and knowledge extraction (Phase 5)
  - `/hotfix` — Emergency fix shortcut (≤3 files)
  - `/tweak` — Small change shortcut (≤5 files)
  - `/diagnose` — Health audit (10 checks)
  - `/onboard` — Interactive setup wizard
- 4 CLI commands:
  - `aiit init` — Initialize base in project
  - `aiit status` — View active changes and phase
  - `aiit doctor` — Diagnose installation health
  - `aiit update` — Update to latest version
- 17 quality gates across 5 phases:
  - Phase 0: Directory Structure, Hook Activation
  - Phase 1: PRD Completeness, Testability
  - Phase 2: Task Granularity, No Cyclic Deps, Spec Alignment
  - Phase 3: TDD Gate, File Scope, Spec Drift
  - Phase 4: Coverage, Contract, Security, Smoke Test, Full Diagnostics
  - Phase 5: Archive Completeness, Destructive Op
- 5 automation scripts:
  - `aiit-env.sh` — Environment discovery
  - `aiit-state.sh` — Unified state management
  - `aiit-guard.sh` — Phase transition guard
  - `aiit-archive.sh` — One-command archive
  - `aiit-yaml-validate.sh` — Schema validation
- Complete 5-phase lifecycle management:
  - Phase 0: Initialize
  - Phase 1: Discover (PRD spec)
  - Phase 2: Plan (task DAG)
  - Phase 3: Execute (TDD loop)
  - Phase 4: Verify (7-step verification)
  - Phase 5: Release (archive)
- Integration with OpenSpec and Superpowers
- Git hooks (pre-commit, commit-msg, pre-push)
- Migration Journal auto-generation
- State management with `.aiit.yaml`
- Session interruption recovery
- 4 enablement levels (L0-L3):
  - L0 Hotfix — Zero config, emergency only
  - L1 Light — Individual developer
  - L2 Standard — Team workflow (recommended)
  - L3 Full — Enterprise with metrics and evolution

### Documentation
- 📚 README.md — Landing page (bilingual links)
- 📚 README.zh.md — Complete Chinese guide
- 📚 README.en.md — Complete English guide
- 📚 Inline documentation for all commands and scripts

---

## Release Notes

### v1.0.1 — Windows Support

This patch release focuses on making Aiit work seamlessly across all major platforms.

**Key Changes:**
- **Cross-platform file operations**: Replaced Unix shell commands with Node.js fs API
- **Windows compatibility**: CLI and initialization now work on Windows PowerShell/CMD
- **Bug fixes**: Resolved 5 issues found during user interaction verification testing

**Verification:**
- ✅ Tested on macOS (full lifecycle)
- ✅ Tested on Windows (initialization and basic commands)
- ✅ 9 commands verified end-to-end
- ✅ All git hooks functional

**Upgrade:**
```bash
npm install -g aiit-base@latest
```

### v1.0.0 — Initial Release

The first public release of Aiit, providing a complete AI-native development workflow base.

**Highlights:**
- Complete 5-phase development lifecycle
- 9 slash commands + 4 CLI commands
- 17 automated quality gates
- State management and session recovery
- Migration Journal for knowledge preservation
- Integration with OpenSpec and Superpowers ecosystems

**Installation:**
```bash
npm install -g aiit-base
aiit init
```

**Next Steps:**
- Run `/onboard` in Claude Code to configure
- Start with `/discover "your idea"` to create your first change
- Follow the guided workflow through all 5 phases
