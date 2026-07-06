# Plan 007: Add tech-aware battle simulation view

> **Executor instructions**: Follow this plan step by step. Run every verification command and confirm the expected result before moving to the next step. If anything in the "STOP conditions" section occurs, stop and report; do not improvise. When done, update the status row for this plan in `plans/README.md` unless a reviewer told you they maintain the index.
>
> **Drift check (run first)**: `git diff --stat 0c6e6f7..HEAD -- docs/battle-simulator-spike.md src/fleet_movements/contract.cairo src/fleet_movements/battle_settlement.cairo src/libraries/types.cairo tests/fleet.cairo tests/fleet_write.cairo plans/README.md`
> If any in-scope file changed since this plan was written, compare the "Current state" excerpts against the live code before proceeding. On a mismatch, treat it as a STOP condition.

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: MED
- **Depends on**: plans/003-restore-battle-math-characterization-tests.md recommended
- **Category**: direction
- **Planned at**: commit `0c6e6f7`, 2026-07-06

## Why this matters

The README roadmap calls for an offchain battle simulator, and the repo already contains a spike defining the smallest useful onchain boundary. The current `simulate_attack` view only supports zero-tech, no-decay previews. Adding a non-breaking `simulate_attack_with_techs` view lets clients compare attacker and defender tech levels while keeping battle settlement as the source of truth.

## Current state

- `docs/battle-simulator-spike.md` recommends a non-breaking `simulate_attack_with_techs` view.
- `src/fleet_movements/contract.cairo` currently exposes only `simulate_attack`.
- `src/fleet_movements/battle_settlement.cairo::settle` already accepts attacker and defender `TechLevels`.
- `src/libraries/types.cairo` defines ABI-visible `TechLevels` and `SimulationResult`.

Current excerpts:

```markdown
<!-- docs/battle-simulator-spike.md:71-88 -->
Add a second view rather than breaking the existing ABI immediately:

fn simulate_attack_with_techs(...)

Keep `simulate_attack` as a compatibility wrapper that passes `Default::default()` for both tech structs.
```

```cairo
// src/fleet_movements/contract.cairo:124-126
fn simulate_attack(
    self: @TState, attacker_fleet: Fleet, defender_fleet: Fleet, defences: Defences,
) -> SimulationResult;
```

```cairo
// src/fleet_movements/battle_settlement.cairo:15-23
fn settle(
    attacker_initial_fleet: Fleet,
    defender_initial_fleet: Fleet,
    initial_defences: Defences,
    attacker_techs: TechLevels,
    defender_techs: TechLevels,
    initial_celestia: u32,
    time_since_arrived: u64,
) -> BattleSettlement {
```

Repo conventions to follow:

- Non-breaking ABI additions go into the Starknet interface and embedded impl in `src/fleet_movements/contract.cairo`.
- Keep shared ABI structs in `src/libraries/types.cairo`; do not create a new result type in this slice.
- Tests should include a zero-tech compatibility check and an asymmetric tech case, as required by the spike.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Format | `scarb fmt --check` | exit 0 |
| Build | `scarb build` | exit 0 |
| Focused tests | `snforge test simulate` | simulator tests pass |
| Full tests | `snforge test` | all tests pass |

## Scope

**In scope**:

- `src/fleet_movements/contract.cairo`
- `tests/fleet.cairo` or `tests/fleet_write.cairo`
- `plans/README.md`

**Out of scope**:

- Offchain TypeScript/Rust simulator implementation
- Decay-aware simulator API
- Changing `SimulationResult`
- Changing battle formulas
- Frontend work

## Git workflow

- Branch: `advisor/007-add-tech-aware-battle-simulation-view`
- Commit style observed in history: imperative/conventional, for example `Document battle simulator API seam`.
- Do not push or open a PR unless the operator instructed it.

## Steps

### Step 1: Add the interface method

In `src/fleet_movements/contract.cairo`, import `TechLevels` in the top-level interface use list if needed. Add this method to `IFleetMovements<TState>` after `simulate_attack`:

```cairo
fn simulate_attack_with_techs(
    self: @TState,
    attacker_fleet: Fleet,
    defender_fleet: Fleet,
    defences: Defences,
    attacker_techs: TechLevels,
    defender_techs: TechLevels,
) -> SimulationResult;
```

Keep `simulate_attack` unchanged for compatibility.

**Verify**: `scarb build` -> expect a compile error until implementation is added, or exit 0 if you add interface and implementation in one edit.

### Step 2: Implement the view through settlement

In `FleetMovementsImpl`, add `simulate_attack_with_techs` that calls:

```cairo
battle_settlement::settle(
    attacker_fleet,
    defender_fleet,
    defences,
    attacker_techs,
    defender_techs,
    defences.celestia,
    0,
)
```

Map the returned losses into `SimulationResult` exactly like current `simulate_attack`.

Then simplify `simulate_attack` if useful so it creates default techs and delegates to `simulate_attack_with_techs`; do not change its output.

**Verify**: `scarb build` -> exit 0.

### Step 3: Add focused simulator tests

Add tests in `tests/fleet.cairo` or `tests/fleet_write.cairo`:

- Zero-tech compatibility: `simulate_attack(...) == simulate_attack_with_techs(..., Default::default(), Default::default())`.
- Asymmetric tech case: use non-default attacker and defender techs where swapping or ignoring techs changes the expected result. Assert exact `SimulationResult` values from current settlement behavior.

If plan 003 has not landed and `tests/fleet.cairo` is still commented out, place tests in `tests/fleet_write.cairo` near fleet behavior tests.

**Verify**: `snforge test simulate` -> new simulator tests pass.

### Step 4: Run full gates and update index

**Verify**:

- `scarb fmt --check` -> exit 0
- `scarb build` -> exit 0
- `snforge test` -> all tests pass
- `git status --short` -> only in-scope files are modified

Update `plans/README.md` status for this plan to `DONE` only after verification passes.

## Test plan

- Add a zero-tech regression proving old and new views match.
- Add one asymmetric tech test that fails if attacker and defender techs are ignored or swapped.
- Full verification is `snforge test`.

## Done criteria

- [ ] `IFleetMovements` exposes `simulate_attack_with_techs`.
- [ ] Existing `simulate_attack` remains available and compatible.
- [ ] New view delegates to `battle_settlement::settle` with caller-supplied techs and `time_since_arrived = 0`.
- [ ] Focused simulator tests pass.
- [ ] `scarb fmt --check`, `scarb build`, and `snforge test` pass.
- [ ] No files outside the in-scope list are modified.
- [ ] `plans/README.md` status row updated.

## STOP conditions

Stop and report if:

- Adding the method changes existing ABI behavior or breaks existing callers.
- You cannot construct an asymmetric tech case that proves both tech arguments are used.
- Product asks for decay-aware simulation in the same slice.
- Verification fails twice after reasonable fix attempts.

## Maintenance notes

This is the onchain parity oracle for any future offchain simulator. Do not fork battle formulas into another module without fixture parity against this view.
