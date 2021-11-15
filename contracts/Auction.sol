// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./interfaces/IDusk.sol";
import "./interfaces/IERC20.sol";

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract Auction is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IDusk public Dusk;

    uint256 public firstEpochBeginAt; // auction begin block number.
    uint256 public epochNumber; // total epoch.
    uint256 public epochLength; // block numbers per epoch.
    uint256 public epochEndAt; // current epoch end at.

    uint256 public priceCut; // decrease sell price per block.
    uint256 public priceIncrement; // increase sell price per sell order. 10 equal 1%
    uint256 public lowestPrice; // the lowest sell price.

    uint256 public currentPrice;

    function __Auction_init(
        address _Dusk,
        uint256 _firstEpochBeginAt,
        uint256 _epochLength,
        uint256 _price,
        uint256 _priceCut,
        uint256 _priceIncrease,
        uint256 _lowestPrice
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        __Auction_init_unchained(
            _Dusk,
            _firstEpochBeginAt,
            _epochLength,
            _price,
            _priceCut,
            _priceIncrease,
            _lowestPrice
        );
    }

    function __Auction_init_unchained(
        address _Dusk,
        uint256 _firstEpochBeginAt,
        uint256 _epochLength,
        uint256 _price,
        uint256 _priceCut,
        uint256 _priceIncrement,
        uint256 _lowestPrice
    ) public onlyOwner {
        require(_price > 0 && _lowestPrice > 0, "init_err: price is zero.");
        require(
            _priceCut > 0 && _priceIncrement > 0,
            "init_err: price change renge is zero."
        );
        require(_Dusk != address(0), "init_err: _duck address is zero.");

        Dusk = IDusk(_Dusk);

        firstEpochBeginAt = _firstEpochBeginAt;
        epochLength = _epochLength;
        epochEndAt = firstEpochBeginAt + epochLength;

        currentPrice = _price;
        priceCut = _priceCut;
        priceIncrement = _priceIncrement;
        lowestPrice = _lowestPrice;
    }

    function bid() external payable nonReentrant whenNotPaused {
        rebase();

        require(
            msg.value >= currentPrice,
            "bid_err: msg.value below current sell price."
        );

        // Dusk.mint();

        currentPrice += (currentPrice * priceIncrement) / 1000;
    }

    function rebase() public {
        if (epochEndAt > block.number) return;

        // block minted less than 1 epoch
        if (block.number - epochEndAt <= epochLength) {
            epochNumber += 1;
            currentPrice -= priceCut;
            epochEndAt += epochLength;
            return;
        }

        // block minted more than 1 epoch length
        uint256 gap = (block.number - epochEndAt) / epochLength;
        epochNumber += gap;
        epochEndAt += epochLength * gap;

        if (currentPrice - priceCut * gap < lowestPrice) {
            currentPrice = lowestPrice;
        } else {
            currentPrice -= priceCut * gap;
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setPrices(
        uint256 _priceCut,
        uint256 _priceIncrement,
        uint256 _lowestPrice
    ) external onlyOwner {
        require(_lowestPrice > 0, "setPrices_err: price is zero.");
        require(
            _priceCut > 0 && _priceIncrement > 0,
            "setPrices_err: price change renge is zero."
        );

        priceCut = _priceCut;
        priceIncrement = _priceIncrement;
        lowestPrice = _lowestPrice;
    }

    function withdraw(address payable _payee, uint256 _amount)
        external
        onlyOwner
    {
        uint256 ownerBalance = address(this).balance;
        require(ownerBalance >= _amount, "withdraw_err: Owner has not enough amount to withdraw.");

        (bool sent, ) = _payee.call{value: _amount}("");
        require(sent, "withdraw_err: Failed to send user balance back to the owner.");
    }
}
