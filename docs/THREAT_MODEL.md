# Helix v0 Threat Model

## Protected Assets

- user principal held idle in the vault
- user principal allocated to the mock strategy
- vault share accounting integrity
- admin control boundaries

## Main Attack Surfaces

### Share inflation and first-depositor edge cases

Risk:

- a small initial depositor can attempt to manipulate exchange rate behavior around an empty vault

Mitigation:

- OpenZeppelin ERC-4626-style virtual share logic via a decimals offset
- tests covering donation and rounding edge cases

### Over-allocation to strategy

Risk:

- owner allocates too much capital into strategy and leaves insufficient idle liquidity

Mitigation:

- `RiskEngine.maxAllocationBps`
- vault pulls from strategy on withdraw
- emergency unwind path

### Admin abuse

Risk:

- privileged account drains user funds or executes arbitrary external calls

Mitigation:

- no generic execute function
- no rescue path for the vault asset
- strategy interface is narrow and typed
- tested ownership and guardian permissions

### Paused-state confusion

Risk:

- pause blocks withdrawals or behaves inconsistently with withdraw-only mode

Mitigation:

- pause and withdraw-only both disable deposits and allocations
- withdrawals remain enabled
- emergency pause unwinds strategy funds back to the vault

### Oracle staleness

Risk:

- stale pricing is accepted as current

Mitigation:

- per-asset heartbeat
- stale reads revert
- zero prices revert

### Strategy loss

Risk:

- strategy losses are not reflected in share accounting

Mitigation:

- `totalAssets` reads actual strategy-reported assets
- tests simulate losses and verify reduced withdrawal capacity

## Residual Risks

- v0 does not yet include venue-specific oracle checks, TWAP logic, calm-zone logic, or drawdown
  limits from the broader Helix design.
- v0 uses a mock strategy and mock oracle, so real integration risks remain deferred.
- owner concentration remains strong in v0 because governance is intentionally postponed.

