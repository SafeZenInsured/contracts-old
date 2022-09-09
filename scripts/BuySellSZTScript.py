import time
from brownie import accounts, BuySellSZT, SZT, FakeCoin, GSZT

# brownie run scripts/BuySellSZTScript.py --network development
# brownie console --network development
# export WEB3_INFURA_PROJECT_ID="300ff78a0a394452b6b3e00b4c3c3b54"

"""
few things that are yet to be considered: aka TODO task:

"""
accountA = accounts.add("0797b4c6d28170e148ca24a4d8d8547600deb6bb7a07ce8f591a7713ba38a0ef") # old accountA
accountA = accounts.add("bed7ccf7bc6d24b639ae1e77e636320474100b6c898834a0da5fe8e3876245ce") # new accountA

def main():
    # Deploying the contracts
    BuySellContract = BuySellSZT.deploy(1, 4, {"from":accountA})
    DAIContract = FakeCoin.deploy("DAI", "DAI", BuySellContract.address, {"from": accountA})
    GSZTContract = GSZT.deploy(BuySellContract.address, {"from":accountA})
    SZTContract = SZT.deploy(BuySellContract.address, {"from":accountA})

    # Initializing contract addresses
    BuySellContract.setDAITokenCA(DAIContract.address, {"from":accountA})
    tx1 = BuySellContract.setSafeZenTokenCA(SZTContract.address, {"from":accountA})
    tx2 = BuySellContract.setSafeZenGovernanceTokenCA(GSZTContract.address, {"from":accountA})

    tx3 = DAIContract.approve(BuySellContract.address, 22050021 * 1e30, {"from":accountA})

    
    tx4 = BuySellContract.buySZTToken(1*1e18, {"from":accountA})
    print(f"Current User SZT Balance [without decimals]: {SZTContract.balanceOf(accountA.address) / (10 ** SZTContract.decimals())}")
    print(f"Current User GSZT Balance [without decimals]: {GSZTContract.balanceOf(accountA.address) / (10 ** GSZTContract.decimals())}")

    tx5 = BuySellContract.buySZTToken(89*1e17, {"from":accountA})
    print(f"Current User SZT Balance [without decimals]: {SZTContract.balanceOf(accountA.address) / (10 ** SZTContract.decimals())}")
    print(f"Current User GSZT Balance [without decimals]: {GSZTContract.balanceOf(accountA.address) / (10 ** GSZTContract.decimals())}")

    tx5 = BuySellContract.buySZTToken(77*1e17, {"from":accountA})
    print(f"Current User SZT Balance [without decimals]: {SZTContract.balanceOf(accountA.address) / (10 ** SZTContract.decimals())}")
    print(f"Current User GSZT Balance [without decimals]: {GSZTContract.balanceOf(accountA.address) / (10 ** GSZTContract.decimals())}")

    tx6 = BuySellContract.activateSellTimer(77*1e17, 5, {"from":accountA})
    print(f"Current User SZT Balance [without decimals]: {SZTContract.balanceOf(accountA.address) / (10 ** SZTContract.decimals())}")
    print(f"Current User GSZT Balance [without decimals]: {GSZTContract.balanceOf(accountA.address) / (10 ** GSZTContract.decimals())}")

    time.sleep(8)
    SZTContract.approve(BuySellContract.address, 1e20, {"from":accountA})
    GSZTContract.approve(BuySellContract.address, 1e20, {"from":accountA})

    tx7 = BuySellContract.sellSZTToken(48*1e17, {"from":accountA})
    print(f"Current User SZT Balance [without decimals]: {SZTContract.balanceOf(accountA.address) / (10 ** SZTContract.decimals())}")
    print(f"Current User GSZT Balance [without decimals]: {GSZTContract.balanceOf(accountA.address) / (10 ** GSZTContract.decimals())}")

    SZTContract.approve(accountB.address, 1e20, {"from":accountA})
    GSZTContract.approve(accountB.address, 1e20, {"from":accountA})
    
    tx8 = BuySellContract.transferSZT(accountA.address, accountB.address, 73*1e17, {"from":accountA})
    print(f"Current UserA SZT Balance [without decimals]: {SZTContract.balanceOf(accountA.address) / (10 ** SZTContract.decimals())}")
    print(f"Current UserA GSZT Balance [without decimals]: {GSZTContract.balanceOf(accountA.address) / (10 ** GSZTContract.decimals())}")
    print(f"Current UserB SZT Balance [without decimals]: {SZTContract.balanceOf(accountB.address) / (10 ** SZTContract.decimals())}")
    print(f"Current UserB GSZT Balance [without decimals]: {GSZTContract.balanceOf(accountB.address) / (10 ** GSZTContract.decimals())}")
    
    
    
    
    # tx9 = BuySellContract.sellSZTToken(20*1e17, {"from":accountA})
    # # print(f"Current User DAI Balance [without decimals]: {DAIContract.balanceOf(accountA.address) / (10 ** DAIContract.decimals())}")
    # print(f"Current User SZT Balance [without decimals]: {SZTContract.balanceOf(accountA.address) / (10 ** SZTContract.decimals())}")
    # print(f"Current User GSZT Balance [without decimals]: {GSZTContract.balanceOf(accountA.address) / (10 ** GSZTContract.decimals())}")
    # # print(f"Current BuySellContract DAI Balance [without decimals]: {DAIContract.balanceOf(BuySellContract.address) / (10 ** DAIContract.decimals())}")
    # tx4 = BuySellContract.buySZTToken(43*1e17, {"from":accountA})
    # print(f"Current User GSZT Balance [without decimals]: {GSZTContract.balanceOf(accountA.address) / (10 ** GSZTContract.decimals())}")
    # tx4 = BuySellContract.buySZTToken(65*1e17, {"from":accountA})
    # # print(f"Current User DAI Balance [without decimals]: {DAIContract.balanceOf(accountA.address) / (10 ** DAIContract.decimals())}")
    # print(f"Current User SZT Balance [without decimals]: {SZTContract.balanceOf(accountA.address) / (10 ** SZTContract.decimals())}")
    # print(f"Current User GSZT Balance [without decimals]: {GSZTContract.balanceOf(accountA.address) / (10 ** GSZTContract.decimals())}")
    # # print(f"Current BuySellContract DAI Balance [without decimals]: {DAIContract.balanceOf(BuySellContract.address) / (10 ** DAIContract.decimals())}")
    # tx4 = BuySellContract.buySZTToken(35*1e17, {"from":accountA})
    # print(f"Current User GSZT Balance [without decimals]: {GSZTContract.balanceOf(accountA.address) / (10 ** GSZTContract.decimals())}")
    
    # # tx4 = BuySellContract.buySZTToken(100*1e18, {"from":accountA})
    # # print(f"Current User DAI Balance [without decimals]: {DAIContract.balanceOf(accountA.address) / (10 ** DAIContract.decimals())}")
    # # print(f"Current User SZT Balance [without decimals]: {SZTContract.balanceOf(accountA.address) / (10 ** SZTContract.decimals())}")
    # # print(f"Current User GSZT Balance [without decimals]: {GSZTContract.balanceOf(accountA.address) / (10 ** GSZTContract.decimals())}")
    # # print(f"Current BuySellContract DAI Balance [without decimals]: {DAIContract.balanceOf(BuySellContract.address) / (10 ** DAIContract.decimals())}")

    # # tx5 = BuySellContract.buySZTToken_0_1({"from":accountA})
    # # print(f"Current User DAI Balance [without decimals]: {DAIContract.balanceOf(accountA.address) / (10 ** DAIContract.decimals())}")
    # # print(f"Current User SZT Balance [without decimals]: {SZTContract.balanceOf(accountA.address) / (10 ** SZTContract.decimals())}")
    # # print(f"Current User GSZT Balance [without decimals]: {GSZTContract.balanceOf(accountA.address) / (10 ** GSZTContract.decimals())}")
    # # print(f"Current BuySellContract DAI Balance [without decimals]: {DAIContract.balanceOf(BuySellContract.address) / (10 ** DAIContract.decimals())}")

    # # tx6 = BuySellContract.buySZTToken_0_1({"from":accountA})
    # # print(f"Current User DAI Balance [without decimals]: {DAIContract.balanceOf(accountA.address) / (10 ** DAIContract.decimals())}")
    # # print(f"Current User SZT Balance [without decimals]: {SZTContract.balanceOf(accountA.address) / (10 ** SZTContract.decimals())}")
    # # print(f"Current User GSZT Balance [without decimals]: {GSZTContract.balanceOf(accountA.address) / (10 ** GSZTContract.decimals())}")
    # # print(f"Current BuySellContract DAI Balance [without decimals]: {DAIContract.balanceOf(BuySellContract.address) / (10 ** DAIContract.decimals())}")

    # # tx7 = BuySellContract.activateSellTimer(100*1e18, 5, {"from":accountA})
    # # time.sleep(10)
    # # SZTContract.approve(BuySellContract.address, 200*1e18, {"from":accountA})
    # # GSZTContract.approve(BuySellContract.address, 200*1e18, {"from":accountA})
    # # tx8 = BuySellContract.sellSZTToken(100*1e18, {"from":accountA})
    # # print(f"Current User DAI Balance [without decimals]: {DAIContract.balanceOf(accountA.address) / (10 ** DAIContract.decimals())}")
    # # print(f"Current User SZT Balance [without decimals]: {SZTContract.balanceOf(accountA.address) / (10 ** SZTContract.decimals())}")
    # # print(f"Current User GSZT Balance [without decimals]: {GSZTContract.balanceOf(accountA.address) / (10 ** GSZTContract.decimals())}")
    # # print(f"Current BuySellContract DAI Balance [without decimals]: {DAIContract.balanceOf(BuySellContract.address) / (10 ** DAIContract.decimals())}")


    # # # tx7 = BuySellContract.buySZTToken(10000*1e18, {"from":accountA})

    # # # tx8 = BuySellContract.buySZTToken_0_01({"from":accountA})
    # # # print(f"Current User DAI Balance [without decimals]: {DAIContract.balanceOf(accountA.address) / (10 ** DAIContract.decimals())}")
    # # # print(f"Current User SZT Balance [without decimals]: {SZTContract.balanceOf(accountA.address) / (10 ** SZTContract.decimals())}")
    # # # print(f"Current User GSZT Balance [without decimals]: {GSZTContract.balanceOf(accountA.address) / (10 ** GSZTContract.decimals())}")
    # # # print(f"Current BuySellContract DAI Balance [without decimals]: {DAIContract.balanceOf(BuySellContract.address) / (10 ** DAIContract.decimals())}")
