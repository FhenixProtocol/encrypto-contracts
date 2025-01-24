// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

import {IERC20, IERC20Metadata, ERC20} from "@openzeppelin/contracts/token/ERC20//ERC20.sol";
import {FHERC20} from "./FHERC20.sol";

contract EncryptableWrappedFHERC20 is FHERC20 {
    IERC20 private immutable _erc20;

    /**
     * @dev The erc20 token couldn't be wrapped.
     */
    error FHERC20InvalidErc20(address token);

    constructor(
        IERC20 erc20_,
        string memory symbolOverride_
    )
        FHERC20(
            string.concat(
                "Fhenix Encrypted - ",
                IERC20Metadata(address(_erc20)).name()
            ),
            bytes(symbolOverride_).length == 0
                ? string.concat("e", IERC20Metadata(address(_erc20)).symbol())
                : symbolOverride_,
            IERC20Metadata(address(_erc20)).decimals()
        )
    {
        if (erc20_ == this) {
            revert FHERC20InvalidErc20(address(this));
        }
        _erc20 = erc20_;
    }

    /**
     * @dev Returns the address of the erc20 ERC-20 token that is being encrypted wrapped.
     */
    function erc20() public view returns (IERC20) {
        return _erc20;
    }

    function _encryptHandleCleartextERC20(
        address from,
        uint256 value
    ) internal virtual {
        IERC20(_erc20).transferFrom(from, address(this), value);
    }

    function encrypt(address to, uint256 value) public virtual {
        _encryptHandleCleartextERC20(msg.sender, value);
        _mint(to, value);
    }

    function _decryptHandleCleartextERC20(
        address to,
        uint256 value
    ) internal virtual {
        IERC20(_erc20).transfer(to, value);
    }

    function decrypt(address to, uint256 value) public {
        _burn(msg.sender, value);
        _decryptHandleCleartextERC20(to, value);
    }
}
