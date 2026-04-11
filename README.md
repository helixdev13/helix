# Helix

PancakeBunny-style auto-compounding yield optimizer on [Citrea](https://citrea.xyz) (Bitcoin rollup).

Users deposit USDC.e into a vault. The strategy deploys capital into a JuiceSwap concentrated liquidity position. Trading fees are auto-compounded via a permissionless `compound()` function. Users earn HLX reward tokens by staking vault shares.

## Deployed Contracts (Citrea Mainnet, Chain ID 4114)

| Contract | Address |
|----------|---------|
| RiskEngine | `0xCDA74676b8c53914c71085414191C0252f741B18` |
| OracleRouter | `0x49B8317E44384D13CdC662D91d14Df4254bE5afD` |
| VaultFactory | `0x945099d64ecfE1aDe18698C35Fb3f607D19134c6` |
| HelixLens | `0x51239c936c9D5F4A461e30e955e09943515f2F0C` |
| HLXToken | `0x1E39f6D1a98b8EE7296aa236106baa2126216805` |
| HelixVault | `0xeDc8aE17318fEdFEf6a10041078Dc3e6816d8607` |
| JuiceSwapClAdapter | `0xa02682e3dCCa9FA779767dA14332a093D6e3dfFc` |
| AutoCompoundClStrategy | `0x4303b4F7Cd37582551bDF6Cfb596b314B8081E97` |
| RewardDistributor | `0xB459B3FCD9969dA4A8d6d0F223C115a6b1d8bEB1` |

Ownership accepted by `FINAL_OWNER` (`0x7C3244f1071Fb9849521f4B15dcFd20433F13f35`). All contracts disabled by default (`maxAllocationBps = 0`).

## Architecture

```
User → HelixVault (USDC.e) → AutoCompoundClStrategy → JuiceSwapClAdapter → JuiceSwap CL Pool
                              ↓
                         compound() harvests fees
                         30% fee → treasury (USDC.e) + HLX minted for stakers
                         70% reinvested into position
                         1% bounty (HLX) → compound caller
```

### Fee math

- Profit → 30% performance fee / 70% reinvested
- Performance fee → 30% to treasury in USDC.e, 70% minted as HLX for reward distributor
- 1% bounty of the fee → HLX minted for the `compound()` caller

### Core contracts

- `HelixVault.sol` — ERC4626 vault with deposit cap, risk pause, and strategy attachment
- `AutoCompoundClStrategy.sol` — compound, fee extraction, HLX minting, best-effort reinvest, rebalance, emergency unwind
- `RewardDistributor.sol` — Synthetix-style staking rewards for HLX
- `HLXToken.sol` — ERC20 with MINTER_ROLE, no max supply
- `HelixLens.sol` — aggregated view functions for frontend
- `JuiceSwapClAdapter.sol` — JuiceSwap concentrated liquidity adapter

### Infrastructure

- `RiskEngine.sol` — per-vault risk parameters (deposit cap, allocation limits, pause)
- `OracleRouter.sol` — multi-source oracle with heartbeat tracking
- `VaultFactory.sol` — vault deployment with risk config registration

## Token Decimals

- USDC.e: 6 decimals
- HLX: 18 decimals

## Repository Structure

```
contracts/
  src/           # Solidity source contracts
    core/        # RiskEngine, OracleRouter, VaultFactory
    strategies/  # AutoCompoundClStrategy, ManagedClStrategy
    adapters/    # JuiceSwapClAdapter, MockClAdapter
    periphery/   # HLXToken, RewardDistributor, HelixLens
    libraries/   # Types, Errors, Events
    token/       # HLXToken
  test/          # Foundry test suites (157+ tests, 100% coverage on auto-compound core)
  script/        # Deployment and ownership transfer scripts
frontend/        # Next.js 14 dApp (wagmi v2 + viem + TailwindCSS + shadcn/ui)
docs/            # Roadmap, deployment state, runbooks
config/          # Citrea deployment profiles
```

## Local Development

### Prerequisites

- [Foundry](https://book.getfoundry.sh/)
- Node.js 18+
- npm

### Contracts

```bash
npm install
forge build
forge test -vvv
```

### Frontend

```bash
cd frontend
npm install
npm run dev
```

## Documentation

- [Master Roadmap](docs/HELIX_MASTER_ROADMAP.md)
- [Current Deployed State](docs/CURRENT_DEPLOYED_STATE.md)
- [Launch Checklist](docs/HELIX_LAUNCH_CHECKLIST.md)
- [Status](docs/STATUS.md)
- [Auto-compound Deployment Runbook](config/citrea/auto_compound_usdce.md)

## Roles (Citrea Mainnet)

| Role | Address |
|------|---------|
| FINAL_OWNER | `0x7C3244f1071Fb9849521f4B15dcFd20433F13f35` |
| GUARDIAN | `0x7eB55a7bEe37B985b0fA10c262Ed712D1DEad742` |
| STRATEGIST | `0xC89044F853a0F004AE5b0daD8A384A52bd2D73bF` |
