# Helix

Helix is a Citrea-native yield optimizer in development.

The repository now has two active layers:

- a frozen live Citrea deployment
- a new v2 allocator foundation for the flagship smart-vault lane

## Current Live State

The current live stack is already deployed on Citrea and remains intentionally frozen:

- venue lane: `JuiceSwap`
- pair: `USDC.e / wcBTC`
- posture: deployed, owned, strategy-attached, disabled by default
- current safety state: `maxAllocationBps = 0`, `paused = false`, `withdrawOnly = false`

This live path is not the full Helix product identity.
It is one specialist concentrated-liquidity lane and one frozen production-shaped deployment.

## Current Product Direction

Helix v2 is now defined as:

- a yield optimizer / aggregator
- flagship first lane: `HLX-USDC.e Smart Vault`
- architecture: `vault + strategy + adapter`
- strategy family now being built: generic allocator foundation

The next major coding direction is allocator-first and venue-agnostic.
No venue-specific non-CL adapter is approved yet.

## Implemented Contract Families

### Frozen live lane

- `HelixVault`
- `RiskEngine`
- `OracleRouter`
- `VaultFactory`
- `ManagedClStrategy`
- `JuiceSwapClAdapter`

### v2 foundation in progress

- `ManagedAllocatorStrategy`
- `IAllocatorAdapter`
- `AllocatorTypes`
- allocator mocks and tests

## Start Here

### Current state and live deployment

- [docs/STATUS.md](docs/STATUS.md)
- [docs/CURRENT_DEPLOYED_STATE.md](docs/CURRENT_DEPLOYED_STATE.md)
- [docs/JUICESWAP_OPERATOR_HANDOFF.md](docs/JUICESWAP_OPERATOR_HANDOFF.md)
- [docs/JUICESWAP_LIVE_RUNBOOK.md](docs/JUICESWAP_LIVE_RUNBOOK.md)
- [docs/JUICESWAP_ORACLE_FREEZE.md](docs/JUICESWAP_ORACLE_FREEZE.md)
- [config/citrea/juiceswap_usdce_wcbtc_candidate.md](config/citrea/juiceswap_usdce_wcbtc_candidate.md)

### v2 direction and build plan

- [docs/HELIX_MASTER_ROADMAP.md](docs/HELIX_MASTER_ROADMAP.md)
- [docs/HELIX_V2_EXEC_SUMMARY.md](docs/HELIX_V2_EXEC_SUMMARY.md)
- [docs/HELIX_V2_DECISION.md](docs/HELIX_V2_DECISION.md)
- [docs/HELIX_V2_CONTRACT_PLAN.md](docs/HELIX_V2_CONTRACT_PLAN.md)
- [docs/HELIX_V2_ALLOCATOR_REVIEW.md](docs/HELIX_V2_ALLOCATOR_REVIEW.md)

## Repository Structure

```text
contracts/
  src/        # protocol, strategy, adapter, and oracle contracts
  test/       # Foundry unit, integration, and fork tests
  script/     # deployment and ownership/oracle scripts
docs/         # frozen live docs plus v2 product/build specs
config/       # concrete Citrea deployment and candidate profiles
broadcast/    # raw machine-generated deployment outputs
```

## Local Development

Install dependencies:

```bash
npm install
```

Build:

```bash
forge build
```

Run the full suite:

```bash
forge test -vvv
```

Run the allocator foundation suite only:

```bash
forge test --match-contract ManagedAllocatorStrategyTest -vvv
```

Run the frozen live-candidate checks:

```bash
forge test --match-contract JuiceSwapUsdcLiveCandidateTest -vvv
CITREA_RPC_URL=https://rpc.mainnet.citrea.xyz forge test --match-contract JuiceSwapCitreaLaunchForkTest -vvv
```
