// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.25;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {FHERC20Upgradeable} from "./FHERC20Upgradeable.sol";

contract FUSD is FHERC20Upgradable, Initializable, AccessControlUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    error CallerNotMinter(address caller);

    function __FUSD_init() public onlyInitializing {
        __FHERC20_init("FHE US Dollar", "FUSD", 6);
        _grantRole(MINTER_ROLE, fusdVault_);
    }

    function __FUSD_init_unchained() public onlyInitializing {}

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
