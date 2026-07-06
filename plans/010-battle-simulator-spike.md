# Plan 010: Design an offchain battle simulator contract/API seam

> **Drift check (run first)**: `git diff --stat a370d98..HEAD -- README.md src/fleet_movements src/libraries/types.cairo tests/fleet.cairo tests/fleet_write.cairo`

## Status

- **Priority**: P3
- **Effort**: M
- **Risk**: LOW
- **Depends on**: none
- **Category**: direction
- **Planned at**: commit `a370d98`, 2026-07-06

## Why This Matters

The README roadmap names an offchain battle simulator, and the contract already exposes `simulate_attack`. The current simulator path uses default tech levels and only accepts fleet/defence inputs, so it is useful for a narrow preview but not a full player-facing simulator. A spike should define the API and shared math boundary before implementation.

## Current State

```markdown
// README.md:18
* [ ] **Add New Features (Q1-Q2)**
  * Implement an offchain battle simulator.
```

```cairo
// src/fleet_movements/contract.cairo:416
fn simulate_attack(
    self: @ContractState, attacker_fleet: Fleet, defender_fleet: Fleet, defences: Defences,
) -> SimulationResult {
    let techs: TechLevels = Default::default();
```

The battle engine itself lives in `src/fleet_movements/battle_settlement.cairo` and related fleet libraries.

## Commands You Will Need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Read current API | `rg -n "simulate_attack|settle\\(|SimulationResult|TechLevels" src tests` | shows current call graph |
| Docs check | `rg -n "battle simulator|simulate_attack" README.md docs plans` | new design is discoverable |
| Code guard | `scarb build` | exit 0 if code touched |

## Scope

**In scope**:
- A design/spike doc such as `docs/battle-simulator-spike.md` or `plans/battle-simulator-spike-output.md`
- Optional small test or prototype only if instructed by the operator

**Out of scope**:
- Full simulator implementation
- Frontend work
- Changing battle formulas

## Steps

### Step 1: Map simulator inputs and outputs

Read `battle_settlement`, `fleet_movements/library.cairo`, and `libraries/types.cairo`. List the minimum inputs needed for parity with real attacks: attacker fleet, defender fleet, defences, both tech levels, celestia count, and fleet decay timing if relevant.

**Verify**: `rg -n "struct SimulationResult|struct TechLevels|fn settle" src/libraries/types.cairo src/fleet_movements` -> expected symbols found.

### Step 2: Write the design spike

Create a concise design doc with:
- target users and use cases,
- proposed onchain view API changes, if any,
- offchain API shape,
- how to share or mirror battle math,
- open questions,
- implementation slices.

**Verify**: `rg -n "Open questions|API shape|battle math" docs plans` -> the spike contains these sections.

### Step 3: Recommend a first implementation slice

Define the first buildable slice, likely extending `simulate_attack` to accept `TechLevels` for both sides and adding tests that compare it to real `attack_planet` settlement facts.

**Verify**: design doc names one first slice and its verification command.

## Test Plan

This is a design/spike plan. If code is not changed, no Cairo tests are required. If a prototype is added, run `scarb build` and focused `snforge test` for the touched tests.

## Done Criteria

- [ ] A spike doc exists and is self-contained.
- [ ] It cites current code paths and README roadmap intent.
- [ ] It recommends one small implementation slice with test strategy.
- [ ] `plans/README.md` status row updated.

## STOP Conditions

- STOP if the operator wants immediate implementation rather than a spike.
- STOP if battle formulas are being actively rewritten in another branch.

## Maintenance Notes

Keep simulator math tied to contract-tested settlement behavior. Do not create an offchain formula fork without parity tests.
