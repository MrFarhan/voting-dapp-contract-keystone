// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title VotingSystem
 * @dev A decentralized voting system with role-based access control
 * @notice This contract allows admins to create elections and registered voters to cast votes
 */
contract VotingSystem is AccessControl, ReentrancyGuard {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct Candidate {
        uint256 id;
        string name;
        string description;
        uint256 voteCount;
    }

    struct Election {
        uint256 id;
        string title;
        string description;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        uint256 totalVotes;
        uint256 candidateCount;
        mapping(uint256 => Candidate) candidates;
        mapping(address => bool) hasVoted;
    }

    uint256 public electionCount;
    mapping(uint256 => Election) public elections;
    
    // Events
    event ElectionCreated(
        uint256 indexed electionId,
        string title,
        uint256 startTime,
        uint256 endTime
    );
    
    event CandidateAdded(
        uint256 indexed electionId,
        uint256 indexed candidateId,
        string name
    );
    
    event VoteCast(
        uint256 indexed electionId,
        uint256 indexed candidateId,
        address indexed voter
    );
    
    event ElectionEnded(uint256 indexed electionId);

    /**
     * @dev Constructor sets the deployer as the default admin
     */
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Modifier to check if election exists
     */
    modifier electionExists(uint256 _electionId) {
        require(_electionId > 0 && _electionId <= electionCount, "Election does not exist");
        _;
    }

    /**
     * @dev Create a new election with candidates
     * @param _title Title of the election
     * @param _description Description of the election
     * @param _startTime Start timestamp of the election
     * @param _endTime End timestamp of the election
     * @param _candidateNames Array of candidate names
     * @param _candidateDescriptions Array of candidate descriptions
     * @return electionId The ID of the newly created election
     */
    function createElection(
        string calldata _title,
        string calldata _description,
        uint256 _startTime,
        uint256 _endTime,
        string[] calldata _candidateNames,
        string[] calldata _candidateDescriptions
    ) external returns (uint256) {
        require(_endTime > _startTime, "End time must be after start time");
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(_candidateNames.length > 0, "Must have at least one candidate");
        require(_candidateNames.length == _candidateDescriptions.length, "Names and descriptions length mismatch");

        electionCount++;
        Election storage newElection = elections[electionCount];
        newElection.id = electionCount;
        newElection.title = _title;
        newElection.description = _description;
        newElection.startTime = _startTime;
        newElection.endTime = _endTime;
        newElection.isActive = true;

        // Add all candidates in the same transaction
        for (uint256 i = 0; i < _candidateNames.length; i++) {
            require(bytes(_candidateNames[i]).length > 0, "Candidate name cannot be empty");
            
            newElection.candidateCount++;
            uint256 candidateId = newElection.candidateCount;
            
            newElection.candidates[candidateId] = Candidate({
                id: candidateId,
                name: _candidateNames[i],
                description: _candidateDescriptions[i],
                voteCount: 0
            });

            emit CandidateAdded(electionCount, candidateId, _candidateNames[i]);
        }

        emit ElectionCreated(electionCount, _title, _startTime, _endTime);
        return electionCount;
    }

    /**
     * @dev Add a candidate to an election
     * @param _electionId ID of the election
     * @param _name Name of the candidate
     * @param _description Description of the candidate
     */
    function addCandidate(
        uint256 _electionId,
        string calldata _name,
        string calldata _description
    ) external electionExists(_electionId) {
        Election storage election = elections[_electionId];
        require(block.timestamp < election.startTime, "Cannot add candidates after election starts");
        require(bytes(_name).length > 0, "Candidate name cannot be empty");

        election.candidateCount++;
        uint256 candidateId = election.candidateCount;
        
        election.candidates[candidateId] = Candidate({
            id: candidateId,
            name: _name,
            description: _description,
            voteCount: 0
        });

        emit CandidateAdded(_electionId, candidateId, _name);
    }

    /**
     * @dev Cast a vote in an election
     * @param _electionId ID of the election
     * @param _candidateId ID of the candidate to vote for
     */
    function vote(
        uint256 _electionId,
        uint256 _candidateId
    ) external electionExists(_electionId) nonReentrant {
        Election storage election = elections[_electionId];
        
        require(election.isActive, "Election is not active");
        require(block.timestamp >= election.startTime, "Election has not started");
        require(block.timestamp <= election.endTime, "Election has ended");
        require(!election.hasVoted[msg.sender], "Already voted in this election");
        require(_candidateId > 0 && _candidateId <= election.candidateCount, "Invalid candidate");

        election.hasVoted[msg.sender] = true;
        election.candidates[_candidateId].voteCount++;
        election.totalVotes++;

        emit VoteCast(_electionId, _candidateId, msg.sender);
    }

    /**
     * @dev End an election manually
     * @param _electionId ID of the election to end
     */
    function endElection(uint256 _electionId) 
        external 
        onlyRole(ADMIN_ROLE) 
        electionExists(_electionId) 
    {
        Election storage election = elections[_electionId];
        require(election.isActive, "Election already ended");
        
        election.isActive = false;
        emit ElectionEnded(_electionId);
    }

    /**
     * @dev Get election details
     * @param _electionId ID of the election
     * @return id Election ID
     * @return title Election title
     * @return description Election description
     * @return startTime Start timestamp
     * @return endTime End timestamp
     * @return isActive Whether election is active
     * @return totalVotes Total votes cast
     * @return candidateCount Number of candidates
     */
    function getElection(uint256 _electionId) 
        external 
        view 
        electionExists(_electionId) 
        returns (
            uint256 id,
            string memory title,
            string memory description,
            uint256 startTime,
            uint256 endTime,
            bool isActive,
            uint256 totalVotes,
            uint256 candidateCount
        ) 
    {
        Election storage election = elections[_electionId];
        return (
            election.id,
            election.title,
            election.description,
            election.startTime,
            election.endTime,
            election.isActive,
            election.totalVotes,
            election.candidateCount
        );
    }

    /**
     * @dev Get candidate details
     * @param _electionId ID of the election
     * @param _candidateId ID of the candidate
     * @return id Candidate ID
     * @return name Candidate name
     * @return description Candidate description
     * @return voteCount Vote count
     */
    function getCandidate(uint256 _electionId, uint256 _candidateId)
        external
        view
        electionExists(_electionId)
        returns (
            uint256 id,
            string memory name,
            string memory description,
            uint256 voteCount
        )
    {
        Election storage election = elections[_electionId];
        require(_candidateId > 0 && _candidateId <= election.candidateCount, "Invalid candidate");
        
        Candidate memory candidate = election.candidates[_candidateId];
        return (
            candidate.id,
            candidate.name,
            candidate.description,
            candidate.voteCount
        );
    }

    /**
     * @dev Get all candidates for an election
     * @param _electionId ID of the election
     * @return Array of all candidates
     */
    function getAllCandidates(uint256 _electionId)
        external
        view
        electionExists(_electionId)
        returns (Candidate[] memory)
    {
        Election storage election = elections[_electionId];
        Candidate[] memory candidateList = new Candidate[](election.candidateCount);
        
        for (uint256 i = 1; i <= election.candidateCount; i++) {
            candidateList[i - 1] = election.candidates[i];
        }
        
        return candidateList;
    }

    /**
     * @dev Check if an address has voted in an election
     * @param _electionId ID of the election
     * @param _voter Address to check
     * @return Whether the address has voted
     */
    function hasVoted(uint256 _electionId, address _voter)
        external
        view
        electionExists(_electionId)
        returns (bool)
    {
        return elections[_electionId].hasVoted[_voter];
    }

    /**
     * @dev Check if an address is a registered voter (deprecated - anyone can vote now)
     * @param _voter Address to check
     * @return Always returns true since anyone can vote
     */
    function isRegisteredVoter(address _voter) external pure returns (bool) {
        return true; // Anyone can vote now
    }

    /**
     * @dev Check if an election is currently ongoing
     * @param _electionId ID of the election
     * @return Whether the election is ongoing
     */
    function isElectionOngoing(uint256 _electionId)
        external
        view
        electionExists(_electionId)
        returns (bool)
    {
        Election storage election = elections[_electionId];
        return (
            election.isActive &&
            block.timestamp >= election.startTime &&
            block.timestamp <= election.endTime
        );
    }

    /**
     * @dev Get the winner(s) of an election
     * @param _electionId ID of the election
     * @return winningCandidateIds Array of candidate IDs with the most votes
     * @return highestVoteCount The highest vote count
     */
    function getWinner(uint256 _electionId)
        external
        view
        electionExists(_electionId)
        returns (uint256[] memory winningCandidateIds, uint256 highestVoteCount)
    {
        Election storage election = elections[_electionId];
        require(!election.isActive || block.timestamp > election.endTime, "Election still ongoing");
        
        // Find highest vote count
        highestVoteCount = 0;
        uint256 winnerCount = 0;
        
        for (uint256 i = 1; i <= election.candidateCount; i++) {
            if (election.candidates[i].voteCount > highestVoteCount) {
                highestVoteCount = election.candidates[i].voteCount;
                winnerCount = 1;
            } else if (election.candidates[i].voteCount == highestVoteCount && highestVoteCount > 0) {
                winnerCount++;
            }
        }
        
        // Collect all winners (handles ties)
        winningCandidateIds = new uint256[](winnerCount);
        uint256 currentIndex = 0;
        
        for (uint256 i = 1; i <= election.candidateCount; i++) {
            if (election.candidates[i].voteCount == highestVoteCount && highestVoteCount > 0) {
                winningCandidateIds[currentIndex] = i;
                currentIndex++;
            }
        }
        
        return (winningCandidateIds, highestVoteCount);
    }
}
