

### [H-1] Users Can Claim `LoveTokens` from `Airdrop` Even After Divorce, Violating the Protocol Rule that Only Couples Can Claim LoveTokens.
**Description:** In the `Airdrop::claim()` function, divorced couples can still claim LoveTokens, contrary to the intended design. The issue arises from the following section of the `Airdrop::claim()` function:

```javascript
function claim() public {
        
@>        if (soulmateContract.isDivorced()) revert Airdrop__CoupleIsDivorced();
        ......
    }
```



The problem lies in the forwarded call to the `Soulmate `contract, where the caller `(msg.sender)` is the `Airdrop` contract itself. The `Soulmate::isDivorced()` function retrieves the value directly for the `msg.sender`. As the airdrop contract will not have a `Soulmate NFT` and will never get divorced, `if (soulmateContract.isDivorced())` will always be `false`. Consequently, even after divorce, users will be able to claim airdrop rewards.

Soulmate getDivorced() function

```javascript
  function isDivorced() public view returns (bool) {
@>        return divorced[msg.sender];
    }

```


**Impact:**Even after divorce, couples can receive `LoveTokens`.

**Proof of Concept:** Here is a proof of code how users can receive love token even after divorced.

<details>
<summary>
Poc for even after divorced user can calim rewards 
</summary>

```javascript

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
```
</details>

**Recommended Mitigation:** To address this issue, reorganize the check for divorce at the `Soulmate` contract by adding the following function:
```javascript

   function checkDivorced(address _caller) public view returns(bool){
        return divorced[_caller];
    }

```
Use the above function in the `Airdrop::claim()` function, passing `msg.sender` as a parameter:

```diff
function claim() public {
        
-      if (soulmateContract.isDivorced()) revert Airdrop__CoupleIsDivorced();
+      if (soulmateContract.checkDivorced(msg.sender)) revert Airdrop__CoupleIsDivorced();
        ......
    }

```
This modofications on both contract ensures protocol rule.


### [H-2] Users Can Claim Rewards Without Waiting for 1 Week from `Staking::claimRewards()`, Violating the Staking Rule and Rapidly Decreasing `LoveTokens` in `StakingVault`.

**Description:** Users can claim rewards before the required `1-week` duration from the `Staking `contract. Consider a scenario where two users mint a `Soulmate NFT token`. As per the protocol rule, each user can claim `1 LoveToken` per day from the `Airdrop`. If they or one of them refrains from claiming LoveTokens from the `Airdrop` for `7 days` and then attempts to claim their `LoveTokens` from the `Airdrop`, they will receive 7 tokens each from the `Airdrop Vault`, which is acceptable. However, if they deposit their LoveTokens for staking at the 'Staking' contract using `Staking::deposit(uint256 amount)`, the protocol breaks when they call `Staking::claimRewards` without waiting for the mandated `1-week duration`. The issue lies in the following section of the `Staking::claimRewards()` function:

```javascript

  if (lastClaim[msg.sender] == 0) {
@>            lastClaim[msg.sender] = soulmateContract.idToCreationTimestamp(
                soulmateId
            );
        }
```
The problem is that `lastClaim[msg.sender]` calculates the claiming time based on the creation of the `Soulmate NFT` using `soulmateContract.idToCreationTimestamp(soulmateId)`. This `timestamp` represents the time of `NFT creation`, not the time of depositing the token into the staking contract. Consequently, users do not need to wait 7 days after depositing their LoveTokens for staking before claiming rewards, which violates the staking and rewards claiming rule.

**Impact:** Viloates Staking And Rewards Claimig Rule.

**Proof of Concept:** The provided proof of code demonstrates how users can claim rewards without waiting for 1 week.

<details>
<summary>POC for Users Claiming Rewards Without Waiting For 1 Week</summary>

```javascript

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


```
</details>



**Recommended Mitigation:**  This issue can be mitigted by updating the both `Staking::deposit(uin256 amount)` and `Staking::claimrewards()` function

```diff
 if (loveToken.balanceOf(address(stakingVault)) == 0)
            revert Staking__NoMoreRewards();
        // No require needed because of overflow protection

+       lastClaim[msg.sender] = block.timestamp; solution to claimrewad before weeks and overfunding of rewads
        userStakes[msg.sender] += amount;
        loveToken.transferFrom(msg.sender, address(this), amount);

        emit Deposited(msg.sender, amount);
```

```diff

 function claimRewards() public {
        uint256 soulmateId = soulmateContract.ownerToId(msg.sender);
        // first claim
-        if (lastClaim[msg.sender] == 0) {
-            lastClaim[msg.sender] = soulmateContract.idToCreationTimestamp(
-                soulmateId
-            );
-        }

        // How many weeks passed since the last claim.
        // Thanks to round-down division, it will be the lower amount possible until a week has completly pass.
        uint256 timeInWeeksSinceLastClaim = ((block.timestamp -
            lastClaim[msg.sender]) / 1 weeks);

        if (timeInWeeksSinceLastClaim < 1)
            revert Staking__StakingPeriodTooShort();

        lastClaim[msg.sender] = block.timestamp;

        // Send the same amount of LoveToken as the week waited times the number of token staked
        uint256 amountToClaim = userStakes[msg.sender] *
            timeInWeeksSinceLastClaim;
        loveToken.transferFrom(
            address(stakingVault),
            msg.sender,
            amountToClaim
        );

        emit RewardsClaimed(msg.sender, amountToClaim);
    }
```

