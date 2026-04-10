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

### Frozen operator roles

- `DEPLOYER_EOA`: `0xad53D0aBC81Ff8a42d6C3620Dc91B275C898EDF7`
- `FINAL_OWNER`: `0x7C3244f1071Fb9849521f4B15dcFd20433F13f35`
- `GUARDIAN`: `0x7eB55a7bEe37B985b0fA10c262Ed712D1DEad742`
- `STRATEGIST`: `0xC89044F853a0F004AE5b0daD8A384A52bd2D73bF`

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

For the current live candidate, the broadcaster must stay the temporary owner of:

- `VaultFactory`
- `RiskEngine`
- `OracleRouter`

### Step 2. Configure the frozen production oracles

Use:

- [ConfigureCitreaUsdcWcBtcOracles.s.sol](../contracts/script/ConfigureCitreaUsdcWcBtcOracles.s.sol)

This script:

- deploys one `AggregatorV3OracleAdapter` for RedStone `USDC/USD`
- deploys one `AggregatorV3OracleAdapter` for RedStone `BTC/USD`
- maps `USDC.e` and `wcBTC` into `OracleRouter`
- freezes both candidate heartbeats at `21600`

### Step 3. Create the `USDC.e` candidate vault

Use:

- [DeployCitreaUsdcBase.s.sol](../contracts/script/DeployCitreaUsdcBase.s.sol)

For the current candidate sequence:

- `INITIAL_OWNER` must be the broadcaster temporarily
- the final owner handoff happens later, after strategy attach

Default launch posture:

- vault asset: `USDC.e`
- deposit cap: `25_000e6`
- `maxAllocationBps = 0`
- `paused = false`
- `withdrawOnly = false`
- strategy unset

### Step 4. Deploy and attach the JuiceSwap productive candidate

Use:

- [DeployCitreaJuiceSwapUsdcWcBtcCandidate.s.sol](../contracts/script/DeployCitreaJuiceSwapUsdcWcBtcCandidate.s.sol)

This script:

- validates the exact live candidate pool
- validates live oracle paths for `USDC.e` and `wcBTC`
- deploys one `JuiceSwapClAdapter`
- deploys one `ManagedClStrategy`
- attaches the strategy to the existing vault
- resets risk config to the disabled-by-default launch posture

### Step 5. Transfer ownership to the final owner

Use:

- [TransferCitreaCandidateOwnership.s.sol](../contracts/script/TransferCitreaCandidateOwnership.s.sol)

This script stages two-step ownership transfer for:

- `VaultFactory`
- `RiskEngine`
- `OracleRouter`
- `HelixVault`
- `ManagedClStrategy`

### Step 6. Accept ownership as the final owner

Use:

- [AcceptCitreaCandidateOwnership.s.sol](../contracts/script/AcceptCitreaCandidateOwnership.s.sol)

If the final owner is an EOA, this script can accept all five ownerships directly.

If the final owner is a multisig or Safe, execute the same `acceptOwnership()` calls from that wallet before any productive enablement.

## Required Environment Variables

### `DeployCitreaUsdcBase.s.sol`

- `PRIVATE_KEY`
- `VAULT_FACTORY_ADDRESS`
- `INITIAL_OWNER`
- `GUARDIAN`
- optional `VAULT_NAME`
- optional `VAULT_SYMBOL`
- optional `DEPOSIT_CAP`

### `ConfigureCitreaUsdcWcBtcOracles.s.sol`

- `PRIVATE_KEY`
- `ORACLE_ROUTER_ADDRESS`

### `DeployCitreaJuiceSwapUsdcWcBtcCandidate.s.sol`

- `PRIVATE_KEY`
- `VAULT_ADDRESS`
- `ORACLE_ROUTER_ADDRESS`
- `STRATEGIST`
- optional `QUOTE_VALIDITY`
- optional `VALUATION_HAIRCUT_BPS`
- optional `MAX_PRICE_DEVIATION_BPS`
- optional `DEPOSIT_CAP`

### `TransferCitreaCandidateOwnership.s.sol`

- `PRIVATE_KEY`
- `FINAL_OWNER`
- `VAULT_FACTORY_ADDRESS`
- `RISK_ENGINE_ADDRESS`
- `ORACLE_ROUTER_ADDRESS`
- `VAULT_ADDRESS`
- `STRATEGY_ADDRESS`

### `AcceptCitreaCandidateOwnership.s.sol`

