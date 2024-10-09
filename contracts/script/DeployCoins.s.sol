// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {GoldCoin, SilverCoin} from "../src/PreciousMetals.sol";

//download & install Frame wallet
//export POLYGON_KEY= ... get this from polygonscan.com
//forge script ./scripts/FreeGold.s.sol --rpc-url http://localhost:1248 --broadcast --chain-id 137 --verify --etherscan-api-key=${POLYGON_KEY} 
contract DeployCoins is Script {
    

    function setUp() public {}

    function run() public {
        vm.startBroadcast(); //fill in the PK here 

        new GoldCoin(0x1101184E85D4CAf7DE2357c66e4F052bbc552497, 0xd4f4baD1Fba15F8B136DBb9A44CE44caa3E92A5A);
        new SilverCoin(0x1101184E85D4CAf7DE2357c66e4F052bbc552497, 0xd4f4baD1Fba15F8B136DBb9A44CE44caa3E92A5A);

        vm.stopBroadcast();
    }
}
