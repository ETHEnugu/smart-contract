// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title ETH Enugu Event Passes
/// @author Therock Ani
/// @notice ERC721-based NFT contract for managing Pop-Up City, Conference, and University Tour passes for ETH Enugu 2025
contract EthEnugu is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    /// @notice Custom errors
    error AlreadyMintedPopUpCity();
    error AlreadyMintedConference();
    error AlreadyMintedUniversityTour(); // New error
    error NonexistentToken();

    /// @notice NFT categories for pass types
    enum Category {
        PopUpCity,
        Conference,
        UniversityTour // New category
    }

    /// @notice Tracks if an address has already minted a Pop-Up City pass
    mapping(address => bool) public hasMintedPopUpCity;

    /// @notice Tracks if an address has already minted a Conference pass
    mapping(address => bool) public hasMintedConference;

    /// @notice Tracks if an address has already minted a University Tour pass // New mapping
    mapping(address => bool) public hasMintedUniversityTour; // New mapping

    /// @notice Base URI for Pop-Up City token metadata
    string public popUpCityBaseTokenURI;

    /// @notice Base URI for Conference token metadata
    string public conferenceBaseTokenURI;

    /// @notice Base URI for University Tour token metadata // New variable
    string public universityTourBaseTokenURI; // New variable

    /// @notice Counter for Pop-Up City token IDs
    Counters.Counter private _popUpCityCounter;

    /// @notice Counter for Conference token IDs
    Counters.Counter private _conferenceCounter;

    /// @notice Counter for University Tour token IDs // New counter
    Counters.Counter private _universityTourCounter; // New counter

    /// @notice Maps token IDs to their Category
    mapping(uint256 => Category) private _tokenCategory;

    /// @notice Emitted when a Pop-Up City pass is minted
    event PopUpCityMinted(address indexed to, uint256 indexed tokenId);

    /// @notice Emitted when a Conference pass is minted
    event ConferenceMinted(address indexed to, uint256 indexed tokenId);

    /// @notice Emitted when a University Tour pass is minted // New event
    event UniversityTourMinted(address indexed to, uint256 indexed tokenId); // New event

    /// @notice Constructor sets token name, symbol, and default URIs
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        popUpCityBaseTokenURI = "https://aquamarine-rare-firefly-756.mypinata.cloud/ipfs/bafkreie3xhrlu3oxhvl6bweqfrk52cbbhprpfxcvt3d6zehet44zpe4cpa";
        conferenceBaseTokenURI = "https://aquamarine-rare-firefly-756.mypinata.cloud/ipfs/bafkreifjepcwhojrfalkn3n4m5iqf5isafnb5kz2ulsjzicvlavw5wnggy";
        universityTourBaseTokenURI = "https://aquamarine-rare-firefly-756.mypinata.cloud/ipfs/bafkreih32fiwhjl4q3rsr4nulncoxbnivaj6aizcu6j5u5wnvm7tk6poxm"; // New base URI
    }

    /// @notice Mints a Pop-Up City pass to caller
    function mintPopUpCityRegistration() external {
        if (hasMintedPopUpCity[msg.sender]) revert AlreadyMintedPopUpCity();
        hasMintedPopUpCity[msg.sender] = true;

        _popUpCityCounter.increment();
        uint256 tokenId = _popUpCityCounter.current();
        _tokenCategory[tokenId] = Category.PopUpCity;
        _safeMint(msg.sender, tokenId);

        emit PopUpCityMinted(msg.sender, tokenId);
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

    /// @notice Mints a University Tour pass to caller // New function
    function mintUniversityTour() external { // New function
        if (hasMintedUniversityTour[msg.sender]) revert AlreadyMintedUniversityTour(); // New check
        hasMintedUniversityTour[msg.sender] = true; // New mapping update

        _universityTourCounter.increment(); // New counter increment
        uint256 tokenId = _universityTourCounter.current(); // New token ID
        _tokenCategory[tokenId] = Category.UniversityTour; // New category assignment
        _safeMint(msg.sender, tokenId);

        emit UniversityTourMinted(msg.sender, tokenId); // New event emission
    }

    /// @notice Returns the metadata URI for a given token ID
    /// @param tokenId NFT identifier
    /// @return URI string pointing to JSON metadata
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert NonexistentToken();
        Category cat = _tokenCategory[tokenId];
        string memory base;
        if (cat == Category.PopUpCity) {
            base = popUpCityBaseTokenURI;
        } else if (cat == Category.Conference) {
            base = conferenceBaseTokenURI;
        } else if (cat == Category.UniversityTour) { // New condition
            base = universityTourBaseTokenURI; // New base URI
        } else {
            revert NonexistentToken(); // Or handle the case if a category is not found
        }
        return string(abi.encodePacked(base, tokenId.toString(), ".json"));
    }
}
