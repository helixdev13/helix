# Citrea CL Decision

## Summary

This document makes the first Citrea concentrated-liquidity venue decision for Helix after:

- `HLX-ctUSD Base`
- strategy unset
- `maxAllocationBps = 0`

This decision is narrower than the earlier high-level venue matrix.

The earlier matrix favored `Satsuma` on market depth.
This document focuses specifically on:

- adapter-first implementation
- contract-surface legibility
- governance / admin visibility
- pair and oracle burden for Helix

## Decision Question

For Helix's first Citrea CL adapter, should Helix build for:

- `Satsuma`
or
- `JuiceSwap`

## Evidence Classes

- `official / project sources`
  - JuiceSwap docs, repos, and published addresses
  - Satsuma official app and GitHub organization
- `public data`
  - DefiLlama TVL, volume, and token-composition data
- `inference`
  - Helix implementation recommendation

## Headline Result

### Market verdict

- `Satsuma` looks stronger on current public liquidity and usage

### Engineering verdict

- `JuiceSwap` is much more legible for adapter implementation

### Helix decision

- build first Citrea CL adapter for `JuiceSwap`

## Comparison Matrix

| Criterion | `Satsuma` | `JuiceSwap` | Helix read |
| --- | --- | --- | --- |
| Liquidity / public usage | Strongest reviewed Citrea DEX by current public TVL and volume | Meaningfully smaller | `Satsuma` wins |
| Docs quality | No reviewed docs site or technical contract reference | Strong docs site with overview, liquidity, governance, and contract pages | `JuiceSwap` wins |
| Contract discoverability | No reviewed public contract-address set | Mainnet and testnet addresses published | `JuiceSwap` wins |
| Contract model legibility | Not confirmed from reviewed project sources | Explicitly documented as Uniswap V3 fork with gateway and V3 periphery | `JuiceSwap` wins |
| Governance / admin risk visibility | Unknown from reviewed project sources | Published veto-governance model, no-admin-key posture, explicit scope of governor powers | `JuiceSwap` wins |
| Upgradeability stance | Unknown | Explicitly documented as no upgradeable proxies | `JuiceSwap` wins |
| Candidate pair visibility | Public token mix strongly suggests `ctUSD`, `WCBTC`, `USDC`, `WBTC`, `GUSD` | Official docs and public data clearly show `WcBTC`, bridged stables, and public Citrea inventory including `CTUSD` | slight `Satsuma` edge on current `ctUSD` inventory |
| Oracle burden | Same pair-level burden as any Citrea `ctUSD / wcBTC` design, plus less contract transparency | Same pair-level burden, but better technical surface to manage quoting and unwinds | `JuiceSwap` wins |
| Adapter complexity | Higher because venue surface is opaque | Lower because contract roles and Uniswap-V3-style surface are published | `JuiceSwap` wins |
| Implementation readiness | Not approved yet | Ready for adapter-first design work | `JuiceSwap` wins |

## Satsuma Assessment

### What Satsuma gets right

Public data reviewed on April 8, 2026 shows:

- current TVL about `$1.39m`
- 24h volume about `$299.6k`
- 30d volume about `$11.82m`

Current public token composition shows meaningful venue inventory in:

- `CTUSD`
- `WCBTC`
- `USDC`
- `GUSD`
- `WBTC`

That makes Satsuma the strongest current market venue for the `ctUSD / wcBTC` direction.

### What Satsuma gets wrong for adapter-first work

From reviewed project sources, Satsuma still does not publish enough for Helix to safely build
against it first:

- no reviewed docs site
- no reviewed contract-address reference
- no reviewed core/periphery repositories
- no reviewed governance or admin documentation
- no reviewed upgradeability stance

### Helix implication

Satsuma looks like the stronger market, but not the stronger implementation target.

## JuiceSwap Assessment

### What JuiceSwap gets right

Reviewed official JuiceSwap sources publish all of the things Helix needs for adapter-first work:

- overview docs
- liquidity docs
- governance docs
- smart-contract reference
- mainnet and testnet addresses
- public GitHub repositories

Published JuiceSwap facts from official sources:

- explicitly described as a `Uniswap V3` fork on Citrea
- `NonfungiblePositionManager` is published
- `UniswapV3Factory` is published
- a dedicated gateway layer is published
- governance is documented as veto-based with a 14-day minimum review period
- no-upgradeable-proxy and no-admin-key posture is explicitly claimed

