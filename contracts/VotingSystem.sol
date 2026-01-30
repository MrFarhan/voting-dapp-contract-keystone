// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title VotingSystem - Bounded Stake Voting (BSV)
 * @dev A decentralized voting system with stake-based vote weighting
 * @notice Combines one-person-one-vote membership with optional stake-based conviction signals
 * 
 * Key Features:
 * - Baseline vote weight of 1.0 for all members
 * - Optional token staking to increase vote weight with diminishing returns
 * - Hard cap at 2.0x maximum vote weight
 * - Formula-based dynamic weight calculation: weight = 1.0 + sqrt(stake / 100)
 * - Membership-gated voting for fairness
 */
contract VotingSystem is AccessControl, ReentrancyGuard {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MEMBER_ROLE = keccak256("MEMBER_ROLE");

    // Staking configuration
    IERC20 public stakingToken;
    uint256 public constant BASE_WEIGHT = 1e18; // 1.0 in wei precision
    uint256 public constant MAX_WEIGHT = 2e18; // 2.0 in wei precision
    uint256 public constant WEIGHT_SCALE = 1e18; // Precision for calculations
    
    // Formula parameter: controls the rate of diminishing returns
    // Higher value = slower growth towards cap
    uint256 public constant DIMINISHING_FACTOR = 100e18; // 100 tokens for moderate growth

    struct Candidate {
        uint256 id;
        string name;
        string description;
        uint256 voteCount; // Weighted vote count (in wei precision)
    }

    struct Election {
        uint256 id;
        string title;
        string description;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        uint256 totalVotes; // Total weighted votes (in wei precision)
        uint256 candidateCount;
        mapping(uint256 => Candidate) candidates;
        mapping(address => bool) hasVoted;
        mapping(address => uint256) voterWeight; // Stores the weight used when voting
    }

    struct StakeInfo {
        uint256 amount;
        uint256 lockedUntil;
    }

    uint256 public electionCount;
    mapping(uint256 => Election) public elections;
    mapping(address => StakeInfo) public stakes;
    
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
        address indexed voter,
        uint256 weight
    );
    
    event ElectionEnded(uint256 indexed electionId);
    
    event Staked(address indexed user, uint256 amount, uint256 totalStaked);
    event Unstaked(address indexed user, uint256 amount, uint256 remaining);
    event MemberAdded(address indexed member);
    event MemberRemoved(address indexed member);

    /**
     * @dev Constructor sets the deployer as the default admin and initializes staking token
     * @param _stakingToken Address of the ERC20 token used for staking
     */
    constructor(address _stakingToken) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(MEMBER_ROLE, msg.sender); // Deployer is a member
        
        stakingToken = IERC20(_stakingToken);
    }

    /**
     * @dev Modifier to check if election exists
     */
    modifier electionExists(uint256 _electionId) {
        require(_electionId > 0 && _electionId <= electionCount, "Election does not exist");
        _;
    }

    /**
     * @dev Modifier to check if caller is a verified member
     */
    modifier onlyMember() {
        require(hasRole(MEMBER_ROLE, msg.sender), "Not a verified member");
        _;
    }

    // ============================================
    // MEMBERSHIP MANAGEMENT
    // ============================================

    /**
     * @dev Add a member to the verified member list
     * @param _member Address to add as member
     */
    function addMember(address _member) external onlyRole(ADMIN_ROLE) {
        require(_member != address(0), "Invalid address");
        _grantRole(MEMBER_ROLE, _member);
        emit MemberAdded(_member);
    }

    /**
     * @dev Add multiple members in batch
     * @param _members Array of addresses to add as members
     */
    function addMembers(address[] calldata _members) external onlyRole(ADMIN_ROLE) {
        for (uint256 i = 0; i < _members.length; i++) {
            require(_members[i] != address(0), "Invalid address");
            _grantRole(MEMBER_ROLE, _members[i]);
            emit MemberAdded(_members[i]);
        }
    }

    /**
     * @dev Remove a member from the verified member list
     * @param _member Address to remove
     */
    function removeMember(address _member) external onlyRole(ADMIN_ROLE) {
        _revokeRole(MEMBER_ROLE, _member);
        emit MemberRemoved(_member);
    }

    /**
     * @dev Check if an address is a verified member
     * @param _account Address to check
     * @return Whether the address is a member
     */
    function isMember(address _account) public view returns (bool) {
        return hasRole(MEMBER_ROLE, _account);
    }

    // ============================================
    // STAKING FUNCTIONS
    // ============================================

    /**
     * @dev Stake tokens to increase vote weight
     * @param _amount Amount of tokens to stake
     */
    function stake(uint256 _amount) external onlyMember nonReentrant {
        require(_amount > 0, "Cannot stake 0 tokens");
        require(address(stakingToken) != address(0), "Staking token not set");
        
        // Transfer tokens from user to contract
        require(
            stakingToken.transferFrom(msg.sender, address(this), _amount),
            "Token transfer failed"
        );
        
        stakes[msg.sender].amount += _amount;
        
        emit Staked(msg.sender, _amount, stakes[msg.sender].amount);
    }

    /**
     * @dev Unstake tokens (can only unstake if not locked)
     * @param _amount Amount of tokens to unstake
     */
    function unstake(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Cannot unstake 0 tokens");
        require(stakes[msg.sender].amount >= _amount, "Insufficient staked amount");
        require(
            block.timestamp >= stakes[msg.sender].lockedUntil,
            "Tokens are locked"
        );
        
        stakes[msg.sender].amount -= _amount;
        
        // Transfer tokens back to user
        require(
            stakingToken.transfer(msg.sender, _amount),
            "Token transfer failed"
        );
        
        emit Unstaked(msg.sender, _amount, stakes[msg.sender].amount);
    }

    /**
     * @dev Calculate vote weight for an address using dynamic formula
     * Formula: weight = 1.0 + sqrt(stake / DIMINISHING_FACTOR)
     * With hard cap at 2.0
     * 
     * This provides:
     * - Baseline of 1.0 for all members
     * - Smooth increase with diminishing returns
     * - Hard cap at 2.0 to prevent excessive influence
     * 
     * Example outcomes:
     * - 0 tokens    → 1.0 weight
     * - 4 tokens    → ~1.2 weight
     * - 16 tokens   → ~1.4 weight
     * - 81 tokens   → ~1.9 weight
     * - 100+ tokens → 2.0 weight (capped)
     * 
     * @param _voter Address to calculate weight for
     * @return weight in wei precision (1e18 = 1.0)
     */
    function calculateVoteWeight(address _voter) public view returns (uint256) {
        if (!isMember(_voter)) {
            return 0; // Non-members cannot vote
        }
        
        uint256 stakedAmount = stakes[_voter].amount;
        
        if (stakedAmount == 0) {
            return BASE_WEIGHT; // 1.0 baseline
        }
        
        // Calculate: boost = sqrt(stake / DIMINISHING_FACTOR)
        // Using: boost = sqrt(stake) / sqrt(DIMINISHING_FACTOR)
        uint256 sqrtStake = sqrt(stakedAmount);
        uint256 sqrtFactor = sqrt(DIMINISHING_FACTOR);
        
        // boost in wei precision
        uint256 boost = (sqrtStake * WEIGHT_SCALE) / sqrtFactor;
        
        // weight = BASE_WEIGHT + boost
        uint256 weight = BASE_WEIGHT + boost;
        
        // Apply hard cap
        if (weight > MAX_WEIGHT) {
            weight = MAX_WEIGHT;
        }
        
        return weight;
    }

    /**
     * @dev Get stake information for an address
     * @param _user Address to query
     * @return amount Staked amount
     * @return lockedUntil Timestamp when tokens can be unstaked
     * @return currentWeight Current vote weight
     */
    function getStakeInfo(address _user) 
        external 
        view 
        returns (
            uint256 amount,
            uint256 lockedUntil,
            uint256 currentWeight
        ) 
    {
        StakeInfo memory stakeInfo = stakes[_user];
        return (
            stakeInfo.amount,
            stakeInfo.lockedUntil,
            calculateVoteWeight(_user)
        );
    }

    /**
     * @dev Square root function using Babylonian method
     * @param x Value to find square root of
     * @return y Square root of x
     */
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        
        uint256 z = (x + 1) / 2;
        y = x;
        
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    // ============================================
    // PROPOSAL/ELECTION MANAGEMENT
    // ============================================

    /**
     * @dev Create a new election (proposal) with candidates
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
    ) external onlyMember returns (uint256) {
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
     * @dev Cast a weighted vote in an election
     * @param _electionId ID of the election
     * @param _candidateId ID of the candidate to vote for
     */
    function vote(
        uint256 _electionId,
        uint256 _candidateId
    ) external onlyMember electionExists(_electionId) nonReentrant {
        Election storage election = elections[_electionId];
        
        require(election.isActive, "Election is not active");
        require(block.timestamp >= election.startTime, "Election has not started");
        require(block.timestamp <= election.endTime, "Election has ended");
        require(!election.hasVoted[msg.sender], "Already voted in this election");
        require(_candidateId > 0 && _candidateId <= election.candidateCount, "Invalid candidate");

        // Calculate voter's weight at time of voting
        uint256 voterWeight = calculateVoteWeight(msg.sender);
        require(voterWeight > 0, "Invalid vote weight");

        // Lock staked tokens until election ends
        if (stakes[msg.sender].amount > 0) {
            if (stakes[msg.sender].lockedUntil < election.endTime) {
                stakes[msg.sender].lockedUntil = election.endTime;
            }
        }

        // Record vote with weight
        election.hasVoted[msg.sender] = true;
        election.voterWeight[msg.sender] = voterWeight;
        election.candidates[_candidateId].voteCount += voterWeight;
        election.totalVotes += voterWeight;

        emit VoteCast(_electionId, _candidateId, msg.sender, voterWeight);
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
     * @return totalVotes Total weighted votes cast
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
     * @dev Get candidate details with weighted vote count
     * @param _electionId ID of the election
     * @param _candidateId ID of the candidate
     * @return id Candidate ID
     * @return name Candidate name
     * @return description Candidate description
     * @return voteCount Weighted vote count (in wei precision)
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
     * @dev Get the vote weight used by a voter in a specific election
     * @param _electionId ID of the election
     * @param _voter Address of the voter
     * @return weight The vote weight used (0 if not voted)
     */
    function getVoterWeight(uint256 _electionId, address _voter)
        external
        view
        electionExists(_electionId)
        returns (uint256)
    {
        return elections[_electionId].voterWeight[_voter];
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
     * @dev Check if an address is a registered voter (member)
     * @param _voter Address to check
     * @return Whether the address is a verified member
     */
    function isRegisteredVoter(address _voter) external view returns (bool) {
        return isMember(_voter);
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
     * @dev Get the winner(s) of an election with weighted votes
     * @param _electionId ID of the election
     * @return winningCandidateIds Array of candidate IDs with the most votes
     * @return highestVoteCount The highest weighted vote count
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
