# Helix v0 PRD

## Summary

Helix v0 is a narrow MVP for the broader Helix project described in [core.md](../core.md).
It focuses on a single BSC-oriented vault with ERC-4626-style share accounting, a single mock
concentrated-liquidity strategy adapter, conservative controls, and strong tests.

v0 is intentionally not the full protocol. It is a contract and testing foundation.

## Problem

Managing concentrated-liquidity positions is operationally difficult. Helix's long-term thesis is
to wrap that complexity in vaults with better accounting, stronger controls, and cleaner user
flows. For v0, the product problem is smaller: prove the vault architecture, accounting, and risk
surface before integrating real venues.

## Goals

- Prove single-vault deposit and withdrawal accounting.
- Prove safe strategy allocation through a narrow adapter interface.
- Prove conservative controls around caps, pause states, and allocation bounds.
- Prove the system with deterministic tests before any live PancakeSwap or THENA integration.

## Non-Goals

- No real PancakeSwap, THENA, or Venus integration.
- No leverage or carry logic.
- No protocol token, emissions, or fee router.
- No multi-vault factory.
- No frontend work.

## Users

- Protocol engineers validating the base vault design.
- Auditors reviewing access control, accounting, and failure modes.
- Future integrators who will later replace the mock strategy with real adapters.

## v0 Components

- `HelixVault`: single asset vault with ERC-4626-style deposit and withdraw flows.
- `RiskEngine`: per-vault deposit cap, pause, withdraw-only, and allocation limits.
- `OracleRouter`: mock oracle routing with staleness enforcement.
- `MockClStrategy`: one vault-bound strategy adapter used only for testing the integration path.

## Functional Requirements

### Vault

- Support `deposit`, `withdraw`, `previewDeposit`, `previewWithdraw`, and `totalAssets`.
- Support owner-only `allocateToStrategy`.
- Support emergency pause and withdraw-only behavior.
- Pull liquidity back from strategy on withdraws when idle cash is insufficient.

### Strategy

- Accept deposits from the vault only.
- Return assets to the vault only.
- Report `totalAssets`.
- Support `harvest` and `unwindAll`.

### Risk Engine

- Track deposit cap by vault.
- Track pause and withdraw-only flags by vault.
- Track max allocation basis points by vault.

### Oracle Router

- Route one asset to one mock price source.
- Reject stale prices.

## Acceptance Criteria

- Deposits respect the configured deposit cap.
- Withdraw-only blocks deposits and strategy allocations while preserving withdrawals.
- Emergency pause unwinds the mock strategy and preserves withdrawals.
- Allocation cannot exceed the configured max allocation bps.
- First-depositor / share-init edge cases are mitigated in tests.
- Loss scenarios lower withdraw capacity in a predictable way.
- Access control is explicit and tested.

