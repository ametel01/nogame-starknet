# Plan 013: Require transport arrival before docking

> **Executor instructions**: Follow this plan step by step. Run every verification command and confirm the expected result before moving to the next step. If anything in the "STOP conditions" section occurs, stop and report -- do not improvise. When done, update the status row for this plan in `plans/README.md` unless a reviewer dispatched you and told you they maintain the index.
>
> **Drift check (run first)**: `git diff --stat a370d98..HEAD -- src/fleet_movements/contract.cairo src/fleet_movements/orchestration.cairo tests/colony_test.cairo tests/fleet_write.cairo`
> If any in-scope file changed since this plan was written, compare the "Current state" excerpts against the live code before proceeding; on a mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: S/M
- **Risk**: MED
- **Depends on**: plans/004-fix-resource-collection-identity.md
- **Category**: bug
- **Planned at**: commit `a370d98`, 2026-07-06

## Why this matters

Fleet travel time is part of the game economy: attack and debris missions already require arrival before effects are applied. Transport missions skip that check in `dock_fleet`, so a caller can send a transport fleet and immediately dock it at the destination, bypassing travel time. This plan aligns transport mission lifecycle with the rest of the fleet system.

## Current state

- `src/fleet_movements/contract.cairo` -- public fleet mission entrypoints.
- `src/fleet_movements/orchestration.cairo` -- mission planning and arrival checks for attack/debris.
- `tests/colony_test.cairo` -- transport-to-colony and transport-from-colony tests.
- `tests/fleet_write.cairo` -- fleet lifecycle tests and panic patterns.

The public interface documents `dock_fleet` as a transport mission completion path:

```cairo
// src/fleet_movements/contract.cairo:74-88
/// Docks a transport mission fleet at destination colony.
///
/// # Parameters
/// - `mission_id`: ID of the transport mission
/// - `colony_id`: Destination colony ID to dock at
...
fn dock_fleet(ref self: TState, mission_id: usize, colony_id: u8);
```

The implementation checks only mission category and emptiness before returning the fleet to `mission.destination`:

```cairo
// src/fleet_movements/contract.cairo:361-369
fn dock_fleet(ref self: ContractState, mission_id: usize, colony_id: u8) {
    let contracts = self.game_manager.read().get_contracts();
    let caller = get_caller_address();
    let origin = contracts.planet.get_owned_planet(caller);
    let mission = self.get_mission_details(origin, mission_id);
    assert!(mission.category == MissionCategory::TRANSPORT, "Fleet:E_WRONG_CATEGORY");
    assert!(!mission.is_zero(), "Fleet:E_MISSION_EMPTY");
    lifecycle::return_fleet(contracts, mission.destination, mission.fleet);
```

Attack and debris flows already assert arrival:

```cairo
// src/fleet_movements/orchestration.cairo:120-123
assert!(!mission.is_zero(), "Fleet:E_MISSION_EMPTY");
assert!(mission.category == MissionCategory::ATTACK, "Fleet:E_WRONG_CATEGORY");
assert!(mission.destination != origin, "Fleet:E_ATTACK_OWN_PLANET");
assert!(time_now >= mission.time_arrival, "Fleet:E_ARRIVAL_PENDING");
```

Existing transport tests warp time before docking, but there is no failing test for docking too early:

```cairo
// tests/colony_test.cairo:127-130
start_cheat_block_timestamp_global(mission.time_arrival + 1);

start_cheat_caller_address(dsp.fleet.contract_address, ACCOUNT1());
dsp.fleet.dock_fleet(1, 0);
```

Repo conventions to match:

- Fleet errors use `Fleet:E_*` strings.
- Mission time checks compare `get_block_timestamp()` with `mission.time_arrival`.
- Panic tests use `#[should_panic]` without relying on exact panic text in this repo.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Format | `scarb fmt --check` | exit 0 |
| Targeted tests | `snforge test dock_fleet` | exit 0, dock fleet tests pass |
| Full tests | `snforge test` | exit 0, all tests pass |
| Build | `scarb build` | exit 0 |

