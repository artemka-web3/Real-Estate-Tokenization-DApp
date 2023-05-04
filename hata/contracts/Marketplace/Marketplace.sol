//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "../HataNFT/HataNFT.sol";
import "../DAO/IDaoContract.sol";


contract Marketplace {

    // HataNFT  
    HataNFT public immutable hataNFT;


    //mapping(uint => bool) public allowedToBeSold;

    // marketplace fees
    address payable public immutable marketplaceFeeAccount; 
    uint public immutable marketplaceFeePercent;

    // dao fees
    address payable public immutable daoFeeAccount;
    uint public immutable daoFeeAmount;


    uint public itemCount; 
    struct Validation{
        uint id;
        address payable buyer;
        uint price;
        uint timestamp;
        bool status;
        bool onValidation;
    } 
    struct Item {
        uint itemId;
        uint tokenId;
        string description;
        uint price;
        address payable seller;
        address payable buyer;
        bool sold;
    }
    mapping(uint => Item) public items;

    IDaoContract public Idao;  

    constructor(uint _feePercent, uint _daoFeeAmount, HataNFT _hataNFT, address _daoContractAddress){
        // marketplace
        marketplaceFeePercent = _feePercent;
        marketplaceFeeAccount = payable(msg.sender);

        // dao
        daoFeeAccount = payable(msg.sender);
        daoFeeAmount = _daoFeeAmount;
        Idao = IDaoContract(_daoContractAddress);

        // hataNFT
        hataNFT = _hataNFT;


    }
    function setBuyer(uint id, address buyer) public {
        items[id].buyer = payable(buyer);
    }
    function setPrice(uint id, uint price) public {
        items[id].price = price;
    }
    // mint NFT button and list to marketplace
    function createToken(string memory _tokenURI) public {
        itemCount += 1; // nfts counts from 1
        hataNFT.safeMint(msg.sender, _tokenURI);
    }
    function createListedToken(uint256 tokenId, uint256 price, string memory description) public {
        //Just sanity check
        require(price > 0, "Make sure the price isn't negative");

        //Update the mapping of tokenId's to Token details, useful for retrieval functions
        items[tokenId] = Item(
            tokenId,
            tokenId,
            description,
            price,
            payable(msg.sender),
            payable(address(0)),
            false
        );

        hataNFT.transferFrom(msg.sender, address(this), tokenId);
        //Emit the event for successful transfer. The frontend parses this message and updates the end user
    }

    // function happens whe  buyer click on button in second time after check
    function buyNFT(uint id) external payable{
        uint _totalPrice = getTotalPrice(id);
        Item storage item = items[id];
        require(id > 0 && id <= itemCount, "item doesn't exist");
        require(msg.value >= item.price, "not enough ether to cover item price and market fee");
        require(item.sold == false, "item already sold");
        require(item.buyer == msg.sender, "You are not buyer of that NFT!");
        require(Idao.validationProposals()[id].status == true, "item is not valid so you can't buy it!");
        //require(item.isValid == true, "Item is not valid, so you can't but it!");
        //require(checkForValidationResult(id) == true, "Not valid so you can't buy it");

        item.seller.transfer(item.price);
        marketplaceFeeAccount.transfer(_totalPrice - item.price);
        item.sold = true;

        Idao.resetValidation(id);
        hataNFT.transferFrom(address(this), msg.sender, item.tokenId);
    }

    // function sendToDAOForCheck(uint id, uint _price) public {
    //     Idao.createValidation(id);
    //     IDaoContract.Validation[] memory proposals = Idao.validationProposals();
    //     for (uint i = 0; i < proposals.length; i++) {
    //         if (proposals[i].id == id) {
    //             // Found the proposal with id = 0
    //             Idao.setBuyer(id, msg.sender);
    //             setBuyer(id, msg.sender);
    //             bool status = true;
    //             Idao.setOnValidation(id, status);
    //             //DaoContract.validationProposals[i].onValidation = true;
    //             Idao.setPrice(id, _price);
    //             //DaoContract.validationProposals[i].price = _price;
    //         }
    //     }
    // }
    function getTotalPrice(uint _itemId) view public returns(uint){
        return((items[_itemId].price*(100 + marketplaceFeePercent))/100);
    }


}