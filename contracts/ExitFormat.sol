// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ERC20Interface {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

// Ideally this would be imported from @connect/vector-withdraw-helpers
// And the interface would match this one (note WithdrawData calldata wd has become bytes calldata cD)
interface WithdrawHelper {
    function execute(bytes calldata cD, uint256 actualAmount) external;
}

library ExitFormat {
    // An Exit is an array of SingleAssetExit (one for each asset)
    // Exit = SingleAssetExit[]

    // A SingleAssetExit specifies
    // * an asset address (0 implies the native asset of the chain: on mainnet, this is ETH)
    // * custom metadata (optional field, can be zero bytes). This might specify how to transfer this particular asset (e.g. target an "ERC20.transfer"' method)
    // * an allocations array
    struct SingleAssetExit {
        address asset;
        bytes metadata;
        Allocation[] allocations;
    }

    // allocations is an ordered array of Allocation.
    // The ordering is important, and may express e.g. a priority order for the exit
    // (which would make a material difference to the final state in the case of running out of gas or funds)
    // Allocations = Allocation[]

    enum AllocationType {simple, withdrawHelper, guarantee}

    // An Allocation specifies
    // * a destination, referring either to an ethereum address or an application-specific identifier
    // * an amount of asset
    // * an allocationType, which directs calling code on how to interpret the allocation
    // * custom metadata (optional field, can be zero bytes). This can be used flexibly by different protocols.
    struct Allocation {
        bytes32 destination;
        uint256 amount;
        uint8 allocationType;
        bytes metadata;
    }

    /**
     * specifies the decoding format for metadata bytes fields
     * received with the WithdrawHelper flag
     */
    struct WithdrawHelperMetaData {
        address callTo;
        bytes callData;
    }

    // We use underscore parentheses to denote an _encodedVariable_
    function encodeExit(SingleAssetExit[] memory exit)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(exit);
    }

    function decodeExit(bytes memory _exit_)
        internal
        pure
        returns (SingleAssetExit[] memory)
    {
        return abi.decode(_exit_, (SingleAssetExit[]));
    }

    function encodeAllocation(Allocation memory allocation)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(allocation);
    }

    function decodeAllocation(bytes memory _allocation_)
        internal
        pure
        returns (Allocation memory)
    {
        return abi.decode(_allocation_, (Allocation));
    }

    /**
     * @notice Executes an exit by paying out assets and calling external contracts
     * @dev Executes an exit by paying out assets and calling external contracts
     * @param exit The exit to be paid out.
     */
    function executeExit(ExitFormat.SingleAssetExit[] memory exit) internal {
        for (uint256 assetIndex = 0; assetIndex < exit.length; assetIndex++) {
            executeSingleAssetExit(exit[assetIndex]);
        }
    }

    /**
     * @notice Executes a single asset exit by paying out the asset and calling external contracts
     * @dev Executes a single asset exit by paying out the asset and calling external contracts
     * @param singleAssetExit The single asset exit to be paid out.
     */
    function executeSingleAssetExit(
        ExitFormat.SingleAssetExit memory singleAssetExit
    ) internal {
        address asset = singleAssetExit.asset;
        for (uint256 j = 0; j < singleAssetExit.allocations.length; j++) {
            require(
                _isAddress(singleAssetExit.allocations[j].destination),
                "Destination is not a zero-padded address"
            );
            address payable destination =
                payable(
                    address(
                        uint160(
                            uint256(singleAssetExit.allocations[j].destination)
                        )
                    )
                );
            uint256 amount = singleAssetExit.allocations[j].amount;
            if (asset == address(0)) {
                (bool success, ) = destination.call{value: amount}(""); //solhint-disable-line avoid-low-level-calls
                require(success, "Could not transfer ETH");
            } else {
                // TODO support other token types via the singleAssetExit.metadata field
                ERC20Interface(asset).transfer(destination, amount);
            }
            if (
                singleAssetExit.allocations[j].allocationType ==
                uint8(AllocationType.withdrawHelper)
            ) {
                WithdrawHelperMetaData memory wd =
                    _parseWithdrawHelper(
                        singleAssetExit.allocations[j].metadata
                    );
                WithdrawHelper(wd.callTo).execute(wd.callData, amount);
            }
        }
    }

    /**
     * @notice Checks whether given destination is a valid Ethereum address
     * @dev Checks whether given destination is a valid Ethereum address
     * @param destination the destination to be checked
     */
    function _isAddress(bytes32 destination) internal pure returns (bool) {
        return uint96(bytes12(destination)) == 0;
    }

    /**
     * @notice Returns a callTo address and callData from metadata bytes
     * @dev Returns a callTo address and callData from metadata bytes
     */
    function _parseWithdrawHelper(bytes memory metadata)
        internal
        pure
        returns (WithdrawHelperMetaData memory)
    {
        return abi.decode(metadata, (WithdrawHelperMetaData));
    }
}
