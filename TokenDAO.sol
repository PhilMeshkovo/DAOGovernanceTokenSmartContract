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

    IERC20 public token;
    mapping(uint => Proposal) public proposals;
    uint public nextProposalId;
    mapping(address => bool) public members;
    uint public proposalThreshold;

    modifier onlyMember() {
        require(members[msg.sender], "Only DAO members can call this function");
        _;
    }

    constructor(address tokenAddress, uint _proposalThreshold) {
        token = IERC20(tokenAddress);
        members[msg.sender] = true;
        proposalThreshold = _proposalThreshold;
    }

    function addMember(address member) external onlyOwner {
        members[member] = true;
    }

    function createProposal(string calldata description) external onlyMember {
        require(token.balanceOf(msg.sender) >= proposalThreshold, "Insufficient token balance to create proposal");
        Proposal storage newProposal = proposals[nextProposalId];
        newProposal.id = nextProposalId;
        newProposal.description = description;
        nextProposalId++;
    }

    function vote(uint proposalId) external onlyMember {
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
}
