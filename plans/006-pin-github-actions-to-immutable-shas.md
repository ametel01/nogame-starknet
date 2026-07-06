# Plan 006: Pin GitHub Actions to immutable SHAs

> **Executor instructions**: Follow this plan step by step. Run every verification command and confirm the expected result before moving to the next step. If anything in the "STOP conditions" section occurs, stop and report; do not improvise. When done, update the status row for this plan in `plans/README.md` unless a reviewer told you they maintain the index.
>
> **Drift check (run first)**: `git diff --stat 0c6e6f7..HEAD -- .github/workflows/build.yml .github/workflows/test.yml .github/workflows/format.yml plans/README.md`
> If any in-scope file changed since this plan was written, compare the "Current state" excerpts against the live code before proceeding. On a mismatch, treat it as a STOP condition.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: security
- **Planned at**: commit `0c6e6f7`, 2026-07-06

## Why this matters

The CI workflows use mutable action tags such as `actions/checkout@v4`. That is common, but smart-contract repositories benefit from stronger supply-chain hygiene. Pinning actions to immutable commit SHAs reduces the risk of upstream tag movement changing the build, test, or format environment unexpectedly.

## Current state

- Build, test, and format workflows all use tag-based actions.
- Tool versions for Scarb and snfoundry are already pinned through environment variables.

Current excerpts:

```yaml
# .github/workflows/build.yml:12-15
- uses: actions/checkout@v4
- uses: software-mansion/setup-scarb@v1
  with:
    scarb-version: ${{ env.SCARB_VERSION }}
```

```yaml
# .github/workflows/test.yml:17-19
- uses: foundry-rs/setup-snfoundry@v4
  with:
    starknet-foundry-version: ${{ env.SNFORGE_VERSION }}
```

Repo conventions to follow:

- Workflows are simple one-job YAML files.
- Keep `SCARB_VERSION` and `SNFORGE_VERSION` unchanged.
- Prefer comments next to pinned SHAs naming the source tag for maintainability.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Inspect workflows | `rg -n "uses:" .github/workflows` | every action use is visible |
| Format | `scarb fmt --check` | exit 0 |
| Build | `scarb build` | exit 0 |
| Tests | `snforge test` | all tests pass |

## Scope

**In scope**:

- `.github/workflows/build.yml`
- `.github/workflows/test.yml`
- `.github/workflows/format.yml`
- `plans/README.md`

**Out of scope**:

- Changing CI topology or adding new jobs
- Updating Scarb or snfoundry versions
- Adding third-party pinning tooling

## Git workflow

- Branch: `advisor/006-pin-github-actions-to-immutable-shas`
- Commit style observed in history: imperative/conventional, for example `chore: docs cleanup`.
- Do not push or open a PR unless the operator instructed it.

## Steps

### Step 1: Resolve current action SHAs

For each action tag in workflows, resolve the exact commit SHA from the upstream repository:

- `actions/checkout@v4`
- `software-mansion/setup-scarb@v1`
- `foundry-rs/setup-snfoundry@v4`

Use a trusted source such as `gh api repos/<owner>/<repo>/git/ref/tags/<tag>` or the GitHub web UI. If using a command, do not print secrets and do not modify the repo.

**Verify**: record the owner/repo, tag, and SHA in your notes before editing.

### Step 2: Replace tags with SHAs

Update every `uses:` entry to use the resolved SHA. Add a short YAML comment above or beside each action with the human-readable tag, for example:

```yaml
# actions/checkout v4
- uses: actions/checkout@<sha>
```

Keep all workflow behavior and tool versions unchanged.

**Verify**: `rg -n "uses: .*@(v[0-9]|main|master)" .github/workflows` -> no mutable action refs remain.

### Step 3: Run local gates and update index

Local commands cannot fully validate GitHub's remote action resolution, but the repo gates should still pass.

**Verify**:

- `scarb fmt --check` -> exit 0
- `scarb build` -> exit 0
- `snforge test` -> all tests pass
- `git status --short` -> only in-scope files are modified

Update `plans/README.md` status for this plan to `DONE` only after verification passes.

## Test plan

- No Cairo tests are needed.
- Verification is workflow inspection plus standard local gates.
- If the operator can run GitHub Actions, check the next CI run for all three workflows.

## Done criteria

- [ ] No workflow uses mutable action tags.
- [ ] Each pinned SHA has an adjacent comment naming the original action tag.
- [ ] Scarb and snfoundry versions are unchanged.
- [ ] `scarb fmt --check`, `scarb build`, and `snforge test` pass locally.
- [ ] No files outside the in-scope list are modified.
- [ ] `plans/README.md` status row updated.

## STOP conditions

Stop and report if:

- You cannot verify the upstream SHA for an action tag.
- A workflow uses a local or reusable workflow syntax not covered by this plan.
- Pinning reveals an action tag with ambiguous or missing upstream refs.
- Verification fails twice after reasonable fix attempts.

## Maintenance notes

Pinned SHAs trade automatic action updates for reproducibility. Future maintainers should periodically update the SHAs intentionally and note the source tag in the PR.
