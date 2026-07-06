# Plan 014: Add defence rebuild settlement

> **Executor instructions**: Follow this plan step by step. Run every verification command and confirm the expected result before moving to the next step. If anything in the "STOP conditions" section occurs, stop and report; do not improvise. When done, update the status row for this plan in `plans/README.md` unless a reviewer dispatched you and told you they maintain the index.
>
> **Drift check (run first)**: `git diff --stat 0c6e6f7..HEAD -- docs/ORIGINAL_BATTLE_LOGIC.md src/fleet_movements/battle_settlement.cairo src/fleet_movements/library.cairo src/fleet_movements/lifecycle.cairo src/fleet_movements/orchestration.cairo src/defence/library.cairo tests/defence_write.cairo tests/fleet_write.cairo tests/colony_test.cairo plans/README.md`
> If any in-scope file changed since this plan was written, compare the "Current state" excerpts against the live code before proceeding. On a mismatch, treat it as a STOP condition.

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: MED
- **Depends on**: plans/003-restore-battle-math-characterization-tests.md, plans/010-add-round-capped-battle-draws.md
- **Category**: direction
- **Planned at**: commit `0c6e6f7`, 2026-07-06

## Why this matters

The original battle model allows destroyed defensive structures to rebuild for free after combat; ships do not. Current NoGame settlement writes post-battle defences directly, so defence losses are always permanent. A deterministic rebuild policy can preserve the original design intent while staying suitable for onchain execution.

## Current state

- `docs/ORIGINAL_BATTLE_LOGIC.md` states defender defensive structures can rebuild after combat.
- `src/fleet_movements/battle_settlement.cairo::settle` computes `defences_loss` from initial and final defences.
- `src/fleet_movements/lifecycle.cairo::update_defender_assets` writes `plan.settlement.defences` directly after an attack.
- `src/defence/library.cairo` contains defence costs but no rebuild policy.

Current excerpts:

```markdown
<!-- docs/ORIGINAL_BATTLE_LOGIC.md:86 -->
After combat, defender **defensive structures** have a chance to rebuild for free; ships do not.
```

```cairo
// src/fleet_movements/battle_settlement.cairo:28-30
let attacker_loss = fleet_loss(attacker_initial_fleet, attacker_after);
let defender_loss = fleet_loss(defender_initial_fleet, defender_after);
let defences_loss = defences_loss(initial_defences, defences_after);
```

```cairo
// src/fleet_movements/lifecycle.cairo:140-151
fn update_defender_assets(
    contracts: Contracts, destination_id: u32, plan: orchestration::AttackMissionPlan,
) {
    if plan.target.is_colony {
        contracts
            .colony
            .update_defences_after_attack(
                plan.target.mother_planet_id, plan.target.colony_id, plan.settlement.defences,
            );
    } else {
        write_planet_fleet(contracts, destination_id, plan.settlement.defender_fleet);
        write_planet_defences(contracts, destination_id, plan.settlement.defences);
    }
}
```

Repo conventions and constraints:

- Settlement should compute facts; lifecycle should apply them.
- Keep rebuild deterministic onchain; do not use random rebuild rolls.
- Colonies and home planets should use the same rebuild policy unless product explicitly decides otherwise.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Format | `scarb fmt --check` | exit 0 |
| Build | `scarb build` | exit 0 |
| Focused tests | `snforge test defence` | defence-related tests pass |
| Fleet tests | `snforge test attack` | attack tests pass |
| Full tests | `snforge test` | all tests pass |

## Scope

**In scope**:

- `src/fleet_movements/battle_settlement.cairo`
- `src/fleet_movements/library.cairo` if rebuild helpers belong beside combat helpers
- `src/fleet_movements/lifecycle.cairo`
- `src/fleet_movements/orchestration.cairo` only if `AttackMissionPlan` needs additional fields
- `src/defence/library.cairo` only if adding a rebuild-rate constant/helper there is cleaner
- `tests/fleet_write.cairo`
- `tests/colony_test.cairo`
- `tests/defence_write.cairo` if a focused helper path is available
- `plans/README.md`

