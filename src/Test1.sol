// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract Test1{
    mapping (address user =>  bool isUser ) public userReg;


    function registerUser() public {
        userReg[msg.sender] = true;
    }

    function removUser() public {
        userReg[msg.sender] = false;
    }

    function isUser() public view returns(bool){
        return userReg[msg.sender];
    }
}