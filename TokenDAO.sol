// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenDAO is Ownable(msg.sender) {
    struct Proposal {
        uint id;
        string description;
        uint voteCount;
        mapping(address => bool) voters;
    }

    struct Role {
        string name;
        mapping(address => bool) members;
    }

    IERC20 public token;
    mapping(uint => Proposal) public proposals;
    uint public nextProposalId;
    uint public proposalThreshold;

    mapping(bytes32 => Role) private roles;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant MEMBER_ROLE = keccak256("MEMBER");

    modifier onlyRole(bytes32 role) {
        require(roles[role].members[msg.sender], "Access denied: insufficient role");
        _;
    }

    constructor(address tokenAddress, uint _proposalThreshold) {
        token = IERC20(tokenAddress);
        proposalThreshold = _proposalThreshold;
        
        // Add contract deployer as the first admin and member
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(MEMBER_ROLE, msg.sender);
    }

    function _grantRole(bytes32 role, address account) internal {
        roles[role].members[account] = true;
    }

    function grantRole(bytes32 role, address account) external onlyRole(ADMIN_ROLE) {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) external onlyRole(ADMIN_ROLE) {
        roles[role].members[account] = false;
    }

    function hasRole(bytes32 role, address account) external view returns (bool) {
        return roles[role].members[account];
    }

    function addMember(address member) external onlyRole(ADMIN_ROLE) {
        _grantRole(MEMBER_ROLE, member);
    }

    function createProposal(string calldata description) external onlyRole(MEMBER_ROLE) {
        require(token.balanceOf(msg.sender) >= proposalThreshold, "Insufficient token balance to create proposal");
        Proposal storage newProposal = proposals[nextProposalId];
        newProposal.id = nextProposalId;
        newProposal.description = description;
        nextProposalId++;
    }

    function vote(uint proposalId) external onlyRole(MEMBER_ROLE) {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.voters[msg.sender], "Already voted on this proposal");

        uint voterTokens = token.balanceOf(msg.sender);
        require(voterTokens > 0, "No tokens to vote with");

        proposal.voters[msg.sender] = true;
        proposal.voteCount += voterTokens;
    }

    function getProposal(uint proposalId) external view returns (uint, string memory, uint) {
        Proposal storage proposal = proposals[proposalId];
        return (proposal.id, proposal.description, proposal.voteCount);
    }

    function getWinningProposal() external view returns (uint, string memory, uint) {
        uint winningProposalId;
        uint highestVoteCount = 0;
        
        for (uint i = 0; i < nextProposalId; i++) {
            if (proposals[i].voteCount > highestVoteCount) {
                highestVoteCount = proposals[i].voteCount;
                winningProposalId = i;
            }
        }

        Proposal storage winningProposal = proposals[winningProposalId];
        return (winningProposal.id, winningProposal.description, winningProposal.voteCount);
    }
}
