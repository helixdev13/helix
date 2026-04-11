# Helix Status

## Current Phase

Helix is in:

- frozen live deployment maintenance
- deployed auto-compound stack maintenance
- PancakeBunny-style auto-compound product development
- flagship smart-vault build planning

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
- strategy family in progress: auto-compound smart vaults
- later CL work remains a specialist lane

The current deployed `JuiceSwap` stack remains untouched while this work proceeds.

## Current Build Status

- auto-compound Citrea deployment has been executed onchain
- auto-compound ownership handoff has been completed
- USDC.e base-vault ownership handoff scripts have been added
- USDC.e base-vault rehearsal harness has been added
- USDC.e base-vault post-deploy verification script has been added
- the frozen live `JuiceSwap` path remains untouched
- the deployed auto-compound stack is the current product-facing deployed lane

## Immediate Next Engineering Focus

- harden and extend the auto-compound core
- keep the deployed auto-compound stack disabled by default until any deliberate enablement review
- preserve the vault/strategy boundary
- do not modify the frozen live deployment path as part of v2 work

## Current Source-Of-Truth Docs

- [CURRENT_DEPLOYED_STATE.md](./CURRENT_DEPLOYED_STATE.md)
- [JUICESWAP_OPERATOR_HANDOFF.md](./JUICESWAP_OPERATOR_HANDOFF.md)
- [JUICESWAP_LIVE_RUNBOOK.md](./JUICESWAP_LIVE_RUNBOOK.md)
- [JUICESWAP_ORACLE_FREEZE.md](./JUICESWAP_ORACLE_FREEZE.md)
- [CITREA_MAINNET_PREREQUISITES.md](./CITREA_MAINNET_PREREQUISITES.md)
- [HELIX_LAUNCH_CHECKLIST.md](./HELIX_LAUNCH_CHECKLIST.md)
- [config/citrea/juiceswap_usdce_wcbtc_candidate.md](../config/citrea/juiceswap_usdce_wcbtc_candidate.md)
- [HELIX_MASTER_ROADMAP.md](./HELIX_MASTER_ROADMAP.md)
- [DeployCitreaAutoCompoundVault.s.sol](../contracts/script/DeployCitreaAutoCompoundVault.s.sol)
- [TransferCitreaAutoCompoundVaultOwnership.s.sol](../contracts/script/TransferCitreaAutoCompoundVaultOwnership.s.sol)
- [AcceptCitreaAutoCompoundVaultOwnership.s.sol](../contracts/script/AcceptCitreaAutoCompoundVaultOwnership.s.sol)
- [DeployCitreaUsdcBase.s.sol](../contracts/script/DeployCitreaUsdcBase.s.sol)
- [TransferCitreaUsdcBaseOwnership.s.sol](../contracts/script/TransferCitreaUsdcBaseOwnership.s.sol)
- [AcceptCitreaUsdcBaseOwnership.s.sol](../contracts/script/AcceptCitreaUsdcBaseOwnership.s.sol)
- [VerifyCitreaUsdcBasePostDeploy.s.sol](../contracts/script/VerifyCitreaUsdcBasePostDeploy.s.sol)
- [CitreaUsdcBaseScripts.t.sol](../contracts/test/CitreaUsdcBaseScripts.t.sol)
- [HelixLens.sol](../contracts/src/periphery/HelixLens.sol)
- [AutoCompoundClStrategy.sol](../contracts/src/strategies/AutoCompoundClStrategy.sol)
- [RewardDistributor.sol](../contracts/src/periphery/RewardDistributor.sol)
- [JuiceSwapClAdapter.sol](../contracts/src/adapters/JuiceSwapClAdapter.sol)
