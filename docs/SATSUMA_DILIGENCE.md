# Satsuma Diligence

## Summary

This document evaluates whether `Satsuma` is sufficiently legible to become Helix's first
concentrated-liquidity venue on Citrea.

As of April 8, 2026, the answer is:

- `Satsuma = not approved yet`

That is not a negative verdict on Satsuma's market importance.
It is a technical-legibility verdict.

Public data makes Satsuma look like the strongest DEX on Citrea today.
Reviewed project sources do not yet make its contract surface legible enough for Helix to approve a
first CL adapter design.

## Evidence Standard

This pass separates:

- `official / project sources`
  - Satsuma's official app and project-controlled surfaces
- `public data`
  - DefiLlama TVL, volume, and token-composition data
- `inference`
  - Helix conclusions drawn from the gap between market strength and technical legibility

## Official / Project Sources Reviewed

- [Satsuma Exchange app](https://www.satsuma.exchange/)
- [Satsuma GitHub organization](https://github.com/SatsumaExchange)

## Public Data Reviewed

- [Satsuma protocol page on DefiLlama](https://defillama.com/protocol/satsuma)
- [Citrea chain page on DefiLlama](https://defillama.com/chain/citrea)
- [Satsuma DEX volume summary on DefiLlama](https://api.llama.fi/summary/dexs/satsuma?dataType=dailyVolume)

## 1. Whether Satsuma Has Official Docs And Where

### Official / project-source finding

From the reviewed project-controlled surfaces, Satsuma currently exposes:

- a live official app at `https://www.satsuma.exchange/`
- a GitHub organization at `https://github.com/SatsumaExchange`

What was **not** found from those reviewed surfaces:

- a dedicated public docs site
- a smart-contract reference page
- a published contract-address page
- a public architecture page
- a public governance page
- a public audits page

### Public-data finding

DefiLlama lists Satsuma as:

- the main DEX of Citrea
- available at `https://www.satsuma.exchange/`

That is useful market metadata, but it does not replace project-authored technical docs.

### Inference

Satsuma has an official public application, but not a sufficiently published technical reference
surface for Helix adapter work.

## 2. Whether Mainnet Contract Addresses Are Publicly Discoverable

### Official / project-source finding

Not from the reviewed Satsuma project surfaces.

During this pass:

- the app HTML exposed only a bundled front-end entrypoint
- no public address table was found
- no explorer-linked contract reference page was found
- no readable contract metadata was recovered from the public app shell
- the reviewed GitHub organization did not expose exchange core or periphery repositories

### Public-data finding

DefiLlama exposes protocol-level metadata, but not the venue's canonical contract-address set for
adapter implementation.

### Inference

For Helix purposes, Satsuma mainnet contracts are not yet publicly discoverable in a way that is
clean enough to support a first adapter design review.

## 3. Factory / Router / Position-Manager Surface

### Official / project-source finding

Not publicly documented from the reviewed Satsuma sources.

The reviewed project surfaces did **not** publish:

- a factory contract
- a router contract
- a position-manager contract
- a quoter contract
- ABIs
- repository links for core or periphery code

### Inference

Helix cannot yet answer basic adapter questions from project sources alone:

- how pools are discovered
- how CL positions are represented
- how fees are collected
- how liquidity is increased or decreased
- whether a canonical quoter exists

## 4. Whether Satsuma Is Uniswap-v3-style, Algebra-style, Or Something Else

### Official / project-source finding

Not confirmed.

No reviewed project-authored source explicitly stated whether Satsuma is:

- Uniswap V3 style
- Algebra style
- another CL design

### Public-data finding

Public market data identifies Satsuma as a DEX, but not its exact contract model.

### Inference

It would be irresponsible for Helix to assume `Uniswap V3` compatibility from public market success
alone.

## 5. Pool Model And LP Position Model

### Official / project-source finding

Not documented from the reviewed project surfaces.

Unknowns that remain open:

- whether LP positions are NFTs, fungible LP shares, or another representation
- whether positions are full-range or custom-range CL positions
- whether fee tiers are static or governance-enabled
- whether positions are managed through a gateway layer or directly through periphery contracts

### Inference

Because the LP position model is not published clearly enough, Helix cannot yet map the current
`ManagedClStrategy` + adapter architecture onto Satsuma with confidence.

## 6. Governance / Admin Controls

### Official / project-source finding

Not publicly documented from the reviewed project surfaces.

No reviewed Satsuma source clearly published:

- governance contracts
- admin roles
- pause roles
- fee-parameter governance
- ownership-transfer process

### Inference

Satsuma's governance and admin risk should currently be treated as `unknown`, not as `low`.

## 7. Upgradeability / Proxy Usage

### Official / project-source finding

Not publicly documented from the reviewed project surfaces.

### Inference

Helix cannot yet determine whether Satsuma relies on:

- immutable deployments
- upgradeable proxies
- upgradeable routers or gateways
- owner-controlled registries

That is a direct blocker for first-adapter approval.

## 8. Fee Collection Model

### Official / project-source finding

Not publicly documented from the reviewed project surfaces.

Unknowns include:

- how LP fees accrue
- whether protocol fees can be toggled or redirected
- how fee collection is invoked
- whether fees are collected per position or through a wrapper layer

### Inference

Without a published fee-collection model, Helix cannot design reliable valuation, harvest, or
unwind semantics for an adapter.

## 9. Emergency Controls / Pause Surface

### Official / project-source finding

Not publicly documented from the reviewed project surfaces.

No reviewed Satsuma source clearly disclosed:

- pause authority
- emergency shutdown behavior
- restricted token lists
- privileged rescue mechanisms

### Inference

Unknown emergency controls are a material integration blocker for Helix's first CL venue.

## 10. Candidate Citrea Pools Relevant To Helix

### Official / project-source finding

No reviewed Satsuma project surface published a canonical live pool list.

### Public-data finding

DefiLlama's current `tokensInUsd` composition for Satsuma on Citrea, as observed on April 8, 2026,
shows meaningful inventory in:

- `CTUSD`
- `WCBTC`
- `USDC`
- `GUSD`
- `WBTC`
- negligible `USDT`

Current public size indicators reviewed in this pass:

- current TVL about `$1.39m`
- 24h DEX volume about `$299.6k`
- 30d DEX volume about `$11.82m`

### Inference

This makes the following pool directions plausible:

- `ctUSD / wcBTC`
- `USDC.e / wcBTC`
- `ctUSD / WBTC.e`
- `GUSD / wcBTC`

Important qualifier:

- this is an inference from token composition and venue inventory
- exact pool addresses and exact pool sizes were not confirmed from reviewed project sources

## 11. Technical Suitability For A First Helix CL Adapter

### What Satsuma gets right

From public market data, Satsuma currently looks like:

- the deepest DEX venue on Citrea
- the strongest current venue for `ctUSD`-related stable liquidity
- the most commercially relevant DEX surface for a later Helix launch

### What is still missing

For Helix adapter design, the missing items are more important than the TVL lead:

- no published contract-address set
- no published factory/router/position-manager reference
- no published governance or admin surface
- no published upgradeability stance
- no published fee-collection model
- no published emergency-control surface

### Helix conclusion

Satsuma is commercially attractive but not technically legible enough yet.

## Decision

### Explicit answer

- `Satsuma = not approved yet`

### Why

The blocker is not liquidity.

The blocker is that Helix would still be guessing about:

- the venue's contract topology
- its trust surface
- its LP position model
- its fee and emergency mechanics

That is too much uncertainty for Helix's first Citrea CL adapter.

## Revisit Conditions

Re-open Satsuma approval only if at least one of the following becomes public from project sources:

- a contract-address page
- core/periphery repositories
- a docs site or technical architecture page
- an explicit governance or admin model
- explorer-linked factory/router/position-manager references

## References

- [Satsuma Exchange app](https://www.satsuma.exchange/)
- [Satsuma GitHub organization](https://github.com/SatsumaExchange)
- [Satsuma protocol page on DefiLlama](https://defillama.com/protocol/satsuma)
- [Citrea chain page on DefiLlama](https://defillama.com/chain/citrea)

## Related Docs

- [SATSUMA_ADAPTER_SPEC.md](./SATSUMA_ADAPTER_SPEC.md)
- [CITREA_CL_DECISION.md](./CITREA_CL_DECISION.md)
- [CITREA_VENUE_MATRIX.md](./CITREA_VENUE_MATRIX.md)
