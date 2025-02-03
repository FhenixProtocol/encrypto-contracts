// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

import {IERC20, IERC20Metadata, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {FHERC20} from "./FHERC20.sol";

contract ConfidentialERC20 is FHERC20, Ownable {
    IERC20 private immutable _erc20;
    string private _symbol;

    /**
     * @dev The erc20 token couldn't be wrapped.
     */
    error FHERC20InvalidErc20(address token);

    constructor(
        IERC20 erc20_,
        string memory symbolOverride_
    )
        Ownable(msg.sender)
        FHERC20(
            string.concat(
                "Confidential ",
                IERC20Metadata(address(erc20_)).name()
            ),
            bytes(symbolOverride_).length == 0
                ? string.concat("e", IERC20Metadata(address(erc20_)).symbol())
                : symbolOverride_,
            IERC20Metadata(address(erc20_)).decimals()
        )
    {
        if (erc20_ == this) {
            revert FHERC20InvalidErc20(address(this));
        }
        _erc20 = erc20_;

        _symbol = bytes(symbolOverride_).length == 0
            ? string.concat("e", IERC20Metadata(address(erc20_)).symbol())
            : symbolOverride_;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function updateSymbol(string memory updatedSymbol) public onlyOwner {
        _symbol = updatedSymbol;
    }

    /**
     * @dev Returns the address of the erc20 ERC-20 token that is being encrypted wrapped.
     */
    function erc20() public view returns (IERC20) {
        return _erc20;
    }

    function encrypt(address to, uint256 value) public {
        IERC20(_erc20).transferFrom(msg.sender, address(this), value);
        _mint(to, value);
    }

    function decrypt(address to, uint256 value) public {
        _burn(msg.sender, value);
        IERC20(_erc20).transfer(to, value);
    }
}
