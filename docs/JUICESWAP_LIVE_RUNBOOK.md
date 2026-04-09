# JuiceSwap Live Runbook

## Summary

This runbook prepares the first live Helix Citrea candidate on JuiceSwap.

It is intentionally narrower than the accepted engineering path:

- engineering pair: `ctUSD / wcBTC`
- first live candidate: `USDC.e / wcBTC`

This runbook is only for the live candidate shape:

- one venue: `JuiceSwap`
- one pair: `USDC.e / wcBTC`
- one fee tier: `3000`
- one pool: `0xD77f369715E227B93D48b09066640F46F0B01b29`
- one adapter deployment
- disabled by default until explicit enable conditions are met

## Required Contracts And Metadata

### Citrea Mainnet

- chain id: `4114`
- RPC: `https://rpc.mainnet.citrea.xyz`

### Assets

- `USDC.e`: `0xE045e6c36cF77FAA2CfB54466D71A3aEF7bbE839`
- `wcBTC`: `0x3100000000000000000000000000000000000006`

### JuiceSwap mainnet contracts

- `UniswapV3Factory`: `0xd809b1285aDd8eeaF1B1566Bf31B2B4C4Bba8e82`
- `SwapRouter`: `0x565eD3D57fe40f78A46f348C220121AE093c3cF8`
- `NonfungiblePositionManager`: `0x3D3821D358f56395d4053954f98aec0E1F0fa568`

### Approved live pool only

- pair: `USDC.e / wcBTC`
- approved fee tier: `3000`
- approved pool: `0xD77f369715E227B93D48b09066640F46F0B01b29`
- approved tick spacing: `60`

Observed on April 9, 2026:

- `500` pool: absent
- `10000` pool: present but not approved for the first live candidate

## Deployment Order

### Step 1. Deploy core

Use the existing Citrea core deployment path:

- [DeployCitreaCore.s.sol](../contracts/script/DeployCitreaCore.s.sol)

### Step 2. Create the `USDC.e` candidate vault

Use:

- [DeployCitreaUsdcBase.s.sol](../contracts/script/DeployCitreaUsdcBase.s.sol)

Default launch posture:

- vault asset: `USDC.e`
- deposit cap: `25_000e6`
- `maxAllocationBps = 0`
- `paused = false`
- `withdrawOnly = false`
- strategy unset

### Step 3. Deploy and attach the JuiceSwap productive candidate

Use:

- [DeployCitreaJuiceSwapUsdcWcBtcCandidate.s.sol](../contracts/script/DeployCitreaJuiceSwapUsdcWcBtcCandidate.s.sol)

This script:

- validates the exact live candidate pool
- validates live oracle paths for `USDC.e` and `wcBTC`
- deploys one `JuiceSwapClAdapter`
- deploys one `ManagedClStrategy`
- attaches the strategy to the existing vault
- resets risk config to the disabled-by-default launch posture

## Required Environment Variables

### `DeployCitreaUsdcBase.s.sol`

- `PRIVATE_KEY`
- `VAULT_FACTORY_ADDRESS`
- `INITIAL_OWNER`
- `GUARDIAN`
- optional `VAULT_NAME`
- optional `VAULT_SYMBOL`
- optional `DEPOSIT_CAP`

### `DeployCitreaJuiceSwapUsdcWcBtcCandidate.s.sol`

- `PRIVATE_KEY`
- `VAULT_ADDRESS`
- `ORACLE_ROUTER_ADDRESS`
- `STRATEGIST`
- optional `QUOTE_VALIDITY`
- optional `VALUATION_HAIRCUT_BPS`
- optional `MAX_PRICE_DEVIATION_BPS`
- optional `DEPOSIT_CAP`

## Exact Commands

### 1. Create the `USDC.e` candidate vault

