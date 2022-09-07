import time
from brownie import accounts, AAVE, ERC20, ZPController

accountA = accounts.add("bed7ccf7bc6d24b639ae1e77e636320474100b6c898834a0da5fe8e3876245ce") # new account


"""
AAVE V3- TESTNET
LENDING POOL ADDRESS: 0x368EedF3f56ad10b9bC57eed4Dac65B26Bb667f6
AAVE ADDRESS: 0x63242B9Bd3C22f18706d5c4E627B4735973f1f07
WETH ADDRESS: 0x2e3a2fb8473316a02b8a297b982498e661e1f6f5
"""


def main():
    POOL_ADDRESS = "0x368EedF3f56ad10b9bC57eed4Dac65B26Bb667f6"  # V3 Pool Address

    AAVECA = "0x63242B9Bd3C22f18706d5c4E627B4735973f1f07"  # AAVE Contract Address
    aAAVECA = "0xC4bf7684e627ee069e9873B70dD0a8a1241bf72c"  # aAAVE Contract Address 

    AAVEToken = ERC20.at(AAVECA)
    aAAVEToken = ERC20.at(aAAVECA)
    print(AAVEToken.balanceOf(accountA.address)/1e18)
    print(aAAVEToken.balanceOf(accountA.address)/1e18)

    AAVEDEFI = AAVE.deploy(POOL_ADDRESS, {"from":accountA})  # 0xBdaF17EE5c3Bc603B330764c2281966dCd511160
    ZeroPremium = ZPController.deploy({"from":accountA})  # 0x9FF85aA1ca422903872d18B373402AFaD529143A
    tx1 = AAVEDEFI.updateZeroPremiumController(ZeroPremium.address)

    tx2 = ZeroPremium.addCoveredProtocol("AAVE", AAVEDEFI.address, 98, True, 1)
    tx3 = AAVEDEFI.mintERC20Tokens(AAVEToken.address, 1000*1e18, {"from":accountA})

    tx4 = AAVEToken.approve(AAVEDEFI.address, 1000*1e18, {"from":accountA})
    tx5 = AAVEDEFI.supplyToken(AAVECA, aAAVECA, 1000*1e18, {"from":accountA})
    tx6 = AAVEDEFI.calculateUserBalance(aAAVEToken)
    time.sleep(30)
    tx7 = AAVEDEFI.withdrawToken(AAVECA, aAAVECA, 1000*1e18, {"from":accountA})
    tx8 = AAVEDEFI.calculateUserBalance(aAAVEToken)
