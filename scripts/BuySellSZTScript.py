import time
from brownie import accounts, BuySellSZT, SZT, FakeCoin, GSZT

old_account = accounts.add("0797b4c6d28170e148ca24a4d8d8547600deb6bb7a07ce8f591a7713ba38a0ef") # 1
new_account = accounts.add("bed7ccf7bc6d24b639ae1e77e636320474100b6c898834a0da5fe8e3876245ce") # 2

def main():
    DAIContract = FakeCoin.deploy("DAI", "DAI", {"from": accountA})
    BuySellContract = BuySellSZT.deploy(1, 4, DAIContract.address, {"from":accountA})
    GSZTContract = GSZT.deploy(BuySellContract.address, {"from":accountA})
    SZTContract = SZT.deploy(BuySellContract.address, {"from":accountA})