**Out of scope**:

- Ship rebuild
- Random rebuild chance
- Defence-into-debris policy
- Changing defence build costs
- Public ABI or event schema changes

## Git workflow

- Branch: `advisor/014-add-defence-rebuild-settlement`
- Commit style observed in history: imperative/conventional, for example `Gate privileged Planet, Dockyard, and Defence state setters`.
- Do not push or open a PR unless the operator instructed it.

## Steps

### Step 1: Choose and encode deterministic rebuild policy

Add a named rebuild policy constant or helper. Because original OGame uses chance but onchain settlement must be deterministic, use a fixed percentage of destroyed defences rebuilt for free unless a product doc specifies another value. For example:

- `DEFENCE_REBUILD_RATE: u128 = 70`
- rebuilt count = destroyed count * rebuild rate / 100, rounded down

Add a short comment stating this is a deterministic onchain approximation of the original random rebuild chance.

**Verify**: `scarb build` -> expect compile errors until applied, or exit 0 if completed in one edit.

### Step 2: Apply rebuild after combat before state write

Update settlement so `BattleSettlement.defences` represents final defences after rebuild, while `defences_loss` represents net permanent losses. Keep `defender_loss` for ships unchanged.

Be careful with debris: original normal defences generally do not create debris unless a universe setting says they should. Current code only adds celestia destroyed into quartz debris. Do not broaden defence debris in this plan.

**Verify**: `scarb build` -> exit 0.

### Step 3: Keep points and reports consistent

Check `lifecycle::battle_report_facts` and `update_points_after_attack`. If `defences_loss` changes to net permanent loss, points and reports should use the same net value unless the product needs both "destroyed before rebuild" and "permanent loss." Do not add new event fields in this plan.

**Verify**: `snforge test attack` -> attack tests pass or expected fixture updates are ready.

### Step 4: Add planet and colony rebuild tests

Add tests that pin:

- destroyed planet defences partially rebuild and stored defence levels reflect rebuilt counts
- destroyed colony defences use the same policy
- ships do not rebuild
- battle reports or observable state use net permanent defence loss

Use existing `tests/fleet_write.cairo::test_attack_planet` and `tests/colony_test.cairo::test_attack_colony` as setup patterns.

**Verify**:

- `snforge test defence` -> defence-related tests pass
- `snforge test attack` -> attack-related tests pass

### Step 5: Run full gates and update index

**Verify**:

- `scarb fmt --check` -> exit 0
- `scarb build` -> exit 0
- `snforge test` -> all tests pass
- `git status --short` -> only in-scope files are modified

Update `plans/README.md` status for this plan to `DONE` only after verification passes.

## Test plan

- Add at least one planet attack fixture with defence destruction and rebuild.
- Add at least one colony attack fixture with defence destruction and rebuild.
- Assert ship losses remain permanent.
- Full verification is `snforge test`.

## Done criteria

- [ ] Defence rebuild policy is named, deterministic, and documented in code.
- [ ] Stored planet defences reflect post-rebuild counts.
- [ ] Stored colony defences reflect post-rebuild counts.
- [ ] Ships do not rebuild.
- [ ] Points/reports use a consistent net-loss interpretation.
- [ ] `scarb fmt --check`, `scarb build`, and `snforge test` pass.
- [ ] No files outside the in-scope list are modified.
- [ ] `plans/README.md` status row updated.

## STOP conditions

Stop and report if:

- Product wants exact random defence rebuilds onchain.
- There is no maintainer-approved deterministic rebuild rate.
- Existing event consumers require both gross destroyed and net permanent defence loss.
- The change requires storage migrations or public ABI changes.
- Verification fails twice after reasonable fix attempts.

## Maintenance notes

This plan intentionally avoids defence-into-debris settings. If a future universe setting enables defence debris, that should be a separate configurable economy plan because it interacts with rebuilds and debris collection.
