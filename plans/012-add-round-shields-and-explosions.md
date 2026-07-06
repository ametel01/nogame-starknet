# Plan 012: Add round shields and deterministic explosions

> **Executor instructions**: Follow this plan step by step. Run every verification command and confirm the expected result before moving to the next step. If anything in the "STOP conditions" section occurs, stop and report; do not improvise. When done, update the status row for this plan in `plans/README.md` unless a reviewer dispatched you and told you they maintain the index.
>
> **Drift check (run first)**: `git diff --stat 0c6e6f7..HEAD -- docs/ORIGINAL_BATTLE_LOGIC.md src/fleet_movements/library.cairo src/fleet_movements/battle_settlement.cairo tests/fleet.cairo tests/fleet_write.cairo plans/README.md`
> If any in-scope file changed since this plan was written, compare the "Current state" excerpts against the live code before proceeding. On a mismatch, treat it as a STOP condition.

## Status

- **Priority**: P2
- **Effort**: L
- **Risk**: HIGH
- **Depends on**: plans/003-restore-battle-math-characterization-tests.md, plans/010-add-round-capped-battle-draws.md, plans/011-add-class-weighted-targeting.md
- **Category**: direction
- **Planned at**: commit `0c6e6f7`, 2026-07-06

## Why this matters

The original battle model restores shields between rounds, keeps hull damage, and can destroy units probabilistically once hull drops below 70%. Current NoGame damage reduces aggregate shield/hull continuously until zero hull. To stay blockchain-friendly, this plan should model those original properties with deterministic class-level expected losses rather than per-shot random explosion rolls.

## Current state

- `docs/ORIGINAL_BATTLE_LOGIC.md` defines per-round shield reset and an explosion chance below 70% hull.
- `src/fleet_movements/library.cairo::apply_damage` only destroys when hull reaches zero.
- `src/fleet_movements/library.cairo::unit_combat` mutates current shield and hull and appends surviving blobs back into the queue.

Current excerpts:

```markdown
<!-- docs/ORIGINAL_BATTLE_LOGIC.md:16-17 -->
remove destroyed units
restore shields on surviving units
```

```markdown
<!-- docs/ORIGINAL_BATTLE_LOGIC.md:62-65 -->
Once current hull drops below 70% of initial hull, every damaging shot can trigger an explosion roll:

explosion_probability = 1 - current_hull / initial_hull
```

```cairo
// src/fleet_movements/library.cairo:111-117
let overflow_damage = attacker_weapon - defender_shield;
if defender_hull <= overflow_damage {
    return (0, 0); // Unit destroyed
}

(0, defender_hull - overflow_damage)
```

Repo conventions and constraints:

- Keep onchain settlement deterministic; do not use random explosion rolls.
- Keep execution bounded by six rounds and class count.
- Prefer fixed-point integer math or scaled integer percentages already common in the repo; avoid floating point in new combat logic.

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
- `src/fleet_movements/battle_settlement.cairo` if result reconstruction needs updated loss fields
- `tests/fleet.cairo`
- `tests/fleet_write.cairo`
- `plans/README.md`

**Out of scope**:

- Randomness or stochastic per-unit rolls
- Rapid-fire redesign
- Defence rebuild
- Public ABI changes
- Changing unit base stats

## Git workflow

- Branch: `advisor/012-add-round-shields-and-explosions`
- Commit style observed in history: imperative/conventional, for example `Use checked ERC20s resource arithmetic`.
- Do not push or open a PR unless the operator instructed it.

## Steps

### Step 1: Track base shield and hull separately from current state

Update the internal class representation from plan 011 so each class can restore shield at the end of a round while retaining hull damage. This likely requires storing:

- per-unit max shield after techs
- per-unit max hull after techs
- current aggregate shield for the round
- current aggregate hull or damaged-count state

Do not change base unit stats in this step.

**Verify**: `scarb build` -> expect compile errors until integration is complete, or exit 0 if completed in one edit.

### Step 2: Restore shields between rounds

At the end of each of the six battle rounds, remove destroyed units, then restore surviving class shield values to their max shield. Hull damage should persist across rounds.

Add a small helper with a name like `restore_round_shields` to make this behavior reviewable.

**Verify**: `scarb build` -> exit 0.

### Step 3: Add deterministic expected explosion losses

Implement a deterministic approximation of the original explosion mechanic:

- explosion eligibility starts when current hull is below 70% of initial hull
- use scaled integer math for `1 - current_hull / initial_hull`
- convert expected explosions into whole unit losses with a documented rounding rule

The rounding rule must be deterministic and conservative enough to avoid negative counts or underflows. Do not call external randomness and do not read block timestamp/hash for this mechanic.

**Verify**: `snforge test fleet` -> focused tests pass or expected fixtures are ready for update.

### Step 4: Add shield-reset and explosion tests

Add tests that pin:

- shields reset each round, so low overflow damage does not permanently drain shield across all six rounds
- hull damage persists across rounds
- units below the 70% hull threshold can be removed by the deterministic explosion rule
- units above or equal to the threshold do not explode

Use exact expected outputs from the new deterministic formula.

**Verify**: `snforge test fleet` -> focused tests pass.

### Step 5: Run full gates and update index

**Verify**:

- `scarb fmt --check` -> exit 0
- `scarb build` -> exit 0
- `snforge test` -> all tests pass
- `git status --short` -> only in-scope files are modified

Update `plans/README.md` status for this plan to `DONE` only after verification passes.

## Test plan

- Add tests for shield restoration, persistent hull damage, explosion threshold, and deterministic explosion rounding.
- Update previous battle characterization fixtures only when changed by this plan's intended mechanics.
- Full verification is `snforge test`.

## Done criteria

- [ ] Surviving units regain shields between battle rounds.
- [ ] Hull damage persists across rounds.
- [ ] A deterministic explosion approximation exists below 70% hull.
- [ ] Explosion behavior has exact-value tests.
- [ ] No randomness, block entropy, or per-unit loops are introduced.
- [ ] `scarb fmt --check`, `scarb build`, and `snforge test` pass.
- [ ] No files outside the in-scope list are modified.
- [ ] `plans/README.md` status row updated.

## STOP conditions

Stop and report if:

- Plan 011 has not landed and the live combat representation is still fixed priority blobs.
- The deterministic explosion rule cannot be expressed without large precision loss or underflow risk.
- A reviewer/product owner requires exact stochastic explosion rolls onchain.
- Meaningful tests require changing public ABI.
- Verification fails twice after reasonable fix attempts.

## Maintenance notes

This plan encodes an onchain approximation, not exact OGame randomness. Reviewers should scrutinize rounding, underflow safety, and whether shield restoration happens after unit removal at the round boundary.
