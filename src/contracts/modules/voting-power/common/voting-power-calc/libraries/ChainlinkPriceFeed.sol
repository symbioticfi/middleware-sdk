// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {InputNormalizer} from "../../../../../../contracts/libraries/utils/InputNormalizer.sol";
import {Scaler} from "../../../../../../contracts/libraries/utils/Scaler.sol";

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

library ChainlinkPriceFeed {
    using Math for uint256;
    using InputNormalizer for bytes[];
    using Scaler for uint256;

    error ZeroLength();
    error NotEqualLength();

    uint256 internal constant PHASE_OFFSET = 64;

    uint8 internal constant BASE_DECIMALS = 18;

    struct RoundData {
        uint80 roundId;
        uint256 answer;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
    }

    function getPriceAt(
        address[2] memory aggregators,
        uint48 timestamp,
        bool[2] memory inverts,
        uint48[2] memory stalenessDurations
    ) public view returns (uint256) {
        (address[] memory dynamicAggregators, bool[] memory dynamicInverts, uint48[] memory dynamicStalenessDurations) =
            toDynamicArrays(aggregators, inverts, stalenessDurations);
        return getPriceAt(dynamicAggregators, timestamp, dynamicInverts, dynamicStalenessDurations);
    }

    function getPriceAt(
        address[] memory aggregators,
        uint48 timestamp,
        bool[] memory inverts,
        uint48[] memory stalenessDurations
    ) public view returns (uint256) {
        uint256 length = aggregators.length;
        if (length == 0) {
            revert ZeroLength();
        }
        if (length != inverts.length || length != stalenessDurations.length) {
            revert NotEqualLength();
        }
        uint256 price = 10 ** BASE_DECIMALS;
        for (uint256 i; i < length; ++i) {
            price = price.mulDiv(
                getPriceAt(aggregators[i], timestamp, inverts[i], stalenessDurations[i]), 10 ** BASE_DECIMALS
            );
        }
        return price;
    }

    function getPriceAt(
        address aggregator,
        uint48 timestamp,
        bool invert,
        uint48 stalenessDuration
    ) public view returns (uint256) {
        (bool success, RoundData memory roundData) = getPriceDataAt(aggregator, timestamp, invert, stalenessDuration);
        return success ? roundData.answer : 0;
    }

    function getPriceDataAt(
        address aggregator,
        uint48 timestamp,
        bool invert,
        uint48 stalenessDuration
    ) public view returns (bool success, RoundData memory roundData) {
        (success, roundData) = getRoundDataAt(aggregator, timestamp);
        if (!success || isStale(timestamp, roundData, stalenessDuration)) {
            return (false, roundData);
        }
        roundData.answer = roundData.answer.scale(AggregatorV3Interface(aggregator).decimals(), BASE_DECIMALS);
        if (invert) {
            roundData.answer = roundData.answer.invert(BASE_DECIMALS);
        }
    }

    function getRoundDataAt(
        address aggregator,
        uint48 timestamp
    ) public view returns (bool, RoundData memory roundData) {
        if (timestamp > block.timestamp) {
            return (false, roundData);
        }

        // determine the latest phaseId
        uint16 latestPhaseId;
        {
            (bool latestRoundDataSuccess, RoundData memory latestRoundData) = getLatestRoundData(aggregator);
            if (!latestRoundDataSuccess) {
                return (false, roundData);
            }
            (latestPhaseId,) = deserializeIds(latestRoundData.roundId);
        }

        // find a phaseId which contains a needed aggregatorRoundId given the timestamp
        uint16 phaseId = latestPhaseId;
        for (; phaseId > 0; --phaseId) {
            uint80 roundId = serializeIds(phaseId, 1);
            (bool phaseRoundDataSuccess, RoundData memory phaseRoundData) = getRoundData(aggregator, roundId);
            if (phaseRoundDataSuccess && phaseRoundData.updatedAt <= timestamp) {
                break;
            }
        }
        if (phaseId == 0) {
            return (false, roundData);
        }

        // find the upper bound for further binary search
        uint64 aggregatorRoundId = 1;
        while (true) {
            (bool roundDataSuccess,) = getRoundData(aggregator, serializeIds(phaseId, aggregatorRoundId));
            if (!roundDataSuccess || aggregatorRoundId == type(uint64).max) {
                break;
            }
            aggregatorRoundId <<= 1;
        }

        // find the biggest roundId which which is less than or equal to the timestamp
        uint80 resultRoundId;
        {
            uint80 lowRoundId = serializeIds(phaseId, 1);
            uint80 highRoundId = serializeIds(phaseId, aggregatorRoundId - 1);

            while (lowRoundId <= highRoundId) {
                uint80 midRoundId = lowRoundId + ((highRoundId - lowRoundId) >> 1);
                (bool midRoundDataSuccess, RoundData memory midRoundData) = getRoundData(aggregator, midRoundId);
                if (!midRoundDataSuccess || midRoundData.updatedAt > timestamp) {
                    highRoundId = midRoundId - 1;
                } else {
                    resultRoundId = midRoundId;
                    lowRoundId = midRoundId + 1;
                }
            }
        }
        return getRoundData(aggregator, resultRoundId);
    }

    function getRoundData(address aggregator, uint80 roundId) public view returns (bool, RoundData memory roundData) {
        try AggregatorV3Interface(aggregator).getRoundData(roundId) returns (
            uint80, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound
        ) {
            roundData = RoundData({
                roundId: roundId,
                answer: uint256(answer),
                startedAt: startedAt,
                updatedAt: updatedAt,
                answeredInRound: answeredInRound
            });
            return (roundData.updatedAt > 0, roundData);
        } catch {}
    }

    function getLatestPrice(
        address[2] memory aggregators,
        bool[2] memory inverts,
        uint48[2] memory stalenessDurations
    ) public view returns (uint256) {
        (address[] memory dynamicAggregators, bool[] memory dynamicInverts, uint48[] memory dynamicStalenessDurations) =
            toDynamicArrays(aggregators, inverts, stalenessDurations);
        return getLatestPrice(dynamicAggregators, dynamicInverts, dynamicStalenessDurations);
    }

    function getLatestPrice(
        address[] memory aggregators,
        bool[] memory inverts,
        uint48[] memory stalenessDurations
    ) public view returns (uint256) {
        uint256 length = aggregators.length;
        if (length == 0) {
            revert ZeroLength();
        }
        if (length != inverts.length || length != stalenessDurations.length) {
            revert NotEqualLength();
        }
        uint256 price = 10 ** BASE_DECIMALS;
        for (uint256 i; i < length; ++i) {
            price = price.mulDiv(getLatestPrice(aggregators[i], inverts[i], stalenessDurations[i]), 10 ** BASE_DECIMALS);
        }
        return price;
    }

    function getLatestPrice(address aggregator, bool invert, uint48 stalenessDuration) public view returns (uint256) {
        (bool success, RoundData memory roundData) = getLatestPriceData(aggregator, invert, stalenessDuration);
        return success ? roundData.answer : 0;
    }

    function getLatestPriceData(
        address aggregator,
        bool invert,
        uint48 stalenessDuration
    ) public view returns (bool success, RoundData memory roundData) {
        (success, roundData) = getLatestRoundData(aggregator);
        if (!success || isStale(uint48(block.timestamp), roundData, stalenessDuration)) {
            return (false, roundData);
        }
        roundData.answer = roundData.answer.scale(AggregatorV3Interface(aggregator).decimals(), BASE_DECIMALS);
        if (invert) {
            roundData.answer = roundData.answer.invert(BASE_DECIMALS);
        }
    }

    function getLatestRoundData(
        address aggregator
    ) public view returns (bool, RoundData memory roundData) {
        try AggregatorV3Interface(aggregator).latestRoundData() returns (
            uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound
        ) {
            roundData = RoundData({
                roundId: roundId,
                answer: uint256(answer),
                startedAt: startedAt,
                updatedAt: updatedAt,
                answeredInRound: answeredInRound
            });
            return (roundData.updatedAt > 0, roundData);
        } catch {}
    }

    function isStale(
        uint48 timestamp,
        RoundData memory roundData,
        uint48 stalenessDuration
    ) public pure returns (bool) {
        return roundData.answer == 0 || roundData.answer >= (1 << 255) || roundData.answeredInRound < roundData.roundId
            || roundData.updatedAt + stalenessDuration < timestamp;
    }

    function serializeIds(uint16 phase, uint64 originalId) public pure returns (uint80) {
        return uint80(uint256(phase) << PHASE_OFFSET | originalId);
    }

    function deserializeIds(
        uint80 roundId
    ) public pure returns (uint16, uint64) {
        return (uint16(roundId >> PHASE_OFFSET), uint64(roundId));
    }

    function toDynamicArrays(
        address[2] memory aggregators,
        bool[2] memory inverts,
        uint48[2] memory stalenessDurations
    )
        public
        pure
        returns (
            address[] memory dynamicAggregators,
            bool[] memory dynamicInverts,
            uint48[] memory dynamicStalenessDurations
        )
    {
        dynamicAggregators = new address[](2);
        dynamicInverts = new bool[](2);
        dynamicStalenessDurations = new uint48[](2);
        uint256 length;
        for (uint256 i; i < 2; ++i) {
            if (aggregators[i] != address(0)) {
                dynamicAggregators[length] = aggregators[i];
                dynamicInverts[length] = inverts[i];
                dynamicStalenessDurations[length] = stalenessDurations[i];
                ++length;
            }
        }
        assembly ("memory-safe") {
            mstore(dynamicAggregators, length)
            mstore(dynamicInverts, length)
            mstore(dynamicStalenessDurations, length)
        }
    }
}
