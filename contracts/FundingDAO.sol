// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/IFundingNFT.sol";

error NotHaveRightToVote();
error ProposalIsNotActive();
error ProposalStillActive();
error onlyLeaderCall();
error NotCommunityMember();
error AlreadyVoted();

contract FundingDAO {
    struct Community {
        uint256 id;
        string name;
        string description;
        address leader;
        address[] members;
    }

    struct Proposal {
        uint256 id;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 deadline; // Deadline of the proposal.
        uint256 requiredBudget; // Budget needed to implement.
        string description;
        Community community; // Id to Community.
        mapping(address => bool) voters;
        bool executed;
    }

    enum Vote {
        YES,
        NO
    }

    uint256 proposalCounts;
    mapping(uint256 => Proposal) public proposals;

    uint256 communityCounts;
    mapping(uint256 => Community) public communities;
    mapping(address => Community) public communityMembers;
    /**
     *  Community Id To Proposal array.
     *  Let users know, which proposals who created.
     */
    mapping(uint256 => Proposal[]) public communityIdToProposals;
    IFundingNFT fundingNFT;

    event memberLeftTheCommunity(address member);
    event communityCreated(uint256 index);
    event proposalCreated(uint256 index);

    modifier nftHolderOnly() {
        if (fundingNFT.balanceOf(msg.sender) > 0) revert NotHaveRightToVote();
        _;
    }

    modifier activeProposals(uint256 _proposalIndex) {
        if (block.timestamp > (proposals[_proposalIndex].deadline))
            revert ProposalIsNotActive();
        _;
    }

    modifier onlyLeader() {
        if (!fundingNFT.isLeader(msg.sender)) revert onlyLeaderCall();
        _;
    }

    modifier onlyMembers(uint256 communityId) {
        if (communityMembers[msg.sender].id != communityId)
            revert NotCommunityMember();
        _;
    }

    modifier activeProposal(uint256 proposalIndex) {
        if (block.timestamp < proposals[proposalIndex].deadline)
            revert ProposalIsNotActive();
        _;
    }

    modifier finishedProposal(uint256 proposalIndex) {
        if (block.timestamp > proposals[proposalIndex].deadline)
            revert ProposalStillActive();
        _;
    }

    constructor(address _fundingNFT) {
        fundingNFT = IFundingNFT(_fundingNFT);
    }

    function createCommunity(string memory _name, string memory _description)
        external
        onlyLeader
    {
        Community storage newCommunity = communities[communityCounts];
        newCommunity.id = communityCounts;
        newCommunity.name = _name;
        newCommunity.description = _description;
        newCommunity.leader = msg.sender;
        communityMembers[msg.sender] = newCommunity;
        emit communityCreated(communityCounts);
        communityCounts++;
    }

    function addMembersToCommunity(address[] calldata memberAddresses)
        external
        onlyLeader
    {
        fundingNFT.setMembers(memberAddresses);
        for (uint256 i; i < memberAddresses.length; i++) {
            communityMembers[msg.sender].members.push(memberAddresses[i]);
        }
    }

    function leftTheCommunity(uint256 communityId)
        external
        onlyMembers(communityId)
    {
        fundingNFT.exitTheCommunity();
        delete communityMembers[msg.sender];
    }

    function transferLeadership(address newLeader, uint256 index)
        external
        onlyLeader
    {
        delete communityMembers[msg.sender];
        communities[index].leader = newLeader;
        fundingNFT.transferLeadership(newLeader);
    }

    function createProposal(uint256 _requiredBudget, string memory _desc)
        external
        onlyLeader
    {
        Proposal storage newProposal = proposals[proposalCounts];
        newProposal.id = proposalCounts;
        newProposal.deadline = block.timestamp + 5 minutes; // it is for tests
        newProposal.requiredBudget = _requiredBudget;
        newProposal.description = _desc;
        newProposal.community = communityMembers[msg.sender];
        emit proposalCreated(proposalCounts);
        proposalCounts++;
    }

    function voteToProposal(uint256 proposalIndex, Vote vote)
        external
        activeProposal(proposalIndex)
    {
        require(
            fundingNFT.balanceOf(msg.sender) > 0,
            "You don't have any NFT."
        );
        Proposal storage proposal = proposals[proposalIndex];
        if (proposal.voters[msg.sender]) {
            revert AlreadyVoted();
        }
        proposal.voters[msg.sender] = true;
        if (vote == Vote.YES) {
            proposal.yesVotes += 1;
        }
        if (vote == Vote.NO) {
            proposal.noVotes += 1;
        }
    }

    function executeProposal(uint256 proposalIndex)
        external
        finishedProposal(proposalIndex)
    {
        Proposal storage proposal = proposals[proposalIndex];
        require(
            proposal.community.leader == msg.sender,
            "The person who opened can execute."
        );
        require(
            proposal.yesVotes > proposal.noVotes,
            "Yes votes is not enough."
        );
        require(!proposal.executed, "Already executed.");
        proposal.executed = true;
    }
}
