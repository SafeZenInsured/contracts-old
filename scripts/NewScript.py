import time
from brownie import accounts
from brownie import BuySellSZT, FakeCoin, TerminateInsurance
from brownie import ConstantFlowAgreement, CoveragePool, ProtocolRegistry
from brownie import SwapDAI, SZTStaking, GSZT, sztDAI, SZT
from brownie import AAVE, CompoundPool, ZPController

accountA = accounts.add("bed7ccf7bc6d24b639ae1e77e636320474100b6c898834a0da5fe8e3876245ce")

# export WEB3_INFURA_PROJECT_ID="300ff78a0a394452b6b3e00b4c3c3b54"
# brownie networks list
# brownie run scripts/NewScript.py --network goerli
# brownie run scripts/NewScript.py --network polygon-test
def main():
    # accountA = accounts.add("bed7ccf7bc6d24b639ae1e77e636320474100b6c898834a0da5fe8e3876245ce")
    # DAI = FakeCoin.at("0xdAE9067d617E07662D35e14f9043deA524Fb47F0")
    # DAI.mint(accountA.address, 1e30, {"from":accountA})
    # DAI.approve(BuySellContract.address, 1e30, {"from":accountA})
    # DAI.approve(SwapDAIContract.address, 1e30, {"from":accountA})
    # BuySellContract = BuySellSZT.at("0x26d3e63C19361A0Ed241e88D3b23a7259FE383B0")
    # BuySellContract.buySZTToken(300*1e18, {"from":accountA})
    # GSZTContract = GSZT.at("0x0ffFD71f1d4b93843C96f8E3DfbBD1F1c09A999d")
    # GSZTContract.approve(BuySellContract.address, 1e30, {"from":accountA})
    # SZTContract = SZT.at("0xE5B040CDeacacFa243577788653BaC1be842b480")
    # SZTContract.approve(BuySellContract.address, 1e30, {"from":accountA})
    # CFA = ConstantFlowAgreement.at("0xB7172C13dc2AD97807bcdAA9B15e34C522d2993F")
    # # Gelato Ops Address [Goerli]:[--> THIS ADDRESS ONE IS NOT FOR YOU ADWAIT] 0xc1C6805B857Bef1f412519C4A842522431aFed39 
    # Gelato = TerminateInsurance.at("0x07cc691947E9ba9BC7747B19E1ab91665B2782FF")
    # sztDAIContract = sztDAI.at("0xa5Dd96F89447f02F8bBb8f0eCfF480e2c3a08f96")
    # sztDAIContract.approve(CFA.address, 1e30, {"from":accountA})
    # CoveragePoolContract = CoveragePool.at("0x89e3CAe6AC6E128f6222461093CC1c797a36BE0e")
    # CoveragePoolContract.underwrite(100*1e18, 1, {"from":accountA})
    # ProtocolRegistryContract = ProtocolRegistry.at("0x40F4e6F60cfe433e82C9ee19E02B4fbe669983F1")
    # ProtocolRegistryContract.addProtocolInfo("AAVE", "0xc4dCB5126a3AfEd129BC3668Ea19285A9f56D15D", 99, True, 1, 126839167935, {"from":accountA})
    # ProtocolRegistryContract.addProtocolInfo("Compound", "0x3cBe63aAcF6A064D32072a630A3eab7545C54d78", 97, True, 1, 159839167104, {"from":accountA})
    # Staking = SZTStaking.at("0x71006701CD49329bd67ec17dD189230f0336DAfc")
    # SwapDAIContract = SwapDAI.at("0xADF045e967e26a718Ed13D076Adb2b49ac76d31c")
    # ZeroPremium = ZPController.at("0x35E569DEA2b1854318C46ee727D2133b78D92644")
    # POOL_ADDRESS = "0x368EedF3f56ad10b9bC57eed4Dac65B26Bb667f6"
    # AAVEDEFI = AAVE.at("0x1Fc0da9C655fb29D46edCCaE0a89F4CB634De380")
    # CompoundDEFI = CompoundPool.at("0x4c1fda4aA017846BCD322a96ca63f5fA48e5A887")


    DAI = FakeCoin.deploy("DAI", "DAI", {"from": accountA})  # 0xDFCe017c913623736db050791a6407A52d5ADa66
    BuySellContract = BuySellSZT.deploy(1, 4, DAI.address, {"from":accountA})  # 0xA1e446FcFB00c14894b625Cd15f2D6020891440D
    GSZTContract = GSZT.deploy(BuySellContract.address, {"from":accountA})  # 0xa570236E9e921cC12A1c34749832E31985676282
    SZTContract = SZT.deploy(BuySellContract.address, {"from":accountA})  # 0x590A6E3b9918f54982A0d1b06ADF808E514C8F5a
    CFA = ConstantFlowAgreement.deploy({"from":accountA})  # 0x775887d74665c67f1772BBe5535952Cb7DdB2b99
    sztDAIContract = sztDAI.deploy(CFA.address, {"from":accountA})  # 0x17EC64626F8157d721957f8c292fe877B9bc8864
    # Gelato Ops Address [Goerli]:[--> THIS ADDRESS ONE IS NOT FOR YOU ADWAIT] 0xc1C6805B857Bef1f412519C4A842522431aFed39 
    # Gelato = TerminateInsurance.deploy("0xc1C6805B857Bef1f412519C4A842522431aFed39", {"from":accountA})  # 0xB19bDb634aa52d4700941eC002Ad43F1635FCdC7
    # Gelato = TerminateInsurance.deploy("0xB3f5503f93d5Ef84b06993a1975B9D21B962892F", {"from":accountA})  # 0xB19bDb634aa52d4700941eC002Ad43F1635FCdC7
    CoveragePoolContract = CoveragePool.deploy(BuySellContract.address, SZTContract.address, {"from":accountA})  # 0xdD8230577D295CDc7B4AA778720F8C149308761E
    ProtocolRegistryContract = ProtocolRegistry.deploy({"from":accountA})  # 0x4d28D183D452f9084b266d3283CAc124C3f42cB7
    Staking = SZTStaking.deploy(BuySellContract.address, SZTContract.address, {"from":accountA})  # 0x2edf36e188063ADe91aBFFD4dF73b21bb72b476d
    SwapDAIContract = SwapDAI.deploy(DAI.address, sztDAIContract.address, {"from":accountA})  # 0xFB232Da9fCA55F0e1CA0231F29bA40d5cF39718B
    ZeroPremium = ZPController.deploy({"from":accountA})  # 0xDDF07c04D30E2146ea2B030fc1A38Dd9Af6aF583
    POOL_ADDRESS = "0x368EedF3f56ad10b9bC57eed4Dac65B26Bb667f6"
    
    AAVEDEFI = AAVE.deploy(POOL_ADDRESS, ZeroPremium.address, {"from":accountA})  # 0xB9e6BbEb729Ad68D727224D47dF1b14636a4b7b9
    CompoundDEFI = CompoundPool.deploy(ZeroPremium.address, {"from":accountA})  # 0x634dEbC440129879e3138079C68F19461DCff61c

    tx1 = BuySellContract.setSafeZenTokenCA(SZTContract.address, {"from":accountA})
    tx2 = BuySellContract.setSafeZenGovernanceTokenCA(GSZTContract.address, {"from":accountA})
    tx4 = BuySellContract.setSZTStakingCA(Staking.address, {"from":accountA})
    tx5 = BuySellContract.setCoveragePoolCA(CoveragePoolContract.address, {"from":accountA})

    tx6 = CFA.setDAIAddress(DAI.address, {"from":accountA})
    tx7 = CFA.setsztDAIAddress(sztDAIContract.address, {"from":accountA})
    # tx8 = CFA.updateTerminateInsuranceAddress(Gelato.address, {"from":accountA})
    tx9 = CFA.updateProtocolRegistryAddress(ProtocolRegistryContract.address, {"from":accountA})

    tx10 = sztDAIContract.setSwapDAIAddress(SwapDAIContract.address, {"from":accountA})

    tx13 = CoveragePoolContract.updateProtocolsRegistry(ProtocolRegistryContract.address, {"from":accountA})

    tx14 = ProtocolRegistryContract.setBuySellSZT(BuySellContract.address, {"from":accountA})

    # tx15 = Gelato.setCFAAddress(CFA.address, {"from":accountA})


    # DAI.mint(accountA.address, 1e30, {"from":accountA})
    # DAI.approve(BuySellContract.address, 1e30, {"from":accountA})
    # BuySellContract.buySZTToken(300*1e18, {"from":accountA})
    ProtocolRegistryContract.addProtocolInfo("AAVE", "0xc4dCB5126a3AfEd129BC3668Ea19285A9f56D15D", 99, True, 1, 126839167935, {"from":accountA})
    ProtocolRegistryContract.addProtocolInfo("Compound", "0x3cBe63aAcF6A064D32072a630A3eab7545C54d78", 97, True, 1, 159839167104, {"from":accountA})
    # SZTContract.approve(BuySellContract.address, 1e30, {"from":accountA})
    # GSZTContract.approve(BuySellContract.address, 1e30, {"from":accountA})
    # CoveragePoolContract.underwrite(100*1e18, 1, {"from":accountA})
    # print(ProtocolRegistryContract.viewProtocolInfo(1))
    # DAI.approve(SwapDAIContract.address, 1e30, {"from":accountA})
    # SwapDAIContract.swapDAI(10000*1e18, {"from":accountA})
    # CFA.activateInsurance(10*1e18, 1, {"from":accountA})
    # print(CFA.getUserInsuranceStatus(accountA.address, 1, {"from":accountA}))
    # print(CFA.getUserInsuranceValidTillInfo(accountA.address, 1, {"from":accountA}))
    # time.sleep(60)
    # sztDAIContract.approve(CFA.address, 1e30, {"from":accountA})
    # accountA.transfer(Gelato.address, 4 * 1e16)
    # # CFA.closeTokenStream(accountA.address, 1, {"from":accountA})

    # CoveragePoolContract.underwrite(100*1e18, 2, {"from":accountA})
    # print(ProtocolRegistryContract.viewProtocolInfo(1))
    # CFA.activateInsurance(10*1e18, 2, {"from":accountA})
    # print(CFA.getUserInsuranceStatus(accountA.address, 2, {"from":accountA}))
    # print(CFA.getUserInsuranceValidTillInfo(accountA.address, 2, {"from":accountA}))
    # time.sleep(65)
    # CFA.addInsuranceAmount(12*1e18, 2, {"from":accountA})
    # print(CFA.getUserInsuranceStatus(accountA.address, 2, {"from":accountA}))
    # print(CFA.getUserInsuranceValidTillInfo(accountA.address, 2, {"from":accountA}))
    # time.sleep(65)
    # CFA.minusInsuranceAmount(5*1e18, 2, {"from":accountA})
    # print(CFA.getUserInsuranceStatus(accountA.address, 2, {"from":accountA}))
    # print(CFA.getUserInsuranceValidTillInfo(accountA.address, 2, {"from":accountA}))






















    # tokens = BuySellContract.getSZTTokenCount()
    # DAI_Amount_Needed = BuySellContract.calculateSZTPrice(tokens, tokens + 5*1e18)
    # print(DAI_Amount_Needed)
    # DAI.approve(BuySellContract.address, DAI_Amount_Needed[1], {"from":accountA})
    # BuySellContract.buySZTToken(5*1e18, {"from":accountA})

    # tokens = BuySellContract.getSZTTokenCount()
    # DAI_Amount_Needed = BuySellContract.calculateSZTPrice(tokens, tokens + 5*1e18)
    # print(DAI_Amount_Needed)
    # DAI.approve(BuySellContract.address, DAI_Amount_Needed[1], {"from":accountA})
    # BuySellContract.buySZTToken(5*1e18, {"from":accountA})
    # BuySellContract.activateSellTimer(5*1e18, {"from":accountA})
    # print(SZTContract.balanceOf(accountA.address)/1e18)

    # SZTContract.approve(BuySellContract.address, 5*1e18, {"from":accountA})
    # print(SZTContract.allowance(accountA.address, BuySellContract.address)/1e18)
    # Staking.stakeSZT(5*1e18, {"from":accountA})
    # print(SZTContract.balanceOf(accountA.address)/1e18)
    # Staking.activateWithdrawalTimer(5*1e18, {"from":accountA})
    # time.sleep(80)
    # DAIBefore = DAI.balanceOf(accountA.address)
    # SZTContract.approve(BuySellContract.address, 5*1e18, {"from":accountA})
    # GSZTContract.approve(BuySellContract.address, 5*1e18, {"from":accountA})
    # print(BuySellContract.getSZTTokenCount())
    # BuySellContract.sellSZTToken(5*1e18, {"from":accountA})
    # DAIAfter = DAI.balanceOf(accountA.address)
    # print(DAIAfter, DAIBefore)
    # Staking.withdrawSZT(5*1e18, {"from":accountA})
    # print(SZTContract.balanceOf(accountA.address)/1e18)



