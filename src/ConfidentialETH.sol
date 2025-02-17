// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import {IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {FHERC20} from "./FHERC20.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {euint128, FHE} from "@fhenixprotocol/cofhe-foundry-mocks/FHE.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract ConfidentialETH is FHERC20, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    IWETH public wETH;

    mapping(uint256 ctHash => address) public claimableBy;
    mapping(uint256 ctHash => bool) public claimed;

    mapping(address => EnumerableSet.UintSet) private _userClaimable;

    error NotFound();
    error AlreadyClaimed();

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
        claimableBy[euint128.unwrap(burned)] = to;
        _userClaimable[to].add(euint128.unwrap(burned));
    }

    /**
     * @notice Claim a decrypted amount of ETH
     * @param ctHash The ctHash of the burned amount
     */
    function claimDecrypted(uint256 ctHash) public {
        // Check that the claimable amount exists and has not been claimed yet
        if (claimableBy[ctHash] == address(0)) revert NotFound();
        if (claimed[ctHash]) revert AlreadyClaimed();

        // Get the decrypted amount (reverts if the amount is not decrypted yet)
        uint256 amount = FHE.getDecryptResult(ctHash);

        // Send the ETH to the recipient
        (bool sent, ) = claimableBy[ctHash].call{value: amount}("");
        if (!sent) revert ETHTransferFailed();

        // Mark the amount as claimed
        claimed[ctHash] = true;

        // Remove the claimable amount from the user's claimable set
        _userClaimable[claimableBy[ctHash]].remove(ctHash);
    }

    function userClaimable(
        address user
    ) public view returns (uint256[] memory) {
        return _userClaimable[user].values();
    }
}
