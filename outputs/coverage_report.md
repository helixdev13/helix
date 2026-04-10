# Coverage Report

Source: stripped coverage workspace at `/tmp/helix-coverage`, refreshed from the current audited source and test files.

Main-tree note: `forge coverage --report summary --exclude-tests` still hits a compiler stack-depth failure in the full repo, so this report uses the stripped workspace to produce a stable summary.

## Audited contracts

| File | Lines | Statements | Branches | Funcs |
| --- | ---: | ---: | ---: | ---: |
| `contracts/src/token/HLXToken.sol` | 100.00% | 100.00% | 100.00% | 100.00% |
| `contracts/src/periphery/HelixLens.sol` | 100.00% | 100.00% | 100.00% | 100.00% |
| `contracts/src/periphery/RewardDistributor.sol` | 100.00% | 100.00% | 100.00% | 100.00% |
| `contracts/src/strategies/AutoCompoundClStrategy.sol` | 100.00% | 100.00% | 100.00% | 100.00% |

## Files below 90% line coverage

These are dependency or mock files in the coverage workspace, not the audited auto-compound contracts:

- `node_modules/@openzeppelin/contracts/access/AccessControl.sol` - 48.65%
- `node_modules/@openzeppelin/contracts/access/Ownable.sol` - 61.90%
- `node_modules/@openzeppelin/contracts/access/Ownable2Step.sol` - 16.67%
- `node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol` - 73.91%
- `node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol` - 44.87%
- `node_modules/@openzeppelin/contracts/utils/Context.sol` - 33.33%
- `node_modules/@openzeppelin/contracts/utils/ReentrancyGuard.sol` - 84.21%
- `node_modules/@openzeppelin/contracts/utils/StorageSlot.sol` - 11.11%
- `node_modules/@openzeppelin/contracts/utils/introspection/ERC165.sol` - 0.00%
- `contracts/src/adapters/MockClAdapter.sol` - 57.69%
- `contracts/src/core/OracleRouter.sol` - 45.83%
- `contracts/src/mocks/MockERC20.sol` - 50.00%

## Branch gaps

None in the audited contracts. The current debug pass shows 100% branch coverage for:

- `contracts/src/token/HLXToken.sol`
- `contracts/src/periphery/HelixLens.sol`
- `contracts/src/periphery/RewardDistributor.sol`
- `contracts/src/strategies/AutoCompoundClStrategy.sol`

## Test status

- `forge test` in the main repo passes `157/157`.
- The coverage workspace uses the current audited tests and passes the focused suite used for the report.
