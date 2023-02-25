pragma solidity 0.8.17;

import "clouds/diamond/LDiamond.sol";

import "../libraries/AppStorage.sol";


contract TestManagerFacet {
    AppStorage s;

    function getDepositToken() external view returns (address) {
        return s.depositToken;
    }

}
