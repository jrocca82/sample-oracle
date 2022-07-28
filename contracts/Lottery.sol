// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/dev/VRFConsumerBase.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery is Ownable, VRFConsumerBase {
     using SafeMath for uint256;
     AggregatorV3Interface internal ethUsdPriceFeed;
     uint256 public usdEntryFee;
     address public recentWinner;
     uint256 public fee;
     bytes32 public keyHash;
     uint256 public randomness;
     address [] public players;

     event RequestedRandomness(bytes32 requestId);

     enum LOTTERY_STATE {OPEN, CLOSED, CALCULATING_WINNER}
     LOTTERY_STATE public lotteryState;

     constructor(
          address _vrfCoordinator, //Find for network at https://docs.chain.link/docs/vrf-contracts/
          address _link, //Find for network at https://docs.chain.link/docs/vrf-contracts/
          bytes32 _keyHash
     ) VRFConsumerBase(
          _vrfCoordinator,
          _link
          )
     {
          ethUsdPriceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
          usdEntryFee = 50;
          fee = 100000000000000000; //0.1 LINK
          lotteryState = LOTTERY_STATE.CLOSED;
          keyHash = _keyHash;
     }

     function enterLottery() public payable {
          require(msg.value >= getEntranceFee(), "Not enough ETH to enter");
          require(lotteryState == LOTTERY_STATE.OPEN, "Lottery not open");
          players.push(msg.sender);
     }

     function getEntranceFee() public view returns(uint256) {
          uint256 precision = 1 * 10 ** 18;
          uint256 price = getLatestEthUsdPrice();
          uint256 costToEnter = (precision / price) * (usdEntryFee * 100000000);
          return costToEnter;
     }

     function getLatestEthUsdPrice() public view returns(uint256) {
          (,int price,,,
          ) = ethUsdPriceFeed.latestRoundData();
          return uint256(price);
     }

     function startLottery() public onlyOwner {
          require(lotteryState == LOTTERY_STATE.CLOSED, "Lottery is already open");
          lotteryState = LOTTERY_STATE.OPEN;
     }

     function endLottery() public onlyOwner {
          require(lotteryState == LOTTERY_STATE.OPEN, "Lottery is not open");
          lotteryState = LOTTERY_STATE.CALCULATING_WINNER;
          pickWinner();
     }

     function pickWinner() private {
          require(lotteryState == LOTTERY_STATE.CALCULATING_WINNER, "Not calculating winner");
          bytes32 requestId = requestRandomness(keyHash, fee);
          fulfillRandomness(requestId, 0);
     }

     function fulfillRandomness(bytes32 requestId, uint256 _randomness) internal override {
          require(_randomness > 0, "Random number not found");
          uint256 index = _randomness % players.length;
          lotteryState = LOTTERY_STATE.CLOSED;
          randomness = _randomness;
          recentWinner = players[index];
          emit RequestedRandomness(requestId);
          address payable winner = payable(players[index]);
          winner.transfer(address(this).balance);
     }
}