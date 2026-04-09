# Satsuma Adapter Spec

## Summary

This document defines what a `Satsuma` adapter would need if Helix later integrates Satsuma as a
Citrea concentrated-liquidity venue.

This is a specification only.
It does **not** change any accepted contracts.

## Current Position

As of April 8, 2026:

- Satsuma is not yet approved for adapter design
- this spec therefore describes a contingent design path
- no contract changes should be made until Satsuma's venue surface becomes legible

## Design Goal

If Satsuma becomes sufficiently legible, Helix should be able to support it without changing the
accepted layering:

- `HelixVault` = generic accounting
- `ManagedClStrategy` = policy, oracle freshness, quote validation
- `SatsumaAdapter` = venue-specific CL logic

## Exact Compatibility Assumptions

A first Satsuma adapter would need all of the following to be true.

### 1. Pool discovery is deterministic

The adapter must be able to determine the relevant live pool or pools from a published venue
surface such as:

- a factory contract
- a registry contract
- a canonical router registry

### 2. LP positions are addressable

The adapter must be able to identify and manage a concrete position through a published venue model
such as:

- position NFTs
- a position key
- a vault share wrapper with direct position introspection

### 3. Liquidity operations are programmable

The adapter must be able to:

- add liquidity
- increase liquidity
- decrease liquidity
- collect fees
- remove liquidity fully

### 4. Position state is readable onchain

The adapter must be able to read enough state to produce Helix valuation and quote surfaces:

- token balances owed
- active liquidity
- tick range or equivalent
- fee accrual state
- pool price state

### 5. Swap execution is available

Because Helix settles a single-asset vault, the adapter must be able to convert the non-base leg
of the CL position back into the vault asset when withdrawing or unwinding.

That requires:

- a swap router or equivalent
- deterministic route assumptions
- slippage bounds that can be surfaced through the adapter quote

## Is The Current `ManagedClStrategy` Boundary Sufficient?

### Answer

- yes, conditionally

The current `ManagedClStrategy` boundary is sufficient **if** Satsuma exposes a normal venue
surface for:

- pool discovery
- position state reads
- liquidity management
- fee collection
- swaps

### Why

The accepted strategy boundary already owns:

- role checks
- oracle freshness gate
- quote validation
- deadlines
- loss bounds

The adapter boundary already owns:

- position state
- venue-specific quote generation
- venue-specific execution
- valuation
- partial withdrawals
- unwind logic

That is the correct place for a Citrea CL venue integration.

## What Additional Adapter Methods Or Structs Would Be Required?

### Strategy / vault surface

- no new `HelixVault` methods required
- no new `ManagedClStrategy` methods required
- no accepted protocol semantic changes should be made for Satsuma alone

### Adapter-local requirements

A Satsuma adapter would likely need venue-specific constructor config such as:

- pool or factory reference
- router reference
- position-manager reference
- token0 / token1 orientation
- preferred fee tier or pool selector
- default swap path for unwinds

These can remain adapter-local and do not justify changing `IManagedStrategy` or `IStrategy`.

## Does The Current Quote / Execute Split Still Fit?

### Answer

- yes

The current quote / validate / execute model still fits a real Citrea CL venue.

### Adapter quote must still provide deterministic execution facts

A Satsuma adapter should still quote:

- `intentHash`
- `positionVersion`
- `adapterAssetsBefore`
- `assetsToDeploy`
- `assetsToWithdraw`
- `estimatedLoss`
- `expectedAssetsOut`
- `expectedAdapterAssetsAfter`

### Strategy validation still works

`ManagedClStrategy` should still:

- recompute the fresh adapter quote
- reject mismatched quote facts
- enforce deadlines
- enforce oracle freshness

### Practical blocker

If Satsuma does not expose a canonical quote helper or enough deterministic pool state to compute a
quote onchain, then adapter design should remain blocked.

## Valuation Requirements

