# JuiceSwap Risks

## Summary

This document focuses on JuiceSwap-specific and launch-specific risks after J2 hardening.

The main point is not that the adapter is unsafe in principle.
The main point is that the launch envelope must stay narrower than the engineering foundation.

## Current Recommendation

As of April 9, 2026:

- JuiceSwap remains the most legible Citrea CL venue for Helix
- the accepted adapter foundation is now materially closer to production shape
- the first live pair should still favor oracle cleanliness over thesis purity

That means:

- `USDC.e / wcBTC` is safer than `ctUSD / wcBTC` for first live launch

## What Is Production-Shaped Already

The current JuiceSwap adapter candidate already has the following important properties:

- direct V3 periphery integration rather than gateway dependence
- single-pool deterministic configuration
- fee-growth-aware pending fee accounting
- pair-leg oracle sanity checks inside the adapter
- oracle-bounded quote-to-base liquidation on collapse, harvest, withdraw, and unwind paths
- post-rebalance version consistency in execution reporting

## What Is Still Mock-Simplified

The current harness and test surface still simplify several real-market behaviors:

- swap execution is modeled as deterministic single-hop execution without real market impact curves
- pool price movement is injected directly rather than emerging from real order flow
- fee-growth behavior is modeled from global/tick growth, but not from a fully realistic crossing and
  observation environment
- no real TWAP reads are used by the adapter itself
- no real mainnet pool-address freeze or pool-by-pool review is enforced in code yet

These are not blockers for the J2 milestone, but they are part of the launch decision.

## Oracle Risks

### Base-asset oracle risk

Helix strategy semantics still rely on a fresh oracle for the vault base asset.

Implication:

- `USDC.e / wcBTC` is materially cleaner for a live launch than `ctUSD / wcBTC`

because reviewed official Citrea docs show:

- `USDC/USD`
- `BTC/USD`

while they do not clearly show:

- `ctUSD/USD`

### Pair-leg oracle risk

The adapter now protects against pair-leg spot abuse better than the J1 baseline, but that still
depends on:

- a live pair-leg oracle
- a credible heartbeat
- operational monitoring

If the pair-leg oracle is stale, missing, or misconfigured:

- the adapter should not be considered live-safe

## Liquidity Risks

Public JuiceSwap metrics remain small enough that Helix must assume:

- exits can move the market
- fee revenue can be lumpy
- pool choice matters more than venue name alone

Practical implication:

- small initial caps
- one pair only
- one fee tier only
- strategy disabled unless public depth is reviewed again immediately before launch

## Venue Governance And Control Risks

Reviewed JuiceSwap docs present a favorable surface:

- no upgradeable proxies
- no admin keys
- veto-based governance with timelock
- TWAP-based protections in JuiceSwap's own fee-collection system

But Helix still inherits venue-level risk from:

- governance-approved contract changes around fee collection or supported bridged tokens
- pool-specific liquidity deterioration
- assumptions about WcBTC and bridged stable support

## Asset Risks

### `ctUSD / wcBTC`

Strengths:

- strongest Citrea-aligned product thesis
- native stable direction

Risks:

- no clearly documented official `ctUSD/USD` oracle path in the reviewed Citrea oracle page
- stronger dependence on a Helix-specific oracle approval decision

### `USDC.e / wcBTC`

Strengths:

- cleaner official oracle coverage
- less ambiguity for the first live strategy boundary

Risks:

- bridged stable risk
- less aligned with the native-stable Citrea thesis

## Conditions Under Which JuiceSwap Should Stay Disabled

JuiceSwap should remain disabled for live Helix strategy use if:

- the intended base asset lacks an approved production oracle path
- the exact live pool has not been reviewed
- public liquidity is too thin for the intended cap
- guardian operations are not staffed for Citrea-specific response times
- the venue contract or governance assumptions change materially

## Bottom Line

The adapter is now strong enough to define a production-shaped candidate.

The remaining launch risk is no longer mostly about adapter code.
It is about:

- choosing the cleaner first live pair
- enforcing a small cap
- and refusing to enable the strategy unless the exact oracle and pool assumptions are rechecked

## References

- [Citrea Oracles & VRF](https://docs.citrea.xyz/developer-documentation/ecosystem-tooling/oracles-vrf)
- [Citrea USD: ctUSD](https://docs.citrea.xyz/developer-documentation/citrea-usd-ctusd)
- [JuiceSwap Smart Contracts](https://docs.juiceswap.com/smart-contracts.html)
- [JuiceSwap on DefiLlama](https://defillama.com/protocol/juiceswap)
