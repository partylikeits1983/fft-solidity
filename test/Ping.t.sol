// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/Ping.sol";

contract PingTest is Test {
	uint ethFork;
	string ETH_RPC = vm.envString("ETH_RPC");

	UNIdata data;

	function setUp() public {
		ethFork = vm.createSelectFork(ETH_RPC);
		data = new UNIdata();
	}

	function testPing() public {
		console.log("start test");
		data.getSeriesData();
	}
}
