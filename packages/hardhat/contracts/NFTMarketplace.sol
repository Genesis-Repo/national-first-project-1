// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is Ownable {
    ERC721 public nftContract;
    uint256 public nextTokenId;

    struct Listing {
        address seller;
        uint256 price;
        bool active;
    }

    mapping(uint256 => Listing) public listings;

    event NFTListed(uint256 indexed tokenId, address seller, uint256 price);
    event NFTSold(uint256 indexed tokenId, address buyer, uint256 price);

    constructor(ERC721 _nftContract) {
        nftContract = _nftContract;
        nextTokenId = 1;
    }

    function listNFT(uint256 price) external {
        require(nftContract.balanceOf(msg.sender) > 0, "Must own NFTs to list");
        uint256 tokenId = nextTokenId;
        nextTokenId++;
        nftContract.transferFrom(msg.sender, address(this), tokenId);
        listings[tokenId] = Listing(msg.sender, price, true);
        emit NFTListed(tokenId, msg.sender, price);
    }

    function buyNFT(uint256 tokenId) external payable {
        Listing storage listing = listings[tokenId];
        require(listing.active, "NFT not available for sale");
        require(msg.value >= listing.price, "Insufficient funds sent");

        listing.active = false;
        nftContract.transferFrom(address(this), msg.sender, tokenId);

        address payable seller = payable(listing.seller);
        seller.transfer(msg.value);

        emit NFTSold(tokenId, msg.sender, listing.price);
    }

    function updatePrice(uint256 tokenId, uint256 newPrice) external {
        Listing storage listing = listings[tokenId];
        require(msg.sender == listing.seller, "Only seller can update price");
        listing.price = newPrice;
    }

    function removeNFT(uint256 tokenId) external {
        Listing storage listing = listings[tokenId];
        require(msg.sender == listing.seller, "Only seller can remove NFT");
        nftContract.transferFrom(address(this), msg.sender, tokenId);
        delete listings[tokenId];
    }
}