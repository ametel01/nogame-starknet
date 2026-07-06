# Plan 011: Design the multi-universe deployment lifecycle

> **Drift check (run first)**: `git diff --stat a370d98..HEAD -- README.md DEPLOYMENT.md scripts/deploy-starknet.sh src/game/contract.cairo Scarb.toml`

## Status

- **Priority**: P3
- **Effort**: M
- **Risk**: LOW
- **Depends on**: plans/006-one-time-game-initialization.md
- **Category**: direction
- **Planned at**: commit `a370d98`, 2026-07-06

## Why This Matters

The roadmap says the project should deploy a new universe each quarter, but the current architecture has a single initialized `Game` registry and a linear deployment script. Before building new deployment features, the project needs a clear decision: redeploy all contracts per universe, create a factory/registry of universes, or version universe state another way.

## Current State

```markdown
// README.md:38
* [ ] **New Features and Updates (Q3-Q4)**
  * Introduce new game elements.
  * Deploy a new universe each quarter of a year.
```

```markdown
// DEPLOYMENT.md:28
The contracts must be deployed in this specific order due to dependencies:
```

```bash
// scripts/deploy-starknet.sh:249
# Initialize Game contract
starkli invoke $GAME_ADDRESS initialize ...
```

`Game` currently stores one set of contract and token addresses.

## Commands You Will Need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Map deployment flow | `rg -n "initialize|deploy|GAME_ADDRESS|universe" README.md DEPLOYMENT.md scripts src/game` | shows current lifecycle |
| Docs check | `rg -n "universe lifecycle|new universe|factory|registry" docs plans` | spike is discoverable |
| Code guard | `scarb build` | exit 0 if code touched |

## Scope

**In scope**:
- A design/spike doc such as `docs/universe-lifecycle-spike.md`
- Optional deployment script notes

**Out of scope**:
- Implementing a universe factory
- Changing deployment scripts without a design decision
- Mainnet migration work

## Steps

### Step 1: Document current lifecycle

Summarize current deployment order, initialization, and address persistence from `DEPLOYMENT.md` and `scripts/deploy-starknet.sh`.

**Verify**: `rg -n "Deployment order|Initialization|Address persistence" docs plans` -> these topics exist in the spike.

### Step 2: Compare lifecycle options

Write trade-offs for at least three options:
- redeploy all contracts per universe,
- add a universe registry/factory,
- add versioned universe configuration while sharing some contracts.

For each, include storage implications, migration risk, frontend/indexer impact, and testing strategy.

**Verify**: spike contains all three option names and trade-off sections.

### Step 3: Recommend the next decision

Recommend one path or one decision checkpoint, not a full implementation. Include the smallest follow-up plan that would validate the chosen path.

**Verify**: spike has a "Recommendation" section and one follow-up slice.

## Test Plan

This is a design/spike plan. No Cairo tests are required unless the executor chooses to prototype code after explicit instruction.

## Done Criteria

- [ ] A universe lifecycle spike doc exists.
- [ ] It cites README, deployment docs, script flow, and `Game` registry shape.
- [ ] It compares at least three options with trade-offs.
- [ ] It recommends one next slice.
- [ ] `plans/README.md` status row updated.

## STOP Conditions

- STOP if plan 006 did not land and initialization semantics are still ambiguous.
- STOP if the operator already has an external roadmap/design doc that contradicts this direction.

## Maintenance Notes

Do not implement multi-universe mechanics until the maintainer has chosen the lifecycle model. The wrong model will create migration debt across every contract and indexer.
