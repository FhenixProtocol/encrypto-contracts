// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {taskManagerAddress} from "./addresses/TaskManagerAddress.sol";
import {PermissionedUpgradeable, Permission} from "./Permissioned.sol";

/**
 * @title  ACL
 * @notice The ACL (Access Control List) is a permission management system designed to
 *         control who can access, compute on, or decrypt encrypted values in fhEVM.
 *         By defining and enforcing these permissions, the ACL ensures that encrypted data remains secure while still being usable
 *         within authorized contexts.
 */
contract ACL is
    UUPSUpgradeable,
    Ownable2StepUpgradeable,
    PermissionedUpgradeable
{
    /// @notice Returned if the delegatee contract is already delegatee for sender & delegator addresses.
    error AlreadyDelegated();

    /// @notice Returned if the sender is the delegatee address.
    error SenderCannotBeDelegateeAddress();

    /// @notice         Returned if the sender address is not allowed for allow operations.
    /// @param sender   Sender address.
    error SenderNotAllowed(address sender);

    /// @notice         Returned if the user is trying to directly allow a handle (not via Task Manager).
    /// @param sender   Sender address.
    error DirectAllowForbidden(address sender);

    /// @notice             Emitted when a list of handles is allowed for decryption.
    /// @param handlesList  List of handles allowed for decryption.
    event AllowedForDecryption(uint256[] handlesList);

    /// @notice                 Emitted when a new delegate address is added.
    /// @param sender           Sender address
    /// @param delegatee        Delegatee address.
    /// @param contractAddress  Contract address.
    event NewDelegation(
        address indexed sender,
        address indexed delegatee,
        address indexed contractAddress
    );

    /// @custom:storage-location erc7201:fhevm.storage.ACL
    struct ACLStorage {
        mapping(uint256 handle => mapping(address account => bool isAllowed)) persistedAllowedPairs;
        mapping(uint256 => bool) allowedForDecryption;
        mapping(address account => mapping(address delegatee => mapping(address contractAddress => bool isDelegate))) delegates;
    }

    /// @notice Name of the contract.
    string private constant CONTRACT_NAME = "ACL";

    /// @notice Major version of the contract.
    uint256 private constant MAJOR_VERSION = 0;

    /// @notice Minor version of the contract.
    uint256 private constant MINOR_VERSION = 1;

    /// @notice Patch version of the contract.
    uint256 private constant PATCH_VERSION = 0;

    /// @notice TaskManagerAddress address.
    address private constant TASK_MANAGER_ADDRESS = taskManagerAddress;

    /// @dev keccak256(abi.encode(uint256(keccak256("fhevm.storage.ACL")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ACLStorageLocation =
        0xa688f31953c2015baaf8c0a488ee1ee22eb0e05273cc1fd31ea4cbee42febc00;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice              Initializes the contract.
     * @param initialOwner  Initial owner address.
     */
    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __PermissionedUpgradeable_init();
    }

    /**
     * @notice              Allows the use of `handle` for the address `account`.
     * @dev                 The caller must be allowed to use `handle` for allow() to succeed. If not, allow() reverts.
     * @param handle        Handle.
     * @param account       Address of the account being given permissions.
     * @param requester     Address of the account giving the permissions.
     */
    function allow(
        uint256 handle,
        address account,
        address requester
    ) public virtual {
        ACLStorage storage $ = _getACLStorage();
        if (msg.sender != TASK_MANAGER_ADDRESS) {
            revert DirectAllowForbidden(msg.sender);
        }
        if (!isAllowed(handle, requester)) {
            revert SenderNotAllowed(requester);
        }
        $.persistedAllowedPairs[handle][account] = true;
    }

    /**
     * @notice              Allows a list of handles to be decrypted.
     * @param handlesList   List of handles.
     */
    function allowForDecryption(
        uint256[] memory handlesList,
        address requester
    ) public virtual {
        if (msg.sender != TASK_MANAGER_ADDRESS) {
            revert DirectAllowForbidden(msg.sender);
        }

        uint256 len = handlesList.length;
        ACLStorage storage $ = _getACLStorage();

        for (uint256 k = 0; k < len; k++) {
            uint256 handle = handlesList[k];
            if (!isAllowed(handle, requester)) {
                revert SenderNotAllowed(requester);
            }
            $.allowedForDecryption[handle] = true;
        }
        emit AllowedForDecryption(handlesList);
    }

    /**
     * @notice              Allows the use of `handle` by address `account` for this transaction.
     * @dev                 The caller must be allowed to use `handle` for allowTransient() to succeed.
     *                      If not, allowTransient() reverts.
     *                      The Coprocessor contract can always `allowTransient`, contrarily to `allow`.
     * @param handle        Handle.
     * @param account       Address of the account.
     */
    function allowTransient(uint256 handle, address account) public virtual {
        if (msg.sender != TASK_MANAGER_ADDRESS) {
            if (!isAllowed(handle, msg.sender)) {
                revert SenderNotAllowed(msg.sender);
            }
        }
        bytes32 key = keccak256(abi.encodePacked(handle, account));
        assembly {
            tstore(key, 1)
            let length := tload(0)
            let lengthPlusOne := add(length, 1)
            tstore(lengthPlusOne, key)
            tstore(0, lengthPlusOne)
        }
    }

    /**
     * @notice              Allows the use of `handle` by address `account` for this transaction.
     * @dev                 The caller must be the Task Manager contract.
     * @dev                 The requester must be allowed to use `handle` for allowTransient() to succeed.
     *                      If not, allowTransient() reverts.
     * @param handle        Handle.
     * @param account       Address of the account.
     * @param requester     Address of the requester.
     */
    function allowTransient(
        uint256 handle,
        address account,
        address requester
    ) public virtual {
        if (msg.sender != TASK_MANAGER_ADDRESS) {
            revert DirectAllowForbidden(msg.sender);
        }
        if (!isAllowed(handle, requester)) {
            revert SenderNotAllowed(requester);
        }
        bytes32 key = keccak256(abi.encodePacked(handle, account));
        assembly {
            tstore(key, 1)
            let length := tload(0)
            let lengthPlusOne := add(length, 1)
            tstore(lengthPlusOne, key)
            tstore(0, lengthPlusOne)
        }
    }

    /**
     * @notice                  Delegates the access of `handles` in the context of account abstraction for issuing
     *                          reencryption requests from a smart contract account.
     * @param delegatee         Delegatee address.
     * @param delegateeContract Delegatee contract.
     */
    function delegateAccount(
        address delegatee,
        address delegateeContract
    ) public virtual {
        // todo (eshel): probably allow only delegations through the taskMaanger contract, as with allow.
        if (delegateeContract == msg.sender) {
            revert SenderCannotBeDelegateeAddress();
        }

        ACLStorage storage $ = _getACLStorage();
        if ($.delegates[msg.sender][delegatee][delegateeContract]) {
            revert AlreadyDelegated();
        }

        $.delegates[msg.sender][delegatee][delegateeContract] = true;
        emit NewDelegation(msg.sender, delegatee, delegateeContract);
    }

    /**
     * @notice                  Returns whether the delegatee is allowed to access the handle.
     * @param delegatee         Delegatee address.
     * @param handle            Handle.
     * @param contractAddress   Contract address.
     * @param account           Address of the account.
     * @return isAllowed        Whether the handle can be accessed.
     */
    function allowedOnBehalf(
        address delegatee,
        uint256 handle,
        address contractAddress,
        address account
    ) public view virtual returns (bool) {
        ACLStorage storage $ = _getACLStorage();
        return
            $.persistedAllowedPairs[handle][account] &&
            $.persistedAllowedPairs[handle][contractAddress] &&
            $.delegates[account][delegatee][contractAddress];
    }

    /**
     * @notice                      Checks whether the account is allowed to use the handle in the
     *                              same transaction (transient).
     * @param handle                Handle.
     * @param account               Address of the account.
     * @return isAllowedTransient   Whether the account can access transiently the handle.
     */
    function allowedTransient(
        uint256 handle,
        address account
    ) public view virtual returns (bool) {
        bool isAllowedTransient;
        bytes32 key = keccak256(abi.encodePacked(handle, account));
        assembly {
            isAllowedTransient := tload(key)
        }
        return isAllowedTransient;
    }

    /**
     * @notice                     Getter function for the TaskManager contract address.
     * @return taskManagerAddress  Address of the TaskManager.
     */
    function getTaskManagerAddress() public view virtual returns (address) {
        return TASK_MANAGER_ADDRESS;
    }

    /**
     * @notice              Returns whether the account is allowed to use the `handle`, either due to
     *                      allowTransient() or allow().
     * @param handle        Handle.
     * @param account       Address of the account.
     * @return isAllowed    Whether the account can access the handle.
     */
    function isAllowed(
        uint256 handle,
        address account
    ) public view virtual returns (bool) {
        return
            allowedTransient(handle, account) ||
            persistAllowed(handle, account);
    }

    /**
     * @notice              Checks whether a handle is allowed for decryption.
     * @param handle        Handle.
     * @return isAllowed    Whether the handle is allowed for decryption.
     */
    function isAllowedForDecryption(
        uint256 handle
    ) public view virtual returns (bool) {
        ACLStorage storage $ = _getACLStorage();
        return $.allowedForDecryption[handle];
    }

    /**
     * @notice              Returns `true` if address `a` is allowed to use `c` and `false` otherwise.
     * @param handle        Handle.
     * @param account       Address of the account.
     * @return isAllowed    Whether the account can access the handle.
     */
    function persistAllowed(
        uint256 handle,
        address account
    ) public view virtual returns (bool) {
        ACLStorage storage $ = _getACLStorage();
        return $.persistedAllowedPairs[handle][account];
    }

    /**
     * @dev This function removes the transient allowances, which could be useful for integration with
     *      Account Abstraction when bundling several UserOps calling the TaskManagerCoprocessor.
     */
    function cleanTransientStorage() external virtual {
        assembly {
            let length := tload(0)
            tstore(0, 0)
            let lengthPlusOne := add(length, 1)
            for {
                let i := 1
            } lt(i, lengthPlusOne) {
                i := add(i, 1)
            } {
                let handle := tload(i)
                tstore(i, 0)
                tstore(handle, 0)
            }
        }
    }

    /**
     * @notice        Getter for the name and version of the contract.
     * @return string Name and the version of the contract.
     */
    function getVersion() external pure virtual returns (string memory) {
        return
            string(
                abi.encodePacked(
                    CONTRACT_NAME,
                    " v",
                    Strings.toString(MAJOR_VERSION),
                    ".",
                    Strings.toString(MINOR_VERSION),
                    ".",
                    Strings.toString(PATCH_VERSION)
                )
            );
    }

    /**
     * @dev Should revert when `msg.sender` is not authorized to upgrade the contract.
     */
    function _authorizeUpgrade(
        address _newImplementation
    ) internal virtual override onlyOwner {}

    /**
     * @dev                         Returns the ACL storage location.
     */
    function _getACLStorage() internal pure returns (ACLStorage storage $) {
        assembly {
            $.slot := ACLStorageLocation
        }
    }

    function isAllowedWithPermission(
        Permission memory permission,
        uint256 handle
    ) public view withPermission(permission) returns (bool) {
        return isAllowed(handle, permission.issuer);
    }
}
