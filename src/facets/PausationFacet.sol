// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "clouds/contracts/LDiamond.sol";
import "../libraries/AppStorage.sol";
import "../libraries/LPausable.sol";

/// @title PausationFacet
/// @author mektigboy
/// @notice Facet in charge of the pausation of certain features
/// @dev Utilizes 'LDiamond', 'AppStorage' and 'LPausable'
contract PausationFacet {
    ///////////////////
    /// APP STORAGE ///
    ///////////////////

    AppStorage s;

    /////////////
    /// LOGIC ///
    /////////////

    /// @notice Get if features are currently paused
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
