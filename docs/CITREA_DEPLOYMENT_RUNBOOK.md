# Citrea Deployment Runbook

## Summary

This runbook prepares the first Helix Citrea release:

- product: `HLX-ctUSD Base`
- chain: `Citrea Mainnet`
- strategy: unset
- `maxAllocationBps = 0`

This is a low-risk base-vault deployment shape only.

It does not include:

- Satsuma integration
- JuiceSwap integration
- Morpho integration
- any live strategy attachment

## Citrea Mainnet Metadata

- chain name: `Citrea Mainnet`
- chain id: `4114`
- RPC: `https://rpc.mainnet.citrea.xyz`
- explorer: `https://explorer.mainnet.citrea.xyz`
- gas asset: `cBTC`

## ctUSD Metadata

- token: `ctUSD`
- address: `0x8D82c4E3c936C7B5724A382a9c5a4E6Eb7aB6d5D`
- decimals: `6`

The deployment script checks that the live token reports `6` decimals before proceeding.

## Deployment Shape

### Required first-release properties

- deploy Helix core contracts to Citrea Mainnet
- create `HLX-ctUSD Base`
- keep strategy unset
- set `maxAllocationBps = 0`
- set `paused = false`
- set `withdrawOnly = false`
- set a conservative initial deposit cap

### Recommended initial cap

- placeholder recommendation: `50,000 ctUSD`
- raw units: `50_000e6`

This should still be treated as an operator decision, not a protocol constant.

## Owner And Guardian Assumptions

### Recommended production posture

- `owner`: multisig or tightly controlled operator address
- `guardian`: separate operational address or operational multisig

### Script assumptions

`DeployCitreaCtUSDBase.s.sol` assumes the broadcaster:

- owns `VaultFactory`
- owns `RiskEngine`

This is required because the script performs both:

- `VaultFactory.createVault(...)`
- `RiskEngine.setConfig(...)`

The broadcaster does not need to be the final vault owner.

## Deployment Order

### Step 1. Deploy core

Deploy:

1. `RiskEngine`
2. `OracleRouter`
3. `VaultFactory`
4. optional `HelixLens`

Script:

- [DeployCitreaCore.s.sol](/Users/melihkarakose/Desktop/helix/contracts/script/DeployCitreaCore.s.sol)

### Step 2. Create the base vault

Create:

- `HLX-ctUSD Base`

With:

- asset: `ctUSD`
- strategy: unset
- deposit cap: configured
- `maxAllocationBps = 0`
- `paused = false`
- `withdrawOnly = false`

Script:

- [DeployCitreaCtUSDBase.s.sol](/Users/melihkarakose/Desktop/helix/contracts/script/DeployCitreaCtUSDBase.s.sol)

## Required Environment Variables

### `DeployCitreaCore.s.sol`

- `PRIVATE_KEY`
  - required
- `RISK_ENGINE_OWNER`
  - optional, defaults to broadcaster
- `ORACLE_ROUTER_OWNER`
  - optional, defaults to broadcaster
- `VAULT_FACTORY_OWNER`
  - optional, defaults to broadcaster
- `DEPLOY_LENS`
  - optional, defaults to `true`

### `DeployCitreaCtUSDBase.s.sol`

- `PRIVATE_KEY`
  - required
- `VAULT_FACTORY_ADDRESS`
  - required
- `INITIAL_OWNER`
  - required
- `GUARDIAN`
  - required
- `VAULT_NAME`
  - optional, defaults to `Helix ctUSD Base`
- `VAULT_SYMBOL`
  - optional, defaults to `HLX-ctUSD-Base`
- `DEPOSIT_CAP`
  - optional, defaults to `50_000e6`

## Exact Commands

### 1. Deploy core on Citrea Mainnet

```bash
export PRIVATE_KEY=0x...
export CITREA_RPC_URL=https://rpc.mainnet.citrea.xyz
export RISK_ENGINE_OWNER=0xYourOwner
export ORACLE_ROUTER_OWNER=0xYourOwner
export VAULT_FACTORY_OWNER=0xYourOwner

forge script contracts/script/DeployCitreaCore.s.sol:DeployCitreaCore \
  --rpc-url $CITREA_RPC_URL \
  --broadcast
```

Record:

- `RiskEngine`
- `OracleRouter`
- `VaultFactory`
- optional `HelixLens`

### 2. Create `HLX-ctUSD Base`

```bash
export VAULT_FACTORY_ADDRESS=0xYourVaultFactory
export INITIAL_OWNER=0xYourVaultOwner
export GUARDIAN=0xYourGuardian
export DEPOSIT_CAP=50000000000

forge script contracts/script/DeployCitreaCtUSDBase.s.sol:DeployCitreaCtUSDBase \
  --rpc-url $CITREA_RPC_URL \
  --broadcast
```

## Expected Result

After the second script:

- one `HelixVault` exists for `ctUSD`
- `strategy == address(0)`
- `depositCap == DEPOSIT_CAP`
- `maxAllocationBps == 0`
- `paused == false`
- `withdrawOnly == false`

## Verification Checklist

Read and verify:

- `VaultFactory.allVaults()`
- `HelixVault.asset()`
- `HelixVault.guardian()`
- `HelixVault.strategy()`
- `HelixVault.totalAssets()`
- `HelixVault.totalIdle()`
- `HelixVault.totalStrategyAssets()`
- `RiskEngine.getConfig(vault)`

Expected:

- `asset == ctUSD`
- `strategy == address(0)`
- `totalStrategyAssets == 0`
- `depositCap == chosen cap`
- `maxAllocationBps == 0`
- `paused == false`
- `withdrawOnly == false`

If `HelixLens` is deployed, also verify:

- `HelixLens.getVaultView(vault)`

## What Must Not Be Done In This Release

Do not:

- attach a strategy
- increase `maxAllocationBps` above `0`
- launch a CL product
- depend on a venue adapter
- require a `ctUSD/USD` oracle for settlement

## Operator Notes

- `maxAllocationBps = 0` is part of the release shape, not a temporary oversight.
- The first Citrea release is a controlled custody-and-accounting deployment, not a yield router.
- Strategy attachment is a later milestone gated by venue and oracle diligence.

## Related Docs

- [CITREA_OPERATIONS.md](./CITREA_OPERATIONS.md)
- [CITREA_INTEGRATION_PLAN.md](./CITREA_INTEGRATION_PLAN.md)
- [PORTABILITY.md](./PORTABILITY.md)
- [config/citrea/mainnet.md](/Users/melihkarakose/Desktop/helix/config/citrea/mainnet.md)
