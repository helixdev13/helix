# Helix Rebalance Flow

## Purpose

This document defines the rebalance flow for the managed CL strategy stack in Milestone 5A.

The flow is intentionally conservative and explicit so real venue adapters can later slot into the
same control path.

## High-Level Sequence

1. operator forms a `RebalanceIntent`
2. strategy calls adapter quote logic through `previewRebalance(...)`
3. owner or strategist submits `rebalance(intent, quote, limits)`
4. strategy validates caller, deadlines, quote freshness, and oracle freshness
5. strategy recomputes a fresh adapter quote from the same intent
6. strategy rejects the rebalance if any deterministic adapter-produced quote fact differs
7. strategy approves the adapter for `assetsToDeploy`
8. adapter validates the quote against current position state
9. adapter executes the mocked rebalance
10. strategy clears approval and emits the execution event

## RebalanceIntent

The intent describes the operator target:

- lower tick
- upper tick
- target liquidity
- assets to deploy from strategy idle
- assets to withdraw from deployed capital
- deadline

The intent is hashed and embedded in the quote so execution cannot silently drift away from the
quoted request.

## RebalanceQuote

The quote contains:

- `intentHash`
- `positionVersion`
- `quotedAt`
- `validUntil`
- `adapterAssetsBefore`
- `assetsToDeploy`
- `assetsToWithdraw`
- `estimatedLoss`
- `expectedAssetsOut`
- `expectedAdapterAssetsAfter`

The adapter fills the execution-side fields.
The oracle is not embedded into the quote in this milestone.

## ExecutionLimits

Execution uses explicit bounds:

- `minAssetsOut`
- `maxLoss`
- `deadline`

These give the strategy a clean integration surface for later real routing logic:

- `minAssetsOut` constrains the cash returned from a rebalance
- `maxLoss` constrains tolerated execution loss
- `deadline` prevents late execution

## Validation Responsibilities

### Strategy-side validation

- owner or strategist only
- rebalance pause check
- intent deadline check
- execution deadline check
- quote has not expired
- oracle is currently fresh through `OracleRouter.getPrice(...)`
- fresh adapter quote recomputation still matches:
  - `intentHash`
  - `positionVersion`
  - `adapterAssetsBefore`
  - `assetsToDeploy`
  - `assetsToWithdraw`
  - `estimatedLoss`
  - `expectedAssetsOut`
  - `expectedAdapterAssetsAfter`

### Adapter-side validation

- bound strategy only
- quote not forced invalid
- quote position version still current
- quote not expired
- max-loss and min-assets-out bounds still satisfied

## Mock Execution Behavior

In this milestone the adapter does not trade on a live venue.
Instead it simulates:

- assets moving from strategy idle into deployed state
- optional assets coming back out to strategy idle
- deterministic execution loss
- a new principal baseline for later fee accounting

This is enough to verify:

- safety checks
- accounting flow
- stale quote handling
- valuation boundaries

## Oracle Usage In 5A

The oracle is intentionally used only as a freshness gate for rebalances.

It is not yet used for:

- multi-asset NAV conversion
- LP token pricing
- tick-range optimization
- route discovery

That keeps the surface honest:

- rebalance code already depends on fresh oracle data
- valuation still remains base-asset and mock-auditable

## Harvest Flow

Harvest does not rebalance.

Instead:

1. vault calls `strategy.harvest()`
2. strategy asks adapter to transfer pending fees back to strategy idle
3. total strategy assets stay the same, but idle liquidity increases

## Emergency Flow

Emergency behavior remains vault-led:

1. vault guardian or owner triggers emergency pause
2. vault enters withdraw-only mode
3. vault calls `strategy.unwindAll()`
4. strategy fully unwinds the adapter
5. strategy transfers all resulting idle assets back to the vault

This keeps emergency exit behavior consistent even as strategy internals become more sophisticated.
