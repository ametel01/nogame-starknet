# Implementation Progress

## PLAN.md Source Summary

Source plan: `/Users/alexmetelli/source/nogame-starknet/PLAN.md`.

The plan coordinates fourteen implementation plans from `plans/README.md` plus the prerequisite tracking setup in Step 0. It preserves the dependency order from the plan index, uses `scarb fmt --check`, `scarb build`, and `snforge test` as the repo-level gates, and requires each completed step to update this file with validation results, current status, and next status before the step commit is made.

The plan goals are to execute independently reviewable slices for fleet speed bounds, loot accounting, battle characterization, stale scripts, license metadata, workflow pinning, tech-aware simulation, multi-universe deployment manifests, large-ship debris accounting, bounded battle outcomes, class-weighted targeting, round shields and explosions, rapid fire, and defence rebuild settlement. Step 0 is tracking-only and must complete before feature or bug-fix implementation begins.

## Execution Checklist

- [x] Step 0: Progress and Changelog Tracking Setup
  - Create `PROGRESS.md`, confirm `CHANGELOG.md` follows Keep a Changelog structure, and record the update rules for all later steps.
- [x] Step 1: Bound Fleet Speed Modifiers
  - Reject `send_fleet` speed modifiers outside `1..=100`.
- [x] Step 2: Prevent Phantom Spendable Loot Grants
  - Keep spendable and collectible loot accounting separated and cargo-limited.
- [x] Step 3: Restore Battle Math Characterization Tests
  - Restore focused live tests before larger battle-model changes.
- [x] Step 4: Repair Stale Scarb Scripts
  - Remove or repair script entries that reference missing files.
- [ ] Step 5: Resolve License Metadata Contradiction
  - Align license metadata after maintainer selection of MIT or CC BY-NC-SA 4.0.
- [x] Step 6: Pin GitHub Actions to Immutable SHAs
  - Pin workflow actions to commit SHAs while preserving tool versions.
- [x] Step 7: Add Tech-Aware Battle Simulation View
  - Add a non-breaking simulator view with caller-supplied tech levels.
- [x] Step 8: Add Multi-Universe Deployment Manifest
  - Add a tracked example manifest and deployment docs for preserving universe address sets.
- [x] Step 9: Fix Large-Ship Debris Costs
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

Steps 1, 2, 3, 4, 6, 7, 8, and 9 are complete and validated. Attack loot buckets remain separated and cargo-limited, GitHub Actions are pinned to immutable commit SHAs while preserving tool versions, the battle simulator supports caller-supplied attacker and defender tech levels, the deployment docs include a tracked example manifest for preserving universe address sets, and large-ship debris uses frigate and armade unit costs. Plan 005 remains blocked on a maintainer license decision.

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
- 2026-07-06: Completed Step 3 / issue #38 on branch `codex/issue-38-battle-characterization`: replaced the commented `tests/fleet.cairo` placeholder with live characterization tests for direct battle helper matchups, zero-tech `simulate_attack`, and carrier speed/flight-time behavior. Validation passed: `snforge test fleet` (31 passed, 87 filtered), `scarb fmt --check`, `scarb build`, and `snforge test` (118 passed). Implementation commit after rebase: `60ee0ae`.
- 2026-07-06: Completed Step 1 for issue #36 by rejecting `send_fleet` `speed_modifier` values outside `1..=100` before travel-time and fuel-cost arithmetic, preserving the public ABI, mission storage, and existing 50 percent behavior. Validation passed: `scarb build`; `snforge test test_send_speed_modifier`; `scarb fmt --check`; `snforge test`. Commit reference pending coordinator handoff.
- 2026-07-06: Completed Step 2 / plan 002 on branch `codex/issue-37-phantom-loot`. `calculate_loot_amount` now loads collectible cargo first and only loads capped defender spendable balances into `loot_spendable` with remaining cargo.
- 2026-07-06: Added regression coverage in `test_attack_planet_loot_low_cargo_does_not_mint_spendable`; it failed before the production fix with `wrong quartz loot source` and passed after the fix.
- 2026-07-06: Validation passed for Step 2: `scarb fmt --check`, `scarb build`, `snforge test test_attack_planet_loot`, and `snforge test` all exited 0. Full suite result: 115 passed, 0 failed. Commit reference pending after rebase.
- 2026-07-06: Step 6 pinned workflow actions to immutable SHAs: `actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5`, `software-mansion/setup-scarb@2a96b748888e3329ee44ac9ac073d930e692b3cd`, and `foundry-rs/setup-snfoundry@ee00ea3f026379008ca40a54448d4059233d06cc`; no Scarb or snfoundry version changes.
- 2026-07-06: Step 6 validation passed: `rg -n "uses:" .github/workflows`, `rg -n "uses: .*@(v[0-9]|main|master)" .github/workflows` returned no matches, `yq e '.'` parsed all workflow YAML files, `scarb fmt --check`, `scarb build`, and `snforge test` passed with 114 tests.
- 2026-07-06: Completed Step 8 by adding `deployments/universes.example.json` and documenting the redeploy-all universe manifest workflow in `DEPLOYMENT.md`; commit reference pending.
- 2026-07-06: Step 8 validation passed: `python3 -m json.tool deployments/universes.example.json >/dev/null`; `rg -n "universes.example.json|UNIVERSE_ID|universe_id|manifest|GAME_ADDRESS" DEPLOYMENT.md deployments/universes.example.json`; `scarb fmt --check`; `scarb build`; `snforge test` (114 passed).
- 2026-07-06: Completed Step 9 on `codex/issue-44-large-ship-debris`: `get_debris` now uses `costs.frigate` and `costs.armade` for destroyed frigate/armade debris instead of sparrow costs, with focused regression coverage in `tests/fleet_write.cairo`.
- 2026-07-06: Step 9 validation passed: `scarb build`; `snforge test debris` (8 passed, 0 failed, 107 filtered out); `scarb fmt --check`; `scarb build`; `snforge test` (115 passed, 0 failed).
- 2026-07-06: Completed Step 7 / issue #42 by adding `simulate_attack_with_techs` to `IFleetMovements` and delegating the existing `simulate_attack` compatibility view through default attacker and defender tech levels. The new view calls `battle_settlement::settle` with caller-supplied techs, `defences.celestia`, and `time_since_arrived = 0`.
- 2026-07-06: Added simulator coverage for zero-tech compatibility and an asymmetric carrier matchup whose expected losses change if attacker or defender techs are ignored or swapped.
- 2026-07-06: Validation passed for Step 7: `snforge test simulate` (2 passed, 120 filtered), `scarb fmt --check`, `scarb build`, and `snforge test` (122 passed). Commit reference pending after rebase.
