# Plan 008: Add multi-universe deployment manifest

> **Executor instructions**: Follow this plan step by step. Run every verification command and confirm the expected result before moving to the next step. If anything in the "STOP conditions" section occurs, stop and report; do not improvise. When done, update the status row for this plan in `plans/README.md` unless a reviewer told you they maintain the index.
>
> **Drift check (run first)**: `git diff --stat 0c6e6f7..HEAD -- docs/universe-lifecycle-spike.md DEPLOYMENT.md scripts/deploy-starknet.sh README.md deployments Scarb.toml plans/README.md`
> If any in-scope file changed since this plan was written, compare the "Current state" excerpts against the live code before proceeding. On a mismatch, treat it as a STOP condition.

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: LOW
- **Depends on**: none
- **Category**: direction
- **Planned at**: commit `0c6e6f7`, 2026-07-06

## Why this matters

The roadmap says the game should deploy a new universe periodically, and the lifecycle spike recommends redeploying all contracts first rather than adding a registry or factory. The current deployment flow persists only one active address set into singular env keys, so a new deployment can overwrite the previous universe pointers unless an operator manually saves them elsewhere. A tracked manifest example and validation path make the redeploy-all lifecycle auditable without changing contract storage.

## Current state

- `docs/universe-lifecycle-spike.md` recommends redeploy-all plus a small offchain manifest.
- `DEPLOYMENT.md` documents singular env keys for current contract addresses.
- `scripts/deploy-starknet.sh` writes singular env vars such as `GAME_ADDRESS`, `PLANET_ADDRESS`, and token addresses.
- No `deployments/` manifest example exists.

Current excerpts:

```markdown
<!-- docs/universe-lifecycle-spike.md:37-39 -->
The persisted keys are singular: `GAME_ADDRESS`, `PLANET_ADDRESS`, ...
There is no persisted `UNIVERSE_ID`, no history of previous universes...
```

```markdown
<!-- docs/universe-lifecycle-spike.md:121-125 -->
Add a design-backed deployment manifest slice:
1. Define a tracked example manifest schema such as `deployments/universes.example.json` ...
2. Update deployment documentation ...
3. Add a script-level dry-run or fixture check ...
```

```bash
# scripts/deploy-starknet.sh:21-33
update_env_var() {
    local env_file=$1
    local var_name=$2
    local var_value=$3
    ...
}
```

Repo conventions to follow:

- Deployment docs live in `DEPLOYMENT.md`.
- Do not introduce onchain registry/factory code in this slice.
- Keep examples free of private keys or real credentials.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Inspect manifest mentions | `rg -n "UNIVERSE_ID|universes|manifest|GAME_ADDRESS" DEPLOYMENT.md docs scripts README.md deployments` | expected manifest docs are visible |
| JSON validation | `python3 -m json.tool deployments/universes.example.json >/dev/null` | exit 0 |
| Format | `scarb fmt --check` | exit 0 |
| Build | `scarb build` | exit 0 |
| Tests | `snforge test` | all tests pass |

## Scope

**In scope**:

- `deployments/universes.example.json` (create)
- `DEPLOYMENT.md`
- `scripts/deploy-starknet.sh` only if adding a non-invasive validation/help mode is needed
- `plans/README.md`

**Out of scope**:

- Onchain universe registry or factory
- Contract storage changes
- Frontend/indexer implementation
- Writing real deployment addresses to tracked files
- Handling secrets or private keys

## Git workflow

- Branch: `advisor/008-add-multi-universe-deployment-manifest`
- Commit style observed in history: imperative/conventional, for example `Document multi-universe lifecycle options`.
- Do not push or open a PR unless the operator instructed it.

## Steps

### Step 1: Add a tracked manifest example

Create `deployments/universes.example.json` with a schema-like example that can hold at least two universes. Use placeholder addresses only.

Include these fields per universe:

- `universe_id`
- `network`
- `deployed_at`
- `rpc_url`
- `uni_speed`
- `token_price`
- `universe_start_time`
- `contracts`: `game`, `planet`, `colony`, `compound`, `defence`, `dockyard`, `fleet`, `tech`
- `tokens`: `erc721`, `steel`, `quartz`, `tritium`, `eth`

Do not include private keys, account private material, or real secrets.

**Verify**: `python3 -m json.tool deployments/universes.example.json >/dev/null` -> exit 0.

### Step 2: Update deployment documentation

In `DEPLOYMENT.md`, add a short section near "Deployment Artifacts" or "Post-Deployment" that says:

- Env files remain the active local pointer for the latest deployment.
- Before overwriting env pointers for a new universe, operators must append the old and new address sets to a universe manifest based on `deployments/universes.example.json`.
- The manifest is the frontend/indexer handoff for multi-universe selection.

Keep this as documentation; do not claim the script writes the manifest unless you implement that.

**Verify**: `rg -n "universes.example.json|UNIVERSE_ID|manifest|GAME_ADDRESS" DEPLOYMENT.md deployments/universes.example.json` -> manifest guidance is present.

### Step 3: Add optional validation helper only if it stays small

If useful and low-risk, add a `--print-manifest-template` or `--validate-manifest <path>` mode to `scripts/deploy-starknet.sh`. This is optional. Prefer docs plus JSON example if script changes would become broad.

If you add a script mode, it must not contact a network, build contracts, or touch env files.

**Verify** if script mode is added: run the mode and confirm it exits 0 without modifying files.

### Step 4: Run gates and update index

**Verify**:

- `python3 -m json.tool deployments/universes.example.json >/dev/null` -> exit 0
- `scarb fmt --check` -> exit 0
- `scarb build` -> exit 0
- `snforge test` -> all tests pass
- `git status --short` -> only in-scope files are modified

Update `plans/README.md` status for this plan to `DONE` only after verification passes.

## Test plan

- JSON example validates with `python3 -m json.tool`.
- No Cairo tests are needed unless script behavior changes.
- Standard repo gates still pass.

## Done criteria

- [ ] `deployments/universes.example.json` exists, is valid JSON, and contains no secrets.
- [ ] `DEPLOYMENT.md` documents how to preserve multiple universe address sets before env files are overwritten.
- [ ] No onchain registry/factory/storage changes are introduced.
- [ ] `scarb fmt --check`, `scarb build`, and `snforge test` pass.
- [ ] No files outside the in-scope list are modified.
- [ ] `plans/README.md` status row updated.

## STOP conditions

Stop and report if:

- The operator wants the deployment script to automatically write real manifest entries during live deploys; that is a larger operational change.
- You discover real secrets or private keys in candidate manifest data.
- The frontend/indexer requires a different manifest shape and no owner can decide the schema.
- Verification fails twice after reasonable fix attempts.

## Maintenance notes

This plan intentionally keeps universe identity offchain. If a future deployment uses this manifest successfully, that real manifest should inform any later onchain registry or factory design.
