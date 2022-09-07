import time
from brownie import accounts, SZTERC20, BuySellSZT, DemoStableCoin, GSZT, ERC20, LendingPool

"""
export WEB3_INFURA_PROJECT_ID="300ff78a0a394452b6b3e00b4c3c3b54"
brownie run scripts/CompoundTest.py --network goerli
"""

accountA = accounts.load(1,"aa")
# accountA address = 0x112Ba4550291C0936C6D987684015562736790bA
# accountB = accounts[1]
# accountC = accounts[2]
accountB = accounts.add("bed7ccf7bc6d24b639ae1e77e636320474100b6c898834a0da5fe8e3876245ce") # new account
account = accounts.add("0797b4c6d28170e148ca24a4d8d8547600deb6bb7a07ce8f591a7713ba38a0ef") # old account

"""
AAVE V3- TESTNET
LENDING POOL ADDRESS: 0x368EedF3f56ad10b9bC57eed4Dac65B26Bb667f6
AAVE ADDRESS: 0x63242B9Bd3C22f18706d5c4E627B4735973f1f07
WETH ADDRESS: 0x2e3a2fb8473316a02b8a297b982498e661e1f6f5

"""

"""
Compound Testnet
DAI ADDRESS: 0xdc31Ee1784292379Fbb2964b3B9C4124D8F89C60
cDAI ADDRESS: 0x822397d9a55d0fefd20f5c4bcab33c5f65bd28eb

BAT ADDRESS: 0x70cBa46d2e933030E2f274AE58c951C800548AeF
cBAT ADDRESS: 0xCCaF265E7492c0d9b7C2f0018bf6382Ba7f0148D

"""



def main():
    POOL_ADDRESS = "0x368EedF3f56ad10b9bC57eed4Dac65B26Bb667f6" # Deployed by AAVE Team
    # AAVE_MINT_ADDRESS = "0x1ca525Cd5Cb77DB5Fa9cBbA02A0824e283469DBe"
    AAVE_2_MINT_ADDRESS = "0x63242B9Bd3C22f18706d5c4E627B4735973f1f07"

    DAICA = "0xDF1742fE5b0bFc12331D8EAec6b478DfDbD31464"
    DAI = ERC20.at(DAICA)
    AAVECA = "0x63242B9Bd3C22f18706d5c4E627B4735973f1f07" # AAVE ASSET Contract Address
    # AAVECA = "0xAFC7f63AFCa3837F11a9fff76a704c401a8F7957"
    AAVE = ERC20.at(AAVECA)
    print(DAI.balanceOf(accountA.address)/1e18)
    print(AAVE.balanceOf(accountA.address)/1e18)

    # ContractAddress = "0xdEF607DD7913208E2E4D3b9320A0233996db0035" #TestAAVE Contract Address
    # AAVE.approve(LendingPoolCA, 20*1e18, {"from":accountA})
    # AAVE.approve("0x04c94825C3e3539e0f2bB21d435302d08B2Dbd77", 20*1e18, {"from":accountA})
    # AAVE.approve("0x77c45699A715A64A7a7796d5CEe884cf617D5254", 20*1e18, {"from":accountA})
    # AAVE.approve("0x63242B9Bd3C22f18706d5c4E627B4735973f1f07", 20*1e18, {"from":accountA})
   
    # Minting AAVE Tokens
    # TESTAAVE_CONTRACT = LendingPool.deploy({"from":accountA})
    # TESTAAVE_CONTRACT.mintAAVE(AAVE_MINT_ADDRESS, 100*1e18)
    # TESTAAVE_CONTRACT.mintAAVE(AAVE_2_MINT_ADDRESS, 100*1e18)
    # print(AAVE.balanceOf(accountA.address)/1e18)
    # print(AAVE.balanceOf(TESTAAVE_CONTRACT.address)/1e18)

    # TESTAAVE_CONTRACT.mintAAVE2(AAVE_MINT_ADDRESS, 100*1e18)
    # TESTAAVE_CONTRACT.mintAAVE2(AAVE_2_MINT_ADDRESS, 100*1e18)
    # print(AAVE.balanceOf(accountA.address)/1e18)
    # print(AAVE.balanceOf(TESTAAVE_CONTRACT.address)/1e18)
    
    # TESTAAVE_CONTRACT.mintAAVE3(AAVE_2_MINT_ADDRESS, 100*1e18)
    # print(AAVE.balanceOf(accountA.address)/1e18)
    # print(AAVE.balanceOf(TESTAAVE_CONTRACT.address)/1e18)
    
    # AAVE.approve(POOL_ADDRESS, 20*1e18, {"from":accountA})

    # # AAVECA = LendingPool.deploy({"from":accountA})
    # # AAVECA.addMoney(LendingPoolCA, DAICA, 100 *1e18, accountA.address)
    # # TestAAVE = LendingPool.at(ContractAddress)
    # # TestAAVE = LendingPool.deploy({"from":accountA})
    # TestAAVE.addMoney(Lending, AAVE, 10, accountA.address, {"from": accountA})
    # print(AAVE.balanceOf(accountA.address)/1e18)





    DAI = DemoStableCoin.deploy("DAI","DAI",{"from":accountA})
    # USDC = DemoStableCoin.deploy("USDC","USDC",{'from':accountA})
    buyCA = BuySellSZT.deploy(1, 4, DAI.address, {'from': accountA})
    GSZTCA = GSZT.deploy(buyCA.address, {"from":accountA})
    SZTCA = SZTERC20.deploy(buyCA.address,{"from":accountA})

    buyCA.setSafeZenTokenCA(SZTCA.address, {"from":accountA})
    buyCA.setSafeZenGovernanceTokenCA(GSZTCA.address, {"from":accountA})

    # buyCA.demoFunctionA({"from": accountA})
    # buyCA.demoFunctionB({"from": accountA})
    # buyCA.demoFunctionC({"from": accountA})
    # # print(GSZTCA.balanceOf(accountA)/10e17)
    # # print(GSZTCA.balanceOf(buyCA.address)/10e17)
    # GSZTCA.approve(buyCA.address, 2100*10e17, {"from": accountA})
    # buyCA.demoFunctionD({"from":accountA})
    # buyCA.demoFunctionE({"from":accountA})
    # buyCA.demoFunctionF({"from":accountA})
    # # print(GSZTCA.balanceOf(accountA)/10e17)
    # # print(GSZTCA.balanceOf(buyCA.address)/10e17)


