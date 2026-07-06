# Plan 015: Use checked resource arithmetic

> **Executor instructions**: Follow this plan step by step. Run every verification command and confirm the expected result before moving to the next step. If anything in the "STOP conditions" section occurs, stop and report -- do not improvise. When done, update the status row for this plan in `plans/README.md` unless a reviewer dispatched you and told you they maintain the index.
>
> **Drift check (run first)**: `git diff --stat a370d98..HEAD -- src/libraries/types.cairo src/fleet_movements/orchestration.cairo src/fleet_movements/lifecycle.cairo src/planet/contract.cairo tests`
> If any in-scope file changed since this plan was written, compare the "Current state" excerpts against the live code before proceeding; on a mismatch, treat it as a STOP condition.

## Status

- **Priority**: P2
- **Effort**: S/M
- **Risk**: MED
- **Depends on**: plans/001-gate-game-resource-manager.md, plans/005-charge-colony-upgrades-and-builds.md
- **Category**: bug
- **Planned at**: commit `a370d98`, 2026-07-06

## Why this matters

`ERC20s` is the shared resource value type for steel, quartz, and tritium. Its `Add` and `Sub` implementations currently use overflowing arithmetic and discard the overflow flag, so resource totals can silently wrap instead of failing. The code often checks balances before spending, but the shared type should make invalid arithmetic loud; otherwise future economy changes can turn a missed check into resource creation or incorrect test expectations.

## Current state

- `src/libraries/types.cairo` -- shared resource, fleet, building, and mission types.
- `src/fleet_movements/orchestration.cairo` -- loot, debris, and battle resource calculations.
- `src/fleet_movements/lifecycle.cairo` -- applies loot/resource effects.
- `src/planet/contract.cairo` -- resource collection and points accounting.
- `tests/*.cairo` -- current resource and fleet tests.

Current `ERC20s` addition and subtraction intentionally ignore overflow flags:

```cairo
// src/libraries/types.cairo:115-129
impl ERC20sAdd of Add<ERC20s> {
    fn add(lhs: ERC20s, rhs: ERC20s) -> ERC20s {
        let (steel, _) = lhs.steel.overflowing_add(rhs.steel);
        let (quartz, _) = lhs.quartz.overflowing_add(rhs.quartz);
        let (tritium, _) = lhs.tritium.overflowing_add(rhs.tritium);
        ERC20s { steel: steel, quartz: quartz, tritium: tritium }
    }
}
impl ERC20sSub of Sub<ERC20s> {
    fn sub(lhs: ERC20s, rhs: ERC20s) -> ERC20s {
        let (steel, _) = lhs.steel.overflowing_sub(rhs.steel);
        let (quartz, _) = lhs.quartz.overflowing_sub(rhs.quartz);
        let (tritium, _) = lhs.tritium.overflowing_sub(rhs.tritium);
        ERC20s { steel: steel, quartz: quartz, tritium: tritium }
    }
}
```

Resource arithmetic is used in gameplay flows, for example loot calculation:

```cairo
// src/fleet_movements/orchestration.cairo:146
total_loot: loot_spendable + loot_collectible,
```

and attack assertions in tests subtract resource snapshots:

```cairo
// tests/colony_test.cairo:387-390
assert!(
    (attacker_resources_after - attacker_resources) == expected_attacker_resources,
    "wrong attacker resources: expected {:?}, got {:?}",
    attacker_resources_after - attacker_resources,
```

Repo conventions to match:

- Cairo shared value operators are implemented in `src/libraries/types.cairo`.
- Error strings use component prefixes such as `Game:E_RESOURCES_STEEL` and `Fleet:E_ARRIVAL_PENDING`.
- Existing tests use focused `#[test]` and `#[should_panic]` cases rather than property tests.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Format | `scarb fmt --check` | exit 0 |
| Targeted tests | `snforge test erc20s` | exit 0 if tests are named with `erc20s`; otherwise use the exact new test names |
| Full tests | `snforge test` | exit 0, all tests pass |
| Build | `scarb build` | exit 0 |

## Scope

**In scope**:

- `src/libraries/types.cairo`
- A focused test file, preferably `tests/math.cairo` or a new `tests/resource_arithmetic.cairo`
- Existing tests only if import/module wiring requires updates

**Out of scope**:

