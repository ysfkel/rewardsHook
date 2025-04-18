// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RewardToken is ERC20("test", "test") {
    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}
