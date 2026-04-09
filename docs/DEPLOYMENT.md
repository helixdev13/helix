# Helix v0 Deployment

## Scope

Helix v0 deployment is intentionally simple:

1. deploy core contracts,
2. create a vault through the factory,
3. deploy and attach a strategy,
4. configure risk limits,
5. optionally seed a local demo state.

There is no upgradeability, no proxy system, no token, and no keeper system in this milestone.

## Deployment Order

1. `RiskEngine`
2. `OracleRouter`
3. `VaultFactory`
4. optional `HelixLens`
5. vault creation via `VaultFactory`
6. strategy deployment
7. `HelixVault.setStrategy(...)`
8. `RiskEngine.setConfig(...)`

## Contracts

- `RiskEngine`
  - per-vault deposit cap
  - pause flag
  - withdraw-only flag
  - max allocation bps
- `OracleRouter`
  - mock-price registry and staleness checks
  - isolated from `HelixVault` state in v0
- `VaultFactory`
  - owner-controlled vault deployment registry
  - deploys `HelixVault` instances with a shared `RiskEngine`
- `HelixLens`
  - read-only aggregation helper for integrations

## Ownership Assumptions

### Core deploy

`DeployCore.s.sol` supports distinct owners per core contract through env vars, but defaults every owner to the broadcaster:

- `RISK_ENGINE_OWNER`
- `ORACLE_ROUTER_OWNER`
- `VAULT_FACTORY_OWNER`

### Mock vault deploy

`DeployMockVault.s.sol` assumes the broadcaster is also:

- the `VaultFactory` owner
- the new vault owner

That keeps the scaffold explicit and lets the script perform:

- vault creation
- strategy attachment
- risk config
- optional demo seeding

If you want a separate vault owner in production-like flows, create the vault explicitly and then hand off ownership in a separate step.

## Guardian Usage

The guardian role is intentionally narrow:

- can trigger `emergencyPause()`
- can enable withdraw-only mode
- cannot disable withdraw-only
- cannot clear pause
- cannot allocate or replace strategy

## Required Env Vars

### `DeployCore.s.sol`

- `PRIVATE_KEY`
  - optional on local Anvil
  - defaults to the standard first Anvil key
- `RISK_ENGINE_OWNER`
  - optional
- `ORACLE_ROUTER_OWNER`
  - optional
- `VAULT_FACTORY_OWNER`
  - optional
- `DEPLOY_LENS`
  - optional, defaults to `true`

### `DeployMockVault.s.sol`

- `PRIVATE_KEY`
  - optional on local Anvil
- `VAULT_FACTORY_ADDRESS`
  - required
- `INITIAL_OWNER`
  - optional, defaults to broadcaster
  - must equal broadcaster for this scaffold script
- `GUARDIAN`
  - optional, defaults to broadcaster
- `MOCK_ASSET_ADDRESS`
  - optional, deploys a new `MockERC20` if unset
- `MOCK_ASSET_NAME`
  - optional
- `MOCK_ASSET_SYMBOL`
  - optional
- `MOCK_ASSET_DECIMALS`
  - optional, defaults to `18`
  - only used when the script deploys the mock asset itself
  - ignored when `MOCK_ASSET_ADDRESS` is set
- `VAULT_NAME`
  - optional
- `VAULT_SYMBOL`
  - optional
- `DEPOSIT_CAP`
  - optional
  - explicit value is interpreted in raw asset units
- `MAX_ALLOCATION_BPS`
  - optional
- `PAUSED`
  - optional
- `WITHDRAW_ONLY`
  - optional
- `SEED_DEMO`
  - optional
  - if `true`, only supported when the script deploys the mock asset
- `SEED_AMOUNT`
  - optional
  - explicit value is interpreted in raw asset units
- `ALLOCATE_AMOUNT`
  - optional
  - explicit value is interpreted in raw asset units
- `DEMO_PROFIT`
  - optional
  - explicit value is interpreted in raw asset units

## Unit Scaling Behavior

`DeployMockVault.s.sol` now scales default values using the asset decimals instead of assuming `18` decimals.

- when deploying a new mock asset:
  - defaults use `MOCK_ASSET_DECIMALS`
- when using `MOCK_ASSET_ADDRESS`:
  - defaults resolve decimals from the token contract itself

Scaled defaults are:

- `depositCap = 1_000_000 * 10^assetDecimals`
- `seedAmount = 100 * 10^assetDecimals`
- `allocateAmount = 60 * 10^assetDecimals`
- `demoProfit = 5 * 10^assetDecimals`

If you set `DEPOSIT_CAP`, `SEED_AMOUNT`, `ALLOCATE_AMOUNT`, or `DEMO_PROFIT` explicitly, the script uses those exact raw-unit values and does not rescale them.

## Seeded Demo Restriction

If `MOCK_ASSET_ADDRESS` is set, `SEED_DEMO=true` will revert.

That restriction is intentional. The seeded demo path uses `MockERC20.mint(...)`, which is only safe to assume when the script deploys the mock asset itself.

## Creating A New Vault

Minimal flow:

1. call `VaultFactory.createVault(asset, initialOwner, guardian, name, symbol)`
2. deploy `MockClStrategy(asset, vault)`
3. call `vault.setStrategy(strategy)`
4. call `riskEngine.setConfig(vault, depositCap, maxAllocationBps, paused, withdrawOnly)`

Strategy attachment is deliberately separate from factory creation in v0. That keeps deployment explicit and makes strategy choice auditable.

## Attaching A Strategy

Requirements enforced by `HelixVault.setStrategy(...)`:

- strategy must be non-zero
- old strategy must be empty
- new strategy must be empty
- strategy asset must equal vault asset
- strategy vault must equal the target vault

## Configuring Limits

Risk configuration uses:

- `depositCap`
- `maxAllocationBps`
- `paused`
- `withdrawOnly`

Example:

```solidity
riskEngine.setConfig(address(vault), 1_000_000e18, 8_000, false, false);
```

## Local End-To-End Demo

See [TESTNET_RUNBOOK.md](./TESTNET_RUNBOOK.md) for command examples.

The reproducible operator flow is also covered in:

- `contracts/test/IntegrationFlow.t.sol`

For the first Citrea base-vault release, use:

- [CITREA_DEPLOYMENT_RUNBOOK.md](./CITREA_DEPLOYMENT_RUNBOOK.md)
- [CITREA_OPERATIONS.md](./CITREA_OPERATIONS.md)
