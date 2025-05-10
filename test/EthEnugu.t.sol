// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/EthEnugu.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @title EthEnugu Test
 * @dev This contract is a test suite for the EthEnugu NFT contract.
 * It uses the Forge testing framework to validate the functionality of the EthEnugu contract.
 * @author Therock Ani
 * @notice Forge test suite for EthEnugu NFT contract covering minting, access control, URI logic, and reentrancy
 */
contract EthEnuguTest is Test {
    /// @notice Instance of the EthEnugu contract under test
    EthEnugu public ethEnugu;
    /// @notice Predefined owner address with default roles
    address public owner = address(0xABCD);
    /// @notice Secondary minter address granted explicit roles in setUp()
    address public minter = address(0xBEEF);
    /// @notice Generic user address for negative tests
    address public user = address(0xCAFE);

    /// @notice Deploys EthEnugu as owner and assigns all roles to `minter`
    function setUp() public {
        // Simulate calls from owner
        vm.prank(owner);
        ethEnugu = new EthEnugu("EthEnuguNFT", "EEN");

        // Grant each minter role to `minter`
        vm.prank(owner);
        ethEnugu.updateAllowedResidencyMinter(minter, true);
        vm.prank(owner);
        ethEnugu.updateAllowedInVenueMinter(minter, true);
        vm.prank(owner);
        ethEnugu.updateAllowedConferenceMinter(minter, true);
    }

    /// @notice Verifies default base URIs match constructor values
    function testInitialBaseTokenURIs() public {
        assertEq(ethEnugu.residencyBaseTokenURI(), "https://residency.example/api/");
        assertEq(ethEnugu.inVenueBaseTokenURI(), "https://invenue.example/api/");
        assertEq(ethEnugu.conferenceBaseTokenURI(), "https://conference.example/api/");
    }

    /// @notice Ensures tokenURI returns correct Residency metadata path
    function testTokenURIResidency() public {
        vm.prank(minter);
        ethEnugu.mintBuilderResidency();
        string memory expected = string(abi.encodePacked(
            ethEnugu.residencyBaseTokenURI(), "1.json"
        ));
        assertEq(ethEnugu.tokenURI(1), expected);
    }

    /// @notice Ensures tokenURI returns correct InVenue metadata path
    function testTokenURIInVenue() public {
        vm.prank(minter);
        ethEnugu.mintInVenueRegistration();
        string memory expected = string(abi.encodePacked(
            ethEnugu.inVenueBaseTokenURI(), "1.json"
        ));
        assertEq(ethEnugu.tokenURI(1), expected);
    }

    /// @notice Ensures tokenURI returns correct Conference metadata path
    function testTokenURIConference() public {
        vm.prank(minter);
        ethEnugu.mintConferenceAttendance();
        string memory expected = string(abi.encodePacked(
            ethEnugu.conferenceBaseTokenURI(), "1.json"
        ));
        assertEq(ethEnugu.tokenURI(1), expected);
    }

    /// @notice Owner default roles: Residency mint
    function testOwnerIsAllowedByDefaultResidency() public {
        vm.prank(owner);
        ethEnugu.mintBuilderResidency();
        assertEq(ethEnugu.ownerOf(1), owner);
    }

    /// @notice Owner default roles: InVenue mint
    function testOwnerIsAllowedByDefaultInVenue() public {
        vm.prank(owner);
        ethEnugu.mintInVenueRegistration();
        assertEq(ethEnugu.ownerOf(1), owner);
    }

    /// @notice Owner default roles: Conference mint
    function testOwnerIsAllowedByDefaultConference() public {
        vm.prank(owner);
        ethEnugu.mintConferenceAttendance();
        assertEq(ethEnugu.ownerOf(1), owner);
    }

    /// @notice Authorized minter: Residency
    function testAuthorizedMinterCanMintResidency() public {
        vm.prank(minter);
        ethEnugu.mintBuilderResidency();
        assertEq(ethEnugu.ownerOf(1), minter);
    }

    /// @notice Authorized minter: InVenue
    function testAuthorizedMinterCanMintInVenue() public {
        vm.prank(minter);
        ethEnugu.mintInVenueRegistration();
        assertEq(ethEnugu.ownerOf(1), minter);
    }

    /// @notice Authorized minter: Conference
    function testAuthorizedMinterCanMintConference() public {
        vm.prank(minter);
        ethEnugu.mintConferenceAttendance();
        assertEq(ethEnugu.ownerOf(1), minter);
    }

    /// @notice Prevent double-residency mint per address
    function testMintingResidencyTwiceReverts() public {
        vm.prank(minter);
        ethEnugu.mintBuilderResidency();
        vm.prank(minter);
        vm.expectRevert("Residency: already minted");
        ethEnugu.mintBuilderResidency();
    }

    /// @notice Prevent double-inVenue mint per address
    function testMintingInVenueTwiceReverts() public {
        vm.prank(minter);
        ethEnugu.mintInVenueRegistration();
        vm.prank(minter);
        vm.expectRevert("InVenue: already minted");
        ethEnugu.mintInVenueRegistration();
    }

    /// @notice Prevent double-conference mint per address
    function testMintingConferenceTwiceReverts() public {
        vm.prank(minter);
        ethEnugu.mintConferenceAttendance();
        vm.prank(minter);
        vm.expectRevert("Conference: already minted");
        ethEnugu.mintConferenceAttendance();
    }

    /// @notice Unauthorized minter should revert for Residency
    function testUnauthorizedMinterRevertsResidency() public {
        address badActor = address(0xDEAD);
        vm.prank(badActor);
        vm.expectRevert("Not allowed");
        ethEnugu.mintBuilderResidency();
    }

    /// @notice Unauthorized minter should revert for InVenue
    function testUnauthorizedMinterRevertsInVenue() public {
        address badActor = address(0xDEAD);
        vm.prank(badActor);
        vm.expectRevert("Not allowed");
        ethEnugu.mintInVenueRegistration();
    }

    /// @notice Unauthorized minter should revert for Conference
    function testUnauthorizedMinterRevertsConference() public {
        주소 badActor = address(0xDEAD);
        vm.prank(badActor);
        vm.expectRevert("Not allowed");
        ethEnugu.mintConferenceAttendance();
    }

    /// @notice Owner role management: add/remove Residency minter
    function testUpdateAllowedMinterAddsAndRemovesResidency() public {
        vm.prank(owner);
        ethEnugu.updateAllowedResidencyMinter(address(0x1234), true);
        assertTrue(ethEnugu.allowedResidencyMinters(address(0x1234)));
        vm.prank(owner);
        ethEnugu.updateAllowedResidencyMinter(address(0x1234), false);
        assertFalse(ethEnugu.allowedResidencyMinters(address(0x1234)));
    }

    /// @notice Owner role management: add/remove InVenue minter
    function testUpdateAllowedMinterAddsAndRemovesInVenue() public {
        vm.prank(owner);
        ethEnugu.updateAllowedInVenueMinter(address(0x1234), true);
        assertTrue(ethEnugu.allowedInVenueMinters(address(0x1234)));
        vm.prank(owner);
        ethEnugu.updateAllowedInVenueMinter(address(0x1234), false);
        assertFalse(ethEnugu.allowedInVenueMinters(address(0x1234)));
    }

    /// @notice Owner role management: add/remove Conference minter
    function testUpdateAllowedMinterAddsAndRemovesConference() public {
        vm.prank(owner);
        ethEnugu.updateAllowedConferenceMinter(address(0x1234), true);
        assertTrue(ethEnugu.allowedConferenceMinters(address(0x1234)));
        vm.prank(owner);
        ethEnugu.updateAllowedConferenceMinter(address(0x1234), false);
        assertFalse(ethEnugu.allowedConferenceMinters(address(0x1234)));
    }

    /// @notice Only owner can manage Residency minters
    function testNonOwnerCannotAddAndRemoveResidencyMinter() public {
        address nonOwner = address(0x7777);
        vm.prank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        ethEnugu.updateAllowedResidencyMinter(address(0x1234), true);
        vm.prank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        ethEnugu.updateAllowedResidencyMinter(address(0x1234), false);
    }

    /// @notice Only owner can manage InVenue minters
    function testNonOwnerCannotAddAndRemoveInVenueMinter() public {
        address nonOwner = address(0x7777);
        vm.prank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        ethEnugu.updateAllowedInVenueMinter(address(0x1234), true);
        vm.prank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        ethEnugu.updateAllowedInVenueMinter(address(0x1234), false);
    }

    /// @notice Only owner can manage Conference minters
    function testNonOwnerCannotAddAndRemoveConferenceMinter() public {
        address nonOwner = address(0x7777);
        vm.prank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        ethEnugu.updateAllowedConferenceMinter(address(0x1234), true);
        vm.prank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        ethEnugu.updateAllowedConferenceMinter(address(0x1234), false);
    }

    /// @notice Querying tokenURI on nonexistent token should revert
    function testNonExistentTokenURI() public {
        vm.expectRevert("ERC721Metadata: URI query for nonexistent token");
        ethEnugu.tokenURI(999);
    }

    /// @notice Reentrancy guard: Residency mint should block reentrant calls
    function testReentrantResidencyReverts() public {
        MaliciousReceiver evil = new MaliciousReceiver(
            address(ethEnugu),
            minter,
            MaliciousReceiver.Mode.Residency
        );
        vm.prank(owner);
        ethEnugu.updateAllowedResidencyMinter(address(evil), true);
        vm.prank(address(evil));
        vm.expectRevert("ReentrancyGuard: reentrant call");
        ethEnugu.mintBuilderResidency();
    }

    /// @notice Reentrancy guard: InVenue mint should block reentrant calls
    function testReentrantInVenueReverts() public {
        MaliciousReceiver evil = new MaliciousReceiver(
            address(ethEnugu),
            minter,
            MaliciousReceiver.Mode.InVenue
        );
        vm.prank(owner);
        ethEnugu.updateAllowedInVenueMinter(address(evil), true);
        vm.prank(address(evil));
        vm.expectRevert("ReentrancyGuard: reentrant call");
        ethEnugu.mintInVenueRegistration();
    }

    /// @notice Reentrancy guard: Conference mint should block reentrant calls
    function testReentrantConferenceReverts() public {
        MaliciousReceiver evil = new MaliciousReceiver(
            address(ethEnugu),
            minter,
            MaliciousReceiver.Mode.Conference
        );
        vm.prank(owner);
        ethEnugu.updateAllowedConferenceMinter(address(evil), true);
        vm.prank(address(evil));
        vm.expectRevert("ReentrancyGuard: reentrant call");
        ethEnugu.mintConferenceAttendance();
    }
}

/**
 * @title MaliciousReceiver
 * @notice Implements IERC721Receiver to attempt reentrancy during safeMint
 */
contract MaliciousReceiver is IERC721Receiver {
    /// @notice Target contract to attack
    EthEnugu public target;
    /// @notice Mode to determine which mint function to call
    enum Mode { Residency, InVenue, Conference }
    Mode public mode;

    /**
     * @param _target Address of the EthEnugu contract
     * @param _minter Unused in this receiver but kept for signature consistency
     * @param _mode Mode of reentrancy attack
     */
    constructor(address _target, address, Mode _mode) {
        target = EthEnugu(_target);
        mode = _mode;
    }

    /**
     * @notice Called by ERC721 safeMint; triggers a second mint call to test ReentrancyGuard
     * @return selector IERC721Receiver return selector
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external override returns (bytes4) {
        if (mode == Mode.Residency) {
            target.mintBuilderResidency();
        } else if (mode == Mode.InVenue) {
            target.mintInVenueRegistration();
        } else {
            target.mintConferenceAttendance();
        }
        return this.onERC721Received.selector;
    }
}
