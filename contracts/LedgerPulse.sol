// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title LedgerPulse
 * @dev Simple on-chain accounting ledger that records labeled credit/debit entries per address
 * @notice Tracks running balances and emits events for each ledger pulse (entry)
 */
contract LedgerPulse {
    address public owner;

    enum EntryType {
        Credit,
        Debit
    }

    struct Entry {
        uint256 id;
        EntryType entryType;
        int256 amount;        // positive for credit, negative for debit in view context
        uint256 absolute;     // absolute amount in wei
        string  label;        // e.g. "deposit", "service-fee", "airdrop"
        uint256 timestamp;
    }

    // user => current balance (can be negative for logical tracking, does not move ETH)
    mapping(address => int256) public balances;

    // user => entries
    mapping(address => Entry[]) public entriesOf;

    // global incremental id
    uint256 public nextEntryId;

    event EntryRecorded(
        address indexed account,
        uint256 indexed id,
        EntryType entryType,
        uint256 absolute,
        int256 newBalance,
        string label,
        uint256 timestamp
    );

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Record a credit entry for an account (owner-controlled)
     * @param account Address to credit
     * @param amount Amount in wei
     * @param label Label/description
     */
    function credit(
        address account,
        uint256 amount,
        string calldata label
    ) external onlyOwner {
        require(account != address(0), "Zero address");
        require(amount > 0, "Amount = 0");

        int256 delta = int256(amount);
        balances[account] += delta;

        uint256 id = nextEntryId++;
        entriesOf[account].push(
            Entry({
                id: id,
                entryType: EntryType.Credit,
                amount: delta,
                absolute: amount,
                label: label,
                timestamp: block.timestamp
            })
        );

        emit EntryRecorded(
            account,
            id,
            EntryType.Credit,
            amount,
            balances[account],
            label,
            block.timestamp
        );
    }

    /**
     * @dev Record a debit entry for an account (owner-controlled)
     * @param account Address to debit
     * @param amount Amount in wei
     * @param label Label/description
     */
    function debit(
        address account,
        uint256 amount,
        string calldata label
    ) external onlyOwner {
        require(account != address(0), "Zero address");
        require(amount > 0, "Amount = 0");

        int256 delta = -int256(amount);
        balances[account] += delta;

        uint256 id = nextEntryId++;
        entriesOf[account].push(
            Entry({
                id: id,
                entryType: EntryType.Debit,
                amount: delta,
                absolute: amount,
                label: label,
                timestamp: block.timestamp
            })
        );

        emit EntryRecorded(
            account,
            id,
            EntryType.Debit,
            amount,
            balances[account],
            label,
            block.timestamp
        );
    }

    /**
     * @dev Public helper for accounts to read their full entry history
     * @param account Address to query
     * @return Array of Entry structs
     */
    function getEntries(address account)
        external
        view
        returns (Entry[] memory)
    {
        return entriesOf[account];
    }

    /**
     * @dev Transfer contract ownership
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        address prev = owner;
        owner = newOwner;
        emit OwnershipTransferred(prev, newOwner);
    }
}
