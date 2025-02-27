// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AlyraToken is ERC20, Ownable {
    constructor() ERC20("AlyraToken", "ALYRA") Ownable(msg.sender) {
        _mint(msg.sender, 10000000000000000000 * 10 ** 18);
    }
}
