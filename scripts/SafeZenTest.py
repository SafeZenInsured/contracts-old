from brownie import accounts, SZTERC20, BuySellSZT, DemoStableCoin, GSZT, ERC20
accountA = accounts[0]

def main():
    DAI = DemoStableCoin.deploy("DAI","DAI",{"from":accountA})
    buyCA = BuySellSZT.deploy(1, 4, DAI.address, {'from': accountA})
    GSZTCA = GSZT.deploy(buyCA.address, {"from":accountA})
    SZTCA = SZTERC20.deploy(buyCA.address,{"from":accountA})

    tx1 = buyCA.setSafeZenTokenCA(SZTCA.address, {"from":accountA})
    tx2 = buyCA.setSafeZenGovernanceTokenCA(GSZTCA.address, {"from":accountA})

    DAI.approve(buyCA.address, 10000000*1e6,{"from":accountA})
    print(DAI.balanceOf(buyCA.address)/1e6)
    print(SZTCA.balanceOf(accountA.address)/1e18)
    print(GSZTCA.balanceOf(accountA.address)/1e18)
    tx3 = buyCA.buySZTToken(1,{"from":accountA})
    print(DAI.balanceOf(buyCA.address)/1e6)
    tx3 = buyCA.buySZTToken(2,{"from":accountA})
    print(DAI.balanceOf(buyCA.address)/1e6)
    tx3 = buyCA.buySZTToken(3,{"from":accountA})
    print(DAI.balanceOf(buyCA.address)/1e6)
    tx3 = buyCA.buySZTToken(4,{"from":accountA})
    print(DAI.balanceOf(buyCA.address)/1e6)
    tx3 = buyCA.buySZTToken(40,{"from":accountA})
    print(DAI.balanceOf(buyCA.address)/1e6)
    print(SZTCA.balanceOf(accountA.address)/1e18)
    print(GSZTCA.balanceOf(accountA.address)/1e18)
    print(buyCA.tokenCounter())
    print(DAI.decimals())
    print(buyCA.calculateSZTPrice(0, ))