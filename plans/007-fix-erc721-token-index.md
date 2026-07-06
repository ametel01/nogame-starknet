# Plan 007: Keep ERC721 token_of index consistent on transfers

> **Drift check (run first)**: `git diff --stat a370d98..HEAD -- src/token/erc721/erc721_ng.cairo src/token/erc721/interface.cairo tests/test_erc721.cairo`

## Status

- **Priority**: P2
- **Effort**: S/M
- **Risk**: MED
- **Depends on**: none
- **Category**: bug
- **Planned at**: commit `a370d98`, 2026-07-06

## Why This Matters

Gameplay identifies a user's home planet through `token_of(account)`. Transfers currently write the recipient's index but do not clear the sender, and camel-case `safeTransferFrom` does not update the index at all. A transferred-out account can retain stale gameplay identity.

## Current State

```cairo
// src/token/erc721/erc721_ng.cairo:97
self.erc721.safe_transfer_from(from, to, token_id, data);
self.tokens.write(to, token_id)
```

```cairo
// src/token/erc721/erc721_ng.cairo:143
self.erc721.safe_transfer_from(from, to, tokenId, data);
```

```cairo
// src/planet/contract.cairo:443
fn get_owned_planet(self: @ContractState, account: ContractAddress) -> u32 {
    tokens.erc721.token_of(account).try_into().unwrap()
}
```

## Commands You Will Need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Focused tests | `snforge test test_erc721_nogame_transfers_and_approvals` | exit 0 |
| Format | `scarb fmt --check` | exit 0 |
| Build | `scarb build` | exit 0 |
| Full tests | `snforge test` | exit 0 |

## Scope

**In scope**:
- `src/token/erc721/erc721_ng.cairo`
- `tests/test_erc721.cairo`

**Out of scope**:
- Generic `src/token/erc721/erc721.cairo` preset unless tests prove it is used for NoGame ownership
- Marketplace/approval policy changes
- Planet transfer restrictions

## Steps

### Step 1: Centralize token index updates

Add a private helper that updates `tokens` after successful transfer:
- if `self.tokens.read(from) == token_id`, clear `from` to zero,
- write `to -> token_id`.

Use it from snake-case and camel-case `transfer` and `safe_transfer` methods.

**Verify**: `scarb build` -> exit 0.

### Step 2: Fix camel-case safe transfer

Ensure `safeTransferFrom` mirrors `safe_transfer_from` by updating `tokens` after the OpenZeppelin transfer succeeds.

**Verify**: `scarb build` -> exit 0.

### Step 3: Update tests

Update `tests/test_erc721.cairo` to assert:
- after transferring token 1 from `ACCOUNT1` to `ACCOUNT2`, `token_of(ACCOUNT2()) == 1`,
- after transferring token 2 from `ACCOUNT1` to `ACCOUNT3`, `token_of(ACCOUNT3()) == 2`,
- if `ACCOUNT1` no longer owns the indexed token, its `token_of` does not still point at a token it transferred away.

If the existing test mints multiple tokens to one account and that conflicts with one-home-planet semantics, adjust test expectations to document the supported invariant.

**Verify**: `snforge test test_erc721_nogame_transfers_and_approvals` -> exit 0.

## Test Plan

- Focused ERC721 transfer tests.
- Full suite to catch gameplay ownership assumptions.

## Done Criteria

- [ ] All transfer variants keep `token_of` consistent.
- [ ] Sender stale index regression is covered.
- [ ] `scarb fmt --check`, `scarb build`, and `snforge test` exit 0.
- [ ] `plans/README.md` status row updated.

## STOP Conditions

- STOP if the intended invariant is that an account may own multiple NoGame planets and `token_of` must return a specific one.
- STOP if fixing the index requires replacing OpenZeppelin ERC721 internals.

## Maintenance Notes

Review future NFT changes for consistency between OpenZeppelin ownership and the custom `tokens` index.
