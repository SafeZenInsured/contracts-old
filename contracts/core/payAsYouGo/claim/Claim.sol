// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./../../../../interfaces/IERC20.sol";
import "./../../../dependencies/openzeppelin/Ownable.sol";
import "./../../../dependencies/openzeppelin/Pausable.sol";

/// @title Insurance Claim Governance
/// @author Anshik Bansal <anshik@safezen.finance>

/// Report any bug or issues at:
/// @custom:security-contact anshik@safezen.finance
contract ClaimGovernance is Ownable, Pausable{
    uint256 private _claimID;
    uint256 private _openClaimsCount;
    uint256 private constant VOTING_END_TIME = 48 hours; // voting duration
    uint256 private constant TIME_BEFORE_VOTING_START = 6 hours; // to notify the users about voting
    uint256 private constant AFTER_VOTING_WAIT_PERIOD = 12 hours; // time to challenge the decision
    IERC20 private _safezenGovernanceToken;

    struct Claim {
        address claimer;
        uint256 claimID;  // not needed thou, but nice to have 
        uint256 protocolID;
        uint256 claimAmountRequested;
        string proof;  // IPFS link or some storage link, where proof is stored
        bool closed;
        bool accepted;
        bool isChallenged;
        mapping(uint256 => VotingInfo) votingInfo; 
        mapping(address => Receipt) receipts;
    }

    struct VotingInfo {
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 advisorForVotes;
        uint256 advisorAgainstVotes;
        uint256 votingCounts;  // no of times decision has been challenged
    }

    struct Receipt {
        bool hasVoted;
        bool support;
        uint256 votes;
    }

    mapping(address => bool) isAdvisor;

    /// @notice The official record of all claims ever made
    mapping (uint256 => Claim) public claims;

    /// @notice The latest claim for each individual claimer
    /// if a user have filed most claims, then the protocol that user invests are generally risky
    mapping (address => uint256) public individualClaims;

    /// @notice mapping the protocol specific claims count to date
    /// more the number, more the risky the platform will be
    mapping (uint256 => uint256) protocolSpecificClaims;

    error VotingTimeEndedError();
    error UserAlreadyVotedError();
    error DecisionChallengedError();
    error VotingNotYetStartedError();
    error DecisionNotYetTakenError();
    error VotingDecisionNotYetFinalizedError();
    error DecisionNoLongerCanBeChallengedError();
    
    /// @dev in case if certain claim require additional time for DAO, 
    /// for e.g., awaiting additional inputs to reserve their decisions 
    function updateVotingEndTime(uint256 claimID, uint256 timeInHours) external onlyOwner {
        claims[claimID].votingInfo[claimID].votingEndTime = timeInHours * 1 hours;
    }

    function setSafeZenGovernanceTokenAddress(address safezenGovernanceTokenAddress) external onlyOwner {
        _safezenGovernanceToken = IERC20(safezenGovernanceTokenAddress);
    }

    function updateAdvisors(address userAddress) external onlyOwner {
        isAdvisor[userAddress] = true;
    }

    function createClaim(
        uint256 protocolID, 
        string memory proof, 
        uint256 requestedClaimAmount
    ) public {
        ++_claimID;
        Claim storage newClaim = claims[_claimID];
        newClaim.protocolID = protocolID;
        newClaim.claimID = _claimID;
        newClaim.claimer = _msgSender();
        newClaim.proof = proof;
        newClaim.claimAmountRequested = requestedClaimAmount;
        newClaim.votingInfo[_claimID].votingStartTime = block.timestamp + TIME_BEFORE_VOTING_START;
        newClaim.votingInfo[_claimID].votingEndTime = newClaim.votingInfo[_claimID].votingStartTime + VOTING_END_TIME;
        ++individualClaims[_msgSender()];
        ++protocolSpecificClaims[protocolID];
        ++_openClaimsCount;
        pause();
    }
     
    
    function vote(uint256 claimID, bool support) external {
        /// checks are made in order
        /// 1. making sure voting time has started
        /// 2. has the user voted or not
        /// 3. if not, whether the user is voting within the voting time limit
        if (claims[claimID].votingInfo[claimID].votingStartTime > block.timestamp) {
            revert VotingNotYetStartedError();
        }
        if (claims[claimID].receipts[_msgSender()].hasVoted) {
            revert UserAlreadyVotedError();
        }
        if (claims[claimID].votingInfo[claimID].votingEndTime < block.timestamp) {
            revert VotingTimeEndedError();
        }
        claims[claimID].receipts[_msgSender()].support = support;
        claims[claimID].receipts[_msgSender()].votes = _safezenGovernanceToken.balanceOf(_msgSender());
        claims[claimID].receipts[_msgSender()].hasVoted = true;

        if ((isAdvisor[_msgSender()]) && (claims[claimID].votingInfo[claimID].votingCounts == 2)) {
            if (support) {
                claims[claimID].votingInfo[claimID].advisorForVotes += claims[claimID].receipts[_msgSender()].votes;
            }
            else {
                claims[claimID].votingInfo[claimID].advisorAgainstVotes += claims[claimID].receipts[_msgSender()].votes;
            }
        }
        else {
            if (support) {
                claims[claimID].votingInfo[claimID].forVotes += claims[claimID].receipts[_msgSender()].votes;
            }
            else {
                claims[claimID].votingInfo[claimID].againstVotes += claims[claimID].receipts[_msgSender()].votes;
            }
        }
    }

    function claimDecision(uint256 claimID) external {
        if (claims[claimID].votingInfo[claimID].votingEndTime + AFTER_VOTING_WAIT_PERIOD > block.timestamp) {
            revert VotingDecisionNotYetFinalizedError();
        }
        if (claims[claimID].isChallenged) {
            revert DecisionChallengedError();
        }
        uint256 totalCommunityVotes = claims[claimID].votingInfo[claimID].forVotes + claims[claimID].votingInfo[claimID].againstVotes;
        if (claims[claimID].votingInfo[claimID].votingCounts == 2) {
            uint256 totalAdvisorVotes = claims[claimID].votingInfo[claimID].advisorForVotes + claims[claimID].votingInfo[claimID].advisorAgainstVotes;
            uint256 forAdvisorVotesEligible = (claims[claimID].votingInfo[claimID].advisorForVotes >= claims[claimID].votingInfo[claimID].advisorAgainstVotes) ? ((claims[_claimID].votingInfo[_claimID].forVotes * 100) / totalAdvisorVotes) : 0;
            /// even if all the community votes are in favor, but, 49% of the voting power will be 
            /// given to the advisors in the final claim decision round.
            /// Community --> (100 * 0.51) = 51%    Advisors -->  (60 * 0.49) = 29.4%
            /// Total  = 51% + 29.4% < 80% (needed to get approved)
            /// keeping >= 59 because of underflow value in forAdvisorVotesEligible
            if (forAdvisorVotesEligible >= 59) {
                uint256 forVotesEligible = (claims[claimID].votingInfo[claimID].forVotes > claims[claimID].votingInfo[claimID].againstVotes) ? ((claims[claimID].votingInfo[claimID].forVotes * 100) / totalCommunityVotes) : 1;
                uint256 supportPercent = ((forAdvisorVotesEligible * 49) / 100) + ((forVotesEligible * 51) / 100);
                claims[claimID].accepted = (supportPercent >= 80) ? true : false;
            }
            else {
                claims[claimID].accepted = false;
            }
        }
        else {
            uint256 forVotesEligible = (claims[claimID].votingInfo[claimID].forVotes > claims[claimID].votingInfo[claimID].againstVotes) ? ((claims[claimID].votingInfo[claimID].forVotes * 100) / totalCommunityVotes) : 1;
            claims[claimID].accepted = (forVotesEligible >= 80) ? true : false;
        }
        claims[claimID].closed = true;
        --_openClaimsCount;
        if (_openClaimsCount == 0) {
            unpause();
        }
    }

    
    function challengeDecision(uint256 claimID) external {
        if ((!claims[claimID].closed) || (!claims[claimID].isChallenged)) {
            revert DecisionNotYetTakenError();
        }
        if (claims[claimID].votingInfo[claimID].votingCounts >= 2) {
            revert DecisionNoLongerCanBeChallengedError();
        }
        claims[claimID].isChallenged = true;
        createClaim(
            claims[claimID].protocolID,
            claims[claimID].proof,
            claims[claimID].claimAmountRequested
        );
        ++claims[_claimID].votingInfo[_claimID].votingCounts; 
        // ^ global claimID, as the latest claim refers to challenged claim
    }

    function pause() internal {
        _pause();
    }

    function unpause() internal {
        _unpause();
    }

    function viewVoteReceipt(uint256 claimID) external view returns(bool, bool, uint256) {
        return (
            claims[claimID].receipts[_msgSender()].hasVoted,
            claims[claimID].receipts[_msgSender()].support,
            claims[claimID].receipts[_msgSender()].votes
        );
    }
}