# Plan 005: Resolve license metadata contradiction

> **Executor instructions**: Follow this plan step by step. Run every verification command and confirm the expected result before moving to the next step. If anything in the "STOP conditions" section occurs, stop and report; do not improvise. When done, update the status row for this plan in `plans/README.md` unless a reviewer told you they maintain the index.
>
> **Drift check (run first)**: `git diff --stat 0c6e6f7..HEAD -- Scarb.toml README.md LICENSE plans/README.md`
> If any in-scope file changed since this plan was written, compare the "Current state" excerpts against the live code before proceeding. On a mismatch, treat it as a STOP condition.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW
- **Depends on**: maintainer decision
- **Category**: docs
- **Planned at**: commit `0c6e6f7`, 2026-07-06

## Why this matters

The package manifest says the project is MIT licensed, while the root license text and README point to Creative Commons Attribution-NonCommercial-ShareAlike. That contradiction is risky for downstream users and contributors because the license determines whether the contracts can be reused commercially and how derivative work must be shared. This plan should align metadata and docs to the maintainer's intended license; it should not make a legal decision silently.

## Current state

- `Scarb.toml` sets `license = "MIT"`.
- `LICENSE` begins with Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International.
- `README.md` states the project is under CC BY-NC-SA.

Current excerpts:

```toml
# Scarb.toml:5
license = "MIT"
```

```text
# LICENSE:1
Attribution-NonCommercial-ShareAlike 4.0 International
```

```markdown
<!-- README.md:47-49 -->
### License

This project is under the [CC BY-NC-SA License](https://github.com/ametel01/nogame-starknet/blob/main/LICENSE/README.md).
```

Repo conventions to follow:

- Keep license text in the root `LICENSE` file.
- Keep package metadata in `Scarb.toml`.
- Do not add SPDX headers across the codebase in this small plan.

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Search license mentions | `rg -n "MIT|CC BY|Creative Commons|license" Scarb.toml README.md LICENSE src tests` | all mentions are understood |
| Format | `scarb fmt --check` | exit 0 |
| Build | `scarb build` | exit 0 |
| Tests | `snforge test` | all tests pass |

## Scope

**In scope**:

- `Scarb.toml`
- `README.md`
- `LICENSE` only if the maintainer explicitly chooses MIT and asks to replace the license text
- `plans/README.md`

**Out of scope**:

- Legal advice
- Relicensing without maintainer approval
- Adding per-file license headers
- Changing dependency licenses

## Git workflow

- Branch: `advisor/005-resolve-license-metadata-contradiction`
- Commit style observed in history: imperative/conventional, for example `chore: docs cleanup`.
- Do not push or open a PR unless the operator instructed it.

## Steps

### Step 1: Get or confirm the intended license

If the operator has not already stated the intended license, STOP and ask:

"Should this repository be MIT licensed, or CC BY-NC-SA 4.0 licensed?"

Recommended default if no answer is available: align `Scarb.toml` with the existing root `LICENSE` and README, because those are the more explicit public docs. However, only use that default if the operator authorized non-interactive execution.

**Verify**: no command. This is a maintainer decision gate.

### Step 2: Align metadata and README

If the intended license is CC BY-NC-SA 4.0:

- Change `Scarb.toml` to a valid SPDX expression if Scarb accepts it, likely `license = "CC-BY-NC-SA-4.0"`.
- Fix the README link if needed so it points to the root `LICENSE`, not a non-existent `LICENSE/README.md`.

If the intended license is MIT:

- Replace `LICENSE` with MIT license text only if the maintainer explicitly instructed this.
- Update README to say MIT.
- Leave `Scarb.toml` as MIT.

**Verify**: `rg -n "MIT|CC BY|Creative Commons|LICENSE/README|license" Scarb.toml README.md LICENSE` -> no contradictory license statements remain.

### Step 3: Run gates and update index

**Verify**:

- `scarb fmt --check` -> exit 0
- `scarb build` -> exit 0
- `snforge test` -> all tests pass
- `git status --short` -> only in-scope files are modified

Update `plans/README.md` status for this plan to `DONE` only after verification passes.

## Test plan

- No new Cairo tests are needed.
- Use search and standard gates to confirm metadata consistency.

## Done criteria

- [ ] `Scarb.toml`, `README.md`, and `LICENSE` communicate one license.
- [ ] README license link resolves to an existing repo file.
- [ ] `scarb fmt --check`, `scarb build`, and `snforge test` pass.
- [ ] No files outside the in-scope list are modified.
- [ ] `plans/README.md` status row updated.

## STOP conditions

Stop and report if:

- The intended license is not explicitly known and non-interactive defaulting was not authorized.
- Scarb rejects the intended SPDX license identifier.
- Changing the license would require contributor relicensing approval.
- Verification fails twice after reasonable fix attempts.

## Maintenance notes

Reviewers should focus on consistency, not legal interpretation. If the project intends commercial deployment or open-source reuse, ask a qualified human to confirm the license choice.