## Scope

**In scope**:

- `src/fleet_movements/contract.cairo`
- `tests/colony_test.cairo`
- `tests/fleet_write.cairo` only if a better test location is needed

**Out of scope**:

- Changing transport destination semantics
- Changing mission recording or incoming mission storage layout
- Changing attack/debris arrival checks
- Implementing the unused destination `colony_id` parameter as a separate feature
- Changing fleet travel-time formulas

## Git workflow

- Branch: `advisor/013-require-transport-arrival-before-docking`
- Commit message style: imperative sentence matching repo history, for example `Require transport arrival before docking`.
- Do not push or open a PR unless the operator instructed it.

## Steps

### Step 1: Add an arrival assertion to `dock_fleet`

In `src/fleet_movements/contract.cairo`, add an arrival check after `mission` has been loaded and verified non-empty/category-correct, before `lifecycle::return_fleet`.

Target behavior:

```cairo
assert!(mission.category == MissionCategory::TRANSPORT, "Fleet:E_WRONG_CATEGORY");
assert!(!mission.is_zero(), "Fleet:E_MISSION_EMPTY");
assert!(get_block_timestamp() >= mission.time_arrival, "Fleet:E_ARRIVAL_PENDING");
lifecycle::return_fleet(contracts, mission.destination, mission.fleet);
```

`get_block_timestamp` is already imported in this module. Preserve existing mission clearing and `touch_origin` behavior.

**Verify**: `scarb fmt --check` -> exit 0.

### Step 2: Add a too-early docking regression test

Add a test near the existing transport tests in `tests/colony_test.cairo`:

1. Set up the same scenario as `test_send_fleet_to_colony` or factor only if the file already has a suitable local helper.
2. Send a `MissionCategory::TRANSPORT` fleet.
3. Do not advance block timestamp to `mission.time_arrival`.
4. Call `dsp.fleet.dock_fleet(1, 0)` as the same account.
5. Mark the test `#[should_panic]`.

Prefer a direct test over broad refactoring. This plan is about one missing check.

**Verify**: `snforge test dock_fleet` -> exit 0 and includes the new panic regression.

### Step 3: Confirm existing successful transport tests still pass

Run the existing colony transport tests to ensure docking still succeeds after arrival.

**Verify**: `snforge test test_send_fleet_to_colony` and `snforge test test_send_fleet_from_colony` -> both exit 0.

### Step 4: Run full gates

Run the repo gates after targeted tests pass.

**Verify**:

- `scarb fmt --check` -> exit 0
- `scarb build` -> exit 0
- `snforge test` -> exit 0

## Test plan

- Add one `#[should_panic]` regression test for docking a transport mission before `mission.time_arrival`.
- Keep existing success tests where time is advanced past arrival.
- Use `tests/colony_test.cairo:97` and `tests/colony_test.cairo:135` as the structural patterns.

## Done criteria

- [ ] `dock_fleet` asserts `get_block_timestamp() >= mission.time_arrival`.
- [ ] New too-early docking test fails before the fix and passes after it.
- [ ] Existing transport docking tests still pass.
- [ ] `scarb fmt --check`, `scarb build`, and `snforge test` exit 0.
- [ ] No files outside the in-scope list are modified, except `plans/README.md` status if the executor updates it.
- [ ] `plans/README.md` status row updated.

## STOP conditions

Stop and report back if:

- The live `dock_fleet` code no longer resembles the excerpt above.
- Transport mission semantics have changed so `mission.destination` is no longer the docking target.
- The fix appears to require implementing the unused `colony_id` parameter rather than only enforcing arrival time.
- Existing successful transport tests fail for reasons unrelated to the new arrival assertion.
- A verification command fails twice after a reasonable fix attempt.

## Maintenance notes

Reviewers should check that transport, attack, and debris missions now share the same "effects require arrival" invariant. The unused `colony_id` parameter remains a separate design issue; do not expand this plan into a broader transport routing redesign.
