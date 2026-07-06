# Plan 002: Prevent phantom spendable loot grants

> **Executor instructions**: Follow this plan step by step. Run every verification command and confirm the expected result before moving to the next step. If anything in the "STOP conditions" section occurs, stop and report; do not improvise. When done, update the status row for this plan in `plans/README.md` unless a reviewer told you they maintain the index.
>
> **Drift check (run first)**: `git diff --stat 0c6e6f7..HEAD -- src/fleet_movements/orchestration.cairo src/fleet_movements/lifecycle.cairo src/fleet_movements/library.cairo tests/fleet_write.cairo plans/README.md`
> If any in-scope file changed since this plan was written, compare the "Current state" excerpts against the live code before proceeding. On a mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: M
- **Risk**: MED
- **Depends on**: none
- **Category**: bug
- **Planned at**: commit `0c6e6f7`, 2026-07-06

## Why this matters

Attack loot is split between resources that are collectible from production and resources that are spendable ERC20 balances. The current low-cargo branch loads `collectible + spendable` into `loot_collectible`, then `apply_attack_effects` grants `total_loot` but only burns `loot_spendable` from the defender. That can mint defender spendable balances to the attacker without debiting the defender when cargo is smaller than collectible production. The fix should preserve cargo ordering while ensuring every spendable resource granted is represented in `loot_spendable` and burned.

## Current state

- `src/fleet_movements/orchestration.cairo` calculates `(loot_spendable, loot_collectible)`.
- `src/fleet_movements/lifecycle.cairo` grants `total_loot` and burns only `plan.loot_spendable` for non-colony targets.
- `tests/fleet_write.cairo` has one loot amount test, but it does not assert the defender spendable balance decreases.

Current excerpts:

```cairo
// src/fleet_movements/orchestration.cairo:286-288
if storage < (collectible.steel + collectible.quartz + collectible.tritium) {
    loot_collectible = fleet::load_resources(collectible + spendable, storage);
} else {
```

```cairo
// src/fleet_movements/lifecycle.cairo:84-85
spend_attack_loot(contracts, mission.destination, lifecycle.plan);
resource_manager(contracts).grant_resources(caller, lifecycle.plan.total_loot);
```

```cairo
// src/fleet_movements/lifecycle.cairo:155-160
fn spend_attack_loot(
    contracts: Contracts, destination_id: u32, plan: orchestration::AttackMissionPlan,
) {
    if !plan.target.is_colony {
        resource_manager(contracts).spend_planet_resources(destination_id, plan.loot_spendable);
    }
}
```

Repo conventions to follow:

- Keep battle and mission orchestration logic in `src/fleet_movements/orchestration.cairo`; state application belongs in `lifecycle.cairo`.
- Use existing `ERC20s` arithmetic and `fleet::load_resources`; do not duplicate resource-loading loops unless the helper cannot express the fix.
- Tests in `tests/fleet_write.cairo` use full game setup and direct spendable resource assertions.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Format | `scarb fmt --check` | exit 0 |
| Build | `scarb build` | exit 0 |
| Focused tests | `snforge test test_attack_planet_loot` | matching loot tests pass |
| Full tests | `snforge test` | all tests pass |

## Scope

**In scope**:

- `src/fleet_movements/orchestration.cairo`
- `tests/fleet_write.cairo`
- `plans/README.md`

**Out of scope**:

- Battle settlement formulas
- Resource token contracts
- Colony attack loot semantics unless a test proves they share the same bug
- Public ABI changes

## Git workflow

- Branch: `advisor/002-prevent-phantom-spendable-loot-grants`
- Commit style observed in history: imperative/conventional, for example `Use checked ERC20s resource arithmetic`.
- Do not push or open a PR unless the operator instructed it.

## Steps

### Step 1: Add a regression test that fails on phantom spendable grants

In `tests/fleet_write.cairo`, add a test near `test_attack_planet_loot_amount`.

The test should:

1. Set up two started planets.
2. Give the attacker a fleet with cargo smaller than the defender's collectible production so the current low-cargo branch is exercised.
3. Record defender spendable resources before attack.
4. Execute `attack_planet`.
5. Record attacker and defender spendable resources after attack.
6. Assert that any attacker gain sourced from defender spendable resources is matched by a defender spendable decrease. In the intended low-cargo case where cargo is filled only by collectible resources, defender spendable should not decrease and no spendable should be minted through `loot_collectible`.

If it is hard to isolate source buckets with existing helpers, first add assertions to the existing `test_attack_planet_loot_amount` that defender spendable decreases by the same amount represented as spendable loot. The test must catch the current mixed-bucket behavior before the fix.

**Verify**: `snforge test test_attack_planet_loot` -> the new regression should fail before the production fix. If it passes before the fix, STOP and report because the test is not proving the bug.

### Step 2: Refactor loot calculation to keep buckets separate

In `calculate_loot_amount`, load cargo in two phases:

1. Load from `collectible` first into `loot_collectible`.
2. Compute remaining cargo.
3. For non-colony spendable resources, cap spendable loot to 50 percent of defender spendable balances, then load only that capped value into `loot_spendable`.

The result should preserve the existing return type:

```cairo
(loot_spendable, loot_collectible)
```

Do not put `spendable` into `loot_collectible`. That field is granted but not burned.

**Verify**: `scarb build` -> exit 0.

### Step 3: Confirm attack state changes

Run the focused loot tests. Ensure:

- Attacker gain equals `loot_spendable + loot_collectible`.
- Defender spendable decreases exactly by `loot_spendable`.
- Collectible production timing remains reset by the existing lifecycle path.

**Verify**: `snforge test test_attack_planet_loot` -> all matching tests pass.

### Step 4: Run full gates and update index

**Verify**:

- `scarb fmt --check` -> exit 0
- `scarb build` -> exit 0
- `snforge test` -> all tests pass
- `git status --short` -> only in-scope files are modified

Update `plans/README.md` status for this plan to `DONE` only after verification passes.

## Test plan

- Add at least one regression test in `tests/fleet_write.cairo` that would fail if spendable balances are granted without being burned.
- Keep existing `test_attack_planet_loot_amount` passing or adjust its expected value only if the old expectation depended on the bug.
- Full verification is `snforge test`.

## Done criteria

- [ ] `calculate_loot_amount` never assigns spendable balances to `loot_collectible`.
- [ ] Defender spendable resources decrease exactly by the spendable loot amount on non-colony attacks.
- [ ] Attacker total gain remains cargo-limited.
- [ ] `scarb fmt --check`, `scarb build`, and `snforge test` pass.
- [ ] No files outside the in-scope list are modified.
- [ ] `plans/README.md` status row updated.

## STOP conditions

Stop and report if:

- Product rules say spendable resources should be grantable without burning the defender.
- You cannot create a failing regression test before changing production code.
- Fixing this requires changing token mint/burn authorization or public ABI.
- Verification fails twice after reasonable fix attempts.

## Maintenance notes

Reviewers should inspect the bucket accounting more than the exact numeric fixture. Future loot changes should keep source buckets explicit: collectible production, spendable ERC20 balances, and debris are different accounting domains.
