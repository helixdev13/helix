# Citrea Auto-Compound `USDC.e` Deployment

## Summary

This file is the concrete configuration profile for the first PancakeBunny-style Helix auto-compound deployment on Citrea.

Target stack:

- `HLXToken`
- `HelixVault`
- `JuiceSwapClAdapter`
- `AutoCompoundClStrategy`
- `RewardDistributor`

Target chain:

- `Citrea Mainnet`
- chain id: `4114`

Target venue:

- `JuiceSwap`
- pair: `USDC.e / wcBTC`
- approved fee tier: `3000`
- approved pool only

## Overview

The deployed stack is a Citrea-native auto-compounder for the approved JuiceSwap `USDC.e / wcBTC` pool.

What is being deployed:

- a new `HLXToken`
- a new `HelixVault`
- a new `JuiceSwapClAdapter`
- a new `AutoCompoundClStrategy`
- a new `RewardDistributor`

What this runbook expects:

- Citrea mainnet is live and reachable
- the approved JuiceSwap pool is already deployed
- Citrea core contracts are already deployed and owned by the broadcaster
- the oracle router is already configured with the production USDC.e and wcBTC feeds

## Prerequisites

Before running `DeployCitreaAutoCompoundVault.s.sol`, the following must already be true:

- `VaultFactory`, `RiskEngine`, and `OracleRouter` have already been deployed by `DeployCitreaCore`
- the broadcaster EOA owns `VaultFactory`, `RiskEngine`, and `OracleRouter`
- `USDC.e` and `wcBTC` oracle feeds are configured in `OracleRouter`
- both feeds use a `6 hour` heartbeat
- the JuiceSwap factory, pool, position manager, and swap router addresses are known
- the approved pool validates as `USDC.e / wcBTC` at fee tier `3000`
- the approved pool tick spacing is `60`
- the approved pool orientation is `token0 = wcBTC`, `token1 = USDC.e`
- `pool.observe([1800, 0])` succeeds
- `OracleRouter.getPrice(USDC.e)` succeeds
- `OracleRouter.getPrice(wcBTC)` succeeds

## Required Environment Variables

`DeployCitreaAutoCompoundVault.s.sol` reads the following configuration from the environment:

- `PRIVATE_KEY` - deployer / broadcaster key
- `VAULT_FACTORY_ADDRESS` - deployed `VaultFactory`
- `ORACLE_ROUTER_ADDRESS` - deployed `OracleRouter`
- `FINAL_OWNER` - final owner address for the two-step handoff
- `GUARDIAN` - guardian address
- `STRATEGIST` - strategist address
- `FEE_RECIPIENT` - optional, defaults to `FINAL_OWNER`
- `QUOTE_VALIDITY` - optional, defaults to `1 days`
- `VALUATION_HAIRCUT_BPS` - optional, defaults to `500`
- `MAX_PRICE_DEVIATION_BPS` - optional, defaults to `500`
- `DEPOSIT_CAP` - optional, defaults to `25_000e6`
- `VAULT_NAME` - optional, defaults to `Helix USDC.e Smart Vault`
- `VAULT_SYMBOL` - optional, defaults to `HLX-USDCe-SV`

## Hardcoded Addresses And Constants

### Assets

- `CITREA_USDCE`: `0xE045e6c36cF77FAA2CfB54466D71A3aEF7bbE839`
- `CITREA_WCBTC`: `0x3100000000000000000000000000000000000006`

### JuiceSwap Mainnet Addresses

- `JUICESWAP_FACTORY`: `0xd809b1285aDd8eeaF1B1566Bf31B2B4C4Bba8e82`
- `JUICESWAP_SWAP_ROUTER`: `0x565eD3D57fe40f78A46f348C220121AE093c3cF8`
- `JUICESWAP_POSITION_MANAGER`: `0x3D3821D358f56395d4053954f98aec0E1F0fa568`
- `JUICESWAP_USDCE_WCBTC_3000_POOL`: `0xD77f369715E227B93D48b09066640F46F0B01b29`

### Deployment Constants

- chain id: `4114`
- `USDC.e` decimals: `6`
- `wcBTC` decimals: `18`
- approved pool fee tier: `3000`
- approved pool tick spacing: `60`
- oracle heartbeat: `6 hours`
- initial `maxAllocationBps`: `0`
- default valuation haircut: `500`
- default max price deviation: `500`
- default quote validity: `1 days`
- default deposit cap: `25_000e6`

## Deployment Sequence

The deployment runbook is split into the deploy script, the transfer script, and the acceptance script.

### 1. Validate the launch surface

`DeployCitreaAutoCompoundVault.s.sol` first validates:

- chain id is `4114`
- the deployer key resolves to the broadcaster EOA
- `FINAL_OWNER`, `GUARDIAN`, `STRATEGIST`, and `FEE_RECIPIENT` are all non-zero
- `FINAL_OWNER` is distinct from the broadcaster
- `VaultFactory`, `RiskEngine`, and `OracleRouter` are owned by the broadcaster
- `USDC.e` and `wcBTC` decimals match the expected values
- the approved pool resolves from the JuiceSwap factory
- the approved pool matches the expected orientation, fee tier, and tick spacing
- `pool.observe([1800, 0])` succeeds
- `OracleRouter.getPrice(USDC.e)` and `OracleRouter.getPrice(wcBTC)` succeed
- both oracle heartbeats equal `6 hours`

