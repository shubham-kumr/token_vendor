pragma solidity 0.8.20; //Do not change the solidity version as it negatively impacts submission grading
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {
    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event SellTokens(address seller, uint256 amountOfTokens, uint256 amountOfETH);

    YourToken public yourToken;
    uint256 public constant tokensPerEth = 100;

    constructor(address tokenAddress) Ownable(msg.sender) {
        yourToken = YourToken(tokenAddress);
    }

    // Payable function to buy tokens with ETH
    function buyTokens() public payable {
        require(msg.value > 0, "You need to send some ETH");
        
        uint256 amountToBuy = msg.value * tokensPerEth;
        uint256 vendorBalance = yourToken.balanceOf(address(this));
        require(vendorBalance >= amountToBuy, "Vendor contract does not have enough tokens in its balance");

        bool sent = yourToken.transfer(msg.sender, amountToBuy);
        require(sent, "Failed to transfer token to user");

        emit BuyTokens(msg.sender, msg.value, amountToBuy);
    }

    // Function to sell tokens back to the vendor
    function sellTokens(uint256 tokenAmountToSell) public {
        require(tokenAmountToSell > 0, "Specify an amount of token greater than zero");

        uint256 userBalance = yourToken.balanceOf(msg.sender);
        require(userBalance >= tokenAmountToSell, "Your balance is lower than the amount of tokens you want to sell");

        uint256 allowance = yourToken.allowance(msg.sender, address(this));
        require(allowance >= tokenAmountToSell, "Check the token allowance");

        bool sent = yourToken.transferFrom(msg.sender, address(this), tokenAmountToSell);
        require(sent, "Failed to transfer tokens from user to vendor");

        uint256 ethToSend = tokenAmountToSell / tokensPerEth;
        require(address(this).balance >= ethToSend, "Vendor does not have enough ETH to pay for tokens");

        (bool success, ) = msg.sender.call{value: ethToSend}("");
        require(success, "Failed to send ETH to user");

        emit SellTokens(msg.sender, tokenAmountToSell, ethToSend);
    }

    // Withdraw function that lets the owner withdraw ETH
    function withdraw() public onlyOwner {
        uint256 ownerBalance = address(this).balance;
        require(ownerBalance > 0, "Owner has no balance to withdraw");

        (bool success, ) = msg.sender.call{value: ownerBalance}("");
        require(success, "Failed to send ETH to owner");
    }
}
