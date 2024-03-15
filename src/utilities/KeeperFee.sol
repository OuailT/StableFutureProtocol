// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.22;

import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {StableFutureErrors} from "../libraries/StableFutureErrors.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

import {IOracles} from "../interfaces/IOracles.sol";
import {IGasPriceOracle} from "../interfaces/IGasPriceOracle.sol";
import {IChainlinkAggregatorV3} from "../interfaces/IChainlinkAggregatorV3.sol";

/// @title KeeperFee
/// @notice A dynamic gas fee module to be used on L2s
/// @dev Adapted from Synthetix PerpsV2DynamicFeesModule.
///      See https://sips.synthetix.io/sips/sip-2013

contract KeeperFee is Ownable {
    using Math for uint256;

    // create state variales with their interface as a type

    // ETH price for gas unit converstions
    IChainlinkAggregatorV3 private _ethOracle;

    // Gas price oracle as deployed on Optimism L2 rollups
    IGasPriceOracle private _gasPriceOracle =
        IGasPriceOracle(0x420000000000000000000000000000000000000F);

    // collateral asset pricing reth/USD
    IOracles private _oracleContract;

    // Decimals of SFR tokens
    uint256 private constant _UNIT = 10 ** 18;

    // max period where the price would be considered Stale
    uint256 private constant _STALENESS = 1 days;

    address private _assetToPayWith;
    uint256 private _profitMarginUSD;
    uint256 private _profitMarginPercent;
    uint256 private _keeperFeeUpperBound;
    uint256 private _keeperFeeLowerBound;
    uint256 private gasUnitsL1;
    uint256 private gasUnitsL2;

    constructor(
        address ethOracle,
        address oracleContract,
        address owner,
        address assetToPayWith,
        uint256 profitMarginUSD,
        uint256 profitMarginPercent,
        uint256 keeperFeeUpperBound,
        uint256 keeperFeeLowerBound,
        uint256 gasUnitsL1,
        uint256 gasUnitsL2
    ) {
        // set Contracts
        _ethOracle = IChainlinkAggregatorV3(ethOracle);
        _oracleContract = IOracles(oracleContract);

        // transferOwnerShip
        _transferOwnership(owner);
    }
}
