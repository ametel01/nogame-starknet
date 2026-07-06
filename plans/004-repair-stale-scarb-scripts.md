# Plan 004: Repair stale Scarb scripts

> **Executor instructions**: Follow this plan step by step. Run every verification command and confirm the expected result before moving to the next step. If anything in the "STOP conditions" section occurs, stop and report; do not improvise. When done, update the status row for this plan in `plans/README.md` unless a reviewer told you they maintain the index.
>
> **Drift check (run first)**: `git diff --stat 0c6e6f7..HEAD -- Scarb.toml scripts README.md DEPLOYMENT.md plans/README.md`
> If any in-scope file changed since this plan was written, compare the "Current state" excerpts against the live code before proceeding. On a mismatch, treat it as a STOP condition.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: dx
- **Planned at**: commit `0c6e6f7`, 2026-07-06

## Why this matters

`Scarb.toml` advertises package scripts that point to files that are not present in this repo. That creates avoidable onboarding friction and makes `scarb run deploy`, `scarb run declare`, and `scarb run len` unreliable. The repo already has a tracked deployment script, so the manifest should either point at that script or remove stale entries.

## Current state

- `Scarb.toml` defines four scripts.
- Only `scripts/deploy-starknet.sh` is tracked under `scripts/`.
- README does not document `scarb run` usage; `DEPLOYMENT.md` documents direct script usage.

Current excerpts:

```toml
# Scarb.toml:30-34
[scripts]
test = "snforge test"
declare = "sh scripts/sepolia/declare.sh"
deploy = "sh scripts/sepolia/deploy.sh"
len = "sh scripts/sierra_len.sh"
```

```text
# tracked scripts
scripts/deploy-starknet.sh
```

Repo conventions to follow:

- Build/test/fmt commands are in CI as raw commands, not Scarb scripts.
- Deployment docs use `./scripts/deploy-starknet.sh local` and related direct invocations.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Inspect scripts | `find scripts -maxdepth 3 -type f -print | sort` | lists tracked scripts |
| Format | `scarb fmt --check` | exit 0 |
| Build | `scarb build` | exit 0 |
| Tests | `snforge test` | all tests pass |

## Scope

**In scope**:

- `Scarb.toml`
- `DEPLOYMENT.md` if script invocation docs need a small correction
- `plans/README.md`

**Out of scope**:

- Creating new deployment scripts for Sepolia or mainnet
- Rewriting `scripts/deploy-starknet.sh`
- Changing CI workflows

## Git workflow

- Branch: `advisor/004-repair-stale-scarb-scripts`
- Commit style observed in history: imperative/conventional, for example `chore: docs cleanup`.
- Do not push or open a PR unless the operator instructed it.

## Steps

### Step 1: Choose the conservative script manifest fix

Update `Scarb.toml` so no script points to a missing path.

Recommended change:

- Keep `test = "snforge test"`.
- Replace `deploy = "sh scripts/sepolia/deploy.sh"` with a script that prints usage or runs the tracked deployment script only when an environment is supplied, if Scarb supports argument forwarding in this repo.
- If clean argument forwarding is not available, remove `declare`, `deploy`, and `len` from `[scripts]` and leave deployment documented through `DEPLOYMENT.md`.

Do not invent missing `scripts/sepolia/*` files in this plan.

**Verify**: `find scripts -maxdepth 3 -type f -print | sort` -> every remaining script path in `Scarb.toml` exists, except commands that are installed tools such as `snforge`.

### Step 2: Adjust deployment docs only if needed

If `Scarb.toml` no longer has deploy scripts, make sure `DEPLOYMENT.md` continues to show direct usage of `./scripts/deploy-starknet.sh`. If it already does, do not edit docs.

**Verify**: `rg -n "scripts/sepolia|sierra_len|scarb run deploy|deploy-starknet" Scarb.toml DEPLOYMENT.md README.md` -> no stale missing paths remain in `Scarb.toml`.

### Step 3: Run gates and update index

**Verify**:

- `scarb fmt --check` -> exit 0
- `scarb build` -> exit 0
- `snforge test` -> all tests pass
- `git status --short` -> only in-scope files are modified

Update `plans/README.md` status for this plan to `DONE` only after verification passes.

## Test plan

- No new Cairo tests are needed for manifest cleanup.
- Verification is command-based: no stale script paths in `Scarb.toml`, plus the standard gates.

## Done criteria

- [ ] `Scarb.toml` has no script entries pointing to missing repository files.
- [ ] Deployment docs remain accurate.
- [ ] `scarb fmt --check`, `scarb build`, and `snforge test` pass.
- [ ] No files outside the in-scope list are modified.
- [ ] `plans/README.md` status row updated.

## STOP conditions

Stop and report if:

- The maintainer wants `scarb run deploy` to remain as a supported public workflow but Scarb argument forwarding is unclear.
- Fixing scripts requires adding new environment-specific deployment code.
- Verification fails twice after reasonable fix attempts.

## Maintenance notes

Keep the package manifest limited to commands that can run from a fresh clone. Deployment behavior should live in one script path and be documented in `DEPLOYMENT.md`.
