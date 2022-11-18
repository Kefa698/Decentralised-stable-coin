// SPDX-License-Identifier: MIT

// Collateral: Exogenous
// Minting (Stability Mechanism): Decentralized (Algorithmic)
// Value (Relative Stability): Anchored (Pegged to USD)
// Collateral Type: Crypto

// ExoDRCCoin... Which I'm going to call ExoDaCCoin... ExoDac?

// Sometimes refered to just as "Crypto Collateralized Stablecoin" or "Decentralized Stablecoin"

pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DecentralizedStableCoin is ERC20Burnable, Ownable {
    constructor() ERC20("DecentralizedStableCoin", "DSC") {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        require(_amount > 0, "amount is less than zero");
        require(balance >= _amount, "burn amount exceeds balance");
        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        require(_to != address(0), "sho;dnt be address zero");
        require(_amount > 0, "amount is less tham zero");
        _mint(_to, _amount);
        return true;
    }
}
