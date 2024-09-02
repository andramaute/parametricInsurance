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
        setChainlinkToken(_link);  
        oracle = 0x2f90A6D021db21e1B2A077c5a37B3C7E75D15b7e; // Chainlink Oracle address
        jobId = "29fa9aa13bf1468788b7cc4a500a45b8"; // Chainlink JobID for getting weather data
        fee = 0.1 * 10 ** 18; // 0.1 LINK
    }

    function purchaseInsurance() external payable {
        require(!policyActive, "Policy already active");
        require(msg.value == PREMIUM, "Incorrect premium amount");

        insured = msg.sender;
        startDate = block.timestamp;
        policyActive = true;
        claimPaid = false;
        totalRainfall = 0;

        emit NewPolicy(insured, startDate);
    }

    function requestRainfallData() public {
        require(policyActive, "No active policy");
        require(block.timestamp < startDate + INSURANCE_PERIOD, "Insurance period ended");

        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        request.add("get", "https://api.weather.com/rainfall");
        request.add("path", "result");
        sendChainlinkRequestTo(oracle, request, fee);
    }

    function fulfill(bytes32 _requestId, uint256 _rainfall) public recordChainlinkFulfillment(_requestId) {
        totalRainfall = totalRainfall.add(_rainfall);
        emit RainfallDataReceived(_rainfall);

        if (block.timestamp >= startDate + INSURANCE_PERIOD) {
            settleClaim();
        }
    }

    function settleClaim() internal {
        require(policyActive, "No active policy");
        require(block.timestamp >= startDate + INSURANCE_PERIOD, "Insurance period not ended");
        require(!claimPaid, "Claim already paid");

        if (totalRainfall < RAINFALL_THRESHOLD) {
            uint256 payoutAmount = COVERAGE_AMOUNT;
            claimPaid = true;
            policyActive = false;
            payable(insured).transfer(payoutAmount);
            emit ClaimPaid(insured, payoutAmount);
        } else {
            policyActive = false;
        }
    }

    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }

    // Weitere Funktionen wie withdrawLink()

//function withdrawLink() 
}
