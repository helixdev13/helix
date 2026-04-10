# JuiceSwap Operator Handoff

## Summary

This is the operator-facing handoff for the only current live Helix Citrea candidate:

- venue: `JuiceSwap`
- pair: `USDC.e / wcBTC`
- approved pool: `0xD77f369715E227B93D48b09066640F46F0B01b29`
- approved fee tier: `3000`
- oracle heartbeat: `21600`
- deployment posture: disabled by default

This handoff is only for:

1. disabled-by-default mainnet deployment
2. later productive enablement review
3. emergency pause and forced-exit operations

## Fixed Live-Candidate Rules

Do not change any of these without an explicit review update:

- pool: `0xD77f369715E227B93D48b09066640F46F0B01b29`
- fee tier: `3000`
- token0: `wcBTC`
- token1: `USDC.e`
- `OracleRouter.getConfig(USDC.e).heartbeat == 21600`
- `OracleRouter.getConfig(wcBTC).heartbeat == 21600`
- initial productive cap: `<= 5_000e6`
- `maxAllocationBps <= 2000`

## Frozen Public Address Watchlist

Use these labels for deployment-day recognition and cross-checking:

- `APPROVED_POOL`: `0xD77f369715E227B93D48b09066640F46F0B01b29`
- `USDCe`: `0xE045e6c36cF77FAA2CfB54466D71A3aEF7bbE839`
- `wcBTC`: `0x3100000000000000000000000000000000000006`
- `USDC_USD_FEED`: `0xf0DEbDAE819b354D076b0D162e399BE013A856d3`
- `BTC_USD_FEED`: `0xc555c100DB24dF36D406243642C169CC5A937f09`

## Wallet Roles

- frozen `DEPLOYER_EOA`: `0xad53D0aBC81Ff8a42d6C3620Dc91B275C898EDF7`
- broadcaster EOA:
  - deploys core
  - configures frozen oracle wrappers
  - creates the candidate vault
  - deploys and attaches the candidate stack
  - stages ownership transfer
- frozen `FINAL_OWNER`: `0x7C3244f1071Fb9849521f4B15dcFd20433F13f35`
- final owner:
  - accepts ownership
  - is the only wallet that may later approve productive enablement
- frozen `GUARDIAN`: `0x7eB55a7bEe37B985b0fA10c262Ed712D1DEad742`
- guardian:
  - handles pause, withdraw-only, and emergency pause
- frozen `STRATEGIST`: `0xC89044F853a0F004AE5b0daD8A384A52bd2D73bF`
- strategist:
  - uses `previewRebalance(...)` and executes rebalance only after productive enablement

## `cBTC` Funding Rules

- broadcaster EOA must hold `cBTC` before disabled deployment broadcast
- final owner EOA must hold `cBTC` only if it will directly run `acceptOwnership()`
- final owner Safe or multisig must hold `cBTC` before ownership acceptance and later owner actions
- guardian should hold `cBTC` before any live operating window
- strategist should hold `cBTC` before any planned productive rebalance

## Disabled Deployment Checklist

Deployment is `GO` only if all of the following are true on the same day:

1. `block.chainid == 4114`
2. broadcaster, final owner, guardian, and strategist addresses are fixed
3. broadcaster still owns:
   - `VaultFactory`
   - `RiskEngine`
   - `OracleRouter`
4. frozen source feeds still match:
   - `USDC/USD -> 0xf0DEbDAE819b354D076b0D162e399BE013A856d3`
   - `BTC/USD -> 0xc555c100DB24dF36D406243642C169CC5A937f09`
5. both source feeds answer `latestRoundData()`
6. both source feeds still report `decimals() == 8`
7. `OracleRouter.getPrice(USDC.e)` succeeds after configuration
8. `OracleRouter.getPrice(wcBTC)` succeeds after configuration
9. `OracleRouter.getConfig(USDC.e).heartbeat == 21600`
10. `OracleRouter.getConfig(wcBTC).heartbeat == 21600`
11. `factory.getPool(USDC.e, wcBTC, 3000) == 0xD77f369715E227B93D48b09066640F46F0B01b29`
12. approved pool reports:
   - `token0 == wcBTC`
   - `token1 == USDC.e`
   - `fee == 3000`
