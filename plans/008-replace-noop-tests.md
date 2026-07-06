# Plan 008: Replace no-op requirement tests with real regressions

> **Drift check (run first)**: `git diff --stat a370d98..HEAD -- tests/dockyard_write.cairo tests/defence_write.cairo tests/dockyard_view.cairo tests/fleet_view.cairo src/dockyard/contract.cairo src/defence/contract.cairo`

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: LOW
- **Depends on**: plans/003-gate-privileged-state-setters.md, plans/005-charge-colony-upgrades-and-builds.md
- **Category**: tests
- **Planned at**: commit `a370d98`, 2026-07-06

## Why This Matters

The repo has useful fleet tests, but several dockyard and defence requirement tests are commented out or pass with `assert(0 == 0, 'todo')`. These are exactly the paths where access control and requirement regressions have already appeared. Replacing no-op tests makes future refactors safer.

## Current State

```cairo
// tests/defence_write.cairo:108
fn test_astral_build_fails_beam_tech_level() {
    // TODO
    assert(0 == 0, 'todo');
}
```

```cairo
// tests/dockyard_write.cairo:41
// fn test_carrier_build_fails_dockyard_level() { // TODO
//     assert(0 == 0, 'todo');
// }
```

Contract comments also show intended access control:

```cairo
// src/dockyard/contract.cairo:117
// Access Control: Only authorized game contracts can modify ship levels
```

## Commands You Will Need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Defence tests | `snforge test defence` | exit 0 |
| Dockyard tests | `snforge test dockyard` | exit 0 |
| Format | `scarb fmt --check` | exit 0 |
| Build | `scarb build` | exit 0 |
| Full tests | `snforge test` | exit 0 |

## Scope

**In scope**:
- `tests/dockyard_write.cairo`
- `tests/defence_write.cairo`
- optionally `tests/dockyard_view.cairo`
- optionally `tests/fleet_view.cairo`

**Out of scope**:
- Contract code changes except tiny testability fixes clearly required by landed plans 003/005
- Battle formula tests
- New helper architecture unless duplication becomes unmanageable

## Steps

### Step 1: Delete or replace no-op tests

Search for `assert(0 == 0, 'todo')` and either replace each with a meaningful test or remove it if it has no clear behavior to assert.

**Verify**: `rg -n "assert\\(0 == 0|'todo'\\)" tests` -> no remaining no-op tests unless intentionally documented.

### Step 2: Restore dockyard requirement tests

For each ship type, add at least one failure test for missing dockyard or tech prerequisites, using patterns from `tests/fleet_write.cairo` and setup helpers from `tests/utils.cairo`.

**Verify**: `snforge test dockyard` -> exit 0.

### Step 3: Restore defence requirement tests

For `Beam`, `Astral`, and other defence types with TODO failure tests, assert missing dockyard/tech prerequisites panic. Keep existing happy path tests.

**Verify**: `snforge test defence` -> exit 0.

### Step 4: Add setter access regression coverage if not already covered

If plan 003 did not add focused setter tests, add them here for `set_ship_levels` and `set_defence_level`.

**Verify**: `snforge test` -> exit 0.

## Test Plan

- Replace no-op tests with real `#[should_panic]` tests.
- Use existing setup helpers; avoid direct storage writes for behavior under test unless the helper already represents fixture setup.

## Done Criteria

- [ ] No meaningless TODO tests remain in edited files.
- [ ] Dockyard prerequisite failures are tested.
- [ ] Defence prerequisite failures are tested.
- [ ] Access-control regressions are covered if not already covered.
- [ ] `scarb fmt --check`, `scarb build`, and `snforge test` exit 0.
- [ ] `plans/README.md` status row updated.

## STOP Conditions

- STOP if a commented-out test references removed public APIs.
- STOP if making a test meaningful requires changing production behavior outside plans 003/005.

## Maintenance Notes

Do not keep placeholder tests in CI. If behavior is not ready, remove the test or mark the missing feature in a plan.
