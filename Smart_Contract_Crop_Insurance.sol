// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CropInsurance is ChainlinkClient {
    using SafeMath for uint256;
    using Chainlink for Chainlink.Request;

    AggregatorV3Interface internal priceFeed;
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    uint256 public constant COVERAGE_AMOUNT = 1 ether;
    uint256 public constant PREMIUM = 0.1 ether;
    uint256 public constant RAINFALL_THRESHOLD = 10; // in mm
    uint256 public constant INSURANCE_PERIOD = 30 days;

    address public insured;
    uint256 public startDate;
    uint256 public totalRainfall;
    bool public policyActive;
    bool public claimPaid;

    event NewPolicy(address insured, uint256 startDate);
    event ClaimPaid(address insured, uint256 amount);
    event RainfallDataReceived(uint256 rainfall);

    constructor(address _priceFeed, address _link) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        setChainlinkToken(_link);  // Ersetzen Sie setPublicChainlinkToken() durch setChainlinkToken(_link)
        oracle = 0x2f90A6D021db21e1B2A077c5a37B3C7E75D15b7e; // Chainlink Oracle address
        jobId = "29fa9aa13bf1468788b7cc4a500a45b8"; // Chainlink JobID for getting weather data
        fee = 0.1 * 10 ** 18; // 0.1 LINK
    }

    // Rest des Codes bleibt unverändert
    ...
}
