// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Deployer } from "./Deployer.sol";
import { DeployConfig } from "./DeployConfig.s.sol";
import { console2 } from "lib/forge-std/src/console2.sol";

import { IMockERC20 } from "../src/interfaces/IMockERC20.sol";
import { HydraERC20 } from "../src/HydraERC20.sol";
import { PRHydraERC20 } from "../src/PRHydraERC20.sol";
import { HydraTreasury } from "../src/Treasury.sol";
import { MockERC20 } from "../src/mocks/MockERC20.sol";
import { Minting } from "../src/Minting.sol";

contract Deploy is Deployer {
    HydraERC20 public hydr;
    PRHydraERC20 public prhydr;
    HydraTreasury public treasury;
    MockERC20 public dai;
    MockERC20 public usdc;
    Minting public minting;

    address public deployer = address(0xd7c8ab7ED67F2986517635B615B0A526D8dda06f);
    address public user1 = address(0x678e0E67555E8fC4533c1a9f204e2C1C7C1C9665);

    function name() public pure override returns (string memory name_) {
        name_ = "Deploy";
    }

    function setUp() public override {
        super.setUp();
        console2.log("Starting to deploy with address:", user1);
    }

    function run() external {
        deployHydraToken();
        deployPRHydraERC20();
        deployTreasury();
        deployMockTokens();
        whitelistMockTokens();
        deployMinting();
        mintHydra();

        console2.log("Deployment completed!");
    }

    function deployHydraToken() public broadcast returns (address) {
        hydr = new HydraERC20();
        console2.log("HYDR_ADDRESS:", address(hydr));
        save("HYDR_ADDRESS", address(hydr));
        return address(hydr);
    }

    function deployPRHydraERC20() public broadcast returns (address) {
        prhydr = new PRHydraERC20();
        console2.log("PRHYDR_ADDRESS:", address(prhydr));
        save("PRHYDR_ADDRESS", address(prhydr));
        return address(prhydr);
    }

    function deployTreasury() public broadcast returns (address) {
        treasury = new HydraTreasury(address(deployer), address(hydr));
        console2.log("HYDRA_TREASURY_ADDRESS:", address(treasury));
        save("HYDRA_TREASURY_ADDRESS", address(treasury));
        return address(treasury);
    }

    function deployMockTokens() public broadcast {
        dai = new MockERC20("DAI Stablecoin", "DAI");
        usdc = new MockERC20("USDC Stablecoin", "USDC");

        dai.mint(user1, 1e24); // Mint 1,000,000 DAI
        usdc.mint(user1, 1e24); // Mint 1,000,000 USDC

        console2.log("DAI_ADDRESS:", address(dai));
        console2.log("USDC_ADDRESS:", address(usdc));
        save("DAI_ADDRESS", address(dai));
        save("USDC_ADDRESS", address(usdc));
    }

    function whitelistMockTokens() public broadcast {
        treasury.addCoinToWhitelist(address(dai));
        treasury.addCoinToWhitelist(address(usdc));

        console2.log("successfully add whitelist");
    }

    function deployMinting() public broadcast returns (address) {
        minting = new Minting(address(treasury), address(prhydr));
        console2.log("HYDRA_MINTING_ADDRESS:", address(minting));
        save("HYDRA_MINTING_ADDRESS", address(minting));
        return address(minting);
    }

    function mintHydra() public broadcast returns (address) {
        // mint dai to user1
        dai.mint(user1, 10 ether);

        minting.mintHYDR(1, address(dai), 1 ether, user1);
        console2.log("successfully minted hydr");
    }
}
