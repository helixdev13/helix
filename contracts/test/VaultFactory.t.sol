// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { HelixVault } from "../src/HelixVault.sol";
import { RiskEngine } from "../src/core/RiskEngine.sol";
import { OracleRouter } from "../src/core/OracleRouter.sol";
import { VaultFactory } from "../src/core/VaultFactory.sol";
import { HelixLens } from "../src/periphery/HelixLens.sol";
import { MockERC20 } from "../src/mocks/MockERC20.sol";
import { MockOracle } from "../src/mocks/MockOracle.sol";

contract VaultFactoryTest is Test {
    address internal constant GUARDIAN = address(0xBEEF);
    address internal constant OTHER = address(0xB0B);

    MockERC20 internal asset;
    RiskEngine internal riskEngine;
    OracleRouter internal oracleRouter;
    VaultFactory internal factory;
    HelixLens internal lens;

    function setUp() public {
        asset = new MockERC20("Mock Asset", "MA", 18);
        riskEngine = new RiskEngine(address(this));
        oracleRouter = new OracleRouter(address(this));
        oracleRouter.setOracle(address(asset), address(new MockOracle(address(this), 1e18)), 1 days);
        factory = new VaultFactory(riskEngine, address(this));
        lens = new HelixLens();
    }

    function testCreateVaultRecordsDeployment() public {
        HelixVault vault = factory.createVault(asset, address(this), GUARDIAN, "Helix Vault", "HLX");

        assertEq(address(vault.RISK_ENGINE()), address(riskEngine));
        assertEq(vault.owner(), address(this));
        assertEq(vault.guardian(), GUARDIAN);
        assertTrue(factory.isVaultFromFactory(address(vault)));
        assertEq(factory.totalVaults(), 1);
        assertEq(factory.vaultAt(0), address(vault));
        assertEq(factory.allVaults().length, 1);
    }

    function testLensReadsFactoryVault() public {
        HelixVault vault = factory.createVault(asset, address(this), GUARDIAN, "Helix Vault", "HLX");
        riskEngine.setConfig(address(vault), 1000e18, 8000, false, false);

        HelixLens.VaultView memory view_ = lens.getVaultView(vault);
        assertEq(view_.vault, address(vault));
        assertEq(view_.asset, address(asset));
        assertEq(view_.guardian, GUARDIAN);
        assertEq(view_.riskEngine, address(riskEngine));
        assertEq(view_.depositCap, 1000e18);
        assertEq(view_.maxAllocationBps, 8000);
        assertEq(view_.totalAssets, 0);
        assertEq(view_.totalIdle, 0);
        assertEq(view_.totalStrategyAssets, 0);
    }

    function testOnlyOwnerCanCreateVault() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, OTHER));
        vm.prank(OTHER);
        factory.createVault(asset, OTHER, address(0), "Other Vault", "OHVX");
    }
}
