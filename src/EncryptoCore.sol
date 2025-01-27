// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

import {IERC20, IERC20Metadata, ERC20} from "@openzeppelin/contracts/token/ERC20//ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EncryptableWrappedFHERC20} from "./EncryptableWrappedFHERC20.sol";

contract EncryptoCore is Ownable {
    mapping(address erc20 => address fherc20) private _fherc20Map;

    constructor() Ownable(msg.sender) {}

    error EncryptoFherc20AlreadyDeployed();
    error EncryptoFherc20NotDeployed();

    modifier fherc20Deployed(IERC20 erc20) {
        if (_fherc20Map[address(erc20)] == address(0)) {
            revert EncryptoFherc20NotDeployed();
        }
        _;
    }

    modifier fherc20NotDeployed(IERC20 erc20) {
        if (_fherc20Map[address(erc20)] == address(0)) {
            revert EncryptoFherc20AlreadyDeployed();
        }
        _;
    }

    function getFherc20(address erc20) public view returns (address) {
        return _fherc20Map[erc20];
    }

    function updateFherc20Symbol(
        EncryptableWrappedFHERC20 fherc20,
        string memory updatedSymbol
    ) public onlyOwner {
        fherc20.updateSymbol(updatedSymbol);
    }

    function deployFherc20(IERC20 erc20) public fherc20NotDeployed(erc20) {
        _deployFherc20(erc20);
    }

    function deployAndEncrypt(
        IERC20 erc20,
        address to,
        uint256 value
    ) public fherc20NotDeployed(erc20) {
        if (_fherc20Map[address(erc20)] == address(0)) _deployFherc20(erc20);

        _encrypt(erc20, to, value);
    }

    function encrypt(
        IERC20 erc20,
        address to,
        uint256 value
    ) public fherc20Deployed(erc20) {
        _encrypt(erc20, to, value);
    }

    function encryptNative(address to) public payable {}

    function decrypt(
        IERC20 erc20,
        address to,
        uint256 value
    ) public fherc20Deployed(erc20) {
        EncryptableWrappedFHERC20(_fherc20Map[address(erc20)]).decrypt(
            to,
            value
        );
    }

    function _deployFherc20(IERC20 erc20) internal {
        EncryptableWrappedFHERC20 fherc20 = new EncryptableWrappedFHERC20(
            erc20,
            ""
        );
        _fherc20Map[address(erc20)] = address(fherc20);
    }

    function _encrypt(IERC20 erc20, address to, uint256 value) internal {
        EncryptableWrappedFHERC20(_fherc20Map[address(erc20)]).encrypt(
            to,
            value
        );
    }
}
