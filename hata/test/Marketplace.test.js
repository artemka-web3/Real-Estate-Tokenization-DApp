const { AddressZero } = require("@ethersproject/constants");
const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");

describe("Marketplace", function () {
    let marketplace;
    let hataNFT;
    let daoContract;
    let GovToken;
    let govToken;
    let owner;
    let buyer;

    beforeEach(async function () {
        [owner, buyer] = await ethers.getSigners();
        const HataNFT = await ethers.getContractFactory("HataNFT");
        hataNFT = await HataNFT.deploy();
        await hataNFT.deployed();

        GovToken = await ethers.getContractFactory("GovToken");
        govToken = await GovToken.deploy();
        await govToken.deployed();

        const DaoContract = await ethers.getContractFactory("DaoContract");
        daoContract = await DaoContract.deploy(govToken.address);
        await daoContract.deployed();

        const Marketplace = await ethers.getContractFactory("Marketplace");
        marketplace = await Marketplace.deploy(10, 100, hataNFT.address, daoContract.address);
        await marketplace.deployed();


    });

    it("should create and list a new NFT", async function () {
        const tokenId = 0;
        const tokenURI = "https://example.com/token";
        //await hataNFT.safeMint(owner.address, tokenURI);
        await marketplace.connect(owner).createToken(tokenURI);
        await hataNFT.connect(owner).approve(marketplace.address, tokenId)
        //await hataNFT.connect(owner).setApprovalForAll(marketplace.address, true);
    
        await marketplace.createListedToken(tokenId, 100, "Example NFT");
    
        const item = await marketplace.items(tokenId);
        expect(item.itemId).to.equal(tokenId);
        expect(item.description).to.equal("Example NFT");
        expect(item.price).to.equal(100);
        expect(item.seller).to.equal(owner.address);
        expect(item.buyer).to.equal(AddressZero);
        expect(item.sold).to.equal(false);
      });

    // it("should send NFT to DAO for validation", async function () {
    //     const tokenId = 0;
    //     const tokenURI = "https://example.com/token";
    //     await marketplace.connect(owner).createToken(tokenURI);
    //     await hataNFT.connect(owner).approve(marketplace.address, tokenId)
    //     //await hataNFT.connect(owner).setApprovalForAll(marketplace.address, true);
    
    //     await marketplace.createListedToken(tokenId, 100, "Example NFT");
    //     const item = await marketplace.items(tokenId);
    //     expect(item.itemId).to.equal(tokenId);
    //     expect(item.description).to.equal("Example NFT");
    //     expect(item.price).to.equal(100);
    //     expect(item.seller).to.equal(owner.address);
    //     expect(item.buyer).to.equal(AddressZero);
    //     expect(item.sold).to.equal(false);

    //     try {
    //         await marketplace.connect(buyer).sendToDAOForCheck(tokenId, 100);
    //       } catch (error) {
    //         console.log(error);
    //       }
    //     // await daoContract.createValidation(0);
    //     // await daoContract.setBuyer(0, buyer.address);
    //     // await daoContract.setPrice(0, 100);
    //     try {
    //         const validationProposal = await daoContract.validationProposals(0);
    //         expect(validationProposal.id).to.equal(tokenId);
    //         expect(validationProposal.buyer).to.equal(buyer.address);
    //         expect(validationProposal.price).to.equal(100);
    //       } catch (error) {
    //         console.log(error);
    //       }



    // });

});