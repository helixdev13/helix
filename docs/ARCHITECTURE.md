# Helix v0 Architecture

## Scope

Helix v0 started as a single-vault, single-strategy foundation.

The current architecture now has two strategy layers:

- the original `MockClStrategy` for minimal vault accounting tests
- the new managed concentrated-liquidity stack for adapter architecture and rebalance flow tests

The goal is still the same: prove clean boundaries between the vault, strategy, adapter, risk
engine, and oracle router before adding real venue logic.

## Components

### `HelixVault`

Responsibilities:

- Hold user deposits and mint vault shares.
- Track total assets as idle assets plus strategy assets.
- Enforce local emergency controls.
- Consult `RiskEngine` for deposit and allocation policy.
- Pull funds back from strategy when withdrawals exceed idle liquidity.

Design notes:

- Uses ERC-4626-style accounting.
- Uses an OpenZeppelin ERC-4626 decimals offset to harden first-depositor behavior.
- Does not expose arbitrary call execution or token rescue paths for the underlying asset.

The vault still only knows about strategies through `IStrategy`.
It does not understand concentrated-liquidity ranges, quotes, ticks, or venue-specific execution.

### `RiskEngine`

Responsibilities:

- Maintain per-vault limits.
- Provide a narrow read surface the vault can consult during deposit and allocation flows.

Config:

- `depositCap`
- `paused`
- `withdrawOnly`
- `maxAllocationBps`

### `OracleRouter`

Responsibilities:

- Map an asset to a mock oracle.
- Normalize read access for later vault or strategy integrations.
- Reject stale or invalid prices.

v0.5 note:

- The vault remains isolated from oracle reads.
- `ManagedClStrategy` uses `OracleRouter` as a rebalance-freshness gate.
- The mock adapter still values positions in asset units rather than converting through market
  prices.

### `MockClStrategy`

Responsibilities:

- Accept vault allocations.
- Hold the underlying token balance as stand-in strategy inventory.
- Return funds to the vault on withdraw or unwind.
- Simulate profit and loss for tests.

Constraints:

- Bound to one vault at deployment.
- Bound to one asset at deployment.
- No arbitrary target calls.

### `ManagedClStrategy`

Responsibilities:

- Remain the only object the vault trusts through `IStrategy`.
- Hold idle strategy assets directly.
- Read conservative deployed valuation from the adapter.
- Validate rebalance intent, quote freshness, oracle freshness, deadlines, and loss bounds.
- Expose a narrower strategist role for rebalances.

Constraints:

- Bound to one vault at deployment.
- Bound to one asset at deployment.
- Bound to one adapter reference at deployment.
- No arbitrary execution surface.

### `MockClAdapter`

Responsibilities:

- Model deployed CL state beneath the managed strategy.
- Quote rebalance outcomes from current adapter state.
- Execute rebalance requests after quote validation.
- Report valuation in asset units using gross assets, pending fees, and an optional haircut.
- Support partial withdrawals, harvests, and full unwind.

Constraints:

- Bound to one asset.
- Bound once to one strategy during strategy construction.
- No owner-controlled drain path.
- No arbitrary target calls.

## Asset Flow

1. User deposits asset into `HelixVault`.
2. Vault mints shares using ERC-4626-style conversion logic.
3. Owner allocates a bounded amount to a strategy.
4. In the managed path, the strategy may rebalance part of its idle balance into the adapter.
5. Strategy reports total assets as direct idle balance plus adapter-reported deployed value.
6. On withdrawal, vault uses idle balance first and pulls shortfall from strategy if needed.
7. In the managed path, strategy uses idle first and only then pulls from the adapter.
8. On emergency pause, vault sets local pause state and calls `strategy.unwindAll()`.
9. Managed strategy fully unwinds the adapter and pushes all assets back to the vault.

## Access Model

- `owner`
  - sets guardian
  - installs or replaces strategy when safe
  - allocates to strategy
  - clears emergency pause
  - toggles local withdraw-only off
- `guardian`
  - can trigger emergency pause
  - can enable local withdraw-only
- `RiskEngine.owner`
  - manages per-vault risk config
- `OracleRouter.owner`
  - manages oracle mappings
- `ManagedClStrategy.owner`
  - sets strategist
  - sets strategy guardian
  - can rebalance
  - can unpause rebalance
- `ManagedClStrategy.strategist`
  - can rebalance
- `ManagedClStrategy.guardian`
  - can pause rebalances
- `MockClAdapter`
  - has no general owner role
  - is bound once to a single strategy

## Upgrade Boundaries

Helix remains non-upgradeable. The architecture is modular instead:

- vault
- risk engine
- oracle router
- strategy
- adapter

Each part can later be replaced with a better implementation without first building a proxy stack.
