// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";

contract MockOracle is Ownable2Step {
    uint256 private _price;
    uint48 private _updatedAt;

    constructor(
        address initialOwner,
        uint256 initialPrice
    ) Ownable(initialOwner) {
        _setPrice(initialPrice, uint48(block.timestamp));
    }

    function latestPrice() external view returns (uint256 price, uint256 updatedAt) {
        return (_price, _updatedAt);
    }

    function setPrice(
        uint256 newPrice
    ) external onlyOwner {
        _setPrice(newPrice, uint48(block.timestamp));
    }

    function setPriceWithTimestamp(
        uint256 newPrice,
        uint48 updatedAt
    ) external onlyOwner {
        _setPrice(newPrice, updatedAt);
    }

    function _setPrice(
        uint256 newPrice,
        uint48 updatedAt
    ) internal {
        _price = newPrice;
        _updatedAt = updatedAt;
    }
}
