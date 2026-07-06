# Plan 014: Harden deployment environment handling

> **Executor instructions**: Follow this plan step by step. Run every verification command and confirm the expected result before moving to the next step. If anything in the "STOP conditions" section occurs, stop and report -- do not improvise. When done, update the status row for this plan in `plans/README.md` unless a reviewer dispatched you and told you they maintain the index.
>
> **Drift check (run first)**: `git diff --stat a370d98..HEAD -- scripts/deploy-starknet.sh .env.local.example .env.docker.example DEPLOYMENT.md`
> If any in-scope file changed since this plan was written, compare the "Current state" excerpts against the live code before proceeding; on a mismatch, treat it as a STOP condition.

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: MED
- **Depends on**: plans/009-clean-deployment-docs.md
- **Category**: security
- **Planned at**: commit `a370d98`, 2026-07-06

## Why this matters

The deployment script is a privileged local tool: it reads account material, calls `starkli`, and writes deployment addresses into environment files. It currently executes `.env.*` contents as shell code and builds command lines with unquoted variables. That is acceptable only for fully trusted local files, but it is fragile and makes accidental malformed values or copied env content much more dangerous than necessary.

## Current state

- `scripts/deploy-starknet.sh` -- one-shot deployment script for local/docker/testnet/mainnet.
- `.env.local.example` and `.env.docker.example` -- example deployment env files. They currently contain deterministic Katana key-looking values; plan 009 cleans those docs/examples first.
- `DEPLOYMENT.md` -- user-facing deployment instructions.

The script creates env files when missing, then sources the primary file:

```bash
# scripts/deploy-starknet.sh:72-83
for env_file in "${ENV_FILES[@]}"; do
    if [ ! -f "$env_file" ]; then
        echo "Creating environment file $env_file"
        touch "$env_file"
    fi
done

# Source the primary environment file if it has content
if [ -s "${ENV_FILES[0]}" ]; then
    source "${ENV_FILES[0]}"
fi
```

It stores the private-key option as one string and expands it unquoted across every `starkli` call:

```bash
# scripts/deploy-starknet.sh:90-95
if [ -z "$STARKNET_PRIVATE_KEY" ]; then
    echo -e "${RED}Error: STARKNET_PRIVATE_KEY not set in ${ENV_FILES[0]}${NC}"
    exit 1
fi
PRIVATE_KEY_FLAG="--private-key $STARKNET_PRIVATE_KEY"
```

Example command construction is repeated many times:

```bash
# scripts/deploy-starknet.sh:134
GAME_HASH=$(starkli declare ./target/dev/nogame_Game.contract_class.json --account $STARKNET_ACCOUNT --rpc $STARKNET_RPC_URL $PRIVATE_KEY_FLAG -w 2>&1 | grep -o '0x[a-fA-F0-9]\{64\}' | head -1)
```

Repo conventions to match:

- Shell script uses Bash, `set -e`, uppercase env variable names, and simple helper functions.
- Deployment docs mention `./scripts/deploy-starknet.sh local` and `./scripts/deploy-starknet.sh docker`.
- Do not reproduce private key values in commits, issues, or plan updates. Refer to credential locations and types only.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Shell syntax | `bash -n scripts/deploy-starknet.sh` | exit 0 |
| Unsafe env sourcing check | `rg -n 'source \"\\$\\{ENV_FILES\\[0\\]\\}\"|PRIVATE_KEY_FLAG=\"--private-key|\\$PRIVATE_KEY_FLAG' scripts/deploy-starknet.sh` | no matches |
| Concrete key check | `rg -n 'PRIVATE_KEY=.*0x|STARKNET_PRIVATE_KEY=.*0x' .env*.example DEPLOYMENT.md` | no concrete key values after plan 009 |
| Format guard | `scarb fmt --check` | exit 0 |

## Scope

**In scope**:

- `scripts/deploy-starknet.sh`
- `DEPLOYMENT.md` only for usage notes if the script interface changes
- `.env.local.example` and `.env.docker.example` only if plan 009 has not already removed concrete keys

**Out of scope**:

- Contract deployment order
- Contract constructor arguments
- Starkli account setup outside this script
- Real untracked `.env.*` files
- Replacing the shell script with another language

## Git workflow

- Branch: `advisor/014-harden-deployment-env-handling`
- Commit message style: imperative sentence matching repo history, for example `Harden deployment env handling`.
- Do not push or open a PR unless the operator instructed it.

## Steps

### Step 1: Replace `source` with a strict env parser

