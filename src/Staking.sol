// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "./interfaces/IERC20.sol";
import {Ownable} from "./utils/Ownable.sol";

interface FeeDistribution {
    function claim(address) external;
}

contract Staking is Ownable {
    /// @notice the balance of reward tokens
    uint256 public balance = 0;
    /// @notice the index of the last update
    uint256 public index = 0;

    /// @notice mapping of user indexes
    mapping(address => uint256) public supplyIndex;

    /// @notice mapping of user balances
    mapping(address => uint256) public balances;
    /// @notice mapping of user claimable rewards
    mapping(address => uint256) public claimable;

    /// @notice the staking token
    IERC20 public immutable TKN;
    /// @notice the reward token
    IERC20 public immutable WETH;

    constructor(address _token, address _weth) Ownable(msg.sender) {
        TKN = IERC20(_token);
        WETH = IERC20(_weth);
    }

    /// @notice deposit tokens to stake
    /// @param _amount the amount to deposit
    function deposit(uint _amount) external {
        //@audit should you not use safetransferfrom
        TKN.transferFrom(msg.sender, address(this), _amount);
        updateFor(msg.sender);
        balances[msg.sender] += _amount;
    }

    /// @notice withdraw tokens from stake
    /// @param _amount the amount to withdraw
    function withdraw(uint _amount) external {
        //@audit this does not check if owner is part of the protocol giving free money.
        updateFor(msg.sender);
        //q what if the user withdraws more money
        balances[msg.sender] -= _amount;
        TKN.transfer(msg.sender, _amount);
    }

    /// @notice claim rewards
    function claim() external {
        updateFor(msg.sender);
        //@audit should have used safeTranser
        //@audit reentrancy attack this does not follow CEI
        WETH.transfer(msg.sender, claimable[msg.sender]);
        claimable[msg.sender] = 0;
        balance = WETH.balanceOf(address(this));
    }

    /// @notice update the global index of earned rewards
    function update() public {
        uint256 totalSupply = TKN.balanceOf(address(this));
        //qanswered initially wont the totalsupply be zero ==> there will be no need to update if its zero
        if (totalSupply > 0) {
            uint256 _balance = WETH.balanceOf(address(this));
            if (_balance > balance) {
                uint256 _diff = _balance - balance;
                if (_diff > 0) {
                    uint256 _ratio = (_diff * 1e18) / totalSupply;
                    if (_ratio > 0) {
                        index = index + _ratio;
                        balance = _balance;
                    }
                }
            }
        }
    }

    /// @notice update the index for a user
    /// @param recipient the user to update
    function updateFor(address recipient) public {
        update();
        uint256 _supplied = balances[recipient];
        if (_supplied > 0) {
            //q will this alway return zero for new users
            uint256 _supplyIndex = supplyIndex[recipient];
            //@audit a user can use a flashloan to stake and recieve a big share since there is no time to check on the
            supplyIndex[recipient] = index;
            uint256 _delta = index - _supplyIndex;
            if (_delta > 0) {
                uint256 _share = (_supplied * _delta) / 1e18;
                claimable[recipient] += _share;
            }
        } else {
            supplyIndex[recipient] = index;
        }
    }
}
