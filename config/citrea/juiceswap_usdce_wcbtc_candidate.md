# Citrea JuiceSwap `USDC.e / wcBTC` Candidate

## Summary

This file is the concrete configuration profile for the first live Helix candidate on Citrea.

It is not the current release profile.

Current release:

- `HLX-ctUSD Base`
- no strategy
- `maxAllocationBps = 0`

First live candidate:

- vault asset: `USDC.e`
- venue: `JuiceSwap`
- pair: `USDC.e / wcBTC`
- approved fee tier: `3000`
- one pool only
- disabled by default until explicit enable conditions are met

## Chain Metadata

- chain name: `Citrea Mainnet`
- chain id: `4114`
- RPC: `https://rpc.mainnet.citrea.xyz`
- explorer: `https://explorer.mainnet.citrea.xyz`

## Asset Metadata

### Base asset

- token: `USDC.e`
- address: `0xE045e6c36cF77FAA2CfB54466D71A3aEF7bbE839`
- decimals: `6`
- role: first live Helix Citrea candidate base asset

### Pair asset

- token: `wcBTC`
- address: `0x3100000000000000000000000000000000000006`
- decimals: `18`
- role: approved BTC-side live-candidate pair leg

## JuiceSwap Mainnet Metadata

- `UniswapV3Factory`: `0xd809b1285aDd8eeaF1B1566Bf31B2B4C4Bba8e82`
- `SwapRouter`: `0x565eD3D57fe40f78A46f348C220121AE093c3cF8`
- `NonfungiblePositionManager`: `0x3D3821D358f56395d4053954f98aec0E1F0fa568`

### Approved live pool only

- pair: `USDC.e / wcBTC`
- approved fee tier: `3000`
- approved pool: `0xD77f369715E227B93D48b09066640F46F0B01b29`
- token0: `wcBTC`
- token1: `USDC.e`
- tick spacing: `60`

### Observed but not approved

- `500` fee tier pool: absent when checked on April 9, 2026
- `10000` fee tier pool: `0x43AAec0c03d56f3839b0467240ea01a86774c0a7`

Only the `3000` pool is approved for the first live Helix candidate.

## Oracle Assumptions

Required live oracle paths:

- `USDC/USD`
- `BTC/USD`

This is why the first live candidate uses `USDC.e / wcBTC` instead of `ctUSD / wcBTC`.

## Helix Address Placeholders

- `RiskEngine`: `TBD`
- `OracleRouter`: `TBD`
- `VaultFactory`: `TBD`
- `HLX-USDCe-Base`: `TBD`
- `JuiceSwapClAdapter`: `TBD`
- `ManagedClStrategy`: `TBD`

## Initial Launch Posture

- vault name: `Helix USDC.e Base`
- vault symbol: `HLX-USDCe-Base`
- strategy: attached only after candidate stack deployment
- deposit cap: `25_000e6`
- `maxAllocationBps = 0`
- `paused = false`
- `withdrawOnly = false`

This means:

- the productive stack can be deployed and attached
- productive allocation still remains disabled until owner approval

## Initial Enable Envelope

If the owner enables productive allocation without changing `depositCap`, the initial ceiling is:

- `maxAllocationBps <= 2000`
- absolute productive cap: `5_000e6`

Do not exceed that envelope without a separate launch review.

## Verification Checklist

Before enabling the candidate, verify:

- `vault.asset() == USDC.e`
- `vault.strategy() == deployed strategy`
- `RiskEngine.getConfig(vault).maxAllocationBps == 0`
- `RiskEngine.getConfig(vault).depositCap == 25_000e6`
- `OracleRouter.getPrice(USDC.e)` succeeds
- `OracleRouter.getPrice(wcBTC)` succeeds
- `factory.getPool(USDC.e, wcBTC, 3000) == 0xD77f369715E227B93D48b09066640F46F0B01b29`

## Sources

- [Canonical Contract Addresses](https://docs.citrea.xyz/developer-documentation/canonical-contract-addresses)
- [Oracles & VRF](https://docs.citrea.xyz/developer-documentation/ecosystem-tooling/oracles-vrf)
- [JuiceSwap Smart Contracts](https://docs.juiceswap.com/smart-contracts.html)
