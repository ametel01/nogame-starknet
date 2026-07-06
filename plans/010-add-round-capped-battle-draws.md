# Plan 010: Add round-capped battle draws

> **Executor instructions**: Follow this plan step by step. Run every verification command and confirm the expected result before moving to the next step. If anything in the "STOP conditions" section occurs, stop and report; do not improvise. When done, update the status row for this plan in `plans/README.md` unless a reviewer dispatched you and told you they maintain the index.
>
> **Drift check (run first)**: `git diff --stat 0c6e6f7..HEAD -- docs/ORIGINAL_BATTLE_LOGIC.md src/fleet_movements/library.cairo src/fleet_movements/battle_settlement.cairo src/fleet_movements/orchestration.cairo src/fleet_movements/lifecycle.cairo src/fleet_movements/contract.cairo tests/fleet.cairo tests/fleet_write.cairo plans/README.md`
> If any in-scope file changed since this plan was written, compare the "Current state" excerpts against the live code before proceeding. On a mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: M
- **Risk**: HIGH
- **Depends on**: plans/003-restore-battle-math-characterization-tests.md
- **Category**: bug
- **Planned at**: commit `0c6e6f7`, 2026-07-06

## Why this matters

The original OGame-style combat model is capped at six rounds. If the attacker has not cleared all defenders by then, the battle is a draw and no resources are looted. Current NoGame settlement loops until one side is empty, so outcomes and gas cost depend on convergence instead of a fixed battle budget. Onchain combat should be strictly bounded; a six-round cap gives the contract a predictable upper limit while matching the source design document.

## Current state

- `docs/ORIGINAL_BATTLE_LOGIC.md` states the target behavior: up to six rounds, stop if one side is gone, draw if defenders remain after round six.
- `src/fleet_movements/library.cairo::war` currently loops until one side is empty and returns only surviving fleets/defences.
- `src/fleet_movements/battle_settlement.cairo::settle` returns `BattleSettlement` without an outcome/status.
- `src/fleet_movements/orchestration.cairo::plan_attack` calculates loot based only on surviving attacker cargo, not on battle victory.

Current excerpts:

```markdown
<!-- docs/ORIGINAL_BATTLE_LOGIC.md:7 -->
A battle runs for **up to 6 rounds**. If the attacker has not destroyed all defending ships/defense by then, the result is a draw and no resources are looted.
```

```cairo
// src/fleet_movements/library.cairo:68-83
let mut attackers = build_ships_array(attackers, Zeroable::zero(), a_techs);
let mut defenders = build_ships_array(defenders, defences, d_techs);
while !attackers.is_empty() && !defenders.is_empty() {
    let mut u1 = attackers.pop_front().unwrap();
    let mut u2 = defenders.pop_front().unwrap();
    let (u1, u2) = unit_combat(ref u1, ref u2);
    if u1.hull > 0 {
        attackers.append(u1);
    }
    if u2.hull > 0 {
        defenders.append(u2);
    }
}
```

```cairo
// src/fleet_movements/orchestration.cairo:137-139
let (loot_spendable, loot_collectible) = calculate_loot_amount(
    contracts, mission.destination, settlement.attacker_fleet,
);
```

Repo conventions to follow:

- Shared combat structs live beside settlement in `src/fleet_movements/battle_settlement.cairo` or shared ABI types only when externally exposed.
- Keep state application in `src/fleet_movements/lifecycle.cairo`; planning/decision logic belongs in `orchestration.cairo` and settlement.
- Use small `mod` constants near the module that consumes them unless a value is ABI-level shared data.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Format | `scarb fmt --check` | exit 0 |
| Build | `scarb build` | exit 0 |
| Focused tests | `snforge test attack` | attack-related tests pass |
| Full tests | `snforge test` | all tests pass |

## Scope

**In scope**:

- `src/fleet_movements/library.cairo`
- `src/fleet_movements/battle_settlement.cairo`
- `src/fleet_movements/orchestration.cairo`
- `src/fleet_movements/lifecycle.cairo` only if battle report facts need outcome-aware loot/debris data
- `tests/fleet.cairo`
- `tests/fleet_write.cairo`
- `plans/README.md`

