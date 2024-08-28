pragma solidity ^0.8.20;

import "./WinnerAddresses.sol";
import "./Treasury.sol";
// Reward Hydra that represents right to mint at floor
import "./PRHydraERC20.sol";
import { IMockERC20 } from "./interfaces/IMockERC20.sol";

struct PlayerInfo {
    uint256 minted; // total minted HYDR in this round
    uint256 prize; // eligible for the prize of how much prHYDR
    bool claimed; // has the prize been claimed yet
    bool isEligibleForPrize; // is eligible for prize
}

contract Minting is WinnerAddresses {
    event MintFromTreasury(
        address indexed paymentToken,
        address indexed minter,
        uint256 indexed roundId,
        uint256 amountInHYDR,
        uint256 avePrice,
        uint256 paymentTokenAmount,
        uint256 increaseFloorPriceTo
    );

    event RewardClaimed(address indexed claimer, uint256 indexed roundId, uint256 amount);

    mapping(address => mapping(uint256 => PlayerInfo)) public plyrRnds;

    HydraTreasury treasury;

    uint256 public slope = 10_000; // = 0.00001 * 10^9
    uint256 public startingMintPrice = 1_000_000_000; // = 10^9
    uint256 public mintPrice = 1_000_000_000; // = 10^9

    PRHydraERC20 public prhydraToken;

    mapping(uint256 => address[]) public rewardsRecords;

    constructor(address _treasury, address _prhydraToken) {
        prhydraToken = PRHydraERC20(_prhydraToken);
        treasury = HydraTreasury(_treasury);
    }

    function getMintingHydrAmount(uint256 _paymentTokenAmount) public view returns (uint256 purchasePrice) {
        // todo: need to adjust to the slope
        return (_paymentTokenAmount / mintPrice) * 10 ** 9;
    }

    function mintHYDR(
        uint256 _minAmountOfHYDR,
        address _paymentToken,
        uint256 _paymentTokenAmount,
        address to
    )
        external
    {
        // update timer and rounds
        bool didRoundEnd = endRoundIfItCan();

        // update mint price
        if (didRoundEnd) {
            mintPrice = startingMintPrice;
        }

        // cal how much hydr will the minter gets
        uint256 hydrWillGet = getMintingHydrAmount(_paymentTokenAmount);
        require(hydrWillGet >= _minAmountOfHYDR, "HYDR WILL BE MINTED IS LOWER THAN MIN");

        // TODO: check whitelisted token

        // send payment
        IMockERC20(_paymentToken).delegateTransferFrom(to, address(treasury), _paymentTokenAmount);

        // mint from treasury
        treasury.mintHYDR(hydrWillGet, to);

        // update player info map
        address overriddenMinter = super.getTheOverriddenMinter();

        plyrRnds[overriddenMinter][rID].isEligibleForPrize = false;
        super.appendAddress(to);

        if (plyrRnds[to][rID].isEligibleForPrize == true) {
            plyrRnds[to][rID].prize += hydrWillGet;
        } else {
            plyrRnds[to][rID].isEligibleForPrize = true;
            plyrRnds[to][rID].prize = hydrWillGet;
        }

        plyrRnds[msg.sender][rID].minted += hydrWillGet;

        // update timer
        updateTimerIfItCan(hydrWillGet);

        // emit event
        emit MintFromTreasury(
            _paymentToken, to, rID, hydrWillGet, mintPrice, _paymentTokenAmount, treasury.getFloorPrice()
        );

        // update mint price
        increaseMintPrice(hydrWillGet);
    }

    function increaseMintPrice(uint256 _amountHYDR) public {
        mintPrice += (slope * _amountHYDR) / 10 ** 18;
    }

    function getReward(address _plyr, uint256 _rID) public view returns (uint256) {
        if (_rID < rID && plyrRnds[_plyr][_rID].isEligibleForPrize && !plyrRnds[_plyr][_rID].claimed) {
            return plyrRnds[_plyr][_rID].prize;
        }

        return 0;
    }

    function secondsToTimerEnds() external view returns (uint256) {
        if (rounds[rID].end > block.timestamp) {
            return rounds[rID].end - block.timestamp;
        }
        return 0;
    }

    function claimReward(uint256 rID, address to) external {
        uint256 reward = getReward(to, rID);
        plyrRnds[to][rID].claimed = true;
        prhydraToken.mint(to, reward);

        emit RewardClaimed(to, rID, reward);
    }
}
