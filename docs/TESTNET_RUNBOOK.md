# Helix v0 Testnet Runbook

## Goal

This runbook covers:

- local Anvil deployment
- mock-vault setup
- the minimum operator flow needed to verify deployability
- BSC testnet placeholders

## Local Anvil Flow

### 1. Start Anvil

```bash
anvil
```

### 2. Deploy Core

```bash
forge script contracts/script/DeployCore.s.sol:DeployCore \
  --rpc-url http://127.0.0.1:8545 \
  --broadcast
```

Record:

- `RiskEngine`
- `OracleRouter`
- `VaultFactory`
- optional `HelixLens`

### 3. Deploy A Mock Vault

Replace `VAULT_FACTORY_ADDRESS` with the address printed by `DeployCore`.

```bash
export VAULT_FACTORY_ADDRESS=0xYourFactoryAddress

forge script contracts/script/DeployMockVault.s.sol:DeployMockVault \
  --rpc-url http://127.0.0.1:8545 \
  --broadcast
```

Optional seeded demo:

```bash
export SEED_DEMO=true
export SEED_AMOUNT=100000000000000000000
export ALLOCATE_AMOUNT=60000000000000000000
export DEMO_PROFIT=5000000000000000000

forge script contracts/script/DeployMockVault.s.sol:DeployMockVault \
  --rpc-url http://127.0.0.1:8545 \
  --broadcast
```

Default unit scaling:

- if the script deploys the mock asset, default amounts scale with `MOCK_ASSET_DECIMALS`
- if `MOCK_ASSET_ADDRESS` is provided, default amounts scale using `IERC20Metadata.decimals()` from that token
- explicit env values such as `DEPOSIT_CAP`, `SEED_AMOUNT`, `ALLOCATE_AMOUNT`, and `DEMO_PROFIT` are always treated as raw asset units

Examples:

- `MOCK_ASSET_DECIMALS=18` gives a default `SEED_AMOUNT` of `100e18`
- `MOCK_ASSET_DECIMALS=6` gives a default `SEED_AMOUNT` of `100e6`

Seeded demo restriction:

- `SEED_DEMO=true` is only supported when the script deploys the mock asset
- if `MOCK_ASSET_ADDRESS` is set, the script reverts instead of assuming the external token supports `mint`

### 4. Inspect The Result

Useful direct reads:

- `VaultFactory.allVaults()`
- `HelixVault.asset()`
- `HelixVault.totalAssets()`
- `HelixVault.totalIdle()`
- `HelixVault.totalStrategyAssets()`
- `HelixVault.strategy()`
- `HelixVault.paused()`
- `HelixVault.withdrawOnly()`
- `RiskEngine.getConfig(vault)`

If `HelixLens` was deployed, use:

- `HelixLens.getVaultView(vault)`

### 5. Reproducible Full Flow

Run the integration test:

```bash
forge test --match-contract IntegrationFlowTest -vvv
```

That test covers:

- core deployment
- vault creation
- strategy attachment
- risk configuration
- user deposit
- strategy allocation
- profit simulation
- loss simulation
- emergency pause
- post-unwind redemptions

## BSC Testnet Placeholders

Suggested envs:

```bash
export PRIVATE_KEY=0x...
export BSC_TESTNET_RPC_URL=https://data-seed-prebsc-1-s1.binance.org:8545
```

Then:

```bash
forge script contracts/script/DeployCore.s.sol:DeployCore \
  --rpc-url $BSC_TESTNET_RPC_URL \
  --broadcast
```

After core deployment:

```bash
export VAULT_FACTORY_ADDRESS=0x...
export GUARDIAN=0x...
export VAULT_NAME="Helix Testnet Vault"
export VAULT_SYMBOL="HLX-T1"
export DEPOSIT_CAP=1000000000000000000000000
export MAX_ALLOCATION_BPS=8000

forge script contracts/script/DeployMockVault.s.sol:DeployMockVault \
  --rpc-url $BSC_TESTNET_RPC_URL \
  --broadcast
```

## Operational Notes

- `OracleRouter` is deployed in core but remains isolated from vault accounting in v0.
- `VaultFactory` is owner-controlled to avoid registry spam and keep deployment explicit.
- Strategy attachment is a separate operator action by design.
- The mock deploy script assumes the broadcaster is the vault owner so it can attach the strategy and set config in one pass.
- Default deploy-script numeric values are decimal-aware; explicit env overrides remain raw token units.
- Seeded demo only works when the script deploys `MockERC20` itself.
- For staged ownership, deploy with the broadcaster as owner, finish setup, then transfer ownership as a separate action.
