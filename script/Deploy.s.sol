// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Deployer } from "./Deployer.sol";
import { DeployConfig } from "./DeployConfig.s.sol";
import { console2 } from "lib/forge-std/src/console2.sol";

import { IERC20 as ERC20 } from "../src/interfaces/IERC20.sol";
import { HydraERC20 } from "../src/HydraERC20.sol";
import { PRHydraERC20 } from "../src/PRHydraERC20.sol";
import { HydraTreasury } from "../src/Treasury.sol";
import { MockERC20 } from "../src/mocks/MockERC20.sol";
import { Minting } from "../src/Minting.sol";

contract Deploy is Deployer {
    HydraERC20 internal hydr;
    PRHydraERC20 internal prhydr;
    HydraTreasury internal treasury;
    MockERC20 internal dai;
    MockERC20 internal usdc;
    Minting internal minting;

    function name() public pure override returns (string memory name_) {
        name_ = "Deploy";
    }

    function setUp() public override {
        super.setUp();
        console2.log("Starting to deploy with address:", address(this));
    }

    function run() external {
        deployHydraToken();
        deployPRHydraERC20();
        deployTreasury();
        deployMockTokens();
        whitelistMockTokens();
        deployMinting();

        console2.log("Deployment completed!");
    }

    function deployHydraToken() internal returns (address) {
        hydr = new HydraERC20();
        console2.log("HYDR_ADDRESS:", address(hydr));
        save("HYDR_ADDRESS", address(hydr));
        return address(hydr);
    }

    function deployPRHydraERC20() internal returns (address) {
        prhydr = new PRHydraERC20();
        console2.log("PRHYDR_ADDRESS:", address(prhydr));
        save("PRHYDR_ADDRESS", address(prhydr));
        return address(prhydr);
    }

    function deployTreasury() internal returns (address) {
        treasury = new HydraTreasury(address(this), address(hydr));
        console2.log("HYDRA_TREASURY_ADDRESS:", address(treasury));
        save("HYDRA_TREASURY_ADDRESS", address(treasury));
        return address(treasury);
    }

    function deployMockTokens() internal {
        dai = new MockERC20("DAI Stablecoin", "DAI");
        usdc = new MockERC20("USDC Stablecoin", "USDC");

        dai.mint(address(this), 1e24); // Mint 1,000,000 DAI
        usdc.mint(address(this), 1e24); // Mint 1,000,000 USDC

        console2.log("DAI_ADDRESS:", address(dai));
        console2.log("USDC_ADDRESS:", address(usdc));
        save("DAI_ADDRESS", address(dai));
        save("USDC_ADDRESS", address(usdc));
    }

    function whitelistMockTokens() internal {
        treasury.addCoinToWhitelist(address(dai));
        treasury.addCoinToWhitelist(address(usdc));
    }

    function deployMinting() internal returns (address) {
        minting = new Minting(address(treasury), address(prhydr));
        console2.log("HYDRA_MINTING_ADDRESS:", address(minting));
        save("HYDRA_MINTING_ADDRESS", address(minting));
        return address(minting);
    }
}
