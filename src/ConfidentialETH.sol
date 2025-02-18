// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import {IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {FHERC20} from "./FHERC20.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {euint128, FHE} from "@fhenixprotocol/cofhe-foundry-mocks/FHE.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ConfidentialClaim} from "./ConfidentialClaim.sol";

contract ConfidentialETH is FHERC20, Ownable, ConfidentialClaim {
    using EnumerableSet for EnumerableSet.UintSet;

    IWETH public wETH;

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

    receive() external payable {}

    fallback() external payable {}

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
        euint128 burned = _burn(msg.sender, value);
        FHE.decrypt(burned);
        _createClaim(to, value, burned);
    }

    /**
     * @notice Claim a decrypted amount of ETH
     * @param ctHash The ctHash of the burned amount
     */
    function claimDecrypted(uint256 ctHash) public {
        Claim memory claim = _handleClaim(ctHash);

        // Send the ETH to the recipient
        (bool sent, ) = claim.to.call{value: claim.decryptedAmount}("");
        if (!sent) revert ETHTransferFailed();
    }
}
