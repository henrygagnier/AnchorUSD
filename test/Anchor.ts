import { expect } from "chai";
import { ethers } from "hardhat";
import { EvmPriceServiceConnection } from "@pythnetwork/pyth-evm-js";
import IPyth from "@pythnetwork/pyth-sdk-solidity/abis/IPyth.json";

const pyth = "0x5744Cbf430D99456a0A8771208b674F27f8EF0Fb";

describe("AnchorUSD", function () {
  it("Should set the right unlockTime", async function () {

    // deploy a lock contract where funds can be withdrawn
    // one year in the future
    const lock = await ethers.deployContract("AnchorUSD", [pyth], {
      value: 0,
    });

    // assert that the value is correct
    console.log(pyth);
    expect(await lock.pyth()).to.equal(pyth);
  });
});