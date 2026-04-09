# Helix on Citrea: Thesis

## Summary

As of April 8, 2026, Citrea is attractive for Helix because it combines:

- Bitcoin-centered product demand
- full EVM compatibility
- a trust-minimized BTC bridge path through Clementine
- a chain-native stablecoin thesis through `ctUSD`
- live DEX and lending infrastructure on mainnet

The recommended Citrea entry is not a CL vault first.

The recommended first Helix product on Citrea is:

- `HLX-ctUSD Base`

That recommendation is intentionally conservative. It uses the portable Helix core, avoids forcing a
venue-specific adapter before market structure settles, and aligns with Citrea’s current stablecoin
and onboarding stack.

## Why Citrea Is Attractive For Helix

### 1. Citrea is explicitly positioning around Bitcoin capital markets

Citrea’s mainnet launch message is not generic L2 positioning. It is explicitly framed around
Bitcoin being used for:

- lending
- trading
- settlement

That maps well to Helix’s long-term goal of being a yield execution layer rather than a generic AMM
or token project.

### 2. Citrea is EVM-compatible, so Helix core is portable

Citrea is fully EVM compatible and exposes standard chain metadata:

- chain id `4114`
- RPC `https://rpc.mainnet.citrea.xyz`
- explorer `https://explorer.mainnet.citrea.xyz`

That means Helix does not need a new non-EVM contract model to begin product planning there.

### 3. Citrea has a native BTC onboarding thesis

Citrea’s `cBTC` path is built around Clementine, which Citrea describes as a trust-minimized
two-way peg with BitVM-based challenge assumptions rather than a standard multisig custody model.

For Helix, that matters because Bitcoin exposure on Citrea is not just “wrapped BTC on another EVM
chain.” The trust model is a core product consideration.

### 4. Citrea already has a native stablecoin story

`ctUSD` is positioned by Citrea as the default stablecoin on the network. It is:

- live on Citrea Mainnet
- fiat-backed
- issued by MoonPay
- powered by M0
- available through bridges, DEX pools, MoonPay, and OTC minting

That makes it a credible first Helix asset even before a BTC-denominated structured product is ready.

### 5. Citrea already has the minimum viable DeFi stack

Citrea’s mainnet announcement points to live trading and lending primitives. Citrea docs also list:

- RedStone on mainnet for oracle feeds
- Hyperlane and LayerZero for interop
- Garden for BTC swap/onboarding paths
- DEX access via Satsuma, JuiceSwap, and Fibrous in the launch announcement

This is early, but it is enough to justify a product-spec pass.

## Which Helix Modules Are Reusable As-Is

The following Helix modules can be reused on Citrea without semantic changes:

- `HelixVault`
- `RiskEngine`
- `VaultFactory`
- `HelixLens`
- most of `ManagedClStrategy` policy logic
- deployment and runbook patterns

These modules remain valid because Citrea is still an EVM chain and Helix’s accepted architecture
already separates:

- generic vault accounting
- strategy policy
- adapter-specific venue logic

## Which Assumptions Break Or Need Review On A Bitcoin-Centered Chain

Citrea is EVM-compatible, so fewer assumptions break than on a non-EVM BTC-native environment.
Still, several BSC-era assumptions do not carry over cleanly.

### 1. Stablecoin abundance is not a safe default assumption

BSC assumptions:

- multiple deep stablecoins
- broad onchain routing depth
- many interchangeable oracle-supported stable assets

Citrea reality as of April 8, 2026:

- `ctUSD` is the official native stablecoin
- bridged `USDC.e` and `USDT.e` exist
- stablecoin and DEX depth are still relatively small

### 2. CL venue maturity is lower than on BSC

BSC assumptions:

- multiple mature CL venues
- deep blue-chip and stable pools
- enough liquidity for managed LP products to absorb operational mistakes

Citrea reality:

- the chain is very early
- TVL is still small
- venue selection and liquidity concentration matter far more

