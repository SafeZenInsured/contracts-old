import time
from brownie import accounts
from brownie import BuySellSZT, FakeCoin, TerminateInsurance
from brownie import ConstantFlowAgreement, CoveragePool, ProtocolRegistry
from brownie import SwapDAI, SZTStaking, GSZT, sztDAI, SZT
from brownie import AAVE, CompoundPool, ZPController

accountA = accounts.add("bed7ccf7bc6d24b639ae1e77e636320474100b6c898834a0da5fe8e3876245ce")
DAI = FakeCoin.at("0xdAE9067d617E07662D35e14f9043deA524Fb47F0")
BuySellContract = BuySellSZT.at("0xAF22c92F31E081C2804826F1a3B95f3831817984")
GSZTContract = GSZT.at("0x9c5768b4C82F11Fc651290BBA3faf62C7C9527d2")
SZTContract = SZT.at("0xB233eB1818b1A7CBCad3FB4464c5660268aa35f2")
CFA = ConstantFlowAgreement.at("0x61Ee36722a93F637b4Bdf9B03e100d328EE30917")
sztDAIContract = sztDAI.at("0x82474498A330fb089269f7FcE662a0eCA709B970")
Gelato = TerminateInsurance.at("0x0eB9489439A7Eeb74b6d8cFfB265eBe642BbFc7E")
CoveragePoolContract = CoveragePool.at("0x32dDA1Bd063a763Cdaa7FC7bd05753087B1Bd467")
ProtocolRegistryContract = ProtocolRegistry.at("0xc2632772cEF707A5d3720328fd14d4f2a946f03f")
Staking = SZTStaking.at("0x7313C1870baCaC5b310B1466cbdB040942229eA6")
SwapDAIContract = SwapDAI.at("0x447373C1434Ece7B3d85f05c9AB2dE32c9D8E10d")
# ZeroPremium = ZPController.at("0x35E569DEA2b1854318C46ee727D2133b78D92644")
# AAVEDEFI = AAVE.at("0x1Fc0da9C655fb29D46edCCaE0a89F4CB634De380")
# CompoundDEFI = CompoundPool.at("0x4c1fda4aA017846BCD322a96ca63f5fA48e5A887")


def main():
    DAI.mint(accountA.address, 1e30, {"from":accountA})
    DAI.approve(BuySellContract.address, 1e30, {"from":accountA})
    BuySellContract.buySZTToken(300*1e18, {"from":accountA})
    ProtocolRegistryContract.addProtocolInfo("AAVE", "0xc4dCB5126a3AfEd129BC3668Ea19285A9f56D15D", 99, True, 1, 126839167935, {"from":accountA})
    ProtocolRegistryContract.addProtocolInfo("Compound", "0x3cBe63aAcF6A064D32072a630A3eab7545C54d78", 97, True, 1, 159839167104, {"from":accountA})
    SZTContract.approve(BuySellContract.address, 1e30, {"from":accountA})
    GSZTContract.approve(BuySellContract.address, 1e30, {"from":accountA})
    CoveragePoolContract.underwrite(100*1e18, 1, {"from":accountA})
    print(ProtocolRegistryContract.viewProtocolInfo(1))
    DAI.approve(SwapDAIContract.address, 1e30, {"from":accountA})
    SwapDAIContract.swapDAI(10000*1e18, {"from":accountA})
    CFA.activateInsurance(10*1e18, 1, {"from":accountA})
    print(CFA.getUserInsuranceStatus(accountA.address, 1, {"from":accountA}))
    print(CFA.getUserInsuranceValidTillInfo(accountA.address, 1, {"from":accountA}))
    time.sleep(60)
    sztDAIContract.approve(CFA.address, 1e30, {"from":accountA})
    CFA.closeTokenStream(accountA.address, 1, {"from":accountA})

    CoveragePoolContract.underwrite(100*1e18, 2, {"from":accountA})
    print(ProtocolRegistryContract.viewProtocolInfo(1))
    CFA.activateInsurance(10*1e18, 2, {"from":accountA})
    print(CFA.getUserInsuranceStatus(accountA.address, 1, {"from":accountA}))
    print(CFA.getUserInsuranceValidTillInfo(accountA.address, 1, {"from":accountA}))
    time.sleep(60)

