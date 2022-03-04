const { expect } = require("chai");
const { ethers } = require("hardhat");
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');

async function deploySingle() {
  const [owner, candyWallet, s1, s2, s3, s4, s5] = await ethers.getSigners();
  const CandyCreatorFactory = await ethers.getContractFactory("CandyCreatorV1A");
  const CandyCreator = await CandyCreatorFactory.deploy("TestToken", "TEST", "candystorage/placeholder.json", 1000000000 * 1, 1000, candyWallet.address, false, [], []);
  await CandyCreator.deployed();
  return {contract: CandyCreator, owner: owner, candyWallet: candyWallet, shareholder1: s1, shareholder2: s2, shareholder3: s3, shareholder4: s4, shareholder5: s5}; 
}

async function deployMulti() {
  const [owner, candyWallet, royalty1, royalty2] = await ethers.getSigners();
  const CandyCreatorFactory = await ethers.getContractFactory("CandyCreatorV1A");
  const CandyCreator = await CandyCreatorFactory.deploy("TestToken", "TEST", "candystorage/placeholder.json", 1000000000 * 1, 3, candyWallet.address, true, [owner.address, royalty1.address], [5000, 4500]);
  await CandyCreator.deployed();
  return {contract: CandyCreator, owner: owner, candyWallet: candyWallet, royalty1: royalty1, royalty2: royalty2}; 
}

