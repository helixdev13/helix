# Citrea Configuration

## Purpose

This directory holds the current Citrea deployment and candidate profiles that still matter to the project.

## Configuration Files

- [juiceswap_usdce_wcbtc_candidate.md](/Users/melihkarakose/Desktop/helix/config/citrea/juiceswap_usdce_wcbtc_candidate.md)
  - frozen profile for the deployed `USDC.e / wcBTC` `JuiceSwap` lane
  - includes the approved pool, fee tier, frozen oracle mapping, ownership posture, and enablement gates

## Chain Metadata

- chain name: `Citrea Mainnet`
- chain id: `4114`
- RPC: `https://rpc.mainnet.citrea.xyz`
- explorer: `https://explorer.mainnet.citrea.xyz`
- gas asset: `cBTC`

## Active Asset References

- `USDC.e`
  - address: `0xE045e6c36cF77FAA2CfB54466D71A3aEF7bbE839`
  - role: current live lane base asset
- `wcBTC`
  - address: `0x3100000000000000000000000000000000000006`
  - role: current live lane BTC-side pair asset

## Active Venue Profile

- `JuiceSwap`
  - status: deployed specialist lane
  - note: current deployed lane uses `USDC.e / wcBTC` and remains disabled by default

## Active Oracle References

- `USDC/USD`
- `BTC/USD`
- frozen heartbeat: `21600`

## Current Repo Rule

The live Citrea deployment is already complete and frozen.

This directory should describe:

- the deployed `JuiceSwap` lane that exists now
- the fixed constants needed to operate or review it

It should not preserve superseded `ctUSD` base-vault release plans.

## Sources

- [Citrea Chain Information](https://docs.citrea.xyz/developer-documentation/chain-information)
- [Citrea USD: ctUSD](https://docs.citrea.xyz/developer-documentation/citrea-usd-ctusd)
- [Canonical Contract Addresses](https://docs.citrea.xyz/developer-documentation/canonical-contract-addresses)
- [Oracles & VRF](https://docs.citrea.xyz/developer-documentation/ecosystem-tooling/oracles-vrf)
- [Citrea Mainnet Is Live](https://www.blog.citrea.xyz/citrea-mainnet-is-live/)
