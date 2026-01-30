// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockStakingToken
 * @dev Simple ERC20 token for testing the BSV system
 */
contract MockStakingToken is ERC20 {
    constructor() ERC20("Voting Stake Token", "VST") {
        // Mint 1,000,000 tokens to deployer for testing
        _mint(msg.sender, 1_000_000 * 10**decimals());
    }

    /**
     * @dev Mint tokens for testing purposes
     * @param to Address to mint tokens to
     * @param amount Amount to mint
     */
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
