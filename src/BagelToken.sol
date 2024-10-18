// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ERC20} from '@openzepplin/contracts/token/ERC20/ERC20.sol';
import {Ownable} from '@openzepplin/contracts/access/Ownable.sol';

contract BagelToken is ERC20, Ownable {
    constructor() ERC20('BagelToken', 'Bagel') Ownable() {}
    
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    } 
}