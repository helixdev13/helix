# JuiceSwap Oracle Freeze

## Summary

This document freezes the production oracle configuration for the first live Helix Citrea candidate:

- venue: `JuiceSwap`
- pair: `USDC.e / wcBTC`
- pool: `0xD77f369715E227B93D48b09066640F46F0B01b29`

This freeze is only for the current live candidate.

## Frozen Source Contracts

### `USDC.e`

- Helix asset: `USDC.e`
- asset address: `0xE045e6c36cF77FAA2CfB54466D71A3aEF7bbE839`
- source price feed: RedStone `USDC/USD`
- source proxy address: `0xf0DEbDAE819b354D076b0D162e399BE013A856d3`
- source feed decimals: `8`
- frozen Helix heartbeat: `21600`

### `wcBTC`

- Helix asset: `wcBTC`
- asset address: `0x3100000000000000000000000000000000000006`
- source price feed: RedStone `BTC/USD`
- source proxy address: `0xc555c100DB24dF36D406243642C169CC5A937f09`
- source feed decimals: `8`
- frozen Helix heartbeat: `21600`

## Required Helix Oracle Wrapper

The current Helix `OracleRouter` expects sources exposing:

- `latestPrice() -> (price, updatedAt)`

The frozen Citrea RedStone proxies expose:

- `latestRoundData()`
- `decimals()`

This is why the live candidate must use:

- `AggregatorV3OracleAdapter`

Required mapping inside `OracleRouter`:

- `USDC.e -> deployed AggregatorV3OracleAdapter(0xf0DE...)`
- `wcBTC -> deployed AggregatorV3OracleAdapter(0xc555...)`

## Same-Day Signoff Checks Before Broadcast

Run these checks again on the same day as deployment or first enablement:

1. confirm the official Citrea oracle docs still point to RedStone on Citrea mainnet
2. confirm the RedStone Citrea mainnet feed list still includes:
   - `USDC` at `0xf0DEbDAE819b354D076b0D162e399BE013A856d3`
   - `BTC` at `0xc555c100DB24dF36D406243642C169CC5A937f09`
3. confirm `latestRoundData()` succeeds on both source proxies
4. confirm both source proxies still report `decimals() == 8`
5. confirm `OracleRouter.getConfig(USDC.e).heartbeat == 21600`
6. confirm `OracleRouter.getConfig(wcBTC).heartbeat == 21600`
7. confirm `OracleRouter.getPrice(USDC.e)` succeeds
8. confirm `OracleRouter.getPrice(wcBTC)` succeeds
9. confirm the approved JuiceSwap pool is still:
   - `0xD77f369715E227B93D48b09066640F46F0B01b29`
   - fee tier `3000`
   - token0 `wcBTC`
   - token1 `USDC.e`
10. confirm `observe([1800,0])` succeeds on the approved pool
11. confirm the pool has enough same-day depth for the intended first productive allocation

## Signoff Rule

Do not broadcast or first-enable the live candidate if any oracle source address, wrapper mapping, heartbeat, or same-day price-read check differs from this freeze without an explicit review update.
