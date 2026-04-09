# Citrea Integration Plan

## Summary

This document defines how Helix should expand to Citrea Mainnet without changing accepted protocol
semantics prematurely.

As of April 8, 2026, the recommended plan is:

- launch first with a `ctUSD` base vault
- do not require a venue adapter on day one
- keep all accepted core contracts unchanged
- use the base-vault period to finish venue diligence
- target a CL venue before any allocator venue

## Freeze Constraints

The following should remain unchanged unless a concrete bug is found:

- `HelixVault`
- `ManagedClStrategy`
- `MockClAdapter`
- `RiskEngine`
- `VaultFactory`

This plan is documentation-first and staging-oriented.

## Exact First Product Recommendation

### Product

- `HLX-ctUSD Base`

### Asset

- `ctUSD`

### Venue

- none for the first release

### Oracle dependency

- no Helix settlement-oracle dependency for the first release

### Onboarding path

- `Bridge Hub` for stablecoin entry into `ctUSD`
- `MoonPay` for direct fiat onboarding where supported

## Why This Is The First Product

This product fits the current Helix core better than a Citrea CL vault because it:

- uses the accepted single-asset vault model
- does not require a real adapter immediately
- avoids forcing a `ctUSD` oracle dependency
- avoids taking bridge risk, venue risk, and CL execution risk all at once

The first Citrea release should validate:

- chain deployment
- asset handling
- 6-decimal stablecoin behavior
- guardian and emergency runbooks
- withdrawals under Citrea operating conditions

before Helix takes venue-specific execution risk.

## Exact Venue Recommendation After The First Release

Because the first release is venue-independent, there are two follow-on venue decisions.

### First external allocator venue

- none approved yet

Current position:

- `Morpho` is not approved yet
- `Zentra` is a later allocator candidate, not the next venue

### First CL adapter venue

- `JuiceSwap`

`Satsuma` should remain the secondary CL target until either:

- it publishes a materially clearer contract surface, or
- direct venue diligence resolves its current governance and contract-legibility gaps

### Why the order changed

Allocator-first is no longer the recommended sequence.

Reason:

- current public lending depth is too small or too opaque
- `Morpho` lacks sufficient Citrea market visibility
- `Zentra` is more legible but still early and smaller than the leading DEX path
- the DEX side is currently the more productive next venue surface

### Why the CL venue changed

The earlier high-level venue recommendation favored `Satsuma` on public liquidity.

After direct venue-specific diligence:

- `Satsuma` still looks stronger on market depth
- `JuiceSwap` is materially stronger on technical legibility
- Helix should optimize first for adapter implementation certainty, not for TVL alone

That makes `JuiceSwap` the correct first CL adapter target, with `Satsuma` as the venue to
re-evaluate later for a production launch path if its contract surface becomes legible.

## Exact Oracle Recommendation

### First release

- do not require Helix to settle against external price feeds

### First oracle provider to standardize in Helix infra on Citrea

- `RedStone`

### Why

Citrea docs explicitly list RedStone on mainnet and testnet, with mainnet feeds for:

- `BTC/USD`
- `USDC/USD`
- `USDT/USD`
- `aUSD/USD`

As of April 8, 2026, Citrea docs do not list a `ctUSD/USD` feed on the official oracle page.
That means the first Helix Citrea release should avoid designs that require `ctUSD` price
dependence inside Helix itself.

## Exact Deployment Order

### Phase 0: Citrea readiness

1. confirm Citrea Mainnet chain settings and RPC/provider choices
2. record Citrea asset, oracle, and venue candidates in repo docs/config
3. define Citrea-specific operator runbooks before any live deployment

### Phase 1: Base vault release

1. deploy `RiskEngine`
2. deploy `OracleRouter`
3. deploy `VaultFactory`
4. optionally deploy `HelixLens`
5. create `HLX-ctUSD Base` through `VaultFactory`
6. set owner and guardian
7. set conservative `depositCap`
8. set `maxAllocationBps = 0` if no live strategy is attached yet
9. leave strategy unset for the first release
10. document addresses and operational limits in Citrea deployment notes

### Phase 2: First CL adapter integration

1. finish venue diligence on the chosen CL venue
2. finalize the first CL venue target
3. implement a Citrea-specific CL adapter
4. wire RedStone-based oracle freshness logic as needed
5. launch under tighter caps than the base vault

### Phase 3: First allocator integration