- `PRIVATE_KEY`
- `VAULT_FACTORY_ADDRESS`
- `RISK_ENGINE_ADDRESS`
- `ORACLE_ROUTER_ADDRESS`
- `VAULT_ADDRESS`
- `STRATEGY_ADDRESS`

## Exact Commands

### 1. Configure the frozen production oracles

```bash
export PRIVATE_KEY=0x...
export CITREA_RPC_URL=https://rpc.mainnet.citrea.xyz
export ORACLE_ROUTER_ADDRESS=0xYourOracleRouter

forge script contracts/script/ConfigureCitreaUsdcWcBtcOracles.s.sol:ConfigureCitreaUsdcWcBtcOracles \
  --rpc-url $CITREA_RPC_URL \
  --broadcast
```

### 2. Create the `USDC.e` candidate vault

```bash
export VAULT_FACTORY_ADDRESS=0xYourVaultFactory
export INITIAL_OWNER=0xBroadcasterTemporaryOwner
export GUARDIAN=0x7eB55a7bEe37B985b0fA10c262Ed712D1DEad742
export DEPOSIT_CAP=25000000000

forge script contracts/script/DeployCitreaUsdcBase.s.sol:DeployCitreaUsdcBase \
  --rpc-url $CITREA_RPC_URL \
  --broadcast
```

### 3. Deploy and attach the JuiceSwap live candidate stack

```bash
export VAULT_ADDRESS=0xYourUsdceVault
export STRATEGIST=0xC89044F853a0F004AE5b0daD8A384A52bd2D73bF
export QUOTE_VALIDITY=86400
export VALUATION_HAIRCUT_BPS=500
export MAX_PRICE_DEVIATION_BPS=500
export DEPOSIT_CAP=25000000000

forge script contracts/script/DeployCitreaJuiceSwapUsdcWcBtcCandidate.s.sol:DeployCitreaJuiceSwapUsdcWcBtcCandidate \
  --rpc-url $CITREA_RPC_URL \
  --broadcast
```

### 4. Stage two-step ownership transfer to the final owner

```bash
export FINAL_OWNER=0x7C3244f1071Fb9849521f4B15dcFd20433F13f35
export RISK_ENGINE_ADDRESS=0xYourRiskEngine
export STRATEGY_ADDRESS=0xYourStrategy

forge script contracts/script/TransferCitreaCandidateOwnership.s.sol:TransferCitreaCandidateOwnership \
  --rpc-url $CITREA_RPC_URL \
  --broadcast
```

### 5. Accept ownership as the final owner

If the final owner is an EOA:

```bash
export PRIVATE_KEY=0xFinalOwnerKey

forge script contracts/script/AcceptCitreaCandidateOwnership.s.sol:AcceptCitreaCandidateOwnership \
  --rpc-url $CITREA_RPC_URL \
  --broadcast
```

If the final owner is a multisig or Safe:

- execute `acceptOwnership()` from the final owner wallet on:
  - `VaultFactory`
  - `RiskEngine`
  - `OracleRouter`
  - `HelixVault`
  - `ManagedClStrategy`

## Expected Post-Deployment State

After the ownership acceptance step:

- the vault asset is `USDC.e`
- the vault strategy is attached
- `maxAllocationBps == 0`
- `paused == false`
- `withdrawOnly == false`
- `totalStrategyAssets == 0`
- the strategy is deployed but productive allocation is still disabled

## Same-Day Checklist For Disabled Deployment

Do not broadcast the disabled-by-default deployment unless all of the following are true on the same day:

1. `block.chainid == 4114`
2. the broadcaster EOA has enough `cBTC` for:
   - core deployment
   - oracle wrapper deployment and `OracleRouter.setOracle(...)`
   - vault deployment
   - candidate strategy deployment and attach
   - ownership transfer staging
   - one retry buffer
3. the final owner address is fixed before deployment starts
4. the guardian address is fixed before deployment starts
5. the strategist address is fixed before deployment starts
6. the frozen oracle sources still match:
   - `USDC/USD -> 0xf0DEbDAE819b354D076b0D162e399BE013A856d3`
   - `BTC/USD -> 0xc555c100DB24dF36D406243642C169CC5A937f09`
