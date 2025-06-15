// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title ETH Enugu Residency Pass
/// @author Therock Ani
/// @notice ERC721-based NFT contract for managing Residency passes for ETH Enugu 2025
contract EthEnuguResidency is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    /// @notice Custom errors
    error InvalidAddress();
    error AddressNotAllowed();
    error AlreadyMinted();
    error NonexistentToken();

    /// @notice Mapping of addresses to allowed Residency minters
    mapping(address => bool) public allowedResidencyAddresses;

    /// @notice Tracks if an address has already minted a Residency pass
    mapping(address => bool) public hasMintedResidency;

    /// @notice Base URI for Residency token metadata
    string public residencyBaseTokenURI;

    /// @notice Counter for Residency token IDs
    Counters.Counter private _residencyCounter;

    /// @notice Emitted when an allowed address is added or removed
    /// @param account Address added or removed from whitelist
    /// @param allowed True if allowed, false if revoked
    event AllowedAddressUpdated(address indexed account, bool allowed);

    /// @notice Emitted when a Residency pass is minted
    event ResidencyMinted(address indexed to, uint256 indexed tokenId);

    /// @notice Constructor sets token name, symbol, and default URI
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        residencyBaseTokenURI = "https://aquamarine-rare-firefly-756.mypinata.cloud/ipfs/bafkreigzu2rrdmh7jj3cz57dn2wh7psuwbdxgiflsphxpcppgfbkeycmsm";
    }

    /// @notice Grant or revoke Residency minter role for an address
    /// @param account Address to update
    /// @param allowed True to grant, false to revoke
    function updateAllowedResidencyAddress(address account, bool allowed) external onlyOwner {
        if (account == address(0)) revert InvalidAddress();
        allowedResidencyAddresses[account] = allowed;
        emit AllowedAddressUpdated(account, allowed);
    }

    /// @notice Mints a Residency pass to caller if whitelisted
    function mintBuilderResidency() external {
        if (!allowedResidencyAddresses[msg.sender]) revert AddressNotAllowed();
        if (hasMintedResidency[msg.sender]) revert AlreadyMinted();

        hasMintedResidency[msg.sender] = true;
        _residencyCounter.increment();
        uint256 tokenId = _residencyCounter.current();
        _safeMint(msg.sender, tokenId);

        emit ResidencyMinted(msg.sender, tokenId);
    }

    /// @notice Returns the metadata URI for a given token ID
    /// @param tokenId NFT identifier
    /// @return URI string pointing to JSON metadata
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert NonexistentToken();
        return string(abi.encodePacked(residencyBaseTokenURI, tokenId.toString(), ".json"));
    }
}
