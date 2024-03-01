// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {console2,console} from "forge-std/Test.sol";

import {BaseTest} from "./BaseTest.t.sol";
import {Soulmate} from "../../src/Soulmate.sol";

contract SoulmateTest is BaseTest {
    function test_MintNewToken() public {
        uint tokenIdMinted = 0;

        vm.prank(soulmate1);
        soulmateContract.mintSoulmateToken();

        assertTrue(soulmateContract.totalSupply() == 0);

        vm.prank(soulmate2);
        soulmateContract.mintSoulmateToken();

        assertTrue(soulmateContract.totalSupply() == 1);
        assertTrue(soulmateContract.soulmateOf(soulmate1) == soulmate2);
        assertTrue(soulmateContract.soulmateOf(soulmate2) == soulmate1);
        assertTrue(soulmateContract.ownerToId(soulmate1) == tokenIdMinted);
        assertTrue(soulmateContract.ownerToId(soulmate2) == tokenIdMinted);
    }

    function test_NoTransferPossible() public {
        _mintOneTokenForBothSoulmates();

        vm.prank(soulmate1);
        vm.expectRevert();
        soulmateContract.transferFrom(soulmate1, soulmate2, 0);
    }

    function compare(
        string memory str1,
        string memory str2
    ) public pure returns (bool) {
        return
            keccak256(abi.encodePacked(str1)) ==
            keccak256(abi.encodePacked(str2));
    }

    function test_WriteAndReadSharedSpace() public {
        vm.prank(soulmate1);
        soulmateContract.writeMessageInSharedSpace("Buy some eggs");

        vm.prank(soulmate2);
        string memory message = soulmateContract.readMessageInSharedSpace();

        string[4] memory possibleText = [
            "Buy some eggs, sweetheart",
            "Buy some eggs, darling",
            "Buy some eggs, my dear",
            "Buy some eggs, honey"
        ];
        bool found;
        for (uint i; i < possibleText.length; i++) {
            if (compare(possibleText[i], message)) {
                found = true;
                break;
            }
        }
        console2.log(message);
        assertTrue(found);
    }

    function test_getDivorced() public {
        //before divorced
        vm.startPrank(soulmate1);
        bool bresult = soulmateContract.isDivorced();
        assert(bresult == false);
        vm.stopPrank();
        // After Divorced
        bool result = _getDivorced();
        assert(result == true);


    }
    // Findings
    function test_AfterDivorcedNotAbleToGetReuinted() public{
        _mintOneTokenForBothSoulmates();


        // get divorced 
        vm.startPrank(soulmate1);
        soulmateContract.getDivorced();
        assert(soulmateContract.isDivorced()==true);
        vm.stopPrank();

        // After Divorced User Cannot reuinted Again
        vm.startPrank(soulmate1);
        vm.expectRevert();
        soulmateContract.mintSoulmateToken();
        vm.stopPrank();
        
    }


    function test_SameUserCanLoveMintToken() public {
        address user1 = makeAddr("user1");
     

        vm.startPrank(user1);
        soulmateContract.mintSoulmateToken();
        vm.stopPrank();

        vm.startPrank(user1);
        soulmateContract.mintSoulmateToken();
        vm.stopPrank();

        assertEq(soulmateContract.soulmateOf(user1), soulmateContract.soulmateOf(user1));

        // even can claim airdrops, deposit lovetoken also can claim loveTokens As Reward for staking

        vm.warp(block.timestamp + 7 days + 1 seconds);

        vm.startPrank(user1);
        airdropContract.claim();
        vm.stopPrank();

        assertEq(loveToken.balanceOf(user1), 7 ether);
        vm.startPrank(user1);
        loveToken.approve(address(stakingContract), 2 ether);
        stakingContract.deposit(2 ether);
        // I am doing the Below Line of Code Beacuse i Know the calimReward() has issues
        // for this this we don't need to wait for 1 week calimReward() will do that for us for its vunrabilty.
        stakingContract.claimRewards();
        stakingContract.withdraw(2 ether);
        vm.stopPrank();

        assertEq(loveToken.balanceOf(user1), 9 ether);





    }



    
}
