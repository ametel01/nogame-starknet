# Plan 004: Fix planet and colony resource collection identity

> **Drift check (run first)**: `git diff --stat a370d98..HEAD -- src/planet/contract.cairo src/colony/contract.cairo tests/colony_test.cairo tests/general_write.cairo`

## Status

- **Priority**: P1
- **Effort**: M
- **Risk**: MED
- **Depends on**: plans/001-gate-game-resource-manager.md, plans/003-gate-privileged-state-setters.md
- **Category**: bug
- **Planned at**: commit `a370d98`, 2026-07-06

## Why This Matters

`Planet.collect_resources(player)` is used by spend workflows before charging upgrades. It verifies that the immediate caller is a game contract, but then derives the planet from the caller contract rather than the `player` argument. It also loops with `while i != colonies_len`, which skips the last colony even if identity is fixed.

## Current State

```cairo
// src/planet/contract.cairo:371
fn collect_resources(ref self: ContractState, player: ContractAddress) {
    let caller = get_caller_address();
    ...
    let planet_id = tokens.erc721.token_of(caller).try_into().unwrap();
    let colonies_len = contracts.colony.get_colonies_for_planet(planet_id).len();
    ...
    while i != colonies_len {
        let production = contracts.colony.collect_resources(i.try_into().unwrap());
```

```cairo
// src/colony/contract.cairo:273
fn collect_resources(ref self: ContractState, colony_id: u8) -> ERC20s {
    let planet_id = contracts.planet.get_owned_planet(get_caller_address());
    self.collect_colony_resources(planet_id, colony_id, ...)
}
```

Calling `Colony.collect_resources` from `Planet` cannot work for a player because `get_caller_address()` inside `Colony` is the `Planet` contract.

## Commands You Will Need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Focused tests | `snforge test test_collect_resources_all_planets` | exit 0 |
| Broader colony tests | `snforge test colony` | exit 0 |
| Format | `scarb fmt --check` | exit 0 |
| Build | `scarb build` | exit 0 |
| Full tests | `snforge test` | exit 0 |

## Scope

**In scope**:
- `src/planet/contract.cairo`
- `src/colony/contract.cairo`
- `tests/colony_test.cairo`
- `tests/general_write.cairo`

**Out of scope**:
- Resource production formulas
- ERC20 mint/burn access rules from plan 001
- Colony upgrade/build costs from plan 005

## Steps

### Step 1: Add an authorized colony collection method

Extend `IColony` and `ColonyImpl` with a method such as `collect_resources_for_planet(ref self, planet_id: u32, colony_id: u8) -> ERC20s`. Gate it with `verify_authorized_caller()` so only registered game contracts can call it. Internally reuse `collect_colony_resources(planet_id, colony_id, uni_speed, time_now)`.

Leave the existing user-facing `collect_resources(colony_id)` behavior intact.

**Verify**: `scarb build` -> exit 0.

### Step 2: Fix Planet collection identity and loop bounds

In `Planet.collect_resources(player)`, derive `planet_id` from `player`, not `caller`. Iterate every colony returned by `get_colonies_for_planet(planet_id)`, starting at array index `0`, and call the new authorized colony collection method with the actual colony id from the tuple.

Avoid `while i != colonies_len` for 1-based ids; use array iteration over the returned tuples.

**Verify**: `scarb build` -> exit 0.

### Step 3: Strengthen tests

Update or add tests that create at least three colonies, advance time, collect through `Planet.collect_resources(ACCOUNT1())` as an authorized game contract caller, and assert spendable resources increased by home planet production plus all colony productions.

**Verify**: `snforge test test_collect_resources_all_planets` -> exit 0.

## Test Plan

- Use `tests/colony_test.cairo::test_collect_resources_all_planets` as the main regression.
- Add a direct colony collection test to ensure the user-facing `Colony.collect_resources(colony_id)` still works.
- Run full suite.

## Done Criteria

- [ ] `Planet.collect_resources(player)` uses `player` to identify the home planet.
- [ ] Planet collection includes every colony for that planet.
- [ ] Inter-contract colony collection does not rely on `get_caller_address()` being the player.
- [ ] Focused and full test commands pass.
- [ ] `plans/README.md` status row updated.

## STOP Conditions

- STOP if adding a new colony ABI method conflicts with generated dispatcher imports in multiple files.
- STOP if current tests depend on the broken caller identity.
- STOP if collection starts minting resources to any address other than the `player` argument.

## Maintenance Notes

Any future resource collection path must make the player identity explicit instead of deriving ownership from the immediate contract caller.
