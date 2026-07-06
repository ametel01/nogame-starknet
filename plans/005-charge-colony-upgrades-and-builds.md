# Plan 005: Charge resources for colony upgrades and builds

> **Drift check (run first)**: `git diff --stat a370d98..HEAD -- src/colony/contract.cairo src/colony/assets.cairo src/compound/library.cairo src/dockyard/library.cairo src/defence/library.cairo tests/colony_test.cairo`

## Status

- **Priority**: P1
- **Effort**: M
- **Risk**: MED
- **Depends on**: plans/001-gate-game-resource-manager.md, plans/004-fix-resource-collection-identity.md
- **Category**: security
- **Planned at**: commit `a370d98`, 2026-07-06

## Why This Matters

Home-planet upgrades and unit builds use `spend_upgrade::spend_and_record`, but colony upgrades and builds directly mutate colony state. This lets a player upgrade colony mines/dockyards and build ships/defences without paying resources or recording points, which breaks the economy and progression model.

## Current State

```cairo
// src/colony/contract.cairo:296
fn process_colony_compound_upgrade(... quantity: u8) {
    let contracts = self.game_manager.read().get_contracts();
    let planet_id = contracts.planet.get_owned_planet(get_caller_address());
    self.verify_colony_exist(planet_id, colony_id);
    self.upgrade_component(planet_id, colony_id, name, quantity);
}
```

```cairo
// src/colony/assets.cairo:14
fn upgrade_compounds(current: CompoundsLevels, component: ColonyUpgradeType, quantity: u8) -> CompoundsLevels {
    let mut next = current;
    ...
    next
}
```

By contrast:

```cairo
// src/libraries/spend_upgrade.cairo:31
fn spend_and_record(workflow: PlanetSpendWorkflow, cost: ERC20s) {
    workflow.resource_manager.spend_resources(workflow.caller, cost);
    workflow.planet.update_planet_points(workflow.planet_id, cost, false);
}
```

## Commands You Will Need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Focused tests | `snforge test colony` | exit 0 |
| Format | `scarb fmt --check` | exit 0 |
| Build | `scarb build` | exit 0 |
| Full tests | `snforge test` | exit 0 |

## Scope

**In scope**:
- `src/colony/contract.cairo`
- `src/colony/assets.cairo`
- tests in `tests/colony_test.cairo`

**Out of scope**:
- Changing base cost formulas in `compound`, `dockyard`, or `defence` libraries
- Changing non-colony upgrade/build behavior
- Changing production formulas

## Steps

### Step 1: Calculate colony compound costs

Make colony compound upgrades calculate the same costs as equivalent home-planet compound upgrades. Either return `(next_levels, cost)` from `assets::upgrade_compounds` or compute cost in `Colony.upgrade_component` before writing state. Use existing `compound::cost::*` functions.

**Verify**: `scarb build` -> exit 0.

### Step 2: Calculate colony unit costs

Make colony ship builds use `dockyard::get_ships_unit_cost()` and colony defence builds use `defence::get_defences_unit_cost()`, with `dockyard::get_ships_cost(quantity, unit_cost)` for multiplication. Preserve existing requirement checks in `assets::build_units`.

**Verify**: `scarb build` -> exit 0.

### Step 3: Spend and record after successful mutation

After computing cost, call the shared resource manager spend path for the real player and update planet points. You may reuse `spend_upgrade::begin_planet_workflow` and `spend_upgrade::spend_and_record` if plan 004 has landed and collection identity is fixed.

Ensure the operation reverts if resources are insufficient.

**Verify**: `snforge test colony` -> exit 0.

### Step 4: Update tests to assert payment

In colony upgrade/build tests, record `dsp.planet.get_spendable_resources(planet_id)` before and after the operation. Assert resources decrease by expected cost and colony state increases only on successful payment. Add at least one `#[should_panic]` insufficient-resource test.

**Verify**: `snforge test colony` -> exit 0.

## Test Plan

- Update `test_process_colony_compound_upgrade`.
- Update `process_colony_unit_build_defences_test`.
- Update `process_colony_unit_build_fleet_test`.
- Add insufficient-resource regression for a colony build or upgrade.

## Done Criteria

- [ ] Colony compound upgrades burn resources.
- [ ] Colony ship/defence builds burn resources.
- [ ] Planet points update for colony spending.
- [ ] Insufficient resources revert.
- [ ] `scarb fmt --check`, `scarb build`, and `snforge test` exit 0.
- [ ] `plans/README.md` status row updated.

## STOP Conditions

- STOP if there is a documented design decision that colony builds should be free.
- STOP if cost functions cannot be reused without changing shared libraries.
- STOP if spend workflow collection identity from plan 004 is not fixed.

## Maintenance Notes

When adding future colony asset types, require a cost calculation and a payment assertion in the same test.
