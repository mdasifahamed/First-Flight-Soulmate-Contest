// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {BaseTest} from "./BaseTest.t.sol";
import {console2,console} from "forge-std/Test.sol";
import{stdError} from "forge-std/StdError.sol";

contract StakingTest is BaseTest {

    address soulmate3 = makeAddr("new Soulmate");
    address soulmate4 = makeAddr("new Soulmate2");
    function test_WellInitialized() public {
        assertTrue(
            loveToken.allowance(
                address(stakingVault),
                address(stakingContract)
            ) == 50000000000 ether
        );
    }

    function test_Deposit() public {
        uint balance = 100 ether;
        _giveLoveTokenToSoulmates(balance);
        vm.startPrank(soulmate1);
        loveToken.approve(address(stakingContract), balance);
        stakingContract.deposit(balance);
        vm.stopPrank();

        assertTrue(stakingContract.userStakes(soulmate1) == balance);

        vm.startPrank(soulmate2);
        loveToken.approve(address(stakingContract), balance);
        stakingContract.deposit(balance);
        vm.stopPrank();

        assertTrue(stakingContract.userStakes(soulmate2) == balance);

        assertTrue(
            loveToken.balanceOf(address(stakingContract)) == balance * 2
        );
    }

    function test_Withdraw() public {
        uint balancePerSoulmates = 50 ether;
        _depositTokenToStake(balancePerSoulmates);

        // Withdraw twice to get back all the tokens
        vm.prank(soulmate1);
        stakingContract.withdraw(balancePerSoulmates / 2);
        assertTrue(
            loveToken.balanceOf(address(stakingContract)) ==
                balancePerSoulmates * 2 - (balancePerSoulmates / 2)
        );
        assertTrue(loveToken.balanceOf(soulmate1) == balancePerSoulmates / 2);

        vm.prank(soulmate1);
        stakingContract.withdraw(balancePerSoulmates / 2);
        assertTrue(
            loveToken.balanceOf(address(stakingContract)) == balancePerSoulmates
        );
        assertTrue(loveToken.balanceOf(soulmate1) == balancePerSoulmates);

        console.log(loveToken.balanceOf(address(stakingContract)));
        console.log(loveToken.balanceOf(address(stakingVault)));

    }

    function test_ClaimRewards() public {
        uint balancePerSoulmates = 5 ether;
        uint weekOfStaking = 5;
        _depositTokenToStake(balancePerSoulmates);

        vm.prank(soulmate1);
        vm.expectRevert();
        stakingContract.claimRewards();

        vm.warp(block.timestamp + weekOfStaking * 1 weeks + 1 seconds);

        vm.prank(soulmate1);
        stakingContract.claimRewards();

        assertTrue(
            loveToken.balanceOf(soulmate1) ==
                weekOfStaking * balancePerSoulmates
        );

        vm.prank(soulmate1);
        stakingContract.withdraw(balancePerSoulmates);
        assertTrue(
            loveToken.balanceOf(soulmate1) ==
                weekOfStaking * balancePerSoulmates + balancePerSoulmates
        );

        console.log(loveToken.balanceOf(address(stakingContract)));
        console.log(loveToken.balanceOf(address(stakingVault)));
    }


    function setupForOutOfFund() internal  {
    
        _mintOneTokenForBothSoulmates();

        vm.startPrank(soulmate3);
        soulmateContract.mintSoulmateToken();
        vm.stopPrank();

        vm.startPrank(soulmate4);
        soulmateContract.mintSoulmateToken();
        vm.stopPrank();

        // Claim Airdrops Bot Both Couples After 25 days
        
        vm.warp(block.timestamp + 25 days + 1 seconds );

        vm.startPrank(soulmate1); 
        airdropContract.claim();
        vm.stopPrank();

        vm.startPrank(soulmate2); 
        airdropContract.claim();
        vm.stopPrank();

        vm.startPrank(soulmate3); 
        airdropContract.claim();
        vm.stopPrank();

        vm.startPrank(soulmate4); 
        airdropContract.claim();
        vm.stopPrank();

        // Checks 


        assertEq(loveToken.balanceOf(soulmate1),25 ether);
        assertEq(loveToken.balanceOf(soulmate2),25 ether);
        assertEq(loveToken.balanceOf(soulmate3),25 ether);
        assertEq(loveToken.balanceOf(soulmate4),25 ether);

        
        // toekn deposits
        uint256 amountToDeposit = 25  ether;
        vm.startPrank(soulmate1); 
        loveToken.approve(address(stakingContract), amountToDeposit);
        stakingContract.deposit(amountToDeposit);
        vm.stopPrank();

        vm.startPrank(soulmate2);
        loveToken.approve(address(stakingContract), amountToDeposit);
        stakingContract.deposit(amountToDeposit);
        vm.stopPrank();

        vm.startPrank(soulmate3);
        loveToken.approve(address(stakingContract), amountToDeposit);
        stakingContract.deposit(amountToDeposit);
        vm.stopPrank();

        vm.startPrank(soulmate4);
        loveToken.approve(address(stakingContract), amountToDeposit);
        stakingContract.deposit(amountToDeposit);
        vm.stopPrank();

        /**
            One of the soulmate come to claim reward after 50 weeks
            and other two comes after after 25 weeks
            and last one comes after 26 weeks las one will able unable to claim rewards
        */

        // 50 weeks after claiming reward

    }

    function test_outOfFund() public {
        setupForOutOfFund();
        uint256 stakingContractBlanceBeforeCalim = loveToken.balanceOf(address(stakingVault));
        vm.warp(block.timestamp + 1 weeks + 1 seconds);

        /**
           here actual time is 25 days + 1 weeks = 32 days 
           whick means 32/7 ~= 4 weeks beacuse fault in `Stakking::claimReward()` which calulates wrong timestamp.
           25 *4 = 100 tokens
         */
        vm.startPrank(soulmate1);
        stakingContract.claimRewards();
        vm.stopPrank();
        uint256 stakingContractBlanceAfterCalim = loveToken.balanceOf(address(stakingVault));
        console.log(stakingContractBlanceBeforeCalim);
        console.log(stakingContractBlanceAfterCalim);
        assert(stakingContractBlanceAfterCalim == 0);

        // Now if Other stakers tries to claimreward he can't
        // Staking vault Does Not have Any Token Others Can't Withdra Token Now 

        vm.warp(block.timestamp + 1 weeks + 1 seconds);
        vm.startPrank(soulmate2);
        // vm.expectRevert(stdError.arithmeticError);
        vm.expectRevert();
        stakingContract.claimRewards();
        vm.stopPrank();
    }


    function test_UserIsUnAbleToWithdrawEvenHisOwnFund() public {
        setupForOutOfFund();
        uint256 stakingContractBlanceBeforeCalim = loveToken.balanceOf(address(stakingVault));
        vm.warp(block.timestamp + 1 weeks + 1 seconds);
        vm.startPrank(soulmate1);
        stakingContract.claimRewards();
        vm.stopPrank();
        uint256 stakingContractBlanceAfterCalim = loveToken.balanceOf(address(stakingVault));
        console.log(stakingContractBlanceBeforeCalim);
        console.log(stakingContractBlanceAfterCalim);
        assert(stakingContractBlanceAfterCalim == 0);

        // Now if Other stakers tries to claimreward he can't
        // Staking vault Does Not have Any Token Others Can't Withdra Token Now 

        vm.warp(block.timestamp + 1 weeks + 1 seconds);
        vm.startPrank(soulmate2);
        vm.expectRevert(stdError.arithmeticError);
        stakingContract.claimRewards();
        vm.stopPrank();
        /** As User failed  Claim Reward he Migh think To Withdraw Bcak his Balance As 
            But It fail Fail beacuse `withdraw()` function transfer token from
            `stakingVault` contract which is now empty. so it will also fails 
            and user fund will be frezze.
         */
        vm.startPrank(soulmate2);
        uint256 amountToWithdraw = 25 ether;
        // vm.expectRevert(stdError.arithmeticError);
        stakingContract.withdraw(amountToWithdraw);
        console.log(loveToken.balanceOf(address(stakingContract)));
        vm.stopPrank();
     
    }

    // uses of fixed minting is harmfull

    // Without waiitng 1 week one claim reward

    function test_withoutwaiting1WeekClaiMreward() public {
       _withdraw7TokenAfterDays();

        uint256 amountToDeposit = loveToken.balanceOf(soulmate1);
        console.log(amountToDeposit);
        uint256 balanceOfStakinVaultBefore = loveToken.balanceOf(address(stakingVault));
        vm.startPrank(soulmate1);
        loveToken.approve(address(stakingContract), amountToDeposit);
        stakingContract.deposit(amountToDeposit);
        vm.stopPrank();

        vm.startPrank(soulmate1);
        stakingContract.claimRewards();
        vm.stopPrank();

        uint256 balanceOfStakinVaultAfter = loveToken.balanceOf(address(stakingVault));

        assert(balanceOfStakinVaultAfter == balanceOfStakinVaultBefore - amountToDeposit);

    }

    // helper function
    function _withdraw7TokenAfterDays() internal{
        _mintOneTokenForBothSoulmates();
        
        vm.warp(block.timestamp + 7 days +1 seconds);
        
        vm.startPrank(soulmate1);
        airdropContract.claim();
        vm.stopPrank();

        vm.startPrank(soulmate2);
        airdropContract.claim();
        vm.stopPrank();
    }


    function test_UserCanClaimMoreThanExpected() public {
        _mintOneTokenForBothSoulmates();

        vm.warp(block.timestamp + 7 days +1 seconds);

        vm.startPrank(soulmate1);
        airdropContract.claim();
        vm.stopPrank();

        assert(loveToken.balanceOf(soulmate1) == 7 ether);

        // as per doc if now solmate deposit 2 token for 
        // 2 weeks he should get 4 tokens as reward
        // but he wiil get 6 tokens 
        uint256 amountToDeposit = 2 ether;
        vm.startPrank(soulmate1);
        loveToken.approve(address(stakingContract), amountToDeposit);
        stakingContract.deposit(amountToDeposit);
        vm.stopPrank();

        uint256 afterDepositSoulmateTokenBalance = loveToken.balanceOf(soulmate1);

        assert(afterDepositSoulmateTokenBalance == 5 ether);

        console.log(afterDepositSoulmateTokenBalance);

        // Let Wait 2 Weeks
        vm.warp(block.timestamp + 2 weeks +1 seconds);
        vm.startPrank(soulmate1);
        stakingContract.claimRewards();
        vm.stopPrank();

        // as per doc now soulmate should have 9 tokens
        // but It will not it will have 11 ether

        assert( loveToken.balanceOf(soulmate1) != 9 ether); 

 
       
        uint256 solmatebalanceAfterClaimimgRewards = loveToken.balanceOf(soulmate1);

        //  the Soulmate1 token balance sholud be 11 
        assert(solmatebalanceAfterClaimimgRewards == 11 ether);

        console.log(solmatebalanceAfterClaimimgRewards);

        vm.startPrank(soulmate1);
        stakingContract.withdraw(amountToDeposit);
        vm.stopPrank();

        // withdraw soulmate1 shoul have 11 token
        // but it has 13 tokens

        assert(loveToken.balanceOf(soulmate1) != 11 ether);

        uint256 solmatebalanceAfterClaimimgRewardsAndWithDraw = loveToken.balanceOf(soulmate1);

        // it Has Now 13 Token

        assert(solmatebalanceAfterClaimimgRewardsAndWithDraw == 13 ether);


        console.log(solmatebalanceAfterClaimimgRewardsAndWithDraw);


        /** 
            Soulmate had 7 tokens from his claim from airdropContract
            he has deposited 2 tokens at the stakingContract
            now he has 7-2 = 5 tokens
            as per doc for stakin 2 tokens for 2 weeks he should get
            a reward of 2 tokens as reward includng his staking he should get back 
            2(reward) + 2(staking) = 4 tokens and then adding his left 5 token the total
            would be 4+5 = 9 token but from  `solmatebalanceAfterClaimimgRewards` we see that
            he gets 11 token back that his no deposited token was 5 so as reward he gets 6 tokens

            This Happended because of  
            ""if (lastClaim[msg.sender] == 0) {
            lastClaim[msg.sender] = soulmateContract.idToCreationTimestamp(
                soulmateId
            );"" this code block calculates lastClaim Time The creation of NFT token

            which does not match with stakingContract Doc For Claiming reward
            
            if now solumate withdraw his deposited token from staking contract 
            he get 13 token back but should be 11 token. `solmatebalanceAfterClaimimgRewardsAndWithDraw` this we can verify that

        } 
         */
        
    }

 

}
