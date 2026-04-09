# Helix Portability

## Summary

Helix v0.5 is only partially portable.

The vault, risk, factory, and most strategy-policy surfaces are chain-agnostic. The adapter layer,
oracle shape, deployment assumptions, and wrapped-asset/liquidity assumptions are where portability
work concentrates.

Related docs:

- [ARCHITECTURE.md](./ARCHITECTURE.md)
- [ADAPTER_ARCHITECTURE.md](./ADAPTER_ARCHITECTURE.md)
- [DEPLOYMENT.md](./DEPLOYMENT.md)
- [CONFIGURATION_MODEL.md](./CONFIGURATION_MODEL.md)

## Chain-Agnostic Modules

These modules are reusable as-is across EVM chains unless local operational requirements force a
different deployment flow:

- `HelixVault`
  - generic ERC-4626-style accounting
  - idle plus strategy asset accounting
  - withdraw-only and emergency unwind behavior
- `RiskEngine`
  - per-vault deposit cap
  - pause and withdraw-only controls
  - max allocation bps
- `VaultFactory`
  - vault deployment and registry
  - no chain-specific assumptions beyond standard EVM deployment
- `ManagedClStrategy`
  - role model
  - quote validation
  - deadline and max-loss enforcement
  - adapter boundary
- `MockClAdapter`
  - useful as a testing harness on any chain
  - not venue-specific in its current mock form

## Venue-Specific Modules Or Responsibilities

These are the areas that would change once Helix moves from mock CL logic to a real venue:

- CL adapter implementation
  - venue position representation
  - fee accounting
  - rebalance execution path
  - partial liquidity withdrawal mechanics
  - full unwind semantics
- oracle integration details
  - feed discovery
  - feed precision
  - heartbeat expectations
  - fallback sources
- deployment and runbooks
  - router addresses
  - token addresses
  - operator conventions

## BSC-Era Assumptions In The Current Stack

The current architecture was shaped around a BSC-first deployment mindset even though the contracts
remain mostly generic:

- wrapped base assets are expected to exist and behave like standard ERC-20s
- stablecoin liquidity is assumed to be available for routing and valuation later
- CL venue shape is assumed to resemble modern EVM DEXs with synchronous position management
- liquidity is assumed to be deep enough that rebalances are worth modeling as bounded-loss
  operations rather than delayed settlement queues
- strategy exits are assumed to be pullable on demand in v0.5

These assumptions are acceptable for architecture work, but they are not universal.

## Portability Dependencies By Module

### `HelixVault`

Depends on:

- ERC-20-compatible asset behavior
- a strategy that can report realizable assets and return liquidity synchronously enough for vault
  exits

Does not depend directly on:

- CL venue shape
- oracle feed format
- bridge model
- stablecoin availability

### `ManagedClStrategy`

Depends on:

- adapter quote and execution shape
- oracle freshness model
- strategy asset being representable as a single ERC-20 settlement asset

Would need review for:

- asynchronous liquidity exit models
- non-EVM account models
- multi-asset settlement paths

### Adapter Layer

Depends heavily on:

- CL venue shape
- fee accounting conventions
- pool liquidity model
- withdrawal friction model
- whether assets are native, wrapped, bridged, or synthetic

This is the least portable layer by design.

### `OracleRouter`

Depends on:

- oracle interface shape
- heartbeat semantics
- feed precision conventions

Reusable if:

- the target chain still exposes a price-feed model that can be normalized into
  `latestPrice() -> (price, updatedAt)`

### Deployment Scripts

Depend on:

- Foundry broadcast flow
- env-based configuration
- standard EVM private-key deployment

Portable across EVM chains, but not directly portable to BTC-native execution environments.

## What Changes For A BTC-Native Chain

If Helix were targeted at a BTC-native chain rather than an EVM chain, most portability work would
not be inside the vault math. It would be around execution environment and asset model mismatch.

Likely changes:

- replace or heavily adapt `HelixVault`
  - ERC-4626 and ERC-20 assumptions may not map directly
- replace deployment scripts
  - Foundry and Solidity deployment flow is EVM-specific
- replace adapter layer completely
  - CL venue model may not exist in the same form
- replace oracle normalization layer
  - feed transport and proof model may differ
- redefine asset custody model
  - wrapped BTC, native BTC, and bridged BTC each create different settlement assumptions

Potentially reusable ideas, not code:

- risk-engine concepts
- strategy versus adapter separation
- quote versus execute architecture
- emergency unwind policy
- conservative valuation as an audit surface distinct from live settlement NAV

## Reusable As-Is Versus Needs Adaptation

Reusable as-is on EVM chains with similar market structure:

- `RiskEngine`
- `VaultFactory`
- most of `HelixVault`
- most of `ManagedClStrategy` policy logic
- deployment/runbook structure

Needs adaptation per chain or venue:

- adapter implementation
- oracle source wiring
- token lists and deployment defaults
- assumptions about exit liquidity and wrapped base assets

Needs major redesign outside EVM:

- share token standard assumptions
- deployment tooling
- low-level asset transfer model
- strategy execution plumbing

## Dependency Matrix

### Oracle Shape

Modules with meaningful dependency:

- `OracleRouter`
- `ManagedClStrategy`
- any future real adapter that needs price-aware quoting

### CL Venue Shape

Modules with meaningful dependency:

- adapter implementation
- rebalance runbooks
- strategy parameterization if venue position limits differ

### Bridge Or Wrapped Asset Model

Modules with meaningful dependency:

- deployment config
- asset allowlists
- oracle selection
- risk policy

### Stablecoin Availability

Modules with meaningful dependency later:

- real adapter execution design
- venue choice
- market selection
- oracle coverage

### Liquidity Depth Assumptions

Modules with meaningful dependency:

- strategy operating bounds
- adapter loss assumptions
- deposit caps
- max allocation policy

## Freeze Note

This portability note is descriptive only.

It does not change accepted contract semantics and should be treated as a planning artifact while
chain and market direction remain under review.
