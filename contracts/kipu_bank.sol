// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title Kipu Bank
 * @notice A secure banking smart contract
 * @author Tadini Gabriel
 */
contract KipuBank {
    /*///////////////////////////////////
           State variables
///////////////////////////////////*/
    /// @notice The maximum amount (in wei) a user can withdraw per transaction (immutable).
    uint256 public immutable i_withdrawalThreshold;

    /// @notice The global maximum limit (in wei) the bank contract can hold (immutable).
    uint256 public immutable i_bankCap;

    /// @notice Mapping that stores the ETH balance (in wei) for each user.
    mapping(address user => uint256 value) public s_deposits;

    /// @notice The current total ETH balance deposited in the contract (used to check against bankCap).
    uint256 private s_totalDeposited;

    /// @notice Counter for the total number of successful deposits made.
    uint256 public s_depositCount;

    /// @notice Counter for the total number of successful withdrawals made.
    uint256 public s_withdrawalCount;

    /*///////////////////////////////////
               Events
///////////////////////////////////*/
    /// @notice Event emitted when a user successfully deposits funds.
    event DepositMade(address indexed user, uint256 value);

    /// @notice Event emitted when a user successfully withdraws funds.
    event WithdrawalMade(address indexed user, uint256 value);

    /*///////////////////////////////////
               Errors
///////////////////////////////////*/
    /// @notice Error thrown when a deposit exceeds the global bank cap.
    error KipuBank_GlobalLimitExceeded(
        uint256 bankCap,
        uint256 currentTotal,
        uint256 depositAttempt
    );

    /// @notice Error thrown when a user attempts to withdraw more than their current balance.
    error KipuBank_InsufficientFunds(
        address user,
        uint256 actualBalance,
        uint256 withdrawalAttempt
    );

    /// @notice Error thrown when the withdrawal amount exceeds the per-transaction threshold.
    error KipuBank_ThresholdExceeded(
        uint256 allowedThreshold,
        uint256 withdrawalAttempt
    );

    /// @notice Error thrown when the native ETH transfer operation fails.
    error KipuBank_TransferFailed();

    /*///////////////////////////////////
            Modifiers
///////////////////////////////////*/
    /**
     * @notice Modifier that checks if a proposed withdrawal is valid.
     * @dev Checks that the amount is less than or equal to the threshold and that the user has sufficient funds.
     * @param _amount The amount of ETH (in wei) to validate.
     */
    modifier validWithdrawal(uint256 _amount) {
        // Check: Does the amount exceed the per-transaction threshold?
        if (_amount > i_withdrawalThreshold) {
            revert KipuBank_ThresholdExceeded(i_withdrawalThreshold, _amount);
        }
        // Check: Does the user have enough balance?
        if (_amount > s_deposits[msg.sender]) {
            revert KipuBank_InsufficientFunds(
                msg.sender,
                s_deposits[msg.sender],
                _amount
            );
        }
        _;
    }

    /*///////////////////////////////////
            Functions
///////////////////////////////////*/

    /*///////////////////////////////////
            Constructor
///////////////////////////////////*/
    /**
     * @notice Constructor for the KipuBank contract. Initializes immutable security limits.
     * @param _withdrawalThreshold The maximum amount (in wei) allowed for a single withdrawal transaction.
     * @param _bankCap The maximum total amount of ETH (in wei) the contract can ever hold.
     */
    constructor(uint256 _withdrawalThreshold, uint256 _bankCap) {
        i_withdrawalThreshold = _withdrawalThreshold;
        i_bankCap = _bankCap;
    }

    /*/////////////////////////
        external
/////////////////////////*/
    /**
     * @notice Allows users to deposit native ETH into their personal vault.
     * @dev The function is payable and verifies that the deposit does not exceed the global bankCap.
     */
    function deposit() external payable {
        // CHECKS: Verify the global limit is not exceeded.
        uint256 newTotal = s_totalDeposited + msg.value;
        if (newTotal > i_bankCap) {
            revert KipuBank_GlobalLimitExceeded(
                i_bankCap,
                s_totalDeposited,
                msg.value
            );
        }

        // EFFECTS: Update state variables first (following CEI pattern).
        s_deposits[msg.sender] += msg.value;
        s_totalDeposited = newTotal;
        s_depositCount++;

        emit DepositMade(msg.sender, msg.value);
    }

    /**
     * @notice Allows the user to withdraw a specified amount of ETH from their vault.
     * @dev Uses the validWithdrawal modifier to enforce threshold and balance checks.
     * @param _amount The amount of ETH (in wei) to withdraw.
     */
    function withdraw(uint256 _amount) external validWithdrawal(_amount) {
        // **CHECKS** are now handled by the modifier (validWithdrawal(_amount)) before the function code runs.

        // EFFECTS
        s_deposits[msg.sender] -= _amount;
        s_totalDeposited -= _amount;
        s_withdrawalCount++;

        // NTERACTIONS
        _transferEth(msg.sender, _amount);
        emit WithdrawalMade(msg.sender, _amount);
    }

    /**
     * @notice Returns the ETH balance deposited by the calling user.
     * @dev This is a view function, it does not modify the contract's state.
     * @return The user's ETH balance in wei.
     */
    function getMyBalance() external view returns (uint256) {
        return s_deposits[msg.sender];
    }

    /*/////////////////////////
        private
/////////////////////////*/
    /**
     * @notice Private function to securely transfer native ETH.
     * @dev Uses the low-level call function for gas flexibility and security, and reverts if unsuccessful.
     * @param _recipient The address to which the ETH will be sent.
     * @param _amount The amount of ETH (in wei) to be transferred.
     */
    function _transferEth(address _recipient, uint256 _amount) private {
        (bool success, ) = _recipient.call{value: _amount}("");

        if (!success) {
            revert KipuBank_TransferFailed();
        }
    }

    /*////////////////////////
     Receive & Fallback
/////////////////////////*/
    /**
     * @notice Receive function to accept ETH sent without data (plain ETH transfer).
     * @dev Redirects the incoming ETH to the deposit logic for security checks (bankCap, state update, etc.).
     */
    receive() external payable {
        // Call the external deposit function to apply all checks (bankCap) and effects.
        this.deposit();
    }

    /**
     * @notice Fallback function. Used when a function that doesn't exist is called or when ETH is sent with data.
     * @dev Left empty as no specific logic is required for invalid function calls.
     */
    fallback() external {}
}
