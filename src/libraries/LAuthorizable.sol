// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { AppStorage } from "./AppStorage.sol";

error LAuthorizable__OnlyAuthorized();

/// @title LAuthorizable
library LAuthorizable {
    /////////////
    /// LOGIC ///
    /////////////

    /// @notice Enforce only authorized address can call a certain function
    /// @param s AppStorage
    /// @param _address Address
    function enforceIsAuthorized(AppStorage storage s, address _address) internal view {
        if (!s.authorized[_address]) revert LAuthorizable__OnlyAuthorized();
    }
}
