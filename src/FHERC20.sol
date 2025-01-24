// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

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
 */
abstract contract FHERC20 is
    Context,
    IERC20,
    IERC20Metadata,
    IERC20Errors,
    EIP712,
    Nonces
{
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
    mapping(address account => uint16) private _indicatedBalances;
    mapping(address account => uint256) private _encBalances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _indicatorOffset;

    // EIP712 Permit

    // TODO: <FHE INTEGRATION> Update `uint256 value` to be the `ct_hash` of the value to transfer
    bytes32 private constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    /**
     * @dev Permit deadline has expired.
     */
    error ERC2612ExpiredSignature(uint256 deadline);

    /**
     * @dev Mismatched signature.
     */
    error ERC2612InvalidSigner(address signer, address owner);

    /**
     * @dev EIP712 Permit reusable struct
     */
    struct FHERC20_EIP712_Permit {
        address owner;
        address spender;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    // FHERC20

    /**
     * @dev Indicates an incompatible function being called.
     * Prevents unintentional treatment of an FHERC20 as a cleartext ERC20
     */
    error FHERC20IncompatibleFunction();

    /**
     * @dev encTransferFrom `from` and `permit.owner` don't match
     */
    error FHERC20EncTransferFromOwnerMismatch(
        address from,
        address permitOwner
    );

    /**
     * @dev encTransferFrom `to` and `permit.spender` don't match
     */
    error FHERC20EncTransferFromSpenderMismatch(
        address to,
        address permitSpender
    );

    /**
     * @dev encTransferFrom `value` greater than `permit.permitValue`
     * TODO: Replace uint256 `value` with uint256 `ct_hash`
     */
    error FHERC20EncTransferFromValueMismatch(
        uint256 value,
        uint256 permitValue
    );

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) EIP712(name_, "1") {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;

        _indicatorOffset = 10 * 10 ** (decimals_ - 4);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
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
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
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
     * @dev Returns an indicator of the underlying encrypted balance.
     * The value returned is [0](no interaction) / [0.0001 - 0.9999](indicated)
     * Indicator acts as a counter of tokens transfers and changes.
     *
     * Receiving tokens increments this indicator by +0.0001.
     * Sending tokens decrements the indicator by -0.0001.
     *
     * Returned in the decimal expectation of the token.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _indicatedBalances[account] * 10 ** (decimals() - 4);
    }

    /**
     * @dev See {IERC20-balanceOf}.
     * TODO: Document
     */
    function encBalanceOf(
        address account
    ) public view virtual returns (uint256) {
        // TODO: Switch this to returning the euint128 encrypted amount
        return _encBalances[account];
    }

    function sealBalanceSelf(bytes32 sealingKey) public virtual {
        // TODO: Indicate that user `msg.sender` is sealing `_encBalances[msg.sender]` with `sealingKey`
        // FHE.sealoutput(_encBalances[msg.sender], sealingKey);
    }

    /**
     * Can be returned without permit here because it was sealed with an unknown sealing key.
     * The sealed result leaks no data without the sealingKey pair privateKey
     */
    function sealedBalanceOf(
        address account
    ) public view virtual returns (uint256) {
        // return FHE.sealoutputResult(_sealedBalances[account]);
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
     *
     * TODO: Replace uint256 cleartext value with inEuint128 encrypted value
     */
    function encTransfer(
        address to,
        uint256 value
    ) public virtual returns (bool) {
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
     * Skips emitting an {Approval} event indicating an allowance update. This is not
     * required by the ERC. See {xref-ERC20-_approve-address-address-uint256-bool-}[_approve].
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     *
     * TODO: Replace uint256 cleartext value with inEuint128 encrypted value
     * TODO: Replace `value` and `permit.value` comparison with `ct_hash` matching (no FHE op comparison)
     */
    function encTransferFrom(
        address from,
        address to,
        uint256 value,
        FHERC20_EIP712_Permit calldata permit
    ) public virtual returns (bool) {
        if (from != permit.owner)
            revert FHERC20EncTransferFromOwnerMismatch(from, permit.owner);
        if (to != permit.spender)
            revert FHERC20EncTransferFromSpenderMismatch(to, permit.spender);
        if (value != permit.value)
            revert FHERC20EncTransferFromValueMismatch(value, permit.value);

        if (block.timestamp > permit.deadline)
            revert ERC2612ExpiredSignature(permit.deadline);

        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                permit.owner,
                permit.spender,
                value,
                _useNonce(permit.owner),
                permit.deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, permit.v, permit.r, permit.s);
        if (signer != permit.owner) {
            revert ERC2612InvalidSigner(signer, permit.owner);
        }

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
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    function _incrementIndicator(
        uint16 current
    ) internal pure returns (uint16) {
        if (current == 0) return 5001;
        if (current < 9999) return current + 1;
        return current;
    }

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
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _encBalances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _encBalances[from] = fromBalance - value;
                _indicatedBalances[from] = _decrementIndicator(
                    _indicatedBalances[from]
                );
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _encBalances[to] += value;
                _indicatedBalances[from] = _incrementIndicator(
                    _indicatedBalances[from]
                );
            }
        }

        emit Transfer(from, to, _indicatorOffset);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    // EIP712 Permit

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) public view override returns (uint256) {
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
