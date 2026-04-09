# Helix Status

## Current Phase

Helix is in:

- release packaging
- Citrea launch-candidate preparation
- public repo migration prep

This is not yet a production deployment phase.

## Accepted State

### Core

- `HelixVault` accounting model
- `RiskEngine` policy model
- `OracleRouter`
- `VaultFactory`
- `ManagedClStrategy`
- `JuiceSwapClAdapter`

### Citrea release path

- first release: `HLX-ctUSD Base`
- release posture: strategy unset
- `maxAllocationBps = 0`

### Citrea live-candidate path

- venue: `JuiceSwap`
- live candidate: `USDC.e / wcBTC`
- fee tier: `3000`
- one approved pool
- one adapter deployment
- disabled by default until explicit enable conditions are met

## Not Production-Ready Yet

The following are still not complete:

- no same-day mainnet verification run has been completed
- no production wallet / multisig set has been frozen in repo docs
- no live broadcast has been executed from the packaged scripts
- no live productive allocation has been enabled
- no post-deploy operational rehearsal has been completed with real operator addresses

## Next Milestone

Recommended next milestone:

- final broadcast rehearsal and go/no-go review for the accepted `USDC.e / wcBTC` live candidate

That milestone should be operational, not architectural.

## What Must Happen Before Mainnet Deployment

Before any mainnet broadcast:

- finalize deployer, owner, and guardian addresses
- fund deployer with sufficient `cBTC`
- verify live oracle paths for `USDC.e` and `wcBTC`
- re-verify the approved `JuiceSwap` pool and fee tier on the same day
- rerun the targeted candidate tests
- confirm the initial cap and disabled-by-default posture
- confirm the owner and guardian runbooks are ready

## Current Source-Of-Truth Docs

- [JUICESWAP_LIVE_RUNBOOK.md](./JUICESWAP_LIVE_RUNBOOK.md)
- [CITREA_MAINNET_PREREQUISITES.md](./CITREA_MAINNET_PREREQUISITES.md)
- [CITREA_INTEGRATION_PLAN.md](./CITREA_INTEGRATION_PLAN.md)
- [JUICESWAP_LAUNCH_CONSTRAINTS.md](./JUICESWAP_LAUNCH_CONSTRAINTS.md)
- [config/citrea/juiceswap_usdce_wcbtc_candidate.md](../config/citrea/juiceswap_usdce_wcbtc_candidate.md)
