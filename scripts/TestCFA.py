import time
from brownie import ConstantFlowERC20, ConstantFlowAgreement, DemoStableCoin, accounts

#  there should be no gaps in encodewithsiganture signuature call

accountA = accounts.add("0797b4c6d28170e148ca24a4d8d8547600deb6bb7a07ce8f591a7713ba38a0ef")
#  brownie run scripts/TestCFA.py --network development
#  brownie console --network development


def main():
    DAI = DemoStableCoin.deploy("DAI", "DAI", {"from":accountA})
    CFA = ConstantFlowAgreement.deploy({"from":accountA})
    SZTDAI = ConstantFlowERC20.deploy("SZTDAI", "SZTDAI",CFA.address, {"from": accountA})
    tx1 = DAI.approve(CFA.address, 1000000000*1e14, {"from":accountA})
    
    print(DAI.balanceOf(accountA.address)/(10**DAI.decimals()))
    print(SZTDAI.balanceOf(accountA.address)/(10**DAI.decimals()))
    
    tx2 = CFA.mintToken(1000000*1e6, SZTDAI.address, DAI.address, {"from":accountA}) # wrapping DAI to SZTDAI
    print(DAI.balanceOf(accountA.address)/(10**DAI.decimals()))
    print(SZTDAI.balanceOf(accountA.address)/(10**SZTDAI.decimals()))
    print(SZTDAI.balanceOf(accountA.address))
    
    tx3 = CFA.updateProtocolCount(5)
    tx4 = CFA.startFlow(1e6, 3, SZTDAI.address)
    print(CFA.userStreamDetails(accountA.address))
    time.sleep(10)
    CFA.startFlow(1e6, 2, SZTDAI.address)
    time.sleep(10)
    CFA.startFlow(1e7, 1, SZTDAI.address)
    time.sleep(10)
    print(CFA.userStreamTransactionInfo(accountA.address,3))
    # test calculatetotalflowmade
    print(CFA.findActiveFlows(CFA._protocolCount()))

    tx4 = SZTDAI.approve(CFA.address, 1000000000*1e14, {"from":accountA})
    print(CFA.calculateTotalFlowMade({"from":accountA}))
    tx5 = CFA.closeTokenStream(3, SZTDAI.address)
    print(DAI.balanceOf(accountA.address)/(10**DAI.decimals()))
    print(SZTDAI.balanceOf(accountA.address)/(10**SZTDAI.decimals()))
    print(CFA.findActiveFlows(5))
    CFA.closeTokenStream(1, SZTDAI.address)
    time.sleep(5)
    CFA.closeTokenStream(2, SZTDAI.address)
    print(DAI.balanceOf(accountA.address)/(10**DAI.decimals()))
    print(SZTDAI.balanceOf(accountA.address)/(10**SZTDAI.decimals()))
