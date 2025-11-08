// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title LedgerPulse
 * @dev A real-time transaction monitoring and analytics system with pulse scoring
 */
contract LedgerPulse {
    struct Transaction {
        address sender;
        address receiver;
        uint256 amount;
        uint256 timestamp;
        string category;
        bytes32 txHash;
    }
    
    struct PulseScore {
        uint256 totalTransactions;
        uint256 totalVolume;
        uint256 score;
        uint256 lastUpdate;
        uint256 reputation;
    }
    
    mapping(address => PulseScore) public pulseScores;
    mapping(bytes32 => Transaction) public transactions;
    mapping(address => bytes32[]) public userTransactions;
    
    bytes32[] public allTransactionHashes;
    uint256 public totalSystemVolume;
    
    event PulseRecorded(bytes32 indexed txHash, address indexed sender, address indexed receiver, uint256 amount);
    event ScoreUpdated(address indexed user, uint256 newScore, uint256 reputation);
    
    function recordPulse(address receiver) external payable {
        require(msg.value > 0, "Amount must be greater than 0");
        require(receiver != address(0), "Invalid receiver");
        
        bytes32 txHash = keccak256(abi.encodePacked(
            msg.sender,
            receiver,
            msg.value,
            block.timestamp,
            allTransactionHashes.length
        ));
        
        string memory category = _determineCategory(msg.value);
        
        transactions[txHash] = Transaction({
            sender: msg.sender,
            receiver: receiver,
            amount: msg.value,
            timestamp: block.timestamp,
            category: category,
            txHash: txHash
        });
        
        allTransactionHashes.push(txHash);
        userTransactions[msg.sender].push(txHash);
        userTransactions[receiver].push(txHash);
        
        _updatePulseScore(msg.sender, msg.value);
        _updatePulseScore(receiver, msg.value);
        
        totalSystemVolume += msg.value;
        
        payable(receiver).transfer(msg.value);
        
        emit PulseRecorded(txHash, msg.sender, receiver, msg.value);
    }
    
    function _determineCategory(uint256 amount) internal pure returns (string memory) {
        if (amount < 0.01 ether) return "Micro";
        if (amount < 0.1 ether) return "Small";
        if (amount < 1 ether) return "Medium";
        if (amount < 10 ether) return "Large";
        return "Whale";
    }
    
    function _updatePulseScore(address user, uint256 amount) internal {
        PulseScore storage pulse = pulseScores[user];
        pulse.totalTransactions++;
        pulse.totalVolume += amount;
        pulse.lastUpdate = block.timestamp;
        
        pulse.score = (pulse.totalTransactions * 10) + (pulse.totalVolume / 1 ether);
        pulse.reputation = pulse.totalTransactions / 10;
        
        emit ScoreUpdated(user, pulse.score, pulse.reputation);
    }
    
    function getPulseScore(address user) external view returns (
        uint256 totalTransactions,
        uint256 totalVolume,
        uint256 score,
        uint256 reputation
    ) {
        PulseScore memory pulse = pulseScores[user];
        return (
            pulse.totalTransactions,
            pulse.totalVolume,
            pulse.score,
            pulse.reputation
        );
    }
    
    function getMyPulseScore() external view returns (
        uint256 totalTransactions,
        uint256 totalVolume,
        uint256 score,
        uint256 reputation
    ) {
        PulseScore memory pulse = pulseScores[msg.sender];
        return (
            pulse.totalTransactions,
            pulse.totalVolume,
            pulse.score,
            pulse.reputation
        );
    }
    
    function getUserTransactions(address user) external view returns (bytes32[] memory) {
        return userTransactions[user];
    }
    
    function getMyTransactions() external view returns (bytes32[] memory) {
        return userTransactions[msg.sender];
    }
    
    function getTransaction(bytes32 txHash) external view returns (
        address sender,
        address receiver,
        uint256 amount,
        uint256 timestamp,
        string memory category
    ) {
        Transaction memory txn = transactions[txHash];
        return (
            txn.sender,
            txn.receiver,
            txn.amount,
            txn.timestamp,
            txn.category
        );
    }
    
    function getSystemStats() external view returns (
        uint256 totalTransactions,
        uint256 systemVolume
    ) {
        return (allTransactionHashes.length, totalSystemVolume);
    }
    
    function getRecentTransactions(uint256 count) external view returns (bytes32[] memory) {
        uint256 length = allTransactionHashes.length;
        uint256 resultCount = count > length ? length : count;
        bytes32[] memory recent = new bytes32[](resultCount);
        
        for (uint256 i = 0; i < resultCount; i++) {
            recent[i] = allTransactionHashes[length - 1 - i];
        }
        
        return recent;
    }
}
// 
End
// 
