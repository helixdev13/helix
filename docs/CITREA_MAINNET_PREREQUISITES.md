# Citrea Mainnet Prerequisites

## Summary

This is the short pre-broadcast checklist for the accepted first live candidate:

- venue: `JuiceSwap`
- pair: `USDC.e / wcBTC`
- posture: disabled by default until explicit enable

## Required Wallets

- deployer wallet `0xad53D0aBC81Ff8a42d6C3620Dc91B275C898EDF7` with the private key available to the operator running `forge script`
- final owner EOA `0x7C3244f1071Fb9849521f4B15dcFd20433F13f35` that will own the vault and approve strategy attachment / cap changes
- guardian wallet `0x7eB55a7bEe37B985b0fA10c262Ed712D1DEad742` that can react quickly to pause or withdraw-only incidents
- strategist wallet `0xC89044F853a0F004AE5b0daD8A384A52bd2D73bF` for live rebalance operations after enable

## Required Funding

- enough `cBTC` in the deployer wallet to cover both deployment scripts and verification reads
- a small extra `cBTC` buffer for reruns if the same-day broadcast sequence needs to be repeated
- enough `cBTC` in the final owner wallet only if ownership acceptance will be executed directly from an EOA
- enough `cBTC` in the final owner Safe if ownership acceptance and later owner actions will be executed from the Safe
- enough `cBTC` in the guardian wallet before any live operating window
- enough `cBTC` in the strategist wallet before any planned productive rebalance

## Same-Day Verification Before Broadcast

On the same day as broadcast, verify:

- `chainid == 4114`
- `USDC.e` address and decimals still match repo config
- `wcBTC` address and decimals still match repo config
- `OracleRouter.getPrice(USDC.e)` succeeds and is fresh
- `OracleRouter.getPrice(wcBTC)` succeeds and is fresh
- `OracleRouter.getConfig(USDC.e).heartbeat == 21600`
- `OracleRouter.getConfig(wcBTC).heartbeat == 21600`
- `JuiceSwap` factory still resolves the approved `3000` pool
- the approved pool still reports:
  - token0 = `wcBTC`
  - token1 = `USDC.e`
  - fee = `3000`
  - tick spacing = `60`
- `observe([1800,0])` succeeds on the approved pool

## Before Live Deployment, Re-Test

Re-run at minimum:

- `forge build`
- `forge test --match-contract JuiceSwapUsdcLiveCandidateTest -vvv`
- `forge test --match-contract JuiceSwapClAdapterTest -vvv`
- `forge test --match-contract JuiceSwapManagedClIntegrationTest -vvv`
- `CITREA_RPC_URL=https://rpc.mainnet.citrea.xyz forge test --match-contract JuiceSwapCitreaLaunchForkTest -vvv`

## Deployment Posture Checks

Before calling the candidate deployment script, confirm:

- the `USDC.e` vault exists or will be created through the dedicated script
- the vault owner is the broadcaster that will attach the strategy
- the `RiskEngine` owner is the broadcaster that will set the launch config
- the target vault currently has no strategy attached
- the intended deposit cap is still `25_000e6` unless separately re-approved
- the intended `maxAllocationBps` at setup is still `0`
- the final owner address is already fixed
- the guardian address is already fixed
- the strategist address is already fixed

## Before First Enable

Do not enable productive allocation until:

- the candidate scripts have completed successfully
- the strategy is attached but `maxAllocationBps` remains `0`
- the owner and guardian have confirmed the initial productive envelope
- public pool depth has been re-reviewed against the exact first-enable gate:
  - `USDC.e.balanceOf(pool) >= 15_000e6`
  - `OracleRouter.quoteAsset(wcBTC, wcBTC.balanceOf(pool)) >= 15_000e6`
  - `observe([1800,0])` succeeds
  - both frozen oracle reads succeed immediately before enable
- the guardian runbook is open and actionable

## Abort Conditions

Do not broadcast if any of the following occurs:

- missing or stale oracle path for `USDC.e`
- missing or stale oracle path for `wcBTC`
- approved pool address mismatch
- fee-tier mismatch
- heartbeat mismatch from `21600`
- `observe([1800,0])` failure on the approved pool
- first-enable liquidity signoff failure
- deployer wallet not funded with enough `cBTC`
- owner or guardian addresses not finalized
- targeted tests fail on the deployment day

## Source-Of-Truth Operator Docs

- [JUICESWAP_OPERATOR_HANDOFF.md](./JUICESWAP_OPERATOR_HANDOFF.md)
- [JUICESWAP_LIVE_RUNBOOK.md](./JUICESWAP_LIVE_RUNBOOK.md)
- [JUICESWAP_ORACLE_FREEZE.md](./JUICESWAP_ORACLE_FREEZE.md)
