import time
from brownie import accounts, ERC20, CompoundPool

"""
const BAT_Token = "0x70cBa46d2e933030E2f274AE58c951C800548AeF"
const cBAT_Token = "0xCCaF265E7492c0d9b7C2f0018bf6382Ba7f0148D"
const CompoundPool = "0x77A1e13b675482355F5C838121535EC2D9176b10"
"""

accountA = accounts.add("bed7ccf7bc6d24b639ae1e77e636320474100b6c898834a0da5fe8e3876245ce")
accountB = accounts.add("0797b4c6d28170e148ca24a4d8d8547600deb6bb7a07ce8f591a7713ba38a0ef")

BAT = ERC20.at("0x70cBa46d2e933030E2f274AE58c951C800548AeF")
cBAT = ERC20.at("0xCCaF265E7492c0d9b7C2f0018bf6382Ba7f0148D")

def main():
    CompPool = CompoundPool.deploy({"from":accountA})  # 0x07c2001e2820c232A0BB51e7552026128626590f
    ZeroPremium = ZPController.deploy({"from":accountA})  # 0x9FF85aA1ca422903872d18B373402AFaD529143A
    CompPool.updateZeroPremiumController(ZeroPremium.address, {"from":accountA})

    tx2 = ZeroPremium.addCoveredProtocol("Compound", CompPool.address, 98, True, 1)
    tx1 = CompPool.mintERC20Tokens(accountA.address, BAT.address, 100000 * 1e18, {"from":accountA}) # mint to users's address
    print(BAT.balanceOf(accountA.address)/1e18)
    
    # tx2 = BAT.approve(CompPool.address, 1000*1e18, {"from":accountA}) 
    BAT.transfer(CompPool.address, 100000*1e18, {"from":accountA})
    tx2 = CompPool.supplyToken(BAT.address, cBAT.address, 100000 * 1e18, {"from":accountA})
    print(cBAT.balanceOf(CompPool.address)/1e8)
    userDepositedAmount = CompPool.calculateUserBalance(accountA.address, cBAT.address)
    time.sleep(150)

    tx3 = CompPool.withdrawToken(BAT.address, cBAT.address, userDepositedAmount, {"from":accountA})
    print(cBAT.balanceOf(CompPool.address)/1e8)
    print(BAT.balanceOf(CompPool.address)/1e18)
