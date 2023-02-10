// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "clouds/diamond/LDiamond.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../libraries/AppStorage.sol";
import "../libraries/LPercentages.sol";

error RestakeFacet__InProgressSeason();
error RestakeFacet__HasWithdrawnOrRestaked();

contract RestakeFacet {

    AppStorage s;

    function restake() external {
        uint256 lastSeasonParticipated = s.addressToLastSeasonId[msg.sender];
        if(s.seasons[lastSeasonParticipated].endTimestamp >= block.timestamp) {
        revert RestakeFacet__InProgressSeason();
        }

        if(s.usersData[lastSeasonParticipated][msg.sender].hasWithdrawnOrRestaked == true){
            revert RestakeFacet__HasWithdrawnOrRestaked();
        }
    }


}