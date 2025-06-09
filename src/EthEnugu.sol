// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title ETH Enugu Event Passes
/// @author Therock Ani
/// @notice ERC721-based NFT contract for managing InVenue and Conference passes for ETH Enugu 2025
contract EthEnugu is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    /// @notice Custom errors
    error AlreadyMintedInVenue();
    error AlreadyMintedConference();
    error NonexistentToken();

    /// @notice NFT categories for pass types
    enum Category {
        InVenue,
        Conference
    }

    /// @notice Tracks if an address has already minted an InVenue pass
    mapping(address => bool) public hasMintedInVenue;

    /// @notice Tracks if an address has already minted a Conference pass
    mapping(address => bool) public hasMintedConference;

    /// @notice Base URI for InVenue token metadata
    string public inVenueBaseTokenURI;

    /// @notice Base URI for Conference token metadata
    string public conferenceBaseTokenURI;

    /// @notice Counter for InVenue token IDs
    Counters.Counter private _inVenueCounter;

    /// @notice Counter for Conference token IDs
    Counters.Counter private _conferenceCounter;

    /// @notice Maps token IDs to their Category
    mapping(uint256 => Category) private _tokenCategory;

    /// @notice Emitted when an InVenue pass is minted
    event InVenueMinted(address indexed to, uint256 indexed tokenId);

    /// @notice Emitted when a Conference pass is minted
    event ConferenceMinted(address indexed to, uint256 indexed tokenId);

    /// @notice Constructor sets token name, symbol, and default URIs
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        inVenueBaseTokenURI = "https://invenue.example/api/";
        conferenceBaseTokenURI = "https://conference.example/api/";
    }

    /// @notice Mints an InVenue pass to caller
    function mintInVenueRegistration() external {
        if (hasMintedInVenue[msg.sender]) revert AlreadyMintedInVenue();
        hasMintedInVenue[msg.sender] = true;

        _inVenueCounter.increment();
        uint256 tokenId = _inVenueCounter.current();
        _tokenCategory[tokenId] = Category.InVenue;
        _safeMint(msg.sender, tokenId);

        emit InVenueMinted(msg.sender, tokenId);
    }

    /// @notice Mints a Conference pass to caller
    function mintConferenceAttendance() external {
        if (hasMintedConference[msg.sender]) revert AlreadyMintedConference();
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
        if (!_exists(tokenId)) revert NonexistentToken();
        Category cat = _tokenCategory[tokenId];
        string memory base = cat == Category.InVenue ? inVenueBaseTokenURI : conferenceBaseTokenURI;
        return string(abi.encodePacked(base, tokenId.toString(), ".json"));
    }
}
