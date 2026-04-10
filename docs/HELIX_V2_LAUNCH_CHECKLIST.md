# Helix V2 Launch Checklist

## Summary

This checklist captures the launch pattern Helix should follow if it wants the PancakeBunny-style product shape without copying the fragile parts.

It is for future v2 launches only:

- not the frozen `JuiceSwap` live lane
- not the already-deployed auto-compound stack unless a deliberate enablement review is requested

## Ship First

The first launchable v2 product should be:

- `HLX-USDC.e Smart Vault`
- single-asset
- stable-denominated
- supply-only
- disabled by default
- hard-capped
- idle-fallback capable
- emergency-unwind capable

The first launch should also preserve the current Helix product boundaries:

- strategy policy stays in the strategy layer
- venue mechanics stay in the adapter layer
- live deployment config stays separate from launch planning

## Launch Sequence

1. Preserve the frozen `USDC.e / wcBTC` JuiceSwap lane.
2. Keep the deployed auto-compound stack disabled by default unless explicitly reviewed for enablement.
3. Keep ownership and post-deploy verification complete before any future launch.
4. Keep the first v2 launch narrow: one vault, one lane, one cap.
5. Add breadth only after the first lane is stable.

## Delay

These should stay out of the first launch:

- multi-venue routing
- leverage
- maximizer layers
- reward-token reflexivity as a launch story
- venue-specific adapters that have not cleared diligence
- broad product expansion before the first vault is stable

## Never Copy

PancakeBunny’s launch pattern shows what not to make central:

- emissions-first positioning
- leverage-first positioning
- token-price-dependent APY narratives
- broad rollout before a narrow core vault is stable
- fragile incentive mechanics that substitute for product discipline

## Practical Exit Criteria

Before any future v2 launch:

- the target lane is disabled by default until explicitly enabled
- ownership handoff is complete
- read-only verification is complete
- the intended venue has passed same-day checks
- the launch cap and withdrawal behavior are explicit
- the fallback path is readable and test-backed

## Sources

- [PancakeBunny BUNNY token docs](https://pancakebunny-finance.readthedocs.io/en/main/bunnytoken.html)
- [PancakeBunny Vaults docs](https://pancakebunny-finance.readthedocs.io/en/main/vaults.html)
- [Bunny roadmap](https://docs.mound.finance/bunny/resources/roadmap)
- [Leveraged Farming Opens on Bunny](https://pancakebunny.medium.com/leveraged-farming-opens-on-bunny-e5953c6afd8f)
