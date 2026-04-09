# Helix

Helix is a vault and strategy foundation for controlled onchain yield deployment.

This repository currently centers on:

- an ERC-4626-style vault core
- explicit risk and oracle routing surfaces
- a managed concentrated-liquidity strategy boundary
- a JuiceSwap adapter path for Citrea
- Citrea release and launch-candidate packaging

## What Is Implemented

### Accepted core contracts

- `HelixVault`
- `RiskEngine`
- `OracleRouter`
- `VaultFactory`
- `ManagedClStrategy`
- `JuiceSwapClAdapter`

### Accepted Citrea path

- first release: `HLX-ctUSD Base`
- first release posture: no strategy attached, `maxAllocationBps = 0`
- first live candidate: `USDC.e / wcBTC` on `JuiceSwap`
- live candidate posture: one pool, one fee tier, one adapter deployment, disabled by default

## What Is Accepted Versus Experimental

### Accepted

- core vault and risk architecture
- managed adapter boundary
- JuiceSwap implementation foundation and hardening
- Citrea deployment docs and launch-candidate packaging
- `USDC.e / wcBTC` as the current first live candidate on Citrea

### Not production-ready yet

- no mainnet deployment has been executed from this repo
- no same-day broadcast verification has been completed
- no live capital has been enabled on the JuiceSwap candidate
- operational wallet setup and funding still need to be finalized
- mainnet go/no-go checks still need to be rerun immediately before broadcast

## Current Citrea Direction

Helix currently keeps two Citrea tracks separate on purpose:

- engineering pair: `ctUSD / wcBTC`
- first live candidate: `USDC.e / wcBTC`

That split exists because:

- `ctUSD / wcBTC` remains the intended product-direction pair
- `USDC.e / wcBTC` currently has the cleaner oracle path for a first live deployment candidate

## Repository Structure

```text
contracts/
  src/        # protocol and adapter contracts
  test/       # Foundry unit, integration, and fork tests
  script/     # deployment and setup scripts
docs/         # architecture, Citrea diligence, runbooks, and status docs
config/       # concrete Citrea config profiles
```

## Start Here

- [docs/STATUS.md](docs/STATUS.md)
- [docs/CITREA_INTEGRATION_PLAN.md](docs/CITREA_INTEGRATION_PLAN.md)
- [docs/JUICESWAP_LIVE_RUNBOOK.md](docs/JUICESWAP_LIVE_RUNBOOK.md)
- [config/citrea/juiceswap_usdce_wcbtc_candidate.md](config/citrea/juiceswap_usdce_wcbtc_candidate.md)
- [docs/CITREA_MAINNET_PREREQUISITES.md](docs/CITREA_MAINNET_PREREQUISITES.md)

## Local Development

Install dependencies:

```bash
npm install
```

Build:

```bash
forge build
```

Run the full test suite:

```bash
forge test -vvv
```

Run the current Citrea live-candidate checks:

```bash
forge test --match-contract JuiceSwapUsdcLiveCandidateTest -vvv
CITREA_RPC_URL=https://rpc.mainnet.citrea.xyz forge test --match-contract JuiceSwapCitreaLaunchForkTest -vvv
```

## Public Repo Notes

This repository is being packaged for public publication under the `helixdev13` GitHub namespace.

Reviewers should treat:

- `docs/STATUS.md` as the current state summary
- `docs/JUICESWAP_LIVE_RUNBOOK.md` as the current operator runbook
- `config/citrea/juiceswap_usdce_wcbtc_candidate.md` as the concrete first live-candidate config

The repo is intended to be understandable without local-only context.