- Rebalancing resource costs
- Changing loot formulas
- Changing ERC20 token decimals or `E18`
- Changing all arithmetic in the repo; this plan is only for `ERC20s` shared add/sub behavior

## Git workflow

- Branch: `advisor/015-use-checked-resource-arithmetic`
- Commit message style: imperative sentence matching repo history, for example `Use checked resource arithmetic`.
- Do not push or open a PR unless the operator instructed it.

## Steps

### Step 1: Replace silent overflowing add/sub with checked behavior

In `src/libraries/types.cairo`, change `ERC20sAdd` and `ERC20sSub` so they assert when any component overflows or underflows.

Safe target shape:

```cairo
let (steel, steel_overflow) = lhs.steel.overflowing_add(rhs.steel);
let (quartz, quartz_overflow) = lhs.quartz.overflowing_add(rhs.quartz);
let (tritium, tritium_overflow) = lhs.tritium.overflowing_add(rhs.tritium);
assert!(!steel_overflow, "ERC20s:E_ADD_OVERFLOW");
assert!(!quartz_overflow, "ERC20s:E_ADD_OVERFLOW");
assert!(!tritium_overflow, "ERC20s:E_ADD_OVERFLOW");
```

Use analogous assertions for subtraction underflow, e.g. `"ERC20s:E_SUB_UNDERFLOW"`. Keep the operator traits in place so call sites do not need to change.

**Verify**: `scarb fmt --check` -> exit 0.

### Step 2: Add focused arithmetic tests

Add focused tests for:

- Normal addition of nonzero steel/quartz/tritium.
- Normal subtraction of nonzero steel/quartz/tritium.
- Addition overflow panics for at least one resource component.
- Subtraction underflow panics for at least one resource component.

Prefer a small new file such as `tests/resource_arithmetic.cairo` if `tests/math.cairo` is effectively unused. Import `nogame::libraries::types::ERC20s` and use `u128` max values available in Cairo. If Cairo syntax for `u128::MAX` is not available in this toolchain, use the largest literal pattern already accepted by the compiler or STOP and report.

**Verify**: run the exact new test filter, for example `snforge test resource_arithmetic` -> exit 0.

### Step 3: Run gameplay tests that exercise resource deltas

Run existing tests that use resource addition/subtraction in fleet and colony flows.

**Verify**:

- `snforge test test_attack_planet_loot_amount` -> exit 0
- `snforge test test_attack_colony` -> exit 0
- `snforge test test_collect_resources_all_planets` -> exit 0

### Step 4: Run full gates

Run the repo gates after targeted tests pass.

**Verify**:

- `scarb fmt --check` -> exit 0
- `scarb build` -> exit 0
- `snforge test` -> exit 0

## Test plan

- Add unit-level tests for `ERC20s` checked add/sub behavior.
- Run existing resource-flow tests to catch any legitimate underflow currently hidden by wrapping.
- If existing tests fail because they relied on wrapping, do not update expectations blindly; investigate the gameplay path and report if it reveals a separate bug.

## Done criteria

- [ ] `ERC20sAdd` asserts on any component overflow.
- [ ] `ERC20sSub` asserts on any component underflow.
- [ ] Normal add/sub tests pass.
- [ ] Overflow and underflow tests panic as expected.
- [ ] Existing fleet/colony resource-flow tests still pass.
- [ ] `scarb fmt --check`, `scarb build`, and `snforge test` exit 0.
- [ ] No files outside the in-scope list are modified, except `plans/README.md` status if the executor updates it.
- [ ] `plans/README.md` status row updated.

## STOP conditions

Stop and report back if:

- Existing resource-flow tests reveal a current underflow/overflow in gameplay code.
- The Cairo toolchain does not support a practical way to construct overflow/underflow regression tests.
- Fixing failures requires changing resource economics, loot formulas, or token decimals.
- Any plan dependency has not landed and leaves resource spend behavior intentionally broken.
- A verification command fails twice after a reasonable fix attempt.

## Maintenance notes

Reviewers should check whether any new `ERC20s` arithmetic sites added after this plan need explicit preconditions or should rely on these checked operators. This plan deliberately keeps operator syntax so existing call sites stay readable, but future high-risk economy code should still assert domain-specific invariants before arithmetic where possible.
