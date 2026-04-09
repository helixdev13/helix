# Citrea Allocator Diligence

## Summary

This document asks a narrow question:

- is `Morpho` the best first productive Helix venue on Citrea after `HLX-ctUSD Base`?

As of April 8, 2026, the answer is:

- `Morpho = not approved yet`

That is not a claim that Morpho is absent from Citrea.
It is a claim that the currently discoverable, market-level evidence is not strong enough for Helix
to approve Morpho as the next live yield venue.

## Evidence Standard

This pass uses three evidence classes:

- `official docs`
  - Citrea launch materials
  - Morpho official docs and public API
- `public market data`
  - DefiLlama TVL and chain-level activity
- `inference`
  - Helix recommendation based on the gap between official venue claims and public market evidence

## Is Morpho Live On Citrea Mainnet?

### Official-source answer

At the ecosystem-announcement level: yes.

Citrea’s mainnet launch post explicitly lists:

- `Morpho` under `Lend`
- `Zentra Finance (soon)`

That means Citrea itself presents Morpho as part of the live mainnet lending stack.

### Public-data answer

DefiLlama also lists Morpho on Citrea.

As of April 8, 2026, the public chain-level numbers exposed there are approximately:

- Citrea supplied / TVL: `$25.7`
- Citrea borrowed: `$9.4`

### Helix interpretation

Those two facts do not add up to an approval decision.

Citrea’s launch page is enough to say:

- Morpho has ecosystem-level presence on Citrea

It is not enough to say:

- Morpho is ready for Helix capital allocation

## Exact Markets And Assets Relevant To Helix

This is the main blocker.

From the official Morpho surfaces reviewed in this pass:

- the public Morpho Blue GraphQL API does **not** list chain `4114`
- the reviewed Morpho docs did **not** expose a Citrea-specific market list
- no Citrea-specific Morpho market addresses were surfaced from the reviewed official docs

That means Helix cannot yet answer basic allocator questions with confidence:

- which exact Citrea markets are live
- which loan assets are available
- which collateral assets are available
- whether the markets are isolated or curator-managed vault routes
- what the Citrea market caps and liquidity actually are

## Is `ctUSD` Usable There?

Not evidenced in this pass.

No reviewed Morpho official surface exposed:

- a `ctUSD` market on Citrea
- a `ctUSD` vault on Citrea
- a Citrea-specific market list where `ctUSD` appears

So the correct answer is:

- `ctUSD` usability on Morpho Citrea is not confirmed

That alone blocks Helix from treating Morpho as the first `ctUSD` productive venue.

## Supply / Borrow Depth

Publicly available Citrea-specific depth is very weak.

From DefiLlama chain-level protocol data as of April 8, 2026:

- Morpho on Citrea TVL: about `$25.7`
- Morpho on Citrea borrowed: about `$9.4`

Even allowing for public-data incompleteness, those numbers are far below the threshold needed for
Helix to treat Morpho as a meaningful allocator venue.

## Oracle Model

Morpho’s official risk documentation describes the oracle model in generic terms:

- every market is connected to an oracle at market creation
- oracle quality must be assessed for safety and liveness
- faulty or stale oracle behavior can lead to liquidations or bad debt

For Helix, that means a Morpho allocator would need market-level oracle diligence on:

- the exact Citrea market oracle
- update frequency
- manipulation resistance
- failure behavior

That market-specific diligence is not possible yet from the currently discoverable Citrea material.

## Liquidation Model

Morpho’s official docs describe:

- immutable market LLTV / liquidation thresholds
- liquidation when positions exceed market limits
- bad debt risk if collateral falls faster than liquidators can react

That model is intelligible and mature in the abstract.

The missing part is Citrea-specific:

- which markets exist
- what LLTVs they use
- how much liquidator competition exists on Citrea
- whether market depth is sufficient for unwind quality

## Pause / Freeze / Admin Controls

### Morpho core

Morpho’s official docs describe core market contracts as:

- immutable

That is a positive trust characteristic.

### Morpho vaults / allocators

Morpho’s official docs also describe additional governance surfaces around vault products:

- owner
- curator
- allocator
- sentinel / guardian-style de-risking roles
- timelocks on critical changes

For Helix this matters because a real integration path might not be:

- direct market only

It could instead be:

- allocator or vault-based routing

That introduces a larger trust and governance surface than immutable core markets alone.

## Upgradeability / Trust Surface

Current read:

- Morpho core market logic: low upgrade risk, high immutability
- vault and allocator layer: higher governance and role risk

But on Citrea specifically, Helix still lacks a clean public answer to:

- which exact Morpho deployment surface is live and liquid
- whether Helix would integrate a market, a vault, or an allocator layer

## Withdrawal Semantics And Liquidity Risk

Morpho’s official docs explicitly note:

- suppliers may be unable to withdraw when liquidity is scarce
- withdrawal quality depends on market utilization and interest-rate behavior

For Helix, that is acceptable only if:

- market depth is real
- exits are observable
- cap sizing is matched to public liquidity

Current Citrea public depth is too small for approval.

## Fit For Helix

| Helix use case | Fit today | Why |
| --- | --- | --- |
| Base-yield allocator | No | No confirmed Citrea market list, no confirmed `ctUSD` venue path, negligible public depth |
| Capped idle allocator | No | Same blockers as above; even a tiny idle allocator still needs reliable venue visibility |
| Later candidate | Yes | Revisit if Citrea-specific markets, oracles, and liquidity become publicly legible |

## Decision

### Explicit answer

- `Morpho = not approved yet`

### Why

The blocker is not Morpho’s general architecture.

The blocker is Citrea-specific diligence quality:

- official Citrea launch material says Morpho is live
- public chain-level data shows only de minimis Citrea depth
- Morpho’s public Blue API does not currently expose chain `4114`
- no reviewed official Morpho surface exposed the Citrea market list Helix would need

That is not enough for Helix to approve a live allocator design.

## Revisit Conditions

Re-open Morpho diligence only if at least one of the following becomes true:

- official Morpho surfaces publish Citrea market addresses and parameters
- the public Morpho API exposes Citrea chain and markets
- `ctUSD` or a clear Helix target stable market is publicly confirmed
- public Citrea supply / borrow depth becomes large enough for a capped allocator

## References

- [Citrea Mainnet Is Live](https://www.blog.citrea.xyz/citrea-mainnet-is-live/)
- [Morpho Risk Documentation](https://docs.morpho.org/learn/resources/risks/)
- [Morpho Contracts and Repositories](https://docs.morpho.org/get-started/resources/contracts/)
- [Morpho Blue Public API](https://blue-api.morpho.org/graphql)
- [Citrea chain page on DefiLlama](https://defillama.com/chain/citrea)
