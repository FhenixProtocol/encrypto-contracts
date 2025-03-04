// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.25;

import "./FHERC20Upgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract FUSD is FHERC20Upgradeable, AccessControlUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    error CallerNotMinter(address caller);

    function __FUSD_init(address fusdVault_) public initializer {
        __FHERC20_init("FHE US Dollar", "FUSD", 6);
        _grantRole(MINTER_ROLE, fusdVault_);
    }

    function __FUSD_init_unchained() public initializer {}

    function mint(address receiver, uint128 amount) external returns (bool) {
        if (!hasRole(MINTER_ROLE, msg.sender))
            revert CallerNotMinter(msg.sender);

        _mint(receiver, amount);
        return true;
    }

    function redeem(address burner, uint128 amount) external returns (bool) {
        if (!hasRole(MINTER_ROLE, msg.sender))
            revert CallerNotMinter(msg.sender);

        _burn(burner, amount);
        return true;
    }
}
