# Plan 012: Enforce colony limits per planet

> **Executor instructions**: Follow this plan step by step. Run every verification command and confirm the expected result before moving to the next step. If anything in the "STOP conditions" section occurs, stop and report -- do not improvise. When done, update the status row for this plan in `plans/README.md` unless a reviewer dispatched you and told you they maintain the index.
>
> **Drift check (run first)**: `git diff --stat a370d98..HEAD -- src/colony/contract.cairo tests/colony_test.cairo tests/utils.cairo`
> If any in-scope file changed since this plan was written, compare the "Current state" excerpts against the live code before proceeding; on a mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: S
- **Risk**: LOW
- **Depends on**: plans/004-fix-resource-collection-identity.md
- **Category**: bug
- **Planned at**: commit `a370d98`, 2026-07-06

## Why this matters

Colony capacity is a per-player, per-home-planet game rule derived from the home planet's Exocraft technology. The current implementation compares that per-planet capacity against a global `colony_count`, so colonies created by one player can block another player from founding colonies even when the second player's own tech allows it. Fixing this keeps colony expansion isolated by owner and prevents cross-player denial of progression.

## Current state

- `src/colony/contract.cairo` -- colony creation and colony storage.
- `tests/colony_test.cairo` -- existing colony integration tests.
- `tests/utils.cairo` -- test helpers for account constants and setup.

Current `generate_colony` computes `max_colonies` from the caller's planet, but uses the global `colony_count` for the capacity assertion:

```cairo
// src/colony/contract.cairo:243-251
let exo_tech = contracts.tech.get_tech_levels(planet_id).exocraft;
let max_colonies = if exo_tech % 2 == 1 {
    exo_tech / 2 + 1
} else {
    exo_tech / 2
};
let current_count = self.colony_count.read();
assert!(
    current_count < max_colonies.into(),
```

The same function later uses the correct per-planet counter for the new `colony_id`:

```cairo
// src/colony/contract.cairo:261-265
let colony_id = self.planet_colonies_count.read(planet_id) + 1;
let id = colony_identity::encode_colony_id(planet_id, colony_id);
self.colony_position.write((planet_id, colony_id), position);
self.planet_colonies_count.write(planet_id, colony_id);
self.colony_count.write(current_count + 1);
```

Existing tests create several colonies for one account, but do not prove that another account can create its own colonies independently:

```cairo
// tests/colony_test.cairo:30-34
start_cheat_caller_address(dsp.colony.contract_address, ACCOUNT1());
dsp.colony.generate_colony();
dsp.colony.generate_colony();
dsp.colony.generate_colony();
let colonies = dsp.colony.get_colonies_for_planet(1);
```

Repo conventions to match:

- Cairo tests live in `tests/*.cairo`, use `#[test]`, and set contract caller context with `start_cheat_caller_address` / `stop_cheat_caller_address`.
- Test assertions use short Cairo assertion messages, e.g. `assert(id == 1, 'wrong assert 1')`.
- Keep generated colony ID vocabulary: home planets are `1..500`; colonies are encoded with `colony_identity::encode_colony_id(planet_id, colony_id)`.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Format | `scarb fmt --check` | exit 0 |
| Targeted tests | `snforge test test_generate_colony` | exit 0, colony generation tests pass |
| Full tests | `snforge test` | exit 0, all tests pass |
| Build | `scarb build` | exit 0 |

## Scope

**In scope**:

- `src/colony/contract.cairo`
- `tests/colony_test.cairo`
- `tests/utils.cairo` only if an existing account/setup helper is needed

**Out of scope**:

- Changing the Exocraft max-colony formula
- Changing colony ID encoding
- Changing resource costs or charging for colony creation
- Changing fleet or planet identity behavior covered by other plans

## Git workflow

- Branch: `advisor/012-fix-per-planet-colony-limit`
- Commit message style: imperative sentence matching repo history, for example `Fix per-planet colony limits`.
- Do not push or open a PR unless the operator instructed it.

