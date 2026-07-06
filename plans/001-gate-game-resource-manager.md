# Plan 001: Gate Game resource mint and burn helpers

> **Executor instructions**: Follow this plan step by step. Run every verification command before moving on. If a STOP condition occurs, stop and report. When done, update `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat a370d98..HEAD -- src/game/contract.cairo src/game/interfaces/resource_manager.cairo tests`
> If these files changed since this plan was written, compare the Current state excerpts against live code before proceeding.

## Status

- **Priority**: P1
- **Effort**: M
- **Risk**: MED
- **Depends on**: none
- **Category**: security
- **Planned at**: commit `a370d98`, 2026-07-06

## Why This Matters

`Game` is configured as the minter/burner for the resource ERC20 contracts. Its resource manager methods are embedded in the public ABI and currently perform mint/burn operations without checking the external caller. Any account that can call `grant_resources`, `receive_resources_erc20`, `pay_resources_erc20`, or `spend_resources` can affect resource balances through `Game`.

## Current State

- `src/game/interfaces/resource_manager.cairo` defines all resource manager methods as external interface methods.
- `src/game/contract.cairo` implements those methods with no caller validation.
- `src/token/erc20/erc20_ng.cairo` correctly restricts token mint/burn to its configured minter, so the vulnerable trust boundary is `Game`.

Relevant excerpts:

```cairo
// src/game/interfaces/resource_manager.cairo:7
fn spend_resources(self: @TState, account: ContractAddress, amounts: ERC20s);
fn grant_resources(self: @TState, account: ContractAddress, amounts: ERC20s);
fn pay_resources_erc20(self: @TState, account: ContractAddress, amounts: ERC20s);
fn receive_resources_erc20(self: @TState, account: ContractAddress, amounts: ERC20s);
```

```cairo
// src/game/contract.cairo:127
fn grant_resources(self: @ContractState, account: ContractAddress, amounts: ERC20s) {
    IResourceManager::receive_resources_erc20(self, account, amounts);
}
```

Repo conventions: Cairo contracts use private helper traits for shared checks, e.g. `src/colony/contract.cairo` has `verify_authorized_caller`, and external tests use `start_cheat_caller_address`.

## Commands You Will Need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Focused tests | `snforge test test_game_resource_manager` | exit 0, new tests pass |
| Format | `scarb fmt --check` | exit 0 |
| Build | `scarb build` | exit 0 |
| Full tests | `snforge test` | exit 0 |

## Scope

**In scope**:
- `src/game/contract.cairo`
- `tests/game_resource_manager_access.cairo` or an equivalent focused test file under `tests/`

**Out of scope**:
- ERC20 token authorization logic in `src/token/erc20/erc20_ng.cairo`
- Economic formula changes
- Any deployment script change

## Git Workflow

- Branch: `advisor/001-gate-game-resource-manager`
- Commit style: short imperative sentence, matching recent history such as `Name game-state fixtures`.
- Do not push unless instructed.

## Steps

### Step 1: Add an authorized resource-mutator check

In `src/game/contract.cairo`, add a private helper that reads registered contracts and allows only game contracts that legitimately call mutating resource methods: `planet`, `compound`, `defence`, `dockyard`, `fleet`, `colony`, and `tech`. Use `get_caller_address()` and the existing `Contracts` registry.

Do not gate read-only methods: `get_account_resources`, `get_planet_spendable_resources`, and `check_enough_resources`.

**Verify**: `scarb fmt --check` -> exit 0.

### Step 2: Apply the check to mutating methods

Call the helper at the start of:
- `spend_resources`
- `grant_resources`
- `spend_planet_resources`
- `pay_resources_erc20`
- `receive_resources_erc20`

Preserve existing resource amount math and error strings unless a test requires a new error string.

**Verify**: `scarb build` -> exit 0.

### Step 3: Add regression tests

Create focused tests that:
- initialize the game normally,
- as an arbitrary account, assert `grant_resources` panics,
- as an arbitrary account, assert `receive_resources_erc20` panics,
- as an authorized contract caller such as `dsp.planet.contract_address`, assert the existing planet generation path still mints starter resources.

Use `#[should_panic]` and `start_cheat_caller_address` patterns from `tests/fleet_write.cairo`.

**Verify**: `snforge test test_game_resource_manager` -> exit 0.

## Test Plan

- New tests in `tests/game_resource_manager_access.cairo`.
- Cover unauthorized direct mint, unauthorized direct burn/spend, and an authorized existing gameplay path.
- Then run `snforge test` to ensure compound, tech, dockyard, defence, fleet, and colony workflows still pass.

## Done Criteria

- [ ] Mutating resource manager methods verify caller authorization.
- [ ] Read-only resource methods remain callable.
- [ ] `snforge test test_game_resource_manager` exits 0.
- [ ] `scarb fmt --check`, `scarb build`, and `snforge test` exit 0.
- [ ] No files outside the in-scope list are modified.
- [ ] `plans/README.md` status row updated.

## STOP Conditions

- STOP if `Game` no longer stores all contract dispatchers locally.
- STOP if a required authorized caller is not registered in `Contracts`.
- STOP if adding the gate requires changing ERC20 minter semantics.

## Maintenance Notes

Any new contract that mints, burns, or spends resources through `Game` must be added to the authorization helper and covered by a regression test.
