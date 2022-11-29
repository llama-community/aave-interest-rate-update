// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import {AaveV2Ethereum} from "@aave-address-book/AaveV2Ethereum.sol";

interface IProposalGenericExecutor {
    function execute() external;
}

/**
 * @title ETH Interest Rate Curve Update
 * @author Llama
 * @notice Amend ETH interest rate parameters on the Aave Ethereum v2 liquidity pool.
 * Governance Forum Post: https://governance.aave.com/t/arc-eth-interest-rate-curve-update/10580
 * Snapshot: https://snapshot.org/#/aave.eth/proposal/0xc78b467a96d72ea7af7d2f0ffaa4fb9e66a86f457c3f6a39a9936e6c52be1741
 */
contract ProposalPayload is IProposalGenericExecutor {
    address public constant INTEREST_RATE_STRATEGY = 0x2Cbf7856f51660Aae066afAbaBf9C854FA6BD11f;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// @notice The AAVE governance executor calls this function to implement the proposal.
    function execute() external {
        AaveV2Ethereum.POOL_CONFIGURATOR.setReserveInterestRateStrategyAddress(WETH, INTEREST_RATE_STRATEGY);
        AaveV2Ethereum.POOL_CONFIGURATOR.setReserveFactor(WETH, 1500);
    }
}
