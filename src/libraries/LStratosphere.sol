// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/AppStorage.sol";
import "../interfaces/IStratosphere.sol";

/// @title LStratosphere
/// @notice Library in charge of Stratosphere related logic
library LStratosphere {
    /////////////
    /// LOGIC ///
    /////////////

    /// @notice Get Stratosphere membership details
    /// @param s AppStorage
    /// @param _address Address
    /// @return isStratosphereMember Is Stratosphere member
    /// @return tier Tier
    function getDetails(
        AppStorage storage s,
        address _address
    ) internal view returns (bool isStratosphereMember, uint8 tier) {
        IStratosphere _stratosphere = IStratosphere(s.stratosphereAddress);
        uint256 _tokenId = _stratosphere.tokenIdOf(_address);
        if (_tokenId > 0) {
            isStratosphereMember = true;
            tier = _stratosphere.tierOf(_tokenId);
        }
    }
}
