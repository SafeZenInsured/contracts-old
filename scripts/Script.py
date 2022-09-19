import time
from brownie import accounts
from brownie import BuySellSZT, FakeCoin, TerminateInsurance
from brownie import ConstantFlowAgreement, CoveragePool, ProtocolRegistry
from brownie import SwapDAI, SZTStaking, GSZT, sztDAI, SZT
from brownie import AAVE, CompoundPool, ZPController

accountA = accounts.add("bed7ccf7bc6d24b639ae1e77e636320474100b6c898834a0da5fe8e3876245ce")


def main():
    DAI = FakeCoin.at("0xc5A59E4CF050Bf587E3b7B1470a5a40DAD44FCFC")
    BuySellContract = BuySellSZT.at("0xb0Dc8a1549f987739d5630b98893D93Fa88F9604")
    GSZTContract = GSZT.at("0x88dfdF682dd64cD6092935a082e9BCed68f17bd6")
    SZTContract = SZT.at("0x628DF7670fa614560AfA332a8a950f976989BdB2")
    CFA = ConstantFlowAgreement.at("0xe7792c8FA204134C41e4D56FFd956C42fE3115c7")
    # Gelato Ops Address [Goerli]:[--> THIS ADDRESS ONE IS NOT FOR YOU ADWAIT] 0xc1C6805B857Bef1f412519C4A842522431aFed39 
    Gelato = TerminateInsurance.at("0xB19bDb634aa52d4700941eC002Ad43F1635FCdC7")
    sztDAIContract = sztDAI.at("0x17EC64626F8157d721957f8c292fe877B9bc8864")
    CoveragePoolContract = CoveragePool.at("0xdD8230577D295CDc7B4AA778720F8C149308761E")
    ProtocolRegistryContract = ProtocolRegistry.at("0x4d28D183D452f9084b266d3283CAc124C3f42cB7")
    Staking = SZTStaking.at("0xdC47391F6D4Bf2eB9d588dA88fd1a8680D76A3b1")
    SwapDAIContract = SwapDAI.at("0xFB232Da9fCA55F0e1CA0231F29bA40d5cF39718B")
    ZeroPremium = ZPController.at("0xDDF07c04D30E2146ea2B030fc1A38Dd9Af6aF583")
    POOL_ADDRESS = "0x368EedF3f56ad10b9bC57eed4Dac65B26Bb667f6"
    AAVEDEFI = AAVE.at("0xB9e6BbEb729Ad68D727224D47dF1b14636a4b7b9")
    CompoundDEFI = CompoundPool.at("0x634dEbC440129879e3138079C68F19461DCff61c")

    tokenCount = BuySellContract.getSZTTokenCount()



    