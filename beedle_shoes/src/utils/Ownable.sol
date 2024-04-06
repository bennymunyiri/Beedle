// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

abstract contract Ownable {
    event OwnershipTransferred(address indexed user, address indexed newOwner);

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    constructor(address _owner) {
        owner = _owner;
        //qanswered what if the previous owner was not address 0 what happens -> it will run during deploy only
        emit OwnershipTransferred(address(0), _owner);
    }

    //qanswered why can  anyone can call this function and transfer ownership-> its called by onlyOwner
    function transferOwnership(address _owner) public virtual onlyOwner {
        owner = _owner;
        emit OwnershipTransferred(msg.sender, _owner);
    }
}
