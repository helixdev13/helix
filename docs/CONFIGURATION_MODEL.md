# Helix Configuration Model

## Summary

Helix does not yet implement an on-chain configuration registry beyond the accepted contracts.

This document defines the minimal repo-level configuration surface to keep chain, venue, and
deployment assumptions explicit while the architecture is frozen.

Related docs:

- [DEPLOYMENT.md](./DEPLOYMENT.md)
- [TESTNET_RUNBOOK.md](./TESTNET_RUNBOOK.md)
- [PORTABILITY.md](./PORTABILITY.md)

## Purpose

The configuration model should answer four questions cleanly:

- which chain is being targeted
- which asset and oracle assumptions are in scope
- which venue or adapter family is intended
- which deployed addresses and operating limits are active

## Recommended Structure

If Helix starts persisting chain or venue configuration in-repo, keep it minimal and explicit:

```text
config/
  chains/
    bsc-testnet.md
    bsc-mainnet.md
    citrea-mainnet.md
  venues/
    mock-cl.md
    pancake-cl.md        # future
    thena-cl.md          # future
  deployments/
    bsc-testnet/
      core.md
      mock-vault.md
  citrea/
    README.md
    mainnet.md
```

Markdown is sufficient for now because the current need is reviewability, not automation.

If machine-readable config becomes necessary later, add it alongside these notes rather than
replacing them immediately.

## Minimal Configuration Categories

### Chain Profile

Each chain note should capture:

- chain name
- chain id
- rpc assumptions
- native gas asset
- wrapped base asset model
- common stablecoins
- oracle coverage expectations
- operational caveats

### Venue Profile

Each venue note should capture:

- venue type
- position model
- quote/execution assumptions
- liquidity withdrawal assumptions
- oracle dependencies
- adapter implementation status

### Deployment Profile

Each deployment note should capture:

- deployed contract addresses
- owner addresses
- guardian addresses
- selected strategy and adapter pairing
- risk config values
- known limitations

## Current Effective Configuration Surface

Today the effective configuration surface is split across:

- Foundry env vars in deployment scripts
- docs in `docs/`
- test setup inside Foundry test contracts

That is acceptable during the freeze because:

- the protocol is still mock-only below the strategy boundary
- there is no live venue integration yet
- chain and market direction are still being decided

## What Should Stay Out Of Scope For Now

Do not add these until a real venue path exists:

- a generic on-chain config registry
- per-chain Solidity constants libraries
- automatic adapter discovery
- large JSON manifests with no runtime consumer
- cross-chain abstraction layers inside the vault

## Suggested First Real Config Files Later

When Helix needs persistent deployment state, the first useful artifacts are likely:

- `config/deployments/<chain>/core.md`
- `config/deployments/<chain>/<vault-name>.md`
- `config/chains/<chain>.md`

Those notes should be human-reviewable first and can be mirrored into machine-readable files only
if automation later requires it.

## Freeze Note

This document defines a documentation-level configuration model only.

It introduces no protocol logic and does not alter accepted contract semantics.