1. finish venue diligence on the chosen allocator venue
2. build a venue-specific allocator strategy or adapter
3. test withdrawal and unwind behavior on Citrea conditions
4. attach strategy only after vault and venue readiness gates are passed
5. raise `maxAllocationBps` gradually from zero

## Config Changes Needed Versus BSC Assumptions

### Chain metadata

- chain id changes from BSC assumptions to `4114`
- RPC/explorer change to Citrea endpoints
- gas asset becomes `cBTC`

### Asset assumptions

- `ctUSD` uses `6` decimals
- `wcBTC`, `USDC.e`, `USDT.e`, and `WBTC.e` are available assets
- stablecoin depth is much smaller than on BSC

### Oracle assumptions

- do not assume broad stablecoin feed coverage
- start with RedStone only
- treat missing `ctUSD` feed coverage as a hard product constraint

### Venue assumptions

- do not assume multiple mature CL venues with deep inventory
- do not assume routing depth comparable to PancakeSwap or THENA

### Finality and operations

- do not assume BSC-like operational finality
- account for Citrea’s soft-confirmed, finalized, and proven states
- account for Bitcoin-anchored finality depth in runbooks

## What To Keep Unchanged In Contracts

Keep unchanged:

- `HelixVault` accounting model
- `RiskEngine` config model
- `VaultFactory` responsibilities
- `ManagedClStrategy` role and quote-validation model
- strategy-to-adapter boundary

The correct Citrea expansion path is to reuse Helix core, not to redesign it around chain-specific
narrative.

## What Must Be Adapter-Specific

Only the following areas should become Citrea- or venue-specific:

- CL venue contract integration
- pool state decoding
- fee accounting
- swap execution path
- partial withdrawal mechanics
- full unwind mechanics
- venue-specific quote construction

If Helix later integrates a lending venue, the venue-specific logic should also stay isolated from
the vault.

## What Should Remain Deferred

The following should remain out of scope until after the base-vault release is stable:

- JuiceSwap adapter implementation
- Satsuma adapter implementation
- cBTC CL vaults
- `ctUSD` stable-stable CL vaults
- lending loops
- multi-venue routing
- bridge automation
- cross-chain onboarding automation
- frontend polish beyond operator or basic deposit flows

## Release Gates

### Gate A: Release `HLX-ctUSD Base`

Required:

- chain deployment working
- guardian runbooks written
- deposit/withdraw ops validated on Citrea
- clear user onboarding instructions

### Gate B: Add first CL adapter

Required:

- proven venue depth
- venue-specific oracle path decided
- adapter and integration tests complete
- staged TVL caps and emergency procedures approved

### Gate C: Add first external allocator

Required:

- public venue docs and contracts
- sufficient liquidity for Helix cap
- clear emergency exit semantics
- acceptable oracle and liquidation assumptions

## Final Recommendation

Helix should not enter Citrea by trying to recreate its BSC CL thesis immediately.

It should enter Citrea in the order that best matches current ecosystem maturity:

1. `HLX-ctUSD Base`
2. first CL adapter
3. first allocator venue

That sequence keeps Helix disciplined and avoids premature semantic changes to accepted contracts.

## References

- [Citrea Mainnet Is Live](https://www.blog.citrea.xyz/citrea-mainnet-is-live/)
- [Citrea Chain Information](https://docs.citrea.xyz/developer-documentation/chain-information)
- [Citrea USD: ctUSD](https://docs.citrea.xyz/developer-documentation/citrea-usd-ctusd)
- [Canonical Contract Addresses](https://docs.citrea.xyz/developer-documentation/canonical-contract-addresses)
- [Oracles & VRF](https://docs.citrea.xyz/developer-documentation/ecosystem-tooling/oracles-vrf)
- [Reorg Handling](https://docs.citrea.xyz/advanced/reorg-handling)
- [Transaction Finality](https://docs.citrea.xyz/essentials/transaction-finality)
- [Morpho Risk Documentation](https://docs.morpho.org/learn/resources/risks/)
- [Morpho Blue Public API](https://blue-api.morpho.org/graphql)
- [Zentra Docs](https://zentrafinance.gitbook.io/zentra)
- [JuiceSwap Overview](https://docs.juiceswap.com/overview.html)
- [Citrea chain page on DefiLlama](https://defillama.com/chain/citrea)
- [Satsuma on DefiLlama](https://defillama.com/protocol/satsuma)
- [JuiceSwap on DefiLlama](https://defillama.com/protocol/juiceswap)
