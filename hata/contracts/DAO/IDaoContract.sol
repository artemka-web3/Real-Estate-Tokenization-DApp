//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IDaoContract {
    // mappings
    function addressVotesForValidHata(address) external view returns (uint);
    function votersOnHata(uint) external view returns (address[] memory);
    function votesForValidHata(uint) external view returns (uint);
    function allVotesOnHata(uint) external view returns (uint);
    function NFTsBuyerAllowedToBuy(address) external view returns (uint[] memory);

    // structs & arrays
    struct Validation{
        uint id;
        address payable buyer;
        uint price;
        uint timestamp;
        bool status;
        bool onValidation;
    } // (will be reset) in array validationProposals
    function validationProposals() external returns(Validation[] memory);

    // functions
    function setBuyer(uint id, address buyer) external;
    function setPrice(uint id, uint price) external;
    function setOnValidation(uint id, bool status) external;

    function createValidation(uint) external;
    function resetValidation(uint) external;
    function checkForValidationResult(uint) external returns(bool);
}