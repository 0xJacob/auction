const { expect } = require("chai");
const { ethers, waffle } = require("hardhat");

async function deploy(name, ...params) {
  const Contract = await ethers.getContractFactory(name);
  return await Contract.deploy(...params).then(f => f.deployed());
}

describe("Auction", function () {

  let _Dusk = "0xf000000000000000000000000000000000000000";
  let fakeAddress = "0xdead000000000000000000000000000000000000";

  let _firstEpochBeginAt = "12673700";    
  let _epochLength = "1200";              
  let _price = "100000000000000000";      
  let _priceCut = "10000000000000000";    
  let _priceIncrease = "100";             
  let _lowestPrice = "10000000000000000"; 



  before(async function () {

    this.accounts = await ethers.getSigners();

    this.auction = await deploy('Auction');
    this.auction.__Auction_init(
      _Dusk,
      _firstEpochBeginAt,
      _epochLength,
      _price,
      _priceCut,
      _priceIncrease,
      _lowestPrice,
    );

  });

  it("Should successful", async function () {
    await this.auction.bid({ value: ethers.utils.parseEther("0.1") });
  });

  it("Should reverted with price error", async function () {
    await expect(this.auction.bid({ value: ethers.utils.parseEther("0.01") }))
      .to.be.revertedWith('bid_err: msg.value below current sell price.');
  });

  it("Should return the correct new price", async function () {
    await this.auction.bid({ value: ethers.utils.parseEther("0.11") });
    expect(ethers.utils.formatEther(await this.auction.currentPrice())).to.equal("0.121");
  });

  it("Withdrow all bnb by owner", async function () {
    const contractBalance = await waffle.provider.getBalance(this.auction.address);
    await this.auction.withdraw(fakeAddress, contractBalance);
    expect(ethers.utils.formatEther(await waffle.provider.getBalance(fakeAddress))).to.equal(
      ethers.utils.formatEther(contractBalance)
    );
  });

});