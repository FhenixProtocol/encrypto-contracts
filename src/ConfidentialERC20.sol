// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.25;

import {IERC20, IERC20Metadata, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IFHERC20, FHERC20} from "./FHERC20.sol";
import {euint128, FHE} from "@fhenixprotocol/cofhe-foundry-mocks/FHE.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract ConfidentialERC20 is FHERC20, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    IERC20 private immutable _erc20;
    string private _symbol;

    mapping(uint256 ctHash => address) public claimableBy;
    mapping(uint256 ctHash => bool) public claimed;

    mapping(address => EnumerableSet.UintSet) private _userClaimable;

    error NotFound();
    error AlreadyClaimed();

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
        try IFHERC20(address(erc20_)).isFherc20() returns (bool isFherc20) {
            if (isFherc20) {
                revert FHERC20InvalidErc20(address(erc20_));
            }
        } catch {
            // Not an FHERC20, continue
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

    function encrypt(address to, uint128 value) public {
        IERC20(_erc20).transferFrom(msg.sender, address(this), value);
        _mint(to, value);
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

        // Send the ERC20 to the recipient
        IERC20(_erc20).transfer(claimableBy[ctHash], amount);

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
