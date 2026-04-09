# Helix v0 Decisions

## D-001: Build v0 as a narrow contract foundation

Helix v0 is intentionally smaller than the product vision in [core.md](../core.md). The goal is to
prove accounting and control surfaces before any live DEX integration.

## D-002: Use OpenZeppelin and Foundry

The implementation uses OpenZeppelin 5.x contracts and Foundry tests for a conventional and
auditable base.

## D-003: Keep strategy integration mock-only

The strategy interface is real enough to validate architecture, but the first implementation is a
mock adapter with no external venue calls.

## D-004: Separate risk policy from the vault

Deposit cap, pause state, withdraw-only state, and allocation bps live in `RiskEngine` so they can
later become more expressive without rewriting vault accounting.

## D-005: Use ERC-4626-style virtual share protection

Helix v0 uses OpenZeppelin ERC-4626 conversion logic with a decimals offset to harden empty-vault
share initialization behavior.

## D-006: No admin drain path for the underlying asset

The vault does not expose a generic execute function or a rescue function for the underlying asset.

## D-007: Emergency pause prioritizes user exits

Emergency pause disables new deposits and allocations, sets the vault into withdraw-only behavior,
and unwinds strategy funds back to the vault where possible.

## D-008: Keep CL-specific logic below the vault boundary

The vault continues to depend only on `IStrategy`. Concentrated-liquidity state, rebalance quotes,
execution bounds, and valuation logic live inside `ManagedClStrategy` and its adapter.

## D-009: Use an adapter abstraction rather than a venue-specific executor

The next architecture layer uses an `adapter` abstraction because it needs to cover:

- valuation reads
- quote generation
- execute semantics
- partial withdrawals
- full unwind

`executor` would be too narrow, and `position manager` would imply ownership of broader policy that
still belongs in the strategy.

## D-010: Treat rebalance as quote plus execute

Rebalances are split into:

- a quoted intent
- strategy-side validation
- adapter-side execution

This makes staleness, deadlines, oracle freshness, and max-loss bounds explicit before any real DEX
integration.