### [H-3] User Can Claim More Than Actual Reward From `Staking::claimRewards()` Contract Violating the Staking Rule and Rapidly Decreasing `LoveTokens` in `StakingVault`.



**Description:** `Staking` contract stands for staking `LoveToken` and in return it will give more `LoveToken`. As per doc if user has to deposit `LoveToken` to the staking and have to wait for 1 week to receive reward as `LoveToken`.
For staking 1 love token for 1 week user will recevie 1 `LoveToken` as reward. But this design pattern actually don't work in the `Staking::claimReward()` function. User can claim more token than protocol rule.   

**Impact:** Rapid decrease of `LoveToken` from `StakingVault`.

**Proof of Concept:** We can form below scerenio to proof that,
lets assume that a user mints a soulmate nft and after 7 days he claim his lovetoken from `Airdrop::claim()`. He  gets 7 `LoveTokens` from the airdroping. Now he has 7 `LoveToken`. And then he dposits 2 `LoveToken` to `Staking` contract
and using `Staking:deposit()`. After Depositing he has 5 `LoveToken`. He waits for 2 weeks to receive reward. 2 tokens staking for 2 weeks he sholud get back 4 tokens as reward. But the problem arises that he actually received 6 tokens as reward. this happend because   `lastClaim[msg.sender]` calculates the claiming time based on the creation of the `Soulmate NFT` using `soulmateContract.idToCreationTimestamp(soulmateId)`. This `timestamp` represents the time of `NFT creation`, not the time of depositing the token into the staking contract.
This the line from the `Staking::claimRewards()` whhic cause the issue
```javascript
  if (lastClaim[msg.sender] == 0) {
@>            lastClaim[msg.sender] = soulmateContract.idToCreationTimestamp(
                soulmateId
            );
        }

```  
So As he created `Soulmate NFT` 7 days back ago before staking the actual staking time is timebeforedeposit+timeafterdeposit = `7+14 = 21 /3 = 3 weeks` so 3 weeks with 2 tokens is equal to 6 token as reward. but as per doc the countdown should satrted from the time of depositing. this `lastClaim[msg.sender]` is placed wrongly in the `Staking::claimRewards()`.

<details>
<summary>
POC For More Reward Claiming Than Expected
</summary>

```javascript

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
            );""
            
            if now solumate withdraw his deposited token from staking contract 
            he get 13 token back but should be 11 token. `solmatebalanceAfterClaimimgRewardsAndWithDraw` this we can verify that

        } 
         */
        
    }

```
</details>

**Recommended Mitigation:** This can be mitigated by updating the both `Staking::deposit(amount)` and `Staking::claimRewards()` function

Update The `Staking::deposit(amount)`

```diff
  function deposit(uint256 amount) public {
        if (loveToken.balanceOf(address(stakingVault)) == 0)
            revert Staking__NoMoreRewards();
        // No require needed because of overflow protection

+       lastClaim[msg.sender] = block.timestamp;
        userStakes[msg.sender] += amount;
        loveToken.transferFrom(msg.sender, address(this), amount);

        emit Deposited(msg.sender, amount);
    }
```
Also Update `Staking::claimRewards()`

```diff
    function claimRewards() public {
        uint256 soulmateId = soulmateContract.ownerToId(msg.sender);
        // first claim
-        if (lastClaim[msg.sender] == 0) {
-            lastClaim[msg.sender] = soulmateContract.idToCreationTimestamp(
-                soulmateId
-            );
-        }

        // How many weeks passed since the last claim.
        // Thanks to round-down division, it will be the lower amount possible until a week has completly pass.
        uint256 timeInWeeksSinceLastClaim = ((block.timestamp -
            lastClaim[msg.sender]) / 1 weeks);

        if (timeInWeeksSinceLastClaim < 1)
            revert Staking__StakingPeriodTooShort();

        lastClaim[msg.sender] = block.timestamp;

        // Send the same amount of LoveToken as the week waited times the number of token staked
        uint256 amountToClaim = userStakes[msg.sender] *
            timeInWeeksSinceLastClaim;
        loveToken.transferFrom(
            address(stakingVault),
            msg.sender,
            amountToClaim
        );

```

### [H-4] `Soulmate::mintSoulmateToken()` Accepts Same Address For Minting Soulmate NFT, A Sinlge Person With A Single Address Can Mint Soulmate NFT Which Allows Him To Use All The Privilege Of The Protocol.

**Description:** `Soulmate::mintSoulmateToken()` does not checks for same user to match for soulmate. Same user can be soulmate to himself and it allows him to claim `LoveToken` From `Airdrop` Also he can deposit to `Staking` contract and 
able to receive `LoveToken` as reward for staking tokens.

