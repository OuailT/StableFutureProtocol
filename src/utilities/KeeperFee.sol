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

contract KeeperFee is Ownable(msg.sender) {
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
    uint256 private constant _STALENESS_PERIOD = 1 days;

    address private _assetToPayWith;
    uint256 private _profitMarginUSD;
    uint256 private _profitMarginPercent;
    uint256 private _keeperFeeUpperBound;
    uint256 private _keeperFeeLowerBound;
    uint256 private _gasUnitsL1;
    uint256 private _gasUnitsL2;

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

        // transferOwnerShip/ Set the owner.
        _transferOwnership(owner);

        // params
        _assetToPayWith = assetToPayWith;
        _profitMarginUSD = profitMarginUSD;
        _profitMarginPercent = profitMarginPercent;
        _keeperFeeUpperBound = keeperFeeUpperBound; // In USD
        _keeperFeeLowerBound = keeperFeeLowerBound; // In USD
        _gasUnitsL1 = gasUnitsL1;
        _gasUnitsL2 = gasUnitsL2;
    }

    // Function to allow us get the keeperFee on L2
    function getKeeperFee()
        public
        view
        returns (uint256 KeeperFeeInCollateral)
    {
        uint256 ethPrice;

        // Get the current price of ETH in USD from the chainlink oracle
        {
            (, int256 price, uint256 ethPriceUpdatedAt, , ) = _ethOracle
                .latestRoundData();

            if (price <= 0) revert StableFutureErrors.ETHPriceInvalid();

            if (block.timestamp >= ethPriceUpdatedAt + _STALENESS_PERIOD) {
                revert StableFutureErrors.ETHPriceStale();
            }

            ethPrice = uint256(price) * 10 ** 10; // Convert the price from 8 to 18 decimals
        }

        // Get the current price of the collateral RETH/USD
        (uint256 collateralPrice, uint256 timestamp) = _oracleContract
            .getPrice();

        if (collateralPrice <= 0) {
            revert StableFutureErrors.InvalidPrice(
                StableFutureErrors.PriceSource.chainlinkOracle
            );
        }

        if (block.timestamp >= timestamp + _STALENESS_PERIOD) {
            revert StableFutureErrors.PriceStale(
                StableFutureErrors.PriceSource.chainlinkOracle
            );
        }

        // Retrieve on chain values from the _gasPriceOracle.
        uint256 gasPriceL2 = _gasPriceOracle.gasPrice();
        uint256 overhead = _gasPriceOracle.overhead();
        uint256 l1BaseFee = _gasPriceOracle.l1BaseFee();
        uint256 decimals = _gasPriceOracle.decimals();
        uint256 scalar = _gasPriceOracle.scalar();

        //** Compute the keeper fee */
        uint256 costOfExecutionGrossEth = ((((_gasUnitsL1 + overhead) *
            l1BaseFee *
            scalar) / 10 ** decimals) + (_gasUnitsL2 * gasPriceL2));

        // calculate the fee priced in USD
        uint256 costOfExecutionGrossUSD = costOfExecutionGrossEth.mulDiv(
            ethPrice,
            _UNIT
        );

        // additional USD profit for the keeper
        uint256 maxProfitMargin = _profitMarginUSD.max(
            costOfExecutionGrossUSD.mulDiv(_profitMarginPercent, _UNIT)
        );

        // The final cost of execution in USD
        uint256 costOfExecutionNet = costOfExecutionGrossUSD + maxProfitMargin; // fee priced in USD

        // The final cost of execution in the collateral price rETH with 18 decimals
        KeeperFeeInCollateral = (
            _keeperFeeUpperBound.min(
                costOfExecutionNet.max(_keeperFeeLowerBound)
            )
        ).mulDiv(_UNIT, collateralPrice); // fee priced in collateral with 1e18 decimals
    }

    ///@dev Return the current configuration
    function getConfig()
        external
        view
        returns (
            address gasPriceOracle,
            uint256 profitMarginUSD,
            uint256 profitMarginPercent,
            uint256 keeperFeeUpperBound,
            uint256 keeperFeeLowerBound,
            uint256 gasUnitsL1,
            uint256 gasUnitsL2
        )
    {
        gasPriceOracle = address(_gasPriceOracle);
        profitMarginUSD = _profitMarginUSD;
        profitMarginPercent = _profitMarginPercent;
        keeperFeeUpperBound = _keeperFeeUpperBound;
        keeperFeeLowerBound = _keeperFeeLowerBound;
        gasUnitsL1 = _gasUnitsL1;
        gasUnitsL2 = _gasUnitsL2;
    }

    /////////////////////////////////////////////
    //             Owner Functions             //
    /////////////////////////////////////////////

    /// @dev Sets params used for gas price computation.
    function setParameters(
        uint256 profitMarginUSD,
        uint256 profitMarginPercent,
        uint256 keeperFeeUpperBound,
        uint256 keeperFeeLowerBound,
        uint256 gasUnitsL1,
        uint256 gasUnitsL2
    ) external onlyOwner {
        _profitMarginUSD = profitMarginUSD;
        _profitMarginPercent = profitMarginPercent;
        _keeperFeeUpperBound = keeperFeeUpperBound;
        _keeperFeeLowerBound = keeperFeeLowerBound;
        _gasUnitsL1 = gasUnitsL1;
        _gasUnitsL2 = gasUnitsL2;
    }

    /// @dev Sets keeper fee upper and lower bounds.
    /// @param keeperFeeUpperBound The upper bound of the keeper fee in USD.
    /// @param keeperFeeLowerBound The lower bound of the keeper fee in USD.
    function setParameters(
        uint256 keeperFeeUpperBound,
        uint256 keeperFeeLowerBound
    ) external onlyOwner {
        if (keeperFeeUpperBound <= keeperFeeLowerBound)
            revert StableFutureErrors.InvalidFee(keeperFeeLowerBound);
        if (keeperFeeLowerBound == 0)
            revert StableFutureErrors.ZeroValue("keeperFeeLowerBound");

        _keeperFeeUpperBound = keeperFeeUpperBound;
        _keeperFeeLowerBound = keeperFeeLowerBound;
    }

    /// @dev Sets a custom gas price oracle. May be needed for some chain deployments.
    function setGasPriceOracle(address gasPriceOracle) external onlyOwner {
        if (address(gasPriceOracle) == address(0))
            revert StableFutureErrors.ZeroAddress("gasPriceOracle");

        _gasPriceOracle = IGasPriceOracle(gasPriceOracle);
    }
}
