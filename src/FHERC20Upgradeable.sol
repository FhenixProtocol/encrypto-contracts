// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.25;

import {IFHERC20} from "./interfaces/IFHERC20.sol";
import {IFHERC20Errors} from "./interfaces/IFHERC20Errors.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {NoncesUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/NoncesUpgradeable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {FHE, euint128, inEuint128, SealedUint, Utils} from "@fhenixprotocol/cofhe-contracts/FHE.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC-20
 * applications.
 *
 * Note: This FHERC20 does not include FHE operations, and is intended to decouple the
 * frontend work from the active CoFHE (FHE Coprocessor) work during development and auditing.
 */
abstract contract FHERC20Upgradeable is
    IFHERC20,
    IFHERC20Errors,
    Initializable,
    ContextUpgradeable,
    EIP712Upgradeable,
    NoncesUpgradeable
{
    struct FHERC20Storage {
        // NOTE: `indicatedBalances` are intended to indicate movement and change
        // of an encrypted FHERC20 balance, without exposing any encrypted data.
        //
        // !! WARNING !! These indicated balances MUST NOT be used in any FHERC20 logic, only
        // the encrypted balance should be used.
        //
        // `indicatedBalance` is implemented to make FHERC20s maximally backwards
        // compatible with existing ERC20 expectations.
        //
        // `indicatedBalance` is internally represented by a number between 0 and 99999.
        // When viewed in a wallet, it is transformed into a decimal value with 4 digits
        // of precision (0.0000 to 0.9999). These same increments are used as the
        // value in any emitted events. If the user has not interacted with this FHERC20
        // their indicated amount will be 0. Their first interaction will set the amount to
        // the midpoint (0.5000), and each subsequent interaction will shift that value by
        // the increment (0.0001). This gives room for up to 5000 interactions in either
        // direction, which is sufficient for >99.99% of user use cases.
        //
        // These `indicatedBalance` changes will show up in:
        // - transactions and block scanners (0xAAA -> 0xBBB - 0.0001 eETH)
        // - wallets and portfolios (eETH - 0.5538)
        //
        // `indicatedBalance` is included in the FHERC20 standard as a stop-gap
        // to indicate change when the real encrypted change is not yet implemented
        // in infrastructure like wallets and etherscans.
        mapping(address account => uint16) _indicatedBalances;
        mapping(address account => euint128) _encBalances;
        uint256 _totalSupply;
        string _name;
        string _symbol;
        uint8 _decimals;
        uint256 _indicatorTick;
        mapping(address account => bytes32 sealingKey) _accountSealingKeys;
        mapping(euint128 euint128 => mapping(bytes32 sealingKey => SealOutputRequest request)) _sealOutputRequests;
        mapping(euint128 euint128 => DecryptRequest request) _decryptRequests;
    }

    // bytes32 private constant FHERC20StorageLocation =
    //     keccak256(
    //         abi.encode(uint256(keccak256("fhenix.storage.FHERC20")) - 1)
    //     ) & ~bytes32(uint256(0xff));
    bytes32 private constant FHERC20StorageLocation =
        0x52c63247e1f47db19d5ce0460030c497f067ca4cebf71ba98eeadabe20bace00;

    function _getFHERC20Storage()
        private
        pure
        returns (FHERC20Storage storage $)
    {
        assembly {
            $.slot := FHERC20StorageLocation
        }
    }

    // EIP712 Permit

    // bytes32 private constant PERMIT_TYPEHASH =
    //     keccak256(
    //         "Permit(address owner,address spender,uint256 value_hash,uint256 nonce,uint256 deadline)"
    //     );
    bytes32 private constant PERMIT_TYPEHASH = 0x0;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __FHERC20_init(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) internal onlyInitializing {
        FHERC20Storage storage $ = _getFHERC20Storage();
        $._name = name_;
        $._symbol = symbol_;
        $._decimals = decimals_;
        $._indicatorTick = 10 ** (decimals_ - 4);
        __EIP712_init_unchained(name_, "1");
    }

    function __FHERC20_init_unchained() internal onlyInitializing {}

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        FHERC20Storage storage $ = _getFHERC20Storage();
        return $._name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        FHERC20Storage storage $ = _getFHERC20Storage();
        return $._symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        FHERC20Storage storage $ = _getFHERC20Storage();
        return $._decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        FHERC20Storage storage $ = _getFHERC20Storage();
        return $._totalSupply;
    }

    /**
     * @dev Returns an flag indicating that the public balances returned by
     * `balanceOf` is an indication of the underlying encrypted balance.
     * The value returned is between 0.0000 and 0.9999, and
     * acts as a counter of tokens transfers and changes.
     *
     * Receiving tokens increments this indicator by +0.0001.
     * Sending tokens decrements the indicator by -0.0001.
     */
    function balanceOfIsIndicator() public view virtual returns (bool) {
        return true;
    }

    /**
     * @dev Returns the true size of the indicator tick
     */
    function indicatorTick() public view returns (uint256) {
        FHERC20Storage storage $ = _getFHERC20Storage();
        return $._indicatorTick;
    }

    /**
     * @dev See {IFHERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        FHERC20Storage storage $ = _getFHERC20Storage();
        return $._indicatedBalances[account] * $._indicatorTick;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     *
     * Returns the euint128 representing the account's true balance (encrypted)
     */
    function encBalanceOf(
        address account
    ) public view virtual returns (euint128) {
        FHERC20Storage storage $ = _getFHERC20Storage();
        return $._encBalances[account];
    }

    /**
     * @dev Requests an account's balance to be sealed. The result of the sealing
     * operation will only be visible to parties in possession of the private key
     * associated with the `sealingKey` passed as a parameter.
     *
     * NOTE: Be very careful when overriding this function not to expose encrypted data.
     */
    function sealBalanceOf(address account, bytes32 sealingKey) public virtual {
        FHERC20Storage storage $ = _getFHERC20Storage();

        FHE.sealoutput($._encBalances[account], sealingKey);

        $._accountSealingKeys[msg.sender] = sealingKey;

        SealOutputRequest storage request = $._sealOutputRequests[
            $._encBalances[account]
        ][sealingKey];

        request.account = account;
        request.ctHash = $._encBalances[account];
        request.status = RequestStatus.Pending;
    }

    /**
     * @dev Function called by CoFHE with the result of a sealoutput request
     */
    function handleSealOutputResult(
        uint256 ctHash,
        string memory result,
        address requestor
    ) external override {
        FHERC20Storage storage $ = _getFHERC20Storage();

        SealOutputRequest storage request = $._sealOutputRequests[
            euint128.wrap(ctHash)
        ][$._accountSealingKeys[requestor]];

        request.result = result;
        request.status = RequestStatus.Ready;

        emit FHERC20SealOutputResultReady(
            request.account,
            ctHash,
            result,
            $._accountSealingKeys[requestor]
        );
    }

    /**
     * @dev Retrieves the sealed output result (if it is ready) that has been returned by the coprocessor.
     *
     * Requirements:
     *
     * - `account`
     * - `sealingKey` must match the `sealingKey` passed into `sealBalanceOf`, or the result will not be found.
     *
     * Returns the sealed result as a `SealedUint` struct so that it can be automatically unsealed by `cofhe.js`.
     */
    function sealedBalanceOf(
        address account,
        bytes32 sealingKey
    )
        public
        view
        virtual
        returns (SealOutputRequest memory request, SealedUint memory result)
    {
        FHERC20Storage storage $ = _getFHERC20Storage();
        request = $._sealOutputRequests[$._encBalances[account]][sealingKey];
        result.data = request.result;
        result.utype = Utils.EUINT128_TFHE;
    }

    /**
     * @dev Requests an account's balance to be decrypted.
     * See Fhenix CoFHE AccessControlList (ACL) for information on which accounts and
     * contracts are permitted to request a decryption.
     *
     * NOTE: Be very careful when overriding this function not to expose encrypted data.
     */
    function decryptBalanceOf(address account) public virtual {
        FHERC20Storage storage $ = _getFHERC20Storage();

        FHE.decrypt($._encBalances[account]);

        DecryptRequest storage request = $._decryptRequests[
            $._encBalances[account]
        ];

        request.account = account;
        request.ctHash = $._encBalances[account];
        request.status = RequestStatus.Pending;
    }

    /**
     * @dev Function called by CoFHE with the result of a decrypt request
     */
    function handleDecryptResult(
        uint256 ctHash,
        uint256 result,
        address
    ) external override {
        FHERC20Storage storage $ = _getFHERC20Storage();

        DecryptRequest storage request = $._decryptRequests[
            euint128.wrap(ctHash)
        ];

        request.result = result;
        request.status = RequestStatus.Ready;

        emit FHERC20DecryptResultReady(request.account, ctHash, result);
    }

    /**
     * @dev Retrieves the decrypted result (if it is ready) that has been returned by the coprocessor.
     */
    function decryptedBalanceOf(
        address account
    )
        public
        view
        virtual
        returns (DecryptRequest memory request, uint256 result)
    {
        FHERC20Storage storage $ = _getFHERC20Storage();
        request = $._decryptRequests[$._encBalances[account]];
        result = request.result;
    }

    /**
     * @dev See {IERC20-transfer}.
     * Always reverts to prevent FHERC20 from being unintentionally treated as an ERC20
     */
    function transfer(address, uint256) public pure returns (bool) {
        revert FHERC20IncompatibleFunction();
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     * - `inValue` must be a `inEuint128` to preserve confidentiality.
     */
    function encTransfer(
        address to,
        inEuint128 memory inValue
    ) public virtual returns (bool) {
        euint128 value = FHE.asEuint128(inValue);
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     * Always reverts to prevent FHERC20 from being unintentionally treated as an ERC20.
     * Allowances have been removed from FHERC20s to prevent encrypted balance leakage.
     * Allowances have been replaced with an EIP712 permit for each `encTransferFrom`.
     */
    function allowance(address, address) external pure returns (uint256) {
        revert FHERC20IncompatibleFunction();
    }

    /**
     * @dev See {IERC20-approve}.
     * Always reverts to prevent FHERC20 from being unintentionally treated as an ERC20.
     * Allowances have been removed from FHERC20s to prevent encrypted balance leakage.
     * Allowances have been replaced with an EIP712 permit for each `encTransferFrom`.
     */
    function approve(address, uint256) external pure returns (bool) {
        revert FHERC20IncompatibleFunction();
    }

    /**
     * @dev See {IERC20-transferFrom}.
     * Always reverts to prevent FHERC20 from being unintentionally treated as an ERC20
     */
    function transferFrom(
        address,
        address,
        uint256
    ) public pure returns (bool) {
        revert FHERC20IncompatibleFunction();
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function encTransferFrom(
        address from,
        address to,
        inEuint128 memory inValue,
        FHERC20_EIP712_Permit calldata permit
    ) public virtual returns (bool) {
        if (block.timestamp > permit.deadline)
            revert ERC2612ExpiredSignature(permit.deadline);

        if (from != permit.owner)
            revert FHERC20EncTransferFromOwnerMismatch(from, permit.owner);
        if (to != permit.spender)
            revert FHERC20EncTransferFromSpenderMismatch(to, permit.spender);

        if (inValue.hash != permit.value_hash)
            revert FHERC20EncTransferFromValueMismatch(
                inValue.hash,
                permit.value_hash
            );

        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                permit.owner,
                permit.spender,
                permit.value_hash,
                _useNonce(permit.owner),
                permit.deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, permit.v, permit.r, permit.s);
        if (signer != permit.owner) {
            revert ERC2612InvalidSigner(signer, permit.owner);
        }

        euint128 value = FHE.asEuint128(inValue);

        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, euint128 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value, 0);
    }

    /*
     * @dev Increments a user's balance indicator by 0.0001
     */
    function _incrementIndicator(
        uint16 current
    ) internal pure returns (uint16) {
        if (current == 0) return 5001;
        if (current < 9999) return current + 1;
        return current;
    }

    /*
     * @dev Decrements a user's balance indicator by 0.0001
     */
    function _decrementIndicator(uint16 value) internal pure returns (uint16) {
        if (value == 0) return 4999;
        if (value > 1) return value - 1;
        return value;
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * The `cleartextValue` input is used only for totalSupply, and is included when updated is called
     * by the `_mint` and `_burn` functions, else it is 0.
     *
     * Emits a {Transfer} event.
     */
    function _update(
        address from,
        address to,
        euint128 value,
        uint128 cleartextValue
    ) internal virtual {
        FHERC20Storage storage $ = _getFHERC20Storage();

        // If `value` is greater than the user's encBalance, it is replaced with 0
        // The transaction will succeed, but the amount transferred may be 0
        // Both `from` and `to` will have their `encBalance` updated in either case to preserve confidentiality
        euint128 valueOr0 = FHE.select(
            value.lte($._encBalances[from]),
            value,
            FHE.asEuint128(0)
        );

        if (from == address(0)) {
            $._totalSupply += cleartextValue;
        } else {
            $._encBalances[from] = FHE.sub($._encBalances[from], valueOr0);
            $._indicatedBalances[from] = _decrementIndicator(
                $._indicatedBalances[from]
            );
        }

        if (to == address(0)) {
            $._totalSupply -= cleartextValue;
        } else {
            $._encBalances[from] = FHE.add($._encBalances[from], valueOr0);
            $._indicatedBalances[to] = _incrementIndicator(
                $._indicatedBalances[to]
            );
        }

        // Update CoFHE Access Control List (ACL) to allow decrypting / sealing of the new balances
        FHE.allowThis($._encBalances[from]);
        FHE.allowThis($._encBalances[to]);
        FHE.allow($._encBalances[from], from);
        FHE.allow($._encBalances[to], to);

        emit Transfer(from, to, $._indicatorTick);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint128 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, FHE.asEuint128(value), value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint128 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), FHE.asEuint128(value), value);
    }

    // EIP712 Permit

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(
        address owner
    ) public view override(IFHERC20, NoncesUpgradeable) returns (uint256) {
        return super.nonces(owner);
    }

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
        return _domainSeparatorV4();
    }
}
