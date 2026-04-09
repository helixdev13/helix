# Citrea Mainnet Prerequisites

## Summary

This is the short pre-broadcast checklist for the accepted first live candidate:

- venue: `JuiceSwap`
- pair: `USDC.e / wcBTC`
- posture: disabled by default until explicit enable

## Required Wallets

- deployer wallet with the private key available to the operator running `forge script`
- owner wallet or multisig that will own the vault and approve strategy attachment / cap changes
- guardian wallet that can react quickly to pause or withdraw-only incidents
- strategist wallet for live rebalance operations after enable

## Required Funding

- enough `cBTC` in the deployer wallet to cover both deployment scripts and verification reads
- a small extra `cBTC` buffer for reruns if the same-day broadcast sequence needs to be repeated

## Same-Day Verification Before Broadcast

On the same day as broadcast, verify:

- `chainid == 4114`
- `USDC.e` address and decimals still match repo config
- `wcBTC` address and decimals still match repo config
- `OracleRouter.getPrice(USDC.e)` succeeds and is fresh
- `OracleRouter.getPrice(wcBTC)` succeeds and is fresh
- `JuiceSwap` factory still resolves the approved `3000` pool
- the approved pool still reports:
  - token0 = `wcBTC`
  - token1 = `USDC.e`
  - fee = `3000`
  - tick spacing = `60`

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

## Before First Enable

Do not enable productive allocation until:

- the candidate scripts have completed successfully
- the strategy is attached but `maxAllocationBps` remains `0`
- the owner and guardian have confirmed the initial productive envelope
- public pool depth has been re-reviewed
- the guardian runbook is open and actionable

## Abort Conditions

Do not broadcast if any of the following occurs:

- missing or stale oracle path for `USDC.e`
- missing or stale oracle path for `wcBTC`
- approved pool address mismatch
- fee-tier mismatch
- deployer wallet not funded with enough `cBTC`
- owner or guardian addresses not finalized
- targeted tests fail on the deployment day
