// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/EthEnugu.sol";

contract EthEnuguTest is Test {
    EthEnugu public ethEnugu;
    address public owner  = address(0xABCD);
    address public minter = address(0xBEEF);
    address public user   = address(0xCAFE);

    function setUp() public {
        // Deploy as owner
        vm.prank(owner);
        ethEnugu = new EthEnugu("EthEnugu", "EE");

        // Grant the Residency minter role to `minter`
        vm.prank(owner);
        ethEnugu.updateAllowedResidencyMinter(minter, true);
    }

    function testOwnerIsAllowedByDefault() public {
        // Owner (by default) can mint a Residency token
        vm.prank(owner);
        ethEnugu.mintBuilderResidency(user);
        assertEq( ethEnugu.ownerOf(1), user );
    }

    function testAuthorizedMinterCanMint() public {
        // minter has been whitelisted: can mint #1
        vm.prank(minter);
        ethEnugu.mintBuilderResidency(user);
        assertEq( ethEnugu.ownerOf(1), user );
    }

    function testUnauthorizedMinterReverts() public {
        address badActor = address(0xDEAD);
        vm.prank(badActor);
        vm.expectRevert("Not allowed");
        ethEnugu.mintBuilderResidency(user);
    }

    function testUpdateAllowedMinterAddsAndRemoves() public {
        // Add a new Residency minter
        vm.prank(owner);
        ethEnugu.updateAllowedResidencyMinter(address(0x1234), true);
        assertTrue( ethEnugu.allowedResidencyMinters(address(0x1234)) );

        // Remove them
        vm.prank(owner);
        ethEnugu.updateAllowedResidencyMinter(address(0x1234), false);
        assertFalse( ethEnugu.allowedResidencyMinters(address(0x1234)) );
    }

    function testNonOwnerCannotUpdateMinters() public {
        address nonOwner = address(0xBADA);
        vm.prank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        ethEnugu.updateAllowedResidencyMinter(minter, false);
    }

    function testSetBaseTokenURIAndTokenURI() public {
        // Change the Residency base URI
        string memory newBase = "https://new.example/api/";
        vm.prank(owner);
        ethEnugu.setResidencyBaseTokenURI(newBase);

        // Mint under the new base
        vm.prank(owner);
        ethEnugu.mintBuilderResidency(user);

        // Check that tokenURI returns newBase + "1.json"
        string memory uri = ethEnugu.tokenURI(1);
        assertEq(uri, string(abi.encodePacked(newBase, "1.json")));
    }

    function testNonOwnerCannotSetBaseURI() public {
        address nonOwner = address(0x7777);
        vm.prank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        ethEnugu.setResidencyBaseTokenURI("https://bad.example/");
    }
}
