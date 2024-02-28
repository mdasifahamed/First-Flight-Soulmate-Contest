// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {BaseTest} from "./BaseTest.t.sol";
import{console} from "forge-std/Test.sol";

contract AirdropTest is BaseTest {
    function test_WellInitialized() public {
        assertTrue(
            loveToken.allowance(
                address(airdropVault),
                address(airdropContract)
            ) == 100 ether
        );
    }

    function test_Claim() public {
        _mintOneTokenForBothSoulmates();

        // Not enough day in relationship
        vm.prank(soulmate1);
        vm.expectRevert();
        airdropContract.claim();

        vm.warp(block.timestamp + 200 days + 1 seconds);

        vm.prank(soulmate1);
        airdropContract.claim();

        assertTrue(loveToken.balanceOf(soulmate1) == 200 ether);

        vm.prank(soulmate2);
        airdropContract.claim();

        assertTrue(loveToken.balanceOf(soulmate2) == 200 ether);
    }

    function test_CanClaimAfterDivorced() public {
        _mintOneTokenForBothSoulmates();

        // claim BeforeDivorce
        vm.startPrank(soulmate1);
        bool bresult = soulmateContract.isDivorced();
        assert(bresult == false);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days + 1 seconds);

        vm.prank(soulmate1);
        airdropContract.claim();
        vm.stopPrank();

        vm.prank(soulmate2);
        airdropContract.claim();
        vm.stopPrank();

        vm.prank(soulmate1);
        assertTrue(loveToken.balanceOf(soulmate2) == 1 ether);
        vm.stopPrank();

        vm.prank(soulmate2);
        assertTrue(loveToken.balanceOf(soulmate2) == 1 ether);
        vm.stopPrank();

        //get divorced now
  

        // divorced result
        vm.startPrank(soulmate1);
        soulmateContract.getDivorced();
        bool result = soulmateContract.isDivorced();
        assert(result == true);
        vm.stopPrank();


        vm.warp(block.timestamp + 2 days + 1 seconds);
        // claim after divorced
        vm.prank(soulmate1);
        airdropContract.claim();
        vm.stopPrank();

        vm.prank(soulmate2);
        airdropContract.claim();
        vm.stopPrank();


        vm.prank(soulmate1);
        assertTrue(loveToken.balanceOf(soulmate2) == 3 ether);
        vm.stopPrank();

        vm.prank(soulmate2);
        assertTrue(loveToken.balanceOf(soulmate2) == 3 ether);
        vm.stopPrank();

        console.log(loveToken.balanceOf(address(airdropVault)));
      
    }

    function test_CannotClaimAfterDivorced() public{
        _mintOneTokenForBothSoulmates();
        vm.startPrank(soulmate1);
        bool bresult = soulmateContract.isDivorced();
        assert(bresult == false);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days + 1 seconds);

        vm.prank(soulmate1);
        airdropContract.claim();
        vm.stopPrank();

        vm.prank(soulmate2);
        airdropContract.claim();
        vm.stopPrank();

        vm.prank(soulmate1);
        assertTrue(loveToken.balanceOf(soulmate2) == 1 ether);
        vm.stopPrank();

        vm.prank(soulmate2);
        assertTrue(loveToken.balanceOf(soulmate2) == 1 ether);
        vm.stopPrank();

        //get divorced now
  

        // divorced result
        vm.startPrank(soulmate1);
        soulmateContract.getDivorced();
        bool result = soulmateContract.isDivorced();
        assert(result == true);
        vm.stopPrank();

        vm.warp(block.timestamp + 2 days + 1 seconds);
        // Now Cna;t Claim After divorced
        vm.prank(soulmate1);
        vm.expectRevert();
        airdropContract.claim();
        vm.stopPrank();


    }
 

}
