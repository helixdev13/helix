# Helix Status

## Current Phase

Helix is in:

- frozen live deployment maintenance
- deployed auto-compound stack maintenance
- v2 allocator-foundation development
- venue-agnostic flagship build planning

The frozen live Citrea deployment exists already, and the deployed auto-compound stack is now live but disabled by default.

## Frozen Live State

### Citrea live lane

- `HelixVault` accounting model
- `RiskEngine` policy model
- `OracleRouter`
- `VaultFactory`
- `ManagedClStrategy`
- `JuiceSwapClAdapter`

- venue: `JuiceSwap`
- live lane: `USDC.e / wcBTC`
- fee tier: `3000`
- one approved pool
- one adapter deployment
- deployment complete
- ownership accepted
- strategy attached
- disabled by default

## Current Safety Posture

- `maxAllocationBps = 0`
- `paused = false`
- `withdrawOnly = false`
- no productive allocation enabled

## Current v2 Direction

Helix v2 is now defined as:

- a Citrea-native yield optimizer / aggregator
- flagship first product: `HLX-USDC.e Smart Vault`
- deployed flagship CL lane: auto-compound `USDC.e / wcBTC`
- strategy family in progress: generic allocator lane
- first non-CL venue work: blocked until venue approval clears

The current deployed `JuiceSwap` stack remains untouched while this work proceeds.

## Current Build Status

- allocator foundation exists in code
- auto-compound Citrea deployment has been executed onchain
- auto-compound ownership handoff has been completed
- venue-specific non-CL adapter work has not started
- the frozen live `JuiceSwap` path remains untouched
- the deployed auto-compound stack is the current product-facing deployed lane

## Immediate Next Engineering Focus

- harden and extend the generic allocator foundation
- keep the deployed auto-compound stack disabled by default until any deliberate enablement review
- preserve venue-agnostic strategy and adapter boundaries
- do not start a real `Zentra` or other venue adapter until diligence clears
- do not modify the frozen live deployment path as part of v2 work

## Current Source-Of-Truth Docs

- [CURRENT_DEPLOYED_STATE.md](./CURRENT_DEPLOYED_STATE.md)
- [JUICESWAP_OPERATOR_HANDOFF.md](./JUICESWAP_OPERATOR_HANDOFF.md)
- [JUICESWAP_LIVE_RUNBOOK.md](./JUICESWAP_LIVE_RUNBOOK.md)
- [JUICESWAP_ORACLE_FREEZE.md](./JUICESWAP_ORACLE_FREEZE.md)
- [CITREA_MAINNET_PREREQUISITES.md](./CITREA_MAINNET_PREREQUISITES.md)
- [HELIX_V2_LAUNCH_CHECKLIST.md](./HELIX_V2_LAUNCH_CHECKLIST.md)
- [config/citrea/juiceswap_usdce_wcbtc_candidate.md](../config/citrea/juiceswap_usdce_wcbtc_candidate.md)
- [HELIX_MASTER_ROADMAP.md](./HELIX_MASTER_ROADMAP.md)
- [DeployCitreaAutoCompoundVault.s.sol](../contracts/script/DeployCitreaAutoCompoundVault.s.sol)
- [HelixLens.sol](../contracts/src/periphery/HelixLens.sol)
- [AutoCompoundClStrategy.sol](../contracts/src/strategies/AutoCompoundClStrategy.sol)
- [RewardDistributor.sol](../contracts/src/periphery/RewardDistributor.sol)
- [JuiceSwapClAdapter.sol](../contracts/src/adapters/JuiceSwapClAdapter.sol)
