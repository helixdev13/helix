# Current Deployed State

## Summary

This note records the current deployed Helix Citrea stack for the frozen `USDC.e / wcBTC` JuiceSwap candidate.

Current status:

- deployed
- ownership accepted
- disabled by default

Productive enablement is not active and remains blocked until the documented same-day liquidity signoff passes.

## Deployed Contracts

- `RiskEngine`: `0xf211C2eFbeFe0e9c26bDDfA8F65c42E1481A1025`
- `OracleRouter`: `0xA666f5806a4fCC563a185372DA6c5b19FAEeA7Ea`
- `VaultFactory`: `0x0EBF079BFB810931838504bfCf051DD056e206e7`
- `USDC/USD oracle adapter`: `0xCd13c1651Cc1E730462A43C85F962E05DE437C88`
- `BTC/USD oracle adapter`: `0x90AA8B6c754A154d3A0a0e79444BCf8275e3cE4F`
- `HelixVault`: `0x963252Bb923f733E9321A2e4c509070337A0fe28`
- `JuiceSwapClAdapter`: `0x9fE0460523b13730EAa5466F4C3ff184276e45aF`
- `ManagedClStrategy`: `0x98c888b9ABC686cb9219013f6AF89E245667B38E`

## Role Addresses

- `FINAL_OWNER`: `0x7C3244f1071Fb9849521f4B15dcFd20433F13f35`
- `GUARDIAN`: `0x7eB55a7bEe37B985b0fA10c262Ed712D1DEad742`
- `STRATEGIST`: `0xC89044F853a0F004AE5b0daD8A384A52bd2D73bF`
- `DEPLOYER_EOA`: `0xad53D0aBC81Ff8a42d6C3620Dc91B275C898EDF7`

## Ownership State

Ownership has been accepted by `FINAL_OWNER` on all five governed contracts:

- `VaultFactory`
- `RiskEngine`
- `OracleRouter`
- `HelixVault`
- `ManagedClStrategy`

Current pending-owner state:

- no contract has a non-zero `pendingOwner`

## Safety State

- strategy attached: `true`
- `maxAllocationBps = 0`
- `paused = false`
- `withdrawOnly = false`

This means the stack is deployed and wired, but remains non-productive.

## Live Candidate Context

- venue: `JuiceSwap`
- pair: `USDC.e / wcBTC`
- approved pool: `0xD77f369715E227B93D48b09066640F46F0B01b29`
- fee tier: `3000`
- heartbeat: `21600`

## Current Operating Constraint

Do not enable productive allocation from this deployed state unless the same-day liquidity signoff in the frozen operator docs passes immediately before enablement.
