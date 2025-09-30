**KipuBank - Secure Banking Smart Contract**

This repository contains the KipuBank smart contract, developed using Solidity 0.8.26. KipuBank simulates a basic decentralized bank that allows users to deposit native tokens (ETH) into personal vaults and withdraw them, enforcing strict security limits at both the individual (per-transaction threshold) and global (bank deposit cap) levels.

**Implemented Features and Requirements**

ETH Deposits: deposit() function (external payable).

Global Limit (bankCap): Immutable variable (i_bankCap), checked within deposit().

Withdrawal Threshold: Immutable variable (i_withdrawalThreshold), checked within withdraw().

external payable Function: deposit()

private Function: _transferEth() (handles secure ETH transfer).

external view Function: getMyBalance() (returns the user's current balance).

Custom Errors: Used for all validation (revert) and transfer failure scenarios.

CEI Pattern: Strictly implemented in the withdraw() function.

Safe ETH Handling: Utilization of the low-level .call{value: _amount}("") method in _transferEth.

Counters: s_depositCount and s_withdrawalCount (track total transactions).

Events: DepositMade and WithdrawalMade emitted on successful transactions.

**Deployment and Initialization**

The KipuBank contract requires two parameters upon deployment, as both define immutable security variables:

_withdrawalThreshold: The maximum amount of ETH (in wei) a user can withdraw in a single transaction.

_bankCap: The maximum total amount of ETH (in wei) the KipuBank contract is allowed to hold globally.

**How to Interact with KipuBank**
Details on how to call the primary functions of the contract.

1. Deposit Funds (deposit)
Function Type: external payable

Purpose: Sends ETH to the contract and registers it in the msg.sender's personal vault.

Parameters: None.

Value (msg.value): The amount of ETH (in wei) to deposit.

Fails if: The deposit exceeds the i_bankCap (throws KipuBank_GlobalLimitExceeded).

2. Withdraw Funds (withdraw)
Function Type: external

Purpose: Allows the user to retrieve ETH from their vault.

Parameters:

_amount (uint256): The amount of ETH (in wei) to withdraw.

Fails if:

_amount is greater than i_withdrawalThreshold (throws KipuBank_ThresholdExceeded).

_amount is greater than the user's current balance (throws KipuBank_InsufficientFunds).

The ETH transfer operation fails (throws KipuBank_TransferFailed).

3. Check Balance (getMyBalance)
Function Type: external view

Purpose: Returns the amount of ETH that the msg.sender has deposited.

Parameters: None.

Returns: uint256 (user's balance in wei).

**Deployed Contract Address**

Testnet: 0x642eF544D686B8789B34aC3bEE411a226a71C0A9

Block Explorer: https://sepolia.etherscan.io/address/0x642eF544D686B8789B34aC3bEE411a226a71C0A9#code
