# Citrea Mainnet Configuration

## Summary

This is the documentation-first deployment profile for the first Helix Citrea release.

Release shape:

- product: `HLX-ctUSD Base`
- chain: `Citrea Mainnet`
- strategy: unset
- `maxAllocationBps = 0`

First live candidate, documented separately:

- product direction: `USDC.e / wcBTC` on `JuiceSwap`
- config profile: [juiceswap_usdce_wcbtc_candidate.md](/Users/melihkarakose/Desktop/helix/config/citrea/juiceswap_usdce_wcbtc_candidate.md)
- status: candidate only, not the accepted current release

## Chain Metadata

- chain name: `Citrea Mainnet`
- chain id: `4114`
- RPC: `https://rpc.mainnet.citrea.xyz`
- explorer: `https://explorer.mainnet.citrea.xyz`
- gas asset: `cBTC`

## Asset Metadata

### ctUSD

- token: `ctUSD`
- address: `0x8D82c4E3c936C7B5724A382a9c5a4E6Eb7aB6d5D`
- decimals: `6`
- role: first Helix Citrea release asset

## Core Address Placeholders

- `RiskEngine`: `TBD`
- `OracleRouter`: `TBD`
- `VaultFactory`: `TBD`
- `HelixLens`: `TBD`
- `HLX-ctUSD Base`: `TBD`

## Operator Address Placeholders

- `owner`: `TBD`
- `guardian`: `TBD`
- deployer / factory owner: `TBD`
- risk engine owner: `TBD`

## Initial Vault Configuration

- vault name: `Helix ctUSD Base`
- vault symbol: `HLX-ctUSD-Base`
- strategy: unset
- `paused = false`
- `withdrawOnly = false`
- `maxAllocationBps = 0`

## Initial Cap Recommendation

- placeholder recommendation: `50,000 ctUSD`
- raw units: `50_000e6`

This is intentionally conservative and should be explicitly approved before deployment.

## Verification Checklist

After deployment, verify:

- `asset == ctUSD`
- `guardian == configured guardian`
- `strategy == address(0)`
- `depositCap == configured cap`
- `maxAllocationBps == 0`
- `paused == false`
- `withdrawOnly == false`
- `totalStrategyAssets == 0`

## Release Notes

This profile intentionally avoids:

- live strategy risk
- venue dependency
- CL adapter dependency
- external allocator dependency

The first Citrea release is a controlled base-vault launch only.
