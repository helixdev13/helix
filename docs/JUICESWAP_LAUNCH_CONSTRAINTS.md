# JuiceSwap Launch Constraints

## Summary

This document defines the narrowest acceptable launch shape for a first live Helix strategy on
JuiceSwap on Citrea.

It distinguishes between:

- the engineering foundation pair used in J1 and J2
- the first live pair that is currently safest to approve

As of April 9, 2026:

- engineering foundation pair: `ctUSD / wcBTC`
- first live pair candidate: `USDC.e / wcBTC`

The reason for that split is simple:

- `ctUSD / wcBTC` still matches the intended Citrea product thesis
- `USDC.e / wcBTC` is materially cleaner for the first live launch because both legs have an
  officially documented Citrea oracle path, while `ctUSD/USD` still does not appear on the
  reviewed official Citrea oracle page

## Pair Decision

### Keep for engineering

- `ctUSD / wcBTC`

Why:

- it keeps the adapter honest about the intended Citrea product direction
- it exercises the real decimal asymmetry
- it keeps Helix grounded in the Citrea-native stable thesis

### Shift for the first live strategy candidate

- `USDC.e / wcBTC`

Why:

- official Citrea oracle docs list `USDC/USD`
- official Citrea oracle docs list `BTC/USD`
- the current Helix strategy boundary still assumes a fresh oracle for the vault base asset
- the adapter now checks the pair leg locally, but the base-asset oracle still matters at the
  strategy boundary

### What would allow `ctUSD / wcBTC` to become launchable

At least one of:

- an officially documented `ctUSD/USD` feed on Citrea
- an explicitly approved Helix oracle path for `ctUSD` with production operations around it
- a separately accepted Helix launch decision that treats `ctUSD` as a controlled stable
  assumption rather than a priced asset

Until one of those is true:

- `ctUSD / wcBTC` should remain an engineering and paper-design pair
- `USDC.e / wcBTC` is the safer live-launch candidate

## Allowed Venue Shape

The first live JuiceSwap strategy should remain constrained to:

- one pool only
- one fee tier only
- one configured base asset
- one configured pair asset
- one adapter deployment per pair

Do not approve at first launch:

- multiple fee tiers
- multi-hop routing
- gateway-only flows
- automatic bridged-token expansion
- multi-pool reallocation logic

## Allowed Fee Tier

The only fee tier that should be considered for first launch is:

- `3000` (`0.30%`)

Why:

- it is JuiceSwapGateway's documented default fee tier
- it is the fee tier the current adapter harness and assumptions already target
- widening to multiple fee tiers adds configuration risk without immediate launch value

## Cap Sizing

The first live JuiceSwap strategy should start with an intentionally small cap.

Recommended initial cap envelope:

- strategy disabled by default
- initial strategy allocation cap no higher than `10_000e6` if the base asset is a 6-decimal
  stable
- preferred first live cap: `5_000e6`

Rationale:

- JuiceSwap public 24h volume is still modest
- current public venue TVL is still small
- Helix should not become a dominant share of pool liquidity on day one

## Rebalance And Exit Constraints

The following should remain mandatory for first live use:

- adapter-local pair-leg oracle sanity
- adapter-local oracle-bounded liquidation minimum output
- single-pool deterministic routing
- guardian emergency unwind path tested against the live deployment shape

The following should remain disabled or out of scope:

- discretionary route changes
- multi-hop execution
- dynamic fee-tier switching
- strategy replacement without a full unwind

## Guardian Playbook Assumptions

First live JuiceSwap usage assumes:

- guardian can and will use emergency pause if the pool becomes operationally unsafe
- guardian responds to oracle failure, pair-leg oracle staleness, or unexplained output weakness
- operators monitor both the strategy base asset oracle and the adapter pair-leg oracle

Guardian should pause immediately if any of the following occurs:

- base-asset oracle becomes stale or unavailable
- pair-leg oracle becomes stale or unavailable
- repeated liquidation attempts fail on the adapter's min-out bound
- public pool liquidity falls materially below the intended unwind size
- venue governance or contract-surface assumptions change unexpectedly

## Conditions That Keep Strategy Disabled

Even with a deployed adapter, the first live JuiceSwap strategy should remain disabled if:

- the intended base asset does not have an approved production oracle path
- the exact live pool and fee tier are not separately reviewed
- public liquidity remains too thin for the intended cap
- operators do not have a Citrea-specific guardian runbook
- the deployed venue contracts differ materially from the reviewed contract surface

## Production-Safe Today Versus Deferred

### Production-shaped already

- direct factory / pool / position-manager / router model
- one-base-asset settlement
- adapter-local pair-leg sanity checks
- oracle-bounded quote-to-base liquidation
- fee-growth-aware pending fee accounting

### Still intentionally deferred

- mainnet pool selection and address freeze
- TWAP-aware Helix-side valuation beyond the venue's own surfaces
- multi-hop swap logic
- dynamic route selection
- broader asset expansion on JuiceSwap

## Launch Decision

If Helix wants the first live JuiceSwap strategy soon, the cleanest path is:

- keep `ctUSD / wcBTC` as the product-direction pair
- approve only `USDC.e / wcBTC` as the first live strategy candidate
- leave `ctUSD / wcBTC` disabled until the `ctUSD` oracle path is explicitly accepted

## References

- [Citrea Oracles & VRF](https://docs.citrea.xyz/developer-documentation/ecosystem-tooling/oracles-vrf)
- [Citrea USD: ctUSD](https://docs.citrea.xyz/developer-documentation/citrea-usd-ctusd)
- [JuiceSwap Smart Contracts](https://docs.juiceswap.com/smart-contracts.html)
- [JuiceSwap Liquidity](https://docs.juiceswap.com/liquidity.html)
- [JuiceSwap on DefiLlama](https://defillama.com/protocol/juiceswap)
