const { assert, expect } = require("chai")
const { network, deployments, ethers } = require("hardhat")
const { developmentChains } = require("../helper-hardhat-config")

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Decentralized Stablecoin tests", function () {
          let decentralizedStableCoin,
              deployer,
              accounts,
              liquidator,
              dscEngine,
              weth,
              ethUsdPriceFeed
          beforeEach(async () => {
              accounts = await ethers.getSigners()
              deployer = accounts[0]
              liquidator = accounts[1]
              await deployments.fixture(["mocks", "decentralizedstablecoin"])
              decentralizedStableCoin = await ethers.getContract("DecentralizedStableCoin")
              dscEngine = await ethers.getContract("DSCEngine")
              weth = await ethers.getContract("WETH")
              ethUsdPriceFeed = await ethers.getContract("ETHUSDPriceFeed")
          })

          it("can be minted with deposited collateral", async function () {
              const amountCollateral = ethers.utils.parseEther("10") // Price Starts off at $1,000
              const amountToMint = ethers.utils.parseEther("100") // $100 minted with $10,000 collateral
              await weth.approve(dscEngine.address, amountCollateral)
              await dscEngine.depositCollateralAndMintDsc(
                  weth.address,
                  amountCollateral,
                  amountToMint
              )
              const balance = await decentralizedStableCoin.balanceOf(deployer.address)
              assert.equal(balance.toString(), amountToMint.toString())
          })

          it("can redeem deposited collateral", async function () {
              const amountCollateral = ethers.utils.parseEther("10") // Price Starts off at $1,000
              const amountToMint = ethers.utils.parseEther("100") // $100 minted with $10,000 collateral
              await weth.approve(dscEngine.address, amountCollateral)

              await dscEngine.depositCollateralAndMintDsc(
                  weth.address,
                  amountCollateral,
                  amountToMint
              )
              await decentralizedStableCoin.approve(dscEngine.address, amountToMint)
              await dscEngine.redeemCollateralForDsc(weth.address, amountCollateral, amountToMint)

              assert(await decentralizedStableCoin.balanceOf(dscEngine.address), "0")
          })
      })
