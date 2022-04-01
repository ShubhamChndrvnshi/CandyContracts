const { expect } = require("chai");
const { ethers } = require("hardhat");

async function deployFactory() {
  const [owner] = await ethers.getSigners();
  const cloneContractFactory = await ethers.getContractFactory("CandyCreator721ACloneFactory");
  const CandyCreatorCloneFactory = await cloneContractFactory.deploy();
  await CandyCreatorCloneFactory.deployed();
  return { contract: CandyCreatorCloneFactory, owner: owner};
}

describe("Basic Tests", function () {

  it("Deploy Factory", async function () {
    const cloneFactory = await deployFactory()
  });

  it("Deploy Factory and Create Clone", async function () {

    const cloneFactoryDeployment = await deployFactory()
    const cloneFactoryContract = cloneFactoryDeployment.contract
    const newClone = await cloneFactoryContract.connect(cloneFactoryDeployment.owner).callStatic.createToken("TestToken", "TEST", "candystorage/placeholder.json", 1000000000 * 1, 10000, "0x0000000000000000000000000000000000000000000000000000000000000000")
    console.log(`CandyCreator721ACloneFactory.createToken`);
    console.log(`Deployed Address: ${newClone}`)
    
  });

  it("Deploy Factory, Create 100 Clones", async function () {

    const cloneFactoryDeployment = await deployFactory()
    const cloneFactoryContract = cloneFactoryDeployment.contract
    await cloneFactoryContract.connect(cloneFactoryDeployment.owner).createToken("TestToken", "TEST", "candystorage/placeholder.json", 1000000000 * 1, 10000, "0x0000000000000000000000000000000000000000000000000000000000000000")
    await cloneFactoryContract.connect(cloneFactoryDeployment.owner).createToken("TestToken", "TEST", "candystorage/placeholder.json", 1000000000 * 1, 10000, "0x0000000000000000000000000000000000000000000000000000000000000000")
    await cloneFactoryContract.connect(cloneFactoryDeployment.owner).createToken("TestToken", "TEST", "candystorage/placeholder.json", 1000000000 * 1, 10000, "0x0000000000000000000000000000000000000000000000000000000000000000")
    await cloneFactoryContract.connect(cloneFactoryDeployment.owner).createToken("TestToken", "TEST", "candystorage/placeholder.json", 1000000000 * 1, 10000, "0x0000000000000000000000000000000000000000000000000000000000000000")
    await cloneFactoryContract.connect(cloneFactoryDeployment.owner).createToken("TestToken", "TEST", "candystorage/placeholder.json", 1000000000 * 1, 10000, "0x0000000000000000000000000000000000000000000000000000000000000000")
    await cloneFactoryContract.connect(cloneFactoryDeployment.owner).createToken("TestToken", "TEST", "candystorage/placeholder.json", 1000000000 * 1, 10000, "0x0000000000000000000000000000000000000000000000000000000000000000")
    await cloneFactoryContract.connect(cloneFactoryDeployment.owner).createToken("TestToken", "TEST", "candystorage/placeholder.json", 1000000000 * 1, 10000, "0x0000000000000000000000000000000000000000000000000000000000000000")
    await cloneFactoryContract.connect(cloneFactoryDeployment.owner).createToken("TestToken", "TEST", "candystorage/placeholder.json", 1000000000 * 1, 10000, "0x0000000000000000000000000000000000000000000000000000000000000000")
    await cloneFactoryContract.connect(cloneFactoryDeployment.owner).createToken("TestToken", "TEST", "candystorage/placeholder.json", 1000000000 * 1, 10000, "0x0000000000000000000000000000000000000000000000000000000000000000")
    await cloneFactoryContract.connect(cloneFactoryDeployment.owner).createToken("TestToken", "TEST", "candystorage/placeholder.json", 1000000000 * 1, 10000, "0x0000000000000000000000000000000000000000000000000000000000000000")
    //await cloneFactoryContract.connect(cloneFactoryDeployment.owner).createToken("TestToken", "TEST", "candystorage/placeholder.json", 1000000000 * 1, 10000, "0x0000000000000000000000000000000000000000000000000000000000000000")
    //console.log(`CandyCreator721ACloneFactory.createToken`);
    //console.log(`Deployed Address: ${newClone}`)

    //const { interface } = await ethers.getContractFactory('CandyCreator721AUpgradeable');
    //const instance = new ethers.Contract(newClone, interface, cloneFactoryDeployment.owner);
    //await instance.connect(cloneFactoryDeployment.owner).enableMinting()

    
  });

});
