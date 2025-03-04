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

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Implement this to add upgrade authorization mechanisms.
     */
    function _authorizeUpgrade(address newImplementation) internal override {
        _checkRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

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
