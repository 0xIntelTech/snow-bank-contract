// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SnowNFT.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor(uint256 initialSupply) ERC20("MockToken", "MTK") {
        _mint(msg.sender, initialSupply);  // Mint initial supply to the sender
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract SnowNFTTest is Test {
    SnowNFT public snowNFT;
    ERC20Mock public scUSD;

    address public owner = address(0x123);
    address public buyer = address(0x456);
    uint256 public price = 1 * 10**6;  // 1 USDC (assuming 6 decimals)

    function setUp() public {
        vm.startPrank(owner); // Impersonate the owner
        scUSD = new ERC20Mock(100 * 1e6);
        snowNFT = new SnowNFT("SnowNFT", "SNFT", "https://example.com/metadata/", address(scUSD));
        snowNFT.transferOwnership(owner);
        scUSD.mint(buyer, 100 * 10**6);  // Mint 100 USDC to buyer
        vm.stopPrank();
    }

    function testBuyNFT() public {
        uint256 initialBalance = scUSD.balanceOf(buyer);

        vm.startPrank(buyer);
        scUSD.approve(address(snowNFT), price * 2);
        snowNFT.buy();
        snowNFT.buy();
        vm.stopPrank();

        uint256 tokenId1 = snowNFT.tokenOfOwnerByIndex(buyer, 0);
        uint256 tokenId2 = snowNFT.tokenOfOwnerByIndex(buyer, 1);

        uint256 finalBalance = scUSD.balanceOf(buyer);
        assertEq(finalBalance, initialBalance - price * 2, "Buyer should have spent correct USDC amount");

        assertEq(snowNFT.ownerOf(tokenId1), buyer, "Buyer should own the first NFT");
        assertEq(snowNFT.ownerOf(tokenId2), buyer, "Buyer should own the second NFT");

        string memory expectedTokenURI1 = string(abi.encodePacked(snowNFT.baseURI(), uint2str(tokenId1), ".png"));
        string memory expectedTokenURI2 = string(abi.encodePacked(snowNFT.baseURI(), uint2str(tokenId2), ".png"));

        assertEq(snowNFT.tokenURI(tokenId1), expectedTokenURI1, "Token URI should be correct");
        assertEq(snowNFT.tokenURI(tokenId2), expectedTokenURI2, "Token URI should be correct");
    }

    function testWithdraw() public {
        vm.startPrank(buyer);
        scUSD.approve(address(snowNFT), price);
        snowNFT.buy();
        vm.stopPrank();

        uint256 initialContractBalance = scUSD.balanceOf(address(snowNFT));
        assertGt(initialContractBalance, 0, "Contract balance should be greater than zero before withdrawal");

        uint256 ownerInitBalance = scUSD.balanceOf(owner);
        vm.startPrank(owner);
        snowNFT.withdraw();
        vm.stopPrank();

        uint256 finalContractBalance = scUSD.balanceOf(address(snowNFT));
        assertEq(finalContractBalance, 0, "Contract balance should be zero after withdrawal");

        uint256 ownerFinalBalance = scUSD.balanceOf(owner);
        assertGt(ownerFinalBalance, ownerInitBalance, "Owner's balance should increase by contract balance");
    }

    function testBuyWithoutApprovalShouldFail() public {
        vm.startPrank(buyer);
        vm.expectRevert("Payment failed");
        snowNFT.buy();
        vm.stopPrank();
    }

    function testBuyWithInsufficientFundsShouldFail() public {
        vm.startPrank(buyer);
        scUSD.approve(address(snowNFT), price);
        scUSD.transfer(address(0x789), scUSD.balanceOf(buyer)); // Drain buyer's balance
        vm.expectRevert("Payment failed");
        snowNFT.buy();
        vm.stopPrank();
    }

    function testWithdrawWithoutBalanceShouldFail() public {
        vm.startPrank(owner);
        vm.expectRevert("No funds to withdraw");
        snowNFT.withdraw();
        vm.stopPrank();
    }

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}