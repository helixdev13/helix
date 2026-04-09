# Citrea Asset Matrix

## Summary

This matrix compares the main Citrea asset candidates Helix could use after the first
`HLX-ctUSD Base` release.

Where possible, decimals below were verified directly against Citrea Mainnet RPC on April 8, 2026.

## Asset Matrix

| Asset | Decimals | Type | Likely Helix role | Oracle availability from reviewed official sources | Main dependency surface | First base vault | First allocator | First CL pair | Current recommendation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `ctUSD` | `6` | Native Citrea stablecoin, fiat-backed | Primary stable asset | No official `ctUSD/USD` feed found in reviewed Citrea oracle docs | `ctUSD` issuer / liquidity concentration | `yes` | `not yet confirmed` | `yes`, as stable leg | `primary` |
| `wcBTC` | `18` | Citrea-native wrapped BTC path | BTC-side exposure and likely CL counterpart | Official Citrea docs list `BTC/USD`; Zentra publishes a `WcBTCRedStoneAdapter` | Clementine / bridge peg plus BTC volatility | `no` | `no` | `yes`, as BTC leg | `primary BTC-side candidate` |
| `USDC.e` | `6` | Bridged stablecoin | Contingent first allocator asset | Official Citrea docs list `USDC/USD` | Bridge risk plus issuer risk | `no` | `yes, but only if an allocator venue is later approved` | `possible` | `contingent allocator asset` |
| `USDT.e` | `6` | Bridged stablecoin | Secondary stable / routing asset | Official Citrea docs list `USDT/USD` | Bridge risk plus issuer risk | `no` | `later only` | `later only` | `avoid for first product` |
| `WBTC.e` | `8` | Bridged BTC wrapper | Secondary BTC exposure | No reviewed official Citrea oracle page evidence for `WBTC.e` specifically | Bridge plus custodian plus BTC risk | `no` | `no` | `later only` | `avoid for now` |
| `JUSD` | `18` | Protocol-local stablecoin | Juice ecosystem-specific asset only | No reviewed official Citrea oracle evidence | JuiceDollar protocol and governance dependency | `no` | `no` | `only if Juice-specific later` | `avoid for now` |

## Asset Notes

## `ctUSD`

### Why it matters

- it is Citrea’s native stablecoin thesis
- it remains the cleanest first Helix asset
- it aligns with the accepted `HLX-ctUSD Base` launch path

### Limitation

- no official `ctUSD/USD` oracle feed was found in the reviewed Citrea oracle docs
- no reviewed lender venue clearly confirmed `ctUSD` support yet

### Helix view

- best first base-vault asset
- still the preferred stable leg for the first CL direction

## `wcBTC`

### Why it matters

- it is the most Citrea-native BTC exposure path reviewed here
- Citrea uses it broadly across ecosystem materials
- it is already supported in Zentra docs and JuiceSwap docs

### Important metadata

- `wcBTC` on Citrea Mainnet currently reports `18` decimals, not `8`

### Helix view

- not the first standalone Helix base-vault asset
- best BTC-side counterpart for a future `ctUSD / wcBTC` CL direction

## `USDC.e`

### Why it matters

- official Citrea oracle docs list `USDC/USD`
- Zentra’s contract-address page explicitly lists `USDC`
- current lender-side docs are much more `USDC`-centric than `ctUSD`-centric

### Limitation

- it is still a bridged stablecoin, not Citrea’s native stable

### Helix view

- if Helix later launches a first allocator, `USDC.e` is the most plausible first allocator asset
- that recommendation is contingent on allocator venue approval

## `USDT.e`

### Why it matters

- official Citrea oracle docs list `USDT/USD`

### Limitation

- it adds bridge risk and issuer risk without a clear product advantage over `ctUSD` or `USDC.e`

### Helix view

- not a first-product asset

## `WBTC.e`

### Why it matters

- it is a recognizable BTC wrapper

### Limitation

- it adds a second BTC wrapper path on top of `wcBTC`
- it is less aligned with Citrea’s native BTC thesis
- no reviewed official oracle evidence made it a stronger choice than `wcBTC`

### Helix view

- avoid for now

## `JUSD`

### Why it matters

- it is relevant only because JuiceSwap is a potential later venue

### Limitation

- it is protocol-local
- it increases dependency on the JuiceDollar ecosystem
- it is not the right first Helix stable thesis on Citrea

### Helix view

- mention it
- do not center Helix’s first productive Citrea product on it

## Explicit Recommendations

### Best first base-vault asset

- `ctUSD`

### Best first allocator asset

- `USDC.e`

Important qualifier:

- this is a contingent allocator recommendation only
- no allocator venue is approved yet
- `ctUSD` remains the preferred Helix asset overall, but current lender-side evidence is more
  `USDC`-ready than `ctUSD`-ready

### Best first CL-pair direction

- `ctUSD / wcBTC`

Why:

- `ctUSD` is the preferred stable leg
- `wcBTC` is the most Citrea-native BTC leg
- this direction avoids anchoring Helix to `JUSD` as its first CL stable thesis

## References

- [Citrea USD: ctUSD](https://docs.citrea.xyz/developer-documentation/citrea-usd-ctusd)
- [Canonical Contract Addresses](https://docs.citrea.xyz/developer-documentation/canonical-contract-addresses)
- [Oracles & VRF](https://docs.citrea.xyz/developer-documentation/ecosystem-tooling/oracles-vrf)
- [Zentra Contract Addresses](https://zentrafinance.gitbook.io/zentra/protocol/contract-addresses)
- [Zentra Oracle Docs](https://zentrafinance.gitbook.io/zentra/protocol/oracle)
- [JuiceSwap Overview](https://docs.juiceswap.com/overview.html)
- [JuiceSwap Smart Contracts](https://docs.juiceswap.com/smart-contracts.html)
- [Citrea chain page on DefiLlama](https://defillama.com/chain/citrea)
- [ctUSD on DefiLlama](https://defillama.com/stablecoin/citrea-usd)
