// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EthEnugu is ERC721URIStorage, Ownable {
    /// @notice Whitelist mapping for authorized minters
    mapping(address => bool) public allowedMinters;

    /// @notice Base URI for all token metadata
    string private baseTokenURI;

    /// @notice Emitted when an address is added or removed from allowedMinters
    event AllowedMinterUpdated(address indexed minter, bool allowed);

    /// @notice Emitted when the baseTokenURI is updated
    event BaseTokenURIUpdated(string newBaseURI);

    modifier onlyAllowed() {
        require(allowedMinters[msg.sender], "POAPNFT: Not an allowed minter");
        _;
    }

    constructor(string memory _name, string memory _symbol, string memory _initialBaseURI) 
        ERC721(_name, _symbol) 
    {
        baseTokenURI = _initialBaseURI;
        allowedMinters[msg.sender] = true;
    }

    /// @notice Owner can add or remove allowed minters
    function updateAllowedMinter(address _minter, bool _allowed) external onlyOwner {
        allowedMinters[_minter] = _allowed;
        emit AllowedMinterUpdated(_minter, _allowed);
    }

    /// @notice Owner can update the base URI for token metadata
    function setBaseTokenURI(string memory _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
        emit BaseTokenURIUpdated(_newBaseURI);
    }

    /// @notice Mints a new POAP NFT to `to` with `tokenId`
    function mintPOAP(address to, uint256 tokenId) external onlyAllowed {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, Strings.toString(tokenId));
    }

    /// @notice Override to return the baseTokenURI
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}