### 3. Bridge model is part of product risk, not background infrastructure

BSC assumptions often treat onboarding as solved.

Citrea does not allow that. Product design has to respect:

- `cBTC` bridge trust model
- bridge liveness
- peg-out timelines
- third-party bridge availability for stablecoins

### 4. Oracle coverage is narrower

Citrea docs list RedStone mainnet feeds for:

- `BTC/USD`
- `USDC/USD`
- `USDT/USD`
- `aUSD/USD`

As of April 8, 2026, Citrea docs do not list a `ctUSD/USD` feed on that page. That is a meaningful
constraint for any product that wants explicit `ctUSD` oracle dependence.

### 5. Finality and operations differ from BSC

Citrea is anchored to Bitcoin finality, with distinct notions of:

- soft confirmation
- finalized state
- proven state

Its reorg-handling docs also describe a mainnet finality depth of 6 Bitcoin confirmations. Helix
operations cannot assume BSC-style operational cadence.

## Product Recommendation

### Recommended First Launch Shape

Helix should launch on Citrea first as:

- a base vault

More specifically:

- `HLX-ctUSD Base`

### Why base vault first

- It matches accepted Helix semantics today.
- It does not force an immediate CL adapter decision.
- It avoids overfitting to thin early DEX liquidity.
- It lets Helix validate Citrea-specific onboarding, guardian operations, and risk limits first.
- It works with a single-asset vault model and avoids premature multi-asset valuation complexity.

### Why not CL first

- venue choice is still early
- public liquidity is still thin
- oracle coverage is narrower than on BSC
- BTC/stable pair management would add bridge, stable, and venue risk at the same time

### Why not lending allocator first

A lending allocator may ultimately be the right second step, but as of April 8, 2026 it is better
treated as a gated follow-on phase than as Helix’s first Citrea release.

Reason:

- there is evidence of lending activity on Citrea
- but venue, market, and risk parameter due diligence should precede a live allocator launch

## Recommended First Asset

### Recommendation

- `ctUSD`

### Why `ctUSD`

- It is the official default stablecoin on Citrea.
- Citrea is explicitly pushing it as the native liquidity standard.
- It has a clear onboarding path:
  - bridge from Ethereum
  - DEX liquidity
  - MoonPay fiat on-ramp
  - OTC minting
- It is a better product entry asset than `cBTC` for Helix’s first Citrea release because it avoids
  forcing users into immediate BTC price volatility while the chain is still building liquidity.

### Explicit answer: Is `ctUSD` the best first Helix asset on Citrea?

Yes, for the first Helix Citrea release.

Important qualifier:

- `ctUSD` is the best first base-vault asset
- it is not automatically the best first CL-pair asset

## Recommended First Venue

### Recommendation for the first Helix Citrea release

- no external venue dependency

The first Citrea release should be able to ship as an idle, capped base vault using accepted
Helix core contracts without forcing immediate venue integration.

### Recommendation for the first venue-specific allocator after that

- `Morpho`, if a public, liquid, and clearly parameterized Citrea market exists for the target asset

This recommendation is partly an inference from Citrea’s own mainnet announcement, which names
Morpho as a live lending primitive. It should be treated as a due-diligence gate, not as already
approved implementation scope.

### Recommendation for the first CL adapter target after the base-vault phase

- `Satsuma`, not `JuiceSwap`

### Why `Satsuma` over `JuiceSwap` for the first CL adapter target

As of April 8, 2026, public DeFiLlama metrics show:

- Citrea total TVL about `$1.90m`
- Satsuma TVL about `$1.39m`
- JuiceSwap TVL about `$293k`
- Satsuma 30d DEX volume about `$11.82m`
- JuiceSwap 30d DEX volume about `$0.96m`

That makes Satsuma look materially stronger on public liquidity and activity.

JuiceSwap still has real strengths:

