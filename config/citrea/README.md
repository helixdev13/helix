# Citrea Configuration Stub

## Purpose

This file is a documentation-first Citrea config stub.

It exists to keep chain, asset, venue, oracle, and deployment assumptions explicit while Helix is
still in research/spec mode.

## Configuration Files

- [mainnet.md](/Users/melihkarakose/Desktop/helix/config/citrea/mainnet.md)
  - deployment profile for the first Citrea release
  - includes chain metadata, ctUSD metadata, config placeholders, and launch checklist
- [juiceswap_usdce_wcbtc_candidate.md](/Users/melihkarakose/Desktop/helix/config/citrea/juiceswap_usdce_wcbtc_candidate.md)
  - concrete first-live candidate profile for `USDC.e / wcBTC` on `JuiceSwap`
  - includes the approved pool, fee tier, launch envelope, and verification checklist

## Chain Metadata

- chain name: `Citrea Mainnet`
- chain id: `4114`
- RPC: `https://rpc.mainnet.citrea.xyz`
- explorer: `https://explorer.mainnet.citrea.xyz`
- gas asset: `cBTC`

## Asset Candidates

### Recommended first asset

- `ctUSD`
  - address: `0x8D82c4E3c936C7B5724A382a9c5a4E6Eb7aB6d5D`
  - decimals: `6`
  - role: recommended first Helix Citrea base-vault asset

### Other notable assets

- `wcBTC`
  - address: `0x3100000000000000000000000000000000000006`
  - role: later BTC-native product candidate
- `USDC.e`
  - address: `0xE045e6c36cF77FAA2CfB54466D71A3aEF7bbE839`
  - role: bridged stable candidate
- `USDT.e`
  - address: `0x9f3096Bac87e7F03DC09b0B416eB0DF837304dc4`
  - role: bridged stable candidate
- `WBTC.e`
  - address: `0xDF240DC08B0FdaD1d93b74d5048871232f6BEA3d`
  - role: bridged BTC candidate

## Venue Candidates

### First release

- no venue dependency

### First allocator candidate

- `Morpho`
  - status: due diligence required
  - note: referenced by Citrea’s mainnet launch materials as a live lending primitive

### First CL adapter candidate

- `JuiceSwap`
  - status: approved first CL venue for implementation and launch-candidate prep
  - note: first live candidate uses `USDC.e / wcBTC`, not `ctUSD / wcBTC`

## Oracle Candidates

### Preferred first provider

- `RedStone`

Citrea docs list the following RedStone mainnet feeds:

- `BTC/USD`
- `USDC/USD`
- `USDT/USD`
- `aUSD/USD`

As of April 8, 2026, no `ctUSD/USD` feed is listed on the official Citrea oracle page reviewed for
this repo pass.

## Onboarding Candidates

### Stablecoin onboarding

- `Bridge Hub`
- `MoonPay`

### BTC onboarding

- `Clementine`
- `Garden`

## Recommended First Deployment

- product: `HLX-ctUSD Base`
- asset: `ctUSD`
- strategy: none on day one
- external venue dependency: none on day one

## Recommended First Live Candidate

- product direction: `USDC.e / wcBTC`
- venue: `JuiceSwap`
- approved fee tier: `3000`
- posture: strategy deployment allowed, productive allocation disabled by default

## Deployment Checklist

1. confirm chain metadata and RPC provider choice
2. confirm owner and guardian addresses
3. confirm `ctUSD` token metadata and decimals handling
4. deploy core contracts to Citrea
5. create `HLX-ctUSD Base`
6. set conservative initial `depositCap`
7. set `maxAllocationBps = 0` if no strategy is attached
8. publish addresses and runbooks in deployment notes
9. keep venue integration deferred until diligence gates are passed

## Sources

- [Citrea Chain Information](https://docs.citrea.xyz/developer-documentation/chain-information)
- [Citrea USD: ctUSD](https://docs.citrea.xyz/developer-documentation/citrea-usd-ctusd)
- [Canonical Contract Addresses](https://docs.citrea.xyz/developer-documentation/canonical-contract-addresses)
- [Oracles & VRF](https://docs.citrea.xyz/developer-documentation/ecosystem-tooling/oracles-vrf)
- [Citrea Mainnet Is Live](https://www.blog.citrea.xyz/citrea-mainnet-is-live/)
