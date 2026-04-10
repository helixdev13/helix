// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";

import { DeployCitreaCore } from "../script/DeployCitreaCore.s.sol";
import { DeployCitreaUsdcBase } from "../script/DeployCitreaUsdcBase.s.sol";
import { TransferCitreaUsdcBaseOwnership } from "../script/TransferCitreaUsdcBaseOwnership.s.sol";
import { AcceptCitreaUsdcBaseOwnership } from "../script/AcceptCitreaUsdcBaseOwnership.s.sol";
import { VerifyCitreaUsdcBasePostDeploy } from "../script/VerifyCitreaUsdcBasePostDeploy.s.sol";
import { HelixVault } from "../src/HelixVault.sol";
import { RiskEngine } from "../src/core/RiskEngine.sol";
import { VaultFactory } from "../src/core/VaultFactory.sol";
import { MockERC20 } from "../src/mocks/MockERC20.sol";

contract CitreaUsdcBaseScriptsTest is Test {
    uint256 internal constant CITREA_MAINNET_CHAIN_ID = 4114;
    address internal constant CITREA_USDCE = 0xE045e6c36cF77FAA2CfB54466D71A3aEF7bbE839;
    uint256 internal constant DEPLOYER_KEY = 0xA11CE;
    uint256 internal constant FINAL_OWNER_KEY = 0xB0B;
    address internal constant GUARDIAN = address(0xBEEF);

    function testBaseVaultScriptsRehearsalFlow() public {
        vm.chainId(CITREA_MAINNET_CHAIN_ID);

        address broadcaster = vm.addr(DEPLOYER_KEY);
        address finalOwner = vm.addr(FINAL_OWNER_KEY);
        MockERC20 usdce = new MockERC20("Citrea USDC.e", "USDC.e", 6);
        vm.etch(CITREA_USDCE, address(usdce).code);

        vm.setEnv("PRIVATE_KEY", vm.toString(DEPLOYER_KEY));
        vm.setEnv("RISK_ENGINE_OWNER", vm.toString(broadcaster));
        vm.setEnv("ORACLE_ROUTER_OWNER", vm.toString(broadcaster));
        vm.setEnv("VAULT_FACTORY_OWNER", vm.toString(broadcaster));
        vm.setEnv("DEPLOY_LENS", "true");

        DeployCitreaCore deployCore = new DeployCitreaCore();
        (RiskEngine riskEngine, , VaultFactory vaultFactory, ) =
            deployCore.run();

        assertTrue(address(riskEngine) != address(0));
        assertTrue(address(vaultFactory) != address(0));

        vm.setEnv("VAULT_FACTORY_ADDRESS", vm.toString(address(vaultFactory)));
        vm.setEnv("INITIAL_OWNER", vm.toString(broadcaster));
        vm.setEnv("GUARDIAN", vm.toString(GUARDIAN));

        DeployCitreaUsdcBase deployBase = new DeployCitreaUsdcBase();
        (HelixVault vault, RiskEngine baseRiskEngine) = deployBase.run();

        assertEq(address(baseRiskEngine), address(riskEngine));
        assertEq(vault.asset(), CITREA_USDCE);
        assertEq(vault.owner(), broadcaster);
        assertEq(vault.guardian(), GUARDIAN);
        assertEq(address(vault.strategy()), address(0));
        assertEq(riskEngine.getMaxAllocationBps(address(vault)), 0);
        assertFalse(riskEngine.isPaused(address(vault)));
        assertFalse(riskEngine.isWithdrawOnly(address(vault)));

        vm.setEnv("FINAL_OWNER", vm.toString(finalOwner));
        vm.setEnv("RISK_ENGINE_ADDRESS", vm.toString(address(riskEngine)));
        vm.setEnv("VAULT_ADDRESS", vm.toString(address(vault)));

        TransferCitreaUsdcBaseOwnership transfer = new TransferCitreaUsdcBaseOwnership();
        transfer.run();

        assertEq(vaultFactory.pendingOwner(), finalOwner);
        assertEq(riskEngine.pendingOwner(), finalOwner);
        assertEq(vault.pendingOwner(), finalOwner);

        vm.setEnv("PRIVATE_KEY", vm.toString(FINAL_OWNER_KEY));
        vm.setEnv("FINAL_OWNER", vm.toString(finalOwner));
        vm.setEnv("VAULT_FACTORY_ADDRESS", vm.toString(address(vaultFactory)));
        vm.setEnv("RISK_ENGINE_ADDRESS", vm.toString(address(riskEngine)));
        vm.setEnv("VAULT_ADDRESS", vm.toString(address(vault)));

        AcceptCitreaUsdcBaseOwnership accept = new AcceptCitreaUsdcBaseOwnership();
        accept.run();

        assertEq(vaultFactory.owner(), finalOwner);
        assertEq(riskEngine.owner(), finalOwner);
        assertEq(vault.owner(), finalOwner);
        assertEq(vaultFactory.pendingOwner(), address(0));
        assertEq(riskEngine.pendingOwner(), address(0));
        assertEq(vault.pendingOwner(), address(0));
        assertEq(address(vault.strategy()), address(0));
        assertEq(riskEngine.getMaxAllocationBps(address(vault)), 0);
        assertFalse(riskEngine.isPaused(address(vault)));
        assertFalse(riskEngine.isWithdrawOnly(address(vault)));

        VerifyCitreaUsdcBasePostDeploy verify = new VerifyCitreaUsdcBasePostDeploy();
        verify.run();
    }
}
