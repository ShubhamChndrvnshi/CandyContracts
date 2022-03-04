const { expect } = require("chai");
const { ethers } = require("hardhat");


async function deploySingle() {
  const [owner, candyWallet, royalty1, royalty2] = await ethers.getSigners();
  const CandyCreatorFactory = await ethers.getContractFactory("CandyCreatorV1A");
  const CandyCreator = await CandyCreatorFactory.deploy("TestToken", "TEST", "candystorage/placeholder.json", 1000000000 * 1, 10000, candyWallet.address, false, [], []);
  await CandyCreator.deployed();
  return {contract: CandyCreator, owner: owner, candyWallet: candyWallet, royalty1: royalty1, royalty2: royalty2}; 
}

async function deployMulti() {
  const [owner, candyWallet, royalty1, royalty2] = await ethers.getSigners();
  const CandyCreatorFactory = await ethers.getContractFactory("CandyCreatorV1A");
  const CandyCreator = await CandyCreatorFactory.deploy("TestToken", "TEST", "candystorage/placeholder.json", 1000000000 * 1, 10000, candyWallet.address, true, [owner.address, royalty1.address], [5000, 4500]);
  await CandyCreator.deployed();
  return {contract: CandyCreator, owner: owner, candyWallet: candyWallet, royalty1: royalty1, royalty2: royalty2}; 
}

describe("Payment", function () {

    it("Contract has Correct Balance (Single Mint)", async function() {
        const deployment = await deployMulti()
        CandyCreator = deployment.contract 

        // Enable minting
        await CandyCreator.connect(deployment.owner)
        .enableMinting()
    
        // Get the minting fee
        const fee = await CandyCreator.connect(deployment.owner)
        .mintingFee()
        
        await CandyCreator.connect(deployment.owner)
        .publicMint(1, {
          value: 1 * fee
        })

        await CandyCreator.connect(deployment.owner)
        .publicMint(1, {
          value: 1 * fee
        })

        await CandyCreator.connect(deployment.owner)
        .publicMint(1, {
          value: 1 * fee
        })

        const balance = await CandyCreator.getBalance()
        expect(balance).to.be.equal(3*fee)
    });

    it("Contract has Correct Balance (Batch Mint)", async function() {
        const deployment = await deployMulti()
        CandyCreator = deployment.contract 

        // Enable minting
        await CandyCreator.connect(deployment.owner)
        .enableMinting()

        // Enable minting
        await CandyCreator.connect(deployment.owner)
        .setMaxPublicMints(100)
    
        // Get the minting fee
        const fee = await CandyCreator.connect(deployment.owner)
        .mintingFee()
        
        await CandyCreator.connect(deployment.owner)
        .publicMint(5, {
          value: 5 * fee
        })

        await CandyCreator.connect(deployment.owner)
        .publicMint(45, {
          value: 45 * fee
        })

        await CandyCreator.connect(deployment.owner)
        .publicMint(50, {
          value: 50 * fee
        })

        const balance = await CandyCreator.getBalance()
        expect(balance).to.be.equal(100*fee)
    });

});