- clearer public docs
- explicit Uniswap V3 fork description
- listed contract addresses

But JuiceSwap is also more tightly coupled to the JuiceDollar ecosystem through:

- `JUSD`
- `svJUSD`
- automatic savings integration

That is attractive for ecosystem alignment, but it increases venue-specific complexity for Helix’s
first CL adapter.

### Explicit answer: Is `JuiceSwap` the best first venue for a Helix CL adapter?

No.

It is a credible secondary target, but the current public evidence points to:

- `Satsuma` as the stronger first CL candidate on liquidity grounds
- `JuiceSwap` as the better-documented but more ecosystem-coupled secondary candidate

## Recommended First Oracle Path

### Recommendation

- do not require a Helix settlement oracle for the first `ctUSD` base-vault release
- standardize on `RedStone` inside `OracleRouter` for the first Citrea oracle provider

### Why

For a single-asset `ctUSD` base vault:

- Helix share accounting does not need a cross-asset oracle
- this avoids forcing a `ctUSD/USD` dependency before one is clearly documented on Citrea

For later venue-specific strategy work:

- RedStone is the official mainnet oracle provider listed in Citrea docs
- its listed Citrea feeds include `BTC/USD`, `USDC/USD`, and `USDT/USD`

### Practical implication

The first Citrea Helix product should avoid any design that requires:

- `ctUSD/USD` oracle dependence inside Helix settlement

## Recommended Bridge / Onboarding Path

### Recommendation

For the first `ctUSD` base-vault release:

- primary onboarding: `Bridge Hub` / official stablecoin bridge path to `ctUSD`
- fiat onboarding: `MoonPay`

For later BTC-centric products:

- primary BTC onboarding: `Clementine` / Bridge Hub
- secondary BTC path to monitor: `Garden`

### Explicit answer: Should bridge/onboarding support be considered part of MVP planning?

Yes.

But it should be considered part of:

- product MVP planning
- runbooks
- wallet UX
- user documentation

It should not be treated as a new protocol logic requirement inside Helix core contracts.

## Final Position

Helix should expand to Citrea in stages:

1. `HLX-ctUSD Base`
2. first external allocator only after venue diligence
3. first CL adapter only after the chain’s liquidity and oracle surface are more mature

That path keeps accepted Helix semantics intact while matching the actual state of Citrea on
April 8, 2026.

## References

- [Citrea Mainnet Is Live](https://www.blog.citrea.xyz/citrea-mainnet-is-live/)
- [Citrea Chain Information](https://docs.citrea.xyz/developer-documentation/chain-information)
- [Citrea USD: ctUSD](https://docs.citrea.xyz/developer-documentation/citrea-usd-ctusd)
- [Canonical Contract Addresses](https://docs.citrea.xyz/developer-documentation/canonical-contract-addresses)
- [Interop, Bridges & Swaps](https://docs.citrea.xyz/developer-documentation/ecosystem-tooling/interop-bridges-swaps)
- [Oracles & VRF](https://docs.citrea.xyz/developer-documentation/ecosystem-tooling/oracles-vrf)
- [Clementine: trust-minimized Bitcoin Bridge](https://docs.citrea.xyz/essentials/clementine-trust-minimized-bitcoin-bridge)
- [Transaction Finality](https://docs.citrea.xyz/essentials/transaction-finality)
- [Reorg Handling](https://docs.citrea.xyz/advanced/reorg-handling)
- [Fee Model](https://docs.citrea.xyz/advanced/fee-model)
- [JuiceSwap Overview](https://docs.juiceswap.com/overview.html)
- [Citrea chain page on DefiLlama](https://defillama.com/chain/citrea)
- [Satsuma on DefiLlama](https://defillama.com/protocol/satsuma)
- [JuiceSwap on DefiLlama](https://defillama.com/protocol/juiceswap)
- [ctUSD on DefiLlama](https://defillama.com/stablecoin/citrea-usd)
