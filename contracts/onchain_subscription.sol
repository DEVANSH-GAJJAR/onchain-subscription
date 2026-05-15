// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title  OnChainSubscription
/// @author Your Name
/// @notice ETH-based recurring subscription with pro-rata refunds on cancel.
/// @dev    Uses checks-effects-interactions throughout to prevent re-entrancy.
contract OnChainSubscription {

    // -------------------------------------------------------------------------
    // State
    // -------------------------------------------------------------------------

    address public owner;

    /// @notice Cost (in wei) for one subscription period.
    uint256 public subscriptionPrice;

    /// @notice Length of one subscription period in seconds.
    uint256 public subscriptionDuration;

    /// @notice Maps subscriber address to the UNIX timestamp their sub expires.
    mapping(address => uint256) public expiresAt;

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    event Subscribed(address indexed subscriber, uint256 expiresAt, uint256 pricePaid);
    event Cancelled(address indexed subscriber, uint256 refundAmount);
    event PriceUpdated(uint256 oldPrice, uint256 newPrice);
    event DurationUpdated(uint256 oldDuration, uint256 newDuration);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Withdrawn(address indexed to, uint256 amount);

    // -------------------------------------------------------------------------
    // Custom errors
    // -------------------------------------------------------------------------

    error InsufficientPayment(uint256 sent, uint256 required);
    error NotSubscribed();
    error NotOwner();
    error ZeroAddress();
    error ZeroValue();
    error TransferFailed();
    error NothingToWithdraw();

    // -------------------------------------------------------------------------
    // Modifiers
    // -------------------------------------------------------------------------

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    /// @param _price     Subscription cost in wei per period.
    /// @param _duration  Period length in seconds (e.g. 30 days = 2_592_000).
    constructor(uint256 _price, uint256 _duration) {
        if (_price == 0) revert ZeroValue();
        if (_duration == 0) revert ZeroValue();
        owner = msg.sender;
        subscriptionPrice = _price;
        subscriptionDuration = _duration;
    }

    // -------------------------------------------------------------------------
    // Subscriber functions
    // -------------------------------------------------------------------------

    /// @notice Subscribe for one period, or extend an active subscription.
    /// @dev    If caller already has an active sub, one period is stacked on
    ///         top of existing expiry. Overpayment is refunded immediately.
    function subscribe() external payable {
        if (msg.value < subscriptionPrice)
            revert InsufficientPayment(msg.value, subscriptionPrice);

        // Refund overpayment
        uint256 excess = msg.value - subscriptionPrice;
        if (excess > 0) _safeTransfer(msg.sender, excess);

        // Stack on existing expiry if still active, otherwise start fresh
        uint256 base = isActive(msg.sender) ? expiresAt[msg.sender] : block.timestamp;
        uint256 newExpiry = base + subscriptionDuration;
        expiresAt[msg.sender] = newExpiry;

        emit Subscribed(msg.sender, newExpiry, subscriptionPrice);
    }

    /// @notice Cancel an active subscription and receive a pro-rata refund.
    /// @dev    Clears expiry BEFORE transfer (checks-effects-interactions).
    function cancel() external {
        uint256 expiry = expiresAt[msg.sender];
        if (expiry <= block.timestamp) revert NotSubscribed();

        uint256 timeLeft = expiry - block.timestamp;
        uint256 refund = (timeLeft * subscriptionPrice) / subscriptionDuration;

        // Effects before interaction
        expiresAt[msg.sender] = 0;

        if (refund > 0) _safeTransfer(msg.sender, refund);

        emit Cancelled(msg.sender, refund);
    }

    // -------------------------------------------------------------------------
    // View helpers
    // -------------------------------------------------------------------------

    /// @notice Returns true when subscriber has a currently active subscription.
    function isActive(address subscriber) public view returns (bool) {
        return expiresAt[subscriber] > block.timestamp;
    }

    /// @notice Seconds remaining on subscriber's plan (0 if expired).
    function timeRemaining(address subscriber) external view returns (uint256) {
        uint256 expiry = expiresAt[subscriber];
        return expiry > block.timestamp ? expiry - block.timestamp : 0;
    }

    /// @notice ETH balance held by this contract.
    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // -------------------------------------------------------------------------
    // Owner functions
    // -------------------------------------------------------------------------

    /// @notice Withdraw all accumulated ETH to `to`.
    function withdraw(address to) external onlyOwner {
        if (to == address(0)) revert ZeroAddress();
        uint256 balance = address(this).balance;
        if (balance == 0) revert NothingToWithdraw();
        emit Withdrawn(to, balance);
        _safeTransfer(to, balance);
    }

    /// @notice Update the price for future subscriptions.
    function setPrice(uint256 newPrice) external onlyOwner {
        if (newPrice == 0) revert ZeroValue();
        emit PriceUpdated(subscriptionPrice, newPrice);
        subscriptionPrice = newPrice;
    }

    /// @notice Update the period duration for future subscriptions.
    function setDuration(uint256 newDuration) external onlyOwner {
        if (newDuration == 0) revert ZeroValue();
        emit DurationUpdated(subscriptionDuration, newDuration);
        subscriptionDuration = newDuration;
    }

    /// @notice Transfer contract ownership to newOwner.
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // -------------------------------------------------------------------------
    // Internal
    // -------------------------------------------------------------------------

    function _safeTransfer(address to, uint256 amount) internal {
        (bool ok, ) = to.call{value: amount}("");
        if (!ok) revert TransferFailed();
    }

    receive() external payable {
        revert("Use subscribe()");
    }

    fallback() external payable {
        revert("Use subscribe()");
    }
}
