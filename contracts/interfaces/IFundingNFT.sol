// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IFundingNFT {
    error OnlyLeaderCanCallTheFunction();
    error OnlyMembersCanCallTheFunction();
    error MemberHasAlreadyHasNFT();
    error YouCanHaveJustOneNFT();
    error InsufficientFunds();

    enum Breed {
        CommunityMemberNFT,
        CommunityLeaderNFT
    }

    /**
     *  The caller can only be owner of the contract.
     *  User in given address will qualify for mint leader NFT.
     */
    function setLeader(address leaderAddress) external;

    /**
     *  The caller can only be a leader.
     *  Users in member addresses array will qualify for mint member NFT.
     */
    function setMembers(address[] calldata memberAddresses) external;

    /**
     *  Owner of the contract must run setLeader before the function.
     *  The caller can only be a leader.
     */
    function mintLeaderNFT() external;

    /**
     *  One leader must run setMembers function before the function.
     *  The caller can only be a member.
     */
    function mintMemberNFT() external;

    /**
     *  Only leaders can call the function.
     *  They can hand over their leaderships.
     */
    function transferLeadership(address newLeader) external;

    /**
     *  Only members can exit their communities.
     *  If a member run this function their NFT's are burns.
     *  And they lose their voting rights.
     */
    function exitTheCommunity() external;

    /**
     *  Is given address a leader?
     */
    function isLeader(address leaderAddress) external view returns (bool);

    /**
     *  Is given address a member?
     */
    function isMember(address memberAddress) external view returns (bool);

    function getTokenId(address tokenOwner) external view returns (uint256);

    function getTokenUris(uint256 index) external view returns (string memory);

    function getTokenCounter() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);
}
