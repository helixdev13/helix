# Helix Master Roadmap

## Summary

This is the canonical roadmap for the repository.

It merges the current:

- project direction
- build sequence
- flagship product plan
- current execution status

If roadmap language elsewhere drifts from this file, this file wins.

## Permanent Constraints

### Frozen live Citrea lane stays untouched

The deployed `USDC.e / wcBTC` `JuiceSwap` stack on Citrea remains:

- deployed
- owned
- strategy-attached
- disabled by default

Do not change as part of v2 roadmap execution:

- deployed contracts
- live config
- deployment scripts for the frozen lane
- current ownership / guardian / strategist state
- productive-allocation posture on the frozen lane unless explicitly requested

### Helix product identity

Helix is being built as:

- a Citrea-native yield optimizer / aggregator

Helix is not being built as:

- a DEX
- a CL-only product
- a clone of the current live `JuiceSwap` lane

### Flagship v2 direction

The first flagship product direction remains:

- `HLX-USDC.e Smart Vault`

That flagship should be:

- single-asset
- stable-denominated
- allocator-based
- supply-only at first
- idle-fallback capable
- venue-agnostic at the strategy layer
- venue-specific only at the adapter layer

## Current State

### Live state

- frozen Citrea `JuiceSwap` lane is deployed
- ownership is accepted
- strategy is attached
- `maxAllocationBps = 0`
- `paused = false`
- `withdrawOnly = false`
- productive allocation remains disabled

### v2 state

- generic allocator foundation exists in code
- Phase 1 allocator hardening is complete enough to move to Phase 2
- Phase 2 read surfaces, policy visibility, and allocator observability are in place
- Phase 3 deterministic mock multi-adapter routing has started and is test-backed
- final generic allocator hardening review is clean; venue-approval recheck has now returned no-build
- April 10, 2026 narrow fallback screen is complete: no non-CL venue beyond blocked Zentra clears a build-now decision
- v2 auto-compound deployment has been executed onchain and ownership acceptance is complete
- `HelixLens` has a product-facing allocator read surface for the current stack
- auto-compound deployment, transfer, and acceptance scripts now exist
- post-deploy read-only verification is complete
- venue-specific non-CL adapter work has not started
- current first venue target remains `Zentra`
- current venue decision state remains `no-build-yet`

## Strategic End State

The target end state is a broader Helix product suite on Citrea with:

- smart single-asset vaults as the core identity
- CL as one specialist lane
- later maximizer-style or second-order optimizer products only after the core allocator lane is stable

## Phase Map

### Phase 0. Preserve the frozen live lane

Objective:

- keep the deployed `JuiceSwap` stack intact and operationally frozen

Success condition:

- no accidental semantic drift or config drift in the current live lane

### Phase 1. Harden the generic allocator foundation

Primary code surface:

- `AllocatorTypes`
- `IAllocatorAdapter`
- `ManagedAllocatorStrategy`
- `MockAllocatorAdapter`
- allocator tests

Objective:

- make the allocator core reusable, venue-agnostic, and test-backed

Required themes:

- correctness hardening
- conservative accounting
- explicit health/liveness surfaces
- operator-observable events and errors
- no venue-specific assumptions in the strategy layer

Exit condition:

- no major correctness, accounting, interface, or missing-test gaps remain

### Phase 2. Production-shape the allocator lane

Objective:

- bring the allocator lane closer to the maturity of the CL lane without making a venue commitment

Required work:

- richer reporting/state surfaces: implemented for policy state, allocation capacity, adapter
  summaries, withdrawal plans, and deallocation plans
- clear live vs conservative valuation separation
- idle floor / liquidity reserve logic
- degraded vs blocked handling
- stronger policy hooks
- better multi-adapter readiness: started through deterministic mock routing and preview/execution
  tests

Exit condition:

- a real venue adapter can later plug in without redesigning the strategy boundary

### Phase 3. Multi-adapter readiness

Objective:

- make the allocator base safely extensible beyond one adapter without turning it into a router product

Required work:

- deterministic adapter registry behavior: implemented for equal-liquidity routing tie-breaks
- health-aware deallocation ordering: implemented for healthy-before-degraded, blocked-skipped
  routing
- aggregate state correctness across mixed adapter health: covered in allocator tests
- repeated-cycle robustness

Exit condition:

- mock multi-adapter tests prove stable accounting and predictable routing: in progress and
  currently covered for planning, user withdrawal, strategist deallocation, mixed health, blocked
  shortfall, and repeated cycles

### Phase 4. Venue approval recheck

This phase is not coding-first.

A real allocator adapter may start only if a venue clears all of:

- supply-side surface clarity
- acceptable withdrawal/liveness quality
- acceptable oracle assumptions
- legible admin / upgrade surface
- acceptable same-day onchain launch posture

Current state:

- `Zentra = screened but blocked`
- `Morpho = watchlist only; current Citrea surface is too small / opaque`
- no fallback non-CL venue currently clears build-now
- no real adapter should start yet

If Helix continues building before a venue clears, the active buildable direction is an idle/base-vault-first smart-vault shell, not a venue adapter.

### Phase 5. First real allocator adapter

Starts only if Phase 4 clears.

Likely candidate order:

1. `Zentra` if conditions materially improve
2. `Morpho` only if its Citrea surface later becomes legible enough

Adapter rule:

- venue mechanics stay in the adapter
- portfolio policy stays in `ManagedAllocatorStrategy`

### Phase 6. First flagship product integration

Objective:

- launch the first real Helix v2 flagship lane on top of the mature allocator foundation and an approved adapter

Launch target:

- `HLX-USDC.e Smart Vault`

Launch constraints:

- supply-only
- one venue
- hard cap
- low allocation posture
- idle fallback
- validated emergency unwind
- no leverage
- no reflexive tokenomics

### Phase 7. Later strategy families

Only after the flagship allocator lane is stable:

- treat CL as a specialist strategy lane
- consider maximizer-style products later
- consider later assets such as `ctUSD` and `wcBTC`

## Exact Engineering Order

1. Harden the allocator foundation.
2. Expand allocator reporting, policy, and liveness surfaces.
3. Complete multi-adapter generic readiness.
4. Recheck venue approval.
5. Build a real adapter only if approved.
6. Integrate the first flagship smart vault.

Do not reorder this.

## Current Immediate Priority

The immediate engineering mission is:

- keep both deployed Citrea stacks disabled by default unless a deliberate enablement review is requested
- keep the frozen `JuiceSwap` deployment untouched
- continue expanding the generic allocator-based smart-vault lane
- use `HELIX_V2_LAUNCH_CHECKLIST.md` as the launch gate for any future v2 rollout
- keep any next implementation venue-agnostic unless a venue later clears the documented approval gates
- preserve the already-hardened strategy/adapter boundary

Do not start:

- a real `Zentra` adapter
- a real `Morpho` adapter
- productive-enable work on the frozen live lane
- any redesign of the frozen `JuiceSwap` deployment path

## Definition Of Done For The Allocator Foundation

The generic allocator lane is ready for venue-specific integration only when:

- strategy and adapter boundaries are stable
- accounting states are explicit
- live vs conservative valuation are clearly separated
- blocked / degraded / healthy states are enforced and tested
- emergency unwind is defined and tested
- idle fallback works
- cap and liquidity policies work
- multi-adapter readiness is proven in mocks
- the strategy no longer relies on venue-specific assumptions

If that bar is not met, venue-specific coding is premature.

## Source-Of-Truth Links

### Frozen live deployment

- [CURRENT_DEPLOYED_STATE.md](./CURRENT_DEPLOYED_STATE.md)
- [JUICESWAP_OPERATOR_HANDOFF.md](./JUICESWAP_OPERATOR_HANDOFF.md)
- [JUICESWAP_LIVE_RUNBOOK.md](./JUICESWAP_LIVE_RUNBOOK.md)
- [JUICESWAP_ORACLE_FREEZE.md](./JUICESWAP_ORACLE_FREEZE.md)
- [HELIX_V2_LAUNCH_CHECKLIST.md](./HELIX_V2_LAUNCH_CHECKLIST.md)
- [config/citrea/juiceswap_usdce_wcbtc_candidate.md](../config/citrea/juiceswap_usdce_wcbtc_candidate.md)

### v2 deployment surface

- [DeployCitreaAutoCompoundVault.s.sol](../contracts/script/DeployCitreaAutoCompoundVault.s.sol)
- [TransferCitreaAutoCompoundVaultOwnership.s.sol](../contracts/script/TransferCitreaAutoCompoundVaultOwnership.s.sol)
- [AcceptCitreaAutoCompoundVaultOwnership.s.sol](../contracts/script/AcceptCitreaAutoCompoundVaultOwnership.s.sol)
- [HelixLens.sol](../contracts/src/periphery/HelixLens.sol)
- [AutoCompoundClStrategy.sol](../contracts/src/strategies/AutoCompoundClStrategy.sol)
- [RewardDistributor.sol](../contracts/src/periphery/RewardDistributor.sol)
- [JuiceSwapClAdapter.sol](../contracts/src/adapters/JuiceSwapClAdapter.sol)
