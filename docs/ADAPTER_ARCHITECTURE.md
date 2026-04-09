# Helix Adapter Architecture

## Goal

Milestone 5A introduces a realistic strategy stack without integrating a real venue yet:

- `HelixVault`
- `ManagedClStrategy`
- `MockClAdapter`

The vault remains generic. Concentrated-liquidity concerns stay below the `IStrategy` boundary.

## Actor Model

### Vault

- owns user share accounting
- allocates idle vault assets to the strategy
- requests withdrawals from the strategy
- calls `harvest()` and `unwindAll()` through the strategy interface

### Managed Strategy

- bound to one vault
- bound to one asset
- bound to one adapter reference
- holds idle strategy assets directly
- validates quote freshness, oracle freshness, deadlines, and max-loss bounds
- calls the adapter for CL-specific execution

### Adapter

- bound to one asset
- bound once to one strategy
- models the deployed CL position
- exposes auditable valuation and quote surfaces
- performs execution against mock state

### Owner

- owns the vault
- owns the managed strategy
- can set strategist and strategy guardian
- can rebalance

### Strategist

- narrower than owner
- can call `rebalance(...)`
- cannot reconfigure vault ownership or strategy roles

### Guardian

- at the vault layer:
  - can trigger emergency pause
  - can enable withdraw-only
- at the managed strategy layer:
  - can pause rebalances
  - cannot unpause rebalances

### Risk Engine

- still controls vault-level cap, pause, withdraw-only, and max-allocation policy

### Oracle Router

- provides a fresh oracle read gate for managed-strategy rebalances
- is not used by the vault itself

## Contract Boundaries

### `HelixVault`

Knows only:

- `asset()`
- `vault()`
- `deposit(...)`
- `withdraw(...)`
- `totalAssets()`
- `harvest()`
- `unwindAll()`

The vault never sees:

- ticks
- liquidity bands
- adapter quote details
- slippage logic
- rebalance intents

### `ManagedClStrategy`

Owns:

- idle strategy cash
- oracle freshness validation
- quote-vs-intent validation
- deadline checks
- max-loss checks
- role checks for rebalancing

### `MockClAdapter`

Owns:

- deployed position state
- rebalance quoting
- rebalance execution mechanics
- fee accrual accounting
- partial liquidity pulls
- full unwind mechanics

## Quote vs Execute Model

### What is quoted

The adapter quotes:

- current position version
- current adapter asset balance
- requested assets in
- requested assets out
- estimated execution loss
- expected assets out
- expected adapter balance after execution
- quote validity window

The strategy adds:

- no quote fields
- oracle freshness is checked independently at execution time

### What is validated

The strategy validates:

- caller is owner or strategist
- strategy rebalance is not paused
- intent deadline
- execution deadline
- quote hash matches the intent
- quote validity window has not expired
- oracle data is currently fresh
- all deterministic adapter-produced quote facts still match a freshly recomputed adapter quote

The adapter validates:

- caller is the bound strategy
- quote is not forcibly invalidated by mock controls
- quote hash still matches the intent
- position version still matches
- quote validity window has not expired
- requested execution stays inside max-loss and min-assets-out limits

### What is executed

Execution is still mock logic in this milestone:

- transfer idle assets from strategy into the adapter
- simulate execution loss
- optionally return assets back to strategy idle
- update position metadata
- set a new principal baseline for future fee accounting

### What can go stale

Between quote and execute, any of these can invalidate a rebalance:

- time passing beyond `validUntil`
- time passing beyond the strategy/operator deadline
- an oracle becoming stale
- adapter position version changing because of a withdrawal, harvest, unwind, or simulation change
- the adapter being forced into an invalid-quote mode in tests

## Valuation Model

`ManagedClStrategy.totalAssets()` is intentionally auditable:

- `strategy idle` = asset balance held directly by the strategy
- `adapter deployed` = adapter valuation in asset units

The adapter valuation reports:

- `grossAssets`
- `deployedAssets`
- `pendingFees`
- `haircutBps`
- `haircutAmount`
- `netAssets`

Current milestone behavior:

- all values are in the base asset
- fees are mocked as `adapter balance - principal baseline`
- haircut is mock-configurable
- no external venue valuation exists yet

Settlement rule:

- live vault/share settlement uses withdrawable gross assets
- conservative haircuted valuation remains visible for risk review and audit only

Future venue adapters can preserve the same surface while replacing the internals with real CL
position valuation logic.

## Unwind Semantics

### Partial withdraw

Withdrawals follow:

1. use strategy idle first
2. if needed, pull the exact shortfall from the adapter
3. transfer requested assets back to the vault

### Full unwind

Emergency unwind follows:

1. vault calls `strategy.unwindAll()`
2. strategy asks the adapter to unwind all remaining assets back to the strategy
3. strategy transfers all idle assets back to the vault

### v0.5 assumptions

- adapter liquidity is still fully pullable on demand
- there are no asynchronous exits or withdrawal queues
- loss is socialized through lower reported strategy assets, not through delayed settlement logic
