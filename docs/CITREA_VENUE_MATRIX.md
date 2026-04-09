# Citrea Venue Matrix

## Summary

This matrix compares the most relevant next-step venues for Helix on Citrea after:

- `HLX-ctUSD Base`
- no strategy attached
- `maxAllocationBps = 0`

As of April 8, 2026:

- no lending venue is approved yet for Helix
- `Satsuma` is the best first productive venue candidate
- `JuiceSwap` is the best-documented CL fallback
- `Morpho` is not approved yet

## Decision Matrix

| Venue | Product type | Relevance to Helix | Docs quality | Public contract discoverability | Public liquidity / usage | Oracle dependency | Admin / governance risk | Emergency exit complexity | Fit |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Morpho` | Lending | Natural allocator candidate in theory | High for generic Morpho, low for Citrea-specific markets | Low for Citrea-specific markets in this pass | DefiLlama shows about `$25.7` Citrea TVL and `$9.4` borrowed | High, market-oracle dependent | Low at core-market layer, higher if vault / allocator roles are involved | Medium to high, depends on market liquidity | `reject for now` |
| `Zentra` | Lending | Plausible capped allocator candidate later | Medium to high | Medium to high; mainnet addresses published | About `$220k` TVL and `$147k` borrowed on Citrea | High, explicit oracle dependence | Medium to high; provider / configurator / implementation / guardian / governance surfaces | Medium to high, pool-liquidity dependent | `later only` |
| `Satsuma` | DEX | Strongest current productive venue candidate | Low from reviewed sources | Low from reviewed sources | About `$1.38m` TVL, `$299.6k` 24h volume, `$11.82m` 30d volume | Medium to high for Helix adapter design | Unknown from reviewed official sources | Medium; CL unwind and slippage risk, but no lender queue risk | `first CL adapter` |
| `JuiceSwap` | DEX / CL venue | Strong secondary CL candidate | High | High; docs, addresses, and repos are public | About `$293k` TVL, `$46.9k` 24h volume, `$0.96m` 30d volume | Medium to high; Helix still needs external oracle discipline | Low to medium; no admin keys claim, but governance can act via veto-based system | Medium; CL unwind plus `JUSD` ecosystem coupling | `later only` |

## Venue Notes

## `Morpho`

### Strengths

- strong generic protocol quality
- immutable core-market design
- mature generic risk documentation

### Weaknesses

- Citrea-specific markets were not discoverable from reviewed official Morpho surfaces
- public Citrea depth is effectively zero for Helix purposes
- no public confirmation of `ctUSD` usability was found

### Helix conclusion

- not approved yet

## `Zentra`

### Strengths

- real Citrea-specific docs
- mainnet addresses published
- explicit oracle and liquidation docs
- Sherlock audit linked from official docs

### Weaknesses

- smaller public depth than the main DEX venues
- upgrade / implementation surface is materially broader than a simple immutable DEX
- docs are internally mixed on supported assets:
  - contract-address page lists `USDC` and `wcBTC`
  - risk page also mentions `ctUSD`

### Helix conclusion

- a future allocator candidate
- not the first productive venue

## `Satsuma`

### Strengths

- strongest current public DEX liquidity on Citrea
- strongest public DEX usage in 24h, 7d, and 30d volume among reviewed Citrea DEX venues

### Weaknesses

- limited public docs were discoverable in this pass
- contract surface and governance details still need direct venue-specific diligence

### Helix conclusion

- best first productive venue candidate
- best first CL adapter candidate

## `JuiceSwap`

### Strengths

- best public documentation among reviewed Citrea CL candidates
- mainnet and testnet addresses published
- public source repositories published
- explicit governance and security-property documentation

### Weaknesses

- materially lower public liquidity and volume than Satsuma
- tighter dependency on the JuiceDollar / `JUSD` / `svJUSD` ecosystem

### Helix conclusion

- best documentation-first fallback CL venue
- not the preferred first productive venue while liquidity remains lower than Satsuma

## Decision Readout

### First allocator

- none approved yet

Reason:

- Morpho lacks sufficient Citrea market visibility
- Zentra is more legible, but still early and smaller

### First CL adapter

- `Satsuma` preferred
- `JuiceSwap` secondary

Reason:

- Satsuma currently wins on public market depth
- JuiceSwap currently wins on docs and contract discoverability

## Final Position

Helix should not force allocator-first sequencing on Citrea just because lending venues exist.

Current evidence says:

- the lending side is still too thin or too opaque
- the DEX side is more productively legible

That makes the correct next-step venue call:

- `Satsuma` first

with one important qualifier:

- adapter coding should still begin only after direct Satsuma contract-surface diligence

## References

- [Citrea Mainnet Is Live](https://www.blog.citrea.xyz/citrea-mainnet-is-live/)
- [Zentra Docs](https://zentrafinance.gitbook.io/zentra)
- [JuiceSwap Overview](https://docs.juiceswap.com/overview.html)
- [JuiceSwap Governance](https://docs.juiceswap.com/governance.html)
- [JuiceSwap Smart Contracts](https://docs.juiceswap.com/smart-contracts.html)
- [Morpho Risk Documentation](https://docs.morpho.org/learn/resources/risks/)
- [Morpho Blue Public API](https://blue-api.morpho.org/graphql)
- [Citrea chain page on DefiLlama](https://defillama.com/chain/citrea)
- [Satsuma on DefiLlama](https://defillama.com/protocol/satsuma)
- [JuiceSwap on DefiLlama](https://defillama.com/protocol/juiceswap)
- [Zentra Finance on DefiLlama](https://defillama.com/protocol/zentra-finance)
