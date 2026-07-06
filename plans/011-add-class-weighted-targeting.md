# Plan 011: Add class-weighted target dilution

> **Executor instructions**: Follow this plan step by step. Run every verification command and confirm the expected result before moving to the next step. If anything in the "STOP conditions" section occurs, stop and report; do not improvise. When done, update the status row for this plan in `plans/README.md` unless a reviewer dispatched you and told you they maintain the index.
>
> **Drift check (run first)**: `git diff --stat 0c6e6f7..HEAD -- docs/ORIGINAL_BATTLE_LOGIC.md src/fleet_movements/library.cairo src/fleet_movements/battle_settlement.cairo tests/fleet.cairo tests/fleet_write.cairo plans/README.md`
> If any in-scope file changed since this plan was written, compare the "Current state" excerpts against the live code before proceeding. On a mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: L
- **Risk**: HIGH
- **Depends on**: plans/003-restore-battle-math-characterization-tests.md, plans/010-add-round-capped-battle-draws.md
- **Category**: direction
- **Planned at**: commit `0c6e6f7`, 2026-07-06

## Why this matters

Original OGame combat is driven by target dilution: each shot chooses one random enemy unit, so cheap units can absorb targeting probability and protect valuable units. Current NoGame combat uses a fixed priority queue of aggregated class blobs, so fleet composition does not create the same fodder behavior. A literal per-unit random implementation is not suitable onchain, so this plan introduces a bounded class-weighted deterministic approximation.

## Current state

- `docs/ORIGINAL_BATTLE_LOGIC.md` says each shot targets one random enemy unit and highlights fodder as a core design property.
- `src/fleet_movements/library.cairo::build_ships_array` compresses all units of a class into a single `Unit` blob.
- `src/fleet_movements/library.cairo::war` pops one attacker blob and one defender blob in fixed order.

Current excerpts:

```markdown
<!-- docs/ORIGINAL_BATTLE_LOGIC.md:37 -->
Each shot chooses **one random enemy unit**, not a ship class in aggregate.
```

```cairo
// src/fleet_movements/library.cairo:70-73
while !attackers.is_empty() && !defenders.is_empty() {
    let mut u1 = attackers.pop_front().unwrap();
    let mut u2 = defenders.pop_front().unwrap();
    let (u1, u2) = unit_combat(ref u1, ref u2);
```

```cairo
// src/fleet_movements/library.cairo:170-179
fn build_ships_array(mut fleet: Fleet, mut defences: Defences, techs: TechLevels) -> Array<Unit> {
    let mut array: Array<Unit> = array![];

    if defences.plasma > 0 {
        let mut defence = PLASMA();
        add_techs(ref defence, techs);
        defence.hull *= defences.plasma;
        defence.shield *= defences.plasma;
        defence.weapon *= defences.plasma;
        array.append(defence);
```

Repo conventions and constraints:

- Onchain settlement must be deterministic.
- Do not use randomness, block hashes, timestamps, or external oracle data for target selection.
- Do not instantiate individual units; combat cost must be bounded by the number of ship/defence classes and the six-round cap from plan 010.
- Keep formulas in `src/fleet_movements/library.cairo`; settlement remains the source of truth.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Format | `scarb fmt --check` | exit 0 |
| Build | `scarb build` | exit 0 |
| Focused tests | `snforge test fleet` | fleet tests pass |
| Full tests | `snforge test` | all tests pass |

## Scope

**In scope**:

- `src/fleet_movements/library.cairo`
- `src/fleet_movements/battle_settlement.cairo` if settlement signatures need to adapt to the new internal result type
- `tests/fleet.cairo`
- `tests/fleet_write.cairo`
- `plans/README.md`

**Out of scope**:

- Exact stochastic per-unit simulation
- New public APIs
- Rapid-fire redesign beyond preserving current behavior through the new target allocation
- Explosion and shield-reset changes
- Defence rebuild
- Loot policy changes beyond those already introduced by plan 010

## Git workflow

- Branch: `advisor/011-add-class-weighted-targeting`
- Commit style observed in history: imperative/conventional, for example `Deepen fleet mission orchestration`.
- Do not push or open a PR unless the operator instructed it.

## Steps

### Step 1: Add a class-count representation

Introduce an internal representation that keeps each combat class separate with:

- unit id
- count
- per-unit base/current hull and shield values after techs
- per-unit or aggregate weapon value

Avoid a layout that requires appending one `Unit` per ship. The maximum active classes should remain five attacker ship classes and ten defender ship/defence classes.

**Verify**: `scarb build` -> expect compile errors until integrated, or exit 0 if completed in one edit.

### Step 2: Allocate damage by target counts

Replace fixed pop-front targeting with deterministic class-weighted damage allocation. A reasonable onchain approximation is:

- compute total enemy unit count for the side being fired on
- for each target class, allocate incoming shots or incoming weapon power by `target_count / total_enemy_count`
- define and test a deterministic rounding policy for remainders, such as assigning remainder to lower-id or higher-count classes

Document the rounding policy in a short code comment near the helper. Keep the loop bounded by class count, not total unit count.

**Verify**: `scarb build` -> exit 0.

### Step 3: Preserve six-round settlement behavior

Make the weighted targeting fit inside the six-round loop introduced by plan 010. At the end of each round, reconstruct `Fleet` and `Defences` from surviving class counts.

Do not reintroduce a `while !attackers.is_empty() && !defenders.is_empty()` loop that can iterate indefinitely.

**Verify**: `snforge test fleet` -> focused fleet tests pass or show expected fixture updates.

### Step 4: Add fodder-dilution tests

Add tests proving target dilution changes outcomes:

- a valuable defender plus many cheap defenders should preserve more valuable hull than the same valuable defender alone
- adding cheap attacker fodder should change damage distribution compared with only expensive attackers
- two identical inputs produce identical outputs, proving the onchain approximation is deterministic

Use exact expected values from the new deterministic formula.

**Verify**: `snforge test fleet` -> focused tests pass.

### Step 5: Run full gates and update index

**Verify**:

- `scarb fmt --check` -> exit 0
- `scarb build` -> exit 0
- `snforge test` -> all tests pass
- `git status --short` -> only in-scope files are modified

Update `plans/README.md` status for this plan to `DONE` only after verification passes.

## Test plan

- Add deterministic target-dilution tests in `tests/fleet.cairo` or, if helper visibility blocks direct testing, through `simulate_attack`/attack flows.
- Keep characterization tests from plan 003 updated to the intentionally changed formula.
- Full verification is `snforge test`.

## Done criteria

- [ ] Combat damage allocation depends on target class counts, not fixed class priority alone.
- [ ] No per-unit arrays or loops over individual ship counts are introduced.
- [ ] Rounding policy is deterministic and tested.
- [ ] Fodder-dilution tests pass.
- [ ] `scarb fmt --check`, `scarb build`, and `snforge test` pass.
- [ ] No files outside the in-scope list are modified.
- [ ] `plans/README.md` status row updated.

## STOP conditions

Stop and report if:

- Plan 010 has not landed, because this plan assumes a six-round cap.
- The implementation appears to require randomness or block-derived entropy.
- The implementation appears to require loops proportional to ship count rather than class count.
- Existing helper visibility makes meaningful tests impossible without ABI changes.
- Verification fails twice after reasonable fix attempts.

## Maintenance notes

This is an intentional approximation of original OGame behavior for blockchain constraints. Reviewers should focus on bounded execution, deterministic rounding, and whether fodder changes outcomes in the expected direction.
