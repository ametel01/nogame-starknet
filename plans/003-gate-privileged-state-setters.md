# Plan 003: Gate privileged state setters

> **Drift check (run first)**: `git diff --stat a370d98..HEAD -- src/planet/contract.cairo src/dockyard/contract.cairo src/defence/contract.cairo tests`

## Status

- **Priority**: P1
- **Effort**: M
- **Risk**: MED
- **Depends on**: plans/001-gate-game-resource-manager.md
- **Category**: security
- **Planned at**: commit `a370d98`, 2026-07-06

## Why This Matters

Several public ABI methods mutate game state but are intended only for contract-to-contract lifecycle updates. Today external users can update planet points, timers, debris fields, and home-planet ship/defence counts. That bypasses gameplay rules and makes fleet/battle accounting untrustworthy.

## Current State

```cairo
// src/planet/contract.cairo:397
fn update_planet_points(ref self: ContractState, planet_id: u32, spent: ERC20s, neg: bool) {
    self.last_active.write(planet_id, get_block_timestamp());
    ...
}
```

```cairo
// src/dockyard/contract.cairo:116
fn set_ship_levels(ref self: ContractState, planet_id: u32, name: u8, level: u32) {
    // TODO: Re-enable once test framework caller propagation issue is resolved
    // self.verify_caller_is_game_contract();
    self.ships_level.write((planet_id, name), level);
}
```

```cairo
// src/defence/contract.cairo:124
fn set_defence_level(ref self: ContractState, planet_id: u32, name: u8, level: u32) {
    // self.verify_caller_is_game_contract();
    self.defence_level.write((planet_id, name), level);
}
```

`Colony` already has the local pattern to follow: `verify_authorized_caller` checks registered contract addresses before mutating internal colony state.

## Commands You Will Need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Focused tests | `snforge test test_privileged_setters` | exit 0 |
| Format | `scarb fmt --check` | exit 0 |
| Build | `scarb build` | exit 0 |
| Full tests | `snforge test` | exit 0 |

## Scope

**In scope**:
- `src/planet/contract.cairo`
- `src/dockyard/contract.cairo`
- `src/defence/contract.cairo`
- focused tests under `tests/`

**Out of scope**:
- User-facing build/upgrade methods such as `process_ship_build` and `process_defence_build`
- Battle formula changes
- Test helper storage writes in `tests/utils.cairo`

## Steps

### Step 1: Add Planet mutator authorization

In `Planet`, gate these methods with a helper based on registered contracts:
- `update_planet_points`
- `add_colony_planet`
- `set_last_active`
- `set_resources_timer`
- `set_planet_debris_field`

Allowed callers should match actual call sites: `colony` for `add_colony_planet`; `compound`, `tech`, `dockyard`, `defence`, and `fleet` for points/activity; `fleet` for debris and raid timer changes. It is acceptable to implement one conservative helper that permits the registered game contracts already used by current call sites.

**Verify**: `scarb build` -> exit 0.

### Step 2: Enable Dockyard and Defence setter gates

In `Dockyard.set_ship_levels` and `Defence.set_defence_level`, restore the existing `verify_caller_is_game_contract()` calls. Adjust allowed callers only if current legitimate call sites fail: fleet lifecycle uses both, and colony/fleet helpers may use dockyard.

**Verify**: `scarb build` -> exit 0.

### Step 3: Add negative and positive tests

Add focused tests where `ACCOUNT1()` cannot call:
- `dsp.planet.set_planet_debris_field`
- `dsp.planet.update_planet_points`
- `dsp.dockyard.set_ship_levels`
- `dsp.defence.set_defence_level`

Also verify authorized callers still work by cheating caller to `dsp.fleet.contract_address` or the appropriate registered contract.

**Verify**: `snforge test test_privileged_setters` -> exit 0.

## Test Plan

- New unauthorized setter tests should panic.
- Existing fleet send/attack/debris tests must still pass because they exercise legitimate setter calls.
- Full `snforge test` is required.

## Done Criteria

- [ ] All listed privileged setters check the immediate caller.
- [ ] Unauthorized regression tests exist.
- [ ] Existing gameplay flows still pass.
- [ ] `scarb fmt --check`, `scarb build`, and `snforge test` exit 0.
- [ ] `plans/README.md` status row updated.

## STOP Conditions

- STOP if Starknet Foundry caller propagation prevents testing real inter-contract calls.
- STOP if a legitimate current call site cannot be represented by the registry.
- STOP if the fix requires changing public ABI names.

## Maintenance Notes

When adding a public method that writes state for lifecycle reasons, include an explicit authorized caller helper and a negative test in the same PR.
