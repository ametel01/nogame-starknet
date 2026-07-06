# Plan 003: Restore battle math characterization tests

> **Executor instructions**: Follow this plan step by step. Run every verification command and confirm the expected result before moving to the next step. If anything in the "STOP conditions" section occurs, stop and report; do not improvise. When done, update the status row for this plan in `plans/README.md` unless a reviewer told you they maintain the index.
>
> **Drift check (run first)**: `git diff --stat 0c6e6f7..HEAD -- src/fleet_movements/library.cairo src/fleet_movements/battle_settlement.cairo src/fleet_movements/contract.cairo tests/fleet.cairo tests/fleet_write.cairo plans/README.md`
> If any in-scope file changed since this plan was written, compare the "Current state" excerpts against the live code before proceeding. On a mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: M
- **Risk**: LOW
- **Depends on**: none
- **Category**: tests
- **Planned at**: commit `0c6e6f7`, 2026-07-06

## Why this matters

Fleet battle math is the core of the game economy and is also the source of truth for the planned offchain simulator. The repo currently has many direct battle and speed tests in `tests/fleet.cairo`, but they are commented out and therefore provide no regression protection. Restoring a focused subset gives future simulator and battle changes a stable safety net without refactoring gameplay code.

## Current state

- `src/fleet_movements/library.cairo` defines `war`, speed, flight time, cargo, fuel, and debris helpers.
- `src/fleet_movements/battle_settlement.cairo` calls `fleet::war` and derives losses/debris.
- `src/fleet_movements/contract.cairo` exposes `simulate_attack` as a zero-tech preview.
- `tests/fleet.cairo` is almost entirely commented out.

Current excerpts:

```cairo
// src/fleet_movements/library.cairo:61-67
fn war(
    mut attackers: Fleet,
    a_techs: TechLevels,
    mut defenders: Fleet,
    defences: Defences,
    d_techs: TechLevels,
) -> (Fleet, Fleet, Defences) {
```

```cairo
// src/fleet_movements/battle_settlement.cairo:15-23
fn settle(
    attacker_initial_fleet: Fleet,
    defender_initial_fleet: Fleet,
    initial_defences: Defences,
    attacker_techs: TechLevels,
    defender_techs: TechLevels,
    initial_celestia: u32,
    time_since_arrived: u64,
) -> BattleSettlement {
```

```cairo
// tests/fleet.cairo:12-17
// #[test]
// fn test_war_basic() {
//     let mut attackers: Fleet = Default::default();
//     attackers.sparrow = 4;
//     attackers.scraper = 15;
```

Repo conventions to follow:

- Integration tests live under `tests/*.cairo`.
- Assertions use `assert(condition, 'short message')` or `assert!(condition, "...")`.
- Avoid changing production visibility unless necessary; prefer testing via public contract views where private functions cannot be reached.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Format | `scarb fmt --check` | exit 0 |
| Build | `scarb build` | exit 0 |
| Focused tests | `snforge test fleet` | fleet-related tests pass |
| Full tests | `snforge test` | all tests pass |

## Scope

**In scope**:

- `tests/fleet.cairo`
- `tests/fleet_write.cairo` only if public contract setup is needed for simulator assertions
- `plans/README.md`

**Out of scope**:

- Production battle formula changes
- Public ABI additions; that belongs to plan 007
- Large fixture rewrites in `tests/utils.cairo`

## Git workflow

- Branch: `advisor/003-restore-battle-math-characterization-tests`
- Commit style observed in history: imperative/conventional, for example `Replace no-op dockyard and defence tests`.
- Do not push or open a PR unless the operator instructed it.

## Steps

### Step 1: Replace commented test file with focused live tests

In `tests/fleet.cairo`, remove or leave behind no large commented blocks. Add a focused set of live tests that exercise public or test-accessible battle helpers. If direct helper functions are not importable because they are module-private, use `IFleetMovementsDispatcher.simulate_attack` through deployed contracts instead.

Minimum coverage:

- One attacker-vs-defender fleet matchup.
- One attacker-vs-defence matchup.
- One flight-time/speed behavior if helpers are importable; otherwise keep this for a future public helper plan and document why in a code comment.
- One simulator result assertion through `simulate_attack` to pin zero-tech behavior.

**Verify**: `scarb build` -> exit 0.

### Step 2: Use current behavior as characterization, not redesign

Use exact expected outputs from the current implementation. Do not "fix" odd battle math in this plan. The purpose is to pin current behavior before future changes.

If a current formula looks wrong, add a note in the test name or message only if needed, but do not change production code.

**Verify**: `snforge test fleet` -> new tests pass.

### Step 3: Run full gates and update index

**Verify**:

- `scarb fmt --check` -> exit 0
- `scarb build` -> exit 0
- `snforge test` -> all tests pass
- `git status --short` -> only in-scope files are modified

Update `plans/README.md` status for this plan to `DONE` only after verification passes.

## Test plan

- Convert `tests/fleet.cairo` from a commented-out placeholder into live characterization tests.
- Prefer small deterministic tests over broad end-to-end scenarios already covered by `tests/fleet_write.cairo`.
- Full verification is `snforge test`.

## Done criteria

- [ ] `tests/fleet.cairo` contains live tests, not only commented-out code.
- [ ] Tests pin at least simulator or battle behavior and one speed/flight-time behavior if accessible.
- [ ] No production code is changed.
- [ ] `scarb fmt --check`, `scarb build`, and `snforge test` pass.
- [ ] No files outside the in-scope list are modified.
- [ ] `plans/README.md` status row updated.

## STOP conditions

Stop and report if:

- Battle helpers cannot be tested directly and public `simulate_attack` is insufficient to write meaningful characterization.
- The expected behavior is nondeterministic.
- You need to change production visibility or ABI to make tests possible.
- Verification fails twice after reasonable fix attempts.

## Maintenance notes

These tests are a prerequisite safety net for plan 007 and any battle formula changes. Reviewers should reject production behavior changes in this plan; that would make the characterization ambiguous.