The adapter must preserve the accepted distinction between:

- live settlement NAV
- conservative / risk valuation

### Live settlement NAV

For ERC-4626 settlement, the adapter must expose gross withdrawable value in vault-asset units.

That means a Satsuma adapter must be able to estimate:

- withdrawable fees
- withdrawable principal
- post-swap base-asset amount after collapsing the non-base leg

### Conservative valuation

The richer risk view can still expose:

- haircuted value
- liquidity risk discount
- wider slippage assumptions
- stale or degraded oracle flags

But that value must remain separate from live settlement NAV.

## Withdrawal And Unwind Assumptions

### Partial withdrawal

A Satsuma adapter must support:

1. determine how much liquidity to remove to satisfy the shortfall
2. decrease liquidity
3. collect accrued fees
4. swap the non-base asset into the vault asset
5. return exact or bounded assets back to the strategy

### Full unwind

A Satsuma adapter must support:

1. remove all remaining liquidity
2. collect all accrued fees
3. swap remaining non-base inventory into the vault asset
4. return all resulting vault-asset balance to the strategy

### Launch assumption

If Satsuma cannot support deterministic partial exits with acceptable slippage bounds, Helix should
not integrate it as the first Citrea CL venue.

## Oracle Requirements

## Preferred pair direction: `ctUSD / wcBTC`

### What is clean

Reviewed official Citrea oracle docs list:

- `BTC/USD`

That makes the `wcBTC` side legible through a `BTC/USD` feed.

### What is not clean

Reviewed official Citrea oracle docs do **not** list:

- `ctUSD/USD`

That creates a specific adapter-design burden.

For `ctUSD / wcBTC`, a production adapter would need one of:

- an approved `ctUSD` stable-value assumption
- a secondary trusted `ctUSD` reference path
- a valuation path that crosses through a more legible stable reference

## Alternate pair direction: `USDC.e / wcBTC`

### Why it is cleaner technically

Reviewed official Citrea oracle docs list:

- `USDC/USD`
- `BTC/USD`

That makes `USDC.e / wcBTC` a cleaner oracle pair for early execution logic.

### Why it is weaker strategically

It is less aligned with Helix's accepted Citrea product thesis than `ctUSD`.

## Which Parts Reuse The Current Adapter Model Unchanged

The following conceptual pieces can be reused without changing accepted protocol semantics:

- one-vault / one-base-asset settlement
- strategy-side quote recomputation and validation
- adapter-side `PositionState`
- adapter-side `Valuation`
- partial-withdraw flow
- full-unwind flow
- conservative valuation separated from live NAV

## Which Parts Would Be Satsuma-Specific

These parts would be venue-specific:

- pool discovery
- liquidity call surface
- swap router interface
- fee-tier model
- LP position representation
- fee-collection logic
- any pause or admin checks needed for risk gating

## Open Blockers Before Any Code

No adapter coding should begin for Satsuma until the following become legible from project sources:

- contract addresses
- core or periphery repositories
- LP position representation
- governance and admin surface
- upgradeability stance

## Final Position

The accepted Helix architecture is already sufficient for a Satsuma adapter in principle.

The current blocker is not architecture.
The blocker is missing venue legibility.

## References

- [SATSUMA_DILIGENCE.md](./SATSUMA_DILIGENCE.md)
- [ADAPTER_ARCHITECTURE.md](./ADAPTER_ARCHITECTURE.md)
- [REBALANCE_FLOW.md](./REBALANCE_FLOW.md)
- [Citrea Oracles](https://docs.citrea.xyz/developer-documentation/ecosystem-tooling/oracles-vrf)

## Related Docs

- [SATSUMA_DILIGENCE.md](./SATSUMA_DILIGENCE.md)
- [CITREA_CL_DECISION.md](./CITREA_CL_DECISION.md)
- [ADAPTER_ARCHITECTURE.md](./ADAPTER_ARCHITECTURE.md)
