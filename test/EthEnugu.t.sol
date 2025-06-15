// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/EthEnuguResidency.sol";
import "../src/EthEnugu.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @title EthEnugu Test Suite
 * @dev Test suite for EthEnuguResidency and EthEnugu NFT contracts
 * @author Therock Ani
 * @notice Tests minting, access control, URI logic for Residency, Pop-Up City, Conference, and University Tour passes
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
        assertEq(ethEnugu.popUpCityBaseTokenURI(), "https://popupcity.example/api/"); // Changed
        assertEq(ethEnugu.conferenceBaseTokenURI(), "https://conference.example/api/");
        assertEq(ethEnugu.universityTourBaseTokenURI(), "https://universitytour.example/api/"); // New
    }

    /// @notice Ensures tokenURI returns correct Residency metadata path
    function testTokenURIResidency() public {
        vm.prank(minter);
        ethEnuguResidency.mintBuilderResidency();
        string memory expected = string(abi.encodePacked(ethEnuguResidency.residencyBaseTokenURI(), "1.json"));
        assertEq(ethEnuguResidency.tokenURI(1), expected);
    }

    /// @notice Ensures tokenURI returns correct Pop-Up City metadata path // Changed
    function testTokenURIPopUpCity() public { // Changed
        vm.prank(minter);
        ethEnugu.mintPopUpCityRegistration(); // Changed
        string memory expected = string(abi.encodePacked(ethEnugu.popUpCityBaseTokenURI(), "1.json")); // Changed
        assertEq(ethEnugu.tokenURI(1), expected);
    }

    /// @notice Ensures tokenURI returns correct Conference metadata path
    function testTokenURIConference() public {
        vm.prank(minter);
        ethEnugu.mintConferenceAttendance();
        string memory expected = string(abi.encodePacked(ethEnugu.conferenceBaseTokenURI(), "1.json"));
        assertEq(ethEnugu.tokenURI(1), expected);
    }

    /// @notice Ensures tokenURI returns correct University Tour metadata path // New test
    function testTokenURIUniversityTour() public { // New test
        vm.prank(minter);
        ethEnugu.mintUniversityTour(); // New function call
        string memory expected = string(abi.encodePacked(ethEnugu.universityTourBaseTokenURI(), "1.json")); // New base URI
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

    /// @notice Minter can mint Pop-Up City // Changed
    function testMinterCanMintPopUpCity() public { // Changed
        vm.prank(minter);
        ethEnugu.mintPopUpCityRegistration(); // Changed
        assertEq(ethEnugu.ownerOf(1), minter);
    }

    /// @notice Minter can mint Conference
    function testMinterCanMintConference() public {
        vm.prank(minter);
        ethEnugu.mintConferenceAttendance();
        assertEq(ethEnugu.ownerOf(1), minter);
    }

    /// @notice Minter can mint University Tour // New test
    function testMinterCanMintUniversityTour() public { // New test
        vm.prank(minter);
        ethEnugu.mintUniversityTour(); // New function call
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

    /// @notice Prevent double-Pop-Up City mint per address // Changed
    function testMintingPopUpCityTwiceReverts() public { // Changed
        vm.prank(minter);
        ethEnugu.mintPopUpCityRegistration(); // Changed
        vm.prank(minter);
        vm.expectRevert(EthEnugu.AlreadyMintedPopUpCity.selector); // Changed
        ethEnugu.mintPopUpCityRegistration(); // Changed
    }

    /// @notice Prevent double-conference mint per address
    function testMintingConferenceTwiceReverts() public {
        vm.prank(minter);
        ethEnugu.mintConferenceAttendance();
        vm.prank(minter);
        vm.expectRevert(EthEnugu.AlreadyMintedConference.selector);
        ethEnugu.mintConferenceAttendance();
    }

    /// @notice Prevent double-University Tour mint per address // New test
    function testMintingUniversityTourTwiceReverts() public { // New test
        vm.prank(minter);
        ethEnugu.mintUniversityTour(); // New function call
        vm.prank(minter);
        vm.expectRevert(EthEnugu.AlreadyMintedUniversityTour.selector); // New revert
        ethEnugu.mintUniversityTour(); // New function call
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
        address newAddress = address(0x1234);
        vm.prank(minter);
        vm.expectRevert(EthEnuguResidency.OwnableUnauthorizedAccount.selector);
        ethEnuguResidency.updateAllowedResidencyAddress(newAddress, true);
    }
}