**Out of scope**:

- Per-unit random target selection
- Shield reset and explosion mechanics
- Rapid-fire redesign
- Defence rebuild
- Public ABI changes unless unavoidable for internal compilation
- Offchain simulator implementation

## Git workflow

- Branch: `advisor/010-add-round-capped-battle-draws`
- Commit style observed in history: imperative/conventional, for example `Deepen fleet mission lifecycle`.
- Do not push or open a PR unless the operator instructed it.

## Steps

### Step 1: Add explicit internal battle outcome

Add an internal outcome representation to settlement, for example a small enum or struct field on `BattleSettlement` that can distinguish at least:

- attacker victory: defender fleet and defences are empty
- defender victory: attacker fleet is empty
- draw: both sides still have units after six rounds

Keep the outcome internal for this plan. Do not add it to `SimulationResult` or emitted events unless compilation forces it.

**Verify**: `scarb build` -> expect compile errors until the round cap is wired, or exit 0 if completed in one edit.

### Step 2: Cap combat at six rounds

Change `fleet::war` or add a new settlement-level wrapper so combat runs at most six rounds. Preserve the existing unit-combat behavior inside a round for this plan; the goal here is the cap and draw semantics, not the full OGame model.

Use a named constant such as `MAX_BATTLE_ROUNDS: u8 = 6`. The onchain constraint is important: do not introduce any loop whose iteration count scales with total ship count. The implementation must remain bounded by a small fixed number times the current class-blob count.

**Verify**: `scarb build` -> exit 0.

### Step 3: Prevent loot on draw or defender victory

Update `orchestration::plan_attack` so `calculate_loot_amount` is called only when settlement outcome is attacker victory. For draw and defender victory, return zero loot even if some attacker ships survive.

Keep fleet return behavior unchanged: surviving attacker fleet still returns to origin.

**Verify**: `snforge test attack` -> focused attack tests pass or show expected failures to update in Step 4.

### Step 4: Add draw and victory tests

Add tests that pin:

- attacker victory still grants loot when all defenders are cleared
- draw after six rounds grants zero loot
- defender victory grants zero loot and returns no destroyed attacker ships

Use existing `tests/fleet_write.cairo::test_attack_planet_loot_amount` as the shape for resource-loot assertions.

**Verify**: `snforge test attack` -> focused tests pass.

### Step 5: Run full gates and update index

**Verify**:

- `scarb fmt --check` -> exit 0
- `scarb build` -> exit 0
- `snforge test` -> all tests pass
- `git status --short` -> only in-scope files are modified

Update `plans/README.md` status for this plan to `DONE` only after verification passes.

## Test plan

- Add one draw fixture that would previously continue until a side was empty or grant loot despite defenders remaining.
- Add one attacker-victory fixture to prove normal successful raids still grant loot.
- Add one defender-victory fixture for zero-loot behavior.
- Full verification is `snforge test`.

## Done criteria

- [ ] Battle execution has a named six-round cap.
- [ ] Settlement records whether the attacker won, defender won, or the battle drew.
- [ ] Draws and defender victories grant zero loot.
- [ ] Existing successful attack flows still work.
- [ ] `scarb fmt --check`, `scarb build`, and `snforge test` pass.
- [ ] No files outside the in-scope list are modified.
- [ ] `plans/README.md` status row updated.

## STOP conditions

Stop and report if:

- Plan 003 has not landed and there is no meaningful battle characterization coverage to protect this change.
- Product asks for exact stochastic OGame combat onchain instead of a bounded deterministic model.
- Adding outcome status requires changing public ABI or event schemas.
- The only viable implementation introduces loops over individual ship counts.
- Verification fails twice after reasonable fix attempts.

## Maintenance notes

This plan is the foundation for the later OGame-alignment plans. It deliberately keeps current target ordering, damage, and rapid-fire behavior so reviewers can isolate the impact of round caps and draw loot.
