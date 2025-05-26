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
    /// @notice Test email for whitelisting
    string public testEmail = "test@example.com";

    /// @notice Deploys EthEnugu as owner and assigns email whitelist role to `minter`
    function setUp() public {
        // Simulate calls from owner
        vm.prank(owner);
        ethEnugu = new EthEnugu("EthEnuguNFT", "EEN");

        // Grant Residency minting role to `minter`'s email
        vm.prank(owner);
        ethEnugu.updateAllowedResidencyEmail(testEmail, true);
    }

    /// @notice Verifies default base URIs match constructor values
    function testInitialBaseTokenURIs() public view {
        assertEq(ethEnugu.residencyBaseTokenURI(), "https://residency.example/api/");
        assertEq(ethEnugu.inVenueBaseTokenURI(), "https://invenue.example/api/");
        assertEq(ethEnugu.conferenceBaseTokenURI(), "https://conference.example/api/");
    }

    /// @notice Ensures tokenURI returns correct Residency metadata path
    function testTokenURIResidency() public {
        vm.prank(minter);
        ethEnugu.mintBuilderResidency(testEmail);
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

    /// @notice Owner default roles: Residency mint with whitelisted email
    function testOwnerCanMintResidencyWithEmail() public {
        vm.prank(owner);
        ethEnugu.updateAllowedResidencyEmail(testEmail, true);
        vm.prank(owner);
        ethEnugu.mintBuilderResidency(testEmail);
        assertEq(ethEnugu.ownerOf(1), owner);
    }

    /// @notice Authorized email: Residency
    function testAuthorizedEmailCanMintResidency() public {
        vm.prank(minter);
        ethEnugu.mintBuilderResidency(testEmail);
        assertEq(ethEnugu.ownerOf(1), minter);
    }

    /// @notice Minter: InVenue
    function testMinterCanMintInVenue() public {
        vm.prank(minter);
        ethEnugu.mintInVenueRegistration();
        assertEq(ethEnugu.ownerOf(1), minter);
    }

    /// @notice Minter: Conference
    function testMinterCanMintConference() public {
        vm.prank(minter);
        ethEnugu.mintConferenceAttendance();
        assertEq(ethEnugu.ownerOf(1), minter);
    }

    /// @notice Prevent double-residency mint per address
    function testMintingResidencyTwiceReverts() public {
        vm.prank(minter);
        ethEnugu.mintBuilderResidency(testEmail);
        vm.prank(minter);
        vm.expectRevert("Residency: already minted");
        ethEnugu.mintBuilderResidency(testEmail);
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

    /// @notice Unauthorized email should revert for Residency
    function testUnauthorizedEmailRevertsResidency() public {
        string memory badEmail = "unauthorized@example.com";
        vm.prank(user);
        vm.expectRevert("EthEnugu: email not allowed");
        ethEnugu.mintBuilderResidency(badEmail);
    }

    /// @notice Owner role management: add/remove Residency email
    function testUpdateAllowedEmailAddsAndRemovesResidency() public {
        string memory newEmail = "new@example.com";
        bytes32 emailHash = keccak256(abi.encodePacked(newEmail));
        vm.prank(owner);
        ethEnugu.updateAllowedResidencyEmail(newEmail, true);
        assertTrue(ethEnugu.allowedResidencyEmails(emailHash));
        vm.prank(owner);
        ethEnugu.updateAllowedResidencyEmail(newEmail, false);
        assertFalse(ethEnugu.allowedResidencyEmails(emailHash));
    }

    /// @notice Only owner can manage Residency emails
    function testNonOwnerCannotAddAndRemoveResidencyEmail() public {
        string memory newEmail = "new@example.com";
        address nonOwner = address(0x7777);
        vm.prank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        ethEnugu.updateAllowedResidencyEmail(newEmail, true);
        vm.prank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        ethEnugu.updateAllowedResidencyEmail(newEmail, false);
    }

    /// @notice Querying tokenURI on nonexistent token should revert
    function testNonExistentTokenURI() public {
        vm.expectRevert("ERC721: URI query for nonexistent token");
        ethEnugu.tokenURI(999);
    }

    /// @notice Reentrancy guard: Residency mint should block reentrant calls
    function testReentrantResidencyReverts() public {
        MaliciousReceiver evil = new MaliciousReceiver(
            address(ethEnugu),
            testEmail,
            MaliciousReceiver.Mode.Residency
        );
        vm.prank(owner);
        ethEnugu.updateAllowedResidencyEmail(testEmail, true);
        vm.prank(address(evil));
        vm.expectRevert("ReentrancyGuard: reentrant call");
        ethEnugu.mintBuilderResidency(testEmail);
    }

    /// @notice Reentrancy guard: InVenue mint should block reentrant calls
    function testReentrantInVenueReverts() public {
        MaliciousReceiver evil = new MaliciousReceiver(
            address(ethEnugu),
            testEmail,
            MaliciousReceiver.Mode.InVenue
        );
        vm.prank(address(evil));
        vm.expectRevert("ReentrancyGuard: reentrant call");
        ethEnugu.mintInVenueRegistration();
    }

    /// @notice Reentrancy guard: Conference mint should block reentrant calls
    function testReentrantConferenceReverts() public {
        MaliciousReceiver evil = new MaliciousReceiver(
            address(ethEnugu),
            testEmail,
            MaliciousReceiver.Mode.Conference
        );
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
    /// @notice Email to use for Residency mint attempts
    string public email;

    /**
     * @param _target Address of the EthEnugu contract
     * @param _email Email for Residency mint attempts
     * @param _mode Mode of reentrancy attack
     */
    constructor(address _target, string memory _email, Mode _mode) {
        target = EthEnugu(_target);
        email = _email;
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
            target.mintBuilderResidency(email);
        } else if (mode == Mode.InVenue) {
            target.mintInVenueRegistration();
        } else {
            target.mintConferenceAttendance();
        }
        return this.onERC721Received.selector;
    }
}