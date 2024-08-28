// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Script } from "lib/forge-std/src/Script.sol";
import { console2 } from "lib/forge-std/src/console2.sol";

contract DeployConfig is Script {
    uint256 public chainID = 11_155_111;
    address public deployer = vm.envOr({ name: "DEPLOYER", defaultValue: address(0) });
    address public proxyAdminOwner = vm.envOr({ name: "PROXY_ADMIN", defaultValue: address(0) });
    address public teamAddress = vm.envOr({ name: "TEAM_ADDRESS", defaultValue: address(0) });
    address public feeAddress = vm.envOr({ name: "FEE_ADDRESS", defaultValue: address(0) });

    constructor() { }
}
