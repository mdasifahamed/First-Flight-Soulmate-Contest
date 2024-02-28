// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import{Test1} from "./Test1.sol";
contract Test2 {    

    uint256 public number;

    Test1 test1;

    constructor(Test1 _test){
        test1 =_test;
    }


    function updateNumber() public{
        if(test1.isUser()){
            number=1;
        }
        else{
           number++;
        }

    }

}