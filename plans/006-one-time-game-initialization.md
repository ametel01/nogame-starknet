# Plan 006: Make Game initialization one-time and timestamped

> **Drift check (run first)**: `git diff --stat a370d98..HEAD -- src/game/contract.cairo src/planet/contract.cairo tests`

## Status

- **Priority**: P1
- **Effort**: S/M
- **Risk**: MED
- **Depends on**: plans/001-gate-game-resource-manager.md, plans/002-require-owner-for-game-upgrade.md
- **Category**: security
- **Planned at**: commit `a370d98`, 2026-07-06

## Why This Matters

`Game.initialize` is documented as one-time setup, but the implementation can be called repeatedly by the owner. It also never writes `universe_start_time`, even though planet pricing reads it. That makes the registry mutable after deployment and makes VRGDA pricing depend on a default zero timestamp.

## Current State

```cairo
// src/game/contract.cairo:85
universe_start_time: u64,
```

```cairo
// src/game/contract.cairo:275
fn initialize(...) {
    self.ownable.assert_only_owner();
    self.planet_manager.write(...);
    ...
    self.token_price.write(token_price * E18);
    self.uni_speed.write(uni_speed);
}
```

```cairo
// src/planet/contract.cairo:455
let time_elapsed = (get_block_timestamp() - universe_config.get_universe_start_time()) / DAY;
```

## Commands You Will Need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Focused tests | `snforge test test_game_initialize` | exit 0 |
| Format | `scarb fmt --check` | exit 0 |
| Build | `scarb build` | exit 0 |
| Full tests | `snforge test` | exit 0 |

## Scope

**In scope**:
- `src/game/contract.cairo`
- tests under `tests/`

**Out of scope**:
- Deployment order changes
- Pricing formula changes
- New admin reconfiguration feature

## Steps

### Step 1: Add initialized storage

Add a `initialized: bool` field to `Game.Storage`. In `initialize`, assert it is false before writing registry values, then set it true after successful writes.

Because this is an upgradeable contract, review storage layout risk. If deployed instances exist, STOP and ask whether storage layout compatibility is required.

**Verify**: `scarb build` -> exit 0.

### Step 2: Store universe start time

Import `get_block_timestamp` and write `self.universe_start_time.write(get_block_timestamp())` during initialization. Keep `get_universe_start_time` unchanged.

**Verify**: `scarb build` -> exit 0.

### Step 3: Add initialization tests

Add tests that:
- initialize once and assert `get_universe_start_time()` equals the cheated block timestamp,
- assert a second initialize call panics,
- assert non-owner initialize still panics.

**Verify**: `snforge test test_game_initialize` -> exit 0.

## Test Plan

- Focused initialize tests.
- Existing planet price tests must still pass or be updated for the non-zero start time.
- Full suite required.

## Done Criteria

- [ ] `Game.initialize` cannot be called twice.
- [ ] `universe_start_time` is written during initialization.
- [ ] Owner and non-owner behavior is tested.
- [ ] `scarb fmt --check`, `scarb build`, and `snforge test` exit 0.
- [ ] `plans/README.md` status row updated.

## STOP Conditions

- STOP if deployed storage layout compatibility is required and adding a field is unsafe.
- STOP if tests reveal existing helpers intentionally call `initialize` multiple times on one deployed `Game`.

## Maintenance Notes

If the project later needs registry rotation, add an explicit owner-only reconfiguration method with events and tests instead of reusing initialization.
