# Plan 001: Bound fleet speed modifiers

> **Executor instructions**: Follow this plan step by step. Run every verification command and confirm the expected result before moving to the next step. If anything in the "STOP conditions" section occurs, stop and report; do not improvise. When done, update the status row for this plan in `plans/README.md` unless a reviewer told you they maintain the index.
>
> **Drift check (run first)**: `git diff --stat 0c6e6f7..HEAD -- src/fleet_movements/contract.cairo src/fleet_movements/orchestration.cairo src/fleet_movements/library.cairo tests/fleet_write.cairo plans/README.md`
> If any in-scope file changed since this plan was written, compare the "Current state" excerpts against the live code before proceeding. On a mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: bug
- **Planned at**: commit `0c6e6f7`, 2026-07-06

## Why this matters

`send_fleet` accepts a caller-supplied `speed_modifier` described as a percentage where `100` is normal and `50` is half speed. The value is not bounded before it is used in flight-time and fuel-cost arithmetic. Values above `100` make travel faster and fuel cheaper than the documented model; `0` reaches division-by-zero behavior. This is a direct game-economy boundary and should be enforced before mission records are written.

## Current state

- `src/fleet_movements/contract.cairo` defines the public ABI and documents `speed_modifier`.
- `src/fleet_movements/orchestration.cairo` builds the mission plan and computes travel time and fuel.
- `src/fleet_movements/library.cairo` computes flight time from the percentage.
- `tests/fleet_write.cairo` has one positive `50` percent speed test but no invalid-bound tests.

Current excerpts:

```cairo
// src/fleet_movements/contract.cairo:13
/// - `speed_modifier`: Speed multiplier as percentage (100 = normal, 50 = half speed)
```

```cairo
// src/fleet_movements/orchestration.cairo:80
let travel_time = fleet::get_flight_time(speed, distance, speed_modifier);

// src/fleet_movements/orchestration.cairo:86
fuel_cost.tritium = fleet::get_fuel_consumption(f, distance) * 100 / speed_modifier.into();
```

```cairo
// src/fleet_movements/library.cairo:353-355
let speed_percentage = FixedTrait::new_unscaled(speed_percentage.into(), false)
    / FixedTrait::new_unscaled(100, false);
let res = res / speed_percentage;
```

Repo conventions to follow:

- Contract boundary checks use `assert!(condition, "Module:E_REASON")`, for example `assert!(active_missions < max_missions, "Fleet:E_ACTIVE_MISSIONS_LIMIT");` in `src/fleet_movements/orchestration.cairo`.
- Tests use `#[should_panic]` without overfitting panic text for many guard cases in `tests/fleet_write.cairo`.
- Keep public ABI unchanged.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Format | `scarb fmt --check` | exit 0 |
| Build | `scarb build` | exit 0 |
| Focused tests | `snforge test test_send_speed_modifier` | matching test passes |
| Full tests | `snforge test` | all tests pass |

## Scope

**In scope**:

- `src/fleet_movements/orchestration.cairo`
- `tests/fleet_write.cairo`
- `plans/README.md`

**Out of scope**:

- `src/fleet_movements/contract.cairo` ABI changes
- `src/fleet_movements/library.cairo` formula rewrites
- Changes to mission categories, fleet speed formulas, or fuel formulas beyond validating the modifier

## Git workflow

- Branch: `advisor/001-bound-fleet-speed-modifiers`
- Commit style observed in history: imperative/conventional, for example `Fix per-planet colony limits` or `chore: docs cleanup`.
- Do not push or open a PR unless the operator instructed it.

## Steps

### Step 1: Add a speed modifier guard

In `src/fleet_movements/orchestration.cairo`, add an assertion in `plan_send_mission` before `get_flight_time` and fuel calculation. The expected accepted range is `1..=100`: `100` normal, lower values slower/more expensive, `0` invalid, above `100` invalid.

Use the local error style:

```cairo
assert!(speed_modifier > 0 && speed_modifier <= 100, "Fleet:E_SPEED_MODIFIER");
```

Place it near the other mission preconditions, before line 80 in the current code.

**Verify**: `scarb build` -> exit 0.

### Step 2: Add invalid-bound tests

In `tests/fleet_write.cairo`, add two tests near `test_send_speed_modifier`:

- `test_send_speed_modifier_fails_zero`
- `test_send_speed_modifier_fails_above_100`

Use the same setup pattern as `test_send_speed_modifier`: create two started planets, build a fleet, and call `send_fleet`. Mark both tests `#[should_panic]`. Use `0` and `101` as the invalid inputs.

**Verify**: `snforge test test_send_speed_modifier` -> the existing positive test and the two new bound tests pass.

### Step 3: Run full gates and update index

Run the repo gates and update this plan's row in `plans/README.md` from `TODO` to `DONE` only after all gates pass.

**Verify**:

- `scarb fmt --check` -> exit 0
- `scarb build` -> exit 0
- `snforge test` -> all tests pass
- `git status --short` -> only in-scope files are modified

## Test plan

- Add two negative tests in `tests/fleet_write.cairo` for `speed_modifier == 0` and `speed_modifier > 100`.
- Keep the existing `test_send_speed_modifier` positive case for `50`.
- Full verification is `snforge test`.

## Done criteria

- [ ] `send_fleet` rejects `speed_modifier == 0`.
- [ ] `send_fleet` rejects `speed_modifier > 100`.
- [ ] Existing `50` percent speed behavior still passes.
- [ ] `scarb fmt --check`, `scarb build`, and `snforge test` pass.
- [ ] No files outside the in-scope list are modified.
- [ ] `plans/README.md` status row updated.

## STOP conditions

Stop and report if:

- The live `plan_send_mission` no longer computes travel time and fuel from `speed_modifier`.
- Product requirements say speeds above `100` are intentional.
- Adding the guard requires changing public ABI or mission storage.
- Verification fails twice after reasonable fix attempts.

## Maintenance notes

Future work that adds speed boosts should introduce a separate, explicit mechanic instead of overloading this user-supplied percentage. Reviewers should check that the guard runs before both `get_flight_time` and fuel calculation.
