# Plan 009: Clean deployment docs and example credential hygiene

> **Drift check (run first)**: `git diff --stat a370d98..HEAD -- DEPLOYMENT.md .env.local.example .env.docker.example README.md Scarb.toml .tool-versions`

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: docs
- **Planned at**: commit `a370d98`, 2026-07-06

## Why This Matters

The repo includes deterministic local Katana private-key material in example env files and deployment docs. These are not production secrets, but committed key-looking values trigger scanners and encourage unsafe copy/paste habits. The deployment guide also shows stale OpenZeppelin and Scarb references that conflict with current config.

## Current State

- `.env.local.example:11`, `.env.local.example:17`, `.env.local.example:22`, `.env.local.example:27`, `.env.local.example:32` contain example Starknet private keys.
- `.env.docker.example` has the same pattern.
- `DEPLOYMENT.md:141` contains a Katana private key example.
- `DEPLOYMENT.md:94-98` lists OpenZeppelin `2.0.0`, while `Scarb.toml` uses OpenZeppelin `3.0.0` and related `2.1.0` packages.
- `.tool-versions` currently says `scarb 2.19.1` and `starknet-foundry 0.62.1`.

Do not copy any key values into commits, issues, or docs.

## Commands You Will Need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Secret pattern check | `rg -n "PRIVATE_KEY=.*0x|STARKNET_PRIVATE_KEY=.*0x" .env*.example DEPLOYMENT.md` | no concrete key values |
| Docs sanity | `rg -n "2\\.0\\.0|2\\.12\\.2" DEPLOYMENT.md` | no stale tool/package versions unless historically explained |
| Format/build guard | `scarb build` | exit 0 |

## Scope

**In scope**:
- `.env.local.example`
- `.env.docker.example`
- `DEPLOYMENT.md`
- optionally `README.md` if setup pointers need correction

**Out of scope**:
- Real `.env.*` files that are not tracked examples
- Deployment script behavior
- Contract code

## Steps

### Step 1: Replace concrete private keys with placeholders

In example env files and `DEPLOYMENT.md`, replace private-key values with placeholders such as `<katana-private-key-0>` or `<set-in-local-env>`. Keep account addresses only if they are needed for local Katana documentation and are not secret.

**Verify**: `rg -n "PRIVATE_KEY=.*0x|STARKNET_PRIVATE_KEY=.*0x" .env*.example DEPLOYMENT.md` -> no concrete key values.

### Step 2: Add a clear local-only note

Document that local Katana accounts are deterministic development accounts and must never be reused for public networks. Keep this note short and near the env example.

**Verify**: `rg -n "local.*Katana|never.*public|test.*only" DEPLOYMENT.md .env*.example` -> matching warning text exists.

### Step 3: Update stale versions

Update deployment docs to match `Scarb.toml` and `.tool-versions`: Scarb `2.19.1`, Starknet Foundry `0.62.1`, current OpenZeppelin package versions from `Scarb.toml`.

**Verify**: `rg -n "2\\.0\\.0|2\\.12\\.2" DEPLOYMENT.md` -> no stale references unless explicitly described as old history.

## Test Plan

No code tests are required. Run `scarb build` as a guard to ensure no accidental source edits broke build metadata.

## Done Criteria

- [ ] No concrete private-key values remain in tracked examples/docs.
- [ ] Docs state local Katana keys are development-only.
- [ ] Deployment guide versions match current config.
- [ ] `scarb build` exits 0.
- [ ] `plans/README.md` status row updated.

## STOP Conditions

- STOP if real tracked environment files beyond examples contain credentials.
- STOP if the operator wants concrete Katana keys preserved for copy/paste.

## Maintenance Notes

If future docs need local account material, link to Katana documentation or use placeholders rather than embedding key-looking literals.
