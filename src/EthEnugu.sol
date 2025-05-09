// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract EthEnugu is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    enum Category { Residency, InVenue, Conference }

    // Whitelisted minters
    mapping(address => bool) public allowedResidencyMinters;
    mapping(address => bool) public allowedInVenueMinters;
    mapping(address => bool) public allowedConferenceMinters;

    // Prevent double mint per address per category
    mapping(address => bool) public hasMintedResidency;
    mapping(address => bool) public hasMintedInVenue;
    mapping(address => bool) public hasMintedConference;

    // Base URIs per category
    string public residencyBaseTokenURI;
    string public inVenueBaseTokenURI;
    string public conferenceBaseTokenURI;

    // Token ID counters
    Counters.Counter private _residencyCounter;
    Counters.Counter private _inVenueCounter;
    Counters.Counter private _conferenceCounter;

    // Category mapping for each token
    mapping(uint256 => Category) private _tokenCategory;

    // Events
    event AllowedMinterUpdated(address indexed minter, bool allowed);
    event BaseTokenURIUpdated(Category category, string newBaseURI);
    event ResidencyMinted(address indexed to, uint256 indexed tokenId);
    event InVenueMinted(address indexed to, uint256 indexed tokenId);
    event ConferenceMinted(address indexed to, uint256 indexed tokenId);

    // Modifiers
    modifier onlyAllowedResidency() {
        require(allowedResidencyMinters[msg.sender], "Not allowed");
        _;
    }
    modifier onlyAllowedInVenue() {
        require(allowedInVenueMinters[msg.sender], "Not allowed");
        _;
    }
    modifier onlyAllowedConference() {
        require(allowedConferenceMinters[msg.sender], "Not allowed");
        _;
    }

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        // Set initial base URIs
        residencyBaseTokenURI   = "https://residency.example/api/";
        inVenueBaseTokenURI     = "https://invenue.example/api/";
        conferenceBaseTokenURI  = "https://conference.example/api/";

        // Grant owner all minting roles
        allowedResidencyMinters[msg.sender]   = true;
        allowedInVenueMinters[msg.sender]     = true;
        allowedConferenceMinters[msg.sender]  = true;
    }

    // Owner functions to manage base URIs
    function setResidencyBaseTokenURI(string memory uri) external onlyOwner {
        residencyBaseTokenURI = uri;
        emit BaseTokenURIUpdated(Category.Residency, uri);
    }
    function setInVenueBaseTokenURI(string memory uri) external onlyOwner {
        inVenueBaseTokenURI = uri;
        emit BaseTokenURIUpdated(Category.InVenue, uri);
    }
    function setConferenceBaseTokenURI(string memory uri) external onlyOwner {
        conferenceBaseTokenURI = uri;
        emit BaseTokenURIUpdated(Category.Conference, uri);
    }

    // Owner functions to manage minters
    function updateAllowedResidencyMinter(address minter, bool ok) external onlyOwner {
        allowedResidencyMinters[minter] = ok;
        emit AllowedMinterUpdated(minter, ok);
    }
    function updateAllowedInVenueMinter(address minter, bool ok) external onlyOwner {
        allowedInVenueMinters[minter] = ok;
        emit AllowedMinterUpdated(minter, ok);
    }
    function updateAllowedConferenceMinter(address minter, bool ok) external onlyOwner {
        allowedConferenceMinters[minter] = ok;
        emit AllowedMinterUpdated(minter, ok);
    }

    // Minting functions
    function mintBuilderResidency(address to) external onlyAllowedResidency nonReentrant {
        require(!hasMintedResidency[to], "Residency: already minted");
        hasMintedResidency[to] = true;

        _residencyCounter.increment();
        uint256 tokenId = _residencyCounter.current();
        _tokenCategory[tokenId] = Category.Residency;
        _safeMint(to, tokenId);

        emit ResidencyMinted(to, tokenId);
    }

    function mintInVenueRegistration(address to) external onlyAllowedInVenue nonReentrant {
        require(!hasMintedInVenue[to], "InVenue: already minted");
        hasMintedInVenue[to] = true;

        _inVenueCounter.increment();
        uint256 tokenId = _inVenueCounter.current();
        _tokenCategory[tokenId] = Category.InVenue;
        _safeMint(to, tokenId);

        emit InVenueMinted(to, tokenId);
    }

    function mintConferenceAttendance(address to) external onlyAllowedConference nonReentrant {
        require(!hasMintedConference[to], "Conference: already minted");
        hasMintedConference[to] = true;

        _conferenceCounter.increment();
        uint256 tokenId = _conferenceCounter.current();
        _tokenCategory[tokenId] = Category.Conference;
        _safeMint(to, tokenId);

        emit ConferenceMinted(to, tokenId);
    }

    // Override tokenURI to build URIs on the fly
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
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
