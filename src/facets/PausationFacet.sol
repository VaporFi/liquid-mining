// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "clouds/diamond/LDiamond.sol";
import "../libraries/AppStorage.sol";
import "../libraries/LPausable.sol";

/// @title PausationFacet
/// @notice Facet in charge of the pausation of certain features
/// @dev Utilizes 'LDiamond', 'AppStorage' and 'LPausable'
contract PausationFacet {
    AppStorage s;

    /// @notice Get if features are currently paused
    /// @return bool if features are paused
    function paused() external view returns (bool) {
        return s.paused;
    }

    /// @notice Pause features
    function pause() external {
        LDiamond.enforceIsOwner();

        if (s.paused) revert LPausable__AlreadyPaused();

        s.paused = true;
    }

    /// @notice Unpause features
    function unpause() external {
        LDiamond.enforceIsOwner();

        if (!s.paused) revert LPausable__AlreadyUnpaused();

        s.paused = false;
    }
}