13. `observe([1800,0])` succeeds on the approved pool
14. deployment ends with:
   - strategy attached
   - `maxAllocationBps == 0`
   - `totalStrategyAssets == 0`

If any item fails, do not broadcast.

## Productive Enablement Checklist

Productive enablement is `GO` only if all of the following are true immediately before enable:

1. final owner has accepted ownership of:
   - `VaultFactory`
   - `RiskEngine`
   - `OracleRouter`
   - `HelixVault`
   - `ManagedClStrategy`
2. `OracleRouter.getPrice(USDC.e)` succeeds and is fresh
3. `OracleRouter.getPrice(wcBTC)` succeeds and is fresh
4. `OracleRouter.getConfig(USDC.e).heartbeat == 21600`
5. `OracleRouter.getConfig(wcBTC).heartbeat == 21600`
6. approved pool still resolves exactly
7. approved pool still reports:
   - `token0 == wcBTC`
   - `token1 == USDC.e`
   - `fee == 3000`
8. `observe([1800,0])` succeeds on the approved pool
9. vault is not paused
10. vault is not withdraw-only
11. guardian is active and reachable
12. first-enable liquidity signoff passes

If any item fails, keep `maxAllocationBps = 0`.

## First-Enable Liquidity Signoff

Before the first productive enablement only, require all of the following on the same day:

1. `depositCap = 25_000e6`
2. `maxAllocationBps <= 2000`
3. productive cap `<= 5_000e6`
4. `USDC.e.balanceOf(approvedPool) >= 15_000e6`
5. `OracleRouter.quoteAsset(wcBTC, wcBTC.balanceOf(approvedPool)) >= 15_000e6`
6. `observe([1800,0])` succeeds immediately before enable
7. both frozen oracle reads succeed immediately before enable

This is the minimum same-day signoff. If it fails, the candidate stays deployed but disabled.

## Emergency Pause And Forced-Exit Response

Use this path if the live candidate is deployed and any of the following occurs:

- either oracle path becomes stale or unavailable
- rebalance or harvest operations start failing unexpectedly
- productive allocation becomes unsafe while user exits must remain available
- pool conditions deteriorate below the intended unwind size

Guardian response order:

1. pause new risk-taking first
2. move to withdraw-only if productive operation is unsafe but full unwind is not yet required
3. use `emergencyPause()` if full unwind is the safest response

After `emergencyPause()`, verify:

- `vault.withdrawOnly() == true`
- `vault.totalStrategyAssets() == 0`
- `adapter.positionTokenId() == 0`
- the position is no longer active
- user withdrawals from idle vault assets are still functioning

## No-Go Conditions

Do not deploy or enable if any of the following is true:

- approved pool address differs from `0xD77f369715E227B93D48b09066640F46F0B01b29`
- fee tier differs from `3000`
- oracle heartbeat differs from `21600`
- first productive cap would exceed `5_000e6`
- `maxAllocationBps` would exceed `2000`
- `observe([1800,0])` fails on the approved pool
- either frozen oracle read fails
- same-day liquidity signoff fails

## Source Docs

- [JUICESWAP_LIVE_RUNBOOK.md](./JUICESWAP_LIVE_RUNBOOK.md)
- [JUICESWAP_ORACLE_FREEZE.md](./JUICESWAP_ORACLE_FREEZE.md)
- [CITREA_MAINNET_PREREQUISITES.md](./CITREA_MAINNET_PREREQUISITES.md)
- [config/citrea/juiceswap_usdce_wcbtc_candidate.md](../config/citrea/juiceswap_usdce_wcbtc_candidate.md)
