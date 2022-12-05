# AAVE ETH Interest Rate Strategy Update

This repository contains the payload to update the AAVE V2 WETH Liquity Pool interest rate strategy.

## Specification

The Proposal Payload does the following:

1. Sets the new interest rate strategy address.

The new interest rate strategy is deployed here: https://etherscan.io/address/0x4b8D3277d49E114C8F2D6E0B2eD310e29226fe16

The changes are as follows:

```
==========================================
| Parameter	   Current (%)	Proposed (%)
==========================================
| Uoptimal	  |   70       |  80     |
------------------------------------------
| Base	          |   0        |  0      |
------------------------------------------
| Slope1	  |   3.0      |   5.75  |
------------------------------------------
| Slope2	  |   100      |   80    |
------------------------------------------
| Reserve Factor  |   10       |   15    |
------------------------------------------
```

The function used to set the strategy comes from the `@aave-address-book` library

```
  /**
   * @dev Sets the interest rate strategy of a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param rateStrategyAddress The new address of the interest strategy contract
   **/
  function setReserveInterestRateStrategyAddress(
    address asset,
    address rateStrategyAddress
  ) external;
```

2. Sets the new reserve factor for the liquidity pool:

The function used to set the reserve factor comes from the `@aave-address-book` library

```
/**
   * @dev Updates the reserve factor of a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param reserveFactor The new reserve factor of the reserve
   **/
  function setReserveFactor(address asset, uint256 reserveFactor) external;
```

## Installation

It requires [Foundry](https://github.com/gakonst/foundry) installed to run. You can find instructions here [Foundry installation](https://github.com/gakonst/foundry#installation).

To set up the project manually, run the following commands:

```sh
$ git clone https://github.com/llama-community/aave-interest-rate-update.git
$ cd aave-interest-rate-update/
$ npm install
$ forge install
```

## Setup

Duplicate `.env.example` and rename to `.env`:

- Add a valid mainnet URL for an Ethereum JSON-RPC client for the `RPC_MAINNET_URL` variable.
- Add a valid Private Key for the `PRIVATE_KEY` variable.
- Add a valid Etherscan API Key for the `ETHERSCAN_API_KEY` variable.

### Commands

- `make build` - build the project
- `make test [optional](V={1,2,3,4,5})` - run tests (with different debug levels if provided)
- `make match MATCH=<TEST_FUNCTION_NAME> [optional](V=<{1,2,3,4,5}>)` - run matched tests (with different debug levels if provided)

### Deploy and Verify

- `make deploy-payload` - deploy and verify the payload
- `make deploy-proposal`- deploy proposal on mainnet

To confirm the deploy was successful, re-run your test suite but use the newly created contract address.
