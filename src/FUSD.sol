// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {FHERC20} from "./FHERC20.sol";

contract FUSD is FHERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    error CallerNotMinter(address caller);

    constructor(address fusdVault_) FHERC20("FHE Dollar", "FHED", 6) {
        _grantRole(MINTER_ROLE, fusdVault_);
    }

    function mint(address receiver, uint256 amount) external returns (bool) {
        if (!hasRole(MINTER_ROLE, msg.sender))
            revert CallerNotMinter(msg.sender);

        _mint(receiver, amount);
        return true;
    }

    function redeem(address burner, uint256 amount) external returns (bool) {
        if (!hasRole(MINTER_ROLE, msg.sender))
            revert CallerNotMinter(msg.sender);

        _burn(burner, amount);
        return true;
    }
}
