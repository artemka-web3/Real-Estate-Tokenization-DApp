const { AddressZero } = require('@ethersproject/constants');
const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('DaoContract', function () {
    let DaoContract, daoContract, GovToken, govToken, owner, addr1, addr2;
    beforeEach(async function () {
        [owner, addr1, addr2, _] = await ethers.getSigners();

        // Deploy GovToken
        GovToken = await ethers.getContractFactory("GovToken");
        govToken = await GovToken.deploy();
    
        // Deploy DaoContract
        DaoContract = await ethers.getContractFactory("DaoContract");
        daoContract = await DaoContract.deploy(govToken.address);
    });
    describe('createValidation', function () {
        it('should create a new proposal', async function () {
            await daoContract.connect(addr1).createValidation(0, 100);
            const validationProposal = await daoContract.validationProposals(0);
      
            expect(validationProposal.id).to.equal(0);
            expect(validationProposal.buyer).to.equal(addr1.address);
            expect(validationProposal.price).to.equal(100);
        });
    });
    describe("vote", function(){
        beforeEach(async function(){
            govToken.connect(owner).mint(addr1.address, 0, 1);
            
        });
        it('should allow a GovToken owner to vote', async function(){
            await daoContract.connect(addr2).createValidation(0, 100);
            const validationProposal = await daoContract.validationProposals(0);
            validationProposal.onValidation = true;
            await daoContract.connect(addr1).voteForValid(0);
            const votesForValidHata = await daoContract.allVotesOnHata(0);
            expect(votesForValidHata).to.equal(1);
        });
        it("should not allow non-GovToken owner to vote", async function(){
            await daoContract.connect(addr2).createValidation(0, 100);
            const validationProposal = await daoContract.validationProposals(0);
            validationProposal.onValidation = true;
            await expect(daoContract.connect(addr2).voteForValid(0)).to.be.revertedWith(
                "Don't have GovToken!"
            );
        });
        it("should revert if user already voted", async function(){
            await daoContract.connect(addr2).createValidation(0, 100);
            const validationProposal = await daoContract.validationProposals(0);
            validationProposal.onValidation = true;
            await daoContract.connect(addr1).voteForValid(0);
            const votesForValidHata = await daoContract.allVotesOnHata(0);
            expect(votesForValidHata).to.equal(1);
            await expect(daoContract.connect(addr1).voteForValid(0)).to.be.revertedWith("can't vote more than once!");

        });
        it("should revert if block.timestamp less than item.timestamp", async function(){
            await daoContract.connect(addr2).createValidation(0, 100);
            const validationProposal = await daoContract.validationProposals(0);
            validationProposal.onValidation = true;
            await ethers.provider.send("evm_increaseTime", [2 * 7 * 24 * 60 * 60]);
            await expect(daoContract.connect(addr1).voteForValid(0)).to.be.revertedWith("Voting period has ended");
        })
    });

    describe("unvote", function(){
        let validationProposal;
        beforeEach(async function(){
            govToken.connect(owner).mint(addr1.address, 0, 1);
            await daoContract.connect(addr2).createValidation(0, 100);
            validationProposal = await daoContract.validationProposals(0);
            validationProposal.onValidation = true;
            await daoContract.connect(addr1).voteForValid(0);
        });
        it('should allow a GovToken owner to unvote', async function(){
            await daoContract.connect(addr1).unvote(0);
            const votesForValidHata = await daoContract.allVotesOnHata(0);
            expect(votesForValidHata).to.equal(1);
        });
        it("should not allow an unvoted user to cancel his vote", async function(){
            govToken.connect(owner).mint(addr2.address, 0, 1);
            await expect(daoContract.connect(addr2).unvote(0)).to.be.revertedWith("You didn't vote for that Hata!");
        });
        it("should not allow non-GovToken owner to unvote", async function(){
            await expect(daoContract.connect(addr2).unvote(0)).to.be.revertedWith("Don't have GovToken!");
        });
        it("should revert if block.timestamp less than item.timestamp", async function(){
            await ethers.provider.send("evm_increaseTime", [2 * 7 * 24 * 60 * 60]);
            await expect(daoContract.connect(addr1).unvote(0)).to.be.revertedWith("Voting period has ended");
        });
    });

    describe("resetValidation", function(){
        let validationProposal;
        // beforeEach(async function(){
        //     // set govToken owner
        //     govToken.connect(owner).mint(addr1.address, 0, 1);
        //     // create validation
        //     await daoContract.createValidation(0);
        //     validationProposal = await daoContract.validationProposals(0);
            

        // })
        it("Should reset the validation for the given id and update NFTsBuyerAllowedToBuy", async function () {
            // Mint GovToken for addr1
            await govToken.connect(owner).mint(addr1.address, 0, 1);
      
            // Create a validation
            await daoContract.connect(addr2).createValidation(0, 100);
            
            

      
            // Vote for the validation
            await daoContract.connect(addr1).voteForValid(0);
      
            // Set the validation as not onValidation and update NFTsBuyerAllowedToBuy
            await daoContract.allowToBuy(0);
            const nftsBeforeReset = await daoContract.getNFTsBuyerCanBuy(addr2.address);
            expect(nftsBeforeReset.length).to.equal(1);
            expect(nftsBeforeReset[0]).to.equal(0);
      
            // Check if NFTsBuyerAllowedToBuy is updated

      
            // Reset the validation
            await daoContract.resetValidation(0);
      
            // Check if the validation is reset
            const validation = await daoContract.validationProposals(0);
            expect(validation.id).to.equal(validation.id);
            expect(validation.buyer).to.equal(AddressZero);
            expect(validation.price).to.equal(0);
            expect(validation.timestamp).to.equal(0);
            expect(validation.status).to.equal(false);
            expect(validation.onValidation).to.equal(false);
      
            const allVotes = await daoContract.allVotesOnHata(0);
            expect(allVotes).to.equal(0);
      
            const votesForValid = await daoContract.votesForValidHata(0);
            expect(votesForValid).to.equal(0);
      
            const addressVotes = await daoContract.addressVotesForValidHata(addr1.address, 0);
            expect(addressVotes).to.equal(0);
      
            // Check if NFTsBuyerAllowedToBuy is reset
            const nftsAfterReset = await daoContract.getNFTsBuyerCanBuy(addr2.address);
            expect(nftsAfterReset.length).to.equal(0);
        });
        
        it("should revert if proposal on validation", async function(){
            // expect to revert with ...
            await daoContract.connect(addr2).createValidation(0, 100);
            await expect(daoContract.resetValidation(0)).to.be.revertedWith("Item can't be reset in this moment");
        })
    });

    describe("checkForValidationResult", async function(){
        beforeEach(async function(){
            await govToken.connect(owner).mint(addr1.address, 0, 1);
            await daoContract.connect(addr2).createValidation(0, 100);
            
            await daoContract.connect(addr1).voteForValid(0);
            await ethers.provider.send("evm_increaseTime", [2 * 7 * 24 * 60 * 60]);
        })
        it("should check nft / case: allowToBuy", async function(){
            await daoContract.checkForValidationResult(0);
            const nftsBeforeReset = await daoContract.getNFTsBuyerCanBuy(addr2.address);
            expect(nftsBeforeReset.length).to.equal(1);
            expect(nftsBeforeReset[0]).to.equal(0);
        });

        xit("should check nft / case: not allowed to buy => resetValidation", async function(){

        })
    });
});