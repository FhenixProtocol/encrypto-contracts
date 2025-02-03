// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

import {IERC20, IERC20Metadata, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ConfidentialERC20} from "./ConfidentialERC20.sol";
import {ConfidentialETH} from "./ConfidentialETH.sol";
import {IWETH} from "./interfaces/IWETH.sol";

contract EncryptoCore is Ownable {
    mapping(address erc20 => address fherc20) private _fherc20Map;

    // Confidential ETH :: ETH / wETH deposited into Encrypto are routed to cETH
    IWETH public wETH;
    ConfidentialETH public cETH;

    // Stablecoins :: deposited stablecoins are routed to FUSD
    mapping(address erc20 => bool isStablecoin) public _stablecoins;

    constructor() Ownable(msg.sender) {}

    error Invalid_AlreadyDeployed();
    error Invalid_Stablecoin();
    error Invalid_WETH();

    function updateStablecoin(
        address stablecoin,
        bool isStablecoin
    ) public onlyOwner {
        _stablecoins[stablecoin] = isStablecoin;
    }

    function getFherc20(address erc20) public view returns (address) {
        return _fherc20Map[erc20];
    }

    function getIsStablecoin(address erc20) public view returns (bool) {
        return _stablecoins[erc20];
    }

    function getIsWETH(address erc20) public view returns (bool) {
        return erc20 == address(wETH);
    }

    function updateFherc20Symbol(
        ConfidentialERC20 fherc20,
        string memory updatedSymbol
    ) public onlyOwner {
        fherc20.updateSymbol(updatedSymbol);
    }

    function deployFherc20(IERC20 erc20) public {
        if (_fherc20Map[address(erc20)] == address(0))
            revert Invalid_AlreadyDeployed();

        if (_stablecoins[address(erc20)]) revert Invalid_Stablecoin();
        if (address(erc20) == address(wETH)) revert Invalid_WETH();

        ConfidentialERC20 fherc20 = new ConfidentialERC20(erc20, "");
        _fherc20Map[address(erc20)] = address(fherc20);
    }
}
