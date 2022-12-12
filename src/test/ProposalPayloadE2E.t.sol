// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

// testing libraries
import "@forge-std/Test.sol";

// contract dependencies
import {GovHelpers} from "@aave-helpers/GovHelpers.sol";
import {AaveV2Ethereum} from "@aave-address-book/AaveV2Ethereum.sol";
import {AaveAddressBookV2} from "@aave-address-book/AaveAddressBook.sol";
import {ProposalPayload} from "../ProposalPayload.sol";
import {DeployMainnetProposal} from "../../script/DeployMainnetProposal.s.sol";
import {AaveV2Helpers, InterestStrategyValues, IReserveInterestRateStrategy, ReserveConfig} from "./utils/AaveV2Helpers.sol";

contract ProposalPayloadE2ETest is Test {
    ProposalPayload public payload;

    string internal MARKET_NAME = AaveAddressBookV2.AaveV2Ethereum;

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant NEW_INTEREST_RATE_STRATEGY = 0x853844459106feefd8C7C4cC34066bFBC0531722;
    uint16 public constant RESERVE_FACTOR = 1500;

    IReserveInterestRateStrategy public constant OLD_INTEREST_RATE_STRATEGY =
        IReserveInterestRateStrategy(0xEc368D82cb2ad9fc5EfAF823B115A622b52bcD5F);

    IReserveInterestRateStrategy strategy = IReserveInterestRateStrategy(NEW_INTEREST_RATE_STRATEGY);

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"));
    }

    function testProposal() public {
        _modifyStrategy();

        // Post-execution assertations
        ReserveConfig[] memory allConfigs = AaveV2Helpers._getReservesConfigs(false, MARKET_NAME);

        ReserveConfig memory expectedConfig = ReserveConfig({
            symbol: "WETH",
            underlying: WETH,
            aToken: address(0), // Mock, no-validation because of the "dynamic" deployment on proposal execution
            variableDebtToken: address(0), // Mock, no-validation because of the "dynamic" deployment on proposal exec
            stableDebtToken: address(0), // Mock, no-validation because of the "dynamic" deployment on proposal execution
            decimals: 18,
            ltv: 8250,
            liquidationThreshold: 8600,
            liquidationBonus: 10500,
            reserveFactor: 1500,
            usageAsCollateralEnabled: true,
            borrowingEnabled: true,
            interestRateStrategy: NEW_INTEREST_RATE_STRATEGY,
            stableBorrowRateEnabled: true,
            isActive: true,
            isFrozen: false
        });

        AaveV2Helpers._validateReserveConfig(expectedConfig, allConfigs);

        AaveV2Helpers._validateInterestRateStrategy(
            WETH,
            ProposalPayload(payload).INTEREST_RATE_STRATEGY(),
            InterestStrategyValues({
                excessUtilization: 20 * (AaveV2Helpers.RAY / 100),
                optimalUtilization: 80 * (AaveV2Helpers.RAY / 100),
                baseVariableBorrowRate: 0,
                stableRateSlope1: OLD_INTEREST_RATE_STRATEGY.stableRateSlope1(),
                stableRateSlope2: 80 * (AaveV2Helpers.RAY / 100),
                variableRateSlope1: 575 * (AaveV2Helpers.RAY / 10000),
                variableRateSlope2: 80 * (AaveV2Helpers.RAY / 100)
            }),
            MARKET_NAME
        );
    }

    function testUtilizationAtZeroPercent() public {
        _modifyStrategy();

        (uint256 liqRate, uint256 stableRate, uint256 varRate) = strategy.calculateInterestRates(
            WETH,
            100 * 1e18,
            0,
            0,
            68200000000000000000000000,
            RESERVE_FACTOR
        );

        // At nothing borrowed, liquidity rate should be 0, variable rate should be 0 and stable rate should be 3%.
        assertEq(liqRate, 0);
        assertEq(stableRate, 3 * (AaveV2Helpers.RAY / 100));
        assertEq(varRate, 0);
    }

    function testUtilizationAtOneHundredPercent() public {
        _modifyStrategy();

        (uint256 liqRate, uint256 stableRate, uint256 varRate) = strategy.calculateInterestRates(
            WETH,
            0,
            0,
            100 * 1e18,
            68200000000000000000000000,
            RESERVE_FACTOR
        );

        // At max borrow rate, stable rate should be 87% and variable rate should be 85.75%.
        assertEq(liqRate, 728875000000000000000000000);
        assertEq(stableRate, 870000000000000000000000000);
        assertEq(varRate, 857500000000000000000000000);
    }

    function testUtilizationAtUOptimal() public {
        _modifyStrategy();

        (uint256 liqRate, uint256 stableRate, uint256 varRate) = strategy.calculateInterestRates(
            WETH,
            20 * 1e18,
            0,
            80 * 1e18,
            68200000000000000000000000,
            RESERVE_FACTOR
        );

        // At UOptimal, stable rate should be 7% and variable rate should be 5.75%.
        assertEq(liqRate, 39100000000000000000000000);
        assertEq(stableRate, 7 * (AaveV2Helpers.RAY / 100));
        assertEq(varRate, 575 * (AaveV2Helpers.RAY / 10000));
    }

    function _modifyStrategy() internal {
        // 1. Deploy new payload
        payload = new ProposalPayload();

        // 2. create proposal
        vm.startPrank(GovHelpers.AAVE_WHALE);
        uint256 proposalId = DeployMainnetProposal._deployMainnetProposal(
            address(payload),
            0xec9d2289ab7db9bfbf2b0f2dd41ccdc0a4003e9e0d09e40dee09095145c63fb5 // TODO: replace with actual ipfs-hash
        );
        vm.stopPrank();

        // 3. Execute proposal
        GovHelpers.passVoteAndExecute(vm, proposalId);
    }
}