In `scripts/deploy-starknet.sh`, add a small helper that reads only simple `KEY=VALUE` lines from the selected env file:

- Ignore blank lines and lines beginning with `#`.
- Accept only variable names matching `^[A-Z0-9_]+$`.
- Export or assign only the known variables this script uses: `STARKNET_PRIVATE_KEY`, `STARKNET_ACCOUNT`, `STARKNET_RPC_URL`, `STARKNET_ACCOUNT_ADDRESS`, and existing address variables if needed.
- Strip one surrounding pair of single or double quotes if present; do not evaluate command substitutions, backticks, `$()`, or shell escapes.
- Fail with a clear message if an unsupported non-comment line is present.

Do not use `eval`. Do not use `source`.

**Verify**: `bash -n scripts/deploy-starknet.sh` -> exit 0.

### Step 2: Use arrays for optional private-key flags

Replace `PRIVATE_KEY_FLAG="--private-key $STARKNET_PRIVATE_KEY"` with a Bash array, for example:

```bash
PRIVATE_KEY_ARGS=()
...
PRIVATE_KEY_ARGS=(--private-key "$STARKNET_PRIVATE_KEY")
```

Then update every `starkli` command to pass `"${PRIVATE_KEY_ARGS[@]}"` and quote all variable expansions such as `"$STARKNET_ACCOUNT"`, `"$STARKNET_RPC_URL"`, `"$DEPLOYER_ADDRESS"`, `"$GAME_HASH"`, and deployed addresses.

Prefer adding tiny helper functions for repeated `starkli declare` / `starkli deploy` patterns if that reduces duplicated command construction without changing behavior.

**Verify**: `rg -n 'PRIVATE_KEY_FLAG=\"--private-key|\\$PRIVATE_KEY_FLAG' scripts/deploy-starknet.sh` -> no matches.

### Step 3: Make command failures explicit

The current command substitutions pipe `starkli` output into `grep`/`head`, which can hide failure context. Add `set -o pipefail` near `set -e`, and make declare/deploy helpers print a clear error if no class hash/address is parsed.

Keep output values redacted only where they are credentials. Contract addresses and class hashes are safe to print.

**Verify**: `bash -n scripts/deploy-starknet.sh` -> exit 0.

### Step 4: Update docs only if behavior changed for users

If the env parser now rejects shell-style lines that docs previously allowed, update `DEPLOYMENT.md` with a short note that `.env.*` files must contain plain `KEY=VALUE` lines. Do not include private key values.

**Verify**: `rg -n 'source|eval|shell code' DEPLOYMENT.md scripts/deploy-starknet.sh` -> no docs instruct users to rely on sourced shell behavior; script contains no `source` or `eval`.

### Step 5: Run final gates

Run syntax and repo guard checks.

**Verify**:

- `bash -n scripts/deploy-starknet.sh` -> exit 0
- `rg -n 'source "\$\{ENV_FILES\[0\]\}"|PRIVATE_KEY_FLAG="--private-key|\$PRIVATE_KEY_FLAG' scripts/deploy-starknet.sh` -> no matches
- `scarb fmt --check` -> exit 0

## Test plan

- Add no contract tests; this is a shell tooling change.
- Syntax-check the script with `bash -n`.
- Manually exercise only if the operator provides a safe local Katana environment. Do not run deployments against remote networks as part of this plan.
- If helper functions are added, test parser behavior by using temporary env files outside the repo or ignored local env files only. Do not commit generated env files.

## Done criteria

- [ ] `scripts/deploy-starknet.sh` no longer uses `source` or `eval` for env files.
- [ ] Private-key flags are built with an array, not a single interpolated string.
- [ ] `starkli` invocations quote variable arguments.
- [ ] `set -o pipefail` or equivalent explicit failure handling is present.
- [ ] `bash -n scripts/deploy-starknet.sh` exits 0.
- [ ] `scarb fmt --check` exits 0.
- [ ] No private key values are added to tracked files.
- [ ] `plans/README.md` status row updated.

## STOP conditions

Stop and report back if:

- Plan 009 has not removed concrete key values from tracked docs/examples and you would need to touch those values directly.
- The script has been replaced or significantly rewritten since `a370d98`.
- Safe parsing would require supporting shell features such as command substitution or variable expansion.
- A deployment must be run against Sepolia or mainnet to verify the change.
- A verification command fails twice after a reasonable fix attempt.

## Maintenance notes

Reviewers should scrutinize every `starkli` invocation for quoted variables and array expansion. Future deployment options should be added as arrays from the start; shell strings containing multiple flags are the pattern this plan removes.
