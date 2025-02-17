// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import {IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {FHERC20} from "./FHERC20.sol";
import {IWETH} from "./interfaces/IWETH.sol";

contract ConfidentialETH is FHERC20, Ownable {
    IWETH public immutable wETH;

    constructor(
        IWETH wETH_
    )
        Ownable(msg.sender)
        FHERC20(
            "Confidential Wrapped ETHER",
            "eETH",
            IERC20Metadata(address(wETH_)).decimals()
        )
    {
        wETH = wETH_;
    }

    error ETHTransferFailed();

    function encryptWETH(address to, uint128 value) public {
        wETH.transferFrom(msg.sender, address(this), value);
        wETH.withdraw(value);
        _mint(to, value);
    }

    function encryptETH(address to) public payable {
        _mint(to, uint128(msg.value));
    }

    function decrypt(address to, uint128 value) public {
        _burn(msg.sender, value);

        (bool sent, ) = to.call{value: value}("");
        if (!sent) revert ETHTransferFailed();
    }
}