7. both source feeds still answer `latestRoundData()`
8. both source feeds still report `decimals() == 8`
9. `OracleRouter.getConfig(USDC.e).heartbeat == 21600` after configuration
10. `OracleRouter.getConfig(wcBTC).heartbeat == 21600` after configuration
11. `OracleRouter.getPrice(USDC.e)` succeeds after configuration
12. `OracleRouter.getPrice(wcBTC)` succeeds after configuration
13. `factory.getPool(USDC.e, wcBTC, 3000) == 0xD77f369715E227B93D48b09066640F46F0B01b29`
14. the approved pool still reports:
   - `token0 == wcBTC`
   - `token1 == USDC.e`
   - `fee == 3000`
15. `observe([1800,0])` succeeds on the approved pool
16. the broadcaster still owns:
   - `VaultFactory`
   - `RiskEngine`
   - `OracleRouter`
17. `INITIAL_OWNER` for the candidate vault is the broadcaster temporarily
18. productive allocation remains disabled at the end of deployment:
   - `maxAllocationBps == 0`
   - `totalStrategyAssets == 0`

## Exact Enable Conditions

Do not enable productive allocation until all of the following are true:

- `OracleRouter.getPrice(USDC.e)` succeeds and is fresh
- `OracleRouter.getPrice(wcBTC)` succeeds and is fresh
- `OracleRouter.getConfig(USDC.e).heartbeat == 21600`
- `OracleRouter.getConfig(wcBTC).heartbeat == 21600`
- the live pool still resolves to `0xD77f369715E227B93D48b09066640F46F0B01b29`
- the approved pool still reports `token0 == wcBTC`
- the approved pool still reports `token1 == USDC.e`
- the fee tier remains `3000`
- `observe([1800,0])` succeeds on the approved pool
- the final owner has accepted ownership of all five candidate contracts
- the vault is not paused and not withdraw-only
- the guardian address is active and reachable
- public pool depth passes the minimum signoff below immediately before enable

## Minimum Same-Day Liquidity Signoff Before First Enablement

For the first live enablement only, do not enable productive allocation unless the approved pool passes all of the following on the same day:

1. the initial productive envelope is still capped at:
   - `depositCap = 25_000e6`
   - `maxAllocationBps <= 2000`
   - productive cap `<= 5_000e6`
2. `USDC.e.balanceOf(approvedPool) >= 15_000e6`
3. `OracleRouter.quoteAsset(wcBTC, wcBTC.balanceOf(approvedPool)) >= 15_000e6`
4. `observe([1800,0])` still succeeds immediately before enable
5. both `OracleRouter.getPrice(...)` reads still succeed immediately before enable

This is a conservative first-enable gate equal to at least `3x` the initial productive cap on each side of the approved pool in same-day notional terms.

If any of these checks fails, keep `maxAllocationBps = 0`.

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

## Wallet Roles And `cBTC` Funding

- broadcaster EOA:
  - deploys core
  - configures frozen oracle wrappers
  - creates the vault
  - deploys and attaches the candidate stack
  - stages ownership transfer
  - must hold `cBTC` before disabled deployment broadcast
- final owner EOA:
  - must hold `cBTC` only if using the EOA acceptance script directly
- final owner Safe or multisig:
  - the Safe itself must hold `cBTC` before executing `acceptOwnership()` and later owner actions
- guardian:
  - should hold `cBTC` before any period where emergency actions may be needed
- strategist:
  - should hold `cBTC` before any planned rebalance after productive enablement

## Conditions Before Raising Caps Above The Initial Envelope

Do not raise the productive envelope above `5_000e6` unless all of the following are true:

- the exact `USDC.e / wcBTC` pool remains the approved live pool
- both live-candidate oracle paths have remained healthy through the initial operating window
- at least one manual harvest and one manual unwind review have been completed without incident
- current public pool depth still supports a larger exit
- the owner explicitly re-approves a higher cap
- the guardian explicitly signs off on the higher envelope

## Related Docs

- [JUICESWAP_OPERATOR_HANDOFF.md](./JUICESWAP_OPERATOR_HANDOFF.md)
- [CURRENT_DEPLOYED_STATE.md](./CURRENT_DEPLOYED_STATE.md)
- [JUICESWAP_OPERATOR_HANDOFF.md](./JUICESWAP_OPERATOR_HANDOFF.md)
- [JUICESWAP_ORACLE_FREEZE.md](./JUICESWAP_ORACLE_FREEZE.md)
- [STATUS.md](./STATUS.md)
- [CITREA_MAINNET_PREREQUISITES.md](./CITREA_MAINNET_PREREQUISITES.md)
- [config/citrea/juiceswap_usdce_wcbtc_candidate.md](../config/citrea/juiceswap_usdce_wcbtc_candidate.md)
