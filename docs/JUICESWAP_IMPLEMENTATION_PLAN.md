# JuiceSwap Implementation Plan

## Summary

This document defines the first bounded implementation pass for a real Citrea CL venue adapter
against the approved venue target:

- venue: `JuiceSwap`
- adapter: `JuiceSwapClAdapter`
- first pair direction: `ctUSD / wcBTC`

This is an implementation-foundation milestone, not a mainnet-launch package.

## Contract Model Assumptions

The implementation assumes the official JuiceSwap contract model published in JuiceSwap docs:

- JuiceSwap V3 is a Uniswap V3 fork
- `UniswapV3Factory` is the canonical pool registry
- `NonfungiblePositionManager` is the canonical LP position surface
- V3 swap routing is handled through the V3 swap router
- `JuiceSwapGateway` is a convenience layer, not the adapter’s integration target

For Helix, that means the adapter should talk directly to:

- factory
- pool
- position manager
- swap router

and should intentionally defer:

- Gateway-specific token conversions
- JUSD ↔ svJUSD convenience paths
- multi-hop routing
- later venue abstractions

## Mapping To The Current Adapter Architecture

The current accepted Helix boundaries already fit JuiceSwap directly.

### `HelixVault`

Unchanged.

The vault still:

- prices shares off strategy `totalAssets()`
- does generic ERC-4626 accounting
- allocates to a strategy, not to a venue

### `ManagedClStrategy`

Unchanged in semantics.

The strategy still owns:

- owner / strategist authorization
- oracle freshness gating
- quote recomputation and validation
- deadlines
- max-loss and min-assets-out execution limits

### `JuiceSwapClAdapter`

This adapter owns the venue-specific CL logic:

- pool discovery through the JuiceSwap factory
- position state through the JuiceSwap position manager
- valuation in one-base-asset terms
- rebalance execution
- partial withdrawals
- fee harvest
- full unwind

## First Implementation Scope

This first pass is intentionally narrow.

### Included

- one configured pool only
- one configured base asset and one configured pair asset
- direct V3 position-manager integration
- direct V3 swap-router integration
- deterministic quote generation from live pool state
- one-base-asset settlement valuation
- full-unwind then remint rebalance model
- partial withdrawals via unwind to base and same-range remint

### Deferred

- multi-pool routing
- multi-hop swaps
- JuiceSwapGateway integration
- route optimization
- onchain quoter integration
- dynamic venue discovery beyond one configured pool
- mainnet deployment scripts
- cap tuning and production risk parameters
- Satsuma support

## Pair Direction

The first target pair direction for implementation is:

- `ctUSD / wcBTC`

### Why this pair for J1

- it matches the accepted Citrea product direction
- it keeps the implementation aligned with the intended Citrea user story
- it proves the adapter against the actual decimal asymmetry Helix will face:
  - `ctUSD`: 6 decimals
  - `wcBTC`: 18 decimals

### Important qualifier

This does **not** mean `ctUSD / wcBTC` is already approved for mainnet deployment.

It means:

- this is the right pair direction for the first engineering foundation pass
- final production launch still depends on oracle, liquidity, and operational review

## Oracle Assumptions

### What the current Helix strategy already assumes

`ManagedClStrategy` only gates execution on:

- a fresh oracle for the vault base asset

For this first implementation, the base asset is `ctUSD`, so tests can use a mock oracle and the
strategy boundary remains unchanged.

### What is intentionally deferred

This pass does **not** add:

- a new cross-asset oracle model
- a JuiceSwap-specific TWAP dependency inside Helix
- special-case `ctUSD` pricing logic inside the strategy

### Practical implication

For J1:

- adapter valuation uses live pool state and swap-fee-aware spot conversion into the base asset
- strategy oracle logic remains the same accepted freshness gate

For later production work:

- the exact `ctUSD` oracle path still needs explicit deployment approval

## J2 Launch-Shape Override

After the J2 hardening pass, the implementation and launch recommendation split:

- engineering foundation pair remains `ctUSD / wcBTC`
- first live strategy candidate should temporarily shift to `USDC.e / wcBTC`

Why:

- the current adapter now protects the pair leg locally
- but the current strategy boundary still depends on a fresh base-asset oracle
- reviewed official Citrea oracle docs still make `USDC/USD` and `BTC/USD` clearer than
  `ctUSD/USD`

So the production-shaped reading is:

- keep `ctUSD / wcBTC` for implementation fidelity
- prefer `USDC.e / wcBTC` for the first live strategy candidate until `ctUSD` gets an explicitly
  approved oracle path

## Venue Surface Assumptions

The implementation assumes the following JuiceSwap surfaces are canonical:

- `UniswapV3Factory`
- `NonfungiblePositionManager`
- V3 swap router

The implementation does **not** assume:

- custom JuiceSwap pool math beyond the published Uniswap V3 fork model
- gateway-only position flows
- additional admin-mediated routing steps

## Quote / Execute Model

The accepted Helix quote model still fits JuiceSwap.

### Adapter quote includes

- intent hash
- position version
- adapter assets before
- assets to deploy
- assets to withdraw
- estimated loss
- expected assets out
- expected adapter assets after

### Strategy validation remains unchanged

`ManagedClStrategy` still:

- recomputes the adapter quote from the same intent
- rejects tampered adapter facts
- checks deadlines
- checks base-asset oracle freshness

## Settlement NAV Versus Conservative Valuation

The adapter must preserve the accepted distinction:

- live settlement NAV
- conservative valuation

### Live settlement NAV

Live `grossAssets` is defined as:

- immediately realizable value in the vault base asset

In a JuiceSwap CL position, that means:

- base token balances count directly
- non-base balances are converted into base-asset value using the pool price
- the conversion is swap-fee-aware so the value reflects a realizable one-base-asset unwind

### Conservative valuation

Conservative value remains:

- haircuted from the live gross figure
- visible in `netAssets`
- not used as the ERC-4626 settlement base

## Implementation Notes For J1

### Why direct V3 periphery, not Gateway

The Gateway is useful for end-user flows, but it adds extra behavior that Helix does not need for a
bounded adapter foundation:

- automatic token conversion
- JUSD / svJUSD convenience wrapping
- cBTC / WcBTC gateway behavior

Helix needs a narrower and more auditable venue surface than that.

### Why full-unwind / remint

This first adapter foundation uses:

- full unwind to base
- exact withdrawal in base
- remint of the target position

That is not the final capital-efficiency path, but it is:

- easier to reason about
- easier to test
- aligned with the current quote/validate/execute model

## Review Focus

Human review for this milestone should focus on:

1. whether the JuiceSwap contract assumptions are represented correctly
2. whether the adapter keeps settlement NAV versus conservative valuation clean
3. whether the single-pool and direct-periphery assumptions are narrow enough for J1
4. whether the deferred items are the right ones to leave out

## References

- [JuiceSwap Smart Contracts](https://docs.juiceswap.com/smart-contracts.html)
- [JuiceSwap Liquidity](https://docs.juiceswap.com/liquidity.html)
- [JuiceSwap Overview](https://docs.juiceswap.com/overview.html)
- [JuiceSwap v3-core](https://github.com/JuiceSwapxyz/v3-core)
- [JuiceSwap v3-periphery](https://github.com/JuiceSwapxyz/v3-periphery)
