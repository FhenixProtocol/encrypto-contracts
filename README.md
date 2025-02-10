# <h1 align="center"> Encrypto Contracts </h1>

**FHERC20 standard + Encrypto Contracts (FHED / EncryptableWrappedFHERC20)**

### Contracts (/src)

Audit scope:

- All contracts other than `___NonFHE.sol`. The non-fhe enabled contracts are included purely as reference contracts.

Standards:

- FHERC20NonFHE.sol (The full FHERC20 without FHE included, for testing EIP712 / indicated balances. Documented in FHERC20.md)
- FHERC20.sol (FHERC20.sol + FHE operations)
- FHERC20Upgradeable.sol (FHERC20wFHE.sol + Upgradeability)
- interfaces/IFHERC20.sol
- interfaces/IFHERC20Errors.sol

Encrypto:

- EncryptoCore.sol (Routing tokens to their encrypted counterpart)
- ConfidentialERC20.sol (FHERC20 wrapper around ERC20 with `encrypt` and `decrypt` functionality)
- ConfidentialERC20NonFHE.sol (ConfidentialERC20.sol functionality without FHE for testing)
- ConfidentialETH.sol (ConfidentialERC20.sol + native ETH -> eETH `encrypt`ing)
- FUSD.sol (FHERC20Upgradeable.sol + `mint` and `burn` integration with Paxos)

---

### Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

### Documentation

https://book.getfoundry.sh/

### Usage

#### Build

```shell
$ forge build
```

#### Test

```shell
$ forge test
```

#### Format

```shell
$ forge fmt
```

#### Gas Snapshots

```shell
$ forge snapshot
```

#### Anvil

```shell
$ anvil
```

#### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

#### Cast

```shell
$ cast <subcommand>
```

#### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
