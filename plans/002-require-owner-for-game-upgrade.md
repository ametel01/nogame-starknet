# Plan 002: Require owner for Game upgrades

> **Drift check (run first)**: `git diff --stat a370d98..HEAD -- src/game/contract.cairo tests/upgrade_test.cairo tests`

## Status

- **Priority**: P1
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: security
- **Planned at**: commit `a370d98`, 2026-07-06

## Why This Matters

Upgradeable contract entrypoints must be owner-only. `Compound`, `Tech`, and ERC20 upgrade paths already call `assert_only_owner`, but `Game.upgrade` does not. `Game` is the central registry and resource manager, so an unrestricted implementation replacement is a critical control-plane risk.

## Current State

```cairo
// src/game/contract.cairo:309
fn upgrade(ref self: ContractState, impl_hash: ClassHash) {
    self.upgradeable.upgrade(impl_hash);
}
```

```cairo
// src/compound/contract.cairo:74
fn upgrade(ref self: ContractState, impl_hash: ClassHash) {
    self.ownable.assert_only_owner();
    self.upgradeable.upgrade(impl_hash);
}
```

The existing `tests/upgrade_test.cairo` only checks owner success and has no unauthorized negative test.

## Commands You Will Need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Focused tests | `snforge test test_game_upgrade` | exit 0 |
| Format | `scarb fmt --check` | exit 0 |
| Build | `scarb build` | exit 0 |
| Full tests | `snforge test` | exit 0 |

## Scope

**In scope**:
- `src/game/contract.cairo`
- `tests/upgrade_test.cairo` or `tests/game_upgrade_access.cairo`

**Out of scope**:
- Other upgradeable contracts
- Deployment scripts
- Class hash selection logic

## Steps

### Step 1: Add owner assertion

In `GameAdminImpl.upgrade`, call `self.ownable.assert_only_owner();` before `self.upgradeable.upgrade(impl_hash);`, matching `Compound` and `Tech`.

**Verify**: `scarb build` -> exit 0.

### Step 2: Add unauthorized regression test

Add a `#[should_panic]` test where `ACCOUNT1()` calls `dsp.game.upgrade(...)`. Keep the existing owner success test.

**Verify**: `snforge test test_game_upgrade` -> exit 0.

## Test Plan

- Existing `test_owner_can_call_upgrade_entrypoints` continues to pass.
- New unauthorized Game upgrade test panics.
- Full suite passes.

## Done Criteria

- [ ] `Game.upgrade` calls `assert_only_owner`.
- [ ] Unauthorized upgrade test exists and passes.
- [ ] `scarb fmt --check`, `scarb build`, and `snforge test` exit 0.
- [ ] `plans/README.md` status row updated.

## STOP Conditions

- STOP if the `Game` upgrade method moved or no longer uses `UpgradeableComponent`.
- STOP if the fix requires changing OpenZeppelin component storage layout.

## Maintenance Notes

When adding future upgradeable contracts, use this same positive and negative test pattern.
