// Based VEEEEEEEEEEERY LOOSELY on the MakerDAO DSS System (Dsc)
// Also has some Aave mixed in

/////////////////////////////////////////////////
/******  We are ignoring the following modules: *********/
// System Stabilizer: We are pretending that our liquidation model is good enough
// (It's definetly not)
// https://docs.makerdao.com/smart-contract-modules/system-stabilizer-module

// Oracle Module:
// We use Chainlink instead
// https://docs.makerdao.com/smart-contract-modules/oracle-module

// MKR Module:
// The MKR Module is for governance and a backstop against becoming insolvent.
// This is crucial for production
// https://docs.makerdao.com/smart-contract-modules/mkr-module

// Governance Module:
// See above
// https://docs.makerdao.com/smart-contract-modules/governance-module

// Rates Module:
// We are removing the rates module because we don't have governance
// We could include it more protection against insolvency, but we are going to pretend (again) that our liquidation thresholds are high enough
// https://docs.makerdao.com/smart-contract-modules/rates-module

// Flash Mint Module
// Not necesary
// https://docs.makerdao.com/smart-contract-modules/flash-mint-module

// Emergency Shutdown Module:
// Because
// https://docs.makerdao.com/smart-contract-modules/shutdown
/////////////////////////////////////////////////

/////////////////////////////////////////////////
/******  Included Modules: *********/

// Core Module
// Collateral Module (but wrapped into one contract)
// Liquidation Module (but wrapped into one contract)

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./DecentralizedStableCoin.sol";
import "hardhat/console.sol";

contract DSCEngine {
    uint256 public constant LIQUIDATION_THRESHOLD = 50; //you should be 200% over-collateralised
    uint256 public constant LIQUIDATION_REWARD = 10; //you get 10% discount when liquidating
    uint256 public constant MINIMUM_HEALTH_FACTOR = 1e18;
    DecentralizedStableCoin public immutable i_dsc;

    mapping(address => address) public s_TokenAddressToPriceFeed;
    //user   ->token   ->amount
    mapping(address => mapping(address => uint256)) public s_userToTokenAddressToAmountDeposited;
    //user->amount
    mapping(address => uint256) public s_userToDscMinted;
    address[] public s_collateralTokens;

    modifier moreThanero(uint256 amount) {
        require(amount > 0, "amount should be more than zero");
        _;
    }
    modifier isAllowedToken(address token) {
        require(s_TokenAddressToPriceFeed[token] != address(0), "token is not allowed");
        _;
    }

    constructor(
        address[] memory tokenAdresses,
        address[] memory priceFeedAddress,
        address dscAddress
    ) {
        require(
            tokenAdresses.length == priceFeedAddress.length,
            "priceFeedAddress and tokenAdress do not match"
        );

        //these pricefeed will be in usd pairs
        //like eth/usd or mkr/usd
        for (uint256 i = 0; i < tokenAdresses.length; i++) {
            s_TokenAddressToPriceFeed[tokenAdresses[i]] == priceFeedAddress[i];
            s_collateralTokens.push(tokenAdresses[i]);
        }
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    function healthFacor(address user) public view returns (uint256) {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = getAccountInformation(user);
        if (totalDscMinted == 0) return 100e10;
        uint256 collateralAdjustedThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / 100;
        return (collateralAdjustedThreshold * 1e18) / totalDscMinted;
    }

    function getAccountInformation(address user)
        public
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        totalDscMinted = s_userToDscMinted[user];
        collateralValueInUsd = getAccountCollateralValue(user);
    }

    function getAccountCollateralValue(address user)
        public
        view
        returns (uint256 totalCollateralValueInUsd)
    {
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_userToTokenAddressToAmountDeposited[user][token];
            totalCollateralValueInUsd += getUsdValue(user, amount);
        }
        return totalCollateralValueInUsd;
    }

    function getUsdValue(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_TokenAddressToPriceFeed[token]);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // 1 ETH = 1000 USD
        // The returned value from Chainlink will be 1000 * 1e8
        // Most USD pairs have 8 decimals, so we will just pretend they all do
        // We want to have everything in terms of WEI, so we add 10 zeros at the end
        return ((uint256(price) * 1e10) * amount) / 1e18;
    }

    function getTokenValuFromUsd(address token, uint256 usdAmountInWei)
        public
        view
        returns (uint256)
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_TokenAddressToPriceFeed[token]);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return (uint256(price) * 1e10 * 1e18) / usdAmountInWei;
    }
}
