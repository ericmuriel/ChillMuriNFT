// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {ERC721} from "@openzeppelin/contracts@5.1.0/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts@5.1.0/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721Pausable} from "@openzeppelin/contracts@5.1.0/token/ERC721/extensions/ERC721Pausable.sol";
import {Ownable} from "@openzeppelin/contracts@5.1.0/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts@5.1.0/utils/Strings.sol";

contract ChillMuri is ERC721, ERC721Enumerable, ERC721Pausable, Ownable {
    uint256 private _nextTokenId;
    uint public immutable maxSupply = 100;
    bool public publicMintOpen = true;
    bool public whiteListMintOpen = false;
    mapping (address => bool) public whiteList;
    enum Rarity { Common, Rare, Epic, Legendary }
    mapping(uint256 => Rarity) public tokenRarities;
    event TokenMinted(uint256 tokenId, Rarity rarity);

    constructor()
        ERC721("ChillMuri", "CHM")
        Ownable(msg.sender)
    {}

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmRRRr9qCZ1B7zbJnzQVK7mzcyRDkoqPeF6z24jtQdmhG8/";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    //Permit users mint before because they are whitelisted
    function whiteListMint() external payable {
        require(whiteListMintOpen == true, "Window Closed");
        require(whiteList[msg.sender], "You're not in whitelist");
        require(msg.value == 0.0001 ether, "Not enough ether send");
        _internalMint();
    }

    function publicMint() external payable  {
        require(publicMintOpen == true, "Window Closed");
        require(msg.value == 0.01 ether, "Not enough ether send");
        _internalMint();
    }


    //Update windows for minting
    function updateMintWindows(bool _publicMintOpen, bool _whiteListMintOpen) external onlyOwner {
        publicMintOpen = _publicMintOpen;
        whiteListMintOpen = _whiteListMintOpen;
    }

    //Add address to whitelist
    function updateWhiteList(address[] memory _addresses) external onlyOwner (){
        for(uint i; i<_addresses.length; i++){
            whiteList[_addresses[i]] = true;
        }
    }

    
    //Refactor Code
    function _internalMint() internal {
        require(totalSupply() < maxSupply, "NFTs Sold Out");
        uint256 tokenId = _nextTokenId++;
        Rarity rarity = _assignRarity();
        tokenRarities[tokenId] = rarity;
        emit TokenMinted(tokenId, rarity); // Emit event
        _safeMint(msg.sender, tokenId);
    }

     function _assignRarity() internal view returns (Rarity) {
        uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, _nextTokenId))) % 100;
        if (randomValue < 40) {
            return Rarity.Common; // 40% chance
        } else if (randomValue < 70) {
            return Rarity.Rare; // 30% chance
        } else if (randomValue < 90) {
            return Rarity.Epic; // 20% chance
        } else {
            return Rarity.Legendary; // 10% chance
        }
    }

    function _rarityToIpfsId(Rarity rarity) internal pure returns (uint256) {
        if (rarity == Rarity.Common) {
            return 0; // Metadata 0
        } else if (rarity == Rarity.Rare) {
            return 1; // Metadata 1
        } else if (rarity == Rarity.Epic) {
            return 2; // Metadata 2
        } else if (rarity == Rarity.Legendary) {
            return 3; // Metadata 3
        } else {
            revert("Invalid rarity");
        }
    }

    //I override tokenUri Function to adapt to maximum 4 NFT'S images and depends on rarity, 
    // return the correct id to find her ipfs metadata
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        Rarity rarity = tokenRarities[tokenId]; // Get Token Rarity
        uint256 ipfsId = _rarityToIpfsId(rarity); // Use _rarityToIpfsId

        return bytes(baseURI).length > 0 
            ? string.concat(baseURI, Strings.toString(ipfsId))
            : "";
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return ownerOf(tokenId) != address(0);
    }

    //Withdraw balance
    function withdraw(address _receiver) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_receiver).transfer(balance);
    }
    
    // The following functions are overrides required by Solidity.

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable, ERC721Pausable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    

    function getTokenRarity(uint256 tokenId) external view returns (Rarity) {
        require(ownerOf(tokenId) != address(0), "Token does not exist");
        return tokenRarities[tokenId];
    }
}
