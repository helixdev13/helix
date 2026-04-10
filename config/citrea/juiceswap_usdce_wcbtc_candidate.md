# Citrea JuiceSwap `USDC.e / wcBTC` Candidate

## Summary

This file is the concrete configuration profile for the first live Helix candidate on Citrea.

Current deployed live lane:

- vault asset: `USDC.e`
- venue: `JuiceSwap`
- pair: `USDC.e / wcBTC`
- approved fee tier: `3000`
- one pool only
- deployment complete
- ownership accepted
- disabled by default until explicit enable conditions are met

## Chain Metadata

- chain name: `Citrea Mainnet`
- chain id: `4114`
- RPC: `https://rpc.mainnet.citrea.xyz`
- explorer: `https://explorer.mainnet.citrea.xyz`

## Frozen Public Address Watchlist

- `APPROVED_POOL`: `0xD77f369715E227B93D48b09066640F46F0B01b29`
- `USDCe`: `0xE045e6c36cF77FAA2CfB54466D71A3aEF7bbE839`
- `wcBTC`: `0x3100000000000000000000000000000000000006`
- `USDC_USD_FEED`: `0xf0DEbDAE819b354D076b0D162e399BE013A856d3`
- `BTC_USD_FEED`: `0xc555c100DB24dF36D406243642C169CC5A937f09`

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

## Oracle Freeze

Frozen production candidate mapping:

- `USDC.e` asset: `0xE045e6c36cF77FAA2CfB54466D71A3aEF7bbE839`
  - source feed: RedStone `USDC/USD`
  - source proxy: `0xf0DEbDAE819b354D076b0D162e399BE013A856d3`
  - source feed decimals: `8`
- `wcBTC` asset: `0x3100000000000000000000000000000000000006`
  - source feed: RedStone `BTC/USD`
  - source proxy: `0xc555c100DB24dF36D406243642C169CC5A937f09`
  - source feed decimals: `8`

Helix does not wire those proxies into `OracleRouter` directly.

Frozen Helix production shape:

- wrapper contract: `AggregatorV3OracleAdapter`
- `OracleRouter` heartbeat for `USDC.e`: `21600`
- `OracleRouter` heartbeat for `wcBTC`: `21600`

This is why the first live candidate uses `USDC.e / wcBTC` instead of `ctUSD / wcBTC`.

## Deployed Stack Reference

The human-readable deployed-address summary is tracked in:

- [CURRENT_DEPLOYED_STATE.md](../../docs/CURRENT_DEPLOYED_STATE.md)

## Ownership Posture

Deployment ownership is intentionally two-step:

- temporary deployment owner / `DEPLOYER_EOA`: `0xad53D0aBC81Ff8a42d6C3620Dc91B275C898EDF7`
- final owner: `0x7C3244f1071Fb9849521f4B15dcFd20433F13f35`
- guardian: `0x7eB55a7bEe37B985b0fA10c262Ed712D1DEad742`
- strategist: `0xC89044F853a0F004AE5b0daD8A384A52bd2D73bF`

Required sequence:

1. deploy core with broadcaster as temporary owner
2. configure `OracleRouter` with the frozen production oracle wrappers
3. create the `USDC.e` vault with broadcaster as temporary vault owner
4. deploy and attach the JuiceSwap candidate stack
5. transfer ownership of all candidate contracts to the final owner
6. final owner accepts ownership before any productive enablement

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
- `OracleRouter.getConfig(USDC.e).heartbeat == 21600`
- `OracleRouter.getConfig(wcBTC).heartbeat == 21600`
- `OracleRouter.getPrice(USDC.e)` succeeds
- `OracleRouter.getPrice(wcBTC)` succeeds
- `factory.getPool(USDC.e, wcBTC, 3000) == 0xD77f369715E227B93D48b09066640F46F0B01b29`
- `VaultFactory.owner() == FINAL_OWNER`
- `RiskEngine.owner() == FINAL_OWNER`
- `OracleRouter.owner() == FINAL_OWNER`
- `vault.owner() == FINAL_OWNER`
- `strategy.owner() == FINAL_OWNER`
- `observe([1800,0])` succeeds on the approved pool
- `USDC.e.balanceOf(approvedPool) >= 15_000e6`
- `OracleRouter.quoteAsset(wcBTC, wcBTC.balanceOf(approvedPool)) >= 15_000e6`

## First-Enable Liquidity Rule

For the first productive enablement only:

- keep `depositCap = 25_000e6`
- keep `maxAllocationBps <= 2000`
- do not enable unless both visible pool sides represent at least `15_000e6` of same-day notional depth

This is a conservative `3x` gross-depth gate against the initial `5_000e6` productive cap.

If this check fails, keep the candidate deployed but disabled.

## Wallet Funding Posture

- broadcaster EOA needs `cBTC` before disabled deployment broadcast
- final owner EOA needs `cBTC` only if it will run direct ownership acceptance
- final owner Safe needs `cBTC` before executing `acceptOwnership()` and later owner actions
- guardian should hold `cBTC` before any live operating window
- strategist should hold `cBTC` before any planned productive rebalance

## Sources

- [Canonical Contract Addresses](https://docs.citrea.xyz/developer-documentation/canonical-contract-addresses)
- [Oracles & VRF](https://docs.citrea.xyz/developer-documentation/ecosystem-tooling/oracles-vrf)
- [JuiceSwap Smart Contracts](https://docs.juiceswap.com/smart-contracts.html)
- [JUICESWAP_ORACLE_FREEZE.md](../../docs/JUICESWAP_ORACLE_FREEZE.md)
