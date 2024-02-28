// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import{Test1} from "../../src/Test1.sol";
import{Test2} from "../../src/Test2.sol";
import{Test} from "forge-std/Test.sol";
contract TestCon is Test{
    Test1 test1;
    Test2 test2;

    address user = makeAddr("User");



    function setUp() public{

        test1 = new Test1();
        test2 = new Test2(test1);
    }


    function testNonRegUserAlsoCanUpdateNumber() public  {

      

        vm.startPrank(user);

        test1.registerUser();

        assert(test1.isUser()== true);
    

        // change number

        test2.updateNumber();

        uint256 afterFirstChange =  test2.number();
        assert(afterFirstChange==1);

        test1.removUser();


        test2.updateNumber();

        uint256 afterFirstChange2 =  test2.number();
        assert(afterFirstChange2==1);

        vm.stopPrank();


    }
}

