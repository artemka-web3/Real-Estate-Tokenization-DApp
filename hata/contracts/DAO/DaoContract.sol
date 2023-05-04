//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "../GovToken/IGovToken.sol";

contract DaoContract {
    IGovToken public GovTokenInterface;

    // address => (id => votes amount)
    mapping(address => mapping(uint => uint)) public addressVotesForValidHata; // only valid options (will be reset)
    mapping(address => mapping(uint => uint)) public addressVotesForUnvalidHata; // only valid options (will be reset)
    mapping(uint => address[]) public votersOnHata; 

    mapping(uint => uint) public votesForValidHata; // only valid options (will be reset)
    mapping(uint => uint) public votesForUnvalidHata; // only valid options (will be reset)

    mapping(uint => uint) public allVotesOnHata; // (will be reset)
    uint validationTime = 1 weeks;

    mapping(address => uint[]) public NFTsBuyerAllowedToBuy;

    // proposal object
    struct Validation{
        uint id;
        address payable buyer;
        uint price;
        uint timestamp;
        bool status;
        bool onValidation;
    } // (will be reset) in array validationProposals

    // all proposal objects
    Validation [] public validationProposals;

    // only available ones
    Validation [] public availableValidationProposals;



    constructor(address _govToken){
        GovTokenInterface = IGovToken(_govToken);
    }

    function setBuyer(uint id, address buyer) public {
        validationProposals[id].buyer = payable(buyer);
    }
    function setPrice(uint id, uint price) public {
        validationProposals[id].price = price;
    }
    function setOnValidation(uint id, bool status) public {
        validationProposals[id].onValidation = status;
    }
    function createValidation(uint id, uint price) external {
        uint lengthOfValidationProposals = validationProposals.length;
        uint counter;
        if(lengthOfValidationProposals >= 0){
            for(uint i=0; i<lengthOfValidationProposals; i++){
                if(validationProposals[id].id == id){
                    counter+=1;
                }
            }
        }
        if(counter >= 1){
            validationProposals[id].buyer = payable(msg.sender);
            validationProposals[id].price = price;
            validationProposals[id].timestamp = block.timestamp + validationTime;
            validationProposals[id].status = false;
            validationProposals[id].onValidation = true;
        } else if(counter == 0) {
            Validation memory validation = Validation(id, payable(msg.sender), price, block.timestamp + validationTime, false, true);
            validationProposals.push(validation);
        } else if(counter >= 1 && validationProposals[id].buyer != payable(address(0)) && validationProposals[id].timestamp != 0 && validationProposals[id].onValidation == true){
            revert("You can't send proposal to validation because it is already sent on validation by another buyer!");
        }

    } 
    function voteForValid(uint id) external govTokenOwner {
        require(addressVotesForValidHata[msg.sender][id] < 1, "can't vote more than once!");
        require(addressVotesForUnvalidHata[msg.sender][id] < 1, "can't vote more than once!");
        require(validationProposals[id].onValidation == true, "this object is not currently on validation!");
        uint proposalTimestamp = validationProposals[id].timestamp;
        require(block.timestamp <= proposalTimestamp, "Voting period has ended");
        votersOnHata[id].push(msg.sender);
        addressVotesForValidHata[msg.sender][id] ++;
        votesForValidHata[id] ++;
        allVotesOnHata[id] ++;
        // check if allVotesOnHata are equal or more than 50% of all dao members
        // if more than 50% of voters think that R-E is valid
        // send seller request to sell R-E
    }
    function voteForUnvalid(uint id) external govTokenOwner {
        require(addressVotesForValidHata[msg.sender][id] < 1, "can't vote more than once!");
        require(addressVotesForUnvalidHata[msg.sender][id] < 1, "can't vote more than once!");
        require(validationProposals[id].onValidation == true, "this object is not currently on validation!");
        uint proposalTimestamp = validationProposals[id].timestamp;
        require(block.timestamp <= proposalTimestamp, "Voting period has ended");
        votersOnHata[id].push(msg.sender);
        votesForUnvalidHata[id] ++;
        addressVotesForUnvalidHata[msg.sender][id] ++;
        allVotesOnHata[id] ++;
        // check if allVotesOnHata are equal or more than 50% of all dao members
        // if more than 50% of voters think that R-E is valid
        // send seller request to sell R-E
    }
    function unvote(uint id) external govTokenOwner {
        require(addressVotesForValidHata[msg.sender][id] == 1, "You didn't vote for that Hata!");
        require(validationProposals[id].onValidation == true, "this object is not currently on validation!");
        uint proposalTimestamp = validationProposals[id].timestamp;
        require(block.timestamp <= proposalTimestamp, "Voting period has ended");
        addressVotesForValidHata[msg.sender][id] --;
        votesForValidHata[id] --;

    }

    function allowToBuy(uint id) public {
        //requests.push(RequestForAllowance(id, validationProposals[id].buyer, true));
        NFTsBuyerAllowedToBuy[validationProposals[id].buyer].push(id);
        validationProposals[id].onValidation = false;
        validationProposals[id].status = true;

    }
    function isVotingEnded(uint id) public returns(bool isEnded){
        if(validationProposals[id].timestamp < block.timestamp){
            isEnded = true;
            checkForValidationResult(id);
            return isEnded;
        }
        else{
            isEnded = false;
            return isEnded;
        }
    }
    function checkForValidationResult(uint id) public  {
        // require(validationProposals[id].timestamp < block.timestamp, "Can't be validated properly!");
        uint lengthOfBuyerNFTsArray = NFTsBuyerAllowedToBuy[validationProposals[id].buyer].length;
        uint counter;
        if(lengthOfBuyerNFTsArray >= 0){
            for(uint i=0; i<lengthOfBuyerNFTsArray; i++){
                if(NFTsBuyerAllowedToBuy[validationProposals[id].buyer][i] == id){
                    counter+=1;
                }
            }
        }
        if(counter>=1){
            revert("NFT already checked. Buyer already allowed to buy");
        }
        if(validationProposals[id].timestamp < block.timestamp){
            if(allVotesOnHata[id] >= GovTokenInterface.getDaoMembersAmount()){
                if(votesForValidHata[id] >= votesForUnvalidHata[id]){
                    allowToBuy(id);
                } else{
                    validationProposals[id].onValidation = false;
                    validationProposals[id].status = false;
                    resetValidation(id);
                    // take FTK
                }
            } else {
                validationProposals[id].onValidation = false;
                validationProposals[id].status = false;
                resetValidation(id);
                // take FTK
            }
        } else {
            validationProposals[id].onValidation = false;
            // take FTK
        }  
        
    }

    // this function set all values about proposal(id) to zero
    function resetValidation(uint id) public {
        require(validationProposals[id].onValidation == false, "Item can't be reset in this moment");
        uint lengthOfBuyerNFTsArray = NFTsBuyerAllowedToBuy[validationProposals[id].buyer].length;
        NFTsBuyerAllowedToBuy[validationProposals[id].buyer][id] = NFTsBuyerAllowedToBuy[validationProposals[id].buyer][lengthOfBuyerNFTsArray - 1];
        NFTsBuyerAllowedToBuy[validationProposals[id].buyer].pop();

        validationProposals[id] = Validation(id, payable(address(0)), 0,  0, false, false);
        allVotesOnHata[id] = 0;
        for(uint i = 0; i<votersOnHata[id].length; i++){
            addressVotesForValidHata[votersOnHata[id][i]][id] = 0;
        }
        votesForValidHata[id] = 0;

    }

    function getNFTsBuyerCanBuy(address _buyer) external view returns(uint[] memory){
        return NFTsBuyerAllowedToBuy[_buyer];
    }

    // create function which get list of nfts which are on validation
    function getAvailableProposals() external returns(Validation[] memory){
        for(uint i = 0; i < validationProposals.length; i ++){
            if(validationProposals[i].onValidation == true){
                Validation memory availableValidation = Validation(
                    validationProposals[i].id, 
                    validationProposals[i].buyer, 
                    validationProposals[i].price, 
                    validationProposals[i].timestamp, 
                    validationProposals[i].status, 
                    validationProposals[i].onValidation
                );
                availableValidationProposals.push(availableValidation);
            }
        }
        return availableValidationProposals;
    }

    // this function creates / opens validation process in DAO
    // this function called by buyer
    // function sendToDAO(uint id, uint price) external {
    //     require(validationProposals[id].buyer == payable(address(0)), "deal already in process with another buyer!");
    //     require(address(validationProposals[id].buyer).balance >= validationProposals[id].price, "You must have enough ether to buy NFT!");
    //     createValidation(id, msg.sender, price);
    // }

    modifier govTokenOwner() {
        require(GovTokenInterface.balanceOf(msg.sender, 0) >= 1, "Don't have GovToken!");
        _;
    }

}