**Impact:** A malicious actor can create multiple wallet address and using a single address for twice can mint soulmate. using each address calling twice `Soulmate::mintSoulmateToken()` can mint soulmate for all the addresses. Start claiming airdrops and rewards and in the end of the day real couple may not get airdop lovetoken because airdrop token was limited.

**Proof of Concept:** Proof Code is given below for the issue.

<details>
<summary>
POC For Same User Minting
</summary>

```javascript

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

```
</details>

**Recommended Mitigation:** The isssue can be mitigated by adding a chkes before assinging  solumate by updating 
`Soulmate::mintSoulmateToken()`  function.

```diff
   function mintSoulmateToken() public returns (uint256) {
        // Check if people already have a soulmate, which means already have a token
        address soulmate = soulmateOf[msg.sender];
        if (soulmate != address(0))
            revert Soulmate__alreadyHaveASoulmate(soulmate);

        address soulmate1 = idToOwners[nextID][0];
        address soulmate2 = idToOwners[nextID][1];
        if (soulmate1 == address(0)) {
            idToOwners[nextID][0] = msg.sender;
            ownerToId[msg.sender] = nextID;
            emit SoulmateIsWaiting(msg.sender);
        } else if (soulmate2 == address(0)) {

            idToOwners[nextID][1] = msg.sender;
+           if(idToOwners[nextID][0] == idToOwners[nextID][1]){
+               revert("Same user");
+            };
            // Once 2 soulmates are reunited, the token is minted
            ownerToId[msg.sender] = nextID;
            soulmateOf[msg.sender] = soulmate1;
            soulmateOf[soulmate1] = msg.sender;
            idToCreationTimestamp[nextID] = block.timestamp;

            emit SoulmateAreReunited(soulmate1, soulmate2, nextID);

            _mint(msg.sender, nextID++);
        }

        return ownerToId[msg.sender];
    }

```




### [M-1] `StakingVault` Can Be Out Of `LoveToken` Refusing The Users To Claim Rewards.

**Description:** Users are allowed to claim rewrds for staking their `LoveToken`. Those rewards tokens are hold by the 

`StakingVault` contract and reward are transfered from the `StakingVault` contract. The issue start from that the `StakingVault` contract hold a specific amount of `LoveToken`. We Can see that from the `LoveToken::iniiVault()`. 

```javascript
    // Consoder Folloing Changes to the Below For Proving The Concept OtherWise Test Will faill
    function initVault(address managerContract) public {
        if (msg.sender == airdropVault) {
            _mint(airdropVault, 100 ether);
            approve(managerContract, 100 ether);
            emit AirdropInitialized(managerContract);
        } else if (msg.sender == stakingVault) {
         
@>          _mint(stakingVault, 500_000_000 ether);
            approve(managerContract, 500_000_000 ether);
            emit StakingInitialized(managerContract);
        } else revert LoveToken__Unauthorized();
    }

    // And In both ./test/unit/AirDropTest.t.sol; and in ./test/unit/StakingTest.t.sol otherWise This Will fail.

    function test_WellInitialized() public {
        assertTrue(
            loveToken.allowance(
                address(stakingVault),
                address(stakingContract)
            ) == 100 ether
        );

     function test_WellInitialized() public {
        assertTrue(
            loveToken.allowance(
                address(airdropVault),
                address(airdropVault)
            ) == 100 ether
        );
    
    
```
It is clear that `Staking` contracts mints `5000000000` tokens. Which is limited amount and it can ended one day. After it become zero it will be unable to send reward token to the user which will be potential time loss for the users. 

**Impact:** Users will be unable to receive rewards and it will also be a time loss for the users to stake their token for nothing.

**Proof of Concept:** Below a Proof of code is given with the minting of 100 token to `StakingValut` 

```javascript
// changed initValut function from the LoveToken.sol for proving

    function initVault(address managerContract) public {
        if (msg.sender == airdropVault) {
            _mint(airdropVault, 500_000_000 ether);
            approve(managerContract, 500_000_000 ether);
            emit AirdropInitialized(managerContract);
        } else if (msg.sender == stakingVault) {
         
@>          _mint(stakingVault, 100 ether);
            approve(managerContract, 500_000_000 ether);
            emit StakingInitialized(managerContract);
        } else revert LoveToken__Unauthorized();
    }

```

<details>
<summary>
POC for `StakingVault` Out Fund
</summary>

```javascript

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
        vm.expectRevert(stdError.arithmeticError);
        stakingContract.claimRewards();
        vm.stopPrank();
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

    }

```
</details>



**Recommended Mitigation:** There are few steps can be taken to mitigate this issue

1. Ensuring Continous Supply Of `LoveToken` To The `StakingVault`.
2. Use A Checks Before Transfering Rewards To The From `Staking::claimRewards()` By adding The Below Lines Of Code

```diff
 function claimRewards() public {
    rest of the code
    ....

+   if(loveToken.balanceOf(address(stakingVault)) == 0){
+                revert Staking__NoMoreRewards();
+       }

        loveToken.transferFrom(
            address(stakingVault),
            msg.sender,
            amountToClaim
        );

        emit RewardsClaimed(msg.sender, amountToClaim);
    }
```


