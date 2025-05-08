pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/EthEnugu.sol";

contract EthEnuguTest is Test {
EthEnugu public ethEnugu;
address public owner = address(0xABCD);
address public minter = address(0xBEEF);
address public user = address(0xCAFE);

function setUp() public {
    vm.prank(owner);
    ethEnugu = new EthEnugu("EthEnugu", "EthEnugu", "https://initial.example/api/");

    // Grant minter role to `minter`
    vm.prank(owner);
    ethEnugu.updateAllowedMinter(minter, true);
}

function testOwnerIsAllowedByDefault() public {
    // Owner should be allowed by default
    vm.prank(owner);
    uint256 tokenId = 1;
    ethEnugu.mintPOAP(user, tokenId);
    assertEq(ethEnugu.ownerOf(tokenId), user);
}

function testAuthorizedMinterCanMint() public {
    vm.prank(minter);
    uint256 tokenId = 2;
    ethEnugu.mintPOAP(user, tokenId);
    assertEq(ethEnugu.ownerOf(tokenId), user);
}

function testUnauthorizedMinterReverts() public {
    address badActor = address(0xDEAD);
    vm.prank(badActor);
    vm.expectRevert("POAPNFT: Not an allowed minter");
    ethEnugu.mintPOAP(user, 3);
}

function testUpdateAllowedMinterAddsAndRemoves() public {
    // Add new minter
    vm.prank(owner);
    ethEnugu.updateAllowedMinter(address(0x1234), true);
    assertTrue(ethEnugu.allowedMinters(address(0x1234)));

    // Remove minter
    vm.prank(owner);
    ethEnugu.updateAllowedMinter(address(0x1234), false);
    assertFalse(ethEnugu.allowedMinters(address(0x1234)));
}

function testNonOwnerCannotUpdateMinters() public {
    address nonOwner = address(0xBADA);
    vm.prank(nonOwner);
    vm.expectRevert("Ownable: caller is not the owner");
    ethEnugu.updateAllowedMinter(minter, false);
}

function testSetBaseTokenURIAndTokenURI() public {
    string memory newBase = "https://new.example/api/";
    vm.prank(owner);
    ethEnugu.setBaseTokenURI(newBase);

    // Mint token under new base URI
    vm.prank(owner);
    ethEnugu.mintPOAP(user, 4);

    string memory uri = ethEnugu.tokenURI(4);
    assertEq(uri, string(abi.encodePacked(newBase, "4")));
}

function testNonOwnerCannotSetBaseURI() public {
    address nonOwner = address(0x7777);
    vm.prank(nonOwner);
    vm.expectRevert("Ownable: caller is not the owner");
    ethEnugu.setBaseTokenURI("https://bad.example/");
}

}