### What JuiceSwap gets wrong

Current public market size is materially smaller than Satsuma:

- current TVL about `$296k`
- 24h volume about `$46.9k`
- 30d volume about `$0.96m`

Current public token composition is heavily concentrated in `WCBTC`, with much smaller visible
`CTUSD` inventory than Satsuma.

JuiceSwap is also more tightly tied to the JuiceDollar stack through:

- `JUSD`
- `svJUSD`
- fee flows routed toward `JUICE`

### Helix implication

JuiceSwap is not the strongest market venue today.
It is the strongest venue to build against first without guessing.

## Pair Availability And Oracle Burden

## `ctUSD / wcBTC`

### Market reality

- `ctUSD / wcBTC` remains the best Helix product direction on Citrea
- Satsuma public inventory currently supports that direction more strongly than JuiceSwap

### Oracle reality

Reviewed official Citrea oracle docs list:

- `BTC/USD`
- `USDC/USD`
- `USDT/USD`
- `aUSD/USD`

Reviewed official Citrea oracle docs do **not** list:

- `ctUSD/USD`

That means both Satsuma and JuiceSwap inherit the same `ctUSD` oracle burden.

## Alternate pair: `USDC.e / wcBTC`

This pair is cleaner from an oracle standpoint because reviewed official Citrea oracle docs list:

- `USDC/USD`
- `BTC/USD`

But it is less aligned with Helix's accepted Citrea thesis than `ctUSD / wcBTC`.

## Why The Decision Favors JuiceSwap

Helix is not choosing the venue with the biggest current liquidity.
Helix is choosing the first venue it can implement against responsibly.

That favors JuiceSwap because:

- the venue model is explicit
- addresses are published
- repositories are public
- governance powers are disclosed
- LP position mechanics are documented

Satsuma may still become the better **launch** venue later.
It is not the better **first adapter implementation** venue today.

## Fallback Logic

If JuiceSwap ceases to be acceptable for first adapter work, the fallback venue is:

- `Satsuma`

but only after Satsuma publishes enough of the following:

- contract addresses
- core/periphery repositories
- governance or admin model
- upgradeability stance

## Final Recommendation

### Exact recommendation

- `build first Citrea CL adapter for JuiceSwap`

### Why

JuiceSwap is the first Citrea CL venue whose surface is sufficiently published for Helix to start
adapter implementation without guessing about core integration mechanics.

### Important qualifier

This does **not** mean JuiceSwap is already the best production launch venue for `ctUSD / wcBTC`.

It means:

- JuiceSwap is the best first engineering target
- Satsuma remains the venue to watch most closely for later market-driven launch re-evaluation

## References

- [Satsuma Exchange app](https://www.satsuma.exchange/)
- [Satsuma GitHub organization](https://github.com/SatsumaExchange)
- [JuiceSwap Overview](https://docs.juiceswap.com/overview.html)
- [JuiceSwap Liquidity Docs](https://docs.juiceswap.com/liquidity.html)
- [JuiceSwap Governance](https://docs.juiceswap.com/governance.html)
- [JuiceSwap Smart Contracts](https://docs.juiceswap.com/smart-contracts.html)
- [JuiceSwap GitHub organization](https://github.com/JuiceSwapxyz)
- [Citrea Mainnet Is Live](https://www.blog.citrea.xyz/citrea-mainnet-is-live/)
- [Citrea Oracles](https://docs.citrea.xyz/developer-documentation/ecosystem-tooling/oracles-vrf)
- [Satsuma protocol page on DefiLlama](https://defillama.com/protocol/satsuma)
- [JuiceSwap protocol page on DefiLlama](https://defillama.com/protocol/juiceswap)

## Related Docs

- [SATSUMA_DILIGENCE.md](./SATSUMA_DILIGENCE.md)
- [SATSUMA_ADAPTER_SPEC.md](./SATSUMA_ADAPTER_SPEC.md)
- [CITREA_INTEGRATION_PLAN.md](./CITREA_INTEGRATION_PLAN.md)
- [CITREA_VENUE_MATRIX.md](./CITREA_VENUE_MATRIX.md)
