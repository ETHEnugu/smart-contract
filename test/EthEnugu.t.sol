// SPDX-License-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/EthEnuguResidency.sol";
import "../src/EthEnugu.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @title EthEnugu Test Suite
 * @dev Test suite for EthEnuguResidency and EthEnugu NFT contracts
 * @author Therock Ani
 * @notice Tests minting, access control, URI logic for Residency, InVenue, and Conference passes
 */
contract EthEnuguTest is Test {
    /// @notice Instances of the contracts under test
    EthEnuguResidency public ethEnuguResidency;
    EthEnugu public ethEnugu;

    /// @notice Predefined owner address with default roles
    address public owner = address(0xABCD);
    /// @notice Secondary minter address for testing
    address public minter = address(0xBEEF);
    /// @notice Generic user address for negative tests
    address public user = address(0xCAFE);

    /// @notice Deploys both contracts and assigns whitelist role to `minter`
    function setUp() public {
        // Deploy EthEnuguResidency
        vm.prank(owner);
        ethEnuguResidency = new EthEnuguResidency("EthEnuguResidencyNFT", "EERN");

        // Deploy EthEnugu
        vm.prank(owner);
        ethEnugu = new EthEnugu("EthEnuguNFT", "EEN");

        // Whitelist minter for Residency
        vm.prank(owner);
        ethEnuguResidency.updateAllowedResidencyAddress(minter, true);
    }

    /// @notice Verifies default base URIs match constructor values
    function testInitialBaseTokenURIs() public view {
        assertEq(ethEnuguResidency.residencyBaseTokenURI(), "https://residency.example/api/");
        assertEq(ethEnugu.inVenueBaseTokenURI(), "https://invenue.example/api/");
        assertEq(ethEnugu.conferenceBaseTokenURI(), "https://conference.example/api/");
    }

    /// @notice Ensures tokenURI returns correct Residency metadata path
    function testTokenURIResidency() public {
        vm.prank(minter);
        ethEnuguResidency.mintBuilderResidency();
        string memory expected = string(abi.encodePacked(ethEnuguResidency.residencyBaseTokenURI(), "1.json"));
        assertEq(ethEnuguResidency.tokenURI(1), expected);
    }

    /// @notice Ensures tokenURI returns correct InVenue metadata path
    function testTokenURIInVenue() public {
        vm.prank(minter);
        ethEnugu.mintInVenueRegistration();
        string memory expected = string(abi.encodePacked(ethEnugu.inVenueBaseTokenURI(), "1.json"));
        assertEq(ethEnugu.tokenURI(1), expected);
    }

    /// @notice Ensures tokenURI returns correct Conference metadata path
    function testTokenURIConference() public {
        vm.prank(minter);
        ethEnugu.mintConferenceAttendance();
        string memory expected = string(abi.encodePacked(ethEnugu.conferenceBaseTokenURI(), "1.json"));
        assertEq(ethEnugu.tokenURI(1), expected);
    }

    /// @notice Owner can mint Residency when whitelisted
    function testOwnerCanMintResidency() public {
        vm.prank(owner);
        ethEnuguResidency.updateAllowedResidencyAddress(owner, true);
        vm.prank(owner);
        ethEnuguResidency.mintBuilderResidency();
        assertEq(ethEnuguResidency.ownerOf(1), owner);
    }

    /// @notice Whitelisted address can mint Residency
    function testWhitelistedAddressCanMintResidency() public {
        vm.prank(minter);
        ethEnuguResidency.mintBuilderResidency();
        assertEq(ethEnuguResidency.ownerOf(1), minter);
    }

    /// @notice Minter can mint InVenue
    function testMinterCanMintInVenue() public {
        vm.prank(minter);
        ethEnugu.mintInVenueRegistration();
        assertEq(ethEnugu.ownerOf(1), minter);
    }

    /// @notice Minter can mint Conference
    function testMinterCanMintConference() public {
        vm.prank(minter);
        ethEnugu.mintConferenceAttendance();
        assertEq(ethEnugu.ownerOf(1), minter);
    }

    /// @notice Prevent double-residency mint per address
    function testMintingResidencyTwiceReverts() public {
        vm.prank(minter);
        ethEnuguResidency.mintBuilderResidency();
        vm.prank(minter);
        vm.expectRevert(EthEnuguResidency.AlreadyMinted.selector);
        ethEnuguResidency.mintBuilderResidency();
    }

    /// @notice Prevent double-inVenue mint per address
    function testMintingInVenueTwiceReverts() public {
        vm.prank(minter);
        ethEnugu.mintInVenueRegistration();
        vm.prank(minter);
        vm.expectRevert(EthEnugu.AlreadyMintedInVenue.selector);
        ethEnugu.mintInVenueRegistration();
    }

    /// @notice Prevent double-conference mint per address
    function testMintingConferenceTwiceReverts() public {
        vm.prank(minter);
        ethEnugu.mintConferenceAttendance();
        vm.prank(minter);
        vm.expectRevert(EthEnugu.AlreadyMintedConference.selector);
        ethEnugu.mintConferenceAttendance();
    }

    /// @notice Non-whitelisted address reverts for Residency
    function testNonWhitelistedAddressRevertsResidency() public {
        vm.prank(user);
        vm.expectRevert(EthEnuguResidency.AddressNotAllowed.selector);
        ethEnuguResidency.mintBuilderResidency();
    }

    /// @notice Owner can add/remove Residency whitelist address
    function testUpdateAllowedAddressAddsAndRemovesResidency() public {
        address newAddress = address(0x1234);
        vm.prank(owner);
        ethEnuguResidency.updateAllowedResidencyAddress(newAddress, true);
        assertTrue(ethEnuguResidency.allowedResidencyAddresses(newAddress));
        vm.prank(owner);
        ethEnuguResidency.updateAllowedResidencyAddress(newAddress, false);
        assertFalse(ethEnuguResidency.allowedResidencyAddresses(newAddress));
    }

    /// @notice Non-owner cannot manage Residency whitelist
    function testNonOwnerCannotAddAndRemoveResidencyAddress() public {
        address nonOwner = address(0x7777);
        address newAddress = address(0x1234);
        vm.prank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        ethEnuguResidency.updateAllowedResidencyAddress(newAddress, true);
        vm.prank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        ethEnuguResidency.updateAllowedResidencyAddress(newAddress, false);
    }

    /// @notice Zero address cannot be whitelisted
    function testZeroAddressWhitelistReverts() public {
        vm.prank(owner);
        vm.expectRevert(EthEnuguResidency.InvalidAddress.selector);
        ethEnuguResidency.updateAllowedResidencyAddress(address(0), true);
    }

    /// @notice Querying tokenURI on nonexistent token reverts for Residency
    function testNonExistentTokenURIResidency() public {
        vm.expectRevert(EthEnuguResidency.NonexistentToken.selector);
        ethEnuguResidency.tokenURI(999);
    }

    /// @notice Querying tokenURI on nonexistent token reverts for InVenue/Conference
    function testNonExistentTokenURIInVenueConference() public {
        vm.expectRevert(EthEnugu.NonexistentToken.selector);
        ethEnugu.tokenURI(999);
    }
}

/**
 * @title MaliciousReceiver
 * @notice Implements IERC721Receiver for testing (not used for reentrancy since guard removed)
 */
contract MaliciousReceiver is IERC721Receiver {
    /// @notice Target contracts
    EthEnuguResidency public residencyTarget;
    EthEnugu public passTarget;

    /// @notice Mode to determine which mint function to call
    enum Mode {
        Residency,
        InVenue,
        Conference
    }

    Mode public mode;

    /**
     * @param _residencyTarget Address of EthEnuguResidency contract
     * @param _passTarget Address of EthEnugu contract
     * @param _mode Mode of operation
     */
    constructor(address _residencyTarget, address _passTarget, Mode _mode) {
        residencyTarget = EthEnuguResidency(_residencyTarget);
        passTarget = EthEnugu(_passTarget);
        mode = _mode;
    }

    /**
     * @notice Called by ERC721 safeMint; included for completeness
     * @return selector IERC721Receiver return selector
     */
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