### 2. Deploy `HLXToken`

- deploy `HLXToken` with the broadcaster as admin

### 3. Create the vault

- create the `HelixVault` through `VaultFactory`
- base asset is `USDC.e`
- initial owner is the broadcaster
- guardian is set from the environment
- vault name and symbol default to the auto-compound values if not overridden

### 4. Configure `RiskEngine`

- set `depositCap` from the environment or the default
- set `maxAllocationBps = 0`
- set `paused = false`
- set `withdrawOnly = false`

### 5. Deploy `JuiceSwapClAdapter`

- bind the adapter to `USDC.e`, `wcBTC`, the approved pool, the JuiceSwap position manager, the swap router, and the oracle router
- apply the configured quote validity and valuation bounds

### 6. Deploy `RewardDistributor`

- staking token is the vault share token
- reward token is `HLXToken`
- distributor owner is the broadcaster at deployment time

### 7. Deploy `AutoCompoundClStrategy`

- strategy is bound to `USDC.e`
- strategy is bound to the new vault
- strategy is bound to the new adapter
- strategy is bound to the oracle router
- strategist, guardian, and fee recipient are loaded from the environment
- strategy is bound to `HLXToken` and the reward distributor

### 8. Attach the strategy and wire rewards

- attach the strategy to the vault
- grant `MINTER_ROLE` on `HLXToken` to the strategy

### 9. Stage ownership transfer

Run `TransferCitreaAutoCompoundVaultOwnership.s.sol` with the broadcaster key to:

- transfer `VaultFactory` to `FINAL_OWNER`
- transfer `RiskEngine` to `FINAL_OWNER`
- transfer `OracleRouter` to `FINAL_OWNER`
- transfer `HelixVault` to `FINAL_OWNER`
- transfer `AutoCompoundClStrategy` to `FINAL_OWNER`
- transfer `RewardDistributor` to `FINAL_OWNER`
- grant `HLXToken` admin to `FINAL_OWNER`
- keep `HLXToken` minter role on the strategy only
- revoke `HLXToken` admin and minter privileges from the broadcaster

### 10. Accept ownership

Run `AcceptCitreaAutoCompoundVaultOwnership.s.sol` as the final owner to complete the two-step transfer on:

- `VaultFactory`
- `RiskEngine`
- `OracleRouter`
- `HelixVault`
- `AutoCompoundClStrategy`
- `RewardDistributor`

## Post-Deploy Verification

After the deploy and handoff scripts, verify:

- all deployed addresses were logged
- `VaultFactory.owner() == FINAL_OWNER`
- `RiskEngine.owner() == FINAL_OWNER`
- `OracleRouter.owner() == FINAL_OWNER`
- `vault.owner() == FINAL_OWNER`
- `strategy.owner() == FINAL_OWNER`
- `rewardDistributor.owner() == FINAL_OWNER`
- no pending owner remains on any transferred contract
- `vault.strategy()` is set to the deployed strategy
- `RiskEngine.getMaxAllocationBps(vault) == 0`
- `RiskEngine.isPaused(vault) == false`
- `RiskEngine.isWithdrawOnly(vault) == false`
- `strategy.adapter()` is the deployed `JuiceSwapClAdapter`
- `RewardDistributor.STAKING_TOKEN()` is the vault
- `RewardDistributor.REWARD_TOKEN()` is `HLXToken`
- `HLXToken` minter role is held by the strategy
- no deployer admin role remains on `HLXToken`

## Ownership Acceptance

Ownership acceptance is a separate final-owner step.

Do not run `AcceptCitreaAutoCompoundVaultOwnership.s.sol` until:

- the transfer script has staged every pending owner to `FINAL_OWNER`
- the final owner key is loaded locally
- the broadcaster has already handed off `HLXToken` admin

## Safety Posture

The auto-compound stack deploys disabled by default:

- `maxAllocationBps = 0`
- `paused = false`
- `withdrawOnly = false`

No productive allocation should happen until a separate enablement review is completed.

## Wallet Funding Posture

- the broadcaster EOA needs `cBTC` before broadcasting the deploy and transfer scripts
- the final owner EOA needs `cBTC` before running the acceptance script directly
- the strategist and guardian only need `cBTC` when later operating the live stack

## Sources

- [DeployCitreaAutoCompoundVault.s.sol](../../contracts/script/DeployCitreaAutoCompoundVault.s.sol)
- [TransferCitreaAutoCompoundVaultOwnership.s.sol](../../contracts/script/TransferCitreaAutoCompoundVaultOwnership.s.sol)
- [AcceptCitreaAutoCompoundVaultOwnership.s.sol](../../contracts/script/AcceptCitreaAutoCompoundVaultOwnership.s.sol)
- [Citrea JuiceSwap `USDC.e / wcBTC` Candidate](./juiceswap_usdce_wcbtc_candidate.md)
- [JUICESWAP_ORACLE_FREEZE.md](../../docs/JUICESWAP_ORACLE_FREEZE.md)