```bash
export PRIVATE_KEY=0x...
export CITREA_RPC_URL=https://rpc.mainnet.citrea.xyz
export VAULT_FACTORY_ADDRESS=0xYourVaultFactory
export INITIAL_OWNER=0xYourVaultOwner
export GUARDIAN=0xYourGuardian
export DEPOSIT_CAP=25000000000

forge script contracts/script/DeployCitreaUsdcBase.s.sol:DeployCitreaUsdcBase \
  --rpc-url $CITREA_RPC_URL \
  --broadcast
```

### 2. Deploy and attach the JuiceSwap live candidate stack

```bash
export VAULT_ADDRESS=0xYourUsdceVault
export ORACLE_ROUTER_ADDRESS=0xYourOracleRouter
export STRATEGIST=0xYourStrategist
export QUOTE_VALIDITY=86400
export VALUATION_HAIRCUT_BPS=500
export MAX_PRICE_DEVIATION_BPS=500
export DEPOSIT_CAP=25000000000

forge script contracts/script/DeployCitreaJuiceSwapUsdcWcBtcCandidate.s.sol:DeployCitreaJuiceSwapUsdcWcBtcCandidate \
  --rpc-url $CITREA_RPC_URL \
  --broadcast
```

## Expected Post-Deployment State

After the second script:

- the vault asset is `USDC.e`
- the vault strategy is attached
- `maxAllocationBps == 0`
- `paused == false`
- `withdrawOnly == false`
- `totalStrategyAssets == 0`
- the strategy is deployed but productive allocation is still disabled

## Exact Enable Conditions

Do not enable productive allocation until all of the following are true:

- `OracleRouter.getPrice(USDC.e)` succeeds and is fresh
- `OracleRouter.getPrice(wcBTC)` succeeds and is fresh
- the live pool still resolves to `0xD77f369715E227B93D48b09066640F46F0B01b29`
- the fee tier remains `3000`
- the vault is not paused and not withdraw-only
- the guardian address is active and reachable
- public pool depth is re-reviewed immediately before enable

## Owner Actions To Enable First Capital

Enable in this order:

1. verify all enable conditions above
2. keep `depositCap = 25_000e6` unless separately re-approved
3. set `maxAllocationBps` no higher than `2000`
4. allocate no more than the current allowed cap
5. have the strategist use `previewRebalance(...)` before the first live rebalance

With `depositCap = 25_000e6` and `maxAllocationBps = 2000`, the initial productive cap is:

- `5_000e6`

## Exact Disable Conditions

Move back to disabled or emergency state if any of the following occurs:

- `USDC.e` oracle becomes stale or unavailable
- `wcBTC` oracle becomes stale or unavailable
- the approved pool no longer matches the documented live candidate
- repeated unwind, harvest, or collapse operations fail on min-out protection
- public liquidity deteriorates below the intended unwind size
- venue assumptions change materially

## Guardian Triggers

Guardian should act immediately if:

- the vault enters an oracle incident for either live-candidate asset
- rebalance or unwind paths begin failing unexpectedly
- withdrawals remain safe but new productive allocation is no longer safe

Default guardian response order:

1. pause new risk-taking first
2. move to withdraw-only if productive operation is unsafe
3. use emergency pause if a full unwind is the safest response

## Conditions Before Raising Caps Above The Initial Envelope

Do not raise the productive envelope above `5_000e6` unless all of the following are true:

- the exact `USDC.e / wcBTC` pool remains the approved live pool
- both live-candidate oracle paths have remained healthy through the initial operating window
- at least one manual harvest and one manual unwind review have been completed without incident
- current public pool depth still supports a larger exit
- the owner explicitly re-approves a higher cap
- the guardian explicitly signs off on the higher envelope

## Related Docs

- [JUICESWAP_LAUNCH_CONSTRAINTS.md](./JUICESWAP_LAUNCH_CONSTRAINTS.md)
- [JUICESWAP_RISKS.md](./JUICESWAP_RISKS.md)
- [STATUS.md](./STATUS.md)
- [CITREA_MAINNET_PREREQUISITES.md](./CITREA_MAINNET_PREREQUISITES.md)
- [config/citrea/juiceswap_usdce_wcbtc_candidate.md](../config/citrea/juiceswap_usdce_wcbtc_candidate.md)
