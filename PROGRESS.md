# Implementation Progress

## PLAN.md Source Summary

Source plan: `/Users/alexmetelli/source/nogame-starknet/PLAN.md`.

The plan coordinates fourteen implementation plans from `plans/README.md` plus the prerequisite tracking setup in Step 0. It preserves the dependency order from the plan index, uses `scarb fmt --check`, `scarb build`, and `snforge test` as the repo-level gates, and requires each completed step to update this file with validation results, current status, and next status before the step commit is made.

The plan goals are to execute independently reviewable slices for fleet speed bounds, loot accounting, battle characterization, stale scripts, license metadata, workflow pinning, tech-aware simulation, multi-universe deployment manifests, large-ship debris accounting, bounded battle outcomes, class-weighted targeting, round shields and explosions, rapid fire, and defence rebuild settlement. Step 0 is tracking-only and must complete before feature or bug-fix implementation begins.

## Execution Checklist

- [x] Step 0: Progress and Changelog Tracking Setup
  - Create `PROGRESS.md`, confirm `CHANGELOG.md` follows Keep a Changelog structure, and record the update rules for all later steps.
- [ ] Step 1: Bound Fleet Speed Modifiers
  - Reject `send_fleet` speed modifiers outside `1..=100`.
- [ ] Step 2: Prevent Phantom Spendable Loot Grants
  - Keep spendable and collectible loot accounting separated and cargo-limited.
- [ ] Step 3: Restore Battle Math Characterization Tests
  - Restore focused live tests before larger battle-model changes.
- [x] Step 4: Repair Stale Scarb Scripts
  - Remove or repair script entries that reference missing files.
- [ ] Step 5: Resolve License Metadata Contradiction
  - Align license metadata after maintainer selection of MIT or CC BY-NC-SA 4.0.
- [ ] Step 6: Pin GitHub Actions to Immutable SHAs
  - Pin workflow actions to commit SHAs while preserving tool versions.
- [ ] Step 7: Add Tech-Aware Battle Simulation View
  - Add a non-breaking simulator view with caller-supplied tech levels.
- [ ] Step 8: Add Multi-Universe Deployment Manifest
  - Add a tracked example manifest and deployment docs for preserving universe address sets.
- [ ] Step 9: Fix Large-Ship Debris Costs
  - Use frigate and armade unit costs when calculating debris from large-ship losses.
- [ ] Step 10: Add Round-Capped Battle Draws
  - Bound battle execution at six rounds and grant loot only on attacker victory.
- [ ] Step 11: Add Class-Weighted Target Dilution
  - Use deterministic class counts for combat damage distribution.
- [ ] Step 12: Add Round Shields and Deterministic Explosions
  - Restore shield reset, persistent hull damage, and deterministic explosion approximation.
- [ ] Step 13: Replace Rapid-Fire Instant Kill
  - Replace hardcoded rapid-fire instant kill with bounded deterministic extra fire.
- [ ] Step 14: Add Defence Rebuild Settlement
  - Apply a named deterministic defence rebuild policy after attacks without rebuilding ships.

## Current status

Step 4 is complete and validated. The next available wave after Step 0 contains independent implementation plans 001, 002, 003, 006, 008, and 009; plan 005 remains blocked on a maintainer license decision.

## Update Rules

Every later implementation step must end with:

1. Run all quality gates listed for that step.
2. Fix any failures before proceeding.
3. Update `PROGRESS.md` with the completed step, validation results, commit reference if available, current status, and next step.
4. Update `CHANGELOG.md` under `## [Unreleased]` only if the step shipped a functional change, using Keep a Changelog headings and omitting empty headings.
5. Create a commit for that completed step.

Changelog entries are not required for tracking-only setup, test-only coverage, docs-only updates, validation runs, or CI housekeeping unless the specific step ships an observable user-facing or operator-facing change.

## Update log

- 2026-07-06: Created `PROGRESS.md` for Step 0. Confirmed `CHANGELOG.md` already has `# Changelog`, a Keep a Changelog preamble, and `## [Unreleased]`; no changelog edit needed.
- 2026-07-06: Validation passed: `test -f PROGRESS.md && rg -n "Step 0|Step 14|Current status|Update log" PROGRESS.md` found the required tracker markers.
- 2026-07-06: Validation passed: `test -f CHANGELOG.md && rg -n "# Changelog|Keep a Changelog|## \\[Unreleased\\]" CHANGELOG.md` found the required changelog markers.
- 2026-07-06: Completed Step 4 by removing stale `declare`, `deploy`, and `len` Scarb scripts that pointed to missing `scripts/sepolia/*` and `scripts/sierra_len.sh` files. Deployment docs already use `./scripts/deploy-starknet.sh`, so no deployment-doc edit was needed.
- 2026-07-06: Validation passed for Step 4: `find scripts -maxdepth 3 -type f -print | sort`; `rg -n "scripts/sepolia|sierra_len|scarb run deploy|deploy-starknet" Scarb.toml DEPLOYMENT.md README.md`; `rg -n "declare|deploy|len|scripts/" Scarb.toml DEPLOYMENT.md scripts`; `scarb fmt --check`; `scarb build`; `snforge test` (114 passed).
