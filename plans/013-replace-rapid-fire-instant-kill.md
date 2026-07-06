# Plan 013: Replace rapid-fire instant kill

> **Executor instructions**: Follow this plan step by step. Run every verification command and confirm the expected result before moving to the next step. If anything in the "STOP conditions" section occurs, stop and report; do not improvise. When done, update the status row for this plan in `plans/README.md` unless a reviewer dispatched you and told you they maintain the index.
>
> **Drift check (run first)**: `git diff --stat 0c6e6f7..HEAD -- docs/ORIGINAL_BATTLE_LOGIC.md src/fleet_movements/library.cairo src/fleet_movements/battle_settlement.cairo tests/fleet.cairo tests/fleet_write.cairo plans/README.md`
> If any in-scope file changed since this plan was written, compare the "Current state" excerpts against the live code before proceeding. On a mismatch, treat it as a STOP condition.

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: MED
- **Depends on**: plans/003-restore-battle-math-characterization-tests.md, plans/010-add-round-capped-battle-draws.md, plans/011-add-class-weighted-targeting.md
- **Category**: bug
- **Planned at**: commit `0c6e6f7`, 2026-07-06

## Why this matters

Current rapid fire is a hardcoded instant kill: frigates set sparrow hull to zero before normal damage. Original rapid fire is not extra damage; it is a chance to fire again after hitting a specific target type. Onchain settlement should avoid stochastic chains, but it can still replace instant kill with a deterministic expected-extra-shots model bounded by class count and round count.

## Current state

- `docs/ORIGINAL_BATTLE_LOGIC.md` defines rapid fire as chance for another shot: `(r - 1) / r`.
- `src/fleet_movements/library.cairo::unit_combat` calls `rapid_fire` before `apply_damage`.
- `src/fleet_movements/library.cairo::rapid_fire` currently destroys sparrows when hit by frigates.

Current excerpts:

```markdown
<!-- docs/ORIGINAL_BATTLE_LOGIC.md:74-80 -->
If unit A has rapid fire `r` against unit B:

chance_extra_shot = (r - 1) / r
```

```cairo
// src/fleet_movements/library.cairo:120-129
fn unit_combat(ref unit1: Unit, ref unit2: Unit) -> (Unit, Unit) {
    // Unit1 attacks Unit2
    rapid_fire(ref unit1, ref unit2);
    let (new_shield2, new_hull2) = apply_damage(unit1.weapon, unit2.shield, unit2.hull);
```

```cairo
// src/fleet_movements/library.cairo:136-139
fn rapid_fire(ref unit1: Unit, ref unit2: Unit) {
    if unit1.id == 3 && unit2.id == 2 {
        unit2.hull = 0
    }
}
```

Repo conventions and constraints:

- Keep combat deterministic onchain.
- Keep rapid-fire data local to `src/fleet_movements/library.cairo` unless a shared config type becomes necessary.
- Use bounded expected values or capped extra-shot multipliers; do not model unbounded random rapid-fire chains.

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
- `src/fleet_movements/battle_settlement.cairo` only if helper signatures need adapting
- `tests/fleet.cairo`
- `tests/fleet_write.cairo`
- `plans/README.md`

**Out of scope**:

- Exact random rapid-fire chains
- Adding more rapid-fire matchups than the game currently wants to support
- Target dilution implementation; this belongs to plan 011
- Shield/explosion mechanics; this belongs to plan 012
- Public ABI changes

## Git workflow

- Branch: `advisor/013-replace-rapid-fire-instant-kill`
- Commit style observed in history: imperative/conventional, for example `Replace no-op dockyard and defence tests`.
- Do not push or open a PR unless the operator instructed it.

## Steps

### Step 1: Replace mutating instant kill with rapid-fire lookup

Remove the current `rapid_fire(ref unit1, ref unit2)` mutating helper. Replace it with a pure lookup helper such as:

- `rapid_fire_value(attacker_id: u8, defender_id: u8) -> u32`

For the existing special case, return a configured value for frigate against sparrow. If no product value is documented, keep the smallest useful value that avoids instant kill and document it in a code comment as a balance constant requiring review.

**Verify**: `scarb build` -> expect compile errors until callers are updated, or exit 0 if completed in one edit.

### Step 2: Apply deterministic expected extra shots

Integrate rapid-fire value into the class-level combat flow. The model should be bounded and deterministic, for example:

- if `r <= 1`, no extra shots
- if `r > 1`, increase effective shots or weapon allocation by a fixed-point multiplier derived from expected rapid-fire chains
- cap any multiplier or extra-shot count per round so it cannot loop indefinitely

Do not call randomness or use block data.

**Verify**: `scarb build` -> exit 0.

### Step 3: Add rapid-fire tests

Add tests that prove:

- frigate-vs-sparrow no longer destroys sparrows before normal damage resolution
- rapid fire increases expected damage compared with the same matchup with no rapid-fire value
- non-rapid-fire matchups are unaffected
- the result is deterministic for identical inputs

Use exact expected outputs from the new formula.

**Verify**: `snforge test fleet` -> focused tests pass.

### Step 4: Run full gates and update index

**Verify**:

- `scarb fmt --check` -> exit 0
- `scarb build` -> exit 0
- `snforge test` -> all tests pass
- `git status --short` -> only in-scope files are modified

Update `plans/README.md` status for this plan to `DONE` only after verification passes.

## Test plan

- Add rapid-fire-specific tests in `tests/fleet.cairo` if battle helpers are testable there; otherwise use public simulator/attack flows.
- Preserve existing attack tests, updating exact values only where the instant-kill behavior intentionally changes.
- Full verification is `snforge test`.

## Done criteria

- [ ] No helper directly sets target hull to zero for rapid fire.
- [ ] Rapid fire is represented as deterministic bounded extra fire or multiplier.
- [ ] Rapid-fire and non-rapid-fire matchups have exact tests.
- [ ] No randomness or unbounded loops are introduced.
- [ ] `scarb fmt --check`, `scarb build`, and `snforge test` pass.
- [ ] No files outside the in-scope list are modified.
- [ ] `plans/README.md` status row updated.

## STOP conditions

Stop and report if:

- Product has no acceptable rapid-fire value for the existing frigate/sparrow matchup.
- The implementation would require unbounded chains or per-unit loops.
- Plan 011 has not landed and rapid-fire cannot be cleanly applied to class-weighted targeting.
- Meaningful tests require public ABI changes.
- Verification fails twice after reasonable fix attempts.

## Maintenance notes

Future ship and defence types should add rapid-fire values through the lookup helper, not by adding new mutating special cases. Reviewers should reject any reintroduction of instant-kill behavior unless it is a separate named weapon mechanic.
