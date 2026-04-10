// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Errors } from "../libraries/Errors.sol";

interface IAggregatorV3Feed {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract AggregatorV3OracleAdapter {
    IAggregatorV3Feed public immutable FEED;
    uint8 public immutable FEED_DECIMALS;

    constructor(
        IAggregatorV3Feed feed_
    ) {
        if (address(feed_) == address(0)) {
            revert Errors.ZeroAddress();
        }

        FEED = feed_;
        FEED_DECIMALS = feed_.decimals();
    }

    function latestPrice() external view returns (uint256 price, uint256 updatedAt) {
        (, int256 answer,, uint256 updatedAt_,) = FEED.latestRoundData();
        updatedAt = updatedAt_;
        if (answer <= 0) {
            return (0, updatedAt);
        }

        uint256 rawAnswer = uint256(answer);
        if (FEED_DECIMALS == 18) {
            price = rawAnswer;
        } else if (FEED_DECIMALS < 18) {
            price = rawAnswer * 10 ** uint256(18 - FEED_DECIMALS);
        } else {
            price = rawAnswer / 10 ** uint256(FEED_DECIMALS - 18);
        }
    }
}
