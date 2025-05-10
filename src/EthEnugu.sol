// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title ETH Enugu Event Passes
/// @author Therock Ani
/// @notice ERC721-based NFT contract for managing event passes for ETH Enugu 2025
/// @dev Uses OpenZeppelin libraries for security and token standard compliance
contract EthEnugu is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    /// @notice NFT categories corresponding to pass types
    enum Category { Residency, InVenue, Conference }

    /// @notice Mapping of addresses allowed to mint Residency passes
    mapping(address => bool) public allowedResidencyMinters;

    /// @notice Mapping of addresses allowed to mint InVenue passes
    mapping(address => bool) public allowedInVenueMinters;

    /// @notice Mapping of addresses allowed to mint Conference passes
    mapping(address => bool) public allowedConferenceMinters;

    /// @notice Tracks if an address has already minted a Residency pass
    mapping(address => bool) public hasMintedResidency;

    /// @notice Tracks if an address has already minted an InVenue pass
    mapping(address => bool) public hasMintedInVenue;

    /// @notice Tracks if an address has already minted a Conference pass
    mapping(address => bool) public hasMintedConference;

    /// @notice Base URI for Residency token metadata
    string public residencyBaseTokenURI;

    /// @notice Base URI for InVenue token metadata
    string public inVenueBaseTokenURI;

    /// @notice Base URI for Conference token metadata
    string public conferenceBaseTokenURI;

    /// @notice Counter for Residency token IDs
    Counters.Counter private _residencyCounter;

    /// @notice Counter for InVenue token IDs
    Counters.Counter private _inVenueCounter;

    /// @notice Counter for Conference token IDs
    Counters.Counter private _conferenceCounter;

    /// @notice Maps token IDs to their Category
    mapping(uint256 => Category) private _tokenCategory;

    /// @notice Emitted when an allowed minter is added or removed
    /// @param minter Address of the minter
    /// @param allowed True if allowed, false if revoked
    event AllowedMinterUpdated(address indexed minter, bool allowed);

    /// @notice Emitted when a category base URI is updated
    /// @param category The Category updated
    /// @param newBaseURI New base URI string
    event BaseTokenURIUpdated(Category category, string newBaseURI);

    /// @notice Emitted when a Residency pass is minted
    event ResidencyMinted(address indexed to, uint256 indexed tokenId);

    /// @notice Emitted when an InVenue pass is minted
    event InVenueMinted(address indexed to, uint256 indexed tokenId);

    /// @notice Emitted when a Conference pass is minted
    event ConferenceMinted(address indexed to, uint256 indexed tokenId);

    /// @notice Restricts function to allowed Residency minters
    modifier onlyAllowedResidency() {
        require(allowedResidencyMinters[msg.sender], "EthEnugu: caller not allowed");
        _;
    }

    /// @notice Restricts function to allowed InVenue minters
    modifier onlyAllowedInVenue() {
        require(allowedInVenueMinters[msg.sender], "EthEnugu: caller not allowed");
        _;
    }

    /// @notice Restricts function to allowed Conference minters
    modifier onlyAllowedConference() {
        require(allowedConferenceMinters[msg.sender], "EthEnugu: caller not allowed");
        _;
    }

    /// @notice Constructor sets token name, symbol, default URIs, and grants owner all mint roles
    /// @param name_ ERC721 token name
    /// @param symbol_ ERC721 token symbol
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        residencyBaseTokenURI  = "https://residency.example/api/";
        inVenueBaseTokenURI    = "https://invenue.example/api/";
        conferenceBaseTokenURI = "https://conference.example/api/";

        // Owner begins with all roles
        allowedResidencyMinters[_msgSender()]   = true;
        allowedInVenueMinters[_msgSender()]     = true;
        allowedConferenceMinters[_msgSender()]  = true;
    }

    /// @notice Grant or revoke Residency minter role
    /// @param minter Address to update
    /// @param ok True to grant, false to revoke
    function updateAllowedResidencyMinter(address minter, bool ok) external onlyOwner {
        allowedResidencyMinters[minter] = ok;
        emit AllowedMinterUpdated(minter, ok);
    }

    /// @notice Grant or revoke InVenue minter role
    function updateAllowedInVenueMinter(address minter, bool ok) external onlyOwner {
        allowedInVenueMinters[minter] = ok;
        emit AllowedMinterUpdated(minter, ok);
    }

    /// @notice Grant or revoke Conference minter role
    function updateAllowedConferenceMinter(address minter, bool ok) external onlyOwner {
        allowedConferenceMinters[minter] = ok;
        emit AllowedMinterUpdated(minter, ok);
    }

    /// @notice Mints a Residency pass to caller
    /// @dev Prevents double-mint and protected against reentrancy
    function mintBuilderResidency() external onlyAllowedResidency nonReentrant {
        require(!hasMintedResidency[msg.sender], "Residency: already minted");
        hasMintedResidency[msg.sender] = true;

        _residencyCounter.increment();
        uint256 tokenId = _residencyCounter.current();
        _tokenCategory[tokenId] = Category.Residency;
        _safeMint(msg.sender, tokenId);

        emit ResidencyMinted(msg.sender, tokenId);
    }

    /// @notice Mints an InVenue pass to caller
    function mintInVenueRegistration() external onlyAllowedInVenue nonReentrant {
        require(!hasMintedInVenue[msg.sender], "InVenue: already minted");
        hasMintedInVenue[msg.sender] = true;

        _inVenueCounter.increment();
        uint256 tokenId = _inVenueCounter.current();
        _tokenCategory[tokenId] = Category.InVenue;
        _safeMint(msg.sender, tokenId);

        emit InVenueMinted(msg.sender, tokenId);
    }

    /// @notice Mints a Conference pass to caller
    function mintConferenceAttendance() external onlyAllowedConference nonReentrant {
        require(!hasMintedConference[msg.sender], "Conference: already minted");
        hasMintedConference[msg.sender] = true;

        _conferenceCounter.increment();
        uint256 tokenId = _conferenceCounter.current();
        _tokenCategory[tokenId] = Category.Conference;
        _safeMint(msg.sender, tokenId);

        emit ConferenceMinted(msg.sender, tokenId);
    }

    /// @notice Returns the metadata URI for a given token ID
    /// @param tokenId NFT identifier
    /// @return URI string pointing to JSON metadata
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        Category cat = _tokenCategory[tokenId];
        string memory base;
        if (cat == Category.Residency) {
            base = residencyBaseTokenURI;
        } else if (cat == Category.InVenue) {
            base = inVenueBaseTokenURI;
        } else {
            base = conferenceBaseTokenURI;
        }
        return string(abi.encodePacked(base, tokenId.toString(), ".json"));
    }
}