# def main():
#     # Deploying smart contracts
#     DAI = DemoStableCoin.deploy("DAI","DAI",{"from":accountA})
#     USDC = DemoStableCoin.deploy("USDC","USDC",{'from':accountA})
#     buyCA = BuySellSZT.deploy(1, 4, DAI.address, {'from': accountA})
#     GSZTCA = GSZT.deploy(buyCA.address, {"from":accountA})
#     SZTCA = SZTERC20.deploy(buyCA.address,{"from":accountA})

#     # Setting up the addresses for buyCA contract
#     buyCA.setSafeZenTokenCA(SZTCA.address, {"from":accountA})
#     buyCA.setSafeZenGovernanceTokenCA(GSZTCA.address, {"from":accountA})


#     DAI.approve(buyCA.address, 10000000*1e18,{"from":accountA})
#     print(f'Current GSZT Balance: {buyCA.transferGSZT(1, {"from": accountA}).return_value}')
#     print(buyCA.transferGSZT(10, {"from": accountA}).return_value)
#     print(buyCA.transferGSZT(100, {"from": accountA}).return_value)
#     # buyCA.demoAddPenalty(90, {"from": accountA})
#     buyCA.buySZTToken(5000,{"from":accountA})
#     print(GSZTCA.balanceOf(accountA)/10e17)
#     print(SZTCA.balanceOf(buyCA.address)/10e17)
#     print(DAI.balanceOf(buyCA.address))
#     print(SZTCA.balanceOf(accountA)/10e17)

#     buyCA.sellSZTToken(2, {"from": accountA})
#     SZTCA.approve(buyCA.address, 2*10e17, {"from":accountA})
#     time.sleep(12)
#     print(buyCA.sellSZTToken(2, {"from": accountA}))
#     print(DAI.balanceOf(buyCA.address))
#     print(SZTCA.balanceOf(accountA)/10e17)

#     buyCA.sellSZTToken(4, {"from": accountA})
#     time.sleep(12)
#     SZTCA.approve(buyCA.address, 4*10e17, {"from":accountA})
#     buyCA.sellSZTToken(4, {"from": accountA})
#     print(DAI.balanceOf(buyCA.address))
#     print(SZTCA.balanceOf(accountA)/10e17)

#     print(SZTCA.balanceOf(buyCA.address)/10e17)
#     print(SZTCA.balanceOf(accountA)/10e17)
#     print(DAI.balanceOf(buyCA.address))
#     print(GSZTCA.balanceOf(accountA)/10e17)

#     print(SZTCA.allowance(accountA, buyCA.address)/10e17)