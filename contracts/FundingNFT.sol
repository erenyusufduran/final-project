// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // For accessing onlyOwner.

error OnlyLeaderCanCallTheFunction();
error OnlyMembersCanCallTheFunction();
error MemberAlreadyHasNFT();
error YouCanHaveJustOneNFT();
error InsufficientFunds();

contract FundingNFT is ERC721URIStorage, Ownable {
    enum Breed {
        CommunityMemberNFT,
        CommunityLeaderNFT
    }

    mapping(address => bool) private leaders;
    mapping(address => bool) private members;
    mapping(address => uint256) public addressToTokenId;

    uint256 private s_tokenCounter;
    string[2] private s_tokenUris;

    event nftMinted(address minter, Breed nftBreed);
    event leadershipTransferred(address oldLeader, address newLeader);
    event memberLeftTheCommunity(address oldMember);

    modifier onlyLeader() {
        if (!leaders[msg.sender]) {
            revert OnlyLeaderCanCallTheFunction();
        }
        _;
    }

    modifier onlyMembers() {
        if (!members[msg.sender]) {
            revert OnlyMembersCanCallTheFunction();
        }
        _;
    }

    modifier canOnlyHaveOneNFT() {
        if (balanceOf(msg.sender) > 0) {
            revert YouCanHaveJustOneNFT();
        }
        _;
    }

    constructor(string[2] memory tokenUris)
        ERC721("Funding University Clubs NFT", "FUC")
    {
        s_tokenUris = tokenUris;
    }

    function setLeader(address leaderAddress) external onlyOwner {
        leaders[leaderAddress] = true;
    }

    function setMembers(address[] calldata memberAddresses)
        external
        onlyLeader
    {
        for (uint256 i; i < memberAddresses.length; i++) {
            if (members[memberAddresses[i]] == true) {
                revert MemberAlreadyHasNFT();
            }
            members[memberAddresses[i]] = true;
        }
    }

    function mintLeaderNFT() external onlyLeader canOnlyHaveOneNFT {
        uint256 newTokenId = s_tokenCounter;
        Breed nftBreed = Breed(1);
        s_tokenCounter++;
        addressToTokenId[msg.sender] = newTokenId;
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, s_tokenUris[uint256(nftBreed)]);
        emit nftMinted(msg.sender, nftBreed);
    }

    function mintMemberNFT() external onlyMembers canOnlyHaveOneNFT {
        uint256 newTokenId = s_tokenCounter;
        Breed nftBreed = Breed(0);
        s_tokenCounter++;
        addressToTokenId[msg.sender] = newTokenId;
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, s_tokenUris[uint256(nftBreed)]);
        emit nftMinted(msg.sender, nftBreed);
    }

    function transferLeadership(address newLeader) external onlyLeader {
        require(
            balanceOf(msg.sender) > 0,
            "You haven't minted leader NFT yet."
        );
        leaders[msg.sender] = false;
        leaders[newLeader] = true;
        if (balanceOf(newLeader) == 1) {
            _burn(addressToTokenId[newLeader]);
        }
        addressToTokenId[newLeader] = addressToTokenId[msg.sender];
        delete addressToTokenId[msg.sender];
        safeTransferFrom(msg.sender, newLeader, addressToTokenId[newLeader]);
        emit leadershipTransferred(msg.sender, newLeader);
    }

    function exitTheCommunity() external onlyMembers {
        require(balanceOf(msg.sender) == 0, "You are not in a community.");
        members[msg.sender] = false;
        uint256 _tokenId = addressToTokenId[msg.sender];
        delete addressToTokenId[msg.sender];
        _burn(_tokenId);
        emit memberLeftTheCommunity(msg.sender);
    }

    function isLeader(address leaderAddress) external view returns (bool) {
        return leaders[leaderAddress];
    }

    function isMember(address memberAddress) external view returns (bool) {
        return members[memberAddress];
    }

    function getTokenId(address tokenOwner) external view returns (uint256) {
        return addressToTokenId[tokenOwner];
    }

    function getTokenUris(uint256 index) external view returns (string memory) {
        return s_tokenUris[index];
    }

    function getTokenCounter() external view returns (uint256) {
        return s_tokenCounter;
    }
}