## Steps

### Step 1: Use the per-planet colony counter for the capacity check

In `src/colony/contract.cairo`, change `generate_colony` so it reads the existing colonies for `planet_id` from `self.planet_colonies_count.read(planet_id)` before the max-colony assertion. Use that per-planet count in the assertion and for the new `colony_id`.

Keep the global `self.colony_count` only for global position selection and global total tracking, unless a later plan deliberately changes colony placement.

Target shape:

```cairo
let global_count = self.colony_count.read();
let current_planet_colonies = self.planet_colonies_count.read(planet_id);
assert!(current_planet_colonies < max_colonies, ...);
let position = positions::get_colony_position(global_count);
let colony_id = current_planet_colonies + 1;
...
self.colony_count.write(global_count + 1);
```

Use exact names that fit local style; do not introduce a new helper unless the code becomes harder to read without one.

**Verify**: `scarb fmt --check` -> exit 0.

### Step 2: Add a regression test for independent player colony limits

In `tests/colony_test.cairo`, add a test near `test_generate_colony` that:

1. Deploys and initializes with `set_up()` and `init_game(dsp)`.
2. Generates a home planet for `ACCOUNT1()` and a home planet for `ACCOUNT2()`.
3. Calls `init_storage(dsp, 1)` and `init_storage(dsp, 2)` so both planets have enough test setup for colony generation.
4. As `ACCOUNT1()`, creates enough colonies to make `self.colony_count` greater than `ACCOUNT2()`'s allowed first-colony threshold.
5. As `ACCOUNT2()`, calls `dsp.colony.generate_colony()`.
6. Asserts `dsp.colony.get_colonies_for_planet(2).len() == 1` and `dsp.colony.get_colony_mother_planet(2001) == 2`.

Use existing account helpers from `tests/utils.cairo`. If the current Exocraft fixture in `init_storage` permits more than one colony, the point of the test is still that a nonzero global count must not block the first colony for planet 2.

**Verify**: `snforge test test_generate_colony` -> exit 0 and the new regression passes.

### Step 3: Run full gates

Run the repo gates after the targeted test passes.

**Verify**:

- `scarb fmt --check` -> exit 0
- `scarb build` -> exit 0
- `snforge test` -> exit 0

## Test plan

- Add one regression test in `tests/colony_test.cairo` for multi-player colony generation after global colony count has increased.
- Keep existing `test_generate_colony` behavior intact: planet 1 still gets colonies `1001`, `1002`, `1003`.
- Use the existing structural pattern from `tests/colony_test.cairo:21` and `tests/colony_test.cairo:97`.

## Done criteria

- [ ] `generate_colony` checks `planet_colonies_count.read(planet_id)` against `max_colonies`.
- [ ] Global `colony_count` still increments exactly once per new colony.
- [ ] A regression test proves one player's colonies do not block another player's first allowed colony.
- [ ] `scarb fmt --check`, `scarb build`, and `snforge test` exit 0.
- [ ] No files outside the in-scope list are modified, except `plans/README.md` status if the executor updates it.
- [ ] `plans/README.md` status row updated.

## STOP conditions

Stop and report back if:

- `plans/004-fix-resource-collection-identity.md` has not been applied and its current TODO state makes the caller/planet identity semantics ambiguous for this change.
- The live `generate_colony` code no longer resembles the excerpts above.
- Fixing the bug appears to require changing the Exocraft formula or colony ID encoding.
- The new test cannot create enough colonies with the current fixtures without unrelated resource/economy changes.
- A verification command fails twice after a reasonable fix attempt.

## Maintenance notes

Reviewers should check that the fix uses the per-planet count for capacity only, while preserving the global count for total colony placement. If a future plan changes colony placement from global deterministic positions to per-player positions, revisit this test so it still asserts cross-player independence rather than exact global ordering.
