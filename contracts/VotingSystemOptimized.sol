// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title VotingSystemOptimized - Bounded Stake Voting (BSV) - Gas Optimized
 * @dev A decentralized voting system with stake-based vote weighting
 * @notice Combines one-person-one-vote membership with optional stake-based conviction signals
 *
 * Gas Optimizations:
 * - Custom errors instead of require strings
 * - Cached storage reads
 * - Unchecked arithmetic where safe
 * - Optimized struct packing
 * - calldata for external functions
 * - uint256 for all counters (EVM native)
 */
contract VotingSystemOptimized is AccessControl, ReentrancyGuard {
    // ============================================
    // CUSTOM ERRORS (Gas Efficient)
    // ============================================
    error InvalidAddress();
    error NotMember();
    error NotAdmin();
    error ElectionNotFound();
    error InvalidAmount();
    error InsufficientStake();
    error TokensLocked();
    error TokenTransferFailed();
    error InvalidElectionTime();
    error EmptyTitle();
    error NoCandidates();
    error ArrayLengthMismatch();
    error EmptyCandidateName();
    error CannotModifyAfterStart();
    error ElectionInactive();
    error ElectionNotStarted();
    error ElectionHasEnded();
    error AlreadyVoted();
    error InvalidCandidate();
    error InvalidVoteWeight();
    error ElectionAlreadyEnded();
    error ElectionStillOngoing();

    // ============================================
    // STATE VARIABLES
    // ============================================
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MEMBER_ROLE = keccak256("MEMBER_ROLE");

    IERC20 public immutable stakingToken; // immutable saves gas

    // Constants
    uint256 private constant BASE_WEIGHT = 1e18; // 1.0 in wei precision
    uint256 private constant MAX_WEIGHT = 2e18; // 2.0 in wei precision
    uint256 private constant WEIGHT_SCALE = 1e18;
    uint256 private constant DIMINISHING_FACTOR = 100e18;

    // Optimized struct packing (order by size for storage efficiency)
    struct Candidate {
        uint256 voteCount; // Weighted vote count (in wei precision)
        string name;
        string description;
    }

    struct Election {
        uint256 startTime;
        uint256 endTime;
        uint256 totalVotes; // Total weighted votes
        uint256 candidateCount;
        string title;
        string description;
        bool isActive;
        mapping(uint256 => Candidate) candidates;
        mapping(address => bool) hasVoted;
        mapping(address => uint256) voterWeight;
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

    constructor(address _stakingToken) {
        if (_stakingToken == address(0)) revert InvalidAddress();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(MEMBER_ROLE, msg.sender);

        stakingToken = IERC20(_stakingToken);
    }

    modifier onlyMember() {
        if (!hasRole(MEMBER_ROLE, msg.sender)) revert NotMember();
        _;
    }

    modifier electionExists(uint256 _electionId) {
        if (_electionId == 0 || _electionId > electionCount)
            revert ElectionNotFound();
        _;
    }

    // ============================================
    // MEMBERSHIP MANAGEMENT
    // ============================================

    function addMember(address _member) external onlyRole(ADMIN_ROLE) {
        if (_member == address(0)) revert InvalidAddress();
        _grantRole(MEMBER_ROLE, _member);
        emit MemberAdded(_member);
    }

    function addMembers(
        address[] calldata _members
    ) external onlyRole(ADMIN_ROLE) {
        uint256 length = _members.length;
        for (uint256 i; i < length; ) {
            address member = _members[i];
            if (member == address(0)) revert InvalidAddress();
            _grantRole(MEMBER_ROLE, member);
            emit MemberAdded(member);

            unchecked {
                ++i;
            } // Safe: i < length
        }
    }

    function removeMember(address _member) external onlyRole(ADMIN_ROLE) {
        _revokeRole(MEMBER_ROLE, _member);
        emit MemberRemoved(_member);
    }

    function isMember(address _account) public view returns (bool) {
        return hasRole(MEMBER_ROLE, _account);
    }

    // ============================================
    // STAKING FUNCTIONS
    // ============================================

    function stake(uint256 _amount) external onlyMember nonReentrant {
        if (_amount == 0) revert InvalidAmount();

        // Cache storage read
        StakeInfo storage userStake = stakes[msg.sender];

        if (!stakingToken.transferFrom(msg.sender, address(this), _amount)) {
            revert TokenTransferFailed();
        }

        unchecked {
            userStake.amount += _amount; // Safe: checked by ERC20 transfer
        }

        emit Staked(msg.sender, _amount, userStake.amount);
    }

    function unstake(uint256 _amount) external nonReentrant {
        if (_amount == 0) revert InvalidAmount();

        StakeInfo storage userStake = stakes[msg.sender];
        if (userStake.amount < _amount) revert InsufficientStake();
        if (block.timestamp < userStake.lockedUntil) revert TokensLocked();

        unchecked {
            userStake.amount -= _amount; // Safe: checked above
        }

        if (!stakingToken.transfer(msg.sender, _amount)) {
            revert TokenTransferFailed();
        }

        emit Unstaked(msg.sender, _amount, userStake.amount);
    }

    function calculateVoteWeight(address _voter) public view returns (uint256) {
        if (!isMember(_voter)) return 0;

        uint256 stakedAmount = stakes[_voter].amount;
        if (stakedAmount == 0) return BASE_WEIGHT;

        uint256 sqrtStake = sqrt(stakedAmount);
        uint256 sqrtFactor = sqrt(DIMINISHING_FACTOR);

        unchecked {
            uint256 boost = (sqrtStake * WEIGHT_SCALE) / sqrtFactor;
            uint256 weight = BASE_WEIGHT + boost;

            return weight > MAX_WEIGHT ? MAX_WEIGHT : weight;
        }
    }

    function getStakeInfo(
        address _user
    )
        external
        view
        returns (uint256 amount, uint256 lockedUntil, uint256 currentWeight)
    {
        StakeInfo memory stakeInfo = stakes[_user];
        return (
            stakeInfo.amount,
            stakeInfo.lockedUntil,
            calculateVoteWeight(_user)
        );
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;

        uint256 z = (x + 1) >> 1; // Divide by 2 using bit shift (cheaper)
        y = x;

        while (z < y) {
            y = z;
            z = (x / z + z) >> 1;
        }
    }

    // ============================================
    // ELECTION MANAGEMENT
    // ============================================

    function createElection(
        string calldata _title,
        string calldata _description,
        uint256 _startTime,
        uint256 _endTime,
        string[] calldata _candidateNames,
        string[] calldata _candidateDescriptions
    ) external onlyMember returns (uint256) {
        if (_endTime <= _startTime) revert InvalidElectionTime();
        if (bytes(_title).length == 0) revert EmptyTitle();

        uint256 candidateLength = _candidateNames.length;
        if (candidateLength == 0) revert NoCandidates();
        if (candidateLength != _candidateDescriptions.length)
            revert ArrayLengthMismatch();

        unchecked {
            ++electionCount; // Safe: unlikely to overflow
        }

        Election storage newElection = elections[electionCount];
        newElection.title = _title;
        newElection.description = _description;
        newElection.startTime = _startTime;
        newElection.endTime = _endTime;
        newElection.isActive = true;

        for (uint256 i; i < candidateLength; ) {
            if (bytes(_candidateNames[i]).length == 0)
                revert EmptyCandidateName();

            unchecked {
                ++newElection.candidateCount; // Safe: limited by array length
            }
            uint256 candidateId = newElection.candidateCount;

            Candidate storage candidate = newElection.candidates[candidateId];
            candidate.name = _candidateNames[i];
            candidate.description = _candidateDescriptions[i];

            emit CandidateAdded(electionCount, candidateId, _candidateNames[i]);

            unchecked {
                ++i;
            }
        }

        emit ElectionCreated(electionCount, _title, _startTime, _endTime);
        return electionCount;
    }

    function addCandidate(
        uint256 _electionId,
        string calldata _name,
        string calldata _description
    ) external electionExists(_electionId) {
        Election storage election = elections[_electionId];
        if (block.timestamp >= election.startTime)
            revert CannotModifyAfterStart();
        if (bytes(_name).length == 0) revert EmptyCandidateName();

        unchecked {
            ++election.candidateCount;
        }
        uint256 candidateId = election.candidateCount;

        Candidate storage candidate = election.candidates[candidateId];
        candidate.name = _name;
        candidate.description = _description;

        emit CandidateAdded(_electionId, candidateId, _name);
    }

    function vote(
        uint256 _electionId,
        uint256 _candidateId
    ) external onlyMember electionExists(_electionId) nonReentrant {
        Election storage election = elections[_electionId];

        if (!election.isActive) revert ElectionInactive();
        if (block.timestamp < election.startTime) revert ElectionNotStarted();
        if (block.timestamp > election.endTime) revert ElectionHasEnded();
        if (election.hasVoted[msg.sender]) revert AlreadyVoted();
        if (_candidateId == 0 || _candidateId > election.candidateCount)
            revert InvalidCandidate();

        uint256 voterWeight = calculateVoteWeight(msg.sender);
        if (voterWeight == 0) revert InvalidVoteWeight();

        // Lock stakes - cache storage read
        StakeInfo storage userStake = stakes[msg.sender];
        if (userStake.amount > 0 && userStake.lockedUntil < election.endTime) {
            userStake.lockedUntil = election.endTime;
        }

        election.hasVoted[msg.sender] = true;
        election.voterWeight[msg.sender] = voterWeight;

        unchecked {
            election.candidates[_candidateId].voteCount += voterWeight; // Safe: weight is capped
            election.totalVotes += voterWeight;
        }

        emit VoteCast(_electionId, _candidateId, msg.sender, voterWeight);
    }

    function endElection(
        uint256 _electionId
    ) external onlyRole(ADMIN_ROLE) electionExists(_electionId) {
        Election storage election = elections[_electionId];
        if (!election.isActive) revert ElectionAlreadyEnded();

        election.isActive = false;
        emit ElectionEnded(_electionId);
    }

    // ============================================
    // VIEW FUNCTIONS
    // ============================================

    function getElection(
        uint256 _electionId
    )
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
            _electionId,
            election.title,
            election.description,
            election.startTime,
            election.endTime,
            election.isActive,
            election.totalVotes,
            election.candidateCount
        );
    }

    function getCandidate(
        uint256 _electionId,
        uint256 _candidateId
    )
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
        if (_candidateId == 0 || _candidateId > election.candidateCount)
            revert InvalidCandidate();

        Candidate storage candidate = election.candidates[_candidateId];
        return (
            _candidateId,
            candidate.name,
            candidate.description,
            candidate.voteCount
        );
    }

    function getAllCandidates(
        uint256 _electionId
    ) external view electionExists(_electionId) returns (Candidate[] memory) {
        Election storage election = elections[_electionId];
        uint256 count = election.candidateCount;
        Candidate[] memory candidateList = new Candidate[](count);

        for (uint256 i = 1; i <= count; ) {
            candidateList[i - 1] = election.candidates[i];
            unchecked {
                ++i;
            }
        }

        return candidateList;
    }

    function getVoterWeight(
        uint256 _electionId,
        address _voter
    ) external view electionExists(_electionId) returns (uint256) {
        return elections[_electionId].voterWeight[_voter];
    }

    function hasVoted(
        uint256 _electionId,
        address _voter
    ) external view electionExists(_electionId) returns (bool) {
        return elections[_electionId].hasVoted[_voter];
    }

    function isRegisteredVoter(address _voter) external view returns (bool) {
        return isMember(_voter);
    }

    function isElectionOngoing(
        uint256 _electionId
    ) external view electionExists(_electionId) returns (bool) {
        Election storage election = elections[_electionId];
        return (election.isActive &&
            block.timestamp >= election.startTime &&
            block.timestamp <= election.endTime);
    }

    function getWinner(
        uint256 _electionId
    )
        external
        view
        electionExists(_electionId)
        returns (uint256[] memory winningCandidateIds, uint256 highestVoteCount)
    {
        Election storage election = elections[_electionId];
        if (election.isActive && block.timestamp <= election.endTime) {
            revert ElectionStillOngoing();
        }

        highestVoteCount = 0;
        uint256 winnerCount = 0;
        uint256 candidateCount = election.candidateCount;

        // First pass: find highest vote count
        for (uint256 i = 1; i <= candidateCount; ) {
            uint256 voteCount = election.candidates[i].voteCount;
            if (voteCount > highestVoteCount) {
                highestVoteCount = voteCount;
                winnerCount = 1;
            } else if (voteCount == highestVoteCount && highestVoteCount > 0) {
                unchecked {
                    ++winnerCount;
                }
            }
            unchecked {
                ++i;
            }
        }

        // Second pass: collect winners
        winningCandidateIds = new uint256[](winnerCount);
        uint256 currentIndex;

        for (uint256 i = 1; i <= candidateCount; ) {
            if (
                election.candidates[i].voteCount == highestVoteCount &&
                highestVoteCount > 0
            ) {
                winningCandidateIds[currentIndex] = i;
                unchecked {
                    ++currentIndex;
                }
            }
            unchecked {
                ++i;
            }
        }

        return (winningCandidateIds, highestVoteCount);
    }
}
