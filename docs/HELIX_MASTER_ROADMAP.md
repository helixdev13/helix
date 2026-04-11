# Helix Master Roadmap

## Summary

This is the canonical roadmap for the repository.

It merges the current:

- project direction
- build sequence
- flagship product plan
- current execution status

If roadmap language elsewhere drifts from this file, this file wins.

## Permanent Constraints

### Frozen live Citrea lane stays untouched

The deployed `USDC.e / wcBTC` `JuiceSwap` stack on Citrea remains:

- deployed
- owned
- strategy-attached
- disabled by default

Do not change as part of v2 roadmap execution:

- deployed contracts
- live config
- deployment scripts for the frozen lane
- current ownership / guardian / strategist state
- productive-allocation posture on the frozen lane unless explicitly requested

### Helix product identity

Helix is being built as:

- a Citrea-native yield optimizer / aggregator

Helix is not being built as:

- a DEX
- a CL-only product
- a clone of the current live `JuiceSwap` lane

### Flagship v2 direction

The first flagship product direction remains:

- `HLX-USDC.e Smart Vault`

That flagship should be:

- single-asset
- stable-denominated
- auto-compound-based
- supply-only at first
- idle-fallback capable
- PancakeBunny-style in product shape
- venue-specific only where a later lane truly needs it

## Current State

### Live state

- frozen Citrea `JuiceSwap` lane is deployed
- ownership is accepted
- strategy is attached
- `maxAllocationBps = 0`
- `paused = false`
- `withdrawOnly = false`
- productive allocation remains disabled

### v2 state

- deployed auto-compound stack exists onchain and ownership acceptance is complete
- `HelixLens` has product-facing vault and compound-strategy read surfaces for the current stack
- auto-compound deployment, transfer, and acceptance scripts now exist
- USDC.e base-vault ownership handoff scripts now exist
- USDC.e base-vault rehearsal harness now exists
- USDC.e base-vault post-deploy verification script now exists
- post-deploy read-only verification is complete
- the deployed auto-compound stack is the current product-facing deployed lane
- venue-specific non-CL adapter work has not started
- frozen live lane remains untouched

## Strategic End State

The target end state is a broader Helix product suite on Citrea with:

- smart single-asset vaults as the core identity
- CL as one specialist lane
- later maximizer-style or second-order optimizer products only after the core auto-compound lane is stable

## Phase Map

### Phase 0. Preserve the frozen live lane

Objective:

- keep the deployed `JuiceSwap` stack intact and operationally frozen

Success condition:

- no accidental semantic drift or config drift in the current live lane

### Phase 1. Stabilize the auto-compound core

Primary code surface:

- `AutoCompoundClStrategy`
- `RewardDistributor`
- `HelixLens` compound view
- auto-compound tests

Objective:

- keep the deployed auto-compound stack deterministic, correctly owned, and disabled by default

Required themes:

- compounding correctness
- fee math and HLX minting
- conservative accounting for compound rewards
- operator-observable events and errors

Exit condition:

- no major correctness or missing-test gaps remain in the auto-compound core

### Phase 2. Productize the flagship smart vault

Objective:

- turn the deployed auto-compound lane into the flagship `HLX-USDC.e Smart Vault`

Required work:

- base-vault / shell deployment flow
- disabled-by-default launch posture
- ownership handoff and verification
- read surfaces and operator docs
- launch-checklist compliance

Exit condition:

- a stable product-facing `HLX-USDC.e Smart Vault` lane can be introduced without touching the frozen live lane

### Phase 3. Expand the auto-compound vault family

Objective:

- add more PancakeBunny-style vault breadth on Citrea

Required work:

- later asset expansion
- later compound strategies
- CL remains the specialist lane
- no leverage
- no reflexive tokenomics

Exit condition:

- a second auto-compound vault lane can be added without reworking the core stack

### Phase 4. Later specialist lanes

Objective:

- keep CL and later products separate from the core auto-compound identity

Required work:

- keep CL as a specialist strategy lane
- consider later maximizer-style products only after core lane stability

Exit condition:

- product breadth grows without diluting the smart-vault identity

## Exact Engineering Order

1. Stabilize the auto-compound core.
2. Productize the flagship smart vault.
3. Expand the auto-compound vault family.
4. Keep specialist lanes separate.

Do not reorder this.

## Current Immediate Priority

The immediate engineering mission is:

- keep both deployed Citrea stacks disabled by default unless a deliberate enablement review is requested
- keep the frozen `JuiceSwap` deployment untouched
- continue expanding the PancakeBunny-style auto-compound smart-vault lane
- use `HELIX_LAUNCH_CHECKLIST.md` as the launch gate for any future rollout
- preserve the already-hardened vault/strategy boundary
- do not reintroduce the deleted generic branch

Do not start:

- productive-enable work on the frozen live lane
- any redesign of the frozen `JuiceSwap` deployment path

## Definition Of Done For The Auto-Compound Core

The deployed auto-compound lane is ready for further product expansion only when:

- vault and strategy boundaries are stable
- compounding math and accounting are explicit
- live vs conservative reporting is clearly separated
- disabled-by-default and ownership-finalized behavior is tested
- harvest and emergency unwind paths are defined and tested
- operator read surfaces are stable
- the core lane no longer relies on venue-specific assumptions

If that bar is not met, broader product expansion is premature.

## Source-Of-Truth Links

### Frozen live deployment

- [CURRENT_DEPLOYED_STATE.md](./CURRENT_DEPLOYED_STATE.md)
- [JUICESWAP_OPERATOR_HANDOFF.md](./JUICESWAP_OPERATOR_HANDOFF.md)
- [JUICESWAP_LIVE_RUNBOOK.md](./JUICESWAP_LIVE_RUNBOOK.md)
- [JUICESWAP_ORACLE_FREEZE.md](./JUICESWAP_ORACLE_FREEZE.md)
- [HELIX_LAUNCH_CHECKLIST.md](./HELIX_LAUNCH_CHECKLIST.md)
- [config/citrea/juiceswap_usdce_wcbtc_candidate.md](../config/citrea/juiceswap_usdce_wcbtc_candidate.md)

### v2 deployment surface

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