describe("Voting", function () {

  it("Can't vote unless proposal is active", async function() {
    const deployment = await deploySingle()
    CandyCreator = deployment.contract 

    // Enable minting
    await CandyCreator.connect(deployment.owner)
    .enableMinting()

    // Get price 
    const fee = await CandyCreator.connect(deployment.shareholder1)
    .mintingFee()

    // Mint 25 tokens to 4 shareholders each (100 tokens)
    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder1)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder2)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder3)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder4)
      .publicMint(1, {value: fee*1})
    }
    
    await expect(CandyCreator.connect(deployment.shareholder1)
    .vote(true)).to.be.revertedWith("Proposal is not active")

  });

  it("Can't propose another vote when proposal active", async function() {
    const deployment = await deploySingle()
    CandyCreator = deployment.contract 

    // Enable minting
    await CandyCreator.connect(deployment.owner)
    .enableMinting()

    // Get price 
    const fee = await CandyCreator.connect(deployment.shareholder1)
    .mintingFee()

    // Mint 25 tokens to 4 shareholders each (100 tokens)
    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder1)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder2)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder3)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder4)
      .publicMint(1, {value: fee*1})
    }

    const proposal = await CandyCreator.connect(deployment.owner)
    .proposeRelease(1000)
    
    await expect(CandyCreator.connect(deployment.owner)
    .proposeRelease(1000)).to.be.revertedWith("Release already proposed by contract owner")

  });

  it("Only token holders can vote", async function() {
    const deployment = await deploySingle()
    CandyCreator = deployment.contract 

    // Enable minting
    await CandyCreator.connect(deployment.owner)
    .enableMinting()

    // Get price 
    const fee = await CandyCreator.connect(deployment.shareholder1)
    .mintingFee()

    // Mint 25 tokens to 4 shareholders each (100 tokens)
    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder1)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder2)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder3)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder4)
      .publicMint(1, {value: fee*1})
    }

    const proposal = await CandyCreator.connect(deployment.owner)
    .proposeRelease(1000)
    
    await expect(CandyCreator.connect(deployment.shareholder5)
    .vote(true)).to.be.revertedWith("User does not own any tokens")

  });

  it("Only owner can propose release", async function() {
    const deployment = await deploySingle()
    CandyCreator = deployment.contract 

    // Enable minting
    await CandyCreator.connect(deployment.owner)
    .enableMinting()

    // Get price 
    const fee = await CandyCreator.connect(deployment.shareholder1)
    .mintingFee()

    // Mint 25 tokens to 4 shareholders each (100 tokens)
    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder1)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder2)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder3)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder4)
      .publicMint(1, {value: fee*1})
    }

    await expect(CandyCreator.connect(deployment.shareholder1)
    .proposeRelease(1000)).to.be.revertedWith("Owner: caller is not the Owner")

  });

  it("First proposal number is 1", async function() {
    const deployment = await deploySingle()
    CandyCreator = deployment.contract 

    // Enable minting
    await CandyCreator.connect(deployment.owner)
    .enableMinting()

    // Get price 
    const fee = await CandyCreator.connect(deployment.shareholder1)
    .mintingFee()

    // Mint 25 tokens to 4 shareholders each (100 tokens)
    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder1)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder2)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder3)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder4)
      .publicMint(1, {value: fee*1})
    }

    const proposed = await CandyCreator.connect(deployment.owner)
    .proposeRelease(1000)

    const proposalNumber = await CandyCreator.connect(deployment.owner)
    .latestProposal()

    expect(proposalNumber).to.be.equal(1)
  });

  it("Can't vote twice", async function() {
    const deployment = await deploySingle()
    CandyCreator = deployment.contract 

    // Enable minting
    await CandyCreator.connect(deployment.owner)
    .enableMinting()

    // Get price 
    const fee = await CandyCreator.connect(deployment.shareholder1)
    .mintingFee()

    // Mint 25 tokens to 4 shareholders each (100 tokens)
    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder1)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder2)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder3)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder4)
      .publicMint(1, {value: fee*1})
    }

    const proposal = await CandyCreator.connect(deployment.owner)
    .proposeRelease(5000)
    
    await CandyCreator.connect(deployment.shareholder1)
    .vote(true)

    await expect(CandyCreator.connect(deployment.shareholder1)
    .vote(true)).to.be.revertedWith("User has already voted on current proposal")

    await expect(CandyCreator.connect(deployment.shareholder1)
    .vote(false)).to.be.revertedWith("User has already voted on current proposal")

  });

  it("Proposal must reach over 60% quorum", async function() {
    const deployment = await deploySingle()
    CandyCreator = deployment.contract 

    // Enable minting
    await CandyCreator.connect(deployment.owner)
    .enableMinting()

    // Get price 
    const fee = await CandyCreator.connect(deployment.shareholder1)
    .mintingFee()

    // Mint 25 tokens to 4 shareholders each (100 tokens)
    for (var i = 0; i < 95; i++) {
      await CandyCreator.connect(deployment.shareholder1)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 1; i++) {
      await CandyCreator.connect(deployment.shareholder2)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 2; i++) {
      await CandyCreator.connect(deployment.shareholder3)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 2; i++) {
      await CandyCreator.connect(deployment.shareholder4)
      .publicMint(1, {value: fee*1})
    }

    const proposal = await CandyCreator.connect(deployment.owner)
    .proposeRelease(5000)
    
    await CandyCreator.connect(deployment.shareholder2)
    .vote(true)

    await CandyCreator.connect(deployment.shareholder3)
    .vote(true)

    await CandyCreator.connect(deployment.shareholder4)
    .vote(true)

    await expect(CandyCreator.connect(deployment.owner)
    .release()).to.be.revertedWith("Proposal did not pass")

  });

  it("Candy Wallet can always withdraw guaranteed 5% of mint earnings", async function() {
    const deployment = await deploySingle()
    CandyCreator = deployment.contract 

    // Enable minting
    await CandyCreator.connect(deployment.owner)
    .enableMinting()

    // Get price 
    const fee = await CandyCreator.connect(deployment.shareholder1)
    .mintingFee()

    // Mint 25 tokens to 4 shareholders each (100 tokens)
    for (var i = 0; i < 95; i++) {
      await CandyCreator.connect(deployment.shareholder1)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 1; i++) {
      await CandyCreator.connect(deployment.shareholder2)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 2; i++) {
      await CandyCreator.connect(deployment.shareholder3)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 2; i++) {
      await CandyCreator.connect(deployment.shareholder4)
      .publicMint(1, {value: fee*1})
    }

    const proposal = await CandyCreator.connect(deployment.owner)
    .proposeRelease(5000)

    await CandyCreator.connect(deployment.candyWallet)
    .platformRelease()

    await CandyCreator.connect(deployment.candyWallet)
    .platformRelease()


  });

  it("Minting and transfers paused during voting period", async function() {
    const deployment = await deploySingle()
    CandyCreator = deployment.contract 

    // Enable minting
    await CandyCreator.connect(deployment.owner)
    .enableMinting()

    // Get price 
    const fee = await CandyCreator.connect(deployment.shareholder1)
    .mintingFee()

    // Mint 25 tokens to 4 shareholders each (100 tokens)
    for (var i = 0; i < 95; i++) {
      await CandyCreator.connect(deployment.shareholder1)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 1; i++) {
      await CandyCreator.connect(deployment.shareholder2)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 2; i++) {
      await CandyCreator.connect(deployment.shareholder3)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 1; i++) {
      await CandyCreator.connect(deployment.shareholder4)
      .publicMint(1, {value: fee*1})
    }

    const proposal = await CandyCreator.connect(deployment.owner)
    .proposeRelease(5000)

    // Test whitelist mint as well 

    await expect(CandyCreator.connect(deployment.shareholder4)
    .publicMint(1, {value: fee*1})).to.be.revertedWith("Can't mint during an active proposal")

    await expect(CandyCreator.connect(deployment.shareholder4)
    .transferFrom(deployment.shareholder4.address, deployment.shareholder1.address, 99)).to.be.revertedWith("Token transfers are paused during voting period")

  });

  it("Withdrawal proposal should pass with enough votes", async function() {
    const deployment = await deploySingle()
    CandyCreator = deployment.contract 

    // Enable minting
    await CandyCreator.connect(deployment.owner)
    .enableMinting()

    // Get price 
    const fee = await CandyCreator.connect(deployment.shareholder1)
    .mintingFee()

    // Mint 25 tokens to 4 shareholders each (100 tokens)
    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder1)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder2)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder3)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder4)
      .publicMint(1, {value: fee*1})
    }

    const proposal = await CandyCreator.connect(deployment.owner)
    .proposeRelease(5000)
    
    await CandyCreator.connect(deployment.shareholder1)
    .vote(true)

    await CandyCreator.connect(deployment.shareholder2)
    .vote(true)

    await CandyCreator.connect(deployment.shareholder3)
    .vote(true)

    const release = await CandyCreator.connect(deployment.owner)
    .release()

  });

  it("Refund should occur with enough votes", async function() {
    const deployment = await deploySingle()
    CandyCreator = deployment.contract 

    // Enable minting
    await CandyCreator.connect(deployment.owner)
    .enableMinting()

    // Get price 
    const fee = await CandyCreator.connect(deployment.shareholder1)
    .mintingFee()

    // Mint 25 tokens to 4 shareholders each (100 tokens)
    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder1)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder2)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder3)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder4)
      .publicMint(1, {value: fee*1})
    }

    const proposal = await CandyCreator.connect(deployment.owner)
    .proposeRelease(5000)
    
    await CandyCreator.connect(deployment.shareholder1)
    .vote(false)

    await CandyCreator.connect(deployment.shareholder2)
    .vote(false)

    await CandyCreator.connect(deployment.shareholder3)
    .vote(false)

    await expect(CandyCreator.connect(deployment.owner)
    .release()).to.be.revertedWith("Proposal did not pass")

    await CandyCreator.connect(deployment.shareholder1)
    .refundRelease()

    await CandyCreator.connect(deployment.shareholder2)
    .refundRelease()

    await CandyCreator.connect(deployment.shareholder3)
    .refundRelease()

    await CandyCreator.connect(deployment.shareholder4)
    .refundRelease()



  });

  it("Can't refund account more than once", async function() {
    const deployment = await deploySingle()
    CandyCreator = deployment.contract 

    // Enable minting
    await CandyCreator.connect(deployment.owner)
    .enableMinting()

    // Get price 
    const fee = await CandyCreator.connect(deployment.shareholder1)
    .mintingFee()

    // Mint 25 tokens to 4 shareholders each (100 tokens)
    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder1)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder2)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder3)
      .publicMint(1, {value: fee*1})
    }

    for (var i = 0; i < 25; i++) {
      await CandyCreator.connect(deployment.shareholder4)
      .publicMint(1, {value: fee*1})
    }

    const proposal = await CandyCreator.connect(deployment.owner)
    .proposeRelease(5000)
    
    await CandyCreator.connect(deployment.shareholder1)
    .vote(false)

    await CandyCreator.connect(deployment.shareholder2)
    .vote(false)

    await CandyCreator.connect(deployment.shareholder3)
    .vote(false)

    await expect(CandyCreator.connect(deployment.owner)
    .release()).to.be.revertedWith("Proposal did not pass")

    await CandyCreator.connect(deployment.shareholder1)
    .refundRelease()

    await CandyCreator.connect(deployment.shareholder2)
    .refundRelease()

    await expect(CandyCreator.connect(deployment.shareholder2)
    .refundRelease()).to.be.revertedWith("Refund already claimed")

  });




  

 
});
