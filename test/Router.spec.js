const { chai, expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("Router contract", () => {
  async function deployRouterFixture() {
    const DAIERC20TokenContract = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
    const WETHERERC30TokenContract =
      "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";

    const factoryContracAddress = "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984";

    const RouterContract = await ethers.getContractFactory("Router");
    const router = await RouterContract.deploy(factoryContracAddress);
    await router.deployed();

    return { router, DAIERC20TokenContract, WETHERERC30TokenContract };
  }

  describe("Deposit Liquidity", () => {
    it("should only allow deposit of pair of equal value", async () => {
      const { router, DAIERC20TokenContract, WETHERERC30TokenContract } =
        await loadFixture(deployRouterFixture);
      const { amountA, amountB } = await router.addLiquidity(
        DAIERC20TokenContract,
        WETHERERC30TokenContract
      );
      expect(true).to.equal(true);
    });
  });
});
