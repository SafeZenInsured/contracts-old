import time
from brownie import accounts
from brownie import BuySellSZT, FakeCoin, TerminateInsurance
from brownie import ConstantFlowAgreement, CoveragePool, ProtocolRegistry
from brownie import SwapDAI, SZTStaking, GSZT, sztDAI, SZT
from brownie import AAVE, CompoundPool, ZPController

accountA = accounts.add("bed7ccf7bc6d24b639ae1e77e636320474100b6c898834a0da5fe8e3876245ce")

# brownie run scripts/CompoundTest.py --network goerli
def main():
    # DAI = FakeCoin.at("0xc5A59E4CF050Bf587E3b7B1470a5a40DAD44FCFC")
    # BuySellContract = BuySellSZT.at("0xb0Dc8a1549f987739d5630b98893D93Fa88F9604")
    # GSZTContract = GSZT.at("0x88dfdF682dd64cD6092935a082e9BCed68f17bd6")
    # SZTContract = SZT.at("0x628DF7670fa614560AfA332a8a950f976989BdB2")
    # CFA = ConstantFlowAgreement.at("0xe7792c8FA204134C41e4D56FFd956C42fE3115c7")
    # # Gelato Ops Address [Goerli]:[--> THIS ADDRESS ONE IS NOT FOR YOU ADWAIT] 0xc1C6805B857Bef1f412519C4A842522431aFed39 
    # Gelato = TerminateInsurance.at("0xB19bDb634aa52d4700941eC002Ad43F1635FCdC7")
    # sztDAIContract = sztDAI.at("0x17EC64626F8157d721957f8c292fe877B9bc8864")
    # CoveragePoolContract = CoveragePool.at("0xdD8230577D295CDc7B4AA778720F8C149308761E")
    # ProtocolRegistryContract = ProtocolRegistry.at("0x4d28D183D452f9084b266d3283CAc124C3f42cB7")
    # Staking = SZTStaking.at("0xcd1200b39CF13df0D2322c3839D4448D2490a29c")
    # SwapDAIContract = SwapDAI.at("0xFB232Da9fCA55F0e1CA0231F29bA40d5cF39718B")
    # ZeroPremium = ZPController.at("0xDDF07c04D30E2146ea2B030fc1A38Dd9Af6aF583")
    # POOL_ADDRESS = "0x368EedF3f56ad10b9bC57eed4Dac65B26Bb667f6"
    # AAVEDEFI = AAVE.at("0xB9e6BbEb729Ad68D727224D47dF1b14636a4b7b9")
    # CompoundDEFI = CompoundPool.at("0x634dEbC440129879e3138079C68F19461DCff61c")

    # Staking = SZTStaking.deploy(BuySellContract.address, SZTContract.address, {"from":accountA})
    # print(Staking.address)
    # BuySellContract.setSZTStakingCA(Staking.address, {"from":accountA})


    DAI = FakeCoin.deploy("DAI", "DAI", {"from": accountA})  # 0x99B5edB4F28BE00748EA7BaE4f0994d0bDBb2A03
    BuySellContract = BuySellSZT.deploy(1, 4, {"from":accountA})  # 0x85e97de2807c2A8d5520Ee9Cd66fCE21C9aD9192
    GSZTContract = GSZT.deploy(BuySellContract.address, {"from":accountA})  # 0xa570236E9e921cC12A1c34749832E31985676282
    SZTContract = SZT.deploy(BuySellContract.address, {"from":accountA})  # 0x590A6E3b9918f54982A0d1b06ADF808E514C8F5a
    CFA = ConstantFlowAgreement.deploy({"from":accountA})  # 0x775887d74665c67f1772BBe5535952Cb7DdB2b99
    # Gelato Ops Address [Goerli]:[--> THIS ADDRESS ONE IS NOT FOR YOU ADWAIT] 0xc1C6805B857Bef1f412519C4A842522431aFed39 
    Gelato = TerminateInsurance.deploy("0xc1C6805B857Bef1f412519C4A842522431aFed39", {"from":accountA})  # 0xB19bDb634aa52d4700941eC002Ad43F1635FCdC7
    sztDAIContract = sztDAI.deploy(CFA.address, {"from":accountA})  # 0x17EC64626F8157d721957f8c292fe877B9bc8864
    CoveragePoolContract = CoveragePool.deploy(BuySellContract.address, SZTContract.address, {"from":accountA})  # 0xdD8230577D295CDc7B4AA778720F8C149308761E
    ProtocolRegistryContract = ProtocolRegistry.deploy({"from":accountA})  # 0x4d28D183D452f9084b266d3283CAc124C3f42cB7
    Staking = SZTStaking.deploy(BuySellContract.address, SZTContract.address, {"from":accountA})  # 0x2edf36e188063ADe91aBFFD4dF73b21bb72b476d
    SwapDAIContract = SwapDAI.deploy({"from":accountA})  # 0xFB232Da9fCA55F0e1CA0231F29bA40d5cF39718B
    ZeroPremium = ZPController.deploy({"from":accountA})  # 0xDDF07c04D30E2146ea2B030fc1A38Dd9Af6aF583
    POOL_ADDRESS = "0x368EedF3f56ad10b9bC57eed4Dac65B26Bb667f6"
    
    AAVEDEFI = AAVE.deploy(POOL_ADDRESS, ZeroPremium.address, {"from":accountA})  # 0xB9e6BbEb729Ad68D727224D47dF1b14636a4b7b9
    CompoundDEFI = CompoundPool.deploy(ZeroPremium.address, {"from":accountA})  # 0x634dEbC440129879e3138079C68F19461DCff61c

    tx1 = BuySellContract.setSafeZenTokenCA(SZTContract.address, {"from":accountA})
    tx2 = BuySellContract.setSafeZenGovernanceTokenCA(GSZTContract.address, {"from":accountA})
    tx3 = BuySellContract.setDAIAddress(DAI.address, {"from":accountA})
    tx4 = BuySellContract.setSZTStakingCA(Staking.address, {"from":accountA})
    tx5 = BuySellContract.setCoveragePoolCA(CoveragePoolContract.address, {"from":accountA})

    tx6 = CFA.setDAIAddress(DAI.address, {"from": accountA})
    tx7 = CFA.setsztDAIAddress(sztDAIContract.address, {"from": accountA})
    tx8 = CFA.updateTerminateInsuranceAddress(Gelato.address, {"from":accountA})
    tx9 = CFA.updateProtocolRegistryAddress(ProtocolRegistryContract.address, {"from":accountA})

    tx10 = sztDAIContract.setSwapDAIAddress(SwapDAIContract.address, {"from":accountA})

    tx11 = SwapDAIContract.updateDAIAddress(DAI.address, {"from":accountA})
    tx12 = SwapDAIContract.updatesztDAIAddress(sztDAIContract.address, {"from":accountA})

    tx13 = CoveragePoolContract.updateProtocolsRegistry(ProtocolRegistryContract.address, {"from":accountA})

    tx14 = ProtocolRegistryContract.setBuySellSZT(BuySellContract.address, {"from":accountA})

    tx15 = Gelato.setCFAAddress(CFA.address, {"from":accountA})



    tokens = BuySellContract.getSZTTokenCount()
    DAI_Amount_Needed = BuySellContract.calculateSZTPrice(tokens, tokens + 5*1e18)
    print(DAI_Amount_Needed)
    DAI.approve(BuySellContract.address, DAI_Amount_Needed[1], {"from":accountA})
    BuySellContract.buySZTToken(5*1e18, {"from":accountA})

    tokens = BuySellContract.getSZTTokenCount()
    DAI_Amount_Needed = BuySellContract.calculateSZTPrice(tokens, tokens + 5*1e18)
    print(DAI_Amount_Needed)
    DAI.approve(BuySellContract.address, DAI_Amount_Needed[1], {"from":accountA})
    BuySellContract.buySZTToken(5*1e18, {"from":accountA})
    BuySellContract.activateSellTimer(5*1e18, {"from":accountA})
    print(SZTContract.balanceOf(accountA.address)/1e18)

    SZTContract.approve(BuySellContract.address, 5*1e18, {"from":accountA})
    print(SZTContract.allowance(accountA.address, BuySellContract.address)/1e18)
    Staking.stakeSZT(5*1e18, {"from":accountA})
    print(SZTContract.balanceOf(accountA.address)/1e18)
    Staking.activateWithdrawalTimer(5*1e18, {"from":accountA})
    time.sleep(80)
    DAIBefore = DAI.balanceOf(accountA.address)
    SZTContract.approve(BuySellContract.address, 5*1e18, {"from":accountA})
    GSZTContract.approve(BuySellContract.address, 5*1e18, {"from":accountA})
    print(BuySellContract.getSZTTokenCount())
    BuySellContract.sellSZTToken(5*1e18, {"from":accountA})
    DAIAfter = DAI.balanceOf(accountA.address)
    print(DAIAfter, DAIBefore)
    Staking.withdrawSZT(5*1e18, {"from":accountA})
    print(SZTContract.balanceOf(accountA.address)/1e18)
    print(DAIAfter - DAIBefore)


    # Point to consider: adding GSZT with staking transfer function
    # as someone might first stake, then sell, and then find unstake, and their governance tokens might not lined up that way