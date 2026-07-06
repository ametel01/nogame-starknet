# Plan 009: Fix large-ship debris costs

> **Executor instructions**: Follow this plan step by step. Run every verification command and confirm the expected result before moving to the next step. If anything in the "STOP conditions" section occurs, stop and report; do not improvise. When done, update the status row for this plan in `plans/README.md` unless a reviewer dispatched you and told you they maintain the index.
>
> **Drift check (run first)**: `git diff --stat 0c6e6f7..HEAD -- src/fleet_movements/library.cairo src/dockyard/library.cairo tests/general_view.cairo tests/colony_test.cairo tests/fleet.cairo tests/fleet_write.cairo plans/README.md`
> If any in-scope file changed since this plan was written, compare the "Current state" excerpts against the live code before proceeding. On a mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: bug
- **Planned at**: commit `0c6e6f7`, 2026-07-06

## Why this matters

Destroyed frigates and armades currently contribute debris using sparrow unit costs. That undercounts debris from the most expensive ships and distorts the post-battle economy. This is a small, local correctness fix with a clear test surface and does not require redesigning the combat loop.

## Current state

- `src/fleet_movements/library.cairo` owns `get_debris`, which converts destroyed ships and celestia losses into steel/quartz debris.
- `src/dockyard/library.cairo` owns ship unit costs.
- `tests/general_view.cairo` and `tests/colony_test.cairo` already assert exact debris values for attack flows.

Current excerpts:

```cairo
// src/fleet_movements/library.cairo:397-408
let steel = ((f_before.carrier - f_after.carrier).into() * costs.carrier.steel)
    + ((f_before.scraper - f_after.scraper).into() * costs.scraper.steel)
    + ((f_before.sparrow - f_after.sparrow).into() * costs.sparrow.steel)
    + ((f_before.frigate - f_after.frigate).into() * costs.sparrow.steel)
    + ((f_before.armade - f_after.armade).into() * costs.sparrow.steel);

let quartz = ((f_before.carrier - f_after.carrier).into() * costs.carrier.quartz)
    + ((f_before.scraper - f_after.scraper).into() * costs.scraper.quartz)
    + ((f_before.sparrow - f_after.sparrow).into() * costs.sparrow.quartz)
    + ((f_before.frigate - f_after.frigate).into() * costs.sparrow.quartz)
    + ((f_before.armade - f_after.armade).into() * costs.sparrow.quartz)
    + (celestia * 2000).into();
```

```cairo
// src/dockyard/library.cairo:16-18
sparrow: ERC20s { steel: 3000, quartz: 1000, tritium: 0 },
frigate: ERC20s { steel: 20000, quartz: 7000, tritium: 2000 },
armade: ERC20s { steel: 45000, quartz: 15000, tritium: 0 },
```

Repo conventions to follow:

- Keep combat and debris helpers in `src/fleet_movements/library.cairo`.
- Tests live under `tests/*.cairo`.
- Assertions use `assert(condition, 'short message')` or `assert!(condition, "...")`.
- Use existing exact-value integration tests as patterns; do not introduce approximate assertions.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Format | `scarb fmt --check` | exit 0 |
| Build | `scarb build` | exit 0 |
| Focused tests | `snforge test debris` | debris-related tests pass |
| Full tests | `snforge test` | all tests pass |

## Scope

**In scope**:

- `src/fleet_movements/library.cairo`
- `tests/general_view.cairo`
- `tests/colony_test.cairo`
- `tests/fleet.cairo` or `tests/fleet_write.cairo` if a more focused debris test is easier there
- `plans/README.md`

**Out of scope**:

- Battle formula redesign
- Defence rebuild behavior
- Changing debris rate from the current `/ 3`
- Changing celestia debris handling
- Public ABI changes

## Git workflow

- Branch: `advisor/009-fix-large-ship-debris-costs`
- Commit style observed in history: imperative/conventional, for example `Fix planet and colony resource collection identity`.
- Do not push or open a PR unless the operator instructed it.

## Steps

### Step 1: Correct frigate and armade cost references

In `src/fleet_movements/library.cairo::get_debris`, replace the `costs.sparrow` references used for frigate and armade losses with their matching unit costs:

- frigate steel/quartz uses `costs.frigate`
- armade steel/quartz uses `costs.armade`

Do not change carrier, scraper, sparrow, or celestia formulas.

**Verify**: `scarb build` -> exit 0.

### Step 2: Add or update exact debris coverage

Add a focused regression that destroys at least one frigate or armade and asserts the debris field uses that ship's own cost. Prefer a compact test near existing fleet/debris tests. If changing existing exact debris fixtures is necessary because they relied on the bug, update the expected values and add a comment naming the ship-cost correction.

Minimum assertion for a direct helper-style test, if the helper is accessible: one destroyed frigate should produce `(20000 / 3)` steel and `(7000 / 3)` quartz. If the helper is not accessible, use a public attack flow that deterministically destroys a frigate or armade and assert the resulting `get_planet_debris_field` values.

**Verify**: `snforge test debris` -> focused debris tests pass.

### Step 3: Run full gates and update index

**Verify**:

- `scarb fmt --check` -> exit 0
- `scarb build` -> exit 0
- `snforge test` -> all tests pass
- `git status --short` -> only in-scope files are modified

Update `plans/README.md` status for this plan to `DONE` only after verification passes.

## Test plan

- Add one regression that fails on the current `costs.sparrow` bug for frigate or armade debris.
- Keep existing debris tests passing with updated expected values where required.
- Full verification is `snforge test`.

## Done criteria

- [ ] `get_debris` uses `costs.frigate` for frigate losses.
- [ ] `get_debris` uses `costs.armade` for armade losses.
- [ ] At least one test fails on the old large-ship debris bug and passes with the fix.
- [ ] `scarb fmt --check`, `scarb build`, and `snforge test` pass.
- [ ] No files outside the in-scope list are modified.
- [ ] `plans/README.md` status row updated.

## STOP conditions

Stop and report if:

- The intended debris rate is no longer `/ 3` in live code or product docs.
- The only way to test this requires changing production visibility or public ABI.
- Existing tests reveal a broader debris policy change is needed beyond ship cost references.
- Verification fails twice after reasonable fix attempts.

## Maintenance notes

This plan intentionally fixes only a local economic accounting bug. Larger questions from `docs/ORIGINAL_BATTLE_LOGIC.md`, such as whether normal defences should create debris, belong to later battle-model plans and should not be folded into this change.
